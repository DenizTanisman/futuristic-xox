//! Hard-difficulty tactical correctness: takes immediate wins, blocks immediate losses, and plays
//! tic-tac-toe perfectly (spec §7.4).

mod common;
use ai::{play_move, SelectionPolicy};
use common::{p, perfect, play_game, state, E};
use engine::{GameConfig, GameResult, LineMode, Mode, ModeKind};

#[test]
fn hard_takes_immediate_win_classic() {
    // Player 0 has cells 0,1; playing cell 2 completes the top row.
    let mut board = vec![E; 9];
    board[0] = p(0, 0);
    board[1] = p(0, 0);
    let mode = LineMode::new(3, 3, false, 3);
    let s = state(3, 3, board, vec![0, 0, 0], vec![0, 0], 0, 1);

    let mv = play_move(&mode, &s, SelectionPolicy::AlwaysBest, perfect(9), 1).unwrap();
    assert_eq!(mv.cell, 2, "Hard must take the winning move");
}

#[test]
fn hard_blocks_immediate_loss_classic() {
    // Player 1 threatens the middle row (cells 3,4) — open at 5. Player 0 (one pawn at corner) must
    // block cell 5; it has no win of its own.
    let mut board = vec![E; 9];
    board[0] = p(0, 0);
    board[3] = p(1, 0);
    board[4] = p(1, 0);
    let mode = LineMode::new(3, 3, false, 3);
    let s = state(3, 3, board, vec![0, 0, 0], vec![0, 0, 0], 0, 1);

    let mv = play_move(&mode, &s, SelectionPolicy::AlwaysBest, perfect(9), 1).unwrap();
    assert_eq!(mv.cell, 5, "Hard must block the opponent's winning move");
}

#[test]
fn hard_takes_capture_win_original() {
    // Original 3×3: player 0 owns cells 0,1; cell 2 holds an enemy 3. Player 0 holds a 5 → capturing
    // cell 2 both removes the enemy and completes the line.
    let mut board = vec![E; 9];
    board[0] = p(0, 7);
    board[1] = p(0, 7);
    board[2] = p(1, 3);
    let mode = LineMode::new(3, 3, true, 3);
    let s = state(3, 3, board, vec![5], vec![1], 0, 1);

    let mv = play_move(&mode, &s, SelectionPolicy::AlwaysBest, perfect(12), 1).unwrap();
    assert_eq!(mv.cell, 2);
    assert_eq!(mv.value, Some(5));
}

#[test]
fn hard_vs_hard_classic_3x3_is_a_draw() {
    // Perfect tic-tac-toe play by both sides always draws — the canonical correctness check.
    let config = GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 };
    let result = play_game(config, 0, SelectionPolicy::AlwaysBest, SelectionPolicy::AlwaysBest, perfect(9));
    assert_eq!(result, GameResult::Draw);
}

#[test]
fn hard_never_loses_classic_3x3_against_easy() {
    // Across several seeds, perfect play must never lose to Easy (draw or win only).
    let config = GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 };
    for seed in 0..15u64 {
        // Hard is player 0.
        let r = play_game(config, seed, SelectionPolicy::AlwaysBest, SelectionPolicy::LowMix, perfect(9));
        assert_ne!(r, GameResult::Win(1), "Hard (P0) lost to Easy at seed {seed}");
        // Hard is player 1.
        let r = play_game(config, seed, SelectionPolicy::LowMix, SelectionPolicy::AlwaysBest, perfect(9));
        assert_ne!(r, GameResult::Win(0), "Hard (P1) lost to Easy at seed {seed}");
    }
}

#[test]
fn hard_prefers_faster_win() {
    // With a one-move win available, Hard must not dawdle (win-sooner scoring, spec §7.4).
    let mut board = vec![E; 9];
    board[0] = p(0, 0);
    board[1] = p(0, 0);
    let mode = LineMode::new(3, 3, false, 3);
    let s = state(3, 3, board, vec![0, 0, 0], vec![0, 0], 0, 1);
    let mv = play_move(&mode, &s, SelectionPolicy::AlwaysBest, perfect(9), 7).unwrap();
    // Completing now (cell 2) is the only immediate win.
    assert_eq!(mv.cell, 2);
    // Sanity: applying it is indeed terminal.
    let ns = mode.apply(&s, &mv);
    assert_eq!(mode.is_terminal(&ns), Some(GameResult::Win(0)));
}
