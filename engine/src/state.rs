//! Core state model (spec §6).
//!
//! All types are plain data. The only behavior here is small, allocation-free accessors;
//! all rules live in the mode implementations so this stays a pure value layer.

/// A pawn on the board. `value` is unused in Classic (stored as 0).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Pawn {
    pub owner: u8, // 0 or 1
    pub value: u8,
}

/// A single placement. `value` is `None` in Classic (symbols carry no value); `Some(v)` otherwise.
/// `cell` is a flat board index in `0..rows*cols`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct Move {
    pub value: Option<u8>,
    pub cell: usize,
}

/// Terminal outcome. Named `GameResult` to avoid shadowing `std::result::Result`
/// (semantically the spec's `enum Result { Win(u8), Draw }`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum GameResult {
    Win(u8), // winning owner: 0 or 1
    Draw,
}

/// The full game state (spec §6). `apply` produces a new value; it is never mutated in place
/// during search.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GameState {
    /// Flat board, length `rows*cols`. `None` = empty.
    pub board: Vec<Option<Pawn>>,
    /// Remaining pawn values per player. Classic stores symbol tokens as `0`s.
    pub hands: [Vec<u8>; 2],
    /// Side to move: 0 or 1.
    pub turn: u8,
    /// Moves remaining in the current turn (1 for line modes; 2 for Morph, decremented to 0).
    pub moves_left_in_turn: u8,
    pub cols: usize,
    pub rows: usize,
}

impl GameState {
    /// Total number of cells.
    #[inline]
    pub fn cell_count(&self) -> usize {
        self.rows * self.cols
    }

    /// Whether a flat index is inside the board (spec §9: never trust a computed index).
    #[inline]
    pub fn in_bounds(&self, cell: usize) -> bool {
        cell < self.cell_count()
    }

    /// Pawn at a cell, if any. Returns `None` for empty *or* out-of-bounds cells.
    #[inline]
    pub fn at(&self, cell: usize) -> Option<Pawn> {
        self.board.get(cell).copied().flatten()
    }

    /// The hand of the side to move.
    #[inline]
    pub fn current_hand(&self) -> &[u8] {
        &self.hands[self.turn as usize]
    }

    /// Convert a flat index to `(row, col)`.
    #[inline]
    pub fn rc(&self, cell: usize) -> (usize, usize) {
        (cell / self.cols, cell % self.cols)
    }

    /// Convert `(row, col)` to a flat index.
    #[inline]
    pub fn idx(&self, row: usize, col: usize) -> usize {
        row * self.cols + col
    }

    /// True when no pawns remain in either hand.
    #[inline]
    pub fn both_hands_empty(&self) -> bool {
        self.hands[0].is_empty() && self.hands[1].is_empty()
    }
}
