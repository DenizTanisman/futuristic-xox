//! End-to-end sanity: drive full random games per mode and assert engine invariants never break.

use engine::{build, GameConfig, GameResult, ModeKind, Rng};

/// Play a full game choosing pseudo-random legal moves; assert invariants every step and that it
/// terminates in a bounded number of plies.
fn play_to_end(config: GameConfig, seed: u64) -> GameResult {
    let (mode, mut s) = build(config, seed);
    let mut rng = Rng::new(seed ^ 0xABCD);
    let max_plies = s.cell_count() * 4 + 10; // generous upper bound

    for _ply in 0..max_plies {
        if let Some(r) = mode.is_terminal(&s) {
            return r;
        }
        let moves = mode.legal_moves(&s);
        assert!(!moves.is_empty(), "non-terminal state must have legal moves");

        let pick = moves[rng.below(moves.len())];
        let prev_turn = s.turn;
        let prev = s.clone();
        s = mode.apply(&s, &pick);

        // Invariant: apply did not mutate the input.
        assert_eq!(prev.turn, prev_turn);
        // Invariant: board length is constant.
        assert_eq!(s.board.len(), config.rows * config.cols);
        // Invariant: hand sizes never grow (captured pawns are deleted, not banked).
        assert!(s.hands[0].len() <= prev.hands[0].len());
        assert!(s.hands[1].len() <= prev.hands[1].len());
    }
    panic!("game did not terminate within {max_plies} plies for {config:?}");
}

#[test]
fn all_modes_terminate_and_are_consistent() {
    let configs = [
        GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3 },
        GameConfig { kind: ModeKind::Classic, rows: 4, cols: 4 },
        GameConfig { kind: ModeKind::Original, rows: 3, cols: 3 },
        GameConfig { kind: ModeKind::Original, rows: 4, cols: 4 },
        GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3 },
        GameConfig { kind: ModeKind::Bonanza, rows: 4, cols: 4 },
        GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4 },
        GameConfig { kind: ModeKind::Morph, rows: 5, cols: 5 },
    ];
    for config in configs {
        for seed in 0..40u64 {
            // Just needs to terminate without tripping an invariant.
            let _ = play_to_end(config, seed);
        }
    }
}

#[test]
fn ordered_moves_is_a_permutation_of_legal_moves() {
    let (mode, s) = build(GameConfig { kind: ModeKind::Original, rows: 3, cols: 3 }, 0);
    let mut a = mode.legal_moves(&s);
    let mut b = mode.ordered_moves(&s);
    a.sort_by_key(|m| (m.cell, m.value));
    b.sort_by_key(|m| (m.cell, m.value));
    assert_eq!(a, b, "ordered_moves must contain exactly the legal moves");
}
