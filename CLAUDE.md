# Futuristic XOX — Build Specification & Claude Code Instructions

> **Single source of truth.** This document is both the complete design spec and the build brief for
> Claude Code. Build the project exactly per this spec, following the methodology and discipline in
> §10–§14. Conversation with the user is in **Turkish**; everything you produce (code, comments,
> MD/README/CHANGELOG, commit messages, file/folder names) is in **English**.
>
> You may rename this file to `CLAUDE.md` at the repo root so it is auto-loaded as context.

---

## 0. How Claude Code should use this document

- Treat §3–§9 as the frozen design (rules, modes, algorithms, UI). Treat §10–§14 as mandatory process.
- Work autonomously per §10.3. Stop only at a **🛑 TEST DURAĞI** (functional test the user must run),
  before an irreversible op, or on behavior-changing design ambiguity (take the most defensive
  option, log it, continue).
- Build the three Units (§11) with parallelism where the platform allows: once the Engine's public
  interface (§7.1) is frozen, the AI and UI Units progress concurrently against it. When any Unit
  reaches a 🛑 TEST DURAĞI, report it to the user and **keep progressing the other Units** — do not
  block all work on one test.
- After each phase/feature, drop a 6–10 line completion report, update `CHANGELOG.md`, then continue.

---

## 1. Intent & Scope

An enhanced tic-tac-toe where pawns carry numeric values and can capture each other; classic X/O play
is preserved as a separate mode.

- **Mobile-first: Android + iOS.** Web is optional and deferred (only if there is strong demand).
- **v1 = offline** (human vs. computer, or local play). **v2 = online**, deferred; the Rust engine is
  designed so it can later run server-authoritative without a rewrite.
- Priorities, in order: **correctness**, **speed/responsiveness**, **smooth 60fps graphics**.

---

## 2. Architecture & Tech Stack

Three strictly separated layers:

```
        UI Layer (Flutter)         AI Layer (Rust)
        screens, board,            easy / medium / hard
        animations, input              search engine
              \                          /
               \                        /
                v                      v
            +-----------------------------------+
            |        Game Engine (Rust)         |
            |   pure logic, platform-independent |
            |  State | Rules | WinCheck | Modes  |
            +-----------------------------------+
```

- **Flutter (Dart)** — all UI and graphics. Use Flutter's animation framework for smooth 60fps
  transitions (pawn placement, capture, rail slide, screen changes). Graphics quality is a priority:
  fluid and polished.
- **Rust** — the engine and the AI search core. Compiled native for mobile.
- **`flutter_rust_bridge`** binds them. The bridge must be **async**: the heavy search runs off
  Flutter's main isolate so the UI never freezes while the AI thinks. This is the key to fluidity.
- Engine is a pure Rust crate with **no UI dependencies** — unit-tested headless, reusable later for
  the v2 server and (if ever needed) a WASM web build.

Top-level workspace layout:

```
/                      repo root
  aidlc-docs/          plans, requirements, story-artifacts, design-artifacts
  engine/              Rust crate: state, rules, win-check, modes (Unit 1)
  ai/                  Rust crate/module: easy, medium, hard, optimizations (Unit 2)
  ui/                  Flutter app: screens, board, animations (Unit 3)
  bridge/              flutter_rust_bridge glue
  CHANGELOG.md
  README.md
```

---

## 3. Common Rules

### 3.1 Board & pawns
Board = flat array length `rows*cols`; each cell holds a pawn or is empty.
`Pawn = { owner: 0|1, value: u8 }`. Classic ignores `value`. Futuristic colors: **bordeaux** (player A)
vs **dark luxury gold** (player B); each pawn shows its value.

### 3.2 Pawn counts

| Mode / Grid          | Cells | Pawns/player | Values            |
|----------------------|-------|--------------|-------------------|
| Classic 3×3          | 9     | symbols      | none              |
| Classic 4×4          | 16    | symbols      | none              |
| Original·Bonanza 3×3 | 9     | 6            | 1..6              |
| Original·Bonanza 4×4 | 16    | 11           | 1..11             |
| Morph 4×4            | 16    | 12           | 1..6, two each    |
| Morph 5×5            | 25    | 22           | 1..11, two each   |

### 3.3 Placement & capture (Futuristic)
1. Empty cell → always legal.
2. Enemy pawn on cell → legal **only if** placed value **strictly greater**; this **captures** and the
   enemy pawn is **deleted permanently** (does not return to hand).
3. Equal value → illegal.
4. Own pawn on cell → illegal (wasted move).

Illegal move → small inline error message; no state change, turn does not pass. A placed pawn always
leaves the hand.

### 3.4 Win & end
Checked after every move, **winner before draw**:
- Win (line modes — Classic, Original, Bonanza, all grids): **3 in a row** (h / v / diagonal).
- Win (Morph): complete a target 4-cell shape (§5).
- End/draw: game runs until **both hands empty** (no passing); no winner → draw.

---

## 4. Modes

### 4.1 Classic (3×3, 4×4)
Symbols, no values, no capture. Win = 3 in a row.

### 4.2 Original (3×3, 4×4)
Classic flow + valued pawns + capture (§3.3). Both players see each other's remaining pawns.
Win = 3 in a row.

### 4.3 Bonanza (3×3, 4×4)
Same rules as Original, but **initial hands are randomized** at start:
1. Random `k` in `0..pawnsPerPlayer` (`k=0` valid — may own none of own color).
2. Type split: player A gets `k` own-color + `(pawnsPerPlayer-k)` opponent-color pawns; player B gets
   the complement. Each ends with `pawnsPerPlayer` pawns.
3. For each color, the full value set is split **randomly** between players; no balancing guarantee.

After distribution is fixed, play is deterministic perfect-information → **uses the exact same engine
and AI as Original** (different starting state only, not a separate algorithm).

### 4.4 Morph (4×4, 5×5)
Capture rules identical to Original. Win = complete a randomly chosen 4-cell shape (§5). Each player
holds two of every value (1..6 on 4×4, 1..11 on 5×5), own color only.

**Two moves per turn (Morph only).** Each turn the active player places **two pawns** (a single 4-cell
shape is nearly impossible to complete one move at a time). The other modes remain one move per turn.
- **Win check after EACH of the two moves.** If the shape completes on the first move, the player wins
  immediately and does not make the second move.
- **If no second move is possible** (no space/pawn left mid-turn): show a message and the player
  finishes the turn with a single move.
- *Deferred experimental ideas (NOT part of v1 rules):* variable moves-per-turn (e.g. 2 early then 1).
  Keep these out of the core rules; revisit during play-testing only.

---

## 5. Morph Shapes

Three base shapes, each **4 cells**: **I** (straight line), **L** (L-tetromino), **Z** (Z/S-tetromino).

**Algorithmic definition (do NOT hand-list coordinates):** define each shape once as relative cells in
a bounding box, e.g. `I = [(0,0),(0,1),(0,2),(0,3)]`, `L = [(0,0),(1,0),(2,0),(2,1)]`,
`Z = [(0,1),(0,2),(1,0),(1,1)]`. The engine derives all **4 rotations + mirror**, then scans the grid
with a **sliding window** over every valid placement. Same code runs on 4×4 and 5×5. Win check tests
whether any precomputed placement has all 4 cells owned by one player.

**Defensive defaults for open points (proceed with these; flag if a play-test contradicts):** include
the straight I in all 4 orientations; **exclude** the pure corner-to-corner diagonal "I" (it is a
diagonal line, not the I tetromino). Confirm exact L/Z relative cells against this section during the
Engine Unit and log the final chosen sets in `aidlc-docs/design-artifacts/`.

---

## 6. State Model (Rust)

```rust
struct Pawn { owner: u8, value: u8 }        // value unused in Classic

struct GameState {
    board: Vec<Option<Pawn>>,               // length rows*cols
    hands: [Vec<u8>; 2],                     // remaining pawn values per player
    turn: u8,                                // 0 or 1
    moves_left_in_turn: u8,                  // 1 normally; 2 for Morph (decrements to turn end)
    cols: usize,
    rows: usize,
}

enum Result { Win(u8), Draw }
struct Move { value: Option<u8>, cell: usize }
```

`apply(&state, mv) -> GameState` is **pure**: returns a new state, never mutates input (avoids the
"forgot to undo the move" search bug). For Morph it decrements `moves_left_in_turn` and only flips
`turn` when it reaches 0.

---

## 7. AI / Algorithms

### 7.1 Engine interface (frozen contract — Units 2 & 3 build against this)

```rust
trait Mode {
    fn legal_moves(&self, s: &GameState) -> Vec<Move>;
    fn ordered_moves(&self, s: &GameState) -> Vec<Move>;   // legal_moves, best-first (for pruning)
    fn apply(&self, s: &GameState, m: &Move) -> GameState;  // pure
    fn is_terminal(&self, s: &GameState) -> Option<Result>;
    fn terminal_score(&self, r: &Result, s: &GameState, depth: i32) -> i32;
    fn heuristic(&self, s: &GameState) -> i32;              // static estimate at depth limit
}
```

### 7.2 Easy
Random. Futuristic: roll odd → prefer empty cells, even → prefer occupied (capture attempt); fall back
to all legal moves if the preferred pool is empty. Fallback is recomputed **every turn** — no
permanent "can't place here" flag.

### 7.3 Medium
Per turn: roll odd → run `easy`, even → run `hard`. Decided fresh each turn.

### 7.4 Hard — negamax + alpha-beta

```rust
const INF: i32 = i32::MAX;  const WIN: i32 = 1000;

fn negamax(s: &GameState, depth: i32, mut alpha: i32, beta: i32, mode: &dyn Mode) -> i32 {
    if let Some(r) = mode.is_terminal(s) { return mode.terminal_score(&r, s, depth); }
    if depth == 0 { return mode.heuristic(s); }
    let mut best = -INF;
    for m in mode.ordered_moves(s) {
        let child = mode.apply(s, &m);
        // For Morph: if the move did NOT end the turn (same player still to move),
        // recurse WITHOUT negating (still maximizing for the same side); negate only on turn flip.
        let same_player = child.turn == s.turn;
        let score = if same_player {
            negamax(&child, depth - 1, alpha, beta, mode)
        } else {
            -negamax(&child, depth - 1, -beta, -alpha, mode)
        };
        if score > best { best = score; }
        if best > alpha { alpha = best; }
        if alpha >= beta { break; }   // cutoff
    }
    best
}
```

`terminal_score`: win → `WIN - depth` (win sooner), loss → `depth - WIN` (lose later), draw → 0.

### 7.5 Per-mode plug-ins
- **Classic** — `legal_moves` = empty cells; `is_terminal` = 3-in-a-row / board full. 3×3 searches to
  the bottom (perfect); 4×4 uses depth limit + threat count.
- **Original / Bonanza** (one shared impl) — `legal_moves` = empty + capturable enemy cells × each
  distinct hand value; `apply` removes the pawn from hand and deletes any captured enemy pawn;
  `is_terminal` = 3-in-a-row, or Draw when both hands empty.
- **Morph** — reuses Original's move/capture/apply; `is_terminal`/`heuristic` use shape completion;
  `apply` handles the two-moves-per-turn turn flip.

### 7.6 Heuristics (used at depth limit; scored "me minus opponent")
- **Line modes:** line threats (2 of mine + 1 empty/capturable in a line) · hand economy (sum of big
  pawns still in hand = capture power) · center control. Start weights `30*threats + 1*economy +
  5*center` — **calibrate via self-play** (open item §13).
- **Morph:** best shape-completion ratio across all rotations/mirrors for me, minus opponent, plus a
  small blocking term.

### 7.7 Optimizations (cut node count — the real speed)
1. **Alpha-beta pruning** (effective branching → √b with good ordering).
2. **Move ordering** — captures first (MVV-LVA), line/shape-completing moves, killer/history moves.
3. **Transposition table (Zobrist hashing)** — cache positions reached by different move orders.
4. **Iterative deepening + time box** — search depth 1,2,3… until the time budget expires; return best
   so far; previous depth feeds next depth's ordering.
5. **Symmetry reduction** — 8 symmetries on early boards (4 rotations × mirror).
6. **Bitboard** — occupancy + owner as bit masks; win-check = single AND per line/shape (hot path),
   values in a parallel array.
7. **Depth limit + heuristic** for big states.

### 7.8 Performance budget (NFR)
Search depth = remaining moves; **shrinks every turn**, so the first move is the hardest. Target per
move: 300–500 ms (ceiling 1 s). Conservative device estimate (Rust native on phone): tens of millions
of nodes/sec — comfortably faster than the JS baseline used for the table below.

| Mode / Grid          | Max depth | Opening branching                | Practical depth |
|----------------------|-----------|----------------------------------|-----------------|
| Classic 3×3          | 9         | 9                                | full solve      |
| Classic 4×4          | 16        | 16                               | ~full / 10–12   |
| Original·Bonanza 3×3 | 12        | ~54                              | ~7–8            |
| Original·Bonanza 4×4 | 22        | ~176                             | ~5–6            |
| Morph 4×4            | 24        | ~96 → **~b² per turn** (two moves) | ~5–6 (moves)  |
| Morph 5×5            | 44        | ~275 → **~b² per turn** (two moves)| ~4–5 (moves)  |

**Morph note:** two moves per turn squares the effective per-turn branching (~b²; 5×5 ≈ 75,000). This
is exactly why Rust matters here — alpha-beta + transposition + aggressive ordering + depth limit make
it tractable. Use the **iterative-deepening time box** rather than a fixed depth so the engine adapts
per position and per device.

---

## 8. UI Flow (Flutter)

1. **Entry** — full-screen split: **Classic** | **Futuristic**.
2. **Classic** → difficulty (easy/medium/hard) + grid (3×3/4×4) → game.
3. **Futuristic** → submode (Original / Bonanza / Morph):
   - Original / Bonanza → difficulty + grid (3×3/4×4).
   - Morph → difficulty + grid (**4×4/5×5**).
4. **Game screen:** board (bordeaux vs dark-gold pawns, value shown); per-player pawn rail (both
   visible) that **slides to close the gap** when a pawn is placed; turn indicator; illegal-move inline
   message; win/lose/draw banner. Morph: indicate "move 1 of 2 / 2 of 2" in the turn UI.

Animation priority: all transitions fluid at 60fps (placement, capture, rail slide). Run AI off the
main isolate so animations never stutter while the engine thinks.

---

## 9. Security
- **v1 (offline):** engine validates every move against bounds + legality (never trust a computed
  index); no `eval`; safe rendering only; no secrets; no remote calls.
- **v2 (online, forward):** server-authoritative engine (never trust client results); auth middleware +
  IDOR ownership checks on every endpoint; parameterized queries/ORM; rate limiting; CORS whitelist (no
  `*`); secrets via env vars; `debug=false` in prod; CI with semgrep + secret scan.

---

## 10. Development Methodology — Claude Code MUST follow

### 10.1 AI-DLC phases
INCEPTION (this doc) → CONSTRUCTION (domain design → logical design + ADR → code + tests → deployable
units) → OPERATIONS (v2). Persist artifacts under `aidlc-docs/`.

### 10.2 Parallel development
Engine / AI / UI are independent Units (§11) on separate branches with merge contracts defined up
front. `main` always holds the current working state. Run Units concurrently once the Engine interface
(§7.1) is frozen (UI works against a mock AI; AI works against the real engine).

### 10.3 Autonomous mode
Do all intermediate work without asking: branching, committing, merging, refactoring, writing/fixing
tests, adding packages, moving files, linting, mock data. Stop ONLY for:
- **(A) 🛑 TEST DURAĞI** — a functional test the user must run and observe.
- **(B)** an irreversible op (public GitHub push, production secret, first touch of another repo) —
  give a brief summary first.
- **(C)** behavior-changing design ambiguity — take the most defensive option, log it, continue.

When a Unit hits a 🛑 TEST DURAĞI, notify the user with what to test, then **continue progressing other
Units** while waiting. After each phase/feature: a 6–10 line completion report, then continue.

### 10.4 Feature discipline
One feature at a time, in its own branch/module; tested + approved before merge to `main`; do not start
the next feature before the current is complete.

### 10.5 Git, CHANGELOG, README
Local git during development (do not suggest GitHub push until completion). At completion, suggest
GitHub push (repo + remote + push). `CHANGELOG.md` in Keep-a-Changelog format (Unreleased + version
headers; Added/Changed/Fixed/Removed), updated at every phase/feature. Portfolio-quality `README.md`.

### 10.6 Language
Code, comments, MD/README/CHANGELOG, file/folder names, commit messages → **English**. Conversation
with the user → **Turkish**.

### 10.7 Security inline
Threat model at project start; per-feature security review; inline secure-pattern feedback while
coding; OWASP checklist at project end.

---

## 11. Unit Decomposition & Merge Contracts

| Unit | Scope | Merge contract |
|------|-------|----------------|
| **U1 — Engine (Rust)** | state model, rules, capture, win-check (lines + shapes), mode configs, pure `apply`, two-moves-per-turn for Morph | Exposes the frozen `Mode` trait (§7.1); fully unit-tested headless. **Build first** — unblocks U2 and U3. |
| **U2 — AI (Rust)** | easy / medium / hard, negamax + alpha-beta, optimizations (§7.7), iterative deepening, heuristics | Consumes only the `Mode` trait; exposes `choose_move(state, difficulty, time_budget) -> Move`. |
| **U3 — UI (Flutter)** | screens, board, pawn rail + slide animation, capture message, turn/Morph indicators, banners | Consumes engine `apply`/`legal_moves`/result via the bridge + `choose_move` from U2; can start against a mock AI. |

Build order: **U1 → freeze interface → U2 & U3 in parallel.** Bridge (`flutter_rust_bridge`) wiring is
its own small integration step after U1's interface is stable.

---

## 12. Folder Structure
See §2. Persist AI-DLC artifacts under `aidlc-docs/{plans,requirements,story-artifacts,design-artifacts}`.

---

## 13. Open Items (defensive defaults — proceed, flag on contradiction)
1. **Morph exact shape cells** — use the relative-cell sets in §5 (include straight I, exclude diagonal
   I); confirm and log final sets during U1.
2. **Heuristic weights** — start values in §7.6 are placeholders; calibrate via self-play during U2.
3. **5×5 Morph latency ceiling** — default to a 500 ms time box; if play-testing feels too weak there,
   raise to 1 s before considering further native optimization. Log the decision.

---

## 14. Build Order & Test Stops
1. Scaffold repo, workspace, `CHANGELOG.md`, `README.md`, `aidlc-docs/`.
2. **U1 Engine** — implement + headless unit tests for every rule (capture strict-greater, capture
   deletes pawn, win-before-draw, hands-empty draw, Morph shapes + rotations/mirrors, Morph two-moves
   + win-after-each + single-move fallback). Completion report.
3. Freeze `Mode` trait. Bridge skeleton.
4. **U2 AI** + **U3 UI** in parallel. U2: difficulties + optimizations + self-play weight calibration.
   U3: screens + board + animations against a mock AI, then wire to U2.
5. Integration: full game playable per mode. **🛑 TEST DURAĞI** — user plays each mode on device and
   confirms feel/fluidity (especially 5×5 Morph responsiveness and animation smoothness).
6. Polish, OWASP checklist, portfolio README. At completion, suggest GitHub push.
