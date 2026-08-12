/// A deterministic pseudo-random number generator that produces the **same
/// sequence on the Dart VM and on JavaScript**.
///
/// `dart:math`'s `Random` makes no cross-platform reproducibility guarantee.
/// Two things in this project depend on that guarantee:
///
///   * **C2 / seeded property tests** — the same seed must produce the same
///     1,000 puzzles on any machine, or a failure cannot be reproduced.
///   * **The daily challenge** — every player must receive the same puzzle for
///     a given date, with no server involved. If the VM and JS diverge, a phone
///     and a browser would show different puzzles on the same day.
///
/// Implementation is xorshift128 (Marsaglia, 2003). It deliberately uses only
/// XOR and shifts and **never multiplication**: a 32x32 multiply exceeds
/// JavaScript's 53-bit exact integer range, so a multiply-based generator
/// (PCG, splitmix) would silently diverge from the VM after the first overflow.
///
/// Every intermediate value is masked back to 32 bits, so all state stays a
/// non-negative integer below 2^32 — exactly representable in JS.
class DeterministicRandom {
  /// Creates a generator from an integer [seed].
  ///
  /// Any seed is accepted, including 0 and negatives; it is folded into the
  /// 32-bit range and scrambled so that nearby seeds produce unrelated streams.
  DeterministicRandom(int seed)
      : _x = 0,
        _y = 0,
        _z = 0,
        _w = 0 {
    var s = seed & _mask32;
    if (s == 0) {
      s = 0x9E3779B9; // golden-ratio constant; any non-zero value works
    }
    _x = s;
    _y = _scramble(_x);
    _z = _scramble(_y);
    _w = _scramble(_z);
    // Discard the first few outputs so that low-entropy seeds (0, 1, 2 …) do
    // not produce visibly correlated opening values.
    for (var i = 0; i < 12; i++) {
      nextUint32();
    }
  }

  /// Creates the generator for a daily challenge.
  ///
  /// The seed depends only on the calendar date and on [puzzleTypeId], so every
  /// player worldwide derives the same puzzle without any server round-trip.
  /// The date is interpreted in the player's local calendar on purpose: the
  /// "daily" puzzle should change when the player's own day changes.
  factory DeterministicRandom.forDate(DateTime date, String puzzleTypeId) {
    final day = date.year * 10000 + date.month * 100 + date.day;
    var h = 0x811C9DC5; // FNV-1a offset basis
    for (var i = 0; i < puzzleTypeId.length; i++) {
      h = (h ^ puzzleTypeId.codeUnitAt(i)) & _mask32;
      // FNV's multiply is replaced by a shift/xor mix to stay JS-exact.
      h = (h ^ ((h << 13) & _mask32)) & _mask32;
      h = (h ^ (h >> 7)) & _mask32;
      h = (h ^ ((h << 3) & _mask32)) & _mask32;
    }
    return DeterministicRandom((h ^ day) & _mask32);
  }

  static const int _mask32 = 0xFFFFFFFF;
  static const int _pow32 = 0x100000000;

  int _x;
  int _y;
  int _z;
  int _w;

  static int _scramble(int value) {
    var t = value & _mask32;
    t = (t ^ ((t << 13) & _mask32)) & _mask32;
    t = (t ^ (t >> 17)) & _mask32;
    t = (t ^ ((t << 5) & _mask32)) & _mask32;
    if (t == 0) {
      t = 0x6D2B79F5;
    }
    return t;
  }

  /// Returns the next raw 32-bit value, in `[0, 2^32)`.
  int nextUint32() {
    final t = (_x ^ ((_x << 11) & _mask32)) & _mask32;
    _x = _y;
    _y = _z;
    _z = _w;
    _w = (_w ^ (_w >> 19) ^ t ^ (t >> 8)) & _mask32;
    return _w;
  }

  /// Returns a uniformly distributed integer in `[0, max)`.
  ///
  /// Uses rejection sampling rather than a plain modulo so the distribution has
  /// no bias toward small values — which matters because the generator uses
  /// this to pick region-boundary cells, and a biased pick would quietly skew
  /// the shape of every puzzle we ship.
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'must be positive');
    }
    if (max > _pow32) {
      throw ArgumentError.value(max, 'max', 'must be at most 2^32');
    }
    final limit = _pow32 - (_pow32 % max);
    int value;
    do {
      value = nextUint32();
    } while (value >= limit);
    return value % max;
  }

  /// Returns `true` with probability 1/2.
  bool nextBool() => (nextUint32() & 1) == 1;

  /// Returns a double in `[0, 1)` with 32 bits of precision.
  double nextDouble() => nextUint32() / _pow32;

  /// Shuffles [items] in place using Fisher–Yates.
  void shuffle<T>(List<T> items) {
    for (var i = items.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Returns a uniformly chosen element of [items].
  T pick<T>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    return items[nextInt(items.length)];
  }
}
