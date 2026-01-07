import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Serve per controllare se siamo su Web (kIsWeb)
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // Core di Firebase

// --- IMPORTS DEI PROVIDER ---
import 'logic/creation_provider.dart';
import 'logic/combat_provider.dart';
import 'logic/room_provider.dart'; // Gestione Stanze Online
import 'logic/gm_provider.dart';   // Gestione Dashboard GM

// --- IMPORTS DEI DATI E UI ---
import 'data/data_manager.dart';
import 'ui/screens/character_list_screen.dart';

void main() async {
  // Assicura che il motore grafico di Flutter sia pronto
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- INIZIALIZZA FIREBASE (MODALITÀ SICURA) ---
  // Invece di scrivere le chiavi qui, le chiediamo all'ambiente di compilazione.
  // Su GitHub: verranno prese dai "Secrets".
  // In Locale: verranno prese dal file launch.json o dai parametri --dart-define.
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
        appId: String.fromEnvironment('FIREBASE_APP_ID'),
        messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      ),
    );
  } else {
    // Se un giorno compilerai per Android/iOS, userà automaticamente il file google-services.json
    await Firebase.initializeApp();
  }

  // Carica tutti i JSON (Classi, Razze, Nemici) prima di avviare l'interfaccia
  await DataManager().loadAllData();
  
  // Avvia l'applicazione
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Qui registriamo TUTTI i cervelli dell'app
      providers: [
        ChangeNotifierProvider(create: (_) => CreationProvider()), // Creazione Personaggi
        ChangeNotifierProvider(create: (_) => CombatProvider()),   // Combattimento
        ChangeNotifierProvider(create: (_) => RoomProvider()),     // Multiplayer Online
        ChangeNotifierProvider(create: (_) => GmProvider()),       // Strumenti GM
      ],
      child: MaterialApp(
        title: 'Daggerheart Companion',
        debugShowCheckedModeBanner: false,
        
        // --- TEMA SCURO & ORO ---
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212), // Nero profondo
          primaryColor: const Color(0xFFD4AF37), // Oro Daggerheart
          
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            secondary: Colors.amberAccent,
            surface: Color(0xFF1E1E1E), // Grigio scuro per le Card
          ),
          
          // Stile AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          // Stile Testo Base
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Lato', color: Colors.white),
          ),
          
          // Stile Bottoni
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black, // Testo nero su bottone oro
            ),
          ),
          
          // Stile Campi di Testo (Input)
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey),
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        
        // Schermata Iniziale
        home: const CharacterListScreen(),
      ),
    );
  }
}