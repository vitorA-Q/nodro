# Tents & Trees — Human deduction technique catalogue

Research output, Phase 0. Implementation spec for `lib/engine/puzzles/tents/techniques/`.

**Structural summary.** Tents & Trees is a **bipartite matching problem wearing a Nonogram
costume**: the tree↔candidate-cell graph must admit a tree-saturating matching, while the
no-touching rule and the row/column counts act as side constraints pruning the graph. Nearly
every published "technique" is a specialisation of one of five principles:

1. a cell must be supportable by some unmatched tree;
2. tents occupy an exclusive 3x3 halo;
3. line counts bound tents per line;
4. Hall's marriage condition on sets of trees;
5. invariance across all valid completions of a line.

**Best source by a very wide margin:** Simon Tatham's `tents.c`, which contains a ~180-line
design essay proving results about unique perfect matchings adapted from Hall's Marriage
Theorem, plus the full solver with verbatim rule comments and an explicit Easy/Tricky rule
split. Note the brief's premise was wrong: **Conceptis has no Tents techniques page** (404;
they publish tiered guides for Sudoku/Kakuro/Hashi/Nurikabe but not Tents).

---

## Summary table

| # | id | name | tier | concludes |
|---|---|---|---|---|
| 1 | `zeroCountLine` | Zero Line / Zero Rule | 1 | grass |
| 2 | `countSatisfiedLine` | Count Satisfied | 1 | grass |
| 3 | `cellNotAdjacentToTree` | Unreachable Cell | 1 | grass |
| 4 | `treeSingleCandidate` | Forced Tent / Lonely Tree | 2 | tent + pairing |
| 5 | `tentAdjacencyExclusion` | No-Touch Halo | 2 | grass |
| 6 | `tentSingleUnmatchedTree` | Forced Pairing from Tent Side | 2 | pairing |
| 7 | `matchedTreeReleasesCells` | Spent Tree | 2 | edge removal → grass |
| 8 | `treeDiagonalPairCorner` | Diagonal Separation | 2 | grass |
| 9 | `lineFreeEqualsRemaining` | Line Capacity Check / Exact Fit | 3 | tent |
| 10 | `candidateSetCommonNeighbour` | Common Neighbour of a Forced Set | 3 | grass |
| 11 | `lineSegmentPacking` | Segment Saturation / Alternating Fill | 3 | tent + grass |
| 12 | `twoByTwoCapacity` | 2x2 Rule / Two-Row Analysis | 3 | grass (+ contradiction) |
| 13 | `hallTightTreeSet` | Hall Set / Tree Set Analysis | 4 | tents + edge removal |
| 14 | `hallDualCellSet` | Reverse Hall / Cell-Set Cap | 4 | grass + edge removal |
| 15 | `componentBalance` | Component Count Balance | 4 | exact count on a cell set |
| 16 | `treePairSharedCandidates` | Two-Tree Pair Argument | 5 | tents + edge removal |
| 17 | `forcedPairingExclusion` | Claimed Tent / Y-Needs-Another | 5 | edge removal → cascade |
| 18 | `countMatchingInteraction` | Count x Matching Cross-Talk | 5 | tent, grass |
| 19 | `lineEnumerationInvariant` | Line Enumeration | 6 | tent, grass |
| 20 | `lineEnumerationNeighbourSpill` | Cross-Line Spillover | 6 | grass |
| 21 | `matchingRelevanceFilter` | Augmenting-Path Edge Filter | 6 | tent, grass, pairing |
| 22 | `countAwareRelaxationFilter` | Global Relaxation / IP Bound | 7 | grass (+ contradiction) |

Three techniques (#8, #10, #12) are geometric rather than count- or matching-based, so they
don't map perfectly onto the tier definitions. They are placed by **cost and sophistication**,
which is what the tier ladder actually encodes.

---

## TIER 1

### 1. `zeroCountLine` — Zero Line
*Alt: Zero Rule, "0 clue", Nullzeile.*
- **Description** — Every undetermined cell in a line whose clue is 0 (or whose remaining count
  has dropped to 0) is grass.
- **Soundness** — A line with clue 0 contains zero tents in *every* solution by direct rule.
- **Concludes** — grass.
- **Data** — `rowRemaining[]`/`colRemaining[]`; cell-state grid. No graph needed.

### 2. `countSatisfiedLine` — Count Satisfied
- **Description** — Once a line contains as many placed tents as its clue, every remaining
  undetermined cell in that line is grass.
- **Soundness** — The clue is an exact equality, not a lower bound, so any additional tent
  violates a constraint the true solution satisfies.
- **Concludes** — grass.
- **Data** — remaining counters decremented on each tent placement.

### 3. `cellNotAdjacentToTree` — Unreachable Cell
*Alt: Tree Proximity Filtering, orphan cell.*
- **Description** — A cell with no orthogonally adjacent *unmatched* tree cannot be a tent.
- **Soundness** — Every tent is matched to an orthogonally adjacent tree; with no adjacent tree —
  or all adjacent trees provably matched elsewhere — the cell has no possible partner.
- **Concludes** — grass.
- **Data** — `supporters[cell] → set of unmatched trees`; 4-neighbour masks; `pairOfTree[]`.
- **⚠ Trap** — The naive version ("no adjacent tree at all") is safe but weak; the strong version
  ("no adjacent *unmatched* tree") is only sound if the pairing marks are themselves sound.
  **Converse fallacy:** a tent may legally be orthogonally adjacent to *several* trees — it
  merely *serves* one. Tatham calls this the single most commonly mis-stated rule in published
  Tents rulesets.

---

## TIER 2

### 4. `treeSingleCandidate` — Forced Tent / Lonely Tree
- **Description** — If exactly one of a tree's four orthogonal neighbours is still a possible
  tent site, that cell is a tent, paired with this tree.
- **Soundness** — Every tree is matched to exactly one adjacent tent; with one surviving
  neighbour the solution's tent must be there. The rule only *places*, so it can never erase.
- **Concludes** — places a tent **and** fixes the pairing.
- **Data** — `cand[tree] → bitset`, maintained incrementally; `pairOfTree[]`, `pairOfTent[]`.
- **⚠ CRITICAL TRAP** — The candidate set must count cells **already marked TENT but not yet
  matched**, not just blank cells. Tatham's condition is literally `{unattached tent, BLANK}`.
  Counting blanks only will place a second tent next to a tree that already had one — **unsound**.

### 5. `tentAdjacencyExclusion` — No-Touch Halo
- **Description** — All eight neighbours of a placed tent are grass.
- **Soundness** — Direct restatement of a hard constraint: tents never touch, even diagonally.
- **Concludes** — grass.
- **Data** — 8-neighbour masks. Highest-yield propagation in the game; run to fixpoint after
  every tent placement.

### 6. `tentSingleUnmatchedTree` — Forced Pairing from the Tent Side
- **Description** — A placed tent with exactly one unmatched orthogonally adjacent tree must be
  matched to that tree.
- **Soundness** — Each tent is matched to exactly one adjacent tree; with one such tree
  unmatched the assignment is forced. Marks no cell at all, so it cannot erase a tent.
- **Concludes** — fixes a pairing only.
- **Data** — `supporters[cell]`, `pairOfTent[]`, `pairOfTree[]`.
- **Note** — Tatham runs this *before* every other rule and even at his lowest difficulty,
  because pairings unlock #3 and #7.

### 7. `matchedTreeReleasesCells` — Spent Tree
- **Description** — Once a tree is matched, it is removed as a supporter from every *other*
  adjacent cell; cells left with no supporter become grass (via #3).
- **Soundness** — The correspondence is a bijection, so a matched tree cannot also partner
  another cell. Removing that edge cannot remove the solution's own edge, which is the one kept.
- **Concludes** — edge removal, cascading into grass and further forced tents.
- **Data** — `cand[tree]`, `supporters[cell]`, `pairOfTree[]`, plus a dirty-cell worklist.

### 8. `treeDiagonalPairCorner` — Diagonal Separation
*Tatham, verbatim: "If there are two possible places where this tree's tent can go, and they are
diagonally separated rather than being on opposite sides of the tree, then the square (other than
the tree square) which is adjacent to both of them must be a non-tent."*
- **Description** — A tree with exactly two candidates at right angles (one horizontal, one
  vertical) forces the corner cell completing the 2x2 square to be grass.
- **Soundness** — One of the two candidates is certainly this tree's tent, and the corner is
  orthogonally adjacent to both, so a tent there would touch a tent in either scenario.
- **Concludes** — grass.
- **Data** — `cand[tree]` with direction information; 8-neighbour masks.
- **Note** — This is one of only two rules Tatham gates behind `DIFF_TRICKY`; it is the geometric
  rule separating his Easy from his Tricky generator (the other is #20).

---

## TIER 3

### 9. `lineFreeEqualsRemaining` — Line Capacity Check / Exact Fit
- **Description** — If the number of still-undetermined tent-capable cells in a line equals that
  line's remaining tent count, every one of those cells is a tent.
- **Soundness** — The clue is an exact equality and the remaining tents must all land in the
  surviving cells. Places tents only, so it can never erase one.
- **Concludes** — places tents (often followed immediately by #6 fixing pairings).
- **Data** — remaining counters plus per-line undetermined-cell lists, refreshed via a dirty-line
  flag.

### 10. `candidateSetCommonNeighbour` — Common Neighbour of a Forced Set
*Alt: domino elimination; "pointing pair" by analogy with Sudoku.*
- **Description** — If a set C of cells is known to contain at least one tent (canonically
  C = a tree's full candidate set), any cell 8-adjacent to *every* member of C is grass.
- **Soundness** — Whichever member of C holds the tent, a tent in the common neighbour would
  touch it.
- **Concludes** — grass.
- **Data** — `cand[tree]`; bitwise AND over the halos of C's members.
- **⚠ This one rule subsumes three separately-published techniques** — implement the general form
  once, not three times:
  - C = two horizontally adjacent cells ⇒ four cells eliminated (Puzzler's pair rule)
  - C = three in a line ⇒ two cells eliminated, above and below the middle (Puzzler's 1x3 rule)
  - C = two cells at right angles ⇒ one cell eliminated (#8 above)

  Keep #8 as a fast path since it produces a better hint message.

### 11. `lineSegmentPacking` — Segment Saturation / Alternating Fill
- **Description** — A maximal run of `n` consecutive undetermined cells holds at most `⌈n/2⌉`
  tents. If a line's remaining count equals the sum of its runs' caps, every run is saturated,
  and each **odd-length** run is forced into the unique alternating pattern starting at its first
  cell.
- **Soundness** — Two tents in the same line cannot be orthogonally adjacent, so the cap holds in
  every solution. When caps sum exactly to the requirement, the true solution must achieve every
  cap, and for odd `n` the alternating pattern is the unique way.
- **Concludes** — places tents and grass. **Even-length saturated runs yield no cell-level
  conclusion** — only odd runs force.
- **Data** — per-line run decomposition (recomputed on line dirty); remaining counters.
- **Note on why it's sound** — The `⌈n/2⌉` bound uses in-line adjacency only, ignoring diagonal
  conflicts with neighbouring lines. That makes it a *relaxation* — an upper bound — which is
  exactly why it is sound: relaxations over-estimate capacity, never under-estimate it, so they
  can never wrongly declare a cell grass.

### 12. `twoByTwoCapacity` — 2x2 Rule / Two-Row Analysis
- **Description** — Any 2x2 block holds at most one tent, giving `clue(r) + clue(r+1) ≤ ⌈w/2⌉`
  for adjacent rows (and the transpose for columns). When the bound is tight, tent columns in the
  two rows are forced into one column per block-pair.
- **Soundness** — All four cells of a 2x2 lie within each other's 8-neighbourhoods, so at most
  one can be a tent. Tiling the strip into disjoint 2x2 blocks yields a valid upper bound.
- **Concludes** — grass when tight; otherwise a contradiction detector for validating generated
  puzzles.
- **Data** — remaining counters, cell-state grid. Cheap; good first-pass sanity check in the
  generator.

---

## TIER 4 — Hall's Marriage Theorem (the heart of the puzzle)

### The argument in plain terms

Build a bipartite graph. Left: one vertex per **unmatched tree**. Right: one vertex per
**candidate cell** — still undetermined (or already a tent but unmatched) and orthogonally
adjacent to at least one unmatched tree. Edge = tree can use that cell.

The defining rule says: in the solution, every tree gets its own private cell, and no two trees
share one. In graph terms, **the solution contains a matching that saturates every tree**.

Hall's Marriage Theorem: such a matching exists **iff** for every set S of trees, the number of
distinct cells those trees can collectively reach is at least `|S|`. The intuition to put in the
UI: *three trees that between them can only reach two cells is hopeless, because two cells cannot
give three trees a private cell each.*

The solving power comes from the boundary case. When a set S of `k` trees reaches exactly `k`
cells — a **tight Hall set** — the matching is forced to be a bijection onto all of them. So
**all `k` cells are tents**, and **no tree outside S may use any of them**. This is the direct
analogue of a naked subset in Sudoku, and Tatham explicitly names the connection.

### 13. `hallTightTreeSet` — Hall Set / Tree Set Analysis
- **Description** — If a set S of `k` unmatched trees has combined candidate neighbourhood
  `N(S)` of exactly `k` cells, every cell of `N(S)` is a tent and every tree outside S loses all
  edges into `N(S)`.
- **Soundness** — The trees must be matched injectively into their candidates, so S's `k` trees
  occupy `k` distinct cells of `N(S)`; with `|N(S)| = k` this exhausts it. Note the rule **places
  tents and removes edges only, never marks grass directly**, which makes it structurally
  incapable of erasing a solution tent.
- **Concludes** — places tents **and** removes edges.
- **Data** — `cand[tree]` and `supporters[cell]` as bitsets; for enumeration either bounded
  subset search over `k ≤ 3–4`, or (strongly preferred) Hopcroft–Karp plus Dulmage–Mendelsohn
  decomposition, whose diagonal blocks *are* the strong Hall components.
- **Contradiction form** — `|N(S)| < |S|` is a **Hall violation**: immediate contradiction, used
  to reject a hypothesis during generation or flag a corrupt board.

### 14. `hallDualCellSet` — Reverse Hall / Cell-Set Cap
- **Description** — For any set C of cells, the number of tents inside C is at most the number of
  distinct trees adjacent to C. When the cap is met exactly, those trees are consumed inside C
  and cannot serve any cell outside C.
- **Soundness** — Each tent inside C must be matched to a distinct tree adjacent to C, a valid
  upper bound in every solution; when tight, the outside edges are genuinely impossible.
- **Concludes** — grass (combined with a line count that would exceed the cap) and edge removal.
- **Data** — `supporters[cell]` bitsets; union-of-supporters accumulator; per-line cell lists.
- **⚠ ASYMMETRY WARNING** — **Cells are not required to be saturated.** Only the tree side must
  be matched. So the dual rule yields an *upper bound* on tents in a cell set, **not** "all these
  cells are tents." Getting this asymmetry wrong is the most likely way to write an unsound Hall
  rule.

### 15. `componentBalance` — Component Count Balance
- **Description** — Within each connected component of the tree↔candidate-cell graph, the number
  of tents among that component's cells equals exactly the number of trees in it.
- **Soundness** — No edge leaves a component, so every tree in it is matched inside it and every
  tent among its cells is matched to a tree inside it. The counts are equal in the true solution,
  making the derived count **exact** rather than merely bounding.
- **Concludes** — an exact tent count on a cell subset — extremely powerful fed into line
  counting (#18). Degenerates to #13 when #cells = #trees.
- **Data** — DSU/union-find over trees and candidate cells, maintained incrementally as edges are
  removed.
- **⚠ Caveat** — Tatham proves this criterion is **necessary but not sufficient** for a matching
  to exist (counterexample: three trees whose neighbourhood structure balances but no matching
  exists). It is fully sound as a deduction; it just does not catch everything. **Do not use it
  as the only feasibility check.**

---

## TIER 5

### 16. `treePairSharedCandidates` — Two-Tree Pair Argument
- **Description** — If two unmatched trees have candidate sets whose union is exactly two cells,
  both cells are tents, exclusively owned by those two trees.
- **Soundness** — Two trees need two distinct cells and only two exist between them. Places tents
  and strips edges only, so it can never mark grass over a solution tent.
- **Concludes** — places two tents **and** removes edges from all other trees. Also a
  contradiction detector: if the two cells touch each other, the board is inconsistent.
- **Data** — `cand[tree]` bitsets; pairwise scan restricted to trees with `|cand| ≤ 2`, keeping it
  O(T·4) rather than O(T²).
- **Why keep it separately from #13** — It is a strict special case, but it is the case a human
  actually spots, so it produces a far better hint ("these two trees can only use these two
  cells") than a generic Hall-set report.

### 17. `forcedPairingExclusion` — Claimed Tent
- **Description** — When a tent is provably matched to tree X, every other tree adjacent to that
  tent loses it as an option and must find a different candidate — often collapsing another tree
  to a single candidate.
- **Soundness** — Bijection: a tent already assigned to X cannot also serve Y. Deleting the
  (Y, tent) edge cannot delete the solution's own edge for Y, which by definition points
  elsewhere.
- **Concludes** — edge removal, cascading into #4 and #3.
- **Data** — pairing arrays, `cand`, `supporters`, propagation worklist.

### 18. `countMatchingInteraction` — Count x Matching Cross-Talk
- **Description** — Take an exact tent count derived from a component or Hall set (#13–#15) and
  subtract it from the remaining count of any line the region sits inside, then apply the
  tier-1/3 line rules to what is left.
- **Soundness** — Both inputs are exact statements true of the solution — "this component's cells
  hold exactly T tents" and "this row holds exactly k tents" — so their difference is also true.
- **Concludes** — places tents and grass.
- **Data** — DSU component → cell lists indexed by row and column; remaining counters.
- **Note** — **This is the most under-implemented technique in hobbyist solvers and is where most
  of the "hard" difficulty tier actually lives.**

---

## TIER 6

### 19. `lineEnumerationInvariant` — Line Enumeration
*Tatham: "For each row and column, we go through all possible combinations of locations for the
unplaced tents, rule out any which have adjacent tents, and spot any square which is given the
same state by all remaining combinations."*
- **Description** — Enumerate every way of placing the line's remaining `k` tents among its `n`
  free cells subject to all *necessary* filters, and fix any cell taking the same value in all
  surviving arrangements.
- **Soundness** — The true solution's restriction to this line is one of the enumerated
  arrangements, **provided every filter used is a necessary condition**. A value shared by all
  arrangements is therefore the solution's value.
- **Concludes** — places tents and grass.
- **Data** — per-line free-cell index list, a combination iterator, and a merge buffer initialised
  to a sentinel then collapsed to "unknown" on first disagreement.
- **⚠⚠ THE MOST DANGEROUS TECHNIQUE IN THE CATALOGUE FOR SOUNDNESS.** Every filter applied during
  enumeration must be a *necessary* condition. Filtering out an arrangement using a heuristic, an
  assumption of uniqueness, or a not-quite-right adjacency test **silently deletes the true
  arrangement**, and the merge will then confidently mark grass where the solution has a tent.
  Tatham keeps his filter minimal on purpose — he checks only in-line adjacency, noting that
  cross-line conflicts "will have been dealt with already by other parts of the solver."
  **Cap `n` at roughly 12–14 free cells** so this remains a technique rather than an exponential
  search.

### 20. `lineEnumerationNeighbourSpill` — Cross-Line Spillover
*Tatham gates this behind `DIFF_TRICKY`: "In Easy mode, we don't look at the effect of one row on
the next."*
- **Description** — If every valid arrangement of line L puts some tent 8-adjacent to cell X in
  an adjacent line, X is grass.
- **Soundness** — The solution's arrangement of L is among those enumerated, so in the solution X
  is adjacent to a tent of L, and no-touching forces X to grass.
- **Concludes** — grass.
- **Data** — the #19 enumeration plus two extra merge buffers for the lines above and below,
  seeded to BLANK and stamped NONTENT across each placed tent's three-cell shadow.
- **Note** — Together with #8, this is precisely what separates Tatham's Easy from his Tricky
  generator. **A strong, cheap, well-tested difficulty knob — recommended as the headline tier-6
  rule.**

### 21. `matchingRelevanceFilter` — Augmenting-Path Edge Filter
- **Description** — Compute a maximum matching of the tree↔candidate graph. Any cell used by
  **no** tree-saturating matching is grass; any cell used by **every** such matching is a tent;
  any edge in no such matching is a dead pairing.
- **Soundness** — The solution's own tree↔tent assignment *is* a tree-saturating matching in the
  current candidate graph, so a cell in no such matching cannot be a solution tent, and a cell in
  every such matching must be one. Direct logical consequence, **no hypothesis or lookahead**.
- **Concludes** — places tents, places grass, and fixes pairings — all three.
- **Data** — Hopcroft–Karp matching state plus alternating-path reachability marks (or full
  Dulmage–Mendelsohn decomposition). One HK run is O(E√V); classification is O(V+E) afterwards.
- **⚠ This rule dominates all of tiers 4 and 5 combined.** Every grass mark and every tent any
  Hall-set argument can produce is also produced here, in one polynomial pass, without
  enumerating subsets. **Keep #13–#16 anyway — for *explanation*.** "These three trees can only
  reach these three cells" is a hint a human understands; "no maximum matching uses this cell" is
  not. Extract the human-readable witness from the DM decomposition's strong Hall components.
- **⚠ Do NOT extend this** into "assume edge (T,c), propagate the halo, see if a matching still
  exists." That is a one-ply hypothesis test — see the exclusion list.

---

## TIER 7

### 22. `countAwareRelaxationFilter` — Global Relaxation Filter
- **Tier 7 honestly stated:** **there is no exact polynomial technique here, and there cannot be**
  — Tents with hints is NP-complete (De Biasi, 2012, by reduction from 3-SAT). Anything at tier 7
  is a sound *relaxation* or a bounded search, not a complete rule.
- **Description** — Solve a relaxation coupling the matching constraint with the row/column counts
  (LP relaxation, or matching plus per-line capacity bounds propagated to fixpoint) and eliminate
  any cell whose forced value makes the relaxation infeasible.
- **Soundness** — A relaxation admits *every* real solution as a feasible point, so infeasibility
  under "cell c is a tent" proves no real solution has a tent at c.
- **Concludes** — grass; also detects global contradictions.
- **Data** — full bipartite graph, remaining counters, and an LP/IP or a fixpoint engine over
  #1–#21.
- **⚠ Why counts do not fold into a flow network** — A tent consumes one unit of its row's budget
  *and* one unit of its column's budget, and a single flow unit cannot split in two. The combined
  problem is genuinely an integer program, not a matching. **Be honest about this rather than
  shipping a "flow solver" that quietly drops one of the two count families.**

---

## Matching: complexity and what our solver should do

**The tree↔tent matching is polynomial.** Hopcroft–Karp is O(E√V). Our instances are tiny and
sparse: a tree has at most 4 candidate cells, so `E ≤ 4T` and `V = O(T)`. A 20x20 board with ~80
trees is a few thousand operations — microseconds. Classifying every edge as "in some / every /
no maximum matching" is one further O(V+E) alternating-path sweep, or a Dulmage–Mendelsohn
decomposition whose diagonal blocks are exactly the strong Hall components.

**⚠ A subtlety in Tatham's essay that must not be misread.** Tatham proves that a bipartite graph
with a *unique* perfect matching can always be resolved by naive greedy peeling, and concludes he
can "be reasonably confident that... it will not need to do anything complicated like set analysis
between trees and tents." **That conclusion is correct for his problem** — determining the matching
once tent positions are known. **It does not transfer to ours.** During solving, the right-hand
side is the set of *candidate cells*, a strict superset of the tents; that graph has many perfect
matchings, greedy peeling stalls almost immediately, and Hall set analysis is exactly what breaks
the deadlock. Tatham gets away without it because his row/column enumeration (#19–#20) happens to
cover the cases his generator produces. A solver strictly stronger than his — which a 7-tier
human-simile solver implies — **needs the matching machinery**.

### Recommended architecture

1. Make #1–#8 a tight incremental fixpoint loop with a dirty-cell worklist. These do 80–90% of the
   work on easy and medium boards and must be fast.
2. Maintain `cand[tree]` and `supporters[cell]` as **bitsets from the start**. Nearly every
   tier-3-and-up technique reads them; rebuilding them per-rule is what makes naive solvers slow.
3. At tier 4+, run Hopcroft–Karp once per fixpoint round and use the relevance classification
   (#21) as the engine. Then use the DM strong Hall components to **name** the deduction for the
   user, reporting the smallest tight set as a tier-4 or tier-5 hint. **This gives tier-6 strength
   with tier-4 explainability — the best of both, and exactly what P3 needs.**
4. Keep explicit small-k Hall enumeration (`k ≤ 3`) as a fast pre-pass; cheaper than an HK run and
   fires often.
5. **Use brute-force search only in the generator**, for uniqueness verification, never in the
   hint path.

### Difficulty calibration — adopt Tatham's method for PROP-3

A puzzle is **difficulty d iff the solver succeeds with tiers ≤ d and fails with tiers ≤ d−1**.
Tatham's code does literally this (`tents_solve(..., diff-1)` must fail, `tents_solve(..., diff)`
must succeed). It is a clean, proven design and maps directly onto our tier ladder. **This is a
better formulation of PROP-3 than "max tier used"** — it is a two-sided test, so it also catches
the case where a technique is invoked but was not actually necessary.

---

## PROP-6 / Minimality — ⚠ MAJOR FINDING

**A Tents puzzle with all its row and column counts is NEVER minimal — and this is provable, not
empirical.**

The number of tents equals the number of trees, and the trees are visible on the board. So:

> Σ(all row counts) = Σ(all column counts) = number of trees

That identity means **any single row count is recoverable from the other row counts plus a tree
count**. Remove row clue `r₃` and the solver simply computes it as `#trees − Σ(other row clues)`.
The information content is unchanged, so uniqueness is unchanged. The same holds for any single
column clue. And **one row clue and one column clue can be removed simultaneously**, each
recovered from its own axis's identity.

Therefore a standard Tents instance always has **at least two strictly redundant clues**, and the
strict PROP-6 condition is **never satisfiable** by a fully-clued Tents puzzle.

**If the app tests minimality naively — drop each clue in turn, re-solve, check uniqueness — every
puzzle will report at least two removable clues and we would wrongly conclude the generator is
sloppy.**

### Recommended definition: minimality modulo the two sum identities

Designate one row clue and one column clue as derived-by-convention (say the last of each),
exclude them from the removal test, and require that no clue among the remaining `2n − 2` can be
dropped without losing uniqueness. Equivalently: measure "clue economy" as the size of the
smallest uniqueness-preserving subset, and note its **ceiling is `2n − 2`, not `2n`**.

### Beyond the first two, removal usually bites — but less often than expected

- A **0 clue is almost never removable.** Highest-information clue type; wipes an entire line.
- **Clues near the packing bound** (close to `⌈L/2⌉`) are similarly load-bearing.
- **Mid-range clues on long, tree-sparse lines are frequently redundant**, because tree geometry
  plus no-touching already pins those cells.
- The extreme case is real and studied: De Biasi formalises **TENTS WITHOUT HINTS**, the variant
  with no counts at all. Some instances remain uniquely solvable from tree geometry alone — the
  strongest evidence that counts are far from all necessary.

**Note:** Tatham's generator makes **no attempt at minimality** — it plants trees and tents, then
reads off all `2n` counts. His puzzles are maximally clued. Minimal or near-minimal instances
require an added greedy prune pass.

### Tree positions are NOT removable clues

Removing a tree does not weaken a constraint; it **changes the instance**. Tent count drops by
one, every row and column clue the tree's tent contributed to becomes wrong, and the result is a
different puzzle, not a harder version of the same one. Trees are part of the **board**, in the
same category as the grid dimensions, not in the category of Sudoku givens.

**Conclusion: apply PROP-6 to the `2n` counts only, with the sum-identity correction, and treat
tree positions as fixed structure.**

### ⚠ A second finding that changes what "unique" means

Tatham documents an ambiguity the rules leave open: **a tent placement can be unique while the
bijection is not.** His example is a plus-shaped arrangement with counts 2/0/2 by 2/0/2, where the
tent positions are forced but two distinct tree→tent assignments both work.

His policy: *"When checking a user-supplied solution for correctness, only verify that there
exists at least one matching. When generating a puzzle, enforce that there must be exactly one."*

**Recommend adopting exactly this.** It matters for minimality because "unique solution" under the
strict (bijection-unique) reading is a stronger condition, so **fewer clues are removable under it
than under the loose (placement-unique) reading**. Pick one, state it in the generator spec, and
test against it consistently. This is a genuine product decision and belongs in the open questions.

---

## EXCLUDED — guessing in disguise

All *sound* in the sense of never producing a wrong answer, but they are search, not deduction,
and a human-simile solver that uses them produces hints no human would accept.

- **`trialAndErrorContradiction`** (bifurcation, Nishio, "what-if", 1-ply lookahead). Assume cell
  c is a tent, propagate to fixpoint, observe a contradiction, conclude grass. This is depth-1
  DFS. **Exclude — and note it is the technique most often smuggled in unlabelled**, because it is
  easy to write and dissolves every puzzle.
- **`forcingChain` / multi-hypothesis chains.** Same objection, deeper.
- **`matchingHypothesisTest`** — the tempting extension of #21: assume edge (T,c), delete c's
  8-neighbours from all other trees' candidate sets, re-run Hopcroft–Karp, eliminate the edge if
  no matching survives. This **is** a hypothesis test with propagation, i.e. guessing with a fast
  oracle. Keep only the pure relevance form of #21, which involves no assumption at all.
- **`uniquenessAssumption`** (Sudoku's unique-rectangle analogue). Tatham's plus-shaped ambiguity
  pattern is a live target for this in Tents. Exclude on two grounds: unsound on boards that are
  not in fact unique, and **our generator needs the solver to *detect* non-uniqueness rather than
  assume it away**.
- **#19–#20 are borderline — keep with a cap.** Bounded per-line enumeration is something humans
  genuinely do, and Tatham ships it as a core rule. But it becomes search if `n` grows. **Cap the
  free-cell count per line at ~12** and refuse the rule above it; otherwise tier-6 hints degenerate
  into "I checked 4096 cases."

---

## Sources

**Substantive:**

- [Simon Tatham's `tents.c`](https://github.com/ghewgill/puzzles/blob/master/tents.c) — **by far
  the best source in existence.** ~180-line design essay proving results about unique perfect
  matchings via Hall's Marriage Theorem; explicit statement of why the bijection rule is
  universally mis-stated elsewhere; full solver with verbatim rule comments; the
  `DIFF_EASY`/`DIFF_TRICKY` split and exactly which rules each tier gets; the connected-component
  error-detection lemma with proof; and the generator's difficulty-calibration method. Everything
  in tiers 2 and 6, and much of 4, traces back here.
- [Marzio De Biasi, "The Complexity of Camping" (2012)](https://www.nearly42.org/vdisk/cstheory/tentsnpc2.pdf)
  — NP-completeness for Tents with hints, by reduction from 3-SAT; also formalises TENTS WITHOUT
  HINTS, which makes the minimality discussion concrete.
- [Puzzler — Campsite](https://www.puzzler.com/puzzles-a-z/campsite) — the only mainstream source
  with genuinely advanced named techniques: the forced-pair four-cell elimination, the 1x3
  two-cell elimination, and the 2x2 two-row analysis.
- [BrainBashers — Tents help](https://www.brainbashers.com/tentshelp.asp) — clean, correct worked
  example; canonical statement of tier-1 and tier-2 rules. Thin above tier 2.
- [janko.at — Zeltlager](https://www.janko.at/Raetsel/Zeltlager/index.htm) — the most precise
  *rule* statement (explicit one-to-one correspondence) and useful German terminology.
- [queensgame.io — Tents and Trees](https://queensgame.io/tents-and-trees) — decent named-strategy
  taxonomy (Zero Rule, Forced Tent, Capacity Check, Territory Claim, Constraint Integration).

**Background:**

- [Hall's marriage theorem](https://en.wikipedia.org/wiki/Hall%27s_marriage_theorem)
- [Dulmage–Mendelsohn decomposition (`dmperm`)](https://www.mathworks.com/help/matlab/ref/dmperm.html)
  — confirms diagonal blocks are the strong Hall components, the practical route to human-readable
  Hall witnesses.
- [Tatham's Tents documentation](https://www.chiark.greenend.org.uk/~sgtatham/puzzles/doc/tents.html)
  — confirms no difficulty level requires guesswork or backtracking.

**Dead ends — recorded so nobody re-walks them:**

- **conceptispuzzles.com has NO Tents techniques page.** The research brief's premise was wrong.
  The techniques URL 404s; site-restricted search finds only a puzzle-book listing. Conceptis
  publishes tiered guides for Sudoku, Kakuro, Hashi and Nurikabe, but **not** Tents. Do not budget
  more time here.
- [puzzle-tents.com](https://www.puzzle-tents.com/) — rules only, no solving guide.
- [dkmgames.com Tents help](https://dkmgames.com/Tents/TentsHelp.htm) — UI help only; one useful
  rule clarification ("a tree may end up adjacent to two tents, but is only attached to one").
- puzzlegenius.org/tents and keepitsimplepuzzles.com — failed to render (empty body / SSL 526).
- **puzzling.stackexchange.com — essentially nothing on Tents.** The genre has little presence.
- **puzz.link / pzprjs — no documented deduction rules for Tents.**
- GitHub solvers (tihmels CSP, lauragalera SAT/Prolog, LoicGoulefert, disposedtrolley Racket) —
  all CSP/SAT encodings or plain backtracking. Useful as correctness oracles for the generator;
  **none enumerate named human techniques.**
