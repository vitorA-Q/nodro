import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// The product name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'Nodro'**
  String get appTitle;

  /// No description provided for @starBattleName.
  ///
  /// In en, this message translates to:
  /// **'Star Battle'**
  String get starBattleName;

  /// Player-facing difficulty label. The four labels map onto internal technique tiers 1..7; only the tier is ever stored.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get difficultyExtreme;

  /// Used inside hint sentences.
  ///
  /// In en, this message translates to:
  /// **'row'**
  String get unitRow;

  /// No description provided for @unitColumn.
  ///
  /// In en, this message translates to:
  /// **'column'**
  String get unitColumn;

  /// No description provided for @unitRegion.
  ///
  /// In en, this message translates to:
  /// **'region'**
  String get unitRegion;

  /// No description provided for @selectTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a puzzle'**
  String get selectTitle;

  /// No description provided for @selectSolvedCount.
  ///
  /// In en, this message translates to:
  /// **'{solved} of {total} solved'**
  String selectSolvedCount(int solved, int total);

  /// Shown on a difficulty the bank has no puzzles for.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get selectEmptyGroup;

  /// No description provided for @selectBestTime.
  ///
  /// In en, this message translates to:
  /// **'Best {time}'**
  String selectBestTime(String time);

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String dailyStreak(int days);

  /// No description provided for @dailyDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get dailyDoneToday;

  /// No description provided for @continueGame.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueGame;

  /// No description provided for @headerLine.
  ///
  /// In en, this message translates to:
  /// **'{name} · {size}×{size} · {difficulty}'**
  String headerLine(String name, int size, String difficulty);

  /// No description provided for @ruleLine.
  ///
  /// In en, this message translates to:
  /// **'{stars} star per row, column and region · stars never touch, not even diagonally'**
  String ruleLine(int stars);

  /// No description provided for @tapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell: empty → star → cross'**
  String get tapHint;

  /// No description provided for @starsPlaced.
  ///
  /// In en, this message translates to:
  /// **'{placed} of {total} stars'**
  String starsPlaced(int placed, int total);

  /// No description provided for @solvedMessage.
  ///
  /// In en, this message translates to:
  /// **'Solved!'**
  String get solvedMessage;

  /// No description provided for @loadingBank.
  ///
  /// In en, this message translates to:
  /// **'Loading puzzle…'**
  String get loadingBank;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the puzzle bank.'**
  String get loadFailed;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get actionRedo;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get actionHint;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @clearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the board?'**
  String get clearConfirmTitle;

  /// No description provided for @clearConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every mark is removed. You can still undo it.'**
  String get clearConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @wonTitle.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get wonTitle;

  /// No description provided for @wonTime.
  ///
  /// In en, this message translates to:
  /// **'{time}'**
  String wonTime(String time);

  /// No description provided for @wonNewBest.
  ///
  /// In en, this message translates to:
  /// **'New best time'**
  String get wonNewBest;

  /// No description provided for @wonHintsUsed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hints} =1{1 hint} other{{count} hints}}'**
  String wonHintsUsed(int count);

  /// The button that keeps a session going. Prominent by design.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle'**
  String get nextPuzzle;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get backToMenu;

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareResult;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedToClipboard;

  /// No description provided for @hintStepTechnique.
  ///
  /// In en, this message translates to:
  /// **'Technique: {name}'**
  String hintStepTechnique(String name);

  /// No description provided for @hintStepLook.
  ///
  /// In en, this message translates to:
  /// **'Look at the highlighted cells.'**
  String get hintStepLook;

  /// No description provided for @hintNextStep.
  ///
  /// In en, this message translates to:
  /// **'Tell me more'**
  String get hintNextStep;

  /// No description provided for @hintApply.
  ///
  /// In en, this message translates to:
  /// **'Apply it'**
  String get hintApply;

  /// No description provided for @hintDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hintDismiss;

  /// No description provided for @hintMistakeTitle.
  ///
  /// In en, this message translates to:
  /// **'There is a mistake on the board'**
  String get hintMistakeTitle;

  /// No description provided for @hintMistakeBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One mark contradicts the solution.} other{{count} marks contradict the solution.}} Undo back to before it and the hints can help again.'**
  String hintMistakeBody(int count);

  /// No description provided for @hintUndoToMistake.
  ///
  /// In en, this message translates to:
  /// **'Undo to the last good move'**
  String get hintUndoToMistake;

  /// No description provided for @hintStuck.
  ///
  /// In en, this message translates to:
  /// **'No named technique applies here.'**
  String get hintStuck;

  /// No description provided for @techName_sbAdjacencyElimination.
  ///
  /// In en, this message translates to:
  /// **'Neighbour elimination'**
  String get techName_sbAdjacencyElimination;

  /// No description provided for @techWhy_sbAdjacencyElimination.
  ///
  /// In en, this message translates to:
  /// **'A star sits at {starCell}. Stars never touch, not even diagonally, so none of the {count} marked cells can hold one.'**
  String techWhy_sbAdjacencyElimination(String starCell, int count);

  /// No description provided for @techName_sbUnitCompletionElimination.
  ///
  /// In en, this message translates to:
  /// **'Unit already complete'**
  String get techName_sbUnitCompletionElimination;

  /// No description provided for @techWhy_sbUnitCompletionElimination.
  ///
  /// In en, this message translates to:
  /// **'This {unit} {index} already holds all {quota} of its stars, so every cell still open in it must be empty.'**
  String techWhy_sbUnitCompletionElimination(String unit, int index, int quota);

  /// No description provided for @techName_sbUnitForcedFill.
  ///
  /// In en, this message translates to:
  /// **'Only places left'**
  String get techName_sbUnitForcedFill;

  /// No description provided for @techWhy_sbUnitForcedFill.
  ///
  /// In en, this message translates to:
  /// **'This {unit} {index} still needs {remaining} star(s) and has exactly that many cells left, so every one of them is a star.'**
  String techWhy_sbUnitForcedFill(String unit, int index, int remaining);

  /// No description provided for @techName_sbSharedNeighbourElimination.
  ///
  /// In en, this message translates to:
  /// **'Shared neighbours'**
  String get techName_sbSharedNeighbourElimination;

  /// No description provided for @techWhy_sbSharedNeighbourElimination.
  ///
  /// In en, this message translates to:
  /// **'The remaining star of this {unit} {index} must be in one of the {candidateCount} highlighted cells. Each marked cell touches all of them, so wherever that star lands, they cannot hold one.'**
  String techWhy_sbSharedNeighbourElimination(
    String unit,
    int index,
    int candidateCount,
  );

  /// No description provided for @techName_sbRegionLineConfinement.
  ///
  /// In en, this message translates to:
  /// **'Region trapped in a line'**
  String get techName_sbRegionLineConfinement;

  /// No description provided for @techWhy_sbRegionLineConfinement.
  ///
  /// In en, this message translates to:
  /// **'Every cell still open in region {regionIndex} lies in this {line} {lineIndex}. That region\'s {stars} star(s) therefore use up the whole quota of the line, so the rest of the line is empty.'**
  String techWhy_sbRegionLineConfinement(
    int regionIndex,
    String line,
    int lineIndex,
    int stars,
  );

  /// No description provided for @techName_sbLineRegionConfinement.
  ///
  /// In en, this message translates to:
  /// **'Line trapped in a region'**
  String get techName_sbLineRegionConfinement;

  /// No description provided for @techWhy_sbLineRegionConfinement.
  ///
  /// In en, this message translates to:
  /// **'Every cell still open in this {line} {lineIndex} sits inside region {regionIndex}. The line\'s {stars} star(s) therefore come out of that region\'s quota, so the region\'s other cells are empty.'**
  String techWhy_sbLineRegionConfinement(
    String line,
    int lineIndex,
    int regionIndex,
    int stars,
  );

  /// No description provided for @techName_sbCrowdingExclusion.
  ///
  /// In en, this message translates to:
  /// **'Too crowded'**
  String get techName_sbCrowdingExclusion;

  /// No description provided for @techWhy_sbCrowdingExclusion.
  ///
  /// In en, this message translates to:
  /// **'This {unit} {index} still needs {remaining} stars. The marked cell touches every other candidate, so putting a star there would leave nowhere for the others.'**
  String techWhy_sbCrowdingExclusion(String unit, int index, int remaining);

  /// No description provided for @techName_sbForwardElimination.
  ///
  /// In en, this message translates to:
  /// **'One step ahead'**
  String get techName_sbForwardElimination;

  /// No description provided for @techWhy_sbForwardElimination.
  ///
  /// In en, this message translates to:
  /// **'Suppose a star went at {cell}. It would black out its neighbours and close its row, column and region — and then some unit could no longer reach its own quota. So no star can go there.'**
  String techWhy_sbForwardElimination(String cell);

  /// No description provided for @techName_sbRegionsWithinLines.
  ///
  /// In en, this message translates to:
  /// **'Regions filling whole lines'**
  String get techName_sbRegionsWithinLines;

  /// No description provided for @techWhy_sbRegionsWithinLines.
  ///
  /// In en, this message translates to:
  /// **'{regionCount} regions have all their open cells inside {line}s {lineIndices}. Those regions supply exactly the {stars} stars those lines need, so every other cell in those lines is empty.'**
  String techWhy_sbRegionsWithinLines(
    int regionCount,
    String line,
    String lineIndices,
    int stars,
  );
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
