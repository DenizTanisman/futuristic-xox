# Morph tutorial — single-placement update

Morph changed from two-stones-per-turn to **single alternating placement** (engine Unit A). Two
surgical tutorial changes, all four locales (tr/en/ru/es) in parity.

## 1. Repurposed the former "double move" step → "two of each piece"

- Keys `tutMorphTwomovesTitle` / `tutMorphTwomovesBody` (kept the same keys, the same step slot, and
  its showcase visual) now teach **hand composition only**:
  - tr: `Her taştan iki tane` / `Elinde her taş çeşidinden ikişer tane bulunur.`
  - en: `Two of each piece` / `You have two of each piece in your hand.`
  - ru: `По две каждой фигуры` / `В руке у тебя по две фишки каждого значения.`
  - es: `Dos de cada pieza` / `Tienes dos de cada pieza en la mano.`

### §1.1 decision (logged)
The step already used `bigMedallions: [g(2), g(2), g(5), g(5)]` — a showcase of two 2's and two 5's,
i.e. **each value appearing twice**. That visual matches the new "two of each piece" purpose exactly,
so it was **kept as-is** (no new asset, compiles cleanly). The owner can swap it for a hand/rail
visual later if preferred.

## 2. Removed the "two stones to win" demo

- Deleted the `tutMorphIh` demo step (the only one with two-cell `targets: [6, 7]`, teaching a
  two-stone win — impossible now). Removed its strings `tutMorphIhTitle` / `tutMorphIhBody` and the
  now-orphan `tutMorphHintFirst` from all four locales; regenerated `app_localizations`.
- The single-stone vertical-I demo (`tutMorphIv`, `targets: [13]`) is unchanged and already teaches
  completing a shape with one placement — correct under single-placement Morph.

## Re-indexing / navigation
Step order and all counters derive from `steps.length` / `stepIndex` in `TutorialController` (no
hard-coded counts), so removing one step auto-reindexes with no gaps/off-by-one. The keyed
`AnimatedSwitcher` transition keys off `stepIndex` and remains correct.

## §1.4 straggler scan (reported, not edited)
No remaining two-stones-per-turn references. Two `две фишки` hits in `app_ru.arb` are benign: one is
the **Bonanza** deal body ("two opponent pawns", unrelated to Morph turns), the other is the
repurposed "two of each value" string above.

## Tests
65 Dart tests pass (incl. tutorial); `flutter analyze` clean. 🛑 owner device test pending.
