//! Position hashing for the transposition table (spec §7.7.3).
//!
//! Board cells use Zobrist hashing (XOR of per-`(cell, owner, value)` random keys). Hands, turn, and
//! `moves_left_in_turn` are mixed in too, since two states with the same board but different hands are
//! genuinely different positions. The full 64-bit key makes collisions negligible at these node counts.

use engine::{GameState, Rng};

/// Max pawn value across all modes is 11 (spec §3.2); index 0 covers Classic symbols.
const VALUE_SLOTS: usize = 13;

pub struct Zobrist {
    cells: usize,
    /// `[cell][owner][value]` flattened random keys.
    board: Vec<u64>,
    turn: [u64; 2],
    moves_left: [u64; 3], // 0, 1, or 2 moves left
}

impl Zobrist {
    pub fn new(cells: usize) -> Self {
        // Fixed seed → identical tables every run, so TT keys are stable and reproducible.
        let mut rng = Rng::new(0x5345_5845_5F58_4F58); // "SEXE_XOX"
        let board = (0..cells * 2 * VALUE_SLOTS).map(|_| rng.next_u64()).collect();
        Zobrist {
            cells,
            board,
            turn: [rng.next_u64(), rng.next_u64()],
            moves_left: [rng.next_u64(), rng.next_u64(), rng.next_u64()],
        }
    }

    #[inline]
    fn board_index(&self, cell: usize, owner: u8, value: u8) -> usize {
        (cell * 2 + owner as usize) * VALUE_SLOTS + value as usize
    }

    /// A 64-bit key uniquely (up to rare collision) identifying the full state.
    pub fn key(&self, s: &GameState) -> u64 {
        let mut h = 0u64;
        for cell in 0..self.cells {
            if let Some(p) = s.at(cell) {
                h ^= self.board[self.board_index(cell, p.owner, p.value.min(12))];
            }
        }
        h ^= self.turn[s.turn as usize & 1];
        h ^= self.moves_left[(s.moves_left_in_turn as usize).min(2)];

        // Hands are multisets, so XOR (which cancels duplicates) is unsafe — fold a sorted copy with
        // a multiply-add mixer instead, keeping value counts significant.
        for player in 0..2 {
            let mut hand = s.hands[player].clone();
            hand.sort_unstable();
            let mut acc = 0xcbf2_9ce4_8422_2325u64 ^ (player as u64).wrapping_mul(0x9E37_79B9);
            for &v in &hand {
                acc = (acc ^ (v as u64 + 1)).wrapping_mul(0x100_0000_01b3);
            }
            h ^= acc;
        }
        h
    }
}
