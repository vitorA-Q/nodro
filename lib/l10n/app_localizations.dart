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

  /// A 1..10 number comparable across board sizes, shown beside the difficulty label.
  ///
  /// In en, this message translates to:
  /// **'Challenge {value}/10'**
  String challengeBadge(int value);

  /// No description provided for @autoMarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic marking'**
  String get autoMarkTitle;

  /// No description provided for @autoMarkOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get autoMarkOff;

  /// No description provided for @autoMarkOffBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is marked for you.'**
  String get autoMarkOffBody;

  /// No description provided for @autoMarkNeighbours.
  ///
  /// In en, this message translates to:
  /// **'Neighbours'**
  String get autoMarkNeighbours;

  /// No description provided for @autoMarkNeighboursBody.
  ///
  /// In en, this message translates to:
  /// **'Cross out the eight cells around each star.'**
  String get autoMarkNeighboursBody;

  /// No description provided for @autoMarkFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get autoMarkFull;

  /// No description provided for @autoMarkFullBody.
  ///
  /// In en, this message translates to:
  /// **'Neighbours, plus any row, column or region that already has all its stars.'**
  String get autoMarkFullBody;

  /// No description provided for @dailyLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenge is done'**
  String get dailyLockedTitle;

  /// No description provided for @dailyLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow for a new one.'**
  String get dailyLockedBody;

  /// Replays a finished daily without a clock and without affecting the streak.
  ///
  /// In en, this message translates to:
  /// **'Practise this puzzle'**
  String get practiceThis;

  /// No description provided for @practiceBanner.
  ///
  /// In en, this message translates to:
  /// **'Practice · not scored'**
  String get practiceBanner;

  /// No description provided for @hintTapWhy.
  ///
  /// In en, this message translates to:
  /// **'Tap to see why'**
  String get hintTapWhy;

  /// No description provided for @hintTapApply.
  ///
  /// In en, this message translates to:
  /// **'Tap to apply it'**
  String get hintTapApply;

  /// No description provided for @hintClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get hintClose;

  /// No description provided for @pickRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get pickRandom;

  /// No description provided for @pickFromList.
  ///
  /// In en, this message translates to:
  /// **'Choose from the list'**
  String get pickFromList;

  /// No description provided for @pickTitle.
  ///
  /// In en, this message translates to:
  /// **'{size}×{size} · {difficulty}'**
  String pickTitle(int size, String difficulty);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnsolved.
  ///
  /// In en, this message translates to:
  /// **'Unsolved'**
  String get filterUnsolved;

  /// No description provided for @filterSolved.
  ///
  /// In en, this message translates to:
  /// **'Solved'**
  String get filterSolved;

  /// No description provided for @puzzleNumber.
  ///
  /// In en, this message translates to:
  /// **'#{number}'**
  String puzzleNumber(int number);

  /// No description provided for @solvedInWithHints.
  ///
  /// In en, this message translates to:
  /// **'{time} · {hints, plural, =0{no hints} =1{1 hint} other{{hints} hints}}'**
  String solvedInWithHints(String time, int hints);

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get tutorialTitle;

  /// No description provided for @tutorialStep1.
  ///
  /// In en, this message translates to:
  /// **'The goal is to place stars. Tap the highlighted cell to place one.'**
  String get tutorialStep1;

  /// No description provided for @tutorialStep2.
  ///
  /// In en, this message translates to:
  /// **'Stars are never neighbours — not even diagonally. See how the eight cells around it went grey? No star can go there.'**
  String get tutorialStep2;

  /// No description provided for @tutorialStep3.
  ///
  /// In en, this message translates to:
  /// **'Every row and every column holds exactly one star on this board. So the rest of that row and column just got crossed out too.'**
  String get tutorialStep3;

  /// No description provided for @tutorialStep4.
  ///
  /// In en, this message translates to:
  /// **'The coloured areas are regions, marked by the thick borders. Each region also holds exactly one star. That is what makes the puzzle interesting.'**
  String get tutorialStep4;

  /// No description provided for @tutorialStep5.
  ///
  /// In en, this message translates to:
  /// **'Now a real deduction. Tap the hint panel to see what the board can already prove.'**
  String get tutorialStep5;

  /// No description provided for @tutorialStep6.
  ///
  /// In en, this message translates to:
  /// **'That is the whole game: place a star, watch what it rules out, and find the cell that has no other option left.'**
  String get tutorialStep6;

  /// No description provided for @tutorialDone.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutorialDone;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// Gentle correction. The tutorial never blocks or scolds.
  ///
  /// In en, this message translates to:
  /// **'Not that one — try the highlighted cell.'**
  String get tutorialWrongCell;

  /// No description provided for @tutorialTwoStarTitle.
  ///
  /// In en, this message translates to:
  /// **'Two stars per line'**
  String get tutorialTwoStarTitle;

  /// No description provided for @tutorialTwoStar1.
  ///
  /// In en, this message translates to:
  /// **'This board is different: every row, column and region holds TWO stars.'**
  String get tutorialTwoStar1;

  /// No description provided for @tutorialTwoStar2.
  ///
  /// In en, this message translates to:
  /// **'So one star does not finish its row. Watch — placing this one only blocks its neighbours.'**
  String get tutorialTwoStar2;

  /// No description provided for @tutorialTwoStar3.
  ///
  /// In en, this message translates to:
  /// **'Now the second star in that row. Only now does the rest of the row get crossed out, because the row has its full quota.'**
  String get tutorialTwoStar3;

  /// No description provided for @tutorialTwoStar4.
  ///
  /// In en, this message translates to:
  /// **'That is the one rule to carry over: a line clears when it is FULL, not when it has a star.'**
  String get tutorialTwoStar4;

  /// No description provided for @techniquesTitle.
  ///
  /// In en, this message translates to:
  /// **'Techniques'**
  String get techniquesTitle;

  /// No description provided for @techniquesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every deduction this game will ever ask of you, named and explained. No puzzle here needs a guess.'**
  String get techniquesSubtitle;

  /// No description provided for @techniqueTier.
  ///
  /// In en, this message translates to:
  /// **'Tier {tier}'**
  String techniqueTier(int tier);

  /// No description provided for @techniqueSeen.
  ///
  /// In en, this message translates to:
  /// **'Used {count} times'**
  String techniqueSeen(int count);

  /// No description provided for @techniqueUnseen.
  ///
  /// In en, this message translates to:
  /// **'Not met yet'**
  String get techniqueUnseen;

  /// No description provided for @techniqueOpenLibrary.
  ///
  /// In en, this message translates to:
  /// **'Read about this technique'**
  String get techniqueOpenLibrary;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsSolvedTotal.
  ///
  /// In en, this message translates to:
  /// **'Puzzles solved'**
  String get statsSolvedTotal;

  /// No description provided for @statsCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statsCurrentStreak;

  /// No description provided for @statsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get statsBestStreak;

  /// No description provided for @statsHintsUsed.
  ///
  /// In en, this message translates to:
  /// **'Hints used'**
  String get statsHintsUsed;

  /// No description provided for @statsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average {time}'**
  String statsAverage(String time);

  /// No description provided for @statsLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statsLast30;

  /// No description provided for @statsNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet — solve a puzzle and it shows up here.'**
  String get statsNothingYet;

  /// No description provided for @statsTopTechniques.
  ///
  /// In en, this message translates to:
  /// **'Techniques you needed most'**
  String get statsTopTechniques;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsTimer.
  ///
  /// In en, this message translates to:
  /// **'Show the timer'**
  String get settingsTimer;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsHaptics;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @settingsEraseAll.
  ///
  /// In en, this message translates to:
  /// **'Erase all progress'**
  String get settingsEraseAll;

  /// No description provided for @settingsEraseWarning.
  ///
  /// In en, this message translates to:
  /// **'This removes every solved puzzle, best time and streak. It cannot be undone.'**
  String get settingsEraseWarning;

  /// No description provided for @settingsEraseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase everything'**
  String get settingsEraseConfirm;

  /// No description provided for @settingsEraseReally.
  ///
  /// In en, this message translates to:
  /// **'Really erase? There is no way back.'**
  String get settingsEraseReally;

  /// No description provided for @settingsErased.
  ///
  /// In en, this message translates to:
  /// **'Progress erased'**
  String get settingsErased;

  /// No description provided for @openTutorial.
  ///
  /// In en, this message translates to:
  /// **'Replay the tutorial'**
  String get openTutorial;

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
