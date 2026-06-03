//! # Futuristic XOX — AI (Unit 2)
//!
//! Builds against the engine's frozen [`engine::Mode`] trait only (spec §7.1, §11).
//!
//! - **Easy** (spec §7.2): random with a capture/placement bias.
//! - **Medium** (spec §7.3): per turn, randomly run Easy or Hard.
//! - **Hard** (spec §7.4, §7.7): negamax + alpha-beta + transposition table + iterative deepening
//!   with a time box.
//!
//! The public entry point is [`choose_move`], the merge contract for Unit 3 (spec §11):
//! `choose_move(state, difficulty, time_budget) -> Move`.

mod easy;
mod hard;
mod hash;

pub use hard::SearchLimits;

use engine::{GameState, Mode, Move, Rng};

/// Difficulty selection (spec §8 UI flow).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Difficulty {
    Easy,
    Medium,
    Hard,
}

/// Choose a move for the side to move.
///
/// - `mode` / `state`: the current game (engine merge contract).
/// - `difficulty`: which engine to use.
/// - `limits`: time box + depth cap for the Hard search (spec §7.8). Ignored by Easy.
/// - `seed`: drives Easy/Medium randomness and Medium's per-turn Easy/Hard coin flip; pass a varying
///   seed per turn for variety, or a fixed seed for reproducible tests.
///
/// Returns `None` only when there are no legal moves (i.e. a terminal state).
pub fn choose_move(
    mode: &dyn Mode,
    state: &GameState,
    difficulty: Difficulty,
    limits: SearchLimits,
    seed: u64,
) -> Option<Move> {
    match difficulty {
        Difficulty::Easy => {
            let mut rng = Rng::new(seed);
            easy::easy_move(mode, state, &mut rng)
        }
        Difficulty::Medium => {
            // Decided fresh each turn: roll odd → Easy, even → Hard (spec §7.3).
            let mut rng = Rng::new(seed);
            if rng.next_u64() % 2 == 1 {
                easy::easy_move(mode, state, &mut rng)
            } else {
                hard::hard_move(mode, state, limits)
            }
        }
        Difficulty::Hard => hard::hard_move(mode, state, limits),
    }
}
