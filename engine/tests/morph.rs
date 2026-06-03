//! Morph rules (spec §4.4, §5): shape completion across rotations/mirrors, two moves per turn,
//! win-after-each-move, single-move fallback.

mod common;
use common::{p, state, E};
use engine::{build, GameConfig, GameResult, Mode, ModeKind, Move, MorphMode};

fn morph_4x4() -> MorphMode {
    MorphMode::new(4, 4)
}

#[test]
fn every_precomputed_shape_is_a_win_when_fully_owned() {
    // Strong property: owning all 4 cells of ANY placement (every I/L/Z rotation + mirror) wins.
    for (rows, cols) in [(4usize, 4usize), (5, 5)] {
        let mode = MorphMode::new(rows, cols);
        for placement in mode.placements() {
            let mut board = vec![E; rows * cols];
            for &cell in placement {
                board[cell] = p(0, 1);
            }
            let s = state(rows, cols, board, vec![], vec![], 1, 2);
            assert_eq!(
                mode.is_terminal(&s),
                Some(GameResult::Win(0)),
                "placement {placement:?} on {rows}x{cols} should be a win"
            );
        }
    }
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
fn two_moves_per_turn_keeps_same_player() {
    let (mode, s) = build(GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4 }, 0);
    assert_eq!(s.turn, 0);
    assert_eq!(s.moves_left_in_turn, 2);

    let m = mode.ordered_moves(&s)[0];
    let after_first = mode.apply(&s, &m);
    assert_eq!(after_first.turn, 0, "still player 0 after first of two moves");
    assert_eq!(after_first.moves_left_in_turn, 1);

    let m2 = mode.ordered_moves(&after_first)[0];
    let after_second = mode.apply(&after_first, &m2);
    assert_eq!(after_second.turn, 1, "turn flips after the second move");
    assert_eq!(after_second.moves_left_in_turn, 2);
}

#[test]
fn win_on_first_of_two_moves_is_detected_immediately() {
    // I-cells 0,1,2 already mine; player 0 to move with two moves left, completes on cell 3.
    let mut board = vec![E; 16];
    board[0] = p(0, 1);
    board[1] = p(0, 1);
    board[2] = p(0, 1);
    let mode = morph_4x4();
    // The player still holds another pawn, so the win — not the single-move fallback — is what ends
    // the turn early (spec §4.4: "wins immediately and does not make the second move").
    let s = state(4, 4, board, vec![5, 1], vec![1], 0, 2);

    let ns = mode.apply(&s, &Move { value: Some(5), cell: 3 });
    // Turn has NOT flipped (this was only the first move) but the game is already won (spec §4.4).
    assert_eq!(ns.turn, 0);
    assert_eq!(ns.moves_left_in_turn, 1);
    assert_eq!(mode.is_terminal(&ns), Some(GameResult::Win(0)));

    // terminal_score is positive from the winner's perspective (side to move == winner).
    assert!(mode.terminal_score(&GameResult::Win(0), &ns, 0) > 0);
}

#[test]
fn single_move_fallback_when_no_second_move() {
    // Player 0 holds exactly one pawn but has two moves in the turn. After placing it, no second
    // move is possible → the turn passes anyway (spec §4.4).
    let mode = morph_4x4();
    let s = state(4, 4, vec![E; 16], vec![3], vec![1, 2], 0, 2);
    let ns = mode.apply(&s, &Move { value: Some(3), cell: 5 });
    assert!(ns.hands[0].is_empty());
    assert_eq!(ns.turn, 1, "turn passes after the single available move");
    assert_eq!(ns.moves_left_in_turn, 2, "new player gets a fresh two-move turn");
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
