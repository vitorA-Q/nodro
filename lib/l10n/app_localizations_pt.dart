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
  String challengeBadge(int value) {
    return 'Desafio $value/10';
  }

  @override
  String get autoMarkTitle => 'Marcação automática';

  @override
  String get autoMarkOff => 'Desligada';

  @override
  String get autoMarkOffBody => 'Nada é marcado para você.';

  @override
  String get autoMarkNeighbours => 'Vizinhos';

  @override
  String get autoMarkNeighboursBody =>
      'Marca as oito células ao redor de cada estrela.';

  @override
  String get autoMarkFull => 'Completa';

  @override
  String get autoMarkFullBody =>
      'Vizinhos, mais toda linha, coluna ou região que já tem todas as estrelas dela.';

  @override
  String get dailyLockedTitle => 'O desafio de hoje já foi feito';

  @override
  String get dailyLockedBody => 'Volte amanhã para um novo.';

  @override
  String get practiceThis => 'Praticar este puzzle';

  @override
  String get practiceBanner => 'Prática · não conta pontos';

  @override
  String get hintTapWhy => 'Toque para entender por quê';

  @override
  String get hintTapApply => 'Toque para aplicar';

  @override
  String get hintClose => 'Fechar';

  @override
  String get pickRandom => 'Aleatório';

  @override
  String get pickFromList => 'Escolher da lista';

  @override
  String pickTitle(int size, String difficulty) {
    return '$size×$size · $difficulty';
  }

  @override
  String get filterAll => 'Todos';

  @override
  String get filterUnsolved => 'Não resolvidos';

  @override
  String get filterSolved => 'Resolvidos';

  @override
  String puzzleNumber(int number) {
    return '#$number';
  }

  @override
  String solvedInWithHints(String time, int hints) {
    String _temp0 = intl.Intl.pluralLogic(
      hints,
      locale: localeName,
      other: '$hints dicas',
      one: '1 dica',
      zero: 'sem dicas',
    );
    return '$time · $_temp0';
  }

  @override
  String get tutorialTitle => 'Como jogar';

  @override
  String get tutorialStep1 =>
      'O objetivo é colocar estrelas. Toque na célula destacada para colocar uma.';

  @override
  String get tutorialStep2 =>
      'Estrelas nunca são vizinhas — nem na diagonal. Viu as oito células ao redor ficarem cinzas? Nenhuma estrela cabe ali.';

  @override
  String get tutorialStep3 =>
      'Neste tabuleiro, cada linha e cada coluna tem exatamente uma estrela. Então o resto daquela linha e daquela coluna também foi eliminado.';

  @override
  String get tutorialStep4 =>
      'As áreas coloridas são regiões, marcadas pelas bordas grossas. Cada região também tem exatamente uma estrela. É isso que deixa o puzzle interessante.';

  @override
  String get tutorialStep5 =>
      'Agora uma dedução de verdade. Toque no painel de dica para ver o que o tabuleiro já consegue provar.';

  @override
  String get tutorialStep6 =>
      'É esse o jogo inteiro: colocar uma estrela, ver o que ela elimina, e achar a célula que não tem mais outra opção.';

  @override
  String get tutorialDone => 'Concluir';

  @override
  String get tutorialNext => 'Avançar';

  @override
  String get tutorialSkip => 'Pular';

  @override
  String get tutorialWrongCell => 'Essa não — tente a célula destacada.';

  @override
  String get tutorialTwoStarTitle => 'Duas estrelas por linha';

  @override
  String get tutorialTwoStar1 =>
      'Este tabuleiro é diferente: cada linha, coluna e região tem DUAS estrelas.';

  @override
  String get tutorialTwoStar2 =>
      'Então uma estrela não fecha a linha dela. Repare — colocar esta aqui só bloqueia as vizinhas.';

  @override
  String get tutorialTwoStar3 =>
      'Agora a segunda estrela daquela linha. Só agora o resto da linha é eliminado, porque a linha completou a cota dela.';

  @override
  String get tutorialTwoStar4 =>
      'É essa a regra que muda: a linha só é eliminada quando está CHEIA, não quando tem uma estrela.';

  @override
  String get techniquesTitle => 'Técnicas';

  @override
  String get techniquesSubtitle =>
      'Toda dedução que este jogo vai pedir de você, nomeada e explicada. Nenhum puzzle daqui precisa de chute.';

  @override
  String techniqueTier(int tier) {
    return 'Tier $tier';
  }

  @override
  String techniqueSeen(int count) {
    return 'Usada $count vezes';
  }

  @override
  String get techniqueUnseen => 'Ainda não apareceu';

  @override
  String get techniqueOpenLibrary => 'Ler sobre esta técnica';

  @override
  String get statsTitle => 'Estatísticas';

  @override
  String get statsSolvedTotal => 'Puzzles resolvidos';

  @override
  String get statsCurrentStreak => 'Sequência atual';

  @override
  String get statsBestStreak => 'Maior sequência';

  @override
  String get statsHintsUsed => 'Dicas usadas';

  @override
  String statsAverage(String time) {
    return 'Média $time';
  }

  @override
  String get statsLast30 => 'Últimos 30 dias';

  @override
  String get statsNothingYet =>
      'Nada ainda — resolva um puzzle e ele aparece aqui.';

  @override
  String get statsTopTechniques => 'Técnicas que você mais precisou';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsTimer => 'Mostrar o cronômetro';

  @override
  String get settingsHaptics => 'Vibração';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get settingsEraseAll => 'Apagar todo o progresso';

  @override
  String get settingsEraseWarning =>
      'Isso remove todos os puzzles resolvidos, melhores tempos e sequências. Não dá para desfazer.';

  @override
  String get settingsEraseConfirm => 'Apagar tudo';

  @override
  String get settingsEraseReally => 'Apagar mesmo? Não tem volta.';

  @override
  String get settingsErased => 'Progresso apagado';

  @override
  String get openTutorial => 'Refazer o tutorial';

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
