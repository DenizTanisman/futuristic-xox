//! Adversarial search: negamax + alpha-beta (spec §7.4) with the §7.7 optimizations that matter most
//! — move ordering, a transposition table (Zobrist), and iterative deepening with a time box.
//!
//! Unlike a plain best-move search, the **root** collects the **top-3 ranked moves**
//! (`first ≥ second ≥ third` by score) via a top-k alpha-beta bound (the pruning bound is held at the
//! current 3rd-best, not the best — see `aidlc-docs/design-artifacts/topk-root-search-adr.md`). The
//! interior `negamax`, the TT, the negation-on-turn-flip rule (Morph two-move turns), and the time
//! box are unchanged.

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

/// The three strongest root moves, strongest first: `first ≥ second ≥ third` by search score.
///
/// Always fully populated whenever the position has at least one legal move (slots repeat the weakest
/// available move when fewer than three distinct moves exist — see [`adversarial_search`]). Labels in
/// the owner's Turkish: Birinci / İkinci / Üçüncü.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AdversarialChoice {
    /// Birinci — the strongest move.
    pub first: Move,
    /// İkinci — the second-strongest (or `first` again when only one distinct move exists).
    pub second: Move,
    /// Üçüncü — the weakest of the three (or `second` again when only two distinct moves exist).
    pub third: Move,
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

    /// Top-k (k = 3) root search at a fixed depth. Returns the ranked `(move, score)` list, strongest
    /// first, with **exact** scores for the retained moves (top-k alpha-beta: the bound is held at the
    /// current 3rd-best so anything below 3rd fails low and is discarded, while anything that breaks
    /// into the top-3 is searched on a wide `beta = INF` window and is therefore exact). See the ADR.
    ///
    /// `prev_first` (the previous depth's best) is searched first for sharper ordering.
    fn search_root_top3(
        &mut self,
        s: &GameState,
        depth: i32,
        prev_first: Option<Move>,
    ) -> Vec<(Move, i32)> {
        let beta = INF;
        let mut top: Vec<(Move, i32)> = Vec::with_capacity(4);
        for m in self.order(s, prev_first) {
            // Pruning bound = current 3rd-best; -INF until three candidates exist.
            let alpha = if top.len() >= 3 { top[2].1 } else { -INF };
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
            // A move only matters if it breaks into the current top-3 (or the top-3 isn't full yet);
            // its score is then exact (searched with beta = INF). Insert sorted, keep three.
            if top.len() < 3 || score > top[2].1 {
                let pos = top.partition_point(|&(_, sc)| sc >= score);
                top.insert(pos, (m, score));
                top.truncate(3);
            }
        }
        top
    }
}

/// Adversarial search: the **top-3** ranked moves for the side to move, within the time box
/// (spec §7.7.4). Each completed depth produces a top-3; the last fully-completed depth wins (a
/// timed-out depth is discarded). The result is always fully populated when ≥1 legal move exists —
/// slots repeat the weakest available move so `first ≥ second ≥ third` holds for 1 / 2 / ≥3 moves.
///
/// Returns `None` **only** at a terminal position (no legal moves).
pub fn adversarial_search(
    mode: &dyn Mode,
    state: &GameState,
    limits: SearchLimits,
) -> Option<AdversarialChoice> {
    let root_moves = mode.ordered_moves(state);
    match root_moves.len() {
        0 => return None,
        1 => {
            // Single legal move: no search, all three slots identical.
            let m = root_moves[0];
            return Some(AdversarialChoice { first: m, second: m, third: m });
        }
        _ => {}
    }

    let deadline =
        (limits.time_ms > 0).then(|| Instant::now() + Duration::from_millis(limits.time_ms));
    let mut searcher = Searcher::new(mode, state.cell_count(), deadline);

    // Seed with the static ordering so a result exists even if depth 1 times out mid-way.
    let mut ranked: Vec<(Move, i32)> = root_moves.iter().map(|&m| (m, 0)).take(3).collect();
    let mut prev_first = Some(root_moves[0]);

    for depth in 1..=limits.max_depth {
        let top = searcher.search_root_top3(state, depth, prev_first);
        if searcher.timed_out {
            break; // discard this partial depth; keep the last completed one
        }
        if !top.is_empty() {
            ranked = top;
            prev_first = Some(ranked[0].0);
        }
        // A forced win/loss on the best move is proven — deeper search cannot change the decision.
        if ranked[0].1.abs() >= engine::WIN - limits.max_depth {
            break;
        }
    }

    Some(pad_to_choice(&ranked))
}

/// Build a fully-populated [`AdversarialChoice`] from a ranked list (strongest first). Missing slots
/// repeat the weakest available move so the never-`None` invariant holds: `1 → first==second==third`,
/// `2 → third==second`, `≥3 → the true top-3`. Caller guarantees `ranked` is non-empty.
fn pad_to_choice(ranked: &[(Move, i32)]) -> AdversarialChoice {
    let first = ranked[0].0;
    let second = ranked.get(1).map(|&(m, _)| m).unwrap_or(first);
    let third = ranked.get(2).map(|&(m, _)| m).unwrap_or(second);
    AdversarialChoice { first, second, third }
}

#[cfg(test)]
mod tests {
    use super::*;
    use engine::{build, GameConfig, ModeKind};

    fn original_3x3() -> (Box<dyn Mode>, GameState) {
        build(GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, 0)
    }

    fn classic_3x3() -> (Box<dyn Mode>, GameState) {
        build(GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 }, 0)
    }

    fn depth_limits(d: i32) -> SearchLimits {
        SearchLimits { time_ms: 0, max_depth: d }
    }

    /// Independent full-window argmax over root moves — the honest single-best reference. No alpha
    /// clipping (every child searched on the widest window), so the returned best is exact.
    fn reference_best(mode: &dyn Mode, state: &GameState, depth: i32) -> Move {
        let mut searcher = Searcher::new(mode, state.cell_count(), None);
        let mut best = -INF;
        let mut best_move = mode.ordered_moves(state)[0];
        for m in mode.ordered_moves(state) {
            let child = mode.apply(state, &m);
            let same_player = child.turn == state.turn;
            let score = if same_player {
                searcher.negamax(&child, depth - 1, -INF, INF)
            } else {
                -searcher.negamax(&child, depth - 1, -INF, INF)
            };
            if score > best {
                best = score;
                best_move = m;
            }
        }
        best_move
    }

    #[test]
    fn none_only_at_terminal() {
        let (mode, state) = original_3x3();
        let c = adversarial_search(&*mode, &state, depth_limits(3)).expect("non-terminal → Some");
        // All three slots are legal moves.
        let legal = mode.legal_moves(&state);
        for m in [c.first, c.second, c.third] {
            assert!(legal.contains(&m), "slot must be a legal move");
        }
    }

    #[test]
    fn ordering_is_descending() {
        // Assert via the root scores that first ≥ second ≥ third.
        let (mode, state) = original_3x3();
        let mut searcher = Searcher::new(&*mode, state.cell_count(), None);
        let top = searcher.search_root_top3(&state, 4, None);
        assert_eq!(top.len(), 3, "≥3 root moves should fill the top-3");
        assert!(
            top[0].1 >= top[1].1 && top[1].1 >= top[2].1,
            "scores must be non-increasing"
        );
    }

    #[test]
    fn single_legal_move_pads_all_three() {
        // Classic 3x3 with 8 cells filled → at most one legal move left.
        let (mode, mut state) = classic_3x3();
        for cell in 0..8usize {
            let mv = Move { value: None, cell };
            state = mode.apply(&state, &mv);
            if mode.is_terminal(&state).is_some() {
                return; // a line formed early; this fixture no longer applies
            }
        }
        if mode.legal_moves(&state).len() == 1 {
            let c = adversarial_search(&*mode, &state, depth_limits(2)).unwrap();
            assert_eq!(c.first, c.second);
            assert_eq!(c.second, c.third);
        }
    }

    #[test]
    fn two_distinct_moves_pad_third_equals_second() {
        // A ranked list of length 2 must pad third == second.
        let a = Move { value: Some(1), cell: 0 };
        let b = Move { value: Some(2), cell: 1 };
        let c = pad_to_choice(&[(a, 50), (b, 10)]);
        assert_eq!(c.first, a);
        assert_eq!(c.second, b);
        assert_eq!(c.third, b, "third must repeat the weakest available (second)");
    }

    #[test]
    fn first_matches_independent_best_move() {
        // Regression: the top-k bound must not degrade the best move vs a full-window argmax.
        // Depths kept modest so the no-pruning reference stays fast.
        for depth in [2, 3, 4] {
            let (mode, state) = original_3x3();
            let want = reference_best(&*mode, &state, depth);
            let got = adversarial_search(&*mode, &state, depth_limits(depth)).unwrap().first;
            assert_eq!(got, want, "first must equal the independent best at depth {depth}");
        }
    }
}
