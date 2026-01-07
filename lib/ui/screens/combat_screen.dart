import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/combat_provider.dart';
import '../../data/models/adversary.dart';
import '../../data/data_manager.dart'; // <--- Import necessario
import '../widgets/dice_roller_dialog.dart';

class CombatScreen extends StatelessWidget {
  const CombatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ... (Codice Appbar e Body identico a prima, cambia solo la chiamata al dialog)
    // Quando premi FAB o bottone vuoto:
    // onPressed: () => _showAddEnemyDialog(context),
    return Scaffold(
        // ... (Appbar e Body come nel codice precedente) ...
        appBar: AppBar(
        title: const Text("COMBAT TRACKER", style: TextStyle(fontFamily: 'Cinzel', color: Colors.redAccent)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => Provider.of<CombatProvider>(context, listen: false).clearCombat(),
          )
        ],
      ),
      body: Consumer<CombatProvider>(
        builder: (context, combat, child) {
          if (combat.activeEnemies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Nessun avversario presente.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                    icon: const Icon(Icons.add),
                    label: const Text("AGGIUNGI NEMICO"),
                    onPressed: () => _showAddEnemyDialog(context),
                  )
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: combat.activeEnemies.length,
            itemBuilder: (context, index) {
              final enemy = combat.activeEnemies[index];
              return _buildEnemyCard(context, combat, enemy);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEnemyDialog(context),
      ),
    );
  }

  // ... (Widget _buildEnemyCard e _circleBtn restano uguali, aggiungi features se vuoi) ...
  Widget _buildEnemyCard(BuildContext context, CombatProvider combat, Adversary enemy) {
      // (Usa il codice della risposta precedente per la card, 
      //  ma puoi aggiungere enemy.thresholds sotto la difficoltà se vuoi)
      return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: enemy.currentHp == 0 ? Colors.grey : Colors.redAccent.withOpacity(0.5), 
          width: 1
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(enemy.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text("Dif: ${enemy.difficulty} • ${enemy.thresholds} • ${enemy.tier}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => combat.removeAdversary(enemy.id),
                )
              ],
            ),
            const Divider(color: Colors.white24),
            // STATS
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      _circleBtn(Icons.remove, Colors.red, () => combat.modifyHp(enemy.id, -1)),
                      const SizedBox(width: 8),
                      Text(
                        "${enemy.currentHp}/${enemy.maxHp}",
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: enemy.currentHp == 0 ? Colors.red : Colors.greenAccent
                        )
                      ),
                      const SizedBox(width: 8),
                      _circleBtn(Icons.add, Colors.green, () => combat.modifyHp(enemy.id, 1)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    icon: const Icon(Icons.casino, size: 16, color: Colors.amber),
                    label: Text("${enemy.attackName} (+${enemy.attackMod})", style: const TextStyle(fontSize: 11, color: Colors.white)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => DiceRollerDialog(label: "Attacco di ${enemy.name}")
                      );
                    },
                  ),
                ),
              ],
            ),
             // Features Espandibili (Opzionale)
            if (enemy.features.isNotEmpty)
              ExpansionTile(
                title: const Text("Capacità", style: TextStyle(fontSize: 12, color: Colors.white70)),
                children: enemy.features.map((f) => ListTile(
                  title: Text(f.name, style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  subtitle: Text(f.text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // --- NUOVO DIALOGO ---
  void _showAddEnemyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEnemyDialog(),
    );
  }
}

class AddEnemyDialog extends StatefulWidget {
  const AddEnemyDialog({super.key});

  @override
  State<AddEnemyDialog> createState() => _AddEnemyDialogState();
}

class _AddEnemyDialogState extends State<AddEnemyDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Variabili per Libreria
  String selectedCampaign = "Tutti";
  List<String> campaigns = ["Tutti"];
  
  // Variabili per Manuale
  final nameCtrl = TextEditingController();
  final hpCtrl = TextEditingController(text: "10");
  final diffCtrl = TextEditingController(text: "10");
  final atkCtrl = TextEditingController(text: "0");
  final dmgCtrl = TextEditingController(text: "d6");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Carica campagne disponibili
    final allCampaigns = DataManager().getAdversaryCampaigns();
    if (allCampaigns.isNotEmpty) {
      campaigns.addAll(allCampaigns);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2C),
      contentPadding: EdgeInsets.zero,
      title: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFD4AF37),
        labelColor: const Color(0xFFD4AF37),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: "LIBRERIA"),
          Tab(text: "MANUALE"),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Altezza fissa per il contenuto
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLibraryTab(),
            _buildManualTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryTab() {
    // Filtra la lista
    List<Adversary> enemies = DataManager().getAdversariesByCampaign(selectedCampaign);

    return Column(
      children: [
        // Filtro Campagna
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<String>(
            value: selectedCampaign,
            dropdownColor: Colors.grey[850],
            decoration: const InputDecoration(
              labelText: "Filtra per Campagna",
              filled: true, fillColor: Colors.black26
            ),
            style: const TextStyle(color: Colors.white),
            items: campaigns.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) {
              setState(() {
                selectedCampaign = val!;
              });
            },
          ),
        ),
        
        // Lista Mostri
        Expanded(
          child: ListView.separated(
            itemCount: enemies.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, color: Colors.white10),
            itemBuilder: (ctx, i) {
              final adv = enemies[i];
              return ListTile(
                title: Text(adv.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text("Dif ${adv.difficulty} • HP ${adv.maxHp} • ${adv.tier}", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                  onPressed: () {
                    // Crea una COPIA dell'avversario per il combattimento
                    // (Importante: Adversary.fromJson crea un nuovo ID)
                    // Qui usiamo un trick: serializziamo e deserializziamo per clonare
                    final clone = Adversary.fromJson(
                      {
                        'name': adv.name,
                        'campaign': adv.campaign,
                        'tier': adv.tier,
                        'description': adv.description,
                        'maxHp': adv.maxHp,
                        'difficulty': adv.difficulty,
                        'attack_name': adv.attackName,
                        'attack_mod': adv.attackMod,
                        'damage_dice': adv.damageDice,
                        'thresholds': adv.thresholds,
                        // Feature manual mapping if needed usually works via helper
                      }
                    );
                    // Copia manuale delle features se il fromJson semplificato sopra non basta
                    clone.features = adv.features; 
                    
                    Provider.of<CombatProvider>(context, listen: false).addAdversary(clone);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _inputField("Nome", nameCtrl),
          Row(
            children: [
              Expanded(child: _inputField("HP Max", hpCtrl, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _inputField("Difficoltà", diffCtrl, isNum: true)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _inputField("Mod. Attacco", atkCtrl, isNum: true)),
              const SizedBox(width: 10),
              Expanded(child: _inputField("Dadi Danno", dmgCtrl)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), minimumSize: const Size(double.infinity, 50)),
            child: const Text("AGGIUNGI MANUALE", style: TextStyle(color: Colors.black)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Provider.of<CombatProvider>(context, listen: false).addAdversary(
                  Adversary(
                    name: nameCtrl.text,
                    maxHp: int.tryParse(hpCtrl.text) ?? 10,
                    difficulty: int.tryParse(diffCtrl.text) ?? 10,
                    attackMod: int.tryParse(atkCtrl.text) ?? 0,
                    damageDice: dmgCtrl.text,
                  )
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.black26,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}