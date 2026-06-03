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

[Unreleased]: https://example.com/compare/HEAD
