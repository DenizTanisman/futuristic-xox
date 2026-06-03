# Security Review — Threat Model & OWASP Checklist

Per spec §9 and §10.7 (threat model at start, per-feature review, OWASP checklist at end).

## Scope
v1 is **offline** (human vs. computer / local play). No network, no accounts, no persistence of
sensitive data, no remote calls. The attack surface is correspondingly small; the main risks are
local input handling and integer/index safety in the engine.

## Threat model (v1)

| Asset / Surface | Threat | Mitigation (status) |
|-----------------|--------|---------------------|
| Engine board indices | Out-of-bounds / computed-index access | `GameState::in_bounds` + `is_move_legal` validate every cell before use; `at()` returns `None` for OOB. Board is a `Vec` (bounds-checked in Rust). ✅ |
| Move legality | Illegal capture / wrong-owner / value-not-in-hand | Centralized in `rules::is_move_legal` + `placement_legal`; the UI/bridge call it before `apply`. Search only ever passes generated legal moves. ✅ |
| AI search | Unbounded compute / UI freeze | Iterative deepening **time box** + depth cap (`SearchLimits`); designed to run off the Flutter UI isolate via the async bridge. ✅ (latency tuned in §13.3) |
| Untrusted input | `eval`, code injection, unsafe rendering | None used. No `eval`, no dynamic code, no HTML/web view; Flutter renders typed widgets only. ✅ |
| Secrets | Leaked keys/tokens | None present. No credentials, no API keys, no telemetry. ✅ |
| Memory safety | UB / buffer overrun in the native core | Pure safe Rust — **no `unsafe`** in `engine`, `ai`, or `bridge` (the generated FRB glue is the only FFI boundary, added at integration). ✅ |

## OWASP-style checklist (v1, offline)

- [x] **Input validation** — all moves bounds- and rule-checked before mutating state.
- [x] **No injection vectors** — no `eval`, no SQL, no shell, no dynamic code paths.
- [x] **Safe rendering** — Flutter typed widgets only; no web view / raw HTML.
- [x] **No secrets in code or repo** — verified; nothing to leak in an offline build.
- [x] **No remote calls** — fully offline; no network permissions required.
- [x] **Memory safety** — 100% safe Rust (no `unsafe`); Dart is memory-safe by construction.
- [x] **Dependency hygiene** — engine/ai have **zero** third-party crates; bridge depends only on
      the local crates; the UI ships with no third-party Dart packages (mock backend).
- [x] **Resource bounds** — AI compute is time-boxed and depth-capped; no unbounded loops on input.
- [x] **Determinism / no RNG misuse** — RNG is a local PRNG for gameplay only (not security); seeded
      for reproducibility.

## Forward (v2, online — NOT in v1, tracked per spec §9)
When the engine moves server-authoritative: server validates every move (never trust the client);
auth middleware + IDOR ownership checks on every endpoint; parameterized queries/ORM; rate limiting;
CORS whitelist (no `*`); secrets via env vars; `debug=false` in prod; CI with semgrep + secret scan.

## Status
v1 offline checklist **passed**. Re-run this review when networking is introduced (v2).
