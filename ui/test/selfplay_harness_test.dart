// Tests for the dev-only self-play harness driver + scrub view-model. Run with `flutter test`.
// Search depths here are kept small (test speed); the production caps live in `depthCapFor`.

import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/src/dev/selfplay_harness/selfplay_driver.dart';
import 'package:futuristic_xox/src/dev/selfplay_harness/selfplay_models.dart';
import 'package:futuristic_xox/src/game/dart_game_api.dart';
import 'package:futuristic_xox/src/models/game_models.dart';

int _seedForShape(int grid, MorphShape shape) {
  for (var s = 0; s < 1000; s++) {
    if (DartGameApi().newGame(mode: Mode4.morph, rows: grid, cols: grid, seed: s).morphShape ==
        shape) {
      return s;
    }
  }
  return 0;
}

/// Build a config with a legal first move and a (small) test depth.
SelfPlayConfig configFor(Mode4 mode, int grid,
    {int seed = 0, MorphShape shape = MorphShape.i, required int depth}) {
  final eff = mode == Mode4.morph ? _seedForShape(grid, shape) : seed;
  final api = DartGameApi();
  final snap = api.newGame(mode: mode, rows: grid, cols: grid, seed: eff);
  if (!mode.valued) {
    return SelfPlayConfig(
        mode: mode,
        rows: grid,
        cols: grid,
        seed: eff,
        firstColor: null,
        firstValue: null,
        firstCell: 0,
        maxDepth: depth);
  }
  final h = snap.hand0.first;
  final cells = api.legalCells(color: h.color, value: h.value);
  return SelfPlayConfig(
      mode: mode,
      rows: grid,
      cols: grid,
      seed: eff,
      firstColor: h.color,
      firstValue: h.value,
      firstCell: cells.first,
      maxDepth: depth);
}

List<SelfPlayFrame> run(SelfPlayConfig c) {
  final out = <SelfPlayFrame>[];
  produceSelfPlay(c, out.add);
  return out;
}

String canon(SelfPlayFrame f) {
  final b = f.snapshot.board.map((c) => c.empty ? '.' : '${c.owner}:${c.value}').join(',');
  return '${f.lastMoveCell}|${f.snapshot.turn}|${f.snapshot.outcome}|$b';
}

SelfPlayFrame frame(int turn, {int? cell}) => SelfPlayFrame(
      snapshot: Snapshot(
        rows: 3,
        cols: 3,
        board: List.generate(9, (_) => const CellView.empty()),
        hand0: const [],
        hand1: const [],
        turn: turn,
        movesLeftInTurn: 1,
        outcome: Outcome.inProgress,
        bonanzaOwnCount: null,
        morphShape: null,
        winningCells: const [],
      ),
      lastMoveCell: cell,
    );

void main() {
  group('driver reaches a terminal position (each mode/grid)', () {
    final cases = <(Mode4, int, int)>[
      (Mode4.classic, 3, 9),
      (Mode4.classic, 4, 6),
      (Mode4.original, 3, 6),
      (Mode4.original, 4, 4),
      (Mode4.bonanza, 3, 6),
      (Mode4.bonanza, 4, 4),
      (Mode4.morph, 4, 3),
      (Mode4.morph, 5, 2),
    ];
    for (final (mode, grid, depth) in cases) {
      test('$mode ${grid}x$grid', () {
        final frames = run(configFor(mode, grid, depth: depth));
        expect(frames, isNotEmpty);
        expect(frames.last.snapshot.outcome, isNot(Outcome.inProgress),
            reason: 'self-play must end in win or draw');
      });
    }
  });

  test('determinism: same setup → identical record twice', () {
    final c = configFor(Mode4.original, 3, depth: 6);
    final a = run(c).map(canon).toList();
    final b = run(c).map(canon).toList();
    expect(a, b);

    final cb = configFor(Mode4.bonanza, 3, seed: 7, depth: 6);
    expect(run(cb).map(canon).toList(), run(cb).map(canon).toList());
  });

  test('first-move legality: an illegal first move yields no frames', () {
    // Value 99 is never in hand → humanMove is rejected → producer bails (no frames).
    const bad = SelfPlayConfig(
        mode: Mode4.original,
        rows: 3,
        cols: 3,
        seed: 0,
        firstColor: 0,
        firstValue: 99,
        firstCell: 0,
        maxDepth: 4);
    expect(run(bad), isEmpty);
  });

  test('Bonanza: same seed reproduces the same initial hands', () {
    final a = run(configFor(Mode4.bonanza, 3, seed: 11, depth: 4)).first.snapshot;
    final b = run(configFor(Mode4.bonanza, 3, seed: 11, depth: 4)).first.snapshot;
    String hand(List<HandPawnView> h) => h.map((e) => '${e.color}:${e.value}').join(',');
    // Frame 0 is after the human's first move; hand1 is untouched, hand0 lost one pawn — both stable.
    expect(hand(a.hand1), hand(b.hand1));
    expect(hand(a.hand0), hand(b.hand0));
  });

  test('Morph: chosen shape is the target and the game completes', () {
    for (final shape in MorphShape.values) {
      final frames = run(configFor(Mode4.morph, 4, shape: shape, depth: 3));
      expect(frames.first.snapshot.morphShape, shape,
          reason: 'frame 0 must carry the chosen shape');
      expect(frames.last.snapshot.outcome, isNot(Outcome.inProgress));
    }
  });

  group('scrub view-model', () {
    test('current clamps and starts at 0', () {
      final m = SelfPlayViewModel();
      expect(m.current, isNull);
      m.addFrame(frame(0));
      m.addFrame(frame(1));
      expect(m.viewIndex, 0);
      expect(m.current!.snapshot.turn, 0);
    });

    test('tick auto-advances only while autoPlay and frames remain', () {
      final m = SelfPlayViewModel()
        ..addFrame(frame(0))
        ..addFrame(frame(1))
        ..addFrame(frame(0));
      m.tick();
      expect(m.viewIndex, 1);
      m.tick();
      expect(m.viewIndex, 2);
      m.tick(); // at end → no move
      expect(m.viewIndex, 2);
    });

    test('next/prev disable autoPlay and clamp', () {
      final m = SelfPlayViewModel()
        ..addFrame(frame(0))
        ..addFrame(frame(1));
      m.next();
      expect(m.autoPlay, isFalse);
      expect(m.viewIndex, 1);
      m.next(); // clamp at last
      expect(m.viewIndex, 1);
      m.prev();
      expect(m.viewIndex, 0);
      m.prev(); // clamp at 0
      expect(m.viewIndex, 0);
      expect(m.autoPlay, isFalse);
    });

    test('replay resets to 0 and re-enables autoPlay (no recompute)', () {
      final m = SelfPlayViewModel()
        ..addFrame(frame(0))
        ..addFrame(frame(1));
      m.next();
      final before = m.frames.length;
      m.replay();
      expect(m.viewIndex, 0);
      expect(m.autoPlay, isTrue);
      expect(m.frames.length, before, reason: 'replay reuses the record, no recompute');
    });

    test('tick does nothing after a manual scrub froze autoPlay', () {
      final m = SelfPlayViewModel()
        ..addFrame(frame(0))
        ..addFrame(frame(1))
        ..addFrame(frame(0));
      m.next(); // index 1, autoPlay off
      m.tick();
      expect(m.viewIndex, 1, reason: 'autoPlay is off, tick must not advance');
    });
  });
}
