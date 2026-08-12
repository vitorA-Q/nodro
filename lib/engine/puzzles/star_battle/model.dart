import 'dart:typed_data';

import '../../core/cell_ref.dart';

/// An immutable Star Battle puzzle.
///
/// Rules: place exactly [starsPerUnit] stars in every row, every column and
/// every region. Stars never touch, not even diagonally.
///
/// Note what the *clue* is here: in Star Battle there are no numbers to remove.
/// The region partition IS the clue, which is why PROP-6 does not apply
/// literally to this genre (decision D5).
class StarBattlePuzzle {
  StarBattlePuzzle({
    required this.size,
    required this.starsPerUnit,
    required List<int> regionOfCell,
  }) : regionOfCell = Uint8List.fromList(regionOfCell) {
    if (size < 4 || size > 16) {
      throw ArgumentError.value(size, 'size', 'must be between 4 and 16');
    }
    if (starsPerUnit < 1 || starsPerUnit > 3) {
      throw ArgumentError.value(
          starsPerUnit, 'starsPerUnit', 'must be between 1 and 3');
    }
    if (regionOfCell.length != size * size) {
      throw ArgumentError.value(regionOfCell.length, 'regionOfCell.length',
          'must equal size * size (${size * size})');
    }
    for (final region in regionOfCell) {
      if (region < 0 || region >= size) {
        throw ArgumentError.value(
            region, 'regionOfCell', 'region index must be in [0, $size)');
      }
    }
  }

  /// Grid is [size] x [size], and there are exactly [size] regions.
  final int size;

  /// Stars per row, per column and per region. 1 or 2 for the shipped sizes (D6).
  final int starsPerUnit;

  /// Row-major map from cell index to region index, values in `[0, size)`.
  final Uint8List regionOfCell;

  /// Total number of stars in a completed grid.
  int get totalStars => size * starsPerUnit;

  /// Bit mask with the low [size] bits set — one bit per column.
  int get fullRowMask => (1 << size) - 1;

  int regionAt(int row, int col) => regionOfCell[row * size + col];

  /// Cell indices belonging to [region], in row-major order.
  List<int> cellsOfRegion(int region) {
    final cells = <int>[];
    for (var index = 0; index < regionOfCell.length; index++) {
      if (regionOfCell[index] == region) {
        cells.add(index);
      }
    }
    return cells;
  }

  CellRef cellRefOf(int index) => CellRef.fromIndex(index, size);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StarBattlePuzzle ||
        other.size != size ||
        other.starsPerUnit != starsPerUnit) {
      return false;
    }
    for (var i = 0; i < regionOfCell.length; i++) {
      if (other.regionOfCell[i] != regionOfCell[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(size, starsPerUnit, Object.hashAll(regionOfCell));

  @override
  String toString() => 'StarBattlePuzzle(${size}x$size, $starsPerUnit star(s))';
}

/// An immutable Star Battle solution, stored as one bit mask per row.
///
/// Bit `c` of `rowMasks[r]` is set when cell (r, c) holds a star. Masks keep the
/// oracle's inner loop to bitwise operations, and every value stays well under
/// 2^16 so the representation is exact on JavaScript too.
class StarBattleSolution {
  StarBattleSolution(List<int> rowMasks)
      : rowMasks = List<int>.unmodifiable(rowMasks);

  /// Builds a solution from row-major cell indices.
  factory StarBattleSolution.fromCellIndices(
      Iterable<int> cellIndices, int size) {
    final masks = List<int>.filled(size, 0);
    for (final index in cellIndices) {
      masks[index ~/ size] |= 1 << (index % size);
    }
    return StarBattleSolution(masks);
  }

  final List<int> rowMasks;

  int get size => rowMasks.length;

  bool hasStarAt(int row, int col) => (rowMasks[row] & (1 << col)) != 0;

  /// Row-major indices of every star, in reading order.
  List<int> get starIndices {
    final indices = <int>[];
    for (var row = 0; row < rowMasks.length; row++) {
      var mask = rowMasks[row];
      while (mask != 0) {
        final bit = mask & -mask;
        indices.add(row * rowMasks.length + _bitIndex(bit));
        mask ^= bit;
      }
    }
    return indices;
  }

  List<CellRef> get starCells =>
      starIndices.map((i) => CellRef.fromIndex(i, size)).toList();

  static int _bitIndex(int isolatedBit) {
    var index = 0;
    var bit = isolatedBit;
    while (bit > 1) {
      bit >>= 1;
      index++;
    }
    return index;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! StarBattleSolution ||
        other.rowMasks.length != rowMasks.length) {
      return false;
    }
    for (var i = 0; i < rowMasks.length; i++) {
      if (other.rowMasks[i] != rowMasks[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(rowMasks);

  @override
  String toString() => 'StarBattleSolution($starIndices)';
}
