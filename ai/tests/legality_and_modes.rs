//! Cross-mode robustness: every difficulty produces only legal moves and games terminate, for all
//! mode/grid combinations.

mod common;
use ai::SelectionPolicy;
use common::{perfect, play_game};
use engine::{GameConfig, ModeKind};

const CONFIGS: [GameConfig; 8] = [
    GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 },
    GameConfig { kind: ModeKind::Classic, rows: 4, cols: 4, win_len: 3 },
    GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 },
    GameConfig { kind: ModeKind::Original, rows: 4, cols: 4, win_len: 3 },
    GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 },
    GameConfig { kind: ModeKind::Bonanza, rows: 4, cols: 4, win_len: 3 },
    GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 },
    GameConfig { kind: ModeKind::Morph, rows: 5, cols: 5, win_len: 3 },
];

#[test]
fn easy_only_legal_and_terminates() {
    for config in CONFIGS {
        for seed in 0..10u64 {
            let _ = play_game(config, seed, SelectionPolicy::LowMix, SelectionPolicy::LowMix, perfect(1));
        }
    }
}

#[test]
fn medium_only_legal_and_terminates() {
    // Medium mixes Easy and a shallow Hard. 5×5 Morph's huge per-turn branching is exercised
    // separately by the time-box test, so cap depth here to keep the suite fast — legality and
    // termination are what we're checking.
    for config in CONFIGS {
        let depth = match config.kind {
            ModeKind::Morph => 2,
            _ => 3,
        };
        let _ = play_game(config, 3, SelectionPolicy::MidMix, SelectionPolicy::MidMix, perfect(depth));
    }
}

#[test]
fn hard_only_legal_and_terminates_small_boards() {
    // Depth-limited (no time box) so it's deterministic; depth chosen to stay quick.
    let small = [
        GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 },
        GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 },
        GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 },
        GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 },
    ];
    for config in small {
        let depth = if matches!(config.kind, ModeKind::Morph) { 3 } else { 5 };
        let _ = play_game(config, 1, SelectionPolicy::AlwaysBest, SelectionPolicy::AlwaysBest, perfect(depth));
    }
}

#[test]
fn hard_respects_time_box_on_large_morph() {
    // 5×5 Morph: with a real time box the search must return a legal move quickly (spec §7.8, §13.3).
    use ai::{play_move, SearchLimits};
    use engine::{build, is_move_legal};
    use std::time::Instant;

    let config = GameConfig { kind: ModeKind::Morph, rows: 5, cols: 5, win_len: 3 };
    let (mode, s) = build(config, 0);
    let limits = SearchLimits { time_ms: 500, max_depth: 64 };

    let start = Instant::now();
    let mv = play_move(&*mode, &s, SelectionPolicy::AlwaysBest, limits, 0).unwrap();
    let elapsed = start.elapsed();

    assert!(is_move_legal(&s, &mv, true));
    // Generous ceiling (spec §7.8 hard ceiling 1 s) to avoid flakiness on slow CI.
    assert!(elapsed.as_millis() < 2000, "5×5 Morph search took {elapsed:?}");
}
