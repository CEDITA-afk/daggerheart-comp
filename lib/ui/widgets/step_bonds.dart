import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepBonds extends StatelessWidget {
  const StepBonds({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final bonds = provider.selectedClassData?['narrative_prompts']['bond_questions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CREA LEGAMI", style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          const Text(
            "Scegli una domanda e discutine con il gruppo per stabilire i legami.",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          
          ...bonds.map((q) {
            if (!provider.bondControllers.containsKey(q)) {
              provider.bondControllers[q] = TextEditingController();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: provider.bondControllers[q],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(),
                      hintText: "Nome PG / Risposta...",
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}