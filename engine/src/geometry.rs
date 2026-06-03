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

/// Every concrete 4-cell placement of every Morph shape on a `rows×cols` grid (spec §5):
/// all orientations of I/L/Z, slid over every position that fits. Deduplicated by cell set.
///
/// The straight I appears in all 4 orientations; the pure corner-to-corner diagonal is *not* a
/// tetromino orientation and therefore never appears (spec §5 defensive default).
pub fn morph_placements(rows: usize, cols: usize) -> Vec<[usize; 4]> {
    let mut placements: Vec<[usize; 4]> = Vec::new();
    let mut seen: Vec<[usize; 4]> = Vec::new();

    for base in base_shapes() {
        for orient in orientations(&base) {
            let max_r = orient.iter().map(|&(r, _)| r).max().unwrap();
            let max_c = orient.iter().map(|&(_, c)| c).max().unwrap();
            if max_r as usize >= rows || max_c as usize >= cols {
                continue;
            }
            // Slide the bounding box over every valid top-left offset.
            for off_r in 0..(rows - max_r as usize) {
                for off_c in 0..(cols - max_c as usize) {
                    let mut cells = [0usize; 4];
                    for (i, &(r, c)) in orient.iter().enumerate() {
                        let rr = off_r + r as usize;
                        let cc = off_c + c as usize;
                        cells[i] = rr * cols + cc;
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
            let ps = morph_placements(rows, cols);
            assert!(!ps.is_empty());
            for p in &ps {
                let mut sorted = *p;
                sorted.sort_unstable();
                // 4 distinct, in-bounds cells.
                assert!(sorted.windows(2).all(|w| w[0] < w[1]), "cells must be distinct");
                assert!(p.iter().all(|&c| c < rows * cols));
            }
        }
    }

    #[test]
    fn morph_excludes_pure_diagonal() {
        // The main diagonal of a 4×4 (0,5,10,15) is a line, not a tetromino — must not appear.
        let ps = morph_placements(4, 4);
        let diag = {
            let mut d = [0, 5, 10, 15];
            d.sort_unstable();
            d
        };
        assert!(!ps.iter().any(|p| {
            let mut s = *p;
            s.sort_unstable();
            s == diag
        }));
    }
}
