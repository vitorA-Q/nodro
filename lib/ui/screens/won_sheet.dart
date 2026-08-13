import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/analytics.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../game/game_session.dart';
import '../theme/challenge.dart';
import '../theme/difficulty.dart';
import '../theme/nodro_theme.dart';

/// The completion screen.
///
/// This is the moment of highest attention in a whole session, so it earns more
/// care than any other surface: the time is the hero, and NEXT PUZZLE is the
/// biggest, warmest target on it. Everything here exists to make the next board
/// easier to start than to walk away from.
Future<void> showWonSheet({
  required BuildContext context,
  required GameSession session,
  required bool isNewBest,
  required bool isDaily,
  required int streak,
  required VoidCallback onNext,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => _WonSheet(
      session: session,
      isNewBest: isNewBest,
      isDaily: isDaily,
      streak: streak,
      onNext: onNext,
    ),
  );
}

/// The shared result: Wordle-shaped, and it reveals NOTHING about the solution.
///
/// The emoji block is a PACE GAUGE, not a picture of the board — always ten
/// segments regardless of board size, so neither its length nor its shape says
/// anything about the puzzle. Sharing the grid itself would hand the answer to
/// whoever reads the message, which would quietly destroy the daily challenge
/// for everyone in the thread, using the one feature meant to spread it.
///
/// A top-level function so a test can assert the no-leak property directly.
String buildShareText({
  required AppLocalizations l10n,
  required GameSession session,
  required bool isDaily,
  required int streak,
}) {
  final puzzle = session.puzzle.entry.puzzle;
  final difficulty = Difficulty.of(session.puzzle.entry.tier).label(l10n);

  // Par is generous on purpose: the bar should feel like a reward, not a
  // scolding, for anyone who finished at all.
  final par = puzzle.size * puzzle.size * 4;
  final ratio = par / math.max(session.elapsedSeconds, 1);
  final filled = (ratio * 6).round().clamp(1, 10);
  final bar = '${'🟩' * filled}${'⬜' * (10 - filled)}';

  final challenge = globalChallenge(
    size: puzzle.size,
    stars: puzzle.starsPerUnit,
    tier: session.puzzle.entry.tier,
  );

  return <String>[
    isDaily
        ? '${l10n.appTitle} · ${l10n.dailyChallenge}'
        : '${l10n.appTitle} · ${l10n.puzzleNumber(session.puzzle.number)}',
    '${puzzle.size}×${puzzle.size} $difficulty · '
        '${l10n.challengeBadge(challenge)}',
    '⏱ ${formatDuration(session.elapsedSeconds)} · '
        '${l10n.wonHintsUsed(session.hintsUsed)}',
    bar,
    if (isDaily && streak > 1) '🔥 $streak',
    'nodro.app',
  ].join('\n');
}

class _WonSheet extends StatelessWidget {
  const _WonSheet({
    required this.session,
    required this.isNewBest,
    required this.isDaily,
    required this.streak,
    required this.onNext,
  });

  final GameSession session;
  final bool isNewBest;
  final bool isDaily;
  final int streak;
  final VoidCallback onNext;

  /// Wordle-shaped, and it reveals NOTHING about the solution.
  ///
  /// The bar is a pace gauge, not a picture of the board: sharing the grid
  /// itself would hand the answer to whoever reads the message, which would
  /// quietly destroy the daily challenge for everyone in the thread.
  String _shareText(AppLocalizations l10n) => buildShareText(
        l10n: l10n,
        session: session,
        isDaily: isDaily,
        streak: streak,
      );

  /// Native share sheet when the platform has one, clipboard when it does not.
  ///
  /// Either way the player gets visible confirmation: a share that silently
  /// does nothing is worse than no share button, because they think it worked.
  Future<void> _share(BuildContext context, AppLocalizations l10n) async {
    Analytics.shared(isDaily);
    final text = _shareText(l10n);
    var shared = false;
    try {
      final result = await Share.share(text);
      shared = result.status == ShareResultStatus.success;
    } on Object {
      // No share sheet on this platform, or the user dismissed it.
      shared = false;
    }

    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.copiedToClipboard),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = NodroPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: palette.ink, width: 2),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.star_rounded, color: palette.success, size: 40),
            const SizedBox(height: 6),
            Text(
              l10n.wonTitle,
              style: TextStyle(
                color: palette.success,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              formatDuration(session.elapsedSeconds),
              style: TextStyle(
                color: palette.ink,
                fontSize: 46,
                height: 1.05,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            if (isNewBest) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                l10n.wonNewBest,
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              l10n.wonHintsUsed(session.hintsUsed),
              style: TextStyle(color: palette.inkSoft, fontSize: 13),
            ),
            if (isDaily && streak > 0) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                '🔥 ${l10n.dailyStreak(streak)}',
                style: TextStyle(color: palette.inkSoft, fontSize: 13),
              ),
            ],
            const SizedBox(height: 22),
            // The daily deliberately does NOT offer another puzzle. Handing out
            // a fresh board at the exact moment "one per day" should become
            // clear would argue against the mechanic while announcing it.
            if (isDaily) ...<Widget>[
              _PrimaryButton(
                palette: palette,
                label: l10n.shareResult,
                icon: Icons.ios_share_rounded,
                onTap: () => _share(context, l10n),
              ),
              const SizedBox(height: 10),
              _SecondaryButton(
                palette: palette,
                label: l10n.backToMenu,
                icon: Icons.grid_view_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).maybePop();
                },
              ),
            ] else ...<Widget>[
              _PrimaryButton(
                palette: palette,
                label: l10n.nextPuzzle,
                icon: Icons.arrow_forward_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  onNext();
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SecondaryButton(
                      palette: palette,
                      label: l10n.shareResult,
                      icon: Icons.ios_share_rounded,
                      onTap: () => _share(context, l10n),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryButton(
                      palette: palette,
                      label: l10n.backToMenu,
                      icon: Icons.grid_view_rounded,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
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
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: palette.ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: palette.paper,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: palette.paper, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.hairline, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: palette.ink, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
