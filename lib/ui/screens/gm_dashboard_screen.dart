import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../logic/gm_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/combat_provider.dart';
import '../../data/models/character.dart'; // Importa il modello Character
import '../widgets/dice_roller_dialog.dart';
import 'combat_screen.dart';

class GmDashboardScreen extends StatelessWidget {
  const GmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<GmProvider, RoomProvider, CombatProvider>(
      builder: (context, gm, room, combat, child) {
        
        // Funzione di Sync
        void syncIfOnline() {
          if (room.currentRoomCode != null) {
            // Uniamo nemici e PG attivi nel combat provider per inviarli al cloud
            List<dynamic> allActive = [...combat.activeEnemies, ...combat.activeCharacters];
            room.syncCombatData(gm.fear, gm.actionTokens, allActive);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("DASHBOARD GM", style: TextStyle(fontFamily: 'Cinzel')),
            bottom: room.currentRoomCode != null 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(30),
                  child: Container(
                    color: Colors.blue[900],
                    alignment: Alignment.center,
                    child: Text("CODICE: ${room.currentRoomCode}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                )
              : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TRACKERS
                Row(
                  children: [
                    Expanded(child: _buildTrackerCard("PAURA", gm.fear, Colors.red, (v) { gm.modifyFear(v); syncIfOnline(); })),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTrackerCard("AZIONI", gm.actionTokens, Colors.amber, (v) { gm.modifyActionTokens(v); syncIfOnline(); })),
                  ],
                ),
                
                const SizedBox(height: 20),

                // --- SEZIONE LOBBY GIOCATORI ONLINE ---
                if (room.isGm && room.playersStream != null) ...[
                  const Text("GIOCATORI CONNESSI", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: room.playersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Text("Nessun giocatore connesso.", style: TextStyle(fontStyle: FontStyle.italic));

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (ctx, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final charName = data['name'] ?? 'Sconosciuto';
                          final charClass = data['classId'] ?? '';
                          final charId = docs[index].id;
                          
                          // Controlla se è già in combattimento
                          bool isInCombat = combat.activeCharacters.any((c) => c.id == charId);

                          return Card(
                            color: Colors.grey[900],
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.blueAccent),
                              title: Text(charName, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(charClass, style: const TextStyle(color: Colors.white54)),
                              trailing: isInCombat
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text("In Combattimento"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                                    onPressed: () {
                                      // 1. Crea oggetto Character dai dati Firebase
                                      final newChar = Character.fromJson(data); 
                                      // 2. Aggiungi al Combat Provider Locale
                                      combat.addCharacterToCombat(newChar);
                                      // 3. Sincronizza col Cloud
                                      syncIfOnline();
                                    },
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // --- PULSANTE COMBAT TRACKER ---
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  icon: const Icon(Icons.flash_on, size: 28),
                  label: const Text("APRI GESTORE COMBATTIMENTO", style: TextStyle(fontSize: 18)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatScreen())),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackerCard(String label, int value, Color color, Function(int) onMod) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text("$value", style: const TextStyle(fontSize: 40, color: Colors.white)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => onMod(-1)),
              IconButton(icon: const Icon(Icons.add_circle), onPressed: () => onMod(1)),
            ],
          )
        ],
      ),
    );
  }
}