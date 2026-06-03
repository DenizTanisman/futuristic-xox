// Widget smoke test: the app builds and the entry → setup → game navigation renders a board.
// Run with `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/main.dart';

void main() {
  testWidgets('entry screen shows the Classic/Futuristic split', (tester) async {
    await tester.pumpWidget(const FuturisticXoxApp());
    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Futuristic'), findsOneWidget);
    expect(find.text('FUTURISTIC XOX'), findsOneWidget);
  });

  testWidgets('Classic flow reaches a rendered board', (tester) async {
    await tester.pumpWidget(const FuturisticXoxApp());

    await tester.tap(find.text('Classic'));
    await tester.pumpAndSettle();
    // Setup screen.
    expect(find.text('DIFFICULTY'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    // Game screen: a board grid is present. Human (player 0) moves first, so no AI timer is pending.
    expect(find.byType(GridView), findsOneWidget);
  });
}
