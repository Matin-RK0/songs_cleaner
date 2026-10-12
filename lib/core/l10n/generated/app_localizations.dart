import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کن آهنگ'**
  String get appName;

  /// No description provided for @libraryTitle.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ پاک کن'**
  String get libraryTitle;

  /// No description provided for @songsTab.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌ها'**
  String get songsTab;

  /// No description provided for @artistsTab.
  ///
  /// In fa, this message translates to:
  /// **'هنرمندان'**
  String get artistsTab;

  /// No description provided for @albumsTab.
  ///
  /// In fa, this message translates to:
  /// **'آلبوم‌ها'**
  String get albumsTab;

  /// No description provided for @searchHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی آهنگ یا خواننده…'**
  String get searchHint;

  /// No description provided for @shuffleAll.
  ///
  /// In fa, this message translates to:
  /// **'شافل همه'**
  String get shuffleAll;

  /// No description provided for @sortLabel.
  ///
  /// In fa, this message translates to:
  /// **'مرتب‌سازی'**
  String get sortLabel;

  /// No description provided for @sortByTitle.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس نام'**
  String get sortByTitle;

  /// No description provided for @sortByArtist.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس خواننده'**
  String get sortByArtist;

  /// No description provided for @sortByDateAdded.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس تاریخ افزودن'**
  String get sortByDateAdded;

  /// No description provided for @sortByDuration.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس مدت'**
  String get sortByDuration;

  /// No description provided for @refreshLibraryTooltip.
  ///
  /// In fa, this message translates to:
  /// **'به‌روزرسانی کتابخانه'**
  String get refreshLibraryTooltip;

  /// No description provided for @librarySyncedToast.
  ///
  /// In fa, this message translates to:
  /// **'کتابخانه به‌روزرسانی شد'**
  String get librarySyncedToast;

  /// No description provided for @nowPlaying.
  ///
  /// In fa, this message translates to:
  /// **'در حال پخش'**
  String get nowPlaying;

  /// No description provided for @unknownArtist.
  ///
  /// In fa, this message translates to:
  /// **'هنرمند ناشناس'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In fa, this message translates to:
  /// **'آلبوم ناشناس'**
  String get unknownAlbum;

  /// No description provided for @untitledSong.
  ///
  /// In fa, this message translates to:
  /// **'بدون عنوان'**
  String get untitledSong;

  /// No description provided for @queueTitle.
  ///
  /// In fa, this message translates to:
  /// **'صف پخش'**
  String get queueTitle;

  /// No description provided for @queueUpNext.
  ///
  /// In fa, this message translates to:
  /// **'بعدی‌ها'**
  String get queueUpNext;

  /// No description provided for @queueEmpty.
  ///
  /// In fa, this message translates to:
  /// **'چیزی در صف پخش نیست'**
  String get queueEmpty;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In fa, this message translates to:
  /// **'موزیکی پیدا نشد'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryMessage.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فایل صوتی‌ای روی دستگاه نیست یا دسترسی داده نشده است.'**
  String get emptyLibraryMessage;

  /// No description provided for @noResultsTitle.
  ///
  /// In fa, this message translates to:
  /// **'نتیجه‌ای پیدا نشد'**
  String get noResultsTitle;

  /// No description provided for @noResultsMessage.
  ///
  /// In fa, this message translates to:
  /// **'عبارت دیگری را جستجو کنید.'**
  String get noResultsMessage;

  /// No description provided for @loadingLibrary.
  ///
  /// In fa, this message translates to:
  /// **'در حال خواندن کتابخانه…'**
  String get loadingLibrary;

  /// No description provided for @errorLoadFailedTitle.
  ///
  /// In fa, this message translates to:
  /// **'خطا در خواندن کتابخانه'**
  String get errorLoadFailedTitle;

  /// No description provided for @errorLoadFailedMessage.
  ///
  /// In fa, this message translates to:
  /// **'مشکلی پیش آمد؛ دوباره تلاش کنید.'**
  String get errorLoadFailedMessage;

  /// No description provided for @retry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره'**
  String get retry;

  /// No description provided for @actionFailedGeneric.
  ///
  /// In fa, this message translates to:
  /// **'انجام عملیات ناموفق بود'**
  String get actionFailedGeneric;

  /// No description provided for @permissionTitle.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی لازم است'**
  String get permissionTitle;

  /// No description provided for @permissionAudioMessage.
  ///
  /// In fa, this message translates to:
  /// **'برای نمایش موزیک‌های دستگاه، اجازه دسترسی به فایل‌های صوتی را بدهید.'**
  String get permissionAudioMessage;

  /// No description provided for @permissionFilesMessage.
  ///
  /// In fa, this message translates to:
  /// **'برای پاک کردن آهنگ‌ها، اجازه مدیریت فایل‌ها را در تنظیمات فعال کنید.'**
  String get permissionFilesMessage;

  /// No description provided for @grantPermission.
  ///
  /// In fa, this message translates to:
  /// **'اعطای دسترسی'**
  String get grantPermission;

  /// No description provided for @openSettings.
  ///
  /// In fa, this message translates to:
  /// **'رفتن به تنظیمات'**
  String get openSettings;

  /// No description provided for @deleteAction.
  ///
  /// In fa, this message translates to:
  /// **'حذف از دستگاه'**
  String get deleteAction;

  /// No description provided for @deleteCurrentTooltip.
  ///
  /// In fa, this message translates to:
  /// **'حذف آهنگ فعلی'**
  String get deleteCurrentTooltip;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'این آهنگ حذف شود؟'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In fa, this message translates to:
  /// **'«{title}» برای همیشه از حافظه دستگاه حذف می‌شود و آهنگ بعدی پخش می‌شود.'**
  String deleteConfirmMessage(String title);

  /// No description provided for @delete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get cancel;

  /// No description provided for @songDeletedToast.
  ///
  /// In fa, this message translates to:
  /// **'«{title}» حذف شد'**
  String songDeletedToast(String title);

  /// No description provided for @songDeleteFailedToast.
  ///
  /// In fa, this message translates to:
  /// **'حذف «{title}» ناموفق بود'**
  String songDeleteFailedToast(String title);

  /// No description provided for @shuffleTooltip.
  ///
  /// In fa, this message translates to:
  /// **'شافل'**
  String get shuffleTooltip;

  /// No description provided for @repeatOffTooltip.
  ///
  /// In fa, this message translates to:
  /// **'تکرار: خاموش'**
  String get repeatOffTooltip;

  /// No description provided for @repeatAllTooltip.
  ///
  /// In fa, this message translates to:
  /// **'تکرار: همه'**
  String get repeatAllTooltip;

  /// No description provided for @repeatOneTooltip.
  ///
  /// In fa, this message translates to:
  /// **'تکرار: همین آهنگ'**
  String get repeatOneTooltip;

  /// No description provided for @playTooltip.
  ///
  /// In fa, this message translates to:
  /// **'پخش'**
  String get playTooltip;

  /// No description provided for @pauseTooltip.
  ///
  /// In fa, this message translates to:
  /// **'توقف'**
  String get pauseTooltip;

  /// No description provided for @nextTooltip.
  ///
  /// In fa, this message translates to:
  /// **'بعدی'**
  String get nextTooltip;

  /// No description provided for @previousTooltip.
  ///
  /// In fa, this message translates to:
  /// **'قبلی'**
  String get previousTooltip;

  /// No description provided for @closeTooltip.
  ///
  /// In fa, this message translates to:
  /// **'بستن'**
  String get closeTooltip;

  /// No description provided for @expandPlayerTooltip.
  ///
  /// In fa, this message translates to:
  /// **'نمایش صفحه پخش'**
  String get expandPlayerTooltip;

  /// No description provided for @playerScreenTitle.
  ///
  /// In fa, this message translates to:
  /// **'در حال پخش'**
  String get playerScreenTitle;

  /// No description provided for @songCountLabel.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ'**
  String songCountLabel(int count);

  /// No description provided for @playbackFailedToast.
  ///
  /// In fa, this message translates to:
  /// **'پخش «{title}» ممکن نشد'**
  String playbackFailedToast(String title);

  /// No description provided for @removeFromQueueTooltip.
  ///
  /// In fa, this message translates to:
  /// **'حذف از صف پخش'**
  String get removeFromQueueTooltip;

  /// No description provided for @clearQueueTooltip.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن صف'**
  String get clearQueueTooltip;

  /// No description provided for @playTooltipShort.
  ///
  /// In fa, this message translates to:
  /// **'پخش'**
  String get playTooltipShort;

  /// No description provided for @nothingPlayingTitle.
  ///
  /// In fa, this message translates to:
  /// **'چیزی در حال پخش نیست'**
  String get nothingPlayingTitle;

  /// No description provided for @backTooltip.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت'**
  String get backTooltip;

  /// No description provided for @notifPermissionTitle.
  ///
  /// In fa, this message translates to:
  /// **'نمایش کنترل‌های پخش'**
  String get notifPermissionTitle;

  /// No description provided for @notifPermissionMessage.
  ///
  /// In fa, this message translates to:
  /// **'برای دیدن آهنگ در حال پخش و دکمه‌های آن در نوار وضعیت، اجازه نوتیفیکیشن را فعال کنید.'**
  String get notifPermissionMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get settingsTitle;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In fa, this message translates to:
  /// **'ظاهر'**
  String get settingsAppearanceSection;

  /// No description provided for @themeModeTitle.
  ///
  /// In fa, this message translates to:
  /// **'تم'**
  String get themeModeTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In fa, this message translates to:
  /// **'سیستم'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In fa, this message translates to:
  /// **'روشن'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In fa, this message translates to:
  /// **'تیره'**
  String get themeModeDark;

  /// No description provided for @settingsLockScreenSection.
  ///
  /// In fa, this message translates to:
  /// **'صفحه قفل'**
  String get settingsLockScreenSection;

  /// No description provided for @lockScreenControlTitle.
  ///
  /// In fa, this message translates to:
  /// **'کنترل موزیک روی صفحه قفل'**
  String get lockScreenControlTitle;

  /// No description provided for @lockScreenControlSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'وقتی موزیک در حال پخش است و صفحه روشن می‌شود، پخش‌کننده نمایش داده شود.'**
  String get lockScreenControlSubtitle;

  /// No description provided for @lockScreenPermissionNeeded.
  ///
  /// In fa, this message translates to:
  /// **'برای فعال‌سازی، اجازه «نمایش روی برنامه‌های دیگر» را بدهید.'**
  String get lockScreenPermissionNeeded;

  /// No description provided for @lockScreenUnsupportedSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'روی این دستگاه پشتیبانی نمی‌شود.'**
  String get lockScreenUnsupportedSubtitle;

  /// No description provided for @lockScreenPermissionTitle.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی لازم است'**
  String get lockScreenPermissionTitle;

  /// No description provided for @lockScreenPermissionMessage.
  ///
  /// In fa, this message translates to:
  /// **'برای نمایش کنترل‌های موزیک روی صفحه قفل، اجازه دهید آهنگ پاک‌کن روی برنامه‌های دیگر نمایش داده شود.'**
  String get lockScreenPermissionMessage;

  /// No description provided for @lockScreenPermissionAllow.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن تنظیمات'**
  String get lockScreenPermissionAllow;

  /// No description provided for @lockScreenPermissionNotNow.
  ///
  /// In fa, this message translates to:
  /// **'الان نه'**
  String get lockScreenPermissionNotNow;

  /// No description provided for @lockScreenEnabledToast.
  ///
  /// In fa, this message translates to:
  /// **'کنترل صفحه قفل فعال شد'**
  String get lockScreenEnabledToast;

  /// No description provided for @lockScreenDisabledToast.
  ///
  /// In fa, this message translates to:
  /// **'کنترل صفحه قفل غیرفعال شد'**
  String get lockScreenDisabledToast;

  /// No description provided for @settingsPlaybackSection.
  ///
  /// In fa, this message translates to:
  /// **'پخش'**
  String get settingsPlaybackSection;

  /// No description provided for @previousGoesToPreviousTitle.
  ///
  /// In fa, this message translates to:
  /// **'دکمه آهنگ قبلی مستقیم به آهنگ قبلی برود'**
  String get previousGoesToPreviousTitle;

  /// No description provided for @previousGoesToPreviousSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'روشن: بدون توقف، بلافاصله به آهنگ قبلی بروید. خاموش: ابتدا آهنگ فعلی از اول پخش شود.'**
  String get previousGoesToPreviousSubtitle;

  /// No description provided for @playlistsTab.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست‌ها'**
  String get playlistsTab;

  /// No description provided for @smartPlaylistsSection.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست‌های هوشمند'**
  String get smartPlaylistsSection;

  /// No description provided for @myPlaylistsSection.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست‌های من'**
  String get myPlaylistsSection;

  /// No description provided for @smartLikedTitle.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌های موردعلاقه'**
  String get smartLikedTitle;

  /// No description provided for @smartRecentTitle.
  ///
  /// In fa, this message translates to:
  /// **'تازه‌افزوده‌شده‌ها'**
  String get smartRecentTitle;

  /// No description provided for @smartMostPlayedTitle.
  ///
  /// In fa, this message translates to:
  /// **'پربازدیدترین‌ها'**
  String get smartMostPlayedTitle;

  /// No description provided for @playlistsEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز پلی‌لیستی نیست'**
  String get playlistsEmptyTitle;

  /// No description provided for @playlistsEmptyMessage.
  ///
  /// In fa, this message translates to:
  /// **'یک پلی‌لیست بسازید و با نگه‌داشتن انگشت روی آهنگ‌ها آن‌ها را اضافه کنید.'**
  String get playlistsEmptyMessage;

  /// No description provided for @newPlaylist.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست جدید'**
  String get newPlaylist;

  /// No description provided for @playlistNameLabel.
  ///
  /// In fa, this message translates to:
  /// **'نام پلی‌لیست'**
  String get playlistNameLabel;

  /// No description provided for @createAction.
  ///
  /// In fa, this message translates to:
  /// **'ساختن'**
  String get createAction;

  /// No description provided for @saveAction.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get saveAction;

  /// No description provided for @renamePlaylist.
  ///
  /// In fa, this message translates to:
  /// **'تغییر نام پلی‌لیست'**
  String get renamePlaylist;

  /// No description provided for @deletePlaylist.
  ///
  /// In fa, this message translates to:
  /// **'حذف پلی‌لیست'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'«{name}» حذف شود؟'**
  String deletePlaylistConfirmTitle(String name);

  /// No description provided for @deletePlaylistConfirmMessage.
  ///
  /// In fa, this message translates to:
  /// **'این پلی‌لیست حذف می‌شود؛ خود آهنگ‌ها روی دستگاه باقی می‌مانند.'**
  String get deletePlaylistConfirmMessage;

  /// No description provided for @playlistCreatedToast.
  ///
  /// In fa, this message translates to:
  /// **'«{name}» ساخته شد'**
  String playlistCreatedToast(String name);

  /// No description provided for @playlistRenamedToast.
  ///
  /// In fa, this message translates to:
  /// **'نام پلی‌لیست تغییر کرد'**
  String get playlistRenamedToast;

  /// No description provided for @playlistDeletedToast.
  ///
  /// In fa, this message translates to:
  /// **'«{name}» حذف شد'**
  String playlistDeletedToast(String name);

  /// No description provided for @addedToPlaylistToast.
  ///
  /// In fa, this message translates to:
  /// **'به «{name}» اضافه شد'**
  String addedToPlaylistToast(String name);

  /// No description provided for @addToPlaylist.
  ///
  /// In fa, this message translates to:
  /// **'افزودن به پلی‌لیست'**
  String get addToPlaylist;

  /// No description provided for @addToFavorites.
  ///
  /// In fa, this message translates to:
  /// **'افزودن به موردعلاقه‌ها'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fa, this message translates to:
  /// **'حذف از موردعلاقه‌ها'**
  String get removeFromFavorites;

  /// No description provided for @reorderTooltip.
  ///
  /// In fa, this message translates to:
  /// **'چیدن ترتیب'**
  String get reorderTooltip;

  /// No description provided for @removeFromPlaylist.
  ///
  /// In fa, this message translates to:
  /// **'حذف از پلی‌لیست'**
  String get removeFromPlaylist;

  /// No description provided for @playlistMetaLabel.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ · {duration}'**
  String playlistMetaLabel(int count, String duration);

  /// No description provided for @playlistEmptySongsTitle.
  ///
  /// In fa, this message translates to:
  /// **'این پلی‌لیست خالی است'**
  String get playlistEmptySongsTitle;

  /// No description provided for @playlistEmptySongsMessage.
  ///
  /// In fa, this message translates to:
  /// **'روی یک آهنگ در کتابخانه نگه دارید و «افزودن به پلی‌لیست» را انتخاب کنید.'**
  String get playlistEmptySongsMessage;

  /// No description provided for @likedEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ موردعلاقه‌ای نیست'**
  String get likedEmptyTitle;

  /// No description provided for @likedEmptyMessage.
  ///
  /// In fa, this message translates to:
  /// **'روی یک آهنگ نگه دارید و آن را به موردعلاقه‌ها اضافه کنید.'**
  String get likedEmptyMessage;

  /// No description provided for @mostPlayedEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز سابقه‌ای نیست'**
  String get mostPlayedEmptyTitle;

  /// No description provided for @mostPlayedEmptyMessage.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌هایی که زیاد پخش می‌کنید اینجا نمایش داده می‌شوند.'**
  String get mostPlayedEmptyMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
