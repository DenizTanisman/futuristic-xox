//! # Futuristic XOX — Game Engine (Unit 1)
//!
//! Pure, platform-independent game logic: state model, rules, capture, win detection (lines and
//! Morph shapes), per-mode configuration, and a pure `apply`. No UI or platform dependencies, so it
//! is fully headless-testable and reusable for the v2 server (spec §2, §6, §7.1).
//!
//! The [`Mode`] trait is the frozen merge contract that Units 2 (AI) and 3 (UI) build against.
//!
//! ## Quick start
//! ```
//! use engine::{build, GameConfig, ModeKind};
//!
//! let (mode, state) = build(GameConfig { kind: ModeKind::Original, rows: 3, cols: 3, win_len: 3 }, 0);
//! let moves = mode.ordered_moves(&state);
//! let next = mode.apply(&state, &moves[0]);
//! assert!(mode.is_terminal(&next).is_none());
//! ```

pub mod geometry;
pub mod mode;
pub mod modes;
pub mod rng;
pub mod rules;
pub mod setup;
pub mod state;

// ---- Public surface ----
pub use mode::{build, GameConfig, Mode, ModeKind, INF, WIN};
pub use rng::Rng;
pub use rules::is_move_legal;
pub use state::{GameResult, GameState, Move, Pawn};

pub use modes::line::LineMode;
pub use modes::morph::MorphMode;
