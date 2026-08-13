import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/ui/game/play_grid.dart';
import 'package:nodro/ui/painters/star_battle_painter.dart';
import 'package:nodro/ui/theme/nodro_theme.dart';

/// Fast regression guard for the Stage A bug: taps registered in state but
/// nothing was ever drawn.
///
/// The screen kept ONE cell list and mutated it in place, then handed that same
/// list to every painter. `oldDelegate.cells` and `cells` were the very same
/// object, so an element-by-element comparison always matched, `shouldRepaint`
/// always said no, and the canvas never repainted. The counter still climbed,
/// because that is a plain Text rebuilt by setState — which is exactly why the
/// board looked empty while the counter read "6 of 6".
///
/// The fix was to replace the snapshot instead of editing it, so "did anything
/// change" is answerable by identity. These tests pin that down cheaply; the
/// pixel-level proof lives in play_screen_test.dart.
void main() {
  final puzzle = StarBattlePuzzle(
    size: 6,
    starsPerUnit: 1,
    regionOfCell: List<int>.generate(36, (i) => i ~/ 6),
  );

  StarBattlePainter painterFor(PlayGrid grid) => StarBattlePainter(
        grid: grid,
        palette: NodroPalette.light,
        blocked: grid.blockedByAdjacency,
        conflicts: grid.conflictingStars,
        placeProgress: 1,
        placedCell: null,
        conflictProgress: 0,
        winProgress: 0,
      );

  test('shouldRepaint sees a placed star', () {
    final empty = PlayGrid.empty(puzzle);
    final withStar = empty.cycled(0);

    expect(painterFor(withStar).shouldRepaint(painterFor(empty)), isTrue,
        reason: 'the painter must repaint after a cell changes, or marks never '
            'appear on screen no matter how many taps land');
  });

  test('shouldRepaint stays false when nothing changed', () {
    final grid = PlayGrid.empty(puzzle);
    expect(painterFor(grid).shouldRepaint(painterFor(grid)), isFalse,
        reason: 'repainting every frame would waste the RepaintBoundary');
  });

  test('cycling never edits the previous snapshot', () {
    final empty = PlayGrid.empty(puzzle);
    final withStar = empty.cycled(0);

    expect(empty.starCount, 0,
        reason: 'the older snapshot must be untouched — sharing one mutable '
            'list between frames is precisely what broke the board');
    expect(withStar.starCount, 1);
    expect(identical(empty.manual, withStar.manual), isFalse);
  });

  test('a star shades its eight neighbours and nothing further', () {
    // The teaching layer: this is what explains the no-touching rule without
    // any text at all.
    final grid = PlayGrid.empty(puzzle).cycled(14); // row 2, col 2
    expect(grid.blockedByAdjacency,
        containsAll(<int>[7, 8, 9, 13, 15, 19, 20, 21]));
    expect(grid.blockedByAdjacency.length, 8);
    expect(grid.blockedByAdjacency.contains(14), isFalse,
        reason: 'the star cell itself is not shaded');
  });

  test('touching stars are both reported as conflicts', () {
    final grid = PlayGrid.empty(puzzle).cycled(0).cycled(1);
    expect(grid.conflictingStars, <int>{0, 1});
  });

  test('stars in the same row conflict once the quota is exceeded', () {
    // Region 0 is the whole first row here, so two stars break row, region and
    // adjacency all at once; three cells apart isolates the counting rule.
    final grid = PlayGrid.empty(puzzle).cycled(0).cycled(3);
    expect(grid.conflictingStars, containsAll(<int>[0, 3]));
  });

  test('a lone star is never a conflict', () {
    expect(PlayGrid.empty(puzzle).cycled(0).conflictingStars, isEmpty);
  });
}
