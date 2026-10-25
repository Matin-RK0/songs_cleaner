import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_artwork_loader.dart';
import 'telegram_fakes.dart';

void main() {
  late FakeTelegramRepository repository;
  setUp(() {
    repository = FakeTelegramRepository();
  });
  tearDown(() => repository.dispose());

  test(
    'local cover bytes are cached instead of refetched per rebuild',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'telegram-artwork-test',
      );
      addTearDown(() => dir.delete(recursive: true));
      final image = await File('${dir.path}/cover.jpg').writeAsBytes([1, 2, 3]);
      repository.cover = image.path;
      final loader = TelegramArtworkLoader(repository);
      expect(await loader.load((10, '', '')), [1, 2, 3]);
      expect(await loader.load((10, '', '')), [1, 2, 3]);
      expect(repository.coverCalls, 1);
    },
  );
  test(
    'miniature is used offline but does not prevent a later full-cover retry',
    () async {
      final loader = TelegramArtworkLoader(repository);
      final mini = base64Encode([4, 5, 6]);
      expect(await loader.load((1, '', mini)), [4, 5, 6]);
      expect(await loader.load((1, '', mini)), [4, 5, 6]);
      expect(repository.coverCalls, 2);
    },
  );
  test(
    'missing covers and malformed miniatures safely fall back to the music icon',
    () async {
      expect(
        await TelegramArtworkLoader(repository).load((0, '', 'invalid base64')),
        isNull,
      );
    },
  );
  test(
    'deduplicates identical requests and bounds concurrent thumbnail downloads',
    () async {
      final requests = <int, Completer<String?>>{};
      repository.loadCover = (id) =>
          (requests[id] = Completer<String?>()).future;
      final loader = TelegramArtworkLoader(repository);
      final futures = [for (var i = 1; i <= 5; i++) loader.load((i, '', ''))];
      final duplicate = loader.load((1, '', ''));
      await Future<void>.delayed(Duration.zero);
      expect(repository.coverCalls, 3);
      requests[1]!.complete(null);
      await Future<void>.delayed(Duration.zero);
      expect(repository.coverCalls, 4);
      requests[2]!.complete(null);
      await Future<void>.delayed(Duration.zero);
      expect(repository.coverCalls, 5);
      for (final request in requests.values) {
        if (!request.isCompleted) request.complete(null);
      }
      await Future.wait([...futures, duplicate]);
      expect(repository.coverCalls, 5);
    },
  );
}
