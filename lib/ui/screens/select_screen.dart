import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../engine/core/deterministic_random.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../theme/difficulty.dart';
import '../theme/nodro_theme.dart';
import 'pick_screen.dart';
import 'play_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'techniques_screen.dart';
import 'tutorial_screen.dart';

/// The hub: every group, the daily challenge, and whatever game was left
/// unfinished.
///
/// Groups are ordered by the 1..10 challenge number rather than by board size,
/// because ordering by size quietly argues that a 6x6 Extreme is harder than a
/// 9x9 Medium — which it is not.
class SelectScreen extends StatefulWidget {
  const SelectScreen({
    super.key,
    required this.library,
    required this.progress,
    required this.onSettingsChanged,
  });

  final PuzzleLibrary library;
  final ProgressRepository progress;

  /// Tells the app root to rebuild when the theme or locale changes.
  final VoidCallback onSettingsChanged;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  @override
  void initState() {
    super.initState();
    // The tutorial runs on the very first open. Deferred a frame so it opens
    // over a drawn hub rather than over nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.progress.flag(Flags.tutorialSeen) == null) {
        _openTutorial();
      }
    });
  }

  Future<void> _openTutorial(
      {TutorialKind kind = TutorialKind.oneStar}) async {
    final sample = kind == TutorialKind.twoStar
        ? widget.library
            .inGroup(const PuzzleGroup(9, 2, Difficulty.medium))
            .firstOrNull
        : widget.library
            .inGroup(const PuzzleGroup(6, 1, Difficulty.easy))
            .firstOrNull;
    if (sample == null || !mounted) {
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          TutorialScreen(puzzle: sample.entry.puzzle, kind: kind),
    ));
    await widget.progress.setFlag(
        kind == TutorialKind.twoStar
            ? Flags.twoStarTutorialSeen
            : Flags.tutorialSeen,
        'yes');
    if (mounted) {
      setState(() {});
    }
  }
  Future<void> _openGroup(PuzzleGroup group) async {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WideButton(
                palette: palette,
                label: l10n.pickRandom,
                icon: Icons.shuffle_rounded,
                onTap: () => Navigator.of(context).pop('random'),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list_rounded, color: palette.ink),
              title: Text(l10n.pickFromList,
                  style: TextStyle(
                      color: palette.ink, fontWeight: FontWeight.w700)),
              onTap: () => Navigator.of(context).pop('list'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) {
      return;
    }

    if (choice == 'random') {
      final puzzle = widget.library.pick(
        group,
        widget.progress.solvedIn(group.key),
        DeterministicRandom(DateTime.now().microsecondsSinceEpoch),
      );
      if (puzzle != null) {
        await _push(puzzle, isDaily: false);
      }
      return;
    }

    final chosen = await Navigator.of(context).push<LibraryPuzzle>(
      MaterialPageRoute<LibraryPuzzle>(
        builder: (_) => PickScreen(
          group: group,
          library: widget.library,
          progress: widget.progress,
        ),
      ),
    );
    if (chosen != null && mounted) {
      await _push(chosen, isDaily: false);
    }
  }

  /// A finished daily stays finished until the local date turns over. Reopening
  /// shows the stored result, with practice as the only way back onto the board.
  Future<void> _openDaily() async {
    final today = isoDate(DateTime.now());
    final result = widget.progress.dailyResult(today);
    final puzzle = widget.library.daily(DateTime.now());
    if (puzzle == null) {
      return;
    }

    if (result == null) {
      await _push(puzzle, isDaily: true);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final practise = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: palette.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.event_available_outlined,
                  color: palette.success, size: 34),
              const SizedBox(height: 8),
              Text(l10n.dailyLockedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: palette.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.dailyLockedBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.inkSoft, fontSize: 13)),
              const SizedBox(height: 14),
              Text(
                l10n.solvedInWithHints(
                    formatDuration(result.seconds), result.hintsUsed),
                style: TextStyle(
                    color: palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              _WideButton(
                palette: palette,
                label: l10n.practiceThis,
                icon: Icons.refresh_rounded,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );

    if (practise == true && mounted) {
      await _push(puzzle, isDaily: true, isPractice: true);
    }
  }

  Future<void> _push(LibraryPuzzle puzzle,
      {required bool isDaily, bool isPractice = false}) async {
    // The two-star lesson fires the first time a 9x9 is opened: the quota rule
    // is exactly what a player who has only met 1★ will get wrong.
    if (puzzle.entry.puzzle.starsPerUnit > 1 &&
        widget.progress.flag(Flags.twoStarTutorialSeen) == null) {
      await _openTutorial(kind: TutorialKind.twoStar);
      if (!mounted) {
        return;
      }
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlayScreen(
        puzzle: puzzle,
        library: widget.library,
        progress: widget.progress,
        isDaily: isDaily,
        isPractice: isPractice,
      ),
    ));
    if (mounted) {
      setState(() {}); // progress may have changed while we were away
    }
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) {
      setState(() {});
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
    final dailyDone = widget.progress.dailyResult(isoDate(today)) != null;
    final hasSaved = widget.progress.savedGame() != null;

    return Scaffold(
      backgroundColor: palette.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                      tooltip: l10n.techniquesTitle,
                      onPressed: () => _openScreen(TechniquesScreen(
                        progress: widget.progress,
                        samplePuzzle: widget.library
                            .inGroup(const PuzzleGroup(
                                8, 1, Difficulty.hard))
                            .first
                            .entry
                            .puzzle,
                      )),
                      icon: Icon(Icons.menu_book_outlined,
                          color: palette.inkSoft),
                    ),
                    IconButton(
                      tooltip: l10n.statsTitle,
                      onPressed: () => _openScreen(StatsScreen(
                        progress: widget.progress,
                        library: widget.library,
                      )),
                      icon: Icon(Icons.insights_outlined,
                          color: palette.inkSoft),
                    ),
                    IconButton(
                      tooltip: l10n.settingsTitle,
                      onPressed: () => _openScreen(SettingsScreen(
                        progress: widget.progress,
                        onChanged: widget.onSettingsChanged,
                        onReplayTutorial: () {
                          Navigator.of(context).pop();
                          _openTutorial();
                        },
                      )),
                      icon: Icon(Icons.tune_rounded, color: palette.inkSoft),
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
                // One ROW per board size, four blocks across. A flat list
                // ordered by challenge was tried and destroyed the grouping the
                // eye relies on; the challenge number still makes sizes
                // comparable without having to dictate the layout.
                for (final (size, stars) in PuzzleLibrary.shippedSizes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$size×$size · $stars★',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: <Widget>[
                            for (final group
                                in widget.library.groupsForSize(size, stars))
                              ...<Widget>[
                              Expanded(
                                child: _GroupTile(
                                  palette: palette,
                                  l10n: l10n,
                                  group: group,
                                  total: widget.library.countIn(group),
                                  solved: widget.progress
                                      .solvedIn(group.key)
                                      .length,
                                  bestTime:
                                      widget.progress.bestTime(group.key),
                                  onTap: () => _openGroup(group),
                                ),
                              ),
                              if (group.difficulty != Difficulty.values.last)
                                const SizedBox(width: 7),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.palette,
    required this.l10n,
    required this.group,
    required this.total,
    required this.solved,
    required this.bestTime,
    required this.onTap,
  });

  final NodroPalette palette;
  final AppLocalizations l10n;
  final PuzzleGroup group;
  final int total;
  final int solved;
  final int? bestTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A group can legitimately be empty: a 9x9 with two stars is never solvable
    // by tier-1 techniques alone, so it has no Easy puzzles at all. Greying the
    // tile is more honest than leaving a hole in the row.
    final available = total > 0;
    final complete = available && solved >= total;

    return Semantics(
      button: available,
      label: '${group.size}x${group.size} '
          '${group.difficulty.label(l10n)}, $solved/$total',
      child: InkWell(
        onTap: available ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          decoration: BoxDecoration(
            color: available
                ? palette
                    .regionTints[group.challenge % palette.regionTints.length]
                : palette.neighbourWash,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: available ? palette.ink : palette.hairline,
              width: available ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                group.difficulty.label(l10n),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available ? palette.ink : palette.inkSoft,
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                available
                    ? l10n.challengeBadge(group.challenge)
                    : l10n.selectEmptyGroup,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: available ? palette.ink : palette.inkSoft,
                  fontSize: 9.5,
                  height: 1.15,
                ),
              ),
              if (available) ...<Widget>[
                const SizedBox(height: 3),
                Text(
                  '$solved/$total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (bestTime != null)
                  Text(
                    formatDuration(bestTime!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 9.5,
                      height: 1.15,
                    ),
                  ),
                if (complete)
                  Icon(Icons.check_circle_rounded,
                      color: palette.success, size: 13),
              ],
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
                      style: TextStyle(color: palette.inkSoft, fontSize: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
