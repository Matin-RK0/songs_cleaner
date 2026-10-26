import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_cleaner/core/l10n/generated/app_localizations.dart';
import 'package:songs_cleaner/features/library/application/providers/library_providers.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_controller.dart';
import 'package:songs_cleaner/features/telegram/application/telegram_download_controller.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_download.dart';
import 'package:songs_cleaner/features/telegram/domain/telegram_models.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/tdlib_transport.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_music_publisher.dart';
import 'package:songs_cleaner/features/telegram/infrastructure/telegram_repository_impl.dart';
import 'package:songs_cleaner/features/telegram/presentation/providers/download_labels_provider.dart';

import 'telegram_fakes.dart';
import 'telegram_controller_test.dart' show settle;

class _Authorized extends TelegramController {
  @override
  TelegramState build() => const TelegramState(auth: TelegramAuth.ready);
}

final class _PublishedPathAccess extends IOOverrides {
  _PublishedPathAccess(this.deniedPath);
  final String deniedPath;
  int lengthReads = 0;

  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return path == deniedPath ? _PublishedFile(file, this) : file;
  }
}

class _PublishedFile extends Fake implements File {
  _PublishedFile(this.file, this.access);
  final File file;
  final _PublishedPathAccess access;

  @override
  Future<bool> exists() => file.exists();

  @override
  Future<int> length() async {
    access.lengthReads++;
    throw FileSystemException(
      'Permission denied after MediaStore publication',
      file.path,
    );
  }
}

class _CompletedFileTransport extends TdlibTransport {
  _CompletedFileTransport(this.source);
  final File source;
  int downloads = 0;

  @override
  Future<Map<String, dynamic>> call(
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async {
    if (type == 'downloadFile') {
      downloads++;
      await source.parent.create(recursive: true);
      await source.writeAsBytes([1, 2, 3]);
      return {
        '@type': 'file',
        'id': fields['file_id'],
        'size': 3,
        'local': {
          'path': source.path,
          'downloaded_size': 3,
          'is_downloading_completed': true,
        },
      };
    }
    if (type == 'deleteFile' && await source.exists()) await source.delete();
    return {'@type': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> read(
    String scope,
    String type, [
    Map<String, dynamic> fields = const {},
  ]) async => {
    '@type': 'foundChatMessages',
    'messages': [],
    'next_from_message_id': 0,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  for (final damagedIndex in [
    'valid',
    'files',
    'publishedFiles',
    'bindings',
    'unrelatedAudio',
    'publishedPathAccess',
  ]) {
    test(
      'native publication completes and Retry reuses it ($damagedIndex cache)',
      () async {
        final dir = await Directory.systemTemp.createTemp(
          'telegram-publish-pipeline-',
        );
        final audio = testAudio(size: 3);
        final source = File('${dir.path}/files/music/source.mp3');
        final destination = File('${dir.path}/Music/Telegram/song.mp3');
        final seed = <String, dynamic>{
          'audio:123': [audio.toJson()],
        };
        if (damagedIndex == 'unrelatedAudio') {
          seed['audio:999'] = [
            {'legacy': true},
            'old record',
          ];
        } else if (damagedIndex != 'valid' &&
            damagedIndex != 'publishedPathAccess') {
          seed[damagedIndex] = {
            'old': null,
            'another': {'legacy': true},
            'kept': '/Music/previous-song.mp3',
          };
        }
        await File(
          '${dir.path}/library-v1.json',
        ).writeAsString(jsonEncode(seed));
        var publications = 0;
        messenger.setMockMethodCallHandler(TelegramMusicPublisher.channel, (
          call,
        ) async {
          if (call.method == 'requiresLegacyPermission') return false;
          if (call.method == 'saveAudio') {
            publications++;
            await destination.parent.create(recursive: true);
            await File(
              (call.arguments as Map)['sourcePath'] as String,
            ).copy(destination.path);
            return destination.path;
          }
          return null;
        });
        final access = _PublishedPathAccess(
          damagedIndex == 'publishedPathAccess' ? destination.path : '',
        );
        await IOOverrides.runWithIOOverrides(() async {
          final transport = _CompletedFileTransport(source);
          final repository = TelegramRepositoryImpl(
            cacheDirectory: dir,
            transportFactory: () => transport,
          );
          final container = ProviderContainer(
            overrides: [
              telegramRepositoryProvider.overrideWithValue(repository),
              telegramProvider.overrideWith(_Authorized.new),
              telegramLibrarySyncProvider.overrideWithValue(() async {}),
              allSongsProvider.overrideWithValue([]),
            ],
          );
          addTearDown(() async {
            container.dispose();
            await repository.dispose();
            messenger.setMockMethodCallHandler(
              TelegramMusicPublisher.channel,
              null,
            );
            await dir.delete(recursive: true);
          });
          final chat = container.listen(telegramChatProvider(123), (_, _) {});
          addTearDown(chat.close);
          await settle();
          final manager = container.read(telegramDownloadsProvider.notifier);
          await settle();
          Future<void> download() async {
            manager.enqueue(audio);
            await manager.waitFor(audio.fileId);
          }

          await download();
          await settle();
          expect(await destination.readAsBytes(), [1, 2, 3]);
          expect(
            container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
            TelegramDownloadPhase.completed,
          );
          expect(
            container.read(telegramDownloadsProvider)[audio.fileId]!.failure,
            isNull,
          );
          expect(
            container.read(telegramChatSongsProvider(123)).single.path,
            destination.path,
          );
          expect(container.read(telegramChatProvider(123)).failure, isNull);
          final l10n = lookupAppLocalizations(const Locale('en'));
          expect(
            container
                .read(telegramDownloadLabelsProvider((audio.fileId, 'en')))
                .$1,
            l10n.telegramCompleted,
          );
          // Force the same request again, as with repeated Retry taps after the old bug.
          await download();
          await settle();
          expect(
            container.read(telegramDownloadsProvider)[audio.fileId]!.phase,
            TelegramDownloadPhase.completed,
          );
          expect(publications, 1);
          expect(transport.downloads, 1);
          expect(access.lengthReads, 0);
          if (damagedIndex != 'valid' &&
              damagedIndex != 'unrelatedAudio' &&
              damagedIndex != 'publishedPathAccess') {
            final repaired =
                jsonDecode(
                      await File('${dir.path}/library-v1.json').readAsString(),
                    )
                    as Map;
            expect(
              (repaired[damagedIndex] as Map)['kept'],
              '/Music/previous-song.mp3',
            );
            expect((repaired[damagedIndex] as Map).containsKey('old'), isFalse);
          }
        }, access);
      },
    );
  }
}
