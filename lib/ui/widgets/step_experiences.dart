import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepExperiences extends StatelessWidget {
  const StepExperiences({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("CREA LE TUE ESPERIENZE", style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          const Text(
            "Usa la storia del tuo PG per creare due esperienze iniziali (es. 'Guardia del corpo', 'Sopravvissuto'). Assegna a entrambe +2.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          
          _ExpInput(index: 1, controller: provider.experienceControllers[0]),
          const SizedBox(height: 20),
          _ExpInput(index: 2, controller: provider.experienceControllers[1]),
        ],
      ),
    );
  }
}

class _ExpInput extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  const _ExpInput({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: "Esperienza $index",
        suffixText: "+2",
        suffixStyle: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white10,
        border: const OutlineInputBorder(),
      ),
    );
  }
}