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

## Defensive defaults applied (spec §5, §13.1)
- The **straight I is included in all valid orientations** (horizontal + vertical).
- The **pure corner-to-corner diagonal is excluded** — it is a line, not the I tetromino.
  Verified by `geometry::tests::morph_excludes_pure_diagonal` (the 4×4 main diagonal `[0,5,10,15]`
  never appears as a placement).

## Generated placement counts (sliding window, deduped)
| Grid | Total 4-cell placements |
|------|-------------------------|
| 4×4  | 80                      |
| 5×5  | 164                     |

A win is any placement whose 4 cells are all owned by one player (`rules::winner_on_placements`).
Property-tested in `tests/morph.rs::every_precomputed_shape_is_a_win_when_fully_owned`.

## Status
Accepted for v1. Revisit only if play-testing contradicts (spec §5, §13.1).
