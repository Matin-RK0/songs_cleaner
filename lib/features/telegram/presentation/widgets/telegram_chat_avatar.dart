import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_avatar_palette.dart';
import '../../application/telegram_artwork_provider.dart';
import '../../domain/telegram_models.dart';
import '../providers/telegram_avatar_identity_provider.dart';

class TelegramChatAvatar extends ConsumerWidget {
  const TelegramChatAvatar({
    super.key,
    required this.chat,
    this.size = AppSpacing.avatarLarge,
  });
  final TelegramChat chat;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final identity = ref.watch(
      telegramAvatarIdentityProvider((chat.id, chat.title)),
    );
    final palette = AppAvatarPalette.colors(colors, identity.colorIndex);
    final photo = ref.watch(
      telegramArtworkProvider((
        chat.photoFileId,
        chat.photoPath,
        chat.miniPhoto,
      )),
    );
    final bytes = photo.value;
    final resolution = (size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, 256);
    final placeholder = identity.initial.isNotEmpty
        ? Padding(
            padding: AppSpacing.allSm,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                identity.initial,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: palette.foreground),
              ),
            ),
          )
        : Icon(
            chat.kind == 'chatTypePrivate'
                ? Icons.person_outline_rounded
                : Icons.forum_outlined,
            size: AppSpacing.xl,
            color: palette.foreground,
          );
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.background,
            ),
            child: bytes == null
                ? placeholder
                : ClipOval(
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      cacheWidth: resolution,
                      gaplessPlayback: true,
                      errorBuilder: (context, error, stackTrace) => placeholder,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
