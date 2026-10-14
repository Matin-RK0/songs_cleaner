// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'پاک‌کن آهنگ';

  @override
  String get libraryTitle => 'آهنگ پاک کن';

  @override
  String get songsTab => 'آهنگ‌ها';

  @override
  String get artistsTab => 'هنرمندان';

  @override
  String get albumsTab => 'آلبوم‌ها';

  @override
  String get searchHint => 'جستجوی آهنگ یا خواننده…';

  @override
  String get shuffleAll => 'شافل همه';

  @override
  String get sortLabel => 'مرتب‌سازی';

  @override
  String get sortByTitle => 'بر اساس نام';

  @override
  String get sortByArtist => 'بر اساس خواننده';

  @override
  String get sortByDateAdded => 'بر اساس تاریخ افزودن';

  @override
  String get sortByDuration => 'بر اساس مدت';

  @override
  String get refreshLibraryTooltip => 'به‌روزرسانی کتابخانه';

  @override
  String get librarySyncedToast => 'کتابخانه به‌روزرسانی شد';

  @override
  String get nowPlaying => 'در حال پخش';

  @override
  String get unknownArtist => 'هنرمند ناشناس';

  @override
  String get unknownAlbum => 'آلبوم ناشناس';

  @override
  String get untitledSong => 'بدون عنوان';

  @override
  String get queueTitle => 'صف پخش';

  @override
  String get queueUpNext => 'بعدی‌ها';

  @override
  String get queueEmpty => 'چیزی در صف پخش نیست';

  @override
  String get emptyLibraryTitle => 'موزیکی پیدا نشد';

  @override
  String get emptyLibraryMessage =>
      'هنوز فایل صوتی‌ای روی دستگاه نیست یا دسترسی داده نشده است.';

  @override
  String get noResultsTitle => 'نتیجه‌ای پیدا نشد';

  @override
  String get noResultsMessage => 'عبارت دیگری را جستجو کنید.';

  @override
  String get loadingLibrary => 'در حال خواندن کتابخانه…';

  @override
  String get errorLoadFailedTitle => 'خطا در خواندن کتابخانه';

  @override
  String get errorLoadFailedMessage => 'مشکلی پیش آمد؛ دوباره تلاش کنید.';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get actionFailedGeneric => 'انجام عملیات ناموفق بود';

  @override
  String get permissionTitle => 'دسترسی لازم است';

  @override
  String get permissionAudioMessage =>
      'برای نمایش موزیک‌های دستگاه، اجازه دسترسی به فایل‌های صوتی را بدهید.';

  @override
  String get permissionFilesMessage =>
      'برای پاک کردن آهنگ‌ها، اجازه مدیریت فایل‌ها را در تنظیمات فعال کنید.';

  @override
  String get grantPermission => 'اعطای دسترسی';

  @override
  String get openSettings => 'رفتن به تنظیمات';

  @override
  String get deleteAction => 'حذف از دستگاه';

  @override
  String get deleteCurrentTooltip => 'حذف آهنگ فعلی';

  @override
  String get deleteConfirmTitle => 'این آهنگ حذف شود؟';

  @override
  String deleteConfirmMessage(String title) {
    return '«$title» برای همیشه از حافظه دستگاه حذف می‌شود و آهنگ بعدی پخش می‌شود.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'انصراف';

  @override
  String songDeletedToast(String title) {
    return '«$title» حذف شد';
  }

  @override
  String songDeleteFailedToast(String title) {
    return 'حذف «$title» ناموفق بود';
  }

  @override
  String get shuffleTooltip => 'شافل';

  @override
  String get repeatOffTooltip => 'تکرار: خاموش';

  @override
  String get repeatAllTooltip => 'تکرار: همه';

  @override
  String get repeatOneTooltip => 'تکرار: همین آهنگ';

  @override
  String get playTooltip => 'پخش';

  @override
  String get pauseTooltip => 'توقف';

  @override
  String get nextTooltip => 'بعدی';

  @override
  String get previousTooltip => 'قبلی';

  @override
  String get closeTooltip => 'بستن';

  @override
  String get expandPlayerTooltip => 'نمایش صفحه پخش';

  @override
  String get playerScreenTitle => 'در حال پخش';

  @override
  String songCountLabel(int count) {
    return '$count آهنگ';
  }

  @override
  String playbackFailedToast(String title) {
    return 'پخش «$title» ممکن نشد';
  }

  @override
  String get removeFromQueueTooltip => 'حذف از صف پخش';

  @override
  String get clearQueueTooltip => 'پاک کردن صف';

  @override
  String get playTooltipShort => 'پخش';

  @override
  String get nothingPlayingTitle => 'چیزی در حال پخش نیست';

  @override
  String get backTooltip => 'بازگشت';

  @override
  String get notifPermissionTitle => 'نمایش کنترل‌های پخش';

  @override
  String get notifPermissionMessage =>
      'برای دیدن آهنگ در حال پخش و دکمه‌های آن در نوار وضعیت، اجازه نوتیفیکیشن را فعال کنید.';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingsAppearanceSection => 'ظاهر';

  @override
  String get themeModeTitle => 'تم';

  @override
  String get themeModeSystem => 'سیستم';

  @override
  String get themeModeLight => 'روشن';

  @override
  String get themeModeDark => 'تیره';

  @override
  String get settingsLanguageSection => 'زبان';

  @override
  String get languageTitle => 'زبان برنامه';

  @override
  String get languageSystem => 'سیستم';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get settingsLockScreenSection => 'صفحه قفل';

  @override
  String get lockScreenControlTitle => 'کنترل موزیک روی صفحه قفل';

  @override
  String get lockScreenControlSubtitle =>
      'وقتی موزیک در حال پخش است و صفحه روشن می‌شود، پخش‌کننده نمایش داده شود.';

  @override
  String get lockScreenPermissionNeeded =>
      'برای فعال‌سازی، اجازه «نمایش روی برنامه‌های دیگر» را بدهید.';

  @override
  String get lockScreenUnsupportedSubtitle =>
      'روی این دستگاه پشتیبانی نمی‌شود.';

  @override
  String get lockScreenPermissionTitle => 'دسترسی لازم است';

  @override
  String get lockScreenPermissionMessage =>
      'برای نمایش کنترل‌های موزیک روی صفحه قفل، اجازه دهید آهنگ پاک‌کن روی برنامه‌های دیگر نمایش داده شود.';

  @override
  String get lockScreenPermissionAllow => 'باز کردن تنظیمات';

  @override
  String get lockScreenPermissionNotNow => 'الان نه';

  @override
  String get lockScreenEnabledToast => 'کنترل صفحه قفل فعال شد';

  @override
  String get lockScreenDisabledToast => 'کنترل صفحه قفل غیرفعال شد';

  @override
  String get settingsPlaybackSection => 'پخش';

  @override
  String get previousGoesToPreviousTitle =>
      'دکمه آهنگ قبلی مستقیم به آهنگ قبلی برود';

  @override
  String get previousGoesToPreviousSubtitle =>
      'روشن: بدون توقف، بلافاصله به آهنگ قبلی بروید. خاموش: ابتدا آهنگ فعلی از اول پخش شود.';

  @override
  String get hideQuickDeleteTitle => 'مخفی کردن دکمه حذف سریع';

  @override
  String get hideQuickDeleteSubtitle =>
      'با روشن بودن، دکمه حذف آهنگ از صفحه پخش نمایش داده نمی‌شود.';

  @override
  String get playlistsTab => 'پلی‌لیست‌ها';

  @override
  String get smartPlaylistsSection => 'پلی‌لیست‌های هوشمند';

  @override
  String get myPlaylistsSection => 'پلی‌لیست‌های من';

  @override
  String get smartLikedTitle => 'آهنگ‌های موردعلاقه';

  @override
  String get smartRecentTitle => 'تازه‌افزوده‌شده‌ها';

  @override
  String get smartMostPlayedTitle => 'پربازدیدترین‌ها';

  @override
  String get playlistsEmptyTitle => 'هنوز پلی‌لیستی نیست';

  @override
  String get playlistsEmptyMessage =>
      'یک پلی‌لیست بسازید و با نگه‌داشتن انگشت روی آهنگ‌ها آن‌ها را اضافه کنید.';

  @override
  String get newPlaylist => 'پلی‌لیست جدید';

  @override
  String get playlistNameLabel => 'نام پلی‌لیست';

  @override
  String get createAction => 'ساختن';

  @override
  String get saveAction => 'ذخیره';

  @override
  String get renamePlaylist => 'تغییر نام پلی‌لیست';

  @override
  String get deletePlaylist => 'حذف پلی‌لیست';

  @override
  String deletePlaylistConfirmTitle(String name) {
    return '«$name» حذف شود؟';
  }

  @override
  String get deletePlaylistConfirmMessage =>
      'این پلی‌لیست حذف می‌شود؛ خود آهنگ‌ها روی دستگاه باقی می‌مانند.';

  @override
  String playlistCreatedToast(String name) {
    return '«$name» ساخته شد';
  }

  @override
  String get playlistRenamedToast => 'نام پلی‌لیست تغییر کرد';

  @override
  String playlistDeletedToast(String name) {
    return '«$name» حذف شد';
  }

  @override
  String addedToPlaylistToast(String name) {
    return 'به «$name» اضافه شد';
  }

  @override
  String get addToPlaylist => 'افزودن به پلی‌لیست';

  @override
  String get addToFavorites => 'افزودن به موردعلاقه‌ها';

  @override
  String get removeFromFavorites => 'حذف از موردعلاقه‌ها';

  @override
  String get reorderTooltip => 'چیدن ترتیب';

  @override
  String get removeFromPlaylist => 'حذف از پلی‌لیست';

  @override
  String playlistMetaLabel(int count, String duration) {
    return '$count آهنگ · $duration';
  }

  @override
  String get playlistEmptySongsTitle => 'این پلی‌لیست خالی است';

  @override
  String get playlistEmptySongsMessage =>
      'روی یک آهنگ در کتابخانه نگه دارید و «افزودن به پلی‌لیست» را انتخاب کنید.';

  @override
  String get likedEmptyTitle => 'آهنگ موردعلاقه‌ای نیست';

  @override
  String get likedEmptyMessage =>
      'روی یک آهنگ نگه دارید و آن را به موردعلاقه‌ها اضافه کنید.';

  @override
  String get mostPlayedEmptyTitle => 'هنوز سابقه‌ای نیست';

  @override
  String get mostPlayedEmptyMessage =>
      'آهنگ‌هایی که زیاد پخش می‌کنید اینجا نمایش داده می‌شوند.';

  @override
  String get playbackOptionsTitle => 'گزینه‌های پخش';

  @override
  String get playbackSpeed => 'سرعت پخش';

  @override
  String get sleepTimer => 'تایمر خواب';

  @override
  String get sleepTimerOff => 'خاموش';

  @override
  String get sleepTimerSongEnd => 'پایان این آهنگ';

  @override
  String sleepTimerMinutes(Object minutes) {
    return '$minutes دقیقه';
  }

  @override
  String sleepTimerRemaining(Object time) {
    return 'تایمر خواب: $time';
  }
}
