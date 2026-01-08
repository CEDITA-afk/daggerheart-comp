import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/combat_provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/gm_provider.dart';
import '../../data/models/adversary.dart';
import '../../data/data_manager.dart';
import '../../data/models/character.dart';
import '../widgets/adversary_details_dialog.dart'; // <--- IMPORTA IL NUOVO WIDGET
import 'character_sheet_screen.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  // ... (Gestione aggiunta nemici rimane uguale, ometti per brevità se non cambiata)
  // Assumo tu abbia la funzione _showAddAdversaryDialog qui sotto.
  // Se non ce l'hai, dimmelo che la reinserisco.

  @override
  Widget build(BuildContext context) {
    return Consumer3<CombatProvider, RoomProvider, GmProvider>(
      builder: (context, combat, room, gm, child) {
        
        // Uniamo le liste per visualizzazione
        final enemies = combat.activeEnemies;
        final characters = combat.activeCharacters;

        return Scaffold(
          appBar: AppBar(
            title: const Text("GESTIONE SCONTRO", style: TextStyle(fontFamily: 'Cinzel')),
            actions: [
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: "Forza Sincronizzazione",
                onPressed: () {
                   List<dynamic> allActive = [...enemies, ...characters];
                   room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizzato!")));
                },
              )
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SEZIONE EROI
              const Text("EROI IN COMBATTIMENTO", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (characters.isEmpty) 
                const Text("Nessun eroe aggiunto.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              
              ...characters.map((char) => Card(
                color: const Color(0xFF1A237E).withOpacity(0.4),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: Text(char.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text("Livello ${char.level}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      combat.activeCharacters.removeWhere((c) => c.id == char.id);
                      combat.notifyListeners(); // Forza aggiornamento UI
                      // Auto-sync
                      List<dynamic> allActive = [...combat.activeEnemies, ...combat.activeCharacters];
                      room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                    },
                  ),
                  onTap: () {
                    // IL GM APRE LA SCHEDA DEL GIOCATORE
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CharacterSheetScreen(character: char)));
                  },
                ),
              )),

              const SizedBox(height: 24),

              // SEZIONE AVVERSARI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AVVERSARI", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.redAccent),
                    onPressed: () => _showAddEnemyDialog(context, combat),
                  ),
                ],
              ),
              if (enemies.isEmpty) 
                const Text("Nessun nemico presente.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

              ...enemies.map((enemy) => Card(
                color: const Color(0xFFB71C1C).withOpacity(0.2),
                child: ListTile(
                  leading: const Icon(Icons.android, color: Colors.redAccent),
                  title: Text("${enemy.name} (Tier ${enemy.tier})", style: const TextStyle(color: Colors.white)),
                  subtitle: Row(
                    children: [
                      // CONTROLLI HP DIRETTI PER IL GM
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                        onPressed: () {
                           combat.modifyHp(enemy.id, -1);
                           // Auto-sync
                           List<dynamic> allActive = [...combat.activeEnemies, ...combat.activeCharacters];
                           room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                        },
                      ),
                      Text("${enemy.currentHp}/${enemy.maxHp} HP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                        onPressed: () {
                           combat.modifyHp(enemy.id, 1);
                           // Auto-sync
                           List<dynamic> allActive = [...combat.activeEnemies, ...combat.activeCharacters];
                           room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                        },
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      combat.removeAdversary(enemy.id);
                      // Auto-sync
                      List<dynamic> allActive = [...combat.activeEnemies, ...combat.activeCharacters];
                      room.syncCombatData(gm.fear, gm.actionTokens, allActive);
                    },
                  ),
                  onTap: () {
                    // IL GM APRE I DETTAGLI DEL NEMICO
                    // Dobbiamo convertire l'oggetto Adversary in Map per il dialog
                    // (Assumendo che Adversary non abbia un toJson completo, lo costruiamo al volo o usiamo toJson se c'è)
                    // Per semplicità qui passo una mappa costruita
                    showDialog(context: context, builder: (_) => AdversaryDetailsDialog(data: {
                      'name': enemy.name,
                      'tier': enemy.tier,
                      'currentHp': enemy.currentHp,
                      'maxHp': enemy.maxHp,
                      'attack': enemy.attackModifier,
                      'damage': enemy.damageOutput,
                      'difficulty': enemy.difficulty,
                      'moves': enemy.moves,
                      'gm_moves': enemy.gmMoves,
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

  void _showAddEnemyDialog(BuildContext context, CombatProvider combat) {
    // ... (Logica per aggiungere nemici dal JSON, come avevi prima o simile)
    // Se ti serve il codice per questo, dimmelo, ma credo tu lo abbia già nel DataManager
    // Per ora metto un placeholder semplice
    showModalBottomSheet(context: context, builder: (ctx) {
       final adversaries = DataManager().adversaries; // Assicurati di avere questo getter
       return ListView.builder(
         itemCount: adversaries.length,
         itemBuilder: (c, i) {
           final adv = adversaries[i];
           return ListTile(
             title: Text(adv['name']),
             subtitle: Text("Tier ${adv['tier']}"),
             onTap: () {
               // Converti JSON in Oggetto Adversary
               // Nota: qui devi avere un metodo factory fromJson nel tuo modello Adversary
               final enemyObj = Adversary.fromJson(adv); 
               enemyObj.id = DateTime.now().millisecondsSinceEpoch.toString(); // ID univoco per l'istanza
               combat.addAdversary(enemyObj);
               Navigator.pop(ctx);
             },
           );
         }
       );
    });
  }
}