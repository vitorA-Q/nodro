// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Nodro';

  @override
  String get starBattleName => 'Star Battle';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExtreme => 'Extreme';

  @override
  String boardSummary(int size, int stars) {
    return '$size×$size · $stars star per row, column and region';
  }

  @override
  String starsPlaced(int placed, int total) {
    return '$placed of $total stars';
  }

  @override
  String get solvedMessage => 'Solved!';

  @override
  String get loadingBank => 'Loading puzzle…';

  @override
  String get loadFailed => 'Could not load the puzzle bank.';
}
