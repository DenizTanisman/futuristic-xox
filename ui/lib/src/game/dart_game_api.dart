import 'dart:math';

import '../models/game_models.dart';
import 'game_api.dart';
import 'geometry.dart';

/// Pure-Dart mock backend: a faithful port of the engine rules (spec §3–§5) plus a real
/// negamax + alpha-beta AI, so the UI is fully playable — and the Hard difficulty genuinely strong —
/// without the Rust toolchain. The native backend (flutter_rust_bridge → `bridge::GameSession`)
/// replaces this with the production engine + AI behind the same [GameApi].
///
/// Rule parity with the spec: strict-greater capture with permanent deletion (§3.3); 3-in-a-row and
/// a single chosen Morph shape (§3.4, §4.4, §5); two moves per turn with single-move fallback (§4.4);
/// Bonanza hands may hold opponent-coloured pawns whose owner-on-board is the pawn's colour (§4.3).

const int _kWin = 1000;
const int _kInf = 1 << 29;

class _Pawn {
  int owner;
  int value;
  _Pawn(this.owner, this.value);
  _Pawn copy() => _Pawn(owner, value);
}

/// A pawn in hand. `color` becomes its board owner when placed (differs from the holder only in
/// Bonanza, spec §4.3). Classic stores symbol tokens as value 0.
class _HandPawn {
  int color;
  int value;
  _HandPawn(this.color, this.value);
  _HandPawn copy() => _HandPawn(color, value);
}

class _Move {
  final int? color; // pawn colour to place (null for Classic symbols)
  final int? value; // null for Classic
  final int cell;
  const _Move(this.color, this.value, this.cell);
}

class _State {
  List<_Pawn?> board;
  List<List<_HandPawn>> hands;
  int turn;
  int movesLeft;
  _State(this.board, this.hands, this.turn, this.movesLeft);

  _State copy() => _State(
        board.map((p) => p?.copy()).toList(),
        [hands[0].map((h) => h.copy()).toList(), hands[1].map((h) => h.copy()).toList()],
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
  late List<List<int>> _placements; // Morph: placements of the chosen shape only
  int? _bonanzaOwnCount;
  MorphShape? _morphShape;
  late Random _rng;

  @override
  Snapshot newGame({required Mode4 mode, required int rows, required int cols, int? seed}) {
    _mode = mode;
    _rows = rows;
    _cols = cols;
    final s = seed ?? DateTime.now().microsecondsSinceEpoch;
    _rng = Random(s);
    _lines = lineTriples(rows, cols);

    if (mode == Mode4.morph) {
      final shapeIdx = Random(s).nextInt(3);
      _morphShape = MorphShape.values[shapeIdx];
      _placements = morphPlacementsForShape(rows, cols, shapeIdx);
    } else {
      _morphShape = null;
      _placements = const [];
    }

    _s = _initialState(mode, rows, cols, s);
    return snapshot();
  }

  // ---- setup (mirrors engine/src/setup.rs, extended for per-pawn colour) ----

  _State _initialState(Mode4 mode, int rows, int cols, int seed) {
    final cells = rows * cols;
    final board = List<_Pawn?>.filled(cells, null, growable: false);
    List<_HandPawn> own(int color, Iterable<int> values) =>
        values.map((v) => _HandPawn(color, v)).toList();

    switch (mode) {
      case Mode4.classic:
        final p0 = (cells + 1) ~/ 2;
        return _State(
          board,
          [own(0, List.filled(p0, 0)), own(1, List.filled(cells - p0, 0))],
          0,
          1,
        );
      case Mode4.original:
        final n = _originalPawns(cells);
        final vals = List<int>.generate(n, (i) => i + 1);
        return _State(board, [own(0, vals), own(1, vals)], 0, 1);
      case Mode4.bonanza:
        return _State(board, _bonanzaHands(_originalPawns(cells), seed), 0, 1);
      case Mode4.morph:
        final n = cells == 16 ? 6 : 11;
        final vals = [for (var v = 1; v <= n; v++) ...[v, v]];
        return _State(board, [own(0, vals), own(1, vals)], 0, 2);
    }
  }

  int _originalPawns(int cells) => cells == 9 ? 6 : (cells == 16 ? 11 : max(1, cells * 11 ~/ 16));

  /// Bonanza (spec §4.3): two colour pools of `1..=N`. Player 0 takes `k` pawns from pool 0 and
  /// `N-k` from pool 1; player 1 takes the complements. Each player may therefore hold a mix of
  /// their own and the opponent's colour. `_bonanzaOwnCount` = `k` (player 0's own-colour count).
  List<List<_HandPawn>> _bonanzaHands(int n, int seed) {
    final rng = Random(seed);
    final k = rng.nextInt(n + 1);
    _bonanzaOwnCount = k;
    final pool0 = List<int>.generate(n, (i) => i + 1)..shuffle(rng);
    final pool1 = List<int>.generate(n, (i) => i + 1)..shuffle(rng);

    final h0 = <_HandPawn>[
      ...pool0.take(k).map((v) => _HandPawn(0, v)),
      ...pool1.take(n - k).map((v) => _HandPawn(1, v)),
    ];
    final h1 = <_HandPawn>[
      ...pool0.skip(k).map((v) => _HandPawn(0, v)),
      ...pool1.skip(n - k).map((v) => _HandPawn(1, v)),
    ];
    return [h0, h1];
  }

  // ---- rules ----

  bool _placementLegal(_State s, int cell, int color, int value) {
    final p = s.board[cell];
    if (p == null) return true;
    if (p.owner == color) return false; // cannot stack/capture your own colour
    return value > p.value; // strict-greater captures (spec §3.3)
  }

  List<_Move> _legalMoves(_State s) {
    final out = <_Move>[];
    final hand = s.hands[s.turn];
    if (!_mode.valued) {
      if (hand.isEmpty) return out;
      for (var c = 0; c < s.board.length; c++) {
        if (s.board[c] == null) out.add(_Move(s.turn, null, c));
      }
      return out;
    }
    // Distinct (colour, value) pairs in hand.
    final seen = <int>{};
    final distinct = <_HandPawn>[];
    for (final h in hand) {
      final key = h.color * 100 + h.value;
      if (seen.add(key)) distinct.add(h);
    }
    for (var c = 0; c < s.board.length; c++) {
      for (final h in distinct) {
        if (_placementLegal(s, c, h.color, h.value)) {
          out.add(_Move(h.color, h.value, c));
        }
      }
    }
    return out;
  }

  bool _hasLegalMove(_State s) => _legalMoves(s).isNotEmpty;

  void _apply(_State s, _Move m) {
    final color = _mode.valued ? m.color! : s.turn;
    final value = _mode.valued ? m.value! : 0;
    s.board[m.cell] = _Pawn(color, value);
    // remove one matching hand pawn from the player to move
    final hand = s.hands[s.turn];
    final idx = hand.indexWhere((h) => h.color == color && h.value == value);
    if (idx >= 0) hand.removeAt(idx);

    final perTurn = _mode.twoMovesPerTurn ? 2 : 1;
    s.movesLeft -= 1;
    if (s.movesLeft == 0) {
      s.turn ^= 1;
      s.movesLeft = perTurn;
    } else if (!_hasLegalMove(s)) {
      s.turn ^= 1; // single-move fallback (spec §4.4)
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
  Snapshot snapshot() => _snapshotOf(_s);

  Snapshot _snapshotOf(_State s) {
    final board = s.board
        .map((p) => p == null
            ? const CellView.empty()
            : CellView(owner: p.owner, value: p.value, empty: false))
        .toList();
    List<HandPawnView> view(List<_HandPawn> h) =>
        h.map((e) => HandPawnView(color: e.color, value: e.value)).toList();
    return Snapshot(
      rows: _rows,
      cols: _cols,
      board: board,
      hand0: view(s.hands[0]),
      hand1: view(s.hands[1]),
      turn: s.turn,
      movesLeftInTurn: s.movesLeft,
      outcome: _outcome(s),
      bonanzaOwnCount: _bonanzaOwnCount,
      morphShape: _morphShape,
    );
  }

  @override
  List<int> legalCells({int? color, int? value}) {
    return _legalMoves(_s)
        .where((m) => m.color == (color ?? m.color) && m.value == value)
        .where((m) => _mode.valued ? (m.color == color && m.value == value) : true)
        .map((m) => m.cell)
        .toList();
  }

  @override
  List<int> completingCells() {
    final me = _s.turn;
    final groups = _mode == Mode4.morph ? _placements : _lines;
    final need = _mode == Mode4.morph ? 3 : 2; // own cells before the finishing one
    final myColorPawns = _s.hands[me].where((h) => h.color == me);
    final result = <int>{};
    for (final g in groups) {
      var mine = 0;
      int? open;
      var blocked = false;
      for (final c in g) {
        final p = _s.board[c];
        if (p != null && p.owner == me) {
          mine++;
        } else if (open == null) {
          open = c;
        } else {
          blocked = true;
        }
      }
      if (blocked || mine != need || open == null) continue;
      final target = _s.board[open];
      final bool canPlace;
      if (!_mode.valued) {
        canPlace = target == null && _s.hands[me].isNotEmpty;
      } else if (target == null) {
        canPlace = myColorPawns.isNotEmpty; // need an own-colour pawn to extend my own line/shape
      } else {
        canPlace = target.owner != me && myColorPawns.any((h) => h.value > target.value);
      }
      if (canPlace) result.add(open);
    }
    return result.toList();
  }

  @override
  MoveResult humanMove({int? color, int? value, required int cell}) {
    final legal = _legalMoves(_s)
        .any((m) => m.cell == cell && m.color == (_mode.valued ? color : m.color) && m.value == value);
    if (!legal) {
      return MoveResult(
        applied: false,
        captured: false,
        singleMoveFallback: false,
        illegalReason: _rejectReason(color, value, cell),
        snapshot: snapshot(),
      );
    }
    return _commit(_Move(_mode.valued ? color : _s.turn, value, cell));
  }

  @override
  Future<MoveResult> aiMove(Difficulty difficulty) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
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
    return _commit(_chooseMove(difficulty, moves));
  }

  // ---- AI: real negamax + alpha-beta (mirrors ai/src/hard.rs) ----

  _Move _chooseMove(Difficulty difficulty, List<_Move> moves) {
    if (difficulty == Difficulty.easy) return moves[_rng.nextInt(moves.length)];
    if (difficulty == Difficulty.medium && _rng.nextBool()) {
      return moves[_rng.nextInt(moves.length)];
    }
    // Hard (and half of Medium): iterative-deepening negamax with a time box.
    final sw = Stopwatch()..start();
    const budgetMs = 450;
    final maxDepth = _mode == Mode4.morph ? 5 : (_rows == 3 ? 9 : 7);

    var best = _ordered(moves, _s).first;
    for (var depth = 1; depth <= maxDepth; depth++) {
      var alpha = -_kInf;
      const beta = _kInf;
      _Move? localBest;
      var bestScore = -_kInf;
      var aborted = false;
      for (final m in _ordered(moves, _s)) {
        final child = _s.copy();
        _apply(child, m);
        final samePlayer = child.turn == _s.turn;
        final score = samePlayer
            ? _negamax(child, depth - 1, alpha, beta, sw, budgetMs)
            : -_negamax(child, depth - 1, -beta, -alpha, sw, budgetMs);
        if (sw.elapsedMilliseconds > budgetMs) {
          aborted = true;
          break;
        }
        if (score > bestScore) {
          bestScore = score;
          localBest = m;
        }
        if (bestScore > alpha) alpha = bestScore;
      }
      if (localBest != null && !aborted) best = localBest;
      if (aborted) break;
      if (bestScore.abs() >= _kWin - maxDepth) break; // forced result proven
    }
    return best;
  }

  int _negamax(_State s, int depth, int alpha, int beta, Stopwatch sw, int budgetMs) {
    final w = _winner(s);
    if (w != null) {
      // perspective of side to move at s
      return (w == s.turn) ? (_kWin - depth) : (depth - _kWin);
    }
    if (!_hasLegalMove(s)) return 0; // draw
    if (depth == 0 || sw.elapsedMilliseconds > budgetMs) return _heuristic(s);

    var best = -_kInf;
    for (final m in _ordered(_legalMoves(s), s)) {
      final child = s.copy();
      _apply(child, m);
      final samePlayer = child.turn == s.turn;
      final score = samePlayer
          ? _negamax(child, depth - 1, alpha, beta, sw, budgetMs)
          : -_negamax(child, depth - 1, -beta, -alpha, sw, budgetMs);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break; // cutoff
      if (sw.elapsedMilliseconds > budgetMs) break;
    }
    return best;
  }

  List<_Move> _ordered(List<_Move> moves, _State s) {
    final list = List<_Move>.from(moves);
    list.sort((a, b) {
      final ga = _captureGain(s, a), gb = _captureGain(s, b);
      if (ga != gb) return gb - ga; // captures first
      final va = a.value ?? 0, vb = b.value ?? 0;
      if (va != vb) return va - vb; // cheaper pawn first (MVV-LVA)
      return _centerDistance(a.cell) - _centerDistance(b.cell);
    });
    return list;
  }

  int _captureGain(_State s, _Move m) {
    final p = s.board[m.cell];
    return (p != null && m.color != null && p.owner != m.color) ? p.value : 0;
  }

  int _heuristic(_State s) {
    final me = s.turn, opp = 1 - s.turn;
    if (_mode == Mode4.morph) {
      final shape = _shapeProgress(s, me) - _shapeProgress(s, opp);
      return 40 * shape + _economy(s, me, opp) + 3 * _centerControl(s, me, opp);
    }
    final threats = _threats(s, me) - _threats(s, opp);
    return 30 * threats + _economy(s, me, opp) + 5 * _centerControl(s, me, opp);
  }

  int _economy(_State s, int me, int opp) {
    int sum(int p) => s.hands[p].fold(0, (a, h) => a + h.value);
    return sum(me) - sum(opp);
  }

  int _centerControl(_State s, int me, int opp) {
    int count(int who) => List.generate(s.board.length, (i) => i)
        .where((c) => _centerDistance(c) == 0 && s.board[c]?.owner == who)
        .length;
    return count(me) - count(opp);
  }

  int _maxHandValue(_State s, int color) {
    var mx = 0;
    for (final h in s.hands[s.turn]) {
      if (h.value > mx) mx = h.value;
    }
    return mx;
  }

  int _threats(_State s, int color) {
    final maxHand = _maxHandValue(s, color);
    var count = 0;
    for (final line in _lines) {
      var mine = 0;
      int? open;
      var blocked = false;
      for (final cell in line) {
        final p = s.board[cell];
        if (p != null && p.owner == color) {
          mine++;
        } else {
          if (open != null) blocked = true;
          open = cell;
        }
      }
      if (blocked || mine != 2 || open == null) continue;
      final p = s.board[open];
      final usable = p == null || (p.owner != color && maxHand > p.value);
      if (usable) count++;
    }
    return count;
  }

  int _shapeProgress(_State s, int color) {
    var best = 0;
    for (final p in _placements) {
      var mine = 0;
      var blocked = false;
      for (final cell in p) {
        final q = s.board[cell];
        if (q != null && q.owner == color) {
          mine++;
        } else if (q != null) {
          blocked = true;
          break;
        }
      }
      if (!blocked && mine > best) best = mine;
    }
    return best;
  }

  // ---- helpers ----

  int _centerDistance(int cell) {
    final r = cell ~/ _cols, c = cell % _cols;
    return (2 * r - (_rows - 1)).abs() + (2 * c - (_cols - 1)).abs();
  }

  MoveResult _commit(_Move m) {
    final turnBefore = _s.turn;
    final movesBefore = _s.movesLeft;
    final target = _s.board[m.cell];
    final placingColor = _mode.valued ? m.color! : turnBefore;
    final captured = target != null && target.owner != placingColor;
    _apply(_s, m);
    final fallback = movesBefore == 2 && _s.turn != turnBefore;
    return MoveResult(
      applied: true,
      captured: captured,
      singleMoveFallback: fallback,
      illegalReason: null,
      snapshot: snapshot(),
    );
  }

  String _rejectReason(int? color, int? value, int cell) {
    if (cell < 0 || cell >= _s.board.length) return 'Out of bounds';
    final p = _s.board[cell];
    if (!_mode.valued) return 'Cell is occupied';
    if (value == null || color == null) return 'Select a pawn first';
    final holds = _s.hands[_s.turn].any((h) => h.color == color && h.value == value);
    if (!holds) return "You don't hold that pawn";
    if (p != null && p.owner == color) return 'That colour already owns this cell';
    if (p != null) return 'Value $value cannot capture a ${p.value} (must be strictly greater)';
    return 'Illegal move';
  }
}
