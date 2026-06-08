//! Morph rules (spec §4.4, §5): shape completion across rotations/mirrors, two moves per turn,
//! win-after-each-move, single-move fallback.

mod common;
use common::{p, state, E};
use engine::{build, GameConfig, GameResult, Mode, ModeKind, Move, MorphMode};

// Shape index 0 = I; tests below use horizontal-I patterns (0,1,2,3) or are shape-independent.
fn morph_4x4() -> MorphMode {
    MorphMode::new(4, 4, 0)
}

#[test]
fn every_precomputed_shape_is_a_win_when_fully_owned() {
    // Strong property: for each chosen shape, owning all 4 cells of ANY of its placements
    // (every rotation + mirror, axis AND diagonal) wins.
    for (rows, cols) in [(4usize, 4usize), (5, 5)] {
        for shape in 0..3 {
            let mode = MorphMode::new(rows, cols, shape);
            for placement in mode.placements() {
                let mut board = vec![E; rows * cols];
                for &cell in placement {
                    board[cell] = p(0, 1);
                }
                let s = state(rows, cols, board, vec![], vec![], 1, 2);
                assert_eq!(
                    mode.is_terminal(&s),
                    Some(GameResult::Win(0)),
                    "shape {shape} placement {placement:?} on {rows}x{cols} should be a win"
                );
            }
        }
    }
}

#[test]
fn diagonal_shape_completion_wins() {
    // The diagonal/staircase I (0,5,10,15) is now a valid win (diagonals are IN, spec §5/§13.1).
    let mode = MorphMode::new(4, 4, 0); // I
    let mut board = vec![E; 16];
    for &cell in &[0usize, 5, 10, 15] {
        board[cell] = p(1, 3);
    }
    let s = state(4, 4, board, vec![1], vec![], 0, 2);
    assert_eq!(mode.is_terminal(&s), Some(GameResult::Win(1)));
}

#[test]
fn partial_shape_is_not_a_win() {
    // Only 3 of the 4 I-cells owned → not terminal.
    let mut board = vec![E; 16];
    board[0] = p(0, 1);
    board[1] = p(0, 1);
    board[2] = p(0, 1);
    let s = state(4, 4, board, vec![1], vec![1], 0, 2);
    assert_eq!(morph_4x4().is_terminal(&s), None);
}

#[test]
fn shape_blocked_by_enemy_is_not_a_win() {
    // I-cells 0,1,2 mine but cell 3 is enemy → that placement is blocked.
    let mut board = vec![E; 16];
    board[0] = p(0, 1);
    board[1] = p(0, 1);
    board[2] = p(0, 1);
    board[3] = p(1, 9);
    let s = state(4, 4, board, vec![1], vec![1], 0, 2);
    assert_eq!(morph_4x4().is_terminal(&s), None);
}

#[test]
fn single_placement_flips_turn() {
    // Morph now alternates single placements: one stone per turn, turn flips after each placement.
    let (mode, s) = build(GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 }, 0);
    assert_eq!(s.turn, 0);
    assert_eq!(s.moves_left_in_turn, 1);

    let m = mode.ordered_moves(&s)[0];
    let after = mode.apply(&s, &m);
    assert_eq!(after.turn, 1, "turn flips after a single placement");
    assert_eq!(after.moves_left_in_turn, 1);
}

#[test]
fn win_on_placement_is_detected() {
    // I-cells 0,1,2 already mine; player 0 completes the shape at cell 3 in a single placement.
    let mut board = vec![E; 16];
    board[0] = p(0, 1);
    board[1] = p(0, 1);
    board[2] = p(0, 1);
    let mode = morph_4x4();
    let s = state(4, 4, board, vec![5], vec![1], 0, 1);

    let ns = mode.apply(&s, &Move { value: Some(5), cell: 3 });
    assert_eq!(mode.is_terminal(&ns), Some(GameResult::Win(0)));
    // The placement flips the turn (single placement); the winner is the player who just moved.
    assert_eq!(ns.turn, 1);
}

#[test]
fn morph_capture_follows_original_rules() {
    // Capture rules identical to Original (spec §4.4): strict-greater captures, deletes permanently.
    let mut board = vec![E; 16];
    board[5] = p(1, 4);
    let mode = morph_4x4();
    let s = state(4, 4, board, vec![6], vec![4], 0, 2);
    let ns = mode.apply(&s, &Move { value: Some(6), cell: 5 });
    assert_eq!(ns.at(5).unwrap().owner, 0);
    assert_eq!(ns.at(5).unwrap().value, 6);
    assert_eq!(ns.hands[1], vec![4], "captured pawn does not return to enemy hand");
}
