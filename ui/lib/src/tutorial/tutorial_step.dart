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
