# songs_cleaner

A local music player with library cleanup and an optional Telegram music library.

## Telegram music (Android)

The **Telegram** home tab groups music by conversation, group or channel. It uses
TDLib's real user authorization flow (phone number, verification code and optional
two-step-verification password). A bot token cannot be used for this feature.

### Configure the Telegram application

1. Create an application at <https://my.telegram.org/apps>.
2. Supply its application credentials when running/building Flutter:

```powershell
flutter run --dart-define=TELEGRAM_API_ID=YOUR_NUMERIC_ID --dart-define=TELEGRAM_API_HASH=YOUR_API_HASH
flutter build apk --release --dart-define=TELEGRAM_API_ID=YOUR_NUMERIC_ID --dart-define=TELEGRAM_API_HASH=YOUR_API_HASH
```

Use a numeric value for `TELEGRAM_API_ID`. Without these values, the UI explains
that connection is not configured; local Telegram-folder browsing still works.
Do not commit credential files. These are Telegram *application* credentials, not
the user's login code or session. The user's session database is encrypted with a
random per-install key held in Android secure storage. Phone login codes and
two-step-verification passwords are not persisted by this app.

### User flow

- Open **Telegram → Connect Telegram**, sign in, then select a chat.
- **On this device** shows existing local copies, including automatically matched
  files, ready for playback without confirmation. **All music** shows loaded music
  messages and offers downloading for tracks without an available local copy.
- Files in the device library automatically match by case-insensitive filename and
  exact nonzero byte size, after checking that the path still exists. Saved bindings
  and existing TDLib paths take priority; otherwise duplicate matches use a stable
  path order. The same file may serve multiple chats without copying or downloading
  it again. This identifies a usable local copy, not the file's original source chat.
- Downloads are received through TDLib and then saved to the shared **Music/Telegram**
  folder under their original filenames. Android MediaStore publishes/indexes the
  completed audio so file managers and other music players can find it. Existing
  same-name files are not overwritten. Android 10+ uses scoped storage; older
  Android versions request the legacy storage permission when needed.
  Downloaded/matched tracks play through the existing queue and mini player.
  Native file updates refresh local availability without a manual refresh, and
  completed paths are indexed for offline reopening.
- Audio thumbnails and miniatures are read from Telegram's album-cover metadata.
  Visible covers use bounded memory/disk caching and at most three concurrent
  thumbnail requests; local MediaStore album art is used as a fallback.
- Older music messages load near the end of the list, with **Load more** as an
  explicit fallback. Additional chats are loaded with **Load more**.
  Main and archived chat lists are included. Refresh preserves older indexed tracks.
- The cached chat index and existing verified files remain browsable offline.
  An authorized session reconnects automatically on subsequent visits.
- Disconnecting logs this app out and clears its chat index and bindings. TDLib
  manages its private cache on logout; published files in Music/Telegram remain
  independently in the device library, including after uninstalling this app.
  The Telegram session, key storage and index are excluded from Android backup/transfer.

### Telegram UX and download lifecycle

- **Clear Telegram cache** is available in Settings and the Telegram chat-list
  toolbar. It clears cached images and the app's offline chat/music index while
  preserving public music, bindings, transfer progress, preferences and login.
  The optional sign-out choice also ends the TDLib session and resets Telegram
  preferences; it stops active transfers and keeps music files on the device.
  Browsing or refreshing may populate the cache again. The native session database
  is retained by cache-only cleanup and managed by TDLib when signing out.

- Device music and Telegram music share `MusicTrackCard`; playable Telegram
  tracks use the same `SongTile` actions as the device library. Cloud messages
  never become fake playable files.
- Chats support pinned/recent ordering, verified local-track counts, an active
  download badge and cached profile pictures. Query, sort, filter and scroll
  position are retained per chat. Search explicitly covers loaded messages.
- Chat lists separate pinned chats from other chats, including within search
  results. Missing chat pictures use a grapheme-safe first letter and an
  ID-stable, theme-aware color. Empty sections are hidden.
- Downloads are grouped as active (queued/receiving/saving), needs attention
  (paused/failed), and finished (completed/canceled). Group membership updates
  independently of byte progress, and rows retain their existing controls.
- Long press selects tracks. Group download confirms the missing tracks' size;
  local selections can be queued or added to playlists. Download-and-play is
  explicit. Opening a Telegram message uses TDLib's message link when available.
- The shared download panel shows received/total bytes, percentage, smoothed speed
  and approximate ETA. Receiving, waiting, paused, saving, failed and complete are
  separate states. Completion means the public file has been committed and verified.
  Committed downloads become playable from their public path immediately; a
  delayed library scan or a recoverable metadata-write error does not mark a
  saved file as failed. Temporary source cleanup waits for a durable path index.
- The application-level queue is independent of chat routes. It deduplicates by
  TDLib file id, supports pause/resume/cancel/retry, defaults to two concurrent
  transfers and allows one to three. Pending work is capped at 200 and finished
  UI history at 40. Storage/network/rate-limit errors pause waiting work.
- In-progress queue metadata is persisted. After process death, entries restore
  **paused**, without claiming that old partial bytes still exist or auto-playing.
  Registered interrupted temporary audio is pruned on the next connection.
- TDLib still needs **temporary private audio** while receiving; a paused transfer
  may retain partial bytes for resuming. After a verified public copy and durable
  path index exist, its full private copy is deleted. Cancel discards the private
  transfer. Upgrade cleanup also removes old private duplicates with a verified
  public counterpart, excluding paths still used by the playback queue.
- Public `Music/Telegram` files are never deleted by cache maintenance. Canonical
  path checks constrain filesystem fallback cleanup to this installation's TDLib
  files directory. Thumbnail/profile-photo cache optimization excludes audio.
- Progress notifications use an Android dataSync foreground service with a bounded
  wake lock and heartbeat watchdog. The storage bridge belongs to the Flutter
  engine, not an Activity. Tapping the notification opens Downloads. Android
  service restrictions/process termination still apply; process-death recovery
  restores metadata rather than pretending a headless Dart engine was restarted.
- Progress UI commits at most every 250ms; page/list identity subscribers do not
  rebuild for byte packets. Disk snapshots are coalesced and JSON work is isolated.
  Images have bounded request concurrency, queue length and an LRU; offscreen
  queued requests are skipped. Metadata/session storage remains private.
- Chat avatar Hero transitions, cached route slides, download-icon swaps and the
  floating selection panel respect reduced motion. Repeating indicators stop
  under hidden routes. Selection does not insert a header that shifts song rows.

Android notification delivery, Activity recreation, background restrictions,
real file publication and ten-minute memory/frame stability need a real-device
Profile/Release session. Unit/widget tests cannot certify zero leaks or a frame budget.

### Boundaries

An ordinary music app cannot read another app's private Telegram database/cache.
This feature cannot automatically recover the exact source chat of every file
previously downloaded by the official app. A track can also occur in several chats.
Accessible Telegram folders are listed separately without invented chat labels.
Only file paths visible in the device library are offered for matching.

This integration currently supports one account, ordinary cloud chats and Telegram
audio messages. Secret chats and extra authorization flows (for example email
verification/registration) are not supported. Connection is Android-only; the
bundled TDLib native library is supplied by the pinned `handy_tdlib_next` package.
It adds native-library size to the APK. No server/backend is required.

### Architecture and checks

`lib/features/telegram/` contains domain models/matching rules, a repository contract,
TDLib transport and persistence, Riverpod controllers, and presentation widgets.
Native polling and TDLib JSON parsing run in a separate isolate. Lists are lazy;
the small entrance animation caches its curve/tween, uses a repaint-isolated scale
transition and respects reduced motion. Text is localized in English and Persian.

```powershell
flutter analyze
flutter test test/features/telegram/
flutter run --profile --dart-define=TELEGRAM_API_ID=YOUR_NUMERIC_ID --dart-define=TELEGRAM_API_HASH=YOUR_API_HASH
```

Live authorization, downloads and animation frame times must be verified on an
Android device with your own Telegram application credentials.

References: [TDLib](https://core.telegram.org/tdlib),
[Telegram application registration](https://core.telegram.org/api/obtaining_api_id),
[binding/native library](https://pub.dev/packages/handy_tdlib_next).
