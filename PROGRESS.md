# DEDUCE — Diário de progresso

Escrito em português simples. Uma seção por fase, na ordem em que aconteceram.

---

## Fase -1 — Setup ✅ concluída

**Data:** 12/08/2026

### O que foi feito

1. **Confirmei que o Flutter funciona.** Versão 3.44.6, canal estável, Dart 3.12.2.
   Um detalhe: o Flutter estava instalado em `C:\flutter` mas não estava configurado para
   ser chamado de qualquer lugar do computador. Resolvi apontando o caminho completo em
   cada comando — não precisa mexer em nada na sua máquina.

2. **Criei o esqueleto do app** com o identificador `com.vitorarzua`, nome `deduce`, para
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
