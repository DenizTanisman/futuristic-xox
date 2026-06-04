import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/game_theme.dart';
import '../widgets/pawn_widget.dart';
import 'tutorial_board.dart';
import 'tutorial_controller.dart';
import 'tutorial_futuristic_board.dart';
import 'tutorial_painters.dart';
import 'tutorial_step.dart';

/// A reusable tutorial player (spec §0, §6): header (progress dots + always-on Skip), an animated body
/// per step (info / gif-loop / triple showcase / tap demo), and a footer button. Handles both Classic
/// (X/O marks) and Futuristic (valued medallion pawns + hand rail + capture) steps.
///
/// The tutorial wears its **mode's** identity ([GameTheme]); marks/medallions keep their fixed colours.
/// `onExit` is called on Skip and on finishing the last step — the destination is the caller's choice.
class TutorialScreen extends StatefulWidget {
  final List<TutorialStep> steps;
  final GameTheme theme;
  final VoidCallback onExit;
  const TutorialScreen({super.key, required this.steps, required this.theme, required this.onExit});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final TutorialController c = TutorialController(steps: widget.steps);
  Timer? _advance;

  // Demo feedback (overrides the step's default hint) + Futuristic hand selection.
  String? _fbText;
  Color? _fbColor;
  int? _selectedHand;

  GameTheme get t => widget.theme;
  static const _green = Color(0xFF4CC38A);

  @override
  void initState() {
    super.initState();
    c.addListener(_onStepChanged);
  }

  void _onStepChanged() {
    _advance?.cancel();
    setState(() {
      _fbText = null;
      _fbColor = null;
      _selectedHand = null;
    });
  }

  @override
  void dispose() {
    _advance?.cancel();
    c.removeListener(_onStepChanged);
    c.dispose();
    super.dispose();
  }

  void _scheduleAdvance() {
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 1150), () {
      if (!mounted) return;
      if (c.isLast) {
        widget.onExit();
      } else {
        c.next();
      }
    });
  }

  void _fb(String text, Color color) => setState(() {
        _fbText = text;
        _fbColor = color;
      });

  // Classic demo result.
  void _onClassicResult(bool correct) {
    final l = AppLocalizations.of(context)!;
    if (correct) {
      _fb(l.tutHintGreat, _green);
      _scheduleAdvance();
    } else {
      _fb(l.tutHintWrong, t.danger);
    }
  }

  // Futuristic demo result.
  void _onFutResult(FutTapResult r) {
    final l = AppLocalizations.of(context)!;
    switch (r) {
      case FutTapResult.noSelection:
        _fb(l.tutHintSelect, t.danger);
      case FutTapResult.redirect:
        _fb(l.tutHintRedirect, t.danger);
      case FutTapResult.tooSmall:
        _fb(l.tutHintSmall, t.danger);
      case FutTapResult.placed:
      case FutTapResult.captured:
        _fb(l.tutHintGreat, _green);
        _scheduleAdvance();
      case FutTapResult.placedWin:
      case FutTapResult.capturedWin:
        _fb(l.tutHintWin, _green);
        _scheduleAdvance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GameThemeProvider(
      theme: t,
      child: Container(
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
            onPressed: widget.onExit,
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
        step.futuristic ? _futVisual(l, step, boardSize) : _classicVisual(l, step, boardSize),
        if (step.kind == TutKind.demo) ...[
          if (step.futuristic && step.hand != null) ...[
            const SizedBox(height: 18),
            HandRail(
              values: step.hand!,
              selectedIndex: _selectedHand,
              onSelect: (i) => setState(() => _selectedHand = i),
              label: l.tutRailLabel,
            ),
          ],
          const SizedBox(height: 14),
          _demoHint(l, step),
        ],
      ],
    );
  }

  // ---- Futuristic visuals ----

  Widget _futVisual(AppLocalizations l, TutorialStep step, double boardSize) {
    switch (step.kind) {
      case TutKind.info:
        if (step.bigMedallions != null) return _bigMedallions(step);
        // static info board (e.g. the win-rule showcase)
        return FuturisticTutorialBoard(
          key: ValueKey('finfo-${c.stepIndex}'),
          cells: step.fcells,
          size: boardSize,
          winLine: step.winLine,
          showWin: step.winLine != null,
        );
      case TutKind.loop:
        return FuturisticTutorialBoard(
          key: ValueKey('floop-${c.stepIndex}'),
          cells: step.fcells,
          size: boardSize,
          highlight: step.highlight,
          loop: true,
          loopPlaceCell: step.loopPlaceCell,
          loopValue: step.loopValue,
          loopOwner: step.loopOwner,
          eatAt: step.eatAt,
        );
      case TutKind.demo:
        return FuturisticTutorialBoard(
          key: ValueKey('fdemo-${c.stepIndex}'),
          cells: step.fcells,
          size: boardSize,
          highlight: step.highlight,
          interactive: true,
          target: step.target,
          demoMode: step.demoMode,
          winLine: step.winLine,
          selectedValue:
              (_selectedHand != null && step.hand != null) ? step.hand![_selectedHand!] : null,
          onResult: _onFutResult,
        );
      case TutKind.triple:
        return const SizedBox.shrink();
    }
  }

  Widget _bigMedallions(TutorialStep step) {
    final meds = step.bigMedallions!;
    final children = <Widget>[];
    for (var i = 0; i < meds.length; i++) {
      if (i > 0 && step.gtrSeparator) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('>', style: t.display(40, color: t.accent)),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: PawnWidget(
          key: ValueKey('bigmed-${step.title}-${meds[i].owner}-${meds[i].value}-$i'),
          owner: meds[i].owner,
          value: meds[i].value,
          showValue: true,
          size: 96,
          animateIn: false,
        ),
      ));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }

  // ---- Classic visuals ----

  Widget _classicVisual(AppLocalizations l, TutorialStep step, double boardSize) {
    switch (step.kind) {
      case TutKind.info:
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
          onResult: _onClassicResult,
        );
      case TutKind.triple:
        return _tripleVisual(l, step);
    }
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
    final text = _fbText ?? step.hint?.call(l) ?? '';
    final color = _fbColor ?? t.muted;
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

/// The Classic tutorial — cold-metallic identity (silver tones).
class ClassicTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const ClassicTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) =>
      TutorialScreen(steps: classicTutorialSteps(), theme: GameTheme.classic, onExit: onExit);
}

/// The Futuristic · Original tutorial — warm gold identity, valued medallion pawns.
class OriginalTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const OriginalTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) =>
      TutorialScreen(steps: originalTutorialSteps(), theme: GameTheme.futuristic, onExit: onExit);
}
