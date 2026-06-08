// Dev-only self-play test harness — driver: the background producer + the scrub view-model.
//
// Producer/viewer are decoupled (work order §2.3): the producer plays the whole game to a terminal
// position and streams every [SelfPlayFrame] back; the viewer scrubs over whatever has been produced.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../game/dart_game_api.dart';
import '../../models/game_models.dart';
import 'selfplay_models.dart';

/// Play a full game from `config` and emit every frame in order: frame 0 = the state right after the
/// human's first move, then one frame per deterministic best move (time-box-off, depth-capped) until a
/// terminal position. Synchronous and side-effect-free except `emit` — used both inside the producer
/// isolate and directly in unit tests.
void produceSelfPlay(SelfPlayConfig config, void Function(SelfPlayFrame) emit) {
  final api = DartGameApi();
  api.newGame(
      mode: config.mode,
      rows: config.rows,
      cols: config.cols,
      seed: config.seed,
      winLen: config.winLen);

  final first = api.humanMove(
    color: config.firstColor,
    value: config.firstValue,
    cell: config.firstCell,
  );
  if (!first.applied) return; // first move is validated before producing; bail defensively
  emit(SelfPlayFrame(
    snapshot: first.snapshot,
    lastMoveCell: config.firstCell,
    lastWasCapture: first.captured,
  ));

  var prev = first.snapshot;
  while (true) {
    final r = api.selfPlayStep(timeMs: config.timeMs, maxDepth: config.maxDepth);
    if (r == null) break; // terminal
    emit(SelfPlayFrame(
      snapshot: r.snapshot,
      lastMoveCell: _diffCell(prev, r.snapshot),
      lastWasCapture: r.captured,
    ));
    prev = r.snapshot;
  }
}

/// The single board cell that differs between two consecutive snapshots (a placement or capture
/// changes exactly one cell), for the last-move highlight. Null if nothing changed.
int? _diffCell(Snapshot a, Snapshot b) {
  final n = a.board.length < b.board.length ? a.board.length : b.board.length;
  for (var i = 0; i < n; i++) {
    final x = a.board[i], y = b.board[i];
    if (x.empty != y.empty || x.owner != y.owner || x.value != y.value) return i;
  }
  return null;
}

// ---- producer isolate ----

class _ProducerInit {
  final SendPort port;
  final SelfPlayConfig config;
  const _ProducerInit(this.port, this.config);
}

/// Isolate entry: produce the whole game, sending each frame, then a `null` done-sentinel.
void _producerEntry(_ProducerInit init) {
  produceSelfPlay(init.config, (frame) => init.port.send(frame));
  init.port.send(null);
}

/// Pure, testable scrub state: the recorded frames plus a view cursor. No isolate, no timer — the
/// session below drives it. Auto-advance only moves up to the latest *produced* frame.
class SelfPlayViewModel extends ChangeNotifier {
  final List<SelfPlayFrame> frames = [];
  int viewIndex = 0;

  /// True while the viewer auto-advances; any manual scrub (prev/next) turns it off (work order §2.3).
  bool autoPlay = true;

  /// True until the producer reaches the terminal position.
  bool producing = true;

  SelfPlayFrame? get current =>
      frames.isEmpty ? null : frames[viewIndex.clamp(0, frames.length - 1)];

  bool get canPrev => viewIndex > 0;
  bool get canNext => viewIndex < frames.length - 1;

  void addFrame(SelfPlayFrame f) {
    frames.add(f);
    notifyListeners();
  }

  void markDone() {
    producing = false;
    notifyListeners();
  }

  /// One auto-advance tick: advance by one only while auto-playing and frames remain.
  void tick() {
    if (autoPlay && canNext) {
      viewIndex++;
      notifyListeners();
    }
  }

  void next() {
    autoPlay = false;
    if (canNext) viewIndex++;
    notifyListeners();
  }

  void prev() {
    autoPlay = false;
    if (canPrev) viewIndex--;
    notifyListeners();
  }

  /// Restart playback from the start using the existing record — no recompute (work order §2.3).
  void replay() {
    viewIndex = 0;
    autoPlay = true;
    notifyListeners();
  }
}

/// Live session: spawns the producer isolate, feeds frames into [model], and ticks the auto-advance
/// timer. The UI listens to [model]. Reset = dispose the session and return to setup.
class SelfPlaySession {
  final SelfPlayConfig config;
  final SelfPlayViewModel model = SelfPlayViewModel();

  /// How long each ply is shown during auto-advance.
  final Duration cadence;

  Isolate? _isolate;
  ReceivePort? _port;
  Timer? _timer;
  bool _disposed = false;

  SelfPlaySession(this.config, {this.cadence = const Duration(milliseconds: 600)});

  Future<void> start() async {
    _port = ReceivePort();
    _isolate = await Isolate.spawn(_producerEntry, _ProducerInit(_port!.sendPort, config));
    _port!.listen((msg) {
      if (_disposed) return;
      if (msg == null) {
        model.markDone();
        _teardownIsolate();
      } else {
        model.addFrame(msg as SelfPlayFrame);
      }
    });
    _timer = Timer.periodic(cadence, (_) {
      if (!_disposed) model.tick();
    });
  }

  void _teardownIsolate() {
    _port?.close();
    _port = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _teardownIsolate();
    model.dispose();
  }
}
