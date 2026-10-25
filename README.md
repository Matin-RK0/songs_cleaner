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
- **On this device** shows verified local files and accessible matching files
  awaiting confirmation. Only verified tracks enter the playback queue.
  **All music** shows the loaded music messages and offers linking or downloading.
- Existing device files with the same filename and byte size are *suggestions*.
  The user must confirm the correct file. Name/size alone never assigns provenance.
- Downloads are received through TDLib and then saved to the shared **Music/Telegram**
  folder under their original filenames. Android MediaStore publishes/indexes the
  completed audio so file managers and other music players can find it. Existing
  same-name files are not overwritten. Android 10+ uses scoped storage; older
  Android versions request the legacy storage permission when needed.
  Downloaded/linked tracks play through the existing queue and mini player.
  Native file updates refresh local availability without a manual refresh, and
  completed paths are indexed for offline reopening.
- Audio thumbnails and miniatures are read from Telegram's album-cover metadata.
  Visible covers use bounded memory/disk caching and at most three concurrent
  thumbnail requests; local MediaStore album art is used as a fallback.
- Older music messages and additional chats are loaded explicitly with **Load more**.
  Main and archived chat lists are included. Refresh preserves older indexed tracks.
- The cached chat index and existing verified files remain browsable offline.
  An authorized session reconnects automatically on subsequent visits.
- Disconnecting logs this app out and clears its chat index and bindings. TDLib
  manages its private cache on logout; published files in Music/Telegram remain
  independently in the device library, including after uninstalling this app.
  The Telegram session, key storage and index are excluded from Android backup/transfer.

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
