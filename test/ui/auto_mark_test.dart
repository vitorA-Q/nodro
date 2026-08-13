import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/ui/game/play_grid.dart';

/// Automatic marking, and the one rule that makes it correct on both board
/// families.
///
/// The tempting shortcut is "a star clears its row and column". That is right
/// on a one-star board and WRONG on a two-star board, where the row still needs
/// a second star — and the bug would only ever appear on the larger puzzles,
/// which are the ones least often tested. The rule is written once, in terms of
/// the unit's QUOTA, and these tests pin both cases.
void main() {
  const serializer = StarBattleSerializer();

  StarBattlePuzzle load(String file, String prefix) {
    final line = File('assets/bank/$file')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith(prefix));
    return serializer.deserialize(line.substring(line.indexOf('|') + 1));
  }

  group('one star per unit', () {
    late StarBattlePuzzle puzzle;
    setUp(() => puzzle = load('star_battle_6x6_1.txt', '2|'));

    test('full marking clears the whole row and column at once', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.full).cycled(14);

      for (var col = 0; col < 6; col++) {
        final index = 2 * 6 + col;
        if (index == 14) {
          continue;
        }
        expect(grid.stateAt(index), CellState.empty,
            reason: 'row 3 has its only star, so cell $index must be cleared');
      }
      for (var row = 0; row < 6; row++) {
        final index = row * 6 + 2;
        if (index == 14) {
          continue;
        }
        expect(grid.stateAt(index), CellState.empty,
            reason: 'column 3 has its only star, so cell $index must be '
                'cleared');
      }
    });

    test('neighbours-only marking leaves the rest of the line alone', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.neighbours).cycled(14);

      expect(grid.stateAt(13), CellState.empty, reason: 'adjacent');
      expect(grid.stateAt(17), CellState.unknown,
          reason: 'same row but three cells away — not adjacent, and this '
              'level does not do line clearing');
    });

    test('off marks nothing at all', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.off).cycled(14);
      for (var i = 0; i < 36; i++) {
        if (i == 14) {
          continue;
        }
        expect(grid.stateAt(i), CellState.unknown);
      }
    });
  });

  group('two stars per unit', () {
    late StarBattlePuzzle puzzle;
    setUp(() => puzzle = load('star_battle_9x9_2.txt', '3|'));

    test('the first star does NOT clear its line', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.full).cycled(4 * 9 + 4);

      // Far enough along the row to be outside the eight-neighbour halo.
      expect(grid.stateAt(4 * 9 + 8), CellState.unknown,
          reason: 'the row still needs a second star, so clearing it here '
              'would be wrong. This is exactly the case a "star clears its '
              'row" shortcut gets wrong.');
      expect(grid.stateAt(8 * 9 + 4), CellState.unknown,
          reason: 'same for the column');
    });

    test('the first star still blocks its eight neighbours', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.full).cycled(4 * 9 + 4);
      expect(grid.stateAt(4 * 9 + 5), CellState.empty);
      expect(grid.stateAt(3 * 9 + 3), CellState.empty);
    });

    test('the second star in a row clears what is left of it', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.full)
          .cycled(4 * 9 + 1)
          .cycled(4 * 9 + 4);

      expect(grid.starCount, 2);
      expect(grid.stateAt(4 * 9 + 8), CellState.empty,
          reason: 'the row quota is met now, so the rest of it clears');
    });
  });

  group('automatic marks stay separate from the player\'s own', () {
    late StarBattlePuzzle puzzle;
    setUp(() => puzzle = load('star_battle_6x6_1.txt', '2|'));

    test('removing the star removes its marks and keeps mine', () {
      // A cross the player placed by hand, far from the star.
      var grid = PlayGrid.empty(puzzle, AutoMarkLevel.full)
          .withState(35, CellState.empty)
          .cycled(0);

      expect(grid.isAuto(1), isTrue, reason: 'marked by the board');
      expect(grid.isAuto(35), isFalse, reason: 'marked by the player');

      grid = grid.withState(0, CellState.unknown);

      expect(grid.stateAt(1), CellState.unknown,
          reason: 'the automatic marks belonged to that star and go with it');
      expect(grid.stateAt(35), CellState.empty,
          reason: 'my own mark must survive — the board does not get to erase '
              'my decisions');
    });

    test('changing the level never touches the manual layer', () {
      final full = PlayGrid.empty(puzzle, AutoMarkLevel.full)
          .withState(35, CellState.empty)
          .cycled(0);
      final off = full.withAutoMark(AutoMarkLevel.off);

      expect(off.manual, full.manual);
      expect(off.stateAt(35), CellState.empty);
      expect(off.stateAt(1), CellState.unknown);
      expect(off.starCount, 1);
    });

    test('a star is never reported as an automatic mark', () {
      final grid = PlayGrid.empty(puzzle, AutoMarkLevel.full).cycled(0);
      expect(grid.isAuto(0), isFalse);
      expect(grid.stateAt(0), CellState.star);
    });
  });
}
