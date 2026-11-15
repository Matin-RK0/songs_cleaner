import 'dart:io';

/// Runs the official SDK generator, then migrates its legacy delegate imports.
/// Flutter 3.50's gen-l10n template still references the deprecated classes.
/// Generation is isolated so builds cannot overwrite the migrated output.
Future<void> main() async {
  final root = File.fromUri(Platform.script).parent.parent;
  final cache = Directory.fromUri(root.uri.resolve('.dart_tool/'));
  await cache.create(recursive: true);
  final project = await cache.createTemp('l10n-');
  try {
    await File.fromUri(project.uri.resolve('pubspec.yaml')).writeAsString('''
name: songs_cleaner_l10n_generation
environment:
  sdk: ^3.14.0
dependencies:
  flutter:
    sdk: flutter
flutter:
  generate: true
''');
    await File.fromUri(root.uri.resolve('tool/l10n.yaml'))
        .copy(File.fromUri(project.uri.resolve('l10n.yaml')).path);
    const arbPath = 'lib/core/l10n/arb/';
    final arbOutput = Directory.fromUri(project.uri.resolve(arbPath));
    await arbOutput.create(recursive: true);
    await for (final file in Directory.fromUri(
      root.uri.resolve(arbPath),
    ).list()) {
      if (file is File) {
        await file.copy(
          File.fromUri(arbOutput.uri.resolve(file.uri.pathSegments.last)).path,
        );
      }
    }
    final process = await Process.start(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['gen-l10n', '--project-dir=${project.path}'],
      workingDirectory: project.path,
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.inheritStdio,
    );
    final result = await process.exitCode;
    if (result != 0) {
      exitCode = result;
      return;
    }
    const generatedPath = 'lib/core/l10n/generated/';
    final destination = Directory.fromUri(root.uri.resolve(generatedPath));
    await destination.create(recursive: true);
    await for (final file in Directory.fromUri(
      project.uri.resolve(generatedPath),
    ).list()) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = (await file.readAsString()).replaceAll(
        "import 'package:flutter_localizations/flutter_localizations.dart';",
        "import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;\n"
            "import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;\n"
            "import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;",
      );
      await File.fromUri(destination.uri.resolve(file.uri.pathSegments.last))
          .writeAsString(source);
    }
  } finally {
    // Only delete the unique scratch project created by this invocation.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await project.delete(recursive: true);
        break;
      } on FileSystemException {
        // Windows may briefly retain handles after flutter.bat exits.
        if (attempt == 2) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  }
}
