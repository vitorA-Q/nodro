import '../../data/puzzle_library.dart';
import '../../engine/puzzles/star_battle/board.dart';
import 'play_grid.dart';

/// One puzzle being played: the board, the full undo history, the clock and the
/// hint count.
///
/// The undo stack is a plain list of immutable [PlayGrid] snapshots, which is
/// only affordable because those snapshots are cheap — and it is what makes
/// "unlimited undo" and "restore exactly where I was, history included" the
/// same feature rather than two.
class GameSession {
  GameSession({
    required this.puzzle,
    List<PlayGrid>? history,
    int? cursor,
    this.elapsedSeconds = 0,
    this.hintsUsed = 0,
  })  : _history = history ?? <PlayGrid>[PlayGrid.empty(puzzle.entry.puzzle)],
        _cursor = cursor ?? 0;

  final LibraryPuzzle puzzle;
  final List<PlayGrid> _history;
  int _cursor;

  int elapsedSeconds;
  int hintsUsed;

  PlayGrid get grid => _history[_cursor];
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _history.length - 1;
  bool get isPristine => _history.length == 1 && _history.first.starCount == 0;

  /// Applies a new board state, discarding any redo branch.
  void push(PlayGrid next) {
    if (_cursor < _history.length - 1) {
      _history.removeRange(_cursor + 1, _history.length);
    }
    _history.add(next);
    _cursor = _history.length - 1;
  }

  void undo() {
    if (canUndo) {
      _cursor--;
    }
  }

  void redo() {
    if (canRedo) {
      _cursor++;
    }
  }

  /// Wipes the board but keeps the history, so clearing is itself undoable.
  void clear() => push(PlayGrid.empty(puzzle.entry.puzzle));

  /// Steps back until the board holds no mistake, used by the hint engine when
  /// the player has painted themselves into a corner.
  void undoUntil(bool Function(PlayGrid grid) isClean) {
    while (canUndo && !isClean(grid)) {
      _cursor--;
    }
  }

  // ------------------------------------------------------------ persistence

  static const String _prefix = 'NG1';

  /// The whole session as one string, undo history included.
  ///
  /// A 9x9 board is 81 characters per step, so even a long game is a few tens
  /// of kilobytes — small enough to write on every move without thinking about
  /// it, which is what makes autosave reliable rather than periodic.
  String serialize() {
    final states = _history.map((grid) {
      final buffer = StringBuffer();
      for (final state in grid.cells) {
        buffer.write(switch (state) {
          CellState.unknown => '.',
          CellState.star => '*',
          CellState.empty => '-',
        });
      }
      return buffer.toString();
    }).join(',');

    return <String>[
      _prefix,
      puzzle.id,
      '$elapsedSeconds',
      '$hintsUsed',
      '$_cursor',
      states,
    ].join('|');
  }

  /// Rebuilds a session, or returns null when the blob does not match anything
  /// in the current library — a bank rebuild shifts ids, and losing one saved
  /// game is far better than crashing on startup.
  static GameSession? deserialize(String blob, PuzzleLibrary library) {
    final parts = blob.split('|');
    if (parts.length != 6 || parts[0] != _prefix) {
      return null;
    }
    final puzzle = library.byId(parts[1]);
    if (puzzle == null) {
      return null;
    }

    final cellCount = puzzle.entry.puzzle.size * puzzle.entry.puzzle.size;
    final history = <PlayGrid>[];
    for (final chunk in parts[5].split(',')) {
      if (chunk.length != cellCount) {
        return null;
      }
      var grid = PlayGrid.empty(puzzle.entry.puzzle);
      for (var i = 0; i < chunk.length; i++) {
        switch (chunk[i]) {
          case '*':
            grid = grid.withState(i, CellState.star);
          case '-':
            grid = grid.withState(i, CellState.empty);
          default:
            break;
        }
      }
      history.add(grid);
    }
    if (history.isEmpty) {
      return null;
    }

    final cursor = int.tryParse(parts[4]) ?? 0;
    return GameSession(
      puzzle: puzzle,
      history: history,
      cursor: cursor.clamp(0, history.length - 1),
      elapsedSeconds: int.tryParse(parts[2]) ?? 0,
      hintsUsed: int.tryParse(parts[3]) ?? 0,
    );
  }
}
