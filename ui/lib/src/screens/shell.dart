import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_controllers.dart';
import '../audio/music_controller.dart';
import '../audio/sfx_controller.dart';
import '../theme/app_themes.dart';
import '../tutorial/tutorial_screen.dart';

AppLocalizations _l(BuildContext c) => AppLocalizations.of(c)!;

/// Locale-aware upper-casing. Dart's [String.toUpperCase] is not Turkish-aware ('i' → 'I'), and the
/// Cinzel display font renders lowercase as dotless small-caps — so a Turkish title like "Eğitimler"
/// must be pre-cased with the dotted İ (U+0130) to read correctly ("EĞİTİMLER", not "EĞITIMLER").
String _localeUpper(BuildContext c, String s) {
  if (Localizations.localeOf(c).languageCode == 'tr') {
    s = s.replaceAll('ı', 'I').replaceAll('i', 'İ');
  }
  return s.toUpperCase();
}

/// Left navigation drawer: brand header + Settings / About / Issue (spec §3).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    final lux = LuxTokens.of(context);
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FUTURISTIC XOX',
                      style: GoogleFonts.cinzel(
                          fontSize: 18, fontWeight: FontWeight.w800, color: lux.accent, letterSpacing: 2)),
                  const SizedBox(height: 2),
                  Text(l.menuLabel, style: TextStyle(color: lux.muted, fontSize: 12, letterSpacing: 1.5)),
                ],
              ),
            ),
            Divider(color: lux.line, height: 1),
            _item(context, Icons.settings_outlined, l.navSettings, const SettingsPage()),
            _item(context, Icons.school_outlined, l.navTutorials, const TutorialsPage()),
            _item(context, Icons.info_outline, l.navAbout, const AboutPage()),
            _item(context, Icons.bug_report_outlined, l.navIssue, const IssuePage()),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        SfxController.instance.play(SoundId.menuForward);
        Navigator.of(context).pop(); // close drawer
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}

/// A simple themed scaffold for the shell pages (app bar with title + back).
class _ShellPage extends StatelessWidget {
  final String title;
  final Widget body;
  const _ShellPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_localeUpper(context, title), style: GoogleFonts.cinzel(fontWeight: FontWeight.w700))),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: body)),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    final scope = AppScope.of(context);
    final lux = LuxTokens.of(context);
    return _ShellPage(
      title: l.settingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(lux, l.settingsLanguage),
          AnimatedBuilder(
            animation: scope.locale,
            builder: (context, _) {
              final current = scope.locale.locale?.languageCode ??
                  Localizations.localeOf(context).languageCode;
              return Column(
                children: [
                  for (final opt in const [
                    ['tr', 'Türkçe'],
                    ['en', 'English'],
                    ['ru', 'Русский'],
                    ['es', 'Español'],
                  ])
                    _choice(context, opt[1], current == opt[0],
                        () => scope.locale.setLocale(Locale(opt[0]))),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _label(lux, l.settingsTheme),
          AnimatedBuilder(
            animation: scope.theme,
            builder: (context, _) => Row(
              children: [
                Expanded(
                  child: _choice(context, l.themeDark, scope.theme.mode == ThemeMode.dark,
                      () => scope.theme.setMode(ThemeMode.dark)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _choice(context, l.themeLight, scope.theme.mode == ThemeMode.light,
                      () => scope.theme.setMode(ThemeMode.light)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _label(lux, l.settingsSfx),
          _sfxSection(context, l, lux),
          const SizedBox(height: 28),
          _label(lux, l.settingsMusic),
          _musicSection(context, l, lux),
        ],
      ),
    );
  }

  /// SFX on/off + volume (spec §4). Independent of music. A short sample plays on enable / volume-release.
  Widget _sfxSection(BuildContext context, AppLocalizations l, LuxTokens lux) {
    final sfx = SfxController.instance;
    return AnimatedBuilder(
      animation: sfx,
      builder: (context, _) => _audioCard(
        context,
        lux,
        title: l.settingsSfx,
        volumeLabel: l.settingsSfxVolume,
        enabled: sfx.enabled,
        volume: sfx.volume,
        onToggle: (v) {
          sfx.setEnabled(v);
          if (v) sfx.play(SoundId.menuTap);
        },
        onVolume: (v) => sfx.setVolume(v),
        onVolumeEnd: () => sfx.play(SoundId.select),
      ),
    );
  }

  /// Music on/off + volume (spec §4). Independent of SFX — toggling it silences/resumes the loops.
  Widget _musicSection(BuildContext context, AppLocalizations l, LuxTokens lux) {
    final music = MusicController.instance;
    return AnimatedBuilder(
      animation: music,
      builder: (context, _) => _audioCard(
        context,
        lux,
        title: l.settingsMusic,
        volumeLabel: l.settingsMusicVolume,
        enabled: music.enabled,
        volume: music.volume,
        onToggle: music.setEnabled,
        onVolume: (v) => music.setVolume(v),
        onVolumeEnd: null,
      ),
    );
  }

  Widget _audioCard(
    BuildContext context,
    LuxTokens lux, {
    required String title,
    required String volumeLabel,
    required bool enabled,
    required double volume,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onVolume,
    VoidCallback? onVolumeEnd,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lux.line),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: lux.accent,
            title: Text(title,
                style: TextStyle(color: lux.ink, fontWeight: FontWeight.w700, fontSize: 15)),
            value: enabled,
            onChanged: onToggle,
          ),
          Opacity(
            opacity: enabled ? 1 : 0.4,
            child: Row(
              children: [
                Icon(Icons.volume_up_outlined, color: lux.muted, size: 20),
                const SizedBox(width: 8),
                Text(volumeLabel, style: TextStyle(color: lux.muted, fontSize: 13)),
                Expanded(
                  child: Slider(
                    activeColor: lux.accent,
                    value: volume.clamp(0.0, 1.0),
                    onChanged: enabled ? onVolume : null,
                    onChangeEnd: enabled && onVolumeEnd != null ? (_) => onVolumeEnd() : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(LuxTokens lux, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Text(s.toUpperCase(),
            style: TextStyle(color: lux.muted, letterSpacing: 1.5, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final lux = LuxTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          SfxController.instance.play(SoundId.menuTap); // committed language/theme selection
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? lux.accent.withValues(alpha: 0.18) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? lux.accent : lux.line, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                // The UI font (Rajdhani) has no Cyrillic, so "Русский" fell back to a heavy system
                // font. Use Noto Sans as a Cyrillic-capable fallback (Latin still renders in Rajdhani)
                // at medium weight; selection stays clear via colour + border + check.
                child: Text(label,
                    style: TextStyle(
                        color: selected ? lux.accent : lux.ink,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        fontFamilyFallback: [GoogleFonts.notoSans().fontFamily!])),
              ),
              if (selected) Icon(Icons.check, color: lux.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    final lux = LuxTokens.of(context);
    return _ShellPage(
      title: l.aboutTitle,
      body: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: lux.line),
        ),
        child: Text(l.aboutBody, style: TextStyle(color: lux.ink, height: 1.5, fontSize: 15)),
      ),
    );
  }
}

class IssuePage extends StatelessWidget {
  const IssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    final lux = LuxTokens.of(context);
    return _ShellPage(
      title: l.issueTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.issueFaq.toUpperCase(),
              style: TextStyle(color: lux.muted, letterSpacing: 1.5, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          for (var i = 1; i <= 5; i++)
            Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: lux.line),
              ),
              child: ExpansionTile(
                shape: const Border(),
                title: Text('${l.issueFaqItem} $i', style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.issueFaqSoon, style: TextStyle(color: lux.muted)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          Text(l.issueContact.toUpperCase(),
              style: TextStyle(color: lux.muted, letterSpacing: 1.5, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: lux.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.issueContactNote, style: TextStyle(color: lux.ink, height: 1.4)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'mailto', path: 'help@futuristicxox.com')),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('help@futuristicxox.com'),
                  style: OutlinedButton.styleFrom(foregroundColor: lux.accent, side: BorderSide(color: lux.accent)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tutorials hub: replay a mode's interactive tutorial any time (spec: drawer Tutorials item).
class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = _l(context);
    final lux = LuxTokens.of(context);
    return _ShellPage(
      title: l.navTutorials,
      body: Column(
        children: [
          _tut(context, lux, l.modeClassic, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ClassicTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
            ));
          }),
          _tut(context, lux, l.modeOriginal, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OriginalTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
            ));
          }),
          _tut(context, lux, l.modeBonanza, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => BonanzaTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
            ));
          }),
          _tut(context, lux, l.modeMorph, onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MorphTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
            ));
          }),
        ],
      ),
    );
  }

  Widget _tut(BuildContext context, LuxTokens lux, String name, {VoidCallback? onTap, String? soon}) {
    final available = onTap != null;
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: lux.line),
      ),
      child: Opacity(
        opacity: available ? 1 : 0.5,
        child: ListTile(
          leading: Icon(Icons.school_outlined, color: available ? lux.accent : lux.muted),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: available
              ? const Icon(Icons.chevron_right)
              : Text(soon ?? '', style: TextStyle(color: lux.muted, fontSize: 12)),
          onTap: onTap,
        ),
      ),
    );
  }
}
