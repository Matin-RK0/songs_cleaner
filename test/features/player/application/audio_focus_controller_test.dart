import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/player/application/providers/audio_focus_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
  });

  tearDown(() => container.dispose());

  test('ducking defaults to 30 percent', () {
    expect(container.read(audioDuckingPercentProvider), 30);
  });

  test('ducking percentage survives controller recreation', () async {
    await container.read(audioDuckingPercentProvider.notifier).setPercent(45);
    expect(container.read(audioDuckingPercentProvider), 45);
    container.invalidate(audioDuckingPercentProvider);
    expect(container.read(audioDuckingPercentProvider), 45);
    expect(AppSettingsRepository(preferences).loadAudioDuckingPercent(), 45);
  });

  test('ducking percentage is clamped to the valid volume range', () async {
    final controller = container.read(audioDuckingPercentProvider.notifier);
    await controller.setPercent(-10);
    expect(container.read(audioDuckingPercentProvider), 0);
    await controller.setPercent(110);
    expect(container.read(audioDuckingPercentProvider), 100);
  });
}
