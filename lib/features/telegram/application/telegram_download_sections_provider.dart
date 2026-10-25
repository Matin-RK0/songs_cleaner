import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/telegram_download_group.dart';
import 'telegram_download_controller.dart';

class TelegramDownloadSection {
  const TelegramDownloadSection({required this.group, required this.ids});
  final TelegramDownloadGroup group;
  final List<int> ids;
}

final telegramDownloadSectionsProvider = Provider<List<TelegramDownloadSection>>(
  (ref) {
    // Progress bytes and transitions within the same group update only the row.
    ref.watch(
      telegramDownloadsProvider.select(
        (jobs) => Object.hashAll(
          jobs.entries.map(
            (entry) => Object.hash(
              entry.key,
              TelegramDownloadGroup.fromPhase(entry.value.phase),
            ),
          ),
        ),
      ),
    );
    final grouped = {
      for (final group in TelegramDownloadGroup.values) group: <int>[],
    };
    for (final entry in ref.read(telegramDownloadsProvider).entries) {
      grouped[TelegramDownloadGroup.fromPhase(entry.value.phase)]!.add(
        entry.key,
      );
    }
    return List.unmodifiable([
      for (final group in TelegramDownloadGroup.values)
        if (grouped[group]!.isNotEmpty)
          TelegramDownloadSection(
            group: group,
            ids: List.unmodifiable(grouped[group]!),
          ),
    ]);
  },
);
