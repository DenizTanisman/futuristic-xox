import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../audio/sfx_controller.dart';
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

  /// Action for a step's secondary "ghost" button (e.g. Bonanza's "Learn Original" cross-link).
  final VoidCallback? onSecondary;

  const TutorialScreen(
      {super.key, required this.steps, required this.theme, required this.onExit, this.onSecondary});

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
      if (c.current.winLine != null) SfxController.instance.play(SoundId.win);
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
        SfxController.instance.play(SoundId.win);
        _fb(l.tutHintWin, _green);
        _scheduleAdvance();
      case FutTapResult.placeEmpty:
        _fb(l.tutBonHintRedirectEmpty, t.danger);
      case FutTapResult.lost:
        // Forced loss: the opponent completes a line (bordeaux). Still advance — the lesson landed.
        SfxController.instance.play(SoundId.lose);
        _fb(l.tutBonHintOppWin, t.discGlow(1));
        _scheduleAdvance();
      case FutTapResult.shapeProgress:
        // Morph two-pawns-per-turn: first target filled, one more to go.
        _fb(l.tutMorphHintOneMore, t.accent);
      case FutTapResult.shapeWin:
        SfxController.instance.play(SoundId.win);
        _fb(l.tutMorphHintWin(c.current.shapeName ?? ''), _green);
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
                      // Fade-through: the old step fades fully out in the first half before the new one
                      // fades in — so medallions/boards never overlap mid-transition (no ghost copy).
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        switchInCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                        switchOutCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
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
              onSelect: (i) {
                SfxController.instance.play(SoundId.select); // Futuristic hand selection
                setState(() => _selectedHand = i);
              },
              label: step.railLabel?.call(l) ?? l.tutRailLabel,
              owner: step.handOwner,
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
        if (step.infoBadge != null) return _numberBadge(l, step.infoBadge!);
        if (step.shapeIcons != null) return _shapeIcons(step.shapeIcons!);
        if (step.bigMedallions != null) return _bigMedallions(step);
        // static info board (e.g. the win-rule showcase)
        return FuturisticTutorialBoard(
          key: ValueKey('finfo-${c.stepIndex}'),
          cells: step.fcells,
          size: boardSize,
          winLine: step.winLine,
          showWin: step.winLine != null,
        );
      case TutKind.deal:
        return DealShowcase(
          key: ValueKey('deal-${c.stepIndex}'),
          badgeText: l.tutBonBadgeNumber('${step.dealNumber}'),
          gold: step.dealGold ?? const [],
          bord: step.dealBord ?? const [],
          goldLabel: l.tutBonRailGold,
          bordLabel: l.tutBonRailBord,
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
          cols: step.gridCols,
          rows: step.gridRows,
          highlight: step.highlight,
          highlights: step.highlights,
          interactive: true,
          target: step.target,
          demoMode: step.demoMode,
          placeOwner: step.handOwner,
          loseMap: step.loseMap,
          targets: step.targets,
          winShape: step.winShape,
          winLine: step.winLine,
          selectedValue:
              (_selectedHand != null && step.hand != null) ? step.hand![_selectedHand!] : null,
          onResult: _onFutResult,
        );
      case TutKind.triple:
        return const SizedBox.shrink();
    }
  }

  Widget _numberBadge(AppLocalizations l, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: t.accent, width: 2),
        boxShadow: [BoxShadow(color: t.accentGlow.withValues(alpha: 0.25), blurRadius: 24)],
      ),
      child: Text(l.tutBonBadgeNumber(value),
          style: t.display(30, color: t.accent).copyWith(letterSpacing: 1.5)),
    );
  }

  /// Morph shape-icon explainers: small gold/dim mini-grids for I/L/Z, the diagonal, and mirror.
  Widget _shapeIcons(List<MorphIcon> icons) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 16,
      children: [for (final icon in icons) _shapeIcon(icon)],
    );
  }

  Widget _shapeIcon(MorphIcon icon) {
    const dot = 18.0;
    const gap = 5.0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.cell.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.accent.withValues(alpha: 0.3)),
      ),
      child: SizedBox(
        width: icon.cols * dot + (icon.cols - 1) * gap,
        height: icon.rows * dot + (icon.rows - 1) * gap,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: icon.cols * icon.rows,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: icon.cols,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
          ),
          itemBuilder: (context, i) {
            final on = icon.filled.contains(i);
            return Container(
              decoration: BoxDecoration(
                color: on ? t.accent : t.muted.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
                boxShadow: on
                    ? [BoxShadow(color: t.accentGlow.withValues(alpha: 0.4), blurRadius: 6)]
                    : null,
              ),
            );
          },
        ),
      ),
    );
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
      case TutKind.deal:
        return const SizedBox.shrink(); // Bonanza-only; never used by Classic
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
    final secondaryText = step.secondary?.call(l);
    final showSecondary = secondaryText != null && widget.onSecondary != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                SfxController.instance.play(SoundId.menuTap);
                c.isLast ? widget.onExit() : c.next();
              },
              child: Text(buttonText, style: t.display(16, color: Colors.black)),
            ),
          ),
          if (showSecondary)
            TextButton(
              onPressed: widget.onSecondary,
              child: Text(secondaryText,
                  style: t.label(14, color: t.accent, weight: FontWeight.w700)
                      .copyWith(decoration: TextDecoration.underline)),
            ),
        ],
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

/// The Futuristic · Bonanza tutorial — same warm gold identity, with the deal showcase, a bordeaux
/// hand rail, a forced-loss demo, and a cross-link that opens the Original tutorial.
class BonanzaTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const BonanzaTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) => TutorialScreen(
        steps: bonanzaTutorialSteps(),
        theme: GameTheme.futuristic,
        onExit: onExit,
        onSecondary: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OriginalTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
        )),
      );
}

/// The Futuristic · Morph tutorial — warm gold identity on a 4×4 board, with shape-completion wins
/// (I/L/Z, axis + diagonal, mirror), a two-pawns-per-turn demo, and a cross-link to Original.
class MorphTutorialScreen extends StatelessWidget {
  final VoidCallback onExit;
  const MorphTutorialScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context) => TutorialScreen(
        steps: morphTutorialSteps(),
        theme: GameTheme.futuristic,
        onExit: onExit,
        onSecondary: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OriginalTutorialScreen(onExit: () => Navigator.of(context).maybePop()),
        )),
      );
}
