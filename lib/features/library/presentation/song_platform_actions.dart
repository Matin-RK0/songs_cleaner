import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_l10n.dart';
import '../../../core/widgets/app_feedback.dart';
import '../application/ringtone_service.dart';
import '../application/song_share_service.dart';
import '../domain/entities/song.dart';

Future<void> shareSong(BuildContext context, Song song) async {
  try {
    final shared = await const SongShareService().share(song);
    if (shared && context.mounted) {
      showAppSnackBar(context, context.l10n.songShareOpened);
    }
  } on Exception {
    if (context.mounted) {
      showAppSnackBar(context, context.l10n.songShareFailed, error: true);
    }
  }
}

Future<void> setSongAsRingtone(BuildContext context, Song song) async {
  try {
    await const RingtoneService().setAsRingtone(song);
    if (context.mounted) {
      showAppSnackBar(context, context.l10n.ringtoneSetToast);
    }
  } on Exception catch (error) {
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      error is PlatformException && error.code == 'WRITE_SETTINGS_REQUIRED'
          ? context.l10n.ringtonePermissionRequired
          : context.l10n.ringtoneSetFailed,
      error: true,
    );
  }
}
