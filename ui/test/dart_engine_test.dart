// Rule-parity tests for the pure-Dart mock backend (mirrors the Rust engine tests). Run with
// `flutter test` once the Flutter SDK is installed.

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

    test('morph placements exist and exclude the pure diagonal on 4x4', () {
      final ps = morphPlacements(4, 4);
      expect(ps, isNotEmpty);
      final diag = [0, 5, 10, 15]..sort();
      expect(ps.any((p) => (List.of(p)..sort()).toString() == diag.toString()), isFalse);
    });
  });

  group('capture & legality', () {
    test('strict-greater capture; equal/own illegal', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      // P0 places a 3 at cell 0.
      expect(api.humanMove(value: 3, cell: 0).applied, isTrue);
      // P1 tries to capture with equal value 3 → illegal.
      final equalTry = api.humanMove(value: 3, cell: 0);
      expect(equalTry.applied, isFalse);
      expect(equalTry.illegalReason, isNotNull);
      // P1 captures with 4 → legal, reported as capture.
      final cap = api.humanMove(value: 4, cell: 0);
      expect(cap.applied, isTrue);
      expect(cap.captured, isTrue);
      expect(cap.snapshot.board[0].owner, 1);
      expect(cap.snapshot.board[0].value, 4);
    });

    test('illegal move leaves state and turn unchanged', () {
      final api = DartGameApi();
      final before = api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      final r = api.humanMove(value: 9, cell: 0); // 9 not in hand (1..6)
      expect(r.applied, isFalse);
      expect(r.snapshot.turn, before.turn);
    });
  });

  group('win & draw', () {
    test('three in a row wins', () {
      final api = DartGameApi();
      api.newGame(mode: Mode4.original, rows: 3, cols: 3);
      api.humanMove(value: 1, cell: 0); // P0
      api.humanMove(value: 1, cell: 3); // P1
      api.humanMove(value: 2, cell: 1); // P0
      api.humanMove(value: 2, cell: 4); // P1
      final win = api.humanMove(value: 3, cell: 2); // P0 completes top row
      expect(win.snapshot.outcome, Outcome.win0);
    });
  });

  group('morph', () {
    test('two moves per turn; same player continues then turn flips', () {
      final api = DartGameApi();
      final s0 = api.newGame(mode: Mode4.morph, rows: 4, cols: 4);
      expect(s0.movesLeftInTurn, 2);
      final r1 = api.humanMove(value: 1, cell: 5);
      expect(r1.snapshot.turn, 0);
      expect(r1.snapshot.movesLeftInTurn, 1);
      final r2 = api.humanMove(value: 1, cell: 6);
      expect(r2.snapshot.turn, 1);
      expect(r2.snapshot.movesLeftInTurn, 2);
    });
  });

  group('mock AI', () {
    test('hard AI plays only legal moves and games terminate', () async {
      for (final mode in Mode4.values) {
        final api = DartGameApi();
        final grid = mode == Mode4.morph ? 4 : 3;
        var s = api.newGame(mode: mode, rows: grid, cols: grid);
        var guard = 0;
        while (s.outcome == Outcome.inProgress && guard++ < 200) {
          final r = await api.aiMove(Difficulty.hard);
          expect(r.applied, isTrue);
          s = r.snapshot;
        }
        expect(s.outcome, isNot(Outcome.inProgress));
      }
    });
  });
}
