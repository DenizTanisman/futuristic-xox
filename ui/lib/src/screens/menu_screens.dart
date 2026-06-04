import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'game_screen.dart';

/// Entry screen: full-screen split between Classic and Futuristic (spec §8.1).
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'FUTURISTIC XOX',
                style: GoogleFonts.cinzel(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: AppColors.accent,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _SplitTile(
                      title: 'Classic',
                      subtitle: 'Pure X / O',
                      color: AppColors.playerA,
                      glow: AppColors.playerAGlow,
                      onTap: () => _go(context, const _SetupScreen(mode: Mode4.classic)),
                    ),
                  ),
                  Expanded(
                    child: _SplitTile(
                      title: 'Futuristic',
                      subtitle: 'Valued pawns · capture',
                      color: AppColors.playerB,
                      glow: AppColors.playerBGlow,
                      onTap: () => _go(context, const _FuturisticSelectScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _SplitTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color glow;
  final VoidCallback onTap;

  const _SplitTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.35), AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: glow.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.2), blurRadius: 16)],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: glow)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
