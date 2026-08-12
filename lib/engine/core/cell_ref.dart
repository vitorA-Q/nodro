/// A zero-based reference to one cell of a puzzle grid.
///
/// This is the currency of the hint engine: a [CellRef] is what a technique
/// hands back so the UI knows exactly which squares to highlight, without the
/// engine knowing anything about pixels or widgets (R5).
class CellRef {
  const CellRef(this.row, this.col);

  /// Zero-based row index, counted from the top.
  final int row;

  /// Zero-based column index, counted from the left.
  final int col;

  /// The index of this cell in a row-major array of width [width].
  int toIndex(int width) => row * width + col;

  /// Rebuilds a [CellRef] from a row-major [index] in a grid of [width].
  static CellRef fromIndex(int index, int width) =>
      CellRef(index ~/ width, index % width);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CellRef && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);

  /// Human-facing coordinates are one-based, matching how players read a grid.
  @override
  String toString() => 'r${row + 1}c${col + 1}';
}
