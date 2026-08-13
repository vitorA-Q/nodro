import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/analytics.dart';
import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../engine/core/deterministic_random.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../game/game_session.dart';
import '../game/hint_engine.dart';
import '../game/hint_text.dart';
import '../game/play_grid.dart';
import '../painters/star_battle_painter.dart';
import '../theme/challenge.dart';
import '../theme/difficulty.dart';
import '../theme/nodro_theme.dart';
import 'won_sheet.dart';

/// Playing one puzzle: the board, unlimited undo, the clock, and hints.
///
/// Portrait phone is the primary case (see the layout note below); desktop is
/// the adaptation.
class PlayScreen extends StatefulWidget {
  const PlayScreen({
    super.key,
    this.puzzle,
    this.resumeBlob,
    required this.library,
    required this.progress,
    required this.isDaily,
    this.isPractice = false,
  }) : assert(puzzle != null || resumeBlob != null,
            'a PlayScreen needs either a puzzle or a saved game to resume');

  final LibraryPuzzle? puzzle;
  final String? resumeBlob;
  final PuzzleLibrary library;
  final ProgressRepository progress;
  final bool isDaily;

  /// Replaying a finished daily: no clock, no record, no effect on the streak.
  final bool isPractice;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> with TickerProviderStateMixin {
  /// Fixed bands so the board is sized from what is actually left over, which
  /// is what guarantees the game fits one screen at any size and never scrolls.
  static const double headerHeight = 78;
  static const double controlsHeight = 62;
  static const double footerHeight = 92;
  static const double maxBoardSide = 640;

  late GameSession _session;
  late HintEngine _hints;

  Timer? _clock;
  int? _placedCell;
  Set<int> _blocked = const <int>{};
  Set<int> _conflicts = const <int>{};

  Hint? _hint;
  int _hintStage = 0;
  bool _recorded = false;

  late final AnimationController _placeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150));
  late final AnimationController _conflictController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150));
  late final AnimationController _winController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    _startSession(_initialSession());
  }

  AutoMarkLevel get _level =>
      AutoMarkLevel.fromKey(widget.progress.autoMark());

  void _haptic({bool strong = false}) {
    if (widget.progress.flag(Flags.haptics) == 'off') {
      return;
    }
    if (strong) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  GameSession _initialSession() {
    final blob = widget.resumeBlob;
    if (blob != null) {
      final restored =
          GameSession.deserialize(blob, widget.library, autoMark: _level);
      if (restored != null) {
        return restored;
      }
    }
    return GameSession(
      puzzle: widget.puzzle ?? _fallbackPuzzle(),
      autoMark: _level,
      isPractice: widget.isPractice,
    );
  }

  LibraryPuzzle _fallbackPuzzle() =>
      widget.library.pick(
        widget.library.groups.first,
        const <String>{},
        DeterministicRandom(1),
      )!;

  void _startSession(GameSession session) {
    _session = session;
    _hints = HintEngine(session.puzzle.entry.puzzle);
    _recorded = false;
    _hint = null;
    _hintStage = 0;
    _placedCell = null;
    _blocked = session.grid.blockedByAdjacency;
    _conflicts = session.grid.conflictingStars;
    _conflictController.value = _conflicts.isEmpty ? 0 : 1;
    _winController.value = 0;
    Analytics.puzzleStarted(session.puzzle.group.key);
    _clock?.cancel();
    if (session.isPractice) {
      // Practice runs without a clock on purpose: timing a replay of a puzzle
      // you have already seen measures memory, not skill.
      return;
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _session.grid.isSolved) {
        return;
      }
      setState(() => _session.elapsedSeconds++);
    });
  }

  Future<void> _chooseAutoMark() async {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final chosen = await showModalBottomSheet<AutoMarkLevel>(
      context: context,
      backgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.autoMarkTitle,
                    style: TextStyle(
                        color: palette.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            for (final option in <(AutoMarkLevel, String, String)>[
              (AutoMarkLevel.off, l10n.autoMarkOff, l10n.autoMarkOffBody),
              (
                AutoMarkLevel.neighbours,
                l10n.autoMarkNeighbours,
                l10n.autoMarkNeighboursBody
              ),
              (AutoMarkLevel.full, l10n.autoMarkFull, l10n.autoMarkFullBody),
            ])
              ListTile(
                onTap: () => Navigator.of(context).pop(option.$1),
                leading: Icon(
                  option.$1 == _session.grid.autoMark
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: option.$1 == _session.grid.autoMark
                      ? palette.accent
                      : palette.inkSoft,
                ),
                title: Text(option.$2,
                    style: TextStyle(
                        color: palette.ink, fontWeight: FontWeight.w700)),
                subtitle: Text(option.$3,
                    style: TextStyle(color: palette.inkSoft, fontSize: 12)),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) {
      return;
    }
    await widget.progress.setAutoMark(chosen.storageKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _session.setAutoMark(chosen);
      _refreshDerived();
    });
    unawaited(_autosave());
  }

  @override
  void dispose() {
    // Leaving without finishing is the number that says where the game is too
    // hard, too slow or too confusing — the one thing worth measuring.
    if (!_session.grid.isSolved && !_session.isPractice) {
      Analytics.puzzleAbandoned(
        _session.puzzle.group.key,
        _session.grid.starCount,
        _session.puzzle.entry.puzzle.totalStars,
      );
    }
    _clock?.cancel();
    _placeController.dispose();
    _conflictController.dispose();
    _winController.dispose();
    super.dispose();
  }

  Future<void> _autosave() async {
    if (_session.isPractice) {
      // Practice must never clobber the real game someone left half-finished.
      return;
    }
    if (_session.grid.isSolved) {
      await widget.progress.saveGame(null);
    } else {
      await widget.progress.saveGame(_session.serialize());
    }
  }

  void _refreshDerived({int? placed}) {
    final grid = _session.grid;
    final hadConflicts = _conflicts.isNotEmpty;
    _placedCell = placed;
    _blocked = grid.blockedByAdjacency;
    _conflicts = grid.conflictingStars;

    if (_conflicts.isNotEmpty && !hadConflicts) {
      _conflictController.forward(from: 0);
    } else if (_conflicts.isEmpty && hadConflicts) {
      _conflictController.reverse();
    }
  }

  void _tap(int index) {
    if (_session.grid.isSolved) {
      return;
    }
    final next = _session.grid.cycled(index);
    final placedStar = next.stateAt(index) == CellState.star;

    setState(() {
      _session.push(next);
      _hint = null;
      _hintStage = 0;
      _refreshDerived(placed: placedStar ? index : null);
    });

    if (placedStar) {
      _haptic();
      _placeController.forward(from: 0);
    }
    _afterMove();
  }

  void _afterMove() {
    unawaited(_autosave());
    if (_session.grid.isSolved && !_recorded) {
      _recorded = true;
      _winController.forward(from: 0);
      _haptic(strong: true);
      unawaited(_recordWin());
    }
  }

  Future<void> _recordWin() async {
    final group = _session.puzzle.group;
    final best = widget.progress.bestTime(group.key);
    final isBest = !_session.isPractice &&
        (best == null || _session.elapsedSeconds < best);

    Analytics.puzzleSolved(
        group.key, _session.elapsedSeconds, _session.hintsUsed);

    if (!_session.isPractice) {
      await widget.progress.recordSolved(
          group.key, _session.puzzle.id, _session.elapsedSeconds);
      if (widget.isDaily) {
        await widget.progress.recordDaily(
          isoDate(DateTime.now()),
          DailyResult(
            seconds: _session.elapsedSeconds,
            hintsUsed: _session.hintsUsed,
            puzzleId: _session.puzzle.id,
          ),
        );
      }
    }
    await widget.progress.saveGame(null);

    if (!mounted) {
      return;
    }
    // Let the victory animation land before the sheet covers the board.
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) {
      return;
    }
    await showWonSheet(
      context: context,
      session: _session,
      isNewBest: isBest,
      isDaily: widget.isDaily,
      streak: currentStreak(widget.progress.dailyCompletions(), DateTime.now()),
      onNext: _nextPuzzle,
    );
  }

  void _nextPuzzle() {
    final group = _session.puzzle.group;
    final next = widget.library.pick(
      group,
      widget.progress.solvedIn(group.key),
      DeterministicRandom(DateTime.now().microsecondsSinceEpoch),
    );
    if (next == null) {
      return;
    }
    setState(() => _startSession(GameSession(puzzle: next)));
    unawaited(_autosave());
  }

  void _undo() {
    setState(() {
      _session.undo();
      _hint = null;
      _hintStage = 0;
      _refreshDerived();
    });
    unawaited(_autosave());
  }

  void _redo() {
    setState(() {
      _session.redo();
      _hint = null;
      _hintStage = 0;
      _refreshDerived();
    });
    _afterMove();
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.paper,
        title: Text(l10n.clearConfirmTitle,
            style: TextStyle(color: palette.ink)),
        content: Text(l10n.clearConfirmBody,
            style: TextStyle(color: palette.inkSoft)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionClear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _session.clear();
      _hint = null;
      _hintStage = 0;
      _refreshDerived();
    });
    unawaited(_autosave());
  }

  /// Three taps, not one.
  ///
  /// Step one names the technique and shows where to look. Step two explains
  /// why. Only step three touches the board. Someone who wants the answer taps
  /// three times; someone who wants to learn stops at the first — which is the
  /// whole difference between a hint that teaches and a hint that solves.
  void _hintPressed() {
    if (_session.grid.isSolved) {
      return;
    }
    setState(() {
      if (_hint == null) {
        final found = _hints.hintFor(_session.grid);
        _hint = found;
        _hintStage = 1;
        _session.hintsUsed++;
        if (found is DeductionHint) {
          // Counted per technique so the statistics screen can say which
          // reasoning the player actually leans on.
          unawaited(
              widget.progress.recordHint(found.deduction.techniqueId));
          Analytics.hintUsed(found.deduction.techniqueId);
        }
        return;
      }
      final hint = _hint!;
      if (hint is DeductionHint) {
        if (_hintStage < 3) {
          _hintStage++;
        }
        if (_hintStage == 3) {
          _session.push(_hints.apply(_session.grid, hint.deduction));
          _hint = null;
          _hintStage = 0;
          _refreshDerived();
        }
      } else {
        _hint = null;
        _hintStage = 0;
      }
    });
    if (_hintStage == 0) {
      _afterMove();
    }
  }

  void _undoToLastGood() {
    setState(() {
      _session.undoUntil(_hints.isClean);
      _hint = null;
      _hintStage = 0;
      _refreshDerived();
    });
    unawaited(_autosave());
  }

  Set<int> get _hintEvidence {
    final hint = _hint;
    if (hint is DeductionHint && _hintStage >= 1) {
      return hint.deduction.highlightedCells
          .map((ref) => ref.toIndex(_session.puzzle.entry.puzzle.size))
          .toSet();
    }
    if (hint is MistakeHint) {
      return hint.wrongCells
          .map((ref) => ref.toIndex(_session.puzzle.entry.puzzle.size))
          .toSet();
    }
    return const <int>{};
  }

  Set<int> get _hintTargets {
    final hint = _hint;
    if (hint is DeductionHint && _hintStage >= 2) {
      return hint.deduction.affectedCells
          .map((ref) => ref.toIndex(_session.puzzle.entry.puzzle.size))
          .toSet();
    }
    return const <int>{};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final puzzle = _session.puzzle.entry.puzzle;
    final grid = _session.grid;

    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = math.max(
              120.0,
              math.min(
                math.min(constraints.maxWidth * 0.92, maxBoardSide),
                constraints.maxHeight -
                    headerHeight -
                    controlsHeight -
                    footerHeight,
              ),
            );

            return Column(
              children: <Widget>[
                SizedBox(
                  height: headerHeight,
                  child: _Header(
                    palette: palette,
                    title: '${l10n.puzzleNumber(_session.puzzle.number)} · '
                        '${puzzle.size}×${puzzle.size} · '
                        '${Difficulty.of(_session.puzzle.entry.tier).label(l10n)}',
                    rule: _session.isPractice
                        ? l10n.practiceBanner
                        : l10n.ruleLine(puzzle.starsPerUnit),
                    challenge: l10n.challengeBadge(globalChallenge(
                      size: puzzle.size,
                      stars: puzzle.starsPerUnit,
                      tier: _session.puzzle.entry.tier,
                    )),
                    elapsed: _session.isPractice ||
                            widget.progress.flag(Flags.showTimer) == 'off'
                        ? ''
                        : formatDuration(_session.elapsedSeconds),
                    onBack: () => Navigator.of(context).maybePop(),
                    onSettings: _chooseAutoMark,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _Board(
                      side: side,
                      grid: grid,
                      palette: palette,
                      blocked: _blocked,
                      conflicts: _conflicts,
                      hintEvidence: _hintEvidence,
                      hintTargets: _hintTargets,
                      placeController: _placeController,
                      conflictController: _conflictController,
                      winController: _winController,
                      placedCell: _placedCell,
                      onCellTapped: _tap,
                    ),
                  ),
                ),
                SizedBox(
                  height: controlsHeight,
                  child: _Controls(
                    palette: palette,
                    l10n: l10n,
                    canUndo: _session.canUndo,
                    canRedo: _session.canRedo,
                    onUndo: _undo,
                    onRedo: _redo,
                    onClear: _clear,
                    onHint: _hintPressed,
                  ),
                ),
                SizedBox(
                  height: footerHeight,
                  child: _Footer(
                    palette: palette,
                    l10n: l10n,
                    hint: _hint,
                    hintStage: _hintStage,
                    solved: grid.isSolved,
                    counterText:
                        l10n.starsPlaced(grid.starCount, puzzle.totalStars),
                    onUndoToLastGood: _undoToLastGood,
                    onAdvanceHint: _hintPressed,
                    onDismissHint: () => setState(() {
                      _hint = null;
                      _hintStage = 0;
                    }),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.title,
    required this.rule,
    required this.challenge,
    required this.elapsed,
    required this.onBack,
    required this.onSettings,
  });

  final NodroPalette palette;
  final String title;
  final String rule;
  final String challenge;
  final String elapsed;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: palette.inkSoft),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$title · $challenge',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 13.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    rule,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.inkSoft,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (elapsed.isNotEmpty)
                Text(
                  elapsed,
                  style: TextStyle(
                    color: palette.inkSoft,
                    fontSize: 12,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              // Reachable without leaving the puzzle on purpose: a marking
              // setting you have to hunt for in a menu is a setting nobody
              // finds.
              InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.tune_rounded,
                      color: palette.inkSoft, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.side,
    required this.grid,
    required this.palette,
    required this.blocked,
    required this.conflicts,
    required this.hintEvidence,
    required this.hintTargets,
    required this.placeController,
    required this.conflictController,
    required this.winController,
    required this.placedCell,
    required this.onCellTapped,
  });

  final double side;
  final PlayGrid grid;
  final NodroPalette palette;
  final Set<int> blocked;
  final Set<int> conflicts;
  final Set<int> hintEvidence;
  final Set<int> hintTargets;
  final AnimationController placeController;
  final AnimationController conflictController;
  final AnimationController winController;
  final int? placedCell;
  final void Function(int index) onCellTapped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // onTapDown, not onTapUp: the cell answers at the moment of touch. That
      // is the difference between a board that feels alive and one that feels
      // like a form.
      onTapDown: (details) {
        final cell = side / grid.size;
        final col = (details.localPosition.dx / cell).floor();
        final row = (details.localPosition.dy / cell).floor();
        if (row < 0 || row >= grid.size || col < 0 || col >= grid.size) {
          return;
        }
        onCellTapped(row * grid.size + col);
      },
      child: RepaintBoundary(
        key: const ValueKey<String>('board'),
        child: AnimatedBuilder(
          animation: Listenable.merge(
              <Listenable>[placeController, conflictController, winController]),
          builder: (context, _) => CustomPaint(
            size: Size.square(side),
            painter: StarBattlePainter(
              grid: grid,
              palette: palette,
              blocked: blocked,
              conflicts: conflicts,
              hintEvidence: hintEvidence,
              hintTargets: hintTargets,
              placeProgress: placeController.value,
              placedCell: placedCell,
              conflictProgress: conflictController.value,
              winProgress: winController.value,
            ),
          ),
        ),
      ),
    );
  }
}

/// Undo, redo, clear and hint, in the lower third where a thumb reaches.
class _Controls extends StatelessWidget {
  const _Controls({
    required this.palette,
    required this.l10n,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.onHint,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onClear;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _ControlButton(
            palette: palette,
            icon: Icons.undo_rounded,
            label: l10n.actionUndo,
            onTap: canUndo ? onUndo : null,
          ),
          _ControlButton(
            palette: palette,
            icon: Icons.redo_rounded,
            label: l10n.actionRedo,
            onTap: canRedo ? onRedo : null,
          ),
          _ControlButton(
            palette: palette,
            icon: Icons.delete_outline_rounded,
            label: l10n.actionClear,
            onTap: onClear,
          ),
          _ControlButton(
            palette: palette,
            icon: Icons.lightbulb_outline_rounded,
            label: l10n.actionHint,
            onTap: onHint,
            emphasised: true,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasised = false,
  });

  final NodroPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colour = !enabled
        ? palette.hairline
        : (emphasised ? palette.accent : palette.ink);

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: colour, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colour, fontSize: 10.5, height: 1.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The counter, or whatever the current hint is saying.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.palette,
    required this.l10n,
    required this.hint,
    required this.hintStage,
    required this.solved,
    required this.counterText,
    required this.onUndoToLastGood,
    required this.onAdvanceHint,
    required this.onDismissHint,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final Hint? hint;
  final int hintStage;
  final bool solved;
  final String counterText;
  final VoidCallback onUndoToLastGood;
  final VoidCallback onAdvanceHint;
  final VoidCallback onDismissHint;

  @override
  Widget build(BuildContext context) {
    final current = hint;

    if (current is MistakeHint) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              l10n.hintMistakeTitle,
              style: TextStyle(
                color: palette.danger,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                l10n.hintMistakeBody(current.wrongCells.length),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: palette.inkSoft, fontSize: 11.5, height: 1.25),
              ),
            ),
            TextButton(
              onPressed: onUndoToLastGood,
              child: Text(l10n.hintUndoToMistake,
                  style: TextStyle(color: palette.accent, fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (current is DeductionHint) {
      final text = HintText(l10n);
      // The whole panel is the button. Telling someone to "tap to apply" while
      // the only tappable thing sits elsewhere is a small lie the interface
      // tells every single time a hint appears.
      return Semantics(
        button: true,
        label: hintStage >= 2 ? l10n.hintTapApply : l10n.hintTapWhy,
        child: InkWell(
          onTap: onAdvanceHint,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        l10n.hintStepTechnique(
                            text.name(current.deduction.techniqueId)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          hintStage >= 2
                              ? text.why(current.deduction)
                              : l10n.hintStepLook,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: palette.ink, fontSize: 11.5, height: 1.25),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hintStage >= 2 ? l10n.hintTapApply : l10n.hintTapWhy,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: l10n.hintClose,
                  child: IconButton(
                    onPressed: onDismissHint,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded,
                        color: palette.inkSoft, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (current is StuckHint) {
      return Center(
        child: Text(l10n.hintStuck,
            style: TextStyle(color: palette.inkSoft, fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: solved ? palette.success : palette.ink,
              fontSize: solved ? 25 : 18,
              height: 1.2,
              fontWeight: solved ? FontWeight.w700 : FontWeight.w400,
            ),
            child: Text(solved ? l10n.solvedMessage : counterText),
          ),
          const SizedBox(height: 5),
          Flexible(
            child: Text(
              l10n.tapHint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: palette.inkSoft, fontSize: 11.5, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
