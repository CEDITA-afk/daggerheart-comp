import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepEquipment extends StatelessWidget {
  const StepEquipment({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final loadouts = provider.selectedClassData?['creation_guide']['starting_equipment_choices'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("EQUIPAGGIAMENTO INIZIALE", style: TextStyle(fontFamily: 'Cinzel', fontSize: 18, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView.builder(
              itemCount: loadouts.length,
              itemBuilder: (context, index) {
                final loadout = loadouts[index];
                final isSelected = provider.selectedLoadoutIndex == index;
                
                return GestureDetector(
                  onTap: () => provider.selectLoadout(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2A2A2A) : const Color(0xFF1E1E1E),
                      border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: provider.selectedLoadoutIndex,
                              activeColor: const Color(0xFFD4AF37),
                              onChanged: (val) => provider.selectLoadout(val!),
                            ),
                            Text(loadout['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        ...(loadout['items'] as List).map((item) => Padding(
                          padding: const EdgeInsets.only(left: 40, bottom: 4),
                          child: Text("• ${item['name']}", style: const TextStyle(color: Colors.white70)),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}