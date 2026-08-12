import '../../core/puzzle_type.dart';
import 'model.dart';

/// Checks a Star Battle solution against the three rules of the genre.
///
/// This is deliberately written the slow, obvious way — one independent check
/// per rule, no shared cleverness. It is the last line of defence behind the
/// oracle, and a validator that shares a bug with the solver it validates is
/// worth nothing.
class StarBattleValidator
    implements RuleValidator<StarBattlePuzzle, StarBattleSolution> {
  const StarBattleValidator();

  @override
  bool isValidSolution(StarBattlePuzzle puzzle, StarBattleSolution solution) =>
      violations(puzzle, solution).isEmpty;

  @override
  List<String> violations(
      StarBattlePuzzle puzzle, StarBattleSolution solution) {
    final problems = <String>[];
    final size = puzzle.size;
    final k = puzzle.starsPerUnit;

    if (solution.rowMasks.length != size) {
      return <String>[
        'solution has ${solution.rowMasks.length} rows, expected $size'
      ];
    }

    final colCounts = List<int>.filled(size, 0);
    final regionCounts = List<int>.filled(size, 0);

    for (var row = 0; row < size; row++) {
      final mask = solution.rowMasks[row];
      if (mask & ~puzzle.fullRowMask != 0) {
        problems.add('row ${row + 1} has a star outside the grid');
      }
      var rowCount = 0;
      for (var col = 0; col < size; col++) {
        if (!solution.hasStarAt(row, col)) {
          continue;
        }
        rowCount++;
        colCounts[col]++;
        regionCounts[puzzle.regionAt(row, col)]++;
      }
      if (rowCount != k) {
        problems.add('row ${row + 1} has $rowCount stars, expected $k');
      }
    }

    for (var col = 0; col < size; col++) {
      if (colCounts[col] != k) {
        problems.add('column ${col + 1} has ${colCounts[col]} stars, expected $k');
      }
    }
    for (var region = 0; region < size; region++) {
      if (regionCounts[region] != k) {
        problems.add(
            'region ${region + 1} has ${regionCounts[region]} stars, expected $k');
      }
    }

    // Adjacency, including diagonals. Checking only right/down/down-left/
    // down-right avoids reporting the same touching pair twice.
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (!solution.hasStarAt(row, col)) {
          continue;
        }
        const deltas = <List<int>>[
          <int>[0, 1],
          <int>[1, -1],
          <int>[1, 0],
          <int>[1, 1],
        ];
        for (final delta in deltas) {
          final r = row + delta[0];
          final c = col + delta[1];
          if (r < 0 || r >= size || c < 0 || c >= size) {
            continue;
          }
          if (solution.hasStarAt(r, c)) {
            problems.add('stars at r${row + 1}c${col + 1} and '
                'r${r + 1}c${c + 1} touch');
          }
        }
      }
    }

    return problems;
  }

  /// Structural checks on the puzzle itself, independent of any solution.
  ///
  /// Every region must be non-empty and orthogonally connected — a disconnected
  /// "region" is not a Star Battle region, and shipping one would look like a
  /// rendering bug to the player.
  List<String> puzzleViolations(StarBattlePuzzle puzzle) {
    final problems = <String>[];
    final size = puzzle.size;

    for (var region = 0; region < size; region++) {
      final cells = puzzle.cellsOfRegion(region);
      if (cells.isEmpty) {
        problems.add('region ${region + 1} is empty');
        continue;
      }
      if (cells.length < puzzle.starsPerUnit) {
        problems.add('region ${region + 1} has ${cells.length} cells, '
            'too few for ${puzzle.starsPerUnit} stars');
      }
      if (!_isOrthogonallyConnected(puzzle, cells, region)) {
        problems.add('region ${region + 1} is not connected');
      }
    }
    return problems;
  }

  bool _isOrthogonallyConnected(
      StarBattlePuzzle puzzle, List<int> cells, int region) {
    final size = puzzle.size;
    final seen = <int>{cells.first};
    final queue = <int>[cells.first];
    while (queue.isNotEmpty) {
      final index = queue.removeLast();
      final row = index ~/ size;
      final col = index % size;
      const deltas = <List<int>>[
        <int>[-1, 0],
        <int>[1, 0],
        <int>[0, -1],
        <int>[0, 1],
      ];
      for (final delta in deltas) {
        final r = row + delta[0];
        final c = col + delta[1];
        if (r < 0 || r >= size || c < 0 || c >= size) {
          continue;
        }
        final neighbour = r * size + c;
        if (puzzle.regionOfCell[neighbour] != region || seen.contains(neighbour)) {
          continue;
        }
        seen.add(neighbour);
        queue.add(neighbour);
      }
    }
    return seen.length == cells.length;
  }
}
