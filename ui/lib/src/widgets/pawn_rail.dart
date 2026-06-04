import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'pawn_widget.dart';

/// A player's remaining hand. Both rails are always visible (spec §8). When a pawn is placed the row
/// reflows and animates its size, so the rail "slides to close the gap". For the active human the
/// pawns are tappable to select one.
///
/// Each token is drawn in **its own colour** — in Bonanza a player may hold opponent-coloured pawns
/// (spec §4.3), so a rail can show a mix of both colours.
class PawnRail extends StatelessWidget {
  final int owner;
  final String label;
  final List<HandPawnView> hand;
  final bool showValues;
  final bool classic;
  final bool active;
  final int? selectedColor;
  final int? selectedValue;
  final void Function(int color, int value)? onSelect;

  const PawnRail({
    super.key,
    required this.owner,
    required this.label,
    required this.hand,
    required this.showValues,
    required this.classic,
    required this.active,
    this.selectedColor,
    this.selectedValue,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    const tokenSize = 38.0;
    return AnimatedContainer(
      duration: AppTheme.railSlide,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.ownerGlow(owner) : AppColors.gridLine,
          width: active ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _dot(),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 72),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSize(
              duration: AppTheme.railSlide,
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              child: hand.isEmpty
                  ? const Text('—', style: TextStyle(color: AppColors.textMuted))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < hand.length; i++) _token(hand[i], i, tokenSize),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.owner(owner),
        boxShadow: active ? [BoxShadow(color: AppColors.ownerGlow(owner), blurRadius: 8)] : null,
      ),
    );
  }

  Widget _token(HandPawnView h, int index, double size) {
    final selectable = active && onSelect != null;
    final selected = selectedColor == h.color && selectedValue == h.value;
    final pawn = PawnWidget(
      key: ValueKey('hand-$owner-$index-${h.color}-${h.value}'),
      owner: h.color,
      value: h.value,
      showValue: showValues,
      size: size,
      selected: selected,
      glyph: classic ? (h.color == 0 ? 'X' : 'O') : null,
    );
    if (!selectable) return Opacity(opacity: active ? 1 : 0.65, child: pawn);
    return GestureDetector(onTap: () => onSelect!(h.color, h.value), child: pawn);
  }
}
