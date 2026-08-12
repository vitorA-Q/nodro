// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Nodro';

  @override
  String get starBattleName => 'Star Battle';

  @override
  String get difficultyEasy => 'Fácil';

  @override
  String get difficultyMedium => 'Médio';

  @override
  String get difficultyHard => 'Difícil';

  @override
  String get difficultyExtreme => 'Extremo';

  @override
  String headerLine(String name, int size, String difficulty) {
    return '$name · $size×$size · $difficulty';
  }

  @override
  String ruleLine(int stars) {
    return '$stars estrela por linha, coluna e região · estrelas nunca se tocam, nem na diagonal';
  }

  @override
  String get tapHint => 'Toque numa célula: vazio → estrela → X';

  @override
  String starsPlaced(int placed, int total) {
    return '$placed de $total estrelas';
  }

  @override
  String get solvedMessage => 'Resolvido!';

  @override
  String get loadingBank => 'Carregando puzzle…';

  @override
  String get loadFailed => 'Não foi possível carregar o banco de puzzles.';
}
