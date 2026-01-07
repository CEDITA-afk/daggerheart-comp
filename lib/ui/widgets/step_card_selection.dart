import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepCardSelection extends StatelessWidget {
  const StepCardSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final cards = provider.availableCards; // Filtrate nel provider in base alla classe

    if (cards.isEmpty) {
      return const Center(child: Text("Nessuna carta disponibile per questa classe."));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                "SCEGLI LE TUE CARTE",
                style: const TextStyle(fontSize: 18, fontFamily: 'Cinzel', color: Color(0xFFD4AF37)),
              ),
              Text(
                "Selezionate: ${provider.draftCharacter.activeCardIds.length} / 2",
                style: TextStyle(
                  color: provider.draftCharacter.activeCardIds.length == 2 
                      ? Colors.green 
                      : Colors.white70,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 carte per riga
              childAspectRatio: 0.65, // Formato carta verticale
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final isSelected = provider.draftCharacter.activeCardIds.contains(card['id']);

              return GestureDetector(
                onTap: () => provider.toggleCardSelection(card['id']),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.grey.shade800,
                      width: isSelected ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected 
                      ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8)] 
                      : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Carta (Colore del Dominio)
                      Container(
                        height: 25,
                        decoration: BoxDecoration(
                          color: _getDomainColor(card['domain'].toString()),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          card['domain'].toString().toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 10, 
                            color: Colors.white
                          ),
                        ),
                      ),
                      // Corpo Carta
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                card['name'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Divider(color: Colors.white24, thickness: 0.5),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    card['text'] ?? "", 
                                    style: const TextStyle(fontSize: 9, color: Colors.white70),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper per colorare l'intestazione della carta
  Color _getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'lame': return const Color(0xFF8B0000); // Rosso Scuro
      case 'ossa': return const Color(0xFF555555); // Grigio
      case 'codice': return const Color(0xFF003366); // Blu Scuro
      case 'splendore': return const Color(0xFFCC7700); // Ambra/Oro
      case 'arcano': return const Color(0xFF4B0082); // Indaco/Viola
      case 'valore': return const Color(0xFFA52A2A); // Marrone/Rosso
      case 'grazia': return const Color(0xFFC71585); // Rosa Scuro
      case 'mezzanotte': return const Color(0xFF191970); // Blu Notte
      case 'saggio': return const Color(0xFF006400); // Verde Scuro
      default: return Colors.black;
    }
  }
}