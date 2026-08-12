import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';

import 'prop_checks.dart';

/// LAYER 1 — Bank verification. **This is the release gate.**
///
/// Runs PROP-1 .. PROP-6 against every puzzle in the shipped bank, generating
/// nothing. That is the whole point: these are the exact puzzles the player will
/// receive, not a random sample nobody ever plays. Verification is cheap (one
/// oracle call plus one human solve); generation is what costs, and it already
/// happened once on a developer machine.
///
///   flutter test test/property/bank_verification_test.dart
///
/// Build the bank first with:
///   dart run tool/generate_bank.dart
void main() {
  final files = _bankFiles();

  test('the bank exists and holds at least 1,000 puzzles', () {
    expect(files, isNotEmpty,
        reason: 'No bank files under assets/bank/. Build them with '
            '`dart run tool/generate_bank.dart` — this gate verifies the '
            'shipped artefact, so there is nothing to verify without it.');

    var total = 0;
    for (final file in files) {
      total += _entriesOf(file).length;
    }
    expect(total, greaterThanOrEqualTo(1000),
        reason: 'The bank holds $total puzzles. The correctness contract asks '
            'for at least 1,000 verified instances.');
  });

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final entries = _entriesOf(file);

    group(name, () {
      test('every puzzle satisfies PROP-1 to PROP-5 '
          '(${entries.length} puzzles)', () {
        for (var i = 0; i < entries.length; i++) {
          final entry = entries[i];
          verifyPuzzle(
            entry.puzzle,
            expectedTier: entry.tier,
            label: '$name#$i',
          );
        }
      });

      // PROP-6 has no Star Battle analogue — decided, not deferred. See the
      // note at the top of prop_checks.dart.

      test('stored tiers cover more than one difficulty', () {
        final tiers = entries.map((entry) => entry.tier.level).toSet();
        expect(tiers.length, greaterThan(1),
            reason: 'every puzzle in $name has the same difficulty, which '
                'means the bank cannot offer a difficulty choice');
      });
    });
  }
}

class _BankEntry {
  const _BankEntry(this.tier, this.puzzle);
  final TechniqueTier tier;
  final StarBattlePuzzle puzzle;
}

List<File> _bankFiles() {
  final dir = Directory('assets/bank');
  if (!dir.existsSync()) {
    return <File>[];
  }
  final files = dir
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.txt'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

List<_BankEntry> _entriesOf(File file) {
  final entries = <_BankEntry>[];
  for (final line in file.readAsLinesSync()) {
    if (line.trim().isEmpty) {
      continue;
    }
    final split = line.indexOf('|');
    expect(split, greaterThan(0),
        reason: 'malformed bank line in ${file.path}: $line');
    final tier = TechniqueTier.fromLevel(int.parse(line.substring(0, split)));
    entries.add(_BankEntry(tier, serializer.deserialize(line.substring(split + 1))));
  }
  return entries;
}
