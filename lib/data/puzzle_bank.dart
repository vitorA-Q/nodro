import 'package:flutter/services.dart' show rootBundle;

import '../engine/core/technique_tier.dart';
import '../engine/puzzles/star_battle/model.dart';
import '../engine/puzzles/star_battle/serializer.dart';

/// One puzzle as stored in the bank: the puzzle plus the tier it was rated at.
///
/// The tier is the number 1..7, never a label (decision D3). Turning it into
/// "Fácil" or "Hard" happens in the display layer and nowhere else.
class BankEntry {
  const BankEntry(this.tier, this.puzzle);

  final TechniqueTier tier;
  final StarBattlePuzzle puzzle;
}

/// Reads the pre-generated puzzle bank shipped in `assets/bank/`.
///
/// Decision D2: the player never waits for generation. Everything here is a
/// file read and a string parse — no solving, no generating, nothing that could
/// block the frame. Which is what lets the same code run on the web, where
/// isolates do not exist.
class PuzzleBank {
  PuzzleBank._(this._entries);

  static const StarBattleSerializer _serializer = StarBattleSerializer();

  final List<BankEntry> _entries;

  List<BankEntry> get entries => List<BankEntry>.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  /// Loads one bank file, e.g. `star_battle_6x6_1`.
  static Future<PuzzleBank> load(String name) async {
    final raw = await rootBundle.loadString('assets/bank/$name.txt');
    final entries = <BankEntry>[];

    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final split = trimmed.indexOf('|');
      if (split <= 0) {
        throw FormatException('malformed bank line in $name', trimmed);
      }
      entries.add(BankEntry(
        TechniqueTier.fromLevel(int.parse(trimmed.substring(0, split))),
        _serializer.deserialize(trimmed.substring(split + 1)),
      ));
    }

    return PuzzleBank._(entries);
  }

  /// The first puzzle rated exactly [tier], or null if the bank has none.
  BankEntry? firstAtTier(TechniqueTier tier) {
    for (final entry in _entries) {
      if (entry.tier == tier) {
        return entry;
      }
    }
    return null;
  }
}
