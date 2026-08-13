import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../theme/nodro_theme.dart';
import '../widgets/board_thumbnail.dart';

enum _Filter { all, unsolved, solved }

/// Picking a specific puzzle from a group, by looking at it.
///
/// A grid of real board thumbnails rather than a list of numbers: within a
/// group every puzzle carries the same size and the same tier, so a repeated
/// "Challenge 6/10" on each row is pure noise — what actually distinguishes one
/// board from another is its shape.
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
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = (constraints.maxWidth / 116).floor().clamp(2, 6);
                  // GridView.builder, not a Column: a group can hold 845
                  // boards, and building them all would stall the first frame.
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.80,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final puzzle = visible[index];
                      final time = widget.progress.timeFor(puzzle.id);
                      return _PuzzleCard(
                        palette: palette,
                        puzzle: puzzle,
                        solved: solved.contains(puzzle.id),
                        label: l10n.puzzleNumber(puzzle.number),
                        time: time == null ? '' : formatDuration(time),
                        onTap: () => Navigator.of(context).pop(puzzle),
                      );
                    },
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

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({
    required this.palette,
    required this.puzzle,
    required this.solved,
    required this.label,
    required this.time,
    required this.onTap,
  });

  final NodroPalette palette;
  final LibraryPuzzle puzzle;
  final bool solved;
  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) => Opacity(
                    opacity: solved ? 0.45 : 1,
                    child: BoardThumbnail(
                      puzzle: puzzle.entry.puzzle,
                      side: constraints.maxWidth,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (solved) ...<Widget>[
                  Icon(Icons.check_rounded,
                      color: palette.success, size: 13),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    time.isEmpty ? label : '$label · $time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: solved ? palette.inkSoft : palette.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
