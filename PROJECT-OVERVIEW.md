# Futuristic XOX — Comprehensive Project Overview & Handoff

> A self-contained briefing for picking the project up in a fresh context (another chat, a new
> contributor, or future-you). It covers what the project is, how it was built, the full rule set, and
> **deep detail on every algorithm**. Repo: <https://github.com/DenizTanisman/futuristic-xox> (public,
> MIT). Code/docs are in English; the project owner (Deniz) converses in Turkish.

---

## 0. TL;DR

Futuristic XOX is an **enhanced tic-tac-toe** for mobile (Android + iOS), offline. Pawns carry numeric
values and can **capture** weaker enemy pawns; classic X/O is preserved as its own mode. There are four
modes (Classic, Original, Bonanza, Morph), three AI difficulties driven by a **negamax + alpha-beta**
search, four UI languages (tr/en/ru/es), light/dark themes, interactive tutorials for every mode, a
continuous animated win-line, and a full recorded audio pass (SFX + two-layer music). It is **v1.0.0**,
public on GitHub with a downloadable Android APK. iOS code is ready but has no published build yet.

The design intent: **a luxury, polished, 60fps feel**; priorities in order are **correctness →
speed/responsiveness → smooth graphics**.

---

## 1. Origin & methodology

The project began from a single design document (`futuristic-xox-build-spec.md`, also copied to
`CLAUDE.md` so it auto-loads as context). That spec froze the rules, modes, algorithms, and UI, and
defined the build methodology (a lightweight **AI-DLC**: inception → construction → operations).

It was built as **three strictly separated units** against frozen contracts:

- **U1 — Engine (Rust)**: pure game logic (state, rules, capture, win-check for lines + Morph shapes,
  per-mode configs, a pure `apply`). No UI deps; unit-tested headless. Exposes a frozen `Mode` trait.
- **U2 — AI (Rust)**: easy/medium/hard; negamax + alpha-beta + transposition table + iterative
  deepening + heuristics. Consumes only the `Mode` trait; exposes `choose_move`.
- **U3 — UI (Flutter)**: screens, board, pawn rails, animations, themes, i18n, tutorials, audio.

A **`bridge/`** crate (flutter_rust_bridge facade) was written to connect Rust to Flutter. **Important
nuance:** the live mobile app currently runs on a **pure-Dart parity backend** (`DartGameApi`) that
re-implements the exact same rules and a negamax AI in Dart. The native Rust path
(flutter_rust_bridge + ffi) is scaffolded but **not yet wired into the running app** — it's the next
integration step. So when reading "the engine", remember there are two parity implementations: Rust
(`engine/`, `ai/`, tested headless) and Dart (`ui/lib/src/game/`, what ships today).

Development discipline: one feature per branch, tested before merge, English commits, `CHANGELOG.md`
(Keep a Changelog) updated each step, design artifacts under `aidlc-docs/`.

---

## 2. Tech stack & repo layout

- **Flutter/Dart** for all UI and the live game backend. Packages: `google_fonts` (Cinzel display +
  Rajdhani UI; Noto Sans fallback for Cyrillic), `shared_preferences` (persisted settings),
  `url_launcher` (mailto), `audioplayers` (SFX + music), `flutter_localizations` + ARB (i18n).
- **Rust** (workspace) for the headless engine + AI + bridge (zero third-party crates, no `unsafe`).

```
/                         repo root
  CLAUDE.md               the frozen build spec (single source of truth)
  README.md               portfolio README
  CHANGELOG.md            Keep a Changelog
  LICENSE                 MIT (© 2026 İsmail Deniz Tanışman)
  PROJECT-OVERVIEW.md     this file
  engine/                 Rust: state, rules, win-check, modes, geometry
  ai/                     Rust: easy/medium/hard, negamax, TT, heuristics
  bridge/                 Rust: flutter_rust_bridge facade (GameSession)
  aidlc-docs/             plans, design artifacts, store metadata, security review
  ui/                     the Flutter app (ships today on the Dart backend)
    lib/
      main.dart           app entry, lifecycle audio suspend/resume
      l10n/               app_{tr,en,ru,es}.arb + generated AppLocalizations
      src/
        app/              AppPrefs + controllers (Locale/Theme/Tutorial)
        audio/            sfx_controller.dart, music_controller.dart
        controllers/      game_controller.dart (turn loop, seats)
        game/             game_api.dart, dart_game_api.dart (engine+AI), geometry.dart, player_controller.dart
        models/           game_models.dart (Snapshot, Move, Outcome, …)
        screens/          menu_screens.dart, game_screen.dart, shell.dart (drawer/settings)
        theme/            game_theme.dart (Futuristic/Classic), app_themes.dart (Material + LuxTokens)
        tutorial/         reusable tutorial engine + per-mode steps + boards
        widgets/          board_view.dart, pawn_widget.dart, pawn_rail.dart, win_line.dart, …
    assets/audio/         renamed ASCII audio assets (WAV)
    android/ ios/         platform projects (Android signing scaffolded)
  sounds/                 raw audio source drop (gitignored; non-ASCII names)
```

---

## 3. Game model & rules

### 3.1 Board & pawns

- Board = a flat array of length `rows*cols`; each cell holds a pawn or is empty.
- `Pawn = { owner: 0|1, value: u8 }`. Classic ignores `value`.
- Colors: **player A = bordeaux** vs **player B = dark luxury gold** (in-app the human seat 0 is gold,
  seat 1 / opponent is bordeaux). Each pawn shows its value on a metallic medallion.

### 3.2 Pawn counts per mode/grid

| Mode / Grid          | Cells | Pawns/player | Values         |
|----------------------|-------|--------------|----------------|
| Classic 3×3 / 4×4    | 9/16  | symbols      | none           |
| Original·Bonanza 3×3 | 9     | 6            | 1..6           |
| Original·Bonanza 4×4 | 16    | 11           | 1..11          |
| Morph 4×4            | 16    | 12           | 1..6, two each |
| Morph 5×5            | 25    | 22           | 1..11, two each |

### 3.3 Placement & capture (Futuristic modes)

1. Empty cell → always legal.
2. Enemy pawn on the cell → legal **only if** the placed value is **strictly greater**; this
   **captures** (the enemy pawn is deleted permanently, does **not** return to hand).
3. Equal value → illegal.
4. Own pawn → illegal.

Illegal move → inline error, no state change, turn does not pass. A placed pawn always leaves the hand.

### 3.4 Win & end (checked after every move, **winner before draw**)

- Line modes (Classic, Original, Bonanza, all grids): **3 in a row** (h/v/diagonal).
- Morph: complete a target **4-cell shape** (see §5).
- The game runs until **both hands are empty** (no passing). No winner → draw.

### 3.5 Modes

- **Classic**: symbols, no values, no capture. Win = 3 in a row.
- **Original**: classic flow + valued pawns + capture. Win = 3 in a row. Both hands visible.
- **Bonanza**: same rules as Original, but the **initial hands are randomized** (see §6). After the
  deal it is identical to Original — same engine and AI.
- **Morph**: capture rules as in Original; win = complete a randomly chosen 4-cell shape (I/L/Z, any
  rotation + mirror, axis or diagonal frame). **Two pawns per turn.** Win is checked **after each** of
  the two placements (you can win mid-turn). If no second move is possible, the player finishes with a
  single move and a message is shown.

---

## 4. State model (Dart, mirrors the Rust engine)

```dart
// models/game_models.dart
enum Outcome { inProgress, win0, win1, draw }

class Snapshot {
  final int rows, cols, turn, movesLeftInTurn;   // movesLeftInTurn: 1 normally, 2→1 in Morph
  final List<CellView> board;                    // length rows*cols
  final List<HandPawnView> hand0, hand1;         // remaining pawns per seat (color + value)
  final Outcome outcome;
  final int? bonanzaOwnCount;                    // Bonanza: how many of seat 0's pawns are its own colour
  final MorphShape? morphShape;                  // Morph: the chosen target shape
  final List<int> winningCells;                  // the winning group's cells (for the win-line overlay)
}
```

`apply` is **pure**: it returns a new state, never mutating the input (this design eliminates the
classic "forgot to undo the move during search" bug). For Morph, `apply` decrements
`movesLeftInTurn` and only flips `turn` when it reaches 0.

The UI talks to a swappable `GameApi` interface (`newGame`, `humanMove`, `aiMove`, `legalCells`,
`snapshot`, …). `DartGameApi` is the live implementation; a future `RustGameApi` will sit behind the
same interface via the bridge.

---

## 5. Algorithm: win geometry

### 5.1 Line triples (Classic / Original / Bonanza)

All length-3 winning segments are generated once for a grid (`geometry.dart → lineTriples`):

```
for each cell (r,c):
  for each direction d in [ (0,1) right, (1,0) down, (1,1) down-right, (1,-1) down-left ]:
    if (r+2*dr, c+2*dc) is in bounds:
      emit [ idx(r,c), idx(r+dr,c+dc), idx(r+2dr,c+2dc) ]
```

A win check tests whether any triple has all three cells owned by the same player. (3×3 → 8 triples;
4×4 → 24.)

### 5.2 Morph shapes — the hard part (axis **and** diagonal frames)

Three base tetromino shapes, each 4 cells, defined **once** as relative `(row, col)` cells (never
hand-listing every placement):

```
I = (0,0)(0,1)(0,2)(0,3)
L = (0,0)(1,0)(2,0)(2,1)
Z = (0,1)(0,2)(1,0)(1,1)
```

From each base, the engine derives **all orientations** = 4 rotations × mirror, de-duplicated:

- `rotate((r,c)) = (c, -r)` — 90°.
- `mirror((r,c)) = (r, -c)`.
- `normalize` — shift so min row/col = 0, then sort cells (canonical form for de-dup).

Then comes the key generalization that lets Morph recognize **diagonal/staircase** shapes (not just
axis-aligned ones). Each orientation is laid onto the grid under **two placement bases** — a *basis*
maps the shape's own (row, col) axes to grid steps:

- **Axis basis** — shape-row → grid `(+1, 0)`, shape-col → grid `(0, +1)`. The classic placement.
- **Diagonal basis** — shape-row → grid `(+1, -1)`, shape-col → grid `(+1, +1)`. A 45°-rotated frame
  that yields staircase/diagonal placements (e.g. the diagonal I `0,5,10,15`), which the axis frame
  can **never** produce (a 90° rotation only swaps row/col, staying axis-aligned).

For each (orientation × basis):

1. Map every shape cell into grid space: `gridCell = r*rowStep + c*colStep`.
2. **Normalize** (shift min row/col to 0). *This step is critical:* the diagonal basis produces
   negative coordinates for top-left placements; without the shift those placements would require a
   negative anchor and be silently dropped — an asymmetry bug where top-left diagonals went missing
   while bottom-right ones worked. (This was a real bug found during play-testing and fixed here.)
3. Bounds-check the bounding box against `rows×cols`.
4. Slide the normalized shape over **every valid anchor** `(offR, offC)`, emit the 4 absolute cells
   (sorted), de-duplicated across all orientations/bases/anchors.

The result is the full set of concrete 4-cell placements for one shape. At game start Morph picks one
shape (I/L/Z) at random; the win test is "do any of that shape's placements have all 4 cells owned by
one player". Regression fixtures that must pass for I on 4×4: axis `[0,1,2,3]` & `[0,4,8,12]`, and
diagonal `[0,5,10,15]` & `[3,6,9,12]`.

Code: `ui/lib/src/game/geometry.dart` (`morphPlacementsForShape`), mirrors `engine/src/geometry.rs`.

---

## 6. Algorithm: Bonanza deal

Two typed pools, one per colour: `pool0` = own-colour values `1..N`, `pool1` = opponent-colour values
`1..N` (N = pawnsPerPlayer). The deal is a **structured, deterministic procedure** (not a free shuffle):

```
k = random in 0..=N                       // how many own-colour pawns seat 0 holds (k=0 is valid)
shuffle pool0; shuffle pool1
seat0 own  = pool0.take(k)        ; seat1 own  = pool0.skip(k)      // remainder to the opponent
seat0 opp  = pool1.take(N-k)      ; seat1 opp  = pool1.skip(N-k)
sort EACH of the four groups ASCENDING (within its colour)
hand0 = [seat0 own ascending] ++ [seat0 opp ascending]             // colour-0 group, then colour-1
hand1 = [seat1 own ascending] ++ [seat1 opp ascending]
```

**Invariant (stressed by Deniz):** sort **within each colour group only**, never across the whole hand
— Bonanza has two tile types, and a single mixed sort would interleave them, which is wrong. Integrity:
`seat0own ∪ seat1own == pool0` and `seat0opp ∪ seat1opp == pool1` (every tile dealt exactly once).
After the deal Bonanza plays identically to Original. `bonanzaOwnCount = k` is shown briefly at start.

Code: `ui/lib/src/game/dart_game_api.dart → _bonanzaHands`. Tested over many seeds for per-colour
sorting + exact pool partition.

---

## 7. Algorithm: the AI

### 7.1 Difficulty dispatch

- **Easy** — random legal move.
- **Medium** — per turn, a coin flip: half the time play Easy, half the time play Hard.
- **Hard** — iterative-deepening **negamax with alpha-beta** and a time box.

### 7.2 Negamax + alpha-beta (with the Morph twist)

Negamax is the single-function form of minimax: each node maximizes its own score and negates the
child's score when the turn flips. Alpha-beta pruning cuts branches that can't affect the result
(effective branching factor → ≈√b with good move ordering).

```
fn negamax(s, depth, alpha, beta) -> int:
    if winner(s):  return (winner == sideToMove) ? (WIN - depth) : (depth - WIN)
    if no legal move:  return 0                       // draw
    if depth == 0 or time exceeded:  return heuristic(s)
    best = -INF
    for m in ordered(legal_moves(s)):
        child = apply(s, m)                            // pure copy
        samePlayer = (child.turn == s.turn)            // Morph: a non-final move keeps the same side
        score = samePlayer ? negamax(child, depth-1, alpha, beta)
                           : -negamax(child, depth-1, -beta, -alpha)
        best = max(best, score)
        alpha = max(alpha, best)
        if alpha >= beta: break                        // cutoff
    return best
```

**The Morph subtlety:** because a turn is two placements, the *first* placement does **not** flip the
side to move. So the recursion must **not negate** when `child.turn == s.turn` (still maximizing for the
same side); it negates only on a real turn flip. This is the single most error-prone part of the search
and is handled both at the root and inside the recursion.

**Terminal scoring** encodes "win sooner, lose later": win → `WIN - depth`, loss → `depth - WIN`,
draw → `0`. (`WIN = 1000`, `INF = i32::MAX`.)

### 7.3 Iterative deepening + time box

Rather than a fixed depth, Hard searches depth 1, 2, 3 … until a **time budget** (~450 ms) expires,
keeping the best move from the last completed depth. Benefits: it adapts to position and device, it
returns a usable move even if interrupted, and the previous depth's best move feeds the next depth's
ordering (better pruning). Max depth caps: Morph 5, 3×3 line 9 (full solve), 4×4 line 7. It also stops
early once a forced win/loss is proven (`|bestScore| >= WIN - maxDepth`).

The native Rust AI additionally uses a **Zobrist-hashed transposition table** (cache positions reached
by different move orders) and **bitboards** (occupancy/owner as bit masks; win-check = one AND per
line/shape). The Dart parity AI keeps the same shape minus the TT/bitboard micro-optimizations.

### 7.4 Move ordering (makes alpha-beta effective)

`ordered(moves)` sorts:

1. **Captures first**, by victim value (MVV — most valuable victim first).
2. Then **cheaper attacker first** (LVA — least valuable attacker), i.e. ascending placed value.
3. Then **closer to center** first.

Good ordering is what turns alpha-beta from "a bit faster" into "√b branching".

### 7.5 Heuristics (static evaluation at the depth limit, scored "me − opponent")

- **Line modes:** `30*threats + 1*economy + 5*centerControl`, where
  - **threats** = lines with two of mine + a third cell I can still take (empty, or capturable with a
    pawn I hold),
  - **economy** = sum of my hand values − opponent's (big pawns = capture power left),
  - **centerControl** = center cells I own − opponent's.
- **Morph:** `40*shapeProgress + economy + 3*centerControl`, where **shapeProgress** is the best
  completion ratio across all of the chosen shape's placements (how close any placement is to being
  fully mine), me minus opponent.

Code: `dart_game_api.dart → _chooseMove / _negamax / _ordered / _heuristic`, mirroring `ai/src/hard.rs`.

---

## 8. Algorithm: the continuous win-line

When a game is won, the board draws **one continuous, unbroken stroke** through the winning cells in
path order — straight for a 3-in-a-row or Morph I, a single bend for L, a zigzag for Z, including
diagonal/mirrored shapes. Two parts:

### 8.1 Path ordering (`orderWinPath`, `widgets/win_line.dart`)

The engine returns the winning cells as an **unordered set**. To draw them as one stroke, consecutive
cells must be adjacent. The key insight: a shape connects by **exactly one step type** — an axis-frame
I/L/Z (and h/v lines) is a polyomino connected by **orthogonal** steps only; a diagonal-frame shape
(and diagonal lines) is a staircase connected by **diagonal** steps only. So:

1. Try to walk the cells into a single simple path using **orthogonal-only** adjacency.
2. If that fails (no single path), try **diagonal-only** adjacency.
3. Fall back to permissive king-move adjacency.

A "walk" builds an adjacency map, rejects any node with >2 neighbours or a dead end (not a simple
path), starts from a degree-1 endpoint, and chains to the end. Trying orthogonal first prevents a
diagonal "shortcut" from cutting across an axis-aligned L (e.g. drawing `10→13` instead of
`10→14→13`) — a real bug that this two-pass approach fixes.

### 8.2 Rendering (`WinLinePainter`)

A single `Path` through the ordered cell centers, stroked with round caps/joins (so bends read
smoothly) plus a blurred glow under-stroke. It is revealed **progressively** start→end via
`PathMetric.extractPath(0, totalLength * t)` over ~0.9 s (the Flutter analogue of CSS
`stroke-dashoffset`). Cell centers are computed from the live board metrics (padding + gap), so the
overlay aligns exactly at both board sizes. **Color is by the winner's side**: gold (you) / bordeaux
(opponent) in Futuristic, silver (X) / gold (O) in Classic. Lose/draw show no line, and the win sound
fires with it.

---

## 9. UI / UX systems

### 9.1 Theme & the metallic medallion

Two identities via a `GameTheme` (InheritedWidget `GameThemeProvider` + `GameTheme.of`): **Futuristic**
(warm gold/bordeaux) and **Classic** (cold silver). `PawnWidget` renders a metallic **medallion**: a
same-hue sweep-gradient ring around a radial-gradient disc, with the value drawn as a dark-stroke pass
under a gradient-fill pass for crisp legibility — numbers are always the *opposite* brightness of the
disc (dark number on gold, bright number on bordeaux). Selection = a glow halo only (no lift). A
separate Material light/dark theme (`AppThemes` + a `LuxTokens` extension) recolors the chrome; the
entry screen keeps a fixed dark-luxury palette regardless.

### 9.2 Internationalization

Four languages (tr/en/ru/es) via `flutter_localizations` + ARB files generating `AppLocalizations`.
**Brand-name invariant:** the mode names **"Classic"** and **"Futuristic"** never translate (fixed in
every locale); only descriptive text localizes. Turkish-aware upper-casing is used for headers so the
dotted **İ** renders (Dart's default `toUpperCase` and the Cinzel small-caps glyph both drop the dot →
"EĞİTİMLER", not "EĞITIMLER"). Cyrillic falls back to Noto Sans so Russian doesn't render heavy. The
Turkish win banner uses 2nd-person grammar ("Sen kazandın!") when the human wins.

### 9.3 Tutorials

A reusable tutorial engine (`tutorial/`): a `TutorialController` (step index / next / restart) drives
a `TutorialScreen` with progress dots + an always-on Skip, an animated body per step, and a footer
button. Step kinds: `info`, `loop` (a gif-style showcase that loops every 2 s), `triple` (Classic
win-rule mini-boards), `demo` (tap interaction), and `deal` (Bonanza's reveal). There are four
walkthroughs (Classic, Original, Bonanza, Morph) sharing the engine; each auto-shows the first time its
mode is entered (gated by a persisted per-mode "seen" flag) and is replayable from a **Tutorials**
drawer item. Demos use select-then-place with value-agnostic shape completion for Morph, a forced-loss
demo for Bonanza, etc. Step transitions use a **fade-through** (old fully out before new in) so
medallions never overlap mid-transition. All timers are cancelled on step change/dispose.

### 9.4 Hand rail layout

The shared pawn rail lays tiles in a **single clean row**, shrinking them to fit the rail width (with a
horizontal-scroll fallback for very large hands) instead of wrapping/overlapping onto a second row;
numbers stay readable across all modes.

### 9.5 Audio (two layers + a music state machine)

- **`SfxController`** — pooled one-shots, one preloaded `AudioPlayer` per `SoundId`
  (`menuForward, menuBack, menuTap, place, select, matchStart, win, lose, draw`), ~60 ms same-id
  throttle, distinct sounds overlap, results are exclusive. `select` is Futuristic-only; `place` fires
  for the player **and** the AI (and in tutorials).
- **`MusicController`** — two gapless WAV loops (`ReleaseMode.loop`) driving a state machine:
  **lobby_music** loops across all menus (never restarted on navigation) → on match start it fades out
  while a quiet **match_ambient** loop fills the silence under the SFX → on match end the ambient stops
  and the exclusive win/lose/draw SFX plays → after the result the lobby loop resumes. Linear
  cross-fades between transitions.
- **Settings** has **independent** SFX and Music toggles + volumes, persisted.
- **App lifecycle:** a `WidgetsBindingObserver` **suspends both audio layers when the app is
  backgrounded / screen off** (paused/hidden/detached) and resumes the current scene's loop on resume
  (transient `inactive` ignored to avoid app-switcher stutter). Audio respects the iOS silent switch
  (ambient audio context).
- Source files were recorded by Deniz with Turkish/spaced names under `sounds/`; they are imported into
  `assets/audio/` under **ASCII names** (the originals would break Flutter asset paths). `sounds/` is
  gitignored.

---

## 10. Build history (chronological)

1. Scaffold (workspace, CHANGELOG, README, aidlc-docs).
2. **U1 Engine** (Rust) + headless tests for every rule, incl. Morph diagonal regression fixtures.
3. Freeze the `Mode` trait; bridge skeleton.
4. **U2 AI** (difficulties, negamax + alpha-beta + TT + iterative deepening, self-play calibration) and
   **U3 UI** (screens, board, rails, animations) in parallel, on a Dart mock backend.
5. Play-testing fixes: diagonal/staircase win detection (the basis-vector generalization + normalize
   fix), capture correctness.
6. Feature waves (each its own branch): offline pass-and-play multiplayer; UI themes + metallic
   medallion; entry screen; app icon; app shell (drawer, light/dark theme, i18n tr/en/ru/es);
   interactive tutorials for Classic → Original → Bonanza → Morph; sound system; continuous win-line.
7. Polish: Turkish casing (İ), Turkish win-grammar, Cyrillic font fallback, win-line winner color,
   hand-rail selection glow (no lift), fade-through tutorial transitions, brand-name invariants.
8. **Release engineering**: MIT LICENSE, portfolio README, Android release-signing scaffolding
   (gitignored `key.properties` + template, debug-key fallback), store metadata.
9. **Full audio wiring**: imported recorded WAVs, split menu sounds, matchStart cue, two-layer audio +
   music state machine, lifecycle suspend/resume.
10. **v1.0.0 cut & publish**: merged everything to `main`, tagged `v1.0.0`, created the public GitHub
    repo, and attached a downloadable Android APK to the release.
11. Post-release fixes (current): background-audio pause; Bonanza per-colour sorted deal; hand-rail
    single-row no-overlap layout.

---

## 11. Current state, testing, release

- **Quality:** Rust side — 61 engine/AI/bridge tests, `cargo clippy` clean, Hard scores 95–100% vs
  Easy/Medium in self-play and never loses. Flutter side — 44 widget/logic tests passing, `flutter
  analyze` clean. (The Rust and Dart rule implementations are kept in parity.)
- **On device:** builds and runs as a release APK on Android (tested on a Samsung Galaxy S24 Ultra,
  Android 16). The app is **permanent on Android** (APK install persists; no computer/Mac needed).
- **Release:** public repo with `v1.0.0` and a downloadable `FuturisticXOX-v1.0.0.apk` (~92 MB,
  debug-signed for direct sideload). MIT licensed.

---

## 12. Known limitations & next steps

- **Native Rust not wired into the app yet** — the app ships on the Dart parity backend. Wiring
  flutter_rust_bridge (so the heavy search runs in Rust off the UI isolate) is the main integration
  step. Both implementations are kept in rule parity in the meantime.
- **iOS** — code is cross-platform and ready, but there is **no published iOS build**. iOS can't
  sideload an arbitrary `.ipa`; putting it on an iPhone needs a Mac + Xcode (free signing = 7-day
  expiry) or the **Apple Developer Program ($99/yr)** → TestFlight / App Store. No iOS download link
  exists yet.
- **APK size** — `lobby_music.wav` is ~34 MB, pushing the APK to ~92 MB. Re-encoding the two music
  loops to OGG (verifying gapless looping) would cut this to ~60 MB.
- **Offline fonts** — `google_fonts` may fetch display fonts from the network on first launch; bundling
  Cinzel/Rajdhani/Noto Sans as assets would make the app genuinely offline on first run.
- **Android upload keystore / Google Play** — signing config is scaffolded (`key.properties` template);
  creating the real keystore and a Play release is a pending owner-gated step.

---

## 13. Glossary of key files (Dart, what ships)

- `game/dart_game_api.dart` — the live engine + AI (rules, capture, win-check, Bonanza deal, negamax).
- `game/geometry.dart` — line triples + Morph shape placement generation (axis + diagonal bases).
- `models/game_models.dart` — Snapshot/Move/Outcome/CellView/HandPawnView, `winningCells`.
- `controllers/game_controller.dart` — turn loop, seats (human/AI), messages, result + audio triggers.
- `widgets/board_view.dart` — themed board + the win-line overlay trigger.
- `widgets/win_line.dart` — `orderWinPath` + `WinLinePainter` (progressive polyline).
- `widgets/pawn_widget.dart` — metallic medallion; `widgets/pawn_rail.dart` — shrink-to-fit hand rail.
- `audio/sfx_controller.dart`, `audio/music_controller.dart` — the two audio layers + state machine.
- `tutorial/` — reusable tutorial engine + per-mode steps + tutorial boards.
- `screens/menu_screens.dart` (entry/setup), `screens/game_screen.dart`, `screens/shell.dart`
  (drawer/settings).
- `l10n/app_{tr,en,ru,es}.arb` — translations.

> For the authoritative frozen design and the exact numbers/weights, see `CLAUDE.md` (the build spec).
