//! The frozen `Mode` trait (spec §7.1) — the merge contract Units 2 (AI) and 3 (UI) build against —
//! plus mode identity and the initial-state factory.

use crate::state::{GameResult, GameState, Move};

/// Score constants for the search (spec §7.4).
pub const INF: i32 = i32::MAX;
pub const WIN: i32 = 1000;

/// The four playable modes (spec §4). Bonanza shares Original's engine; it differs only in the
/// randomized initial hand (spec §4.3).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ModeKind {
    Classic,
    Original,
    Bonanza,
    Morph,
}

/// A grid + mode selection (the UI's choice in spec §8).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct GameConfig {
    pub kind: ModeKind,
    pub rows: usize,
    pub cols: usize,
    /// Cells in a row to win for line modes (3 default; Classic 4×4 "long" = 4). Ignored by Morph,
    /// and forced to 3 for Original/Bonanza.
    pub win_len: usize,
}

/// The frozen engine interface (spec §7.1). Object-safe: the AI consumes it as `&dyn Mode`.
///
/// All methods are pure with respect to `GameState` (no interior mutation of the input).
pub trait Mode {
    /// Every legal move from `s` for the side to move (spec §3.3, §7.5).
    fn legal_moves(&self, s: &GameState) -> Vec<Move>;

    /// `legal_moves`, best-first, to maximize alpha-beta pruning (spec §7.7.2).
    fn ordered_moves(&self, s: &GameState) -> Vec<Move>;

    /// Pure transition: returns a new state, never mutates `s` (spec §6).
    fn apply(&self, s: &GameState, m: &Move) -> GameState;

    /// Terminal check, winner before draw (spec §3.4). `None` if play continues.
    fn is_terminal(&self, s: &GameState) -> Option<GameResult>;

    /// Terminal value from the perspective of the side to move at `s` (spec §7.4):
    /// win → `WIN - depth` (win sooner), loss → `depth - WIN` (lose later), draw → 0.
    fn terminal_score(&self, r: &GameResult, s: &GameState, depth: i32) -> i32;

    /// Static estimate at the depth limit, "me minus opponent" where me = `s.turn` (spec §7.6).
    fn heuristic(&self, s: &GameState) -> i32;
}

/// Build the `(Mode, initial GameState)` pair for a configuration.
///
/// Bonanza requires a seed for its randomized hands (spec §4.3); the others ignore it.
pub fn build(config: GameConfig, seed: u64) -> (Box<dyn Mode>, GameState) {
    use crate::modes::{line::LineMode, morph::MorphMode};
    match config.kind {
        ModeKind::Classic => {
            // Classic honors the configured win length (3 = "short" / 4 = "long" on 4×4).
            let mode = LineMode::new(config.rows, config.cols, false, config.win_len);
            let state = crate::setup::classic_state(config.rows, config.cols);
            (Box::new(mode), state)
        }
        ModeKind::Original => {
            let mode = LineMode::new(config.rows, config.cols, true, 3); // always 3-in-a-row
            let state = crate::setup::original_state(config.rows, config.cols);
            (Box::new(mode), state)
        }
        ModeKind::Bonanza => {
            let mode = LineMode::new(config.rows, config.cols, true, 3); // always 3-in-a-row
            let state = crate::setup::bonanza_state(config.rows, config.cols, seed);
            (Box::new(mode), state)
        }
        ModeKind::Morph => {
            // One target shape is chosen at game start, seeded for reproducibility (spec §4.4).
            let shape = (crate::Rng::new(seed ^ 0x5159_0000).below(crate::geometry::MORPH_SHAPE_COUNT))
                .min(crate::geometry::MORPH_SHAPE_COUNT - 1);
            let mode = MorphMode::new(config.rows, config.cols, shape);
            let state = crate::setup::morph_state(config.rows, config.cols);
            (Box::new(mode), state)
        }
    }
}
