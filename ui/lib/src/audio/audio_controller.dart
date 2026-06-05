import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The six in-game effects (spec §0/§1). `capture` is intentionally omitted (deferred unless asked).
enum SoundId { menuNav, place, select, win, lose, draw }

/// Low-latency SFX player (spec §1, §5). One preloaded [AudioPlayer] per [SoundId] — never one per tap
/// — so distinct sounds can overlap while same-id repeats are throttled. A singleton: call
/// [AudioController.instance] anywhere; before [init] (e.g. in headless tests) [play] is a safe no-op.
class AudioController extends ChangeNotifier {
  AudioController._();
  static final AudioController instance = AudioController._();

  static const _enabledKey = 'sfx_enabled';
  static const _volumeKey = 'sfx_volume';
  static const _throttleMs = 60; // ignore the same id fired again within this window

  static const Map<SoundId, String> _files = {
    SoundId.menuNav: 'audio/menu.ogg',
    SoundId.place: 'audio/place.ogg',
    SoundId.select: 'audio/select.ogg',
    SoundId.win: 'audio/win.ogg',
    SoundId.lose: 'audio/lose.ogg',
    SoundId.draw: 'audio/draw.ogg',
  };

  final Map<SoundId, AudioPlayer> _players = {};
  final Map<SoundId, int> _lastPlayedMs = {};

  bool _enabled = true;
  double _volume = 0.8;
  bool _ready = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// Preload every clip once and read persisted settings. Tolerant of a missing audio backend
  /// (headless tests / unsupported platforms) — failures leave [play] a no-op rather than crashing.
  Future<void> init({required bool enabled, required double volume}) async {
    _enabled = enabled;
    _volume = volume;
    try {
      // Effects context: respect the iOS silent switch (ambient) and don't hold focus when idle.
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      for (final entry in _files.entries) {
        final player = AudioPlayer(playerId: 'sfx_${entry.key.name}');
        await player.setReleaseMode(ReleaseMode.stop); // keep the source loaded for instant replay
        await player.setSource(AssetSource(entry.value));
        await player.setVolume(_volume);
        _players[entry.key] = player;
      }
      _ready = true;
    } catch (_) {
      _ready = false; // audio unavailable — stay silent, never block or throw
    }
  }

  /// Fire-and-forget. No-op when disabled or not yet loaded; throttles rapid same-id repeats. Distinct
  /// ids use separate players so they overlap; the result sounds (win/lose/draw) play once by nature.
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
    } catch (_) {
      // ignore transient audio errors — SFX must never disrupt the UI
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
