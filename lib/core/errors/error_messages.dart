import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'failure.dart';

String failureMessage(BuildContext context, Failure failure) {
  final l10n = AppLocalizations.of(context);
  switch (failure) {
    case PermissionFailure():
      return l10n.permissionAudioMessage;
    case LibraryLoadFailure():
      return l10n.errorLoadFailedMessage;
    case SongDeleteFailure():
      return l10n.actionFailedGeneric;
    case PlaybackFailure():
      return l10n.actionFailedGeneric;
    case UnknownFailure():
      return l10n.errorLoadFailedMessage;
  }
}
