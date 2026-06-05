import 'package:flutter/material.dart';

import '../models/game_models.dart';
import '../theme/game_theme.dart';
import 'pawn_widget.dart';

/// A player's remaining hand. Both rails are always visible (spec §8). When a pawn is placed the row
/// reflows and animates its size, so the rail "slides to close the gap". Each token is drawn in its
/// own colour (Bonanza mixes colours). The active human seat's tokens are tappable to select one.
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
    final theme = GameTheme.of(context);
    const tokenSize = 38.0;
    return AnimatedContainer(
      duration: Motion.railSlide,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: theme.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? theme.discGlow(owner) : theme.cellEmptyBorder,
          width: active ? 2 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: theme.discGlow(owner).withValues(alpha: 0.25), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          _dot(theme),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 78),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.label(
                13,
                color: active ? theme.ink : theme.muted,
                weight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSize(
              duration: Motion.railSlide,
              curve: Curves.easeOut,
              alignment: Alignment.centerLeft,
              child: hand.isEmpty
                  ? Text('—', style: theme.label(14, color: theme.muted))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Single clean row, never overlapping/stacking: shrink tiles to fit the rail
                        // width; if a very large hand still won't fit at the min size, scroll instead.
                        const spacing = 6.0;
                        const maxSize = tokenSize;
                        const minSize = 22.0;
                        final n = hand.length;
                        final avail = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : maxSize * n + spacing * (n - 1);
                        final raw = (avail - spacing * (n - 1)) / n;
                        final size = raw.clamp(minSize, maxSize);
                        final row = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < n; i++)
                              Padding(
                                padding: EdgeInsets.only(right: i == n - 1 ? 0 : spacing),
                                child: _token(hand[i], i, size),
                              ),
                          ],
                        );
                        final needed = size * n + spacing * (n - 1);
                        if (needed <= avail + 0.5) {
                          return Align(alignment: Alignment.centerLeft, child: row);
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: row,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(GameTheme theme) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.ownerColor(owner),
        boxShadow: active ? [BoxShadow(color: theme.discGlow(owner), blurRadius: 8)] : null,
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
      animateIn: false,
      glyph: classic ? (h.color == 0 ? 'X' : 'O') : null,
    );
    if (!selectable) return Opacity(opacity: active ? 1 : 0.65, child: pawn);
    return GestureDetector(onTap: () => onSelect!(h.color, h.value), child: pawn);
  }
}
