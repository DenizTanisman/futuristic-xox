//! Win/draw rules (spec §3.4): 3-in-a-row (h/v/diag, all grids), win-before-draw, hands-empty draw.

mod common;
use common::{p, state, E};
use engine::{GameResult, LineMode, Mode};

fn original_3x3() -> LineMode {
    LineMode::new(3, 3, true, 3)
}

#[test]
fn horizontal_line_wins() {
    let mut board = vec![E; 9];
    board[0] = p(0, 1);
    board[1] = p(0, 2);
    board[2] = p(0, 3);
    // turn flipped to player 1 after player 0's winning move.
    let s = state(3, 3, board, vec![], vec![5], 1, 1);
    assert_eq!(original_3x3().is_terminal(&s), Some(GameResult::Win(0)));
}

#[test]
fn vertical_line_wins() {
    let mut board = vec![E; 9];
    board[0] = p(1, 1);
    board[3] = p(1, 2);
    board[6] = p(1, 3);
    let s = state(3, 3, board, vec![5], vec![], 0, 1);
    assert_eq!(original_3x3().is_terminal(&s), Some(GameResult::Win(1)));
}

#[test]
fn diagonal_line_wins() {
    let mut board = vec![E; 9];
    board[0] = p(0, 1);
    board[4] = p(0, 2);
    board[8] = p(0, 3);
    let s = state(3, 3, board, vec![], vec![5], 1, 1);
    assert_eq!(original_3x3().is_terminal(&s), Some(GameResult::Win(0)));
}

#[test]
fn three_in_a_row_wins_on_4x4_too() {
    // "3 in a row, all grids" (spec §3.4): a 3-window on a 4×4 still wins.
    let mode = LineMode::new(4, 4, true, 3);
    let mut board = vec![E; 16];
    board[5] = p(0, 1);
    board[6] = p(0, 2);
    board[7] = p(0, 3);
    let s = state(4, 4, board, vec![], vec![9], 1, 1);
    assert_eq!(mode.is_terminal(&s), Some(GameResult::Win(0)));
}

#[test]
fn win_before_draw_even_when_hands_empty() {
    // Both hands empty AND a completed line → must report Win, not Draw (spec §3.4).
    let mut board = vec![E; 9];
    board[0] = p(0, 1);
    board[1] = p(0, 2);
    board[2] = p(0, 3);
    let s = state(3, 3, board, vec![], vec![], 1, 1);
    assert_eq!(original_3x3().is_terminal(&s), Some(GameResult::Win(0)));
}

#[test]
fn hands_empty_no_line_is_draw() {
    // No 3-in-a-row and the side to move has nothing to play → Draw (spec §3.4).
    let board = vec![
        p(0, 1), p(1, 2), p(0, 3),
        p(1, 4), p(0, 5), p(1, 6),
        p(1, 1), p(0, 2), p(1, 3),
    ];
    let s = state(3, 3, board, vec![], vec![], 0, 1);
    assert_eq!(original_3x3().is_terminal(&s), Some(GameResult::Draw));
}

#[test]
fn game_in_progress_is_not_terminal() {
    let s = state(3, 3, vec![E; 9], vec![1, 2, 3], vec![1, 2, 3], 0, 1);
    assert_eq!(original_3x3().is_terminal(&s), None);
}

#[test]
fn classic_draw_on_full_board() {
    // Classic uses board-full as draw (modeled as hands-empty, spec §4.1).
    let mode = LineMode::new(3, 3, false, 3);
    let board = vec![
        p(0, 0), p(1, 0), p(0, 0),
        p(0, 0), p(1, 0), p(1, 0),
        p(1, 0), p(0, 0), p(0, 0),
    ];
    let s = state(3, 3, board, vec![], vec![], 0, 1);
    assert_eq!(mode.is_terminal(&s), Some(GameResult::Draw));
}
