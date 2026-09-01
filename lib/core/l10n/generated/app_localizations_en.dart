// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Songs Cleaner';

  @override
  String get libraryTitle => 'Songs Cleaner';

  @override
  String get songsTab => 'Songs';

  @override
  String get artistsTab => 'Artists';

  @override
  String get albumsTab => 'Albums';

  @override
  String get searchHint => 'Search';

  @override
  String get shuffleAll => 'Shuffle all';

  @override
  String get sortLabel => 'Sort';

  @override
  String get sortByTitle => 'By title';

  @override
  String get sortByArtist => 'By artist';

  @override
  String get sortByDateAdded => 'By date added';

  @override
  String get sortByDuration => 'By duration';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get untitledSong => 'Untitled';

  @override
  String get queueTitle => 'Play queue';

  @override
  String get queueUpNext => 'Up next';

  @override
  String get queueEmpty => 'The play queue is empty';

  @override
  String get emptyLibraryTitle => 'No music found';

  @override
  String get emptyLibraryMessage =>
      'There are no audio files on this device yet, or access was not granted.';

  @override
  String get noResultsTitle => 'No results';

  @override
  String get noResultsMessage => 'Try a different search term.';

  @override
  String get loadingLibrary => 'Reading library…';

  @override
  String get errorLoadFailedTitle => 'Failed to load library';

  @override
  String get errorLoadFailedMessage =>
      'Something went wrong; please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get actionFailedGeneric => 'The action could not be completed';

  @override
  String get permissionTitle => 'Permission required';

  @override
  String get permissionAudioMessage =>
      'Grant access to audio files so the app can show your device\'s music.';

  @override
  String get permissionFilesMessage =>
      'Enable \"All files access\" in settings so songs can be deleted.';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get openSettings => 'Open settings';

  @override
  String get deleteAction => 'Delete from device';

  @override
  String get deleteCurrentTooltip => 'Delete current song';

  @override
  String get deleteConfirmTitle => 'Delete this song?';

  @override
  String deleteConfirmMessage(String title) {
    return '\"$title\" will be permanently removed from your device and the next song will start.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String songDeletedToast(String title) {
    return '\"$title\" deleted';
  }

  @override
  String songDeleteFailedToast(String title) {
    return 'Could not delete \"$title\"';
  }

  @override
  String get shuffleTooltip => 'Shuffle';

  @override
  String get repeatOffTooltip => 'Repeat: off';

  @override
  String get repeatAllTooltip => 'Repeat: all';

  @override
  String get repeatOneTooltip => 'Repeat: one';

  @override
  String get playTooltip => 'Play';

  @override
  String get pauseTooltip => 'Pause';

  @override
  String get nextTooltip => 'Next';

  @override
  String get previousTooltip => 'Previous';

  @override
  String get closeTooltip => 'Close';

  @override
  String get expandPlayerTooltip => 'Open player screen';

  @override
  String get playerScreenTitle => 'Now playing';

  @override
  String songCountLabel(int count) {
    return '$count songs';
  }

  @override
  String playbackFailedToast(String title) {
    return 'Could not play \"$title\"';
  }

  @override
  String get removeFromQueueTooltip => 'Remove from queue';

  @override
  String get clearQueueTooltip => 'Clear queue';

  @override
  String get playTooltipShort => 'Play';

  @override
  String get nothingPlayingTitle => 'Nothing is playing';

  @override
  String get backTooltip => 'Back';

  @override
  String get notifPermissionTitle => 'Show playback controls';

  @override
  String get notifPermissionMessage =>
      'Allow notifications to see the playing song and its controls in the status bar.';
}
