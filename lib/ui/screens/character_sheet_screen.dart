import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../../data/models/character.dart';
import '../../data/data_manager.dart';
import '../../logic/json_data_service.dart';
import '../../logic/pdf_export_service.dart';
import '../../logic/room_provider.dart'; // Import per la modalità online

import '../widgets/tabs/status_tab.dart';
import '../widgets/tabs/actions_tab.dart';
import '../widgets/tabs/inventory_tab.dart';
import '../widgets/tabs/cards_tab.dart';

class CharacterSheetScreen extends StatefulWidget {
  final Character character;

  const CharacterSheetScreen({super.key, required this.character});

  @override
  State<CharacterSheetScreen> createState() => _CharacterSheetScreenState();
}

class _CharacterSheetScreenState extends State<CharacterSheetScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final char = widget.character;
    
    // Recuperiamo i dati statici della classe (per descrizioni, privilegi, ecc.)
    final classData = DataManager().getClassById(char.classId);

    // Titolo dinamico (Nome - Livello Classe)
    String title = char.name.isNotEmpty ? char.name : "Scheda Personaggio";
    String subtitle = "Livello ${char.level} ${classData?['name'] ?? 'Eroe'}";

    // Usiamo il Consumer per ascoltare i dati della stanza (se siamo online)
    return Consumer<RoomProvider>(
      builder: (context, roomProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Cinzel', fontSize: 18)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
            // SE ONLINE: Mostra la barra con Paura e Token del GM
            bottom: roomProvider.currentRoomCode != null
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(40),
                    child: Container(
                      color: const Color(0xFF1E1E1E),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(children: [
                            const Icon(Icons.bolt, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text("AZIONI GM: ${roomProvider.actionTokens}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ]),
                          Row(children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 4),
                            Text("PAURA: ${roomProvider.fear}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          ]),
                        ],
                      ),
                    ),
                  )
                : null,
            actions: [
              // --- NUOVO PULSANTE COMBATTIMENTO (SOLO ONLINE) ---
              if (roomProvider.currentRoomCode != null && roomProvider.activeCombatantsData.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.redAccent), // Icona Spade non standard, usiamo swords o simile
                  // Nota: Se Icons.swords non esiste nella tua versione flutter, usa Icons.flash_on o Icons.security
                  tooltip: "Vedi Combattimento",
                  onPressed: () => _showCombatDialog(context, roomProvider),
                ),

              // Menu Opzioni (Export/Salva)
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, char),
                itemBuilder: (BuildContext context) {
                  return [
                    const PopupMenuItem(value: 'save_json', child: Text("Esporta File (JSON)")),
                    const PopupMenuItem(value: 'export_pdf', child: Text("Esporta Scheda (PDF)")),
                  ];
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // TAB BAR PERSONALIZZATA
              Container(
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(0, Icons.person, "STATUS"),
                    _buildTabItem(1, Icons.flash_on, "AZIONI"),
                    _buildTabItem(2, Icons.backpack, "INVENTARIO"),
                    _buildTabItem(3, Icons.style, "CARTE"),
                  ],
                ),
              ),
              
              // CONTENUTO TAB
              Expanded(
                child: IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    // 1. STATUS TAB
                    StatusTab(char: char), 

                    // 2. AZIONI TAB
                    ActionsTab(char: char, classData: classData),

                    // 3. INVENTARIO TAB
                    InventoryTab(char: char),

                    // 4. CARTE TAB
                    CardsTab(char: char),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildTabItem(int index, IconData icon, String label) {
    bool isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: isSelected 
              ? const Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 3)) 
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label, 
              style: TextStyle(
                fontSize: 10, 
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGICA DIALOGO COMBATTIMENTO ---
  void _showCombatDialog(BuildContext context, RoomProvider roomProvider) {
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("COMBATTIMENTO", style: TextStyle(color: Colors.white, fontFamily: 'Cinzel')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: roomProvider.activeCombatantsData.length,
            separatorBuilder: (ctx, i) => const Divider(color: Colors.white24),
            itemBuilder: (ctx, i) {
                final c = roomProvider.activeCombatantsData[i];
                final isPlayer = c['isPlayer'] == true;
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isPlayer ? Colors.blue[900] : Colors.red[900],
                    child: Icon(
                      isPlayer ? Icons.person : Icons.android, 
                      color: Colors.white, size: 20
                    ),
                  ),
                  title: Text(
                    c['name'] ?? 'Sconosciuto', 
                    style: TextStyle(
                      color: isPlayer ? Colors.blueAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  subtitle: Text(
                    "HP: ${c['currentHp']}/${c['maxHp']}", 
                    style: const TextStyle(color: Colors.white70)
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white12)
                    ),
                    child: Text(
                      isPlayer ? "ALLEATO" : "NEMICO",
                      style: TextStyle(fontSize: 10, color: isPlayer ? Colors.blue : Colors.red),
                    ),
                  ),
                );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("CHIUDI", style: TextStyle(color: Colors.grey))
          )
        ],
      )
    );
  }

  void _handleMenuAction(String value, Character char) async {
    if (value == 'save_json') {
      await JsonDataService.exportCharacterJson(context, char);
    } else if (value == 'export_pdf') {
      await PdfExportService.printCharacterPdf(char);
    }
  }
}