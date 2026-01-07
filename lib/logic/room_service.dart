import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/character.dart';
import '../data/models/adversary.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- GM: CREAZIONE STANZA ---
  Future<String> createRoom(String gmName) async {
    // Genera un codice stanza casuale (es. 4 lettere)
    String roomCode = DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12);
    
    await _db.collection('rooms').doc(roomCode).set({
      'gmName': gmName,
      'createdAt': FieldValue.serverTimestamp(),
      'fear': 0,
      'actionTokens': 0,
      'combatActive': false,
      'adversaries': [], // Lista JSON dei nemici
    });

    return roomCode;
  }

  // --- GIOCATORE: UNISCITI ALLA STANZA ---
  Future<void> joinRoom(String roomCode, Character character) async {
    DocumentReference roomRef = _db.collection('rooms').doc(roomCode);
    DocumentSnapshot snap = await roomRef.get();

    if (!snap.exists) throw Exception("Stanza non trovata!");

    // Aggiungi il personaggio alla sottocollezione 'players' della stanza
    await roomRef.collection('players').doc(character.id).set(character.toJson());
  }

  // --- GM: AGGIORNA STATO COMBATTIMENTO ---
  Future<void> updateCombatState(String roomCode, int fear, int tokens, List<Adversary> enemies) async {
    // Convertiamo i nemici in JSON per salvarli
    List<Map<String, dynamic>> enemiesJson = enemies.map((e) {
      // Nota: devi assicurarti che Adversary abbia un metodo toJson completo
      return {
        'id': e.id,
        'name': e.name,
        'currentHp': e.currentHp,
        'maxHp': e.maxHp,
        // ... altri campi necessari per la visualizzazione ai player
      };
    }).toList();

    await _db.collection('rooms').doc(roomCode).update({
      'fear': fear,
      'actionTokens': tokens,
      'adversaries': enemiesJson,
    });
  }

  // --- STREAM: ASCOLTARE I CAMBIAMENTI (REAL TIME) ---
  
  // Per i Giocatori: Ascolta i dati della stanza (Paura, Token, Nemici)
  Stream<DocumentSnapshot> streamRoomData(String roomCode) {
    return _db.collection('rooms').doc(roomCode).snapshots();
  }

  // Per il GM: Ascolta i Personaggi dei giocatori
  Stream<QuerySnapshot> streamPlayers(String roomCode) {
    return _db.collection('rooms').doc(roomCode).collection('players').snapshots();
  }
}