import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the chosen [Locale] (null = follow the device) and persists it (spec §1, §5).
class LocaleController extends ChangeNotifier {
  static const _key = 'locale';
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleController(this._locale);

  Future<void> setLocale(Locale? value) async {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value.languageCode);
    }
  }
}

/// Holds the [ThemeMode] (dark/light) and persists it (spec §2, §5).
class ThemeController extends ChangeNotifier {
  static const _key = 'theme';
  ThemeMode _mode;
  ThemeMode get mode => _mode;

  ThemeController(this._mode);

  Future<void> setMode(ThemeMode value) async {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value == ThemeMode.light ? 'light' : 'dark');
  }
}

/// Tracks which modes' tutorials the player has already seen, so each mode's tutorial auto-shows only
/// the first time that mode is entered (persisted). Keyed by `Mode4.name`.
class TutorialProgress extends ChangeNotifier {
  static const _prefix = 'tut_seen_';
  final Set<String> _seen;
  TutorialProgress(this._seen);

  bool seen(String modeKey) => _seen.contains(modeKey);

  Future<void> markSeen(String modeKey) async {
    if (_seen.add(modeKey)) {
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$modeKey', true);
    }
  }
}

/// The persisted app preferences, loaded once at startup.
class AppPrefs {
  final Locale? locale;
  final ThemeMode themeMode;
  final Set<String> seenTutorials;
  final bool sfxEnabled;
  final double sfxVolume;
  const AppPrefs(
      this.locale, this.themeMode, this.seenTutorials, this.sfxEnabled, this.sfxVolume);

  static Future<AppPrefs> load(Iterable<Locale> supported) async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    final locale = (code != null && supported.any((l) => l.languageCode == code))
        ? Locale(code)
        : null; // null → MaterialApp resolves the device locale (with fallback)
    final theme = prefs.getString('theme') == 'light' ? ThemeMode.light : ThemeMode.dark;
    final seen = <String>{};
    for (final m in const ['classic', 'original', 'bonanza', 'morph']) {
      if (prefs.getBool('${TutorialProgress._prefix}$m') ?? false) seen.add(m);
    }
    final sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    final sfxVolume = prefs.getDouble('sfx_volume') ?? 0.8;
    return AppPrefs(locale, theme, seen, sfxEnabled, sfxVolume);
  }
}

/// Exposes the two controllers to the widget tree.
class AppScope extends InheritedWidget {
  final LocaleController locale;
  final ThemeController theme;
  final TutorialProgress tutorialProgress;
  const AppScope({
    super.key,
    required this.locale,
    required this.theme,
    required this.tutorialProgress,
    required super.child,
  });

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) => false; // controllers notify directly
}
