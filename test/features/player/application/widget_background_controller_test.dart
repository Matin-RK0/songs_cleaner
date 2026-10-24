import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:songs_cleaner/core/settings/app_settings_repository.dart';
import 'package:songs_cleaner/features/player/application/providers/widget_background_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.songs_cleaner/now_playing_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ProviderContainer container;
  late SharedPreferences preferences;
  late List<MethodCall> calls;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    container.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('saves an opaque color and synchronizes the widget', () async {
    expect(container.read(widgetBackgroundColorProvider), isNull);
    await container
        .read(widgetBackgroundColorProvider.notifier)
        .setColor(0x00123456);

    expect(container.read(widgetBackgroundColorProvider), 0xff123456);
    expect(
      AppSettingsRepository(preferences).loadWidgetBackgroundColor(),
      0xff123456,
    );
    expect(calls.single.method, 'setBackgroundColor');
    expect(calls.single.arguments, {'color': 0xff123456});
  });

  test('reset restores dynamic background', () async {
    final controller = container.read(widgetBackgroundColorProvider.notifier);
    await controller.setColor(0xffabcdef);
    await controller.setColor(null);

    expect(container.read(widgetBackgroundColorProvider), isNull);
    expect(
      AppSettingsRepository(preferences).loadWidgetBackgroundColor(),
      isNull,
    );
    expect(calls.last.arguments, {'color': null});
  });

  test('failed native update preserves the previous setting', () async {
    final controller = container.read(widgetBackgroundColorProvider.notifier);
    await controller.setColor(0xff123456);
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'UNAVAILABLE');
    });

    await expectLater(
      controller.setColor(0xffabcdef),
      throwsA(isA<PlatformException>()),
    );
    expect(container.read(widgetBackgroundColorProvider), 0xff123456);
    expect(
      AppSettingsRepository(preferences).loadWidgetBackgroundColor(),
      0xff123456,
    );
  });
}
