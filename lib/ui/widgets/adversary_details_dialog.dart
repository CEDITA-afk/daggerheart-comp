import 'package:flutter/material.dart';

class AdversaryDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdversaryDetailsDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Estrai i dati in sicurezza
    final name = data['name'] ?? 'Nemico';
    final tier = data['tier'] ?? 0;
    final currentHp = data['currentHp'] ?? 0;
    final maxHp = data['maxHp'] ?? 1;
    final attack = data['attack'] ?? '';
    final damage = data['damage'] ?? '';
    final difficulty = data['difficulty'] ?? 10;
    
    // Lista di mosse e tratti
    final moves = data['moves'] as List<dynamic>? ?? [];
    final gmMoves = data['gm_moves'] as List<dynamic>? ?? [];

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(Icons.android, color: Colors.redAccent, size: 40),
          const SizedBox(height: 8),
          Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontFamily: 'Cinzel', fontWeight: FontWeight.bold)),
          Text("Tier $tier • Difficoltà $difficulty", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HP BAR
              _buildSectionHeader("STATO VITALE"),
              LinearProgressIndicator(
                value: (currentHp / maxHp).clamp(0.0, 1.0),
                color: Colors.redAccent,
                backgroundColor: Colors.black,
                minHeight: 10,
              ),
              Center(child: Text("$currentHp / $maxHp HP", style: const TextStyle(color: Colors.white))),
              const SizedBox(height: 16),

              // ATTACCO
              _buildSectionHeader("ATTACCO"),
              _buildInfoRow("Modificatore:", attack),
              _buildInfoRow("Danno:", damage),
              const SizedBox(height: 16),

              // MOSSE
              if (moves.isNotEmpty) ...[
                _buildSectionHeader("MOSSE & CAPACITÀ"),
                ...moves.map((m) => _buildMoveTile(m)),
                const SizedBox(height: 16),
              ],

              // MOSSE GM
              if (gmMoves.isNotEmpty) ...[
                _buildSectionHeader("MOSSE GM (REAZIONI)"),
                ...gmMoves.map((m) => _buildMoveTile(m, isGm: true)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CHIUDI", style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMoveTile(dynamic moveData, {bool isGm = false}) {
    // Gestiamo sia stringhe che mappe (a seconda del JSON)
    String title = "";
    String desc = "";

    if (moveData is String) {
      desc = moveData;
    } else if (moveData is Map) {
      title = moveData['name'] ?? "";
      desc = moveData['description'] ?? "";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isGm ? Colors.redAccent.withOpacity(0.1) : Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isGm ? Colors.redAccent.withOpacity(0.3) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}