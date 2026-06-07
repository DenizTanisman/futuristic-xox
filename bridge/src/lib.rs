//! # Futuristic XOX — Game Facade / Bridge (Unit 3 wiring)
//!
//! A thin, FFI-friendly layer over the pure [`engine`] and [`ai`] crates. The UI (Flutter) drives a
//! [`GameSession`] through plain methods and reads flat, serializable view structs ([`Snapshot`],
//! [`MoveResult`]). This is the integration surface that `flutter_rust_bridge` will wrap once the
//! Flutter SDK is available (spec §2, §11); keeping it dependency-light means the Dart codegen step
//! is purely additive.
//!
//! State lives in Rust (the `GameSession` is the opaque object held across the bridge), so the heavy
//! AI search runs natively off the Flutter UI isolate (spec §2 — the key to 60fps fluidity).

use ai::{play_move, SearchLimits, SelectionPolicy};
use engine::{
    build, is_move_legal, GameConfig, GameResult, GameState, Mode, ModeKind, Move,
};

// Per-side difficulty tiers + their policy mapping (the §3.2 boundary contract for the UI). Re-exported
// so the UI selects a tier and maps it to a `SelectionPolicy` before calling [`GameSession::ai_move`].
pub use ai::{ClassicDifficulty, FuturisticDifficulty, SelectionPolicy as AiSelectionPolicy};

/// Selectable mode for the UI (mirrors [`engine::ModeKind`] for a stable FFI surface).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode4 {
    Classic,
    Original,
    Bonanza,
    Morph,
}

impl From<Mode4> for ModeKind {
    fn from(m: Mode4) -> Self {
        match m {
            Mode4::Classic => ModeKind::Classic,
            Mode4::Original => ModeKind::Original,
            Mode4::Bonanza => ModeKind::Bonanza,
            Mode4::Morph => ModeKind::Morph,
        }
    }
}

/// FFI-friendly terminal outcome (avoids an enum payload that some bindings dislike).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Outcome {
    InProgress,
    Win0,
    Win1,
    Draw,
}

impl Outcome {
    fn from_result(r: Option<GameResult>) -> Self {
        match r {
            None => Outcome::InProgress,
            Some(GameResult::Win(0)) => Outcome::Win0,
            Some(GameResult::Win(_)) => Outcome::Win1,
            Some(GameResult::Draw) => Outcome::Draw,
        }
    }
}

/// A single board cell for the UI.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CellView {
    pub owner: u8,
    pub value: u8,
    pub empty: bool,
}

/// A flat, serializable view of the full game state for rendering (spec §8).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Snapshot {
    pub rows: usize,
    pub cols: usize,
    pub board: Vec<CellView>,
    pub hand0: Vec<u8>,
    pub hand1: Vec<u8>,
    pub turn: u8,
    /// 1 normally; for Morph, 2 then 1 within a turn (drives the "move 1 of 2 / 2 of 2" UI, spec §8).
    pub moves_left_in_turn: u8,
    pub outcome: Outcome,
}

/// Result of attempting a move (human or AI).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MoveResult {
    /// Whether a move was applied.
    pub applied: bool,
    /// Whether the applied move captured an enemy pawn (drives the capture animation, spec §8).
    pub captured: bool,
    /// True only for Morph: the turn passed after a single move because no second move was possible
    /// (single-move fallback, spec §4.4) — the UI shows a message.
    pub single_move_fallback: bool,
    /// Set when the move was rejected; a short inline reason for the UI (spec §3.3).
    pub illegal_reason: Option<String>,
    /// The state after the attempt (unchanged on an illegal move).
    pub snapshot: Snapshot,
}

/// A live game. Owns the mode logic + state; the UI holds this across the bridge.
pub struct GameSession {
    mode: Box<dyn Mode>,
    state: GameState,
    valued: bool,
}

impl GameSession {
    /// Start a new game. `seed` only affects Bonanza's randomized hands (spec §4.3).
    pub fn new(kind: Mode4, rows: usize, cols: usize, seed: u64) -> Self {
        let config = GameConfig { kind: kind.into(), rows, cols };
        let (mode, state) = build(config, seed);
        GameSession {
            mode,
            state,
            valued: !matches!(kind, Mode4::Classic),
        }
    }

    /// Current state as a flat view.
    pub fn snapshot(&self) -> Snapshot {
        let board = self
            .state
            .board
            .iter()
            .map(|c| match c {
                Some(p) => CellView { owner: p.owner, value: p.value, empty: false },
                None => CellView { owner: 0, value: 0, empty: true },
            })
            .collect();
        Snapshot {
            rows: self.state.rows,
            cols: self.state.cols,
            board,
            hand0: self.state.hands[0].clone(),
            hand1: self.state.hands[1].clone(),
            turn: self.state.turn,
            moves_left_in_turn: self.state.moves_left_in_turn,
            outcome: Outcome::from_result(self.mode.is_terminal(&self.state)),
        }
    }

    /// Legal target cells for a held pawn value, for UI affordances (highlighting placeable cells).
    /// For Classic pass `None`; any empty cell is legal.
    pub fn legal_cells(&self, value: Option<u8>) -> Vec<usize> {
        self.mode
            .legal_moves(&self.state)
            .into_iter()
            .filter(|m| m.value == value)
            .map(|m| m.cell)
            .collect()
    }

    /// Attempt a human move. Illegal moves leave the state untouched and return an inline reason
    /// (spec §3.3): no state change, the turn does not pass.
    pub fn human_move(&mut self, value: Option<u8>, cell: usize) -> MoveResult {
        let mv = Move { value, cell };
        if !is_move_legal(&self.state, &mv, self.valued) {
            return self.rejected(cell, value);
        }
        self.commit(mv)
    }

    /// Have the AI move for the side to move. Returns `applied: false` if the game is already over.
    ///
    /// The UI maps its per-side tier (`FuturisticDifficulty` / `ClassicDifficulty`) to a
    /// [`SelectionPolicy`] via `to_policy()` and passes it here. `play_move` is stateless; pass a
    /// per-turn varying `seed` for variety (or a fixed seed for reproducible games).
    pub fn ai_move(&mut self, policy: SelectionPolicy, time_ms: u64, max_depth: i32, seed: u64) -> MoveResult {
        let limits = SearchLimits { time_ms, max_depth };
        match play_move(&*self.mode, &self.state, policy, limits, seed) {
            Some(mv) => self.commit(mv),
            None => MoveResult {
                applied: false,
                captured: false,
                single_move_fallback: false,
                illegal_reason: None,
                snapshot: self.snapshot(),
            },
        }
    }

    /// Whether it is currently a terminal position.
    pub fn outcome(&self) -> Outcome {
        Outcome::from_result(self.mode.is_terminal(&self.state))
    }

    // ---- internals ----

    fn commit(&mut self, mv: Move) -> MoveResult {
        let captured = self
            .state
            .at(mv.cell)
            .is_some_and(|p| p.owner != self.state.turn);
        let turn_before = self.state.turn;
        let moves_left_before = self.state.moves_left_in_turn;

        self.state = self.mode.apply(&self.state, &mv);

        // Morph single-move fallback: a two-move turn that flipped after just one move (spec §4.4).
        let single_move_fallback =
            moves_left_before == 2 && self.state.turn != turn_before;

        MoveResult {
            applied: true,
            captured,
            single_move_fallback,
            illegal_reason: None,
            snapshot: self.snapshot(),
        }
    }

    fn rejected(&self, cell: usize, value: Option<u8>) -> MoveResult {
        let reason = if !self.state.in_bounds(cell) {
            "Out of bounds".to_string()
        } else {
            match (self.valued, value, self.state.at(cell)) {
                (true, None, _) => "Select a pawn value first".to_string(),
                (true, Some(v), Some(p)) if p.owner == self.state.turn => {
                    let _ = v;
                    "That is your own pawn".to_string()
                }
                (true, Some(v), Some(p)) => {
                    format!("Value {v} cannot capture a {} (must be strictly greater)", p.value)
                }
                (true, Some(v), None) if !self.state.hands[self.state.turn as usize].contains(&v) => {
                    format!("You don't hold a {v}")
                }
                (false, _, Some(_)) => "Cell is occupied".to_string(),
                _ => "Illegal move".to_string(),
            }
        };
        MoveResult {
            applied: false,
            captured: false,
            single_move_fallback: false,
            illegal_reason: Some(reason),
            snapshot: self.snapshot(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_game_snapshot_is_in_progress() {
        let g = GameSession::new(Mode4::Original, 3, 3, 0);
        let s = g.snapshot();
        assert_eq!(s.outcome, Outcome::InProgress);
        assert_eq!(s.board.len(), 9);
        assert!(s.board.iter().all(|c| c.empty));
        assert_eq!(s.turn, 0);
    }

    #[test]
    fn human_move_applies_and_passes_turn() {
        let mut g = GameSession::new(Mode4::Original, 3, 3, 0);
        let r = g.human_move(Some(3), 4);
        assert!(r.applied);
        assert!(!r.captured);
        assert_eq!(r.snapshot.turn, 1);
        assert!(!r.snapshot.board[4].empty);
        assert_eq!(r.snapshot.board[4].value, 3);
    }

    #[test]
    fn illegal_move_is_rejected_without_state_change() {
        let mut g = GameSession::new(Mode4::Original, 3, 3, 0);
        let before = g.snapshot();
        // Value not in hand (hands are 1..=6, so 9 is invalid).
        let r = g.human_move(Some(9), 0);
        assert!(!r.applied);
        assert!(r.illegal_reason.is_some());
        assert_eq!(r.snapshot, before, "state must be unchanged on illegal move");
        assert_eq!(g.snapshot().turn, 0, "turn must not pass");
    }

    #[test]
    fn capture_is_reported() {
        let mut g = GameSession::new(Mode4::Original, 3, 3, 0);
        g.human_move(Some(1), 0); // P0 places 1 at cell 0
        let r = g.human_move(Some(2), 0); // P1 captures with 2
        assert!(r.applied);
        assert!(r.captured);
        assert_eq!(r.snapshot.board[0].owner, 1);
        assert_eq!(r.snapshot.board[0].value, 2);
    }

    #[test]
    fn ai_can_play_a_full_game() {
        let mut g = GameSession::new(Mode4::Classic, 3, 3, 0);
        let limits_depth = 9;
        for _ in 0..20 {
            if g.outcome() != Outcome::InProgress {
                break;
            }
            let r = g.ai_move(SelectionPolicy::AlwaysBest, 0, limits_depth, 1);
            assert!(r.applied);
        }
        assert_ne!(g.outcome(), Outcome::InProgress);
    }

    #[test]
    fn morph_reports_move_progress() {
        let g = GameSession::new(Mode4::Morph, 4, 4, 0);
        assert_eq!(g.snapshot().moves_left_in_turn, 2);
        let mut g = g;
        let r = g.human_move(Some(1), 5);
        assert!(r.applied);
        // Still player 0's turn, now on the second of two moves.
        assert_eq!(r.snapshot.turn, 0);
        assert_eq!(r.snapshot.moves_left_in_turn, 1);
    }
}
