import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/data/progress_repository.dart';
import 'package:nodro/data/puzzle_bank.dart';
import 'package:nodro/data/puzzle_library.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/l10n/app_localizations.dart';
import 'package:nodro/ui/painters/star_battle_painter.dart';
import 'package:nodro/ui/screens/play_screen.dart';
import 'package:nodro/ui/theme/difficulty.dart';
import 'package:nodro/ui/theme/nodro_theme.dart';

/// Stage A acceptance: the whole path a player walks, asserted on PIXELS.
///
/// ## Why pixels
///
/// The previous version of this test checked the star counter — a plain Text
/// rebuilt by setState — and passed green while the board never repainted once.
/// The player looks at the canvas, not at the counter, so the canvas is what
/// gets asserted. Each check takes the painter the widget tree is actually
/// holding, renders it, and reads the colour of the tapped cell.
///
/// It fails against the pre-fix code, where one mutable cell list was shared
/// between frames so `shouldRepaint` could never see a change.
void main() {
  const oracle = StarBattleExhaustiveSolver();
  const serializer = StarBattleSerializer();
  const boardSize = 6;

  /// The same file the app ships, read straight from disk.
  ///
  /// Deliberately not through `rootBundle`: that is a platform channel which
  /// only answers on the real event loop, and mixing it with the widget test's
  /// fake clock is what made an earlier version of this suite hang for ten
  /// minutes. `bank_verification_test.dart` covers the asset path itself.
  late final BankEntry entry = () {
    final line = File('assets/bank/star_battle_6x6_1.txt')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('2|'));
    return BankEntry(
      TechniqueTier.tier2,
      serializer.deserialize(line.substring(line.indexOf('|') + 1)),
    );
  }();

  late final LibraryPuzzle libraryPuzzle = LibraryPuzzle(
    'test#0',
    PuzzleGroup(6, 1, Difficulty.medium),
    entry,
  );

  Future<void> pumpApp(WidgetTester tester,
      {Size surface = const Size(390, 844)}) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildNodroTheme(Brightness.light),
      home: PlayScreen(
        puzzle: libraryPuzzle,
        library: PuzzleLibrary.fromPuzzles(<LibraryPuzzle>[libraryPuzzle]),
        progress: InMemoryProgressRepository(),
        isDaily: false,
      ),
    ));
    await tester.pump();
  }

  /// The board itself, by key.
  ///
  /// NOT `find.byType(GestureDetector).last`: once the control row existed, the
  /// last gesture detector on screen was the hint button, and every tap in this
  /// suite silently went to a button instead of the board.
  final boardFinder = find.byKey(const ValueKey<String>('board'));

  StarBattlePainter livePainter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<StarBattlePainter>()
      .last;

  /// Average darkness at the middle of one cell, 0 (light) to 1 (dark).
  ///
  /// Captures the board's OWN repaint boundary — what the widget actually put
  /// on screen — not a fresh render of the painter. That distinction is the
  /// entire point: an earlier version of this helper re-rendered the painter
  /// itself and passed happily against a painter hard-wired never to repaint,
  /// which is exactly the defect it was meant to catch.
  ///
  /// A star is a large filled shape in ink; an empty cell is a pale tint. So
  /// "was a star drawn here" is answerable from pixels alone, with no
  /// dependence on any particular colour value.
  Future<double> cellDarkness(WidgetTester tester, int row, int col) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey<String>('board')));

    final darkness = await tester.runAsync<double>(() async {
      final ui.Image image = await boundary.toImage();
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();

      final cell = image.width / boardSize;
      final centreX = (col * cell + cell / 2).round();
      final centreY = (row * cell + cell / 2).round();
      final radius = (cell * 0.12).round();

      var total = 0.0;
      var samples = 0;
      for (var y = centreY - radius; y <= centreY + radius; y++) {
        for (var x = centreX - radius; x <= centreX + radius; x++) {
          if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
            continue;
          }
          final offset = (y * image.width + x) * 4;
          total += 1 -
              ((bytes[offset] + bytes[offset + 1] + bytes[offset + 2]) / 3) /
                  255;
          samples++;
        }
      }
      image.dispose();
      return total / samples;
    });
    return darkness!;
  }

  Future<void> tapCell(WidgetTester tester, int row, int col) async {
    final board = boardFinder;
    final topLeft = tester.getTopLeft(board);
    final cell = tester.getSize(board).width / boardSize;
    await tester.tapAt(
        topLeft + Offset(col * cell + cell / 2, row * cell + cell / 2));
    await tester.pump();
    // Explicit duration rather than pumpAndSettle: settling waits for the tree
    // to go quiet, and with animations plus off-screen image work it sat until
    // its ten-minute timeout instead of failing usefully.
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a tap actually DRAWS a star on the board', (tester) async {
    await pumpApp(tester);

    final before = await cellDarkness(tester, 0, 0);
    await tapCell(tester, 0, 0);
    final after = await cellDarkness(tester, 0, 0);

    expect(after, greaterThan(before + 0.15),
        reason: 'the tapped cell must become visibly darker because a filled '
            'star was painted into it. before=$before after=$after. If this '
            'fails the board is not drawing, whatever the counter says.');
  });

  testWidgets('the full cycle draws star, then cross, then clears',
      (tester) async {
    await pumpApp(tester);

    final empty = await cellDarkness(tester, 2, 3);

    await tapCell(tester, 2, 3);
    final star = await cellDarkness(tester, 2, 3);
    expect(star, greaterThan(empty + 0.15), reason: 'the star must be drawn');
    expect(find.text('1 of 6 stars'), findsOneWidget);

    await tapCell(tester, 2, 3);
    final cross = await cellDarkness(tester, 2, 3);
    expect(cross, lessThan(star - 0.10),
        reason: 'the cross is far lighter than the star, so darkness must drop');
    expect(find.text('0 of 6 stars'), findsOneWidget);

    await tapCell(tester, 2, 3);
    final cleared = await cellDarkness(tester, 2, 3);
    expect((cleared - empty).abs(), lessThan(0.05),
        reason: 'the third tap should return the cell to how it started');
  });

  testWidgets('placing every star of the real solution wins the game',
      (tester) async {
    await pumpApp(tester);

    // The solution comes from the oracle, so the test walks the same path a
    // player would rather than one invented for the test.
    final StarBattleSolution solution =
        oracle.findFirstSolution(entry.puzzle)!;

    expect(find.text('0 of 6 stars'), findsOneWidget,
        reason: 'the counter must start at zero');

    var placed = 0;
    for (final index in solution.starIndices) {
      await tapCell(tester, index ~/ boardSize, index % boardSize);
      placed++;

      final darkness =
          await cellDarkness(tester, index ~/ boardSize, index % boardSize);
      expect(darkness, greaterThan(0.20),
          reason: 'star $placed should be visible at cell $index');

      if (placed < solution.starIndices.length) {
        expect(find.text('$placed of 6 stars'), findsOneWidget,
            reason: 'the counter should read $placed after $placed taps');
      }
    }

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Solved!'), findsOneWidget,
        reason: 'the screen must declare victory once the board is correct');
  });

  testWidgets('two touching stars are both marked as a conflict',
      (tester) async {
    await pumpApp(tester);

    await tapCell(tester, 0, 0);
    await tapCell(tester, 0, 1);

    expect(find.text('2 of 6 stars'), findsOneWidget);

    final painter = livePainter(tester);
    expect(painter.conflicts, containsAll(<int>[0, 1]),
        reason: 'stars side by side break the no-touching rule, so both must '
            'be marked');
    expect(painter.conflictProgress, greaterThan(0.0),
        reason: 'the conflict ring must have animated in');
  });

  testWidgets('a star shades its eight neighbours', (tester) async {
    // The layer that teaches the rule without any text at all.
    await pumpApp(tester);
    await tapCell(tester, 2, 2);

    final painter = livePainter(tester);
    expect(painter.blocked.length, 8);
    expect(painter.blocked, containsAll(<int>[7, 8, 9, 13, 15, 19, 20, 21]));
  });

  testWidgets('the hint takes three taps: name, why, then apply',
      (tester) async {
    await pumpApp(tester);

    // Step one: the technique is named and the board is untouched.
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Technique:'), findsOneWidget,
        reason: 'the first tap must name the technique');

    final painterAfterStepOne = livePainter(tester);
    expect(painterAfterStepOne.grid.manual.every((c) => c == CellState.unknown),
        isTrue,
        reason: 'the first tap must NOT change the board — someone who wants '
            'to learn stops here');
    expect(painterAfterStepOne.hintEvidence, isNotEmpty,
        reason: 'step one shows where to look');
    expect(painterAfterStepOne.hintTargets, isEmpty,
        reason: 'step one must not reveal the conclusion');

    // Step two: the reasoning is spelled out, board still untouched.
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final painterAfterStepTwo = livePainter(tester);
    expect(painterAfterStepTwo.grid.manual.every((c) => c == CellState.unknown),
        isTrue,
        reason: 'the second tap explains, it does not solve');
    expect(painterAfterStepTwo.hintTargets, isNotEmpty,
        reason: 'step two may point at what the deduction concludes');

    // Step three: now it acts.
    await tester.tap(find.text('Hint'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('Technique:'), findsNothing,
        reason: 'the hint clears itself once applied');
    expect(livePainter(tester).grid.manual.where((c) => c != CellState.unknown),
        isNotEmpty,
        reason: 'the third tap must actually change the board');
  });

  testWidgets('undo and redo work from the buttons', (tester) async {
    await pumpApp(tester);

    await tapCell(tester, 0, 0);
    expect(find.text('1 of 6 stars'), findsOneWidget);
    final withStar = await cellDarkness(tester, 0, 0);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('0 of 6 stars'), findsOneWidget);
    expect(await cellDarkness(tester, 0, 0), lessThan(withStar - 0.15),
        reason: 'undo must erase the star from the SCREEN, not just the state');

    await tester.tap(find.text('Redo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 of 6 stars'), findsOneWidget);
    expect(await cellDarkness(tester, 0, 0), greaterThan(withStar - 0.05),
        reason: 'redo must put it back on screen');
  });

  testWidgets('clearing asks first and can itself be undone', (tester) async {
    await pumpApp(tester);
    await tapCell(tester, 0, 0);
    await tapCell(tester, 2, 2);
    expect(find.text('2 of 6 stars'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Clear the board?'), findsOneWidget,
        reason: 'wiping the board must never happen on a stray tap');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 6 stars'), findsOneWidget,
        reason: 'cancelling must leave the board alone');

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();
    expect(find.text('0 of 6 stars'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 of 6 stars'), findsOneWidget,
        reason: 'clearing by accident has to be recoverable');
  });

  group('layout fits one screen with no scrolling', () {
    for (final entry in <String, Size>{
      'cheap Android 360x640': Size(360, 640),
      'common phone 390x844': Size(390, 844),
      'tall phone 412x915': Size(412, 915),
      'wide desktop 1440x900': Size(1440, 900),
    }.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpApp(tester, surface: entry.value);

        // Any overflow paints the yellow-and-black stripes and records an
        // exception; a silent one would let a cropped board ship.
        expect(tester.takeException(), isNull);

        final board = tester.getSize(boardFinder);
        expect(board.width, board.height,
            reason: 'the board must always be square');
        expect(board.width, lessThanOrEqualTo(entry.value.width * 0.92 + 0.5),
            reason: 'the board must not exceed 92% of the width');
        expect(board.width, lessThanOrEqualTo(640.5),
            reason: 'the board is capped so a desktop does not get a wall of '
                'squares');
        expect(board.width, greaterThan(240),
            reason: 'cells must stay big enough for a fingertip');
        expect(tester.getBottomLeft(boardFinder).dy,
            lessThanOrEqualTo(entry.value.height),
            reason: 'the board must fit above the fold — the game never '
                'scrolls');
      });
    }
  });
}
