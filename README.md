# Futuristic XOX

An enhanced tic-tac-toe where pawns carry numeric values and can capture each other.
Classic X/O play is preserved as a separate mode. Mobile-first (Android + iOS), offline v1,
with an online-ready server-authoritative engine for v2.

> Priorities, in order: **correctness → speed/responsiveness → smooth 60fps graphics**.

## Architecture

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

- **`engine/`** — pure Rust crate: state model, rules, capture, win-check (lines + Morph shapes),
  per-mode configs, pure `apply`. No UI dependencies; unit-tested headless. (Unit 1)
- **`ai/`** — Rust crate: easy / medium / hard, negamax + alpha-beta, transposition table,
  iterative deepening, heuristics. Consumes only the engine's `Mode` trait. (Unit 2)
- **`ui/`** — Flutter app: screens, board, pawn rail + animations. (Unit 3)
- **`bridge/`** — `flutter_rust_bridge` glue (async, so AI search runs off the UI isolate).

## Modes

| Mode      | Grids      | Pawns                | Win condition          |
|-----------|------------|----------------------|------------------------|
| Classic   | 3×3, 4×4   | symbols, no values   | 3 in a row             |
| Original  | 3×3, 4×4   | valued + capture     | 3 in a row             |
| Bonanza   | 3×3, 4×4   | randomized hands     | 3 in a row             |
| Morph     | 4×4, 5×5   | two of each value    | complete a 4-cell shape |

See [`CLAUDE.md`](CLAUDE.md) (the build spec) for the full design.

## Build

### Engine + AI (Rust)

```sh
cargo test            # run all headless engine + AI tests
cargo build --release # optimized native build
```

### UI (Flutter)

Requires the Flutter SDK. See `ui/README.md` (added during Unit 3).

## Project methodology

Built with AI-DLC: INCEPTION → CONSTRUCTION → OPERATIONS. Design and planning artifacts live
under [`aidlc-docs/`](aidlc-docs/). The changelog follows
[Keep a Changelog](https://keepachangelog.com/).

## License

MIT
