import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/room_provider.dart';

class BattleTab extends StatelessWidget {
  const BattleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomProvider>(
      builder: (context, room, child) {
        final combatants = room.activeCombatantsData;

        if (combatants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nature_people, size: 64, color: Colors.grey[800]),
                const SizedBox(height: 16),
                const Text(
                  "Tutto tranquillo...",
                  style: TextStyle(color: Colors.grey, fontSize: 18),
                ),
                const Text(
                  "Nessun combattimento in corso.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- INFO GM (PAURA E AZIONI) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(Icons.bolt, "AZIONI GM", room.actionTokens.toString(), Colors.amber),
                  Container(width: 1, height: 40, color: Colors.grey),
                  _buildStat(Icons.error_outline, "PAURA", room.fear.toString(), Colors.redAccent),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text("CAMPO DI BATTAGLIA", style: TextStyle(color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // --- LISTA COMBATTENTI ---
            ...combatants.map((c) {
              final isPlayer = c['isPlayer'] == true;
              final name = c['name'] ?? 'Sconosciuto';
              final currentHp = (c['currentHp'] ?? 0).toInt();
              final maxHp = (c['maxHp'] ?? 1).toInt();
              final hpPercent = (currentHp / (maxHp > 0 ? maxHp : 1)).clamp(0.0, 1.0);

              return Card(
                color: isPlayer ? const Color(0xFF1A237E).withOpacity(0.4) : const Color(0xFFB71C1C).withOpacity(0.2),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isPlayer ? Colors.blueAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPlayer ? Icons.person : Icons.android, // Usa un'icona generica per i nemici se non hai icone specifiche
                            color: isPlayer ? Colors.blueAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                              ),
                            ),
                          ),
                          Text(
                            "$currentHp / $maxHp HP",
                            style: TextStyle(
                              color: _getHpColor(hpPercent),
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // BARRA DELLA SALUTE
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: hpPercent,
                          minHeight: 8,
                          backgroundColor: Colors.black54,
                          valueColor: AlwaysStoppedAnimation<Color>(_getHpColor(hpPercent)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getHpColor(double percent) {
    if (percent > 0.5) return Colors.green;
    if (percent > 0.25) return Colors.orange;
    return Colors.red;
  }
}