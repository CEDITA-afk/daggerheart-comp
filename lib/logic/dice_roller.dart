import 'dart:math';

enum DualityResult { critical, hope, fear }

class DualityRoll {
  final int hopeDie;
  final int fearDie;
  final int modifier;
  final int total;
  final DualityResult resultType;
  final bool isCritical;

  DualityRoll({
    required this.hopeDie,
    required this.fearDie,
    required this.modifier,
    required this.total,
    required this.resultType,
    required this.isCritical,
  });
}

class DiceRoller {
  static final Random _rng = Random();

  // Tiro Dualità (2d12)
  static DualityRoll rollDuality(int modifier) {
    int hope = _rng.nextInt(12) + 1;
    int fear = _rng.nextInt(12) + 1;
    int total = hope + fear + modifier;

    bool isCrit = (hope == fear);
    DualityResult type;

    if (isCrit) {
      type = DualityResult.critical;
    } else if (hope > fear) {
      type = DualityResult.hope;
    } else {
      type = DualityResult.fear;
    }

    return DualityRoll(
      hopeDie: hope,
      fearDie: fear,
      modifier: modifier,
      total: total,
      resultType: type,
      isCritical: isCrit,
    );
  }

  // Tiro Generico (es. 1d8, 2d6)
  static int rollGeneric(int sides, int count) {
    int total = 0;
    for (int i = 0; i < count; i++) {
      total += _rng.nextInt(sides) + 1;
    }
    return total;
  }
}