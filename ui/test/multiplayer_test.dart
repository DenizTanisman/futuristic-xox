// Offline multiplayer + PlayerController turn-loop tests. Run with `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/main.dart';
import 'package:futuristic_xox/src/app/app_controllers.dart';
import 'package:futuristic_xox/src/controllers/game_controller.dart';
import 'package:futuristic_xox/src/game/dart_game_api.dart';
import 'package:futuristic_xox/src/game/player_controller.dart';
import 'package:futuristic_xox/src/models/game_models.dart';

const _strings = GameStrings(
  capture: 'Capture!',
  noSecondMove: 'No second move',
  selectPawnFirst: 'Select a pawn first',
  draw: 'Draw',
  wins: _wins,
);
String _wins(String name) => '$name wins!';

Widget _app() => FuturisticXoxApp(
      locale: LocaleController(const Locale('en')),
      theme: ThemeController(ThemeMode.dark),
    );

GameController mp(Mode4 mode, int grid) => GameController(
      api: DartGameApi(),
      mode: mode,
      rows: grid,
      cols: grid,
      players: [HumanController('Player 1'), HumanController('Player 2')],
      strings: _strings,
      seed: 1,
    );

void main() {
  group('offline multiplayer (two humans)', () {
    test('turns alternate P1 -> P2, no AI runs', () async {
      final c = mp(Mode4.original, 3);
      expect(c.snapshot.turn, 0);
      expect(c.activePlayer.label, 'Player 1');
      expect(c.isHumanTurn, isTrue);

      c.selectPawn(0, 1);
      await c.onCellTap(0);

      expect(c.snapshot.turn, 1, reason: 'handed to top seat');
      expect(c.activePlayer.label, 'Player 2');
      expect(c.isHumanTurn, isTrue, reason: 'seat 2 is also human');
      expect(c.aiThinking, isFalse, reason: 'no AI in offline multiplayer');

      c.selectPawn(1, 1);
      await c.onCellTap(1);
      expect(c.snapshot.turn, 0, reason: 'back to bottom seat');
    });

    test('Morph keeps two-moves-per-turn per human seat', () async {
      final c = mp(Mode4.morph, 4);
      expect(c.snapshot.movesLeftInTurn, 2);

      c.selectPawn(0, 1);
      await c.onCellTap(5);
      expect(c.snapshot.turn, 0, reason: 'still P1 mid-turn');
      expect(c.snapshot.movesLeftInTurn, 1);

      // The selection persists (a second value-1 pawn remains), so just place again.
      await c.onCellTap(6);
      expect(c.snapshot.turn, 1, reason: 'turn passes to P2 after two moves');
      expect(c.snapshot.movesLeftInTurn, 2);
    });
  });

  group('single-player (human vs AI) regression', () {
    test('AI auto-moves after the human, returning the turn', () async {
      final c = GameController(
        api: DartGameApi(),
        mode: Mode4.classic,
        rows: 3,
        cols: 3,
        players: [HumanController('You'), AiController(Difficulty.hard, label: 'Computer')],
        strings: _strings,
        seed: 1,
      );
      expect(c.playerAt(1).isHuman, isFalse);
      await c.onCellTap(0); // Classic: no pawn selection needed
      expect(c.snapshot.turn, 0, reason: 'AI took its turn automatically');
      expect(c.aiThinking, isFalse);
      // The board now has two pawns (human + AI).
      final filled = c.snapshot.board.where((cell) => !cell.empty).length;
      expect(filled, 2);
    });
  });

  group('setup toggle', () {
    testWidgets('Offline Multiplayer dims the difficulty selector', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump(const Duration(seconds: 1)); // entrance animation
      await tester.tap(find.text('CLASSIC'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // nav to setup

      AnimatedOpacity difficultyOpacity() => tester.widget<AnimatedOpacity>(
            find.ancestor(of: find.text('Easy'), matching: find.byType(AnimatedOpacity)),
          );
      expect(difficultyOpacity().opacity, 1.0);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(difficultyOpacity().opacity, 0.34, reason: 'difficulty dimmed when MP on');
    });
  });
}
