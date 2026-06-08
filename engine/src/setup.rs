//! Initial-state construction per mode (spec §3.2 pawn counts, §4 modes).
//!
//! Every state starts with an empty board and `turn = 0`. `moves_left_in_turn` is 1 for line modes
//! and 2 for Morph (spec §4.4).

use crate::rng::Rng;
use crate::state::GameState;

fn empty_board(rows: usize, cols: usize) -> Vec<Option<crate::state::Pawn>> {
    vec![None; rows * cols]
}

/// Classic: symbols, no values. Hands hold symbol tokens (value `0`) sized so they exactly fill the
/// board — player 0 takes the extra cell on odd boards (it moves first). Draw = board full.
pub fn classic_state(rows: usize, cols: usize) -> GameState {
    let cells = rows * cols;
    let p0 = cells.div_ceil(2);
    let p1 = cells - p0;
    GameState {
        board: empty_board(rows, cols),
        hands: [vec![0u8; p0], vec![0u8; p1]],
        turn: 0,
        moves_left_in_turn: 1,
        cols,
        rows,
    }
}

/// Pawns per player for Original/Bonanza on a given grid (spec §3.2): equals the max value.
/// 3×3 → 6 (values 1..=6); 4×4 → 11 (values 1..=11).
fn original_pawns_per_player(cells: usize) -> usize {
    match cells {
        9 => 6,
        16 => 11,
        // General fallback: a touch over half the cells, matching the spec's two data points.
        _ => (cells * 11 / 16).max(1),
    }
}

/// Original: both players hold the full value set `1..=N` (their own color), one of each.
pub fn original_state(rows: usize, cols: usize) -> GameState {
    let n = original_pawns_per_player(rows * cols);
    let hand: Vec<u8> = (1..=n as u8).collect();
    GameState {
        board: empty_board(rows, cols),
        hands: [hand.clone(), hand],
        turn: 0,
        moves_left_in_turn: 1,
        cols,
        rows,
    }
}

/// Bonanza: Original with randomized initial hands (spec §4.3). Seeded for reproducibility.
///
/// **Design note (logged in `design-artifacts/bonanza-distribution.md`).** The frozen state model
/// (spec §6) stores hands as `[Vec<u8>; 2]` (values only) and §4.3 requires "the exact same engine
/// as Original" — so a placed pawn's owner is the side to move, exactly as in Original. The spec's
/// per-color k-procedure therefore reduces to *randomizing the value multiset each player holds*:
/// there are two value-pools of `1..=N` (one per color); player 0 draws `k` values from pool 0 and
/// `N-k` from pool 1, player 1 takes the complements. Each hand ends with `N` values (duplicates
/// possible, some values missing) — "no balancing guarantee" (spec §4.3).
pub fn bonanza_state(rows: usize, cols: usize, seed: u64) -> GameState {
    let n = original_pawns_per_player(rows * cols);
    let mut rng = Rng::new(seed);

    // Step 1: random k in 0..=N (k = 0 valid).
    let k = rng.below(n + 1);

    // Step 2 & 3: split each color's full value set 1..=N between the two players.
    let mut pool0: Vec<u8> = (1..=n as u8).collect();
    let mut pool1: Vec<u8> = (1..=n as u8).collect();
    rng.shuffle(&mut pool0);
    rng.shuffle(&mut pool1);

    let mut hand0: Vec<u8> = Vec::with_capacity(n);
    let mut hand1: Vec<u8> = Vec::with_capacity(n);

    // From pool 0 (color 0): player 0 takes k, player 1 takes the rest.
    hand0.extend_from_slice(&pool0[..k]);
    hand1.extend_from_slice(&pool0[k..]);
    // From pool 1 (color 1): player 0 takes N-k, player 1 takes the rest (k).
    hand0.extend_from_slice(&pool1[..n - k]);
    hand1.extend_from_slice(&pool1[n - k..]);

    hand0.sort_unstable();
    hand1.sort_unstable();

    GameState {
        board: empty_board(rows, cols),
        hands: [hand0, hand1],
        turn: 0,
        moves_left_in_turn: 1,
        cols,
        rows,
    }
}

/// Max value for Morph on a grid (spec §3.2): 4×4 → 6, 5×5 → 11. Each player holds **two** of each.
fn morph_max_value(cells: usize) -> usize {
    match cells {
        16 => 6,
        25 => 11,
        _ => (cells / 2).max(1),
    }
}

/// Morph: own color only, two of every value `1..=N` (spec §3.2). Single alternating placement —
/// one stone per turn (changed from two).
pub fn morph_state(rows: usize, cols: usize) -> GameState {
    let n = morph_max_value(rows * cols);
    let mut hand: Vec<u8> = Vec::with_capacity(2 * n);
    for v in 1..=n as u8 {
        hand.push(v);
        hand.push(v);
    }
    GameState {
        board: empty_board(rows, cols),
        hands: [hand.clone(), hand],
        turn: 0,
        moves_left_in_turn: 1,
        cols,
        rows,
    }
}
