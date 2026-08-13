import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../engine/core/deterministic_random.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../theme/difficulty.dart';
import '../theme/nodro_theme.dart';
import 'play_screen.dart';

/// The hub: three sizes by four difficulties, the daily challenge, and whatever
/// game was left unfinished.
///
/// This screen is what turns a puzzle into a game — without somewhere to go
/// after a win, a session lasts exactly one board.
class SelectScreen extends StatefulWidget {
  const SelectScreen({
    super.key,
    required this.library,
    required this.progress,
    required this.onToggleTheme,
  });

  final PuzzleLibrary library;
  final ProgressRepository progress;
  final VoidCallback onToggleTheme;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  Future<void> _open(PuzzleGroup group) async {
    final solved = widget.progress.solvedIn(group.key);
    final puzzle = widget.library.pick(
      group,
      solved,
      DeterministicRandom(DateTime.now().microsecondsSinceEpoch),
    );
    if (puzzle == null) {
      return;
    }
    await _push(puzzle, isDaily: false);
  }

  Future<void> _openDaily() async {
    final puzzle = widget.library.daily(DateTime.now());
    if (puzzle == null) {
      return;
    }
    await _push(puzzle, isDaily: true);
  }

  Future<void> _push(LibraryPuzzle puzzle, {required bool isDaily}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlayScreen(
        puzzle: puzzle,
        library: widget.library,
        progress: widget.progress,
        isDaily: isDaily,
      ),
    ));
    if (mounted) {
      setState(() {}); // progress may have changed while we were away
    }
  }

  Future<void> _continue() async {
    final blob = widget.progress.savedGame();
    if (blob == null) {
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlayScreen(
        resumeBlob: blob,
        library: widget.library,
        progress: widget.progress,
        isDaily: false,
      ),
    ));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final today = DateTime.now();
    final streak = currentStreak(widget.progress.dailyCompletions(), today);
    final dailyDone =
        widget.progress.dailyCompletions().contains(isoDate(today));
    final hasSaved = widget.progress.savedGame() != null;

    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 560.0
                ? 560.0
                : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.appTitle,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onToggleTheme,
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: palette.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _DailyCard(
                      palette: palette,
                      title: l10n.dailyChallenge,
                      subtitle: dailyDone
                          ? l10n.dailyDoneToday
                          : (streak > 0 ? l10n.dailyStreak(streak) : ''),
                      done: dailyDone,
                      onTap: _openDaily,
                    ),
                    if (hasSaved) ...<Widget>[
                      const SizedBox(height: 10),
                      _WideButton(
                        palette: palette,
                        label: l10n.continueGame,
                        icon: Icons.play_arrow_rounded,
                        onTap: _continue,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.selectTitle,
                      style: TextStyle(
                        color: palette.inkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final (size, stars) in PuzzleLibrary.shippedSizes) ...<Widget>[
                      _SizeBlock(
                        palette: palette,
                        l10n: l10n,
                        size: size,
                        stars: stars,
                        library: widget.library,
                        progress: widget.progress,
                        onOpen: _open,
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SizeBlock extends StatelessWidget {
  const _SizeBlock({
    required this.palette,
    required this.l10n,
    required this.size,
    required this.stars,
    required this.library,
    required this.progress,
    required this.onOpen,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final int size;
  final int stars;
  final PuzzleLibrary library;
  final ProgressRepository progress;
  final void Function(PuzzleGroup group) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$size×$size · $stars★',
          style: TextStyle(
            color: palette.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            for (final difficulty in Difficulty.values) ...<Widget>[
              Expanded(
                child: _GroupTile(
                  palette: palette,
                  l10n: l10n,
                  group: PuzzleGroup(size, stars, difficulty),
                  library: library,
                  progress: progress,
                  onOpen: onOpen,
                ),
              ),
              if (difficulty != Difficulty.values.last)
                const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.palette,
    required this.l10n,
    required this.group,
    required this.library,
    required this.progress,
    required this.onOpen,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final PuzzleGroup group;
  final PuzzleLibrary library;
  final ProgressRepository progress;
  final void Function(PuzzleGroup group) onOpen;

  @override
  Widget build(BuildContext context) {
    final total = library.countIn(group);
    final solved = progress.solvedIn(group.key).length;
    // A group can legitimately be empty: a 9x9 with two stars is never solvable
    // by tier-1 techniques alone, so it has no Easy puzzles at all. Showing it
    // greyed is more honest than hiding the tile and leaving a hole in the grid.
    final available = total > 0;

    return Semantics(
      button: available,
      label: '${group.difficulty.label(l10n)} '
          '${group.size}x${group.size}, $solved/$total',
      child: InkWell(
        onTap: available ? () => onOpen(group) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: available
                ? palette.regionTints[group.difficulty.index * 3 %
                    palette.regionTints.length]
                : palette.neighbourWash,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: available ? palette.ink : palette.hairline,
              width: available ? 2 : 1,
            ),
          ),
          child: Column(
            children: <Widget>[
              Text(
                group.difficulty.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available ? palette.ink : palette.inkSoft,
                  fontSize: 12.5,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                available ? '$solved/$total' : l10n.selectEmptyGroup,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available ? palette.ink : palette.inkSoft,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
  });

  final NodroPalette palette;
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.ink, width: 2),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              done ? Icons.event_available_outlined : Icons.today_outlined,
              color: done ? palette.success : palette.ink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style:
                          TextStyle(color: palette.inkSoft, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: palette.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.palette,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final NodroPalette palette;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: palette.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: palette.paper, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: palette.paper,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
