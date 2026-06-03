//! A tiny, dependency-free, seedable PRNG (SplitMix64).
//!
//! Used for Bonanza hand randomization (spec §4.3) and — later — the Easy AI (spec §7.2).
//! Being seedable keeps every randomized behavior reproducible in tests.

/// SplitMix64 generator. Fast, good statistical quality, fully deterministic from a seed.
#[derive(Debug, Clone)]
pub struct Rng {
    state: u64,
}

impl Rng {
    /// Create a generator from an explicit seed (any `u64`, including 0).
    pub fn new(seed: u64) -> Self {
        Rng { state: seed }
    }

    /// Next raw 64-bit value.
    pub fn next_u64(&mut self) -> u64 {
        // SplitMix64: https://prng.di.unimi.it/splitmix64.c
        self.state = self.state.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }

    /// Uniform integer in `[0, n)`. Returns 0 when `n == 0`.
    pub fn below(&mut self, n: usize) -> usize {
        if n == 0 {
            return 0;
        }
        // Lemire-style rejection-free mapping is overkill here; modulo bias is negligible
        // for the small ranges this game uses.
        (self.next_u64() % n as u64) as usize
    }

    /// In-place Fisher–Yates shuffle.
    pub fn shuffle<T>(&mut self, slice: &mut [T]) {
        let len = slice.len();
        if len < 2 {
            return;
        }
        for i in (1..len).rev() {
            let j = self.below(i + 1);
            slice.swap(i, j);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn deterministic_from_seed() {
        let mut a = Rng::new(42);
        let mut b = Rng::new(42);
        for _ in 0..100 {
            assert_eq!(a.next_u64(), b.next_u64());
        }
    }

    #[test]
    fn below_in_range() {
        let mut r = Rng::new(7);
        for n in 1..50usize {
            for _ in 0..200 {
                assert!(r.below(n) < n);
            }
        }
        assert_eq!(r.below(0), 0);
    }

    #[test]
    fn shuffle_is_a_permutation() {
        let mut r = Rng::new(123);
        let mut v: Vec<u32> = (0..20).collect();
        r.shuffle(&mut v);
        let mut sorted = v.clone();
        sorted.sort_unstable();
        assert_eq!(sorted, (0..20).collect::<Vec<_>>());
    }
}
