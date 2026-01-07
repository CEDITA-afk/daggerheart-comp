import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../data/models/character.dart';

class RoomProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? currentRoomCode;
  bool isGm = false;
  String? myUserId; // ID univoco dell'utente (GM o Giocatore) sul dispositivo

  // Dati della stanza
  int fear = 0;
  int actionTokens = 0;
  List<dynamic> activeCombatantsData = []; 
  
  Stream<QuerySnapshot>? playersStream;

  // --- INIZIALIZZAZIONE ---
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Generiamo un ID univoco per questo dispositivo se non esiste
    if (!prefs.containsKey('user_device_id')) {
      String newId = DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
      await prefs.setString('user_device_id', newId);
    }
    myUserId = prefs.getString('user_device_id');

    // Controllo se c'era una sessione aperta
    final savedRoom = prefs.getString('room_code');
    final savedIsGm = prefs.getBool('is_gm') ?? false;

    if (savedRoom != null) {
      // Tentiamo di riconnetterci
      try {
        DocumentSnapshot snap = await _db.collection('rooms').doc(savedRoom).get();
        if (snap.exists) {
          currentRoomCode = savedRoom;
          isGm = savedIsGm;
          _listenToRoom(savedRoom);
          if (isGm) _listenToPlayers(savedRoom);
          notifyListeners();
        }
      } catch (e) {
        await exitRoom();
      }
    }
  }

  // --- GM: GESTIONE STANZE ---
  
  // Ottieni le stanze create da questo GM in passato
  Stream<QuerySnapshot> getMyRooms() {
    if (myUserId == null) return const Stream.empty();
    return _db.collection('rooms')
      .where('gmId', isEqualTo: myUserId)
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  Future<String> createRoom(String gmName, String roomName) async {
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
    
    await _db.collection('rooms').doc(code).set({
      'roomName': roomName,
      'gmName': gmName,
      'gmId': myUserId, // Salviamo l'ID del proprietario
      'createdAt': FieldValue.serverTimestamp(),
      'fear': 0,
      'actionTokens': 0,
      'combatants': [], 
    });

    await _enterRoomAsGm(code);
    return code;
  }

  Future<void> resumeRoom(String code) async {
    await _enterRoomAsGm(code);
  }

  Future<void> _enterRoomAsGm(String code) async {
    currentRoomCode = code;
    isGm = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', true);

    _listenToRoom(code);
    _listenToPlayers(code);
    notifyListeners();
  }

  // --- GM: GESTIONE COMBATTIMENTO ---

  Future<void> syncCombatData(int newFear, int newTokens, List<dynamic> allCombatants) async {
    if (!isGm || currentRoomCode == null) return;

    List<Map<String, dynamic>> combatJson = allCombatants.map((e) {
      return {
        'id': e.id,
        'name': e.name,
        'currentHp': e.currentHp,
        'maxHp': e.maxHp,
        'isPlayer': e is Character,
        // Salviamo anche l'immagine o altri dati se servono
      };
    }).toList();

    await _db.collection('rooms').doc(currentRoomCode).update({
      'fear': newFear,
      'actionTokens': newTokens,
      'combatants': combatJson,
    });
  }

  Future<void> clearCombat() async {
    if (!isGm || currentRoomCode == null) return;
    
    // Mantiene Paura e Token, ma svuota i combattenti
    await _db.collection('rooms').doc(currentRoomCode).update({
      'combatants': [],
    });
    // Nota: il CombatProvider locale deve essere pulito separatamente dalla UI
  }

  // --- GIOCATORE ---
  Future<void> joinRoom(String code, Character character) async {
    DocumentReference roomRef = _db.collection('rooms').doc(code);
    DocumentSnapshot snap = await roomRef.get();

    if (!snap.exists) throw Exception("Codice stanza non valido!");

    await roomRef.collection('players').doc(character.id).set(character.toJson());

    currentRoomCode = code;
    isGm = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('room_code', code);
    await prefs.setBool('is_gm', false);
    await prefs.setString('char_id', character.id);

    _listenToRoom(code);
    notifyListeners();
  }

  // --- COMUNE ---
  Future<void> exitRoom() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Rimuove sessione
    // Rigenera ID dispositivo per sicurezza
    if (myUserId != null) await prefs.setString('user_device_id', myUserId!);
    
    currentRoomCode = null;
    isGm = false;
    playersStream = null;
    activeCombatantsData = [];
    notifyListeners();
  }

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
}