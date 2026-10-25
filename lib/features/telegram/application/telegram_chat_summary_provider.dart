import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/telegram_download.dart';
import 'telegram_controller.dart';
import 'telegram_download_controller.dart';

final telegramChatLocalCountProvider = FutureProvider.autoDispose
    .family<int?, int>((ref, id) async {
      ref.watch(telegramProvider.select((state) => state.cacheRevision));
      final matcher = ref.watch(telegramLocalMatcherProvider);
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
      // Cache-only reads keep browsing summaries from opening chat controllers
      // (which can connect and request remote audio pages).
      final bindings = {
        for (final entry in (await repository.loadBindings()).entries)
          if (entry.key.startsWith('$id:')) entry.key: entry.value,
      };
      final audio = await repository.cachedAudio(id);
      if (audio.isEmpty && bindings.isEmpty) return null;
      if (!ref.mounted) return null;
      final jobs = ref.read(telegramDownloadsProvider);
      final playableAudio = {
        for (final item in audio)
          item.key: jobs[item.fileId]?.unfinished == true
              ? item.withLocalPath('')
              : item,
      };
      final paths = {
        ...bindings.values,
        for (final item in playableAudio.values) item.localPath,
        for (final item in playableAudio.values)
          ...matcher.candidatesFor(item).map((song) => song.path),
      }..remove('');
      final existing = await files.existingPaths(paths);
      // Count messages once, even when both a binding and TDLib path exist.
      // Use the same automatic local-copy matching as the open chat.
      return playableAudio.values
              .where(
                (item) =>
                    matcher.resolve(item, bindings, existing).song != null,
              )
              .length +
          bindings.entries
              .where(
                (entry) =>
                    !playableAudio.containsKey(entry.key) &&
                    existing.contains(entry.value),
              )
              .length;
    });
