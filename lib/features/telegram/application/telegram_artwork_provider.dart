import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/telegram_artwork_loader.dart';
import 'telegram_controller.dart';

final telegramArtworkLoaderProvider = Provider<TelegramArtworkLoader>((ref) {
  final loader = TelegramArtworkLoader(ref.watch(telegramRepositoryProvider));
  ref.onDispose(loader.dispose);
  return loader;
});

final telegramArtworkProvider = FutureProvider.autoDispose
    .family<Uint8List?, TelegramCoverKey>((ref, key) {
      // Retry cached/offline artwork once a Telegram connection is available.
      ref.watch(telegramProvider.select((s) => s.auth));
      final loader = ref.watch(telegramArtworkLoaderProvider);
      ref.onDispose(() => loader.release(key));
      return loader.load(key);
    });
