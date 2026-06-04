// Widget smoke test: the app builds and the entry → setup → game navigation renders a board.
// Run with `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/main.dart';

void main() {
  testWidgets('entry screen shows the Classic/Futuristic split', (tester) async {
    await tester.pumpWidget(const FuturisticXoxApp());
    await tester.pump(const Duration(seconds: 1)); // entrance animation
    expect(find.text('CLASSIC'), findsOneWidget);
    expect(find.text('FUTURISTIC'), findsOneWidget);
  });

  testWidgets('Classic flow reaches a rendered board', (tester) async {
    // The entry + game screens have looping animations (sheen, shimmer, pulse), so pumpAndSettle
    // would never settle — pump fixed frames instead.
    await tester.pumpWidget(const FuturisticXoxApp());
    await tester.pump(const Duration(seconds: 1)); // entrance

    await tester.tap(find.text('CLASSIC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // nav to setup
    expect(find.text('DIFFICULTY'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(GridView), findsOneWidget);
  });
}
