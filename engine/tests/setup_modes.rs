//! Initial-state construction (spec §3.2 counts, §4.3 Bonanza distribution).

use engine::{build, GameConfig, ModeKind};

#[test]
fn classic_hands_fill_the_board() {
    let (_m, s) = build(GameConfig { kind: ModeKind::Classic, rows: 3, cols: 3, win_len: 3 }, 0);
    // 9 cells: player 0 gets 5 (moves first), player 1 gets 4.
    assert_eq!(s.hands[0].len(), 5);
    assert_eq!(s.hands[1].len(), 4);
    assert_eq!(s.moves_left_in_turn, 1);

    let (_m, s4) = build(GameConfig { kind: ModeKind::Classic, rows: 4, cols: 4, win_len: 3 }, 0);
    assert_eq!(s4.hands[0].len(), 8);
    assert_eq!(s4.hands[1].len(), 8);
}

#[test]
fn original_hands_match_spec_counts() {
    let (_m, s3) = build(GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, 0);
    assert_eq!(s3.hands[0], (1..=6).collect::<Vec<u8>>());
    assert_eq!(s3.hands[1], (1..=6).collect::<Vec<u8>>());

    let (_m, s4) = build(GameConfig { kind: ModeKind::Original, rows: 4, cols: 4, win_len: 3 }, 0);
    assert_eq!(s4.hands[0].len(), 11);
    assert_eq!(s4.hands[1].len(), 11);
}

#[test]
fn morph_hands_have_two_of_each_value() {
    let (_m, s4) = build(GameConfig { kind: ModeKind::Morph, rows: 4, cols: 4, win_len: 3 }, 0);
    // 4×4 → values 1..6, two each = 12 pawns; single alternating placement (one move per turn).
    assert_eq!(s4.hands[0].len(), 12);
    assert_eq!(s4.moves_left_in_turn, 1);
    for v in 1..=6u8 {
        assert_eq!(s4.hands[0].iter().filter(|&&x| x == v).count(), 2);
    }

    let (_m, s5) = build(GameConfig { kind: ModeKind::Morph, rows: 5, cols: 5, win_len: 3 }, 0);
    assert_eq!(s5.hands[0].len(), 22); // values 1..11, two each
}

#[test]
fn bonanza_is_deterministic_per_seed() {
    let a = build(GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 }, 12345).1;
    let b = build(GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 }, 12345).1;
    assert_eq!(a.hands, b.hands);
}

#[test]
fn bonanza_preserves_the_pawn_pool() {
    // Each player ends with N pawns; the combined multiset is exactly two copies of 1..=N
    // (the two color pools), regardless of seed (spec §4.3).
    for seed in 0..50u64 {
        let s = build(GameConfig { kind: ModeKind::Bonanza, rows: 3, cols: 3, win_len: 3 }, seed).1;
        assert_eq!(s.hands[0].len(), 6);
        assert_eq!(s.hands[1].len(), 6);

        let mut combined: Vec<u8> = s.hands[0].iter().chain(s.hands[1].iter()).copied().collect();
        combined.sort_unstable();
        let mut expected: Vec<u8> = (1..=6).chain(1..=6).collect();
        expected.sort_unstable();
        assert_eq!(combined, expected, "seed {seed}: pool must be two copies of 1..=6");
    }
}

#[test]
fn bonanza_k_zero_case_can_occur() {
    // Over many seeds, at least one distribution should be lopsided (no balancing guarantee).
    let mut saw_imbalance = false;
    for seed in 0..200u64 {
        let s = build(GameConfig { kind: ModeKind::Bonanza, rows: 4, cols: 4, win_len: 3 }, seed).1;
        // duplicates in a hand are possible only because of the randomized pool.
        let has_dup = {
            let mut h = s.hands[0].clone();
            h.sort_unstable();
            h.windows(2).any(|w| w[0] == w[1])
        };
        if has_dup {
            saw_imbalance = true;
            break;
        }
    }
    assert!(saw_imbalance, "Bonanza should produce unbalanced (duplicate-value) hands");
}
