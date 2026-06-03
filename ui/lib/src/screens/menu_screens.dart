import 'package:flutter/material.dart';

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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'FUTURISTIC XOX',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3),
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
              const _SectionLabel('Difficulty'),
              _ChoiceRow<Difficulty>(
                values: Difficulty.values,
                selected: difficulty,
                label: (d) => d.label,
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _go(
                    context,
                    GameScreen(mode: widget.mode, grid: grid, difficulty: difficulty),
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
                style: TextStyle(color: AppColors.textMuted),
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
        side: BorderSide(color: AppColors.gridLine),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(color: AppColors.textMuted)),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: AppColors.textMuted, letterSpacing: 1.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final void Function(T) onSelect;

  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final v in values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => onSelect(v),
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
  }
}
