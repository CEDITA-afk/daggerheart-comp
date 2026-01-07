import 'dart:math';
import 'package:flutter/material.dart';

class GmProvider extends ChangeNotifier {
  // --- TRACKERS ---
  int fear = 0;
  int actionTokens = 0;

  void modifyFear(int amount) {
    fear = max(0, fear + amount);
    notifyListeners();
  }

  void modifyActionTokens(int amount) {
    actionTokens = max(0, actionTokens + amount);
    notifyListeners();
  }

  void resetTrackers() {
    fear = 0;
    actionTokens = 0;
    notifyListeners();
  }

  // --- LOOT GENERATOR ---
  String lastLoot = "";

  void generateLoot(int tier) {
    final rand = Random();
    List<String> rewards = [];

    // Logica Semplificata basata sui Tier di Daggerheart
    if (tier == 1) {
      // Tier 1-4
      int roll = rand.nextInt(100) + 1;
      if (roll <= 40) rewards.add("Manciata d'Oro (${rand.nextInt(4)+1})"); // 1d4
      else if (roll <= 70) rewards.add("Pozione di Salute Minore");
      else if (roll <= 85) rewards.add("Pozione di Stamina Minore");
      else if (roll <= 95) rewards.add("Oggetto Comune Casuale");
      else rewards.add("Oggetto Non Comune (Raro!)");
    } else if (tier == 2) {
      // Tier 5-7
      int roll = rand.nextInt(100) + 1;
      if (roll <= 30) rewards.add("Sacco d'Oro (${rand.nextInt(6)+1})"); // 1d6
      else if (roll <= 60) rewards.add("Pozione di Salute Maggiore");
      else if (roll <= 80) rewards.add("Pergamena Incantesimo");
      else rewards.add("Arma o Armatura Migliorata");
    } else {
      // Tier 8-10
      rewards.add("Forziere d'Oro (${rand.nextInt(8)+1})");
      rewards.add("Oggetto Leggendario o Reliquia");
    }

    lastLoot = rewards.join(" + ");
    notifyListeners();
  }
}