import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';

class StepDerivedStats extends StatelessWidget {
  // NOTA: Il costruttore DEVE essere const
  const StepDerivedStats({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CreationProvider>(context);
    final char = provider.draftCharacter;
    final baseEvasion = provider.selectedClassData?['core_stats']['base_evasion'] ?? 10;
    final agility = char.traits['agilita'] ?? 0;
    
    final evasion = baseEvasion + agility;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("ALTRI PUNTEGGI", style: TextStyle(fontFamily: 'Cinzel', fontSize: 20, color: Color(0xFFD4AF37))),
          const SizedBox(height: 10),
          const Text(
            "In base alla tua classe e ai tratti scelti, ecco le tue statistiche iniziali.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 30),
          
          _StatRow("EVASIONE", "$evasion", "Base Classe ($baseEvasion) + Agilità ($agility)"),
          const SizedBox(height: 20),
          _StatRow("SPERANZA", "${char.hope}", "Tutti i PG iniziano con 2 Speranza"),
          const SizedBox(height: 20),
          _StatRow("STRESS", "${char.currentStress} / ${char.maxStress}", "Soglia standard. ${char.ancestryId == 'human' ? '(+1 Bonus Umano)' : ''}"),
        ],
      ),
    );
  }

  Widget _StatRow(String label, String value, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD4AF37))),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        ],
      ),
    );
  }
}