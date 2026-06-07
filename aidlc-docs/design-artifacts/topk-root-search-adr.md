# ADR — Top-k alpha-beta at the root (honest top-3)

- **Status:** Accepted
- **Context:** The adversarial search must return the **top-3 ranked** root moves with scores such that
  `first_score ≥ second_score ≥ third_score`, so a selection layer can play the 2nd/3rd option. The
  existing negamax + alpha-beta is a **single-value** search: each node returns only the best score
  for the side to move, and a normal root raises `alpha` to the best-so-far, which makes every later
  root move searched against a tighter window. Those later moves may **fail low** — their returned
  score is then only an *upper bound*, not exact. That is fine for picking the single best move but
  **wrong for ranking** 2nd and 3rd.

## Decision

Change **only the root**. Keep a running **top-3** of `(move, score)` and set the pruning bound to the
**current 3rd-best** score, not the best:

- `beta = INF` at the root (no fail-high at the root).
- `alpha = third_best_so_far` once three candidates exist; `alpha = -INF` until then.
- A root move scoring **below** the current 3rd place fails low and is discarded — still pruned, so
  most of the speed is kept. A move that **breaks into** the top-3 is searched with `beta = INF`, so
  its value is **exact**, and the ranking among the retained three is correct.

Because the first three root moves are searched while fewer than three candidates exist (`alpha = -INF`),
they all get exact scores; from then on `alpha` rises monotonically to the 3rd-best, and any move that
breaks in is re-scored exactly. The three retained moves are therefore always the true top-3 with exact
scores.

Iterative deepening keeps the **last fully completed** depth's top-3 (a timed-out depth is discarded);
the previous depth's `first` seeds move ordering. Padding guarantees the never-`None` invariant: slots
start identical and missing slots repeat the weakest available move, so `1 → first==second==third`,
`2 distinct → third==second`, `≥3 → true top-3`. `adversarial_search` returns `None` only at a terminal
position (no legal moves).

## Alternatives considered

- **Full-window per root move** (`alpha = -INF, beta = INF` for every root child): gives exact scores
  for *all* root moves and thus a perfect full ranking, but **disables root pruning** — the most
  expensive option, and we only need the top-3. Rejected on cost.
- **Accept clipped 2nd/3rd** (normal root, alpha at best): cheapest, but 2nd/3rd scores become
  unreliable upper bounds and the ranking is wrong — defeats the purpose. Rejected on correctness.

## Consequences

- Pruning is preserved for everything below 3rd place; only the top band is searched on a wide window.
- Interior `negamax`, TT, the negation-on-turn-flip rule (Morph two-move turns), and the time box are
  **unchanged** — the change is localized and low-risk.
- A regression test asserts `adversarial_search(..).first` equals the independent full-window argmax
  over root moves at a fixed depth (the top-k bound must not degrade the best move).
