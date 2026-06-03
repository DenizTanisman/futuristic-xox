//! Capture & legality rules (spec §3.3): strict-greater capture, permanent deletion,
//! equal/own illegal, empty always legal.

mod common;
use common::{p, state, E};
use engine::{is_move_legal, LineMode, Mode, Move};

/// A 3×3 Original mode (valued + capture).
fn original() -> LineMode {
    LineMode::new(3, 3, true)
}

#[test]
fn empty_cell_always_legal() {
    let s = state(3, 3, vec![E; 9], vec![1, 2, 3], vec![1, 2, 3], 0, 1);
    assert!(is_move_legal(&s, &Move { value: Some(2), cell: 4 }, true));
}

#[test]
fn capture_requires_strictly_greater() {
    // Enemy 3 sits on cell 4. Player 0 holds {2,3,4}.
    let mut board = vec![E; 9];
    board[4] = p(1, 3);
    let s = state(3, 3, board, vec![2, 3, 4], vec![], 0, 1);

    // value 2 < 3 → illegal
    assert!(!is_move_legal(&s, &Move { value: Some(2), cell: 4 }, true));
    // value 3 == 3 → illegal (equal is not enough, spec §3.3.3)
    assert!(!is_move_legal(&s, &Move { value: Some(3), cell: 4 }, true));
    // value 4 > 3 → legal capture
    assert!(is_move_legal(&s, &Move { value: Some(4), cell: 4 }, true));
}

#[test]
fn own_pawn_cell_is_illegal() {
    let mut board = vec![E; 9];
    board[0] = p(0, 5);
    let s = state(3, 3, board, vec![6], vec![], 0, 1);
    // Even a higher value cannot be placed on your own pawn (spec §3.3.4).
    assert!(!is_move_legal(&s, &Move { value: Some(6), cell: 0 }, true));
}

#[test]
fn capture_deletes_enemy_pawn_permanently() {
    // Player 0 captures enemy 3 on cell 4 with a 5.
    let mut board = vec![E; 9];
    board[4] = p(1, 3);
    let mode = original();
    let s = state(3, 3, board, vec![5], vec![3], 0, 1);

    let before_enemy_hand = s.hands[1].clone();
    let ns = mode.apply(&s, &Move { value: Some(5), cell: 4 });

    // The cell is now owner 0, value 5.
    let pawn = ns.at(4).unwrap();
    assert_eq!(pawn.owner, 0);
    assert_eq!(pawn.value, 5);

    // The captured pawn does NOT return to the enemy's hand (spec §3.3.2).
    assert_eq!(ns.hands[1], before_enemy_hand);
    // The placed pawn left player 0's hand.
    assert!(ns.hands[0].is_empty());
}

#[test]
fn placed_pawn_always_leaves_hand_on_empty_cell() {
    let mode = original();
    let s = state(3, 3, vec![E; 9], vec![4, 4, 6], vec![], 0, 1);
    let ns = mode.apply(&s, &Move { value: Some(4), cell: 0 });
    // Exactly one 4 removed.
    assert_eq!(ns.hands[0], vec![4, 6]);
    assert_eq!(ns.at(0).unwrap().value, 4);
}

#[test]
fn apply_does_not_mutate_input() {
    let mode = original();
    let s = state(3, 3, vec![E; 9], vec![1, 2, 3], vec![1, 2, 3], 0, 1);
    let snapshot = s.clone();
    let _ = mode.apply(&s, &Move { value: Some(2), cell: 4 });
    assert_eq!(s, snapshot, "apply must be pure (spec §6)");
}

#[test]
fn turn_flips_after_line_mode_move() {
    let mode = original();
    let s = state(3, 3, vec![E; 9], vec![1], vec![1], 0, 1);
    let ns = mode.apply(&s, &Move { value: Some(1), cell: 0 });
    assert_eq!(ns.turn, 1);
    assert_eq!(ns.moves_left_in_turn, 1);
}
