// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get telegramNoActiveDownloads => 'No active downloads';

  @override
  String telegramDownloadsOverview(
    int active,
    int queued,
    int paused,
    int failed,
  ) {
    return '$active active · $queued queued · $paused paused · $failed failed';
  }

  @override
  String telegramConcurrency(int count) {
    return '$count simultaneous downloads';
  }

  @override
  String get telegramDownloads => 'Downloads';

  @override
  String get telegramQueued => 'Queued';

  @override
  String get telegramReceiving => 'Downloading';

  @override
  String get telegramSaving => 'Saving to Music/Telegram…';

  @override
  String get telegramPaused => 'Paused';

  @override
  String get telegramCompleted => 'Saved to Music/Telegram';

  @override
  String get telegramCanceled => 'Canceled';

  @override
  String get telegramPause => 'Pause';

  @override
  String get telegramResume => 'Resume';

  @override
  String get telegramPauseAll => 'Pause all';

  @override
  String get telegramResumeAll => 'Resume / retry all';

  @override
  String get telegramClearFinished => 'Clear finished';

  @override
  String get telegramNoDownloads => 'No downloads yet';

  @override
  String telegramTransferBytes(String received, String total) {
    return '$received / $total';
  }

  @override
  String telegramTransferSpeed(String speed, int seconds) {
    return '$speed/s · ~${seconds}s left';
  }

  @override
  String telegramPercent(int count) {
    return '$count%';
  }

  @override
  String telegramDownloadSummary(int active, int queued, int failed) {
    return '$active active · $queued queued · $failed failed';
  }

  @override
  String get telegramDownloadAndPlay => 'Download and play';

  @override
  String get telegramSearchMusic => 'Search loaded music';

  @override
  String get telegramLoadedSearchHint =>
      'Search covers the messages loaded so far. Load more for older music.';

  @override
  String get telegramNewest => 'Newest first';

  @override
  String get telegramOldest => 'Oldest first';

  @override
  String get telegramByTitle => 'Track name';

  @override
  String get telegramPin => 'Pin chat';

  @override
  String get telegramUnpin => 'Unpin chat';

  @override
  String get telegramRecent => 'Recently opened';

  @override
  String get telegramPinned => 'Pinned';

  @override
  String get telegramSelect => 'Select tracks';

  @override
  String telegramSelection(int count, String size) {
    return '$count selected · $size';
  }

  @override
  String get telegramDownloadSelected => 'Download selected';

  @override
  String get telegramQueueSelected => 'Queue local selection';

  @override
  String get telegramQueueFull =>
      'The download queue is full. Finish or cancel some items first.';

  @override
  String get telegramDownloadLocation =>
      'Downloads are saved in Music/Telegram. Completed audio is removed from this app’s private cache.';

  @override
  String get telegramDownloadNotification => 'Telegram music downloads';

  @override
  String get telegramOpenMessage => 'Open message in Telegram';

  @override
  String get telegramTitle => 'Telegram';

  @override
  String get telegramHeadline => 'Your chats. Your music.';

  @override
  String get telegramDescription =>
      'Keep music from channels, groups and conversations together, with a library for each chat.';

  @override
  String get telegramConnect => 'Connect Telegram';

  @override
  String get telegramReconnect => 'Reconnect';

  @override
  String get telegramConnected => 'Account connected';

  @override
  String get telegramOffline => 'Offline library';

  @override
  String get telegramOfflineHint =>
      'Saved local music is available. Reconnect to update chats and discover more music.';

  @override
  String get telegramPrivacy =>
      'Sign in directly through Telegram. Your session stays on this device. Private cache in the official Telegram app cannot be scanned.';

  @override
  String get telegramFolders => 'Files in Telegram folders';

  @override
  String get telegramFoldersHint =>
      'Accessible device files; their original chat is unknown';

  @override
  String get telegramChats => 'Your chats';

  @override
  String get telegramSearch => 'Search chats';

  @override
  String get telegramNoChats => 'No chats to show';

  @override
  String get telegramNoResults => 'No matching chats';

  @override
  String get telegramNoChatsHint =>
      'Connect your account to see music by chat, or browse accessible Telegram folders.';

  @override
  String get telegramLoadMore => 'Load more';

  @override
  String get telegramRefresh => 'Update chats';

  @override
  String get telegramLogout => 'Disconnect account';

  @override
  String get telegramLogoutTitle => 'Disconnect Telegram?';

  @override
  String get telegramLogoutHint =>
      'This ends this app’s Telegram session and clears its chat index. Files in your device library are kept.';

  @override
  String get telegramPhone => 'Phone number';

  @override
  String get telegramPhoneHint =>
      'Include the country code, e.g. +989121234567';

  @override
  String get telegramCode => 'Verification code';

  @override
  String get telegramCodeHint =>
      'Enter the code sent by Telegram. It may arrive in the Telegram app rather than by SMS.';

  @override
  String get telegramPassword => 'Two-step verification password';

  @override
  String get telegramPasswordHint =>
      'Enter the password you set for your Telegram account.';

  @override
  String get telegramContinue => 'Continue';

  @override
  String get telegramStarting => 'Connecting securely…';

  @override
  String get telegramSetup => 'Telegram connection needs configuration';

  @override
  String get telegramSetupHint =>
      'Build the app with TELEGRAM_API_ID and TELEGRAM_API_HASH from my.telegram.org. Setup instructions are in the project README.';

  @override
  String get telegramUnsupported =>
      'Telegram connection is available on Android.';

  @override
  String get telegramOtherAuth =>
      'This account needs an additional verification step that this app does not support yet. You can still browse your saved local library.';

  @override
  String get telegramErrorNetwork =>
      'Could not reach Telegram. Check your connection and try again.';

  @override
  String get telegramErrorPhone =>
      'Enter a valid phone number with its country code.';

  @override
  String get telegramErrorCode =>
      'The code is invalid or expired. Check the code and try again.';

  @override
  String get telegramErrorPassword => 'The password is incorrect. Try again.';

  @override
  String get telegramErrorFlood =>
      'Telegram has limited requests. Wait a while before trying again.';

  @override
  String get telegramErrorGeneric =>
      'The Telegram action failed. Please try again.';

  @override
  String get telegramLocal => 'On this device';

  @override
  String get telegramAllAudio => 'All music';

  @override
  String telegramLocalCount(int count) {
    return '$count local tracks';
  }

  @override
  String get telegramNoAudio => 'No local music in this chat yet';

  @override
  String get telegramNoAudioHint =>
      'No accessible file matches the loaded music yet. Switch to All music to download tracks, or load older messages. Downloads kept only in the official Telegram app’s private cache are not accessible here.';

  @override
  String telegramLocalMatchesCount(int count) {
    return '$count local matches to link';
  }

  @override
  String get telegramLocalMatchesHint =>
      'The files below were found on your device. Tap the link button to confirm a match and enable playback in this chat.';

  @override
  String get telegramEmptyChat => 'No music found in the loaded messages';

  @override
  String get telegramDownload => 'Download to Music/Telegram';

  @override
  String get telegramErrorStorage =>
      'Could not save the song to Music/Telegram. Check free storage and storage access, then try again.';

  @override
  String get telegramDownloading => 'Downloading…';

  @override
  String get telegramLink => 'Link local file';

  @override
  String get telegramLinkTitle => 'Choose the matching file';

  @override
  String get telegramLinkHint =>
      'These files have the same name and size. Confirm the correct file before assigning it to this chat.';

  @override
  String get telegramCloud => 'Not available locally';

  @override
  String get telegramSuggested => 'Possible local match';

  @override
  String get telegramPlayLocal => 'Play local music';

  @override
  String get telegramSyncAudio => 'Update music';

  @override
  String get telegramChannelOrGroup => 'Group / channel';

  @override
  String get telegramConversation => 'Conversation';

  @override
  String get undoAction => 'Undo';

  @override
  String get trashRestoreFailed => 'Could not restore the song.';

  @override
  String get trashTitle => 'Trash';

  @override
  String get trashSettingsSubtitle => 'Restore or permanently delete songs';

  @override
  String get trashEmpty => 'Trash is empty';

  @override
  String get restoreAction => 'Restore';

  @override
  String get deletePermanentlyAction => 'Delete permanently';

  @override
  String get trashRestoredToast => 'Song restored';

  @override
  String get trashDeletedToast => 'Song deleted permanently';

  @override
  String get songDeleteFailedGeneric => 'The file operation failed.';

  @override
  String get trashPermanentDeleteWarning =>
      'This song will be deleted permanently and cannot be restored.';

  @override
  String get emptyTrashAction => 'Empty Trash';

  @override
  String get trashEmptyWarning =>
      'All songs in Trash will be deleted permanently.';

  @override
  String get importPlaylists => 'Import playlists';

  @override
  String get exportPlaylists => 'Export playlists';

  @override
  String get playlistsExported => 'Playlists exported';

  @override
  String playlistsImported(int count) {
    return 'Imported $count playlists';
  }

  @override
  String get importedPlaylistName => 'Imported playlist';

  @override
  String get playlistFileInvalid => 'This playlist file is invalid.';

  @override
  String get playlistTransferFailed => 'Playlist transfer failed.';

  @override
  String get sharePlaylists => 'Share playlists';

  @override
  String get playlistsShared => 'Share sheet opened';

  @override
  String get shareSongAction => 'Share song';

  @override
  String get songShareOpened => 'Share sheet opened';

  @override
  String get songShareFailed => 'Could not share this song.';

  @override
  String get setAsRingtoneAction => 'Set as ringtone';

  @override
  String get ringtoneSetToast => 'Ringtone updated';

  @override
  String get ringtonePermissionRequired =>
      'Allow system settings access, then try again.';

  @override
  String get ringtoneSetFailed => 'Could not set this song as ringtone.';

  @override
  String sortApplied(String value) {
    return 'Sorted by $value';
  }

  @override
  String get filterApplied => 'Filter updated';

  @override
  String get historyClearedToast => 'Play history cleared';

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
  String get scrollToTop => 'Back to top';

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
  String get refreshLibraryTooltip => 'Refresh library';

  @override
  String get librarySyncedToast => 'Library updated';

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

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get themeModeTitle => 'Theme';

  @override
  String get primaryColorTitle => 'Primary color';

  @override
  String get widgetBackgroundTitle => 'Home widget background';

  @override
  String get widgetBackgroundDynamic => 'Dynamic';

  @override
  String get widgetBackgroundCustom => 'Custom color';

  @override
  String get widgetBackgroundUseDynamic => 'Use dynamic background';

  @override
  String get colorHue => 'Hue';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Brightness';

  @override
  String get colorSuggested => 'Suggested colors';

  @override
  String get colorFineAdjustments => 'Fine adjustments';

  @override
  String get colorBefore => 'Before';

  @override
  String get colorAfter => 'After';

  @override
  String get colorFieldHint =>
      'Choose saturation and brightness, or use the sliders below for precise adjustments.';

  @override
  String colorChoice(String hex) {
    return 'Choose color $hex';
  }

  @override
  String colorDegrees(String value) {
    return '$value°';
  }

  @override
  String colorPercent(String value) {
    return '$value%';
  }

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get primaryColorSubtitle => 'Choose the app accent color';

  @override
  String primaryColorOption(int index) {
    return 'Primary color option $index';
  }

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get languageTitle => 'App language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get settingsLockScreenSection => 'Lock screen';

  @override
  String get lockScreenControlTitle => 'Music controls on lock screen';

  @override
  String get lockScreenTimeoutTitle => 'Lock screen player timeout';

  @override
  String get screenLockAccessTitle => 'Allow double-tap to turn screen off?';

  @override
  String get screenLockAccessMessage =>
      'This optional feature uses Android Accessibility to turn off the display and lock your phone when you double-tap the player background, or when the selected inactivity timeout expires while your phone is locked. It does not read screen content or collect or send data. In Accessibility settings, open Installed apps and enable Double-tap to turn screen off. Unlock your phone if prompted. You can revoke access at any time. After enabling it, return and double-tap again.';

  @override
  String get screenLockUnsupported =>
      'Double-tap screen locking requires Android 9 or later.';

  @override
  String get screenLockFailed =>
      'Could not turn off the screen. Check the accessibility service and try again.';

  @override
  String lockScreenTimeoutSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get lockScreenControlSubtitle =>
      'Show the player when the screen turns on while music is playing.';

  @override
  String get lockScreenPermissionNeeded =>
      'Allow \"Display over other apps\" to turn this on.';

  @override
  String get lockScreenUnsupportedSubtitle => 'Not supported on this device.';

  @override
  String get lockScreenPermissionTitle => 'Permission needed';

  @override
  String get lockScreenPermissionMessage =>
      'To show music controls over the lock screen, allow Songs Cleaner to display over other apps.';

  @override
  String get lockScreenPermissionAllow => 'Open settings';

  @override
  String get lockScreenPermissionNotNow => 'Not now';

  @override
  String get lockScreenEnabledToast => 'Lock screen controls enabled';

  @override
  String get lockScreenDisabledToast => 'Lock screen controls disabled';

  @override
  String get settingsPlaybackSection => 'Playback';

  @override
  String get previousGoesToPreviousTitle =>
      'Previous button goes to previous song';

  @override
  String get previousGoesToPreviousSubtitle =>
      'On: jump straight to the previous song. Off: restart the current song first.';

  @override
  String get hideQuickDeleteTitle => 'Hide quick delete button';

  @override
  String get hideQuickDeleteSubtitle =>
      'When enabled, the delete button is hidden from the player screen.';

  @override
  String get audioFocusTitle => 'Audio interruptions';

  @override
  String get audioFocusPause => 'Pause and resume';

  @override
  String get audioFocusDuck => 'Lower volume temporarily';

  @override
  String get audioFocusIgnore => 'Keep playing';

  @override
  String get playlistsTab => 'Playlists';

  @override
  String get smartPlaylistsSection => 'Smart playlists';

  @override
  String get myPlaylistsSection => 'My playlists';

  @override
  String get smartLikedTitle => 'Liked songs';

  @override
  String get smartRecentTitle => 'Recently added';

  @override
  String get smartMostPlayedTitle => 'Most played';

  @override
  String get playlistsEmptyTitle => 'No playlists yet';

  @override
  String get playlistsEmptyMessage =>
      'Create a playlist and add songs by long-pressing them.';

  @override
  String get newPlaylist => 'New playlist';

  @override
  String get playlistNameLabel => 'Playlist name';

  @override
  String get createAction => 'Create';

  @override
  String get saveAction => 'Save';

  @override
  String get renamePlaylist => 'Rename playlist';

  @override
  String get deletePlaylist => 'Delete playlist';

  @override
  String deletePlaylistConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deletePlaylistConfirmMessage =>
      'This playlist will be removed. The songs themselves stay on your device.';

  @override
  String playlistCreatedToast(String name) {
    return '\"$name\" created';
  }

  @override
  String get playlistRenamedToast => 'Playlist renamed';

  @override
  String playlistDeletedToast(String name) {
    return '\"$name\" deleted';
  }

  @override
  String addedToPlaylistToast(String name) {
    return 'Added to \"$name\"';
  }

  @override
  String removedFromPlaylistToast(int count, Object name) {
    return 'Removed $count song(s) from \"$name\"';
  }

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get reorderTooltip => 'Reorder';

  @override
  String get removeFromPlaylist => 'Remove from playlist';

  @override
  String playlistMetaLabel(int count, String duration) {
    return '$count songs · $duration';
  }

  @override
  String get playlistEmptySongsTitle => 'This playlist is empty';

  @override
  String get playlistEmptySongsMessage =>
      'Long-press a song in your library and choose \"Add to playlist\".';

  @override
  String get likedEmptyTitle => 'No liked songs';

  @override
  String get likedEmptyMessage =>
      'Long-press a song and add it to your favorites.';

  @override
  String get mostPlayedEmptyTitle => 'No play history yet';

  @override
  String get mostPlayedEmptyMessage =>
      'Songs you play often will show up here.';

  @override
  String get playbackOptionsTitle => 'Playback options';

  @override
  String get playbackSpeed => 'Playback speed';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get sleepTimerOff => 'Off';

  @override
  String get sleepTimerSongEnd => 'At the end of this song';

  @override
  String sleepTimerMinutes(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String sleepTimerRemaining(Object time) {
    return 'Sleep timer: $time';
  }

  @override
  String get equalizerTitle => 'Equalizer';

  @override
  String get equalizerEnabled => 'Enable equalizer';

  @override
  String get equalizerSubtitle => 'Android audio effect for the current player';

  @override
  String get equalizerUnavailable =>
      'The equalizer is not available on this device.';

  @override
  String get equalizerFlat => 'Flat';

  @override
  String get equalizerBassBoost => 'Bass boost';

  @override
  String equalizerRange(Object max, Object min) {
    return 'Range: $min dB to $max dB';
  }

  @override
  String get gaplessPlaybackTitle => 'Gapless playback';

  @override
  String get gaplessPlaybackSubtitle =>
      'Keep album transitions free of silence';

  @override
  String get lyricsTitle => 'Lyrics';

  @override
  String get lyricsUnavailable =>
      'No .lrc lyrics file was found next to this song.';

  @override
  String get historyTitle => 'Play history';

  @override
  String get historySettingsSubtitle => 'Review songs you listened to recently';

  @override
  String get historyEmptyTitle => 'No listening history';

  @override
  String get historyEmptyMessage =>
      'Songs will appear here when you start playing them.';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryTitle => 'Clear play history?';

  @override
  String get clearHistoryMessage =>
      'This removes your recent listening activity. Play counts and favorites are kept.';

  @override
  String get clearAction => 'Clear';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get reorderQueueTooltip => 'Reorder queue';

  @override
  String get genresTab => 'Genres';

  @override
  String get foldersTab => 'Folders';

  @override
  String get unknownGenre => 'Unknown genre';

  @override
  String get unknownFolder => 'Unknown folder';

  @override
  String get sortByAlbum => 'By album';

  @override
  String get sortBySize => 'By file size';

  @override
  String get sortByTrack => 'By track number';

  @override
  String get filterTitle => 'Filter songs';

  @override
  String get filterAll => 'All songs';

  @override
  String get filterMissingMetadata => 'Missing metadata';

  @override
  String get filterShortTracks => 'Shorter than 1 minute';

  @override
  String get filterLongTracks => '10 minutes or longer';

  @override
  String get filterLossless => 'Lossless audio';

  @override
  String get moreActions => 'More actions';

  @override
  String get songDetailsTitle => 'Song information';

  @override
  String get songNotFound => 'This song is no longer in the library';

  @override
  String get artistLabel => 'Artist';

  @override
  String get albumLabel => 'Album';

  @override
  String get genreLabel => 'Genre';

  @override
  String get composerLabel => 'Composer';

  @override
  String get trackNumberLabel => 'Track';

  @override
  String get durationLabel => 'Duration';

  @override
  String get fileFormatLabel => 'Format';

  @override
  String get fileSizeLabel => 'Size';

  @override
  String get folderLabel => 'Folder';

  @override
  String get filePathLabel => 'File path';

  @override
  String get modifiedDateLabel => 'Modified';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get editTagsTitle => 'Edit tags';

  @override
  String get tagEditorTitle => 'Edit song metadata';

  @override
  String get titleLabel => 'Title';

  @override
  String get lyricsEditorHint => 'Paste synchronized lyrics in .lrc format';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get trackNumberInvalid => 'Track number must be between 0 and 999';

  @override
  String get tagsSavedToast => 'Song metadata saved';

  @override
  String get tagsSaveFailed => 'Could not save song metadata';

  @override
  String get renameFileTitle => 'Rename file';

  @override
  String get fileNameLabel => 'File name';

  @override
  String get fileRenamedToast => 'File renamed';

  @override
  String get fileRenameFailed => 'Could not rename this file';

  @override
  String get fileNameRequired => 'File name is required';

  @override
  String get fileNameInvalid => 'File name contains invalid characters';

  @override
  String get fileExtensionCannotChange =>
      'The file extension cannot be changed here';

  @override
  String get fileAlreadyExists => 'A file with this name already exists';

  @override
  String get fileActionsTitle => 'File actions';

  @override
  String get copyFileAction => 'Copy to folder';

  @override
  String get moveFileAction => 'Move to folder';

  @override
  String get fileCopiedToast => 'File copied';

  @override
  String get fileMovedToast => 'File moved';

  @override
  String get fileTransferFailed => 'Could not complete the file operation';

  @override
  String get chooseFolderTitle => 'Choose destination folder';

  @override
  String get chooseThisFolder => 'Choose this folder';

  @override
  String get parentFolder => 'Parent folder';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get noCollectionsMessage =>
      'No matching metadata was found in your music files.';

  @override
  String deleteSelectedTitle(Object count) {
    return 'Delete $count songs?';
  }

  @override
  String get deleteSelectedMessage =>
      'The selected files will be permanently removed from your device.';

  @override
  String deletedSongsCount(Object count) {
    return '$count songs deleted';
  }

  @override
  String get libraryInsightsTitle => 'Library insights';

  @override
  String librarySummary(Object count, Object duration) {
    return '$count songs · $duration';
  }

  @override
  String get missingMetadataMetric => 'Missing metadata';

  @override
  String get shortTracksMetric => 'Short tracks';

  @override
  String get losslessMetric => 'Lossless files';

  @override
  String get largeFilesMetric => 'Files over 50 MB';

  @override
  String get duplicatesTitle => 'Potential duplicates';

  @override
  String potentialDuplicatesCount(Object count) {
    return '$count removable copies found';
  }

  @override
  String recoverableSpace(Object size) {
    return 'Up to $size can be recovered';
  }

  @override
  String get formatsTitle => 'Audio formats';

  @override
  String get duplicateScannerTitle => 'Duplicate scanner';

  @override
  String get noDuplicatesTitle => 'No likely duplicates';

  @override
  String get noDuplicatesMessage =>
      'Your library has no songs with matching title, known artist and duration.';

  @override
  String duplicateGroupSummary(Object count, Object size) {
    return '$count versions · $size recoverable';
  }

  @override
  String get recommendedToKeep => 'Recommended version to keep';

  @override
  String deleteDuplicateMessage(Object title) {
    return 'Delete \"$title\" from the device? Review its format, size and path before continuing.';
  }
}
