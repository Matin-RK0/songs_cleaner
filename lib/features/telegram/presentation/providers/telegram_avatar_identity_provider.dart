import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_avatar_palette.dart';

class TelegramAvatarIdentity {
  TelegramAvatarIdentity(int chatId, String title)
    : colorIndex = chatId % AppAvatarPalette.variants,
      initial = _initial(title);

  final int colorIndex;
  final String initial;
  static final _directionMarkers = RegExp(
    r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]',
  );

  static String _initial(String title) {
    final name = title.replaceAll(_directionMarkers, '').trim();
    return name.isEmpty ? '' : name.characters.first.toUpperCase();
  }
}

final telegramAvatarIdentityProvider = Provider.autoDispose
    .family<TelegramAvatarIdentity, (int, String)>(
      (ref, chat) => TelegramAvatarIdentity(chat.$1, chat.$2),
    );
