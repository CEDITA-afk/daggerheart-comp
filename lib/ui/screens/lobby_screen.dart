import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/creation_provider.dart';
import '../../data/models/character.dart';
import 'gm_dashboard_screen.dart';
import 'character_sheet_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _gmNameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  
  Character? _selectedCharacter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Carica i personaggi salvati per farli scegliere al giocatore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreationProvider>(context, listen: false).loadSavedCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SALA D'ATTESA ONLINE", style: TextStyle(fontFamily: 'Cinzel')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "SONO IL GM", icon: Icon(Icons.security)),
            Tab(text: "SONO UN GIOCATORE", icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGmTab(),
          _buildPlayerTab(),
        ],
      ),
    );
  }

  // --- SCHEDA GM ---
  Widget _buildGmTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.castle, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            "Crea una nuova sessione di gioco.\nRiceverai un codice da condividere con i tuoi giocatori.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _gmNameController,
            // FIX: Forziamo il colore del testo a bianco
            style: const TextStyle(color: Colors.white), 
            decoration: const InputDecoration(
              labelText: "Nome del Game Master",
              prefixIcon: Icon(Icons.edit, color: Colors.white70),
              labelStyle: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          _isLoading 
            ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFFD4AF37),
                ),
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                label: const Text("CREA STANZA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                onPressed: _createRoom,
              ),
        ],
      ),
    );
  }

  // --- SCHEDA GIOCATORE ---
  Widget _buildPlayerTab() {
    return Consumer<CreationProvider>(
      builder: (context, creationProv, child) {
        return FutureBuilder(
          future: creationProv.loadSavedCharacters(),
          builder: (context, snapshot) {
            final chars = snapshot.data ?? [];
            
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  const Text("Inserisci il codice fornito dal GM e seleziona il tuo eroe.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  
                  // Input Codice
                  TextField(
                    controller: _roomCodeController,
                    // FIX: Forziamo il colore del testo a bianco
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Codice Stanza (es. 123456)",
                      prefixIcon: Icon(Icons.key, color: Colors.white70),
                      labelStyle: TextStyle(color: Colors.grey),
                      counterText: "",
                    ),
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Selezione Personaggio
                  DropdownButtonFormField<Character>(
                    value: _selectedCharacter,
                    dropdownColor: Colors.grey[850],
                    decoration: const InputDecoration(
                      labelText: "Seleziona il tuo Personaggio",
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white), // Stile testo dropdown
                    items: chars.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text("${c.name} (Lv ${c.level})", style: const TextStyle(color: Colors.white)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCharacter = val),
                  ),
                  
                  const SizedBox(height: 32),
                  _isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text("ENTRA NELLA STANZA"),
                        onPressed: chars.isEmpty ? null : _joinRoom,
                      ),
                  if (chars.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text("Devi prima creare un personaggio locale!", style: TextStyle(color: Colors.redAccent)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createRoom() async {
    if (_gmNameController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<RoomProvider>(context, listen: false).createRoom(_gmNameController.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GmDashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    if (_roomCodeController.text.isEmpty || _selectedCharacter == null) return;
    setState(() => _isLoading = true);
    try {
      await Provider.of<RoomProvider>(context, listen: false).joinRoom(
        _roomCodeController.text, 
        _selectedCharacter!
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CharacterSheetScreen(character: _selectedCharacter!)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}