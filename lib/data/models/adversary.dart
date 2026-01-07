import 'package:uuid/uuid.dart';

class AdversaryFeature {
  final String name;
  final String text;
  AdversaryFeature({required this.name, required this.text});

  factory AdversaryFeature.fromJson(Map<String, dynamic> json) {
    return AdversaryFeature(
      name: json['name'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class Adversary {
  final String id;
  String name;
  String campaign; // ES: "Age of Umbra"
  String tier;     // ES: "Tier 1 Leader"
  String description;
  int currentHp;
  int maxHp;
  int currentStress;
  int maxStress;
  int difficulty; 
  String attackName; 
  int attackMod; 
  String damageDice;
  String thresholds; // ES: "6/12"
  List<AdversaryFeature> features;

  Adversary({
    String? id,
    required this.name,
    this.campaign = 'Custom',
    this.tier = 'Tier 1',
    this.description = '',
    required this.maxHp,
    this.currentHp = -1,
    this.maxStress = 0,
    this.currentStress = 0,
    this.difficulty = 10,
    this.attackName = "Attacco Base",
    this.attackMod = 0,
    this.damageDice = "d6",
    this.thresholds = "-",
    this.features = const [],
  }) : id = id ?? const Uuid().v4() {
    if (currentHp == -1) currentHp = maxHp;
  }

  factory Adversary.fromJson(Map<String, dynamic> json) {
    return Adversary(
      id: const Uuid().v4(), // Generiamo un nuovo ID univoco per l'istanza in combattimento
      name: json['name'] ?? 'Sconosciuto',
      campaign: json['campaign'] ?? 'Generico',
      tier: json['tier'] ?? '',
      description: json['description'] ?? '',
      maxHp: json['maxHp'] ?? 10,
      maxStress: json['stress'] ?? 0,
      difficulty: json['difficulty'] ?? 10,
      attackName: json['attack_name'] ?? 'Attacco',
      attackMod: json['attack_mod'] ?? 0,
      damageDice: json['damage_dice'] ?? 'd6',
      thresholds: json['thresholds'] ?? '-',
      features: (json['features'] as List?)
          ?.map((e) => AdversaryFeature.fromJson(e))
          .toList() ?? [],
    );
  }
}