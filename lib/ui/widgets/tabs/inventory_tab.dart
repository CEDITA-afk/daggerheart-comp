import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../../data/data_manager.dart';

class InventoryTab extends StatefulWidget {
  final Character char;
  const InventoryTab({super.key, required this.char});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  @override
  Widget build(BuildContext context) {
    final char = widget.char;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- SEZIONE ORO ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade700),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(children: [Icon(Icons.monetization_on, color: Colors.amber), SizedBox(width: 10), Text("ORO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber))]),
              Row(children: [
                IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => setState(() { if(char.gold > 0) char.gold--; })),
                Text("${char.gold}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.greenAccent), onPressed: () => setState(() { char.gold++; })),
              ])
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- SEZIONE 1: EQUIPAGGIAMENTO ATTIVO ---
        const Text("EQUIPAGGIAMENTO ATTIVO", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        
        // 1a. Armatura Attiva
        if (char.armorName.isNotEmpty)
          Card(
            color: const Color(0xFF2E3B2F), // Verde scuro per indicare "Attivo"
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.green, width: 1), borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              leading: const Icon(Icons.shield, color: Colors.greenAccent),
              title: Text(char.armorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("Score: ${char.armorScore} | Evasione: ${char.evasionModifier > 0 ? '+' : ''}${char.evasionModifier}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              trailing: Checkbox(
                value: true,
                activeColor: Colors.green,
                onChanged: (val) => _unequipArmor(),
              ),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text("Nessuna armatura indossata.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          ),

        // 1b. Armi Attive
        ...char.weapons.map((w) => Card(
          color: const Color(0xFF2E3B2F),
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.green, width: 1), borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const Icon(Icons.gavel, color: Colors.greenAccent),
            title: Text(w, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Pronta all'uso", style: TextStyle(color: Colors.white70, fontSize: 12)),
            trailing: Checkbox(
              value: true,
              activeColor: Colors.green,
              onChanged: (val) => _unequipWeapon(w),
            ),
          ),
        )),

        const SizedBox(height: 24),

        // --- SEZIONE 2: ZAINO (Items non equipaggiati) ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("ZAINO", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: () => _showAddItemDialog(context)),
          ],
        ),
        
        if (char.inventory.isEmpty)
          const Text("Lo zaino è vuoto.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

        ...char.inventory.map((itemString) {
          final parts = itemString.split('|');
          final name = parts[0];
          final desc = parts.length > 1 ? parts[1] : "";
          
          // Cerchiamo di capire se è equipaggiabile per mostrare la checkbox
          bool isEquippable = _isEquippable(name);

          return Card(
            color: Colors.white10,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(name, style: const TextStyle(color: Colors.white)),
              subtitle: desc.isNotEmpty ? Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 10)) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox Equipaggia (solo se ha senso equipaggiarlo)
                  if (isEquippable) 
                    Checkbox(
                      value: false,
                      checkColor: Colors.black,
                      fillColor: MaterialStateProperty.resolveWith((states) => Colors.grey),
                      onChanged: (val) => _equipItemFromInventory(itemString),
                    ),
                  // Tasto Cancella
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white30),
                    onPressed: () => setState(() => char.inventory.remove(itemString)),
                  ),
                ],
              ),
            ),
          );
        }),
        
        // Spazio extra in fondo per il FAB
        const SizedBox(height: 80),
      ],
    );
  }

  // --- LOGICA EQUIPAGGIAMENTO ---

  // 1. Equipaggia dallo zaino
  void _equipItemFromInventory(String itemString) {
    final char = widget.char;
    final parts = itemString.split('|');
    final name = parts[0];
    
    // Recupera stats dal DB o indovina
    final stats = _getStats(name);
    final type = stats['type'];

    setState(() {
      // Rimuovi dallo zaino
      char.inventory.remove(itemString);

      if (type == 'armor') {
        // Se c'è già un'armatura, rimettila nello zaino
        if (char.armorName.isNotEmpty) {
          _unequipArmor(updateState: false); // Non chiamare setState qui dentro perché siamo già in setState
        }
        // Indossa la nuova
        char.armorName = name;
        char.armorScore = stats['score'] ?? 0;
        char.evasionModifier = stats['evasion'] ?? 0;
      } 
      else if (type == 'weapon') {
        // Aggiungi alle armi (mantenendo eventuali note sui danni se presenti nel nome originale o nel DB)
        // Se nel DB c'è un danno specifico, potremmo formattarlo tipo "Spada (d8)"
        String weaponEntry = name;
        if (stats['damage'] != null && !name.contains("d")) {
           weaponEntry = "$name (d${stats['damage']})";
        }
        char.weapons.add(weaponEntry);
      }
      else if (type == 'shield') {
        // Scudi: Aggiungi all'inventario ma applica bonus (Daggerheart tratta scudi come oggetti, ma attivi)
        // O meglio: Trattiamoli come "Armi/Secondarie" o teniamoli nello zaino ma attivi?
        // Per semplicità UI: li mettiamo tra le "Armi" per vederli attivi, oppure solo update stats.
        // Soluzione ibrida: Lo mettiamo in inventory (perché non si attacca con lo scudo di solito) 
        // MA aggiorniamo stats. PERO' qui stiamo muovendo fuori dallo zaino.
        // Mettiamolo in weapons per vederlo "Attivo"
        char.armorScore += (stats['score'] as int? ?? 0);
        char.evasionModifier += (stats['evasion'] as int? ?? 0);
        char.weapons.add("$name (Scudo)");
      }
    });
  }

  // 2. Togli Armatura
  void _unequipArmor({bool updateState = true}) {
    final char = widget.char;
    // Crea stringa per zaino
    String itemEntry = char.armorName;
    // Cerchiamo descrizione originale se possibile, altrimenti generica
    var data = DataManager().getItemStats(char.armorName);
    if (data != null && data['desc'] != null) {
      itemEntry += "|${data['desc']}";
    }

    void logic() {
      char.inventory.add(itemEntry);
      char.armorName = "";
      char.armorScore = 0;
      char.evasionModifier = 0;
    }

    if (updateState) setState(logic); else logic();
  }

  // 3. Togli Arma
  void _unequipWeapon(String weaponName) {
    final char = widget.char;
    
    // Logica speciale per Scudi (se li abbiamo messi in weapons)
    if (weaponName.contains("(Scudo)")) {
       String realName = weaponName.replaceAll(" (Scudo)", "").trim();
       var stats = _getStats(realName);
       char.armorScore -= (stats['score'] as int? ?? 0);
       char.evasionModifier -= (stats['evasion'] as int? ?? 0);
       // Pulisce nome
       weaponName = realName;
    }

    setState(() {
      char.weapons.remove(widget.char.weapons.firstWhere((w) => w == weaponName, orElse: () => weaponName));
      
      // Cerca descrizione per rimettere nello zaino
      String cleanName = weaponName.split('(')[0].trim(); // Rimuove "(d8)" se presente
      var data = DataManager().getItemStats(cleanName);
      String entry = weaponName; // Usa nome completo come fallback
      if (data != null) {
        entry = "${data['name']}|${data['desc']}";
      } else {
        // Se non trovato, usa quello che abbiamo
        entry = cleanName; 
      }
      
      char.inventory.add(entry);
    });
  }

  // --- HELPERS STATISTICHE ---
  
  bool _isEquippable(String name) {
    var s = _getStats(name);
    return s['type'] == 'armor' || s['type'] == 'weapon' || s['type'] == 'shield';
  }

  Map<String, dynamic> _getStats(String name) {
    // 1. Cerca nel DB
    var dbStats = DataManager().getItemStats(name);
    if (dbStats != null) return dbStats;

    // 2. Fallback (Indovina dal nome)
    String lower = name.toLowerCase();
    if (lower.contains('scudo')) return {'type': 'shield', 'score': 1, 'evasion': lower.contains('torre') ? -1 : 0};
    if (lower.contains('piastre')) return {'type': 'armor', 'score': 6, 'evasion': -2};
    if (lower.contains('maglia')) return {'type': 'armor', 'score': 4, 'evasion': -1};
    if (lower.contains('gambesone')) return {'type': 'armor', 'score': 3, 'evasion': 1};
    if (lower.contains('cuoio') || lower.contains('pelle')) return {'type': 'armor', 'score': 2, 'evasion': 0};
    
    if (lower.contains('spada') || lower.contains('arco') || lower.contains('pugnale') || lower.contains('ascia') || lower.contains('martello')) {
      return {'type': 'weapon'};
    }

    return {'type': 'item'}; // Default
  }

  // --- DIALOG AGGIUNTA (Invariato ma incluso per completezza) ---
  void _showAddItemDialog(BuildContext context) {
    final commonItems = DataManager().commonItems;
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          backgroundColor: const Color(0xFF222222),
          title: const Text("Aggiungi Oggetto", style: TextStyle(color: Colors.white)),
          content: SizedBox(
            height: 400,
            width: double.maxFinite,
            child: Column(
              children: [
                const TabBar(labelColor: Color(0xFFD4AF37), unselectedLabelColor: Colors.grey, indicatorColor: Color(0xFFD4AF37), tabs: [Tab(text: "LISTA"), Tab(text: "CREA")]),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.separated(
                        itemCount: commonItems.length,
                        separatorBuilder: (_,__) => const Divider(color: Colors.white10, height: 1),
                        itemBuilder: (ctx, i) {
                          final item = commonItems[i];
                          return ListTile(
                            title: Text(item['name'], style: const TextStyle(color: Colors.white)),
                            subtitle: Text(item['desc'], style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1),
                            onTap: () { setState(() => widget.char.inventory.add("${item['name']}|${item['desc']}")); Navigator.pop(context); },
                          );
                        },
                      ),
                      SingleChildScrollView(
                        child: Column(children: [
                          const SizedBox(height: 20),
                          TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nome", filled: true, fillColor: Colors.black26)),
                          const SizedBox(height: 10),
                          TextField(controller: descCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Descrizione", filled: true, fillColor: Colors.black26)),
                          const SizedBox(height: 20),
                          ElevatedButton(onPressed: (){ if(nameCtrl.text.isNotEmpty) { setState(() => widget.char.inventory.add("${nameCtrl.text}|${descCtrl.text}")); Navigator.pop(context); } }, child: const Text("AGGIUNGI"))
                        ]),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}