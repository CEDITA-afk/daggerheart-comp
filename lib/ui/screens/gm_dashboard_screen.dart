import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../logic/gm_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/combat_provider.dart';
import '../../data/models/character.dart'; 
import '../widgets/dice_roller_dialog.dart';
import 'combat_screen.dart';
import 'character_sheet_screen.dart'; // Fondamentale per vedere la scheda giocatore

class GmDashboardScreen extends StatelessWidget {
  const GmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<GmProvider, RoomProvider, CombatProvider>(
      builder: (context, gm, room, combat, child) {
        
        // Funzione helper per sincronizzare tutto col Cloud
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
            actions: [
               IconButton(
                icon: const Icon(Icons.casino),
                tooltip: "Lancia Dadi",
                onPressed: () => showDialog(context: context, builder: (_) => const DiceRollerDialog()),
              ),
            ],
            bottom: room.currentRoomCode != null 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(30),
                  child: Container(
                    color: Colors.blue[900],
                    alignment: Alignment.center,
                    child: Text(
                      "CODICE STANZA: ${room.currentRoomCode}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)
                    ),
                  ),
                )
              : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- TRACKERS PAURA & AZIONI ---
                Row(
                  children: [
                    Expanded(
                      child: _buildTrackerCard(
                        "PAURA", 
                        gm.fear, 
                        Colors.red, 
                        (v) { gm.modifyFear(v); syncIfOnline(); }
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTrackerCard(
                        "AZIONI", 
                        gm.actionTokens, 
                        Colors.amber, 
                        (v) { gm.modifyActionTokens(v); syncIfOnline(); }
                      )
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // --- SEZIONE LOBBY GIOCATORI ONLINE ---
                if (room.isGm && room.playersStream != null) ...[
                  const Text("GIOCATORI CONNESSI", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  StreamBuilder<QuerySnapshot>(
                    stream: room.playersStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Nessun giocatore connesso.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        );
                      }

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
                            color: const Color(0xFF2C2C2C),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[900],
                                child: Text(charName.isNotEmpty ? charName[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white)),
                              ),
                              title: Text(charName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(charClass.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              
                              // TAP SULLA RIGA -> APRE SCHEDA PERSONAGGIO
                              onTap: () {
                                final char = Character.fromJson(data);
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (_) => CharacterSheetScreen(character: char))
                                );
                              },

                              trailing: isInCombat
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text("COMBAT"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[800],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 10)
                                    ),
                                    onPressed: () {
                                      // 1. Crea oggetto Character
                                      final newChar = Character.fromJson(data); 
                                      // 2. Aggiungi al Combat Provider Locale
                                      combat.addCharacterToCombat(newChar);
                                      // 3. Sincronizza col Cloud
                                      syncIfOnline();
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("$charName aggiunto al combattimento!"))
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // --- GESTIONE COMBATTIMENTO ---
                const Divider(color: Colors.white24),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("GESTIONE SCONTRO", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.flash_on, size: 28), // Icona corretta
                  label: const Text("GESTISCI NEMICI & HP", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CombatScreen()));
                  },
                ),
                
                const SizedBox(height: 12),
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900], // Rosso scuro per azione distruttiva
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text("TERMINA / PULISCI SCONTRO"),
                  onPressed: () async {
                    // Conferma prima di cancellare
                    bool confirm = await showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Colors.black,
                        title: const Text("Terminare Scontro?", style: TextStyle(color: Colors.white)),
                        content: const Text("Questo rimuoverà tutti i nemici e i personaggi dalla vista combattimento di TUTTI i giocatori.", style: TextStyle(color: Colors.grey)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("TERMINA", style: TextStyle(color: Colors.red))),
                        ],
                      )
                    ) ?? false;

                    if (confirm) {
                      combat.clearCombat(); // Pulisce locale
                      await room.clearCombat(); // Pulisce cloud
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Combattimento terminato e pulito.")));
                      }
                    }
                  },
                ),
                const SizedBox(height: 40),
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text("$value", style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline), 
                color: Colors.white70,
                onPressed: () => onMod(-1)
              ),
              IconButton(
                icon: const Icon(Icons.add_circle), 
                color: color,
                iconSize: 32,
                onPressed: () => onMod(1)
              ),
            ],
          )
        ],
      ),
    );
  }
}