import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // This is a source/configuration guard, not an Android integration test.
  // Flutter's PlatformChannel drops requests without replying when no
  // Activity/PlatformPlugin is attached. A pre-runApp SystemChrome await
  // therefore blocks both headless playback and subsequent Activity launches.
  test(
    'shared audio entrypoint does not require an Activity platform channel',
    () {
      final source = File('lib/main.dart').readAsStringSync();
      final beforeRunApp = source.substring(0, source.indexOf('  runApp('));
      expect(
        beforeRunApp,
        isNot(matches(RegExp(r'\bSystemChrome\s*\.\s*\w+\s*\('))),
      );
      expect(beforeRunApp, isNot(contains('SystemChannels.platform')));
      expect(beforeRunApp, contains('await initializeMusicPlayerHandler('));
    },
  );

  test(
    'portrait policy belongs to the Android Activity rather than Dart boot',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final activity = RegExp(
        r'<activity\b[^>]*android:name="\.MainActivity"[^>]*>',
      ).firstMatch(manifest)?.group(0);
      expect(activity, isNotNull);
      expect(activity, contains('android:screenOrientation="portrait"'));
    },
  );
}
