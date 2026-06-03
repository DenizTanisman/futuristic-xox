//! Line modes: Classic (`valued = false`) and Original/Bonanza (`valued = true`).
//! Win = 3 in a row (spec §3.4, §4.1–4.3). One move per turn.

use crate::geometry::line_triples;
use crate::mode::{Mode, WIN};
use crate::rules::*;
use crate::state::{GameResult, GameState, Move};

/// Starting heuristic weights (spec §7.6). Placeholders — U2 calibrates via self-play (spec §13.2).
const W_THREAT: i32 = 30;
const W_ECONOMY: i32 = 1;
const W_CENTER: i32 = 5;

pub struct LineMode {
    /// `false` = Classic (symbols, no capture); `true` = Original/Bonanza (valued + capture).
    valued: bool,
    /// Precomputed winning 3-lines for this grid.
    lines: Vec<[usize; 3]>,
}

impl LineMode {
    pub fn new(rows: usize, cols: usize, valued: bool) -> Self {
        LineMode {
            valued,
            lines: line_triples(rows, cols),
        }
    }

    #[inline]
    pub fn is_valued(&self) -> bool {
        self.valued
    }

    /// Count of `owner`'s pawns sitting on the central cell(s) of the board.
    fn center_control(&self, s: &GameState, owner: u8) -> i32 {
        (0..s.cell_count())
            .filter(|&c| center_distance(s, c) == 0)
            .filter(|&c| s.at(c).is_some_and(|p| p.owner == owner))
            .count() as i32
    }

    /// Number of lines that are a *threat* for `owner`: exactly two of `owner`'s pawns plus a third
    /// cell that is empty or capturable by `owner` (spec §7.6).
    fn threats(&self, s: &GameState, owner: u8) -> i32 {
        let max_hand = s.hands[owner as usize].iter().max().copied().unwrap_or(0);
        let mut count = 0;
        for line in &self.lines {
            let mut mine = 0;
            let mut open: Option<usize> = None;
            let mut blocked = false;
            for &cell in line {
                match s.at(cell) {
                    Some(p) if p.owner == owner => mine += 1,
                    Some(_) => {
                        // an enemy pawn here keeps the line alive only if it is the single open
                        // cell and is capturable; track it as the "open" slot.
                        if open.is_some() {
                            blocked = true;
                        }
                        open = Some(cell);
                    }
                    None => {
                        if open.is_some() {
                            blocked = true;
                        }
                        open = Some(cell);
                    }
                }
            }
            if blocked || mine != 2 {
                continue;
            }
            // exactly two mine and one open slot; open must be empty or capturable.
            if let Some(cell) = open {
                let usable = match s.at(cell) {
                    None => true,
                    Some(p) => p.owner != owner && max_hand > p.value,
                };
                if usable {
                    count += 1;
                }
            }
        }
        count
    }
}

impl Mode for LineMode {
    fn legal_moves(&self, s: &GameState) -> Vec<Move> {
        if self.valued {
            valued_legal_moves(s)
        } else {
            classic_legal_moves(s)
        }
    }

    fn ordered_moves(&self, s: &GameState) -> Vec<Move> {
        let mut moves = self.legal_moves(s);
        // captures first (MVV-LVA: biggest capture, cheapest pawn), then most-central (spec §7.7.2).
        moves.sort_by_key(|m| {
            let gain = capture_gain(s, m);
            let own = m.value.unwrap_or(0) as i32;
            (-gain, own, center_distance(s, m.cell))
        });
        moves
    }

    fn apply(&self, s: &GameState, m: &Move) -> GameState {
        if self.valued {
            apply_valued(s, m, 1, valued_has_legal_move)
        } else {
            apply_classic(s, m)
        }
    }

    fn is_terminal(&self, s: &GameState) -> Option<GameResult> {
        if let Some(w) = winner_on_lines(s, &self.lines) {
            return Some(GameResult::Win(w));
        }
        let has = if self.valued {
            valued_has_legal_move(s)
        } else {
            classic_has_legal_move(s)
        };
        (!has).then_some(GameResult::Draw)
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
        let threats = self.threats(s, me) - self.threats(s, opp);
        let economy = s.hands[me as usize].iter().map(|&v| v as i32).sum::<i32>()
            - s.hands[opp as usize].iter().map(|&v| v as i32).sum::<i32>();
        let center = self.center_control(s, me) - self.center_control(s, opp);
        W_THREAT * threats + W_ECONOMY * economy + W_CENTER * center
    }
}
