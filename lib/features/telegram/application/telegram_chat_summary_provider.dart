import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../library/application/providers/library_providers.dart';
import '../domain/telegram_download.dart';
import 'telegram_controller.dart';
import 'telegram_download_controller.dart';

final telegramChatLocalCountProvider = FutureProvider.autoDispose
    .family<int?, int>((ref, id) async {
      ref.watch(allSongsProvider);
      ref.watch(
        telegramDownloadsProvider.select(
          (jobs) => Object.hashAll(
            jobs.values
                .where((job) => job.phase == TelegramDownloadPhase.completed)
                .map((job) => Object.hash(job.audio.fileId, job.path)),
          ),
        ),
      );
      final repository = ref.watch(telegramRepositoryProvider);
      final files = ref.watch(telegramLocalFilesProvider);
      final bindings = await repository.loadBindings();
      final paths = bindings.entries
          .where((entry) => entry.key.startsWith('$id:'))
          .map((e) => e.value)
          .toList();
      if (paths.isEmpty) return null;
      final existing = await files.existingPaths(paths);
      return paths.where(existing.contains).length;
    });
