//! Easy difficulty: random play with a light capture/placement bias (spec §7.2).

use engine::{GameState, Mode, Move, Rng};

/// Roll odd → prefer empty cells; even → prefer occupied cells (capture attempt). If the preferred
/// pool is empty, fall back to all legal moves. The fallback is recomputed every turn — there is no
/// permanent "can't place here" flag (spec §7.2).
pub fn easy_move(mode: &dyn Mode, state: &GameState, rng: &mut Rng) -> Option<Move> {
    let moves = mode.legal_moves(state);
    if moves.is_empty() {
        return None;
    }

    let prefer_empty = rng.next_u64() % 2 == 1;
    let pool: Vec<Move> = moves
        .iter()
        .copied()
        .filter(|m| {
            let occupied = state.at(m.cell).is_some();
            if prefer_empty {
                !occupied
            } else {
                occupied
            }
        })
        .collect();

    let chosen = if pool.is_empty() { &moves } else { &pool };
    Some(chosen[rng.below(chosen.len())])
}
