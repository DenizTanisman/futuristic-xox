# Plan — Setup Redesign + Classic Win-Length + Morph Single-Placement + Phone-Only Test-Dev

> Four coordinated changes (A setup layout, B Classic 4×4 short/long win length, C Morph single
> alternating placement, D phone-only test-dev). Built on `feat/macos-selfplay-harness` (has the tier
> model + Dart mirror + test-dev harness) on branch `feat/setup-winlen-morph`. `main` untouched.

## Confirmed assumptions (§1.2 — owner-approved defaults)

- **"classic 3x3 long" = "classic 4x4 long"** (4-in-a-row is impossible on a 3-wide board; 3×3 stays 3).
- **Futuristic grids stay per-mode** (Original/Bonanza 3×3·4×4; Morph 4×4·5×5).
- **Multiplayer ON = local two-human** (pass-and-play); AI not invoked; difficulty block disabled.
- **Test-dev gating = `kDebugMode`** (owner choice — no Flutter flavor). `kDebugMode` is already false
  in release/profile builds, so the test-dev surface is **absent from every distributable** by
  construction; no extra build config. Present in the owner's debug build, 2 s on-phone budget.

## §5(C) decision — apply changes in BOTH Rust and Dart (owner choice)

The shipping app runs the **Dart** `dart_game_api.dart` mirror; the Rust `engine`/`ai` are canonical
but not wired in. To make Classic 4×4-long and single-placement Morph take effect **on the phone**, the
Dart side must change; to keep the canonical engine + analysis tool consistent, the Rust side changes
too. So gameplay rules are updated in **both** languages (~2× the change). Units:

- **Unit A (rules):** Rust engine + Dart mirror.  ← Rust half done in this commit; Dart half next.
- **Unit B:** UI setup screens (Futuristic 2×2 difficulty + grid + Multiplayer; Classic difficulty row
  + `[3x3][4x4 short][4x4 long]` + Multiplayer).
- **Unit C:** Multiplayer ON/OFF wiring + test-dev 2 s budget (already `kDebugMode`-gated; verify it
  works under the new rules).
- **Tutorial rewrite** (after Unit A): Morph onboarding from two-stones-per-turn → single-alternating,
  all four locales.

## Cross-impacts (flagged)

- **Morph tutorial** steps describing "two stones per turn" become wrong → rewrite (Unit A follow-up).
- **AI/search:** negamax's "same player still to move → don't negate" branch is now never hit for
  Morph (turn always flips). No code change; tests confirm `apply`/search under `moves_left_in_turn=1`.
- **Analysis filler:** the Morph tables it produced are under the OLD two-placement rules → **obsolete**
  for the new Morph; would need re-running. The macOS-harness / analysis-filler order notes assume
  two-placement Morph — documentation parity to follow.
- **Bridge** `MoveResult.single_move_fallback` is now vestigial for Morph (moves_left is always 1);
  left in place (harmless) for a later cleanup.

## Unit A (Rust) — done

- `geometry::line_segments(rows, cols, win_len)` (generalizes `line_triples`); `winner_on_lines`
  accepts variable-length lines; `LineMode` carries `win_len`; `GameConfig.win_len` (default 3, Classic
  honors it, Original/Bonanza forced to 3, Morph unaffected). Threat heuristic generalized to
  `win_len-1` owned + one open.
- Morph single placement: `morph_state.moves_left_in_turn = 1`; `MorphMode::apply` uses `per_turn = 1`
  → turn flips after every placement.
- Tests: line-segment counts (4×4 win3 = 24, win4 = 10); Classic short wins on 3 / long only on 4;
  Morph single placement flips the turn and a full game alternates; obsolete two-move tests rewritten.
  All Rust tests + clippy clean.
