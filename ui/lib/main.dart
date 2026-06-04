import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'src/app/app_controllers.dart';
import 'src/screens/menu_screens.dart';
import 'src/theme/app_themes.dart';

const List<Locale> kSupportedLocales = [Locale('tr'), Locale('en'), Locale('ru'), Locale('es')];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load(kSupportedLocales);
  runApp(FuturisticXoxApp(
    locale: LocaleController(prefs.locale),
    theme: ThemeController(prefs.themeMode),
  ));
}

class FuturisticXoxApp extends StatelessWidget {
  final LocaleController locale;
  final ThemeController theme;
  const FuturisticXoxApp({super.key, required this.locale, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      locale: locale,
      theme: theme,
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
