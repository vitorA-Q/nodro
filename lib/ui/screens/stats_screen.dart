import 'package:flutter/material.dart';

import '../../data/progress_repository.dart';
import '../../data/puzzle_library.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../game/hint_text.dart';
import '../theme/nodro_theme.dart';

/// What the player has actually done.
///
/// Includes which techniques they leaned on most, which is the number that
/// tells them something about themselves rather than about the app.
class StatsScreen extends StatelessWidget {
  const StatsScreen({
    super.key,
    required this.progress,
    required this.library,
  });

  final ProgressRepository progress;
  final PuzzleLibrary library;

  int get _totalSolved {
    var total = 0;
    for (final (size, stars) in PuzzleLibrary.shippedSizes) {
      for (final group in library.groupsForSize(size, stars)) {
        total += progress.solvedIn(group.key).length;
      }
    }
    return total;
  }

  /// The longest run of consecutive completed days ever recorded.
  int get _bestStreak {
    final days = progress.dailyCompletions().toList()..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      final parts = day.split('-').map(int.parse).toList();
      final date = DateTime(parts[0], parts[1], parts[2]);
      run = (previous != null && date.difference(previous).inDays == 1)
          ? run + 1
          : 1;
      previous = date;
      if (run > best) {
        best = run;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);
    final text = HintText(l10n);
    final hints = progress.hintCounts();
    final totalHints =
        hints.values.fold<int>(0, (sum, value) => sum + value);
    final topTechniques = hints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: palette.paper,
      appBar: AppBar(
        backgroundColor: palette.paper,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(l10n.statsTitle,
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
                if (_totalSolved == 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      l10n.statsNothingYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.inkSoft, fontSize: 14),
                    ),
                  )
                else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          palette: palette,
                          label: l10n.statsSolvedTotal,
                          value: '$_totalSolved',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(
                          palette: palette,
                          label: l10n.statsHintsUsed,
                          value: '$totalHints',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          palette: palette,
                          label: l10n.statsCurrentStreak,
                          value: '${currentStreak(progress.dailyCompletions(), DateTime.now())}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(
                          palette: palette,
                          label: l10n.statsBestStreak,
                          value: '$_bestStreak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final (size, stars) in PuzzleLibrary.shippedSizes) ...<Widget>[
                    Text(
                      '$size×$size · $stars★',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final group in library.groupsForSize(size, stars))
                      if (library.countIn(group) > 0)
                        _GroupLine(
                          palette: palette,
                          label: group.difficulty.label(l10n),
                          solved: progress.solvedIn(group.key).length,
                          total: library.countIn(group),
                          best: progress.bestTime(group.key),
                        ),
                    const SizedBox(height: 14),
                  ],
                  if (topTechniques.isNotEmpty) ...<Widget>[
                    Text(
                      l10n.statsTopTechniques,
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final entry in topTechniques.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                text.name(entry.key),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: palette.ink, fontSize: 12.5),
                              ),
                            ),
                            Text('${entry.value}',
                                style: TextStyle(
                                    color: palette.inkSoft, fontSize: 12.5)),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.palette, required this.label, required this.value});

  final NodroPalette palette;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hairline, width: 1.5),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: palette.ink,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: palette.inkSoft, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _GroupLine extends StatelessWidget {
  const _GroupLine({
    required this.palette,
    required this.label,
    required this.solved,
    required this.total,
    required this.best,
  });

  final NodroPalette palette;
  final String label;
  final int solved;
  final int total;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : solved / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 66,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: palette.ink, fontSize: 12)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 7,
                backgroundColor: palette.neighbourWash,
                valueColor: AlwaysStoppedAnimation<Color>(palette.success),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              best == null
                  ? '$solved/$total'
                  : '$solved/$total · ${formatDuration(best!)}',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.inkSoft, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
