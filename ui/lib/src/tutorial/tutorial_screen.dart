import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_themes.dart';
import 'tutorial_board.dart';
import 'tutorial_controller.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// A reusable tutorial player (spec §0, §6): header (progress dots + always-on Skip), an animated body
/// per step (info / gif-loop / triple showcase / tap demo), and a footer button. Surfaces follow the
/// app theme; the Classic marks keep their fixed silver/gold identity. `onExit` is called on Skip and
/// on finishing the last step — the destination is the caller's choice.
class TutorialScreen extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onExit;
  const TutorialScreen({super.key, required this.steps, required this.onExit});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

enum _Feedback { none, wrong, great }

class _TutorialScreenState extends State<TutorialScreen> {
  late final TutorialController c = TutorialController(steps: widget.steps);
  _Feedback _feedback = _Feedback.none;
  Timer? _advance;

  @override
  void initState() {
    super.initState();
    c.addListener(_onStepChanged);
  }

  void _onStepChanged() {
    _advance?.cancel();
    _feedback = _Feedback.none;
  }

  @override
  void dispose() {
    _advance?.cancel();
    c.removeListener(_onStepChanged);
    c.dispose();
    super.dispose();
  }

  void _onDemoResult(bool correct) {
    setState(() => _feedback = correct ? _Feedback.great : _Feedback.wrong);
    if (correct) {
      _advance?.cancel();
      _advance = Timer(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        if (c.isLast) {
          widget.onExit();
        } else {
          c.next();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lux = LuxTokens.of(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final step = c.current;
            return Column(
              children: [
                _header(l, lux),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: SingleChildScrollView(
                      key: ValueKey(c.stepIndex),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: _stepBody(l, lux, step),
                    ),
                  ),
                ),
                _footer(l, lux, step),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l, LuxTokens lux) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          // Progress dots.
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < c.count; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == c.stepIndex ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == c.stepIndex ? lux.accent : lux.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onExit, // Skip exits immediately from any step (spec §0).
            child: Text(l.tutSkip, style: TextStyle(color: lux.muted, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(AppLocalizations l, LuxTokens lux, TutorialStep step) {
    final boardSize = (MediaQuery.of(context).size.width - 80).clamp(220.0, 320.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(step.title(l), textAlign: TextAlign.center, style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.w800, color: lux.accent)),
        const SizedBox(height: 10),
        Text(step.body(l), textAlign: TextAlign.center, style: TextStyle(color: lux.ink, height: 1.5, fontSize: 15)),
        const SizedBox(height: 22),
        _visual(l, step, boardSize),
        if (step.kind == TutKind.demo) ...[
          const SizedBox(height: 16),
          _demoHint(l, lux, step),
        ],
      ],
    );
  }

  Widget _visual(AppLocalizations l, TutorialStep step, double boardSize) {
    switch (step.kind) {
      case TutKind.info:
        return _infoVisual(step, boardSize);
      case TutKind.loop:
        return TutorialBoard(
          key: ValueKey('loop-${c.stepIndex}'),
          cells: step.board,
          size: boardSize,
          highlight: step.highlight,
          loop: true,
          loopPlaceCell: step.loopPlaceCell,
          loopPlaceMark: step.loopPlaceMark,
          winLine: step.winLine,
        );
      case TutKind.demo:
        return TutorialBoard(
          key: ValueKey('demo-${c.stepIndex}'),
          cells: step.board,
          size: boardSize,
          highlight: step.highlight,
          interactive: true,
          target: step.target,
          anyEmpty: step.anyEmpty,
          winLine: step.winLine,
          onResult: _onDemoResult,
        );
      case TutKind.triple:
        return _tripleVisual(l, step);
    }
  }

  Widget _infoVisual(TutorialStep step, double boardSize) {
    final marks = step.infoVisual == InfoVisual.bigXO ? [Mark.x, Mark.o] : [Mark.x];
    return SizedBox(
      height: boardSize * 0.6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final m in marks)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TutorialMark(key: ValueKey('info-${step.infoVisual}-${m.name}'), mark: m, size: boardSize * 0.42),
            ),
        ],
      ),
    );
  }

  Widget _tripleVisual(AppLocalizations l, TutorialStep step) {
    final mini = ((MediaQuery.of(context).size.width - 80) / 3).clamp(78.0, 120.0);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < step.triples!.length; i++)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TutorialBoard(
                key: ValueKey('triple-${c.stepIndex}-$i'),
                cells: step.triples![i].base,
                size: mini,
                loop: true,
                loopPlaceCell: step.triples![i].last,
                winLine: step.triples![i].winLine,
              ),
              const SizedBox(height: 6),
              Text(step.triples![i].caption(l), style: TextStyle(color: LuxTokens.of(context).muted, fontSize: 12)),
            ],
          ),
      ],
    );
  }

  Widget _demoHint(AppLocalizations l, LuxTokens lux, TutorialStep step) {
    final (text, color) = switch (_feedback) {
      _Feedback.great => (l.tutHintGreat, const Color(0xFF4CC38A)),
      _Feedback.wrong => (l.tutHintWrong, lux.accent == const Color(0xFFB8902C) ? const Color(0xFFC0392B) : const Color(0xFFD9544D)),
      _Feedback.none => (step.hint?.call(l) ?? '', lux.muted),
    };
    return Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14));
  }

  Widget _footer(AppLocalizations l, LuxTokens lux, TutorialStep step) {
    final buttonText = step.button?.call(l);
    if (buttonText == null) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: lux.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => c.isLast ? widget.onExit() : c.next(),
          child: Text(buttonText, style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

/// Convenience: the Classic tutorial wired to its steps.
class ClassicTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const ClassicTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) => TutorialScreen(steps: classicTutorialSteps(), onExit: onExit);
}
