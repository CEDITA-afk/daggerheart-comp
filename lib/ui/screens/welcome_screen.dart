import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/room_provider.dart';
import 'gm_room_list_screen.dart'; // Creeremo questo file dopo
import 'character_list_screen.dart';
import 'gm_dashboard_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Tenta il login automatico
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      await roomProvider.init();
      
      // Se c'è una sessione attiva, reindirizza
      if (roomProvider.currentRoomCode != null && mounted) {
        if (roomProvider.isGm) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GmDashboardScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CharacterListScreen()));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 80, color: Color(0xFFD4AF37)),
              const SizedBox(height: 16),
              const Text(
                "DAGGERHEART\nCOMPANION",
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cinzel', fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              
              // BOTTONE GM
              _buildBigButton(
                context, 
                "SONO IL GAME MASTER", 
                Icons.security, 
                Colors.redAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GmRoomListScreen())),
              ),
              
              const SizedBox(height: 24),
              
              // BOTTONE GIOCATORE
              _buildBigButton(
                context, 
                "SONO UN GIOCATORE", 
                Icons.person, 
                Colors.blueAccent,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CharacterListScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBigButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 32),
        label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        onPressed: onTap,
      ),
    );
  }
}