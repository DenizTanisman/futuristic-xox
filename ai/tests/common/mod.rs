//! Shared helpers for AI tests.
// Each integration-test file uses a different subset of these helpers; suppress the resulting
// per-file dead-code warnings.
#![allow(dead_code)]

use ai::{play_move, SearchLimits, SelectionPolicy};
use engine::{build, is_move_legal, GameConfig, GameResult, GameState, Pawn};

/// Build a custom state (mirrors the engine test helper).
pub fn state(
    rows: usize,
    cols: usize,
    board: Vec<Option<(u8, u8)>>,
    hand0: Vec<u8>,
    hand1: Vec<u8>,
    turn: u8,
    moves_left_in_turn: u8,
) -> GameState {
    GameState {
        board: board
            .into_iter()
            .map(|c| c.map(|(owner, value)| Pawn { owner, value }))
            .collect(),
        hands: [hand0, hand1],
        turn,
        moves_left_in_turn,
        cols,
        rows,
    }
}

pub const E: Option<(u8, u8)> = None;
pub fn p(owner: u8, value: u8) -> Option<(u8, u8)> {
    Some((owner, value))
}

/// Deterministic perfect-play limits (no time box; depth-capped).
pub fn perfect(max_depth: i32) -> SearchLimits {
    SearchLimits { time_ms: 0, max_depth }
}

/// Play a full game between two selection policies, asserting every move is legal. Returns the result.
pub fn play_game(
    config: GameConfig,
    seed: u64,
    p0: SelectionPolicy,
    p1: SelectionPolicy,
    limits: SearchLimits,
) -> GameResult {
    let (mode, mut s) = build(config, seed);
    let valued = !matches!(config.kind, engine::ModeKind::Classic);
    let max_plies = s.cell_count() * 4 + 20;

    for ply in 0..max_plies {
        if let Some(r) = mode.is_terminal(&s) {
            return r;
        }
        let policy = if s.turn == 0 { p0 } else { p1 };
        let mv = play_move(&*mode, &s, policy, limits, seed.wrapping_add(ply as u64))
            .expect("non-terminal state must yield a move");
        assert!(
            is_move_legal(&s, &mv, valued),
            "AI produced an illegal move {mv:?} in {config:?}"
        );
        s = mode.apply(&s, &mv);
    }
    panic!("game did not terminate for {config:?}");
}
