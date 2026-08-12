# NODRO — Briefing original

Este arquivo é a cópia integral do briefing do projeto, a partir da seção "MISSÃO",
para poder ser referenciado em sessões futuras sem precisar recolar nada.

Regras adicionais que valem sobre este documento:

- **ORG do projeto:** `com.vitorarzua` (package Android: `com.vitorarzua.nodro`)
- **Regra permanente de comunicação:** o usuário não programa. Toda comunicação com ele e
  todo o `PROGRESS.md` são em português simples. Código, nomes de variáveis e comentários
  ficam em inglês.

---

# MISSÃO

NODRO é uma coleção de puzzles lógicos combinatórios da família Nikoli
(Star Battle, Slitherlink, Shikaku, Tents & Trees e outros), com três
propriedades que definem o produto e não podem ser comprometidas por
nenhuma decisão de implementação:

  P1. UNICIDADE PROVADA
      Todo puzzle mostrado ao jogador tem exatamente uma solução, e isso é
      DEMONSTRADO por um solver exaustivo — nunca assumido pelo gerador.

  P2. DIFICULDADE POR TÉCNICA HUMANA
      A dificuldade é a técnica de dedução mais avançada que o puzzle EXIGE,
      determinada por um solver humano-símile. Não é contagem de pistas, não é
      tempo de força bruta, não é heurística estatística.

  P3. DICAS QUE ENSINAM
      O motor de dicas encontra a próxima dedução válida mais simples, nomeia a
      técnica, destaca as células envolvidas e explica POR QUE a dedução é
      válida. Uma dica nunca revela a resposta sem justificar o raciocínio.

Se qualquer decisão ameaçar P1, P2 ou P3, pare e levante a questão.

# POR QUE ESTAS TRÊS PROPRIEDADES SÃO O PRODUTO INTEIRO

Contexto de mercado que determina a estratégia: em 2026 as lojas de apps
receberam uma enxurrada de apps gerados por IA, enquanto os downloads
cresceram apenas 2-3%. O Google Play encolheu de 3,4 milhões para cerca de
1,89 milhão de apps. Existir não vale mais nada.

Qualquer pessoa gera um app de Slitherlink num fim de semana com IA. O que ela
NÃO consegue gerar é um cujos puzzles sejam provadamente únicos, porque ela não
sabe que precisa de um oráculo de verificação. Ela lança, os puzzles saem com
duas soluções ou nenhuma, o app leva 2 estrelas e morre.

O arnês de property tests não é rigor de engenharia. É o fosso competitivo.
É a única parte deste projeto que a concorrência não copia.
Se em algum momento você propuser cortar testes "para ir mais rápido", você
estará propondo destruir o produto. Não faça isso, e me avise se eu pedir.

# ESTRATÉGIA DE LANÇAMENTO — WEB PRIMEIRO

Ordem inegociável:
  1º  Versão web (Flutter Web), publicada e com SEO
  2º  Android (Google Play)
  3º  iOS, só se os dois anteriores funcionarem

Motivo: a web não tem portão de entrada. A loja exige 12 testadores por 14 dias
consecutivos, conta de adulto e fila de revisão que em 2026 chegou a semanas. A
web me dá usuários reais em duas semanas em vez de oito, valida a demanda antes
do investimento, e o tráfego de SEO ("slitherlink online", "star battle puzzle")
vira funil para o app depois. É o mesmo código-fonte.

Consequência arquitetural: NADA pode depender de plugin exclusivo de mobile nas
Fases 0 a 4. O SDK de anúncios só entra na Fase 6 e atrás de uma abstração.

# MONETIZAÇÃO — ordem de prioridade

  1. Compra única "Pro" (~US$4,99): dicas ilimitadas + sem anúncios + tipos
     extras de puzzle. Esta é a linha PRINCIPAL de receita.
  2. Rewarded ad: dicas além da primeira gratuita, no tier grátis.
  3. Interstitial: no máximo 1 a cada 2 puzzles concluídos. Nunca no meio de um
     puzzle. Nunca nos 3 primeiros puzzles de um usuário novo.
  4. Display ads na web, só quando o tráfego justificar.

NÃO implemente assinatura recorrente. NÃO implemente moeda virtual, loot box,
energia ou vidas. Nada disso combina com o público-alvo (adulto, entusiasta de
lógica), e loot box tem implicação regulatória no Brasil.

Nada de monetização antes da Fase 6.

# RESTRIÇÕES INEGOCIÁVEIS

R1. Flutter estável, Dart puro. NÃO use Flame nem game engine algum.
    Puzzles são grids estáticos: CustomPainter + RepaintBoundary bastam.
R2. NUNCA gere ou resolva puzzle na thread de UI. Tudo em Isolate.
    O app nunca pode travar.
R3. Zero dependência de rede em runtime. Funciona em modo avião.
R4. Cada tipo de puzzle é um módulo autocontido com interface comum.
    Adicionar o 15º tipo não pode exigir tocar nos 14 anteriores.
R5. A camada `engine/` é Dart puro e NÃO importa nada de `package:flutter/`.
    Regra estrutural: se o motor precisar de Flutter, o design está errado.
R6. Todo texto visível vem de arquivos .arb via gen_l10n. Zero string
    hardcoded na UI, incluindo nomes de técnicas e textos de dica.
R7. Sem `dynamic` em API pública. Sem `late` sem comentário justificando.
    flutter_lints com zero warnings.
R8. Tudo que funcionar no Android tem que funcionar na web. Se algo não der,
    me avise ANTES de implementar, não depois.

# CONTRATO DE CORRETUDE  ← a parte mais importante deste prompt

C1. NENHUMA linha de UI antes do motor da fase passar em todos os property
    tests. Sem exceção, sem "só pra visualizar".

C2. Para CADA tipo de puzzle, no mínimo 1.000 instâncias geradas com sementes
    fixas e reprodutíveis, testando:

    PROP-1 (unicidade)
      Todo puzzle gerado tem exatamente uma solução, verificado por um solver
      exaustivo independente que conta soluções com saída antecipada na segunda.

    PROP-2 (solucionabilidade humana)
      Todo puzzle é resolvível pelo solver humano-símile usando apenas técnicas
      nomeadas, sem nenhum passo de chute ou backtracking.

    PROP-3 (consistência de dificuldade)
      O rótulo de dificuldade é igual ao tier da técnica mais avançada que o
      solver humano-símile precisou usar. Determinístico.

    PROP-4 (soundness das técnicas)
      Nenhuma técnica jamais elimina um valor que pertence à solução verdadeira.
      Cruze cada dedução contra a solução conhecida. Técnica unsound é bug
      crítico, não detalhe.

    PROP-5 (serialização)
      serialize(deserialize(x)) == x para todo estado de puzzle e de progresso.

    PROP-6 (minimalidade)
      Remover qualquer pista adicional quebra a unicidade. Declare os tipos
      onde isso não se aplica e por quê.

C3. Dois solvers independentes por tipo:
      ExhaustiveSolver — correto por construção, lento, é o ORÁCULO
      HumanSolver      — aplica técnicas nomeadas por tier, é o PRODUTO
    O HumanSolver é validado CONTRA o ExhaustiveSolver, nunca o contrário.
    Se discordam, o HumanSolver está errado até prova em contrário.

C4. Ao declarar uma fase concluída, execute e COLE A SAÍDA REAL de:
      dart analyze            (zero issues)
      flutter test            (tudo verde)
      dart run tool/bench.dart
    Não escreva "os testes passam". Cole a saída.

# ARQUITETURA

```
lib/
  engine/                    ← Dart puro, ZERO import de flutter/
    core/
      puzzle_type.dart       interface comum
      grid.dart
      deduction.dart         Deduction, Technique, TechniqueTier
      solve_result.dart
    puzzles/
      star_battle/
        model.dart           estado imutável
        rules.dart           validação de restrições
        techniques/          uma técnica = um arquivo = uma classe
        human_solver.dart
        exhaustive_solver.dart
        generator.dart
      slitherlink/  shikaku/  tents/        mesma estrutura
  data/
    puzzle_bank.dart         banco pré-gerado em assets comprimidos
    progress_repository.dart
  ui/
    painters/  screens/  widgets/
  l10n/
test/
  property/                  PROP-1..PROP-6 por tipo
  golden/                    instâncias mínimas de falha, regressão permanente
  unit/
tool/
  bench.dart  generate_bank.dart
web/                         landing pages por tipo de puzzle, para SEO
```

Contratos centrais (adapte nomes, mantenha a semântica):

```dart
abstract class PuzzleType<S extends PuzzleState> {
  String get id;
  PuzzleGenerator<S> get generator;
  HumanSolver<S> get humanSolver;
  ExhaustiveSolver<S> get exhaustiveSolver;
  List<Technique<S>> get techniques;      // ordenadas por tier
  RuleValidator<S> get validator;
  PuzzleSerializer<S> get serializer;
}

abstract class Technique<S> {
  String get id;                   // chave de i18n
  TechniqueTier get tier;          // 1..7
  List<Deduction> apply(S state);  // vazio se não se aplica
}

class Deduction {
  final String techniqueId;
  final List<CellRef> highlightedCells;      // o que a dica destaca
  final List<CellRef> affectedCells;         // o que a dedução conclui
  final Map<String, Object> explanationArgs; // interpolado no .arb
}
```

Deduction tipada é o que torna P3 possível sem gambiarra: a dica não é texto
colado, é o resultado de uma dedução real.

# FASES

## FASE 0 — PLANEJAMENTO (nada de código de produção)

Escreva `planning.md` com:
  a) A missão nas suas palavras, para eu detectar divergência de entendimento
     antes que custe uma semana
  b) A lista COMPLETA de técnicas humanas por tipo de puzzle, com tier e uma
     frase de descrição cada. Espero 10 a 25 técnicas por tipo. Se listar 4,
     você não pesquisou o suficiente — use um subagente de pesquisa
  c) A estratégia de geração por tipo, com justificativa
     (solução-primeiro vs. pistas-primeiro vs. híbrida)
  d) Como garantir PROP-6 em cada tipo
  e) Riscos técnicos concretos e mitigação
  f) PERGUNTAS ABERTAS — tudo que você teve que assumir, ordenado por quanto
     uma resposta errada custaria em retrabalho. Seja generoso: prefiro
     responder 15 perguntas agora a descobrir 15 suposições erradas depois.
     Escreva as perguntas em português simples, com as opções explicadas.

REGRA: se em qualquer fase você se pegar assumindo algo sobre design de
produto, pare, adicione a planning.md e pergunte.

Aguarde minhas respostas antes da Fase 1.

## FASE 1 — MOTOR: STAR BATTLE

Star Battle é o primeiro porque as regras são mínimas (n estrelas por linha,
coluna e região; estrelas não se tocam nem na diagonal) mas as deduções são
ricas — melhor teste do arcabouço pelo menor custo de superfície.

DEFINITION OF DONE:
  □ PROP-1 a PROP-6 passando com 1.000+ instâncias
  □ Geração de grid 10x10 com 2 estrelas em menos de 300ms dentro de Isolate
  □ Mínimo 8 técnicas nomeadas, distribuídas em pelo menos 4 tiers
  □ dart analyze com zero issues
  □ Saída real dos comandos colada na resposta

## FASE 2 — MOTOR: SLITHERLINK, SHIKAKU, TENTS & TREES

Mesma DoD. Se ao adicionar o segundo tipo você precisar mudar `engine/core/`,
a abstração da Fase 1 estava errada — conserte a abstração, não faça caso
especial.

Slitherlink tem dificuldade específica: a restrição de loop único é global e
não-local. Trate conectividade explicitamente (union-find) e documente a
abordagem antes de implementar.

## FASE 3 — UI

  □ Renderer com CustomPainter, um por tipo
  □ Input: toque, toque longo, arrastar. Undo/redo ilimitado. Modo de notas
  □ Salvamento automático (o app pode morrer a qualquer momento)
  □ Motor de dicas ligado à UI com destaque visual das células
  □ Tutorial interativo por tipo
     ← CRÍTICO: "as regras são confusas" é a reclamação nº1 nos reviews do
       principal concorrente. Tutorial jogável, não muro de texto
  □ Tema claro e escuro
  □ 60fps em Android de baixo custo E em navegador desktop

## FASE 4 — WEB E SEO  ← esta fase vem ANTES da loja

  □ Build web funcional, responsivo, jogável no celular pelo navegador
  □ Uma landing page por tipo de puzzle, com URL própria, regras explicadas e
    o puzzle jogável na página
  □ Meta tags, Open Graph, schema.org, sitemap.xml, robots.txt
  □ Deploy configurado (GitHub Pages ou Cloudflare Pages — me explique a
    diferença em português e recomende uma)
  □ Carregamento inicial abaixo de 3 segundos
  □ Desafio diário funcionando (semente determinística derivada da data, para
    todo jogador receber o mesmo puzzle sem precisar de servidor)

## FASE 5 — PROGRESSÃO E i18n

  □ Streak, estatísticas por tipo e por tier de técnica
  □ Trilha de aprendizado: puzzles agrupados PELA técnica que ensinam
  □ Banco pré-gerado em assets + geração on-device para modo infinito
  □ gen_l10n com pt-BR, en, de, ja, nl, pl, es, fr
     (prioridade determinada por eCPM e por tradição de puzzles Nikoli)

## FASE 6 — MONETIZAÇÃO E ANDROID

  □ in_app_purchase: compra única Pro. Esta é a linha principal
  □ google_mobile_ads com IDs DE TESTE apenas, atrás de uma abstração para que
    os testes rodem sem SDK real
  □ Ícone adaptativo, splash, R8, --split-per-abi
  □ Crashlytics + Analytics
  □ Checklist de Data Safety do Play
  □ Build de release assinado
  □ Me guie, em português simples, pelo processo de teste fechado do Play
    (12 testadores por 14 dias) — passo a passo, sem pressupor conhecimento

# PROTOCOLO DE TRABALHO

W1. Plan Mode antes de qualquer mudança que toque múltiplos arquivos.
W2. Uma unidade lógica por vez. Faça stub de tudo, mostre a lista, depois
    preencha um a um. Não despeje 2.000 linhas de uma vez.
W3. Subagente para pesquisa, para não poluir o contexto principal.
W4. Subagente de segunda opinião com a tarefa de REFUTAR cada solver antes de
    eu aprovar. Quem escreveu não deve ser quem avalia.
W5. git commit em checkpoints lógicos, com mensagem descritiva.
W6. Ao fim de cada fase, escreva o resumo em PROGRESS.md, em português simples.

# ANTI-PADRÕES PROIBIDOS

X1. Corrija a CAUSA RAIZ. Nunca suprima erro com catch vazio, nunca retorne
    dado falso de fallback, nunca afrouxe um teste para ele passar. Property
    test falhando significa que o CÓDIGO está errado, não o teste.
X2. Nunca marque um puzzle como válido sem passar pelo ExhaustiveSolver.
X3. Nunca implemente uma técnica cuja soundness você não justifica em uma frase.
X4. Nunca use timeout ou limite de iterações como critério de dificuldade.
X5. Nunca crie um "solver genérico" por força bruta e chame de human solver.
X6. Nenhuma dependência nova sem uma frase de justificativa. Prefira a stdlib.
X7. Não escreva UI antes do motor passar. Já está em C1, e repito porque é a
    regra que os agentes mais quebram.
X8. Nada de assinatura recorrente, moeda virtual, energia, vidas ou loot box.
