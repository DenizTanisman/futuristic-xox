//! Shared test helpers for constructing precise board states.

use engine::{GameState, Pawn};

/// Build a state with a custom board and hands. `board` uses `Some((owner, value))` for a pawn.
pub fn state(
    rows: usize,
    cols: usize,
    board: Vec<Option<(u8, u8)>>,
    hand0: Vec<u8>,
    hand1: Vec<u8>,
    turn: u8,
    moves_left_in_turn: u8,
) -> GameState {
    assert_eq!(board.len(), rows * cols, "board must be rows*cols");
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

/// Shorthand for an empty cell in a board literal.
pub const E: Option<(u8, u8)> = None;

/// Shorthand for a pawn cell.
pub fn p(owner: u8, value: u8) -> Option<(u8, u8)> {
    Some((owner, value))
}
