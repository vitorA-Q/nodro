import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/model.dart';
import '../../engine/puzzles/star_battle/rules.dart';

/// The player's marks on a board, as an immutable snapshot.
///
/// ## Why immutable, and why that was a bug fix
///
/// Stage A kept one growable list and edited it in place. The painter received
/// that same list every rebuild, so comparing "old cells" against "new cells"
/// was comparing an object with itself: it always matched, `shouldRepaint`
/// always said no, and nothing was ever drawn. Taps registered, the counter
/// climbed, the board stayed blank.
///
/// Replacing the whole snapshot on every change makes "did anything change?"
/// answerable by identity, which removes the entire class of bug rather than
/// patching the one place it happened to surface. A 6x6 board is 36 enum
/// references; copying it is free next to a frame.
class PlayGrid {
  PlayGrid._(this.puzzle, List<CellState> cells)
      : cells = List<CellState>.unmodifiable(cells);

  factory PlayGrid.empty(StarBattlePuzzle puzzle) => PlayGrid._(
        puzzle,
        List<CellState>.filled(puzzle.size * puzzle.size, CellState.unknown),
      );

  static const StarBattleValidator _validator = StarBattleValidator();

  final StarBattlePuzzle puzzle;
  final List<CellState> cells;

  int get size => puzzle.size;

  /// Empty -> star -> cross -> empty.
  PlayGrid cycled(int index) {
    final next = List<CellState>.from(cells);
    next[index] = switch (cells[index]) {
      CellState.unknown => CellState.star,
      CellState.star => CellState.empty,
      CellState.empty => CellState.unknown,
    };
    return PlayGrid._(puzzle, next);
  }

  CellState stateAt(int index) => cells[index];

  /// A new snapshot with one cell set outright. Used when restoring a saved
  /// game, where the state is known rather than cycled into.
  PlayGrid withState(int index, CellState state) {
    final next = List<CellState>.from(cells);
    next[index] = state;
    return PlayGrid._(puzzle, next);
  }

  int get starCount {
    var count = 0;
    for (final state in cells) {
      if (state == CellState.star) {
        count++;
      }
    }
    return count;
  }

  List<int> get starIndices {
    final result = <int>[];
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] == CellState.star) {
        result.add(i);
      }
    }
    return result;
  }

  /// Cells touching a star, including diagonally, that do not hold a star.
  ///
  /// Shading these is how the board teaches the no-touching rule without a
  /// single word of instruction.
  Set<int> get blockedByAdjacency {
    final blocked = <int>{};
    for (final star in starIndices) {
      final row = star ~/ size;
      final col = star % size;
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) {
            continue;
          }
          final r = row + dr;
          final c = col + dc;
          if (r < 0 || r >= size || c < 0 || c >= size) {
            continue;
          }
          final index = r * size + c;
          if (cells[index] != CellState.star) {
            blocked.add(index);
          }
        }
      }
    }
    return blocked;
  }

  /// Stars that break a rule right now: touching another star, or sitting in a
  /// row, column or region that already holds its quota.
  ///
  /// Reported per star rather than per rule so the board can mark exactly the
  /// pieces at fault, and clear the moment the player fixes it.
  Set<int> get conflictingStars {
    final stars = starIndices;
    final conflicts = <int>{};

    for (var i = 0; i < stars.length; i++) {
      for (var j = i + 1; j < stars.length; j++) {
        final a = stars[i];
        final b = stars[j];
        final dr = (a ~/ size) - (b ~/ size);
        final dc = (a % size) - (b % size);
        if (dr.abs() <= 1 && dc.abs() <= 1) {
          conflicts..add(a)..add(b);
        }
      }
    }

    void flagOverfull(Map<int, List<int>> groups) {
      for (final group in groups.values) {
        if (group.length > puzzle.starsPerUnit) {
          conflicts.addAll(group);
        }
      }
    }

    final rows = <int, List<int>>{};
    final columns = <int, List<int>>{};
    final regions = <int, List<int>>{};
    for (final star in stars) {
      rows.putIfAbsent(star ~/ size, () => <int>[]).add(star);
      columns.putIfAbsent(star % size, () => <int>[]).add(star);
      regions.putIfAbsent(puzzle.regionOfCell[star], () => <int>[]).add(star);
    }
    flagOverfull(rows);
    flagOverfull(columns);
    flagOverfull(regions);

    return conflicts;
  }

  /// Decided by the same validator the property tests use, so what counts as a
  /// win on screen is exactly what counts as a win in the engine. Cross marks
  /// are a player aid and are ignored.
  bool get isSolved {
    if (starCount != puzzle.totalStars) {
      return false;
    }
    final masks = List<int>.filled(size, 0);
    for (final star in starIndices) {
      masks[star ~/ size] |= 1 << (star % size);
    }
    return _validator.isValidSolution(puzzle, StarBattleSolution(masks));
  }
}
