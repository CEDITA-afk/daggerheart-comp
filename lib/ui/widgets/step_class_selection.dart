import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/data_manager.dart';
import '../../logic/creation_provider.dart';

class StepClassSelection extends StatelessWidget {
  const StepClassSelection({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperiamo la lista delle classi dal DataManager
    final classes = DataManager().classes;
    final provider = Provider.of<CreationProvider>(context);

    if (classes.isEmpty) {
      return const Center(child: Text("Nessuna classe caricata. Controlla i JSON."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        
        // --- FIX DI SICUREZZA ---
        // Cerchiamo sia 'id' che 'class_id' per evitare crash se il JSON è misto
        final String classId = cls['id'] ?? cls['class_id'] ?? '';
        
        if (classId.isEmpty) {
          return const Card(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("ERRORE JSON: Manca la chiave 'id' in questa classe", style: TextStyle(color: Colors.red)),
          ));
        }

        // --- FILTRO COMPAGNO ---
        // Nascondiamo il "Compagno del Ranger" dalla selezione del personaggio principale
        if (classId == 'ranger_companion') {
          return const SizedBox.shrink();
        }
        // ------------------------

        final isSelected = provider.draftCharacter.classId == classId;

        return GestureDetector(
          onTap: () => provider.selectClass(classId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (cls['name'] ?? 'Sconosciuto').toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cinzel',
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      if (isSelected) 
                        const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cls['description'] ?? "Nessuna descrizione.",
                    style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  // Mostra i badge dei Domini
                  if (cls['core_stats'] != null && cls['core_stats']['primary_domains'] != null)
                    Row(
                      children: (cls['core_stats']['primary_domains'] as List)
                          .map((d) => _DomainBadge(domain: d.toString()))
                          .toList(),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DomainBadge extends StatelessWidget {
  final String domain;
  const _DomainBadge({required this.domain});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        domain.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}