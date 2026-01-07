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

        // SE NON C'È COMBATTIMENTO
        if (combatants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.nature_people, size: 64, color: Colors.grey[800]),
                const SizedBox(height: 16),
                const Text("Nessun combattimento in corso.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- HEADER INFO GM (Paura e Azioni) ---
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4AF37)),
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

            const Text("CAMPO DI BATTAGLIA", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),

            // --- LISTA COMBATTENTI ---
            ...combatants.map((c) {
              final isPlayer = c['isPlayer'] == true;
              final name = c['name'] ?? 'Sconosciuto';
              
              // Calcoli HP (servono solo per gli alleati)
              final currentHp = (c['currentHp'] ?? 0).toInt();
              final maxHp = (c['maxHp'] ?? 1).toInt();
              final hpPercent = (currentHp / (maxHp > 0 ? maxHp : 1)).clamp(0.0, 1.0);

              return Card(
                // Colore diverso: Blu scuro per Alleati, Rosso scuro per Nemici
                color: isPlayer 
                    ? const Color(0xFF1A237E).withOpacity(0.3) 
                    : const Color(0xFFB71C1C).withOpacity(0.2),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    // Bordo solo per alleati
                    color: isPlayer ? Colors.blueAccent.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
                // NESSUN INKWELL -> NIENTE CLICK
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // ICONA
                          Icon(
                            isPlayer ? Icons.person : Icons.android, // Persona o Mostro
                            color: isPlayer ? Colors.blueAccent : Colors.redAccent
                          ),
                          const SizedBox(width: 16),
                          
                          // NOME
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          
                          // TESTO HP (VISIBILE SOLO SE È UN ALLEATO)
                          if (isPlayer)
                            Text(
                              "$currentHp / $maxHp HP",
                              style: TextStyle(color: _getHpColor(hpPercent), fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                      
                      // BARRA HP (VISIBILE SOLO SE È UN ALLEATO)
                      if (isPlayer) ...[
                        const SizedBox(height: 12),
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
    return Column(children: [
        Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    ]);
  }

  Color _getHpColor(double percent) {
    if (percent > 0.5) return Colors.green;
    if (percent > 0.25) return Colors.orange;
    return Colors.red;
  }
}