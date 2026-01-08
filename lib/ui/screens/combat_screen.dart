import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/combat_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/gm_provider.dart';
import '../../data/models/adversary.dart';
import '../../data/data_manager.dart';
import '../widgets/adversary_details_dialog.dart';
import 'character_sheet_screen.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {

  // --- DIALOG PER AGGIUNGERE NEMICI ---
  void _showAddEnemyDialog(BuildContext context, CombatProvider combat) {
    // CORREZIONE 1: Usiamo il getter corretto 'getAdversaryLibrary'
    final List<Adversary> adversaries = DataManager().getAdversaryLibrary();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return Column(
          children: [
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text("AGGIUNGI AVVERSARIO", style: TextStyle(color: Colors.white, fontFamily: 'Cinzel', fontWeight: FontWeight.bold)),
             ),
             Expanded(
               child: adversaries.isEmpty 
               ? const Center(child: Text("Nessun avversario caricato.", style: TextStyle(color: Colors.grey)))
               : ListView.builder(
                 itemCount: adversaries.length,
                 itemBuilder: (c, i) {
                   final adv = adversaries[i]; // Ora è un oggetto Adversary, non una Map
                   return ListTile(
                     leading: CircleAvatar(
                       backgroundColor: Colors.red[900], 
                       child: Text(adv.tier.isNotEmpty ? adv.tier[0] : "T", style: const TextStyle(color: Colors.white))
                     ),
                     title: Text(adv.name, style: const TextStyle(color: Colors.white)),
                     subtitle: Text("${adv.tier} • Diff: ${adv.difficulty}", style: const TextStyle(color: Colors.grey)),
                     onTap: () {
                       // CORREZIONE 2: Usiamo clone() invece di cercare di settare l'ID manualmente
                       final enemyObj = adv.clone();
                       combat.addAdversary(enemyObj);
                       Navigator.pop(ctx);
                     },
                   );
                 }
               ),
             ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<CombatProvider, RoomProvider, GmProvider>(
      builder: (context, combat, room, gm, child) {
        final enemies = combat.activeEnemies;
        final characters = combat.activeCharacters;

        return Scaffold(
          appBar: AppBar(
            title: const Text("REGIA SCONTRO", style: TextStyle(fontFamily: 'Cinzel')),
            backgroundColor: Colors.red[900],
            actions: [
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                tooltip: "Invia ai Giocatori",
                onPressed: () {
                   List<dynamic> allActive = [...enemies, ...characters];
                   room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dati inviati ai giocatori!")));
                },
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- EROI ---
              const Text("EROI", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              if (characters.isEmpty) 
                const Padding(padding: EdgeInsets.all(8), child: Text("Nessun eroe.", style: TextStyle(color: Colors.grey))),
              
              ...characters.map((char) => Card(
                color: const Color(0xFF1A237E).withOpacity(0.4),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: Text(char.name, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => combat.activeCharacters.removeWhere((c) => c.id == char.id)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CharacterSheetScreen(character: char))),
                ),
              )),

              const SizedBox(height: 24),

              // --- AVVERSARI ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AVVERSARI", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle, color: Colors.redAccent), onPressed: () => _showAddEnemyDialog(context, combat)),
                ],
              ),
              
              ...enemies.map((enemy) => Card(
                color: const Color(0xFFB71C1C).withOpacity(0.2),
                child: ListTile(
                  leading: const Icon(Icons.android, color: Colors.redAccent),
                  title: Text(enemy.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.remove, size: 16, color: Colors.red), onPressed: () => combat.modifyHp(enemy.id, -1)),
                      Text(" ${enemy.currentHp} / ${enemy.maxHp} ", style: const TextStyle(color: Colors.white)),
                      IconButton(icon: const Icon(Icons.add, size: 16, color: Colors.green), onPressed: () => combat.modifyHp(enemy.id, 1)),
                    ],
                  ),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => combat.removeAdversary(enemy.id)),
                  onTap: () {
                    // CORREZIONE 3: Mappiamo le nuove proprietà per il Dialog
                    showDialog(context: context, builder: (_) => AdversaryDetailsDialog(data: {
                      'name': enemy.name,
                      'tier': enemy.tier,
                      'currentHp': enemy.currentHp,
                      'maxHp': enemy.maxHp,
                      'attack': "${enemy.attackName} (+${enemy.attackMod})", // Format string
                      'damage': enemy.damageDice, // Nome corretto
                      'difficulty': enemy.difficulty,
                      // Convertiamo la lista di oggetti Feature in lista di Mappe per il dialog
                      'moves': enemy.features.map((f) => {
                        'name': f.name,
                        'description': f.text
                      }).toList(),
                      'gm_moves': [], // Campo vuoto o da implementare se aggiungi feature GM
                    }));
                  },
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}