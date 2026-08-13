import '../../engine/core/cell_ref.dart';
import '../../engine/core/deduction.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/exhaustive_solver.dart';
import '../../engine/puzzles/star_battle/human_solver.dart';
import '../../engine/puzzles/star_battle/model.dart';
import 'play_grid.dart';

/// What the hint button found.
sealed class Hint {
  const Hint();
}

/// The player has already put something in the wrong place.
///
/// Deducing on top of a broken board would produce confident nonsense, so the
/// engine refuses and points at the mistake instead.
class MistakeHint extends Hint {
  const MistakeHint(this.wrongCells);

  /// Cells whose mark contradicts the real solution.
  final List<CellRef> wrongCells;
}

/// A real next step, named and explained.
class DeductionHint extends Hint {
  const DeductionHint(this.deduction);

  final Deduction deduction;
}

/// Nothing left to do.
class SolvedHint extends Hint {
  const SolvedHint();
}

/// No named technique applies. On a bank puzzle this cannot happen — PROP-2
/// proves every shipped puzzle is solvable by named techniques — so seeing it
/// means the board was reached some other way.
class StuckHint extends Hint {
  const StuckHint();
}

/// Finds the simplest next deduction available on the player's own board.
///
/// This is invariant P3 made concrete. The hint is not a canned sentence: it is
/// the output of the same human solver that rates difficulty, so what the
/// player is told is exactly the reasoning the puzzle was built to require.
class HintEngine {
  HintEngine(this.puzzle)
      : _truth = const StarBattleExhaustiveSolver().findFirstSolution(puzzle)!;

  final StarBattlePuzzle puzzle;

  /// Cached because the oracle is the slow one and the answer never changes.
  final StarBattleSolution _truth;

  final StarBattleHumanSolver _solver = StarBattleHumanSolver();

  /// Cells where the player contradicts the true solution.
  List<CellRef> mistakesIn(PlayGrid grid) {
    final truthStars = _truth.starIndices.toSet();
    final wrong = <CellRef>[];
    for (var index = 0; index < grid.cells.length; index++) {
      final state = grid.stateAt(index);
      final isTrueStar = truthStars.contains(index);
      if (state == CellState.star && !isTrueStar) {
        wrong.add(CellRef.fromIndex(index, puzzle.size));
      } else if (state == CellState.empty && isTrueStar) {
        wrong.add(CellRef.fromIndex(index, puzzle.size));
      }
    }
    return wrong;
  }

  bool isClean(PlayGrid grid) => mistakesIn(grid).isEmpty;

  Hint hintFor(PlayGrid grid) {
    if (grid.isSolved) {
      return const SolvedHint();
    }

    final mistakes = mistakesIn(grid);
    if (mistakes.isNotEmpty) {
      return MistakeHint(mistakes);
    }

    // Every mark the player has made is correct, so it is safe to hand them to
    // the solver as proven facts and ask what it would do next.
    final board = StarBattleBoard(puzzle);
    for (var index = 0; index < grid.cells.length; index++) {
      switch (grid.stateAt(index)) {
        case CellState.star:
          board.placeStar(index);
        case CellState.empty:
          board.markEmpty(index);
        case CellState.unknown:
          break;
      }
    }

    final deduction = _solver.nextHint(board);
    return deduction == null ? const StuckHint() : DeductionHint(deduction);
  }

  /// Applies a hint's conclusion to the board.
  PlayGrid apply(PlayGrid grid, Deduction deduction) {
    var next = grid;
    for (final ref in deduction.affectedCells) {
      next = next.withState(
        ref.toIndex(puzzle.size),
        deduction.kind == DeductionKind.assertion
            ? CellState.star
            : CellState.empty,
      );
    }
    return next;
  }
}
