import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/puzzle_bank.dart';
import '../../engine/core/technique_tier.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../l10n/app_localizations.dart';
import '../game/play_grid.dart';
import '../painters/star_battle_painter.dart';
import '../theme/nodro_theme.dart';

/// Stage A: one fixed puzzle, one screen.
///
/// ## Portrait phone is the primary case
///
/// The final target is Android in portrait, and most puzzle-site traffic is
/// mobile even on the web, so the layout is designed for a narrow tall screen
/// and desktop is the adaptation — not the other way round. The board takes
/// ~92% of the width, the rules sit in a compact band above it, and the counter
/// sits in the lower third where a thumb can reach. Nothing ever scrolls:
/// the board is sized from the space actually left over.
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, this.initialEntry});

  /// Skips the asset read and starts from this puzzle.
  ///
  /// Exists for widget tests. Reading an asset goes over a platform channel
  /// that only answers on the real event loop, while a widget test runs on a
  /// fake clock — mixing the two made the suite hang until its ten-minute
  /// timeout. That the shipped bank file parses is proven independently by
  /// `test/property/bank_verification_test.dart`, which reads the very same
  /// files, so nothing is lost by handing the puzzle in here.
  final BankEntry? initialEntry;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen>
    with TickerProviderStateMixin {
  /// Fixed heights so the board can be sized from what remains, which is what
  /// guarantees the whole game fits one screen at any size.
  /// Measured against the real font metrics, with slack. Atkinson Hyperlegible
  /// has taller glyphs than the system default, and the first pass overflowed
  /// by two pixels on every phone size — enough to paint the overflow stripes.
  static const double headerHeight = 78;
  static const double footerHeight = 116;
  static const double maxBoardSide = 640;

  BankEntry? _entry;
  String? _error;
  PlayGrid? _grid;

  int? _placedCell;
  Set<int> _blocked = const <int>{};
  Set<int> _conflicts = const <int>{};

  late final AnimationController _placeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150));

  /// Enters, then holds. Deliberately not a loop: something blinking at the
  /// edge of vision for as long as a mistake exists is hostile to someone who
  /// is trying to concentrate.
  late final AnimationController _conflictController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 150));

  late final AnimationController _winController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    final injected = widget.initialEntry;
    if (injected != null) {
      _entry = injected;
      _grid = PlayGrid.empty(injected.puzzle);
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _placeController.dispose();
    _conflictController.dispose();
    _winController.dispose();
    super.dispose();
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
        _grid = PlayGrid.empty(entry.puzzle);
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.toString());
    }
  }

  void _tap(int index) {
    final current = _grid;
    if (current == null || current.isSolved) {
      return;
    }

    final next = current.cycled(index);
    final placedStar = next.stateAt(index) == CellState.star;
    final hadConflicts = _conflicts.isNotEmpty;
    final conflicts = next.conflictingStars;

    setState(() {
      _grid = next;
      _placedCell = placedStar ? index : null;
      _blocked = next.blockedByAdjacency;
      _conflicts = conflicts;
    });

    if (placedStar) {
      HapticFeedback.selectionClick();
      _placeController.forward(from: 0);
    }

    if (conflicts.isNotEmpty && !hadConflicts) {
      _conflictController.forward(from: 0);
    } else if (conflicts.isEmpty && hadConflicts) {
      _conflictController.reverse();
    }

    if (next.isSolved) {
      _winController.forward(from: 0);
    }
  }

  String _difficultyLabel(AppLocalizations l10n, TechniqueTier tier) =>
      switch (tier.level) {
        1 => l10n.difficultyEasy,
        2 => l10n.difficultyMedium,
        3 => l10n.difficultyHard,
        _ => l10n.difficultyExtreme,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);

    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        child: switch ((_error, _entry, _grid)) {
          (final String error, _, _) =>
            _Message(text: '${l10n.loadFailed}\n\n$error', palette: palette),
          (_, final BankEntry entry, final PlayGrid grid) =>
            _buildGame(context, l10n, palette, entry, grid),
          _ => _Message(text: l10n.loadingBank, palette: palette),
        },
      ),
    );
  }

  Widget _buildGame(BuildContext context, AppLocalizations l10n,
      NodroPalette palette, BankEntry entry, PlayGrid grid) {
    final puzzle = entry.puzzle;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          math.min(constraints.maxWidth * 0.92, maxBoardSide),
          constraints.maxHeight - headerHeight - footerHeight,
        );

        return Column(
          children: <Widget>[
            SizedBox(
              height: headerHeight,
              child: _Header(
                palette: palette,
                title: l10n.headerLine(l10n.starBattleName, puzzle.size,
                    _difficultyLabel(l10n, entry.tier)),
                rule: l10n.ruleLine(puzzle.starsPerUnit),
              ),
            ),
            Expanded(
              child: Center(
                child: _Board(
                  side: math.max(side, 120),
                  grid: grid,
                  palette: palette,
                  blocked: _blocked,
                  conflicts: _conflicts,
                  placeController: _placeController,
                  conflictController: _conflictController,
                  winController: _winController,
                  placedCell: _placedCell,
                  onCellTapped: _tap,
                ),
              ),
            ),
            SizedBox(
              height: footerHeight,
              child: _Footer(
                palette: palette,
                solved: grid.isSolved,
                solvedText: l10n.solvedMessage,
                counterText:
                    l10n.starsPlaced(grid.starCount, puzzle.totalStars),
                hint: l10n.tapHint,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The board is the hero of the screen; the header recedes.
class _Header extends StatelessWidget {
  const _Header(
      {required this.palette, required this.title, required this.rule});

  final NodroPalette palette;
  final String title;
  final String rule;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: palette.ink,
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              rule,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.inkSoft,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
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
  final AnimationController placeController;
  final AnimationController conflictController;
  final AnimationController winController;
  final int? placedCell;
  final void Function(int index) onCellTapped;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // onTapDown, not onTapUp: the cell has to answer at the moment of touch.
      // Waiting for release is the difference between a board that feels alive
      // and one that feels like a form.
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
        // Keyed so tests can capture exactly what this boundary put on screen,
        // rather than re-rendering the painter themselves — which would prove
        // only that the painter *could* draw, not that the board repainted.
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

/// Counter and instructions live in the lower third, within thumb reach.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.palette,
    required this.solved,
    required this.solvedText,
    required this.counterText,
    required this.hint,
  });

  final NodroPalette palette;
  final bool solved;
  final String solvedText;
  final String counterText;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: solved ? palette.success : palette.ink,
              fontSize: solved ? 27 : 19,
              height: 1.2,
              fontWeight: solved ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: solved ? 0.4 : 0,
            ),
            child: Text(solved ? solvedText : counterText),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              hint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.inkSoft,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.palette});

  final String text;
  final NodroPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.ink, fontSize: 16),
        ),
      ),
    );
  }
}
