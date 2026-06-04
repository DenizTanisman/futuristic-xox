// Classic tutorial engine tests. Run with `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/l10n/app_localizations.dart';
import 'package:futuristic_xox/main.dart';
import 'package:futuristic_xox/src/app/app_controllers.dart';
import 'package:futuristic_xox/src/tutorial/tutorial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget home) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Classic auto-shows its tutorial on first entry, then setup afterwards', (tester) async {
    await tester.pumpWidget(FuturisticXoxApp(
      locale: LocaleController(const Locale('en')),
      theme: ThemeController(ThemeMode.dark),
      tutorialProgress: TutorialProgress({}), // nothing seen yet
    ));
    await tester.pump(const Duration(seconds: 1)); // entrance
    await tester.tap(find.text('CLASSIC'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // First entry → tutorial, not the setup screen.
    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsNothing);
  });

  testWidgets('skip from the first step exits immediately', (tester) async {
    var exited = false;
    // Step 1 (info) has no loop timer, so this is safe without a Navigator.
    await tester.pumpWidget(_wrap(ClassicTutorialScreen(onExit: () => exited = true)));
    await tester.pump();
    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(exited, isTrue);
  });

  testWidgets('Original tutorial renders (futuristic) and advances', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (ctx) => Center(
        child: TextButton(
          onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => OriginalTutorialScreen(onExit: () => Navigator.of(ctx).pop()),
          )),
          child: const Text('go'),
        ),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Futuristic'), findsOneWidget);

    await tester.tap(find.text("Let's begin"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Now there are numbers'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('Bonanza tutorial reaches the deal step with the Number badge', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (ctx) => Center(
        child: TextButton(
          onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => BonanzaTutorialScreen(onExit: () => Navigator.of(ctx).pop()),
          )),
          child: const Text('go'),
        ),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Bonanza'), findsOneWidget);

    // Advance through the intro info steps to the deal showcase (steps 1→6).
    for (final btn in const ["Let's begin", 'I know it, continue', "I'm curious", 'Continue', 'Show me']) {
      await tester.tap(find.text(btn));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Number: 4'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('advances through steps and Skip pops cleanly from a loop step (no leaked timer)',
      (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (ctx) => Center(
        child: TextButton(
          onPressed: () => Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => ClassicTutorialScreen(onExit: () => Navigator.of(ctx).pop()),
          )),
          child: const Text('go'),
        ),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);

    // Advance info → loop step (which starts a periodic gif timer).
    await tester.tap(find.text("Let's begin"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Your turn to start'), findsOneWidget);

    // Skip from the loop step → pop disposes the screen → timer is cancelled (no pending timer).
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // let the pop transition finish + dispose
    expect(find.text('go'), findsOneWidget);
    expect(find.text('Your turn to start'), findsNothing);
  });
}
