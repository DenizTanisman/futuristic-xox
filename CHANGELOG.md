# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Classic "4×4 long" variant** (4-in-a-row win) selectable in setup, alongside "4×4 short"
  (3-in-a-row); `winLen` threads setup → game → backend.
- **Multiplayer ON/OFF** in setup (local two-human pass-and-play; difficulty disabled) — wired into the
  redesigned setup screens (the toggle/seat routing already existed).

### Changed
- **Setup screens redesigned.** Futuristic difficulty is now a **2×2** grid (Easy/Medium ·
  Hard/Impossible) instead of a cramped 4-tier row; Classic shows a difficulty row + grid options
  `[3×3] [4×4 short] [4×4 long]`. Grid buttons carry `(side, winLen)`.
- **Dev test-dev (self-play harness)** gains a Classic win-length selector so 4×4-long is exercisable;
  it already runs at the 2 s on-device budget, behind `kDebugMode` (absent from release builds).
- **Morph is single alternating placement** (one stone per turn) instead of two per turn; shapes
  (I/L/Z, all orientations) and grids (4×4, 5×5) unchanged. Win length is now configurable for line
  modes (Classic 4×4 "long" = 4-in-a-row), updated in both the Rust engine and the Dart backend.
- **Morph tutorial:** repurposed the former "double move" step into "Her taştan iki tane" / "Two of
  each piece" (teaches the two-of-each hand composition; its [2,2,5,5] medallion visual already fit).

### Removed
- **Morph tutorial:** deleted the "two stones to win" demo (two-stone winning no longer exists under
  single-placement Morph) and its now-orphan strings; remaining steps/counters re-index automatically.

### Added
- **Dev-only macOS self-play test harness.** Pick mode + grid (+ Bonanza seed / Morph shape), make the
  first move, then both sides play the adversarial "first" option (**2 s/move time box**) to a
  win/draw. The full game is recorded; prev/next/replay scrubbing; a background producer (isolate)
  runs to terminal independent of the viewer; touching prev/next freezes auto-advance. No win/lose
  banner; the board persists until reset. Reachable only behind `kDebugMode` — **not in release
  builds**. Backed by `DartGameApi.selfPlayStep({timeMs, maxDepth})` (real `aiMove` keeps its own time
  box). A literally-perfect full-depth search is infeasible past tiny boards (Original 4×4 depth 6 ≈
  70 s), so the harness time-boxes each move; `timeMs: 0` keeps a deterministic depth-only mode for
  tests. Runs on any debug Flutter target (macOS needs full Xcode).

### Fixed
- **Hard AI is actually hard on device.** The shipping Flutter app runs the pure-Dart backend
  (`DartGameApi`) — the native Rust engine is not yet wired in — and that Dart search had no
  transposition table, so on phones it reached far shallower depth than the native engine within its
  ~450 ms time box and collapsed to greedy play: it missed winning moves and even handed the opponent
  immediate wins (a one-move-from-losing threat is only worth `-30` in the heuristic, so a shallow
  search trades it away). Two fixes: (1) a **transposition table + TT-ordered search** ported from
  `ai/src/hash.rs`/`hard.rs`, so the same time box explores many more nodes and deeper lines; and
  (2) two cheap **tactical guards** that run before the search and are depth-independent — take any
  immediate win, and never play a move that hands the opponent an immediate winning reply (line modes;
  Morph's two-move turns lean on the deepened search). Search depth caps bumped accordingly. Note:
  Morph's full strength on large grids still depends on wiring the native Rust AI (planned).

### Added
- **Adversarial search returning the top-3 ranked moves** (`first ≥ second ≥ third`), always
  populated; `None` only at terminal positions. Built via a top-k alpha-beta bound at the root
  (`alpha` held at the 3rd-best), so 2nd/3rd scores are honest while pruning is preserved
  (`ai/src/adversarial.rs`; ADR in `aidlc-docs/design-artifacts/topk-root-search-adr.md`).
- **`SelectionPolicy` (`AlwaysBest` / `Top3Uniform` / `MidMix` / `LowMix`) and `play_move`**, a
  stateless per-turn selector driven by a seedable die, with roll-first efficiency (weaker tiers skip
  the search entirely when the die selects the legacy random move `rastgele()` = `easy_move`).
- **Per-side difficulty tiers:** Futuristic (Easy/Medium/Hard/Impossible — four), Classic
  (Easy/Medium/Hard — three). In Rust via separate `FuturisticDifficulty` / `ClassicDifficulty` enums
  + `to_policy()` (making `Classic + Impossible` unrepresentable); in the Dart backend via a
  mode-aware `(mode, difficulty) → SelectionPolicy` mapping. The setup screen now offers the extra
  **Impossible** tier on the Futuristic side (localized in en/tr/es/ru).
- **Hard-algorithm flowchart** (`aidlc-docs/design-artifacts/hard-algorithm-flowchart.html`): a
  standalone, annotated diagram of the negamax + alpha-beta + TT + iterative-deepening search.

### Changed
- **Hard search refactored into the adversarial search** (`hard.rs` → `adversarial.rs`); the interior
  negamax, TT, time box, and iterative deepening are unchanged — only the root now collects an honest
  top-3. Weaker tiers may skip the search when the die selects `rastgele()`.
- **Difficulty meaning shifted.** On the Futuristic side, the always-best engine is now the new
  **Impossible** tier; **Hard** is `Top3Uniform` (strong but varied), **Medium** `MidMix`, **Easy**
  `LowMix`. On Classic, **Hard** stays always-best, **Medium** is `Top3Uniform`, **Easy** `LowMix`.
- **Dart backend (the shipping phone app) mirrors the tier model.** `DartGameApi` now runs the same
  adversarial top-3 search + selection policies; its earlier Medium anti-streak coin is removed
  (replaced by the tiers). The Rust crate remains the source of truth.

### Removed
- **`MediumState` / `choose_move_medium` / the old `Difficulty` coin** (Easy/Hard anti-streak) —
  superseded by `SelectionPolicy` + `play_move` in Rust and the mirrored tiers in Dart. No anti-streak
  guard anywhere now (by design — the mixes provide enough variety).

## [1.0.1] - 2026-06-05

Polish & bug-fix release: removes the medallion "ghost digit", cleans up pawn selection, structures the
Bonanza deal, fixes hand-rail overlap, and corrects four tutorial example boards.

### Fixed
- **Medallion ghost digit removed.** The pawn number had a text drop-shadow that Impeller (Android's
  renderer) mis-rasterized at erratic offsets, producing a faint duplicate digit around the value. The
  shadow is gone; the number is a clean outline + gradient-fill (opposite brightness of the disc), so
  it stays legible with no ghost.
- **Pawn selection is a clean glow halo only (ghost-digit fix).** Confirmed the value never had a
  selection-conditional emphasis layer — the digit already rendered identically selected/unselected —
  so the "semi-opaque ghost digit" on selected tiles came from the fixed-size selection glow washing
  small medallions and leaving Impeller raster residue. The glow is now scaled to the medallion size
  (no oversized wash on Morph 5×5) and each medallion is isolated in a `RepaintBoundary` so a
  selection change re-rasterizes only the halo, never leaving a stale layer. Value paint is untouched.
- **Tutorial ghost-medallion hardening.** Medallions (big showcase + hand-rail chips) now use
  content-stable widget keys (step + index + owner/value) so a value/content change retires the old
  layer instead of leaving a faint stale digit behind; step transitions already fade-through (old fully
  out before new in). Keys never encode transient state, so selection/place animations are unaffected.

### Changed
- **Tutorial content corrections.** Original "How you win" now shows three distinct values (2/3/5)
  instead of an impossible 2/2/2 row. Original "Capture and win" rebuilt to a rule-legal main-diagonal
  win (board 2 / 5*center / 3* / 4, hand [5,6]; place 6 on the centre 5 to capture and win — 5 is an
  illegal-equal distractor). Morph "That's why you move twice" shows the "two of each" set as a 2×2
  block (no horizontal overflow). Morph "Two pawns this time" hand rail is sorted ascending (1,4,5,6).

### Fixed
- **Bonanza deal is structured and sorted within each colour.** Each colour pool is split by the random
  `k` (remainder to the opponent) and then sorted **ascending within its colour group** — gold among
  gold, bordeaux among bordeaux, never interleaved as one mixed list — composed colour-0 group then
  colour-1 group, left→right, in both hands. Integrity verified: every pool tile lands in exactly one
  hand (no duplicates/none dropped).
- **Hand rail no longer overlaps/stacks tiles.** The shared rail now lays tiles out in a single clean
  row, shrinking them to fit the rail width (with a horizontal-scroll fallback for very large hands)
  instead of wrapping onto a second row — numbers stay readable across Classic/Original/Bonanza/Morph.

## [1.0.0] - 2026-06-05

First public release. Offline tic-tac-toe reimagined — Classic plus three Futuristic modes (Original,
Bonanza, Morph) with valued capturing pawns, a native-grade Rust engine + AI (running today on the
pure-Dart parity backend), four-language UI (tr/en/ru/es), light/dark themes, interactive tutorials
for every mode, a continuous win-line, and a full recorded audio pass (SFX + music).

### Added
- **Full audio wiring + music state machine.** Imported Deniz's recorded WAVs (renamed to ASCII assets
  under `assets/audio/`). Split the menu sound into **forward / back / tap** and added a **matchStart**
  cue. Two-layer audio: a `SfxController` (pooled one-shots, ~60 ms throttle) and a `MusicController`
  with two gapless loops (`ReleaseMode.loop`) driving the state machine — `lobby_music` loops across the
  menus (never restarted on navigation) → on match start it fades out while a quiet `match_ambient`
  loop fills the silence under the SFX → on match end the ambient stops and the exclusive win/lose/draw
  SFX plays → after the result the lobby loop resumes. Triggers wired: menu forward/back/tap, place
  (player **and** AI, incl. tutorials), select (Futuristic only), matchStart, win/lose/draw. Settings
  gains **independent SFX and Music** toggles + volumes (persisted: `sfx_*`, `music_*`); i18n in
  tr/en/ru/es ("Effects Volume" / "Music" / "Music Volume"). Cross-fades on music transitions; iOS
  silent switch respected. (Replaces the earlier synthesized placeholder SFX.)

- **Release engineering (v1.0.0 prep).** MIT `LICENSE`; portfolio README (License section, screenshots
  placeholders, status); Android release-signing config driven by a gitignored `android/key.properties`
  (with a committed `.template`) that falls back to the debug key when absent; signing material excluded
  via `.gitignore`; store metadata copy (Google Play / App Store, TR + EN) under
  `aidlc-docs/release/`. The **[1.0.0]** cut is held until background music lands and the on-device test
  pass is green.

- **Continuous win-line overlay (all modes).** On every win the board draws a single, unbroken stroke
  through the winning cells in path order — straight for 3-in-a-row and Morph I, one bend for L, a
  zigzag for Z, including diagonal/mirrored shapes. The engine now exposes the winning group
  (`Snapshot.winningCells`); an `orderWinPath` adjacency walk orders Morph's `morph_winner` set into a
  continuous path (3-in-a-row keeps its natural order). A `WinLinePainter` strokes one `Path` with
  round caps/joins + a soft glow, revealed progressively start→end via `PathMetric` (~0.9 s), aligned
  to the live cell centers at both board sizes, coloured by side (silver Classic / gold Futuristic),
  in sync with the win sound. Lose/draw show no line.

### Fixed
- **Hand-rail selection — glow only, no lift, no duplicate.** Selecting a pawn from the hand rail no
  longer lifts/translates it (which left a ghost copy under Impeller on mobile); selection is now shown
  purely by a stronger gold halo on the single, fixed-position pawn — across the Original/Bonanza/Morph
  tutorials and the in-game rail. The select sound and place-on-tap are unchanged.
- **Entry screen mode names are now fixed brand names** ("CLASSIC" / "FUTURISTIC") that no longer
  change with the selected language (matching the Original/Bonanza/Morph submode names).
- **Turkish header casing.** Shell page titles now use Turkish-aware upper-casing so the dotted İ
  renders ("EĞİTİMLER", not "EĞITIMLER") — Dart's default `toUpperCase` and the Cinzel small-caps
  glyph both dropped the dot.
- **Turkish win message grammar.** When the human player wins, the banner now reads the 2nd-person
  "Sen kazandın!" (via a dedicated `resultYouWin` string) instead of the 3rd-person "Sen kazandı!".
- **Settings choice weight.** Language/theme option labels use medium weight so the Cyrillic
  fallback ("Русский", absent from the UI font) no longer renders heavy/bold; selection stays clear
  via colour, border, and the check icon.

### Added
- **Sound system (SFX).** An `AudioController` (singleton) preloads six low-latency clips — menu
  navigation, pawn placement, pawn select (Futuristic), and win/lose/draw — one reused `AudioPlayer`
  per `SoundId` (never one per tap), so distinct sounds overlap while same-id repeats are throttled
  (~60 ms). Clips are synthesized from the spec's tone recipes (warm, understated; win ~0.6 s, the
  rest < 0.4 s) as OGG under `assets/audio/`. Triggers: navigation + primary buttons (`menuNav`),
  every placement including AI moves and tutorials (`place`), Futuristic hand selection (`select`),
  and the game result (`win`/`lose`/`draw`, once). Settings gains an **SFX on/off toggle + volume
  slider**, persisted (`sfx_enabled`, `sfx_volume`) and applied live; iOS uses an ambient audio
  context so SFX respect the silent switch. Fully gated by the toggle; localized (tr/en/ru/es).

- **Futuristic (Morph) mode interactive tutorial.** Completes the tutorial set (Classic, Original,
  Bonanza, Morph). A 12-step walkthrough on a **4×4 board** teaching Morph's shape-completion win:
  bring four pawns into an **I, L, or Z** — in any rotation, on the **axis or diagonal** frame, and
  its **mirror**. The win is a **pulsing gold glow on the 4 shape cells** (not a line). Includes a
  **two-pawns-per-turn** demo (place both glowing targets, with a "one more" hint between) and
  value-agnostic completion (any pawn fills a target). Shape-icon explainers (I/L/Z, a diagonal
  staircase, and L + mirrored-L mini-grids), a "Learn Original" ghost cross-link, and full i18n
  (tr/en/ru/es). The shared `FuturisticTutorialBoard` was generalized to any grid size (3×3/4×4).
  Auto-shows on first Morph entry and replayable from the **Tutorials** drawer (all four modes now
  available).

- **Futuristic (Bonanza) mode interactive tutorial.** Extends the Futuristic tutorial engine for
  Bonanza's randomized hands: a 10-step walkthrough with a **deal showcase** (a "Number: 4" badge
  plus the hand revealed chip-by-chip with a fading glow — gold group first, then bordeaux), a
  **bordeaux hand rail** (you can be forced to play opponent-colored pawns), a **win-with-your-own-pawn**
  demo (gold win line), and a **forced-loss** demo where the only empty cells are both losing: placing
  a bordeaux pawn on either completes an opponent line (bordeaux win line + "Opponent wins"). Win-line
  color reflects the winner (gold for us, bordeaux for the opponent). Step 2 carries a **"Learn
  Original"** ghost button that opens the Original tutorial and returns. Fully localized (tr/en/ru/es).
  Auto-shows on first Bonanza entry and replayable from the **Tutorials** drawer (Morph still "coming
  soon").

- **Futuristic (Original) mode interactive tutorial.** Extends the reusable tutorial engine for the
  valued-pawn rules: an 11-step walkthrough that introduces pawn numbers, free placement, capture
  (strictly higher value: a gold pawn can only land on a bordeaux one whose value is *strictly*
  smaller), and the three-in-a-row win — including capture-to-win. Gif-looped showcase boards (place
  and capture, 2s, timer cancelled on step change/dispose) plus select-then-place demos with a
  selectable gold `HandRail`: pick a pawn, then tap a cell; wrong/too-small/redirect taps surface a
  localized hint and flash the correct cell. Gold medallion board (`FuturisticTutorialBoard`) reusing
  the in-game `PawnWidget` (legible numbers, gold pop + ripple on placement, bordeaux scale-out on
  capture) and gold win lines. Uses the Futuristic silver→gold game theme regardless of the app
  light/dark theme; fully localized (tr/en/ru/es). Auto-shows on first Original entry and replayable
  from the **Tutorials** drawer (Bonanza/Morph still "coming soon").

- **Classic mode interactive tutorial.** A reusable tutorial engine (`TutorialController` +
  `TutorialStep` model; works for future modes) driving the 8-step Classic walkthrough: an
  always-on Skip + progress dots; gif-looped showcase steps (empty → place → win line → reset, 2s,
  timer cancelled on step change/dispose); tap-to-place demos with correct/wrong feedback (step 3
  accepts any empty cell, steps 5–7 require the exact target; wrong taps flash the correct cell 3×;
  occupied taps ignored); animated silver/gold mark stroke-draw + win lines (`MarkPainter`,
  `WinLinePainter`). Fully localized (tr/en/ru/es); surfaces follow the app theme while the Classic
  marks keep their fixed silver/gold identity. **Each mode's tutorial auto-shows the first time that
  mode is entered** (right before its setup/difficulty screen), gated by a persisted per-mode "seen"
  flag (`TutorialProgress`). A **Tutorials** drawer item lets players replay any tutorial anytime
  (Classic available; other modes shown as "coming soon" until built).

- **App shell — drawer, theme & localization.** Localization (tr/en/ru/es) via `flutter_localizations`
  + ARB (`AppLocalizations`), with a no-hardcoded-strings rule across the shell, entry, menus, setup,
  and game HUD (tutorial-ready). Light/dark theme system (`AppThemes` + `LuxTokens`) with a
  `ThemeController`; a `LocaleController`; both persisted via `SharedPreferences` and restored on
  launch. A left drawer (hamburger on the home screen) with **Settings** (language + theme),
  **About** (localized origin story), and **Issue** (5 FAQ placeholders + a `mailto:` contact via
  `url_launcher`). The entry screen keeps its fixed dark-luxury visuals but its text is localized;
  every other screen follows the theme. (Backend illegal-move reason strings remain English — a small
  noted follow-up.)

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
