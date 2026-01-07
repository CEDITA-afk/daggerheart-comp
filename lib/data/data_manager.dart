import 'dart:convert';
import 'package:flutter/services.dart';
import 'models/adversary.dart'; 

class DataManager {
  static final DataManager _instance = DataManager._internal();

  factory DataManager() {
    return _instance;
  }

  DataManager._internal();

  // --- ARCHIVIO DATI (PRIVATI) ---
  final Map<String, dynamic> _classes = {};
  final Map<String, dynamic> _ancestries = {};
  final Map<String, dynamic> _communities = {};
  final List<dynamic> _cards = [];
  final List<dynamic> _commonItems = []; // Aggiunto per fixare errore inventory_tab
  
  // --- NUOVO: LIBRERIA AVVERSARI ---
  final List<Adversary> _adversaryLibrary = [];

  // --- LISTA FILE DA CARICARE ---
  final List<String> _classFiles = [
    'assets/data/classes/bardo.json',
    'assets/data/classes/consacrato.json',
    'assets/data/classes/druido.json',
    'assets/data/classes/fuorilegge.json',
    'assets/data/classes/guardiano.json',
    'assets/data/classes/guerriero.json',
    'assets/data/classes/mago.json',
    'assets/data/classes/ranger.json',
    'assets/data/classes/stregone.json',
    'assets/data/classes/ranger_companion.json',
  ];

  final List<String> _adversaryFiles = [
    'assets/data/adversaries/age_of_umbra.json',
    'assets/data/adversaries/the_void_1_5.json',
    'assets/data/adversaries/base_tier0.json',
  ];

  // --- GETTERS PUBBLICI (CORREZIONE ERRORI) ---
  // Questi getter restituiscono i valori come liste o mappe per compatibilità con la UI esistente
  List<dynamic> get classes => _classes.values.toList();
  List<dynamic> get ancestries => _ancestries.values.toList();
  List<dynamic> get communities => _communities.values.toList();
  List<dynamic> get commonItems => _commonItems; // Getter mancante
  List<dynamic> get cards => _cards;

  // --- METODO PRINCIPALE DI CARICAMENTO ---
  Future<void> loadAllData() async {
    await _loadClasses();
    await _loadAncestries();
    await _loadCommunities();
    await _loadCards();
    await _loadAdversaries(); 
    // In futuro carica anche gli items se hai un json dedicato
    
    print("✅ Dati caricati: ${_classes.length} classi, ${_ancestries.length} razze, ${_communities.length} comunità, ${_adversaryLibrary.length} avversari.");
  }

  // --- CARICAMENTO MODULI ---

  Future<void> _loadClasses() async {
    _classes.clear();
    for (String file in _classFiles) {
      try {
        final String response = await rootBundle.loadString(file);
        final data = json.decode(response);
        if (data['id'] != null) {
          _classes[data['id']] = data;
        }
      } catch (e) {
        print("Errore caricamento classe $file: $e");
      }
    }
  }

  Future<void> _loadAncestries() async {
    try {
      final String response = await rootBundle.loadString('assets/data/razze.json');
      final List<dynamic> data = json.decode(response);
      _ancestries.clear();
      for (var item in data) {
        _ancestries[item['id']] = item;
      }
    } catch (e) {
      print("Errore caricamento razze: $e");
    }
  }

  Future<void> _loadCommunities() async {
    try {
      final String response = await rootBundle.loadString('assets/data/comunita.json');
      final List<dynamic> data = json.decode(response);
      _communities.clear();
      for (var item in data) {
        _communities[item['id']] = item;
      }
    } catch (e) {
      print("Errore caricamento comunità: $e");
    }
  }

  Future<void> _loadCards() async {
    try {
      final String response = await rootBundle.loadString('assets/data/carte_domini.json');
      final List<dynamic> data = json.decode(response);
      _cards.clear();
      _cards.addAll(data);
    } catch (e) {
      print("Errore caricamento carte: $e");
    }
  }

  Future<void> _loadAdversaries() async {
    _adversaryLibrary.clear();
    for (String file in _adversaryFiles) {
      try {
        final String response = await rootBundle.loadString(file);
        final List<dynamic> data = json.decode(response);
        _adversaryLibrary.addAll(data.map((jsonItem) => Adversary.fromJson(jsonItem)).toList());
      } catch (e) {
        print("⚠️ Impossibile caricare avversari da $file: $e");
      }
    }
  }

  // --- HELPERS DI RICERCA ---

  Map<String, dynamic>? getClassById(String id) {
    return _classes[id];
  }

  Map<String, dynamic>? getAncestryById(String id) {
    return _ancestries[id];
  }

  Map<String, dynamic>? getCommunityById(String id) {
    return _communities[id];
  }

  List<dynamic> getStartingCardsForDomains(List<dynamic> domains) {
    return _cards.where((card) {
      return domains.contains(card['domain'].toString().toLowerCase()) && card['level'] == 1;
    }).toList();
  }

  Map<String, dynamic>? getCardById(String id) {
    try {
      return _cards.firstWhere((c) => c['id'] == id);
    } catch (e) {
      return null;
    }
  }
  
  Map<String, dynamic>? getItemStats(String itemName) {
    // Implementazione placeholder
    return null; 
  }

  // --- METODI PER AVVERSARI ---

  List<Adversary> getAdversaryLibrary() {
    return _adversaryLibrary;
  }

  List<String> getAdversaryCampaigns() {
    final campaigns = _adversaryLibrary.map((e) => e.campaign).toSet().toList();
    campaigns.sort();
    return campaigns;
  }
  
  List<Adversary> getAdversariesByCampaign(String campaign) {
    if (campaign == "Tutti") return _adversaryLibrary;
    return _adversaryLibrary.where((e) => e.campaign == campaign).toList();
  }
}