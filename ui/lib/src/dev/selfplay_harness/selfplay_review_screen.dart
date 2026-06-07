// Dev-only self-play test harness — review screen: watch perfect-play unfold, scrub the recorded
// game. No win/lose banner; the board persists until the user leaves or starts a new test (§2.3).
library;

import 'package:flutter/material.dart';

import '../../models/game_models.dart';
import '../../theme/game_theme.dart';
import '../../widgets/board_view.dart';
import 'selfplay_driver.dart';
import 'selfplay_models.dart';

class SelfPlayReviewScreen extends StatefulWidget {
  final SelfPlayConfig config;
  const SelfPlayReviewScreen({super.key, required this.config});

  @override
  State<SelfPlayReviewScreen> createState() => _SelfPlayReviewScreenState();
}

class _SelfPlayReviewScreenState extends State<SelfPlayReviewScreen> {
  late final SelfPlaySession _session;

  @override
  void initState() {
    super.initState();
    _session = SelfPlaySession(widget.config);
    _session.start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Mode4 get _mode => widget.config.mode;

  @override
  Widget build(BuildContext context) {
    final theme = _mode == Mode4.classic ? GameTheme.classic : GameTheme.futuristic;
    return GameThemeProvider(
      theme: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0E12),
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: const Color(0xFFE9E2CC),
          title: Text('Self-Play · ${_mode.label} ${widget.config.rows}×${widget.config.cols}'),
        ),
        body: AnimatedBuilder(
          animation: _session.model,
          builder: (context, _) => _body(_session.model),
        ),
      ),
    );
  }

  Widget _body(SelfPlayViewModel m) {
    final frame = m.current;
    return Column(
      children: [
        const _DevBanner(),
        Expanded(
          child: Center(
            child: frame == null
                ? const _Computing()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: AspectRatio(
                      aspectRatio: widget.config.cols / widget.config.rows,
                      child: BoardView(
                        snapshot: frame.snapshot,
                        showValues: _mode.valued,
                        classic: _mode == Mode4.classic,
                        highlightedCells: const [],
                        lastMoveCell: frame.lastMoveCell,
                        lastWasCapture: frame.lastWasCapture,
                        onTap: (_) {}, // read-only review
                        interactive: false,
                      ),
                    ),
                  ),
          ),
        ),
        if (frame != null) _status(m, frame),
        _controls(m),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _status(SelfPlayViewModel m, SelfPlayFrame frame) {
    final last = m.frames.length - 1;
    final shape = frame.snapshot.morphShape;
    final outcome = frame.snapshot.outcome;
    // It is a test environment: report the recorded outcome plainly as text, NOT a win/lose banner.
    final outcomeText = switch (outcome) {
      Outcome.inProgress => '',
      Outcome.win0 => '· result: ${_mode == Mode4.classic ? 'X' : 'bordeaux'} (0)',
      Outcome.win1 => '· result: ${_mode == Mode4.classic ? 'O' : 'gold'} (1)',
      Outcome.draw => '· result: draw',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SideDot(side: frame.snapshot.turn),
          const SizedBox(width: 8),
          Text(
            'ply ${m.viewIndex} / $last'
            '${m.producing ? ' (computing…)' : ''}'
            '${shape != null ? '  · shape ${shape.letter}' : ''}'
            '  $outcomeText',
            style: const TextStyle(color: Color(0xFFC9C2AC), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _controls(SelfPlayViewModel m) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(Icons.skip_previous, 'önceki', m.canPrev ? m.prev : null),
          _btn(Icons.replay, 'tekrar', m.frames.isEmpty ? null : m.replay),
          _btn(Icons.skip_next, 'sonraki', m.canNext ? m.next : null),
          _btn(Icons.refresh, 'yeni test', () => Navigator.of(context).pop()),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    final color = enabled ? const Color(0xFFE9E2CC) : const Color(0xFF55524A);
    return TextButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DevBanner extends StatelessWidget {
  const _DevBanner();
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFF2A1E08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const Text(
          'DEV self-play · deterministic best-play (time-box off). Desktop CPU ≫ phone — '
          'validates correctness/flow/look, not on-phone 450 ms strength.',
          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
        ),
      );
}

class _Computing extends StatelessWidget {
  const _Computing();
  @override
  Widget build(BuildContext context) => const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFFD4AF37)),
          SizedBox(height: 12),
          Text('computing first move…', style: TextStyle(color: Color(0xFFC9C2AC))),
        ],
      );
}

class _SideDot extends StatelessWidget {
  final int side;
  const _SideDot({required this.side});
  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: side == 0 ? const Color(0xFF7A2230) : const Color(0xFFD4AF37),
        ),
      );
}
