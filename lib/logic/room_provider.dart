import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/character.dart';
import '../data/models/adversary.dart'; // Assicurati di avere un modello base per i combattenti

class RoomProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? currentRoomCode;
  bool isGm = false;
  String? myCharacterId; // ID del personaggio corrente (se giocatore)

  // Dati della stanza
  int fear = 0;
  int actionTokens = 0;
  List<dynamic> activeCombatantsData = []; // Lista mista (Nemici + PG)
  
  // Stream dei giocatori nella Lobby (per il GM)
  Stream<QuerySnapshot>? playersStream;

  // --- INIZIALIZZAZIONE (RECUPERO SESSIONE) ---
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRoom = prefs.getString('room_code');
    final savedIsGm = prefs.getBool('is_gm') ?? false;
    final savedCharId = prefs.getString('char_id');

    if (savedRoom != null) {
      print("Tentativo di riconnessione alla stanza: $savedRoom");
      // Tentiamo di riconnetterci silenziosamente
      try {
        DocumentSnapshot snap = await _db.collection('rooms').doc(savedRoom).get();
        if (snap.exists) {
          currentRoomCode = savedRoom;
          isGm = savedIsGm;
          myCharacterId = savedCharId;
          _listenToRoom(savedRoom);
          if (isGm) {
            _listenToPlayers(savedRoom);
          }
          notifyListeners();
        }
      } catch (e) {
        print("Errore riconnessione: $e");
        await clearSession(); // Se fallisce, puliamo tutto
      }
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentRoomCode = null;
    isGm = false;
    myCharacterId = null;
    playersStream = null;
    notifyListeners();
  }

  // --- GM: CREAZIONE STANZA ---
  Future<String> createRoom(String gmName) async {
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
    
    await _db.collection('rooms').doc(code).set({
      'gmName': gmName,
      'createdAt': FieldValue.serverTimestamp(),
      'fear': 0,
      'actionTokens': 0,
      'combatActive': false,
      'combatants': [], 
    });

    currentRoomCode = code;
    isGm = true;
    
    // Salvataggio Sessione
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', true);

    _listenToRoom(code);
    _listenToPlayers(code);
    notifyListeners();
    return code;
  }

  // --- GIOCATORE: UNISCITI ALLA STANZA ---
  Future<void> joinRoom(String code, Character character) async {
    DocumentReference roomRef = _db.collection('rooms').doc(code);
    DocumentSnapshot snap = await roomRef.get();

    if (!snap.exists) throw Exception("Codice stanza non valido!");

    // Aggiungi il personaggio alla stanza
    await roomRef.collection('players').doc(character.id).set(character.toJson());

    currentRoomCode = code;
    isGm = false;
    myCharacterId = character.id;

    // Salvataggio Sessione
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', false);
    await prefs.setString('char_id', character.id);

    _listenToRoom(code);
    notifyListeners();
  }

  // --- ASCOLTO DATI ---
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
      }
    });
  }

  void _listenToPlayers(String code) {
    playersStream = _db.collection('rooms').doc(code).collection('players').snapshots();
    notifyListeners();
  }

  // --- GM: AGGIORNA TUTTO (COMBATTIMENTO) ---
  // Ora salviamo l'intera lista dei combattenti (compresi i PG aggiunti)
  Future<void> syncCombatData(int newFear, int newTokens, List<dynamic> allCombatants) async {
    if (!isGm || currentRoomCode == null) return;

    // Mappiamo i combattenti in un formato JSON semplificato per la vista
    List<Map<String, dynamic>> combatJson = allCombatants.map((e) {
      // Gestiamo sia Adversary che Character (assumendo abbiano campi simili o controllando il tipo)
      return {
        'id': e.id,
        'name': e.name,
        'currentHp': e.currentHp, // Assicurati che Character abbia questo campo o usa un getter
        'maxHp': e.maxHp,
        'isPlayer': e is Character, // Flag utile per colorarli diversamente
        'initiative': 0, // Implementare se serve
      };
    }).toList();

    await _db.collection('rooms').doc(currentRoomCode).update({
      'fear': newFear,
      'actionTokens': newTokens,
      'combatants': combatJson,
    });
  }
}