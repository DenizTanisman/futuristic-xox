// Rule-parity tests for the pure-Dart mock backend. Run with `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/src/game/dart_game_api.dart';
import 'package:futuristic_xox/src/game/geometry.dart';
import 'package:futuristic_xox/src/models/game_models.dart';

void main() {
  group('geometry', () {
    test('line triples count 3x3 / 4x4', () {
      expect(lineTriples(3, 3).length, 8);
      expect(lineTriples(4, 4).length, 24);
    });

    test('Morph placements are 180-degree symmetric (no top-left dropout)', () {
      // Regression: the diagonal frame must be normalized before sliding, else top-left diagonal
      // placements are silently dropped (the screenshot Z/L bug).
      String canon(List<int> c) => (List.of(c)..sort()).toString();
      for (final n in [4, 5]) {
        final last = n * n - 1;
        for (var sh = 0; sh < 3; sh++) {
          final ps = morphPlacementsForShape(n, n, sh);
          final set = ps.map(canon).toSet();
          for (final p in ps) {
            final rot = p.map((i) => last - i).toList();
            expect(set.contains(canon(rot)), isTrue,
                reason: 'shape $sh on ${n}x$n: $p has no 180° mirror');
          }
        }
      }
    });

    test('Morph Z includes the screenshot diagonal pattern [0,2,6,8] on 5x5', () {
      String canon(List<int> c) => (List.of(c)..sort()).toString();
      final z = morphPlacementsForShape(5, 5, 2).map(canon).toSet();
      expect(z.contains(canon([0, 2, 6, 8])), isTrue);
    });

    test('Morph placements INCLUDE diagonal (staircase) forms on 4x4', () {
      // Diagonals are part of Morph (the §5 exclusion was reversed in play-testing, §13.1).
      final iShape = morphPlacementsForShape(4, 4, 0); // I
      bool has(List<int> s) {
        final t = (List.of(s)..sort()).toString();
        return iShape.any((p) => (List.of(p)..sort()).toString() == t);
      }
      expect(iShape, isNotEmpty);
      expect(has([0, 1, 2, 3]), isTrue, reason: 'horizontal I');
      expect(has([0, 4, 8, 12]), isTrue, reason: 'vertical I');
      expect(has([0, 5, 10, 15]), isTrue, reason: 'main-diagonal (staircase) I');
      expect(has([3, 6, 9, 12]), isTrue, reason: 'anti-diagonal (staircase) I');
    });
  });

  group('capture & legality', () {
    test('strict-greater capture; equal/own illegal', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      expect(api.humanMove(color: 0, value: 3, cell: 0).applied, isTrue); // P0 colour 0
      final equalTry = api.humanMove(color: 1, value: 3, cell: 0); // P1 equal value → illegal
      expect(equalTry.applied, isFalse);
      final cap = api.humanMove(color: 1, value: 4, cell: 0); // P1 captures with 4
      expect(cap.applied, isTrue);
      expect(cap.captured, isTrue);
      expect(cap.snapshot.board[0].owner, 1);
      expect(cap.snapshot.board[0].value, 4);
    });

    test('illegal move leaves state and turn unchanged', () {
      final api = DartGameApi();
      final before = api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      final r = api.humanMove(color: 0, value: 9, cell: 0); // 9 not in hand (1..6)
      expect(r.applied, isFalse);
      expect(r.snapshot.turn, before.turn);
    });
  });

  group('win & draw', () {
    test('three in a row wins', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      api.humanMove(color: 0, value: 1, cell: 0);
      api.humanMove(color: 1, value: 1, cell: 3);
      api.humanMove(color: 0, value: 2, cell: 1);
      api.humanMove(color: 1, value: 2, cell: 4);
      final win = api.humanMove(color: 0, value: 3, cell: 2);
      expect(win.snapshot.outcome, Outcome.win0);
    });

    test('CLASSIC diagonals win (both directions)', () {
      // Main diagonal 0,4,8.
      var api = DartGameApi();
      api.newGame(mode: Mode4.classic, rows: 3, cols: 3);
      for (final c in [0, 1, 4, 2]) {
        api.humanMove(cell: c);
      }
      expect(api.humanMove(cell: 8).snapshot.outcome, Outcome.win0);

      // Anti-diagonal 2,4,6.
      api = DartGameApi();
      api.newGame(mode: Mode4.classic, rows: 3, cols: 3);
      for (final c in [2, 0, 4, 1]) {
        api.humanMove(cell: c);
      }
      expect(api.humanMove(cell: 6).snapshot.outcome, Outcome.win0);
    });

    test('valued diagonal wins on 4x4 (0,5,10)', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 4, cols: 4);
      api.humanMove(color: 0, value: 1, cell: 0);
      api.humanMove(color: 1, value: 1, cell: 1);
      api.humanMove(color: 0, value: 2, cell: 5);
      api.humanMove(color: 1, value: 2, cell: 2);
      expect(api.humanMove(color: 0, value: 3, cell: 10).snapshot.outcome, Outcome.win0);
    });
  });

  group('morph', () {
    test('a single shape is chosen and shown', () {
      final api = DartGameApi();
      final s = api.newGame(mode: Mode4.morph, rows: 4, cols: 4, seed: 1);
      expect(s.morphShape, isNotNull);
      expect(s.movesLeftInTurn, 2);
    });

    test('diagonal (staircase) I completion wins', () {
      // Find a seed whose chosen shape is I.
      int? seed;
      for (var s = 0; s < 60; s++) {
        final snap = DartGameApi().newGame(mode: Mode4.morph, rows: 4, cols: 4, seed: s);
        if (snap.morphShape == MorphShape.i) {
          seed = s;
          break;
        }
      }
      expect(seed, isNotNull);
      final api = DartGameApi();
      api.newGame(mode: Mode4.morph, rows: 4, cols: 4, seed: seed!);
      const target = [0, 5, 10, 15]; // main diagonal
      final park = [for (var c = 0; c < 16; c++) if (!target.contains(c)) c];
      api.humanMove(color: 0, value: 1, cell: target[0]);
      api.humanMove(color: 0, value: 1, cell: target[1]);
      api.humanMove(color: 1, value: 1, cell: park[0]);
      api.humanMove(color: 1, value: 1, cell: park[1]);
      api.humanMove(color: 0, value: 2, cell: target[2]);
      final r = api.humanMove(color: 0, value: 2, cell: target[3]);
      expect(r.snapshot.outcome, Outcome.win0);
    });

    test('two moves per turn; same player continues then turn flips', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.morph, rows: 4, cols: 4);
      final r1 = api.humanMove(color: 0, value: 1, cell: 5);
      expect(r1.snapshot.turn, 0);
      expect(r1.snapshot.movesLeftInTurn, 1);
      final r2 = api.humanMove(color: 0, value: 1, cell: 6);
      expect(r2.snapshot.turn, 1);
      expect(r2.snapshot.movesLeftInTurn, 2);
    });
  });

  group('bonanza', () {
    test('hands may hold opponent-coloured pawns; pool conserved; ownCount in range', () {
      for (var seed = 0; seed < 30; seed++) {
        final api = DartGameApi();
        final s = api.newGame(mode: Mode4.bonanza, rows: 3, cols: 3, seed: seed);
        expect(s.hand0.length, 6);
        expect(s.hand1.length, 6);
        expect(s.bonanzaOwnCount, inInclusiveRange(0, 6));

        // Combined pool = two copies of 1..6 (one per colour).
        int countColor(int c) =>
            s.hand0.where((h) => h.color == c).length + s.hand1.where((h) => h.color == c).length;
        expect(countColor(0), 6);
        expect(countColor(1), 6);
      }
    });

    test('across seeds, player 0 sometimes holds opponent-coloured pawns', () {
      var sawOpponentColor = false;
      for (var seed = 0; seed < 30; seed++) {
        final api = DartGameApi();
        final s = api.newGame(mode: Mode4.bonanza, rows: 3, cols: 3, seed: seed);
        if (s.hand0.any((h) => h.color == 1)) {
          sawOpponentColor = true;
          break;
        }
      }
      expect(sawOpponentColor, isTrue);
    });
  });

  group('completing-cell hint', () {
    test('valued line: the third cell of a 2-in-a-row is flagged', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      api.humanMove(color: 0, value: 1, cell: 0);
      api.humanMove(color: 1, value: 1, cell: 8);
      api.humanMove(color: 0, value: 2, cell: 1);
      api.humanMove(color: 1, value: 2, cell: 7);
      // Back to player 0: cell 2 completes the top row 0,1,2.
      expect(api.completingCells(), contains(2));
    });

    test('morph: the 4th cell that completes the chosen shape is flagged', () {
      final api = DartGameApi();
      final s0 = api.newGame(mode: Mode4.morph, rows: 5, cols: 5, seed: 9);
      final target = morphPlacementsForShape(5, 5, MorphShape.values.indexOf(s0.morphShape!)).first;
      final park = [for (var c = 0; c < 25; c++) if (!target.contains(c)) c];
      api.humanMove(color: 0, value: 1, cell: target[0]);
      api.humanMove(color: 0, value: 1, cell: target[1]);
      api.humanMove(color: 1, value: 1, cell: park[0]);
      api.humanMove(color: 1, value: 1, cell: park[1]);
      api.humanMove(color: 0, value: 2, cell: target[2]);
      // Player 0 now owns 3 of the 4 shape cells; target[3] should be flagged as completing.
      expect(api.completingCells(), contains(target[3]));
    });
  });

  group('AI', () {
    test('easy plays only legal moves and games terminate (all modes)', () async {
      for (final mode in Mode4.values) {
        final api = DartGameApi();
        final grid = mode == Mode4.morph ? 4 : 3;
        var s = api.newGame(mode: mode, rows: grid, cols: grid, seed: 7);
        var guard = 0;
        while (s.outcome == Outcome.inProgress && guard++ < 300) {
          final r = await api.aiMove(Difficulty.easy);
          expect(r.applied, isTrue);
          s = r.snapshot;
        }
        expect(s.outcome, isNot(Outcome.inProgress));
      }
    });

    test('hard vs hard on Classic 3x3 is a draw (perfect play)', () async {
      final api = DartGameApi();
      var s = api.newGame(mode: Mode4.classic, rows: 3, cols: 3, seed: 0);
      var guard = 0;
      while (s.outcome == Outcome.inProgress && guard++ < 20) {
        final r = await api.aiMove(Difficulty.hard);
        s = r.snapshot;
      }
      expect(s.outcome, Outcome.draw);
    });
  });
}
