import '../../core/puzzle_type.dart';
import 'board.dart';
import 'model.dart';

/// Compact, total, round-trip-safe encoding.
///
/// PROP-5 requires `deserialize(serialize(x)) == x` for every puzzle state AND
/// every progress state, so both are handled here and both must be total: any
/// malformed input throws rather than returning a half-parsed object, because a
/// silently wrong puzzle is worse than a crash (X1).
///
/// Format, pipe-separated:
///   `SB1|<size>|<stars>|<region chars>`
/// where each region char is a base-36 digit giving that cell's region, in
/// row-major order. A 10x10 puzzle is therefore 100 characters plus a short
/// header — small enough that a whole difficulty tier of the pre-generated bank
/// stays well inside the 3 MB budget (decision D2).
class StarBattleSerializer implements PuzzleSerializer<StarBattlePuzzle> {
  const StarBattleSerializer();

  static const String _puzzlePrefix = 'SB1';
  static const String _boardPrefix = 'SBP1';
  static const String _digits = '0123456789abcdefghijklmnopqrstuvwxyz';

  @override
  String serialize(StarBattlePuzzle puzzle) {
    final buffer = StringBuffer()
      ..write(_puzzlePrefix)
      ..write('|')
      ..write(puzzle.size)
      ..write('|')
      ..write(puzzle.starsPerUnit)
      ..write('|');
    for (final region in puzzle.regionOfCell) {
      buffer.write(_digits[region]);
    }
    return buffer.toString();
  }

  @override
  StarBattlePuzzle deserialize(String data) {
    final parts = data.split('|');
    if (parts.length != 4 || parts[0] != _puzzlePrefix) {
      throw FormatException('not a Star Battle puzzle payload', data);
    }
    final size = int.parse(parts[1]);
    final stars = int.parse(parts[2]);
    final body = parts[3];
    if (body.length != size * size) {
      throw FormatException(
          'expected ${size * size} region chars, got ${body.length}', data);
    }
    final regions = List<int>.generate(body.length, (i) {
      final index = _digits.indexOf(body[i]);
      if (index < 0) {
        throw FormatException('bad region char "${body[i]}"', data, i);
      }
      return index;
    });
    return StarBattlePuzzle(
      size: size,
      starsPerUnit: stars,
      regionOfCell: regions,
    );
  }

  /// Encodes the player's progress: one character per cell.
  ///
  /// Kept separate from the puzzle so autosave can write progress often without
  /// rewriting the immutable part.
  String serializeBoard(StarBattleBoard board) {
    final buffer = StringBuffer()
      ..write(_boardPrefix)
      ..write('|')
      ..write(serialize(board.puzzle))
      ..write('|');
    for (var cell = 0; cell < board.size * board.size; cell++) {
      switch (board.stateAt(cell)) {
        case CellState.unknown:
          buffer.write('.');
        case CellState.star:
          buffer.write('*');
        case CellState.empty:
          buffer.write('-');
      }
    }
    return buffer.toString();
  }

  StarBattleBoard deserializeBoard(String data) {
    final marker = '$_boardPrefix|';
    if (!data.startsWith(marker)) {
      throw FormatException('not a Star Battle progress payload', data);
    }
    final rest = data.substring(marker.length);
    final split = rest.lastIndexOf('|');
    if (split < 0) {
      throw FormatException('progress payload has no cell section', data);
    }
    final puzzle = deserialize(rest.substring(0, split));
    final cells = rest.substring(split + 1);
    if (cells.length != puzzle.size * puzzle.size) {
      throw FormatException(
          'expected ${puzzle.size * puzzle.size} cell chars, '
          'got ${cells.length}',
          data);
    }

    final board = StarBattleBoard(puzzle);
    for (var cell = 0; cell < cells.length; cell++) {
      switch (cells[cell]) {
        case '.':
          break;
        case '*':
          board.placeStar(cell);
        case '-':
          board.markEmpty(cell);
        default:
          throw FormatException('bad cell char "${cells[cell]}"', data, cell);
      }
    }
    return board;
  }
}
