import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/model.dart';
import '../../engine/puzzles/star_battle/rules.dart';

/// How much the board marks for the player.
///
/// The middle setting is the default. Marking nothing makes the game hostile to
/// a newcomer; marking everything is what the genre's most popular apps do and
/// is why they are approachable — so the answer is to offer both rather than to
/// pick a side.
enum AutoMarkLevel {
  /// Nothing is marked. For the purist.
  off,

  /// Only the eight cells around a star.
  neighbours,

  /// Neighbours, plus any row, column or region that has met its quota.
  full;

  String get storageKey => name;

  static AutoMarkLevel fromKey(String? key) {
    for (final level in AutoMarkLevel.values) {
      if (level.name == key) {
        return level;
      }
    }
    return AutoMarkLevel.full;
  }
}

/// The player's marks on a board, as an immutable snapshot.
///
/// ## Two layers, one derived
///
/// [manual] is what the player put down. Automatic eliminations are NOT stored:
/// they are recomputed from the manual stars every time. That is what makes
/// "removing a star removes its automatic marks but not mine" fall out for
/// free, instead of needing bookkeeping about which star produced which mark.
///
/// ## Why immutable
///
/// Stage A kept one growable list and edited it in place. The painter received
/// that same list every rebuild, so comparing old against new compared an
/// object with itself: it always matched, `shouldRepaint` always said no, and
/// nothing was ever drawn. Replacing the whole snapshot makes "did anything
/// change" answerable by identity.
class PlayGrid {
  PlayGrid._(this.puzzle, List<CellState> manual, this.autoMark)
      : manual = List<CellState>.unmodifiable(manual),
        _auto = _deriveAuto(puzzle, manual, autoMark);

  factory PlayGrid.empty(StarBattlePuzzle puzzle,
          [AutoMarkLevel autoMark = AutoMarkLevel.full]) =>
      PlayGrid._(
        puzzle,
        List<CellState>.filled(puzzle.size * puzzle.size, CellState.unknown),
        autoMark,
      );

  static const StarBattleValidator _validator = StarBattleValidator();

  final StarBattlePuzzle puzzle;

  /// Exactly what the player marked, with nothing inferred.
  final List<CellState> manual;

  final AutoMarkLevel autoMark;

  /// Cells eliminated by the board on the player's behalf.
  final Set<int> _auto;

  int get size => puzzle.size;

  /// The canonical rule, written once so it covers every star count.
  ///
  /// A line is only cleared when its QUOTA is met — which on a one-star board
  /// happens with the first star, and on a two-star board only with the second.
  /// Writing it as "a star clears its line" would be right for 1★ and wrong for
  /// 2★, and the bug would only show up on the larger boards.
  static Set<int> _deriveAuto(
      StarBattlePuzzle puzzle, List<CellState> manual, AutoMarkLevel level) {
    if (level == AutoMarkLevel.off) {
      return const <int>{};
    }
    final size = puzzle.size;
    final stars = <int>[];
    for (var i = 0; i < manual.length; i++) {
      if (manual[i] == CellState.star) {
        stars.add(i);
      }
    }
    if (stars.isEmpty) {
      return const <int>{};
    }

    final auto = <int>{};

    for (final star in stars) {
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
          auto.add(r * size + c);
        }
      }
    }

    if (level == AutoMarkLevel.full) {
      final rowCount = List<int>.filled(size, 0);
      final colCount = List<int>.filled(size, 0);
      final regionCount = List<int>.filled(size, 0);
      for (final star in stars) {
        rowCount[star ~/ size]++;
        colCount[star % size]++;
        regionCount[puzzle.regionOfCell[star]]++;
      }
      for (var cell = 0; cell < manual.length; cell++) {
        if (rowCount[cell ~/ size] >= puzzle.starsPerUnit ||
            colCount[cell % size] >= puzzle.starsPerUnit ||
            regionCount[puzzle.regionOfCell[cell]] >= puzzle.starsPerUnit) {
          auto.add(cell);
        }
      }
    }

    auto.removeAll(stars);
    return auto;
  }

  /// What the player sees. Manual marks win; automatic elimination fills in.
  CellState stateAt(int index) {
    final own = manual[index];
    if (own != CellState.unknown) {
      return own;
    }
    return _auto.contains(index) ? CellState.empty : CellState.unknown;
  }

  /// Whether this cell was eliminated by the board rather than by the player.
  /// Drawn lighter, so what the player did stays visible as theirs.
  bool isAuto(int index) =>
      manual[index] == CellState.unknown && _auto.contains(index);

  /// Empty -> star -> cross -> empty, on the manual layer only.
  PlayGrid cycled(int index) {
    final next = List<CellState>.from(manual);
    next[index] = switch (manual[index]) {
      CellState.unknown => CellState.star,
      CellState.star => CellState.empty,
      CellState.empty => CellState.unknown,
    };
    return PlayGrid._(puzzle, next, autoMark);
  }

  /// Sets one cell outright. Used when restoring a saved game and when a hint
  /// applies its conclusion.
  PlayGrid withState(int index, CellState state) {
    final next = List<CellState>.from(manual);
    next[index] = state;
    return PlayGrid._(puzzle, next, autoMark);
  }

  PlayGrid withAutoMark(AutoMarkLevel level) =>
      PlayGrid._(puzzle, manual, level);

  int get starCount {
    var count = 0;
    for (final state in manual) {
      if (state == CellState.star) {
        count++;
      }
    }
    return count;
  }

  List<int> get starIndices {
    final result = <int>[];
    for (var i = 0; i < manual.length; i++) {
      if (manual[i] == CellState.star) {
        result.add(i);
      }
    }
    return result;
  }

  /// Cells touching a star that do not themselves hold one.
  ///
  /// Shading these is how the board teaches the no-touching rule without a
  /// single word, and it stays even when automatic marking is off.
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
          if (manual[index] != CellState.star) {
            blocked.add(index);
          }
        }
      }
    }
    return blocked;
  }

  /// Stars that break a rule right now, reported per star so the board can mark
  /// exactly the pieces at fault and clear the moment they are fixed.
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

  /// Decided by the same validator the property tests use, so a win on screen
  /// is exactly a win in the engine. Cross marks are an aid and are ignored.
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
