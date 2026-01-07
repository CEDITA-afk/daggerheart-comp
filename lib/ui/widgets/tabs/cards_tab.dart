import 'package:flutter/material.dart';
import '../../../data/models/character.dart';
import '../../../data/data_manager.dart';

// --- FIX: IL NOME DELLA CLASSE DEVE ESSERE CardsTab ---
class CardsTab extends StatelessWidget {
  final Character char;

  const CardsTab({super.key, required this.char});

  @override
  Widget build(BuildContext context) {
    final activeCards = char.activeCardIds
        .map((id) => DataManager().getCardById(id))
        .where((c) => c != null)
        .toList();

    if (activeCards.isEmpty) {
      return const Center(child: Text("Nessuna carta dominio attiva.", style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        childAspectRatio: 0.68, 
        crossAxisSpacing: 12, 
        mainAxisSpacing: 12
      ),
      itemCount: activeCards.length,
      itemBuilder: (context, index) {
        final card = activeCards[index]!;
        Color headerColor = _getDomainColor(card['domain'].toString());

        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF222222),
                title: Text(card['name'], style: TextStyle(color: headerColor, fontFamily: 'Cinzel')),
                content: SingleChildScrollView(
                  child: Text(card['text'], style: const TextStyle(color: Colors.white70)),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CHIUDI"))],
              )
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF222222), 
              border: Border.all(color: Colors.white24), 
              borderRadius: BorderRadius.circular(8)
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity, 
                  padding: const EdgeInsets.symmetric(vertical: 4), 
                  decoration: BoxDecoration(color: headerColor.withOpacity(0.8), borderRadius: const BorderRadius.vertical(top: Radius.circular(8))), 
                  alignment: Alignment.center, 
                  child: Text(card['domain'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), 
                    child: Column(
                      children: [
                        Text(card['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)), 
                        const Divider(color: Colors.white24), 
                        Expanded(child: SingleChildScrollView(child: Text(card['text'], style: const TextStyle(fontSize: 10, color: Colors.white70))))
                      ]
                    )
                  )
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'lame': return const Color(0xFF8B0000);
      case 'ossa': return const Color(0xFF555555);
      case 'codice': return const Color(0xFF003366);
      case 'splendore': return const Color(0xFFCC7700);
      case 'arcano': return const Color(0xFF4B0082);
      case 'valore': return const Color(0xFFA52A2A);
      case 'grazia': return const Color(0xFFC71585);
      case 'mezzanotte': return const Color(0xFF191970);
      case 'saggio': return const Color(0xFF006400);
      default: return Colors.black;
    }
  }
}