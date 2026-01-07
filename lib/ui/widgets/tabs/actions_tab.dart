import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../../data/data_manager.dart';
import '../../widgets/dice_roller_dialog.dart';

class ActionsTab extends StatefulWidget {
  final Character char;
  final Map<String, dynamic>? classData;

  const ActionsTab({super.key, required this.char, this.classData});

  @override
  State<ActionsTab> createState() => _ActionsTabState();
}

class _ActionsTabState extends State<ActionsTab> {
  @override
  Widget build(BuildContext context) {
    final char = widget.char;
    final classData = widget.classData;
    final features = classData?['class_features'] as List? ?? [];
    
    // Sottoclasse
    final subclasses = classData?['subclasses'] as List? ?? [];
    final subclassData = subclasses.firstWhere(
      (s) => s['id'] == char.subclassId, 
      orElse: () => <String, dynamic>{}
    );
    final subFeatures = subclassData['features'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- SEZIONE RANGER: COMPAGNO ---
        if (char.classId == 'ranger' && char.subclassId == 'ranger_beastbound') ...[
          _buildCompanionButton(context),
          const SizedBox(height: 20),
        ],

        // --- ARMI ---
        const Text("ARMI EQUIPAGGIATE", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        
        if (char.weapons.isEmpty) 
          const Text("Nessuna arma equipaggiata.", style: TextStyle(color: Colors.grey)),

        ...char.weapons.map((w) {
          int? damageDie;
          if (w.contains("d4")) damageDie = 4;
          else if (w.contains("d6")) damageDie = 6;
          else if (w.contains("d8")) damageDie = 8;
          else if (w.contains("d10")) damageDie = 10;
          else if (w.contains("d12")) damageDie = 12;
          else if (w.contains("d20")) damageDie = 20;

          return Card(
            color: const Color(0xFF2C2C2C),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.gavel, color: Colors.white70),
              title: Text(w, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              trailing: IconButton(
                icon: const Icon(Icons.casino, color: Colors.redAccent),
                onPressed: () => showDialog(context: context, builder: (_) => DiceRollerDialog(label: "Danni $w", startWithDamage: true, preselectedDie: damageDie)),
              ),
              onTap: () => showDialog(context: context, builder: (_) => DiceRollerDialog(label: "Attacco con $w")),
            ),
          );
        }),

        const SizedBox(height: 24),

        // --- SEZIONE DRUIDO: FORME BESTIALI ---
        if (char.classId == 'druido') ...[
          const Text("FORME BESTIALI", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          _buildDruidFormsList(classData),
          const SizedBox(height: 24),
        ],

        // --- PRIVILEGI ---
        const Text("PRIVILEGI", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        ...features.map((feat) => _buildFeatureBox(feat['name'], feat['text'])),
        if (subFeatures.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text("FONDAMENTA: ${subclassData['name'] ?? ''}".toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          ...subFeatures.map((feat) => _buildFeatureBox(feat['name'], feat['text'])),
        ]
      ],
    );
  }

  // WIDGET FORME DRUIDO
  Widget _buildDruidFormsList(Map<String, dynamic>? classData) {
    final forms = classData?['beast_forms'] as List? ?? [];
    if (forms.isEmpty) return const Text("Nessuna forma bestiale disponibile.", style: TextStyle(color: Colors.grey));

    return Column(
      children: forms.map((form) {
        return ExpansionTile(
          title: Text(form['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("Esempi: ${form['examples']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          collapsedBackgroundColor: Colors.white10,
          backgroundColor: Colors.black26,
          textColor: const Color(0xFFD4AF37),
          iconColor: const Color(0xFFD4AF37),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("STATS: ${form['stats']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: (form['traits'] as List).map((t) => Chip(label: Text(t, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact)).toList()),
                  const SizedBox(height: 8),
                  ...(form['features'] as List).map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text("• ${f['name']}: ${f['text']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  )),
                ],
              ),
            )
          ],
        );
      }).toList(),
    );
  }

  // WIDGET COMPAGNO RANGER
  Widget _buildCompanionButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)],
      ),
      child: ListTile(
        leading: const Icon(Icons.pets, color: Colors.white, size: 28),
        title: Text(widget.char.companion?['name'] ?? "COMPAGNO", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(widget.char.companion?['type'] ?? "Animale", style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.edit, color: Colors.white54),
        onTap: () => _showCompanionSheet(context),
      ),
    );
  }

  void _showCompanionSheet(BuildContext context) {
    // Usiamo un StatefulBuilder per aggiornare il dialog mentre si edita
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (c) => StatefulBuilder(
        builder: (context, setSheetState) {
          final comp = widget.char.companion ?? {};
          final currentStress = comp['currentStress'] ?? 0;
          final maxStress = comp['maxStress'] ?? 5;

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            builder: (c, s) => ListView(
              controller: s,
              padding: const EdgeInsets.all(20),
              children: [
                const Text("SCHEDA COMPAGNO", style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontFamily: 'Cinzel'), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                
                // Modifica Nome e Tipo
                Row(children: [
                  Expanded(child: _buildEditField("Nome", comp['name'], (val) => setSheetState(() => comp['name'] = val))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildEditField("Tipo", comp['type'], (val) => setSheetState(() => comp['type'] = val))),
                ]),
                const SizedBox(height: 20),

                // Stress Tracker
                const Text("STRESS", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(maxStress, (index) {
                    return IconButton(
                      icon: Icon(
                        index < currentStress ? Icons.circle : Icons.circle_outlined,
                        color: Colors.deepPurpleAccent,
                      ),
                      onPressed: () {
                        setSheetState(() {
                          if (index < currentStress) {
                            comp['currentStress'] = index; // Riduci
                          } else {
                            comp['currentStress'] = index + 1; // Aumenta
                          }
                          // IMPORTANTE: Salvare lo stato nel main char? 
                          // Qui stiamo modificando la mappa per riferimento, quindi widget.char.companion è aggiornato.
                          // Ma non è persistito su disco finché non si salva l'app o si esce.
                        });
                      },
                    );
                  }),
                ),

                const Divider(color: Colors.grey),
                const Text("AZIONI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  icon: const Icon(Icons.casino),
                  label: const Text("ATTACCO (d6)"),
                  onPressed: () {
                     Navigator.pop(context);
                     showDialog(context: context, builder: (_) => const DiceRollerDialog(label: "Attacco Compagno", startWithDamage: true, preselectedDie: 6));
                  },
                ),
              ],
            ),
          );
        }
      ),
    ).whenComplete(() {
      // Quando chiudi la scheda, forziamo un refresh della schermata principale se necessario
      setState(() {}); 
    });
  }

  Widget _buildFeatureBox(String? title, String? text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title?.toUpperCase() ?? "", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(text ?? "", style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, String? val, Function(String) onChanged) {
    return TextFormField(
      initialValue: val,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.black26),
      onChanged: onChanged,
    );
  }
}