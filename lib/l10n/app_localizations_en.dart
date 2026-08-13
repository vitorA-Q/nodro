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
  String get unitRow => 'row';

  @override
  String get unitColumn => 'column';

  @override
  String get unitRegion => 'region';

  @override
  String get selectTitle => 'Choose a puzzle';

  @override
  String selectSolvedCount(int solved, int total) {
    return '$solved of $total solved';
  }

  @override
  String get selectEmptyGroup => 'None yet';

  @override
  String selectBestTime(String time) {
    return 'Best $time';
  }

  @override
  String get dailyChallenge => 'Daily challenge';

  @override
  String dailyStreak(int days) {
    return '$days day streak';
  }

  @override
  String get dailyDoneToday => 'Done today';

  @override
  String get continueGame => 'Continue';

  @override
  String headerLine(String name, int size, String difficulty) {
    return '$name · $size×$size · $difficulty';
  }

  @override
  String ruleLine(int stars) {
    return '$stars star per row, column and region · stars never touch, not even diagonally';
  }

  @override
  String get tapHint => 'Tap a cell: empty → star → cross';

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

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionRedo => 'Redo';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionHint => 'Hint';

  @override
  String get actionBack => 'Back';

  @override
  String get clearConfirmTitle => 'Clear the board?';

  @override
  String get clearConfirmBody =>
      'Every mark is removed. You can still undo it.';

  @override
  String get cancel => 'Cancel';

  @override
  String get wonTitle => 'Solved';

  @override
  String wonTime(String time) {
    return '$time';
  }

  @override
  String get wonNewBest => 'New best time';

  @override
  String wonHintsUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hints',
      one: '1 hint',
      zero: 'No hints',
    );
    return '$_temp0';
  }

  @override
  String get nextPuzzle => 'Next puzzle';

  @override
  String get backToMenu => 'Choose another';

  @override
  String get shareResult => 'Share';

  @override
  String get copiedToClipboard => 'Copied';

  @override
  String hintStepTechnique(String name) {
    return 'Technique: $name';
  }

  @override
  String get hintStepLook => 'Look at the highlighted cells.';

  @override
  String get hintNextStep => 'Tell me more';

  @override
  String get hintApply => 'Apply it';

  @override
  String get hintDismiss => 'Got it';

  @override
  String get hintMistakeTitle => 'There is a mistake on the board';

  @override
  String hintMistakeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marks contradict the solution.',
      one: 'One mark contradicts the solution.',
    );
    return '$_temp0 Undo back to before it and the hints can help again.';
  }

  @override
  String get hintUndoToMistake => 'Undo to the last good move';

  @override
  String get hintStuck => 'No named technique applies here.';

  @override
  String challengeBadge(int value) {
    return 'Challenge $value/10';
  }

  @override
  String get autoMarkTitle => 'Automatic marking';

  @override
  String get autoMarkOff => 'Off';

  @override
  String get autoMarkOffBody => 'Nothing is marked for you.';

  @override
  String get autoMarkNeighbours => 'Neighbours';

  @override
  String get autoMarkNeighboursBody =>
      'Cross out the eight cells around each star.';

  @override
  String get autoMarkFull => 'Full';

  @override
  String get autoMarkFullBody =>
      'Neighbours, plus any row, column or region that already has all its stars.';

  @override
  String get dailyLockedTitle => 'Today\'s challenge is done';

  @override
  String get dailyLockedBody => 'Come back tomorrow for a new one.';

  @override
  String get practiceThis => 'Practise this puzzle';

  @override
  String get practiceBanner => 'Practice · not scored';

  @override
  String get hintTapWhy => 'Tap to see why';

  @override
  String get hintTapApply => 'Tap to apply it';

  @override
  String get hintClose => 'Close';

  @override
  String get pickRandom => 'Random';

  @override
  String get pickFromList => 'Choose from the list';

  @override
  String pickTitle(int size, String difficulty) {
    return '$size×$size · $difficulty';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterUnsolved => 'Unsolved';

  @override
  String get filterSolved => 'Solved';

  @override
  String puzzleNumber(int number) {
    return '#$number';
  }

  @override
  String solvedInWithHints(String time, int hints) {
    String _temp0 = intl.Intl.pluralLogic(
      hints,
      locale: localeName,
      other: '$hints hints',
      one: '1 hint',
      zero: 'no hints',
    );
    return '$time · $_temp0';
  }

  @override
  String get tutorialTitle => 'How to play';

  @override
  String get tutorialStep1 =>
      'The goal is to place stars. Tap the highlighted cell to place one.';

  @override
  String get tutorialStep2 =>
      'Stars are never neighbours — not even diagonally. See how the eight cells around it went grey? No star can go there.';

  @override
  String get tutorialStep3 =>
      'Every row and every column holds exactly one star on this board. So the rest of that row and column just got crossed out too.';

  @override
  String get tutorialStep4 =>
      'The coloured areas are regions, marked by the thick borders. Each region also holds exactly one star. That is what makes the puzzle interesting.';

  @override
  String get tutorialStep5 =>
      'Now a real deduction. Tap the hint panel to see what the board can already prove.';

  @override
  String get tutorialStep6 =>
      'That is the whole game: place a star, watch what it rules out, and find the cell that has no other option left.';

  @override
  String get tutorialDone => 'Finish';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialWrongCell => 'Not that one — try the highlighted cell.';

  @override
  String get tutorialTwoStarTitle => 'Two stars per line';

  @override
  String get tutorialTwoStar1 =>
      'This board is different: every row, column and region holds TWO stars.';

  @override
  String get tutorialTwoStar2 =>
      'So one star does not finish its row. Watch — placing this one only blocks its neighbours.';

  @override
  String get tutorialTwoStar3 =>
      'Now the second star in that row. Only now does the rest of the row get crossed out, because the row has its full quota.';

  @override
  String get tutorialTwoStar4 =>
      'That is the one rule to carry over: a line clears when it is FULL, not when it has a star.';

  @override
  String get techniquesTitle => 'Techniques';

  @override
  String get techniquesSubtitle =>
      'Every deduction this game will ever ask of you, named and explained. No puzzle here needs a guess.';

  @override
  String techniqueTier(int tier) {
    return 'Tier $tier';
  }

  @override
  String techniqueSeen(int count) {
    return 'Used $count times';
  }

  @override
  String get techniqueUnseen => 'Not met yet';

  @override
  String get techniqueOpenLibrary => 'Read about this technique';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsSolvedTotal => 'Puzzles solved';

  @override
  String get statsCurrentStreak => 'Current streak';

  @override
  String get statsBestStreak => 'Longest streak';

  @override
  String get statsHintsUsed => 'Hints used';

  @override
  String statsAverage(String time) {
    return 'Average $time';
  }

  @override
  String get statsLast30 => 'Last 30 days';

  @override
  String get statsNothingYet =>
      'Nothing yet — solve a puzzle and it shows up here.';

  @override
  String get statsTopTechniques => 'Techniques you needed most';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsTimer => 'Show the timer';

  @override
  String get settingsHaptics => 'Vibration';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsEraseAll => 'Erase all progress';

  @override
  String get settingsEraseWarning =>
      'This removes every solved puzzle, best time and streak. It cannot be undone.';

  @override
  String get settingsEraseConfirm => 'Erase everything';

  @override
  String get settingsEraseReally => 'Really erase? There is no way back.';

  @override
  String get settingsErased => 'Progress erased';

  @override
  String get openTutorial => 'Replay the tutorial';

  @override
  String get techName_sbAdjacencyElimination => 'Neighbour elimination';

  @override
  String techWhy_sbAdjacencyElimination(String starCell, int count) {
    return 'A star sits at $starCell. Stars never touch, not even diagonally, so none of the $count marked cells can hold one.';
  }

  @override
  String get techName_sbUnitCompletionElimination => 'Unit already complete';

  @override
  String techWhy_sbUnitCompletionElimination(
    String unit,
    int index,
    int quota,
  ) {
    return 'This $unit $index already holds all $quota of its stars, so every cell still open in it must be empty.';
  }

  @override
  String get techName_sbUnitForcedFill => 'Only places left';

  @override
  String techWhy_sbUnitForcedFill(String unit, int index, int remaining) {
    return 'This $unit $index still needs $remaining star(s) and has exactly that many cells left, so every one of them is a star.';
  }

  @override
  String get techName_sbSharedNeighbourElimination => 'Shared neighbours';

  @override
  String techWhy_sbSharedNeighbourElimination(
    String unit,
    int index,
    int candidateCount,
  ) {
    return 'The remaining star of this $unit $index must be in one of the $candidateCount highlighted cells. Each marked cell touches all of them, so wherever that star lands, they cannot hold one.';
  }

  @override
  String get techName_sbRegionLineConfinement => 'Region trapped in a line';

  @override
  String techWhy_sbRegionLineConfinement(
    int regionIndex,
    String line,
    int lineIndex,
    int stars,
  ) {
    return 'Every cell still open in region $regionIndex lies in this $line $lineIndex. That region\'s $stars star(s) therefore use up the whole quota of the line, so the rest of the line is empty.';
  }

  @override
  String get techName_sbLineRegionConfinement => 'Line trapped in a region';

  @override
  String techWhy_sbLineRegionConfinement(
    String line,
    int lineIndex,
    int regionIndex,
    int stars,
  ) {
    return 'Every cell still open in this $line $lineIndex sits inside region $regionIndex. The line\'s $stars star(s) therefore come out of that region\'s quota, so the region\'s other cells are empty.';
  }

  @override
  String get techName_sbCrowdingExclusion => 'Too crowded';

  @override
  String techWhy_sbCrowdingExclusion(String unit, int index, int remaining) {
    return 'This $unit $index still needs $remaining stars. The marked cell touches every other candidate, so putting a star there would leave nowhere for the others.';
  }

  @override
  String get techName_sbForwardElimination => 'One step ahead';

  @override
  String techWhy_sbForwardElimination(String cell) {
    return 'Suppose a star went at $cell. It would black out its neighbours and close its row, column and region — and then some unit could no longer reach its own quota. So no star can go there.';
  }

  @override
  String get techName_sbRegionsWithinLines => 'Regions filling whole lines';

  @override
  String techWhy_sbRegionsWithinLines(
    int regionCount,
    String line,
    String lineIndices,
    int stars,
  ) {
    return '$regionCount regions have all their open cells inside ${line}s $lineIndices. Those regions supply exactly the $stars stars those lines need, so every other cell in those lines is empty.';
  }
}
