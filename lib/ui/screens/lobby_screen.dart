import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/room_provider.dart';
import '../../logic/creation_provider.dart';
import '../../data/models/character.dart';
import 'character_sheet_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  Character? _selectedCharacter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Carica i personaggi salvati per farli scegliere al giocatore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CreationProvider>(context, listen: false).loadSavedCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UNISCITI A UNA PARTITA", style: TextStyle(fontFamily: 'Cinzel')),
      ),
      body: Consumer<CreationProvider>(
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
                    const Text(
                      "Inserisci il codice fornito dal GM e seleziona il tuo eroe per entrare.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.white70)
                    ),
                    const SizedBox(height: 32),
                    
                    // Input Codice
                    TextField(
                      controller: _roomCodeController,
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
                        prefixIcon: Icon(Icons.person, color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text("ENTRA NELLA STANZA", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: chars.isEmpty ? null : _joinRoom,
                        ),
                        
                    if (chars.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          "Non hai personaggi salvati! Creane uno prima di giocare online.", 
                          style: TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _joinRoom() async {
    if (_roomCodeController.text.isEmpty || _selectedCharacter == null) return;
    
    setState(() => _isLoading = true);
    try {
      await Provider.of<RoomProvider>(context, listen: false).joinRoom(
        _roomCodeController.text.trim(), 
        _selectedCharacter!
      );
      
      if (mounted) {
        // Naviga alla scheda del personaggio in modalità online
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CharacterSheetScreen(character: _selectedCharacter!)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore: ${e.toString().replaceAll('Exception:', '')}"),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}