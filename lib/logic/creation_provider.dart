import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_manager.dart';
import '../data/models/character.dart';

class CreationProvider extends ChangeNotifier {
  Character draftCharacter = Character();
  int currentStep = 0;
  
  Map<String, dynamic>? selectedClassData;
  Map<String, dynamic>? selectedSubclassData;
  Map<String, dynamic>? selectedAncestryData;
  Map<String, dynamic>? selectedCommunityData;
  List<dynamic> availableCards = [];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController pronounsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  List<TextEditingController> experienceControllers = [
    TextEditingController(), 
    TextEditingController()
  ];
  
  Map<String, TextEditingController> backgroundControllers = {};
  Map<String, TextEditingController> bondControllers = {};

  int selectedLoadoutIndex = 0; 

  // --- VALIDAZIONE STEP ---
  String? validationError; // Messaggio di errore per la UI

  bool validateCurrentStep() {
    validationError = null;
    switch (currentStep) {
      case 0: // Classe
        if (draftCharacter.classId.isEmpty) {
          validationError = "Devi selezionare una Classe per continuare.";
          return false;
        }
        break;
      case 1: // Sottoclasse
        if (draftCharacter.subclassId.isEmpty) {
          validationError = "Devi scegliere una Sottoclasse (Fondamenta).";
          return false;
        }
        // Controllo Ranger Compagno (Opzionale ma consigliato)
        if (draftCharacter.classId == 'ranger' && 
            draftCharacter.subclassId == 'ranger_beastbound') {
             if ((draftCharacter.companion?['name'] ?? '').isEmpty) {
               validationError = "Dai un nome al tuo compagno animale.";
               return false;
             }
        }
        break;
      case 2: // Retaggio & Comunità
        if (draftCharacter.ancestryId.isEmpty) {
          validationError = "Seleziona un Retaggio.";
          return false;
        }
        if (draftCharacter.communityId.isEmpty) {
          validationError = "Seleziona una Comunità.";
          return false;
        }
        break;
      case 3: // Tratti
        // Verifica che tutti i tratti siano stati assegnati (es. somma non zero o logica specifica)
        // Per ora ci fidiamo dei default, ma potremmo controllare se l'utente ha modificato qualcosa.
        break;
      case 6: // Background (Nome obbligatorio)
        if (nameController.text.trim().isEmpty) {
          validationError = "Il personaggio deve avere un nome.";
          return false;
        }
        break;
      case 8: // Carte Dominio
        if (draftCharacter.activeCardIds.length != 2) {
          validationError = "Devi scegliere esattamente 2 carte dominio.";
          return false;
        }
        break;
    }
    notifyListeners();
    return true;
  }

  // --- NAVIGAZIONE ---
  void nextStep() {
    if (validateCurrentStep()) {
      currentStep++;
      validationError = null; // Pulisci errori precedenti
      notifyListeners();
    } else {
      notifyListeners(); // Aggiorna UI per mostrare errore
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      currentStep--;
      validationError = null;
      notifyListeners();
    }
  }

  // ... (Resto del codice: loadSavedCharacters, selectClass, saveCharacter, ecc. identico a prima) ...
  // Copia qui le funzioni esistenti dal file precedente per non perderle.
  // Per brevità, riporto solo le funzioni modificate. Assicurati di mantenere tutto il resto.

  // --- REINSERISCO LE FUNZIONI BASE PER COMPLETEZZA ---
  Future<List<Character>> loadSavedCharacters() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedChars = prefs.getStringList('saved_characters') ?? [];
    return savedChars.map((jsonStr) {
      try { return Character.fromJson(jsonDecode(jsonStr)); } catch (e) { return null; }
    }).whereType<Character>().toList();
  }

  Future<void> deleteCharacter(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedChars = prefs.getStringList('saved_characters') ?? [];
    savedChars.removeWhere((c) { try { return jsonDecode(c)['id'] == id; } catch (e) { return false; } });
    await prefs.setStringList('saved_characters', savedChars);
    notifyListeners();
  }

  Future<void> addImportedCharacter(Character char) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedChars = prefs.getStringList('saved_characters') ?? [];
    savedChars.removeWhere((c) { try { return jsonDecode(c)['id'] == char.id; } catch (e) { return false; } });
    savedChars.add(jsonEncode(char.toJson()));
    await prefs.setStringList('saved_characters', savedChars);
    notifyListeners();
  }

  void resetDraft() {
    draftCharacter = Character();
    currentStep = 0;
    selectedClassData = null;
    selectedSubclassData = null;
    selectedAncestryData = null;
    selectedCommunityData = null;
    availableCards = [];
    selectedLoadoutIndex = 0;
    validationError = null; // Reset errore

    nameController.clear();
    pronounsController.clear();
    descriptionController.clear();
    for (var c in experienceControllers) c.clear();
    backgroundControllers.clear();
    bondControllers.clear();
    notifyListeners();
  }

  void selectClass(String classId) {
    selectedClassData = DataManager().getClassById(classId);
    if (selectedClassData != null) {
      draftCharacter.classId = classId;
      draftCharacter.subclassId = '';
      draftCharacter.companion = null;
      selectedSubclassData = null;
      if (selectedClassData!['creation_guide'] != null) {
        draftCharacter.traits = Map<String, int>.from(selectedClassData!['creation_guide']['recommended_traits']);
      }
      var filterRules = selectedClassData!['available_domains_filter'];
      if (filterRules != null) {
        List<dynamic> domains = filterRules['valid_domains'];
        availableCards = DataManager().getStartingCardsForDomains(domains);
      }
      draftCharacter.activeCardIds = [];
      draftCharacter.maxHp = 6;
      draftCharacter.maxStress = 5;
      draftCharacter.hope = 2;
      selectedLoadoutIndex = 0;
    }
    notifyListeners();
  }

  void selectSubclass(String subclassId) {
    if (selectedClassData != null && selectedClassData!['subclasses'] != null) {
      final subclasses = selectedClassData!['subclasses'] as List;
      try {
        final sub = subclasses.firstWhere((s) => s['id'] == subclassId);
        draftCharacter.subclassId = subclassId;
        selectedSubclassData = sub;
        if (draftCharacter.classId == 'ranger' && subclassId == 'ranger_beastbound') {
          draftCharacter.companion ??= { 'name': 'Compagno Fedele', 'type': 'Lupo', 'currentStress': 0, 'maxStress': 5 };
        } else {
          draftCharacter.companion = null;
        }
        notifyListeners();
      } catch (e) { print("Subclass not found: $subclassId"); }
    }
  }

  void selectAncestry(String ancestryId) {
    var ancestry = DataManager().getAncestryById(ancestryId);
    if (ancestry != null) {
      draftCharacter.ancestryId = ancestryId;
      selectedAncestryData = ancestry;
      draftCharacter.maxStress = 5; 
      if (ancestryId == 'human') draftCharacter.maxStress += 1; 
    }
    notifyListeners();
  }

  void selectCommunity(String communityId) {
    var community = DataManager().getCommunityById(communityId);
    if (community != null) {
      draftCharacter.communityId = communityId;
      selectedCommunityData = community;
    }
    notifyListeners();
  }

  void updateTrait(String traitKey, int newValue) {
    if (draftCharacter.traits.containsKey(traitKey)) {
      draftCharacter.traits[traitKey] = newValue;
      notifyListeners();
    }
  }

  void selectLoadout(int index) {
    selectedLoadoutIndex = index;
    notifyListeners();
  }

  void toggleCardSelection(String cardId) {
    if (draftCharacter.activeCardIds.contains(cardId)) {
      draftCharacter.activeCardIds.remove(cardId);
    } else {
      if (draftCharacter.activeCardIds.length < 2) {
        draftCharacter.activeCardIds.add(cardId);
      }
    }
    notifyListeners();
  }

  Future<void> saveCharacter() async {
    if (selectedClassData == null) return;
    draftCharacter.name = nameController.text.isNotEmpty ? nameController.text : "Eroe Senza Nome";
    draftCharacter.pronouns = pronounsController.text;
    draftCharacter.description = descriptionController.text;
    draftCharacter.experiences = experienceControllers.map((c) => c.text).toList();
    draftCharacter.backgroundAnswers.clear();
    backgroundControllers.forEach((q, c) { if (c.text.isNotEmpty) draftCharacter.backgroundAnswers[q] = c.text; });
    draftCharacter.bonds.clear();
    bondControllers.forEach((q, c) { if (c.text.isNotEmpty) draftCharacter.bonds[q] = c.text; });

    draftCharacter.weapons.clear();
    draftCharacter.inventory.clear(); 
    draftCharacter.armorName = '';
    draftCharacter.armorScore = 0;
    draftCharacter.evasionModifier = 0;

    List<dynamic> loadouts = selectedClassData!['creation_guide']['starting_equipment_choices'];
    if (loadouts.isNotEmpty) {
      var chosenLoadout = loadouts[selectedLoadoutIndex];
      for (var item in chosenLoadout['items']) {
        String type = item['type'].toString().toLowerCase();
        String name = item['name'];
        if (type == 'weapon') {
          if (item['damage'] != null && !name.contains("d")) {
             draftCharacter.weapons.add("$name (d${item['damage']})");
          } else {
             draftCharacter.weapons.add(name);
          }
        } else if (type == 'armor') {
          draftCharacter.armorName = name;
          var dbStats = DataManager().getItemStats(name);
          if (dbStats != null) {
            draftCharacter.armorScore = dbStats['score'] ?? 0;
            draftCharacter.evasionModifier = dbStats['evasion'] ?? 0;
          } else {
            String lower = name.toLowerCase();
            if (lower.contains('cuoio')) { draftCharacter.armorScore = 2; } 
            else if (lower.contains('gambesone')) { draftCharacter.armorScore = 3; draftCharacter.evasionModifier = 1; } 
            else if (lower.contains('maglia')) { draftCharacter.armorScore = 4; draftCharacter.evasionModifier = -1; } 
            else if (lower.contains('piastre')) { draftCharacter.armorScore = 6; draftCharacter.evasionModifier = -2; } 
            else { draftCharacter.armorScore = 2; }
          }
        } else {
          if (name.toLowerCase().contains('scudo')) {
             if (name.toLowerCase().contains('torre')) { draftCharacter.armorScore += 2; draftCharacter.evasionModifier -= 1; } 
             else { draftCharacter.armorScore += 1; }
             draftCharacter.weapons.add("$name (Scudo)");
          } else {
             draftCharacter.inventory.add(name);
          }
        }
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedChars = prefs.getStringList('saved_characters') ?? [];
      savedChars.removeWhere((c) { try { return jsonDecode(c)['id'] == draftCharacter.id; } catch (e) { return false; } });
      savedChars.add(jsonEncode(draftCharacter.toJson()));
      await prefs.setStringList('saved_characters', savedChars);
    } catch (e) { print("Errore salvataggio: $e"); }
  }
  
  @override
  void dispose() {
    nameController.dispose();
    pronounsController.dispose();
    descriptionController.dispose();
    for (var c in experienceControllers) c.dispose();
    backgroundControllers.forEach((_, c) => c.dispose());
    bondControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }
}