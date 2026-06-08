//! Self-play harness for heuristic validation / calibration (spec §7.6, §13.2).
//!
//! Runs matchups (e.g. Hard vs Easy) over many seeds per mode and reports win/draw/loss rates.
//! Used to confirm the search + heuristic produce strong play before locking starting weights.
//!
//! Run: `cargo run --release --example selfplay`

use ai::{play_move, SearchLimits, SelectionPolicy};
use engine::{build, GameConfig, GameResult, ModeKind};

fn play(config: GameConfig, seed: u64, d0: SelectionPolicy, d1: SelectionPolicy, limits: SearchLimits) -> GameResult {
    let (mode, mut s) = build(config, seed);
    let max_plies = s.cell_count() * 4 + 20;
    for ply in 0..max_plies {
        if let Some(r) = mode.is_terminal(&s) {
            return r;
        }
        let diff = if s.turn == 0 { d0 } else { d1 };
        let mv = play_move(&*mode, &s, diff, limits, seed.wrapping_mul(1009).wrapping_add(ply as u64))
            .expect("non-terminal must yield a move");
        s = mode.apply(&s, &mv);
    }
    GameResult::Draw
}

fn matchup(name: &str, config: GameConfig, hard_is: SelectionPolicy, foe: SelectionPolicy, games: u64, limits: SearchLimits) {
    let (mut hw, mut d, mut hl) = (0u32, 0u32, 0u32);
    for seed in 0..games {
        // Alternate who moves first to remove first-move bias.
        let (d0, d1, hard_player) = if seed % 2 == 0 {
            (hard_is, foe, 0u8)
        } else {
            (foe, hard_is, 1u8)
        };
        match play(config, seed, d0, d1, limits) {
            GameResult::Win(w) if w == hard_player => hw += 1,
            GameResult::Win(_) => hl += 1,
            GameResult::Draw => d += 1,
        }
    }
    let pct = 100.0 * (hw as f64 + 0.5 * d as f64) / games as f64;
    println!(
        "{name:<26} {hard_is:?} vs {foe:?}: {hw}W / {d}D / {hl}L  (score {pct:.0}%)"
    );
}

fn main() {
    // Modest depth boxes (no wall clock) for reproducible, quick numbers. Strength is already clear
    // at these depths; deeper search only widens Hard's margin.
    let small = SearchLimits { time_ms: 0, max_depth: 6 }; // 3×3 boards
    let line4 = SearchLimits { time_ms: 0, max_depth: 4 }; // 4×4 line modes
    let morph = SearchLimits { time_ms: 0, max_depth: 3 }; // Morph (b² per turn)

    println!("== Heuristic validation: Hard should dominate Easy, beat Medium ==\n");

    matchup("Classic 3x3", GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, 30, small);
    matchup("Original 3x3", GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, 30, small);
    matchup("Original 4x4", GameConfig { kind: ModeKind::Original, rows: 4, cols: 4, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, 16, line4);
    matchup("Bonanza 3x3", GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, 30, small);
    matchup("Morph 4x4", GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, 16, morph);

    println!();
    matchup("Original 3x3", GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, SelectionPolicy::AlwaysBest, SelectionPolicy::Top3Uniform, 30, small);
}
