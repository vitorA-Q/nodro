import 'analytics_stub.dart'
    if (dart.library.js_interop) 'analytics_web.dart';

/// Product analytics with no cookies, no identifiers and no personal data.
///
/// Every event below is a counter. Nothing here can distinguish one player from
/// another, and nothing is stored that would let anyone try. The question this
/// is meant to answer is a single one: **where do people give up?**
///
/// The events are emitted unconditionally; whether anything receives them is a
/// deployment decision. The web implementation calls a global `nodroTrack`
/// hook, so pointing it at a cookieless provider — Cloudflare Web Analytics,
/// GoatCounter, Umami — is one script tag in `web/index.html`, and with no hook
/// present the calls are silent no-ops.
abstract final class Analytics {
  static void _send(String event, Map<String, String> props) =>
      sendAnalyticsEvent(event, props);

  static void appOpened() => _send('app_open', const <String, String>{});

  static void tutorialStarted(String kind) =>
      _send('tutorial_start', <String, String>{'kind': kind});

  static void tutorialFinished(String kind) =>
      _send('tutorial_finish', <String, String>{'kind': kind});

  /// [group] is a size-and-difficulty key such as `8x8.hard`. Deliberately the
  /// group and never the puzzle id: the drop-off question is about difficulty,
  /// and per-puzzle data would start to look like a fingerprint.
  static void puzzleStarted(String group) =>
      _send('puzzle_start', <String, String>{'group': group});

  static void puzzleSolved(String group, int seconds, int hints) =>
      _send('puzzle_solve', <String, String>{
        'group': group,
        // Bucketed, not exact: an exact duration is far closer to a unique
        // signature than it looks.
        'bucket': _bucket(seconds),
        'hints': hints > 3 ? '4+' : '$hints',
      });

  /// Left without finishing. This is the number that says where the game is
  /// too hard, too slow or too confusing.
  static void puzzleAbandoned(String group, int starsPlaced, int total) =>
      _send('puzzle_abandon', <String, String>{
        'group': group,
        'progress': total == 0
            ? '0'
            : '${((starsPlaced / total) * 4).floor() * 25}',
      });

  static void hintUsed(String techniqueId) =>
      _send('hint', <String, String>{'technique': techniqueId});

  static void shared(bool isDaily) =>
      _send('share', <String, String>{'daily': isDaily ? '1' : '0'});

  static String _bucket(int seconds) {
    if (seconds < 60) {
      return '<1m';
    }
    if (seconds < 180) {
      return '1-3m';
    }
    if (seconds < 600) {
      return '3-10m';
    }
    return '10m+';
  }
}
