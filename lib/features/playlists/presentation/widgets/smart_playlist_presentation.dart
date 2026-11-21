import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/entities/smart_playlist.dart';

extension SmartPlaylistPresentation on SmartPlaylistKind {
  String title(AppLocalizations l10n) => switch (this) {
    SmartPlaylistKind.liked => l10n.smartLikedTitle,
    SmartPlaylistKind.recentlyAdded => l10n.smartRecentTitle,
    SmartPlaylistKind.mostPlayed => l10n.smartMostPlayedTitle,
    SmartPlaylistKind.recentlyPlayed => l10n.smartRecentlyPlayedTitle,
  };

  IconData get icon => switch (this) {
    SmartPlaylistKind.liked => Icons.favorite_rounded,
    SmartPlaylistKind.recentlyAdded => Icons.library_music_rounded,
    SmartPlaylistKind.mostPlayed => Icons.local_fire_department_rounded,
    SmartPlaylistKind.recentlyPlayed => Icons.history_rounded,
  };
}
