import '../../core/cell_ref.dart';
import 'model.dart';

/// What the solver currently knows about one cell.
enum CellState {
  /// Not yet determined.
  unknown,

  /// Proven to hold a star.
  star,

  /// Proven not to hold a star. (The player's "dot" or "X" mark.)
  empty,
}

/// The three kinds of unit that must each hold exactly `k` stars.
///
/// Most techniques are stated once over "a unit" rather than three times over
/// rows, columns and regions, which is both less code and less surface for an
/// unsound copy-paste.
enum UnitKind { row, column, region }

/// One row, column or region, as a fixed list of row-major cell indices.
class BoardUnit {
  BoardUnit(this.kind, this.index, List<int> cells)
      : cells = List<int>.unmodifiable(cells);

  final UnitKind kind;

  /// Row number, column number, or region number — all zero-based.
  final int index;

  final List<int> cells;

  /// One-based label for hint text.
  int get displayIndex => index + 1;

  @override
  String toString() => '${kind.name} $displayIndex';
}

/// The mutable working state of a Star Battle solve.
///
/// Holds only what has been *proven*, never a guess. Techniques read this and
/// return deductions; the human solver is the only thing that writes to it.
class StarBattleBoard {
  StarBattleBoard(this.puzzle)
      : _star = List<int>.filled(puzzle.size, 0),
        _empty = List<int>.filled(puzzle.size, 0),
        units = _buildUnits(puzzle),
        unitsOfCell = _buildUnitsOfCell(puzzle);

  /// Deep copy, for bounded refutation techniques that must be able to discard
  /// a hypothetical line of reasoning without contaminating the real board.
  StarBattleBoard.copy(StarBattleBoard other)
      : puzzle = other.puzzle,
        _star = List<int>.from(other._star),
        _empty = List<int>.from(other._empty),
        units = other.units,
        unitsOfCell = other.unitsOfCell;

  final StarBattlePuzzle puzzle;
  final List<int> _star;
  final List<int> _empty;

  /// All `3 * size` units: every row, every column, every region.
  final List<BoardUnit> units;

  /// `unitsOfCell[cellIndex]` — the three units a cell belongs to.
  final List<List<BoardUnit>> unitsOfCell;

  int get size => puzzle.size;
  int get starsPerUnit => puzzle.starsPerUnit;

  static List<BoardUnit> _buildUnits(StarBattlePuzzle puzzle) {
    final size = puzzle.size;
    final result = <BoardUnit>[];
    for (var row = 0; row < size; row++) {
      result.add(BoardUnit(UnitKind.row, row,
          List<int>.generate(size, (col) => row * size + col)));
    }
    for (var col = 0; col < size; col++) {
      result.add(BoardUnit(UnitKind.column, col,
          List<int>.generate(size, (row) => row * size + col)));
    }
    for (var region = 0; region < size; region++) {
      result.add(BoardUnit(UnitKind.region, region, puzzle.cellsOfRegion(region)));
    }
    return List<BoardUnit>.unmodifiable(result);
  }

  static List<List<BoardUnit>> _buildUnitsOfCell(StarBattlePuzzle puzzle) {
    final size = puzzle.size;
    final units = _buildUnits(puzzle);
    final result = List<List<BoardUnit>>.generate(
        size * size, (_) => <BoardUnit>[],
        growable: false);
    for (final unit in units) {
      for (final cell in unit.cells) {
        result[cell].add(unit);
      }
    }
    return List<List<BoardUnit>>.unmodifiable(
        result.map(List<BoardUnit>.unmodifiable));
  }

  // ---------------------------------------------------------------- cell state

  CellState stateAt(int cellIndex) {
    final row = cellIndex ~/ size;
    final bit = 1 << (cellIndex % size);
    if ((_star[row] & bit) != 0) {
      return CellState.star;
    }
    if ((_empty[row] & bit) != 0) {
      return CellState.empty;
    }
    return CellState.unknown;
  }

  bool isUnknown(int cellIndex) => stateAt(cellIndex) == CellState.unknown;
  bool isStar(int cellIndex) => stateAt(cellIndex) == CellState.star;
  bool isEmpty(int cellIndex) => stateAt(cellIndex) == CellState.empty;

  /// Cells that could still be a star: unknown, or already proven to be one.
  bool isCandidate(int cellIndex) => !isEmpty(cellIndex);

  /// Bit mask of cells in [row] that are still undetermined.
  int unknownMask(int row) =>
      puzzle.fullRowMask & ~_star[row] & ~_empty[row];

  int starMask(int row) => _star[row];

  /// Records a proven star. Returns false if this was already known.
  ///
  /// Throws if it contradicts a previous conclusion, because that can only mean
  /// a technique is unsound — and silently tolerating it would hide exactly the
  /// bug PROP-4 exists to catch (X1).
  bool placeStar(int cellIndex) {
    final state = stateAt(cellIndex);
    if (state == CellState.star) {
      return false;
    }
    if (state == CellState.empty) {
      throw StateError(
          'contradiction: star asserted at ${CellRef.fromIndex(cellIndex, size)} '
          'which was already proven empty');
    }
    _star[cellIndex ~/ size] |= 1 << (cellIndex % size);
    return true;
  }

  /// Records a proven non-star. Returns false if this was already known.
  bool markEmpty(int cellIndex) {
    final state = stateAt(cellIndex);
    if (state == CellState.empty) {
      return false;
    }
    if (state == CellState.star) {
      throw StateError(
          'contradiction: empty asserted at ${CellRef.fromIndex(cellIndex, size)} '
          'which was already proven to hold a star');
    }
    _empty[cellIndex ~/ size] |= 1 << (cellIndex % size);
    return true;
  }

  // --------------------------------------------------------------- unit views

  /// Cells of [unit] proven to hold a star.
  List<int> starsIn(BoardUnit unit) =>
      unit.cells.where(isStar).toList(growable: false);

  /// Cells of [unit] still undetermined.
  List<int> unknownsIn(BoardUnit unit) =>
      unit.cells.where(isUnknown).toList(growable: false);

  /// Cells of [unit] that could still end up holding a star.
  List<int> candidatesIn(BoardUnit unit) =>
      unit.cells.where(isCandidate).toList(growable: false);

  int starCountIn(BoardUnit unit) {
    var count = 0;
    for (final cell in unit.cells) {
      if (isStar(cell)) {
        count++;
      }
    }
    return count;
  }

  /// How many stars [unit] still needs. Negative means a contradiction.
  int remainingIn(BoardUnit unit) => starsPerUnit - starCountIn(unit);

  // -------------------------------------------------------------- geometry

  /// The up-to-eight cells touching [cellIndex], including diagonals.
  List<int> neighboursOf(int cellIndex) {
    final row = cellIndex ~/ size;
    final col = cellIndex % size;
    final result = <int>[];
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
        result.add(r * size + c);
      }
    }
    return result;
  }

  /// Whether two cells touch, including diagonally.
  bool touches(int a, int b) {
    final dr = (a ~/ size) - (b ~/ size);
    final dc = (a % size) - (b % size);
    return a != b && dr.abs() <= 1 && dc.abs() <= 1;
  }

  // ---------------------------------------------------------------- progress

  bool get isSolved {
    for (final unit in units) {
      if (starCountIn(unit) != starsPerUnit) {
        return false;
      }
    }
    return unknownCellCount == 0;
  }

  int get unknownCellCount {
    var count = 0;
    for (var row = 0; row < size; row++) {
      var mask = unknownMask(row);
      while (mask != 0) {
        mask &= mask - 1;
        count++;
      }
    }
    return count;
  }

  int get resolvedCellCount => size * size - unknownCellCount;

  /// Whether the board is provably broken: a unit over quota, or one that can
  /// no longer reach its quota.
  bool get hasContradiction {
    for (final unit in units) {
      final placed = starCountIn(unit);
      if (placed > starsPerUnit) {
        return true;
      }
      if (placed + unknownsIn(unit).length < starsPerUnit) {
        return true;
      }
    }
    return false;
  }

  /// The solution implied by the current stars, valid only once [isSolved].
  StarBattleSolution toSolution() => StarBattleSolution(List<int>.from(_star));

  CellRef refOf(int cellIndex) => CellRef.fromIndex(cellIndex, size);
}
