import '../../l10n/app_localizations.dart';

/// A localized-text selector: resolves a string from [AppLocalizations] (keys live in ARB, never as
/// literals — spec §5).
typedef L10nText = String Function(AppLocalizations l);

/// The kind of tutorial step (spec §0).
enum TutKind { info, loop, triple, demo }

/// A Classic mark.
enum Mark { x, o }

/// The decorative visual for an `info` step.
enum InfoVisual { none, bigX, bigXO }

/// Demo interaction mode for Futuristic (Original) tutorials (spec §3).
enum TutMode { free, eat, win, eatwin }

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
