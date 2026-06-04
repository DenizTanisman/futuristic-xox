# Morph Shapes — Final Chosen Sets (U1 log)

Per spec §5 and open item §13.1. Shapes are defined once as relative `(row, col)` cells; the engine
derives all rotations + mirror and slides them over the grid. Coordinates are **not** hand-listed.

## Base shapes (relative cells)
- **I** (straight tetromino): `[(0,0), (0,1), (0,2), (0,3)]`
- **L** (L-tetromino): `[(0,0), (1,0), (2,0), (2,1)]`
- **Z** (Z/S-tetromino): `[(0,1), (0,2), (1,0), (1,1)]`

## Orientation handling
4 rotations × {identity, mirror}, deduplicated by normalized cell set:
- **I → 2** distinct orientations (horizontal, vertical).
- **L → 8** distinct orientations.
- **Z → 4** distinct orientations.

## Diagonal placements — INCLUDED (updated in play-testing, spec §5/§13.1)
The original defensive default *excluded* the diagonal "I". **Play-testing reversed this**: the
intended game wants diagonal/staircase shapes too. The fix is a **Morph-only basis-vector**
generalization (line modes untouched):
- **Axis basis** `row=(+1,0) col=(0,+1)` → classic axis-aligned placements.
- **Diagonal basis** `row=(+1,-1) col=(+1,+1)` → staircase placements (e.g. diagonal I `0,5,10,15`).

Each orientation (4 rotations + mirror) is laid under both bases and slid over every anchor
(bounds-checked, deduped). Verified by `dart_engine_test.dart`: horizontal, vertical, main-diagonal,
and anti-diagonal I are all present, and a diagonal-I completion is detected as a win.

> The earlier `morph_excludes_pure_diagonal` assertion is obsolete and removed; the diagonal I is now
> a valid placement by design.

## Generated placement counts (sliding window, deduped)
| Grid | Total 4-cell placements |
|------|-------------------------|
| 4×4  | 80                      |
| 5×5  | 164                     |

A win is any placement whose 4 cells are all owned by one player (`rules::winner_on_placements`).
Property-tested in `tests/morph.rs::every_precomputed_shape_is_a_win_when_fully_owned`.

## Status
Accepted for v1. Revisit only if play-testing contradicts (spec §5, §13.1).
