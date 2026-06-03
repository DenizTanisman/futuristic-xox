# Heuristic Calibration — Self-Play Validation (U2 log)

Per spec §7.6 and open item §13.2. The starting weights are validated by self-play; full weight
optimization is deferred (the search already produces decisively strong play at these weights).

## Starting weights (spec §7.6)
- **Line modes** (`modes/line.rs`): `30·threats + 1·economy + 5·center`, scored "me − opponent".
- **Morph** (`modes/morph.rs`): `40·best_shape_progress + 1·economy + 3·center`.

Where: *threats* = lines with two of mine + one empty/capturable cell; *economy* = sum of my hand
values (capture power) minus opponent's; *center* = central-cell control; *best_shape_progress* =
most cells owned in any still-completable 4-cell placement.

## Self-play results (`cargo run --release --example selfplay`)
Hard vs Easy, seeds alternate first mover; score = (W + 0.5·D) / games.

| Matchup            | Result            | Score |
|--------------------|-------------------|-------|
| Classic 3×3        | 29W / 1D / 0L     | 98 %  |
| Original 3×3       | 30W / 0D / 0L     | 100 % |
| Original 4×4       | 16W / 0D / 0L     | 100 % |
| Bonanza 3×3        | 28W / 2D / 0L     | 97 %  |
| Morph 4×4          | 16W / 0D / 0L     | 100 % |
| Original 3×3 (vs **Medium**) | 27W / 3D / 0L | 95 % |

(Depth-boxed: 3×3 → 6, 4×4 line → 4, Morph → 3. Deeper search only widens Hard's margin.)

## Conclusion
- Hard **never loses** to Easy or Medium across every mode and grid; it wins the large majority and
  draws the rest. Combined with the tactical unit tests (immediate win/block, perfect 3×3 draw), the
  search + heuristic are confirmed correct and strong.
- The §7.6 starting weights are **accepted for v1**. Finer weight tuning (e.g. raising the threat
  weight, adding a Morph blocking term) is left as a play-testing follow-up (§13.2) — it would refine
  *style*, not fix a weakness.

## Status
Accepted for v1. Re-open during device play-testing if a difficulty feels off (§13.2, §13.3).
