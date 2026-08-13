import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';

/// Fails if any string exists in one language and not the other.
///
/// Rule R6 says every visible string comes from an .arb file, which only helps
/// if the files stay in step. Without this test the usual failure is silent:
/// gen_l10n falls back to the template, so a missing Portuguese string shows up
/// as English text in a Portuguese UI and nobody notices until a player does.
///
/// It also checks that every technique the solver can name has BOTH a display
/// name and an explanation in both languages — a hint that names a technique
/// with a raw identifier like `sbCrowdingExclusion` is worse than no hint.
void main() {
  Map<String, dynamic> readArb(String locale) {
    final raw = File('lib/l10n/app_$locale.arb').readAsStringSync();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Message keys only: entries starting with @ are metadata.
  Set<String> messageKeys(Map<String, dynamic> arb) => arb.keys
      .where((key) => !key.startsWith('@'))
      .toSet();

  late Map<String, dynamic> en;
  late Map<String, dynamic> pt;

  setUpAll(() {
    en = readArb('en');
    pt = readArb('pt');
  });

  test('every English string has a Portuguese translation', () {
    final missing = messageKeys(en).difference(messageKeys(pt)).toList()
      ..sort();
    expect(missing, isEmpty,
        reason: 'these keys exist in en and not in pt, so a Portuguese player '
            'would silently see English:\n${missing.join('\n')}');
  });

  test('Portuguese has no orphan strings', () {
    final extra = messageKeys(pt).difference(messageKeys(en)).toList()..sort();
    expect(extra, isEmpty,
        reason: 'these keys exist only in pt, which usually means a rename was '
            'half-finished:\n${extra.join('\n')}');
  });

  test('no translation was left as a copy of the English', () {
    // Product names and format-only strings legitimately match.
    const allowed = <String>{
      'appTitle',
      'starBattleName',
      'headerLine',
      'pickTitle',
      'wonTime',
      'puzzleNumber',
      'techniqueTier',
    };
    final untranslated = <String>[];
    for (final key in messageKeys(en)) {
      if (allowed.contains(key)) {
        continue;
      }
      if (en[key] == pt[key]) {
        untranslated.add(key);
      }
    }
    untranslated.sort();
    expect(untranslated, isEmpty,
        reason: 'these read identically in both languages, which usually means '
            'the English was pasted in as a placeholder:\n'
            '${untranslated.join('\n')}');
  });

  test('every technique the solver can name is fully translated', () {
    final missing = <String>[];
    for (final id in StarBattleHumanSolver().techniqueIds) {
      for (final prefix in <String>['techName_', 'techWhy_']) {
        final key = '$prefix$id';
        if (!en.containsKey(key)) {
          missing.add('en/$key');
        }
        if (!pt.containsKey(key)) {
          missing.add('pt/$key');
        }
      }
    }
    expect(missing, isEmpty,
        reason: 'a hint would fall back to showing a raw identifier for '
            'these:\n${missing.join('\n')}');
  });

  test('placeholders match between the two languages', () {
    // A missing placeholder does not fail to compile — it renders a literal
    // brace in front of the player.
    final problems = <String>[];
    final placeholder = RegExp(r'\{(\w+)[,}]');

    for (final key in messageKeys(en)) {
      final enValue = en[key];
      final ptValue = pt[key];
      if (enValue is! String || ptValue is! String) {
        continue;
      }
      final enNames =
          placeholder.allMatches(enValue).map((m) => m.group(1)!).toSet();
      final ptNames =
          placeholder.allMatches(ptValue).map((m) => m.group(1)!).toSet();
      if (enNames.length != ptNames.length ||
          !enNames.containsAll(ptNames)) {
        problems.add('$key: en=$enNames pt=$ptNames');
      }
    }
    expect(problems, isEmpty,
        reason: 'placeholder mismatch renders a literal brace on screen:\n'
            '${problems.join('\n')}');
  });
}
