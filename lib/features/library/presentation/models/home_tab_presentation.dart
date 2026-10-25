import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/settings/home_tab_settings.dart';

extension HomeTabPresentation on HomeTab {
  String label(AppLocalizations l10n) => switch (this) {
    HomeTab.songs => l10n.songsTab,
    HomeTab.artists => l10n.artistsTab,
    HomeTab.albums => l10n.albumsTab,
    HomeTab.playlists => l10n.playlistsTab,
    HomeTab.telegram => l10n.telegramTitle,
  };

  IconData get icon => switch (this) {
    HomeTab.songs => Icons.music_note_rounded,
    HomeTab.artists => Icons.person_outline_rounded,
    HomeTab.albums => Icons.album_outlined,
    HomeTab.playlists => Icons.queue_music_rounded,
    HomeTab.telegram => Icons.send_rounded,
  };
}
