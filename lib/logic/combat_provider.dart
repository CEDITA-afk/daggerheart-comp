import 'package:flutter/material.dart';
import '../data/models/adversary.dart';

class CombatProvider extends ChangeNotifier {
  List<Adversary> activeEnemies = [];

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

  // Modifica HP (Danno o Guarigione)
  void modifyHp(String id, int amount) {
    var enemy = activeEnemies.firstWhere((e) => e.id == id);
    enemy.currentHp = (enemy.currentHp + amount).clamp(0, enemy.maxHp);
    notifyListeners();
  }

  // Pulisci il campo di battaglia
  void clearCombat() {
    activeEnemies.clear();
    notifyListeners();
  }
}