import 'package:flutter/material.dart';
import '../../logic/dice_roller.dart';

class DiceRollerDialog extends StatefulWidget {
  final int modifier;
  final String label;
  final bool startWithDamage; // Se true, apre direttamente la tab dei dadi standard
  final int? preselectedDie;  // Es. 8 per preselezionare il d8

  const DiceRollerDialog({
    super.key, 
    this.modifier = 0, 
    this.label = "Tiro",
    this.startWithDamage = false,
    this.preselectedDie,
  });

  @override
  State<DiceRollerDialog> createState() => _DiceRollerDialogState();
}

class _DiceRollerDialogState extends State<DiceRollerDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Stato Dualità
  DualityRoll? _dualityResult;
  
  // Stato Dadi Standard
  List<int> _rollHistory = [];
  int _standardTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.startWithDamage) {
      _tabController.index = 1; // Vai alla tab Dadi
      if (widget.preselectedDie != null) {
        _rollStandard(widget.preselectedDie!); // Tira subito se richiesto
      }
    }
  }

  void _rollDuality() {
    setState(() {
      _dualityResult = DiceRoller.rollDuality(widget.modifier);
    });
  }

  void _rollStandard(int sides) {
    int result = DiceRoller.rollGeneric(sides, 1);
    setState(() {
      _rollHistory.add(result);
      _standardTotal += result;
    });
  }

  void _clearStandard() {
    setState(() {
      _rollHistory.clear();
      _standardTotal = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcoliamo un'altezza fissa (70% dello schermo) per evitare conflitti di layout
    final double dialogHeight = MediaQuery.of(context).size.height * 0.7;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // Usiamo SizedBox per forzare le dimensioni ed evitare l'errore "RenderIntrinsicWidth"
      child: SizedBox(
        height: dialogHeight,
        width: double.maxFinite, // Occupa la larghezza standard del Dialog
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text(
                widget.label.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Cinzel', 
                  color: Color(0xFFD4AF37), 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Tabs Header
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD4AF37),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: "DUALITÀ"),
                Tab(text: "DADI & DANNI"),
              ],
            ),

            // Contenuto Tabs
            // Ora Expanded funziona perché il padre (SizedBox) ha un'altezza definita
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDualityTab(),
                  _buildStandardTab(),
                ],
              ),
            ),
            
            // Footer con pulsante Chiudi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("CHIUDI", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: DUALITÀ ---
  Widget _buildDualityTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_dualityResult != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDieDisplay(_dualityResult!.hopeDie, const Color(0xFFD4AF37), "Speranza"),
                  const SizedBox(width: 20),
                  _buildDieDisplay(_dualityResult!.fearDie, Colors.deepPurpleAccent, "Paura"),
                ],
              ),
              const SizedBox(height: 20),
              Text("Modificatore: +${widget.modifier}", style: const TextStyle(color: Colors.grey)),
              const Divider(indent: 40, endIndent: 40, color: Colors.white24),
              Text("${_dualityResult!.total}", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(
                _getDualityLabel(_dualityResult!),
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: _dualityResult!.isCritical ? Colors.greenAccent : (_dualityResult!.resultType == DualityResult.hope ? const Color(0xFFD4AF37) : Colors.deepPurpleAccent)
                ),
              ),
            ] else ...[
              const Icon(Icons.casino, size: 60, color: Colors.white12),
              const SizedBox(height: 10),
              const Text("Tira per vedere il destino...", style: TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _rollDuality,
              child: const Text("TIRA DUALITÀ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: DADI STANDARD ---
  Widget _buildStandardTab() {
    return Column(
      children: [
        // Area Risultato (Scrollabile)
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$_standardTotal", style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text("TOTALE", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  if (_rollHistory.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 5,
                      runSpacing: 5,
                      children: _rollHistory.map((val) => Chip(
                        label: Text("$val"),
                        backgroundColor: Colors.white10,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // Pulsanti Dadi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [4, 6, 8, 10, 12, 20].map((sides) => _DiceButton(sides: sides, onPressed: () => _rollStandard(sides))).toList(),
          ),
        ),
        
        // Pulsante Reset
        TextButton.icon(
          onPressed: _clearStandard, 
          icon: const Icon(Icons.refresh, color: Colors.redAccent), 
          label: const Text("RESETTA", style: TextStyle(color: Colors.redAccent))
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDieDisplay(int val, Color color, String label) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text("$val", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }

  String _getDualityLabel(DualityRoll roll) {
    if (roll.isCritical) return "CRITICO!";
    if (roll.resultType == DualityResult.hope) return "CON SPERANZA";
    return "CON PAURA";
  }
}

class _DiceButton extends StatelessWidget {
  final int sides;
  final VoidCallback onPressed;
  const _DiceButton({required this.sides, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white10,
          ),
          child: Text("d$sides", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}