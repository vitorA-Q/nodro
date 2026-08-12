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

## Fase 0 — Planejamento 🔄 em andamento

Em construção. Ver `planning.md`.
