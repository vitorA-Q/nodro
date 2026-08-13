import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/analytics.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/exhaustive_solver.dart';
import '../../engine/puzzles/star_battle/model.dart';
import '../../l10n/app_localizations.dart';
import '../game/hint_engine.dart';
import '../game/hint_text.dart';
import '../game/play_grid.dart';
import '../painters/star_battle_painter.dart';
import '../theme/nodro_theme.dart';

/// Which lesson to run.
enum TutorialKind {
  /// The first-run lesson: goal, adjacency, line, region, a real deduction.
  oneStar,

  /// Fires the first time a two-star board is opened, because the quota rule is
  /// the one thing a player who only met 1★ will get wrong.
  twoStar,
}

/// One beat of the lesson.
class _Beat {
  const _Beat(this.text, {this.tapCell, this.useHint = false});

  final String Function(AppLocalizations l10n) text;

  /// The cell the player must tap to move on. Null means "read and continue".
  final int? tapCell;

  /// The beat is driven by the real hint engine rather than by a script.
  final bool useHint;
}

/// The interactive tutorial: played, never read.
///
/// It teaches on a real bank puzzle, using the real board, the real automatic
/// marking and — for the final beats — the real hint engine. Nothing here is a
/// mock-up, so nothing here can teach something the game does not actually do.
///
/// It never blocks. A wrong tap gets a one-line nudge and the lesson waits.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    required this.puzzle,
    this.kind = TutorialKind.oneStar,
  });

  final StarBattlePuzzle puzzle;
  final TutorialKind kind;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  static const StarBattleExhaustiveSolver _oracle = StarBattleExhaustiveSolver();

  late final StarBattleSolution _solution =
      _oracle.findFirstSolution(widget.puzzle)!;
  late final HintEngine _hints = HintEngine(widget.puzzle);
  late final List<_Beat> _beats = _buildBeats();

  late PlayGrid _grid =
      PlayGrid.empty(widget.puzzle, AutoMarkLevel.full);
  int _index = 0;
  String? _nudge;
  Hint? _hint;
  int _hintStage = 0;

  /// The first star of the solution, and for the two-star lesson the second one
  /// sharing its row — chosen from the real solution so the lesson can never
  /// ask the player to do something wrong.
  int get _firstStar => _solution.starIndices.first;

  int? get _sameRowPartner {
    final row = _firstStar ~/ widget.puzzle.size;
    for (final star in _solution.starIndices) {
      if (star != _firstStar && star ~/ widget.puzzle.size == row) {
        return star;
      }
    }
    return null;
  }

  List<_Beat> _buildBeats() {
    if (widget.kind == TutorialKind.twoStar) {
      return <_Beat>[
        _Beat((l10n) => l10n.tutorialTwoStar1),
        _Beat((l10n) => l10n.tutorialTwoStar2, tapCell: _firstStar),
        _Beat((l10n) => l10n.tutorialTwoStar3, tapCell: _sameRowPartner),
        _Beat((l10n) => l10n.tutorialTwoStar4),
      ];
    }
    return <_Beat>[
      _Beat((l10n) => l10n.tutorialStep1, tapCell: _firstStar),
      _Beat((l10n) => l10n.tutorialStep2),
      _Beat((l10n) => l10n.tutorialStep3),
      _Beat((l10n) => l10n.tutorialStep4),
      _Beat((l10n) => l10n.tutorialStep5, useHint: true),
      _Beat((l10n) => l10n.tutorialStep6),
    ];
  }

  _Beat get _beat => _beats[_index];
  bool get _isLast => _index == _beats.length - 1;

  @override
  void initState() {
    super.initState();
    Analytics.tutorialStarted(widget.kind.name);
  }

  void _advance() {
    setState(() {
      _nudge = null;
      _hint = null;
      _hintStage = 0;
      if (_isLast) {
        Analytics.tutorialFinished(widget.kind.name);
        Navigator.of(context).pop();
      } else {
        _index++;
      }
    });
  }

  void _tap(int index) {
    final required = _beat.tapCell;
    if (required == null) {
      return;
    }
    if (index != required) {
      // Never blocks and never scolds: the lesson simply waits.
      setState(() => _nudge = AppLocalizations.of(context).tutorialWrongCell);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _grid = _grid.withState(index, CellState.star);
      _nudge = null;
    });
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) {
        _advance();
      }
    });
  }

  void _hintPressed() {
    setState(() {
      if (_hint == null) {
        _hint = _hints.hintFor(_grid);
        _hintStage = 1;
        return;
      }
      final hint = _hint;
      if (hint is DeductionHint) {
        if (_hintStage < 3) {
          _hintStage++;
        }
        if (_hintStage == 3) {
          _grid = _hints.apply(_grid, hint.deduction);
          _hint = null;
          _hintStage = 0;
          _advance();
        }
      }
    });
  }

  Set<int> get _highlight {
    final cell = _beat.tapCell;
    if (cell != null && _grid.stateAt(cell) != CellState.star) {
      return <int>{cell};
    }
    final hint = _hint;
    if (hint is DeductionHint && _hintStage >= 1) {
      return hint.deduction.highlightedCells
          .map((ref) => ref.toIndex(widget.puzzle.size))
          .toSet();
    }
    return const <int>{};
  }

  Set<int> get _targets {
    final hint = _hint;
    if (hint is DeductionHint && _hintStage >= 2) {
      return hint.deduction.affectedCells
          .map((ref) => ref.toIndex(widget.puzzle.size))
          .toSet();
    }
    return const <int>{};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final hint = _hint;

    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              120.0,
              math.min(math.min(constraints.maxWidth * 0.90, 520.0),
                  constraints.maxHeight - 250),
            );

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.kind == TutorialKind.twoStar
                              ? l10n.tutorialTwoStarTitle
                              : l10n.tutorialTitle,
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.tutorialSkip,
                            style: TextStyle(color: palette.inkSoft)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final cell = side / widget.puzzle.size;
                        final col = (details.localPosition.dx / cell).floor();
                        final row = (details.localPosition.dy / cell).floor();
                        if (row < 0 ||
                            row >= widget.puzzle.size ||
                            col < 0 ||
                            col >= widget.puzzle.size) {
                          return;
                        }
                        _tap(row * widget.puzzle.size + col);
                      },
                      child: RepaintBoundary(
                        key: const ValueKey<String>('tutorialBoard'),
                        child: CustomPaint(
                          size: Size.square(side),
                          painter: StarBattlePainter(
                            grid: _grid,
                            palette: palette,
                            blocked: _grid.blockedByAdjacency,
                            conflicts: const <int>{},
                            hintEvidence: _highlight,
                            hintTargets: _targets,
                            placeProgress: 1,
                            placedCell: null,
                            conflictProgress: 0,
                            winProgress: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                  decoration: BoxDecoration(
                    color: palette.paper,
                    border: Border(
                        top: BorderSide(color: palette.hairline, width: 1.5)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        hint is DeductionHint
                            ? (_hintStage >= 2
                                ? HintText(l10n).why(hint.deduction)
                                : l10n.hintStepTechnique(HintText(l10n)
                                    .name(hint.deduction.techniqueId)))
                            : _beat.text(l10n),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: palette.ink, fontSize: 14, height: 1.35),
                      ),
                      if (_nudge != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          _nudge!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: palette.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (_beat.useHint)
                        _Button(
                          palette: palette,
                          label: _hint == null
                              ? l10n.actionHint
                              : (_hintStage >= 2
                                  ? l10n.hintTapApply
                                  : l10n.hintTapWhy),
                          onTap: _hintPressed,
                        )
                      else if (_beat.tapCell == null)
                        _Button(
                          palette: palette,
                          label:
                              _isLast ? l10n.tutorialDone : l10n.tutorialNext,
                          onTap: _advance,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.palette,
    required this.label,
    required this.onTap,
  });

  final NodroPalette palette;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: palette.ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.paper,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
