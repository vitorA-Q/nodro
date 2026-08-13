import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Everything the player has done, and everything they were in the middle of.
///
/// Decision D10: the storage is the simplest thing that behaves identically on
/// web and Android, hidden behind this interface so replacing it later is a
/// one-file change. Nothing above this layer knows that shared_preferences
/// exists.
abstract class ProgressRepository {
  Future<void> load();

  /// Puzzle ids the player has finished, per group.
  Set<String> solvedIn(String groupKey);

  /// Records a win. [seconds] updates the group's best time when it beats it.
  Future<void> recordSolved(String groupKey, String puzzleId, int seconds);

  /// Best time in seconds for a group, or null if never finished.
  int? bestTime(String groupKey);

  /// The game in progress, as an opaque blob, or null.
  String? savedGame();

  /// Autosave. Called often, so it must be cheap and must never throw.
  Future<void> saveGame(String? blob);

  /// Dates, as `yyyy-mm-dd`, on which the daily challenge was completed.
  Set<String> dailyCompletions();

  /// The stored result for a day, or null if it was never finished.
  ///
  /// A daily challenge is daily: once it is done it stays done until the local
  /// date turns over, and reopening shows this instead of a fresh board.
  DailyResult? dailyResult(String isoDate);

  Future<void> recordDaily(String isoDate, DailyResult result);

  /// How much the board marks on the player's behalf.
  AutoMarkSetting autoMark();

  Future<void> setAutoMark(AutoMarkSetting setting);
}

/// What the player scored on a given day.
class DailyResult {
  const DailyResult({
    required this.seconds,
    required this.hintsUsed,
    required this.puzzleId,
  });

  final int seconds;
  final int hintsUsed;
  final String puzzleId;

  Map<String, Object> toJson() => <String, Object>{
        's': seconds,
        'h': hintsUsed,
        'p': puzzleId,
      };

  static DailyResult? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return DailyResult(
      seconds: raw['s'] as int? ?? 0,
      hintsUsed: raw['h'] as int? ?? 0,
      puzzleId: raw['p'] as String? ?? '',
    );
  }
}

/// Stored as a plain string so the storage layer never imports UI code.
typedef AutoMarkSetting = String;

/// Backed by shared_preferences: localStorage on the web, SharedPreferences on
/// Android. Values are kept in memory after [load] so reads are synchronous —
/// the UI asks "how many have I solved" while building a frame.
class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository();

  static const String _solvedKey = 'nodro.solved.v1';
  static const String _bestKey = 'nodro.best.v1';
  static const String _gameKey = 'nodro.game.v1';
  static const String _dailyKey = 'nodro.daily.v2';
  static const String _autoMarkKey = 'nodro.automark.v1';

  SharedPreferences? _prefs;
  Map<String, Set<String>> _solved = <String, Set<String>>{};
  Map<String, int> _best = <String, int>{};
  Map<String, DailyResult> _daily = <String, DailyResult>{};

  @override
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    // A corrupt blob must not brick the app: the player loses history, not
    // access. This is the one place a swallowed error is the right call, and
    // it is narrow — decoding an untrusted local string.
    try {
      final rawSolved = _prefs!.getString(_solvedKey);
      if (rawSolved != null) {
        final decoded = jsonDecode(rawSolved) as Map<String, dynamic>;
        _solved = decoded.map((key, value) => MapEntry(
            key, (value as List<dynamic>).map((e) => e as String).toSet()));
      }
      final rawBest = _prefs!.getString(_bestKey);
      if (rawBest != null) {
        final decoded = jsonDecode(rawBest) as Map<String, dynamic>;
        _best = decoded.map((key, value) => MapEntry(key, value as int));
      }
      final rawDaily = _prefs!.getString(_dailyKey);
      if (rawDaily != null) {
        final decoded = jsonDecode(rawDaily) as Map<String, dynamic>;
        _daily = <String, DailyResult>{};
        decoded.forEach((key, value) {
          final result = DailyResult.fromJson(value);
          if (result != null) {
            _daily[key] = result;
          }
        });
      }
    } on Object {
      _solved = <String, Set<String>>{};
      _best = <String, int>{};
      _daily = <String, DailyResult>{};
    }
  }

  @override
  Set<String> solvedIn(String groupKey) =>
      _solved[groupKey] ?? const <String>{};

  @override
  Future<void> recordSolved(
      String groupKey, String puzzleId, int seconds) async {
    _solved.putIfAbsent(groupKey, () => <String>{}).add(puzzleId);
    final previous = _best[groupKey];
    if (previous == null || seconds < previous) {
      _best[groupKey] = seconds;
    }
    await _prefs?.setString(
        _solvedKey,
        jsonEncode(
            _solved.map((key, value) => MapEntry(key, value.toList()))));
    await _prefs?.setString(_bestKey, jsonEncode(_best));
  }

  @override
  int? bestTime(String groupKey) => _best[groupKey];

  @override
  String? savedGame() => _prefs?.getString(_gameKey);

  @override
  Future<void> saveGame(String? blob) async {
    if (blob == null) {
      await _prefs?.remove(_gameKey);
    } else {
      await _prefs?.setString(_gameKey, blob);
    }
  }

  @override
  Set<String> dailyCompletions() => _daily.keys.toSet();

  @override
  DailyResult? dailyResult(String isoDate) => _daily[isoDate];

  @override
  Future<void> recordDaily(String isoDate, DailyResult result) async {
    // First finish of the day wins. Replaying must not move the streak or the
    // best time, or the daily stops being daily.
    if (_daily.containsKey(isoDate)) {
      return;
    }
    _daily[isoDate] = result;
    await _prefs?.setString(
        _dailyKey,
        jsonEncode(
            _daily.map((key, value) => MapEntry(key, value.toJson()))));
  }

  @override
  AutoMarkSetting autoMark() => _prefs?.getString(_autoMarkKey) ?? 'full';

  @override
  Future<void> setAutoMark(AutoMarkSetting setting) async {
    await _prefs?.setString(_autoMarkKey, setting);
  }
}

/// In-memory implementation for tests. Same contract, no platform channel.
class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, Set<String>> _solved = <String, Set<String>>{};
  final Map<String, int> _best = <String, int>{};
  final Map<String, DailyResult> _daily = <String, DailyResult>{};
  String? _game;
  AutoMarkSetting _autoMark = 'full';

  @override
  Future<void> load() async {}

  @override
  Set<String> solvedIn(String groupKey) =>
      _solved[groupKey] ?? const <String>{};

  @override
  Future<void> recordSolved(
      String groupKey, String puzzleId, int seconds) async {
    _solved.putIfAbsent(groupKey, () => <String>{}).add(puzzleId);
    final previous = _best[groupKey];
    if (previous == null || seconds < previous) {
      _best[groupKey] = seconds;
    }
  }

  @override
  int? bestTime(String groupKey) => _best[groupKey];

  @override
  String? savedGame() => _game;

  @override
  Future<void> saveGame(String? blob) async => _game = blob;

  @override
  Set<String> dailyCompletions() => _daily.keys.toSet();

  @override
  DailyResult? dailyResult(String isoDate) => _daily[isoDate];

  @override
  Future<void> recordDaily(String isoDate, DailyResult result) async {
    _daily.putIfAbsent(isoDate, () => result);
  }

  @override
  AutoMarkSetting autoMark() => _autoMark;

  @override
  Future<void> setAutoMark(AutoMarkSetting setting) async =>
      _autoMark = setting;
}
