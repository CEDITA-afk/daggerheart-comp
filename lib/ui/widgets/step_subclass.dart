import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepSubclass extends StatelessWidget {
  const StepSubclass({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final classData = provider.selectedClassData;

    if (classData == null || classData['subclasses'] == null) {
      return const Center(
        child: Text("Seleziona prima una classe valida.", style: TextStyle(color: Colors.grey)),
      );
    }

    final subclasses = classData['subclasses'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SOTTOCLASSE - ${classData['name'].toString().toUpperCase()}",
            style: const TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 10),
          const Text(
            "Scegli la tua specializzazione (Fondamenta).",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),

          ...subclasses.map((sub) {
            final isSelected = provider.draftCharacter.subclassId == sub['id'];
            final features = sub['features'] as List? ?? [];

            return GestureDetector(
              onTap: () => provider.selectSubclass(sub['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 10)] 
                      : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sub['name'].toString().toUpperCase(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sub['description'] ?? "",
                      style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    ...features.map((feat) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.white60),
                          children: [
                            TextSpan(text: "• ${feat['name']}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            TextSpan(text: feat['text']),
                          ],
                        ),
                      ),
                    )),

                    // --- SEZIONE MODIFICA COMPAGNO (Solo Ranger Bestiale) ---
                    if (isSelected && sub['id'] == 'ranger_beastbound') ...[
                      const Divider(color: Color(0xFFD4AF37), height: 30),
                      const Text("PERSONALIZZA COMPAGNO", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: provider.draftCharacter.companion?['name'],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Nome Compagno",
                          filled: true, fillColor: Colors.black45,
                          border: OutlineInputBorder()
                        ),
                        onChanged: (val) => provider.draftCharacter.companion?['name'] = val,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: provider.draftCharacter.companion?['type'],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Tipo di Animale (es. Lupo, Orso)",
                          filled: true, fillColor: Colors.black45,
                          border: OutlineInputBorder()
                        ),
                        onChanged: (val) => provider.draftCharacter.companion?['type'] = val,
                      ),
                    ]
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}