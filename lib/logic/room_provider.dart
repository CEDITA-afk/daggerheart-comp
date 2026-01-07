import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/character.dart';
import '../data/models/adversary.dart';

class RoomProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  String? currentRoomCode;
  bool isGm = false;
  
  // Dati della stanza corrente
  int fear = 0;
  int actionTokens = 0;
  List<dynamic> activeEnemiesData = [];

  // --- GM: CREAZIONE STANZA ---
  Future<String> createRoom(String gmName) async {
    // Genera un codice semplice a 6 cifre
    String code = DateTime.now().millisecondsSinceEpoch.toString().substring(7, 13);
    
    await _db.collection('rooms').doc(code).set({
      'gmName': gmName,
      'createdAt': FieldValue.serverTimestamp(),
      'fear': 0,
      'actionTokens': 0,
      'combatActive': false,
      'adversaries': [], 
    });

    currentRoomCode = code;
    isGm = true;
    _listenToRoom(code); // Inizia ad ascoltare i cambiamenti
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
    _listenToRoom(code);
    notifyListeners();
  }

  // --- ASCOLTO DATI IN TEMPO REALE ---
  void _listenToRoom(String code) {
    _db.collection('rooms').doc(code).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          fear = data['fear'] ?? 0;
          actionTokens = data['actionTokens'] ?? 0;
          activeEnemiesData = data['adversaries'] ?? [];
          notifyListeners();
        }
      }
    });
  }

  // --- GM: AGGIORNA COMBATTIMENTO ---
  Future<void> syncCombatData(int newFear, int newTokens, List<Adversary> enemies) async {
    if (!isGm || currentRoomCode == null) return;

    List<Map<String, dynamic>> enemiesJson = enemies.map((e) => {
      'id': e.id,
      'name': e.name,
      'currentHp': e.currentHp,
      'maxHp': e.maxHp,
      'stress': e.currentStress, // Assicurati che Adversary abbia currentStress
    }).toList();

    await _db.collection('rooms').doc(currentRoomCode).update({
      'fear': newFear,
      'actionTokens': newTokens,
      'adversaries': enemiesJson,
    });
  }
}