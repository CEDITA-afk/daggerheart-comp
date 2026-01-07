import 'dart:convert';
import 'package:flutter/material.dart';

// IMPORT MAGICO CONDIZIONALE
// Se siamo su web (dart.library.html) usa json_ops_web.dart
// Altrimenti usa json_ops_mobile.dart
import 'json_ops_mobile.dart' if (dart.library.html) 'json_ops_web.dart' as ops;

import '../data/models/character.dart';

class JsonDataService {
  
  static Future<void> exportCharacterJson(BuildContext context, Character char) async {
    try {
      String jsonStr = jsonEncode(char.toJson());
      String safeName = char.name.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      if (safeName.isEmpty) safeName = "character";
      String fileName = "$safeName.json";

      // Chiamiamo la funzione generica, ci penserà l'import a scegliere quella giusta
      await ops.saveAndShareFile(fileName, jsonStr);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Esportazione completata: $fileName"), backgroundColor: Colors.green)
        );
      }

    } catch (e) {
      print("Errore Export: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  static Future<Character?> importCharacterJson(BuildContext context) async {
    try {
      // Anche qui, deleghiamo la lettura
      Map<String, dynamic>? jsonData = await ops.pickAndReadFile();
      
      if (jsonData != null) {
        return Character.fromJson(jsonData);
      }
    } catch (e) {
      print("Errore Import: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore import: $e"), backgroundColor: Colors.red)
        );
      }
    }
    return null;
  }
}