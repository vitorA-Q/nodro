import '../engine/core/deterministic_random.dart';
import '../engine/core/technique_tier.dart';
import '../ui/theme/challenge.dart';
import '../ui/theme/difficulty.dart';
import 'puzzle_bank.dart';

/// One cell of the selection grid: a board size crossed with a difficulty.
class PuzzleGroup {
  const PuzzleGroup(this.size, this.stars, this.difficulty);

  final int size;
  final int stars;
  final Difficulty difficulty;

  /// Stable identity for stored progress. Uses names rather than indices so
  /// reordering an enum never silently reassigns someone's history.
  String get key => '${size}x$size.${difficulty.storageKey}';

  /// The 1..10 axis that makes groups comparable across sizes.
  ///
  /// A group holds one tier band, so the band's lowest tier is used — a group
  /// needs one number, and taking the easiest entry keeps the label honest
  /// about what the player will most often meet.
  int get challenge => globalChallenge(
        size: size,
        stars: stars,
        tier: TechniqueTier.fromLevel(difficulty.tiers.first),
      );

  @override
  bool operator ==(Object other) =>
      other is PuzzleGroup &&
      other.size == size &&
      other.difficulty == difficulty;

  @override
  int get hashCode => Object.hash(size, difficulty);
}

/// A puzzle plus where it came from, so progress can be recorded against it.
class LibraryPuzzle {
  const LibraryPuzzle(this.id, this.group, this.entry);

  /// Stable within a given bank build.
  final String id;
  final PuzzleGroup group;
  final BankEntry entry;
}

/// The whole shipped bank, grouped for the selection screen.
///
/// Loaded once and held in memory: 4,500 puzzles of region digits is a few
/// hundred kilobytes, and the player must never wait (decision D2).
class PuzzleLibrary {
  PuzzleLibrary._(this._byGroup);

  /// The three shipped sizes. The 10x10 is deliberately absent — see BACKLOG.md.
  static const List<(int size, int stars)> shippedSizes = <(int, int)>[
    (6, 1),
    (8, 1),
    (9, 2),
  ];

  final Map<String, List<LibraryPuzzle>> _byGroup;

  static Future<PuzzleLibrary> load() async {
    final byGroup = <String, List<LibraryPuzzle>>{};

    for (final (size, stars) in shippedSizes) {
      final bank = await PuzzleBank.load('star_battle_${size}x${size}_$stars');
      final entries = bank.entries;
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        final group =
            PuzzleGroup(size, stars, Difficulty.of(entry.tier));
        byGroup
            .putIfAbsent(group.key, () => <LibraryPuzzle>[])
            .add(LibraryPuzzle('${size}x$size#$index', group, entry));
      }
    }

    return PuzzleLibrary._(byGroup);
  }

  /// Builds a library from puzzles already in hand.
  ///
  /// Exists so widget tests can read the bank file with `dart:io` instead of
  /// through `rootBundle`, which is a platform channel that only answers on the
  /// real event loop and hangs a fake-clock widget test.
  static PuzzleLibrary fromPuzzles(List<LibraryPuzzle> puzzles) {
    final byGroup = <String, List<LibraryPuzzle>>{};
    for (final puzzle in puzzles) {
      byGroup.putIfAbsent(puzzle.group.key, () => <LibraryPuzzle>[]).add(puzzle);
    }
    return PuzzleLibrary._(byGroup);
  }

  /// Every group in display order: size ascending, then difficulty ascending.
  List<PuzzleGroup> get groups => <PuzzleGroup>[
        for (final (size, stars) in shippedSizes)
          for (final difficulty in Difficulty.values)
            PuzzleGroup(size, stars, difficulty),
      ];

  int countIn(PuzzleGroup group) => _byGroup[group.key]?.length ?? 0;

  List<LibraryPuzzle> inGroup(PuzzleGroup group) =>
      List<LibraryPuzzle>.unmodifiable(
          _byGroup[group.key] ?? const <LibraryPuzzle>[]);

  /// Groups ordered by how hard they actually are, across sizes.
  ///
  /// Ordering by board size hides the thing the challenge number exists to
  /// reveal: a 6x6 Extreme is genuinely easier than a 9x9 Medium, and a hub
  /// sorted by size argues the opposite every time it is opened.
  List<PuzzleGroup> get groupsByChallenge {
    final all = groups.where((group) => countIn(group) > 0).toList();
    all.sort((a, b) {
      final byChallenge = a.challenge.compareTo(b.challenge);
      return byChallenge != 0 ? byChallenge : a.size.compareTo(b.size);
    });
    return all;
  }

  /// Picks a puzzle the player has not finished yet.
  ///
  /// Only falls back to repeating one when every puzzle in the group is
  /// already solved — the requirement is "never repeat while unseen ones
  /// remain", not "never repeat".
  LibraryPuzzle? pick(
    PuzzleGroup group,
    Set<String> solvedIds,
    DeterministicRandom random,
  ) {
    final all = _byGroup[group.key];
    if (all == null || all.isEmpty) {
      return null;
    }
    final unseen =
        all.where((puzzle) => !solvedIds.contains(puzzle.id)).toList();
    final pool = unseen.isNotEmpty ? unseen : all;
    return pool[random.nextInt(pool.length)];
  }

  LibraryPuzzle? byId(String id) {
    for (final puzzles in _byGroup.values) {
      for (final puzzle in puzzles) {
        if (puzzle.id == id) {
          return puzzle;
        }
      }
    }
    return null;
  }

  /// The daily challenge: same puzzle for everyone on a given date, chosen with
  /// a seed derived only from the calendar (decision D9). No server involved.
  LibraryPuzzle? daily(DateTime date) {
    final random = DeterministicRandom.forDate(date, 'starBattle');
    // A fixed group so the daily has a predictable shape day to day.
    const group = PuzzleGroup(8, 1, Difficulty.medium);
    final all = _byGroup[group.key];
    if (all == null || all.isEmpty) {
      return null;
    }
    return all[random.nextInt(all.length)];
  }
}
