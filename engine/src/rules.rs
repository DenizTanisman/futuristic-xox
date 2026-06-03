//! Shared rule helpers used by the mode implementations: legality (spec §3.3), move generation,
//! win detection, and pure turn advancement with the Morph single-move fallback (spec §4.4).

use crate::state::{GameState, Move, Pawn};

/// Distinct values in the side-to-move's hand, ascending. Move generation uses one move per
/// *distinct* value per cell (placing one `5` is the same move whichever physical `5` you use).
pub fn distinct_hand_values(s: &GameState) -> Vec<u8> {
    let mut v: Vec<u8> = s.current_hand().to_vec();
    v.sort_unstable();
    v.dedup();
    v
}

/// Legality of placing `value` (held by `owner`) on `cell` (spec §3.3):
/// empty → legal; own pawn → illegal; enemy pawn → legal iff strictly greater (captures).
#[inline]
pub fn placement_legal(s: &GameState, cell: usize, value: u8, owner: u8) -> bool {
    match s.at(cell) {
        None => true,
        Some(p) if p.owner == owner => false,
        Some(p) => value > p.value,
    }
}

/// Public legality check for a full `Move` (used by the UI/bridge before calling `apply`).
/// Validates bounds, hand ownership, and placement rules. Classic moves carry `value: None`.
pub fn is_move_legal(s: &GameState, m: &Move, valued: bool) -> bool {
    if !s.in_bounds(m.cell) {
        return false;
    }
    match (valued, m.value) {
        (false, None) => s.at(m.cell).is_none() && !s.current_hand().is_empty(),
        (false, Some(_)) => false,
        (true, None) => false,
        (true, Some(v)) => {
            s.current_hand().contains(&v) && placement_legal(s, m.cell, v, s.turn)
        }
    }
}

// ---- Valued move generation (Original / Bonanza / Morph) ----

/// All legal valued moves: each distinct hand value × each cell it may legally occupy (spec §7.5).
pub fn valued_legal_moves(s: &GameState) -> Vec<Move> {
    let owner = s.turn;
    let values = distinct_hand_values(s);
    let mut out = Vec::with_capacity(values.len() * 4);
    for cell in 0..s.cell_count() {
        match s.at(cell) {
            None => {
                for &v in &values {
                    out.push(Move { value: Some(v), cell });
                }
            }
            Some(p) if p.owner == owner => {} // own pawn → no move
            Some(p) => {
                for &v in &values {
                    if v > p.value {
                        out.push(Move { value: Some(v), cell });
                    }
                }
            }
        }
    }
    out
}

/// Cheap "is there any move?" check for `is_terminal` (avoids allocating the move list).
pub fn valued_has_legal_move(s: &GameState) -> bool {
    let hand = s.current_hand();
    let Some(&max_v) = hand.iter().max() else {
        return false; // empty hand
    };
    let owner = s.turn;
    for cell in 0..s.cell_count() {
        match s.at(cell) {
            None => return true,
            Some(p) if p.owner == owner => {}
            Some(p) => {
                if max_v > p.value {
                    return true;
                }
            }
        }
    }
    false
}

// ---- Classic move generation ----

/// Classic legal moves: place a symbol on any empty cell (spec §4.1).
pub fn classic_legal_moves(s: &GameState) -> Vec<Move> {
    if s.current_hand().is_empty() {
        return Vec::new();
    }
    (0..s.cell_count())
        .filter(|&c| s.at(c).is_none())
        .map(|cell| Move { value: None, cell })
        .collect()
}

/// Cheap existence check for Classic.
pub fn classic_has_legal_move(s: &GameState) -> bool {
    !s.current_hand().is_empty() && (0..s.cell_count()).any(|c| s.at(c).is_none())
}

// ---- Win detection ----

/// First fully-owned 3-line, if any (spec §3.4). Only the last mover can complete a line, so
/// returning the first match is correct.
pub fn winner_on_lines(s: &GameState, lines: &[[usize; 3]]) -> Option<u8> {
    for line in lines {
        if let (Some(a), Some(b), Some(c)) = (s.at(line[0]), s.at(line[1]), s.at(line[2])) {
            if a.owner == b.owner && b.owner == c.owner {
                return Some(a.owner);
            }
        }
    }
    None
}

/// First fully-owned 4-cell shape placement, if any (spec §5).
pub fn winner_on_placements(s: &GameState, placements: &[[usize; 4]]) -> Option<u8> {
    for p in placements {
        if let Some(a) = s.at(p[0]) {
            let o = a.owner;
            if p[1..].iter().all(|&c| s.at(c).is_some_and(|q| q.owner == o)) {
                return Some(o);
            }
        }
    }
    None
}

// ---- Pure transitions ----

/// Advance the turn after a placement (spec §6, §4.4). Decrements `moves_left_in_turn`; flips `turn`
/// only at 0. Mid-turn (Morph), if the same player has no legal second move, end their turn
/// (single-move fallback, spec §4.4). `has_move` reports whether the side to move can move.
fn advance_turn(ns: &mut GameState, moves_per_turn: u8, has_move: impl Fn(&GameState) -> bool) {
    ns.moves_left_in_turn -= 1;
    if ns.moves_left_in_turn == 0 {
        ns.turn ^= 1;
        ns.moves_left_in_turn = moves_per_turn;
    } else if !has_move(ns) {
        // Same player still to move but cannot — consume the remaining move(s) and pass.
        ns.turn ^= 1;
        ns.moves_left_in_turn = moves_per_turn;
    }
}

/// Pure apply for valued modes (Original/Bonanza/Morph). Assumes `m` is legal (search only ever
/// passes legal moves; the UI guards with `is_move_legal`). Captures overwrite the enemy pawn,
/// deleting it permanently — it never returns to hand (spec §3.3).
pub fn apply_valued(
    s: &GameState,
    m: &Move,
    moves_per_turn: u8,
    has_move: impl Fn(&GameState) -> bool,
) -> GameState {
    let mut ns = s.clone();
    let owner = ns.turn;
    let v = m.value.expect("valued move must carry a value");
    ns.board[m.cell] = Some(Pawn { owner, value: v });
    if let Some(pos) = ns.hands[owner as usize].iter().position(|&x| x == v) {
        ns.hands[owner as usize].remove(pos);
    }
    advance_turn(&mut ns, moves_per_turn, has_move);
    ns
}

/// Pure apply for Classic: place a symbol (value `0`), consume one token, advance the turn.
pub fn apply_classic(s: &GameState, m: &Move) -> GameState {
    let mut ns = s.clone();
    let owner = ns.turn;
    ns.board[m.cell] = Some(Pawn { owner, value: 0 });
    ns.hands[owner as usize].pop();
    advance_turn(&mut ns, 1, classic_has_legal_move);
    ns
}

// ---- Ordering helpers ----

/// Doubled-coordinate Manhattan distance from a cell to the board center (smaller = more central).
/// Doubled to stay integer for even/odd dimensions alike.
pub fn center_distance(s: &GameState, cell: usize) -> i32 {
    let (r, c) = s.rc(cell);
    let cr = (s.rows - 1) as i32; // = 2 * center_row
    let cc = (s.cols - 1) as i32;
    (2 * r as i32 - cr).abs() + (2 * c as i32 - cc).abs()
}

/// Value of the enemy pawn this move would capture (0 if it does not capture).
#[inline]
pub fn capture_gain(s: &GameState, m: &Move) -> i32 {
    match s.at(m.cell) {
        Some(p) if p.owner != s.turn => p.value as i32,
        _ => 0,
    }
}
