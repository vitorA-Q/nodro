# BACKLOG — coisas boas que NÃO entram no marco 1

Regra de escopo (S1): até o marco 1 estar no ar, tudo que for identificado como "seria bom
fazer" e não estiver na definição de pronto do marco 1 é anotado aqui e seguimos em frente.
Sem implementar, sem perguntar.

O marco 1 é: **Star Battle jogável e publicado na web**, com dicas, tutorial, desafio diário
com botão de compartilhar, em pt-BR e inglês.

---

## Outros tipos de puzzle

- **Slitherlink** — motor completo. É o mais difícil dos quatro por causa da restrição de laço
  único. Catálogo de 30 técnicas já levantado em `docs/research/slitherlink_techniques.md`, e a
  decisão arquitetural (duas estruturas de união-e-busca + verificação final independente) já
  está documentada. Entra logo depois do marco 1.
- **Shikaku** — motor completo. Catálogo de 19 técnicas em `docs/research/shikaku_techniques.md`.
- **Tents & Trees** — motor completo. Catálogo de 22 técnicas em `docs/research/tents_techniques.md`.

## Idiomas

- Alemão, japonês, holandês, polonês, espanhol e francês. A infraestrutura de tradução fica
  pronta no marco 1 (todo texto sai de arquivos `.arb`), mas as traduções em si entram antes da
  Play Store.
- Revisão humana das dicas em cada idioma. Dica é explicação de raciocínio; tradução automática
  ruim mata a proposta de "dicas que ensinam".

## Monetização (Fase 6)

- Compra única "Pro" via `in_app_purchase`.
- Anúncios recompensados para dicas extras. **O contador de dicas é construído no marco 1**
  (decisão D8), só o anúncio em si fica para depois.
- Interstitial com as regras de frequência do briefing.
- Anúncios de display na web, só quando o tráfego justificar.

## Android

- Ícone adaptativo, splash, R8, `--split-per-abi`.
- Crashlytics + Analytics.
- Checklist de Data Safety do Play.
- Processo de teste fechado (12 testadores por 14 dias).

## Progressão e estatísticas

- Estatísticas completas por tipo e por tier de técnica (a versão simples do streak entra no
  marco 1 junto com o desafio diário; a completa é do Pro).
- Trilha de aprendizado: puzzles agrupados pela técnica que ensinam.
- Biblioteca de técnicas navegável (recurso do Pro).

## Técnicas de Star Battle ainda não implementadas

Registrar aqui as que ficarem de fora do primeiro motor, para não sumirem. O catálogo completo
está em `docs/research/star_battle_techniques.md`.

- `cornerEdgeCapacity` — a pesquisa recomenda implementar como dica de ordenação de busca, não
  como técnica separada. Reavaliar se a qualidade das dicas pedir.
- `compositeRegionTiling` (tier 4), `pressuredShapeExclusion` (tier 5),
  `setDifferentials` (tier 5), `finnedCounting` (tier 6), `forcingChainRelay` (tier 6).

## Ideias de produto

- Star Battle 14x14 com 3 estrelas, para entusiastas.
- Variante do Tents com números redundantes escondidos (possível diferencial do Pro).
- Variante do Shikaku com números trocados por interrogação — é uma variante publicada de
  verdade, e o mecanismo já existiria por causa do teste de minimalidade.
- Domínio próprio antes do lançamento público.

## Dívida técnica conhecida

- A pasta antiga em `OneDrive\Área de Trabalho\deduce` ficou vazia porque a sessão que fez a
  mudança a mantinha aberta. Pode ser apagada manualmente a qualquer momento.

## Geração ao vivo no dispositivo — FORA do marco 1

Decisão D16. A meta original de 300 ms por puzzle foi definida para gerar puzzle na hora, no
aparelho do jogador. O marco 1 não faz isso: usa banco pré-gerado em assets, construído uma vez
no PC. Então a meta não bloqueia mais nada — mas a análise fica registrada aqui para quando o
modo infinito entrar.

Medições single-thread do gerador atual (Dart 3.12.2, mediana):

| Tamanho | Mediana | Dentro dos 300 ms? |
|---|---|---|
| 6x6 / 1 estrela | 1,0 ms | sim |
| 8x8 / 1 estrela | 4,3 ms | sim |
| 9x9 / 2 estrelas | 610 ms | não |
| 10x10 / 2 estrelas | 7.725 ms | não, 25x acima |

O gargalo é o refinamento de unicidade, não a busca. O gerador já faz solução-primeiro (sorteia
as estrelas antes das regiões, então a existência de solução é garantida por construção) e já faz
busca linha a linha com posicionamentos pré-computados. O custo está em transformar um traçado de
regiões qualquer num traçado com resposta única: layouts aleatórios são únicos ~1 vez em 300.

Duas otimizações plausíveis foram testadas e **medidas como piores** (ver regra W7):
- orçamento de refinamento de 400 para 6.000 passos: 610 ms → 1.074 ms
- pontuar 6 movimentos candidatos e ficar com o melhor: 610 ms → 904 ms

Hipóteses ainda não testadas, para quando o modo infinito for prioridade:
- Bitmask de 64 bits para linhas, colunas e regiões no oráculo (hoje as linhas já são bitmask, mas
  as contagens de coluna e região são arrays de int).
- Começar de um traçado de regiões já mais restrito, em vez de crescer e depois consertar.
- Gerar em segundo plano com folga, escondendo a latência atrás da fila de puzzles do jogador.
## Revisitar se houver reclamação de jogador

- **Star Battle com "espaço morto".** PROP-6 foi declarado não aplicável ao Star Battle em
  12/08/2026, com medição: 63% a 72% das mudanças de fronteira preservam a unicidade e nenhum
  puzzle é rígido. A conclusão é que célula longe de estrela não carrega informação, e isso é
  propriedade do gênero. **Se aparecer reclamação real de jogador** dizendo que os puzzles têm
  regiões grandes e sem graça, ou "muito espaço que não faz nada", revisitar com dado real de
  uso — não com teoria. O ponto de partida seria medir a distribuição de tamanho de região e a
  distância média entre estrelas nos puzzles reclamados.

## Otimização do gerador — fora do caminho crítico

- **Bitmask de 64 bits para contagens de coluna e região no oráculo.** É a única das três
  hipóteses de velocidade que ainda não foi testada (as outras duas já estavam implementadas:
  busca por linha com posicionamentos pré-computados, e solução-primeiro). Fora do Marco 1 por
  decisão: o banco é gerado uma vez no PC e o jogador nunca espera, então um gerador 3x mais
  rápido não muda nada no lançamento.
## 10x10 com 2 estrelas — FORA do Marco 1, decidido

Não perguntar sobre isto de novo até o Marco 1 estar publicado.

O banco tem três tamanhos (6x6, 8x8, 9x9) e quatro dificuldades, o que basta para avaliar se o
jogo é bom. O 10x10 gera lento demais para encher uma fatia em tempo razoável: uma rodada
paralela sozinha estourou o orçamento de tempo inteiro antes do corte agir. O corte foi
consertado (rodadas menores), mas o lote não foi refeito, de propósito.

Quando voltar: rodar `dart run tool/generate_bank.dart --max-minutes 45` e deixar trabalhando.