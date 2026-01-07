import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../logic/room_provider.dart';
import 'gm_dashboard_screen.dart';

class GmRoomListScreen extends StatelessWidget {
  const GmRoomListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("LE TUE STANZE", style: TextStyle(fontFamily: 'Cinzel'))),
      body: StreamBuilder<QuerySnapshot>(
        stream: roomProvider.getMyRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data?.docs ?? [];

          return Column(
            children: [
              // LISTA STANZE ESISTENTI
              Expanded(
                child: docs.isEmpty 
                  ? const Center(child: Text("Nessuna stanza attiva.", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final roomId = docs[index].id;
                        final roomName = data['roomName'] ?? "Stanza $roomId";
                        final date = (data['createdAt'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? "";

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: Colors.grey[900],
                          child: ListTile(
                            title: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text("Codice: $roomId • Creato il: $date", style: const TextStyle(color: Colors.grey)),
                            trailing: const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37)),
                            onTap: () async {
                              await roomProvider.resumeRoom(roomId);
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GmDashboardScreen()));
                            },
                          ),
                        );
                      },
                    ),
              ),
              
              // BOTTONE CREA NUOVA
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  icon: const Icon(Icons.add),
                  label: const Text("CREA NUOVA STANZA"),
                  onPressed: () => _showCreateDialog(context, roomProvider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, RoomProvider provider) {
    final nameCtrl = TextEditingController();
    final roomNameCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Nuova Sessione", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Tuo Nome (GM)")),
            const SizedBox(height: 10),
            TextField(controller: roomNameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Nome Avventura")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULLA")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && roomNameCtrl.text.isNotEmpty) {
                await provider.createRoom(nameCtrl.text, roomNameCtrl.text);
                Navigator.pop(ctx);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GmDashboardScreen()));
              }
            },
            child: const Text("CREA"),
          ),
        ],
      ),
    );
  }
}