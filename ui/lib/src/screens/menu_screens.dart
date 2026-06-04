import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../theme/game_theme.dart';
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

/// Futuristic submode selection: Original / Bonanza / Morph (spec §8.3).
class _FuturisticSelectScreen extends StatelessWidget {
  const _FuturisticSelectScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Futuristic')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _MenuCard(
              title: 'Original',
              subtitle: 'Valued pawns, capture, 3 in a row',
              onTap: () => _go(context, const _SetupScreen(mode: Mode4.original)),
            ),
            _MenuCard(
              title: 'Bonanza',
              subtitle: 'Original with randomized starting hands',
              onTap: () => _go(context, const _SetupScreen(mode: Mode4.bonanza)),
            ),
            _MenuCard(
              title: 'Morph',
              subtitle: 'Two moves per turn · complete a 4-cell shape',
              onTap: () => _go(context, const _SetupScreen(mode: Mode4.morph)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Difficulty + grid selection, then launch the game (spec §8.2–8.3).
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.label)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Difficulty is meaningless with two human players, so dim + disable it.
              _SectionLabel('Difficulty', dimmed: multiplayer),
              _ChoiceRow<Difficulty>(
                values: Difficulty.values,
                selected: difficulty,
                label: (d) => d.label,
                enabled: !multiplayer,
                onSelect: (d) => setState(() => difficulty = d),
              ),
              const SizedBox(height: 28),
              const _SectionLabel('Grid'),
              _ChoiceRow<int>(
                values: widget.mode.grids,
                selected: grid,
                label: (g) => '$g×$g',
                onSelect: (g) => setState(() => grid = g),
              ),
              const SizedBox(height: 28),
              _MultiplayerToggle(
                value: multiplayer,
                onChanged: (v) => setState(() => multiplayer = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _go(
                    context,
                    GameScreen(
                      mode: widget.mode,
                      grid: grid,
                      difficulty: difficulty,
                      multiplayer: multiplayer,
                    ),
                  ),
                  child: const Text('Play', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Offline-multiplayer (same-device, two humans) switch. Foundation for online play.
class _MultiplayerToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _MultiplayerToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppColors.accent : AppColors.gridLine,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Offline Multiplayer',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  value ? 'Two players, same device' : 'Play against the computer',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: AppColors.accent, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ---- small shared widgets ----

void _go(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuCard({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.gridLine),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool dimmed;
  const _SectionLabel(this.text, {this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted.withValues(alpha: dimmed ? 0.4 : 1.0),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  /// When false, the row is dimmed and non-interactive (Difficulty under offline multiplayer).
  final bool enabled;

  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: enabled ? () => onSelect(v) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: v == selected ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: v == selected ? AppColors.accent : AppColors.gridLine,
                      width: v == selected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label(v),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: v == selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    // Dim the whole row when disabled.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1.0 : 0.4,
      child: row,
    );
  }
}
