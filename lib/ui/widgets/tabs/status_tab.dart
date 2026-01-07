import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../widgets/dice_roller_dialog.dart';
import '../rest_dialog.dart'; // <--- Importa il nuovo widget

class StatusTab extends StatefulWidget {
  final Character char;

  const StatusTab({super.key, required this.char});

  @override
  State<StatusTab> createState() => _StatusTabState();
}

class _StatusTabState extends State<StatusTab> {
  // Funzione per mostrare il dialogo del riposo breve
  void _showShortRest() {
    showDialog(
      context: context,
      builder: (context) => RestDialog(
        character: widget.char,
        onConfirm: (summary) {
          setState(() {}); // Aggiorna la UI coi nuovi valori
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Riposo completato:\n$summary"), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  // Funzione per il riposo lungo (Reset Totale)
  void _performLongRest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("RIPOSO LUNGO", style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text(
          "Questo ripristinerà completamente PF, Stress, Armatura e Speranza.\nSei sicuro?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("ANNULLA", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text("RIPOSA", style: TextStyle(color: Colors.black)),
            onPressed: () {
              setState(() {
                widget.char.currentHp = widget.char.maxHp;
                widget.char.currentStress = 0;
                widget.char.armorSlotsUsed = 0;
                widget.char.hope = 2; // O il massimo, ma di solito si resetta a 2
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sei completamente riposato!"), backgroundColor: Colors.green),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- SEZIONE RIPOSO (NUOVA) ---
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.coffee, size: 20, color: Colors.amberAccent),
                label: const Text("RIPOSO BREVE", style: TextStyle(color: Colors.white)),
                onPressed: _showShortRest,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[900],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.bed, size: 20, color: Colors.white),
                label: const Text("RIPOSO LUNGO", style: TextStyle(color: Colors.white)),
                onPressed: _performLongRest,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // --- SALUTE (HP) ---
        _buildSectionHeader("PUNTI FERITA"),
        const SizedBox(height: 10),
        _buildHpBar(),

        const SizedBox(height: 24),

        // --- STRESS ---
        _buildSectionHeader("STRESS"),
        const SizedBox(height: 10),
        _buildStressTracker(),

        const SizedBox(height: 24),

        // --- ARMATURA ---
        _buildSectionHeader("ARMATURA"),
        const SizedBox(height: 10),
        _buildArmorTracker(),
      ],
    );
  }

  // WIDGET HELPERS (Invariati o leggermente puliti)

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 18,
        color: Color(0xFFD4AF37),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildHpBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
              onPressed: () => setState(() {
                if (widget.char.currentHp > 0) widget.char.currentHp--;
              }),
            ),
            Text(
              "${widget.char.currentHp} / ${widget.char.maxHp}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              onPressed: () => setState(() {
                if (widget.char.currentHp < widget.char.maxHp) widget.char.currentHp++;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: widget.char.currentHp / widget.char.maxHp,
          backgroundColor: Colors.grey[800],
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.char.currentHp <= 2 ? Colors.red : Colors.green,
          ),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildStressTracker() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.char.maxStress, (index) {
            bool isFilled = index < widget.char.currentStress;
            return GestureDetector(
              onTap: () => setState(() {
                // Toggle logica: se clicchi su uno pieno, scendi a quello. Se vuoto, sali.
                if (isFilled && index == widget.char.currentStress - 1) {
                   widget.char.currentStress--;
                } else {
                   widget.char.currentStress = index + 1;
                }
              }),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isFilled ? Colors.deepPurpleAccent : Colors.transparent,
                  border: Border.all(color: Colors.deepPurpleAccent, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isFilled ? const Icon(Icons.close, size: 20, color: Colors.white) : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          "${widget.char.currentStress} / ${widget.char.maxStress} Stress",
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildArmorTracker() {
    int maxSlots = widget.char.armorScore; 
    // Fallback se l'armatura non ha score (es. 0), mostriamo almeno 1 slot o gestiamo diversamente
    if (maxSlots == 0) return const Text("Nessuna armatura equipaggiata.", style: TextStyle(color: Colors.grey));

    return Column(
      children: [
        Text(widget.char.armorName.isNotEmpty ? widget.char.armorName : "Armatura Base", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(maxSlots, (index) {
            bool isBroken = index < widget.char.armorSlotsUsed;
            return GestureDetector(
              onTap: () => setState(() {
                if (isBroken && index == widget.char.armorSlotsUsed - 1) {
                  widget.char.armorSlotsUsed--;
                } else {
                  widget.char.armorSlotsUsed = index + 1;
                }
              }),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isBroken ? Colors.grey[900] : Colors.blueGrey,
                  border: Border.all(color: isBroken ? Colors.red : Colors.white70),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isBroken ? Icons.broken_image : Icons.shield,
                  color: isBroken ? Colors.red : Colors.white,
                  size: 20,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        const Text("Tocca per rompere/riparare slot", style: TextStyle(color: Colors.white30, fontSize: 10)),
      ],
    );
  }
}