import 'dart:io';

class TelegramLocalFiles {
  Future<Set<String>> existingPaths(Iterable<String> paths) async {
    final existing = <String>{};
    for (final path in paths.toSet()) {
      if (path.isNotEmpty && await File(path).exists()) existing.add(path);
    }
    return existing;
  }
}
