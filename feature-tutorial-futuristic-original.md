# Feature Spec — Futuristic Original Mode Tutorial (detailed, build-it-right)

> **Ground truth:** `tutorial-futuristic-original-demo.html` (exact visuals, flow, copy, timing).
> **Depends on:** `feature-app-shell-i18n-theme.md` (i18n + theme) **and** `feature-tutorial-classic.md`
> (the reusable tutorial engine — **extend it, do not rebuild**). Also reuse the medallion widget from
> `feature-futuristic-metallic-pawn.md`. Flutter/Dart. Follow §10 methodology: branch
> `feature/tutorial-futuristic-original`, autonomous mode, update `CHANGELOG.md`, English code.
> Build one mode at a time; this is **Futuristic · Original**.

---

## 0. Reuse + extend the engine

Reuse from Classic: `TutorialController`, the step/progress/always-on-Skip scaffold, the gif-loop
driver, info/loop/demo step kinds. **What Original adds:**

- Pawns now have a **value** and an **owner**: `gold` = ours, `bordeaux` = opponent.
- Demo steps have a **hand** (a rail of selectable gold pawns) and a **select-then-place**
  interaction (tap a hand pawn, then tap a board cell).
- A **capture rule** (place a strictly larger pawn onto an opponent pawn to eat it).

Extend `TutorialStep` with: `hand` (list of int values), owner-aware board cells, `mode`
(`free | eat | win | eatwin`), and `eatAt` (for the capture loop).

## 1. Visual language & theme (Futuristic)

- **Pawns = metallic medallions** (reuse `feature-futuristic-metallic-pawn.md`): ours **gold**,
  opponent **bordeaux**. Numbers must be legible per the opposite-brightness rule — **gold disc →
  dark number, bordeaux disc → bright number**, two-pass (stroke + fill), never outline-only.
- **Board:** gold shimmer frame + warm dark cells (empty cell shows a faint `+`).
- **Showcase (info) pawns:** large **fixed** size (~96px) with a large number (~44px) so the ring +
  digit are clearly visible (the fix just approved — don't let them shrink to content size).
- **Highlight:** target cell pulses gold. **Wrong / too-small:** target cell flashes (~3×).
  **Capture:** the bordeaux pawn plays a leave animation (scale-down + slight rotate) then the gold
  pawn pops in, with a gold ripple ring. **Win line:** bright gold line across the 3 winning cells.
- Surfaces follow the active dark/light theme; the medallion identity (gold/bordeaux) stays constant.

## 2. Gif-loop rule (showcase steps) — same as Classic

`loop` steps animate gif-style: empty (target highlighted) **2s** → place the pawn (pop; for the
**capture** loop, play the bordeaux leave + gold ripple) → hold **2s** → reset → repeat. **Cancel the
timer on step change, skip, and dispose** (top bug risk).

## 3. Demo interaction (select-then-place)

- Each demo shows a **hand rail** of gold pawns. Tap a hand pawn → **select** (it lifts/glows). Tap a
  board cell → attempt to place the selected pawn.
- **No pawn selected** → hint `hint_select` ("select a pawn first").
- Modes:
  - **`free`** — placing on any **empty** cell succeeds.
  - **`win`** — only the **target** (empty) cell: place → draw win line → success; any other cell →
    `hint_redirect`.
  - **`eat`** — only the **target** (opponent) cell: if `selectedValue > cellValue` → capture
    (leave + ripple) + place → success; if `selectedValue ≤ cellValue` → `hint_small`; other cell →
    `hint_redirect`. **Capture requires strictly greater value; equal is not allowed.**
  - **`eatwin`** — same as `eat`, and on success also draw the win line.
- Tap on an own/occupied non-target cell → ignore or `hint_redirect`.
- On success: show `hint_great` (or `hint_win` when a win line is drawn) and auto-advance after ~1.15s.

## 4. Steps — exact configuration

Board indices `0..8` row-major. `G(v)` = gold (ours), `B(v)` = bordeaux (opponent), `_` = empty.

| # | kind | board | hand | hi / target | win | mode | text keys (prefix `tut_orig_`) | button |
|---|------|-------|------|-------------|-----|------|--------------------------------|--------|
| 1 | info | visual: big `G(6)` `B(4)` | — | — | — | — | `welcome_title`/`welcome_body` | `btn_start` |
| 2 | info | visual: big `G(5)` `G(2)` `B(6)` | — | — | — | — | `numbers_title`/`numbers_body` | `btn_next` |
| 3 | loop | `[G2,_,_, B4,_,G3, _,B1,_]`, place `G(5)`@`4` | — | hi `4` | — | — | `place_title`/`place_body` | `btn_ok` |
| 4 | demo | `[G2,_,_, B4,_,G3, _,B1,_]` | `[1,4,5,6]` | hi `4` | — | `free` | `demoplace_title`/`demoplace_body`/`hint_select` | — |
| 5 | loop | `[B2,_,G1, _,B3,_, G5,_,B5]`, place `G(4)`@`4`, `eatAt 4` | — | hi `4` | — | — | `capintro_title`/`capintro_body` | `btn_next` |
| 6 | info | visual: `G(5)` `>` `B(3)` | — | — | — | — | `caprule_title`/`caprule_body` | `btn_ok` |
| 7 | demo | `[B2,_,G1, _,B3,_, _,_,_]` | `[2,5]` | target `4` | — | `eat` | `demoeat_title`/`demoeat_body`/`hint_eat` | — |
| 8 | info | visual: board `[G2,G2,G2, _,_,_, _,_,_]` win `[0,1,2]` | — | — | — | — | `winrule_title`/`winrule_body` | `btn_try` |
| 9 | demo | `[B5,_,G4, _,B6,G2, _,_,_]` | `[1,3,5,6]` | target `8` | `[2,5,8]` | `win` | `demowin_title`/`demowin_body`/`hint_win_place` | — |
| 10 | demo | `[G6,_,G1, _,B5,_, _,G2,G4]` | `[3,4,5,6]` | target `4` | `[0,4,8]` | `eatwin` | `demoeatwin_title`/`demoeatwin_body`/`hint_eatwin` | — |
| 11 | info | visual: big `G(6)` | — | — | — | — | `done_title`/`done_body` | `btn_finish` |

Notes: step 4 accepts any empty cell (4 is the suggested highlight). Step 7 must capture the `B(3)` at
index 4 (`2` fails as too small, `5` succeeds). Step 9 completes the right column `[2,5,8]` (4,2,new
gold). Step 10 captures `B(5)` at index 4 with a pawn `>5` and completes the diagonal `[0,4,8]`
(6,new,4 gold).

## 5. i18n — keys + copy

All in ARB (`tut_orig_*` + shared hints/buttons). **No literals in code.** TR + EN final;
**translate RU + ES in the same warm tone.**

| key | TR | EN |
|-----|----|----|
| `welcome_title` | Futuristic’e hoş geldin | Welcome to Futuristic |
| `welcome_body` | Burada tic-tac-toe’yu daha önce hiç görmediğin bir hâliyle oynayacaksın. Acele yok — yeni kuralları birlikte, adım adım keşfedeceğiz. Hazırsan başlıyoruz. | You're about to play tic-tac-toe like you've never seen it. No rush — we'll discover the new rules together, step by step. Ready when you are. |
| `numbers_title` | Artık sayılar var | Now there are numbers |
| `numbers_body` | Sadece X ya da O koymuyorsun. Onların yerine değerli sayılar koyuyorsun — ve her sayının bir gücü var. Bu küçük fark her şeyi değiştiriyor. | You no longer place just X or O. Instead you place valued numbers — and each one carries a power. That small change changes everything. |
| `place_title` | İstediğin taşı koy | Place any pawn you like |
| `place_body` | Boş bir kareye dilediğin taşını bırakabilirsin. İzle — parlayan kareye altın bir taş düşüveriyor. | You can drop any of your pawns on an empty square. Watch — a gold pawn lands on the glowing square. |
| `demoplace_title` | Şimdi sen dene | Now you try |
| `demoplace_body` | Önce alttan bir taş seç, sonra boş bir kareye dokunup koy. | First pick a pawn below, then tap an empty square to place it. |
| `capintro_title` | Taş da yiyebilirsin | You can capture, too |
| `capintro_body` | İşin güzel yanı: rakibin taşını yiyebilirsin. İzle — daha büyük bir altın taş, rakibin taşının üstüne gelip onu alıyor. | Here's the fun part: you can capture your opponent's pawn. Watch — a larger gold pawn lands on theirs and takes it. |
| `caprule_title` | Ama bir şartı var | But there's one rule |
| `caprule_body` | Bir taşı yiyebilmen için, ondan daha büyük değerde bir taşa sahip olman gerekir. Küçük taş, büyüğü yiyemez. | To capture a pawn, yours must have a strictly greater value. A smaller pawn can't take a larger one. |
| `demoeat_title` | Hadi sen ye | Now you capture |
| `demoeat_body` | Ortadaki rakip taşını (3) yemeyi dene. Önce küçük bir taşla — sonra yeterince büyük olanla. | Try to capture the opponent pawn (3) in the center. First with a small pawn — then with one that's big enough. |
| `winrule_title` | Kazanmanın yolu | How you win |
| `winrule_body` | Kazanmak hâlâ tanıdık: kendi üç taşını yatay, dikey ya da çapraz bir hizaya getir. Değerleri değil, hizayı önemse. | Winning is still familiar: line up three of your own pawns — horizontal, vertical, or diagonal. It's the line that matters, not the values. |
| `demowin_title` | Hattı tamamla | Complete the line |
| `demowin_body` | Parlayan boş kareye bir taş koy ve sağ sütundaki üçlüyü tamamla. | Place a pawn on the glowing empty square and complete the right-column trio. |
| `demoeatwin_title` | Hem ye, hem kazan | Capture and win at once |
| `demoeatwin_body` | Bu sefer kazanç hamlen aynı zamanda bir taş yiyecek. Ortadaki rakip 5’i yiyecek kadar büyük bir taş seç ve oraya koyarak çaprazı kapat. | This time your winning move also captures. Pick a pawn big enough to take the opponent's 5 in the center, place it there, and close the diagonal. |
| `done_title` | İşte Original bu kadar! | That's Original! |
| `done_body` | Artık sayıların gücünü, yemeyi ve kazanmayı biliyorsun. Hadi gerçek bir oyunda dene — kazanan sen ol. | Now you know the power of numbers, capturing, and winning. Try it in a real game — be the one who wins. |
| `hint_select` | Önce bir taş seç | Pick a pawn first |
| `hint_place_now` | Şimdi bir kareye koy | Now tap a square |
| `hint_eat` | Bir taş seç, sonra ortadaki rakip taşına koy | Pick a pawn, then tap the center opponent pawn |
| `hint_win_place` | Bir taş seç, sonra parlayan kareye koy | Pick a pawn, then tap the glowing square |
| `hint_eatwin` | 5’ten büyük bir taş seç, sonra ortaya koy | Pick a pawn bigger than 5, then place it in the center |
| `hint_small` | Bu taş çok küçük — daha büyük bir taş seç | Too small — pick a bigger pawn |
| `hint_redirect` | Parlayan kareye koy | Place it on the glowing square |
| `hint_great` | Harika! | Nice! |
| `hint_win` | Kazandın! | You win! |
| `rail_label` | Senin taşların | Your pawns |
| `btn_start` / `btn_next` / `btn_ok` / `btn_try` / `btn_finish` | Başlayalım / Devam / Anladım / Hadi deneyelim / Bitir | Let's begin / Continue / Got it / Let's try / Finish |
| `skip` | Geç | Skip |

## 6. Flutter mapping

- **Reuse** the engine scaffold (controller, dots, Skip, info/loop/demo dispatch).
- **`MedallionPawn`** widget (gold/bordeaux, value, legible two-pass number) — reused from the
  metallic-pawn spec; a `large` flag for showcase pawns (fixed ~96px, number ~44px).
- **`HandRail`** widget: a row of selectable gold medallion chips; tap selects (lifts/glows), exposes
  `selectedIndex`.
- **`TutorialBoard`** + `TutorialCell` (empty shows `+`); cell tap → demo placement logic (§3).
- **Capture animation:** bordeaux pawn `AnimatedScale`/rotation leave (~260ms) then gold pawn pop +
  a gold ripple ring overlay.
- **Win line:** gold `CustomPainter`, animated draw; centers for an 88px-cell / 9px-gap board are
  `[44,141,238]` (viewBox 282) — verify against the real layout.
- **Loop driver:** reuse; the capture loop also emits the ripple each cycle. Cancel on step
  change/skip/dispose.
- **Demo controller state:** `selectedHandIndex` (reset on each step). All copy via `AppLocalizations`.

## 7. Pitfalls to avoid

- **Legible numbers:** gold disc → **dark** number fill, bordeaux disc → **bright** fill, two-pass —
  never the disc's own color, never outline-only (this was a real bug earlier).
- **Capture rule is strictly `>`** — equal value must NOT capture.
- **Mode logic:** `free` = any empty; `win` = target empty only; `eat`/`eatwin` = target opponent
  only with the `>` check; everything else redirects, occupied own cells are ignored.
- **Selection reset:** clear `selectedHandIndex` whenever the step changes.
- **Timer leaks:** cancel loop timers on step change/skip/dispose.
- **Win-line geometry:** confirm the 3 winning centers; an off line is the most visible defect.
- **Showcase pawns:** fixed large size (don't shrink to content).
- **Theme:** medallions stay gold/bordeaux in both themes; only surfaces follow dark/light.

## CHANGELOG (Unreleased)

- `Added` — Futuristic Original interactive tutorial: extends the tutorial engine with valued/owned
  medallion pawns, a selectable hand rail and select-then-place interaction, the capture rule
  (strictly greater), gif-looped place/capture showcases, demos for placing, capturing,
  winning-by-placing and winning-by-capturing, animated gold win lines, and full i18n (tr/en/ru/es).

## 🛑 TEST DURAĞI

On device: full pass in each language (all text incl. hints/buttons change); showcase steps loop
2s→place→2s→reset (capture loop shows the eat + ripple) and stop on leaving the step; demos require
selecting a hand pawn first; `free` accepts any empty, `win` only the target empty (draws the line),
`eat`/`eatwin` only capture with a strictly larger pawn (small → "too small", equal → not allowed) and
`eatwin` draws the line; numbers are legible (dark on gold, bright on bordeaux) under dark and light
themes; Skip exits cleanly from any step with no leaked timers. Report and wait for confirmation;
continue unrelated work meanwhile.
