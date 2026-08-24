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
}
