import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Per kIsWeb
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

// --- PROVIDERS ---
import 'logic/creation_provider.dart';
import 'logic/combat_provider.dart';
import 'logic/room_provider.dart';
import 'logic/gm_provider.dart';

// --- DATA ---
import 'data/data_manager.dart';

// --- SCREENS ---
import 'ui/screens/welcome_screen.dart'; // <--- NUOVA HOMEPAGE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- INIZIALIZZA FIREBASE ---
  // Usa le variabili d'ambiente per la sicurezza su GitHub Pages
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
    // Per Android/iOS usa il file google-services.json
    await Firebase.initializeApp();
  }

  // Carica i dati JSON statici (Razze, Classi, ecc.)
  await DataManager().loadAllData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CreationProvider()),
        ChangeNotifierProvider(create: (_) => CombatProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => GmProvider()),
      ],
      child: MaterialApp(
        title: 'Daggerheart Companion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: const Color(0xFFD4AF37),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37),
            secondary: Colors.amberAccent,
            surface: Color(0xFF1E1E1E),
          ),
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
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Lato', color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(),
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        // Qui impostiamo la nuova schermata di benvenuto come punto di partenza
        home: const WelcomeScreen(),
      ),
    );
  }
}