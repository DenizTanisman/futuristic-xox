//! Concrete `Mode` implementations (spec §7.5).
//!
//! - [`line::LineMode`] — Classic (symbols) and Original/Bonanza (valued + capture); 3-in-a-row win.
//! - [`morph::MorphMode`] — valued + capture, two moves per turn, 4-cell shape win.

pub mod line;
pub mod morph;
