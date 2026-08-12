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

> **[PENDENTE]** Quatro pesquisas independentes estão rodando em paralelo, uma por tipo de
> puzzle, para levantar o catálogo completo de técnicas nomeadas com tier e justificativa
> de soundness. Esta seção é preenchida assim que elas retornarem.

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

| Tipo | PROP-6 se aplica? | Como é garantida / o que a substitui |
|---|---|---|
| Slitherlink | **Sim, plenamente** | Por construção: o gerador só para de remover quando nenhuma remoção adicional preserva a unicidade. O teste apenas reconfirma. |
| Tents & Trees | **Sim, nos números** | As pistas removíveis são os números de linha/coluna. Mesma remoção gulosa. As árvores não são removíveis (ver abaixo). |
| Star Battle | **Não se aplica literalmente** | Não existem pistas discretas: a pista é a partição em regiões, que é uma peça só. Substituição proposta abaixo. |
| Shikaku | **Não se aplica literalmente** | O conjunto de pistas é estruturalmente forçado. Substituição proposta abaixo. |

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

### Shikaku — por que não se aplica, e o que colocar no lugar

Aqui a razão é aritmética. Cada retângulo precisa conter exatamente um número, e a soma de
todos os números tem que dar exatamente a área da grade. Se você remove um número, um
retângulo fica órfão e a soma não fecha: o puzzle não passa a ter *duas* soluções, ele
passa a ter **zero**. Não é um puzzle mais fraco, é um puzzle quebrado.

**Substituição — PROP-6-SK (minimalidade exata):** para toda pista `c`, o puzzle sem `c`
tem exatamente **zero** soluções. Isso é um teste real e forte: prova que o conjunto de
pistas não tem nenhuma redundância, porque nenhuma delas é dispensável nem sequer para a
mera existência de solução. É o análogo correto de PROP-6 para este tipo.

### Tents & Trees — o recorte exato

As árvores não são pistas removíveis: elas *são* o puzzle (definem quantas barracas
existem). Os números de linha e coluna, sim, são removíveis. Então PROP-6-T se aplica só a
eles, com remoção gulosa idêntica à do Slitherlink.

**Porém há uma decisão de produto aqui**, que virou a pergunta 7 lá embaixo: o Tents
clássico mostra *todos* os números. Esconder os redundantes deixa o puzzle mais difícil e
mais "limpo" visualmente, mas foge da convenção que o jogador conhece.

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
projetos. Nada quebrou até agora, mas é um risco barato de eliminar. Pergunta 2.

### E10 — Qualidade das traduções das dicas

As dicas explicam raciocínio lógico. Tradução automática ruim transforma "esta região só
cabe nesta linha" em algo incompreensível, e aí a proposta P3 (dicas que ensinam) morre no
idioma traduzido. Mitigação: manter o texto das dicas curto e estruturado, com variáveis
interpoladas, e marcar os 8 idiomas como "precisa de revisão humana" antes de considerar a
Fase 5 pronta.

---

## (f) PERGUNTAS ABERTAS

Ordenadas por quanto custa retrabalhar se a resposta for errada. As primeiras cinco valem
muito mais do que as últimas.

> **[PENDENTE]** Esta seção é finalizada junto com a seção (b), para que eu possa incluir
> também as perguntas que surgirem da pesquisa de técnicas.
