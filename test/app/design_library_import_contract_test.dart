import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app and tests do not import deprecated SDK design libraries', () {
    final legacyDirective = RegExp(
      r'''^\s*(?:import|export)\s+['"]package:flutter/(?:material|cupertino)\.dart['"]''',
      multiLine: true,
    );
    final offenders = <String>[];
    for (final directory in ['lib', 'test']) {
      for (final file in Directory(directory).listSync(recursive: true)) {
        if (file is File &&
            file.path.endsWith('.dart') &&
            legacyDirective.hasMatch(file.readAsStringSync())) {
          offenders.add(file.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Use the official material_ui and cupertino_ui packages.',
    );
  });
}
