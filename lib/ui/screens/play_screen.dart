import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/puzzle_bank.dart';
import '../../l10n/app_localizations.dart';
import '../../engine/core/technique_tier.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/model.dart';
import '../../engine/puzzles/star_battle/rules.dart';
import '../painters/star_battle_painter.dart';

/// Stage A: one fixed puzzle, one screen, nothing else.
///
/// No menu, no puzzle picker, no undo, no hints, no saving. The point of this
/// stage is a short feedback loop — something playable in a browser today — not
/// a finished app. Everything else is deliberately deferred.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  static const StarBattleValidator _validator = StarBattleValidator();

  BankEntry? _entry;
  String? _error;
  late List<CellState> _cells;
  bool _isSolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bank = await PuzzleBank.load('star_battle_6x6_1');
      final entry = bank.firstAtTier(TechniqueTier.tier2) ?? bank.entries.first;
      if (!mounted) {
        return;
      }
      setState(() {
        _entry = entry;
        _cells = List<CellState>.filled(
            entry.puzzle.size * entry.puzzle.size, CellState.unknown);
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    }
  }

  /// Empty -> star -> cross -> empty. One gesture, works with mouse and finger.
  void _cycle(int index) {
    if (_isSolved) {
      return;
    }
    setState(() {
      _cells[index] = switch (_cells[index]) {
        CellState.unknown => CellState.star,
        CellState.star => CellState.empty,
        CellState.empty => CellState.unknown,
      };
      _isSolved = _checkSolved();
    });
  }

  /// Victory is decided by the same rule validator the property tests use, so
  /// what counts as solved on screen is exactly what counts as solved in the
  /// engine. Cross marks are a player aid and are ignored.
  bool _checkSolved() {
    final puzzle = _entry!.puzzle;
    final masks = List<int>.filled(puzzle.size, 0);
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] == CellState.star) {
        masks[i ~/ puzzle.size] |= 1 << (i % puzzle.size);
      }
    }
    return _validator.isValidSolution(puzzle, StarBattleSolution(masks));
  }

  int get _starCount =>
      _cells.where((state) => state == CellState.star).length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: StarBattlePainter.paper,
      body: SafeArea(
        child: Center(
          child: switch ((_error, _entry)) {
            (final String error, _) => _Message(text: '${l10n.loadFailed}\n\n$error'),
            (_, null) => _Message(text: l10n.loadingBank),
            (_, final BankEntry entry) => _buildBoard(context, l10n, entry),
          },
        ),
      ),
    );
  }

  Widget _buildBoard(
      BuildContext context, AppLocalizations l10n, BankEntry entry) {
    final puzzle = entry.puzzle;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The board is always square and always fits: it never crops and never
        // asks the player to scroll. 24 px of breathing room on the tight axis,
        // and room reserved for the two lines of text.
        final available = math.min(
          constraints.maxWidth - 32,
          constraints.maxHeight - 132,
        );
        final side = available.clamp(200.0, 640.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.boardSummary(puzzle.size, puzzle.starsPerUnit),
              style: const TextStyle(
                color: StarBattlePainter.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isSolved
                  ? l10n.solvedMessage
                  : l10n.starsPlaced(_starCount, puzzle.totalStars),
              style: TextStyle(
                color: _isSolved
                    ? StarBattlePainter.success
                    : StarBattlePainter.markGrey,
                fontSize: _isSolved ? 26 : 15,
                fontWeight: _isSolved ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: _isSolved ? 0.5 : 0,
              ),
            ),
            const SizedBox(height: 16),
            _BoardSurface(
              side: side,
              puzzle: puzzle,
              cells: _cells,
              isSolved: _isSolved,
              onCellTapped: _cycle,
            ),
          ],
        );
      },
    );
  }
}

/// The tappable board. Kept separate so the hit test and the painting stay
/// side by side and cannot drift apart on cell geometry.
class _BoardSurface extends StatelessWidget {
  const _BoardSurface({
    required this.side,
    required this.puzzle,
    required this.cells,
    required this.isSolved,
    required this.onCellTapped,
  });

  final double side;
  final StarBattlePuzzle puzzle;
  final List<CellState> cells;
  final bool isSolved;
  final void Function(int index) onCellTapped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        final cell = side / puzzle.size;
        final col = (details.localPosition.dx / cell).floor();
        final row = (details.localPosition.dy / cell).floor();
        if (row < 0 || row >= puzzle.size || col < 0 || col >= puzzle.size) {
          return;
        }
        onCellTapped(row * puzzle.size + col);
      },
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(side),
          painter: StarBattlePainter(
            puzzle: puzzle,
            cells: cells,
            isSolved: isSolved,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: StarBattlePainter.ink, fontSize: 16),
      ),
    );
  }
}
