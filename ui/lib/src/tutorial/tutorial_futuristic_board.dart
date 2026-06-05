import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/sfx_controller.dart';
import '../theme/game_theme.dart';
import '../widgets/pawn_widget.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// Result of a demo tap on the Futuristic board (spec §3); the screen maps it to a localized hint.
/// `placeEmpty` / `lost` are Bonanza's forced-loss outcomes (tapped a filled cell / completed an
/// opponent line). `shapeProgress` / `shapeWin` are Morph's shape-completion outcomes (one target
/// filled with more to go / all targets filled → shape glows).
enum FutTapResult {
  noSelection,
  redirect,
  tooSmall,
  placed,
  placedWin,
  captured,
  capturedWin,
  placeEmpty,
  lost,
  shapeProgress,
  shapeWin,
}

/// A Futuristic (Original) tutorial board: valued medallion cells (gold = ours, bordeaux = opponent),
/// a faint `+` on empty cells, a pulsing gold highlight, the gif-style place/capture showcase loop,
/// and select-then-place demo interaction with capture rules (spec §1–§4). Keyed by step in the
/// screen so its loop timer is cancelled on step change / dispose.
class FuturisticTutorialBoard extends StatefulWidget {
  final List<TutPawn?> cells;
  final double size;
  final int? highlight;

  /// Board dimensions (Morph uses 4×4; Original/Bonanza default 3×3).
  final int cols;
  final int rows;

  /// Extra highlighted cells (Bonanza's forced-loss step glows every empty cell).
  final List<int>? highlights;

  // Showcase loop.
  final bool loop;
  final int? loopPlaceCell;
  final int? loopValue;
  final int loopOwner;
  final int? eatAt; // capture loop: the placed pawn lands on this opponent cell

  // Demo.
  final bool interactive;
  final int? target;
  final TutMode demoMode;
  final int? selectedValue; // currently selected hand pawn value
  final void Function(FutTapResult result)? onResult;

  /// Owner of the pawn placed in a demo (0 = gold, 1 = bordeaux for the forced-loss step).
  final int placeOwner;

  /// `lose` demo: each empty (forced) cell → the opponent line it completes when played.
  final Map<int, List<int>>? loseMap;

  /// `shape` demo: the empty cells to fill (one or two for the double move).
  final List<int>? targets;

  /// `shape` demo: the 4 cells that pulse with a gold glow on win.
  final List<int>? winShape;

  final List<int>? winLine;

  /// Force the win line to always show (static info board, e.g. the win-rule showcase).
  final bool showWin;

  const FuturisticTutorialBoard({
    super.key,
    required this.cells,
    required this.size,
    this.highlight,
    this.cols = 3,
    this.rows = 3,
    this.highlights,
    this.loop = false,
    this.loopPlaceCell,
    this.loopValue,
    this.loopOwner = 0,
    this.eatAt,
    this.interactive = false,
    this.target,
    this.demoMode = TutMode.free,
    this.selectedValue,
    this.onResult,
    this.placeOwner = 0,
    this.loseMap,
    this.targets,
    this.winShape,
    this.winLine,
    this.showWin = false,
  });

  @override
  State<FuturisticTutorialBoard> createState() => _FuturisticTutorialBoardState();
}

class _FuturisticTutorialBoardState extends State<FuturisticTutorialBoard> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  Timer? _loopTimer;
  bool _placedPhase = false;

  final Map<int, TutPawn> _demoPlaced = {};
  int? _flash;
  bool _won = false;
  List<int>? _loseLine; // the opponent line completed in a forced-loss demo
  List<int>? _winShape; // the 4 Morph shape cells to glow on win (no line)

  @override
  void initState() {
    super.initState();
    if (widget.loop) {
      _loopTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) setState(() => _placedPhase = !_placedPhase);
      });
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  TutPawn? _cellAt(int i) {
    if (_demoPlaced.containsKey(i)) return _demoPlaced[i];
    if (widget.loop && _placedPhase && i == widget.loopPlaceCell) {
      return TutPawn(widget.loopOwner, widget.loopValue ?? 0);
    }
    return widget.cells[i];
  }

  List<int>? get _activeWinLine => _loseLine ?? widget.winLine;
  bool get _showWin => _activeWinLine != null && (widget.showWin || (widget.loop ? false : _won));

  /// In a capture loop, the cell shows a gold ripple in the placed phase.
  bool _isFreshPlacement(int i) {
    if (widget.loop) return _placedPhase && i == widget.loopPlaceCell;
    return _demoPlaced.containsKey(i);
  }

  Future<void> _flashCell(int? cell) async {
    if (cell == null) return;
    for (var k = 0; k < 3; k++) {
      if (!mounted) return;
      setState(() => _flash = cell);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _flash = null);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
  }

  void _onTap(int i) {
    if (!widget.interactive || _won) return;
    final sel = widget.selectedValue;
    if (sel == null) {
      widget.onResult?.call(FutTapResult.noSelection);
      return;
    }
    final cell = _cellAt(i);
    final mode = widget.demoMode;

    switch (mode) {
      case TutMode.free:
        if (cell == null) {
          _place(i, sel);
          widget.onResult?.call(FutTapResult.placed);
        } else {
          _redirect();
        }
      case TutMode.win:
        if (i == widget.target && cell == null) {
          _place(i, sel);
          setState(() => _won = true);
          widget.onResult?.call(FutTapResult.placedWin);
        } else if (cell == null) {
          _redirect();
        }
      case TutMode.eat:
      case TutMode.eatwin:
        if (i == widget.target && cell != null && cell.owner == 1) {
          if (sel > cell.value) {
            _capture(i, sel);
            final win = mode == TutMode.eatwin;
            if (win) setState(() => _won = true);
            widget.onResult?.call(win ? FutTapResult.capturedWin : FutTapResult.captured);
          } else {
            widget.onResult?.call(FutTapResult.tooSmall);
            _flashCell(widget.target);
          }
        } else if (cell == null || cell.owner == 1) {
          _redirect();
        }
        // tapping our own pawn: ignore.
      case TutMode.lose:
        // Forced loss: any empty cell completes an opponent line; a filled cell is illegal.
        if (cell != null) {
          widget.onResult?.call(FutTapResult.placeEmpty);
        } else {
          _place(i, sel, owner: widget.placeOwner);
          setState(() {
            _won = true;
            _loseLine = widget.loseMap?[i];
          });
          widget.onResult?.call(FutTapResult.lost);
        }
      case TutMode.shape:
        // Shape completion is value-agnostic: fill every target cell with our pawn, then the shape
        // glows. The win triggers only once ALL targets are filled (two-pawns-per-turn supported).
        final targets = widget.targets ?? const [];
        if (cell == null && targets.contains(i)) {
          _place(i, sel);
          final remaining = targets.where((t) => _cellAt(t) == null).toList();
          if (remaining.isEmpty) {
            setState(() {
              _won = true;
              _winShape = widget.winShape;
            });
            widget.onResult?.call(FutTapResult.shapeWin);
          } else {
            widget.onResult?.call(FutTapResult.shapeProgress);
          }
        } else {
          // Wrong cell (non-target or occupied): nudge toward a still-open target.
          widget.onResult?.call(FutTapResult.redirect);
          final open = targets.where((t) => _cellAt(t) == null).toList();
          _flashCell(open.isEmpty ? widget.target : open.first);
        }
    }
  }

  void _place(int i, int value, {int owner = 0}) {
    SfxController.instance.play(SoundId.place); // tutorials get placement feedback too (spec §2)
    setState(() => _demoPlaced[i] = TutPawn(owner, value));
  }

  // Capture: the gold pawn lands on the opponent's cell (overwriting it). The bordeaux "leaves" via
  // the cell's AnimatedSwitcher scale-out and the gold pawn pops in with its gold ripple.
  void _capture(int i, int value) {
    SfxController.instance.play(SoundId.place);
    setState(() => _demoPlaced[i] = TutPawn(0, value));
  }

  void _redirect() {
    widget.onResult?.call(FutTapResult.redirect);
    _flashCell(widget.target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    final cols = widget.cols;
    final rows = widget.rows;
    final gap = cols >= 4 ? 6.0 : 8.0;
    const pad = 10.0;
    final cell = (widget.size - pad * 2 - gap * (cols - 1)) / cols;

    Offset centerOf(int i) {
      final r = i ~/ cols, c = i % cols;
      return Offset(pad + c * (cell + gap) + cell / 2, pad + r * (cell + gap) + cell / 2);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: theme.panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.accent.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18, offset: const Offset(0, 8))],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(pad),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cols * rows,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
              ),
              itemBuilder: (context, i) => _cell(theme, i, cell),
            ),
          ),
          if (_showWin && _activeWinLine != null)
            Positioned.fill(
              child: TutorialWinLine(
                start: centerOf(_activeWinLine!.first),
                end: centerOf(_activeWinLine!.last),
                // Gold when we win; bordeaux when the opponent does (forced-loss demo).
                color: widget.demoMode == TutMode.lose ? theme.discGlow(1) : theme.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(GameTheme theme, int i, double size) {
    final pawn = _cellAt(i);
    // In shape mode the still-open target cells pulse gold (alongside any explicit highlight).
    final isTarget = pawn == null &&
        widget.demoMode == TutMode.shape &&
        (widget.targets?.contains(i) ?? false);
    final isHighlight = pawn == null &&
        (widget.highlight == i || (widget.highlights?.contains(i) ?? false) || isTarget);
    final isFlash = _flash == i;
    // On a Morph win the 4 shape cells pulse with a gold glow (no line).
    final isWinShape = _won && (_winShape?.contains(i) ?? false);

    return GestureDetector(
      onTap: widget.interactive ? () => _onTap(i) : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          Color border = theme.cellEmptyBorder;
          List<BoxShadow>? glow;
          if (isWinShape) {
            border = Color.lerp(theme.accent, theme.accentGlow, t)!;
            glow = [
              BoxShadow(color: theme.accentGlow.withValues(alpha: 0.35 + 0.45 * t), blurRadius: 14 + 12 * t),
            ];
          } else if (isFlash) {
            border = theme.danger;
            glow = [BoxShadow(color: theme.danger.withValues(alpha: 0.6), blurRadius: 14)];
          } else if (isHighlight) {
            border = Color.lerp(theme.accent.withValues(alpha: 0.5), theme.accentGlow, t)!;
            glow = [BoxShadow(color: theme.accentGlow.withValues(alpha: 0.15 + 0.35 * t), blurRadius: 8 + 8 * t)];
          }
          return Container(
            decoration: BoxDecoration(
              color: theme.cell,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: isHighlight || isFlash || isWinShape ? 2 : 1),
              boxShadow: glow,
            ),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: pawn == null
            ? Icon(Icons.add, color: theme.accent.withValues(alpha: 0.3), size: size * 0.3)
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (c, anim) => ScaleTransition(scale: anim, child: c),
                child: Padding(
                  // Only the loop's active cell varies with the phase, so surrounding pawns stay put
                  // and don't re-pop every cycle — keeping the capture effect on the center pawn alone.
                  key: ValueKey('fp-$i-${pawn.owner}-${pawn.value}-'
                      '${widget.loop && i == widget.loopPlaceCell ? _placedPhase : false}'),
                  padding: EdgeInsets.all(size * 0.08),
                  child: PawnWidget(
                    owner: pawn.owner,
                    value: pawn.value,
                    showValue: true,
                    size: size * 0.84,
                    animateIn: _isFreshPlacement(i),
                    captured: false, // gold/own glow ripple (not the red capture-of-ours tint)
                  ),
                ),
              ),
      ),
    );
  }
}

/// Bonanza's deal showcase (spec §1, §6): a "Number: N" badge, then the gold group and the bordeaux
/// group revealed chip-by-chip with a fading glow (gold first, then bordeaux). Non-interactive.
class DealShowcase extends StatefulWidget {
  final String badgeText;
  final List<int> gold;
  final List<int> bord;
  final String goldLabel;
  final String bordLabel;

  const DealShowcase({
    super.key,
    required this.badgeText,
    required this.gold,
    required this.bord,
    required this.goldLabel,
    required this.bordLabel,
  });

  @override
  State<DealShowcase> createState() => _DealShowcaseState();
}

class _DealShowcaseState extends State<DealShowcase> with SingleTickerProviderStateMixin {
  late final int _total = widget.gold.length + widget.bord.length;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Duration(milliseconds: 500 + _total * 280))..forward();
  late final List<Animation<double>> _anims = _buildAnims();

  List<Animation<double>> _buildAnims() {
    final step = 1.0 / _total;
    return [
      for (var k = 0; k < _total; k++)
        CurvedAnimation(
          parent: _c,
          // Slight overlap so the reveal flows; each chip pops in within its window.
          curve: Interval(k * step * 0.85, (k * step * 0.85 + step).clamp(0.0, 1.0),
              curve: Curves.easeOutBack),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Column(
          children: [
            _badge(theme),
            const SizedBox(height: 22),
            _label(theme, widget.goldLabel),
            const SizedBox(height: 8),
            _group(theme, widget.gold, owner: 0, indexOffset: 0),
            const SizedBox(height: 14),
            Container(width: 120, height: 1, color: theme.muted.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            _label(theme, widget.bordLabel),
            const SizedBox(height: 8),
            _group(theme, widget.bord, owner: 1, indexOffset: widget.gold.length),
          ],
        );
      },
    );
  }

  Widget _badge(GameTheme theme) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: theme.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.accent, width: 1.5),
        ),
        child: Text(widget.badgeText,
            style: theme.display(20, color: theme.accent).copyWith(letterSpacing: 1.2)),
      );

  Widget _label(GameTheme theme, String s) =>
      Text(s.toUpperCase(), style: theme.label(11, color: theme.muted, weight: FontWeight.w700));

  Widget _group(GameTheme theme, List<int> values, {required int owner, required int indexOffset}) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < values.length; i++) _chip(theme, owner, values[i], indexOffset + i),
      ],
    );
  }

  Widget _chip(GameTheme theme, int owner, int value, int globalIndex) {
    final t = _anims[globalIndex].value.clamp(0.0, 1.0);
    // A glow that peaks mid-reveal and fades as the chip settles.
    final glow = (t < 1.0) ? (1.0 - (t - 0.5).abs() * 2).clamp(0.0, 1.0) : 0.0;
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.6 + 0.4 * t,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glow > 0
                ? [BoxShadow(color: theme.discGlow(owner).withValues(alpha: 0.6 * glow), blurRadius: 16 * glow)]
                : null,
          ),
          child: PawnWidget(owner: owner, value: value, showValue: true, size: 46, animateIn: false),
        ),
      ),
    );
  }
}

/// A rail of selectable medallion chips for demo steps (spec §3, §6). [owner] 0 = gold (ours),
/// 1 = bordeaux (the opponent pawns you're forced to play in Bonanza).
class HandRail extends StatelessWidget {
  final List<int> values;
  final int? selectedIndex;
  final void Function(int index) onSelect;
  final String label;
  final int owner;

  const HandRail({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onSelect,
    required this.label,
    this.owner = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    return Column(
      children: [
        Text(label.toUpperCase(), style: theme.label(11, color: theme.muted, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          children: [
            for (var i = 0; i < values.length; i++)
              GestureDetector(
                onTap: () => onSelect(i),
                // Selection is a glow only — no lift/translate/clone (that caused a ghost copy on
                // mobile). One widget, fixed position; PawnWidget(selected:) lights its halo.
                child: PawnWidget(
                  owner: owner,
                  value: values[i],
                  showValue: true,
                  size: 46,
                  animateIn: false,
                  selected: selectedIndex == i,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
