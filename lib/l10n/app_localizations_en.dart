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
