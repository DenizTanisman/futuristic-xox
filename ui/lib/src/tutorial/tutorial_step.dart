import '../../l10n/app_localizations.dart';

/// A localized-text selector: resolves a string from [AppLocalizations] (keys live in ARB, never as
/// literals — spec §5).
typedef L10nText = String Function(AppLocalizations l);

/// The kind of tutorial step (spec §0). `deal` is Bonanza's showcase that reveals a random number
/// and a sequenced gold-then-bordeaux hand.
enum TutKind { info, loop, triple, demo, deal }

/// A Classic mark.
enum Mark { x, o }

/// The decorative visual for an `info` step.
enum InfoVisual { none, bigX, bigXO }

/// Demo interaction mode for Futuristic tutorials (spec §3). `lose` is Bonanza-only: any empty cell is
/// a forced loss — placing a bordeaux pawn there completes an opponent line. `shape` is Morph-only:
/// fill the target cells (value-agnostic); the win glows the 4 shape cells (no line).
enum TutMode { free, eat, win, eatwin, lose, shape }

/// A small shape-icon (Morph explainer steps §4): a [cols]×[rows] mini-grid with [filled] cells lit.
class MorphIcon {
  final int cols;
  final int rows;
  final List<int> filled;
  const MorphIcon({required this.cols, required this.rows, required this.filled});
}

/// A valued, owned pawn for Futuristic tutorials: owner 0 = gold (ours), 1 = bordeaux (opponent).
class TutPawn {
  final int owner;
  final int value;
  const TutPawn(this.owner, this.value);
}

/// Gold (ours) / bordeaux (opponent) literal helpers.
TutPawn g(int v) => TutPawn(0, v);
TutPawn b(int v) => TutPawn(1, v);

/// One mini board for the `triple` win-rule showcase (spec §4).
class MiniBoard {
  final List<Mark?> base; // 9 cells; the `last` cell is empty here and gets placed in the loop
  final int last;
  final List<int> winLine;
  final L10nText caption;
  const MiniBoard({required this.base, required this.last, required this.winLine, required this.caption});
}

/// A single tutorial step (spec §0, §4). Text comes from [title]/[body]/[hint]/[button] selectors.
class TutorialStep {
  final TutKind kind;

  /// 9-cell preset board (row-major). Empty/unused for `info` and `triple`.
  final List<Mark?> board;

  /// Suggested highlight cell (a glow); for `loop` it's also where the pawn drops.
  final int? highlight;

  /// `demo`: the exact required cell (unless [anyEmpty]).
  final int? target;

  /// Winning line cells to draw (3 cells), if any.
  final List<int>? winLine;

  /// `demo`: accept any empty cell as correct (spec §3).
  final bool anyEmpty;

  /// `loop`: the cell + mark to place in the gif loop.
  final int? loopPlaceCell;
  final Mark loopPlaceMark;

  /// `triple`: the three mini boards.
  final List<MiniBoard>? triples;

  /// `info`: decorative big mark visual.
  final InfoVisual infoVisual;

  final L10nText title;
  final L10nText body;
  final L10nText? hint;

  /// Footer button label; `null` for `demo` steps (which auto-advance).
  final L10nText? button;

  // ---- Futuristic (Original) extensions (spec §0) ----

  /// Marks this as a Futuristic step (valued medallion pawns instead of X/O marks).
  final bool futuristic;

  /// Futuristic board: owned, valued pawns (gold/bordeaux). 9 cells.
  final List<TutPawn?> fcells;

  /// Demo hand: selectable gold pawn values (rail).
  final List<int>? hand;

  /// Demo interaction mode (free / eat / win / eatwin).
  final TutMode demoMode;

  /// `loop`: value + owner of the pawn placed each cycle; `eatAt` marks a capture loop (the placed
  /// pawn lands on an opponent at that cell).
  final int? loopValue;
  final int loopOwner;
  final int? eatAt;

  /// `info` (futuristic): large showcase medallions in a row; `gtrSeparator` shows a ">" between them.
  final List<TutPawn>? bigMedallions;
  final bool gtrSeparator;

  // ---- Bonanza extensions (spec §1, §4) ----

  /// `info` (Bonanza): show a "Number: N" badge instead of medallions; the value plugged into the
  /// localized badge (e.g. "?" before the deal, "4" on the deal step).
  final String? infoBadge;

  /// `deal`: the drawn number + the sequenced gold-then-bordeaux hand reveal.
  final int? dealNumber;
  final List<int>? dealGold;
  final List<int>? dealBord;

  /// Demo hand owner: 0 = gold (ours), 1 = bordeaux (opponent rail).
  final int handOwner;

  /// `demo`: multiple highlighted cells (Bonanza's forced-loss step highlights every empty cell).
  final List<int>? highlights;

  /// `lose` demo: maps each empty (forced) cell to the opponent line it completes when played.
  final Map<int, List<int>>? loseMap;

  /// `info`: an optional secondary "ghost" button (e.g. "Learn Original" cross-link).
  final L10nText? secondary;

  /// `demo`: overrides the hand rail label (e.g. gold vs bordeaux rail); falls back to the shared one.
  final L10nText? railLabel;

  // ---- Morph extensions (spec §3, §4) ----

  /// Board dimension for futuristic boards (Morph uses 4×4; Original/Bonanza default 3×3).
  final int gridCols;
  final int gridRows;

  /// `shape` demo: the empty cells to fill (one or two for the double move).
  final List<int>? targets;

  /// `shape` demo: the 4 cells that pulse with a gold glow on win.
  final List<int>? winShape;

  /// `shape` demo: the shape's name (I / L / Z) for the win hint.
  final String? shapeName;

  /// `info` (Morph): small shape-icon mini-grids (I/L/Z, diagonal, mirror examples).
  final List<MorphIcon>? shapeIcons;

  const TutorialStep({
    required this.kind,
    this.board = const [null, null, null, null, null, null, null, null, null],
    this.highlight,
    this.target,
    this.winLine,
    this.anyEmpty = false,
    this.loopPlaceCell,
    this.loopPlaceMark = Mark.x,
    this.triples,
    this.infoVisual = InfoVisual.none,
    required this.title,
    required this.body,
    this.hint,
    this.button,
    this.futuristic = false,
    this.fcells = const [null, null, null, null, null, null, null, null, null],
    this.hand,
    this.demoMode = TutMode.free,
    this.loopValue,
    this.loopOwner = 0,
    this.eatAt,
    this.bigMedallions,
    this.gtrSeparator = false,
    this.infoBadge,
    this.dealNumber,
    this.dealGold,
    this.dealBord,
    this.handOwner = 0,
    this.highlights,
    this.loseMap,
    this.secondary,
    this.railLabel,
    this.gridCols = 3,
    this.gridRows = 3,
    this.targets,
    this.winShape,
    this.shapeName,
    this.shapeIcons,
  });
}

// Convenience for terse board literals.
const Mark _x = Mark.x;
const Mark _o = Mark.o;

/// The Classic tutorial's 8 steps (spec §4). All text via ARB selectors.
List<TutorialStep> classicTutorialSteps() => [
      // 1 — welcome (info)
      TutorialStep(
        kind: TutKind.info,
        infoVisual: InfoVisual.bigXO,
        title: (l) => l.tutClassicWelcomeTitle,
        body: (l) => l.tutClassicWelcomeBody,
        button: (l) => l.tutBtnStart,
      ),
      // 2 — your turn (loop): place X on cell 4
      TutorialStep(
        kind: TutKind.loop,
        board: const [_x, _o, _o, null, null, null, null, null, _x],
        highlight: 4,
        loopPlaceCell: 4,
        title: (l) => l.tutClassicTurnTitle,
        body: (l) => l.tutClassicTurnBody,
        button: (l) => l.tutBtnOk,
      ),
      // 3 — now you try (demo, any empty)
      TutorialStep(
        kind: TutKind.demo,
        board: const [_x, _o, _o, null, null, null, null, null, _x],
        highlight: 4,
        anyEmpty: true,
        title: (l) => l.tutClassicDemo1Title,
        body: (l) => l.tutClassicDemo1Body,
        hint: (l) => l.tutClassicDemo1Hint,
      ),
      // 4 — win rule (triple loop)
      TutorialStep(
        kind: TutKind.triple,
        triples: [
          MiniBoard(
            base: const [_x, _x, null, null, null, null, null, null, null],
            last: 2,
            winLine: const [0, 1, 2],
            caption: (l) => l.tutCapH,
          ),
          MiniBoard(
            base: const [_x, null, null, _x, null, null, null, null, null],
            last: 6,
            winLine: const [0, 3, 6],
            caption: (l) => l.tutCapV,
          ),
          MiniBoard(
            base: const [_x, null, null, null, _x, null, null, null, null],
            last: 8,
            winLine: const [0, 4, 8],
            caption: (l) => l.tutCapD,
          ),
        ],
        title: (l) => l.tutClassicWinruleTitle,
        body: (l) => l.tutClassicWinruleBody,
        button: (l) => l.tutBtnTry,
      ),
      // 5 — horizontal demo
      TutorialStep(
        kind: TutKind.demo,
        board: const [_x, _x, null, null, null, null, null, null, null],
        target: 2,
        highlight: 2,
        winLine: const [0, 1, 2],
        title: (l) => l.tutClassicDemo2aTitle,
        body: (l) => l.tutClassicDemo2aBody,
        hint: (l) => l.tutHintGlow,
      ),
      // 6 — vertical demo
      TutorialStep(
        kind: TutKind.demo,
        board: const [_x, null, null, _x, null, null, null, null, null],
        target: 6,
        highlight: 6,
        winLine: const [0, 3, 6],
        title: (l) => l.tutClassicDemo2bTitle,
        body: (l) => l.tutClassicDemo2bBody,
        hint: (l) => l.tutHintGlow,
      ),
      // 7 — diagonal demo
      TutorialStep(
        kind: TutKind.demo,
        board: const [_x, null, null, null, null, null, null, null, _x],
        target: 4,
        highlight: 4,
        winLine: const [0, 4, 8],
        title: (l) => l.tutClassicDemo2cTitle,
        body: (l) => l.tutClassicDemo2cBody,
        hint: (l) => l.tutHintGlow,
      ),
      // 8 — done (info)
      TutorialStep(
        kind: TutKind.info,
        infoVisual: InfoVisual.bigX,
        title: (l) => l.tutClassicDoneTitle,
        body: (l) => l.tutClassicDoneBody,
        button: (l) => l.tutBtnFinish,
      ),
    ];

/// The Futuristic · Original tutorial's 11 steps (spec §4). All text via ARB selectors.
List<TutorialStep> originalTutorialSteps() => [
      // 1 — welcome
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6), b(4)],
        title: (l) => l.tutOrigWelcomeTitle,
        body: (l) => l.tutOrigWelcomeBody,
        button: (l) => l.tutBtnStart,
      ),
      // 2 — numbers have power
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(5), g(2), b(6)],
        title: (l) => l.tutOrigNumbersTitle,
        body: (l) => l.tutOrigNumbersBody,
        button: (l) => l.tutBtnNext,
      ),
      // 3 — place loop (gold 5 on cell 4)
      TutorialStep(
        kind: TutKind.loop,
        futuristic: true,
        fcells: [g(2), null, null, b(4), null, g(3), null, b(1), null],
        highlight: 4,
        loopPlaceCell: 4,
        loopValue: 5,
        title: (l) => l.tutOrigPlaceTitle,
        body: (l) => l.tutOrigPlaceBody,
        button: (l) => l.tutBtnOk,
      ),
      // 4 — place demo (any empty)
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [g(2), null, null, b(4), null, g(3), null, b(1), null],
        hand: [1, 4, 5, 6],
        highlight: 4,
        demoMode: TutMode.free,
        title: (l) => l.tutOrigDemoplaceTitle,
        body: (l) => l.tutOrigDemoplaceBody,
        hint: (l) => l.tutHintSelect,
      ),
      // 5 — capture loop (gold 4 eats bordeaux 3 at cell 4)
      TutorialStep(
        kind: TutKind.loop,
        futuristic: true,
        fcells: [b(2), null, g(1), null, b(3), null, g(5), null, b(5)],
        highlight: 4,
        loopPlaceCell: 4,
        loopValue: 4,
        eatAt: 4,
        title: (l) => l.tutOrigCapintroTitle,
        body: (l) => l.tutOrigCapintroBody,
        button: (l) => l.tutBtnNext,
      ),
      // 6 — capture rule (5 > 3)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(5), b(3)],
        gtrSeparator: true,
        title: (l) => l.tutOrigCapruleTitle,
        body: (l) => l.tutOrigCapruleBody,
        button: (l) => l.tutBtnOk,
      ),
      // 7 — capture demo (eat the B3 at 4; 2 too small, 5 works)
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [b(2), null, g(1), null, b(3), null, null, null, null],
        hand: [2, 5],
        target: 4,
        highlight: 4,
        demoMode: TutMode.eat,
        title: (l) => l.tutOrigDemoeatTitle,
        body: (l) => l.tutOrigDemoeatBody,
        hint: (l) => l.tutHintEat,
      ),
      // 8 — win rule (static board with a line)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        fcells: [g(2), g(2), g(2), null, null, null, null, null, null],
        winLine: [0, 1, 2],
        title: (l) => l.tutOrigWinruleTitle,
        body: (l) => l.tutOrigWinruleBody,
        button: (l) => l.tutBtnTry,
      ),
      // 9 — win by placing (right column [2,5,8], target 8)
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [b(5), null, g(4), null, b(6), g(2), null, null, null],
        hand: [1, 3, 5, 6],
        target: 8,
        highlight: 8,
        winLine: [2, 5, 8],
        demoMode: TutMode.win,
        title: (l) => l.tutOrigDemowinTitle,
        body: (l) => l.tutOrigDemowinBody,
        hint: (l) => l.tutHintWinPlace,
      ),
      // 10 — win by capturing (eat B5 at 4, diagonal [0,4,8])
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [g(6), null, g(1), null, b(5), null, null, g(2), g(4)],
        hand: [3, 4, 5, 6],
        target: 4,
        highlight: 4,
        winLine: [0, 4, 8],
        demoMode: TutMode.eatwin,
        title: (l) => l.tutOrigDemoeatwinTitle,
        body: (l) => l.tutOrigDemoeatwinBody,
        hint: (l) => l.tutHintEatwin,
      ),
      // 11 — done
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6)],
        title: (l) => l.tutOrigDoneTitle,
        body: (l) => l.tutOrigDoneBody,
        button: (l) => l.tutBtnFinish,
      ),
    ];

/// The Futuristic · Bonanza tutorial's 10 steps (spec §4). Extends the Original engine with a deal
/// showcase, a bordeaux hand rail, a cross-link to Original, and a forced-loss demo. Text via ARB.
List<TutorialStep> bonanzaTutorialSteps() => [
      // 1 — welcome
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6), b(4)],
        title: (l) => l.tutBonWelcomeTitle,
        body: (l) => l.tutBonWelcomeBody,
        button: (l) => l.tutBtnStart,
      ),
      // 2 — first the basics (+ cross-link to Original)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(4), g(2), g(6)],
        title: (l) => l.tutBonOriginalTitle,
        body: (l) => l.tutBonOriginalBody,
        button: (l) => l.tutBonBtnKnown,
        secondary: (l) => l.tutBonBtnLearnOriginal,
      ),
      // 3 — the hook
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(5), b(5)],
        title: (l) => l.tutBonHookTitle,
        body: (l) => l.tutBonHookBody,
        button: (l) => l.tutBonBtnCurious,
      ),
      // 4 — it starts with a number (badge "Number: ?")
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        infoBadge: '?',
        title: (l) => l.tutBonRandomTitle,
        body: (l) => l.tutBonRandomBody,
        button: (l) => l.tutBtnNext,
      ),
      // 5 — the rest are the opponent's
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(3), b(6)],
        title: (l) => l.tutBonLuckTitle,
        body: (l) => l.tutBonLuckBody,
        button: (l) => l.tutBonBtnShow,
      ),
      // 6 — deal showcase (number 4, gold then bordeaux)
      TutorialStep(
        kind: TutKind.deal,
        futuristic: true,
        dealNumber: 4,
        dealGold: [2, 4, 5, 6],
        dealBord: [3, 4],
        title: (l) => l.tutBonDealTitle,
        body: (l) => l.tutBonDealBody,
        button: (l) => l.tutBtnOk,
      ),
      // 7 — win with your own (gold) pawn: complete the bottom row [6,7,8] at cell 7
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [b(5), null, b(6), null, null, null, g(2), null, g(4)],
        hand: [5, 6],
        target: 7,
        highlight: 7,
        winLine: [6, 7, 8],
        demoMode: TutMode.win,
        title: (l) => l.tutBonDemowinTitle,
        body: (l) => l.tutBonDemowinBody,
        hint: (l) => l.tutHintWinPlace,
        railLabel: (l) => l.tutBonRailGold,
      ),
      // 8 — the warning
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [b(1), b(2)],
        title: (l) => l.tutBonWarningTitle,
        body: (l) => l.tutBonWarningBody,
        button: (l) => l.tutBonBtnWhy,
      ),
      // 9 — forced loss: only empties are 1 & 5; a bordeaux pawn on either completes an opponent line
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        fcells: [b(5), null, b(6), g(5), g(6), null, b(3), g(4), b(4)],
        hand: [1, 2],
        handOwner: 1,
        highlights: [1, 5],
        loseMap: {
          1: [0, 1, 2],
          5: [2, 5, 8],
        },
        demoMode: TutMode.lose,
        title: (l) => l.tutBonDemoloseTitle,
        body: (l) => l.tutBonDemoloseBody,
        hint: (l) => l.tutBonHintLose,
        railLabel: (l) => l.tutBonRailBord,
      ),
      // 10 — done
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6), b(6)],
        title: (l) => l.tutBonDoneTitle,
        body: (l) => l.tutBonDoneBody,
        button: (l) => l.tutBtnFinish,
      ),
    ];

/// A 16-cell (4×4) Morph board with our gold pawns pre-placed at the given `index → value` pairs.
List<TutPawn?> _morphBoard(Map<int, int> gold) {
  final cells = List<TutPawn?>.filled(16, null);
  gold.forEach((i, v) => cells[i] = g(v));
  return cells;
}

/// The Futuristic · Morph tutorial's 12 steps (spec §4). Adds a 4×4 board, shape-completion (I/L/Z,
/// axis + diagonal, mirror) with a gold shape-glow win, and a two-pawns-per-turn demo. Text via ARB.
List<TutorialStep> morphTutorialSteps() => [
      // 1 — welcome
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6), g(2)],
        title: (l) => l.tutMorphWelcomeTitle,
        body: (l) => l.tutMorphWelcomeBody,
        button: (l) => l.tutBtnStart,
      ),
      // 2 — first the basics (+ cross-link to Original)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(4), g(2), g(6)],
        title: (l) => l.tutMorphOriginalTitle,
        body: (l) => l.tutMorphOriginalBody,
        button: (l) => l.tutBonBtnKnown,
        secondary: (l) => l.tutBonBtnLearnOriginal,
      ),
      // 3 — but winning…
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(5)],
        title: (l) => l.tutMorphMysteryTitle,
        body: (l) => l.tutMorphMysteryBody,
        button: (l) => l.tutMorphBtnHow,
      ),
      // 4 — four pawns, one shape (I / L / Z icons)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        shapeIcons: const [
          MorphIcon(cols: 2, rows: 4, filled: [0, 2, 4, 6]), // I (vertical)
          MorphIcon(cols: 2, rows: 3, filled: [0, 2, 4, 5]), // L
          MorphIcon(cols: 3, rows: 2, filled: [1, 2, 3, 4]), // Z
        ],
        title: (l) => l.tutMorphShapesTitle,
        body: (l) => l.tutMorphShapesBody,
        button: (l) => l.tutBtnNext,
      ),
      // 5 — that's why you move twice (two pairs)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(2), g(2), g(5), g(5)],
        title: (l) => l.tutMorphTwomovesTitle,
        body: (l) => l.tutMorphTwomovesBody,
        button: (l) => l.tutBtnOk,
      ),
      // 6 — vertical I (single target 13 → column [1,5,9,13])
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        gridCols: 4,
        gridRows: 4,
        fcells: _morphBoard({1: 2, 5: 3, 9: 5}),
        hand: [2, 4, 6],
        targets: [13],
        winShape: [1, 5, 9, 13],
        shapeName: 'I',
        demoMode: TutMode.shape,
        title: (l) => l.tutMorphIvTitle,
        body: (l) => l.tutMorphIvBody,
        hint: (l) => l.tutHintWinPlace,
      ),
      // 7 — horizontal I, TWO pawns this turn (targets 6 & 7 → row [4,5,6,7])
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        gridCols: 4,
        gridRows: 4,
        fcells: _morphBoard({4: 2, 5: 3}),
        hand: [4, 5, 6, 1],
        targets: [6, 7],
        winShape: [4, 5, 6, 7],
        shapeName: 'I',
        demoMode: TutMode.shape,
        title: (l) => l.tutMorphIhTitle,
        body: (l) => l.tutMorphIhBody,
        hint: (l) => l.tutMorphHintFirst,
      ),
      // 8 — shapes can be slanted (diagonal staircase icon)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        shapeIcons: const [
          MorphIcon(cols: 4, rows: 4, filled: [0, 5, 10, 15]), // diagonal I
        ],
        title: (l) => l.tutMorphDiagTitle,
        body: (l) => l.tutMorphDiagBody,
        button: (l) => l.tutBonBtnShow,
      ),
      // 9 — diagonal Z (single target 3 → [1,3,4,6]) — Deniz-verified
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        gridCols: 4,
        gridRows: 4,
        fcells: _morphBoard({1: 3, 4: 2, 6: 3}),
        hand: [2, 4, 5],
        targets: [3],
        winShape: [1, 3, 4, 6],
        shapeName: 'Z',
        demoMode: TutMode.shape,
        title: (l) => l.tutMorphZTitle,
        body: (l) => l.tutMorphZBody,
        hint: (l) => l.tutHintWinPlace,
      ),
      // 10 — the mirror counts (L + mirrored-L icons)
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        shapeIcons: const [
          MorphIcon(cols: 2, rows: 3, filled: [0, 2, 4, 5]), // L
          MorphIcon(cols: 2, rows: 3, filled: [1, 3, 5, 4]), // mirrored L
        ],
        title: (l) => l.tutMorphMirrorTitle,
        body: (l) => l.tutMorphMirrorBody,
        button: (l) => l.tutMorphBtnOneMore,
      ),
      // 11 — mirrored/diagonal L (single target 13 → [0,5,10,13]) — Deniz-verified
      TutorialStep(
        kind: TutKind.demo,
        futuristic: true,
        gridCols: 4,
        gridRows: 4,
        fcells: _morphBoard({0: 2, 5: 3, 10: 6}),
        hand: [3, 5, 6],
        targets: [13],
        winShape: [0, 5, 10, 13],
        shapeName: 'L',
        demoMode: TutMode.shape,
        title: (l) => l.tutMorphLTitle,
        body: (l) => l.tutMorphLBody,
        hint: (l) => l.tutHintWinPlace,
      ),
      // 12 — done
      TutorialStep(
        kind: TutKind.info,
        futuristic: true,
        bigMedallions: [g(6)],
        title: (l) => l.tutMorphDoneTitle,
        body: (l) => l.tutMorphDoneBody,
        button: (l) => l.tutBtnFinish,
      ),
    ];
