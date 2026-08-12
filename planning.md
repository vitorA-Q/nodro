# DEDUCE — Planejamento (Fase 0)

Documento escrito em português porque é para você ler e conferir. Identificadores de
código, IDs de técnica e nomes de classe ficam em inglês, como manda a regra do projeto.

**Status:** Fase -1 (setup) concluída. Fase 0 em andamento. Nenhuma linha de código de
produção escrita.

---

## (a) A missão nas minhas palavras

Você quer construir um app de puzzles de lógica — daquela família japonesa (Nikoli) onde
você preenche uma grade seguindo regras e a graça está em deduzir, não em adivinhar.
Star Battle, Slitherlink, Shikaku, Tents & Trees.

Mas o app em si não é o produto. O produto são três garantias que quase nenhum
concorrente consegue dar:

**Primeira: todo puzzle tem exatamente uma resposta, e a gente PROVA isso.** Não é o
gerador dizendo "acho que tá certo". É um segundo programa, independente e burro de
propósito, que testa todas as possibilidades e conta quantas soluções existem. Se contar
duas, o puzzle é jogado fora antes de você ver. Esse segundo programa é lento — e tudo
bem, porque ele roda na sua máquina antes do lançamento, não no celular do jogador.

**Segunda: a dificuldade é honesta.** Hoje a maioria dos apps chama de "difícil" o puzzle
com menos números na tela, ou o que demora mais pra um computador resolver. Isso é
mentira: um puzzle com poucas pistas pode ser trivial e um com muitas pode ser cruel. Aqui
a dificuldade é *qual raciocínio o puzzle obriga você a fazer*. A gente escreve um
programa que pensa como humano — ele conhece uma lista de técnicas nomeadas, ordenadas da
mais óbvia para a mais sofisticada, e resolve o puzzle usando só elas, sem nunca chutar.
A dificuldade do puzzle é a técnica mais avançada que ele foi obrigado a usar. Se um
puzzle sai "difícil", é porque ele *exige* um raciocínio difícil, ponto.

**Terceira: as dicas ensinam.** Quando o jogador trava e pede ajuda, o app não entrega a
resposta. Ele roda aquele mesmo solucionador humano, acha o próximo passo mais simples que
ainda dá pra fazer, e diz: *"olha essas três células destacadas — como esta região só cabe
nesta linha, nenhuma outra célula desta linha pode ter estrela"*. Nome da técnica, células
destacadas, e o porquê. O jogador termina o app sabendo mais do que quando começou.

**Por que isso importa comercialmente, na minha leitura do que você escreveu:** existir na
loja não vale nada mais. Qualquer pessoa faz um app de Slitherlink num fim de semana com
IA. O que ela não faz é o oráculo de verificação, porque ela nem sabe que precisa dele. O
app dela sai com puzzles impossíveis ou com duas respostas, leva duas estrelas, e morre.
Sua defesa não é o design nem a velocidade de lançar — é o arnês de testes. É a parte que
ninguém copia porque ninguém vê.

**Consequência prática que eu vou respeitar:** a ordem é motor primeiro, tela depois.
Nenhum pixel antes dos testes passarem. E web antes da loja, porque a web te dá jogadores
reais em duas semanas enquanto a Play Store te faz esperar dois meses com 12 testadores.

*Se alguma coisa acima estiver errada, me corrija agora — é justamente para isso que esta
seção existe.*

---

## (b) Técnicas humanas por tipo de puzzle

Esta é a seção que determina se as promessas P2 (dificuldade honesta) e P3 (dicas que
ensinam) funcionam ou não. Cada técnica levantada tem: um identificador, um tier de 1 a 7,
uma descrição, e — o mais importante — **uma justificativa de por que ela nunca pode apagar
uma célula que faz parte da resposta certa**. Sem essa justificativa a técnica não entra
(regra X3).

O catálogo completo de cada tipo, com todos os detalhes de implementação, está em
`docs/research/`. Aqui vai o resumo.

---

### Star Battle — 25 técnicas em 6 tiers ✅ pesquisa concluída

Documento completo: `docs/research/star_battle_techniques.md`

Três ideias sustentam praticamente tudo em Star Battle:

- **Capacidade 2x2** — quatro células num quadrado 2x2 se tocam todas entre si, então esse
  quadrado nunca tem mais de uma estrela. Isso transforma "quanto espaço sobrou" num limite
  numérico rígido.
- **Contagem de cotas** — toda linha, coluna e região tem exatamente `k` estrelas. Sempre
  que um conjunto de regiões está contido num conjunto de linhas, sai uma igualdade.
- **Confinamento** — quando as possibilidades de uma região se espremem dentro de uma
  linha, as duas passam a disputar a mesma cota.

| Tier | Quantas | Exemplos |
|---|---|---|
| 1 — imediato | 4 | apagar vizinhas de uma estrela; região já completa; última célula |
| 2 — local | 6 | região confinada numa linha; vizinhos comuns de duas candidatas |
| 3 — contagem | 5 | ladrilhar região com blocos 2x2; contagem de faixas |
| 4 — conjuntos | 4 | N regiões dentro de N linhas; "o aperto" (squeeze) |
| 5 — avançado | 4 | enumerar todos os pares válidos; formas pressionadas; fish |
| 6 — cadeias | 2 | contagens "com barbatana"; cadeias de implicação |

**Duas famílias foram deliberadamente excluídas**, e vale você saber por quê:

1. **Look-ahead profundo** ("e se eu puser uma estrela aqui e seguir 10 passos?"). Isso é
   busca, não dedução. Um puzzle que só se resolve assim é rejeitado na geração — ele está
   fora do que a gente promete que é resolvível por raciocínio.
2. **Argumentos de unicidade** ("essa jogada não pode ser, senão o puzzle teria duas
   respostas"). Essa é logicamente **inválida**: ela não usa as regras do puzzle, usa a
   promessa de que o puzzle é único. Além de ser um raciocínio circular no nosso caso, ela
   destruiria P3 — uma dica que diz "confie que é único" não ensina nada.

**Achado que muda a Fase 1:** a técnica "o aperto" (`bandSqueeze`) tem folga exatamente 1
num tabuleiro **10x10 com 2 estrelas** — que é justamente o tamanho que o briefing usa como
meta de performance. É o caso clássico e mais poderoso da técnica. Boa notícia para a
escolha do tamanho padrão.

**Alerta de armadilha registrado:** duas técnicas (`twoByTwoTiling` e `setDifferentials`)
viram **inválidas** se implementadas com um detalhe errado — blocos que se sobrepõem no
primeiro caso, células contadas duas vezes no segundo. Ambas já estão marcadas no documento
de pesquisa com aviso, e ambas serão testadas contra a solução conhecida por PROP-4.

---

### Slitherlink — 30 técnicas em 6 tiers ✅ pesquisa concluída

Documento completo: `docs/research/slitherlink_techniques.md`

| Tier | Quantas | Exemplos |
|---|---|---|
| 1 — aritmética de uma pista só | 8 | regra do zero; 3 no canto; 1 no canto; 3 ao lado de 0 |
| 2 — duas pistas conversando | 6 | dois 3 vizinhos; dois 3 na diagonal; dois 1 na diagonal |
| 3 — regras do ponto | 4 | ponto já tem duas linhas; uma linha entra, outra tem que sair |
| 4 — conectividade | 3 | não fechar um laço pequeno cedo demais; ponte forçada |
| 5 — dentro/fora | 5 | colorir células como dentro ou fora do laço |
| 6 — cadeias longas | 4 | corrente diagonal de 2; 3…2…2…3 na diagonal |

**A pergunta arquitetural que o briefing mandou responder ANTES de implementar, respondida:**

O briefing pedia para tratar a conectividade do laço explicitamente com union-find e
documentar a abordagem. A pesquisa achou a resposta precisa, e ela é mais sutil do que
parece:

- **Colorir dentro/fora sozinho NÃO garante um laço único.** Existem colorações
  perfeitamente consistentes — todo ponto com o número certo de linhas, tudo válido
  localmente — que desenham **dois laços separados**. O contraexemplo é simples: dois
  retângulos, um dentro do outro. Fora = fora, o anel entre eles = dentro, o miolo = fora.
  Está tudo consistente e são dois laços.
- **Union-find sozinho também não basta**, porque ele só enxerga linhas já desenhadas. Ele
  é cego para os "X" (arestas marcadas como ausentes), e é exatamente por eles que a
  informação viaja longe no Slitherlink.
- **Conclusão: são necessárias as duas estruturas ao mesmo tempo.** Uma união-e-busca sobre
  os pontos para detectar laço prematuro, e uma união-e-busca *com paridade* sobre as
  células para a coloração. Elas veem informações completamente diferentes.
- **E no fim, sempre uma verificação independente:** percorrer o laço e conferir que ele
  volta ao início depois de exatamente o número de arestas que existem. É barato e pega o
  erro de contagem que a regra de laço prematuro erra com facilidade.

**Armadilha registrada:** a regra mais famosa do Slitherlink — "dois 3 lado a lado, a
aresta do meio é linha" — **não é uma dedução puramente local**. Existe um caso legal em
que ela não vale. A conclusão só é válida porque esse caso teria que ser o puzzle inteiro.
Vou implementá-la com a checagem que fecha o buraco.

---

### Shikaku — 19 técnicas em 7 tiers ✅ pesquisa concluída

Documento completo: `docs/research/shikaku_techniques.md`

| Tier | Quantas | Exemplos |
|---|---|---|
| 1 | 2 | pista 1; sobrou um único encaixe possível |
| 2 | 5 | número primo vira uma tira 1xN; retângulo não pode conter outro número |
| 3 | 2 | só uma pista consegue alcançar esta célula |
| 4 | 3 | células presentes em todos os encaixes possíveis de uma pista |
| 5 | 2 | dois números perto demais disputam o mesmo corredor |
| 6 | 4 | contagem de área numa região fechada; paridade tipo tabuleiro de xadrez |
| 7 | 1 | "se este número tomasse esta célula, aquela ali ficaria órfã" |

A literatura de Shikaku é genuinamente mais pobre que a dos outros. Duas fontes que eu
esperava usar simplesmente não existem (a Conceptis nunca publicou nada sobre Shikaku). As
melhores fontes acabaram sendo **código, não texto** — o gerador do Simon Tatham, que é o
melhor documentado que existe. Sete das 19 técnicas eu derivei da estrutura do problema, e
estão marcadas como tal no documento.

**Achado que muda a geração:** dificuldade em Shikaku vem de **retângulos maiores e menos
numerosos**, não de mais pistas. E a **posição** do número dentro do retângulo determina
tanto a unicidade quanto a dificuldade — a mesma divisão da grade pode ser única ou ambígua
dependendo só de onde o número é colocado. É lá que o gerador deve gastar o orçamento.

**Padrões fatais catalogados** (as configurações que produzem duas respostas e matam apps
concorrentes): o menor deles são dois "2" na diagonal de um bloco 2x2 isolado — sempre
ambíguo. A família geral está descrita no documento e vai virar um filtro no gerador.

---

### Tents & Trees — 22 técnicas em 7 tiers ✅ pesquisa concluída

Documento completo: `docs/research/tents_techniques.md`

| Tier | Quantas | Exemplos |
|---|---|---|
| 1 | 3 | linha com número 0; linha já completa; célula sem árvore vizinha |
| 2 | 5 | árvore com um único lugar possível; grama em volta de toda barraca |
| 3 | 4 | vagas restantes = barracas restantes; capacidade de um bloco 2x2 |
| 4 | 3 | **teorema do casamento de Hall** |
| 5 | 3 | duas árvores que só alcançam duas células; conversa entre contagem e casamento |
| 6 | 3 | enumerar todas as arrumações de uma linha; filtro por emparelhamento máximo |
| 7 | 1 | relaxação global |

**O coração do Tents é um teorema, e ele dá uma dica excelente.** O puzzle é, no fundo, um
problema de casamento: cada árvore precisa de uma barraca só dela. O teorema de Hall diz
que isso é possível se e só se, para todo grupo de árvores, o número de células que elas
conseguem alcançar juntas é pelo menos igual ao número de árvores. A dica que sai disso é
das mais bonitas do app inteiro: *"estas três árvores, juntas, só alcançam estas três
células — então as três células são barracas, e nenhuma outra árvore pode usá-las"*.

**Decisão técnica com efeito visível:** existe um algoritmo (Hopcroft–Karp) que resolve o
casamento inteiro em microssegundos e que é **mais forte que todas as técnicas de tier 4 e
5 juntas**. A recomendação é usar ele como motor, mas **extrair dele a explicação em
formato humano** — porque "nenhum emparelhamento máximo usa esta célula" não ensina nada,
enquanto "estas três árvores só alcançam estas três células" ensina. Isso dá força de tier
6 com explicação de tier 4. É exatamente o que P3 precisa.

**Achado que melhora o PROP-3:** o Simon Tatham usa uma definição de dificuldade melhor que
a que estava no briefing. Em vez de "o tier mais alto que o solver usou", ele testa dos dois
lados: *o puzzle tem dificuldade d se o solver resolve com as técnicas até d **e falha** com
as técnicas até d−1*. É mais rigoroso, porque pega o caso em que uma técnica avançada foi
usada mas não era necessária. Vou adotar essa forma.

**Armadilha registrada, e é séria:** a técnica de enumerar arrumações de uma linha (tier 6)
é a mais perigosa do catálogo inteiro. Se qualquer filtro usado durante a enumeração for
um "quase certo" em vez de uma certeza, ela apaga silenciosamente a arrumação verdadeira e
depois marca com confiança total uma célula errada. Está marcada com aviso duplo no
documento.

---

## (c) Estratégia de geração por tipo

O princípio geral é o mesmo nos quatro: **solução-primeiro**. Nunca "sorteia pistas e torce
para dar certo". Sortear pistas produz, na esmagadora maioria das vezes, puzzles com zero
soluções ou com dezenas — e o custo de descobrir isso é justamente rodar o solver caro.
Partindo de uma solução válida construída à mão, o puzzle *já nasce com pelo menos uma
resposta*, e o único trabalho que sobra é garantir que não haja uma segunda.

Isso muda o problema de "achar agulha no palheiro" para "aparar o excesso", que é
mensuravelmente mais rápido e, mais importante, tem tempo de execução previsível.

### Star Battle — solução-primeiro, com perturbação de fronteiras

Aqui existe uma particularidade que define tudo: **em Star Battle a pista É o desenho das
regiões**. Não existem números para remover. Então o roteiro é:

1. Sortear uma configuração válida de estrelas (k por linha, k por coluna, nenhuma
   encostando em outra nem na diagonal). Isso é feito por busca em profundidade com
   propagação, não por tentativa e erro cega.
2. Dividir a grade em N regiões conectadas, cada uma contendo exatamente k estrelas.
   Crescimento de regiões a partir de sementes ancoradas nas estrelas.
3. Rodar o `ExhaustiveSolver` e contar soluções, com saída antecipada na segunda.
4. Se der mais de uma: mover uma célula de fronteira de uma região para a vizinha,
   preservando conectividade e a contagem de estrelas, e tentar de novo.
5. Quando for única: rodar o `HumanSolver`. Se ele precisar chutar, o puzzle é rejeitado
   ou perturbado. Se resolver, a dificuldade é o tier máximo que ele usou.

**Vantagem estrutural importante:** como a configuração inicial de estrelas *é* uma
solução, o caso "zero soluções" nunca acontece. O gerador só pode errar para o lado do
excesso, que é o lado barato de detectar.

### Slitherlink — solução-primeiro, com remoção gulosa de pistas

1. Gerar um laço fechado único. A forma robusta não é desenhar o laço, é **colorir
   células**: escolher um conjunto de células que será o "dentro" do laço, exigindo que
   ele seja conectado, sem buracos, e com o complemento também conectado. A fronteira
   desse conjunto é automaticamente um laço fechado. Um cuidado específico: duas células
   "de dentro" que se tocam só pela diagonal criam um vértice onde o laço se cruzaria —
   essa configuração precisa ser proibida explicitamente.
2. Calcular o número de todas as células (quantas das 4 bordas dela fazem parte do laço).
   Nesse ponto o puzzle está 100% preenchido e é trivialmente único.
3. **Remover pistas em ordem aleatória**, uma a uma, testando com o `ExhaustiveSolver`
   depois de cada remoção. Se a unicidade quebrou, a pista volta. Quando nenhuma pista
   mais pode sair, o conjunto restante é minimal — **PROP-6 sai de graça, por construção**.
4. `HumanSolver` determina a dificuldade.

### Shikaku — solução-primeiro, com escolha de posição do número

1. Particionar a grade inteira em retângulos, por preenchimento guloso aleatório com
   retrocesso quando dá beco sem saída.
2. Enviesar contra padrões que geram ambiguidade: muitos 1x1, e principalmente blocos
   onde um 2x3 e um 3x2 são intercambiáveis.
3. Escolher, dentro de cada retângulo, **em qual célula o número aparece**. Essa é a única
   liberdade que o Shikaku oferece, e ela afeta tanto a unicidade quanto a dificuldade.
4. `ExhaustiveSolver`: se não for único, primeiro tenta mexer nas posições dos números
   (barato); só re-sorteia a partição inteira se isso não bastar.
5. `HumanSolver` determina a dificuldade.

### Tents & Trees — solução-primeiro, emparelhamento por construção

1. Espalhar as barracas: um conjunto de células que não se tocam, nem na diagonal.
2. Pendurar uma árvore em uma das 4 vizinhas ortogonais de cada barraca, garantindo que
   cada árvore serve exatamente uma barraca. O emparelhamento perfeito existe **por
   construção**, o que elimina a categoria inteira de bug "puzzle impossível".
3. Calcular os números das linhas e colunas.
4. `ExhaustiveSolver` para unicidade, `HumanSolver` para dificuldade.

---

## (d) Como garantir PROP-6 (minimalidade) em cada tipo

PROP-6 diz "remover qualquer pista adicional quebra a unicidade". Isso faz sentido pleno
em dois dos quatro tipos e **não faz sentido literal nos outros dois** — e o briefing pede
explicitamente que eu declare onde não se aplica e por quê. Segue a declaração.

> ⚠️ **Esta seção foi corrigida depois da pesquisa.** Duas coisas que eu tinha escrito
> antes estavam erradas, e a pesquisa provou que estavam. As correções estão marcadas.

| Tipo | PROP-6 se aplica? | Como é garantida / o que a substitui |
|---|---|---|
| Slitherlink | **Sim, plenamente** | Por construção: o gerador só para de remover quando nenhuma remoção adicional preserva a unicidade. O teste apenas reconfirma. |
| Tents & Trees | **Sim, mas nunca no formato literal** ⚠️ corrigido | Dois números são *provadamente* redundantes em todo Tents. Aplicar com a correção descrita abaixo. |
| Star Battle | **Não se aplica literalmente** | Não existem pistas discretas: a pista é a partição em regiões, que é uma peça só. Substituição proposta abaixo. |
| Shikaku | **Não se aplica, e minha primeira substituição era inútil** ⚠️ corrigido | Substituição nova proposta abaixo. |

### Star Battle — por que não se aplica, e o que colocar no lugar

Não há o que remover. Você não pode "tirar uma pista" de um Star Battle; o desenho das
regiões é indivisível. Tirar uma linha de fronteira funde duas regiões e muda as regras do
puzzle (passa a ter N-1 regiões), não o enfraquece.

**Substituição — PROP-6-SB (minimalidade de fronteira):** para toda fronteira entre duas
regiões vizinhas, mover qualquer célula de um lado para o outro ou (a) quebra a
conectividade da região, ou (b) muda a contagem de estrelas da região, ou (c) destrói a
unicidade. Ou seja: o desenho é *localmente rígido* — não existe variação de uma célula que
produza outro puzzle válido e igualmente único. Isso é testável, é rigoroso e captura o
espírito de "sem gordura".

### Shikaku — ⚠️ CORREÇÃO: minha primeira proposta era inútil

A razão de PROP-6 não se aplicar continua valendo, e é aritmética. Cada retângulo precisa
conter exatamente um número, e a soma de todos os números tem que dar exatamente a área da
grade. Se você remove um número, um retângulo fica órfão e a soma não fecha: o puzzle não
passa a ter *duas* soluções, ele passa a ter **zero**.

**Onde eu errei.** Eu tinha proposto "PROP-6-SK: para toda pista, o puzzle sem ela tem zero
soluções" e te disse que era um teste real e forte. **Não é.** Aquilo é verdade em *todo*
Shikaku que já foi impresso na história, inclusive nos piores. Um teste que aprova 100% dos
candidatos não distingue nada — ele só gastaria tempo de máquina fingindo que protege algo.
Isso é exatamente o tipo de teste decorativo que o seu briefing manda evitar.

**Substituição nova — PROP-6-SK (minimalidade de valor).** Em vez de apagar a pista inteira,
troca-se o **número** dela por uma interrogação, mantendo a marca da célula. Isso é uma
variante publicada de verdade do Shikaku, não invenção minha. A estrutura sobrevive: o
número de retângulos continua o mesmo, e o valor apagado é recuperável pela soma. Então
perguntar *"continua tendo uma resposta só?"* passa a ser uma pergunta com sentido. Se sim,
aquele número era informação redundante e o puzzle **não** é minimal.

Esse é o análogo estrutural direto da minimalidade do Sudoku, e é o que eu recomendo.
Existem duas alternativas (fundir dois retângulos vizinhos num só, ou medir quantas posições
o número poderia ocupar dentro do próprio retângulo sem quebrar a unicidade). As três estão
descritas em `docs/research/shikaku_techniques.md`. Isso virou a pergunta 6.

### Tents & Trees — ⚠️ CORREÇÃO: PROP-6 literal é matematicamente impossível aqui

Eu tinha escrito que PROP-6 "se aplica plenamente aos números". **Está errado, e dá para
provar em duas linhas.**

O número de barracas é igual ao número de árvores, e as árvores estão visíveis no tabuleiro.
Logo:

> soma de todos os números das linhas = soma de todos os números das colunas = número de árvores

Isso quer dizer que **qualquer número de linha é recuperável a partir dos outros** — basta
subtrair. O mesmo vale para qualquer número de coluna. E dá para apagar um de cada eixo ao
mesmo tempo. Portanto **todo Tents tem pelo menos duas pistas provadamente redundantes**, e
a condição literal de PROP-6 nunca é satisfeita por nenhum Tents completo.

**Por que isso importa na prática:** se eu tivesse implementado o teste ingênuo — apaga cada
pista, resolve, confere unicidade — **todos os 1.000 puzzles teriam sido reprovados**, e eu
teria passado horas caçando um bug no gerador que não existe. Este é o tipo exato de
armadilha que a Fase 0 existe para pegar.

**Correção — PROP-6-T (minimalidade módulo as duas identidades):** designa-se um número de
linha e um de coluna como "derivados por convenção", tiram-se eles do teste, e exige-se que
nenhuma das pistas restantes possa sair sem quebrar a unicidade.

As árvores continuam não sendo pistas removíveis: tirar uma árvore não enfraquece o puzzle,
**troca o puzzle** — o número de barracas muda e todos os números de linha e coluna que
aquela barraca contava ficam errados. Árvore é tabuleiro, não é pista.

**Um segundo achado sobre Tents, que é decisão de produto:** existe um caso em que as
posições das barracas são únicas mas o *emparelhamento* árvore↔barraca não é — duas
atribuições diferentes funcionam igual. A recomendação da literatura é: **ao conferir a
jogada do usuário, aceitar se existe pelo menos um emparelhamento válido; ao gerar, exigir
que exista exatamente um**. Isso é generoso com o jogador e rigoroso com o gerador. Virou a
pergunta 7.

---

## (e) Riscos técnicos e mitigação

Riscos ordenados por quanto eles doem se ignorados.

### E1 — Isolates não existem na web. Conflito direto entre R2 e R8. ⚠️

**Este é o risco número um e ele é factual, não uma suspeita.** A documentação oficial do
Flutter diz literalmente que plataformas web do Dart, incluindo Flutter web, não suportam
isolates. `Isolate.spawn()` e `Isolate.run()` simplesmente não funcionam. O `compute()`
compila, mas **roda na thread principal na web** — ou seja, ele não trava o build, ele
trava a tela.

Como a estratégia é lançar na web *primeiro*, isso significa que a regra R2 ("tudo em
Isolate, o app nunca trava") não é implementável na plataforma principal do lançamento sem
uma decisão explícita sua. Está na pergunta 1.

**Mitigações possíveis, em ordem de custo:** (i) fatiar o trabalho em pedaços pequenos e
devolver o controle para a tela entre eles — funciona nas duas plataformas, custa
reescrever os solvers em estilo incremental; (ii) usar Web Workers de verdade na web via
uma camada de abstração, mantendo Isolate no Android; (iii) pré-gerar tudo e não gerar
nada ao vivo na web.

### E2 — O `Random` do Dart não é reproduzível entre plataformas

O briefing exige "sementes fixas e reprodutíveis" (C2) e um desafio diário determinístico
onde todo jogador recebe o mesmo puzzle sem servidor (Fase 4). O `Random(seed)` da
biblioteca padrão do Dart **não garante a mesma sequência** entre a máquina virtual e o
JavaScript compilado. Se eu usar ele, o desafio diário sai *diferente* no celular e no
navegador, e os testes de propriedade deixam de ser reproduzíveis entre ambientes.

**Mitigação (vou fazer isso desde a primeira linha):** implementar um gerador
pseudoaleatório próprio em Dart puro, com aritmética explicitamente de 32 bits, segura sob
compilação para JavaScript. É cerca de 30 linhas, sem dependência externa, e resolve os
dois problemas de uma vez.

### E3 — O orçamento de 300ms para gerar um 10x10 com 2 estrelas

O laço "gera → verifica unicidade → perturba" pode precisar de muitas iterações. Mitigação:
representar o tabuleiro como máscaras de bits em vez de listas de booleanos, e fazer o
solver exaustivo trabalhar de forma incremental sobre a perturbação em vez de recomeçar do
zero. Se ainda assim não couber, a saída honesta é subir o orçamento e te avisar, nunca
afrouxar a verificação.

### E4 — O solver exaustivo de Slitherlink pode explodir

Slitherlink é NP-completo e a restrição de laço único é global. Uma busca ingênua sobre as
arestas não termina em tempo útil em grades médias. Mitigação: busca sobre arestas com
propagação agressiva das regras locais a cada passo, mais union-find para cortar
imediatamente qualquer ramo que feche um laço prematuro. Isso será documentado antes de
implementar, como o briefing exige.

### E5 — Determinismo do rótulo de dificuldade (PROP-3)

Se o `HumanSolver` aplicar as técnicas em ordem variável, o mesmo puzzle pode receber
rótulos diferentes em execuções diferentes, e PROP-3 quebra de forma intermitente — o pior
tipo de bug. Mitigação estrutural: esgotar completamente cada tier antes de subir para o
próximo, varrer células sempre em ordem fixa, e **nunca iterar sobre estruturas com ordem
indefinida** dentro do solver.

### E6 — O gargalo real do gerador vai ser o `HumanSolver`, não a unicidade

Um puzzle pode ser perfeitamente único e ainda assim exigir chute, porque nossa lista de
técnicas não cobre o raciocínio necessário. Esses puzzles são rejeitados por PROP-2. Se a
lista de técnicas for curta, a taxa de rejeição explode e a geração fica lenta por um
motivo que parece de performance mas é de *cobertura*. É exatamente por isso que a seção
(b) precisa de 15-25 técnicas por tipo, não 8.

### E7 — Tempo total da suíte de testes

1.000 instâncias × 4 tipos × (gerar + resolver exaustivamente + resolver como humano) é
muito trabalho. Se a suíte levar 40 minutos, ninguém roda ela, e aí ela para de proteger.
Mitigação proposta na pergunta 4.

### E8 — Peso inicial do Flutter Web contra a meta de 3 segundos

O runtime gráfico do Flutter para web é pesado. A meta de carregar em menos de 3 segundos
é atingível, mas exige decisões conscientes de renderizador e de carregamento. Isso será
medido na Fase 4 com número real, não com estimativa.

### E9 — O projeto está dentro do OneDrive, numa pasta com acento

A pasta é `OneDrive\Área de Trabalho\deduce`. Dois problemas conhecidos: o OneDrive
sincroniza e trava arquivos no meio de um build, causando erros que parecem aleatórios; e
o acento em "Área" já causou problemas com as ferramentas de build do Android em outros
projetos.

⚠️ **Isto deixou de ser hipótese na Fase 0.** Ao rodar os testes pela segunda vez, o
comando falhou com:

```
Flutter failed to delete a directory at "build\unit_test_assets".
The flutter tool cannot access the file or directory.
```

Apaguei a pasta `build` e o teste passou normalmente na sequência. Ou seja: o build
funcionou, quebrou sozinho, e voltou a funcionar sem nenhuma mudança no código. Esse é
exatamente o padrão de falha que custa uma tarde quando acontece no meio de algo
complicado. Aconteceu duas vezes em duas rodadas de teste. Vai piorar quando a suíte tiver
1.000 puzzles por tipo em vez de um teste. Pergunta 2.

### E10 — Qualidade das traduções das dicas

As dicas explicam raciocínio lógico. Tradução automática ruim transforma "esta região só
cabe nesta linha" em algo incompreensível, e aí a proposta P3 (dicas que ensinam) morre no
idioma traduzido. Mitigação: manter o texto das dicas curto e estruturado, com variáveis
interpoladas, e marcar os 8 idiomas como "precisa de revisão humana" antes de considerar a
Fase 5 pronta.

---

## (f) PERGUNTAS ABERTAS

Ordenadas por quanto custa retrabalhar se a resposta for errada. As cinco primeiras valem
muito mais que as outras doze juntas. Onde eu tenho recomendação, ela está marcada.

---

### 1. Como o app não vai travar na web, já que Isolate não existe lá? 🔴 custo altíssimo

**O problema:** gerar e resolver puzzles é trabalho pesado. No Android dá pra jogar esse
trabalho numa "linha de produção paralela" (Isolate) e a tela continua lisa. Na web isso
não existe — o navegador roda tudo numa coisa só. Se eu gerar um puzzle na web do jeito
óbvio, a página congela por alguns segundos. E a web é o seu lançamento principal.

Escolher errado aqui significa reescrever os quatro motores.

| Opção | O que muda para o jogador | Custo |
|---|---|---|
| **A. Motor "em fatias"** ⭐ recomendo | O motor trabalha em pedacinhos e devolve o controle para a tela entre eles. O jogador vê uma barrinha de progresso que anda, nunca uma tela congelada. Funciona igual na web e no Android. | Escreve-se uma vez, mas o código dos solvers fica ~20% mais complicado. |
| **B. Web Worker na web, Isolate no Android** | Idêntico ao A para o jogador, e um pouco mais rápido na web. | Duas implementações para manter, e a parte de Web Worker no Flutter é território pouco documentado. Risco real de perder dias. |
| **C. Só puzzles pré-fabricados na web** | Nunca trava, mas o jogador esbarra num "acabaram os puzzles" quando termina o pacote. Sem modo infinito na web. | Mais barato agora, mas te tranca. |

**Por que eu recomendo A:** ela honra as suas duas regras (nunca travar; tudo que roda no
Android roda na web) com uma implementação só, e o custo é pago uma vez, no começo, quando
é barato.

---

### 2. Posso mover o projeto para fora do OneDrive? 🔴 custo alto, conserto barato

**O problema:** a pasta está em `OneDrive\Área de Trabalho\deduce`. O OneDrive fica
sincronizando arquivos enquanto o build acontece, e isso gera erros esquisitos e
intermitentes — o tipo de erro que custa uma tarde inteira porque não parece ter causa. O
acento em "Área" também já quebrou ferramentas de build de Android em outros projetos.

| Opção | Consequência |
|---|---|
| **A. Mover para `C:\dev\deduce`** ⭐ recomendo | Some a classe inteira de problema. Você continua com o projeto no computador, só num caminho mais limpo. Leva 30 segundos e eu faço. |
| **B. Deixar onde está** | Funciona hoje. Quando quebrar, vai quebrar de um jeito confuso e vou gastar tempo achando que é bug meu. |

Se você quer o backup automático do OneDrive, dá para ter os dois: o código fica no
GitHub, que é backup melhor que OneDrive para código.

---

### 3. Quais puzzles entram no primeiro lançamento web? 🔴 custo alto

Isso define quantas semanas até você ter jogador real.

| Opção | Consequência prática |
|---|---|
| **A. Só Star Battle** | Ao ar mais rápido. Uma landing page, uma palavra-chave. Você descobre se a ideia funciona antes de investir nas outras três. |
| **B. Star Battle + Slitherlink** ⭐ recomendo | Slitherlink tem muito mais gente procurando no Google que Star Battle, então ele é o que traz tráfego; Star Battle é o mais barato de construir, então ele valida o arcabouço. Duas landing pages já fazem o site parecer um site, não um experimento. |
| **C. Os quatro** | SEO bem mais forte e produto mais convincente, mas atrasa o lançamento em várias semanas. Se um dos motores der problema, tudo atrasa junto. |

---

### 4. Quanto tempo a suíte de testes pode levar? 🟠 custo médio-alto

**O problema:** 1.000 puzzles por tipo, cada um gerado e depois resolvido duas vezes (uma
pelo verificador lento, outra pelo solucionador humano). Isso pode levar bastante tempo.
Um teste que demora 40 minutos deixa de ser rodado, e um teste que ninguém roda não
protege nada — que seria perder exatamente o fosso competitivo.

| Opção | Consequência |
|---|---|
| **A. 1.000 sempre, em toda rodada** | Máxima segurança, mas se ficar lento eu vou evitar rodar e a proteção evapora na prática. |
| **B. 150 rápidos no dia a dia + 1.000 completos antes de cada entrega** ⭐ recomendo | O ciclo de trabalho fica rápido, e a garantia de 1.000 do briefing continua sendo cumprida — só que num momento definido, com a saída colada para você. As sementes são fixas, então os 150 são sempre os mesmos 150. |
| **C. 1.000 sempre, mas rodando em paralelo** | Bom meio-termo se a máquina aguentar. Posso medir e te dizer o número real antes de você decidir. |

Se você preferir, eu meço primeiro e só então você escolhe. Só não quero descobrir isso na
Fase 2 com quatro motores prontos.

---

### 5. Quantos níveis de dificuldade o jogador vê? 🟠 custo médio-alto

Internamente são 7 tiers de técnica. Mostrar "Tier 5" para o jogador não significa nada
para ele.

| Opção | Consequência |
|---|---|
| **A. 4 nomes: Fácil / Médio / Difícil / Extremo** ⭐ recomendo | É o que o jogador de puzzle espera. Agrupo os 7 tiers em 4 faixas. Simples e familiar. |
| **B. 7 níveis, um por tier** | Mais informativo para o entusiasta e casa perfeitamente com a "trilha de aprendizado" da Fase 5, mas assusta o jogador novo. |
| **C. 4 nomes + o nome da técnica em letra pequena** | O melhor dos dois, mas exige que os nomes de técnica traduzidos fiquem bons em 8 idiomas. |

Isso mexe na interface, no banco de puzzles e nas estatísticas. Trocar depois dá trabalho
em três lugares.

---

### 6. Você aprova as correções no contrato de testes? 🟠 custo médio

Esta é a única parte onde eu estou propondo **mudar o que você escreveu**, então preciso do
seu "ok" explícito. São quatro itens, e três deles vieram da pesquisa provar que a versão
literal não funcionaria.

**6a. Star Battle — PROP-6 não se aplica.** Não existem pistas discretas para remover; a
pista é o desenho das regiões, que é uma peça só. Substituto: *nenhuma célula pode trocar de
região sem quebrar o puzzle* (o desenho é localmente rígido).

**6b. Shikaku — PROP-6 não se aplica, e minha primeira ideia era inútil.** Eu tinha proposto
"tirar qualquer número deixa zero soluções" e te disse que era forte. Não é: isso é verdade
em todo Shikaku que já existiu, então aprovaria 100% dos puzzles e não protegeria nada.
Substituto novo: trocar o **número** por uma interrogação, mantendo a marca da célula, e
exigir que a resposta deixe de ser única. É uma variante publicada de verdade do Shikaku e é
o análogo direto da minimalidade do Sudoku.

**6c. Tents — PROP-6 literal é matematicamente impossível.** A soma dos números das linhas é
igual à soma das colunas é igual ao número de árvores, que estão à vista. Então dois números
são sempre dedutíveis a partir dos outros, em qualquer Tents. Se eu tivesse implementado o
teste ingênuo, **os 1.000 puzzles teriam sido reprovados** e eu teria caçado um bug que não
existe. Correção: excluir um número de linha e um de coluna do teste, e exigir minimalidade
de todo o resto.

**6d. PROP-3 — proposta de deixar o teste MAIS rigoroso, não menos.** O briefing define a
dificuldade como "o tier mais alto que o solver humano precisou usar". A literatura usa uma
definição melhor, testada dos dois lados: *o puzzle tem dificuldade d se o solver resolve
usando técnicas até d **e falha** usando técnicas até d−1*. A diferença prática: a versão do
briefing aceitaria um puzzle rotulado "difícil" onde a técnica difícil foi usada mas não era
necessária — o jogador acharia fácil e o rótulo seria mentira. A versão de dois lados pega
isso. É mais trabalho de máquina e mais honesto.

---

### 7. Tents: duas decisões pequenas com efeito visível 🟡 custo médio

**7a. Escondo os números redundantes?** O Tents clássico mostra o número de todas as linhas
e colunas.

| Opção | Consequência |
|---|---|
| **A. Mostrar todos (clássico)** ⭐ recomendo para o lançamento | O jogador reconhece o puzzle. Zero atrito. |
| **B. Esconder os redundantes** | Puzzle mais difícil e visualmente mais limpo, mas quem vem de outro app estranha. |
| **C. Mostrar todos, e "esconder redundantes" vira modo extra do Pro** | Diferencial de venda real, sem confundir quem chega. |

**7b. O que conta como "acertou"?** Existe um caso raro em que as barracas ficam nos lugares
certos mas dá para ligar árvore↔barraca de duas formas diferentes. Recomendo o que a
literatura faz: **na hora de conferir a jogada do jogador, aceitar se existe pelo menos uma
ligação válida** (generoso — ele acertou onde importa), **e na hora de gerar, exigir que só
exista uma** (rigoroso). Assim ninguém é punido por um detalhe que o puzzle não pedia.
Confirma?

---

### 8. Que tamanhos e quantas estrelas no Star Battle? 🟡 custo médio

O padrão do mercado é 8x8 com 1 estrela (iniciante), 9x9 ou 10x10 com 2 estrelas (o mais
comum de longe) e 14x14 com 3 estrelas (para entusiastas). Minha proposta é começar com
**10x10 com 2 estrelas** (é o que o briefing usa como meta de performance) e adicionar
8x8/1 estrela para o tutorial. Confirma?

---

### 9. Quantos puzzles vêm prontos dentro do app? 🟡 custo médio

Puzzles pré-fabricados carregam instantaneamente e nunca travam; puzzles gerados na hora
são infinitos mas custam processamento. Cada puzzle guardado ocupa pouquíssimo espaço, mas
mil deles engordam o download inicial da web — que tem meta de 3 segundos.

Proposta: cerca de 200 por tipo por dificuldade no pacote (jogo garantido por semanas), e
geração ao vivo para o modo infinito. Ok?

---

### 10. O que é grátis e o que é do Pro? 🟡 custo médio

O briefing diz que o Pro tem "dicas ilimitadas + sem anúncios + tipos extras de puzzle".
Preciso saber quais tipos são "extras":

| Opção | Consequência |
|---|---|
| **A. Todos os 4 grátis; o Pro vende dicas e ausência de anúncio** | Máximo alcance e melhor SEO (todas as landing pages jogáveis). Converte menos. |
| **B. 2 grátis, 2 no Pro** ⭐ tende a ser melhor | Você tem algo concreto para vender, e ainda tem duas portas de entrada abertas para o Google. |
| **C. Todos grátis na web, alguns pagos no app** | Confunde. Não recomendo. |

---

### 11. Quantas dicas o jogador grátis ganha? 🟡 custo baixo-médio

O briefing diz "dicas além da primeira gratuita" vêm de anúncio recompensado. Confirmando:
é **1 dica grátis por puzzle** (proposta) ou 1 por dia, ou 3 por puzzle? Isso mexe direto
na sensação de generosidade do app e na receita.

---

### 12. Como funciona o desafio diário? 🟡 custo baixo-médio

| Opção | Consequência |
|---|---|
| **A. Um tipo por dia, rotativo** ⭐ recomendo | Simples, cria hábito, e a sequência ("streak") fica fácil de entender. Mas quem só gosta de Shikaku fica de fora 3 dias em 4. |
| **B. Um de cada tipo, todo dia** | Todo mundo tem o seu, mas "sequência" fica ambígua: perde a sequência quem não fez os quatro? |

---

### 13. Posso usar uma biblioteca pronta para salvar o progresso? 🟢 custo baixo

Para salvar automaticamente (Fase 3), o padrão é `shared_preferences` — funciona no
Android e na web (usa o armazenamento do navegador), é mantida pelo time do Flutter e não
tem alternativa melhor na biblioteca padrão. **Justificativa exigida pela regra X6:** é a
única forma de persistência que funciona nas duas plataformas sem escrever código
específico de plataforma. Você aprova essa dependência?

---

### 14. Você já tem um domínio na internet? 🟢 custo baixo

Isso muda o SEO. Um endereço tipo `deduce.app` ou `deduce.com.br` vale bem mais que
`seunome.github.io/deduce`. Se você não tiver, dá pra lançar sem e comprar depois, mas
mudar de endereço depois de indexado custa parte do tráfego já conquistado.

---

### 15. Acessibilidade para daltônicos — o Star Battle depende de cor 🟢 custo baixo se decidido agora

Star Battle mostra as regiões coloridas. Cerca de 8% dos homens têm alguma dificuldade com
cores, e o público de puzzle lógico é majoritariamente masculino e adulto. Proposta: usar
**bordas grossas entre regiões além da cor**, para o puzzle ser jogável em preto e branco.
Custa quase nada agora e é caro depois. Confirma?

---

### 16. Confirma os 8 idiomas, e quem revisa? 🟢 custo baixo

pt-BR, en, de, ja, nl, pl, es, fr. A ordem faz sentido (Alemanha, Japão e Holanda são
países com tradição de puzzle Nikoli e bom valor de anúncio). Minha preocupação é
qualidade: as dicas explicam raciocínio, e tradução automática ruim mata a proposta de
"dicas que ensinam". Sugestão: lançar com **pt-BR e en revisados por você/mim** e os outros
seis marcados como beta. Ok?

---

### 17. O motor deve ser um pacote Dart separado? 🟢 custo baixo

A regra R5 diz que o motor não pode importar nada do Flutter. Dá pra garantir isso de dois
jeitos: um teste automático que falha se alguém importar, ou separar o motor num pacote
próprio onde a importação é fisicamente impossível.

**Recomendo o teste automático:** dá a mesma garantia, e um pacote separado adiciona uma
camada de configuração que atrapalha mais do que ajuda num projeto de uma pessoa só.

---

## Resumo do que preciso de você

**Bloqueiam a Fase 1:** perguntas **1, 2, 3, 4, 5 e 6**.
**As outras onze** eu consigo tocar com as recomendações acima e ajustar depois, se você
preferir responder só as seis primeiras agora.
