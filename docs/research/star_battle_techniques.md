# Star Battle — Human deduction technique catalogue

Research output, Phase 0. This is the implementation spec for `lib/engine/puzzles/star_battle/techniques/`.
One technique = one file = one class. Tiers are the difficulty ladder (P2).

**Global soundness caveat.** Every rule below is sound *given* that its premises (confirmed
stars, confirmed eliminations, "this set contains at least one star") were themselves derived
soundly. Soundness is inductive over the derivation: the solver must never admit an unsound
premise. This is what PROP-4 exists to verify.

**Three engines underlie almost everything:**
- **Adjacency capacity** — any 2x2 block holds at most one star, turning "how much area is
  left" into a hard upper bound on star count.
- **Quota counting** — every row, column and region holds exactly `k` stars, so any
  containment relation between a set of regions and a set of lines yields a pigeonhole equality.
- **Confinement** — when a unit's surviving candidates collapse into another unit, the two
  units trade claims.

---

## Summary table

| # | id | name | tier | concludes |
|---|---|---|---|---|
| 1 | `adjacencyElimination` | Neighbour Elimination | 1 | eliminate |
| 2 | `unitCompletionElimination` | Saturated Unit Elimination | 1 | eliminate |
| 3 | `unitForcedFill` | Forced Fill / Last Cells | 1 | place |
| 4 | `twoByTwoCap` | 2x2 Block Cap | 1 | bound (fact producer) |
| 5 | `cornerEdgeCapacity` | Corner & Edge Capacity | 2 | eliminate / place |
| 6 | `crowdingExclusion` | Crowding | 2 | eliminate |
| 7 | `sharedNeighborElimination` | Nosy Neighbours / Shared Exclusion | 2 | eliminate |
| 8 | `regionLineConfinement` | Region Confined to a Line | 2 | eliminate |
| 9 | `lineRegionConfinement` | Line Confined to a Region | 2 | eliminate |
| 10 | `regionSplitByStar` | Region Split by a Star | 2 | eliminate / place |
| 11 | `containerConsumption` | Container Consumption | 3 | eliminate |
| 12 | `twoByTwoTiling` | Minimal 2x2 Tiling (Four-Squares) | 3 | place / eliminate |
| 13 | `clumpPartition` | Clumps / Chunk Confinement | 3 | place / eliminate |
| 14 | `forwardElimination` | Forward Elimination (depth-1) | 3 | eliminate |
| 15 | `bandCounting` | Band / Stack Counting | 3 | eliminate / place |
| 16 | `regionsWithinLines` | N Regions in N Lines (Undercounting) | 4 | eliminate |
| 17 | `linesWithinRegions` | N Lines in N Regions (Overcounting) | 4 | eliminate |
| 18 | `compositeRegionTiling` | Composite Shapes | 4 | eliminate / place |
| 19 | `bandSqueeze` | The Squeeze | 4 | place / eliminate |
| 20 | `pressuredShapeExclusion` | Pressured Exclusion (Ts, Kissing Ls, M) | 5 | eliminate |
| 21 | `fish` | Fish / N-Set | 5 | eliminate |
| 22 | `placementEnumeration` | Pair (k-tuple) Enumeration | 5 | eliminate / place |
| 23 | `setDifferentials` | Set Differentials | 5 | eliminate / place |
| 24 | `finnedCounting` | Finned Counts | 6 | eliminate |
| 25 | `forcingChainRelay` | Relay / Cannot-Both Chains | 6 | eliminate |
| — | `deepLookAhead` | Look-Ahead / Contradiction Chains | 7 | **EXCLUDED — backtracking** |
| — | `uniquenessAssumption` | Uniqueness (By a Thread, At Sea) | 7 | **EXCLUDED — unsound** |

Tier distribution: T1 x4, T2 x6, T3 x5, T4 x4, T5 x4, T6 x2. Six tiers populated — well past
the Phase 1 DoD requirement of 8 techniques across 4 tiers.

---

## TIER 1

### 1. `adjacencyElimination` — Neighbour Elimination
*Alt: no-touch marks, Trivial Marks, Housekeeping, Shadow Crosses, Exclusion Zone.*

- **Description** — Every one of the up-to-8 cells orthogonally or diagonally touching a
  confirmed star is marked no-star.
- **Soundness** — The no-touch rule holds in every valid solution, so a cell touching a true
  star is provably not a true star. Only premise is a confirmed star.
- **Concludes** — Eliminates cells.
- **Data** — Cell state array, 8-neighbourhood offsets. O(1) per placed star.

### 2. `unitCompletionElimination` — Saturated Unit Elimination
*Alt: Rule of Finished Containers, Region Completion Elimination.*

- **Description** — Once a row, column or region holds its full quota of `k` confirmed stars,
  every remaining candidate in that unit is marked no-star.
- **Soundness** — The unit contains exactly `k` true stars; `k` are already identified, so any
  further star gives `k+1`.
- **Concludes** — Eliminates cells.
- **Data** — Per-unit star counters, per-unit candidate bitsets.

### 3. `unitForcedFill` — Forced Fill / Last Cells
*Alt: Last Cell, Line Counting to Two, Small Region Forcing, Exact Match Counting.*

- **Description** — When a unit's surviving candidate count equals its still-needed star count,
  every surviving candidate becomes a star.
- **Soundness** — The unit's true remaining stars are a subset of its surviving candidates
  (prior eliminations were sound), and a subset of size `r` inside a set of size `r` is the
  whole set.
- **Concludes** — Places stars.
- **Data** — Per-unit remaining-star counter and candidate bitset.

### 4. `twoByTwoCap` — 2x2 Block Cap  *(fact producer, not an eliminator)*
*Alt: The 2x2, Spacing Logic, 2x2 Mini-Square Constraint.*

- **Description** — Any 2x2 block contains at most one star (its four cells are pairwise
  adjacent). More generally the minimum number of 2x2 blocks needed to cover a cell set is an
  upper bound on that set's star count.
- **Soundness** — Asserts only an *upper bound*, derived directly from no-touch. An upper bound
  removes nothing by itself; it is a valid relaxation, so any downstream
  "capacity < requirement ⇒ infeasible" conclusion is also true of the real solution.
- **Concludes** — Nothing directly. Produces the capacity bound consumed by #6, #12, #13,
  #18, #19.
- **Data** — Cell set → minimal 2x2 cover (greedy with minimality check, or small exact set
  cover); precomputed 2x2 window list per region.

> **Terminology note.** "Wall counting" is a Nurikabe/Slitherlink term with no Star Battle
> equivalent. The genuine area argument here is this 2x2 capacity bound combined with quota
> counting (#15).

---

## TIER 2

### 5. `cornerEdgeCapacity` — Corner & Edge Capacity
- **Description** — Border and especially corner cells lie in fewer 2x2 windows and have fewer
  neighbours, so a region occupying a corner has markedly fewer legal `k`-placements; the outer
  ring is where capacity runs tight first.
- **Soundness** — It is #4 evaluated on border-clipped windows plus ordinary quotas. Every
  conclusion is a capacity-versus-requirement infeasibility, a valid relaxation.
- **Concludes** — Eliminates cells; occasionally places when a corner region collapses.
- **Data** — Region cell sets ∩ border ring; per-region enumeration of legal `k`-placements.
- **⚠ Implementation caveat** — Most published guides treat this as a corollary of #4/#19
  rather than a standalone rule. **Recommendation: implement as a heuristic ordering hint, not
  a separate `Technique`**, unless we specifically want hint text that reads "corner argument".

### 6. `crowdingExclusion` — Crowding
*Alt: Rule of Crowding, Rule of Selfish Roommates, Spacing Logic.*

- **Description** — A candidate `c` is eliminated when starring it would, through its
  8-neighbour blackout, leave its unit unable to seat the remaining stars pairwise-non-adjacently.
  Classic case (Selfish Roommates): in a set known to hold ≥2 stars, a cell adjacent to *all*
  other cells of the set is impossible — e.g. the centre of a 3x3.
- **Soundness** — One-step refutation. Assume a star at `c`, apply only forced no-touch
  eliminations, compare the unit's remaining capacity (an upper bound from #4) with its
  requirement. Capacity < requirement is a genuine contradiction.
- **Concludes** — Eliminates cells.
- **Data** — Per-unit candidate set, 8-neighbourhood mask, 2x2 cover of the post-blackout residual.

### 7. `sharedNeighborElimination` — Nosy Neighbours / Shared Exclusion
*Alt: Rule of Nosy Neighbors, Overlap Logic, Either-Or (same-elimination form).*

- **Description** — If a set `S` is known to contain at least one star, any cell outside `S`
  adjacent to *every* cell of `S` cannot be a star. Everyday case: a domino (region down to two
  candidates) kills all its common neighbours.
- **Soundness** — Whichever cell of `S` carries the true star, the target touches it, so the
  target violates no-touch in every valid solution.
- **Concludes** — Eliminates cells.
- **Data** — Registry of sets known to contain ≥1 star (region/line candidate sets, clumps from
  #13); intersection of the 8-neighbourhoods of all cells in `S`.

### 8. `regionLineConfinement` — Region Confined to a Line
*Alt: The 1xn, Confined Regions, The Star Claim, Region Locked to a Row/Column.*
*(This is the n=1 case of #16.)*

- **Description** — If all of a region's surviving candidates lie within one row or column, the
  region's stars must go there, consuming that line's quota; line cells outside the region are
  constrained accordingly.
- **Soundness** — The region's `r` remaining true stars all sit among candidates contained in
  the line; the line has fixed quota, so line cells outside the region carry at most
  `quota − r` stars. Pure containment-plus-cardinality.
- **Concludes** — Eliminates cells (rest of the line, fully or partially).
- **Data** — Region → touched rows/columns bitmask over *surviving candidates only*; per-line
  remaining quota.

### 9. `lineRegionConfinement` — Line Confined to a Region
*Alt: Row/Column Locked to a Region. Dual of #8; n=1 case of #17.*

- **Description** — If all of a line's surviving candidates lie inside one region, the line's
  remaining stars come from that region, costing the region's cells outside the line that much
  quota.
- **Soundness** — Line's `r` true stars ⊆ candidates ⊆ region; region quota fixed; so region
  cells outside the line hold at most `regionQuota − r`.
- **Concludes** — Eliminates cells (region cells outside the line).
- **Data** — Per-line candidate set, cell → region map, per-region remaining quota.

### 10. `regionSplitByStar` — Region Split by a Star
*Alt: chunk confinement; the trigger that produces clumps.*

- **Description** — A placed star's blackout cross (or an accumulated wall of marks) severs a
  region's remaining candidates into disconnected components. Each component's capacity is
  bounded independently; if all but one cap below the region's remaining need, the deficit is
  forced into the survivor.
- **Soundness** — Components partition the candidate set, so their true star counts sum to the
  remaining requirement. Combining per-component upper bounds (#4) with that exact sum yields
  per-component *lower* bounds that must hold in the true solution.
- **Concludes** — Eliminates cells; places stars when a component's lower bound equals its cell
  count or capacity.
- **Data** — Connected-component labelling of region candidates; per-component 2x2 capacity.
- **k-note** — For k=1 a split only pays off combined with #13. For k≥2 this is one of the
  highest-yield mid-game moves.

---

## TIER 3

### 11. `containerConsumption` — Container Consumption
*Alt: Rule of Container Consumption, Doubled Confinement, partial region overlap counting.*

- **Description** — If a proper subset `A` of unit `U` is guaranteed to contain at least `m`
  stars, then `U \ A` contains at most `quota(U) − m`; when that is zero, the whole complement
  is eliminated.
- **Soundness** — `A` and `U \ A` partition `U`, whose true star count is exactly `quota(U)`. A
  valid lower bound on `A` yields a valid upper bound on the complement.
- **Concludes** — Eliminates cells.
- **Data** — Unit-pair intersections (region ∩ line, region ∩ region), quotas, lower-bound registry.
- **k-note** — Commonly stated in its k=2 form ("the rest may contain at most one other star").
  General form is `quota − m`. For k=1 it degenerates to #8/#9.

### 12. `twoByTwoTiling` — Minimal 2x2 Tiling
*Alt: Rule of Four-Squares, Four-Square Subdivision Analysis.*

- **Description** — If a region needing `r` more stars has its candidates covered by exactly `r`
  **pairwise-disjoint** 2x2 blocks, each block holds exactly one star and becomes a one-star
  mini-container to which #3, #6 and #7 apply.
- **Soundness** — Each block holds at most one star (#4), blocks are disjoint and cover all
  candidates, so `r` true stars distribute one per block by pigeonhole. The conclusion is an
  equality forced by counts.
- **Concludes** — Places stars (block down to one candidate) and eliminates cells (via mini-container
  crowding / shared-neighbour logic).
- **Data** — Region candidate set; disjoint 2x2 cover search; derived virtual one-star containers.
- **⚠ CORRECTNESS WARNING** — The blocks **must be pairwise disjoint** and **must cover all**
  surviving candidates. Overlapping blocks give only the weaker "at most `r`" bound and must
  **not** be used to conclude "exactly one each". Getting this wrong makes the technique unsound.

### 13. `clumpPartition` — Clumps / Chunk Confinement
*Alt: Rule of Clumps, Confinement, Locked Sets.*

- **Description** — Generalizes #12: partition a unit's candidates into `m` groups each provably
  holding at most one star (each fits in a 2x2, or is a clique under adjacency). If `m` equals
  the unit's remaining need, each group holds exactly one.
- **Soundness** — Groups partition the candidate set, each has proven capacity 1, so the exact
  remaining count `m` distributes one per group. Downstream deductions run inside containers
  whose quota is a proven fact.
- **Concludes** — Places stars and eliminates cells.
- **Data** — Per-unit candidate set; partition into at-most-one-star groups (2x2 windows,
  adjacency-graph cliques); a stack of derived virtual containers.
- **k-note** — Vacuous for k=1 inside an unsplit region. Workhorse at k=2 (two clumps) and k=3.

### 14. `forwardElimination` — Forward Elimination (depth-1 refutation)
*Alt: Exclusion, Shape Elimination, Testing Placements (one-ply form).*

- **Description** — Tentatively star a candidate, apply **only** the immediate no-touch blackout
  and unit-saturation marks (one ply, no branching); if any unit's candidate count or 2x2
  capacity drops below its requirement, eliminate the cell.
- **Soundness** — Modus tollens: `star(c) ⇒ contradiction`, therefore `¬star(c)`. The
  contradiction is detected with monotone sound propagation and capacity upper bounds, so a
  reported contradiction is a real one.
- **Concludes** — Eliminates cells.
- **Data** — Cloneable candidate-set snapshot (bitsets per unit), single-ply propagation, capacity
  evaluator. Cost O(cells × propagation).
- **⚠ Boundary vs. guessing** — This is depth-1 refutation with no branch selection and no state
  kept from a failed branch. It is **not** guessing. Multi-ply versions become the excluded
  `deepLookAhead`.

### 15. `bandCounting` — Band / Stack Counting
*Alt: Counting, Virtual Bands, Stretch Counting, Cross Count.*

- **Description** — A band of `b` rows or columns holds exactly `b·k` stars. Regions wholly
  inside contribute exactly `k` each, so the residual must come from partially-overlapping
  regions, pinning how many stars each spillover region places inside versus outside the band.
- **Soundness** — An exact accounting identity over a partition of the band's cells by region
  membership, using only fixed quotas. Derived counts are equalities or valid bounds satisfied
  by every solution.
- **Concludes** — Eliminates cells (spillover region cells outside the band, band cells outside
  contributing regions) and places stars when a residual pins a region to one sub-area.
- **Data** — Region-to-line incidence matrix; per-band partition into wholly-inside / partial /
  disjoint; per-region inside/outside candidate counts and remaining quotas.

---

## TIER 4

### 16. `regionsWithinLines` — N Regions in N Lines (Undercounting)
*Alt: Undercounting, "N rows / N regions". Contains #8 as its n=1 case.*

- **Description** — If `n` regions have all surviving candidates inside a set of `n` rows (or
  columns), those regions supply `n·k` stars and the lines demand exactly `n·k`, so every cell
  of those lines outside those regions is eliminated.
- **Soundness** — Containment plus equal cardinality forces equality of the two star multisets:
  the lines' `n·k` true stars are exactly the regions' `n·k` true stars, leaving zero for line
  cells outside the regions.
- **Concludes** — Eliminates cells.
- **Data** — Region-to-row/column incidence bitmasks over *surviving candidates only*; subset
  enumeration over regions with an n-line coverage test. Practical to n = 3–4.
- **⚠ Implementation note** — Use **remaining** quotas, not nominal ones, so the rule stays valid
  on a partially-solved board. Published statements that this "does not work with partially
  solved containers" are an artifact of nominal-count phrasing, not a real limitation.

### 17. `linesWithinRegions` — N Lines in N Regions (Overcounting)
*Alt: Overcounting, Rule of Container Cabals, Multi-Region Column Analysis. Dual of #16;
contains #9 as its n=1 case.*

- **Description** — If the union of `n` regions completely contains the union of `n` lines,
  those regions' `n·k` stars must all fall inside those lines, so region cells outside the lines
  are eliminated.
- **Soundness** — The lines' `n·k` true stars lie inside the regions, and the regions hold
  exactly `n·k`, so the two star sets coincide; region cells outside the lines hold zero.
- **Concludes** — Eliminates cells.
- **Data** — Same incidence structure as #16, tested in the containment direction, with
  remaining-quota arithmetic.

### 18. `compositeRegionTiling` — Composite Shapes
- **Description** — Fuse two or more units (or unit fragments) whose combined star total is
  exactly known — from #15, #16 or #17 — into a single composite cell set, discard internal
  boundaries, and apply 2x2 capacity/tiling (#4, #12) to the composite.
- **Soundness** — The composite's exact star total is a sound consequence of prior counting, and
  the 2x2 bound on it is a valid relaxation. An exact total plus a valid upper bound yields only
  forced distributions, never a preference among feasible ones.
- **Concludes** — Eliminates cells and places stars.
- **Data** — Registry of `cellSet → exactStarCount` facts (rows, columns, regions, composites),
  set-union routine, 2x2 cover evaluator.

### 19. `bandSqueeze` — The Squeeze
*Alt: Squeeze, Row/Column Squeeze, Region Squeeze, Pair Squeeze.*

- **Description** — Minimally tile a band of two consecutive lines with disjoint 2x2 blocks: the
  band needs `2k` stars and the tiling gives `t` blocks each capped at one, so at most `t − 2k`
  blocks may be empty. Zero slack ⇒ every block is starred.
- **Soundness** — Pigeonhole over disjoint sets with proven per-set capacity 1 and an exact
  total. Declaring a block starred happens only when leaving it empty is arithmetically impossible.
- **Concludes** — Places stars, eliminates cells via the resulting mini-containers.
- **Data** — Two-row band → disjoint 2x2 tiling (**both offset variants must be tried**),
  per-block candidate counts, slack counter.
- **k-note** — Slack is `⌈N/2⌉ − 2k` for an N-wide band. Tightest for large k and small N. On a
  **10x10 2-star board slack is exactly 1** — the classic case, and directly relevant to our
  Phase 1 target size. On 10x10 1-star, slack is 3 and it rarely fires.

---

## TIER 5

### 20. `pressuredShapeExclusion` — Pressured Exclusion
*Named 2-star instances: Pressured Ts, Kissing Ls, The M.*

- **Description** — An exclusion that does not hold from shape alone but does once an external
  fact is present — a star, or a line-confined region already claiming the same line. Famous
  case: a T-tetromino whose 1x3 bar shares a line with an existing star holds at most one star.
- **Soundness** — The external fact reduces the shape's proven capacity below its geometric
  capacity, so the shape's effective quota is an exact, soundly-derived number; every
  elimination is then an ordinary capacity-versus-requirement infeasibility.
- **Concludes** — Eliminates cells; unblocks otherwise-uninformative squeezes.
- **Data** — Shape-pattern matcher over region candidate sets (tetromino/pentomino
  classification), plus "line already claimed / line saturated" flags.
- **⚠ k-note** — Kissing Ls, The M and Pressured Ts are documented as **2-star-only** patterns.
  Their k=1 and k=3 analogues have different capacity arithmetic. **Do not port them.**

### 21. `fish` — Fish / N-Set
*Named after the Sudoku X-Wing/Swordfish family.*

- **Description** — If across `n` columns every surviving candidate lies within the same `n`
  rows, those rows' entire star supply comes from those columns, so all cells in those rows
  outside the `n` columns are eliminated. Symmetric with rows/columns swapped.
- **Soundness** — The `n` columns hold exactly `n·k` stars, all confined to the `n` rows, which
  demand exactly `n·k`. Containment plus equal cardinality forces the sets to coincide.
- **Concludes** — Eliminates cells.
- **Data** — Per-column candidate row-masks and per-row candidate column-masks; enumerate
  n-subsets and test whether the union of masks has size `n`. Practical for n = 2, 3.
- **Relationship** — `fish` is line-to-line; #16/#17 are region-to-line. Humans name them
  differently and they fire on different data. **Keep them separate.**

### 22. `placementEnumeration` — Pair (k-tuple) Enumeration
- **Description** — Enumerate every legal `k`-tuple of pairwise-non-adjacent candidates for a
  region or line, discard tuples violating any current quota or adjacency fact, then intersect
  what survives: cells in no surviving tuple are eliminated, cells in all are stars, lines used
  by all surviving tuples are claimed.
- **Soundness** — The true solution's stars inside the unit form one of the enumerated tuples
  (enumeration is exhaustive over the surviving candidate set, which still contains all true
  stars), so a cell absent from every surviving tuple is absent from the true solution.
- **Concludes** — Eliminates cells, places stars, and yields "region confined to rows {a,b}"
  facts feeding #16.
- **Data** — Per-region candidate list, non-adjacency graph, combination generator, per-cell hit
  counter across surviving tuples. Cheap for k=1,2; k=3 on a large region needs pruning.
- **⚠ Not guessing** — It evaluates all branches and keeps only what is invariant across them;
  it never commits to one branch. It is the exhaustive-case-analysis cousin of #7.

### 23. `setDifferentials` — Set Differentials
- **Description** — Add and subtract whole units with known exact totals (rows + columns −
  regions) to synthesize an arbitrary cell region whose star count is exactly computable — most
  usefully a region computed to hold exactly zero, which is then wholly eliminated.
- **Soundness** — Star counts are additive over disjoint cell sets and every input total is an
  exact quota, so the resulting count is an exact fact about the true solution.
- **Concludes** — Eliminates cells (zero-count regions), places stars (when a synthesized count
  saturates a small set).
- **Data** — Signed multiset of unit cell sets with per-cell coefficient accumulation (integer
  coefficient grid), plus normalization discarding coefficient-0 cells and flagging coefficient>1
  cells for inclusion–exclusion correction.
- **⚠ CORRECTNESS WARNING** — Valid only when overlaps are correctly accounted. A cell counted
  twice must have its double-count subtracted, or the derived total is wrong and the rule
  becomes **unsound**.

---

## TIER 6

### 24. `finnedCounting` — Finned Counts
*Alt: Finned Undercounting / Finned Overcounting, Forced-Line Count, Line Saturation.*

- **Description** — A near-miss #16/#17 configuration that fails only because of one extra "fin"
  cell is repaired by hypothesis: if starring the fin would push too many stars into an
  undercounted area (or too few into an overcounted one), the fin is eliminated and the clean
  count then applies.
- **Soundness** — One-ply refutation whose contradiction is an exact counting identity:
  `star(fin) ⇒ some unit's exact quota is violated`, therefore `¬star(fin)`. The contradiction
  comes from equalities over quotas, not a heuristic.
- **Concludes** — Eliminates cells (the fin), unlocking #16/#17.
- **Data** — The #16/#17 subset enumerator extended to report near-misses (coverage overflow of
  exactly one or two cells), plus per-fin one-ply count re-evaluation.

### 25. `forcingChainRelay` — Relay / Cannot-Both Chains
*Alt: Relay, Either-Or (divergent form), Constraint Pairs, chain reasoning.*

- **Description** — Build the implication graph over candidates (`star(a) ⇒ ¬star(b)` from
  adjacency and shared units; `¬star(b) ⇒ star(c)` when `b`,`c` are a unit's last two
  candidates) and follow chains. A cell whose chain reaches `star(x) ∧ ¬star(x)` is eliminated,
  without ever committing to a branch.
- **Soundness** — Every edge is an individually sound implication from a quota or from no-touch,
  so any conclusion by transitivity is a valid theorem about all solutions. A cell eliminated by
  self-contradiction is false in every solution.
- **Concludes** — Eliminates cells; occasionally places, when both branches of a strong link
  force the same star.
- **Data** — Implication graph with strong links (unit with exactly two survivors ⇒
  biconditional) and weak links (adjacency / shared unit ⇒ not-both); traversal with cycle and
  contradiction detection.
- **⚠ Boundary note** — Bound chain length (4–6 links) or this degrades into `deepLookAhead` in
  practice while remaining formally sound.

---

## EXCLUDED — do not implement

### `deepLookAhead` — Look-Ahead / Contradiction Chains  **(backtracking)**
*Alt: Contradiction Testing, Trial and Error, Candidate Testing, bifurcation, Nishio.*

Hypothesize a star, propagate many plies deep (possibly to completion or to a nested
hypothesis), and either eliminate on contradiction or — degenerately — keep the branch that
works. The *refutation* form is logically sound; the *selection* form is **not a deduction at
all**, it is search, and a solver committing to a branch without refuting the alternative can
land on a non-star whenever the puzzle admits more than one solution or propagation is incomplete.

**Decision: exclude entirely.** Its sound depth-1 fragment is already #14; its bounded-chain
fragment is #25. A puzzle that cannot be finished without it is outside the human-simile
solver's declared difficulty envelope and must be **rejected at generation time** (PROP-2).

> Note: every general-purpose Star Battle solver found on GitHub (backtracking, CLP(FD), CSP,
> quantum-annealing) is of this kind and contains **no** named human strategies. That avenue was
> checked and came up empty — do not expect to mine technique names from open-source solvers.

### `uniquenessAssumption` — Uniqueness Arguments  **(unsound as pure logic)**
*Alt: By a Thread, At Sea, By a Thread at Sea; Sudoku's Unique Rectangle analogue.*

Reject a placement because it would leave two mutually swappable star configurations, on the
grounds that a published puzzle has exactly one solution.

**This family is not sound as pure logic.** Its premise is metadata about the puzzle (that it
was authored to be unique), not a consequence of the rules. On a puzzle with multiple solutions,
or on a partially-specified position, it eliminates cells that are stars in a valid solution.

**Decision: exclude.** It also directly contradicts P3 — a hint built on "the app promises this
is unique" teaches nothing about the puzzle's logic. If ever enabled, it must be gated behind an
explicit `assumesUniqueSolution` flag and never presented as a rules-derived deduction.

---

## How the meaning changes with k

| Technique | k = 1 | k = 2 | k = 3 |
|---|---|---|---|
| `unitForcedFill` | one survivor is the star | two survivors, and they must be non-adjacent; a 3-cell line region forces the two **outer** cells | needs ≥ `2k−1 = 5` cells in a connected strip; a 5-strip forces cells 1, 3, 5 |
| `twoByTwoCap` | cap always 1; a region fitting one 2x2 immediately gives a star | cap unchanged, tiling must reach 2 blocks | cap unchanged; minimum region size grows, tiny regions impossible |
| `crowdingExclusion` | essentially vacuous within one unit | primary firing case | fires constantly; capacity very tight |
| `regionLineConfinement` | region in one row ⇒ all of that row's quota consumed | must distinguish full claim from partial claim (row keeps 1) | up to three partial-claim levels; becomes a counter, not a boolean |
| `containerConsumption` | degenerates to #8/#9 | "the rest may hold at most one other" | general `quota − m`; three-way splits |
| `clumpPartition` | vacuous in an unsplit region | 2 clumps ↔ 2 stars, standard | 3 clumps ↔ 3 stars |
| `bandSqueeze` | slack large, rarely fires on a 10-wide band | **slack 1 on a 10-wide band — the classic case** | slack 0 or negative on narrow bands; fires very strongly |
| `pressuredShapeExclusion` | must be re-derived | as published (2-star patterns) | must be re-derived |
| `placementEnumeration` | trivial (single cells) | "pair enumeration", standard | triples; needs pruning |
| `regionsWithinLines` / `linesWithinRegions` / `fish` | totals `n` | totals `2n` | totals `3n`; rule shape identical |

---

## Solver architecture implications

1. **Strict tier ordering with fixpoint re-entry.** Run tiers in order, and re-run tier 1 to
   fixpoint after every higher-tier hit — #1–#3 are cheap and cascade. This is also what makes
   PROP-3 deterministic (see risk E5).
2. **A derived-fact registry is required, not optional.** #4, #11 and #23 are *fact producers*,
   not eliminators. #7, #13, #18 and #20 consume premises produced elsewhere. The registry holds
   `cellSet → exactCount`, `cellSet → atLeastOneStar`, `line → claimedByRegion`.
3. **The registry is where the inductive soundness argument lives.** If every entry is added
   only by a rule from #1–#25, every elimination in the whole run is sound. PROP-4 should assert
   exactly this, per entry, against the known solution.

---

## Sources

**Substantive — these carried the catalogue:**

1. <https://kris.pengy.ca/starbattle> — Kris De Asis, "A Star Battle Guide". By far the most
   rigorous published taxonomy: Basics / Counting / Uniqueness / Idiosyncrasies.
2. <https://krazydad.com/twonottouch/adv_tutorial/> — KrazyDad, Two Not Touch Advanced Tutorial.
   Source of the most-recognized community names, with worked diagrams.
3. <https://zavija.com/how-to-solve> — explicit T0–T5 tiering that maps almost 1:1 onto ours.
4. <https://tryhardpuzzles.com/blog/star-battle-strategies> — Beginner/Intermediate/Expert
   grouping; clean statement of Fish.

**Moderately useful:**

5. <https://www.thepuzzlelabs.com/star-battle/how-to-solve-2-star-battle-puzzles>
6. <https://krazydad.com/twonottouch/med_tutorial/>
7. <https://meowsolver.com/star-battle-solver> — hint-engine list separating 1-star and 2-star ladders.
8. <http://www.clarity-media.co.uk/puzzleblog/how-solve-star-battle-strategy>
9. <https://puzzolve.com/intel/star-battle-basics>
10. <https://krazydad.com/how-to-solve-star-battle/>

**Thin or unusable (recorded so the avenue is not re-checked):**

11. <https://www.gmpuzzles.com/blog/star-battle-rules-and-info/> — rules and history only, **no
    techniques**, despite being the most-cited Star Battle authority.
12. `puzzles.wiki` and `starbattle.gg` — HTTP 403, not retrievable.
13. `cross-plus-a.com` Star Battle page — 404, no longer exists.
14. GitHub solvers (mmachenry/star-battle, KeatonMueller/starbattle, norvig/pytudes,
    cosmologicon/constraint-examples, spratapsi/battle_star) — all CLP(FD)/CSP/backtracking/
    annealing. **None enumerate named human strategies.**
15. <https://www.braingle.com/games/starbattle/instructions.php> — contributed only names
    already covered.
