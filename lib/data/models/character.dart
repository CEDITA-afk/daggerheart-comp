import 'package:uuid/uuid.dart';

class Character {
  final String id;
  
  // Dati Anagrafici
  String name;
  String pronouns;
  String description;
  
  // Riferimenti
  String classId;
  String subclassId; // <--- NUOVO: ID della Sottoclasse
  String ancestryId;
  String communityId;
  int level;
  
  // Stats
  Map<String, int> traits;
  
  // Risorse
  int currentHp;
  int maxHp;
  int currentStress;
  int maxStress;
  int hope;
  int armorSlotsUsed;
  
  // Equipaggiamento Avanzato
  List<String> weapons;        
  String armorName;            
  int armorScore;              
  int evasionModifier;         
  List<String> inventory;      
  int gold;
  
  // Carte e Narrativa
  List<String> activeCardIds;
  Map<String, String> backgroundAnswers;
  List<String> experiences;
  Map<String, String> bonds;

  // NUOVO: Dati del Compagno Animale (Ranger)
  Map<String, dynamic>? companion; 

  Character({
    String? id,
    this.name = '',
    this.pronouns = '',
    this.description = '',
    this.classId = '',
    this.subclassId = '', // <--- Inizializza vuoto
    this.ancestryId = '',
    this.communityId = '',
    this.level = 1,
    this.currentHp = 6, 
    this.maxHp = 6,
    this.currentStress = 0,
    this.maxStress = 5,
    this.hope = 2,
    this.armorSlotsUsed = 0,
    this.gold = 0,
    this.armorName = '',
    this.armorScore = 0,        
    this.evasionModifier = 0,   
    Map<String, int>? traits,
    List<String>? activeCardIds,
    List<String>? weapons,
    List<String>? inventory,
    Map<String, String>? backgroundAnswers,
    List<String>? experiences,
    Map<String, String>? bonds,
    this.companion, // <--- Inizializza opzionale
  }) : 
    this.id = id ?? const Uuid().v4(),
    this.traits = traits ?? {
      "agilita": 0, "forza": 0, "astuzia": 0, 
      "istinto": 0, "presenza": 0, "conoscenza": 0
    },
    this.activeCardIds = activeCardIds ?? [],
    this.weapons = weapons ?? [],
    this.inventory = inventory ?? [],
    this.backgroundAnswers = backgroundAnswers ?? {},
    this.experiences = experiences ?? ['', ''],
    this.bonds = bonds ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pronouns': pronouns,
      'description': description,
      'classId': classId,
      'subclassId': subclassId, // <--- Salva
      'ancestryId': ancestryId,
      'communityId': communityId,
      'level': level,
      'traits': traits,
      'currentHp': currentHp,
      'maxHp': maxHp,
      'currentStress': currentStress,
      'maxStress': maxStress,
      'hope': hope,
      'armorSlotsUsed': armorSlotsUsed,
      'gold': gold,
      'armorName': armorName,
      'armorScore': armorScore,
      'evasionModifier': evasionModifier,
      'weapons': weapons,
      'inventory': inventory,
      'activeCardIds': activeCardIds,
      'backgroundAnswers': backgroundAnswers,
      'experiences': experiences,
      'bonds': bonds,
      'companion': companion, // <--- Salva
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'] ?? '',
      pronouns: json['pronouns'] ?? '',
      description: json['description'] ?? '',
      classId: json['classId'] ?? '',
      subclassId: json['subclassId'] ?? '', // <--- Leggi
      ancestryId: json['ancestryId'] ?? '',
      communityId: json['communityId'] ?? '',
      level: json['level'] ?? 1,
      currentHp: json['currentHp'] ?? 6,
      maxHp: json['maxHp'] ?? 6,
      currentStress: json['currentStress'] ?? 0,
      maxStress: json['maxStress'] ?? 5,
      hope: json['hope'] ?? 2,
      armorName: json['armorName'] ?? '',
      armorScore: json['armorScore'] ?? 0,
      evasionModifier: json['evasionModifier'] ?? 0,
      gold: json['gold'] ?? 0,
      traits: Map<String, int>.from(json['traits'] ?? {}),
      activeCardIds: List<String>.from(json['activeCardIds'] ?? []),
      weapons: List<String>.from(json['weapons'] ?? []),
      inventory: List<String>.from(json['inventory'] ?? []),
      backgroundAnswers: Map<String, String>.from(json['backgroundAnswers'] ?? {}),
      experiences: List<String>.from(json['experiences'] ?? []),
      bonds: Map<String, String>.from(json['bonds'] ?? {}),
      companion: json['companion'], // <--- Leggi
    );
  }
}