// Dev-only self-play test harness — setup: pick mode → grid → (Bonanza seed / Morph shape) → make the
// single human first move, then launch the perfect-play review (§2.1). Reachable only behind kDebugMode.
library;

import 'package:flutter/material.dart';

import '../../game/dart_game_api.dart';
import '../../models/game_models.dart';
import '../../theme/game_theme.dart';
import '../../widgets/board_view.dart';
import '../../widgets/pawn_widget.dart';
import 'selfplay_models.dart';
import 'selfplay_review_screen.dart';

class SelfPlaySetupScreen extends StatefulWidget {
  const SelfPlaySetupScreen({super.key});

  @override
  State<SelfPlaySetupScreen> createState() => _SelfPlaySetupScreenState();
}

class _SelfPlaySetupScreenState extends State<SelfPlaySetupScreen> {
  Mode4? _mode;
  int? _grid;
  MorphShape _shape = MorphShape.i;
  final TextEditingController _seedCtrl = TextEditingController(text: '0');

  // First-move selection.
  int? _selColor;
  int? _selValue;
  int? _firstCell;

  // Live preview engine for the chosen setup (gives the initial board + side-0 hand + legality).
  DartGameApi? _preview;
  Snapshot? _snap;

  @override
  void dispose() {
    _seedCtrl.dispose();
    super.dispose();
  }

  bool get _valued => _mode != null && _mode!.valued;

  /// Seed that realizes the current setup: Bonanza → the user's seed; Morph → a seed whose chosen
  /// shape matches (search is cheap, hands are seed-independent in Morph); otherwise irrelevant.
  int get _effectiveSeed {
    if (_mode == Mode4.bonanza) return int.tryParse(_seedCtrl.text.trim()) ?? 0;
    if (_mode == Mode4.morph) return _seedForMorphShape(_grid!, _shape);
    return 0;
  }

  int _seedForMorphShape(int grid, MorphShape shape) {
    for (var s = 0; s < 1000; s++) {
      final snap = DartGameApi().newGame(mode: Mode4.morph, rows: grid, cols: grid, seed: s);
      if (snap.morphShape == shape) return s;
    }
    return 0;
  }

  void _rebuildPreview() {
    if (_mode == null || _grid == null) {
      _preview = null;
      _snap = null;
      return;
    }
    final api = DartGameApi();
    final snap = api.newGame(mode: _mode!, rows: _grid!, cols: _grid!, seed: _effectiveSeed);
    _preview = api;
    _snap = snap;
    _selColor = null;
    _selValue = null;
    _firstCell = null;
  }

  List<int> get _legalCells {
    if (_preview == null) return const [];
    if (!_valued) {
      // Classic: any empty cell.
      final s = _snap!;
      return [for (var i = 0; i < s.board.length; i++) if (s.board[i].empty) i];
    }
    if (_selValue == null) return const [];
    return _preview!.legalCells(color: _selColor, value: _selValue);
  }

  bool get _canRun => _firstCell != null && (!_valued || _selValue != null);

  void _run() {
    final config = SelfPlayConfig(
      mode: _mode!,
      rows: _grid!,
      cols: _grid!,
      seed: _effectiveSeed,
      firstColor: _valued ? _selColor : null,
      firstValue: _valued ? _selValue : null,
      firstCell: _firstCell!,
      // timeMs/maxDepth default to the 2 s harness time box + a high safety cap.
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SelfPlayReviewScreen(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFE9E2CC),
        title: const Text('Self-Play Setup (dev)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Mode'),
            _chips<Mode4>(
              Mode4.values,
              _mode,
              (m) => m.label,
              (m) => setState(() {
                _mode = m;
                _grid = null;
                _rebuildPreview();
              }),
            ),
            if (_mode != null) ...[
              const SizedBox(height: 16),
              _label('Grid'),
              _chips<int>(
                _mode!.grids,
                _grid,
                (g) => '$g×$g',
                (g) => setState(() {
                  _grid = g;
                  _rebuildPreview();
                }),
              ),
            ],
            if (_mode == Mode4.bonanza && _grid != null) ...[
              const SizedBox(height: 16),
              _label('Bonanza seed (u64)'),
              TextField(
                controller: _seedCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFFE9E2CC)),
                decoration: const InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(color: Color(0xFF6A6658)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF3A3730))),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
                onChanged: (_) => setState(_rebuildPreview),
              ),
            ],
            if (_mode == Mode4.morph && _grid != null) ...[
              const SizedBox(height: 16),
              _label('Morph shape'),
              _chips<MorphShape>(
                MorphShape.values,
                _shape,
                (s) => s.letter,
                (s) => setState(() {
                  _shape = s;
                  _rebuildPreview();
                }),
              ),
            ],
            if (_grid != null) ...[
              const SizedBox(height: 20),
              _label(_valued ? 'First move — pick a pawn, then a cell' : 'First move — tap a cell'),
              if (_valued) _handPicker(),
              const SizedBox(height: 12),
              _firstMoveBoard(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canRun ? _run : null,
                child: const Text('Run perfect play →'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _handPicker() {
    final hand = _snap!.hand0;
    // Distinct (color, value) chips — duplicates (Morph holds two of each) collapse to one.
    final seen = <int>{};
    final distinct = <HandPawnView>[];
    for (final h in hand) {
      if (seen.add(h.color * 100 + h.value)) distinct.add(h);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final h in distinct)
          GestureDetector(
            onTap: () => setState(() {
              _selColor = h.color;
              _selValue = h.value;
              _firstCell = null;
            }),
            child: PawnWidget(
              owner: h.color,
              value: h.value,
              showValue: true,
              size: 40,
              selected: _selColor == h.color && _selValue == h.value,
              animateIn: false,
            ),
          ),
      ],
    );
  }

  Widget _firstMoveBoard() {
    final theme = _mode == Mode4.classic ? GameTheme.classic : GameTheme.futuristic;
    final legal = _legalCells;
    return GameThemeProvider(
      theme: theme,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AspectRatio(
            aspectRatio: 1,
            child: BoardView(
              snapshot: _snap!,
              showValues: _valued,
              classic: _mode == Mode4.classic,
              highlightedCells: _firstCell != null ? [_firstCell!] : legal,
              lastMoveCell: _firstCell,
              lastWasCapture: false,
              interactive: true,
              onTap: (cell) {
                if (!legal.contains(cell)) return; // gate on legality
                setState(() => _firstCell = cell);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---- small themed helpers ----

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF9A9484), fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _chips<T>(List<T> values, T? selected, String Function(T) label, void Function(T) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: selected == v,
            onSelected: (_) => onTap(v),
            backgroundColor: const Color(0xFF1B1B22),
            selectedColor: const Color(0xFFD4AF37),
            labelStyle: TextStyle(
                color: selected == v ? Colors.black : const Color(0xFFE9E2CC)),
          ),
      ],
    );
  }
}
