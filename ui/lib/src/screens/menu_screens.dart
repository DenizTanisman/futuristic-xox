import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../app/app_controllers.dart';
import '../models/game_models.dart';
import '../theme/game_theme.dart';
import '../tutorial/tutorial_screen.dart';
import '../widgets/metallic_panel.dart';
import '../widgets/pawn_widget.dart';
import 'game_screen.dart';
import 'shell.dart';

/// Landing screen: a responsive Classic | Futuristic split (side-by-side on wide screens, top/bottom
/// on phones), with a slide-in entrance, metallic titles, an animated metallic divider, themed
/// motifs, and hover-to-expand on desktop. Tapping a side opens that mode's setup (spec §8.1).
class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  late final AnimationController _sheen =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  /// Which half the mouse is over (desktop hover-to-expand); null = none / mobile.
  int? _hovered;

  @override
  void dispose() {
    _entrance.dispose();
    _sheen.dispose();
    super.dispose();
  }

  void _setHover(int? i) {
    if (_hovered != i) setState(() => _hovered = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Entry keeps its fixed dark-luxury look; only its text is localized (spec §0).
      drawer: const AppDrawer(),
      body: LayoutBuilder(
        builder: (context, c) {
          final l = AppLocalizations.of(context)!;
          final isRow = c.maxWidth >= c.maxHeight;
          final main = isRow ? c.maxWidth : c.maxHeight;
          final f0 = _hovered == 0
              ? 0.6
              : _hovered == 1
                  ? 0.4
                  : 0.5;
          final c0 = f0 * main;

          return Stack(
            children: [
              _positioned(
                isRow: isRow,
                start: 0,
                extent: c0,
                full: c,
                child: _half(
                  index: 0,
                  isRow: isRow,
                  theme: GameTheme.classic,
                  title: l.modeClassic.toUpperCase(),
                  tagline: l.classicTagline,
                  tapToPlay: l.tapToPlay,
                  titleColors: const [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)],
                  motif: const _ClassicMotif(),
                  onTap: () => _enterMode(context, Mode4.classic),
                ),
              ),
              _positioned(
                isRow: isRow,
                start: c0,
                extent: main - c0,
                full: c,
                child: _half(
                  index: 1,
                  isRow: isRow,
                  theme: GameTheme.futuristic,
                  title: l.modeFuturistic.toUpperCase(),
                  tagline: l.futuristicTagline,
                  tapToPlay: l.tapToPlay,
                  titleColors: const [Color(0xFFF6E6A8), Color(0xFFD4AF37), Color(0xFF8A6A1D)],
                  motif: const _FuturisticMotif(),
                  onTap: () => _go(context, const _FuturisticSelectScreen()),
                ),
              ),
              // Metallic divider on the seam.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeInOutCubic,
                left: isRow ? c0 - 1 : 0,
                top: isRow ? 0 : c0 - 1,
                width: isRow ? 2 : c.maxWidth,
                height: isRow ? c.maxHeight : 2,
                child: RepaintBoundary(child: _Divider(isRow: isRow, sheen: _sheen)),
              ),
              // Hamburger → drawer (top-left), above the split.
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFFF4ECD8)),
                      tooltip: l.menuLabel,
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _positioned({
    required bool isRow,
    required double start,
    required double extent,
    required BoxConstraints full,
    required Widget child,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      left: isRow ? start : 0,
      top: isRow ? 0 : start,
      width: isRow ? extent : full.maxWidth,
      height: isRow ? full.maxHeight : extent,
      child: child,
    );
  }

  Widget _half({
    required int index,
    required bool isRow,
    required GameTheme theme,
    required String title,
    required String tagline,
    required String tapToPlay,
    required List<Color> titleColors,
    required Widget motif,
    required VoidCallback onTap,
  }) {
    final dim = _hovered != null && _hovered != index;
    final entranceOffset = index == 0
        ? (isRow ? const Offset(-1, 0) : const Offset(0, -1))
        : (isRow ? const Offset(1, 0) : const Offset(0, 1));
    final slide = Tween<Offset>(begin: entranceOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    final contentFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0));

    return MouseRegion(
      onEnter: (_) => _setHover(index),
      onExit: (_) => _setHover(null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 550),
          opacity: dim ? 0.62 : 1.0,
          child: SlideTransition(
            position: slide,
            child: GameThemeProvider(
              theme: theme,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(decoration: BoxDecoration(gradient: theme.background)),
                  // Diagonal light wedge: the two halves' sheens mirror each other and meet near the
                  // top-center seam. Classic runs ↗ from the bottom-left, Futuristic ↖ from the
                  // bottom-right.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: index == 0 ? Alignment.bottomLeft : Alignment.bottomRight,
                        end: index == 0 ? Alignment.topRight : Alignment.topLeft,
                        colors: [
                          Colors.transparent,
                          (index == 0 ? const Color(0xFFEEF1F6) : const Color(0xFFF6E6A8))
                              .withValues(alpha: index == 0 ? 0.06 : 0.07),
                          Colors.transparent,
                        ],
                        stops: const [0.32, 0.5, 0.68],
                      ),
                    ),
                  ),
                  RepaintBoundary(child: motif),
                  Center(
                    child: FadeTransition(
                      opacity: contentFade,
                      child: _HalfContent(
                        theme: theme,
                        title: title,
                        tagline: tagline,
                        tapToPlay: tapToPlay,
                        titleColors: titleColors,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The centered title / tagline / "tap to play" pill for one half.
class _HalfContent extends StatelessWidget {
  final GameTheme theme;
  final String title;
  final String tagline;
  final String tapToPlay;
  final List<Color> titleColors;
  const _HalfContent({
    required this.theme,
    required this.title,
    required this.tagline,
    required this.tapToPlay,
    required this.titleColors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: titleColors,
              stops: const [0.0, 0.45, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.srcIn,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(tagline.toUpperCase(), style: theme.label(13, color: theme.muted, weight: FontWeight.w600)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.accent.withValues(alpha: 0.7)),
              boxShadow: [BoxShadow(color: theme.accent.withValues(alpha: 0.2), blurRadius: 12)],
            ),
            child: Text(tapToPlay.toUpperCase(), style: theme.label(12, color: theme.accent, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Animated metallic divider (steel→gold) with a slow sheen shift along its length.
class _Divider extends StatelessWidget {
  final bool isRow;
  final Animation<double> sheen;
  const _Divider({required this.isRow, required this.sheen});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sheen,
      builder: (context, _) {
        // A bright gold band slides steel→gold→steel along the divider's length.
        final c = sheen.value; // band centre 0..1
        const half = 0.18;
        final lo = (c - half).clamp(0.0, 1.0);
        final mid = c.clamp(0.0, 1.0);
        final hi = (c + half).clamp(0.0, 1.0);
        // Stops must be strictly increasing.
        final stops = <double>[0.0, lo, mid, hi, 1.0];
        for (var i = 1; i < stops.length; i++) {
          if (stops[i] <= stops[i - 1]) stops[i] = (stops[i - 1] + 0.0001).clamp(0.0, 1.0);
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isRow ? Alignment.topCenter : Alignment.centerLeft,
              end: isRow ? Alignment.bottomCenter : Alignment.centerRight,
              colors: const [
                Color(0xFFAAB0BE),
                Color(0xFFAAB0BE),
                Color(0xFFF6E6A8),
                Color(0xFFAAB0BE),
                Color(0xFFAAB0BE),
              ],
              stops: stops,
            ),
            boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.45), blurRadius: 9)],
          ),
        );
      },
    );
  }
}

/// Faint Classic motif: a large silver X and gold O in opposite corners. The opacity is applied
/// **once to the whole mark** (group opacity) so the X's crossing stays uniform — drawing each
/// stroke semi-transparent would double the alpha at the intersection.
class _ClassicMotif extends StatelessWidget {
  const _ClassicMotif();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.13,
      child: CustomPaint(painter: _ClassicMotifPainter(), size: Size.infinite),
    );
  }
}

class _ClassicMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final short = math.min(size.width, size.height);
    final m = short * 0.42; // large, per the mockup
    // Silver X, top-left — fully opaque strokes (group opacity is applied by the wrapping widget).
    final xPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = m * 0.12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC8CDD8);
    final tl = Offset(size.width * 0.10, size.height * 0.08);
    canvas.drawLine(tl, tl + Offset(m, m), xPaint);
    canvas.drawLine(tl + Offset(m, 0), tl + Offset(0, m), xPaint);
    // Gold O, bottom-right.
    final oPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = m * 0.12
      ..color = const Color(0xFFD4AF37);
    final br = Offset(size.width * 0.86, size.height * 0.88);
    canvas.drawCircle(br, m * 0.5, oPaint);
  }

  @override
  bool shouldRepaint(_ClassicMotifPainter old) => false;
}

/// Faint Futuristic motif: large metallic corner medallions, sized to the half (not a fixed small
/// size). Opacity is applied per medallion (group opacity) so internal layers don't double up.
class _FuturisticMotif extends StatelessWidget {
  const _FuturisticMotif();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = math.min(c.maxWidth, c.maxHeight);
        final d1 = (c.maxWidth * 0.26).clamp(70.0, 150.0);
        final d2 = (c.maxWidth * 0.20).clamp(56.0, 120.0);
        final d3 = (c.maxWidth * 0.14).clamp(40.0, 90.0);
        return Stack(
          children: [
            Positioned(
              top: s * 0.05,
              right: s * 0.05,
              child: Opacity(
                opacity: 0.24,
                child: PawnWidget(owner: 1, value: 11, showValue: true, size: d1, animateIn: false),
              ),
            ),
            Positioned(
              bottom: s * 0.06,
              left: s * 0.05,
              child: Opacity(
                opacity: 0.24,
                child: PawnWidget(owner: 0, value: 8, showValue: true, size: d2, animateIn: false),
              ),
            ),
            Positioned(
              top: s * 0.34,
              left: s * 0.08,
              child: Opacity(
                opacity: 0.18,
                child: PawnWidget(owner: 0, value: 5, showValue: true, size: d3, animateIn: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _go(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// Enter a mode's setup. The first time the player enters a mode whose tutorial exists, auto-show
/// that tutorial first (then the difficulty/setup screen); afterwards go straight to setup. Gated by a
/// persisted per-mode "seen" flag (spec: tutorials only on first entry per mode).
void _enterMode(BuildContext context, Mode4 mode) {
  final progress = AppScope.of(context).tutorialProgress;
  final hasTutorial = mode == Mode4.classic; // only Classic has a tutorial for now
  if (hasTutorial && !progress.seen(mode.name)) {
    progress.markSeen(mode.name);
    final nav = Navigator.of(context);
    nav.push(MaterialPageRoute(
      builder: (_) => ClassicTutorialScreen(
        // On finish/skip, replace the tutorial with the mode's setup (back from setup → home).
        onExit: () => nav.pushReplacement(MaterialPageRoute(builder: (_) => _SetupScreen(mode: mode))),
      ),
    ));
  } else {
    _go(context, _SetupScreen(mode: mode));
  }
}

String _modeName(AppLocalizations l, Mode4 mode) => switch (mode) {
      Mode4.classic => l.modeClassic,
      Mode4.original => l.modeOriginal,
      Mode4.bonanza => l.modeBonanza,
      Mode4.morph => l.modeMorph,
    };

String _difficultyName(AppLocalizations l, Difficulty d) => switch (d) {
      Difficulty.easy => l.difficultyEasy,
      Difficulty.medium => l.difficultyMedium,
      Difficulty.hard => l.difficultyHard,
    };

/// Themed shell shared by the submode picker and the setup screen: background gradient + a centered
/// metallic panel with a Cinzel title (+ optional subtitle, back chevron). Internally consistent per
/// theme; only hue/texture differ (spec: Mode Picker & Setup §1).
class _ModeShell extends StatelessWidget {
  final GameTheme theme;
  final String title;
  final String? subtitle;
  final Widget child;
  const _ModeShell({
    required this.theme,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GameThemeProvider(
      theme: theme,
      child: Container(
        decoration: BoxDecoration(gradient: theme.background),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: MetallicPanel(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ShaderMask(
                              shaderCallback: (r) => LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [theme.accentGlow, theme.accent],
                              ).createShader(r),
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.cinzel(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(subtitle!, textAlign: TextAlign.center, style: theme.label(13, color: theme.muted)),
                            ],
                            const SizedBox(height: 22),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: theme.muted),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Futuristic submode selection: Original / Bonanza / Morph (spec §8.3).
class _FuturisticSelectScreen extends StatelessWidget {
  const _FuturisticSelectScreen();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _ModeShell(
      theme: GameTheme.futuristic,
      title: l.modeFuturistic.toUpperCase(),
      subtitle: l.chooseMode,
      child: Column(
        children: [
          _SubmodeCard(
            letter: 'O',
            name: l.modeOriginal,
            desc: l.modeOriginalDesc,
            onTap: () => _enterMode(context, Mode4.original),
          ),
          const SizedBox(height: 14),
          _SubmodeCard(
            letter: 'B',
            name: l.modeBonanza,
            desc: l.modeBonanzaDesc,
            onTap: () => _enterMode(context, Mode4.bonanza),
          ),
          const SizedBox(height: 14),
          _SubmodeCard(
            letter: 'M',
            name: l.modeMorph,
            desc: l.modeMorphDesc,
            onTap: () => _enterMode(context, Mode4.morph),
          ),
        ],
      ),
    );
  }
}

/// A selectable submode card with a metallic icon tile, name, description, and hover lift + glow.
class _SubmodeCard extends StatefulWidget {
  final String letter;
  final String name;
  final String desc;
  final VoidCallback onTap;
  const _SubmodeCard({required this.letter, required this.name, required this.desc, required this.onTap});

  @override
  State<_SubmodeCard> createState() => _SubmodeCardState();
}

class _SubmodeCardState extends State<_SubmodeCard> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final t = GameTheme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _h ? -3 : 0, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.8),
              radius: 1.4,
              colors: [t.accent.withValues(alpha: 0.10), t.cell],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _h ? t.accent : t.accent.withValues(alpha: 0.4), width: _h ? 2 : 1),
            boxShadow: _h ? [BoxShadow(color: t.accent.withValues(alpha: 0.3), blurRadius: 16)] : null,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [t.accentGlow, t.accent],
                  ),
                ),
                child: Text(widget.letter,
                    style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: t.display(18, color: t.ink)),
                    const SizedBox(height: 2),
                    Text(widget.desc, style: t.label(12, color: t.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Difficulty + grid + offline-multiplayer, then launch the game (spec §8.2–8.3).
class _SetupScreen extends StatefulWidget {
  final Mode4 mode;
  const _SetupScreen({required this.mode});

  @override
  State<_SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<_SetupScreen> {
  Difficulty difficulty = Difficulty.medium;
  late int grid = widget.mode.grids.first;
  bool multiplayer = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = widget.mode == Mode4.classic ? GameTheme.classic : GameTheme.futuristic;
    return _ModeShell(
      theme: theme,
      title: _modeName(l, widget.mode).toUpperCase(),
      child: Builder(
        builder: (ctx) {
          final t = GameTheme.of(ctx);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Difficulty — dims + disables under offline multiplayer (no AI opponent).
              IgnorePointer(
                ignoring: multiplayer,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: multiplayer ? 0.34 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionLabel(t, l.difficultyLabel),
                      _Segmented<Difficulty>(
                        values: Difficulty.values,
                        selected: difficulty,
                        label: (d) => _difficultyName(l, d),
                        onSelect: (d) => setState(() => difficulty = d),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionLabel(t, l.gridLabel),
              _Segmented<int>(
                values: widget.mode.grids,
                selected: grid,
                label: (g) => '$g×$g',
                iconBuilder: (g, color) => _GridIcon(n: g, color: color),
                onSelect: (g) => setState(() => grid = g),
              ),
              const SizedBox(height: 22),
              _MultiplayerToggle(value: multiplayer, onChanged: (v) => setState(() => multiplayer = v)),
              const SizedBox(height: 26),
              _StartButton(
                onTap: () => _go(
                  ctx,
                  GameScreen(
                    mode: widget.mode,
                    grid: grid,
                    difficulty: difficulty,
                    multiplayer: multiplayer,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _sectionLabel(GameTheme t, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: t.label(12, color: t.muted, weight: FontWeight.w700)),
    );

/// A themed segmented selector: selected cell = accent gradient + glow + dark text.
class _Segmented<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final Widget Function(T value, Color color)? iconBuilder;
  final void Function(T) onSelect;
  const _Segmented({
    required this.values,
    required this.selected,
    required this.label,
    this.iconBuilder,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final t = GameTheme.of(context);
    return Row(
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _SegCell(
                t: t,
                selected: v == selected,
                label: label(v),
                icon: iconBuilder?.call(v, v == selected ? Colors.black : t.muted),
                onTap: () => onSelect(v),
              ),
            ),
          ),
      ],
    );
  }
}

class _SegCell extends StatelessWidget {
  final GameTheme t;
  final bool selected;
  final String label;
  final Widget? icon;
  final VoidCallback onTap;
  const _SegCell({required this.t, required this.selected, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [t.accentGlow, t.accent]) : null,
          color: selected ? null : t.cell,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? t.accent : t.accent.withValues(alpha: 0.3), width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: t.accent.withValues(alpha: 0.4), blurRadius: 12)] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(height: 6)],
            Text(label, style: t.label(15, color: selected ? Colors.black : t.ink, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// A small n×n grid of dots illustrating the board size.
class _GridIcon extends StatelessWidget {
  final int n;
  final Color color;
  const _GridIcon({required this.n, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 26, height: 26, child: CustomPaint(painter: _GridDotsPainter(n, color)));
  }
}

class _GridDotsPainter extends CustomPainter {
  final int n;
  final Color color;
  _GridDotsPainter(this.n, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final step = size.width / n;
    final r = (step * 0.26).clamp(1.0, 3.0);
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        canvas.drawCircle(Offset((col + 0.5) * step, (row + 0.5) * step), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridDotsPainter old) => old.n != n || old.color != color;
}

/// Offline-multiplayer (same-device, two humans) switch. Foundation for online play.
class _MultiplayerToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MultiplayerToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = GameTheme.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: t.cell,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? t.accent : t.accent.withValues(alpha: 0.3), width: value ? 2 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.offlineMpTitle, style: t.label(15, color: t.ink, weight: FontWeight.w700)),
                Text(
                  value ? l.offlineMpOn : l.offlineMpOff,
                  style: t.label(12, color: t.muted),
                ),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: t.accent, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Full-width metallic gradient start button.
class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = GameTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [t.accentGlow, t.accent]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: t.accent.withValues(alpha: 0.4), blurRadius: 16)],
        ),
        child: Text(
          AppLocalizations.of(context)!.startButton.toUpperCase(),
          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.black),
        ),
      ),
    );
  }
}
