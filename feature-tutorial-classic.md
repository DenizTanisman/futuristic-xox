# Feature Spec — Classic Mode Tutorial (detailed, build-it-right)

> **Ground truth:** `tutorial-classic-demo.html` (exact visuals, flow, copy, timing).
> **Depends on:** `feature-app-shell-i18n-theme.md` (localization + theme must already exist; all
> strings come from ARB). Flutter/Dart. Follow §10 methodology: branch `feature/tutorial-classic`,
> autonomous mode, update `CHANGELOG.md`, English code, Turkish conversation.
> Build one mode's tutorial at a time; this is **Classic** only.

---

## 0. Reusable tutorial engine (build this generically — Futuristic tutorials reuse it)

- **`TutorialController`** (`ChangeNotifier`): holds `int stepIndex`; methods `next()`,
  `skip()`, `restart()`; exposes `current` step and `isLast`. `next()` on the last step → call
  `onFinish`.
- **`TutorialStep`** model (a sealed class or a struct with a `kind` enum):
  `kind ∈ { info, loop, triple, demo }`, plus localized **text keys** (not literals) and an optional
  board configuration (matrix, highlight, target, winLine, anyEmpty).
- **Skip:** a button visible on **every** step (top-right). Tapping it ends the tutorial immediately
  (calls `widget.onExit`) from any step. The progress indicator is a row of dots (one per step), the
  current one elongated/highlighted.
- **Entry/exit:** the tutorial is launched from the tutorial menu (and optionally on first Classic
  play). On finish **or** skip, call the provided callback (e.g. pop back to mode setup, or start a
  real game). Do not hardcode the destination — take it as a parameter.

## 1. Visual language & theme

- **Marks (Classic identity, constant across themes):**
  - X: two round-cap strokes, **silver** gradient `#FFFFFF → #C8CDD8 (50%) → #7D8392`, drawn with a
    stroke-draw animation (second stroke starts ~180ms after the first).
  - O: a circle, **dark-gold** gradient `#E8C87A → #C79A3A (50%) → #8A6A1D`, stroke-draw.
- **Board:** steel frame + dark radial cells (as in the demo).
- **Surfaces vs identity:** the scaffold background and body text follow the **active app theme**
  (dark/light from the app-shell spec). The **marks and board keep their Classic identity** in both
  themes — only the surrounding surfaces adapt; in light theme verify cell/frame contrast stays
  legible. (The tutorial is not exempt from theming the way the entry screen is.)
- **Highlight:** the target cell pulses with a silver glow.
- **Wrong tap:** the *correct* cell flashes red (~3 pulses).
- **Win line:** a bright silver line drawn across the 3 winning cells with an animated draw + glow.
- **Every step has a supporting visual** — no text-only steps.

## 2. Gif-loop rule — showcase (non-demo) steps

For `loop` and `triple` steps (no user interaction), animate **gif-style**:

1. Show the board **empty** at the target cell (target cell highlighted) — hold **2s**.
2. **Place** the pawn (pop + stroke-draw; for `triple`, also draw the win line) — hold **2s**.
3. **Reset** to empty → repeat from step 1.

Implement with a periodic driver (`Timer.periodic(2s)` toggling a phase, or an `AnimationController`
with a 4s loop). **It MUST be cancelled when the step changes and on skip/dispose** — no leaked
timers (this is the #1 bug risk here). Cancel in `dispose()` and whenever `stepIndex` changes.

## 3. Demo interaction rule (`demo` steps)

- The board cells are tappable.
- **Correct tap** — the `target` cell, or *any empty cell* when `anyEmpty == true`:
  place X (pop), draw the win line if the step defines one, show the success hint (`hintGreat`), and
  **auto-advance after ~1.1s**.
- **Wrong tap** on an empty non-target cell: keep the board, show the wrong hint (`hintWrong`), and
  flash the correct cell 3×. **Do not advance.**
- **Tap on an occupied cell:** ignore (no-op).

## 4. Steps — exact configuration

Board is 3×3, indices `0..8` row-major:
```
0 1 2
3 4 5
6 7 8
```

| # | kind   | board (preset)                | highlight / target | win line   | text keys (prefix `tut_classic_`) | button key |
|---|--------|-------------------------------|--------------------|------------|-----------------------------------|------------|
| 1 | info   | visual: big X + big O          | —                  | —          | `welcome_title` / `welcome_body`  | `btn_start`|
| 2 | loop   | `[X,O,O, _,_,_, _,_,X]`, place `4` | hi `4`         | —          | `turn_title` / `turn_body`        | `btn_ok`   |
| 3 | demo   | `[X,O,O, _,_,_, _,_,X]`, `anyEmpty` | hi `4` (suggested) | —     | `demo1_title` / `demo1_body` / `demo1_hint` | — |
| 4 | triple | three mini boards (below), looped | per board       | per board  | `winrule_title` / `winrule_body`  | `btn_try`  |
| 5 | demo   | `[X,X,_, _,_,_, _,_,_]`         | target `2`         | `[0,1,2]`  | `demo2a_title` / `demo2a_body` / `hint_glow` | — |
| 6 | demo   | `[X,_,_, X,_,_, _,_,_]`         | target `6`         | `[0,3,6]`  | `demo2b_title` / `demo2b_body` / `hint_glow` | — |
| 7 | demo   | `[X,_,_, _,_,_, _,_,X]`         | target `4`         | `[0,4,8]`  | `demo2c_title` / `demo2c_body` / `hint_glow` | — |
| 8 | info   | visual: big X                  | —                  | —          | `done_title` / `done_body`        | `btn_finish`|

**Step 4 — triple boards (each loops empty→place-last→line→reset):**
- Horizontal: base `[X,X,_, _,_,_, _,_,_]`, last `2`, win `[0,1,2]`, caption `cap_h`.
- Vertical:   base `[X,_,_, X,_,_, _,_,_]`, last `6`, win `[0,3,6]`, caption `cap_v`.
- Diagonal:   base `[X,_,_, _,X,_, _,_,_]`, last `8`, win `[0,4,8]`, caption `cap_d`.

## 5. i18n — keys + copy

All strings live in the ARB files (`tut_classic_*` + a few shared). **No literals in code.** TR and EN
are final; **translate RU + ES matching the same warm, encouraging tone.**

| key | TR | EN |
|-----|----|----|
| `welcome_title` | Hoş geldin | Welcome |
| `welcome_body` | Seni burada görmek güzel. Birazdan bu tahtanın dilini birlikte çözeceğiz — acelesi yok, her şeyi adım adım, omuz omuza ilerleyeceğiz. Hazırsan başlıyoruz. | Good to have you here. We'll learn this board together in a moment — no rush, step by step, side by side. Ready when you are. |
| `turn_title` | Sıra sende başlıyor | Your turn to start |
| `turn_body` | Sıra sana geldiğinde tahtaya bir X bırakırsın. İzle — parlayan kareye bir X düşüveriyor. | When it's your turn you drop an X on the board. Watch — an X lands on the glowing square. |
| `demo1_title` | Şimdi sen dene | Now you try |
| `demo1_body` | Parlayan kareye dokun ve ilk X'ini koy. (Boş kalan herhangi bir kare de olur.) | Tap the glowing square and place your first X. (Any empty square works too.) |
| `demo1_hint` | Parlayan kareye dokun | Tap the glowing square |
| `winrule_title` | Kazanmanın tek sırrı | The one secret to winning |
| `winrule_body` | Üç X'i bir hizaya getir — yatay, dikey ya da çapraz, fark etmez. Hattı tamamlayan kazanır. | Line up three X's — horizontal, vertical, or diagonal, it doesn't matter. Complete the line and you win. |
| `demo2a_title` | 1 / 3 — Yatay | 1 / 3 — Horizontal |
| `demo2a_body` | İki X yan yana hazır. Parlayan kareyi tamamla ve yatay hattı kapat. | Two X's are lined up. Complete the glowing square and close the horizontal line. |
| `demo2b_title` | 2 / 3 — Dikey | 2 / 3 — Vertical |
| `demo2b_body` | Bu kez sütunu tamamlıyoruz. Parlayan kareye X koy. | This time we complete the column. Place an X on the glowing square. |
| `demo2c_title` | 3 / 3 — Çapraz | 3 / 3 — Diagonal |
| `demo2c_body` | Son olarak çapraz hat. Ortadaki parlayan kareye X koyup üçlüyü tamamla. | Finally, the diagonal. Place an X on the glowing center square to complete the trio. |
| `done_title` | İşte bu kadar! | That's all it takes! |
| `done_body` | Artık Classic tahtası tamamen senin. İstediğin an gerçek bir oyuna geçebilirsin — başarılar, kazanan sen ol. | The Classic board is all yours now. Jump into a real game whenever you like — good luck, and may you be the one who wins. |
| `hint_glow` | Parlayan kareye dokun | Tap the glowing square |
| `hint_wrong` | Oraya değil — parlayan kareye koy | Not there — place it on the glowing square |
| `hint_great` | Harika! | Nice! |
| `cap_h` / `cap_v` / `cap_d` | Yatay / Dikey / Çapraz | Horizontal / Vertical / Diagonal |
| `btn_start` / `btn_ok` / `btn_try` / `btn_finish` | Başlayalım / Anladım / Hadi deneyelim / Bitir | Let's begin / Got it / Let's try / Finish |
| `skip` | Geç | Skip |

## 6. Flutter mapping

- **Widgets:** `TutorialScreen` (Scaffold: dots + Skip in a header, animated body, footer button) →
  builds the current step. `TutorialBoard` (3×3, a `Stack`/`GridView`), `TutorialCell`
  (`GestureDetector` + highlight/flash state), `MarkPainter` (CustomPainter drawing X or O with a
  `progress` 0→1 for the stroke-draw — use `PathMetrics` to reveal the stroke), `WinLinePainter`
  (CustomPainter, animated `progress`).
- **Stroke-draw:** an `AnimationController` per placed mark drives `MarkPainter.progress`; X draws its
  second stroke after the first (offset the second segment's progress).
- **Loop driver:** `Timer.periodic(Duration(seconds:2))` toggling an `empty/placed` phase and calling
  `setState`; **cancel on step change and in `dispose`.**
- **Win-line coordinates:** compute the 3 winning cell centers from the board layout (full board for
  steps 5–7; mini boards for the triple). Draw from first to last winning cell.
- **Demo taps:** `TutorialCell.onTap` → controller logic in §3 (correct/wrong/occupied).
- **Skip / progress:** header row; Skip calls `onExit`; dots reflect `stepIndex`.
- All copy via `AppLocalizations` keys from §5.

## 7. Pitfalls to avoid (so it builds right)

- **Leaked timers:** always cancel the loop timer on step change + dispose; entering a `demo` step
  must stop any running loop.
- **anyEmpty vs target:** step 3 accepts any empty cell (4 is only the suggested highlight); steps
  5–7 require the exact `target`.
- **Win-line geometry:** double-check centers for both full and mini boards; an off line is the most
  visible defect.
- **Theme:** marks stay silver/gold in both themes; only surfaces follow dark/light. Don't tint the X
  with theme accent.
- **Skip from any step** (including mid-loop and mid-demo) must exit cleanly with no pending timers.

## CHANGELOG (Unreleased)

- `Added` — Classic mode interactive tutorial: reusable tutorial engine (steps, progress, always-on
  Skip), gif-looped showcase steps, tap-to-place demos with correct/wrong feedback, animated win
  lines, full i18n (tr/en/ru/es), theme-aware surfaces with constant Classic mark identity.

## 🛑 TEST DURAĞI

On device: run a full pass in each language (all text changes, incl. hints/buttons); confirm the
showcase steps loop 2s→place→2s→reset and stop when leaving the step; demos accept correct taps
(step 3 = any empty; 5–7 = exact target), reject wrong taps with the flash + hint, and ignore occupied
cells; win lines align on the right 3 cells; Skip exits cleanly from any step with no leaked timers;
marks stay silver/gold under both dark and light themes. Report and wait for confirmation; continue
unrelated work meanwhile.
