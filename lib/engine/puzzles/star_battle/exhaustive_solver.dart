import '../../core/puzzle_type.dart';
import '../../core/solve_result.dart';
import 'model.dart';

/// The ORACLE (C3). Correct by construction, deliberately unclever.
///
/// Searches row by row over the pre-enumerated set of legal star placements for
/// a single row, pruning on column and region capacity. It counts solutions
/// with an early exit on the second, because the only question P1 asks is
/// "exactly one?" — never "how many".
///
/// This class must stay easy to audit. Every optimisation here is a bit-level
/// rewrite of a rule, never a heuristic: a heuristic in the oracle would make
/// the entire test harness meaningless.
class StarBattleExhaustiveSolver
    implements ExhaustiveSolver<StarBattlePuzzle, StarBattleSolution> {
  const StarBattleExhaustiveSolver();

  @override
  SolutionCount countSolutions(StarBattlePuzzle puzzle) {
    final search = _Search(puzzle, solutionLimit: 2);
    search.run();
    switch (search.solutionsFound) {
      case 0:
        return SolutionCount.none;
      case 1:
        return SolutionCount.unique;
      default:
        return SolutionCount.multiple;
    }
  }

  @override
  StarBattleSolution? findFirstSolution(StarBattlePuzzle puzzle) {
    final search = _Search(puzzle, solutionLimit: 1);
    search.run();
    return search.firstSolution;
  }

  /// Returns up to [limit] distinct solutions.
  ///
  /// The generator needs the actual second solution, not just the knowledge that
  /// one exists: knowing *where* the intruder puts its stars is what turns
  /// region refinement from a random walk into a directed move that is
  /// guaranteed to kill that intruder.
  List<StarBattleSolution> findSolutions(StarBattlePuzzle puzzle, int limit) {
    final search = _Search(puzzle, solutionLimit: limit, collectAll: true);
    search.run();
    return search.collected;
  }

  /// Counts solutions, stopping once [cap] have been found.
  ///
  /// [countSolutions] answers the only question P1 asks, but the generator needs
  /// a *gradient*: "47 solutions" and "2 solutions" are both `multiple`, yet one
  /// is far closer to a shippable puzzle. Hill-climbing region boundaries needs
  /// to tell them apart.
  int countSolutionsUpTo(StarBattlePuzzle puzzle, int cap) {
    final search = _Search(puzzle, solutionLimit: cap);
    search.run();
    return search.solutionsFound;
  }

  /// Enumerates every legal placement of `k` stars within a single row of
  /// [size] columns: exactly `k` bits set, no two of them adjacent.
  ///
  /// Exposed for tests and for the human solver's placement enumeration, so the
  /// two never drift apart on what "legal within a row" means.
  static List<int> rowPlacements(int size, int k) {
    final results = <int>[];
    final full = (1 << size) - 1;
    for (var mask = 0; mask <= full; mask++) {
      if (_popCount(mask) != k) {
        continue;
      }
      if ((mask & (mask << 1)) != 0) {
        continue; // two stars side by side in the same row
      }
      results.add(mask);
    }
    return results;
  }

  static int _popCount(int mask) {
    var count = 0;
    var value = mask;
    while (value != 0) {
      value &= value - 1;
      count++;
    }
    return count;
  }
}

/// One depth-first search over rows. Mutable, single-use, never shared.
class _Search {
  _Search(this.puzzle, {required this.solutionLimit, this.collectAll = false})
      : size = puzzle.size,
        k = puzzle.starsPerUnit,
        placements =
            StarBattleExhaustiveSolver.rowPlacements(puzzle.size, puzzle.starsPerUnit),
        colCounts = List<int>.filled(puzzle.size, 0),
        regionCounts = List<int>.filled(puzzle.size, 0),
        chosen = List<int>.filled(puzzle.size, 0),
        regionCellsFromRow = _buildRegionSuffixCounts(puzzle);

  final StarBattlePuzzle puzzle;
  final int size;
  final int k;
  final int solutionLimit;

  /// When true every solution found is kept, not just the first.
  final bool collectAll;
  final List<int> placements;
  final List<int> colCounts;
  final List<int> regionCounts;
  final List<int> chosen;

  /// `regionCellsFromRow[row][region]` is how many cells of [region] live in
  /// rows `row..size-1`. Used to prove a region can still reach its quota.
  final List<List<int>> regionCellsFromRow;

  int solutionsFound = 0;
  StarBattleSolution? firstSolution;
  final List<StarBattleSolution> collected = <StarBattleSolution>[];

  void run() => _searchRow(0, 0);

  static List<List<int>> _buildRegionSuffixCounts(StarBattlePuzzle puzzle) {
    final size = puzzle.size;
    final counts = List<List<int>>.generate(
        size + 1, (_) => List<int>.filled(size, 0),
        growable: false);
    for (var row = size - 1; row >= 0; row--) {
      for (var region = 0; region < size; region++) {
        counts[row][region] = counts[row + 1][region];
      }
      for (var col = 0; col < size; col++) {
        counts[row][puzzle.regionAt(row, col)]++;
      }
    }
    return counts;
  }

  void _searchRow(int row, int previousMask) {
    if (solutionsFound >= solutionLimit) {
      return;
    }
    if (row == size) {
      _recordSolution();
      return;
    }

    // Cells of the previous row that forbid a star directly above-adjacent,
    // including both diagonals.
    final blocked =
        (previousMask | (previousMask << 1) | (previousMask >> 1)) &
            puzzle.fullRowMask;

    final rowsLeftAfterThis = size - row - 1;

    for (final placement in placements) {
      if ((placement & blocked) != 0) {
        continue;
      }
      if (!_applyRow(row, placement)) {
        _undoRow(row, placement);
        continue;
      }
      if (_stillFeasible(row, rowsLeftAfterThis)) {
        chosen[row] = placement;
        _searchRow(row + 1, placement);
      }
      _undoRow(row, placement);
      if (solutionsFound >= solutionLimit) {
        return;
      }
    }
  }

  /// Applies [placement] to the running counters and reports whether every
  /// quota still holds.
  ///
  /// CRITICAL: this must apply **all** of [placement] even when a quota is
  /// already blown, because [_undoRow] reverses all of it unconditionally. An
  /// earlier version returned early on the first overflow, so undo decremented
  /// counters that had never been incremented; the counters drifted negative,
  /// the feasibility prune then discarded valid branches, and the oracle
  /// reported "no solution" for puzzles that demonstrably had one. Apply and
  /// undo must stay exact mirrors of each other.
  bool _applyRow(int row, int placement) {
    var withinQuota = true;
    var mask = placement;
    while (mask != 0) {
      final bit = mask & -mask;
      final col = _bitIndex(bit);
      mask ^= bit;
      if (++colCounts[col] > k) {
        withinQuota = false;
      }
      final region = puzzle.regionAt(row, col);
      if (++regionCounts[region] > k) {
        withinQuota = false;
      }
    }
    return withinQuota;
  }

  void _undoRow(int row, int placement) {
    var mask = placement;
    while (mask != 0) {
      final bit = mask & -mask;
      final col = _bitIndex(bit);
      mask ^= bit;
      colCounts[col]--;
      regionCounts[puzzle.regionAt(row, col)]--;
    }
  }

  /// Both checks are capacity relaxations: they only ever report "this branch
  /// cannot possibly reach the quota", which is why pruning here can never
  /// discard a real solution.
  bool _stillFeasible(int row, int rowsLeftAfterThis) {
    for (var col = 0; col < size; col++) {
      if (k - colCounts[col] > rowsLeftAfterThis) {
        return false;
      }
    }
    final available = regionCellsFromRow[row + 1];
    for (var region = 0; region < size; region++) {
      if (k - regionCounts[region] > available[region]) {
        return false;
      }
    }
    return true;
  }

  void _recordSolution() {
    solutionsFound++;
    final solution = StarBattleSolution(List<int>.from(chosen));
    firstSolution ??= solution;
    if (collectAll) {
      collected.add(solution);
    }
  }

  static int _bitIndex(int isolatedBit) {
    var index = 0;
    var bit = isolatedBit;
    while (bit > 1) {
      bit >>= 1;
      index++;
    }
    return index;
  }
}
