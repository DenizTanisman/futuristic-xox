import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single pawn token: owner-coloured disc with its value (hidden in Classic, where [showValue] is
/// false). Animates in with a scale+fade for a fluid placement feel (spec §8).
class PawnWidget extends StatelessWidget {
  final int owner;
  final int value;
  final bool showValue;
  final double size;
  final bool selected;

  /// Optional glyph to show instead of the value (Classic uses 'X' / 'O', spec §4.1).
  final String? glyph;

  const PawnWidget({
    super.key,
    required this.owner,
    required this.value,
    required this.showValue,
    required this.size,
    this.selected = false,
    this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.owner(owner);
    final glow = AppColors.ownerGlow(owner);
    final label = glyph ?? (showValue ? '$value' : null);
    return TweenAnimationBuilder<double>(
      key: ValueKey('pawn-$owner-$value-$showValue-$glyph'),
      tween: Tween(begin: 0.6, end: 1.0),
      duration: AppTheme.place,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [glow, color],
            center: const Alignment(-0.3, -0.3),
            radius: 0.95,
          ),
          border: Border.all(
            color: selected ? AppColors.accent : glow.withValues(alpha: 0.5),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glow.withValues(alpha: selected ? 0.6 : 0.35),
              blurRadius: selected ? 16 : 8,
              spreadRadius: selected ? 1 : 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: label == null
            ? null
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(size * 0.18),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.5,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
