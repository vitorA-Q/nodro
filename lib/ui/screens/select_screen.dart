import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../engine/core/deterministic_random.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../theme/nodro_theme.dart';
import 'pick_screen.dart';
import 'play_screen.dart';

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
    required this.onToggleTheme,
  });

  final PuzzleLibrary library;
  final ProgressRepository progress;
  final VoidCallback onToggleTheme;

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
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
                for (final group in widget.library.groupsByChallenge)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _GroupRow(
                      palette: palette,
                      l10n: l10n,
                      group: group,
                      total: widget.library.countIn(group),
                      solved: widget.progress.solvedIn(group.key).length,
                      bestTime: widget.progress.bestTime(group.key),
                      onTap: () => _openGroup(group),
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

class _GroupRow extends StatelessWidget {
  const _GroupRow({
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
    final complete = solved >= total && total > 0;

    return Semantics(
      button: true,
      label: '${group.size}x${group.size} '
          '${group.difficulty.label(l10n)}, $solved/$total',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette
                .regionTints[group.challenge % palette.regionTints.length],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.ink, width: 2),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${group.size}×${group.size} · '
                      '${group.difficulty.label(l10n)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.challengeBadge(group.challenge)}'
                      '${bestTime != null ? ' · ${l10n.selectBestTime(formatDuration(bestTime!))}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.ink, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '$solved/$total',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (complete)
                    Icon(Icons.check_circle_rounded,
                        color: palette.success, size: 16),
                ],
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
