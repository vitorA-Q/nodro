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

  Future<void> recordDaily(String isoDate);
}

/// Backed by shared_preferences: localStorage on the web, SharedPreferences on
/// Android. Values are kept in memory after [load] so reads are synchronous —
/// the UI asks "how many have I solved" while building a frame.
class SharedPrefsProgressRepository implements ProgressRepository {
  SharedPrefsProgressRepository();

  static const String _solvedKey = 'nodro.solved.v1';
  static const String _bestKey = 'nodro.best.v1';
  static const String _gameKey = 'nodro.game.v1';
  static const String _dailyKey = 'nodro.daily.v1';

  SharedPreferences? _prefs;
  Map<String, Set<String>> _solved = <String, Set<String>>{};
  Map<String, int> _best = <String, int>{};
  Set<String> _daily = <String>{};

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
        _daily = (jsonDecode(rawDaily) as List<dynamic>)
            .map((e) => e as String)
            .toSet();
      }
    } on Object {
      _solved = <String, Set<String>>{};
      _best = <String, int>{};
      _daily = <String>{};
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
  Set<String> dailyCompletions() => _daily;

  @override
  Future<void> recordDaily(String isoDate) async {
    _daily.add(isoDate);
    await _prefs?.setString(_dailyKey, jsonEncode(_daily.toList()));
  }
}

/// In-memory implementation for tests. Same contract, no platform channel.
class InMemoryProgressRepository implements ProgressRepository {
  final Map<String, Set<String>> _solved = <String, Set<String>>{};
  final Map<String, int> _best = <String, int>{};
  final Set<String> _daily = <String>{};
  String? _game;

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
  Set<String> dailyCompletions() => _daily;

  @override
  Future<void> recordDaily(String isoDate) async => _daily.add(isoDate);
}
