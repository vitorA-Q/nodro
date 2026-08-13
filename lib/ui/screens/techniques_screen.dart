import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../engine/core/deduction.dart';
import '../../engine/puzzles/star_battle/board.dart';
import '../../engine/puzzles/star_battle/human_solver.dart';
import '../../engine/puzzles/star_battle/model.dart';
import '../../l10n/app_localizations.dart';
import '../game/hint_text.dart';
import '../game/play_grid.dart';
import '../painters/star_battle_painter.dart';
import '../theme/nodro_theme.dart';

/// The technique library.
///
/// ## Why this is the product, not an extra
///
/// The engine's whole cost — the exhaustive oracle, the human solver, the
/// two-sided difficulty rating — buys one guarantee: every puzzle here is
/// solvable by named reasoning, with no guessing anywhere. Reviews of the
/// leading Star Battle app complain that its hardest tier is often illogical
/// and that its hints lean on assumptions the player could not have derived.
/// PROP-2 makes that impossible here by construction. This screen is where that
/// difference stops being an implementation detail and becomes something a
/// player can see.
///
/// Each entry shows a **worked diagram built by the real solver**, not a
/// hand-drawn illustration, so the library can never describe a technique the
/// engine does not actually apply.
class TechniquesScreen extends StatelessWidget {
  const TechniquesScreen({
    super.key,
    required this.progress,
    required this.samplePuzzle,
    this.focusTechniqueId,
  });

  final ProgressRepository progress;

  /// A real board the diagrams are derived from.
  final StarBattlePuzzle samplePuzzle;

  /// Scrolls straight to one technique, used when a hint offers to explain
  /// itself.
  final String? focusTechniqueId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final counts = progress.hintCounts();
    final text = HintText(l10n);

    final byTier = <int, List<Technique<StarBattleBoard>>>{};
    for (final technique in StarBattleHumanSolver.orderedTechniques) {
      byTier.putIfAbsent(technique.tier.level, () => <Technique<StarBattleBoard>>[])
          .add(technique);
    }
    final tiers = byTier.keys.toList()..sort();

    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(l10n.techniquesTitle,
            style: TextStyle(
                color: palette.ink, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: <Widget>[
                Text(
                  l10n.techniquesSubtitle,
                  style: TextStyle(
                      color: palette.inkSoft, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                for (final tier in tiers) ...<Widget>[
                  Text(
                    l10n.techniqueTier(tier),
                    style: TextStyle(
                      color: palette.inkSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final technique in byTier[tier]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TechniqueCard(
                        palette: palette,
                        l10n: l10n,
                        name: text.name(technique.id),
                        techniqueId: technique.id,
                        uses: counts[technique.id] ?? 0,
                        highlighted: technique.id == focusTechniqueId,
                        diagram: _diagramFor(technique),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Finds a real position where this technique fires, by driving the solver
  /// forward until it does.
  ///
  /// If none is found the card simply shows no diagram, which is honest — far
  /// better than drawing an invented example that the engine would never
  /// produce.
  _Diagram? _diagramFor(Technique<StarBattleBoard> technique) {
    final solver = StarBattleHumanSolver();
    final board = StarBattleBoard(samplePuzzle);
    var grid = PlayGrid.empty(samplePuzzle, AutoMarkLevel.off);

    for (var step = 0; step < 120; step++) {
      final matches = technique.apply(board);
      final useful = matches.where((deduction) => deduction.affectedCells.any(
          (ref) => board.isUnknown(ref.toIndex(samplePuzzle.size))));
      if (useful.isNotEmpty) {
        return _Diagram(grid, useful.first, samplePuzzle);
      }

      final next = solver.nextHint(board);
      if (next == null) {
        return null;
      }
      for (final ref in next.affectedCells) {
        final index = ref.toIndex(samplePuzzle.size);
        if (next.kind == DeductionKind.assertion) {
          board.placeStar(index);
          grid = grid.withState(index, CellState.star);
        } else {
          board.markEmpty(index);
          grid = grid.withState(index, CellState.empty);
        }
      }
    }
    return null;
  }
}

class _Diagram {
  const _Diagram(this.grid, this.deduction, this.puzzle);

  final PlayGrid grid;
  final Deduction deduction;
  final StarBattlePuzzle puzzle;
}

class _TechniqueCard extends StatefulWidget {
  const _TechniqueCard({
    required this.palette,
    required this.l10n,
    required this.name,
    required this.techniqueId,
    required this.uses,
    required this.highlighted,
    required this.diagram,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final String name;
  final String techniqueId;
  final int uses;
  final bool highlighted;
  final _Diagram? diagram;

  @override
  State<_TechniqueCard> createState() => _TechniqueCardState();
}

class _TechniqueCardState extends State<_TechniqueCard> {
  /// Diagrams start hidden and reveal on tap, so the card behaves like the
  /// hints do: look first, then be told.
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _revealed = widget.highlighted;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final diagram = widget.diagram;

    return InkWell(
      onTap: () => setState(() => _revealed = !_revealed),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.highlighted ? palette.accent : palette.hairline,
            width: widget.highlighted ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.name,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  widget.uses > 0
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: widget.uses > 0 ? palette.success : palette.hairline,
                  size: 17,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              widget.uses > 0
                  ? widget.l10n.techniqueSeen(widget.uses)
                  : widget.l10n.techniqueUnseen,
              style: TextStyle(color: palette.inkSoft, fontSize: 11.5),
            ),
            if (_revealed && diagram != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                HintText(widget.l10n).why(diagram.deduction),
                style: TextStyle(
                    color: palette.ink, fontSize: 12.5, height: 1.35),
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: StarBattlePainter(
                      grid: diagram.grid,
                      palette: palette,
                      blocked: diagram.grid.blockedByAdjacency,
                      conflicts: const <int>{},
                      hintEvidence: diagram.deduction.highlightedCells
                          .map((ref) => ref.toIndex(diagram.puzzle.size))
                          .toSet(),
                      hintTargets: diagram.deduction.affectedCells
                          .map((ref) => ref.toIndex(diagram.puzzle.size))
                          .toSet(),
                      placeProgress: 1,
                      placedCell: null,
                      conflictProgress: 0,
                      winProgress: 0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
