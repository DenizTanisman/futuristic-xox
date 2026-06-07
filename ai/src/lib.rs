//! # Futuristic XOX — AI (Unit 2)
//!
//! Builds against the engine's frozen [`engine::Mode`] trait only (spec §7.1, §11).
//!
//! - **Easy** (spec §7.2): random with a capture/placement bias.
//! - **Medium** (spec §7.3): per move, randomly run Easy or Hard — but never the *same* engine three
//!   moves in a row. See [`MediumState`].
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

/// Per-game memory for Medium so its Easy/Hard coin can't run away into a long one-sided streak
/// (the bug report: "Medium sometimes feels like pure Easy or pure Hard"). The flip stays random,
/// but is **anti-streak**: after the same engine has been used twice in a row, the next move is
/// forced to the other one — so it can never run the same engine three moves in a row.
///
/// Lives in the stateful caller (the bridge `GameSession` / Dart game API), one per game, because
/// the decision needs memory across moves that a stateless `choose_move` call cannot hold.
#[derive(Debug, Clone, Copy, Default)]
pub struct MediumState {
    /// The last engine chosen: `Some(true)` = Hard, `Some(false)` = Easy, `None` = no move yet.
    last_hard: Option<bool>,
    /// How many moves in a row that same engine has now been used.
    run: u8,
}

impl MediumState {
    /// Decide whether Medium uses Hard for this move. Random coin from `seed` (even/0 → Hard, odd →
    /// Easy, matching the original spec §7.3 flip), except when the last engine already ran twice in
    /// a row — then it is forced to the opposite engine. Updates the streak counter.
    pub fn pick_hard(&mut self, seed: u64) -> bool {
        let use_hard = if self.run >= 2 {
            // Anti-streak: force the other engine. `last_hard` is always Some once run >= 2.
            !self.last_hard.unwrap_or(false)
        } else {
            // Free coin flip (even/0 → Hard, odd → Easy), same convention as before.
            Rng::new(seed).next_u64() % 2 == 0
        };
        if self.last_hard == Some(use_hard) {
            self.run += 1;
        } else {
            self.last_hard = Some(use_hard);
            self.run = 1;
        }
        use_hard
    }
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
            // Stateless coin (odd → Easy, even → Hard, spec §7.3). The stateful, anti-streak Medium
            // used in real games lives in the caller via [`MediumState`] + [`choose_move_medium`];
            // this branch keeps a memory-free fallback for self-play/tests.
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

/// Medium with memory: picks Easy or Hard via [`MediumState::pick_hard`] (anti-streak), then runs
/// that engine. Use this — not `choose_move(.., Medium, ..)` — wherever a single game is played, so
/// Medium can never feel like pure Easy or pure Hard for a long stretch (spec §7.3, refined).
pub fn choose_move_medium(
    mode: &dyn Mode,
    state: &GameState,
    limits: SearchLimits,
    seed: u64,
    medium: &mut MediumState,
) -> Option<Move> {
    if medium.pick_hard(seed) {
        hard::hard_move(mode, state, limits)
    } else {
        let mut rng = Rng::new(seed);
        easy::easy_move(mode, state, &mut rng)
    }
}

#[cfg(test)]
mod tests {
    use super::MediumState;

    /// Whatever the seed stream produces, Medium must never pick the same engine three moves running.
    #[test]
    fn medium_never_runs_same_engine_three_in_a_row() {
        let mut m = MediumState::default();
        let mut last_two = [false; 2];
        // Worst case: a seed stream that always wants the same engine when free to choose.
        for i in 0..500u64 {
            // Alternate constant-ish seeds to probe both even and odd streams.
            let seed = if i % 2 == 0 { 2 } else { 1 };
            let pick = m.pick_hard(seed);
            if i >= 2 {
                assert!(
                    !(pick == last_two[0] && pick == last_two[1]),
                    "three identical picks in a row at move {i}",
                );
            }
            last_two = [last_two[1], pick];
        }
    }

    /// A forced switch resets the run to 1, so two-then-switch-then-two is allowed (just not three).
    #[test]
    fn medium_allows_pairs_but_forces_switch_after_two() {
        let mut m = MediumState::default();
        // Constant even seed → coin always wants Hard; the rule must inject Easy on the 3rd.
        let a = m.pick_hard(2);
        let b = m.pick_hard(2);
        let c = m.pick_hard(2);
        assert_eq!(a, b, "first two free picks match the coin");
        assert_ne!(b, c, "third pick is forced to the other engine");
    }
}
