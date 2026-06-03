//! Hard difficulty: negamax + alpha-beta (spec §7.4) with the §7.7 optimizations that matter most —
//! move ordering, a transposition table (Zobrist), and iterative deepening with a time box.

use std::collections::HashMap;
use std::time::{Duration, Instant};

use engine::{GameState, Mode, Move, INF};

use crate::hash::Zobrist;

/// How many nodes between wall-clock checks (checking every node would dominate the cost).
const TIME_CHECK_MASK: u64 = 0x3FF; // every 1024 nodes

/// Search limits. `time_ms == 0` disables the time box (depth-limited only — useful for tests).
#[derive(Debug, Clone, Copy)]
pub struct SearchLimits {
    pub time_ms: u64,
    pub max_depth: i32,
}

impl Default for SearchLimits {
    fn default() -> Self {
        // Spec §7.8 budget: 300–500 ms target. Depth cap is a safety net; the time box governs.
        SearchLimits { time_ms: 500, max_depth: 64 }
    }
}

#[derive(Clone, Copy)]
enum Bound {
    Exact,
    Lower,
    Upper,
}

#[derive(Clone, Copy)]
struct TtEntry {
    depth: i32,
    value: i32,
    flag: Bound,
    best_move: Option<Move>,
}

struct Searcher<'a> {
    mode: &'a dyn Mode,
    zobrist: Zobrist,
    tt: HashMap<u64, TtEntry>,
    deadline: Option<Instant>,
    nodes: u64,
    timed_out: bool,
}

impl<'a> Searcher<'a> {
    fn new(mode: &'a dyn Mode, cells: usize, deadline: Option<Instant>) -> Self {
        Searcher {
            mode,
            zobrist: Zobrist::new(cells),
            tt: HashMap::new(),
            deadline,
            nodes: 0,
            timed_out: false,
        }
    }

    #[inline]
    fn out_of_time(&mut self) -> bool {
        if self.timed_out {
            return true;
        }
        self.nodes += 1;
        if self.nodes & TIME_CHECK_MASK == 0 {
            if let Some(d) = self.deadline {
                if Instant::now() >= d {
                    self.timed_out = true;
                }
            }
        }
        self.timed_out
    }

    /// Order moves best-first: the TT's previously-best move, then the engine's static ordering.
    fn order(&self, s: &GameState, tt_move: Option<Move>) -> Vec<Move> {
        let mut moves = self.mode.ordered_moves(s);
        if let Some(best) = tt_move {
            if let Some(pos) = moves.iter().position(|&m| m == best) {
                moves.swap(0, pos);
            }
        }
        moves
    }

    /// Negamax with alpha-beta and TT (spec §7.4). Morph: when a move does not flip the turn
    /// (same player still to move), recurse without negating; negate only on a turn flip.
    fn negamax(&mut self, s: &GameState, depth: i32, mut alpha: i32, beta: i32) -> i32 {
        if self.out_of_time() {
            return 0;
        }
        if let Some(r) = self.mode.is_terminal(s) {
            return self.mode.terminal_score(&r, s, depth);
        }
        if depth == 0 {
            return self.mode.heuristic(s);
        }

        let key = self.zobrist.key(s);
        let alpha_orig = alpha;
        let mut beta = beta;
        let mut tt_move = None;
        if let Some(e) = self.tt.get(&key).copied() {
            tt_move = e.best_move;
            if e.depth >= depth {
                match e.flag {
                    Bound::Exact => return e.value,
                    Bound::Lower => alpha = alpha.max(e.value),
                    Bound::Upper => beta = beta.min(e.value),
                }
                if alpha >= beta {
                    return e.value;
                }
            }
        }

        let mut best = -INF;
        let mut best_move = None;
        for m in self.order(s, tt_move) {
            let child = self.mode.apply(s, &m);
            let same_player = child.turn == s.turn;
            let score = if same_player {
                self.negamax(&child, depth - 1, alpha, beta)
            } else {
                -self.negamax(&child, depth - 1, -beta, -alpha)
            };
            if self.timed_out {
                return best.max(-INF + 1);
            }
            if score > best {
                best = score;
                best_move = Some(m);
            }
            alpha = alpha.max(best);
            if alpha >= beta {
                break; // cutoff
            }
        }

        // Don't pollute the TT with results from a search aborted by the clock.
        if !self.timed_out {
            let flag = if best <= alpha_orig {
                Bound::Upper
            } else if best >= beta {
                Bound::Lower
            } else {
                Bound::Exact
            };
            self.tt.insert(key, TtEntry { depth, value: best, flag, best_move });
        }
        best
    }

    /// Full-width root search at a fixed depth; returns the best `(move, score)` for that depth.
    fn search_root(&mut self, s: &GameState, depth: i32, prev_best: Option<Move>) -> (Option<Move>, i32) {
        let mut alpha = -INF;
        let beta = INF;
        let mut best = -INF;
        let mut best_move = prev_best;
        for m in self.order(s, prev_best) {
            let child = self.mode.apply(s, &m);
            let same_player = child.turn == s.turn;
            let score = if same_player {
                self.negamax(&child, depth - 1, alpha, beta)
            } else {
                -self.negamax(&child, depth - 1, -beta, -alpha)
            };
            if self.timed_out {
                break;
            }
            if score > best {
                best = score;
                best_move = Some(m);
            }
            alpha = alpha.max(best);
        }
        (best_move, best)
    }
}

/// Choose the hard-difficulty move via iterative deepening within the time box (spec §7.7.4).
/// Each completed depth feeds the next depth's move ordering; an incomplete (timed-out) depth is
/// discarded, keeping the best fully-searched move.
pub fn hard_move(mode: &dyn Mode, state: &GameState, limits: SearchLimits) -> Option<Move> {
    let root_moves = mode.ordered_moves(state);
    if root_moves.is_empty() {
        return None;
    }
    if root_moves.len() == 1 {
        return Some(root_moves[0]);
    }

    let deadline = (limits.time_ms > 0).then(|| Instant::now() + Duration::from_millis(limits.time_ms));
    let mut searcher = Searcher::new(mode, state.cell_count(), deadline);

    let mut best_move = Some(root_moves[0]);
    for depth in 1..=limits.max_depth {
        let (mv, score) = searcher.search_root(state, depth, best_move);
        if searcher.timed_out {
            break; // discard this partial depth; keep the last completed one
        }
        if let Some(m) = mv {
            best_move = Some(m);
        }
        // A forced win/loss is proven — deeper search cannot change the decision.
        if score.abs() >= engine::WIN - limits.max_depth {
            break;
        }
    }
    best_move
}
