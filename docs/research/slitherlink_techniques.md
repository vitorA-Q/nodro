# Slitherlink — Human deduction technique catalogue

Research output, Phase 0. Implementation spec for `lib/engine/puzzles/slitherlink/techniques/`.

**Structural summary.** Slitherlink deduction decomposes into six genuinely distinct reasoning
layers plus a "don't do this" layer:

1. **Local arithmetic on a single clue** (a cell's ON-count and unknown-count). Combined with the
   *vertex parity* fact that every dot has degree 0 or 2, this subsumes the whole family of
   "corner" rules — they are all the *same* rule applied at a dot where the two outward edges are
   known absent.
2. **Pairwise clue interaction** (3-3 orthogonal and diagonal, 1-1 diagonal, 1-3 diagonal).
3. **Vertex/sector propagation.** The key non-obvious fact: at any dot the two *opposite*
   adjacent-edge pairs ("sectors") always share their only-one/not-one status. This is what makes
   chains of 2s propagate along diagonals.
4. **Connectivity** (union-find; premature loop closure; reachability).
5. **Inside/outside face colouring** — a parity union-find over faces with a virtual OUTER node.
   Provably equivalent to sector reasoning, and it subsumes every corner rule as neighbour-colour
   counting.
6. **Long chains and forcing arguments.**
7. **Excluded:** trial-of-one-edge refutation and "Highlander"/uniqueness deductions.

> **⚠ THE SINGLE MOST IMPORTANT ARCHITECTURAL FINDING:** inside/outside colouring alone is **NOT
> sufficient** to enforce single-loop-ness — a consistent colouring can encode two nested or
> disjoint loops with every vertex still at degree 0 or 2. A union-find connectivity check remains
> **mandatory**. Conversely union-find cannot replace colouring, because colouring propagates
> long-range information that connectivity never sees. **Both structures are required.** Full
> analysis at the end of this document.

**Notation.** A cell's four edges are *top/left/right/bottom*. A "dot" is a lattice vertex; its
four incident edges are N/E/S/W. For a cell and one of its corner dots D, the cell's "near edges"
are its two edges incident to D; its "far edges" are the other two.

---

## Summary table

| # | id | name | tier | concludes |
|---|---|---|---|---|
| 1 | `zeroRule` | Zero Rule | 1 | edges OFF (x4) |
| 2 | `cellEdgeCounting` | Clue Saturation / Completion | 1 | edges OFF or ON |
| 3 | `threeCornerRule` | 3 at a (Virtual) Corner | 1 | edges ON (x2) |
| 4 | `oneCornerRule` | 1 at a (Virtual) Corner | 1 | edges OFF (x2) |
| 5 | `twoCornerRule` | 2 at a (Virtual) Corner | 1 | pair equivalences; at a true corner, 2 ON |
| 6 | `threeIncomingCorner` | Line into the Corner of a 3 | 1 | 2 ON + 1 OFF |
| 7 | `oneIncomingCorner` | Line into the Corner of a 1 | 1 | edges OFF (x2) |
| 8 | `threeAdjacentToZero` | 3 Orthogonally Next to 0 | 1 | edges ON (x3) |
| 9 | `threeAdjacentToThree` | Two Adjacent 3s (S/Z pattern) | 2 | 2 ON + 2 OFF; middle edge ON (see caveat) |
| 10 | `threeDiagonalToThree` | Two Diagonal 3s | 2 | edges ON (x4) |
| 11 | `threeDiagonalToZero` | 3 Diagonal to 0 | 2 | edges ON (x2) |
| 12 | `oneDiagonalToOne` | Two Diagonal 1s | 2 | disjunction → conditional OFF (x4) |
| 13 | `oneDiagonalToThree` | Diagonal 1-3 | 2 | edges ON (x2) |
| 14 | `oneAdjacentToOneOnBorder` | Two Adjacent 1s on the Border | 2 | edge OFF |
| 15 | `vertexSaturation` | Dot Already Has Two Lines | 3 | edges OFF |
| 16 | `vertexForcedContinuation` | One In Forces One Out | 3 | edge ON |
| 17 | `vertexDeadEnd` | Three Crosses Force the Fourth | 3 | edge OFF |
| 18 | `sectorPropagation` | Opposite Sectors Match | 3 | pair constraint |
| 19 | `noPrematureLoopClosure` | No Premature Closed Loop | 4 | edge OFF |
| 20 | `reachabilityElimination` | Unreachable Segment Pruning | 4 | edge OFF |
| 21 | `forcedBridge` | Only Remaining Connection | 4 | edges ON |
| 22 | `outerFaceSeeding` | Outside Is Outside | 5 | cell colour = OUTSIDE |
| 23 | `colourPropagation` | Inside/Outside Colouring | 5 | cell colour relation |
| 24 | `colourToEdge` | Colour Difference Determines Edge | 5 | edge ON or OFF |
| 25 | `clueColourCount` | Clue = Count of Opposite Neighbours | 5 | cell colour and/or edges |
| 26 | `regionCrossingParity` | Region Boundary Parity (Jordan) | 5 | edge ON/OFF via parity |
| 27 | `twosDiagonalChain` | Diagonal Chain of 2s | 6 | sector chain → edges |
| 28 | `threesSeparatedByTwosDiagonal` | 3…2…2…3 on a Diagonal | 6 | edges ON (x4) |
| 29 | `twosDiagonalToThree` | Line into a Diagonal of 2s Ending in a 3 | 6 | edges ON (x2) |
| 30 | `forcingChain` | Forcing Chain / Both-Branches-Agree | 6 | edge ON or OFF |
| — | `trialOfOneEdge` | Trial & Error / Failed-Literal | 7 | **EXCLUDED — search in disguise** |
| — | `highlanderUniqueness` | Highlander / Metagaming | 7 | **EXCLUDED — assumes uniqueness** |

---

## TIER 1

### 1. `zeroRule` — Zero Rule
- **Description** — A cell clued 0 has all four edges marked absent.
- **Soundness** — The clue is an exact equality, so no solution places a line on any of those four
  edges.
- **Concludes** — 4 x edge OFF.
- **Data** — edge-state grid; per-cell remaining count.

### 2. `cellEdgeCounting` — Clue Saturation and Completion
*Sub-keys `clueSaturation`, `clueCompletion`.*
- **Description** — If a cell already has `clue` edges ON, every remaining unknown edge is OFF
  (saturation). If its unknown edges exactly equal its deficit (`clue − onCount == unknownCount`),
  all of them are ON (completion).
- **Soundness** — Both directions are forced by the clue's exact-equality semantics.
- **Concludes** — edge OFF (saturation) or edge ON (completion).
- **Data** — per-cell `onCount`/`unknownCount`, incrementally maintained; dirty-cell worklist.

### 3. `threeCornerRule` — 3 at a (Virtual) Corner
- **Description** — At a corner dot D of a 3-cell where both edges leaving D away from the cell
  are absent (off-grid, or already crossed), the 3's two near edges at D are both ON.
- **Soundness** — Vertex parity forces the near pair both-ON or both-OFF; both-OFF would leave the
  3 needing three lines from two remaining edges.
- **Concludes** — 2 x edge ON.
- **Data** — edge-state grid; per-dot incident-edge index; off-grid edges modelled as permanently
  OFF.
- **Note** — The "virtual corner" generalisation (a dot behaves like a grid corner as soon as its
  two outward edges are crossed) is what makes this rule fire far more often than beginners expect.

### 4. `oneCornerRule` — 1 at a (Virtual) Corner
- **Description** — At such a corner dot D of a 1-cell, the 1's two near edges at D are both OFF.
- **Soundness** — Parity makes the near pair both-ON or both-OFF; both-ON would give the cell two
  lines, exceeding its clue.
- **Concludes** — 2 x edge OFF.

### 5. `twoCornerRule` — 2 at a (Virtual) Corner
- **Description** — At such a corner dot D of a 2-cell: the near pair is both-ON-or-both-OFF, the
  far pair is the complement, and **if D is a true grid corner** the two border edges one step
  away from the cell along each border are ON.
- **Soundness** — Parity gives near-pair equality; the clue 2 forces the far pair to carry the
  complementary count; in both of the only two possible cases the two identified border edges are
  the unique way to keep the cell's other corner dots at degree 2.
- **Concludes** — pair equivalences (`nearA == nearB`, `farA == farB`, `nearA != farA`); at a true
  grid corner additionally 2 x edge ON.
- **Data** — a pair/sector store, or a parity union-find over edge variables (see #18/#23).

### 6. `threeIncomingCorner` — Line into the Corner of a 3
- **Description** — If a line arrives at corner dot D of a 3-cell from outside the cell, the 3's
  two far edges are both ON, and the other outward edge at D is OFF.
- **Soundness** — If either far edge were absent, the 3's single absent edge would be that one,
  forcing both near edges ON and giving D degree 3 with the incoming line — impossible. Exactly
  one near edge is then ON, bringing D to degree 2 and making the remaining outward edge absent.
- **Concludes** — 2 x edge ON, 1 x edge OFF.

### 7. `oneIncomingCorner` — Line into the Corner of a 1
- **Description** — If a line arrives at corner dot D of a 1-cell and the *other* outward edge at
  D is known absent, the 1's two far edges are both OFF.
- **Soundness** — With one outward edge ON and the other OFF, parity forces exactly one near edge
  ON, consuming the cell's entire quota of 1.
- **Concludes** — 2 x edge OFF.

### 8. `threeAdjacentToZero` — 3 Orthogonally Next to 0
*Commonly taught as tier 2; it is a single-clue rule once the 0 is expanded.*
- **Description** — When a 3 shares an edge with a 0, the shared edge is absent, so the 3's other
  three edges are all ON — and by vertex parity the two edges collinear with the shared edge,
  extending sideways from the 3, are also ON.
- **Soundness** — The 0 rule makes the shared edge absent; the 3 must then take all three
  remaining edges.
- **Concludes** — 3 x edge ON (plus 2 more via #16).

---

## TIER 2

### 9. `threeAdjacentToThree` — Two Adjacent 3s (S/Z pattern)
- **Description** — For two 3s sharing edge S: the two outer edges parallel to S are ON, the two
  edges collinear with S extending beyond it are OFF, and S itself is ON.
- **⚠⚠ READ THIS CAREFULLY — THE ONE CAVEAT IN THE WHOLE CATALOGUE.** The two outer edges and the
  two collinear crosses are *unconditionally* forced: in the S-ON case, making an outer edge
  absent forces both of that cell's perpendicular edges ON, starving the other 3; in the S-OFF
  case all six edges of the domino are ON, so the outer edges are ON there too; and in both cases
  the shared dots already reach degree 2, killing the collinear extensions.
  **But the conclusion `S = ON` is NOT purely local.** S-OFF yields a legal closed 6-cycle around
  the domino that satisfies both 3s. `S = ON` is sound only because that 6-cycle would then have
  to be the *entire* solution.
  **Implementation:** guard it with the cheap test "does the 6-cycle satisfy every clue in the
  puzzle and account for every ON edge on the board?" — if not (essentially always), `S = ON` is
  sound. Alternatively, defer S entirely to #19 `noPrematureLoopClosure`, which handles it
  correctly by construction.
- **Concludes** — 2 x ON and 2 x OFF (unconditional); 1 x ON (S, under the guard).
- **Data** — edge-state grid; per-cell counters; a global clue list for the 6-cycle guard.

### 10. `threeDiagonalToThree` — Two Diagonal 3s
- **Description** — For two 3s meeting at a dot D, each 3's two far edges (not touching D) are ON
  — four lines total. The four outward edges at the two outer corners then become OFF.
- **Soundness** — If one 3's far edge were absent, that 3's other three edges would be ON,
  including both near edges at D, giving D degree 2 and forcing the second 3's near pair OFF —
  leaving it needing three lines from two edges.
- **Concludes** — 4 x edge ON (and 4 x OFF via #15).

### 11. `threeDiagonalToZero` — 3 Diagonal to 0
*An instance of #3.*
- **Description** — When a 3 and a 0 meet at dot D, the 3's two near edges at D are both ON.
- **Soundness** — The 0 makes both of D's other incident edges absent, so parity forces the near
  pair both-ON or both-OFF, and both-OFF starves the 3.
- **Concludes** — 2 x edge ON.

### 12. `oneDiagonalToOne` — Two Diagonal 1s
- **Description** — For two 1s meeting at dot D, either all four "inner" edges (the two cells'
  near edges at D) are OFF, or all four "outer" edges (their far edges) are OFF. So as soon as one
  inner edge is ON, all four outer edges are OFF, and vice versa.
- **Soundness** — If not all inner edges are absent, parity puts exactly two inner edges ON, and
  they cannot both belong to the same 1, so each 1 spends its single line on an inner edge and
  both cells' far edges are absent. The two branches are exhaustive and mutually exclusive, so
  neither branch's conclusion is ever applied to a solution belonging to the other.
- **Concludes** — a disjunctive pair constraint; on trigger, 4 x edge OFF.
- **Data** — a constraint/watch list keyed by the eight edges. The face parity-DSU gives the same
  effect for free (the two diagonal faces at D are same-coloured in the inner-OFF branch).

### 13. `oneDiagonalToThree` — Diagonal 1-3
- **Description** — For a 1 and a 3 meeting at dot D, if the 1's two far edges are both absent
  then the 3's two far edges are both ON.
- **Soundness** — With the 1's far edges absent its single line must be a near edge at D; parity
  then puts exactly one of the 3's near edges ON, leaving it two lines among its two far edges.
- **Concludes** — 2 x edge ON.

### 14. `oneAdjacentToOneOnBorder` — Two Adjacent 1s on the Border
- **Description** — Two 1s sharing an edge S perpendicular to the grid border and touching it:
  S is OFF.
- **Soundness** — If S were ON both 1s would be satisfied by it, forcing all six of their other
  edges absent; the border dot at S's end would then have degree 1 — impossible.
- **Concludes** — 1 x edge OFF.

---

## TIER 3

### 15. `vertexSaturation` — Dot Already Has Two Lines
- **Description** — When two edges at a dot are ON, every remaining unknown edge there is OFF.
- **Soundness** — A simple non-branching loop gives every dot degree exactly 0 or 2.
- **Concludes** — edge OFF.
- **Data** — per-dot `onCount`/`unknownCount`; incident-edge index; worklist.

### 16. `vertexForcedContinuation` — One In Forces One Out
- **Description** — When a dot has exactly one ON edge and exactly one remaining unknown edge,
  that unknown edge is ON.
- **Soundness** — Degree 1 is impossible (the loop has no loose ends) and degree cannot exceed 2.
- **Concludes** — edge ON.

### 17. `vertexDeadEnd` — Three Crosses Force the Fourth
- **Description** — When three of a dot's four edges are OFF and none is ON, the fourth is OFF.
- **Soundness** — Turning it ON would give the dot degree 1.
- **Concludes** — edge OFF.

### 18. `sectorPropagation` — Opposite Sectors Match
*Olson's "only-one / not-one sectors"; arc notation (a 90° arc = exactly one of two adjacent
edges; a double arc = both or neither).*
- **Description** — At any dot, label each of the four adjacent-edge pairs (N,E), (E,S), (S,W),
  (W,N) as *only-one* or *not-one*. The two **opposite** sectors at a dot always carry the same
  label, so the property hops diagonally across the grid.
- **Soundness** — The dot's total degree is 0 or 2, so if one pair contains exactly one ON edge
  the complementary pair must too; if one pair contains 0 or 2, so does the complementary pair.
- **Concludes** — a pair constraint; combined with a clue it yields edge ON or OFF
  ("not-zero + not-one ⇒ both ON"; "not-two + not-one ⇒ both OFF").
- **Data** — **preferably nothing new**: sector (N,E) at a dot is only-one exactly when the NW and
  SE faces at that dot have opposite colours, so #23's face parity-DSU implements this rule for
  free. **Do not build a separate sector store if you build the face DSU.**

---

## TIER 4 — Connectivity

### 19. `noPrematureLoopClosure` — No Premature Closed Loop
*Also: "small loop check", "U-turn-3 pattern" (its most famous special case).*
- **Description** — An unknown edge whose two endpoints already lie in the same connected chain of
  ON edges is OFF — **unless** closing that chain would simultaneously satisfy every clue in the
  puzzle and account for every ON edge on the board.
- **Soundness** — The solution is a *single* closed loop, so any closed cycle formed before all
  clues are satisfied would either be the whole loop (contradicting the unsatisfied clues) or a
  second component (contradicting single-loop-ness). The "unless" clause is exactly the case where
  the closure *is* the complete solution.
- **Concludes** — edge OFF.
- **Data** — union-find over **dots**, `union(u,v)` on every ON edge; per-cell counters for the
  completeness test; a global ON-edge count and a "clues remaining" count.
- **Note** — This fires far more often than beginners expect. It produces the classic "U-turn-3"
  pattern, and it is exactly what supplies the shared-edge conclusion in #9 that pure local
  reasoning cannot reach.

### 20. `reachabilityElimination` — Unreachable Segment Pruning
- **Description** — An unknown edge is OFF if turning it ON would place an existing ON segment in
  a region from which it can no longer reach the rest of the required loop through remaining
  unknown edges.
- **Soundness** — Every ON edge must lie on the single final cycle, so if the graph of
  ON ∪ UNKNOWN edges has no path connecting two ON components, no completion exists.
- **Concludes** — edge OFF.
- **Data** — union-find over dots for ON components; BFS/DFS over the ON ∪ UNKNOWN subgraph
  (recompute lazily, or maintain a second union-find over "still-possibly-connected" dots).

### 21. `forcedBridge` — Only Remaining Connection
- **Description** — If exactly one route of unknown edges remains that can join two distinct ON
  components (or supply a chain endpoint with its second edge), every edge on that route is ON.
- **Soundness** — All ON edges must end up on one cycle, so every solution extending the current
  state uses that route.
- **Concludes** — edge ON (possibly several).
- **Data** — union-find over dots; bridge/articulation detection (Tarjan) on the ON ∪ UNKNOWN
  subgraph; per-dot degree counters.

---

## TIER 5 — Inside/outside colouring

### 22. `outerFaceSeeding` — Outside Is Outside
- **Description** — All of the plane beyond the grid is a single face permanently coloured
  OUTSIDE, and it is the neighbour across every border edge.
- **Soundness** — The loop lies entirely on the finite lattice, so the unbounded complement is
  connected and is by definition the exterior of the Jordan curve. **A fact about every solution,
  not an assumption.**
- **Concludes** — cell state = OUTSIDE for the virtual exterior face.
- **Data** — one extra node in the face parity-DSU, pinned to colour 0; border edges wired to it.

### 23. `colourPropagation` — Inside/Outside Colouring
*Also: parity method, shading, the Jordan-curve colouring.*
- **Description** — Every cell is INSIDE or OUTSIDE the loop. An ON edge forces its two cells to
  opposite colours; an OFF edge forces them to the same colour. These relations merge transitively
  across the whole board.
- **Soundness** — A simple closed curve partitions the plane into exactly two regions (Jordan
  curve theorem), and moving between two edge-adjacent cells crosses the curve exactly once if
  that edge is on the loop and zero times otherwise. **An exact consequence, never a heuristic.**
- **Concludes** — cell state, or a *relative* colour relation between two cells.
- **Data** — **parity (weighted) union-find over faces** including the OUTER node:
  `union(f, g, 1)` for ON edges, `union(f, g, 0)` for OFF edges. `find` returns
  `(root, parityToRoot)`. **A conflicting union is an immediate contradiction.**

### 24. `colourToEdge` — Colour Difference Determines Edge
- **Description** — If two edge-adjacent cells are already known (via the parity-DSU) to be in the
  same colour class, the shared edge is OFF; if in opposite classes, it is ON.
- **Soundness** — This is the converse direction of the same exact biconditional as #23 — the
  shared edge is on the loop *if and only if* the two cells are on opposite sides.
- **Concludes** — edge ON or OFF.
- **Data** — face parity-DSU; a per-edge hook that queries `find(f)`/`find(g)` whenever either
  root changes.

### 25. `clueColourCount` — Clue = Count of Opposite Neighbours
- **Description** — A clue `n` says exactly `n` of the cell's four neighbours (counting the OUTER
  face for border cells) have the opposite colour, turning every clue into a constraint over five
  colour variables.
- **Soundness** — Each of the cell's four edges is ON exactly when the corresponding neighbour
  differs in colour (#23), so the clue's edge-count and the opposite-colour-neighbour count are
  the same number in every solution.
- **Concludes** — cell state and/or edges.
- **⚠ Architectural payoff** — **This single rule derives #3, #4, #5 and #11.** A corner 3 must be
  INSIDE (its two OUTER neighbours are same-coloured, capping it at 2 if it were OUTSIDE); a
  corner 1 must be OUTSIDE; a corner 2 splits into the two-case pattern. **A large simplification
  of the rule table** — but keep the corner rules as named techniques anyway, for hint quality.
- **Data** — face parity-DSU; per-cell list of four neighbour face ids (OUTER substituted at
  borders); a small per-clue constraint propagator.

### 26. `regionCrossingParity` — Region Boundary Parity (Jordan)
- **Description** — Two exact parity facts. (a) For any *closed walk through adjacent faces*, the
  number of ON edges crossed is even. (b) For any set **R** of fully-clued cells, the number of ON
  edges on **R**'s outer boundary is congruent mod 2 to the sum of **R**'s clues — with
  **R** = the whole grid, this is the grid-border parity rule.
- **Soundness** — (a) is the consistency of the two-colouring around a cycle. (b) follows from
  double counting: summing each cell's clue counts every interior edge of **R** exactly twice and
  every boundary edge exactly once. **Both are identities satisfied by every solution.**
- **Concludes** — edge ON or OFF (when parity leaves exactly one possibility), or a contradiction
  that refutes a branch.
- **Data** — face parity-DSU (form a); prefix sums of clues over rectangles plus per-boundary
  ON/unknown counts (form b).
- **Bonus** — the dot lattice is bipartite, so the final loop always has an **even number of
  edges** — a cheap global sanity parity.

---

## TIER 6

### 27. `twosDiagonalChain` — Diagonal Chain of 2s
- **Description** — If exactly one of a 2-cell's two edges at corner D is ON (an only-one sector),
  the same holds at the opposite corner D′, and via #18 it hops into the diagonally adjacent cell.
  So an angled line entering one end of a diagonal run of 2s propagates a matching angled
  constraint all the way along the run.
- **Soundness** — A 2 has exactly two ON edges among four, so a near pair with exactly one ON
  leaves exactly one ON in the far pair; combined with the vertex fact that opposite sectors match,
  each hop is an **equivalence** holding in every solution — exact, not a pattern-match.
- **Concludes** — a chain of only-one sector constraints, resolving to edges as soon as any one
  edge in the chain becomes known.
- **Data** — face parity-DSU (the chain is literally a diagonal chain of face-colour inequalities).

### 28. `threesSeparatedByTwosDiagonal` — 3…2…2…3 on a Diagonal
- **Description** — Two 3s on the same diagonal separated by any number of cells that are *all*
  clued 2 behave exactly like diagonally adjacent 3s: each 3's two far edges are ON.
- **Soundness** — Suppose one 3's far edge were absent; its other three edges are then ON,
  including both near edges at the facing dot, which saturates that dot and forces the adjoining
  2's near pair OFF, hence its far pair ON, which saturates the next dot. The alternation marches
  down the entire run of 2s and arrives at the far 3 with both near edges OFF, leaving it three
  lines among two edges — a contradiction.
- **Concludes** — 4 x edge ON.
- **Data** — a diagonal scan that walks while `clue == 2` and stops at a 3.

### 29. `twosDiagonalToThree` — Line into a Diagonal of 2s Ending in a 3
*Its zero-2s base case (a 2 diagonally touching a 3) is tier 2.*
- **Description** — If a line reaches the outer starting corner **A** of a diagonal made of one or
  more 2s terminating in a 3, then both edges of the 3 at its *far* corner are ON.
- **Soundness** — If not, the 3's absent edge would be a far edge, forcing both near edges ON,
  saturating the adjacent dot, forcing the neighbouring 2's near pair OFF and far pair ON; this
  alternation propagates back down the run of 2s to force lines at the near corner of the first 2
  — conflicting with the line already arriving at **A**.
- **Concludes** — 2 x edge ON.

### 30. `forcingChain` — Forcing Chain / Both-Branches-Agree
- **Description** — Pick one undetermined edge (or sector), propagate *both* of its two possible
  values using only tier 1–5 rules, and commit any conclusion the two branches agree on.
- **Soundness** — The chosen variable is Boolean, so every solution lies in one branch or the
  other; a conclusion reached in *both* branches holds in every solution. **This is sound case
  analysis, not guessing — provided the branch results are discarded and only the agreement is
  kept.**
- **Concludes** — edge ON, edge OFF, or a cell colour.
- **Data** — copy-on-write or trail-based snapshot of edge states / DSU state so both branches can
  run and be rolled back; a diff routine to intersect the outcomes; **a depth cap (depth 1 keeps
  it human-plausible).**

---

## EXCLUDED

### `trialOfOneEdge` — Trial & Error / Failed-Literal
*Conceptis's "Advanced techniques" 1–6, Puzzolve's "proof by contradiction", the
"assumption-testing one or two steps ahead" style — all the same thing.*

Assume an edge, propagate, and if you hit a contradiction assert the negation. This is *sound*
(it is failed-literal detection / DPLL unit propagation), but it is **single-branch search**, not
a named human pattern.

**⚠ THE DECISIVE ARGUMENT:** with `trialOfOneEdge` available, **every** uniquely-solvable
Slitherlink becomes solvable — **so it destroys tier discrimination entirely**, which is to say it
destroys P2. And the "explain this move" text becomes meaningless, which destroys P3. Exclude.

### `highlanderUniqueness` — Highlander / Metagaming
Olson's "Highlander" deductions: if a placement would leave a configuration admitting two
solutions, reject it, because the puzzle is advertised as uniquely solvable.

**Unsound as a general inference** — it is a statement about the *puzzle setter*, not about the
loop. Olson himself warns it is "less pure" and fails on multi-solution puzzles. **Critically: it
must never run inside the generator/validator that certifies uniqueness, because that reasoning is
circular.** Exclude.

Also excluded by the same logic: any rule stated as "the intended solution wouldn't look like
that", and any "guess a random move and see if it works" fallback.

---

## ⚠ The global single-loop constraint — the architecture decision

This is the part of Slitherlink that clue arithmetic and vertex parity **cannot** express. Local
rules guarantee only that every dot has degree 0 or 2 and every clue is met — which characterises
a **disjoint union of loops**, not a single loop. Two independent mechanisms are needed, and
**they are not substitutes for one another.**

### (a) How union-find detects premature closure

Maintain `dsuDots` over the `(R+1) x (C+1)` lattice dots. Invariant: two dots are in the same set
exactly when joined by a path of ON edges.

When an edge `e = (u, v)` is about to be set ON:

- **If `find(u) != find(v)`** — `e` joins two distinct open chains (or starts one). Always legal.
  `union(u, v)`, increment `onEdgeCount`.
- **If `find(u) == find(v)`** — setting `e` ON would close a cycle. Because every dot already has
  degree ≤ 2 (enforced by #15), that component is a simple path and `e` joins its two endpoints,
  producing a closed loop. **Legal only if the resulting loop is the complete solution.** Test
  with three cheap checks:
  1. every clued cell's `onCount` equals its clue (state *after* adding `e`);
  2. `onEdgeCount + 1` equals the number of ON edges in this component — i.e. **no ON edge exists
     outside this component**;
  3. no unknown edge is still required elsewhere (implied by 1 and 2).

  If any check fails, the deduction is **`e = OFF`**. This is #19, and it is a *deduction*, not
  merely a validity guard — it removes an edge and feeds the propagation worklist like any other
  rule.

**Two implementation notes.**
1. Use **union by size/rank with path compression** for a pure deduction loop. But if you add #30
   `forcingChain`, you need a **rollback-capable DSU** (union by rank with an undo trail, **no
   path compression**, or a versioned DSU) so branches can be unwound.
2. Also track per-component **endpoint pairs** — for a path component, cache its two degree-1
   dots. This makes the closure check trivially exact and powers #21 and the "chain endpoint must
   extend" reasoning.

### (b) What inside/outside colouring adds beyond union-find

Colouring and connectivity see **completely different information**.

Union-find sees only **edges already set ON**. It is blind until lines exist, says nothing about
regions with no lines yet, and **propagates nothing through crosses (OFF edges)**.

Colouring, as a **parity union-find over faces** (`dsuFaces`, plus one pinned exterior node),
propagates through *both* line types: ON edge → `union(f, g, parity 1)`; OFF edge →
`union(f, g, parity 0)`. What that buys:

1. **Long-range binary linkage through crosses.** A chain of OFF edges welds a whole region into
   one colour class, so a single line drawn at one end of the board can determine an edge dozens
   of cells away. **Connectivity cannot see crosses at all.**
2. **Deduction in both directions.** Once two edge-adjacent faces are in the same DSU class, the
   shared edge is *determined* by their relative parity (#24) — even if not a single line touches
   either cell yet.
3. **Early contradiction detection.** A `union` with conflicting parity is a contradiction detected
   long before any loop forms. In a `forcingChain` this typically refutes a branch several steps
   sooner than connectivity would.
4. **Corner and clue rules for free** (#25).
5. **Sectors for free** (#18) — including #27 and #28. **If you build the face parity-DSU, do not
   build a separate sector store.**
6. **Region parity** (#26a) is precisely the statement that `dsuFaces` is consistent around cycles.

Conversely, colouring adds **nothing** about premature closure. It cannot tell one loop from two.
**Keep both structures.**

### (c) Is colouring alone sufficient to enforce single-loop-ness? — NO

**A final connectivity check is still required.** Two independent reasons, with concrete
counterexamples:

**Reason 1 — colouring permits degree-4 vertices (crossings).** Given any 2-colouring of the
faces, define `E = {edges whose two faces differ in colour}`. Around any lattice dot the four
faces form a cycle, and the number of colour changes around a cycle is always even, so every dot
has **even** degree in `E` — that is degree 0, 2, **or 4**. A checkerboard colouring of the four
faces around one dot (opposite faces same colour) yields **degree 4** there — a self-crossing,
which standard Slitherlink forbids. So colouring alone does not even guarantee a valid *curve*.
You must additionally forbid the "alternating quadrants" pattern at every dot — equivalently,
enforce degree ≤ 2 via #15.

**Reason 2 — even with degree ≤ 2 everywhere, colouring permits multiple loops.** Take two nested
rectangles. Colour the exterior OUTSIDE, the annulus INSIDE, and the inner rectangle's interior
OUTSIDE. Every colour relation is consistent, every dot has degree exactly 2, all Jordan/parity
conditions hold — and the induced edge set is **two disjoint loops**. Same with two separated
blobs both coloured INSIDE against an OUTSIDE background.

**The precise theory:** for a planar grid, a face 2-colouring's coboundary `E` is always an element
of the cycle space — an **even subgraph**, a disjoint union of edge-disjoint cycles. Requiring
degree ≤ 2 upgrades that to a disjoint union of **simple** cycles. Requiring *exactly one* cycle is
a **connectivity** condition that lives outside the colouring formalism entirely. (This is the same
"1 Loop Problem" that SAT-based Slitherlink work solves with explicit reachability encodings or
lazy subtour-elimination clauses.)

### Recommended architecture

```
State:
  edgeState[]           UNKNOWN | ON | OFF
  cellOn[], cellUnknown[]
  dotOn[], dotUnknown[]
  dsuDots               plain DSU over dots (+ cached endpoint pair per component)
  dsuFaces              parity DSU over faces, plus one pinned OUTER node
  worklist              dirty cells / dots / faces / edges
```

- Run tier 1→6 rules to a fixpoint, re-queueing on every change.
- `dsuDots` handles #19 / #20 / #21 during solving.
- `dsuFaces` handles #22–#27 and, as a bonus, #18 and the corner rules.
- **On completion, ALWAYS run a final verification independent of the rules:** (i) every clue
  exactly satisfied; (ii) every dot has degree 0 or 2; (iii) let `k` = number of ON edges — walk
  the loop from any ON edge and confirm the walk returns to its start after exactly `k` steps.
  Step (iii) is the single-loop check and it is O(k). **Do not skip it on the grounds that #19 was
  enforced throughout: #19's completeness test is exactly where an off-by-one is easy to
  introduce, and the final walk is cheap insurance.**
- If you add #30, make **both** DSUs rollback-capable, or snapshot them per branch.

---

## Sources

**Substantive — these carried real technical content:**

- [How Slitherlink Should be Solved — Jonathan Olson](https://jonathanolson.net/slitherlink/) —
  **by far the deepest source.** Origin of the sector formalism (only-one / not-one / not-two /
  not-zero), the colouring section, the region-parity argument, and the explicit statement that
  colouring implies sectors. Also the honest treatment of Highlander deductions as
  uniqueness-dependent. Companion: [Slither Rule Explorer](https://jonathanolson.net/slitherlink/rule-explorer).
- [Slitherlink techniques — Conceptis](https://www.conceptispuzzles.com/index.aspx?uri=puzzle%2Fslitherlink%2Ftechniques)
  — the canonical starter/basic/advanced taxonomy. Its "Advanced" section is explicitly
  recursion/assumption-based (the technique we exclude).
- [Slitherlink — HandWiki](https://handwiki.org/wiki/Slitherlink) and
  [Kiddle](https://kids.kiddle.co/Slitherlink) — both mirror the **old Wikipedia "Solution
  methods" section, which the live Wikipedia article no longer contains.** They carry the exact
  rule statements for corner rules, diagonal-3s, "3s separated by any number of 2s on a diagonal",
  the diagonal-1s dichotomy, arc notation, and the closed-area even-crossing rule.
- [Para's Puzzle Site — Slitherlink Pattern Guide](http://puzzleparasite.blogspot.com/2011/11/slitherlink-pattern-guide_23.html)
  — a well-organised pattern catalogue.
- [OddThinking — Slitherlinks Hints and Techniques](https://www.somethinkodd.com/oddthinking/2008/01/03/slitherlinks-hints-and-techniques/)
  — source of the very useful **"virtual corner"** generalisation, plus the Jordan-curve rule and
  the explicitly-named "metagaming" uniqueness technique.
- [The Graph Theory Behind Slitherlink — The Puzzle Labs](https://www.thepuzzlelabs.com/slitherlink/the-graph-theory-behind-slitherlink)
  — clean statements of the degree-0-or-2 condition, the single-cycle requirement, and the
  inside/outside ↔ shared-edge biconditional.
- [Slitherlink Corner Patterns — dev.to](https://dev.to/ansonchan/slitherlink-corner-patterns-the-complete-guide-3gcf)
  — precise corner-0/1/2/3 deductions.
- [Slitherlink Reloaded (thesis, David Westreicher)](https://david-westreicher.github.io/static/papers/ba-thesis.pdf)
  — **the best source on the global constraint**: a dedicated chapter "Tackling the 1 Loop
  Problem", plus reachability encodings, confirming single-loop-ness cannot be expressed by local
  constraints alone.
- [Solving Slitherlink with FPGA and SMT Solver (IPSJ JIP 28)](https://www.jstage.jst.go.jp/article/ipsjjip/28/0/28_959/_pdf)
  — same conclusion from the SMT side.

**Moderate:**
- [Puzzolve — Slitherlink Strategies](https://puzzolve.com/intel/slitherlink-strategies)
- [Puzzle-Magazine — Slitherlink Strategy Tips](https://www.puzzle-magazine.com/slitherlink-strategy-tips.php)
- [Slitherlinks.com — 5 Essential Techniques](https://slitherlinks.com/blog/slitherlink-solving-techniques)
  and [The Diagonal 3s Pattern](https://slitherlinks.com/blog/diagonal-3s-pattern)

**Complexity:**
- Yato & Seta, *Complexity and Completeness of Finding Another Solution and Its Application to
  Puzzles*, IEICE Trans. Fundamentals E86-A(5):1052 — proves Slither Link ASP-complete, hence
  NP-complete. **This is the formal reason no finite rule set can solve all instances, and why a
  tiered human-simile solver must be allowed to *fail* rather than silently fall back to search.**
- *Selected Slither Link Variants are NP-complete*, IPSJ JIP 20(3):709.

**Unavailable — noted so nobody re-fetches:** sugurupuzzles.com Slitherlink page (403),
grokipedia.com (403), braingle.com puzzlepedia (403), the classic "A Faster Way To Solve
Slitherlinks" parity essay (domain dead; mirrors not machine-readable),
forum.enjoysudoku.com Slitherlink thread (connection refused), and web.archive.org (blocked). The
old Wikipedia "Solution methods" content was recovered via the HandWiki and Kiddle mirrors instead.
