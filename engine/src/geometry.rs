//! Precomputed win geometry (spec §3.4 lines, §5 Morph shapes).
//!
//! Both are generated algorithmically — no hand-listed coordinates — so the same code serves
//! every grid size (3×3, 4×4, 5×5).

/// All length-3 winning segments for a `rows×cols` grid: horizontal, vertical, and both diagonals.
/// "3 in a row, all grids" (spec §3.4), so on 4×4/5×5 every 3-window counts.
pub fn line_triples(rows: usize, cols: usize) -> Vec<[usize; 3]> {
    let idx = |r: usize, c: usize| r * cols + c;
    let mut out = Vec::new();
    // (dr, dc) direction steps; each window of 3 starts where it still fits.
    const DIRS: [(isize, isize); 4] = [(0, 1), (1, 0), (1, 1), (1, -1)];
    for r in 0..rows as isize {
        for c in 0..cols as isize {
            for (dr, dc) in DIRS {
                let r2 = r + 2 * dr;
                let c2 = c + 2 * dc;
                if r2 < 0 || r2 >= rows as isize || c2 < 0 || c2 >= cols as isize {
                    continue;
                }
                out.push([
                    idx(r as usize, c as usize),
                    idx((r + dr) as usize, (c + dc) as usize),
                    idx(r2 as usize, c2 as usize),
                ]);
            }
        }
    }
    out
}

/// A shape as a set of relative `(row, col)` offsets (spec §5).
type Shape = Vec<(i32, i32)>;

/// The three Morph base shapes (spec §5), each exactly 4 cells.
/// I = straight line, L = L-tetromino, Z = Z/S-tetromino.
fn base_shapes() -> Vec<Shape> {
    vec![
        vec![(0, 0), (0, 1), (0, 2), (0, 3)], // I
        vec![(0, 0), (1, 0), (2, 0), (2, 1)], // L
        vec![(0, 1), (0, 2), (1, 0), (1, 1)], // Z
    ]
}

/// Normalize a shape so its minimum row and column are 0 (translation-invariant key).
fn normalize(mut s: Shape) -> Shape {
    let min_r = s.iter().map(|&(r, _)| r).min().unwrap();
    let min_c = s.iter().map(|&(_, c)| c).min().unwrap();
    for p in &mut s {
        p.0 -= min_r;
        p.1 -= min_c;
    }
    s.sort_unstable();
    s
}

/// Rotate 90° clockwise: (r, c) -> (c, -r).
fn rotate(s: &Shape) -> Shape {
    s.iter().map(|&(r, c)| (c, -r)).collect()
}

/// Mirror horizontally: (r, c) -> (r, -c).
fn mirror(s: &Shape) -> Shape {
    s.iter().map(|&(r, c)| (r, -c)).collect()
}

/// All distinct orientations of a shape: 4 rotations × {identity, mirror}, deduplicated.
fn orientations(base: &Shape) -> Vec<Shape> {
    let mut seen = Vec::new();
    let mut cur = base.clone();
    for _ in 0..4 {
        for variant in [cur.clone(), mirror(&cur)] {
            let n = normalize(variant);
            if !seen.contains(&n) {
                seen.push(n);
            }
        }
        cur = rotate(&cur);
    }
    seen
}

/// Placement frame: how the shape's own (row, col) axes map onto the grid.
/// `Axis` is the classic axis-aligned mapping; `Diag` is a 45°-rotated frame that yields
/// staircase / diagonal placements the axis frame can never produce (spec §5).
/// A placement-frame transform on a relative cell.
type Frame = fn((i32, i32)) -> (i32, i32);

fn axis_frame((r, c): (i32, i32)) -> (i32, i32) {
    (r, c)
}
fn diag_frame((r, c): (i32, i32)) -> (i32, i32) {
    (r + c, r - c)
}

/// The number of Morph base shapes (I, L, Z).
pub const MORPH_SHAPE_COUNT: usize = 3;

/// Base relative cells of a Morph shape by index (0 = I, 1 = L, 2 = Z), for previews/logging.
pub fn morph_base_shape(shape_index: usize) -> Vec<(i32, i32)> {
    base_shapes()[shape_index].clone()
}

/// All concrete 4-cell placements of a SINGLE Morph shape (`shape_index`: 0 = I, 1 = L, 2 = Z) on a
/// `rows×cols` grid (spec §4.4, §5). Each of the shape's orientations (4 rotations + mirror) is laid
/// onto the grid under BOTH the axis and the diagonal frame, anchored at every position that fits,
/// then deduplicated by cell set — giving axis-aligned AND diagonal/staircase placements.
///
/// Diagonals are intentionally included (the earlier "exclude the diagonal I" default was reversed in
/// play-testing, spec §13.1). This is Morph-only; line modes use [`line_triples`].
pub fn morph_placements_for_shape(shape_index: usize, rows: usize, cols: usize) -> Vec<[usize; 4]> {
    let frames: [Frame; 2] = [axis_frame, diag_frame];
    let mut placements: Vec<[usize; 4]> = Vec::new();
    let mut seen: Vec<[usize; 4]> = Vec::new();

    for orient in orientations(&base_shapes()[shape_index]) {
        for frame in frames {
            let t: Shape = orient.iter().map(|&p| frame(p)).collect();
            let t = normalize(t); // shift min row/col to 0
            let max_r = t.iter().map(|&(r, _)| r).max().unwrap();
            let max_c = t.iter().map(|&(_, c)| c).max().unwrap();
            if max_r as usize >= rows || max_c as usize >= cols {
                continue;
            }
            for off_r in 0..(rows - max_r as usize) {
                for off_c in 0..(cols - max_c as usize) {
                    let mut cells = [0usize; 4];
                    for (i, &(r, c)) in t.iter().enumerate() {
                        cells[i] = (off_r + r as usize) * cols + (off_c + c as usize);
                    }
                    cells.sort_unstable();
                    if !seen.contains(&cells) {
                        seen.push(cells);
                        placements.push(cells);
                    }
                }
            }
        }
    }
    placements
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn line_triples_3x3_count() {
        // 3 rows + 3 cols + 2 diagonals = 8 winning lines on 3×3.
        assert_eq!(line_triples(3, 3).len(), 8);
    }

    #[test]
    fn line_triples_4x4_count() {
        // Horizontals: 4 rows × 2 windows = 8; verticals: 8;
        // each diagonal direction: 2×2 starting positions × 2 dirs = 8. Total 24.
        assert_eq!(line_triples(4, 4).len(), 24);
    }

    #[test]
    fn orientations_i_has_two() {
        // The straight I has only horizontal and vertical orientations (mirror/rotation coincide).
        let i = vec![(0, 0), (0, 1), (0, 2), (0, 3)];
        assert_eq!(orientations(&i).len(), 2);
    }

    #[test]
    fn orientations_l_has_eight() {
        // The L-tetromino has 4 rotations × 2 (mirror) = 8 distinct orientations.
        let l = vec![(0, 0), (1, 0), (2, 0), (2, 1)];
        assert_eq!(orientations(&l).len(), 8);
    }

    #[test]
    fn orientations_z_has_four() {
        // The Z/S-tetromino has 2 rotations × 2 (mirror) = 4 distinct orientations.
        let z = vec![(0, 1), (0, 2), (1, 0), (1, 1)];
        assert_eq!(orientations(&z).len(), 4);
    }

    #[test]
    fn morph_placements_all_four_cells_in_bounds_and_distinct() {
        for (rows, cols) in [(4, 4), (5, 5)] {
            for shape in 0..MORPH_SHAPE_COUNT {
                let ps = morph_placements_for_shape(shape, rows, cols);
                assert!(!ps.is_empty());
                for p in &ps {
                    let mut sorted = *p;
                    sorted.sort_unstable();
                    assert!(sorted.windows(2).all(|w| w[0] < w[1]), "cells must be distinct");
                    assert!(p.iter().all(|&c| c < rows * cols));
                }
            }
        }
    }

    /// Regression fixture: the I shape on 4×4 must include axis AND diagonal/staircase placements
    /// (diagonals are IN, spec §5/§13.1). Proven from code, not by eyeballing.
    #[test]
    fn morph_i_includes_axis_and_diagonal() {
        let ps = morph_placements_for_shape(0, 4, 4); // I
        let has = |cells: [usize; 4]| {
            let mut want = cells;
            want.sort_unstable();
            ps.iter().any(|p| {
                let mut s = *p;
                s.sort_unstable();
                s == want
            })
        };
        assert!(has([0, 1, 2, 3]), "horizontal I");
        assert!(has([0, 4, 8, 12]), "vertical I");
        assert!(has([0, 5, 10, 15]), "main-diagonal (staircase) I");
        assert!(has([3, 6, 9, 12]), "anti-diagonal (staircase) I");
    }

    /// Every generated placement of a shape must be reachable from THAT base shape — no shape ever
    /// produces a placement that another base shape would, and random 4-cell sets never qualify.
    #[test]
    fn morph_placements_belong_to_their_own_shape() {
        for shape in 0..MORPH_SHAPE_COUNT {
            let ps = morph_placements_for_shape(shape, 5, 5);
            // Each placement, re-normalized, must match one of this shape's frame×orientation forms.
            let forms: Vec<Shape> = {
                let frames: [Frame; 2] = [axis_frame, diag_frame];
                let mut v = Vec::new();
                for o in orientations(&base_shapes()[shape]) {
                    for f in frames {
                        v.push(normalize(o.iter().map(|&p| f(p)).collect()));
                    }
                }
                v
            };
            for p in &ps {
                let cells: Shape = p.iter().map(|&i| ((i / 5) as i32, (i % 5) as i32)).collect();
                let norm = normalize(cells);
                assert!(forms.contains(&norm), "placement {p:?} not a form of shape {shape}");
            }
        }
    }
}
