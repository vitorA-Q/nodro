import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/main.dart';

/// Stage A acceptance: the loop the player actually performs.
///
/// Loads the real bank asset rather than a fixture, because "the bank file the
/// app ships can be read and rendered" is precisely what could break.
void main() {
  /// Pumps the app and lets the asset read actually finish.
  ///
  /// Widget tests run on a fake clock, but `rootBundle.loadString` does real
  /// I/O outside it, so `pumpAndSettle` alone returns while the bank future is
  /// still pending and the screen is stuck on its loading message. `runAsync`
  /// hands time back to the real event loop for a moment.
  Future<void> pumpApp(WidgetTester tester) async {
    // The first frame AND the wait both have to happen inside runAsync.
    // Reading an asset goes over a platform channel that only answers on the
    // real event loop, and a widget test otherwise runs on a fake clock — so
    // pumping outside this block leaves the screen stuck on its loading state
    // forever, no matter how many frames are pumped afterwards.
    await tester.runAsync(() async {
      await tester.pumpWidget(const NodroApp());
      for (var attempt = 0; attempt < 40; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
        await tester.pump();
        if (find.byType(GestureDetector).evaluate().isNotEmpty) {
          return;
        }
      }
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .toList();
      fail('the board never appeared. On screen: $texts');
    });
    await tester.pumpAndSettle();
  }

  testWidgets('loads a puzzle from the bank and renders a board',
      (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('6×6'), findsOneWidget,
        reason: 'the board summary should name the board size');
    expect(find.text('0 of 6 stars'), findsOneWidget,
        reason: 'the star counter should start at zero');
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('tapping a cell cycles empty to star and on to a cross',
      (tester) async {
    await pumpApp(tester);

    final board = find.byType(GestureDetector).last;
    final topLeft = tester.getTopLeft(board);

    // First tap: a star appears, so the counter moves to one.
    await tester.tapAt(topLeft + const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.text('1 of 6 stars'), findsOneWidget,
        reason: 'one star should be counted after the first tap');

    // Second tap: the star becomes a cross, so the counter returns to zero.
    await tester.tapAt(topLeft + const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.text('0 of 6 stars'), findsOneWidget,
        reason: 'the star should be gone once the cell shows a cross');

    // Third tap: back to empty, and the counter stays at zero.
    await tester.tapAt(topLeft + const Offset(12, 12));
    await tester.pumpAndSettle();
    expect(find.text('0 of 6 stars'), findsOneWidget,
        reason: 'the cycle should return the cell to empty');
  });
}
