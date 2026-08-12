# Shikaku — Human deduction technique catalogue

Research output, Phase 0. Implementation spec for `lib/engine/puzzles/shikaku/techniques/`.

**Research note up front.** The Shikaku technique literature is genuinely thin, and thinner than
the brief assumed. **Conceptis does not publish a Shikaku techniques page at all** (404; they have
never carried the genre). **Puzzling Stack Exchange has essentially no Shikaku strategy content.**
The richest sources turned out to be **code, not prose**: Simon Tatham's `rect.c` (his
"Rectangles" *is* Shikaku) contains a four-rule deterministic engine with explanatory comments,
and pzl.org.uk documents three named "Algorithm 0/1/2" rules plus a difficulty formula.

**19 techniques below: 12 traceable to community/implementation sources, 7 derived from the
constraint structure, each explicitly marked.**

---

## Shared model and data structures

- Grid `W x H`; clue set `C = {c_1 … c_n}` with cell `pos(i)` and value `v_i`.
- **Invariant A:** `Σ v_i = W·H` in **every** valid Shikaku. Every cell is in exactly one
  rectangle; every rectangle has exactly one clue; area = clue.
- **Invariant B (from A):** if you pick one rectangle per clue and they are pairwise disjoint,
  they automatically cover the whole grid. So Shikaku is an **exact cover / set-partitioning**
  problem: choose one candidate per clue, pairwise disjoint.
- `P[i]` — per-clue candidate placement list: rectangles `R = (top, left, h, w)` with `h·w = v_i`,
  `pos(i) ∈ R`, `R ⊆ grid`, and `R` contains no other clue cell.
- `cover[x]` — per-cell candidate index: pairs `(i, k)` with `x ∈ P[i][k]`.
- `clues[x]` — `{ i : ∃k, x ∈ P[i][k] }`, the clues that can still reach `x`.
- `cnt[x][i]` — number of surviving placements of clue `i` covering `x`. Lets you test "all"
  (`cnt[x][i] == |P[i]|`) and "none" (`0`) in O(1).
- `owner[x] ∈ {UNKNOWN} ∪ C`; `SOLVED[i]` once `|P[i]| == 1`.
- Placements stored as row-bitmasks (one `W`-bit word per row) for O(H) overlap tests.

**Blanket soundness principle.** Every technique is either (a) an *elimination* removing a
placement provably in **no** valid solution, or (b) an *assertion* entailed by the constraints in
**every** valid solution. Since the intended solution is a valid solution, neither can destroy it.

---

## Summary table

| # | id | name | tier | concludes | provenance |
|---|---|---|---|---|---|
| 1 | `unitClue` | Clue of One | 1 | places rectangle | community |
| 2 | `soleCandidateRectangle` | Last Remaining Placement | 1 | places rectangle | community |
| 3 | `divisorShapeEnumeration` | Factor-Pair Shapes | 2 | eliminates candidate | community |
| 4 | `primeNumberStrip` | Prime Strip | 2 | eliminates candidate | community |
| 5 | `edgeAndCornerClamp` | Wall and Corner Clamp | 2 | eliminates candidate | community |
| 6 | `foreignClueExclusion` | No Foreign Clue | 2 | eliminates candidate | community |
| 7 | `boundingBoxClueBlock` | Bounding-Box Blocker | 2 | eliminates candidate | **derived** |
| 8 | `uniqueCoveringClue` | Only Clue That Can Reach | 3 | assigns cell + eliminates | community |
| 9 | `cornerCellOwnership` | Corner / Dead-End Ownership | 3 | assigns cell | community (weak) |
| 10 | `placementIntersection` | Guaranteed Cells | 4 | assigns cell | community |
| 11 | `assignedCellConflict` | Claimed-Cell Conflict | 4 | eliminates candidate | community |
| 12 | `knownCellsBoundingBox` | Anchor Hull Growth | 4 | assigns cell + eliminates | **derived** |
| 13 | `disjointPairSupport` | Two-Clue Arc Consistency | 5 | eliminates candidate | community |
| 14 | `corridorSplitBetweenClues` | Corridor Tug-of-War | 5 | eliminates candidate | **derived** |
| 15 | `closedRegionAreaBalance` | Sealed Region Area Balance | 6 | eliminates candidate | hybrid |
| 16 | `hallSetExclusion` | Saturated Clue Set | 6 | eliminates candidate | **derived** |
| 17 | `rowColumnCoverageCount` | Line Width Composition | 6 | eliminates candidate | **derived** |
| 18 | `checkerboardParityBalance` | Checkerboard Parity | 6 | eliminates candidate | **derived** |
| 19 | `placementOrphanTest` | Orphan-Cell Refutation | 7 | eliminates candidate | **derived** |

Engine loop: run tiers ascending, **restart at tier 1 after any change**, escalate only at
fixpoint. Report the highest tier used as difficulty.

---

## TIER 1

### 1. `unitClue` — Clue of One
- **Description** — A clue with value 1 owns exactly its own cell.
- **Soundness** — A rectangle of area 1 containing the clue cell can only be that single cell;
  there is no alternative placement to discard.
- **Concludes** — places a rectangle (immediately triggers #11 on every other clue).
- **Data** — writes `owner[pos(i)] = i` and `SOLVED[i]`.

### 2. `soleCandidateRectangle` — Last Remaining Placement
*Alt: Forced Rectangle, Only Fit, "Algorithm 2" (pzl.org.uk).*
- **Description** — If a clue has exactly one surviving candidate rectangle, place it.
- **Soundness** — The solution's rectangle for `i` is always one of the surviving members of
  `P[i]` (every filter that built `P[i]` is sound), so `|P[i]| = 1` means that survivor *is* it.
- **Concludes** — places a rectangle.
- **Data** — `P[i]` with a live count; worklist of shrunken clues.
- **Note** — This is the **terminal rule of the whole engine**. Every other technique exists to
  feed it.

---

## TIER 2

### 3. `divisorShapeEnumeration` — Factor-Pair Shapes
- **Description** — A clue `v`'s rectangle must have `h·w = v`, so only divisor pairs of `v` are
  legal shapes, in both orientations.
- **Soundness** — A rectangle's area is the product of its integer sides; any other shape is not
  a rectangle of area `v` and appears in no solution.
- **Concludes** — eliminates candidates (in practice it is the *generator* of `P[i]`).
- **Data** — precomputed `divisors[v]` table for `v ≤ W·H`.

### 4. `primeNumberStrip` — Prime Strip
*The most universally cited Shikaku tip; appears in essentially every source.*
- **Description** — A prime clue `p` has only the divisor pair `(1, p)`, so its rectangle is a
  `1xp` or `px1` strip through the clue cell. If the grid or a wall kills one orientation, the
  axis is fixed.
- **Soundness** — Primes admit no non-trivial factorisation, so every area-`p` rectangle in any
  solution is a strip.
- **Concludes** — eliminates candidates, often collapsing `P[i]` to `≤ 2p` entries and with #5
  frequently to a single axis.
- **Data** — primality sieve; per-clue `orientationMask` (`HORIZ | VERT`) so the UI can explain
  "this clue is a strip". Treat clue `2` as a special case worth its own explanation string.

### 5. `edgeAndCornerClamp` — Wall and Corner Clamp
- **Description** — A candidate must lie wholly inside the grid, so clues near a wall lose every
  overhanging placement; a corner clue can only extend inward.
- **Soundness** — Solution rectangles are subsets of the grid by definition.
- **Concludes** — eliminates candidates.
- **Data** — bounds check during `P[i]` generation.
- **Why a separate id** — purely so the explainer can say "this 6 cannot be 6 wide here — the
  wall is 4 cells away."

### 6. `foreignClueExclusion` — No Foreign Clue
*pzl.org.uk builds its difficulty metric on exactly this filter.*
- **Description** — A candidate for clue `i` may not contain any *other* clue cell.
- **Soundness** — Every solution rectangle contains exactly one clue.
- **Concludes** — eliminates candidates.
- **Data** — per-row bitmask `clueRowMask[r]`, so the test is an AND of the candidate's row masks
  — O(h) per candidate.
- **Note** — **The single most productive Tier-2 filter. Run it before anything else touches
  `P[i]`.**

### 7. `boundingBoxClueBlock` — Bounding-Box Blocker  *(derived)*
*A rigorous generalisation of the vague community tip "look for numbers close to each other".*
- **Description** — Clue `i` can never own cell `x` if the axis-aligned bounding box of
  `{pos(i), x}` contains any other clue. Yields a per-clue "reach mask" that prunes `P[i]` and
  `clues[x]` before candidate enumeration.
- **Soundness** — Any rectangle containing both `pos(i)` and `x` necessarily contains their whole
  bounding box (rectangles are closed under bounding boxes), so if that box holds another clue,
  every such rectangle breaks the one-clue rule.
- **Concludes** — eliminates candidates and pre-shrinks `clues[x]`, feeding Tier 3 for free.
- **Data** — per-clue `reach[i]` bitboard from a four-quadrant sweep out from `pos(i)`, each
  ray/quadrant stopping at the first foreign clue. O(W·H) per clue, done once at load. Candidates
  then require `R ⊆ reach[i]`.

---

## TIER 3

### 8. `uniqueCoveringClue` — Only Clue That Can Reach
*Alt: Lonely Cell, "Algorithm 1" (pzl.org.uk), Tatham's "square-focused deduction". Used
explicitly in the janko.at worked example.*
- **Description** — If `|clues[x]| == 1`, cell `x` belongs to that clue, and every placement of
  that clue that misses `x` is dead.
- **Soundness** — Every cell is covered in every solution, so if only clue `i` has a surviving
  candidate covering `x`, the solution's rectangle for `i` must cover `x`.
- **Concludes** — assigns a cell **and** eliminates candidates.
- **Data** — `clues[x]` maintained incrementally as `cnt[x][i]` drops to 0; dirty-cell queue.
- **Note** — Pairs with #11 as the propagation engine.

### 9. `cornerCellOwnership` — Corner / Dead-End Ownership
- **Description** — The four grid corners, and any cell walled in on three sides by grid edges or
  owned cells, have the smallest `clues[x]`, so scan them first for the #8 condition.
- **Soundness** — This is a **search-order specialisation of #8, not a new inference**. A corner
  is a cell like any other and must be covered.
- **Concludes** — assigns a cell.
- **Data** — priority queue of unowned cells keyed by `|clues[x]|` ascending; corners seeded first.
- **Why keep it separate** — **explanation quality only.** "The bottom-left corner must belong to
  the 8" reads far better than a generic coverage message.

---

## TIER 4

### 10. `placementIntersection` — Guaranteed Cells
*Alt: "Algorithm 0" (pzl.org.uk); Tatham's "intersection of all possible placements". The
single most-repeated intermediate tip in the literature.*
- **Description** — Any cell contained in **every** surviving candidate of clue `i` belongs to
  `i`, even though the rectangle's full extent is unknown.
- **Soundness** — The solution's rectangle for `i` is one of the survivors, and by hypothesis
  every one contains `x`.
- **Concludes** — assigns a cell.
- **Data** — maintain `andMask[i]` = bitwise AND of all surviving placements, recomputed lazily
  when `P[i]` shrinks; every set bit is guaranteed. Equivalently test `cnt[x][i] == |P[i]|`.
- **Note** — Fires very early on primes, because a `1xp` strip's placements overlap heavily.

### 11. `assignedCellConflict` — Claimed-Cell Conflict
*Tatham verbatim: "This placement overlaps a square which is _known_ to be part of another
rectangle. Therefore we must rule it out."*
- **Description** — Once cell `x` is known to belong to clue `i`, delete every placement of every
  other clue that covers `x`.
- **Soundness** — Solution rectangles are pairwise disjoint.
- **Concludes** — eliminates candidates.
- **Data** — `cover[x]` makes this O(|cover[x]|) rather than a full rescan; decrement `cnt[x'][j]`
  for every cell of each deleted placement, pushing newly-single cells onto the #8 queue.
- **Note** — **This is the propagation backbone.** It turns any single assertion into a cascade.
  The pairs (#10, #11) and (#8, #2) are precisely Tatham's four-rule engine.

### 12. `knownCellsBoundingBox` — Anchor Hull Growth  *(derived)*
- **Description** — If two or more cells are known to belong to clue `i`, every cell of their
  bounding box belongs to `i` too, any candidate not containing that box is dead, and the box's
  height and width **lower-bound the rectangle's dimensions** — often killing entire divisor pairs.
- **Soundness** — A rectangle containing cells A and B contains their bounding box by definition.
- **Concludes** — assigns cells **and** eliminates candidates.
- **Data** — per-clue `anchorBox[i] = (minR, maxR, minC, maxC)`, updated O(1) per assignment; then
  require `boxH ≤ h`, `boxW ≤ w`, `boxH·boxW ≤ v_i`.
- **Note** — Cheap, fires constantly, and generates very legible explanations: *"the 12 already
  owns two cells three columns apart, so it is at least 3 wide, so it is 3x4 or 4x3 — not 2x6."*

---

## TIER 5

### 13. `disjointPairSupport` — Two-Clue Arc Consistency
*Tatham verbatim: "see if it overlaps _all_ of the candidate number placements for any
rectangle." The rigorous form of "two clues too close together force each other."*
- **Description** — Delete `R ∈ P[i]` if there exists a clue `j` such that `R` intersects **every**
  surviving candidate in `P[j]` — `j` would then have nowhere to go.
- **Soundness** — In any solution `i`'s and `j`'s rectangles are disjoint, so a candidate for `i`
  with no disjoint partner anywhere in `j`'s surviving set cannot be the solution's rectangle.
- **Concludes** — eliminates candidates.
- **Data** — for each ordered pair `(i, j)` with `reach[i] ∩ reach[j] ≠ ∅` (use #7's reach masks
  to build a **sparse neighbour graph** — most clue pairs never interact), a bitset
  `support[i][k]` over `P[j]` marking disjoint partners. `R` dies when `support[i][k]` is
  all-zero for some `j`. Recompute lazily per pair.
- **Note** — This is standard AC-3 restricted to binary disjointness.

### 14. `corridorSplitBetweenClues` — Corridor Tug-of-War  *(derived)*
- **Description** — When a run of cells can be reached by exactly two clues `i` and `j`, that run
  must be partitioned between them, so `i`'s extent plus `j`'s extent equals the run length —
  capping each side's reach and killing overshooting candidates.
- **Soundness** — Every cell of the run is covered in every solution and only `i` or `j` can
  cover it, so the run is exactly split between their rectangles.
- **Concludes** — eliminates candidates.
- **Data** — detect runs from `clues[x]`: maximal connected cell sets `S` with
  `clues[x] == {i, j}` throughout. For each `R ∈ P[i]`, require `S \ R` to be coverable by some
  `S' ∈ P[j]`.
- **Distinct from #13** because it reasons about the *cells* the two clues share rather than about
  placement-pair compatibility. Produces stronger cuts in narrow corridors.

---

## TIER 6

### 15. `closedRegionAreaBalance` — Sealed Region Area Balance
- **Description** — For any set `S` of unowned cells, let `T(S)` be the clues that can still reach
  any cell of `S`. Then `Σ_{i∈T(S)} v_i ≥ |S|`, and on **equality** every clue in `T(S)` is
  entirely inside `S`, so all their placements leaving `S` die.
- **Soundness** — By Invariant B the solution's rectangles are disjoint and cover `S` exactly
  using only clues from `T(S)`. If their total area equals `|S|`, none has a cell to spare
  outside. Violation of the inequality proves the current state contradictory.
- **Concludes** — eliminates candidates, typically cascading straight into #2.
- **Data** — union-find or flood-fill over unowned cells sealed by `owner[]` and grid edges;
  `Σ v` per region; `clues[x]` unioned over the region. Cap region size (~40 cells).
- **Note** — **This is the technique that makes late-game Shikaku collapse.**

### 16. `hallSetExclusion` — Saturated Clue Set  *(derived)*
- **Description** — The dual of #15. Pick a set `T` of clues, let `U(T)` be the union of cells any
  of them can still reach. Then `Σ_{i∈T} v_i ≤ |U(T)|`, and on **equality** `T` exactly tiles
  `U(T)`, so every candidate of every clue *outside* `T` that touches `U(T)` is dead.
- **Soundness** — `T`'s solution rectangles are disjoint, confined to `U(T)`, and total exactly
  `|U(T)|` cells, so they saturate that area.
- **Concludes** — eliminates candidates.
- **Data** — `reach[i]` bitboards kept live as `reach[i] = OR of surviving placements`. Enumerate
  `T` only over **connected components of the clue neighbour graph** and only up to `|T| ≤ 4`,
  else the subset search explodes.
- **Provenance** — no Shikaku source states this; it is the standard Hall's-marriage argument and
  is airtight.

### 17. `rowColumnCoverageCount` — Line Width Composition  *(derived)*
- **Description** — Within a row, each rectangle meeting it contributes one contiguous run equal
  to its width, and those runs exactly tile the row. So for any maximal unowned segment of length
  `L`, a candidate of width `w` survives only if `L − w` is expressible as a sum of widths
  available from the other clues reaching the segment.
- **Soundness** — In every solution the rectangles meeting a row cut it into disjoint runs whose
  widths sum to the row length.
- **Concludes** — eliminates candidates.
- **Data** — per row (and per column by transposing): maximal unowned segments from `owner[]`; for
  each, the multiset of `(clue, possible widths)`; a bounded subset-sum DP bitset over `0…L`.
  **Cap `L ≤ 16.`**
- **Note** — Most valuable on tall/narrow puzzles and in the endgame; skip on wide-open boards.

### 18. `checkerboardParityBalance` — Checkerboard Parity  *(derived — likely novel for Shikaku)*
- **Description** — Colour the grid like a chessboard. Every **even**-area rectangle covers equal
  black and white cells; every **odd**-area rectangle covers one more of its own corner colour.
  So for any sealed region with `b` black and `w` white cells, `b − w` must equal the signed sum
  `Σ ±1` over the odd-valued clues inside it — bounding `|b − w| ≤ #oddClues` and forcing
  `b − w ≡ #oddClues (mod 2)`.
- **Soundness** — The colour-count identity holds for every rectangle individually and therefore
  for any disjoint exact tiling.
- **Concludes** — eliminates candidates; also an excellent O(1) **contradiction detector** for
  the generator's validity check.
- **Data** — two popcounts per sealed region (from #15's flood fill) plus a per-region list of
  odd-valued clues with each candidate's corner colour `((top+left) & 1)`; a tiny ±1 subset-sum.
- **Recommended use** — as a fast **refutation filter in front of #19**, and as a generation-time
  sanity check, rather than as a primary hint. Its explanation ("count the light and dark
  squares") is legible but rarely the shortest human path.

---

## TIER 7

### 19. `placementOrphanTest` — Orphan-Cell Refutation  *(derived)*
- **Tier 7, explicitly deeper.** It **is** hypothetical reasoning — but of *bounded,
  deterministic* depth with **no search tree, no branching, no backtracking**.
- **Description** — Tentatively assume candidate `R ∈ P[i]`, run only the cheap propagation
  (#8, #10, #11), and if that yields **any** cell with `clues[x] = ∅` or **any** clue with
  `P[j] = ∅`, permanently delete `R`.
- **Soundness** — The deletion is justified only by a proof that assuming `R` forces a state with
  an uncoverable cell or an unplaceable clue, and no member of a valid solution can force such a
  state.
- **Concludes** — eliminates candidates.
- **Data** — trail-based snapshot of `P[]`, `cnt[][]`, `clues[]`, `owner[]` for O(changes) rollback.
- **⚠ HARD CAP** — one fixpoint pass over tiers 1–4, and **never nest a second assumption**.
  Nesting is what turns this into search.
- **Explanation template** — *"If the 9 took this cell, the cell at (r,c) could not be reached by
  any clue at all — so the 9 cannot take it."*

---

## EXCLUDED — backtracking or guessing in disguise

Give these ids anyway, so the app can blocklist them and reject puzzles requiring them.

| id | what it actually is | why exclude |
|---|---|---|
| `trialAndErrorBacktrack` | full depth-unbounded DFS with undo (Tatham's `rect.c` fallback; most GitHub solvers) | Unbounded nested assumptions. No human "sees" this; produces no explainable step. **pzl.org.uk agrees — it scores such puzzles difficulty −1.** |
| `mostConstrainedVariableFirst` | MRV / degree ordering | A *search-ordering heuristic*, not a deduction. It concludes nothing. Fine as an internal tie-break for which hint to show first; **must never appear as a named technique.** |
| `randomPlacementDisambiguation` | randomly delete candidate clue positions until unique (Tatham's **generator**) | Generation-only construction device, not an inference. Unsound as a solving rule. |
| `solutionCachingMemo` | memoise identical empty-cell configurations | Implementation optimisation, not a technique. |
| `evolutionarySearch` | GA / population search over partitions | Stochastic, non-explainable, not even guaranteed correct. |
| `uniquenessDeadlyPattern` | "this can't be the answer, it would make the puzzle ambiguous" | **Sound only under the assumption that the puzzle is unique** — not a consequence of the rules. Cannot be used to *prove* uniqueness (circular), so the generator must never validate with it. Flagged because the Tier-5/6 machinery will tempt us into it. |
| `visualScan` | "look at the puzzle from a distance and you will soon find the next rectangle" (Nikoli's official hint) | Charming, not mechanisable. |

---

## ⚠ PROP-6 / Minimality — NOT APPLICABLE, and the earlier substitute was wrong

**Short answer: clue-removal minimality is vacuously true for Shikaku. Do not implement it as a
quality gate.**

### The argument

Shikaku carries Invariant A: `Σ v_i = W·H`. This is not a property of *good* Shikaku puzzles — it
is a property of **every solvable** Shikaku puzzle, and it is an equality, not an inequality.

Delete clue `c_k` entirely. The remaining clues total `W·H − v_k < W·H`. Whatever rectangles you
now choose, they cover at most `W·H − v_k` cells, so at least `v_k` cells are left uncovered — and
uncovered cells are illegal. The reduced puzzle therefore has **zero** solutions. Deleting a clue
does not weaken the puzzle; it **destroys** it.

**Contrast with Sudoku / Slitherlink.** Erasing a Sudoku given leaves a well-formed puzzle with
*more* solutions; minimality is a real, informative, testable quality property. Same for
Slitherlink. In Shikaku there is no "more solutions" regime to fall into, because the clue values
are not merely *constraints on* the solution — they are a **complete accounting of the grid's
area**. Every clue is load-bearing by arithmetic, before any logic happens.

### ⚠ Correction to the Phase 0 draft

The planning draft proposed **PROP-6-SK: "for every clue `c`, the puzzle without `c` has exactly
zero solutions"** and described it as a real and strong test. **It is not.** It is true of *every*
Shikaku puzzle ever printed, including the worst ones. It distinguishes nothing, and would pass
100% of candidate puzzles at 100% of the cost. **Mark PROP-6 NOT APPLICABLE for this genre and use
one of the substitutes below.**

A second, subtler point: you also cannot *add* a clue. The clue count is not a free parameter — it
is exactly the number of rectangles in the partition, fixed the moment the partition is fixed.
**There is no "given count" dial in Shikaku the way there is in Sudoku.** Difficulty is tuned by
rectangle *sizes* and clue *positions*, not clue *quantity*.

### Three replacements that ARE meaningful

1. **`propValueErasureMinimality` — recommended, strongest analogue.** Replace one clue's *number*
   with `?` while keeping the clue cell marked. This is a genuine published variant — janko.at and
   the logic-masters Puzzlewiki both document Sikaku "with some numbers replaced by question
   marks". The rectangle count and one-clue-per-rectangle structure survive; only that clue's
   *value* is unknown, and Invariant A lets the solver recover it as `W·H − Σ(other clues)`. So
   the reduced puzzle is still well-formed, and "is it still uniquely solvable?" is meaningful.
   If erasing clue `k`'s value leaves the puzzle unique, that number was **redundant information**.
   **This is the direct structural analogue of Sudoku minimality — make it the PROP-6 substitute.**

2. **`propClueMergeMinimality` — the true "one fewer clue" test.** If two clues' rectangles are
   adjacent and their union is itself a rectangle, replace the pair `(a, b)` with a single clue of
   value `a + b` placed somewhere in the union. Clue count drops by one and Invariant A still
   holds, so the result is a legal Shikaku. If the merged puzzle is still uniquely solvable, the
   original was carrying a redundant split. **This is what "removing a clue" *should* mean here.**

3. **`propCluePositionRigidity`.** Hold the partition fixed and move one clue to a different cell
   **within its own rectangle**. Count how many of the `v_i` positions still yield a unique
   puzzle. Low counts mean a tightly-tuned puzzle. This is exactly the axis Tatham's generator
   optimises, so it is the empirically validated quality dial for this genre.

---

## Generation strategy — what real Shikaku generators actually do

**Overwhelmingly solution-first.** Every generator inspected builds a random rectangle partition
and *then* decides where the numbers go. Clue-first appears only as a theoretical alternative.

**Both options stated explicitly** in Stefan Schrama's 2012 Leiden report (2012-04):

- **Solution-first:** *"Randomly create rectangles within a given rectangular grid and then place
  the number corresponding with the surface area of the rectangle randomly inside it."* Flagged
  pitfall: naive random rectangle dropping leaves **1x1 gaps**, producing puzzles littered with
  clue-1s (trivial and ugly).
- **Clue-first:** *"First divide the size of the surface area of the grid into smaller numbers,
  which you then use to create rectangles."* Guarantees `Σ v = W·H` by construction and avoids
  stray singletons, but placement can fail and needs retries. The thesis implements **neither**,
  which itself tells you clue-first has little traction.

### Tatham's `rect.c` — the best-documented working generator, in four stages

1. **Shrunken base grid.** Generate on a grid scaled down by an *expansion factor*, placing
   rectangles greedily: walk the uncovered squares, enumerate all rectangles that could sit at
   each spot, pick one at random. Rectangles capped at ~1/6 of grid area and forbidden from
   spanning the full width or height.
2. **Singleton repair.** Leftover 1x1 squares are absorbed by extending or reshaping neighbours;
   if that fails, the surrounding 3x3 is bulldozed into one rectangle. (This solves Schrama's
   pitfall.)
3. **Expansion.** The small grid is inflated to full size by inserting rows, transposing, and
   inserting rows again — preserving rectangle topology while making rectangles **fewer and
   larger**. Tatham recommends an expansion factor **around 0.5 for increased difficulty**.
   **This is the single most useful generation knob found: harder Shikaku = fewer, bigger
   rectangles, not more clues.**
4. **Number placement by solver-guided elimination.** With the partition fixed, run the deduction
   engine over *all* cells as candidate number positions, eliminating positions until the puzzle
   is uniquely solvable, then drop the numbers in. Tatham notes the uniqueness search is the
   expensive part.

### Uniqueness verification — two documented approaches

- **Deductive:** run a complete solver and require it to finish *without* the guessing fallback.
  pzl.org.uk does this and reports difficulty −1 for any puzzle that needed guessing. **This is
  what we want, because it certifies *human*-solvability, not just uniqueness.**
- **Algebraic (no-good cut):** model as set partitioning,
  `minimize 0 s.t. Σ_k allRectangles(k,i,j)·x_k = 1 ∀(i,j)`, solve, add a constraint forbidding
  that exact solution, re-solve; **infeasible ⇒ unique**. Useful as an offline oracle for the test
  suite.

### ⚠ Uniqueness pitfalls — the deadly patterns to screen for

- **The minimal deadly pattern: two 2-clues on the diagonal of a 2x2 block.** Clues `2` at `(r,c)`
  and `2` at `(r+1,c+1)`, block sealed off. Cut into two horizontal `1x2`s, or two vertical
  `2x1`s — both legal. **Always ambiguous.** Trivially cheap to detect.
- **The 6-cell family, correctly stated.** A `2x6` region containing two `6`-clues, one top-left
  and one bottom-right, splits *either* as two `1x6` rows *or* as two `2x3` columns. Note the
  ambiguity is **not** "a 6-clue in a 2x3 region" — that one is forced. The ambiguity needs *two*
  clues whose values admit two different cuts of the same enclosing rectangle. Same phenomenon
  with two `6`s in a `3x4`, two `4`s in a `2x4`, two `3`s in a `1x6`.
- **General form to screen:** any sub-rectangle `p x q` that can be cut two different ways into
  pieces of the *same multiset of areas*, with each clue cell lying in the intersection of its
  piece under both cuttings. Enumerate over small `p·q` (≤ 12 covers virtually all real cases).
- **Clue position, not just partition, determines uniqueness.** The same partition can be unique
  or ambiguous depending purely on where inside each rectangle the number is dropped — which is
  precisely why Tatham's generator spends its budget on position elimination rather than on
  repartitioning. **Budget ours the same way.**
- **Small-rectangle bias.** Greedy random partitioning naturally produces many small rectangles,
  making trivially easy puzzles. The expansion trick is the documented fix; the area cap
  (`≤ grid/6`) and the "no full-span rectangles" rule are complementary guards.
- **Cheap static difficulty proxy (pzl.org.uk):** for each clue, enumerate all rectangles of that
  area through it, delete those falling off the grid edge and those containing another clue cell,
  and count what remains; sum across clues. That is literally #5 and #6 applied once, with no
  solver run. **Pair it with the real signal: the highest tier the engine needed, plus the count
  of steps at that tier.**

---

## Sources

**Substantive (technique- or algorithm-bearing):**
- Simon Tatham's `rect.c` — the richest single source; four named deduction rules plus the full
  generator. <https://raw.githubusercontent.com/chrisboyle/sgtpuzzles/master/app/src/main/jni/rect.c>
- <https://pzl.org.uk/shikaku.html> — "Algorithm 0/1/2", the difficulty formula, and the −1
  "needed guessing" flag.
- <http://yetanothermathprogrammingconsultant.blogspot.com/2020/03/cellblock-or-shikaku-puzzle.html>
  — set-partitioning / exact-cover formulation and the no-good-cut uniqueness proof.
- <https://theses.liacs.nl/pdf/2012-04StefanSchrama.pdf> — Schrama, Leiden 2012-04; the explicit
  solution-first vs clue-first contrast and the 1x1-gap pitfall.
- <https://www.janko.at/Raetsel/Sikaku/Beispiel.htm> — a genuine worked solve; step 2 uses the
  unreachable-cell argument verbatim.
- <https://github.com/wgoodall01/shikaku> — states the propagation loop precisely, then backtracks.
- <https://github.com/nanakin/shikaku-solver> — two named techniques plus explicitly-labelled
  assumption-based recursion and MRV ordering.
- <https://www.chiark.greenend.org.uk/~sgtatham/puzzles/doc/rect.html> — expansion factor ≈ 0.5
  for difficulty; unique-solution toggle.

**Moderate:**
- <https://shikaku.ch/guide.html> — ten labelled strategies; broadest naming inventory found, but
  low authority and likely SEO/AI-authored. Treated as a naming source only.
- <https://gridjoy.app/shikaku-info> — includes the "sum of all clues = total grid area" check.
- puzzle-magazine.com / sugurupuzzles.com Shikaku strategy pages — the "partial cells" and "cells
  reachable by only 1 digit" tips. **Both block direct fetching (403/500).**
- <https://www.puzzler.com/puzzles-a-z/cell-block> — Cell Blocks naming and factoring tip. 403.

**Academic:**
- Takenaga, Aoyagi, Iwata, Kasai, *Shikaku and Ripple Effect are NP-complete*, Congressus
  Numerantium 216 (2013).
- Sudarsana et al., *Implementation of Heuristic Technique and Genetic Algorithms in Shikaku
  Puzzle Problem* — listed only so it can be excluded (search-based).

**Checked and found empty — do not re-spend the budget:**
- **conceptispuzzles.com has NO Shikaku content of any kind.** The techniques URL 404s; Conceptis
  does not publish this genre. The research brief's assumption was wrong.
- **puzzling.stackexchange.com — no Shikaku strategy Q&A surfaced** on repeated site-scoped
  searches.
- **puzz.link / pzprjs — player/editor and rule-violation checker only**, no technique
  documentation.
- <https://www.puzzle-shikaku.com/faq.php> — rules and generic advice only; no technique page
  exists despite the brief's expectation.
