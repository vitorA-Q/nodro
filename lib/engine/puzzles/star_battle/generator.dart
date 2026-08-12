import '../../core/deterministic_random.dart';
import '../../core/puzzle_type.dart';
import '../../core/solve_result.dart';
import '../../core/technique_tier.dart';
import 'exhaustive_solver.dart';
import 'human_solver.dart';
import 'model.dart';
import 'rules.dart';

/// Solution-first Star Battle generator.
///
/// Sampling a star configuration first and building regions around it means the
/// puzzle is born with at least one solution, so the "zero solutions" failure
/// mode cannot occur — the generator can only ever err toward *too many*
/// solutions, which is the cheap side to detect.
///
/// Nothing leaves this class without passing the exhaustive solver (X2) and the
/// human solver (PROP-2).
///
/// ## PROP-6 (minimality) is NOT APPLICABLE to Star Battle
///
/// This is a recorded decision, not an omission and not deferred work.
///
/// Star Battle has no removable clues: the region partition IS the clue. The
/// substitute originally proposed — that no single cell may change region and
/// still leave a uniquely solvable puzzle — was implemented and then measured,
/// and the measurement killed it. From `tool/diagnose.dart`, over 48 generated
/// puzzles across three sizes:
///
/// | board     | legal boundary moves | still unique | fully rigid |
/// |-----------|---------------------|--------------|-------------|
/// | 6x6 / 1   | 26.5 per puzzle     | 62.6%        | 0 of 25     |
/// | 8x8 / 1   | 44.5 per puzzle     | 63.6%        | 0 of 15     |
/// | 9x9 / 2   | 56.1 per puzzle     | 71.7%        | 0 of 8      |
///
/// Roughly two thirds of legal single-cell region changes leave the puzzle
/// still uniquely solvable, and no puzzle is rigid. Enabling the gate made
/// generation fail after 4,000 consecutive attempts on a 6x6 board.
///
/// The reason is structural, not a weak generator: a cell deep inside a region,
/// far from any star, carries no information at all, so moving it between
/// regions cannot change any deduction. Star Battle behaves like Shikaku here —
/// there is no meaningful clue-removal analogue to test.
///
/// **What guards against a flabby puzzle instead is the two-sided PROP-3**
/// (decision D4): a puzzle is only labelled tier `d` if the human solver
/// succeeds with techniques up to `d` AND fails with techniques up to `d - 1`.
/// That makes the hardest technique provably *required*, not merely used.
class StarBattleGenerator
    implements PuzzleGenerator<StarBattlePuzzle, StarBattleSolution> {
  StarBattleGenerator({
    required this.size,
    required this.starsPerUnit,
    this.maxAttempts = 4000,
  });

  final int size;
  final int starsPerUnit;

  /// Fails loudly rather than returning something unverified (X1). A generator
  /// that exhausts this budget is a real defect worth surfacing, not a case to
  /// paper over with a fallback puzzle.
  final int maxAttempts;

  static const StarBattleExhaustiveSolver _oracle = StarBattleExhaustiveSolver();
  static const StarBattleValidator _validator = StarBattleValidator();
  final StarBattleHumanSolver _humanSolver = StarBattleHumanSolver();

  @override
  GeneratedPuzzle<StarBattlePuzzle, StarBattleSolution> generate(int seed) {
    final rng = DeterministicRandom(seed);
    var attempts = 0;

    while (attempts < maxAttempts) {
      attempts++;

      final solution = _sampleSolution(rng);
      if (solution == null) {
        continue;
      }
      final initialRegions = _buildRegions(rng, solution);
      if (initialRegions == null) {
        continue;
      }

      // Random region layouts are almost never unique — measured at roughly 1
      // in 300 — so resampling from scratch is hopeless. Instead hill-climb the
      // boundaries toward uniqueness, which is what makes generation tractable.
      final regionOfCell = _refineToUnique(rng, initialRegions, solution);
      if (regionOfCell == null) {
        continue;
      }

      final puzzle = StarBattlePuzzle(
        size: size,
        starsPerUnit: starsPerUnit,
        regionOfCell: regionOfCell,
      );

      // The sampled configuration must actually be a solution of the puzzle we
      // just built. If this ever fails, region building is broken.
      if (!_validator.isValidSolution(puzzle, solution)) {
        continue;
      }
      if (_validator.puzzleViolations(puzzle).isNotEmpty) {
        continue;
      }
      if (_oracle.countSolutions(puzzle) != SolutionCount.unique) {
        continue;
      }
      // NOTE: there is deliberately no minimality gate here. See the PROP-6
      // note in the class doc comment.
      final tier = _humanSolver.rateDifficulty(puzzle);
      if (tier == null) {
        continue; // needs guessing — outside the declared envelope (PROP-2)
      }

      return GeneratedPuzzle<StarBattlePuzzle, StarBattleSolution>(
        puzzle: puzzle,
        solution: solution,
        seed: seed,
        tier: tier,
        attempts: attempts,
      );
    }

    throw StateError('StarBattleGenerator gave up after $maxAttempts attempts '
        'for ${size}x$size with $starsPerUnit star(s), seed $seed');
  }

  /// Generates a puzzle whose difficulty is exactly [tier], by resampling.
  ///
  /// Used to fill the pre-generated bank evenly across the four difficulties
  /// (decision D2).
  GeneratedPuzzle<StarBattlePuzzle, StarBattleSolution>? generateAtTier(
    int seed,
    TechniqueTier tier, {
    int maxSeeds = 400,
  }) {
    for (var offset = 0; offset < maxSeeds; offset++) {
      final candidate = generate(seed + offset * 7919);
      if (candidate.tier == tier) {
        return candidate;
      }
    }
    return null;
  }

  // ------------------------------------------------------------ star sampling

  /// Stage hooks for `tool/diagnose.dart`. Measuring where the generation funnel
  /// narrows needs each stage in isolation, and guessing instead of measuring is
  /// how you end up "fixing" the wrong stage.
  StarBattleSolution? sampleSolutionForDiagnostics(DeterministicRandom rng) =>
      _sampleSolution(rng);

  List<int>? buildRegionsForDiagnostics(
          DeterministicRandom rng, StarBattleSolution solution) =>
      _buildRegions(rng, solution);

  /// Randomly samples a legal star configuration, ignoring regions.
  StarBattleSolution? _sampleSolution(DeterministicRandom rng) {
    final placements =
        StarBattleExhaustiveSolver.rowPlacements(size, starsPerUnit);
    final colCounts = List<int>.filled(size, 0);
    final chosen = List<int>.filled(size, 0);
    final fullMask = (1 << size) - 1;

    bool search(int row, int previousMask) {
      if (row == size) {
        return true;
      }
      final blocked =
          (previousMask | (previousMask << 1) | (previousMask >> 1)) & fullMask;
      final rowsLeftAfter = size - row - 1;

      final order = List<int>.from(placements);
      rng.shuffle(order);

      for (final placement in order) {
        if ((placement & blocked) != 0) {
          continue;
        }
        final columns = _columnsOf(placement);
        var overflow = false;
        for (final col in columns) {
          if (++colCounts[col] > starsPerUnit) {
            overflow = true;
          }
        }
        if (!overflow && _columnsStillReachable(colCounts, rowsLeftAfter)) {
          chosen[row] = placement;
          if (search(row + 1, placement)) {
            return true;
          }
        }
        for (final col in columns) {
          colCounts[col]--;
        }
      }
      return false;
    }

    if (!search(0, 0)) {
      return null;
    }
    return StarBattleSolution(List<int>.from(chosen));
  }

  bool _columnsStillReachable(List<int> colCounts, int rowsLeftAfter) {
    for (final count in colCounts) {
      if (starsPerUnit - count > rowsLeftAfter) {
        return false;
      }
    }
    return true;
  }

  static List<int> _columnsOf(int placement) {
    final columns = <int>[];
    var mask = placement;
    while (mask != 0) {
      final bit = mask & -mask;
      mask ^= bit;
      var index = 0;
      var value = bit;
      while (value > 1) {
        value >>= 1;
        index++;
      }
      columns.add(index);
    }
    return columns;
  }

  // ------------------------------------------------------ uniqueness refining

  /// Directed refinement steps before abandoning this star configuration.
  ///
  /// Measured, not guessed. Raising this to 6,000 made 9x9 generation *slower*
  /// (1,074 ms median versus 610 ms) while barely reducing the attempt count:
  /// the refinement cycles rather than converging, so a larger budget only buys
  /// a more expensive failure. Restarting from a fresh star configuration is the
  /// cheaper escape.
  static const int _maxRefineSteps = 400;

  // REVERTED, kept as a note so nobody re-derives the idea and re-pays for it:
  // scoring several candidate moves per step and keeping the one that left the
  // fewest solutions. The hypothesis was that a random pick resurrects earlier
  // intruders and makes the search cycle. Measurement disagreed — 9x9 median
  // went from 610 ms to 904 ms, because the extra oracle calls per step cost
  // more than the better move saved.

  /// Reshapes region boundaries until the puzzle has exactly one solution.
  ///
  /// This is a **directed** repair, not a random walk. Each step asks the oracle
  /// for a second solution — the "intruder" — and then moves one cell that the
  /// intruder stars into a neighbouring region. Because the intruder is a valid
  /// solution of the current layout, the region it takes that star from holds
  /// exactly `k` intruder stars; taking the cell away drops it to `k - 1`, so
  /// the intruder is destroyed by construction. Every step therefore makes real
  /// progress instead of hoping to stumble into it.
  ///
  /// Only cells that the INTENDED solution does not star are ever moved. That is
  /// what keeps the intended solution valid throughout: moving a cell holding no
  /// intended star cannot change any region's intended star count, so the
  /// sampled configuration stays a solution of every intermediate puzzle and the
  /// search never wanders into "zero solutions".
  ///
  /// An earlier version hill-climbed on the solution *count* with random moves.
  /// It stalled: once the count reached two or three, a random single-cell move
  /// almost never improved it, and the search burned its whole budget sitting in
  /// a local minimum.
  List<int>? _refineToUnique(
      DeterministicRandom rng, List<int> initial, StarBattleSolution solution) {
    final intendedStars = solution.starIndices.toSet();
    var current = List<int>.from(initial);

    for (var step = 0; step < _maxRefineSteps; step++) {
      final puzzle = StarBattlePuzzle(
        size: size,
        starsPerUnit: starsPerUnit,
        regionOfCell: current,
      );
      final solutions = _oracle.findSolutions(puzzle, 2);
      if (solutions.isEmpty) {
        return null; // cannot happen while the intended solution is preserved
      }
      if (solutions.length == 1) {
        return current;
      }

      final intruder =
          solutions.firstWhere((candidate) => candidate != solution,
              orElse: () => solutions.last);
      // The directed move is the fast path. When the geometry blocks it — a
      // narrow region that would disconnect, or one already down to its minimum
      // size — fall back to a plain legal boundary move rather than abandoning
      // the whole star configuration. Abandoning was measured at ~1,600 wasted
      // attempts per 9x9 puzzle; the fallback keeps the search alive.
      final next = _breakIntruder(rng, current, intendedStars, intruder) ??
          _randomBoundaryMove(rng, current, intendedStars);
      if (next == null) {
        return null;
      }
      current = next;
    }
    return null;
  }

  /// Any legal single-cell region change, used when the directed move is blocked.
  List<int>? _randomBoundaryMove(
      DeterministicRandom rng, List<int> owner, Set<int> intendedStars) {
    final cellCount = size * size;
    final regionSizes = List<int>.filled(size, 0);
    for (final region in owner) {
      regionSizes[region]++;
    }

    final start = rng.nextInt(cellCount);
    for (var offset = 0; offset < cellCount; offset++) {
      final cell = (start + offset) % cellCount;
      if (intendedStars.contains(cell)) {
        continue; // moving an intended star would change a region's quota
      }
      final from = owner[cell];
      if (regionSizes[from] - 1 < starsPerUnit) {
        continue;
      }
      final targets = <int>[];
      for (final neighbour in _orthogonalNeighbours(cell)) {
        final to = owner[neighbour];
        if (to != from && !targets.contains(to)) {
          targets.add(to);
        }
      }
      if (targets.isEmpty || !_staysConnectedWithout(owner, from, cell)) {
        continue;
      }
      final candidate = List<int>.from(owner);
      candidate[cell] = rng.pick(targets);
      return candidate;
    }
    return null;
  }

  /// Moves one cell starred by [intruder] but not by the intended solution into
  /// an adjacent region, which invalidates [intruder].
  ///
  /// Takes the first legal move in a shuffled order rather than evaluating
  /// several — see the reverted-optimisation note above for the measurement.
  List<int>? _breakIntruder(
    DeterministicRandom rng,
    List<int> owner,
    Set<int> intendedStars,
    StarBattleSolution intruder,
  ) {
    final movable = intruder.starIndices
        .where((cell) => !intendedStars.contains(cell))
        .toList();
    if (movable.isEmpty) {
      return null;
    }
    rng.shuffle(movable);

    final regionSizes = List<int>.filled(size, 0);
    for (final region in owner) {
      regionSizes[region]++;
    }

    for (final cell in movable) {
      final from = owner[cell];
      // The source region must keep enough cells to seat its own stars.
      if (regionSizes[from] - 1 < starsPerUnit) {
        continue;
      }
      final targets = <int>[];
      for (final neighbour in _orthogonalNeighbours(cell)) {
        final to = owner[neighbour];
        if (to != from && !targets.contains(to)) {
          targets.add(to);
        }
      }
      if (targets.isEmpty || !_staysConnectedWithout(owner, from, cell)) {
        continue;
      }
      final candidate = List<int>.from(owner);
      candidate[cell] = rng.pick(targets);
      return candidate;
    }
    return null;
  }

  /// Whether [region] is still orthogonally connected once [removed] leaves it.
  bool _staysConnectedWithout(List<int> owner, int region, int removed) {
    final members = <int>[];
    for (var cell = 0; cell < owner.length; cell++) {
      if (owner[cell] == region && cell != removed) {
        members.add(cell);
      }
    }
    if (members.isEmpty) {
      return false;
    }
    final seen = <int>{members.first};
    final stack = <int>[members.first];
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      for (final neighbour in _orthogonalNeighbours(cell)) {
        if (neighbour == removed ||
            owner[neighbour] != region ||
            seen.contains(neighbour)) {
          continue;
        }
        seen.add(neighbour);
        stack.add(neighbour);
      }
    }
    return seen.length == members.length;
  }

  // --------------------------------------------------------- region building

  /// Groups the stars into [size] clusters of [starsPerUnit], links each
  /// cluster with a corridor so the region is guaranteed connected, then grows
  /// the regions outward until every cell is claimed.
  ///
  /// Returns null when the corridors collide, which just means this random
  /// attempt is unusable — the caller resamples.
  List<int>? _buildRegions(DeterministicRandom rng, StarBattleSolution solution) {
    final stars = solution.starIndices;
    if (stars.length != size * starsPerUnit) {
      return null;
    }

    // Corridors collide often at k = 2 — measured at 30-55% of attempts — and a
    // collision is purely bad luck in the clustering, not a bad star layout. A
    // few local retries are far cheaper than resampling the whole solution.
    for (var retry = 0; retry < 12; retry++) {
      final groups = _groupStars(rng, stars);
      if (groups == null) {
        continue;
      }

      final owner = List<int>.filled(size * size, -1);
      var collided = false;
      for (var region = 0; region < groups.length && !collided; region++) {
        for (final cell in _corridorFor(groups[region])) {
          if (owner[cell] != -1 && owner[cell] != region) {
            collided = true;
            break;
          }
          owner[cell] = region;
        }
      }
      if (collided) {
        continue;
      }

      _growRegions(rng, owner);
      if (owner.every((region) => region >= 0)) {
        return owner;
      }
    }
    return null;
  }

  /// Greedy nearest-neighbour clustering, deterministic given [rng].
  List<List<int>>? _groupStars(DeterministicRandom rng, List<int> stars) {
    if (starsPerUnit == 1) {
      return stars.map((star) => <int>[star]).toList();
    }

    final remaining = List<int>.from(stars);
    rng.shuffle(remaining);
    final groups = <List<int>>[];

    while (remaining.isNotEmpty) {
      final seed = remaining.removeLast();
      final group = <int>[seed];
      while (group.length < starsPerUnit && remaining.isNotEmpty) {
        var bestIndex = 0;
        var bestDistance = 1 << 30;
        for (var i = 0; i < remaining.length; i++) {
          final distance = _distance(group.last, remaining[i]);
          if (distance < bestDistance) {
            bestDistance = distance;
            bestIndex = i;
          }
        }
        group.add(remaining.removeAt(bestIndex));
      }
      if (group.length != starsPerUnit) {
        return null;
      }
      groups.add(group);
    }

    return groups.length == size ? groups : null;
  }

  int _distance(int a, int b) {
    final dr = (a ~/ size) - (b ~/ size);
    final dc = (a % size) - (b % size);
    return dr.abs() + dc.abs();
  }

  /// An L-shaped corridor joining every star of a group to the first one, so
  /// the finished region is orthogonally connected by construction.
  List<int> _corridorFor(List<int> group) {
    final cells = <int>{group.first};
    final anchorRow = group.first ~/ size;
    final anchorCol = group.first % size;

    for (var i = 1; i < group.length; i++) {
      final row = group[i] ~/ size;
      final col = group[i] % size;
      final stepCol = col >= anchorCol ? 1 : -1;
      for (var c = anchorCol; c != col + stepCol; c += stepCol) {
        cells.add(anchorRow * size + c);
      }
      final stepRow = row >= anchorRow ? 1 : -1;
      for (var r = anchorRow; r != row + stepRow; r += stepRow) {
        cells.add(r * size + col);
      }
    }
    return cells.toList();
  }

  /// Round-robin flood fill that always expands the currently smallest region,
  /// which keeps region sizes close to `size` cells instead of producing one
  /// blob and nine slivers.
  void _growRegions(DeterministicRandom rng, List<int> owner) {
    final sizes = List<int>.filled(size, 0);
    for (final region in owner) {
      if (region >= 0) {
        sizes[region]++;
      }
    }

    var unowned = owner.where((region) => region < 0).length;
    while (unowned > 0) {
      final order = List<int>.generate(size, (i) => i)
        ..sort((a, b) => sizes[a].compareTo(sizes[b]));

      var expandedAny = false;
      for (final region in order) {
        final frontier = <int>[];
        for (var cell = 0; cell < owner.length; cell++) {
          if (owner[cell] != region) {
            continue;
          }
          for (final neighbour in _orthogonalNeighbours(cell)) {
            if (owner[neighbour] < 0) {
              frontier.add(neighbour);
            }
          }
        }
        if (frontier.isEmpty) {
          continue;
        }
        // Prefer the frontier cell that already has the most neighbours in this
        // region. Picking purely at random grows snake-like regions, and a snake
        // disconnects as soon as one cell is taken out of its middle — which is
        // exactly the move the uniqueness refinement needs to make. Compact
        // regions leave the refinement far more legal moves to work with.
        var bestScore = -1;
        final best = <int>[];
        for (final cell in frontier) {
          var score = 0;
          for (final neighbour in _orthogonalNeighbours(cell)) {
            if (owner[neighbour] == region) {
              score++;
            }
          }
          if (score > bestScore) {
            bestScore = score;
            best
              ..clear()
              ..add(cell);
          } else if (score == bestScore) {
            best.add(cell);
          }
        }
        final picked = rng.pick(best);
        owner[picked] = region;
        sizes[region]++;
        unowned--;
        expandedAny = true;
        if (unowned == 0) {
          return;
        }
      }
      if (!expandedAny) {
        return; // leaves unowned cells; the caller rejects this attempt
      }
    }
  }

  List<int> _orthogonalNeighbours(int cell) {
    final row = cell ~/ size;
    final col = cell % size;
    final result = <int>[];
    if (row > 0) {
      result.add(cell - size);
    }
    if (row < size - 1) {
      result.add(cell + size);
    }
    if (col > 0) {
      result.add(cell - 1);
    }
    if (col < size - 1) {
      result.add(cell + 1);
    }
    return result;
  }
}
