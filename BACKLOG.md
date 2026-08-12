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
