import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_models.dart';
import '../theme/game_theme.dart';
import '../widgets/metallic_panel.dart';
import '../widgets/pawn_widget.dart';
import 'game_screen.dart';

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
      body: LayoutBuilder(
        builder: (context, c) {
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
                  title: 'CLASSIC',
                  tagline: 'Silver × Gold',
                  titleColors: const [Color(0xFFFFFFFF), Color(0xFFC8CDD8), Color(0xFF878D9C)],
                  motif: const _ClassicMotif(),
                  onTap: () => _go(context, const _SetupScreen(mode: Mode4.classic)),
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
                  title: 'FUTURISTIC',
                  tagline: 'Capture · Conquer',
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
                  // Faint diagonal sheen.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.accentGlow.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                  RepaintBoundary(child: motif),
                  Center(
                    child: FadeTransition(
                      opacity: contentFade,
                      child: _HalfContent(theme: theme, title: title, tagline: tagline, titleColors: titleColors),
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
  final List<Color> titleColors;
  const _HalfContent({
    required this.theme,
    required this.title,
    required this.tagline,
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
            child: Text('TAP TO PLAY', style: theme.label(12, color: theme.accent, weight: FontWeight.w700)),
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
        final t = sheen.value; // 0..1
        final begin = isRow ? Alignment(0, -1 + 2 * t) : Alignment(-1 + 2 * t, 0);
        final end = isRow ? Alignment(0, 1 + 2 * t) : Alignment(1 + 2 * t, 0);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: end,
              colors: const [Color(0xFFAAB0BE), Color(0xFFD4AF37), Color(0xFFAAB0BE)],
            ),
            boxShadow: [BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), blurRadius: 8)],
          ),
        );
      },
    );
  }
}

/// Faint Classic motif: a silver X and a gold O in opposite corners.
class _ClassicMotif extends StatelessWidget {
  const _ClassicMotif();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ClassicMotifPainter(), size: Size.infinite);
  }
}

class _ClassicMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final m = math.min(size.width, size.height) * 0.32;
    // Silver X, top-left.
    final xPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = m * 0.12
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC8CDD8).withValues(alpha: 0.13);
    final tl = Offset(size.width * 0.12, size.height * 0.12);
    canvas.drawLine(tl, tl + Offset(m, m), xPaint);
    canvas.drawLine(tl + Offset(m, 0), tl + Offset(0, m), xPaint);
    // Gold O, bottom-right.
    final oPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = m * 0.12
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.13);
    final br = Offset(size.width * 0.82, size.height * 0.82);
    canvas.drawCircle(br, m * 0.5, oPaint);
  }

  @override
  bool shouldRepaint(_ClassicMotifPainter old) => false;
}

/// Faint Futuristic motif: metallic medallions in the corners (reused medallion widget).
class _FuturisticMotif extends StatelessWidget {
  const _FuturisticMotif();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: 24,
          right: 20,
          child: Opacity(
            opacity: 0.24,
            child: PawnWidget(owner: 1, value: 11, showValue: true, size: 64, animateIn: false),
          ),
        ),
        Positioned(
          bottom: 26,
          left: 22,
          child: Opacity(
            opacity: 0.24,
            child: PawnWidget(owner: 0, value: 8, showValue: true, size: 56, animateIn: false),
          ),
        ),
        Positioned(
          top: 120,
          left: 30,
          child: Opacity(
            opacity: 0.18,
            child: PawnWidget(owner: 0, value: 5, showValue: true, size: 40, animateIn: false),
          ),
        ),
      ],
    );
  }
}

void _go(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

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
    return _ModeShell(
      theme: GameTheme.futuristic,
      title: 'FUTURISTIC',
      subtitle: 'Choose a mode',
      child: Column(
        children: [
          _SubmodeCard(
            letter: 'O',
            name: 'Original',
            desc: 'Classic flow with valued pawns & capture',
            onTap: () => _go(context, const _SetupScreen(mode: Mode4.original)),
          ),
          const SizedBox(height: 14),
          _SubmodeCard(
            letter: 'B',
            name: 'Bonanza',
            desc: 'Randomized starting hands — luck of the draw',
            onTap: () => _go(context, const _SetupScreen(mode: Mode4.bonanza)),
          ),
          const SizedBox(height: 14),
          _SubmodeCard(
            letter: 'M',
            name: 'Morph',
            desc: 'Complete a 4-cell shape to win',
            onTap: () => _go(context, const _SetupScreen(mode: Mode4.morph)),
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
    final theme = widget.mode == Mode4.classic ? GameTheme.classic : GameTheme.futuristic;
    return _ModeShell(
      theme: theme,
      title: widget.mode.label.toUpperCase(),
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
                      _sectionLabel(t, 'DIFFICULTY'),
                      _Segmented<Difficulty>(
                        values: Difficulty.values,
                        selected: difficulty,
                        label: (d) => d.label,
                        onSelect: (d) => setState(() => difficulty = d),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _sectionLabel(t, 'GRID'),
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
      child: Text(text, style: t.label(12, color: t.muted, weight: FontWeight.w700)),
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
                Text('Offline Multiplayer', style: t.label(15, color: t.ink, weight: FontWeight.w700)),
                Text(
                  value ? 'Two players · same device' : 'Play vs computer',
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
          'START',
          style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.black),
        ),
      ),
    );
  }
}
