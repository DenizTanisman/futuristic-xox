import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Scene { none, lobby, match }

/// The two looping music layers and their state machine (spec §3), kept separate from one-shot SFX:
///
/// LOBBY (`lobby_music` loops across all menus, never restarted on navigation) → on match start fade
/// the lobby out while a quiet `match_ambient` loop fills the silence under the SFX → on match end stop
/// the ambient (the exclusive win/lose/draw SFX plays) → after the result the lobby resumes and loops.
///
/// Singleton; tolerant of a missing audio backend (headless tests) — every method is then a no-op.
class MusicController extends ChangeNotifier {
  MusicController._();
  static final MusicController instance = MusicController._();

  static const _enabledKey = 'music_enabled';
  static const _volumeKey = 'music_volume';
  static const _ambientFactor = 0.4; // the in-match bed sits well under the SFX
  static const _resultHoldMs = 1800; // let the win/lose/draw SFX finish before the lobby returns

  AudioPlayer? _lobby;
  AudioPlayer? _ambient;
  final Map<String, double> _vol = {'lobby': 0, 'ambient': 0};
  final Map<String, bool> _playing = {'lobby': false, 'ambient': false};
  final Map<String, Timer> _fades = {};
  Timer? _resumeTimer;

  _Scene _scene = _Scene.none;
  bool _enabled = true;
  double _volume = 0.6;
  bool _ready = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  Future<void> init({required bool enabled, required double volume}) async {
    _enabled = enabled;
    _volume = volume;
    try {
      _lobby = AudioPlayer(playerId: 'music_lobby');
      _ambient = AudioPlayer(playerId: 'music_ambient');
      for (final p in [_lobby!, _ambient!]) {
        await p.setReleaseMode(ReleaseMode.loop); // gapless WAV loop
        await p.setVolume(0);
      }
      await _lobby!.setSource(AssetSource('audio/lobby_music.wav'));
      await _ambient!.setSource(AssetSource('audio/match_ambient.wav'));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  double get _lobbyTarget => _volume;
  double get _ambientTarget => _volume * _ambientFactor;

  /// Menus/lobby: lobby loop plays continuously. Idempotent — calling it again while already in the
  /// lobby does NOT restart the track (just keeps it looping).
  void enterLobby() {
    if (!_ready) return;
    _resumeTimer?.cancel();
    _scene = _Scene.lobby;
    _fadeTo('ambient', _ambient!, 0, 300);
    if (_enabled) {
      _ensurePlaying('lobby', _lobby!);
      _fadeTo('lobby', _lobby!, _lobbyTarget, 300);
    }
  }

  /// A match begins: fade the lobby out and bring in the quiet ambient bed.
  void startMatch() {
    if (!_ready) return;
    _resumeTimer?.cancel();
    _scene = _Scene.match;
    _fadeTo('lobby', _lobby!, 0, 300);
    if (_enabled) {
      _ensurePlaying('ambient', _ambient!);
      _fadeTo('ambient', _ambient!, _ambientTarget, 300);
    }
  }

  /// A match ends: stop the ambient now (the exclusive result SFX plays on top), then resume the lobby
  /// loop after the result sound — it covers the result/replay screen and all menus until the next match.
  void endMatch() {
    if (!_ready) return;
    _scene = _Scene.lobby;
    _fadeTo('ambient', _ambient!, 0, 250);
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(milliseconds: _resultHoldMs), () {
      if (_scene == _Scene.lobby && _enabled) {
        _ensurePlaying('lobby', _lobby!);
        _fadeTo('lobby', _lobby!, _lobbyTarget, 400);
      }
    });
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled != value) {
      _enabled = value;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    }
    if (!_ready) return;
    if (!value) {
      _fadeTo('lobby', _lobby!, 0, 200);
      _fadeTo('ambient', _ambient!, 0, 200);
    } else {
      // Resume whichever loop the current scene calls for.
      if (_scene == _Scene.match) {
        _ensurePlaying('ambient', _ambient!);
        _fadeTo('ambient', _ambient!, _ambientTarget, 300);
      } else {
        _scene = _Scene.lobby;
        _ensurePlaying('lobby', _lobby!);
        _fadeTo('lobby', _lobby!, _lobbyTarget, 300);
      }
    }
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    notifyListeners();
    if (_ready && _enabled) {
      if (_scene == _Scene.match) {
        _fadeTo('ambient', _ambient!, _ambientTarget, 120);
      } else {
        _fadeTo('lobby', _lobby!, _lobbyTarget, 120);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value);
  }

  void _ensurePlaying(String key, AudioPlayer player) {
    if (_playing[key] == true) return;
    _playing[key] = true;
    player.resume().catchError((_) {});
  }

  /// Linearly ramp a loop's volume to [to] over [ms]; pause it when it reaches silence.
  void _fadeTo(String key, AudioPlayer player, double to, int ms) {
    _fades[key]?.cancel();
    final from = _vol[key] ?? 0;
    if ((to - from).abs() < 0.001) {
      if (to == 0 && _playing[key] == true) {
        _playing[key] = false;
        player.pause().catchError((_) {});
      }
      return;
    }
    const stepMs = 30;
    final steps = (ms / stepMs).ceil().clamp(1, 1000);
    var i = 0;
    _fades[key] = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      i++;
      final v = (from + (to - from) * (i / steps)).clamp(0.0, 1.0);
      _vol[key] = v;
      player.setVolume(v).catchError((_) {});
      if (i >= steps) {
        t.cancel();
        if (v <= 0.001 && _playing[key] == true) {
          _playing[key] = false;
          player.pause().catchError((_) {});
        }
      }
    });
  }
}
