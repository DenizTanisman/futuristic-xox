//! Morph mode: valued + capture (identical to Original), two moves per turn, win = complete a
//! randomly chosen 4-cell shape (spec §4.4, §5). Reuses the valued move/capture/apply helpers.

use crate::geometry::morph_placements;
use crate::mode::{Mode, WIN};
use crate::rules::*;
use crate::state::{GameResult, GameState, Move};

/// Starting heuristic weights (spec §7.6). Calibrated in U2 (spec §13.2).
const W_SHAPE: i32 = 40; // per owned cell in the best still-completable placement
const W_ECONOMY: i32 = 1;
const W_CENTER: i32 = 3;

pub struct MorphMode {
    /// Precomputed concrete 4-cell shape placements (all I/L/Z orientations, slid over the grid).
    placements: Vec<[usize; 4]>,
}

impl MorphMode {
    pub fn new(rows: usize, cols: usize) -> Self {
        MorphMode {
            placements: morph_placements(rows, cols),
        }
    }

    /// Precomputed placements (exposed for the design-artifact log and AI move ordering).
    pub fn placements(&self) -> &[[usize; 4]] {
        &self.placements
    }

    /// Best shape progress for `owner`: the most cells owned in any placement that contains no
    /// enemy pawn (i.e. is still completable by `owner`). Range 0..=4.
    fn best_progress(&self, s: &GameState, owner: u8) -> i32 {
        let mut best = 0;
        for p in &self.placements {
            let mut mine = 0;
            let mut blocked = false;
            for &cell in p {
                match s.at(cell) {
                    Some(q) if q.owner == owner => mine += 1,
                    Some(_) => {
                        blocked = true;
                        break;
                    }
                    None => {}
                }
            }
            if !blocked && mine > best {
                best = mine;
            }
        }
        best
    }

    fn center_control(&self, s: &GameState, owner: u8) -> i32 {
        (0..s.cell_count())
            .filter(|&c| center_distance(s, c) == 0)
            .filter(|&c| s.at(c).is_some_and(|p| p.owner == owner))
            .count() as i32
    }
}

impl Mode for MorphMode {
    fn legal_moves(&self, s: &GameState) -> Vec<Move> {
        valued_legal_moves(s)
    }

    fn ordered_moves(&self, s: &GameState) -> Vec<Move> {
        let mut moves = self.legal_moves(s);
        moves.sort_by_key(|m| {
            let gain = capture_gain(s, m);
            let own = m.value.unwrap_or(0) as i32;
            (-gain, own, center_distance(s, m.cell))
        });
        moves
    }

    fn apply(&self, s: &GameState, m: &Move) -> GameState {
        // Two moves per turn; `apply_valued` flips the turn only when `moves_left_in_turn` hits 0,
        // and applies the single-move fallback when no second move exists (spec §4.4).
        apply_valued(s, m, 2, valued_has_legal_move)
    }

    fn is_terminal(&self, s: &GameState) -> Option<GameResult> {
        if let Some(w) = winner_on_placements(s, &self.placements) {
            return Some(GameResult::Win(w));
        }
        (!valued_has_legal_move(s)).then_some(GameResult::Draw)
    }

    fn terminal_score(&self, r: &GameResult, s: &GameState, depth: i32) -> i32 {
        match r {
            GameResult::Win(o) => {
                if *o == s.turn {
                    WIN - depth
                } else {
                    depth - WIN
                }
            }
            GameResult::Draw => 0,
        }
    }

    fn heuristic(&self, s: &GameState) -> i32 {
        let me = s.turn;
        let opp = 1 - me;
        let shape = self.best_progress(s, me) - self.best_progress(s, opp);
        let economy = s.hands[me as usize].iter().map(|&v| v as i32).sum::<i32>()
            - s.hands[opp as usize].iter().map(|&v| v as i32).sum::<i32>();
        let center = self.center_control(s, me) - self.center_control(s, opp);
        W_SHAPE * shape + W_ECONOMY * economy + W_CENTER * center
    }
}
