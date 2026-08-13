import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/data/puzzle_bank.dart';
import 'package:nodro/data/puzzle_library.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/ui/game/game_session.dart';
import 'package:nodro/ui/theme/difficulty.dart';

/// Undo, redo, clear and autosave — the machinery behind "close the tab in the
/// middle and come back to exactly where I was, history included".
void main() {
  const serializer = StarBattleSerializer();

  LibraryPuzzle loadPuzzle() {
    final line = File('assets/bank/star_battle_6x6_1.txt')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('2|'));
    return LibraryPuzzle(
      '6x6#test',
      PuzzleGroup(6, 1, Difficulty.medium),
      BankEntry(TechniqueTier.tier2,
          serializer.deserialize(line.substring(line.indexOf('|') + 1))),
    );
  }

  test('undo and redo walk the history in both directions', () {
    final session = GameSession(puzzle: loadPuzzle());
    expect(session.canUndo, isFalse);
    expect(session.canRedo, isFalse);

    session.push(session.grid.cycled(0));
    session.push(session.grid.cycled(7));
    expect(session.grid.starCount, 2);
    expect(session.canUndo, isTrue);

    session.undo();
    expect(session.grid.starCount, 1);
    session.undo();
    expect(session.grid.starCount, 0);
    expect(session.canUndo, isFalse);

    session.redo();
    session.redo();
    expect(session.grid.starCount, 2);
    expect(session.canRedo, isFalse);
  });

  test('undo is unlimited', () {
    final session = GameSession(puzzle: loadPuzzle());
    for (var i = 0; i < 200; i++) {
      session.push(session.grid.cycled(i % 36));
    }
    var steps = 0;
    while (session.canUndo) {
      session.undo();
      steps++;
    }
    expect(steps, 200, reason: 'every move must remain undoable');
    expect(session.grid.starCount, 0);
  });

  test('a new move discards the redo branch', () {
    final session = GameSession(puzzle: loadPuzzle());
    session.push(session.grid.cycled(0));
    session.push(session.grid.cycled(7));
    session.undo();

    expect(session.canRedo, isTrue);
    session.push(session.grid.cycled(14));
    expect(session.canRedo, isFalse,
        reason: 'branching away from a redo path must drop it, or redo would '
            'jump to a board the player never chose');
  });

  test('clear wipes the board but stays undoable', () {
    final session = GameSession(puzzle: loadPuzzle());
    session.push(session.grid.cycled(0));
    session.push(session.grid.cycled(7));

    session.clear();
    expect(session.grid.starCount, 0);

    session.undo();
    expect(session.grid.starCount, 2,
        reason: 'clearing by accident must be recoverable');
  });

  test('a session round-trips through storage with its history intact', () {
    final puzzle = loadPuzzle();
    final session = GameSession(puzzle: puzzle)
      ..elapsedSeconds = 137
      ..hintsUsed = 2;
    session.push(session.grid.cycled(0));
    session.push(session.grid.cycled(7));
    session.push(session.grid.cycled(7)); // star -> cross
    session.undo();

    final library = PuzzleLibrary.fromPuzzles(<LibraryPuzzle>[puzzle]);
    final restored = GameSession.deserialize(session.serialize(), library);

    expect(restored, isNotNull);
    expect(restored!.elapsedSeconds, 137);
    expect(restored.hintsUsed, 2);
    expect(restored.grid.manual, session.grid.manual);
    expect(restored.canUndo, isTrue);
    expect(restored.canRedo, isTrue,
        reason: 'the redo branch must survive a reload too — "exactly where I '
            'was" includes what I had undone');

    restored.undo();
    restored.undo();
    expect(restored.grid.starCount, 0);
  });

  test('cross marks survive the round trip', () {
    final puzzle = loadPuzzle();
    final session = GameSession(puzzle: puzzle);
    session.push(session.grid.cycled(3).cycled(3)); // straight to a cross
    expect(session.grid.stateAt(3), CellState.empty);

    final library = PuzzleLibrary.fromPuzzles(<LibraryPuzzle>[puzzle]);
    final restored =
        GameSession.deserialize(session.serialize(), library)!;
    expect(restored.grid.stateAt(3), CellState.empty);
  });

  test('a blob for an unknown puzzle is refused rather than crashing', () {
    final puzzle = loadPuzzle();
    final session = GameSession(puzzle: puzzle);
    final empty = PuzzleLibrary.fromPuzzles(const <LibraryPuzzle>[]);

    expect(GameSession.deserialize(session.serialize(), empty), isNull,
        reason: 'rebuilding the bank shifts ids; losing one saved game is far '
            'better than failing to start');
    expect(GameSession.deserialize('garbage', empty), isNull);
  });
}
