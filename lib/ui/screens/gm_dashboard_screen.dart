import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/gm_provider.dart';
import '../../logic/room_provider.dart'; // Per sincronizzazione online
import '../../logic/combat_provider.dart'; // Per recuperare i nemici correnti durante il sync
import '../widgets/dice_roller_dialog.dart';
import 'combat_screen.dart'; 

class GmDashboardScreen extends StatelessWidget {
  const GmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usiamo Consumer2 per accedere sia allo stato locale GM che allo stato della Stanza Online
    return Consumer2<GmProvider, RoomProvider>(
      builder: (context, gm, room, child) {
        
        // Funzione Helper per sincronizzare se online
        void syncIfOnline() {
          if (room.currentRoomCode != null) {
            // Recuperiamo i nemici attuali dal CombatProvider per non sovrascriverli con una lista vuota
            final enemies = Provider.of<CombatProvider>(context, listen: false).activeEnemies;
            room.syncCombatData(gm.fear, gm.actionTokens, enemies);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("STRUMENTI DEL GM", style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Color(0xFFD4AF37))),
            centerTitle: true,
            // SE ONLINE, MOSTRA IL CODICE STANZA
            bottom: room.currentRoomCode != null 
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(40),
                  child: Container(
                    color: Colors.blueAccent.withOpacity(0.2),
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.vpn_key, size: 16, color: Colors.white70),
                        const SizedBox(width: 8),
                        SelectableText(
                          "CODICE STANZA: ${room.currentRoomCode}", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.casino, color: Colors.white),
                onPressed: () => showDialog(
                  context: context, 
                  builder: (_) => const DiceRollerDialog(label: "Tiro GM")
                ),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- TRACKERS ---
                Row(
                  children: [
                    Expanded(
                      child: _buildTrackerCard(
                        "PAURA", 
                        gm.fear, 
                        Colors.redAccent, 
                        (val) {
                          gm.modifyFear(val); // Modifica Locale
                          syncIfOnline();     // Sync Cloud
                        }
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTrackerCard(
                        "SEGNALINI AZIONE", 
                        gm.actionTokens, 
                        Colors.amber, 
                        (val) {
                          gm.modifyActionTokens(val); // Modifica Locale
                          syncIfOnline();             // Sync Cloud
                        }
                      )
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // --- PULSANTE COMBAT TRACKER ---
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.flash_on, color: Colors.white, size: 28),
                  label: const Text(
                    "GESTORE COMBATTIMENTO", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CombatScreen()),
                    );
                  },
                ),

                const SizedBox(height: 24),
                
                // --- LOOT GENERATOR ---
                _buildSectionHeader("GENERATORE BOTTINO"),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLootBtn(gm, 1, "TIER 1 (Lv 1-4)"),
                            _buildLootBtn(gm, 2, "TIER 2 (Lv 5-7)"),
                            _buildLootBtn(gm, 3, "TIER 3 (Lv 8-10)"),
                          ],
                        ),
                        const Divider(height: 30, color: Colors.white24),
                        const Text("RISULTATO:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(
                          gm.lastLoot.isEmpty ? "..." : gm.lastLoot,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- NOTE RAPIDE ---
                _buildSectionHeader("NOTE SESSIONE"),
                const SizedBox(height: 10),
                const TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                    hintText: "Annota qui PF dei nemici, iniziative o idee...",
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackerCard(String label, int value, Color color, Function(int) onModify) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Text("$value", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleBtn(Icons.remove, () => onModify(-1)),
              const SizedBox(width: 15),
              _circleBtn(Icons.add, () => onModify(1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[800], shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildLootBtn(GmProvider gm, int tier, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onPressed: () => gm.generateLoot(tier),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontFamily: 'Cinzel', fontSize: 16, color: Color(0xFFD4AF37), letterSpacing: 1.2),
    );
  }
}