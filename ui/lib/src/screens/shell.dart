import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_controllers.dart';
import '../theme/app_themes.dart';
import '../tutorial/tutorial_screen.dart';

AppLocalizations _l(BuildContext c) => AppLocalizations.of(c)!;

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
      appBar: AppBar(title: Text(title, style: GoogleFonts.cinzel(fontWeight: FontWeight.w700))),
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
        onTap: onTap,
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
                child: Text(label,
                    style: TextStyle(
                        color: selected ? lux.accent : lux.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
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
