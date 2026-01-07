import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepTraitsAllocation extends StatelessWidget {
  const StepTraitsAllocation({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final traits = provider.draftCharacter.traits;

    // Controllo validità (somma algebrica deve essere 3 secondo lo standard array)
    int totalPoints = traits.values.fold(0, (sum, val) => sum + val);
    bool isValid = totalPoints == 3;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            "ASSEGNA I TRATTI",
            style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 5),
          const Text(
            "Distribuisci i valori: -1, 0, 0, +1, +1, +2",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: ListView(
              children: traits.keys.map((key) {
                return _TraitRow(
                  label: key, 
                  value: traits[key]!,
                  onChanged: (val) => provider.updateTrait(key, val),
                );
              }).toList(),
            ),
          ),
          
          if (!isValid)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "La somma dei tratti non corrisponde allo standard (+3 totale).",
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TraitRow extends StatelessWidget {
  final String label;
  final int value;
  final Function(int) onChanged;

  const _TraitRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => onChanged(value - 1),
                color: Colors.redAccent,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  value > 0 ? "+$value" : "$value",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => onChanged(value + 1),
                color: Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}