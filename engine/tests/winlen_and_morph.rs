//! Configurable win length (Classic short/long) + Morph single alternating placement.

use engine::{build, GameConfig, GameResult, GameState, LineMode, Mode, ModeKind, Move, Pawn};

fn classic_board_with_p0(cells: &[usize]) -> GameState {
    let board = (0..16)
        .map(|i| {
            if cells.contains(&i) {
                Some(Pawn { owner: 0, value: 0 })
            } else {
                None
            }
        })
        .collect();
    // Non-empty hands so a non-winning position reads as in-progress (not a board-full draw).
    GameState {
        board,
        hands: [vec![0u8; 4], vec![0u8; 4]],
        turn: 1,
        moves_left_in_turn: 1,
        cols: 4,
        rows: 4,
    }
}

#[test]
fn classic_4x4_short_wins_on_three() {
    let short = LineMode::new(4, 4, false, 3);
    let s = classic_board_with_p0(&[0, 1, 2]); // three in the top row
    assert_eq!(short.is_terminal(&s), Some(GameResult::Win(0)));
}

#[test]
fn classic_4x4_long_ignores_three_wins_on_four() {
    let long = LineMode::new(4, 4, false, 4);
    let three = classic_board_with_p0(&[0, 1, 2]);
    assert_eq!(long.is_terminal(&three), None, "3-in-a-row must NOT win in long");
    let four = classic_board_with_p0(&[0, 1, 2, 3]);
    assert_eq!(long.is_terminal(&four), Some(GameResult::Win(0)), "4-in-a-row wins long");
}

#[test]
fn build_passes_win_len_for_classic_only() {
    // Classic long actually uses 4; Original stays 3 regardless of the config field.
    let (long, _) = build(GameConfig { kind: ModeKind::Classic, rows: 4, cols: 4, win_len: 4 }, 0);
    let s = classic_board_with_p0(&[0, 1, 2]);
    assert_eq!(long.is_terminal(&s), None);
}

#[test]
fn morph_single_placement_flips_turn_immediately() {
    let (mode, s) = build(GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 }, 0);
    assert_eq!(s.moves_left_in_turn, 1, "Morph now starts with one move per turn");
    let after = mode.apply(&s, &Move { value: Some(1), cell: 5 });
    assert_eq!(after.turn, 1, "turn flips after a single placement");
    assert_eq!(after.moves_left_in_turn, 1);
}

#[test]
fn morph_full_game_alternates_single_placements() {
    // Drive a Morph game placing the cheapest legal move each ply; the turn must alternate every ply.
    let (mode, mut s) = build(GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 }, 0);
    let mut prev_turn = s.turn;
    let mut plies = 0;
    while mode.is_terminal(&s).is_none() && plies < 60 {
        let mv = mode.ordered_moves(&s)[0];
        s = mode.apply(&s, &mv);
        assert_ne!(s.turn, prev_turn, "every placement flips the turn under single-placement Morph");
        prev_turn = s.turn;
        plies += 1;
    }
    assert!(mode.is_terminal(&s).is_some(), "the game terminates");
}
