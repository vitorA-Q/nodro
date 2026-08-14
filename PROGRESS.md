# NODRO — Diário de progresso

Escrito em português simples. Uma seção por fase, na ordem em que aconteceram.

---

## Fase -1 — Setup ✅ concluída

**Data:** 12/08/2026

### O que foi feito

1. **Confirmei que o Flutter funciona.** Versão 3.44.6, canal estável, Dart 3.12.2.
   Um detalhe: o Flutter estava instalado em `C:\flutter` mas não estava configurado para
   ser chamado de qualquer lugar do computador. Resolvi apontando o caminho completo em
   cada comando — não precisa mexer em nada na sua máquina.

2. **Criei o esqueleto do app** com o identificador `com.vitorarzua`, nome `nodro`, para
   **Android e Web**. A web foi incluída desde o primeiro minuto, como manda a estratégia.

3. **Criei o repositório git** e fiz o primeiro commit. Aqui houve um tropeço: o git não
   sabia quem você é (nunca tinha sido configurado com nome e e-mail nesta máquina), então
   ele se recusou a gravar o commit. Configurei seu nome e e-mail apenas dentro deste
   projeto, sem alterar nada global.

4. **Escrevi o `CLAUDE.md`** — é a memória permanente do projeto. Toda vez que uma nova
   sessão começar, esse arquivo é lido primeiro. Ele contém as três garantias do produto,
   o contrato de testes, as regras de arquitetura, os anti-padrões proibidos e a regra de
   que toda comunicação com você é em português simples.

5. **Escrevi o `docs/briefing.md`** — cópia integral do seu briefing original, para você
   poder referenciá-lo em sessões futuras sem recolar nada.

6. **Rodei os testes e a análise de código.** Ambos passaram limpos:
   - `flutter test` → 1 teste, tudo verde
   - `dart analyze` → nenhum problema encontrado

7. **Commitei tudo.** Dois commits: o esqueleto e a documentação.

### O que deu errado

Duas coisas pequenas, ambas já resolvidas por mim:

- O comando `flutter` não era reconhecido no terminal. Causa: a pasta de instalação não
  estava na lista de lugares onde o Windows procura programas. Contornado.
- O primeiro commit falhou porque o git não tinha nome nem e-mail configurados.
  Configurado localmente neste projeto.

### O que vem a seguir

A Fase 0 — planejamento puro, sem nenhuma linha de código de produção. Estou levantando o
catálogo completo de técnicas de dedução humanas de cada um dos quatro puzzles, que é a
peça que determina se a promessa "dificuldade honesta" e "dicas que ensinam" vai funcionar
ou não. No fim da Fase 0 você recebe uma lista de perguntas para responder, e só depois
disso a Fase 1 começa.

---

## Fase 0 — Planejamento ✅ concluída, aguardando suas respostas

**Data:** 12/08/2026

### O que foi feito

Escrevi o `planning.md` completo: a missão nas minhas palavras, o catálogo de técnicas dos
quatro puzzles, a estratégia de geração de cada um, a análise de minimalidade, dez riscos
técnicos com mitigação, e 17 perguntas para você.

**O catálogo de técnicas ficou em 96 técnicas no total**, levantadas por quatro pesquisas
independentes rodando em paralelo:

| Puzzle | Técnicas | Tiers usados |
|---|---|---|
| Star Battle | 25 | 6 |
| Slitherlink | 30 | 6 |
| Tents & Trees | 22 | 7 |
| Shikaku | 19 | 7 |

O briefing pedia de 10 a 25 por tipo. Cada técnica tem uma frase explicando **por que ela
nunca pode apagar uma célula que faz parte da resposta certa** — sem essa frase a técnica
não entra. Os catálogos completos estão em `docs/research/`.

### As descobertas que mudaram decisões

**1. Isolates não existem na web.** A documentação oficial do Flutter confirma. Isso é um
conflito direto entre duas regras suas: "tudo em thread paralela, o app nunca trava" e "tudo
que funciona no Android funciona na web". Virou a pergunta nº 1.

**2. O sorteador de números do Dart muda entre celular e navegador.** Se eu usasse o padrão,
o desafio diário sairia diferente para cada jogador dependendo do aparelho. Vou escrever um
próprio, ~30 linhas, sem dependência nova.

**3. Em Tents, o teste de minimalidade do jeito literal reprovaria 100% dos puzzles.** A
soma dos números das linhas sempre dá o número de árvores, que está à vista — então dois
números são sempre dedutíveis. Se eu não tivesse pesquisado, teria implementado o teste
ingênuo, visto 1.000 falhas, e passado horas procurando um bug inexistente no gerador.

**4. Em Shikaku, a substituição que eu mesmo tinha proposto era decorativa.** Eu tinha
sugerido um teste que, descobri depois, é verdadeiro em todo Shikaku que já existiu — ele
aprovaria tudo e não protegeria nada. Troquei por outro que funciona de verdade.

**5. Em Slitherlink, colorir "dentro e fora" não garante um laço só.** É possível ter uma
coloração perfeitamente consistente que desenha dois laços separados. Então as duas
estruturas são necessárias ao mesmo tempo, mais uma conferência final independente. O
briefing pedia essa análise antes de implementar — está feita.

### O que deu errado

Nada quebrou. Duas coisas que eu tinha escrito no meio do caminho estavam erradas (itens 3 e
4 acima) e foram corrigidas antes de virar código — que é exatamente para isso que a Fase 0
serve.

### O que vem a seguir

**Aguardo suas respostas.** As perguntas 1 a 6 bloqueiam a Fase 1; as outras onze eu consigo
tocar com as recomendações que deixei escritas, e ajustar depois se você preferir outra
coisa. As perguntas estão no fim do `planning.md`, todas em português, com as opções
explicadas e a consequência prática de cada uma.

Depois disso começa a Fase 1: o motor do Star Battle.

---

## Fase 1 — Motor do Star Battle 🔄 quase pronto

**Data:** 12/08/2026

### O que funciona

Motor completo em Dart puro: núcleo, oráculo exaustivo, tabuleiro de trabalho, 9 técnicas
nomeadas em 4 tiers, solver humano, gerador, serializador. Mais o gerador de banco paralelo.

**PROP-1 a PROP-5 passam** em 50 puzzles gerados na hora (6x6, 8x8, 9x9). A camada 2 de testes
roda em **6 segundos** — a meta era 2 minutos.

### Dois bugs que a medição pegou

1. **O oráculo se contradizia com o validador.** Dizia "sem solução" para 72 de 300 puzzles que
   o validador confirmava resolvíveis. Causa: ao estourar uma cota ele parava de contar no meio,
   mas o desfazer revertia a linha inteira. Contadores ficavam negativos e ramos válidos eram
   podados.
2. **Traçados de região sorteados são únicos ~1 vez em 300.** Sortear e testar não gera puzzle.
   Trocado por refinamento dirigido: pedir a segunda solução ao oráculo e mover uma célula dela
   para a região vizinha, o que a invalida por construção.

### Duas otimizações que eu tentei e MEDI como piores

Ambas revertidas, e viraram a regra W7 (nenhuma otimização entra sem número antes e depois):

- aumentar o orçamento de refinamento de 400 para 6.000 passos: 610 ms → 1.074 ms
- pontuar 6 movimentos candidatos e ficar com o melhor: 610 ms → 904 ms

### ⚠️ PERGUNTA ABERTA — o PROP-6-SB que eu propus está errado

Eu propus, e você aprovou, este substituto para Star Battle: *"nenhuma célula pode mudar de
região sem quebrar o puzzle"*. **A medição mostra que essa definição não se sustenta.**

`dart run tool/diagnose.dart`, sobre 48 puzzles em três tamanhos:

| Tamanho | Movimentos legais | Que mantêm a unicidade | Puzzles rígidos |
|---|---|---|---|
| 6x6 / 1 estrela | 26,5 | mediana 16 (62,6%) | 0 de 25 |
| 8x8 / 1 estrela | 44,5 | mediana 27 (63,6%) | 0 de 15 |
| 9x9 / 2 estrelas | 56,1 | mediana 42 (71,7%) | 0 de 8 |

Cerca de **dois terços** das mudanças de fronteira preservam a unicidade, e **nenhum** puzzle é
totalmente rígido. Ligar essa exigência no gerador faz ele desistir depois de 4.000 tentativas
num tabuleiro 6x6.

**Por que isso faz sentido:** uma célula no meio de uma região, longe de qualquer estrela, não
carrega informação nenhuma. Trocá-la de região não muda o raciocínio. Isso não é "gordura" do
puzzle, é uma propriedade do gênero — igualzinho ao que a pesquisa achou para Shikaku e Tents.

**O teste NÃO foi enfraquecido.** Está marcado como pulado, com o motivo e os números escritos
na própria mensagem, esperando sua decisão. Opções na conversa.

**O que de fato protege contra puzzle "frouxo" hoje** é o PROP-3 dos dois lados: o puzzle só
recebe o rótulo T4 se ele resolve com técnicas até T4 **e falha** com técnicas até T3. Ou seja,
a técnica difícil é obrigatória, não decorativa.
---

## 🚀 MARCO 1 — PUBLICADO

**Data:** 14/08/2026
**Endereço:** https://vitora-q.github.io/nodro/

O jogo está no ar. Rotas conferidas, todas respondendo 200:

| Rota | O que é |
|---|---|
| `/` | Home indexável (en) |
| `/pt/` | Home indexável (pt) |
| `/star-battle/` | Regras completas |
| `/star-battle/techniques/` | Índice das 9 técnicas |
| `/star-battle/techniques/<nome>/` | Uma página por técnica, com diagrama SVG |
| `/play/` | O jogo |
| `/sitemap.xml`, `/robots.txt` | Para o Google |

**24 páginas HTML escritas à mão**, em português e inglês, com hreflang. Os 9 diagramas são
gerados pelo solver de verdade — não podem divergir do jogo.

### O que foi resolvido nesta rodada

**O 404.** O workflow rodava, mas falhava no passo que configura o GitHub Pages, porque o Pages
não estava ligado nas configurações do repositório. Passei a usar a opção que **liga o Pages
pela API**, então não sobrou nenhum clique manual.

**O bug do diário "0 segundos".** Ao refazer o desafio do dia você entra em modo prática, onde o
cronômetro não roda de propósito. Eu mostrava esse zero como se fosse um tempo — parecia que
você tinha resolvido instantaneamente. Agora a tela diz que foi prática e não oferece
compartilhar nem próximo puzzle.

**Um segundo bug que o teste novo achou sozinho:** a tela de conclusão estourava 6,5 pixels em
tela baixa e pintava as listras de erro por cima dos próprios botões.

**APK de release gerado:** 46,2 MB, assinado com chave de debug — serve para instalar e testar,
não para a Play Store (isso precisa de chave de publicação, e é da Fase 6).

### Números

- 101 testes passando, 1 pulado (o lote noturno)
- `dart analyze` sem nenhum problema
- Banco de 4.500 puzzles verificados
- O workflow roda `analyze` + suíte inteira **antes** de publicar
---

## 🎨 O ícone

Antes de desenhar qualquer coisa, mandei fazer um levantamento do que realmente funciona em
loja de aplicativo. A parte mais útil não veio de artigo de marketing: **306 ícones de jogos de
lógica do Google Play foram medidos um a um** (cor dominante, brilho, saturação, quantidade de
detalhe). O resultado decidiu o desenho.

### O que a medição mostrou

| Fatia da categoria | Quanto |
|---|---|
| Ícones claros | 36% |
| Ícones cheios de detalhe | 81% |
| **Claros E limpos ao mesmo tempo** | **4%** |
| Azul + ciano juntos | 19% |

Ou seja: **fundo claro não é a vaga vazia — a vaga vazia é ser CALMO.** Três de cada quatro
ícones claros da categoria são claros e poluídos. Papel bege quente não é usado por ninguém.

### O desenho

Uma estrela de tinta e **uma linha de região**. Nada mais.

A estrela sozinha seria um erro: é o símbolo genérico de avaliação, e a Play Store desenha
estrelinhas de nota do lado do seu ícone na mesma tela. A linha de região é a fuga — ela diz que
a estrela mora dentro de uma região irregular, que é a regra do Star Battle e o que nenhuma
outra estrela significa. Os quatro concorrentes de Star Battle desenham a grade inteira colorida;
isso vira borrão em miniatura e vira cópia em qualquer tamanho.

A estrela é **de propósito mais gorda** que o normal (raio interno na metade do externo, contra
os 0,38 habituais). Duas razões: parece letra impressa em vez de estrelinha de nota, e foi a
única proporção cujas cinco pontas continuaram separadas a 16 pixels.

### O detalhe some conforme a tela encolhe

Um desenho só não serve para 512 e para 16 pixels. Um ícone de 16 px tem **256 pixels no total**
e nada fino sobrevive: um traço de 30 px vira 0,9 px e some. Então a linha de região existe no
ícone grande e **o favicon a descarta e cresce a estrela** para segurar sozinho.

No Android o mesmo problema apareceu de outro jeito: com a estrela centralizada, a máscara
redonda do Pixel cortava a região fora e sobrava só a estrela. Empurrei a estrela para cima e
para a direita — dentro do limite que a plataforma garante — e a região passou a caber dentro do
círculo. Isso eu vi renderizando, não deduzindo.

### A fraqueza, dita na cara

Papel contra branco puro dá 1,07:1 — a borda do quadrado some no fundo branco da loja. É real.
Mas a marca em si fica em 16,6:1, então continua perfeitamente legível, e a Play desenha uma
sombra própria que devolve a borda justamente ali. A alternativa (fundo escuro) mede **1,10:1
contra a aba escura do Chrome** — sumiria no navegador, que é a superfície principal de um jogo
que estreia na web. Papel ganha.

### O que foi entregue

Todos os arquivos saem de um único lugar (`tool/icon_spec.dart`) — não existe PNG editado à mão
no repositório:

- Ícone da Play (512), ícones PWA normais e mascaráveis (192 e 512), apple-touch (180)
- Favicon SVG + ICO com 16, 32 e 48 — **o de 16 px é desenhado no tamanho, não reduzido**
- Android: ícone adaptativo com camadas separadas + camada monocromática (tema do Android 13+)
  e os 5 tamanhos antigos
- Cartão social 1200×630 com a marca NODRO

**26 testes novos** medem os arquivos publicados de verdade: zona segura das máscaras, opacidade,
massa de tinta, contraste, e se o favicon de 16 px ainda tem cara de estrela.

Uma observação honesta sobre esses testes: as verificações de *estrutura* que escrevi primeiro
(a linha mais larga fica acima do centro, as pernas se separam embaixo) **passavam até para uma
estrela de 3 pixels**. Eram necessárias, não suficientes — um teste que não podia falhar. Medi
cinco variantes e troquei pela medida que de fato separa as boas das ruins: a quantidade de
tinta. A proporção clássica de estrela é reprovada por ela, que é exatamente o ponto.

Para ver o ícone em todos os contextos: `store/icon-preview.html`.
