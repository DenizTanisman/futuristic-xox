import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/game_theme.dart';
import '../widgets/pawn_widget.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// Result of a demo tap on the Futuristic board (spec §3); the screen maps it to a localized hint.
enum FutTapResult { noSelection, redirect, tooSmall, placed, placedWin, captured, capturedWin }

/// A Futuristic (Original) tutorial board: valued medallion cells (gold = ours, bordeaux = opponent),
/// a faint `+` on empty cells, a pulsing gold highlight, the gif-style place/capture showcase loop,
/// and select-then-place demo interaction with capture rules (spec §1–§4). Keyed by step in the
/// screen so its loop timer is cancelled on step change / dispose.
class FuturisticTutorialBoard extends StatefulWidget {
  final List<TutPawn?> cells;
  final double size;
  final int? highlight;

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

  final List<int>? winLine;

  /// Force the win line to always show (static info board, e.g. the win-rule showcase).
  final bool showWin;

  const FuturisticTutorialBoard({
    super.key,
    required this.cells,
    required this.size,
    this.highlight,
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

  bool get _showWin => widget.winLine != null && (widget.showWin || (widget.loop ? false : _won));

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
    }
  }

  void _place(int i, int value) => setState(() => _demoPlaced[i] = TutPawn(0, value));

  // Capture: the gold pawn lands on the opponent's cell (overwriting it). The bordeaux "leaves" via
  // the cell's AnimatedSwitcher scale-out and the gold pawn pops in with its gold ripple.
  void _capture(int i, int value) => setState(() => _demoPlaced[i] = TutPawn(0, value));

  void _redirect() {
    widget.onResult?.call(FutTapResult.redirect);
    _flashCell(widget.target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = GameTheme.of(context);
    const gap = 8.0;
    const pad = 10.0;
    final cell = (widget.size - pad * 2 - gap * 2) / 3;

    Offset centerOf(int i) {
      final r = i ~/ 3, c = i % 3;
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
              itemCount: 9,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
              ),
              itemBuilder: (context, i) => _cell(theme, i, cell),
            ),
          ),
          if (_showWin && widget.winLine != null)
            Positioned.fill(
              child: TutorialWinLine(
                start: centerOf(widget.winLine!.first),
                end: centerOf(widget.winLine!.last),
                color: theme.accent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(GameTheme theme, int i, double size) {
    final pawn = _cellAt(i);
    final isHighlight = widget.highlight == i && pawn == null;
    final isFlash = _flash == i;

    return GestureDetector(
      onTap: widget.interactive ? () => _onTap(i) : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          Color border = theme.cellEmptyBorder;
          List<BoxShadow>? glow;
          if (isFlash) {
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
              border: Border.all(color: border, width: isHighlight || isFlash ? 2 : 1),
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

/// A rail of selectable gold medallion chips for demo steps (spec §3, §6).
class HandRail extends StatelessWidget {
  final List<int> values;
  final int? selectedIndex;
  final void Function(int index) onSelect;
  final String label;

  const HandRail({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.onSelect,
    required this.label,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  transform: Matrix4.translationValues(0, selectedIndex == i ? -6 : 0, 0),
                  child: PawnWidget(
                    owner: 0,
                    value: values[i],
                    showValue: true,
                    size: 46,
                    animateIn: false,
                    selected: selectedIndex == i,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
