import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/audio_controller.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// A 3×3 Classic tutorial board: steel frame + dark cells, a pulsing silver highlight, the gif-style
/// showcase loop (spec §2), and demo tap interaction (spec §3). The board is keyed by step in the
/// screen, so changing step disposes this State and cancels its timer (spec §7 — no leaked timers).
class TutorialBoard extends StatefulWidget {
  final List<Mark?> cells;
  final double size;
  final int? highlight;

  /// Gif loop: place [loopPlaceCell] then reset, every 2s (spec §2).
  final bool loop;
  final int? loopPlaceCell;
  final Mark loopPlaceMark;

  /// Demo interaction (spec §3).
  final bool interactive;
  final int? target;
  final bool anyEmpty;

  /// Winning line cells (3) to draw when the board is "completed".
  final List<int>? winLine;

  /// Demo result callback: true = correct tap (placed), false = wrong tap.
  final void Function(bool correct)? onResult;

  const TutorialBoard({
    super.key,
    required this.cells,
    required this.size,
    this.highlight,
    this.loop = false,
    this.loopPlaceCell,
    this.loopPlaceMark = Mark.x,
    this.interactive = false,
    this.target,
    this.anyEmpty = false,
    this.winLine,
    this.onResult,
  });

  @override
  State<TutorialBoard> createState() => _TutorialBoardState();
}

class _TutorialBoardState extends State<TutorialBoard> with TickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  Timer? _loopTimer;

  /// Loop phase: false = empty, true = placed.
  bool _placed = false;

  /// Demo: cells the user has filled, and a transient "flash this cell red" marker.
  final Map<int, Mark> _demoPlaced = {};
  int? _flashCell;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    if (widget.loop) {
      _loopTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) setState(() => _placed = !_placed);
      });
    }
  }

  @override
  void dispose() {
    _loopTimer?.cancel(); // critical: no leaked loop timer (spec §7)
    _pulse.dispose();
    super.dispose();
  }

  bool get _showWinLine {
    if (widget.winLine == null) return false;
    if (widget.loop) return _placed;
    return _won;
  }

  Mark? _markAt(int i) {
    if (widget.loop && _placed && i == widget.loopPlaceCell) return widget.loopPlaceMark;
    if (_demoPlaced.containsKey(i)) return _demoPlaced[i];
    return widget.cells[i];
  }

  void _onTap(int i) {
    if (!widget.interactive || _won) return;
    if (_markAt(i) != null) return; // occupied → ignore (spec §3)
    final correct = widget.anyEmpty || i == widget.target;
    if (correct) {
      AudioController.instance.play(SoundId.place);
      setState(() {
        _demoPlaced[i] = Mark.x;
        if (widget.winLine != null) _won = true;
      });
      widget.onResult?.call(true);
    } else {
      // Flash the correct cell 3× (spec §1, §3) and keep the board.
      widget.onResult?.call(false);
      _flash(widget.target);
    }
  }

  Future<void> _flash(int? cell) async {
    if (cell == null) return;
    for (var k = 0; k < 3; k++) {
      if (!mounted) return;
      setState(() => _flashCell = cell);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      setState(() => _flashCell = null);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    const pad = 10.0;
    final cell = (widget.size - pad * 2 - gap * 2) / 3;
    final winLine = widget.winLine;

    Offset centerOf(int i) {
      final r = i ~/ 3, c = i % 3;
      return Offset(pad + c * (cell + gap) + cell / 2, pad + r * (cell + gap) + cell / 2);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Steel frame.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF161A22), Color(0xFF0B0D12)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3A3F4B), width: 1.5),
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
              itemBuilder: (context, i) => _cell(i, cell),
            ),
          ),
          if (_showWinLine && winLine != null)
            Positioned.fill(
              child: TutorialWinLine(start: centerOf(winLine.first), end: centerOf(winLine.last)),
            ),
        ],
      ),
    );
  }

  Widget _cell(int i, double size) {
    final mark = _markAt(i);
    final isHighlight = widget.highlight == i && mark == null;
    final isFlash = _flashCell == i;

    return GestureDetector(
      onTap: widget.interactive ? () => _onTap(i) : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          Color border = const Color(0xFF2A2F3A);
          List<BoxShadow>? glow;
          if (isFlash) {
            border = const Color(0xFFD9544D);
            glow = [BoxShadow(color: const Color(0xFFD9544D).withValues(alpha: 0.6), blurRadius: 14)];
          } else if (isHighlight) {
            border = Color.lerp(const Color(0xFF8A93A6), const Color(0xFFEEF1F6), t)!;
            glow = [BoxShadow(color: const Color(0xFFEEF1F6).withValues(alpha: 0.15 + 0.35 * t), blurRadius: 8 + 8 * t)];
          }
          return Container(
            decoration: BoxDecoration(
              gradient: const RadialGradient(
                center: Alignment(-0.2, -0.3),
                radius: 1.0,
                colors: [Color(0xFF161B24), Color(0xFF0C0F15)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: isHighlight || isFlash ? 2 : 1),
              boxShadow: glow,
            ),
            child: child,
          );
        },
        child: mark == null
            ? null
            : Padding(
                padding: EdgeInsets.all(size * 0.16),
                // Key by (cell, mark, phase) so a fresh placement replays the stroke-draw.
                child: TutorialMark(
                  key: ValueKey('mark-$i-${mark.name}-${widget.loop ? _placed : true}'),
                  mark: mark,
                  size: size * 0.68,
                ),
              ),
      ),
    );
  }
}
