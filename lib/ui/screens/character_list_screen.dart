import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/creation_provider.dart';
import 'wizard_screen.dart';
import 'character_sheet_screen.dart';
import 'gm_dashboard_screen.dart';
import 'lobby_screen.dart'; // Assicurati che questo file esista

class CharacterListScreen extends StatefulWidget {
  const CharacterListScreen({super.key});

  @override
  State<CharacterListScreen> createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = Provider.of<CreationProvider>(context, listen: false).loadSavedCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DAGGERHEART", 
          style: TextStyle(fontFamily: 'Cinzel', fontSize: 24, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      // --- MENU LATERALE (DRAWER) ---
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              accountName: Text("Daggerheart Companion", style: TextStyle(fontFamily: 'Cinzel', color: Color(0xFFD4AF37), fontSize: 18)),
              accountEmail: Text("Gestore Eroi & GM", style: TextStyle(color: Colors.grey)),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Color(0xFFD4AF37),
                child: Icon(Icons.shield, color: Colors.black, size: 36),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text("I Miei Eroi", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context), // Chiude il menu (siamo già qui)
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.redAccent),
              title: const Text("Strumenti GM", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              subtitle: const Text("Combat Tracker & Utility", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GmDashboardScreen()));
              },
            ),
            const Divider(color: Colors.white24),
            // --- PULSANTE EVIDENTE PER LA STANZA ONLINE ---
            ListTile(
              tileColor: Colors.blueAccent.withOpacity(0.1),
              leading: const Icon(Icons.public, color: Colors.blueAccent),
              title: const Text("Gioca Online", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              subtitle: const Text("Unisciti o Crea Stanza", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LobbyScreen()));
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          
          return Consumer<CreationProvider>(
            builder: (context, provider, child) {
              return FutureBuilder(
                future: provider.loadSavedCharacters(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          const Text(
                            "Nessun personaggio salvato.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text("CREA IL TUO PRIMO EROE"),
                            onPressed: () => _startCreation(context),
                          ),
                        ],
                      ),
                    );
                  }

                  final characters = snapshot.data as List;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: characters.length,
                    itemBuilder: (context, index) {
                      final char = characters[index];
                      return Dismissible(
                        key: Key(char.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text("Eliminare personaggio?", style: TextStyle(color: Colors.white)),
                              content: Text("Sei sicuro di voler eliminare ${char.name}?", style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ANNULLA")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ELIMINA", style: TextStyle(color: Colors.redAccent))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          provider.deleteCharacter(char.id);
                        },
                        child: Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF333333),
                              child: Text(
                                char.name.isNotEmpty ? char.name[0].toUpperCase() : "?",
                                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              char.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Text(
                              "Livello ${char.level} • ${char.classId.toUpperCase()}",
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CharacterSheetScreen(character: char),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text("NUOVO EROE"),
        onPressed: () => _startCreation(context),
      ),
    );
  }

  void _startCreation(BuildContext context) {
    Provider.of<CreationProvider>(context, listen: false).resetDraft();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WizardScreen()),
    );
  }
}