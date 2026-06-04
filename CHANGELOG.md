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
- **App icon** — launcher (iOS opaque master + Android adaptive foreground/background) and the
  store-listing icon (squircle + gold frame), from the Classic-X + Futuristic-medallion design.
  Masters are rendered natively from a `Canvas` (no external rasterizer) by `test/icon_gen_test.dart`,
  then expanded by `flutter_launcher_icons`. iOS master fills to the corners (system rounds it);
  Android keeps content in the safe zone for adaptive masks.

### Added
- **Mode picker & setup screens** — rebuilt inside a shared metallic shimmer panel (reusable
  `MetallicPanel`) with Cinzel metallic titles and a back chevron. Futuristic submode picker shows
  Original / Bonanza / Morph cards (metallic icon tile + description, hover lift + glow). Setup uses
  themed segmented selectors for Difficulty and Grid (grid options adapt per mode; each shows an n×n
  mini-grid dot icon), a styled Offline-Multiplayer toggle (dims + disables Difficulty while Grid
  stays active), and a metallic gradient Start button. Fully themed per mode.
- **Entry/landing screen** — responsive Classic | Futuristic split (side-by-side on wide screens,
  top/bottom on phones via `LayoutBuilder`), slide-in entrance, metallic gradient titles (Cinzel 900
  via `ShaderMask`), an animated steel→gold divider with a sheen shift, themed motifs (Classic X/O
  `CustomPaint`, Futuristic corner medallions reusing the pawn widget), hover-to-expand on desktop,
  and a "tap to play" pill; tapping a side opens that mode's setup.
- **UI themes** — Classic (cold metallic) and Futuristic (warm luxury), rebuilt natively in Flutter
  (no WebView): a shared `GameTheme` abstraction (colours/gradients/fonts via an `InheritedWidget`),
  Cinzel (display) + Rajdhani (UI/numbers) via `google_fonts`, themed radial backgrounds, a beveled
  metallic frame with a sweeping rim shimmer, staggered board reveal, cell hover/press glow, animated
  disc pawns (elastic pop-in + ring ripple, red on capture), animated Classic X/O metallic
  stroke-draw, a pulsing turn indicator, and a themed target badge. Animations are wrapped in
  `RepaintBoundary` and use transform/opacity for 60fps.
- **Offline multiplayer** (same-device, two players) via a `PlayerController` abstraction
  (`HumanController` / `AiController`, with a `RemoteController` seam for future online play). The
  game loop asks the active seat's controller for its move, so the engine/UI are identical across
  single-player, offline multiplayer, and (later) online — only the seat→controller mapping changes.
  Seat 0 (bottom) moves first, then seat 1 (top); Morph's two-moves-per-turn applies per seat.
  Player labels ("Player 1" / "Player 2", or "You" / "Computer") are sourced from the controller, so
  a future name/nickname swap touches one place.

### Changed
- Futuristic pawns are now metallic **medallions** (spec v2): a thin same-hue metallic sweep-gradient
  ring + colored inner radial disc (inset ~7%) + a bevel overlay + a metallic number drawn as a
  dark-stroke pass under a gradient-fill pass for crisp legibility at any size, in both rails.
  Seat 0 (player, bottom) = gold, seat 1 (opponent, top) = bordeaux.
- Morph target badge now shows the shape itself (a compact, vertical tetromino mini-grid with glowing
  gold cells) instead of a letter; keeps the "any rotation" sublabel.
- Board, cells, pawns, and typography are now driven by the shared `GameTheme` (no hardcoded colours);
  Classic mode uses the metallic theme + stroke-drawn X/O, Futuristic modes use the luxury theme +
  valued discs.
- Mode setup screens now include an **Offline Multiplayer** toggle (default off); turning it on dims
  and disables the Difficulty selector (no AI opponent) while Grid stays selectable.
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

### Removed
- On-board winning-cell hint markers (the green-star overlay). Players find winning placements
  themselves; win detection is unchanged.

### Fixed (pawn numbers)
- Pawn numbers are now legible everywhere (board + both rails, both colours): the fill is a solid
  gradient of the **opposite brightness to its disc** — dark bronze digits on gold pawns, bright
  digits on bordeaux pawns — never the disc's own hue, with a contrast outline + drop shadow.

### Fixed (entry screen, to match the mockup)
- Added the diagonal light-wedge sheen on each half (mirrored, meeting at the top-center seam).
- The center divider now animates (a gold sheen band sliding along its length) with a soft glow,
  instead of being a flat static line.
- Decorative corner motifs are sized to the half (responsive) instead of a fixed tiny size.
- The Classic X motif no longer shows a darker patch at the stroke crossing — opacity is applied once
  to the whole mark (group opacity) rather than per stroke.

### Fixed
- Classic hands were fixed-length lists, so playing a symbol threw `Cannot remove from a
  fixed-length list`; hands are now growable. (Caught by the Dart test suite.)
- Morph diagonal placements were asymmetric in the Dart backend (top-left forms dropped) — the
  diagonal frame is now normalized before sliding; guarded by 180°-symmetry tests in both backends.

[Unreleased]: https://example.com/compare/HEAD
