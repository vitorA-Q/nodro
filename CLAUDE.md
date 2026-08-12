# NODRO — Project Memory

Read this before touching anything. It is the permanent contract for this repo.
Full briefing: `docs/briefing.md`. Phase planning: `planning.md`. Status log: `PROGRESS.md`.

## What this is

A collection of combinatorial logic puzzles from the Nikoli family (Star Battle,
Slitherlink, Shikaku, Tents & Trees, more later), built in Flutter for **web first**,
then Android, then maybe iOS.

## The three invariants (P1–P3)

These define the product. No implementation decision may compromise them.

**P1 — PROVEN UNIQUENESS.** Every puzzle shown to a player has exactly one solution,
and that is *demonstrated* by an exhaustive solver, never assumed by the generator.

**P2 — DIFFICULTY BY HUMAN TECHNIQUE.** Difficulty is the most advanced deduction
technique the puzzle *requires*, determined by a human-simile solver. Not clue count,
not brute-force time, not a statistical heuristic.

**P3 — HINTS THAT TEACH.** The hint engine finds the simplest next valid deduction,
names the technique, highlights the cells involved, and explains *why* the deduction
is valid. A hint never reveals an answer without justifying the reasoning.

If any decision threatens P1, P2 or P3 — stop and raise it with the user.

## MILESTONE 1 — the only thing that matters right now

**Star Battle, playable and published on the web.** Nothing else.

Definition of done:
- Star Battle engine complete, PROP-1..PROP-6 passing
- Playable in browser, on phone and desktop
- Explanatory hints with visual highlighting
- Interactive tutorial
- Daily challenge with a share button
- Published at a URL the user can open and send to someone
- pt-BR and en

**Explicitly OUT of milestone 1:** Slitherlink, Shikaku, Tents, the other six locales, ads,
the Pro purchase, Android, advanced stats, the learning path.

**SCOPE RULE (S1)** — Until milestone 1 is live: anything worth doing that is not on the list
above goes into `BACKLOG.md`. Do not implement it. Do not ask whether to implement it.

**SPEED RULE (S2)** — Speed comes from cutting scope, NEVER from cutting tests. If relaxing
C1, C2, C3 or any PROP ever looks tempting, the answer is no. Cut features instead.

Build order is **sequential, not parallel**: Star Battle ships before Slitherlink starts.
Slitherlink is the hardest of the four (global single-loop constraint) and must not sit on
the critical path to the first milestone.

## Locked product decisions

These were decided by the user in Phase 0. Do not re-litigate them.

- **D1 — Concurrency.** One implementation for web and Android: time-sliced solvers that
  yield control between chunks. No isolate-only design (isolates do not exist on web).
- **D2 — Pre-generated bank first.** The player must NEVER wait for generation to start
  playing. Live generation is only for infinite mode and runs in the background. Bank budget:
  **max 3 MB compressed total**, split evenly across the 4 difficulties. Report how many
  puzzles fit.
- **D3 — Difficulty storage.** Persist the **tier, 1..7**, never the label. The four visible
  names (Fácil / Médio / Difícil / Extremo) are a display layer in ONE file, so changing to
  five names later is a one-file change.
- **D4 — PROP-3 is two-sided.** A puzzle is difficulty `d` iff the human solver succeeds
  with techniques up to `d` AND fails with techniques up to `d−1`.
- **D5 — PROP-6 per type.** Slitherlink: applies fully. Star Battle: not applicable, replaced
  by boundary rigidity. Shikaku: not applicable, replaced by value-erasure minimality. Tents:
  applies modulo the two sum identities (one row clue and one column clue are always derivable
  and are excluded from the test). See `planning.md` section (d).
- **D6 — Star Battle sizes.** 6x6 (1 star), 8x8 (1), 9x9 (2), 10x10 (2).
- **D7 — Monetization shape.** Free: every puzzle type, unlimited puzzles, daily challenge,
  1 free hint per puzzle, ads. Pro (one-time): unlimited hints, no ads, technique library and
  learning path, full stats. **NEVER paywall a puzzle type** — it is the main competitor's
  mistake and it kills SEO.
- **D8 — Hint economy.** 1 free hint per puzzle; each additional hint costs one rewarded ad;
  Pro is unlimited. Ads arrive in Phase 6, but **the counter is built now**.
- **D9 — Daily challenge.** One puzzle per day per type, seed derived from the date, identical
  for everyone, no server. The Wordle-style **share button is mandatory in milestone 1** and
  must not reveal the solution.
- **D10 — Persistence.** Simplest thing that works identically on web and Android (JSON in
  key-value storage). Hidden behind a repository interface so swapping it is a one-file change.
  Do not spend time evaluating database libraries.
- **D11 — Accessibility is not optional.** Star Battle regions are separated by a **thick
  border**, not only by colour. Colour-safe palette. Colour is reinforcement, never the only
  carrier of information.
- **D12 — Tents rules.** Show every row and column number (genre standard). Victory = all
  tents correctly placed. Grass marks are an optional aid and do not count toward victory.
- **D13 — Locales.** Milestone 1 ships pt-BR and en only. All text comes from `.arb` from day
  one; the other six locales land before the Play Store release, not before milestone 1.
- **D14 — Hosting.** Cloudflare Pages, because it serves per-type SEO URLs with real redirect
  and header control, works with a private repo, and its CDN is measurably faster from Brazil
  than GitHub Pages.
- **D15 — Test cadence: three layers.** Verification is cheap (one oracle call plus one human
  solve); *generation* is what costs. So the layers separate them:
  - **Layer 1 — bank verification, the RELEASE GATE.** PROP-1..PROP-6 against every puzzle in
    the shipped bank (1,000+), generating nothing. Target under 10 minutes.
    `test/property/bank_verification_test.dart`
  - **Layer 2 — generator regression, the DAILY GATE.** ~50 freshly generated small puzzles,
    all properties. Catches regressions in the generator itself. Target under 2 minutes.
    `test/property/generator_regression_test.dart`
  - **Layer 3 — nightly batch.** Fresh generation in volume, tagged `nightly`, on request.
    `flutter test test/property/nightly_batch_test.dart --tags nightly`

  This *strengthens* the contract: the gate now validates the artefact that actually ships
  rather than a random sample nobody plays. **The 1,000 count is never reduced.**
- **D16 — Generation targets for milestone 1.** The 300 ms figure was set for live on-device
  generation, which milestone 1 does not use. Replaced by: **the full bank batch finishes in
  under 2 hours wall clock, parallelised across cores.** Live on-device generation is OUT of
  milestone-1 scope and sits in `BACKLOG.md` with the current performance analysis.
  **The engine's definition of done is Layer 1 passing against the bank — not the 300 ms.**

## W7 — No optimisation without measurement

No performance change may be committed without a before-and-after number **in the same commit
message**. This rule exists because two entirely plausible optimisations in the Star Battle
generator were both measured to be *worse* and reverted:

- raising the refinement budget from 400 to 6,000 steps: 9x9 median 610 ms → 1,074 ms;
- scoring six candidate moves per step and keeping the best: 610 ms → 904 ms.

Plausible and faster are different things.

## Why the tests are the product

Anyone can generate a Slitherlink app with AI in a weekend. What they cannot generate
is one whose puzzles are provably unique, because they do not know they need a
verification oracle. The property-test harness is not engineering rigor — it is the
competitive moat, and the one part competitors will not copy. **Never propose cutting
tests to go faster.** If the user proposes it, warn them.

## Correctness contract

**C1** — No UI code before that phase's engine passes every property test. No exceptions,
not even "just to visualize". (Repeated as X7 because it is the rule agents break most.)

**C2** — For EACH puzzle type, at least 1,000 instances generated from fixed,
reproducible seeds, tested against:

- **PROP-1 (uniqueness)** — exactly one solution, verified by an independent exhaustive
  solver that counts solutions with early exit on the second.
- **PROP-2 (human solvability)** — solvable by the human-simile solver using only named
  techniques, with zero guessing or backtracking steps.
- **PROP-3 (difficulty consistency)** — the difficulty label equals the tier of the most
  advanced technique the human solver needed. Deterministic.
- **PROP-4 (technique soundness)** — no technique ever eliminates a value that belongs to
  the true solution. Cross-check every deduction against the known solution. An unsound
  technique is a critical bug, not a detail.
- **PROP-5 (serialization)** — `serialize(deserialize(x)) == x` for every puzzle state and
  every progress state.
- **PROP-6 (minimality)** — removing any further clue breaks uniqueness. Declare the types
  where this does not apply and why.

**C3** — Two independent solvers per type:
- `ExhaustiveSolver` — correct by construction, slow, is the **ORACLE**.
- `HumanSolver` — applies named techniques by tier, is the **PRODUCT**.

The HumanSolver is validated *against* the ExhaustiveSolver, never the reverse. If they
disagree, the HumanSolver is wrong until proven otherwise.

**C4** — When declaring a phase done, run and **paste the real output** of the commands
below. Never write "the tests pass" — paste the output.

## Commands

```bash
flutter --version
dart analyze                  # must be zero issues
flutter test                  # must be all green
dart run tool/bench.dart      # phase performance numbers
flutter build web --release
```

Flutter is not on PATH by default in this environment. It lives at `C:\flutter\bin`.
Prefix shell sessions with: `$env:PATH = "C:\flutter\bin;" + $env:PATH`

## Architecture rules (R1–R8)

- **R1** — Stable Flutter, pure Dart. No Flame, no game engine. Puzzles are static grids:
  `CustomPainter` + `RepaintBoundary` is enough.
- **R2** — NEVER generate or solve a puzzle on the UI thread. Everything in an `Isolate`.
  The app must never freeze.
- **R3** — Zero network dependency at runtime. Must work in airplane mode.
- **R4** — Each puzzle type is a self-contained module behind a common interface. Adding
  the 15th type must not require touching the previous 14.
- **R5** — The `engine/` layer is pure Dart and imports NOTHING from `package:flutter/`.
  Structural rule: if the engine needs Flutter, the design is wrong. Enforced by a test.
- **R6** — All visible text comes from `.arb` files via `gen_l10n`. Zero hardcoded strings
  in the UI, including technique names and hint text.
- **R7** — No `dynamic` in public API. No `late` without a comment justifying it.
  `flutter_lints` with zero warnings.
- **R8** — Anything that works on Android must work on web. If something cannot, raise it
  BEFORE implementing, not after.

## Layout

```
lib/
  engine/                  pure Dart, ZERO flutter/ imports
    core/                  puzzle_type.dart grid.dart deduction.dart solve_result.dart
    puzzles/<type>/        model.dart rules.dart techniques/ human_solver.dart
                           exhaustive_solver.dart generator.dart
  data/                    puzzle_bank.dart progress_repository.dart
  ui/                      painters/ screens/ widgets/
  l10n/
test/
  property/                PROP-1..PROP-6 per type
  golden/                  minimal failing instances, permanent regression
  unit/
tool/                      bench.dart generate_bank.dart
web/                       per-type landing pages for SEO
```

Core contracts (names adaptable, semantics not):

```dart
abstract class PuzzleType<S extends PuzzleState> {
  String get id;
  PuzzleGenerator<S> get generator;
  HumanSolver<S> get humanSolver;
  ExhaustiveSolver<S> get exhaustiveSolver;
  List<Technique<S>> get techniques;      // ordered by tier
  RuleValidator<S> get validator;
  PuzzleSerializer<S> get serializer;
}

abstract class Technique<S> {
  String get id;                   // i18n key
  TechniqueTier get tier;          // 1..7
  List<Deduction> apply(S state);  // empty if not applicable
}

class Deduction {
  final String techniqueId;
  final List<CellRef> highlightedCells;      // what the hint highlights
  final List<CellRef> affectedCells;         // what the deduction concludes
  final Map<String, Object> explanationArgs; // interpolated into the .arb
}
```

A typed `Deduction` is what makes P3 possible without hacks: a hint is not pasted text,
it is the result of a real deduction.

## Launch order (non-negotiable)

1. Web (Flutter Web), published, with SEO
2. Android (Google Play)
3. iOS, only if the first two work

Consequence: NOTHING may depend on a mobile-only plugin in Phases 0–4. The ads SDK enters
only in Phase 6, behind an abstraction.

## Monetization (Phase 6 only, in priority order)

1. One-time "Pro" purchase (~US$4.99): unlimited hints, no ads, extra puzzle types. **Main
   revenue line.**
2. Rewarded ad for hints beyond the first free one, free tier only.
3. Interstitial: max 1 per 2 completed puzzles. Never mid-puzzle. Never in a new user's
   first 3 puzzles.
4. Web display ads, only when traffic justifies it.

## Forbidden anti-patterns (X1–X8)

- **X1** — Fix the ROOT CAUSE. Never swallow an error in an empty catch, never return fake
  fallback data, never loosen a test to make it pass. A failing property test means the
  CODE is wrong, not the test.
- **X2** — Never mark a puzzle valid without running it through the ExhaustiveSolver.
- **X3** — Never implement a technique whose soundness you cannot justify in one sentence.
- **X4** — Never use a timeout or iteration limit as a difficulty criterion.
- **X5** — Never build a generic brute-force solver and call it a human solver.
- **X6** — No new dependency without a one-sentence justification. Prefer the stdlib.
- **X7** — No UI before the engine passes. (Same as C1. Repeated on purpose.)
- **X8** — No recurring subscription, virtual currency, energy, lives, or loot boxes.

## Work protocol (W1–W6)

- **W1** — Plan Mode before any change touching multiple files.
- **W2** — One logical unit at a time. Stub everything, show the list, then fill in one by
  one. Do not dump 2,000 lines at once.
- **W3** — Use a subagent for research, to keep the main context clean.
- **W4** — Use a second-opinion subagent tasked with REFUTING each solver before the user
  approves it. The author must not be the evaluator.
- **W5** — `git commit` at logical checkpoints, with a descriptive message.
- **W6** — At the end of each phase, write the summary in `PROGRESS.md`, in simple
  Portuguese.

## Communication rule (permanent)

The user does not program. They will not read code, edit files, or fix anything by hand.
Therefore, in EVERY reply:

- Write the summary in **simple Portuguese**, no unexplained jargon.
- When a decision is needed, present the options in plain language with the practical
  consequence of each. Never ask them to choose between technical alternatives without
  explaining what changes for the end user.
- If a command fails, do not tell them to fix it. Diagnose and fix it yourself, then
  explain in one sentence what it was.
- `PROGRESS.md` is also written in simple Portuguese.
- Code, variable names and comments stay in English. Only the conversation with the user
  and `PROGRESS.md` are in Portuguese.

## Non-goals

Not building: a game engine, multiplayer, a backend, user accounts, a level editor,
recurring subscriptions, or any live-ops economy. No iOS work until web and Android ship.
No monetization code before Phase 6. No UI before the engine passes its tests.
