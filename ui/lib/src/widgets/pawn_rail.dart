import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pawn_widget.dart';

/// A player's remaining hand. Both rails are always visible (spec §8). When a pawn is placed the row
/// reflows and animates its size, so the rail "slides to close the gap". For the active human the
/// pawns are tappable to select a value.
class PawnRail extends StatelessWidget {
  final int owner;
  final List<int> hand;
  final bool showValues;
  final bool active;
  final int? selectedValue;
  final void Function(int value)? onSelect;

  const PawnRail({
    super.key,
    required this.owner,
    required this.hand,
    required this.showValues,
    required this.active,
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
          _label(),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSize(
              duration: AppTheme.railSlide,
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              child: hand.isEmpty
                  ? Text('—', style: TextStyle(color: AppColors.textMuted))
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < hand.length; i++)
                          _token(hand[i], i, tokenSize),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.owner(owner),
        boxShadow: active
            ? [BoxShadow(color: AppColors.ownerGlow(owner), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _token(int value, int index, double size) {
    final selectable = active && onSelect != null;
    final selected = selectedValue == value;
    final pawn = PawnWidget(
      key: ValueKey('hand-$owner-$index-$value'),
      owner: owner,
      value: value,
      showValue: showValues,
      size: size,
      selected: selected,
    );
    if (!selectable) return Opacity(opacity: active ? 1 : 0.65, child: pawn);
    return GestureDetector(onTap: () => onSelect!(value), child: pawn);
  }
}
