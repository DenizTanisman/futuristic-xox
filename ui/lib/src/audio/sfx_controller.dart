import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-shot sound effects (spec §2). Music lives in a separate layer ([MusicController]).
enum SoundId {
  menuForward, // navigating into a deeper screen / opening a page
  menuBack, // navigating back / closing a page
  menuTap, // committing a selection / pressing a primary button
  place, // pawn placed (player AND AI)
  select, // Futuristic hand-pawn select
  matchStart, // a match begins
  win,
  lose,
  draw,
}

/// Low-latency SFX player (spec §1, §5). One preloaded [AudioPlayer] per [SoundId] — never one per tap
/// — so distinct sounds overlap while same-id repeats are throttled. A singleton: call
/// [SfxController.instance] anywhere; before [init] (e.g. headless tests) [play] is a safe no-op.
class SfxController extends ChangeNotifier {
  SfxController._();
  static final SfxController instance = SfxController._();

  static const _enabledKey = 'sfx_enabled';
  static const _volumeKey = 'sfx_volume';
  static const _throttleMs = 60;

  static const Map<SoundId, String> _files = {
    SoundId.menuForward: 'audio/menu_forward.wav',
    SoundId.menuBack: 'audio/menu_back.wav',
    SoundId.menuTap: 'audio/menu_tap.wav',
    SoundId.place: 'audio/place.wav',
    SoundId.select: 'audio/select.wav',
    SoundId.matchStart: 'audio/match_start.wav',
    SoundId.win: 'audio/win.wav',
    SoundId.lose: 'audio/lose.wav',
    SoundId.draw: 'audio/draw.wav',
  };

  final Map<SoundId, AudioPlayer> _players = {};
  final Map<SoundId, int> _lastPlayedMs = {};

  bool _enabled = true;
  double _volume = 0.8;
  bool _ready = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// Preload every clip once and apply persisted settings. Tolerant of a missing audio backend
  /// (headless tests / unsupported platforms) — failures leave [play] a no-op rather than crashing.
  Future<void> init({required bool enabled, required double volume}) async {
    _enabled = enabled;
    _volume = volume;
    try {
      // Effects/music context: respect the iOS silent switch (ambient) and don't hold focus when idle.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      for (final entry in _files.entries) {
        final player = AudioPlayer(playerId: 'sfx_${entry.key.name}');
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(entry.value));
        await player.setVolume(_volume);
        _players[entry.key] = player;
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Fire-and-forget. No-op when disabled or not loaded; throttles rapid same-id repeats; distinct ids
  /// overlap (separate players). The result sounds (win/lose/draw) play once by nature.
  void play(SoundId id) {
    if (!_enabled || !_ready) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedMs[id];
    if (last != null && now - last < _throttleMs) return;
    _lastPlayedMs[id] = now;
    final player = _players[id];
    if (player == null) return;
    unawaited(_replay(player));
  }

  Future<void> _replay(AudioPlayer player) async {
    try {
      await player.seek(Duration.zero);
      await player.setVolume(_volume);
      await player.resume();
    } catch (_) {/* SFX must never disrupt the UI */}
  }

  /// App backgrounded: stop any one-shot still playing so nothing leaks into the background.
  void suspend() {
    if (!_ready) return;
    for (final player in _players.values) {
      player.stop().catchError((_) {});
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setVolume(double value) async {
    _volume = value;
    for (final player in _players.values) {
      player.setVolume(value);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value);
  }
}
