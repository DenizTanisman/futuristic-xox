# Futuristic XOX

An enhanced tic-tac-toe where pawns carry numeric values and can capture each other.
Classic X/O play is preserved as a separate mode. Mobile-first (Android + iOS), offline v1,
with an online-ready server-authoritative engine for v2.

> Priorities, in order: **correctness → speed/responsiveness → smooth 60fps graphics**.

## Download & play

**[▶ Download the latest Android APK](https://github.com/DenizTanisman/futuristic-xox/releases/latest)**
— open it on your phone, allow *Install from unknown sources* if asked, and it installs permanently
(no computer needed). Fully offline.

- **Android:** ready now (signed for direct sideload).
- **iOS:** the code is cross-platform and ready, but there is no published iOS build yet (an iOS build
  requires a Mac + the Apple Developer Program → TestFlight / App Store).

<!-- Screenshots: drop entry / Morph win-line / tutorial images into aidlc-docs/release/screenshots/ and link them here. -->

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

## Status

| Unit | What | State |
|------|------|-------|
| **U1 — Engine** (`engine/`) | rules, capture, win-check (lines + Morph shapes), modes, pure `apply` | ✅ complete, 41 tests |
| **U2 — AI** (`ai/`) | easy / medium / hard (negamax + alpha-beta + transposition table + iterative deepening) | ✅ complete, 14 tests + self-play |
| **Bridge** (`bridge/`) | `GameSession` facade, FFI-friendly views | ✅ complete, 6 tests |
| **U3 — UI** (`ui/`) | screens, board, rails, animations; 4-language i18n (tr/en/ru/es); dark/light themes; interactive tutorials for all four modes; recorded SFX + two-layer music; continuous win-line | ✅ complete, 44 widget/logic tests |
| **Integration** | on-device play (Android) + `flutter_rust_bridge` wiring | ✅ ships & runs on Android (on the Dart parity backend); ⏳ native-Rust wiring still to come |

> **Release:** **v1.0.1 is public** — Android APK on the [Releases page](https://github.com/DenizTanisman/futuristic-xox/releases/latest),
> MIT licensed. The app ships today on a pure-Dart parity backend that mirrors the Rust engine's rules
> and AI; wiring the native Rust path through `flutter_rust_bridge` is the next step. iOS build pending
> (needs a Mac + Apple Developer Program).

**Quality:** 61 Rust tests + 44 Flutter tests pass; `cargo clippy` and `flutter analyze` clean; the
AI's Hard difficulty scores 95–100% vs Easy/Medium in self-play and never loses. Engine/AI use
**zero** third-party crates and contain **no `unsafe`** (see
[`aidlc-docs/design-artifacts/security-review.md`](aidlc-docs/design-artifacts/security-review.md)).

## Build & test

### Engine + AI (Rust) — runs anywhere

```sh
cargo test --workspace            # all headless engine + AI + bridge tests
cargo run --release --example selfplay   # AI strength self-play report
cargo build --release             # optimized native build
```

### UI (Flutter) — requires the Flutter SDK (≥ 3.27)

```sh
cd ui
flutter pub get
flutter test                  # 44 widget/logic + rule-parity tests
flutter run                   # launch on a connected device/emulator
flutter build apk --release   # standalone APK → build/app/outputs/flutter-apk/app-release.apk
```

The released APK is signed with a debug key for direct sideloading; a Google Play build (real upload
keystore, scaffolded via `ui/android/key.properties`) is a later step. See
[`ui/README.md`](ui/README.md) for backend details and the native-Rust wiring steps, and
[`PROJECT-OVERVIEW.md`](PROJECT-OVERVIEW.md) for a full algorithm-level walkthrough.

## Project methodology

Built with AI-DLC: INCEPTION → CONSTRUCTION → OPERATIONS, with the three Units developed against
frozen merge contracts (the engine's `Mode` trait and the `GameApi`/`GameSession` boundary). Design
and planning artifacts (ADR, Morph shapes, Bonanza distribution, heuristic calibration, security
review) live under [`aidlc-docs/`](aidlc-docs/). The changelog follows
[Keep a Changelog](https://keepachangelog.com/).

## License

Released under the **MIT License** — see [`LICENSE`](LICENSE). SPDX-License-Identifier: `MIT`.
Copyright © 2026 İsmail Deniz Tanışman. Use, modify, and distribute freely with attribution; provided
"as is" without warranty.
