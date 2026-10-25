import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/telegram_models.dart';
import 'telegram_controller.dart';
import 'telegram_preferences_controller.dart';

class TelegramChatSections {
  const TelegramChatSections({required this.pinned, required this.other});
  final List<TelegramChat> pinned;
  final List<TelegramChat> other;
  bool get isEmpty => pinned.isEmpty && other.isEmpty;
}

final telegramChatSectionsProvider = Provider<TelegramChatSections>((ref) {
  final chats = ref.watch(telegramVisibleChatsProvider);
  ref.watch(
    telegramPreferencesProvider.select(
      (value) => Object.hashAll(value['pins'] as List? ?? const []),
    ),
  );
  final pins =
      (ref.read(telegramPreferencesProvider)['pins'] as List? ?? const [])
          .whereType<int>()
          .toSet();
  final pinned = <TelegramChat>[];
  final other = <TelegramChat>[];
  for (final chat in chats) {
    (pins.contains(chat.id) ? pinned : other).add(chat);
  }
  return TelegramChatSections(
    pinned: List.unmodifiable(pinned),
    other: List.unmodifiable(other),
  );
});
