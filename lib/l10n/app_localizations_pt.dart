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
  String get unitRow => 'linha';

  @override
  String get unitColumn => 'coluna';

  @override
  String get unitRegion => 'região';

  @override
  String get selectTitle => 'Escolha um puzzle';

  @override
  String selectSolvedCount(int solved, int total) {
    return '$solved de $total resolvidos';
  }

  @override
  String get selectEmptyGroup => 'Nenhum ainda';

  @override
  String selectBestTime(String time) {
    return 'Melhor $time';
  }

  @override
  String get dailyChallenge => 'Desafio diário';

  @override
  String dailyStreak(int days) {
    return '$days dias seguidos';
  }

  @override
  String get dailyDoneToday => 'Feito hoje';

  @override
  String get continueGame => 'Continuar';

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

  @override
  String get actionUndo => 'Desfazer';

  @override
  String get actionRedo => 'Refazer';

  @override
  String get actionClear => 'Limpar';

  @override
  String get actionHint => 'Dica';

  @override
  String get actionBack => 'Voltar';

  @override
  String get clearConfirmTitle => 'Limpar o tabuleiro?';

  @override
  String get clearConfirmBody =>
      'Todas as marcas saem. Você ainda pode desfazer.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get wonTitle => 'Resolvido';

  @override
  String wonTime(String time) {
    return '$time';
  }

  @override
  String get wonNewBest => 'Novo melhor tempo';

  @override
  String wonHintsUsed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dicas',
      one: '1 dica',
      zero: 'Sem dicas',
    );
    return '$_temp0';
  }

  @override
  String get nextPuzzle => 'Próximo puzzle';

  @override
  String get backToMenu => 'Escolher outro';

  @override
  String get shareResult => 'Compartilhar';

  @override
  String get copiedToClipboard => 'Copiado';

  @override
  String hintStepTechnique(String name) {
    return 'Técnica: $name';
  }

  @override
  String get hintStepLook => 'Olhe as células destacadas.';

  @override
  String get hintNextStep => 'Explique melhor';

  @override
  String get hintApply => 'Aplicar';

  @override
  String get hintDismiss => 'Entendi';

  @override
  String get hintMistakeTitle => 'Há um erro no tabuleiro';

  @override
  String hintMistakeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marcas contradizem a solução.',
      one: 'Uma marca contradiz a solução.',
    );
    return '$_temp0 Desfaça até antes dela e as dicas voltam a ajudar.';
  }

  @override
  String get hintUndoToMistake => 'Desfazer até a última jogada boa';

  @override
  String get hintStuck => 'Nenhuma técnica nomeada se aplica aqui.';

  @override
  String get techName_sbAdjacencyElimination => 'Eliminação por vizinhança';

  @override
  String techWhy_sbAdjacencyElimination(String starCell, int count) {
    return 'Há uma estrela em $starCell. Estrelas nunca se tocam, nem na diagonal, então nenhuma das $count células marcadas pode ter uma.';
  }

  @override
  String get techName_sbUnitCompletionElimination => 'Unidade já completa';

  @override
  String techWhy_sbUnitCompletionElimination(
    String unit,
    int index,
    int quota,
  ) {
    return 'Esta $unit $index já tem todas as $quota estrelas dela, então toda célula ainda aberta ali está vazia.';
  }

  @override
  String get techName_sbUnitForcedFill => 'Só sobraram estes lugares';

  @override
  String techWhy_sbUnitForcedFill(String unit, int index, int remaining) {
    return 'Esta $unit $index ainda precisa de $remaining estrela(s) e tem exatamente esse tanto de células livres, então todas elas são estrelas.';
  }

  @override
  String get techName_sbSharedNeighbourElimination => 'Vizinhas em comum';

  @override
  String techWhy_sbSharedNeighbourElimination(
    String unit,
    int index,
    int candidateCount,
  ) {
    return 'A estrela que falta nesta $unit $index tem que estar numa das $candidateCount células destacadas. Cada célula marcada encosta em todas elas, então onde quer que a estrela caia, elas não podem ter uma.';
  }

  @override
  String get techName_sbRegionLineConfinement => 'Região presa numa linha';

  @override
  String techWhy_sbRegionLineConfinement(
    int regionIndex,
    String line,
    int lineIndex,
    int stars,
  ) {
    return 'Toda célula ainda aberta da região $regionIndex está nesta $line $lineIndex. As $stars estrela(s) dessa região consomem toda a cota da linha, então o resto da linha fica vazio.';
  }

  @override
  String get techName_sbLineRegionConfinement => 'Linha presa numa região';

  @override
  String techWhy_sbLineRegionConfinement(
    String line,
    int lineIndex,
    int regionIndex,
    int stars,
  ) {
    return 'Toda célula ainda aberta desta $line $lineIndex está dentro da região $regionIndex. As $stars estrela(s) da linha saem da cota daquela região, então as outras células dela ficam vazias.';
  }

  @override
  String get techName_sbCrowdingExclusion => 'Apertado demais';

  @override
  String techWhy_sbCrowdingExclusion(String unit, int index, int remaining) {
    return 'Esta $unit $index ainda precisa de $remaining estrelas. A célula marcada encosta em todas as outras candidatas, então pôr uma estrela ali não deixaria lugar para as demais.';
  }

  @override
  String get techName_sbForwardElimination => 'Um passo à frente';

  @override
  String techWhy_sbForwardElimination(String cell) {
    return 'Suponha uma estrela em $cell. Ela apagaria as vizinhas e fecharia a linha, a coluna e a região — e aí alguma unidade não alcançaria mais a cota dela. Logo, não cabe estrela ali.';
  }

  @override
  String get techName_sbRegionsWithinLines =>
      'Regiões ocupando linhas inteiras';

  @override
  String techWhy_sbRegionsWithinLines(
    int regionCount,
    String line,
    String lineIndices,
    int stars,
  ) {
    return '$regionCount regiões têm todas as células abertas dentro d${line}s $lineIndices. Essas regiões fornecem exatamente as $stars estrelas que essas linhas precisam, então toda outra célula delas fica vazia.';
  }
}
