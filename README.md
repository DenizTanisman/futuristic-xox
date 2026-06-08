# Futuristic XOX

### Tic-tac-toe, reinvented. Your pawns have **numbers** — and the bigger one **eats** the smaller.

A luxury-styled strategy game that takes the three-symbol classic you know and turns it into a duel of
capture, bluff, and shape-building — then keeps pure Classic X/O in the box for when you just want the
original. Mobile-first (Android now, iOS-ready), **fully offline**, buttery **60 fps**.

> Priorities, in order: **correctness → speed/responsiveness → smooth 60fps graphics**.

**[▶ Download the latest Android APK](https://github.com/DenizTanisman/futuristic-xox/releases/latest)**
— open it on your phone, allow *Install from unknown sources* if asked, and play instantly. No account,
no internet, no nonsense.

<!-- Screenshots: drop entry / Morph win-line / tutorial images into aidlc-docs/release/screenshots/ and link them here. -->

---

## Why you'll keep tapping

- 🎯 **Four ways to play.** Pure **Classic**, capture-driven **Original**, chaos-dealt **Bonanza**, and
  shape-hunting **Morph** — each with its own board sizes, hand, and win condition.
- ♟️ **Pawns that fight.** Every futuristic pawn carries a value. Land a bigger number on a smaller one
  and it's **captured for good** — equal values bounce, your own pieces block. Every placement is a
  threat *and* a target.
- 🧠 **An AI that's actually hard.** A real negamax + alpha-beta search (transposition table, iterative
  deepening) ranks its **top-3 moves** every turn. Pick your challenge: **Easy · Medium · Hard ·
  Impossible** on the futuristic side, **Easy · Medium · Hard** on Classic. *Impossible never blunders.*
- 👥 **Pass-and-play.** Flip Multiplayer on and hand the phone back and forth — two humans, one device,
  no AI.
- 🎓 **Learn by doing.** Built-in interactive tutorials for **all four modes**, fully localized in
  **English, Türkçe, Русский, Español**, with dark/light themes, recorded SFX and a two-layer score.

---

## The four modes

| Mode | Grids | Pawns & turn | How you win |
|------|-------|--------------|-------------|
| **Classic**  | 3×3 · 4×4 **short** · 4×4 **long** | symbols, one per turn | **3-in-a-row** (short) — or **4-in-a-row** on the 4×4 **long** board |
| **Original** | 3×3 · 4×4 | valued pawns + capture, one per turn | **3-in-a-row** |
| **Bonanza**  | 3×3 · 4×4 | Original, but **hands are randomly dealt** | **3-in-a-row** |
| **Morph**    | 4×4 · 5×5 | two of every value; **single alternating placement** | complete a hidden **4-cell shape** (I / L / Z, any rotation, mirror, or diagonal) |

**Capture rule (futuristic modes):** an empty cell is always legal; landing on an enemy pawn is legal
only with a **strictly greater** value and removes it permanently; equal or your-own is illegal. Play
runs until both hands are empty — **winner before draw**.

See [`CLAUDE.md`](CLAUDE.md) (the build spec) for the complete, frozen design.

---

## Under the hood

Three strictly separated layers — a clean split between *how it looks* and *how it thinks*:

```
        UI Layer (Flutter)            AI Layer (Rust)
        screens, board,            adversarial top-3 search
        animations, input         (negamax + α-β + TT + ID)
              \                          /
               \                        /
                v                      v
            +-----------------------------------+
            |        Game Engine (Rust)         |
            |  pure logic, platform-independent  |
            |  State | Rules | WinCheck | Modes  |
            +-----------------------------------+
```

- **`engine/`** — pure Rust crate: state model, rules, capture, configurable win length (3/4),
  win-check (lines + Morph shapes), per-mode configs, pure `apply`. No UI deps; tested headless.
- **`ai/`** — Rust crate: the adversarial search returning the top-3 ranked moves, the per-side
  difficulty tiers + a stateless per-turn selector. Consumes only the engine's `Mode` trait.
- **`ui/`** — Flutter app: screens, board, pawn rails + animations, tutorials, i18n, audio.
- **`bridge/`** — `flutter_rust_bridge` glue (async, so AI search runs off the UI isolate).

> **Why two languages?** Flutter gives one fluid, cross-platform UI; Rust gives native-speed,
> memory-safe search for the deep game tree. The app ships today on a pure-Dart **parity backend** that
> mirrors the Rust engine + AI, so it runs everywhere without a native toolchain — wiring the native
> Rust path through `flutter_rust_bridge` is the next step.

---

## Status & quality

| Area | What | State |
|------|------|-------|
| **Engine** (`engine/`) | rules, capture, configurable win length, win-check (lines + Morph shapes), modes, pure `apply` | ✅ complete |
| **AI** (`ai/`) | adversarial top-3 search (negamax + alpha-beta + transposition table + iterative deepening); per-side difficulty tiers | ✅ complete |
| **Bridge** (`bridge/`) | `GameSession` facade, FFI-friendly views | ✅ complete |
| **UI** (`ui/`) | screens, board, rails, animations; 4-language i18n (tr/en/ru/es); themes; tutorials for all modes; SFX + music; local multiplayer | ✅ complete |
| **Integration** | on-device play (Android) + `flutter_rust_bridge` wiring | ✅ ships & runs on Android (Dart parity backend); ⏳ native-Rust wiring to come |

**Quality:** **76 Rust tests + 67 Flutter tests** pass; `cargo clippy` and `flutter analyze` clean;
Hard/Impossible play scores **95–100% vs Easy/Medium** in self-play and never loses. Engine + AI use
**zero** third-party crates and contain **no `unsafe`** (see
[`aidlc-docs/design-artifacts/security-review.md`](aidlc-docs/design-artifacts/security-review.md)).

- **Android:** ready now (signed for direct sideload), MIT licensed.
- **iOS:** the code is cross-platform and ready — an iOS build just needs a Mac + the Apple Developer
  Program (TestFlight / App Store).

---

## Build & test

### Engine + AI (Rust) — runs anywhere

```sh
cargo test --workspace                   # all headless engine + AI + bridge tests
cargo run --release --example selfplay   # AI strength self-play report
cargo build --release                    # optimized native build
```

### UI (Flutter) — requires the Flutter SDK (≥ 3.27)

```sh
cd ui
flutter pub get
flutter test                  # widget/logic + rule-parity tests
flutter run                   # launch on a connected device/emulator
flutter build apk --release   # standalone APK → build/app/outputs/flutter-apk/app-release.apk
```

The released APK is signed with a debug key for direct sideloading; a Google Play build (real upload
keystore, scaffolded via `ui/android/key.properties`) is a later step. See
[`ui/README.md`](ui/README.md) for backend details and the native-Rust wiring steps, and
[`PROJECT-OVERVIEW.md`](PROJECT-OVERVIEW.md) for a full algorithm-level walkthrough.

---

## Project methodology

Built with AI-DLC: INCEPTION → CONSTRUCTION → OPERATIONS, with the three Units developed against frozen
merge contracts (the engine's `Mode` trait and the `GameApi`/`GameSession` boundary). Design and
planning artifacts (ADRs, Morph shapes, Bonanza distribution, heuristic calibration, security review)
live under [`aidlc-docs/`](aidlc-docs/). The changelog follows
[Keep a Changelog](https://keepachangelog.com/).

## License

Released under the **MIT License** — see [`LICENSE`](LICENSE). SPDX-License-Identifier: `MIT`.
Copyright © 2026 İsmail Deniz Tanışman. Use, modify, and distribute freely with attribution; provided
"as is" without warranty.
