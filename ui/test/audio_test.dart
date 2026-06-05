// AudioController unit tests. Run with `flutter test`.

import 'package:flutter_test/flutter_test.dart';
import 'package:futuristic_xox/src/audio/audio_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('play is a safe no-op before init (no audio backend in tests)', () {
    // Never throws even though no clips are loaded — SFX must never disrupt the app.
    expect(() => AudioController.instance.play(SoundId.place), returnsNormally);
    expect(() => AudioController.instance.play(SoundId.win), returnsNormally);
  });

  test('setEnabled / setVolume update getters and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final audio = AudioController.instance;

    await audio.setEnabled(false);
    expect(audio.enabled, isFalse);
    await audio.setVolume(0.3);
    expect(audio.volume, 0.3);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sfx_enabled'), isFalse);
    expect(prefs.getDouble('sfx_volume'), 0.3);

    // Restore enabled for any later tests sharing the singleton.
    await audio.setEnabled(true);
  });
}
