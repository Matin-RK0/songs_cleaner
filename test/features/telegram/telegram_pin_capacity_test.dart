import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_preferences_controller.dart';

import 'telegram_fakes.dart';

void main() {
  test(
    'pin refuses overflow without losing pins and permits unpin at capacity',
    () async {
      final repository = FakeTelegramRepository()
        ..preferences = {'pins': List.generate(12, (index) => index)};
      final container = ProviderContainer(
        overrides: [telegramRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(() async {
        container.dispose();
        await repository.dispose();
      });
      final preferences = container.read(telegramPreferencesProvider.notifier);
      await preferences.ready;
      final original = container.read(telegramPreferencesProvider);
      expect(preferences.pin(99), isFalse);
      expect(container.read(telegramPreferencesProvider), same(original));
      expect(preferences.pin(5), isTrue);
      expect(preferences.pin(99), isTrue);
      await preferences.prepareLogout();
      expect(repository.preferences['pins'], [
        0,
        1,
        2,
        3,
        4,
        6,
        7,
        8,
        9,
        10,
        11,
        99,
      ]);
      expect(preferences.pin(99), isFalse);
    },
  );
}
