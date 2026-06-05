import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'src/app/app_controllers.dart';
import 'src/audio/music_controller.dart';
import 'src/audio/sfx_controller.dart';
import 'src/screens/menu_screens.dart';
import 'src/theme/app_themes.dart';

const List<Locale> kSupportedLocales = [Locale('tr'), Locale('en'), Locale('ru'), Locale('es')];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load(kSupportedLocales);
  // Preload audio in the background — don't block the first frame. The lobby music loop starts once
  // both layers are ready (we're in the menus at launch).
  SfxController.instance.init(enabled: prefs.sfxEnabled, volume: prefs.sfxVolume);
  MusicController.instance
      .init(enabled: prefs.musicEnabled, volume: prefs.musicVolume)
      .then((_) => MusicController.instance.enterLobby());
  runApp(FuturisticXoxApp(
    locale: LocaleController(prefs.locale),
    theme: ThemeController(prefs.themeMode),
    tutorialProgress: TutorialProgress(prefs.seenTutorials),
  ));
}

class FuturisticXoxApp extends StatefulWidget {
  final LocaleController locale;
  final ThemeController theme;
  final TutorialProgress tutorialProgress;
  const FuturisticXoxApp({
    super.key,
    required this.locale,
    required this.theme,
    required this.tutorialProgress,
  });

  @override
  State<FuturisticXoxApp> createState() => _FuturisticXoxAppState();
}

class _FuturisticXoxAppState extends State<FuturisticXoxApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Don't keep audio running in the background / with the screen off (spec: pause when away, resume
    // on return). `inactive` is transient (app switcher, notification shade) — ignore it to avoid
    // stutter; act on paused/hidden/detached and resume on resumed.
    switch (state) {
      case AppLifecycleState.resumed:
        MusicController.instance.resumeFromBackground();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        MusicController.instance.suspend();
        SfxController.instance.suspend();
      case AppLifecycleState.inactive:
        break;
    }
  }

  LocaleController get locale => widget.locale;
  ThemeController get theme => widget.theme;
  TutorialProgress get tutorialProgress => widget.tutorialProgress;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      locale: locale,
      theme: theme,
      tutorialProgress: tutorialProgress,
      // Rebuild MaterialApp whenever locale or theme changes.
      child: AnimatedBuilder(
        animation: Listenable.merge([locale, theme]),
        builder: (context, _) {
          return MaterialApp(
            title: 'Futuristic XOX',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.light,
            darkTheme: AppThemes.dark,
            themeMode: theme.mode,
            locale: locale.locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const EntryScreen(),
          );
        },
      ),
    );
  }
}
