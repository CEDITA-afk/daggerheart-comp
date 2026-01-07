import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepBackground extends StatelessWidget {
  const StepBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final questions = provider.selectedClassData?['narrative_prompts']['background_questions'] as List? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CHI È IL TUO EROE?", style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Color(0xFFD4AF37))),
          const SizedBox(height: 15),
          
          _TextInput(label: "Nome del Personaggio", controller: provider.nameController),
          const SizedBox(height: 15),
          _TextInput(label: "Pronomi", controller: provider.pronounsController),
          const SizedBox(height: 15),
          _TextInput(label: "Descrizione Fisica (Occhi, Abiti...)", controller: provider.descriptionController, maxLines: 3),
          
          const SizedBox(height: 30),
          const Text("DOMANDE DI BACKGROUND", style: TextStyle(fontFamily: 'Cinzel', fontSize: 16, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          
          ...questions.map((q) {
            // Crea un controller se non esiste per questa domanda
            if (!provider.backgroundControllers.containsKey(q)) {
              provider.backgroundControllers[q] = TextEditingController();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: provider.backgroundControllers[q],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(),
                      hintText: "Scrivi la tua risposta...",
                    ),
                    maxLines: 2,
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

class _TextInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  const _TextInput({required this.label, required this.controller, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }
}