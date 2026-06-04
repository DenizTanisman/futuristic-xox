# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Repository scaffold: Cargo workspace (`engine`, `ai`), `aidlc-docs/` artifact tree,
  `CHANGELOG.md`, `README.md`, `.gitignore`.
- `CLAUDE.md` (copy of the build spec) at repo root for auto-loaded context.
- **U1 Engine** (`engine/` crate): state model (`GameState`, `Pawn`, `Move`, `GameResult`), the
  frozen `Mode` trait (spec §7.1), capture & legality rules (strict-greater, permanent deletion),
  win detection for 3-in-a-row (all grids) and Morph 4-cell shapes (I/L/Z, all rotations + mirror,
  sliding-window), per-mode setup (Classic, Original, Bonanza, Morph), pure `apply`, and
  two-moves-per-turn with single-move fallback for Morph.
- Dependency-free seedable PRNG (`rng::Rng`, SplitMix64) for Bonanza hand randomization.
- 41 headless tests covering every rule (capture/legality, win/draw, Morph shapes & turn handling,
  per-mode setup, full random playthroughs across all 8 mode/grid combinations).
- AI-DLC artifacts: build plan, ADR-001 (engine domain design), Morph-shapes log, Bonanza-distribution
  decision log.
- **U2 AI** (`ai/` crate): Easy (random with capture/placement bias), Medium (per-turn Easy/Hard
  coin flip), Hard (negamax + alpha-beta, transposition table with Zobrist hashing, iterative
  deepening + time box, TT/static move ordering). Public `choose_move(mode, state, difficulty,
  limits, seed)`. 14 tests (tactics: immediate win/block, perfect-play 3×3 draw, never-loses-to-Easy;
  cross-mode legality + termination; 5×5 Morph time-box). Self-play harness + calibration log
  (Hard scores 97–100% vs Easy, 95% vs Medium, never loses).
- **Bridge facade** (`bridge/` crate): `GameSession` over engine + ai with flat, FFI-friendly view
  structs (`Snapshot`, `MoveResult`, `Outcome`) ready for `flutter_rust_bridge`. Reports captures,
  Morph single-move fallback, and inline illegal-move reasons. 6 tests.
- **U3 UI** (`ui/` Flutter app): entry/futuristic-select/setup/game screens (spec §8), board with
  legal-cell highlighting + last-move marker, both pawn rails with slide animation, turn & Morph
  "move N of 2" indicators, inline messages, win/lose/draw banner; bordeaux vs dark-gold theme with
  60fps placement/capture/rail animations. Backend-agnostic `GameApi` with a pure-Dart mock engine
  (`DartGameApi`, faithful rule port + mock AI) so the app runs without the Rust toolchain; native
  `flutter_rust_bridge` backend is the integration step. Dart rule-parity tests.
- **U3 verified with Flutter 3.44.1** (SDK installed): `flutter analyze` clean, 9 tests pass
  (engine rule-parity + widget smoke), `flutter build web` succeeds. Added Android/iOS/web platform
  scaffolding.

### Changed
- **Morph win condition (play-test, spec §4.4/§5/§13.1):** one target shape (I/L/Z) is chosen at
  game start; the win is to complete *that* shape. **Diagonal/staircase placements are now included**
  (reversing the earlier "exclude the diagonal I" default) via a Morph-only basis-vector generator:
  each orientation (4 rotations + mirror) is laid under both an axis frame and a 45° diagonal frame
  `(r,c)->(r+c,r-c)`. Synced across the Rust engine (`geometry::morph_placements_for_shape`,
  `MorphMode::new(rows, cols, shape_index)`, seed-chosen shape in `build`) and the Dart mock backend.
  Line modes' 3-in-a-row is untouched. Build spec §5/§7.5/§14 updated with the verified algorithm and
  diagonal regression fixtures.
- **Bonanza (play-test, spec §4.3):** hands now carry per-pawn colour, so a player can hold (and
  place) opponent-coloured pawns — the placed pawn's board owner is the pawn's colour. (Dart backend;
  Rust state-model sync pending.) Earlier ADR-001 interpretation reversed per play-test.
- UI: Classic renders X/O glyphs; Morph shows a target-shape badge ("any rotation") and a green-star
  hint on cells that complete the target this move; Bonanza shows the own-colour count for 2s at
  start. Dart mock AI upgraded to real negamax + alpha-beta (Hard plays perfectly on 3×3).

### Fixed
- Classic hands were fixed-length lists, so playing a symbol threw `Cannot remove from a
  fixed-length list`; hands are now growable. (Caught by the Dart test suite.)

[Unreleased]: https://example.com/compare/HEAD
