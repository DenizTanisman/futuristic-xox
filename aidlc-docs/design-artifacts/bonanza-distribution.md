# Bonanza Hand Distribution — Design Decision (U1 log)

Per spec §4.3 and the autonomy rule for design ambiguity (spec §10.3 case C: take the most defensive
option, log it, continue).

## The ambiguity
Spec §4.3 describes randomizing hands across "own-color" and "opponent-color" pawns and says "may own
none of own color." Taken literally, that implies a pawn's *color* (= board owner, for win lines) is
intrinsic and can differ from who holds it. But the **frozen state model** (spec §6) stores hands as
`[Vec<u8>; 2]` — **values only, no per-pawn color** — and §4.3 also mandates "the exact same engine
and AI as Original (different starting state only)."

These cannot both hold if holding an opponent-color pawn placed an *opponent-owned* pawn on the board:
that would require per-pawn color in the hand and a different `apply` than Original.

## Decision (most defensive, model-consistent)
A placed pawn's **owner is always the side to move**, identical to Original. Bonanza's randomization
therefore takes effect as a **randomized value multiset per hand**:

1. `k = rand(0..=N)` where `N` = pawns per player (= max value; 6 on 3×3, 11 on 4×4).
2. Two value pools, each `1..=N` (the two colors). Shuffle both.
3. Player 0 draws `k` values from pool 0 and `N-k` from pool 1; player 1 takes the complements.
4. Each hand ends with exactly `N` values — duplicates possible, some values missing, **no balancing
   guarantee** (spec §4.3).

The combined pool is conserved: both hands together are always exactly two copies of `1..=N`
(property-tested in `tests/setup_modes.rs::bonanza_preserves_the_pawn_pool`).

## Consequence
- Satisfies §3.2 counts, §4.3 steps 1–3, §6 state model, and "same engine as Original."
- The strategic effect of §4.3 — an unbalanced, possibly duplicate-heavy hand — is fully preserved.
- The only thing dropped is the (model-incompatible) notion of placing opponent-colored pawns.
- **Flag:** if play-testing reveals §4.3 intended players to place opponent-colored pawns on the
  board, this needs a state-model change (per-pawn color in hands) and would no longer be "the same
  engine as Original." Revisit then.

## Status
Accepted for v1, seeded + reproducible (`rng::Rng`, SplitMix64).
