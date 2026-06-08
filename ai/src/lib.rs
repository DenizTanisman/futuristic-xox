//! # Futuristic XOX — AI (Unit 2)
//!
//! Builds against the engine's frozen [`engine::Mode`] trait only (spec §7.1, §11).
//!
//! The core is an **adversarial search** ([`adversarial_search`]) that returns the **top-3 ranked
//! moves** ([`AdversarialChoice`]: `first ≥ second ≥ third`), reusing negamax + alpha-beta + a
//! transposition table + iterative deepening with a time box (spec §7.4, §7.7). On top of it,
//! per-turn **difficulty tiers** pick which option — or the legacy random move `rastgele()`
//! ([`easy::easy_move`]) — to actually play, via a [`SelectionPolicy`] and the stateless
//! [`play_move`] selector.
//!
//! Per-side label enums map onto the four policies: the Futuristic side (valued modes) offers four
//! tiers ([`FuturisticDifficulty`]), Classic offers three ([`ClassicDifficulty`]). Using separate
//! enums makes the invalid `Classic + Impossible` combination unrepresentable.

mod adversarial;
mod easy;
mod hash;

pub use adversarial::{adversarial_search, AdversarialChoice, SearchLimits};

use engine::{GameState, Mode, Move, Rng};

/// Which move the per-turn selector plays. The single engine-facing knob; per-side label enums
/// ([`FuturisticDifficulty`] / [`ClassicDifficulty`]) collapse onto these four via `to_policy()`.
///
/// `rastgele()` denotes the legacy random move generator ([`easy::easy_move`]).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SelectionPolicy {
    /// Always play `first` (Birinci) — the strongest move.
    AlwaysBest,
    /// Uniformly one of the top-3: `below(3)` → 0 = first, 1 = second, 2 = third.
    Top3Uniform,
    /// Mid mix: `below(3)` → 0 = second, 1 = third, 2 = `rastgele()`.
    MidMix,
    /// Low mix: `below(2)` → 0 = third, 1 = `rastgele()`.
    LowMix,
}

/// Difficulty tiers for the Futuristic side (Original / Bonanza / Morph — valued modes). Four tiers.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FuturisticDifficulty {
    Easy,
    Medium,
    Hard,
    Impossible,
}

/// Difficulty tiers for Classic. Three tiers — there is no `Impossible` here, so `Classic + Impossible`
/// is unrepresentable by construction (no runtime guard needed).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ClassicDifficulty {
    Easy,
    Medium,
    Hard,
}

impl FuturisticDifficulty {
    /// Map a Futuristic tier to its selection policy (the §3.2 contract).
    pub fn to_policy(self) -> SelectionPolicy {
        match self {
            FuturisticDifficulty::Impossible => SelectionPolicy::AlwaysBest,
            FuturisticDifficulty::Hard => SelectionPolicy::Top3Uniform,
            FuturisticDifficulty::Medium => SelectionPolicy::MidMix,
            FuturisticDifficulty::Easy => SelectionPolicy::LowMix,
        }
    }
}

impl ClassicDifficulty {
    /// Map a Classic tier to its selection policy (the §3.2 contract).
    pub fn to_policy(self) -> SelectionPolicy {
        match self {
            ClassicDifficulty::Hard => SelectionPolicy::AlwaysBest,
            ClassicDifficulty::Medium => SelectionPolicy::Top3Uniform,
            ClassicDifficulty::Easy => SelectionPolicy::LowMix,
        }
    }
}

/// Choose and return the move to play this turn for the side to move.
///
/// - `mode` / `state`: the current game (engine merge contract).
/// - `policy`: which tier behaviour to apply ([`SelectionPolicy`]).
/// - `limits`: time box + depth cap for the adversarial search (spec §7.8). Unused on a pure
///   `rastgele()` roll.
/// - `seed`: drives the per-turn selection die **and** the `rastgele()` fallback. Pass a varying seed
///   per turn for variety, or a fixed seed for reproducible games/tests.
///
/// **Roll-first efficiency:** the die is rolled before any search, so weaker tiers that land on
/// `rastgele()` skip the (expensive) search entirely. The selection RNG is independent of the search,
/// which is itself deterministic — so identical `(state, policy, seed)` always yields the same move.
///
/// **Stateless — no anti-streak** (owner decision): the mixes provide enough variety on their own.
///
/// Returns `None` only at a terminal position (no legal moves).
pub fn play_move(
    mode: &dyn Mode,
    state: &GameState,
    policy: SelectionPolicy,
    limits: SearchLimits,
    seed: u64,
) -> Option<Move> {
    let mut rng = Rng::new(seed);
    match policy {
        SelectionPolicy::AlwaysBest => adversarial_search(mode, state, limits).map(|c| c.first),
        SelectionPolicy::Top3Uniform => {
            let pick = rng.below(3);
            adversarial_search(mode, state, limits).map(|c| match pick {
                0 => c.first,
                1 => c.second,
                _ => c.third,
            })
        }
        SelectionPolicy::MidMix => match rng.below(3) {
            2 => easy::easy_move(mode, state, &mut rng), // rastgele() — skip the search
            pick => adversarial_search(mode, state, limits)
                .map(|c| if pick == 0 { c.second } else { c.third }),
        },
        SelectionPolicy::LowMix => match rng.below(2) {
            1 => easy::easy_move(mode, state, &mut rng), // rastgele() — skip the search
            _ => adversarial_search(mode, state, limits).map(|c| c.third),
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use engine::{build, GameConfig, GameState, Mode, ModeKind};

    fn original_3x3() -> (Box<dyn Mode>, GameState) {
        build(GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, 0)
    }

    fn limits() -> SearchLimits {
        // Shallow depth keeps the seed-sweep selection tests fast; they exercise the *selection*
        // branches, not search strength (that is covered by the adversarial-search tests + self-play).
        SearchLimits { time_ms: 0, max_depth: 3 }
    }

    #[test]
    fn policy_mapping_is_per_side() {
        assert_eq!(FuturisticDifficulty::Impossible.to_policy(), SelectionPolicy::AlwaysBest);
        assert_eq!(FuturisticDifficulty::Hard.to_policy(), SelectionPolicy::Top3Uniform);
        assert_eq!(FuturisticDifficulty::Medium.to_policy(), SelectionPolicy::MidMix);
        assert_eq!(FuturisticDifficulty::Easy.to_policy(), SelectionPolicy::LowMix);
        assert_eq!(ClassicDifficulty::Hard.to_policy(), SelectionPolicy::AlwaysBest);
        assert_eq!(ClassicDifficulty::Medium.to_policy(), SelectionPolicy::Top3Uniform);
        assert_eq!(ClassicDifficulty::Easy.to_policy(), SelectionPolicy::LowMix);
        // `Classic + Impossible` does not compile — ClassicDifficulty has no Impossible variant.
    }

    #[test]
    fn always_best_returns_first() {
        let (mode, state) = original_3x3();
        let want = adversarial_search(&*mode, &state, limits()).unwrap().first;
        for seed in 0..20u64 {
            let got = play_move(&*mode, &state, SelectionPolicy::AlwaysBest, limits(), seed);
            assert_eq!(got, Some(want), "AlwaysBest must always play first");
        }
    }

    #[test]
    fn play_move_is_deterministic() {
        let (mode, state) = original_3x3();
        for policy in [
            SelectionPolicy::AlwaysBest,
            SelectionPolicy::Top3Uniform,
            SelectionPolicy::MidMix,
            SelectionPolicy::LowMix,
        ] {
            for seed in 0..10u64 {
                let a = play_move(&*mode, &state, policy, limits(), seed);
                let b = play_move(&*mode, &state, policy, limits(), seed);
                assert_eq!(a, b, "identical (state, policy, seed) → identical move");
            }
        }
    }

    #[test]
    fn selection_branches_cover_their_ranges() {
        let (mode, state) = original_3x3();
        let c = adversarial_search(&*mode, &state, limits()).unwrap();
        let r = |seed| {
            let mut rng = Rng::new(seed);
            easy::easy_move(&*mode, &state, &mut rng).unwrap()
        };

        // Top3Uniform must reach {first, second, third} across seeds.
        let mut seen_top3 = std::collections::HashSet::new();
        // MidMix must reach {second, third, R}; LowMix must reach {third, R}.
        let mut seen_mid = std::collections::HashSet::new();
        let mut seen_low = std::collections::HashSet::new();
        for seed in 0..150u64 {
            seen_top3
                .insert(play_move(&*mode, &state, SelectionPolicy::Top3Uniform, limits(), seed));
            seen_mid.insert(play_move(&*mode, &state, SelectionPolicy::MidMix, limits(), seed));
            seen_low.insert(play_move(&*mode, &state, SelectionPolicy::LowMix, limits(), seed));
        }
        assert!(seen_top3.contains(&Some(c.first)));
        assert!(seen_top3.contains(&Some(c.second)));
        assert!(seen_top3.contains(&Some(c.third)));
        assert!(seen_mid.contains(&Some(c.second)));
        assert!(seen_mid.contains(&Some(c.third)));
        assert!(seen_low.contains(&Some(c.third)));
        // The R branch reaches at least one rastgele() move under some seed (sanity: 0 is one).
        let any_r = (0..150u64).any(|seed| {
            play_move(&*mode, &state, SelectionPolicy::LowMix, limits(), seed) == Some(r(seed))
        });
        assert!(any_r, "LowMix must sometimes play rastgele()");
    }

    #[test]
    fn rastgele_path_matches_easy_move_with_post_roll_rng() {
        // Find a LowMix seed whose die selects the R branch (below(2) == 1), then assert play_move
        // returns exactly easy_move driven by the *same* RNG after that one draw (search was skipped).
        let (mode, state) = original_3x3();
        let seed = (0..1000u64)
            .find(|&s| Rng::new(s).below(2) == 1)
            .expect("some seed lands on the R branch");
        let mut rng = Rng::new(seed);
        assert_eq!(rng.below(2), 1);
        let expected = easy::easy_move(&*mode, &state, &mut rng);
        let got = play_move(&*mode, &state, SelectionPolicy::LowMix, limits(), seed);
        assert_eq!(got, expected, "R path must equal easy_move on the post-roll RNG");
    }
}
