// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get undoAction => 'بازگردانی';

  @override
  String get trashRestoreFailed => 'بازگردانی آهنگ انجام نشد.';

  @override
  String get trashTitle => 'زباله‌دان';

  @override
  String get trashSettingsSubtitle => 'بازگردانی یا حذف دائمی آهنگ‌ها';

  @override
  String get trashEmpty => 'زباله‌دان خالی است';

  @override
  String get restoreAction => 'بازگردانی';

  @override
  String get deletePermanentlyAction => 'حذف دائمی';

  @override
  String get trashRestoredToast => 'آهنگ بازگردانی شد';

  @override
  String get trashDeletedToast => 'آهنگ برای همیشه حذف شد';

  @override
  String get songDeleteFailedGeneric => 'عملیات روی فایل انجام نشد.';

  @override
  String get trashPermanentDeleteWarning =>
      'این آهنگ برای همیشه حذف می‌شود و قابل بازگردانی نیست.';

  @override
  String get emptyTrashAction => 'خالی کردن زباله‌دان';

  @override
  String get trashEmptyWarning =>
      'همه آهنگ‌های زباله‌دان برای همیشه حذف می‌شوند.';

  @override
  String get importPlaylists => 'درون‌ریزی پلی‌لیست‌ها';

  @override
  String get exportPlaylists => 'برون‌بری پلی‌لیست‌ها';

  @override
  String get playlistsExported => 'پلی‌لیست‌ها برون‌بری شدند';

  @override
  String playlistsImported(int count) {
    return '$count پلی‌لیست درون‌ریزی شد';
  }

  @override
  String get importedPlaylistName => 'پلی‌لیست درون‌ریزی‌شده';

  @override
  String get playlistFileInvalid => 'فایل پلی‌لیست معتبر نیست.';

  @override
  String get playlistTransferFailed => 'انتقال پلی‌لیست انجام نشد.';

  @override
  String get sharePlaylists => 'اشتراک‌گذاری پلی‌لیست‌ها';

  @override
  String get playlistsShared => 'پنجره اشتراک‌گذاری باز شد';

  @override
  String get shareSongAction => 'اشتراک‌گذاری آهنگ';

  @override
  String get songShareOpened => 'پنجره اشتراک‌گذاری باز شد';

  @override
  String get songShareFailed => 'اشتراک‌گذاری این آهنگ انجام نشد.';

  @override
  String get setAsRingtoneAction => 'تنظیم به‌عنوان زنگ تماس';

  @override
  String get ringtoneSetToast => 'زنگ تماس تغییر کرد';

  @override
  String get ringtonePermissionRequired =>
      'مجوز تغییر تنظیمات سیستم را بدهید و دوباره تلاش کنید.';

  @override
  String get ringtoneSetFailed => 'تنظیم این آهنگ به‌عنوان زنگ تماس انجام نشد.';

  @override
  String sortApplied(String value) {
    return 'مرتب‌سازی بر اساس $value';
  }

  @override
  String get filterApplied => 'فیلتر به‌روزرسانی شد';

  @override
  String get historyClearedToast => 'تاریخچه پخش پاک شد';

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
  String get scrollToTop => 'بازگشت به ابتدای لیست';

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
  String get primaryColorTitle => 'رنگ اصلی';

  @override
  String get primaryColorSubtitle => 'رنگ تأکیدی برنامه را انتخاب کنید';

  @override
  String primaryColorOption(int index) {
    return 'گزینه رنگ اصلی $index';
  }

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
  String get lockScreenTimeoutTitle => 'زمان نمایش پخش‌کننده روی صفحه قفل';

  @override
  String get screenLockAccessTitle => 'خاموش کردن صفحه با دوبار لمس فعال شود؟';

  @override
  String get screenLockAccessMessage =>
      'این قابلیت اختیاری برای خاموش کردن نمایشگر و قفل کردن گوشی با دوبار لمس پس‌زمینه پخش‌کننده، یا پایان زمان بی‌فعالیتی انتخاب‌شده هنگامی که گوشی قفل است، از دسترسی Accessibility اندروید استفاده می‌کند. محتوای صفحه خوانده نمی‌شود و داده‌ای جمع‌آوری یا ارسال نمی‌شود. در تنظیمات دسترس‌پذیری، بخش برنامه‌های نصب‌شده، «خاموش کردن صفحه با دوبار لمس» را فعال کنید. در صورت درخواست، ابتدا قفل گوشی را باز کنید. هر زمان می‌توانید این دسترسی را لغو کنید. پس از فعال‌سازی برگردید و دوباره پس‌زمینه را دوبار لمس کنید.';

  @override
  String get screenLockUnsupported =>
      'قفل کردن صفحه با دوبار لمس به اندروید ۹ یا جدیدتر نیاز دارد.';

  @override
  String get screenLockFailed =>
      'خاموش کردن صفحه انجام نشد. سرویس دسترس‌پذیری را بررسی و دوباره تلاش کنید.';

  @override
  String lockScreenTimeoutSeconds(int seconds) {
    return '$seconds ثانیه';
  }

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
  String get audioFocusTitle => 'رفتار هنگام وقفه صوتی';

  @override
  String get audioFocusPause => 'توقف و ادامه خودکار';

  @override
  String get audioFocusDuck => 'کاهش موقت صدا';

  @override
  String get audioFocusIgnore => 'ادامه پخش';

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
  String removedFromPlaylistToast(int count, Object name) {
    return '$count آهنگ از «$name» حذف شد';
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

  @override
  String get equalizerTitle => 'اکولایزر';

  @override
  String get equalizerEnabled => 'فعال‌سازی اکولایزر';

  @override
  String get equalizerSubtitle => 'افکت صوتی اندروید برای پخش‌کننده فعلی';

  @override
  String get equalizerUnavailable => 'اکولایزر روی این دستگاه در دسترس نیست.';

  @override
  String get equalizerFlat => 'تخت';

  @override
  String get equalizerBassBoost => 'تقویت بیس';

  @override
  String equalizerRange(Object max, Object min) {
    return 'محدوده: $min تا $max دسی‌بل';
  }

  @override
  String get gaplessPlaybackTitle => 'پخش بدون فاصله';

  @override
  String get gaplessPlaybackSubtitle => 'حذف سکوت بین آهنگ‌های آلبوم';

  @override
  String get lyricsTitle => 'متن آهنگ';

  @override
  String get lyricsUnavailable => 'فایل متن .lrc کنار این آهنگ پیدا نشد.';

  @override
  String get historyTitle => 'تاریخچه پخش';

  @override
  String get historySettingsSubtitle =>
      'آهنگ‌هایی را که اخیراً گوش داده‌اید ببینید';

  @override
  String get historyEmptyTitle => 'تاریخچه‌ای وجود ندارد';

  @override
  String get historyEmptyMessage =>
      'پس از شروع پخش، آهنگ‌ها اینجا نمایش داده می‌شوند.';

  @override
  String get clearHistory => 'پاک‌کردن تاریخچه';

  @override
  String get clearHistoryTitle => 'تاریخچه پخش پاک شود؟';

  @override
  String get clearHistoryMessage =>
      'فعالیت‌های اخیر حذف می‌شوند؛ تعداد پخش و علاقه‌مندی‌ها باقی می‌مانند.';

  @override
  String get clearAction => 'پاک‌کردن';

  @override
  String get today => 'امروز';

  @override
  String get yesterday => 'دیروز';

  @override
  String get playNext => 'پخش بعدی';

  @override
  String get addToQueue => 'افزودن به صف';

  @override
  String get reorderQueueTooltip => 'تغییر ترتیب صف';

  @override
  String get genresTab => 'سبک‌ها';

  @override
  String get foldersTab => 'پوشه‌ها';

  @override
  String get unknownGenre => 'سبک نامشخص';

  @override
  String get unknownFolder => 'پوشه نامشخص';

  @override
  String get sortByAlbum => 'بر اساس آلبوم';

  @override
  String get sortBySize => 'بر اساس حجم فایل';

  @override
  String get sortByTrack => 'بر اساس شماره ترک';

  @override
  String get filterTitle => 'فیلتر آهنگ‌ها';

  @override
  String get filterAll => 'همه آهنگ‌ها';

  @override
  String get filterMissingMetadata => 'اطلاعات ناقص';

  @override
  String get filterShortTracks => 'کوتاه‌تر از یک دقیقه';

  @override
  String get filterLongTracks => 'ده دقیقه یا بیشتر';

  @override
  String get filterLossless => 'صدای بدون افت کیفیت';

  @override
  String get moreActions => 'گزینه‌های بیشتر';

  @override
  String get songDetailsTitle => 'اطلاعات آهنگ';

  @override
  String get songNotFound => 'این آهنگ دیگر در کتابخانه وجود ندارد';

  @override
  String get artistLabel => 'خواننده';

  @override
  String get albumLabel => 'آلبوم';

  @override
  String get genreLabel => 'سبک';

  @override
  String get composerLabel => 'آهنگساز';

  @override
  String get trackNumberLabel => 'شماره ترک';

  @override
  String get durationLabel => 'مدت';

  @override
  String get fileFormatLabel => 'فرمت';

  @override
  String get fileSizeLabel => 'حجم';

  @override
  String get folderLabel => 'پوشه';

  @override
  String get filePathLabel => 'مسیر فایل';

  @override
  String get modifiedDateLabel => 'آخرین تغییر';

  @override
  String get unknownValue => 'نامشخص';

  @override
  String get editTagsTitle => 'ویرایش تگ‌ها';

  @override
  String get tagEditorTitle => 'ویرایش اطلاعات آهنگ';

  @override
  String get titleLabel => 'عنوان';

  @override
  String get lyricsEditorHint => 'متن زمان‌بندی‌شده را با فرمت .lrc وارد کنید';

  @override
  String get titleRequired => 'عنوان الزامی است';

  @override
  String get trackNumberInvalid => 'شماره ترک باید بین ۰ و ۹۹۹ باشد';

  @override
  String get tagsSavedToast => 'اطلاعات آهنگ ذخیره شد';

  @override
  String get tagsSaveFailed => 'ذخیره اطلاعات آهنگ انجام نشد';

  @override
  String get renameFileTitle => 'تغییر نام فایل';

  @override
  String get fileNameLabel => 'نام فایل';

  @override
  String get fileRenamedToast => 'نام فایل تغییر کرد';

  @override
  String get fileRenameFailed => 'تغییر نام فایل انجام نشد';

  @override
  String get fileNameRequired => 'نام فایل الزامی است';

  @override
  String get fileNameInvalid => 'نام فایل دارای نویسه نامعتبر است';

  @override
  String get fileExtensionCannotChange => 'تغییر پسوند فایل از اینجا مجاز نیست';

  @override
  String get fileAlreadyExists => 'فایلی با این نام از قبل وجود دارد';

  @override
  String get fileActionsTitle => 'عملیات فایل';

  @override
  String get copyFileAction => 'کپی به پوشه';

  @override
  String get moveFileAction => 'انتقال به پوشه';

  @override
  String get fileCopiedToast => 'فایل کپی شد';

  @override
  String get fileMovedToast => 'فایل منتقل شد';

  @override
  String get fileTransferFailed => 'عملیات فایل انجام نشد';

  @override
  String get chooseFolderTitle => 'انتخاب پوشه مقصد';

  @override
  String get chooseThisFolder => 'انتخاب این پوشه';

  @override
  String get parentFolder => 'پوشه والد';

  @override
  String selectedCount(Object count) {
    return '$count مورد انتخاب‌شده';
  }

  @override
  String get selectAll => 'انتخاب همه';

  @override
  String get noCollectionsMessage =>
      'اطلاعات مرتبطی در فایل‌های موسیقی پیدا نشد.';

  @override
  String deleteSelectedTitle(Object count) {
    return '$count آهنگ حذف شوند؟';
  }

  @override
  String get deleteSelectedMessage =>
      'فایل‌های انتخاب‌شده برای همیشه از دستگاه حذف می‌شوند.';

  @override
  String deletedSongsCount(Object count) {
    return '$count آهنگ حذف شد';
  }

  @override
  String get libraryInsightsTitle => 'تحلیل کتابخانه';

  @override
  String librarySummary(Object count, Object duration) {
    return '$count آهنگ · $duration';
  }

  @override
  String get missingMetadataMetric => 'اطلاعات ناقص';

  @override
  String get shortTracksMetric => 'فایل‌های کوتاه';

  @override
  String get losslessMetric => 'فایل‌های بدون افت';

  @override
  String get largeFilesMetric => 'فایل‌های بالای ۵۰ مگابایت';

  @override
  String get duplicatesTitle => 'نسخه‌های مشابه احتمالی';

  @override
  String potentialDuplicatesCount(Object count) {
    return '$count نسخه قابل حذف پیدا شد';
  }

  @override
  String recoverableSpace(Object size) {
    return 'تا $size فضا قابل آزادسازی است';
  }

  @override
  String get formatsTitle => 'فرمت‌های صوتی';

  @override
  String get duplicateScannerTitle => 'اسکن آهنگ‌های تکراری';

  @override
  String get noDuplicatesTitle => 'نسخه مشابهی پیدا نشد';

  @override
  String get noDuplicatesMessage =>
      'آهنگی با عنوان، خواننده مشخص و مدت مشابه در کتابخانه وجود ندارد.';

  @override
  String duplicateGroupSummary(Object count, Object size) {
    return '$count نسخه · $size قابل آزادسازی';
  }

  @override
  String get recommendedToKeep => 'نسخه پیشنهادی برای نگهداری';

  @override
  String deleteDuplicateMessage(Object title) {
    return '«$title» از دستگاه حذف شود؟ پیش از ادامه، فرمت، حجم و مسیر فایل را بررسی کنید.';
  }
}
