import 'package:flutter/material.dart';
import '../data/models/adversary.dart';
import '../data/models/character.dart'; // <--- ERA MANCANTE QUESTO IMPORT

class CombatProvider extends ChangeNotifier {
  List<Adversary> activeEnemies = [];
  List<Character> activeCharacters = []; 

  // Aggiungi un nemico alla battaglia
  void addAdversary(Adversary enemy) {
    activeEnemies.add(enemy);
    notifyListeners();
  }

  // Rimuovi un nemico (sconfitto)
  void removeAdversary(String id) {
    activeEnemies.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Metodo per aggiungere un PG al combattimento
  void addCharacterToCombat(Character char) {
    if (!activeCharacters.any((c) => c.id == char.id)) {
      activeCharacters.add(char);
      notifyListeners();
    }
  } // <--- MANCAVA QUESTA PARENTESI!

  // Modifica HP (Danno o Guarigione)
  void modifyHp(String id, int amount) {
    // Cerca prima nei nemici
    var enemyIndex = activeEnemies.indexWhere((e) => e.id == id);
    if (enemyIndex != -1) {
      var enemy = activeEnemies[enemyIndex];
      enemy.currentHp = (enemy.currentHp + amount).clamp(0, enemy.maxHp);
      notifyListeners();
      return;
    }
    
    // Se non è un nemico, cerca nei personaggi (opzionale, se vuoi gestire HP PG qui)
  }

  // Pulisci il campo di battaglia
  void clearCombat() {
    activeEnemies.clear();
    activeCharacters.clear();
    notifyListeners();
  }
}