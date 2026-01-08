import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../data/models/character.dart';
// Assicurati che Adversary sia importato se serve fare check di tipo esplicito, 
// anche se qui usiamo dynamic per flessibilità nel metodo sync.

class RoomProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? currentRoomCode;
  bool isGm = false;
  String? myUserId; // ID univoco del dispositivo (per identificare il GM proprietario)
  String? myCharacterId; // ID del personaggio (se giocatore)

  // Dati della stanza sincronizzati
  int fear = 0;
  int actionTokens = 0;
  List<dynamic> activeCombatantsData = []; // Lista mista (JSON di Nemici e PG)
  
  // Stream per ascoltare chi entra nella lobby (solo per GM)
  Stream<QuerySnapshot>? playersStream;

  // --- INIZIALIZZAZIONE (RECUPERO SESSIONE) ---
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Identità del Dispositivo (genera se non esiste)
    if (!prefs.containsKey('user_device_id')) {
      String newId = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
      await prefs.setString('user_device_id', newId);
    }
    myUserId = prefs.getString('user_device_id');

    // 2. Controllo Sessione Interrotta (Refresh pagina)
    final savedRoom = prefs.getString('room_code');
    final savedIsGm = prefs.getBool('is_gm') ?? false;
    final savedCharId = prefs.getString('char_id');

    if (savedRoom != null) {
      print("Tentativo di riconnessione alla stanza: $savedRoom");
      try {
        DocumentSnapshot snap = await _db.collection('rooms').doc(savedRoom).get();
        if (snap.exists) {
          // Riconnessione riuscita
          currentRoomCode = savedRoom;
          isGm = savedIsGm;
          myCharacterId = savedCharId;
          
          _listenToRoom(savedRoom);
          if (isGm) {
            _listenToPlayers(savedRoom);
          }
          notifyListeners();
        } else {
          // La stanza non esiste più online
          await exitRoom();
        }
      } catch (e) {
        print("Errore riconnessione: $e");
        await exitRoom();
      }
    }
  }

  // --- GM: GESTIONE STANZE ---
  
  // Ottieni le stanze create da questo dispositivo in passato
  Stream<QuerySnapshot> getMyRooms() {
    if (myUserId == null) return const Stream.empty();
    return _db.collection('rooms')
      .where('gmId', isEqualTo: myUserId)
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  // Crea una nuova stanza
  Future<String> createRoom(String gmName, String roomName) async {
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
    
    await _db.collection('rooms').doc(code).set({
      'roomName': roomName,
      'gmName': gmName,
      'gmId': myUserId, // Salviamo l'ID per mostrare la stanza nella lista "Le tue stanze"
      'createdAt': FieldValue.serverTimestamp(),
      'fear': 0,
      'actionTokens': 0,
      'combatants': [], 
    });

    await _enterRoomAsGm(code);
    return code;
  }

  // Riprendi una stanza esistente (dallo storico)
  Future<void> resumeRoom(String code) async {
    await _enterRoomAsGm(code);
  }

  // Logica interna per settare lo stato GM
  Future<void> _enterRoomAsGm(String code) async {
    currentRoomCode = code;
    isGm = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', true);
    await prefs.remove('char_id'); // Il GM non ha un character ID

    _listenToRoom(code);
    _listenToPlayers(code);
    notifyListeners();
  }

  // --- GM: GESTIONE COMBATTIMENTO & SYNC ---

  // Invia i dati locali (CombatProvider) al Cloud, convertendoli in JSON leggibili da tutti
  Future<void> syncCombatData(int newFear, int newTokens, List<dynamic> allCombatants) async {
    if (!isGm || currentRoomCode == null) return;

    List<Map<String, dynamic>> combatJson = allCombatants.map((e) {
      if (e is Character) {
        // --- È UN PERSONAGGIO ---
        return {
          'id': e.id,
          'name': e.name,
          'currentHp': e.currentHp,
          'maxHp': e.maxHp,
          'isPlayer': true,
          // Inviamo i dati essenziali (o tutto il JSON) per permettere di vedere la scheda
          ...e.toJson(), 
        };
      } else {
        // --- È UN NEMICO (Adversary) ---
        // Costruiamo la mappa manualmente o usiamo toJson se presente nel modello
        // Qui assumiamo che l'oggetto 'e' sia di tipo Adversary
        return {
          'id': e.id,
          'name': e.name,
          'currentHp': e.currentHp,
          'maxHp': e.maxHp,
          'isPlayer': false,
          'tier': e.tier,
          'attack': e.attackModifier,
          'damage': e.damageOutput,
          'difficulty': e.difficulty,
          'moves': e.moves,     
          'gm_moves': e.gmMoves 
        };
      }
    }).toList();

    await _db.collection('rooms').doc(currentRoomCode).update({
      'fear': newFear,
      'actionTokens': newTokens,
      'combatants': combatJson,
    });
  }

  // Pulisce il combattimento per tutti
  Future<void> clearCombat() async {
    if (!isGm || currentRoomCode == null) return;
    
    await _db.collection('rooms').doc(currentRoomCode).update({
      'combatants': [],
    });
  }

  // --- GIOCATORE: UNISCITI ---
  Future<void> joinRoom(String code, Character character) async {
    DocumentReference roomRef = _db.collection('rooms').doc(code);
    DocumentSnapshot snap = await roomRef.get();

    if (!snap.exists) throw Exception("Codice stanza non valido!");

    // Aggiunge/Aggiorna il player nella subcollection della stanza
    await roomRef.collection('players').doc(character.id).set(character.toJson());

    currentRoomCode = code;
    isGm = false;
    myCharacterId = character.id;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', false);
    await prefs.setString('char_id', character.id);

    _listenToRoom(code);
    notifyListeners();
  }

  // --- COMUNE: ESCI DALLA STANZA ---
  Future<void> exitRoom() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Manteniamo solo l'ID dispositivo, cancelliamo i dati di sessione
    String? deviceId = prefs.getString('user_device_id');
    await prefs.clear();
    if (deviceId != null) {
      await prefs.setString('user_device_id', deviceId);
    }
    
    // Reset stato locale
    currentRoomCode = null;
    isGm = false;
    myCharacterId = null;
    playersStream = null;
    activeCombatantsData = [];
    
    notifyListeners();
  }

  // --- ASCOLTATORI (LISTENERS) ---
  
  // Ascolta i cambiamenti generali (Paura, Token, Combattimento)
  void _listenToRoom(String code) {
    _db.collection('rooms').doc(code).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          fear = data['fear'] ?? 0;
          actionTokens = data['actionTokens'] ?? 0;
          activeCombatantsData = data['combatants'] ?? [];
          notifyListeners();
        }
      } else {
        // Se il documento viene cancellato mentre siamo dentro
        exitRoom();
      }
    });
  }

  // Ascolta la lista giocatori (Solo per GM)
  void _listenToPlayers(String code) {
    playersStream = _db.collection('rooms').doc(code).collection('players').snapshots();
    notifyListeners();
  }
}