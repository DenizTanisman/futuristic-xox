import 'dart:math';

import '../models/game_models.dart';
import 'game_api.dart';
import 'geometry.dart';

/// Pure-Dart mock backend: a faithful port of the engine rules (spec §3–§5) plus a lightweight AI,
/// so the UI is fully playable without the Rust toolchain. The native backend (flutter_rust_bridge
/// → `bridge::GameSession`) replaces this with the real engine + negamax AI behind the same [GameApi].
///
/// Rule parity with `engine/`: strict-greater capture with permanent deletion (§3.3), 3-in-a-row and
/// 4-cell Morph shapes (§3.4, §5), two moves per turn with single-move fallback for Morph (§4.4).
class _Pawn {
  int owner;
  int value;
  _Pawn(this.owner, this.value);
  _Pawn copy() => _Pawn(owner, value);
}

class _State {
  List<_Pawn?> board;
  List<List<int>> hands;
  int turn;
  int movesLeft;
  _State(this.board, this.hands, this.turn, this.movesLeft);

  _State copy() => _State(
        board.map((p) => p?.copy()).toList(),
        [List<int>.from(hands[0]), List<int>.from(hands[1])],
        turn,
        movesLeft,
      );
}

class DartGameApi implements GameApi {
  late Mode4 _mode;
  late int _rows;
  late int _cols;
  late _State _s;
  late List<List<int>> _lines;
  late List<List<int>> _placements;
  final Random _rng = Random();

  @override
  Snapshot newGame({required Mode4 mode, required int rows, required int cols, int? seed}) {
    _mode = mode;
    _rows = rows;
    _cols = cols;
    _lines = lineTriples(rows, cols);
    _placements = mode == Mode4.morph ? morphPlacements(rows, cols) : const [];
    _s = _initialState(mode, rows, cols, seed);
    return snapshot();
  }

  // ---- setup (mirrors engine/src/setup.rs) ----

  _State _initialState(Mode4 mode, int rows, int cols, int? seed) {
    final cells = rows * cols;
    final board = List<_Pawn?>.filled(cells, null);
    switch (mode) {
      case Mode4.classic:
        final p0 = (cells + 1) ~/ 2;
        return _State(board, [List.filled(p0, 0), List.filled(cells - p0, 0)], 0, 1);
      case Mode4.original:
        final n = _originalPawns(cells);
        final hand = List<int>.generate(n, (i) => i + 1);
        return _State(board, [List.from(hand), List.from(hand)], 0, 1);
      case Mode4.bonanza:
        return _State(board, _bonanzaHands(_originalPawns(cells), seed), 0, 1);
      case Mode4.morph:
        final n = cells == 16 ? 6 : 11;
        final hand = <int>[];
        for (var v = 1; v <= n; v++) {
          hand..add(v)..add(v);
        }
        return _State(board, [List.from(hand), List.from(hand)], 0, 2);
    }
  }

  int _originalPawns(int cells) => cells == 9 ? 6 : (cells == 16 ? 11 : max(1, cells * 11 ~/ 16));

  List<List<int>> _bonanzaHands(int n, int? seed) {
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    final k = rng.nextInt(n + 1);
    final pool0 = List<int>.generate(n, (i) => i + 1)..shuffle(rng);
    final pool1 = List<int>.generate(n, (i) => i + 1)..shuffle(rng);
    final h0 = <int>[...pool0.take(k), ...pool1.take(n - k)]..sort();
    final h1 = <int>[...pool0.skip(k), ...pool1.skip(n - k)]..sort();
    return [h0, h1];
  }

  // ---- rules ----

  bool _placementLegal(_State s, int cell, int value, int owner) {
    final p = s.board[cell];
    if (p == null) return true;
    if (p.owner == owner) return false;
    return value > p.value;
  }

  bool _isMoveLegal(_State s, int? value, int cell) {
    if (cell < 0 || cell >= s.board.length) return false;
    if (!_mode.valued) {
      return value == null && s.board[cell] == null && s.hands[s.turn].isNotEmpty;
    }
    if (value == null) return false;
    return s.hands[s.turn].contains(value) && _placementLegal(s, cell, value, s.turn);
  }

  List<List<int>> _legalMoves(_State s) {
    final out = <List<int>>[]; // [value(-1 for classic), cell]
    if (!_mode.valued) {
      if (s.hands[s.turn].isEmpty) return out;
      for (var c = 0; c < s.board.length; c++) {
        if (s.board[c] == null) out.add([-1, c]);
      }
      return out;
    }
    final values = s.hands[s.turn].toSet().toList()..sort();
    for (var c = 0; c < s.board.length; c++) {
      final p = s.board[c];
      for (final v in values) {
        if (p == null) {
          out.add([v, c]);
        } else if (p.owner != s.turn && v > p.value) {
          out.add([v, c]);
        }
      }
    }
    return out;
  }

  bool _hasLegalMove(_State s) => _legalMoves(s).isNotEmpty;

  void _apply(_State s, int? value, int cell) {
    final owner = s.turn;
    final v = _mode.valued ? value! : 0;
    s.board[cell] = _Pawn(owner, v);
    s.hands[owner].remove(_mode.valued ? v : 0);
    final perTurn = _mode.twoMovesPerTurn ? 2 : 1;
    s.movesLeft -= 1;
    if (s.movesLeft == 0) {
      s.turn ^= 1;
      s.movesLeft = perTurn;
    } else if (!_hasLegalMove(s)) {
      // single-move fallback (spec §4.4)
      s.turn ^= 1;
      s.movesLeft = perTurn;
    }
  }

  int? _winner(_State s) {
    if (_mode == Mode4.morph) {
      for (final p in _placements) {
        final a = s.board[p[0]];
        if (a != null && p.every((c) => s.board[c]?.owner == a.owner)) return a.owner;
      }
    } else {
      for (final l in _lines) {
        final a = s.board[l[0]];
        if (a != null && s.board[l[1]]?.owner == a.owner && s.board[l[2]]?.owner == a.owner) {
          return a.owner;
        }
      }
    }
    return null;
  }

  Outcome _outcome(_State s) {
    final w = _winner(s);
    if (w != null) return w == 0 ? Outcome.win0 : Outcome.win1;
    if (!_hasLegalMove(s)) return Outcome.draw;
    return Outcome.inProgress;
  }

  // ---- GameApi ----

  @override
  Snapshot snapshot() {
    final board = _s.board
        .map((p) => p == null
            ? const CellView.empty()
            : CellView(owner: p.owner, value: p.value, empty: false))
        .toList();
    return Snapshot(
      rows: _rows,
      cols: _cols,
      board: board,
      hand0: List.from(_s.hands[0]),
      hand1: List.from(_s.hands[1]),
      turn: _s.turn,
      movesLeftInTurn: _s.movesLeft,
      outcome: _outcome(_s),
    );
  }

  @override
  List<int> legalCells(int? value) {
    return _legalMoves(_s)
        .where((m) => (_mode.valued ? m[0] : null) == value)
        .map((m) => m[1])
        .toList();
  }

  @override
  MoveResult humanMove({int? value, required int cell}) {
    if (!_isMoveLegal(_s, value, cell)) {
      return MoveResult(
        applied: false,
        captured: false,
        singleMoveFallback: false,
        illegalReason: _rejectReason(value, cell),
        snapshot: snapshot(),
      );
    }
    return _commit(value, cell);
  }

  @override
  Future<MoveResult> aiMove(Difficulty difficulty) async {
    // A small delay mimics the native search latency and keeps animations smooth.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final moves = _legalMoves(_s);
    if (moves.isEmpty) {
      return MoveResult(
        applied: false,
        captured: false,
        singleMoveFallback: false,
        illegalReason: null,
        snapshot: snapshot(),
      );
    }
    final chosen = _chooseMove(difficulty, moves);
    return _commit(_mode.valued ? chosen[0] : null, chosen[1]);
  }

  // ---- mock AI (the real strength lives in the Rust `ai` crate) ----

  List<int> _chooseMove(Difficulty difficulty, List<List<int>> moves) {
    if (difficulty == Difficulty.easy) return moves[_rng.nextInt(moves.length)];
    if (difficulty == Difficulty.medium && _rng.nextBool()) {
      return moves[_rng.nextInt(moves.length)];
    }
    // Greedy 1-ply: win now > don't hand opponent a win > capture/center.
    List<int>? best;
    var bestScore = -1 << 30;
    for (final m in moves) {
      final sim = _s.copy();
      final me = sim.turn;
      final captured = _mode.valued && sim.board[m[1]] != null && sim.board[m[1]]!.owner != me;
      _apply(sim, _mode.valued ? m[0] : null, m[1]);
      var score = 0;
      final w = _winner(sim);
      if (w == me) {
        score += 100000;
      } else {
        // If, after our move, it is the opponent's turn and they can win immediately, penalize.
        if (sim.turn != me && _opponentCanWin(sim)) score -= 50000;
      }
      if (captured) score += 100 + (m[0]);
      score -= _centerDistance(m[1]); // prefer central
      score += _rng.nextInt(3); // tiny tie-break jitter
      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best ?? moves.first;
  }

  bool _opponentCanWin(_State s) {
    for (final m in _legalMoves(s)) {
      final sim = s.copy();
      final mover = sim.turn;
      _apply(sim, _mode.valued ? m[0] : null, m[1]);
      if (_winner(sim) == mover) return true;
    }
    return false;
  }

  int _centerDistance(int cell) {
    final r = cell ~/ _cols, c = cell % _cols;
    return (2 * r - (_rows - 1)).abs() + (2 * c - (_cols - 1)).abs();
  }

  // ---- helpers ----

  MoveResult _commit(int? value, int cell) {
    final turnBefore = _s.turn;
    final movesBefore = _s.movesLeft;
    final captured = _mode.valued && _s.board[cell] != null && _s.board[cell]!.owner != turnBefore;
    _apply(_s, value, cell);
    final fallback = movesBefore == 2 && _s.turn != turnBefore;
    return MoveResult(
      applied: true,
      captured: captured,
      singleMoveFallback: fallback,
      illegalReason: null,
      snapshot: snapshot(),
    );
  }

  String _rejectReason(int? value, int cell) {
    if (cell < 0 || cell >= _s.board.length) return 'Out of bounds';
    final p = _s.board[cell];
    if (!_mode.valued) return 'Cell is occupied';
    if (value == null) return 'Select a pawn value first';
    if (!_s.hands[_s.turn].contains(value)) return "You don't hold a $value";
    if (p != null && p.owner == _s.turn) return 'That is your own pawn';
    if (p != null) return 'Value $value cannot capture a ${p.value} (must be strictly greater)';
    return 'Illegal move';
  }
}
