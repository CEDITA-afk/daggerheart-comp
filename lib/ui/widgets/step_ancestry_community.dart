import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/data_manager.dart';
import '../../logic/creation_provider.dart';

class StepAncestryCommunity extends StatelessWidget {
  const StepAncestryCommunity({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final ancestries = DataManager().ancestries;
    final communities = DataManager().communities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SEZIONE RETAGGIO (RAZZA) ---
          const Text(
            "SCEGLI IL TUO RETAGGIO",
            style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 5),
          const Text(
            "Da quale stirpe provieni?",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 15),
          
          if (ancestries.isEmpty)
            const Text("Nessun retaggio caricato.", style: TextStyle(color: Colors.red)),

          ...ancestries.map((ancestry) {
            final isSelected = provider.draftCharacter.ancestryId == ancestry['id'];
            // Recuperiamo la lista delle features
            final List features = ancestry['features'] as List? ?? [];

            return GestureDetector(
              onTap: () => provider.selectAncestry(ancestry['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 8)] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ancestry['name'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(ancestry['description'], style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                    
                    // --- MOSTRA TUTTE LE ABILITÀ ---
                    if (features.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 20),
                      ...features.map((feat) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(color: Color(0xFFD4AF37))),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                                  children: [
                                    TextSpan(text: "${feat['name']}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    TextSpan(text: feat['text']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ]
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 30),

          // --- SEZIONE COMUNITÀ (Logica identica per completezza) ---
          const Text(
            "SCEGLI LA TUA COMUNITÀ",
            style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(height: 15),

          ...communities.map((community) {
            final isSelected = provider.draftCharacter.communityId == community['id'];
            final List features = community['features'] as List? ?? [];

            return GestureDetector(
              onTap: () => provider.selectCommunity(community['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          community['name'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(community['description'], style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                    
                    if (features.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 20),
                      ...features.map((feat) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                            children: [
                              TextSpan(text: "• ${feat['name']}: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              TextSpan(text: feat['text']),
                            ],
                          ),
                        ),
                      )).toList(),
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