import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/character.dart';

class RestDialog extends StatefulWidget {
  final Character character;
  final Function(String summary) onConfirm;

  const RestDialog({super.key, required this.character, required this.onConfirm});

  @override
  State<RestDialog> createState() => _RestDialogState();
}

class _RestDialogState extends State<RestDialog> {
  // Teniamo traccia di quante volte è stata selezionata ogni opzione
  int selectionsLeft = 2;
  Map<String, int> counts = {
    'heal': 0,    // Curare Ferite
    'stress': 0,  // Pulire Stress
    'armor': 0,   // Riparare Armatura
    'hope': 0,    // Prepararsi
  };

  void _toggleSelection(String key) {
    setState(() {
      if (counts[key]! > 0) {
        // Deseleziona
        counts[key] = counts[key]! - 1;
        selectionsLeft++;
      } else if (selectionsLeft > 0) {
        // Seleziona (se abbiamo azioni disponibili)
        counts[key] = counts[key]! + 1;
        selectionsLeft--;
      }
    });
  }

  void _applyRest() {
    List<String> logs = [];
    final rand = Random();
    int tier = 0; // Per ora Tier 0, in futuro puoi calcolarlo (lvl 1-4 = Tier 0)

    // 1. CURARE FERITE (1d4 + Tier PF)
    if (counts['heal']! > 0) {
      for (int i = 0; i < counts['heal']!; i++) {
        int roll = rand.nextInt(4) + 1;
        int total = roll + tier;
        int oldHp = widget.character.currentHp;
        widget.character.currentHp = min(widget.character.maxHp, widget.character.currentHp + total);
        logs.add("Guariti ${widget.character.currentHp - oldHp} PF (tiro: $roll)");
      }
    }

    // 2. PULIRE STRESS (1d4 + Tier Stress)
    if (counts['stress']! > 0) {
      for (int i = 0; i < counts['stress']!; i++) {
        int roll = rand.nextInt(4) + 1;
        int total = roll + tier;
        int oldStress = widget.character.currentStress;
        widget.character.currentStress = max(0, widget.character.currentStress - total);
        logs.add("Rimossi ${oldStress - widget.character.currentStress} Stress (tiro: $roll)");
      }
    }

    // 3. RIPARARE ARMATURA (1d4 + Tier Slot)
    if (counts['armor']! > 0) {
      for (int i = 0; i < counts['armor']!; i++) {
        int roll = rand.nextInt(4) + 1;
        int total = roll + tier;
        int oldArmor = widget.character.armorSlotsUsed;
        widget.character.armorSlotsUsed = max(0, widget.character.armorSlotsUsed - total);
        logs.add("Riparati ${oldArmor - widget.character.armorSlotsUsed} slot Armatura (tiro: $roll)");
      }
    }

    // 4. PREPARARSI (+1 Speranza)
    if (counts['hope']! > 0) {
      for (int i = 0; i < counts['hope']!; i++) {
        widget.character.hope++;
        logs.add("Guadagnata 1 Speranza");
      }
    }

    widget.onConfirm(logs.join("\n"));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text("RIPOSO BREVE", style: TextStyle(color: Color(0xFFD4AF37), fontFamily: 'Cinzel')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Scegli $selectionsLeft azioni da compiere:",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _buildOption('heal', "Curare Ferite", "1d4 PF", Icons.favorite),
          _buildOption('stress', "Pulire Stress", "-1d4 Stress", Icons.self_improvement),
          _buildOption('armor', "Riparare Armatura", "-1d4 Slot", Icons.shield),
          _buildOption('hope', "Prepararsi", "+1 Speranza", Icons.star),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ANNULLA", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
          onPressed: selectionsLeft == 0 ? _applyRest : null,
          child: const Text("COMPLETA RIPOSO", style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildOption(String key, String title, String subtitle, IconData icon) {
    bool isSelected = counts[key]! > 0;
    // Disabilita se non selezionato e non ci sono più scelte
    bool isDisabled = !isSelected && selectionsLeft == 0;

    return GestureDetector(
      onTap: isDisabled ? null : () => _toggleSelection(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.white10,
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDisabled ? Colors.grey : (isSelected ? const Color(0xFFD4AF37) : Colors.white70)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: isDisabled ? Colors.grey : Colors.white, 
                    fontWeight: FontWeight.bold
                  )),
                  Text(subtitle, style: TextStyle(color: isDisabled ? Colors.white12 : Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
          ],
        ),
      ),
    );
  }
}