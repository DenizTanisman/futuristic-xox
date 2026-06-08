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

/// A "budget" so large the wall clock never reaches it → the time box is effectively off. Used by the
/// dev self-play harness ([DartGameApi.selfPlayStep]) for deterministic, depth-only search.
const int _kNoTimeBox = 1 << 50;

/// Max pawn value across all modes is 11 (spec §3.2); slot 0 covers Classic symbols, +1 headroom.
const int _kValueSlots = 13;

/// A transposition-table entry (mirrors `ai/src/hash.rs` + `hard.rs`): the search value for a
/// position, how deep it was proven to, and an alpha-beta bound flag (0 = exact, 1 = lower, 2 = upper).
/// `best` is the move that produced it, replayed first next time for sharper pruning.
class _TtEntry {
  final int depth;
  final int value;
  final int flag;
  final _Move? best;
  const _TtEntry(this.depth, this.value, this.flag, this.best);
}

/// Which move the per-turn selector plays (mirrors `ai::SelectionPolicy`). `rastgele()` = a uniformly
/// random legal move. The per-side difficulty tiers map onto these four (see `_policyFor`).
enum SelectionPolicy {
  /// Always the strongest move (`first`).
  alwaysBest,

  /// Uniformly one of the top-3: 0 = first, 1 = second, 2 = third.
  top3Uniform,

  /// Mid mix: 0 = second, 1 = third, 2 = `rastgele()`.
  midMix,

  /// Low mix: 0 = third, 1 = `rastgele()`.
  lowMix,
}

/// The top-3 ranked moves, strongest first (mirrors `ai::AdversarialChoice`). Always fully populated;
/// slots repeat the weakest available move when fewer than three distinct moves exist.
class _Choice {
  final _Move first;
  final _Move second;
  final _Move third;
  const _Choice(this.first, this.second, this.third);
}

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
  late int _winLen; // cells in a row to win (3 normally; Classic 4×4 "long" = 4)
  late _State _s;
  late List<List<int>> _lines;
  late List<List<int>> _placements; // Morph: placements of the chosen shape only
  int? _bonanzaOwnCount;
  MorphShape? _morphShape;
  late Random _rng;

  // Transposition table + Zobrist keys for the search (mirrors the Rust TT, ai/src/hash.rs).
  // The Dart backend was previously TT-less, so it explored far fewer nodes per time-box than the
  // native engine and collapsed to shallow, greedy play on phones — the "Hard isn't hard" report.
  final Map<int, _TtEntry> _tt = {};
  late List<int> _zBoard; // flattened [cell*2+owner]*_kValueSlots + value random keys
  late List<int> _zTurn; // [2]
  late List<int> _zMoves; // [0,1,2] moves-left-in-turn

  @override
  Snapshot newGame(
      {required Mode4 mode, required int rows, required int cols, int? seed, int winLen = 3}) {
    _mode = mode;
    _rows = rows;
    _cols = cols;
    // Classic honors winLen (3 = "short", 4 = "long"); other line modes are always 3-in-a-row.
    _winLen = mode == Mode4.classic ? winLen : 3;
    final s = seed ?? DateTime.now().microsecondsSinceEpoch;
    _rng = Random(s);
    _lines = lineSegments(rows, cols, _winLen);

    if (mode == Mode4.morph) {
      final shapeIdx = Random(s).nextInt(3);
      _morphShape = MorphShape.values[shapeIdx];
      _placements = morphPlacementsForShape(rows, cols, shapeIdx);
    } else {
      _morphShape = null;
      _placements = const [];
    }

    _initZobrist(rows * cols);

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
        // Single alternating placement now (one move per turn).
        return _State(board, [own(0, vals), own(1, vals)], 0, 1);
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
    final pool0 = List<int>.generate(n, (i) => i + 1)..shuffle(rng); // own colour (0)
    final pool1 = List<int>.generate(n, (i) => i + 1)..shuffle(rng); // opponent colour (1)

    // Random per-colour split, remainder to the other side; then sort ASCENDING WITHIN EACH COLOUR
    // (never across the whole hand — Bonanza has two tile types). Compose colour-0 group, then colour-1.
    final p0Gold = pool0.take(k).toList()..sort();
    final p1Gold = pool0.skip(k).toList()..sort();
    final p0Bord = pool1.take(n - k).toList()..sort();
    final p1Bord = pool1.skip(n - k).toList()..sort();

    final h0 = <_HandPawn>[
      ...p0Gold.map((v) => _HandPawn(0, v)),
      ...p0Bord.map((v) => _HandPawn(1, v)),
    ];
    final h1 = <_HandPawn>[
      ...p1Gold.map((v) => _HandPawn(0, v)),
      ...p1Bord.map((v) => _HandPawn(1, v)),
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

  int? _winner(_State s) => _winningGroup(s)?.owner;

  /// The winning group (owner + its cells) if any — used both for the outcome and the win-line overlay.
  ({int owner, List<int> cells})? _winningGroup(_State s) {
    if (_mode == Mode4.morph) {
      for (final p in _placements) {
        final a = s.board[p[0]];
        if (a != null && p.every((c) => s.board[c]?.owner == a.owner)) {
          return (owner: a.owner, cells: p);
        }
      }
    } else {
      // Variable-length lines (3 normally; Classic 4×4 "long" = 4): all cells share one owner.
      for (final l in _lines) {
        final a = s.board[l[0]];
        if (a != null && l.every((c) => s.board[c]?.owner == a.owner)) {
          return (owner: a.owner, cells: l);
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
      winningCells: _winningGroup(s)?.cells ?? const [],
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
    // own cells before the finishing one: Morph shape = 3; line modes = winLen-1 (2 short, 3 long).
    final need = _mode == Mode4.morph ? 3 : _winLen - 1;
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
    if (_legalMoves(_s).isEmpty) {
      return MoveResult(
        applied: false,
        captured: false,
        singleMoveFallback: false,
        illegalReason: null,
        snapshot: snapshot(),
      );
    }
    // Per-turn varying seed from the game RNG → deterministic per game, varied across turns.
    final seed = _rng.nextInt(1 << 32);
    final mv = _playMove(_policyFor(_mode, difficulty), seed);
    if (mv == null) {
      return MoveResult(
        applied: false,
        captured: false,
        singleMoveFallback: false,
        illegalReason: null,
        snapshot: snapshot(),
      );
    }
    return _commit(mv);
  }

  /// Dev/test only (self-play harness): commit one best move — the adversarial `first` option.
  ///
  /// - `timeMs > 0` → iterative deepening within that per-move time box (the harness uses 2000 ms);
  ///   strong but *not* reproducible across machines (timing decides the depth reached).
  /// - `timeMs == 0` → **time box off**, search to `maxDepth` only → deterministic, reproducible
  ///   records (used by the determinism tests). A full-depth "perfect" search is infeasible beyond
  ///   tiny boards (Original 4×4 depth 6 ≈ 70 s), hence the time box for real harness runs.
  ///
  /// `maxDepth` is the safety cap; with a time box set high so the clock governs. Real play
  /// ([aiMove]) keeps its own 450 ms box untouched. Returns the [MoveResult], or null at a terminal.
  MoveResult? selfPlayStep({int timeMs = 0, int maxDepth = 64}) {
    if (_outcome(_s) != Outcome.inProgress || _legalMoves(_s).isEmpty) return null;
    final mv = _adversarialSearch(
      budgetMsOverride: timeMs == 0 ? _kNoTimeBox : timeMs,
      maxDepthOverride: maxDepth,
    )?.first;
    if (mv == null) return null;
    return _commit(mv);
  }

  // ---- AI: adversarial top-3 search + per-side difficulty tiers ----
  // Mirrors the Rust crate (ai/src/adversarial.rs + ai/src/lib.rs SelectionPolicy / play_move), which
  // is the source of truth. The interior negamax + transposition table + time box are unchanged; only
  // the root collects an honest top-3, and a stateless selection layer picks which option to play.

  /// Per-side tier → policy. The Futuristic (valued) side has four tiers; Classic three. `Classic +
  /// impossible` can't be selected in the UI, but is folded to always-best defensively.
  SelectionPolicy _policyFor(Mode4 mode, Difficulty d) {
    if (mode == Mode4.classic) {
      switch (d) {
        case Difficulty.easy:
          return SelectionPolicy.lowMix;
        case Difficulty.medium:
          return SelectionPolicy.top3Uniform;
        case Difficulty.hard:
        case Difficulty.impossible:
          return SelectionPolicy.alwaysBest;
      }
    }
    switch (d) {
      case Difficulty.easy:
        return SelectionPolicy.lowMix;
      case Difficulty.medium:
        return SelectionPolicy.midMix;
      case Difficulty.hard:
        return SelectionPolicy.top3Uniform;
      case Difficulty.impossible:
        return SelectionPolicy.alwaysBest;
    }
  }

  /// Choose the move to play this turn under `policy`, driven by a seedable die. **Roll-first:** weaker
  /// tiers that land on `rastgele()` skip the (expensive) search entirely. Stateless — no anti-streak
  /// (the mixes provide enough variety). Returns null only at a terminal position.
  _Move? _playMove(SelectionPolicy policy, int seed) {
    final rng = Random(seed);
    switch (policy) {
      case SelectionPolicy.alwaysBest:
        return _adversarialSearch()?.first;
      case SelectionPolicy.top3Uniform:
        final pick = rng.nextInt(3);
        final c = _adversarialSearch();
        if (c == null) return null;
        return pick == 0 ? c.first : (pick == 1 ? c.second : c.third);
      case SelectionPolicy.midMix:
        final pick = rng.nextInt(3);
        if (pick == 2) return _rastgele(rng); // skip the search
        final c = _adversarialSearch();
        if (c == null) return null;
        return pick == 0 ? c.second : c.third;
      case SelectionPolicy.lowMix:
        final pick = rng.nextInt(2);
        if (pick == 1) return _rastgele(rng); // skip the search
        return _adversarialSearch()?.third;
    }
  }

  /// `rastgele()` — a uniformly random legal move (the legacy Easy primitive). Caller guarantees ≥1.
  _Move _rastgele(Random rng) {
    final moves = _legalMoves(_s);
    return moves[rng.nextInt(moves.length)];
  }

  /// The top-3 ranked moves (`first ≥ second ≥ third`), or null at a terminal position. Top-k
  /// alpha-beta at the root (bound held at the 3rd-best) keeps pruning while giving honest 2nd/3rd
  /// scores. An immediate win is forced into `first` so the strongest tiers convert it even at the
  /// shallow depth a phone reaches in the time box.
  _Choice? _adversarialSearch({int? budgetMsOverride, int? maxDepthOverride}) {
    final all = _legalMoves(_s);
    if (all.isEmpty) return null;

    final winning = _winningMove(_s);
    // Restrict the ranked pool to moves that don't hand the opponent an immediate win (line modes;
    // Morph returns all). Keeps even the weaker 2nd/3rd picks from blundering into a one-move loss.
    final candidates = _safeCandidates(all);
    if (candidates.length == 1 && winning == null) {
      final m = candidates.first;
      return _Choice(m, m, m);
    }

    _tt.clear();
    final sw = Stopwatch()..start();
    // Defaults = real play (time-boxed). The dev self-play harness overrides with the time box off
    // (huge budget the wall clock never reaches) + a depth cap → deterministic, reproducible records.
    final budgetMs = budgetMsOverride ?? 450;
    final maxDepth = maxDepthOverride ?? (_mode == Mode4.morph ? 6 : (_rows == 3 ? 9 : 8));

    // Seed with the static ordering so a result exists even if depth 1 times out mid-way.
    var ranked = <(_Move, int)>[for (final m in _ordered(candidates, _s).take(3)) (m, 0)];
    _Move? prevFirst = ranked.first.$1;
    for (var depth = 1; depth <= maxDepth; depth++) {
      final top = _searchRootTop3(candidates, depth, prevFirst, sw, budgetMs);
      if (sw.elapsedMilliseconds > budgetMs) break; // discard partial depth
      if (top.isNotEmpty) {
        ranked = top;
        prevFirst = ranked.first.$1;
      }
      if (ranked.first.$2.abs() >= _kWin - maxDepth) break; // forced result proven
    }

    var first = ranked[0].$1;
    final second = ranked.length > 1 ? ranked[1].$1 : first;
    final third = ranked.length > 2 ? ranked[2].$1 : second;
    if (winning != null) first = winning; // strongest play always converts an immediate win
    return _Choice(first, second, third);
  }

  /// One depth of the top-k (k = 3) root search. Bound held at the current 3rd-best (`-inf` until the
  /// top-3 is full), `beta = inf`: moves below 3rd fail low and are dropped, moves that break in are
  /// scored exactly. Returns the ranked `(move, score)` list, strongest first.
  List<(_Move, int)> _searchRootTop3(
      List<_Move> candidates, int depth, _Move? prevFirst, Stopwatch sw, int budgetMs) {
    const beta = _kInf;
    final top = <(_Move, int)>[];
    for (final m in _orderedWithTt(candidates, _s, prevFirst)) {
      final alpha = top.length >= 3 ? top[2].$2 : -_kInf;
      final child = _s.copy();
      _apply(child, m);
      final samePlayer = child.turn == _s.turn;
      final score = samePlayer
          ? _negamax(child, depth - 1, alpha, beta, sw, budgetMs)
          : -_negamax(child, depth - 1, -beta, -alpha, sw, budgetMs);
      if (sw.elapsedMilliseconds > budgetMs) break;
      if (top.length < 3 || score > top[2].$2) {
        var pos = top.indexWhere((e) => e.$2 < score);
        if (pos < 0) pos = top.length;
        top.insert(pos, (m, score));
        if (top.length > 3) top.removeLast();
      }
    }
    return top;
  }

  /// A single placement that completes the side-to-move's line/shape *right now* (immediate win),
  /// or null. Early-exits on the first win, so it is cheap even when none exists.
  _Move? _winningMove(_State s) {
    final me = s.turn;
    for (final m in _legalMoves(s)) {
      final child = s.copy();
      _apply(child, m);
      if (_winner(child) == me) return m;
    }
    return null;
  }

  /// Moves that do **not** let the opponent win on their immediate reply. Line modes only (one move
  /// per turn, so the reply is a single placement — O(b²), cheap). Morph's two-move turns would make
  /// this O(b³); there we return every move and rely on the time-boxed search instead. Falls back to
  /// all moves when nothing is safe (a lost position — still has to move).
  List<_Move> _safeCandidates(List<_Move> moves) {
    if (_mode == Mode4.morph) return moves;
    final me = _s.turn;
    final safe = <_Move>[];
    for (final m in moves) {
      final child = _s.copy();
      _apply(child, m);
      // After a line-mode move the turn always flips; if the opponent then has a one-move win, skip.
      if (child.turn != me && _winningMove(child) != null) continue;
      safe.add(m);
    }
    return safe.isEmpty ? moves : safe;
  }

  int _negamax(_State s, int depth, int alpha, int beta, Stopwatch sw, int budgetMs) {
    final w = _winner(s);
    if (w != null) {
      // perspective of side to move at s
      return (w == s.turn) ? (_kWin - depth) : (depth - _kWin);
    }
    if (!_hasLegalMove(s)) return 0; // draw
    if (depth == 0 || sw.elapsedMilliseconds > budgetMs) return _heuristic(s);

    final key = _hash(s);
    final alphaOrig = alpha;
    _Move? ttMove;
    final entry = _tt[key];
    if (entry != null) {
      ttMove = entry.best;
      if (entry.depth >= depth) {
        if (entry.flag == 0) return entry.value; // exact
        if (entry.flag == 1 && entry.value > alpha) alpha = entry.value; // lower bound
        if (entry.flag == 2 && entry.value < beta) beta = entry.value; // upper bound
        if (alpha >= beta) return entry.value;
      }
    }

    var best = -_kInf;
    _Move? bestMove;
    var timedOut = false;
    for (final m in _orderedWithTt(_legalMoves(s), s, ttMove)) {
      final child = s.copy();
      _apply(child, m);
      final samePlayer = child.turn == s.turn;
      final score = samePlayer
          ? _negamax(child, depth - 1, alpha, beta, sw, budgetMs)
          : -_negamax(child, depth - 1, -beta, -alpha, sw, budgetMs);
      if (score > best) {
        best = score;
        bestMove = m;
      }
      if (best > alpha) alpha = best;
      if (alpha >= beta) break; // cutoff
      if (sw.elapsedMilliseconds > budgetMs) {
        timedOut = true;
        break;
      }
    }

    // Don't pollute the TT with a value from a search the clock cut short.
    if (!timedOut) {
      final flag = best <= alphaOrig ? 2 : (best >= beta ? 1 : 0);
      _tt[key] = _TtEntry(depth, best, flag, bestMove);
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

  /// Static ordering, but with the transposition table's remembered best move hoisted to the front —
  /// the single most effective ordering improvement for alpha-beta pruning (spec §7.7.2/§7.7.3).
  List<_Move> _orderedWithTt(List<_Move> moves, _State s, _Move? ttMove) {
    final list = _ordered(moves, s);
    if (ttMove != null) {
      final i = list.indexWhere(
          (m) => m.cell == ttMove.cell && m.color == ttMove.color && m.value == ttMove.value);
      if (i > 0) list.insert(0, list.removeAt(i));
    }
    return list;
  }

  // ---- transposition-table hashing (mirrors ai/src/hash.rs) ----

  void _initZobrist(int cells) {
    // Fixed seed → stable keys, like the native Zobrist. Native Dart ints are 64-bit.
    final r = Random(0x5345);
    int rnd64() => (r.nextInt(1 << 32) << 32) ^ r.nextInt(1 << 32);
    _zBoard = List<int>.generate(cells * 2 * _kValueSlots, (_) => rnd64());
    _zTurn = [rnd64(), rnd64()];
    _zMoves = [rnd64(), rnd64(), rnd64()];
  }

  /// A 64-bit key for the full state: board (Zobrist XOR), turn, moves-left, and both hands. Hands are
  /// multisets so a plain XOR would cancel duplicates — fold an order-independent, count-sensitive
  /// mixer per colour+value instead.
  int _hash(_State s) {
    var h = 0;
    for (var c = 0; c < s.board.length; c++) {
      final p = s.board[c];
      if (p != null) {
        final v = p.value > 12 ? 12 : p.value;
        h ^= _zBoard[(c * 2 + p.owner) * _kValueSlots + v];
      }
    }
    h ^= _zTurn[s.turn & 1];
    h ^= _zMoves[s.movesLeft > 2 ? 2 : s.movesLeft];
    for (var pl = 0; pl < 2; pl++) {
      final keys = s.hands[pl].map((e) => e.color * 100 + e.value).toList()..sort();
      var acc = 0xcbf29ce484222325 ^ (pl * 0x9E3779B9);
      for (final k in keys) {
        acc = (acc ^ (k + 1)) * 0x100000001b3;
      }
      h ^= acc;
    }
    return h;
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
      if (blocked || mine != _winLen - 1 || open == null) continue;
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
