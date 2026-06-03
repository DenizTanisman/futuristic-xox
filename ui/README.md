# Futuristic XOX — UI (Unit 3)

Flutter app: entry/mode/setup screens, board, both pawn rails with slide animation, turn & Morph
indicators, inline messages, and win/lose/draw banners (spec §8).

## Backends

The UI talks to a single [`GameApi`](lib/src/game/game_api.dart) interface, so the backend is
swappable with no UI changes:

- **`DartGameApi`** (default, active now) — a pure-Dart mock engine + a lightweight AI. Faithfully
  ports the engine rules (capture, lines, Morph shapes, two-moves-per-turn) so the app is **fully
  playable today** without the Rust toolchain. This is the "mock AI" development phase (spec §10.2,
  §14.4).
- **`RustGameApi`** (integration step, not yet generated) — `flutter_rust_bridge` bindings to the
  `bridge::GameSession`, swapping in the native engine + the real negamax AI (Unit 2). The AI search
  runs natively off the Flutter UI isolate, which is what keeps animations at 60fps (spec §2).

## Run (requires the Flutter SDK)

> ⚠️ The Flutter SDK is **not installed in the build environment**, so the app could not be compiled
> or run here. Install Flutter ≥ 3.27 (Dart ≥ 3.6), then:

```sh
cd ui
flutter pub get
flutter test          # runs the Dart mock-engine rule-parity tests
flutter run           # launches on a connected device / emulator
```

## Wiring the native Rust backend (integration step)

When ready to replace the mock with the native engine + AI:

1. Add `flutter_rust_bridge` (Dart) and `flutter_rust_bridge` + `flutter_rust_bridge_codegen` (Rust,
   in `../bridge/Cargo.toml`); set the `bridge` crate's `crate-type` to include `staticlib`/`cdylib`.
2. Annotate the `bridge::GameSession` API and run `flutter_rust_bridge_codegen generate`.
3. Implement `RustGameApi implements GameApi` over the generated bindings (1:1 with the mock — the
   view structs already match).
4. Switch the backend constructed in `GameScreen` from `DartGameApi()` to `RustGameApi()`.

No other UI code changes: the model types (`Snapshot`, `MoveResult`, `Outcome`) already mirror the
Rust structs.

## Structure

```
lib/
  main.dart
  src/
    theme/app_theme.dart            bordeaux vs dark-gold palette, animation durations
    models/game_models.dart         Mode4, Difficulty, Snapshot, MoveResult, Outcome
    game/
      game_api.dart                 backend interface
      dart_game_api.dart            pure-Dart mock engine + mock AI
      geometry.dart                 line + Morph shape generation (Dart port)
    controllers/game_controller.dart human↔AI orchestration, selection, messages
    screens/                        entry, futuristic-select, setup, game
    widgets/                        board, pawn, rail, turn/result/message
test/dart_engine_test.dart          rule-parity tests for the mock backend
```
