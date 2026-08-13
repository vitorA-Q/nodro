import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../l10n/app_localizations.dart';
import '../theme/challenge.dart';
import '../theme/nodro_theme.dart';

enum _Filter { all, unsolved, solved }

/// Picking a specific puzzle from a group, rather than being handed one.
///
/// Random is the default path and stays one tap away; this exists for the
/// player who wants to come back to number 214, or to hunt down the ones they
/// have not finished.
class PickScreen extends StatefulWidget {
  const PickScreen({
    super.key,
    required this.group,
    required this.library,
    required this.progress,
  });

  final PuzzleGroup group;
  final PuzzleLibrary library;
  final ProgressRepository progress;

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final solved = widget.progress.solvedIn(widget.group.key);
    final all = widget.library.inGroup(widget.group);

    final visible = switch (_filter) {
      _Filter.all => all,
      _Filter.unsolved =>
        all.where((puzzle) => !solved.contains(puzzle.id)).toList(),
      _Filter.solved =>
        all.where((puzzle) => solved.contains(puzzle.id)).toList(),
    };

    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(
          l10n.pickTitle(
              widget.group.size, widget.group.difficulty.label(l10n)),
          style: TextStyle(
              color: palette.ink, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: <Widget>[
                  for (final option in <(_Filter, String)>[
                    (_Filter.all, l10n.filterAll),
                    (_Filter.unsolved, l10n.filterUnsolved),
                    (_Filter.solved, l10n.filterSolved),
                  ]) ...<Widget>[
                    Expanded(
                      child: _FilterChip(
                        palette: palette,
                        label: option.$2,
                        selected: _filter == option.$1,
                        onTap: () => setState(() => _filter = option.$1),
                      ),
                    ),
                    if (option.$1 != _Filter.solved) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              // ListView.builder, not a giant Column: a group can hold 845
              // puzzles and building them all would stall the first frame.
              child: ListView.builder(
                itemCount: visible.length,
                itemExtent: 56,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final puzzle = visible[index];
                  final isSolved = solved.contains(puzzle.id);
                  final number = all.indexOf(puzzle) + 1;
                  return _PuzzleRow(
                    palette: palette,
                    label: l10n.puzzleNumber(number),
                    challenge: l10n.challengeBadge(globalChallenge(
                      size: puzzle.entry.puzzle.size,
                      stars: puzzle.entry.puzzle.starsPerUnit,
                      tier: puzzle.entry.tier,
                    )),
                    solved: isSolved,
                    onTap: () => Navigator.of(context).pop(puzzle),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NodroPalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? palette.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.hairline, width: 1.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? palette.paper : palette.ink,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PuzzleRow extends StatelessWidget {
  const _PuzzleRow({
    required this.palette,
    required this.label,
    required this.challenge,
    required this.solved,
    required this.onTap,
  });

  final NodroPalette palette;
  final String label;
  final String challenge;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            solved ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: solved ? palette.success : palette.hairline,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: palette.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            challenge,
            style: TextStyle(color: palette.inkSoft, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: palette.inkSoft, size: 20),
        ],
      ),
    );
  }
}
