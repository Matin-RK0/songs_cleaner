import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const native = 'android/app/src/main/kotlin/com/example/songs_cleaner';

  // Source guards complement the JVM command tests; these do not simulate
  // Android Activity/task recreation on a device.
  test('legacy persisted play commands cannot be replayed on app startup', () {
    final source = File('$native/LockScreenController.kt').readAsStringSync();
    expect(source, isNot(contains('"pending_play"')));
    expect(source, contains('result.success(pendingPlay.consume())'));
    expect(
      source,
      contains(
        'if (pendingPlay.consume()) it.invokeMethod("playRequested", null)',
      ),
    );
  });

  test('widget intents are consumed and ignored on Activity restoration', () {
    final source = File('$native/MainActivity.kt').readAsStringSync();
    expect(
      source,
      contains(
        'rememberWidgetAction(intent, allowDispatch = savedInstanceState == null)',
      ),
    );
    final consume = source.indexOf('intent.action = Intent.ACTION_MAIN');
    final guard = source.indexOf('if (!allowDispatch ||', consume);
    expect(source, contains('Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY'));
    final dispatch = source.indexOf('plugin.dispatchAction(action)', guard);
    expect(consume, greaterThanOrEqualTo(0));
    expect(guard, greaterThan(consume));
    expect(dispatch, greaterThan(guard));
  });
}
