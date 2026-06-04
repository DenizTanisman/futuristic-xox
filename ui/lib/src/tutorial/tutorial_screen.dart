import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/game_theme.dart';
import 'tutorial_board.dart';
import 'tutorial_controller.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// A reusable tutorial player (spec §0, §6): header (progress dots + always-on Skip), an animated body
/// per step (info / gif-loop / triple showcase / tap demo), and a footer button.
///
/// The tutorial wears its **mode's** identity (the cold-metallic Classic [GameTheme] for the Classic
/// tutorial — silver tones), exactly like the in-game screen, rather than the warm app theme. `onExit`
/// is called on Skip and on finishing the last step — the destination is the caller's choice.
class TutorialScreen extends StatefulWidget {
  final List<TutorialStep> steps;
  final GameTheme theme;
  final VoidCallback onExit;
  const TutorialScreen({super.key, required this.steps, required this.theme, required this.onExit});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

enum _Feedback { none, wrong, great }

class _TutorialScreenState extends State<TutorialScreen> {
  late final TutorialController c = TutorialController(steps: widget.steps);
  _Feedback _feedback = _Feedback.none;
  Timer? _advance;

  GameTheme get t => widget.theme;

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
    return Container(
      decoration: BoxDecoration(gradient: t.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: c,
            builder: (context, _) {
              final step = c.current;
              return Column(
                children: [
                  _header(l),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SingleChildScrollView(
                        key: ValueKey(c.stepIndex),
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: _stepBody(l, step),
                      ),
                    ),
                  ),
                  _footer(l, step),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
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
                      color: i == c.stepIndex ? t.accent : t.muted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onExit, // Skip exits immediately from any step (spec §0).
            child: Text(l.tutSkip, style: t.label(14, color: t.muted, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _stepBody(AppLocalizations l, TutorialStep step) {
    final boardSize = (MediaQuery.of(context).size.width - 80).clamp(220.0, 320.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(step.title(l), textAlign: TextAlign.center, style: t.display(22, color: t.accent)),
        const SizedBox(height: 10),
        Text(step.body(l), textAlign: TextAlign.center, style: t.label(15, color: t.ink).copyWith(height: 1.5)),
        const SizedBox(height: 22),
        _visual(l, step, boardSize),
        if (step.kind == TutKind.demo) ...[
          const SizedBox(height: 16),
          _demoHint(l, step),
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
              Text(step.triples![i].caption(l), style: t.label(12, color: t.muted)),
            ],
          ),
      ],
    );
  }

  Widget _demoHint(AppLocalizations l, TutorialStep step) {
    final (text, color) = switch (_feedback) {
      _Feedback.great => (l.tutHintGreat, const Color(0xFF4CC38A)),
      _Feedback.wrong => (l.tutHintWrong, t.danger),
      _Feedback.none => (step.hint?.call(l) ?? '', t.muted),
    };
    return Text(text, textAlign: TextAlign.center, style: t.label(14, color: color, weight: FontWeight.w700));
  }

  Widget _footer(AppLocalizations l, TutorialStep step) {
    final buttonText = step.button?.call(l);
    if (buttonText == null) return const SizedBox(height: 24);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () => c.isLast ? widget.onExit() : c.next(),
          child: Text(buttonText, style: t.display(16, color: Colors.black)),
        ),
      ),
    );
  }
}

/// The Classic tutorial — wears the cold-metallic Classic identity (silver tones).
class ClassicTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const ClassicTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) =>
      TutorialScreen(steps: classicTutorialSteps(), theme: GameTheme.classic, onExit: onExit);
}
