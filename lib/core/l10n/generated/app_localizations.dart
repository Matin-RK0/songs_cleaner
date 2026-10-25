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

  /// No description provided for @telegramNoActiveDownloads.
  ///
  /// In fa, this message translates to:
  /// **'دانلود فعالی وجود ندارد'**
  String get telegramNoActiveDownloads;

  /// No description provided for @telegramDownloadsOverview.
  ///
  /// In fa, this message translates to:
  /// **'{active} فعال · {queued} در صف · {paused} متوقف · {failed} ناموفق'**
  String telegramDownloadsOverview(
    int active,
    int queued,
    int paused,
    int failed,
  );

  /// No description provided for @telegramConcurrency.
  ///
  /// In fa, this message translates to:
  /// **'{count} دانلود هم‌زمان'**
  String telegramConcurrency(int count);

  /// No description provided for @telegramDownloads.
  ///
  /// In fa, this message translates to:
  /// **'دانلودها'**
  String get telegramDownloads;

  /// No description provided for @telegramQueued.
  ///
  /// In fa, this message translates to:
  /// **'در صف دانلود'**
  String get telegramQueued;

  /// No description provided for @telegramReceiving.
  ///
  /// In fa, this message translates to:
  /// **'در حال دانلود'**
  String get telegramReceiving;

  /// No description provided for @telegramSaving.
  ///
  /// In fa, this message translates to:
  /// **'در حال ذخیره در Music/Telegram…'**
  String get telegramSaving;

  /// No description provided for @telegramPaused.
  ///
  /// In fa, this message translates to:
  /// **'متوقف‌شده'**
  String get telegramPaused;

  /// No description provided for @telegramCompleted.
  ///
  /// In fa, this message translates to:
  /// **'در Music/Telegram ذخیره شد'**
  String get telegramCompleted;

  /// No description provided for @telegramCanceled.
  ///
  /// In fa, this message translates to:
  /// **'لغوشده'**
  String get telegramCanceled;

  /// No description provided for @telegramPause.
  ///
  /// In fa, this message translates to:
  /// **'توقف'**
  String get telegramPause;

  /// No description provided for @telegramResume.
  ///
  /// In fa, this message translates to:
  /// **'ادامه'**
  String get telegramResume;

  /// No description provided for @telegramPauseAll.
  ///
  /// In fa, this message translates to:
  /// **'توقف همه'**
  String get telegramPauseAll;

  /// No description provided for @telegramResumeAll.
  ///
  /// In fa, this message translates to:
  /// **'ادامه / تلاش مجدد همه'**
  String get telegramResumeAll;

  /// No description provided for @telegramClearFinished.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن موارد تمام‌شده'**
  String get telegramClearFinished;

  /// No description provided for @telegramNoDownloads.
  ///
  /// In fa, this message translates to:
  /// **'هنوز دانلودی وجود ندارد'**
  String get telegramNoDownloads;

  /// No description provided for @telegramTransferBytes.
  ///
  /// In fa, this message translates to:
  /// **'{received} از {total}'**
  String telegramTransferBytes(String received, String total);

  /// No description provided for @telegramTransferSpeed.
  ///
  /// In fa, this message translates to:
  /// **'{speed}/ثانیه · حدود {seconds} ثانیه باقی‌مانده'**
  String telegramTransferSpeed(String speed, int seconds);

  /// No description provided for @telegramPercent.
  ///
  /// In fa, this message translates to:
  /// **'{count}٪'**
  String telegramPercent(int count);

  /// No description provided for @telegramDownloadSummary.
  ///
  /// In fa, this message translates to:
  /// **'{active} فعال · {queued} در صف · {failed} ناموفق'**
  String telegramDownloadSummary(int active, int queued, int failed);

  /// No description provided for @telegramDownloadAndPlay.
  ///
  /// In fa, this message translates to:
  /// **'دانلود و پخش'**
  String get telegramDownloadAndPlay;

  /// No description provided for @telegramSearchMusic.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی آهنگ‌های بارگذاری‌شده'**
  String get telegramSearchMusic;

  /// No description provided for @telegramLoadedSearchHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجو در پیام‌های بارگذاری‌شده انجام می‌شود. برای آهنگ‌های قدیمی‌تر، موارد بیشتری بارگذاری کن.'**
  String get telegramLoadedSearchHint;

  /// No description provided for @telegramNewest.
  ///
  /// In fa, this message translates to:
  /// **'جدیدترین'**
  String get telegramNewest;

  /// No description provided for @telegramOldest.
  ///
  /// In fa, this message translates to:
  /// **'قدیمی‌ترین'**
  String get telegramOldest;

  /// No description provided for @telegramByTitle.
  ///
  /// In fa, this message translates to:
  /// **'نام آهنگ'**
  String get telegramByTitle;

  /// No description provided for @telegramPin.
  ///
  /// In fa, this message translates to:
  /// **'پین‌کردن چت'**
  String get telegramPin;

  /// No description provided for @telegramUnpin.
  ///
  /// In fa, this message translates to:
  /// **'برداشتن پین چت'**
  String get telegramUnpin;

  /// No description provided for @telegramRecent.
  ///
  /// In fa, this message translates to:
  /// **'اخیراً بازشده'**
  String get telegramRecent;

  /// No description provided for @telegramPinned.
  ///
  /// In fa, this message translates to:
  /// **'پین‌شده'**
  String get telegramPinned;

  /// No description provided for @telegramSelect.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب آهنگ‌ها'**
  String get telegramSelect;

  /// No description provided for @telegramSelection.
  ///
  /// In fa, this message translates to:
  /// **'{count} انتخاب‌شده · {size}'**
  String telegramSelection(int count, String size);

  /// No description provided for @telegramDownloadSelected.
  ///
  /// In fa, this message translates to:
  /// **'دانلود انتخاب‌شده‌ها'**
  String get telegramDownloadSelected;

  /// No description provided for @telegramQueueSelected.
  ///
  /// In fa, this message translates to:
  /// **'افزودن انتخاب‌های محلی به صف'**
  String get telegramQueueSelected;

  /// No description provided for @telegramQueueFull.
  ///
  /// In fa, this message translates to:
  /// **'صف دانلود پر است. ابتدا چند مورد را تمام یا لغو کن.'**
  String get telegramQueueFull;

  /// No description provided for @telegramDownloadLocation.
  ///
  /// In fa, this message translates to:
  /// **'محل ذخیره دانلودها Music/Telegram است. نسخه خصوصی آهنگ پس از ذخیره موفق پاک می‌شود.'**
  String get telegramDownloadLocation;

  /// No description provided for @telegramDownloadNotification.
  ///
  /// In fa, this message translates to:
  /// **'دانلود آهنگ‌های تلگرام'**
  String get telegramDownloadNotification;

  /// No description provided for @telegramOpenMessage.
  ///
  /// In fa, this message translates to:
  /// **'بازکردن پیام در تلگرام'**
  String get telegramOpenMessage;

  /// No description provided for @telegramTitle.
  ///
  /// In fa, this message translates to:
  /// **'تلگرام'**
  String get telegramTitle;

  /// No description provided for @telegramHeadline.
  ///
  /// In fa, this message translates to:
  /// **'هر چت، یک دنیای موسیقی'**
  String get telegramHeadline;

  /// No description provided for @telegramDescription.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌های کانال‌ها، گروه‌ها و گفتگوهایت را در کتابخانه‌ای جدا برای هر چت پیدا کن.'**
  String get telegramDescription;

  /// No description provided for @telegramConnect.
  ///
  /// In fa, this message translates to:
  /// **'اتصال به تلگرام'**
  String get telegramConnect;

  /// No description provided for @telegramReconnect.
  ///
  /// In fa, this message translates to:
  /// **'اتصال دوباره'**
  String get telegramReconnect;

  /// No description provided for @telegramConnected.
  ///
  /// In fa, this message translates to:
  /// **'حساب متصل است'**
  String get telegramConnected;

  /// No description provided for @telegramOffline.
  ///
  /// In fa, this message translates to:
  /// **'کتابخانه آفلاین'**
  String get telegramOffline;

  /// No description provided for @telegramOfflineHint.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌های محلی ذخیره‌شده در دسترس‌اند. برای به‌روزرسانی چت‌ها و یافتن آهنگ‌های بیشتر دوباره متصل شو.'**
  String get telegramOfflineHint;

  /// No description provided for @telegramPrivacy.
  ///
  /// In fa, this message translates to:
  /// **'ورود مستقیم از طریق تلگرام انجام می‌شود و نشست روی همین دستگاه می‌ماند. کش خصوصی برنامه اصلی تلگرام قابل اسکن نیست.'**
  String get telegramPrivacy;

  /// No description provided for @telegramFolders.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های پوشه تلگرام'**
  String get telegramFolders;

  /// No description provided for @telegramFoldersHint.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های قابل‌دسترسی گوشی؛ چت مبدا آن‌ها مشخص نیست'**
  String get telegramFoldersHint;

  /// No description provided for @telegramChats.
  ///
  /// In fa, this message translates to:
  /// **'چت‌های تو'**
  String get telegramChats;

  /// No description provided for @telegramSearch.
  ///
  /// In fa, this message translates to:
  /// **'جستجو در چت‌ها'**
  String get telegramSearch;

  /// No description provided for @telegramNoChats.
  ///
  /// In fa, this message translates to:
  /// **'هنوز چتی برای نمایش نیست'**
  String get telegramNoChats;

  /// No description provided for @telegramNoResults.
  ///
  /// In fa, this message translates to:
  /// **'چتی با این نام پیدا نشد'**
  String get telegramNoResults;

  /// No description provided for @telegramNoChatsHint.
  ///
  /// In fa, this message translates to:
  /// **'برای دیدن آهنگ‌ها به تفکیک چت، حسابت را متصل کن؛ یا فایل‌های پوشه تلگرام را ببین.'**
  String get telegramNoChatsHint;

  /// No description provided for @telegramLoadMore.
  ///
  /// In fa, this message translates to:
  /// **'نمایش بیشتر'**
  String get telegramLoadMore;

  /// No description provided for @telegramRefresh.
  ///
  /// In fa, this message translates to:
  /// **'به‌روزرسانی چت‌ها'**
  String get telegramRefresh;

  /// No description provided for @telegramLogout.
  ///
  /// In fa, this message translates to:
  /// **'قطع اتصال حساب'**
  String get telegramLogout;

  /// No description provided for @telegramLogoutTitle.
  ///
  /// In fa, this message translates to:
  /// **'اتصال تلگرام قطع شود؟'**
  String get telegramLogoutTitle;

  /// No description provided for @telegramLogoutHint.
  ///
  /// In fa, this message translates to:
  /// **'نشست تلگرام این برنامه بسته و فهرست چت‌های ذخیره‌شده پاک می‌شود. فایل‌های کتابخانه گوشی باقی می‌مانند.'**
  String get telegramLogoutHint;

  /// No description provided for @telegramPhone.
  ///
  /// In fa, this message translates to:
  /// **'شماره تلفن'**
  String get telegramPhone;

  /// No description provided for @telegramPhoneHint.
  ///
  /// In fa, this message translates to:
  /// **'شماره را با کد کشور وارد کن؛ مانند ‎+989121234567'**
  String get telegramPhoneHint;

  /// No description provided for @telegramCode.
  ///
  /// In fa, this message translates to:
  /// **'کد ورود'**
  String get telegramCode;

  /// No description provided for @telegramCodeHint.
  ///
  /// In fa, this message translates to:
  /// **'کدی که تلگرام فرستاده وارد کن. ممکن است کد در خود تلگرام برسد، نه با پیامک.'**
  String get telegramCodeHint;

  /// No description provided for @telegramPassword.
  ///
  /// In fa, this message translates to:
  /// **'رمز تأیید دومرحله‌ای'**
  String get telegramPassword;

  /// No description provided for @telegramPasswordHint.
  ///
  /// In fa, this message translates to:
  /// **'رمزی را که برای حساب تلگرامت تنظیم کرده‌ای وارد کن.'**
  String get telegramPasswordHint;

  /// No description provided for @telegramContinue.
  ///
  /// In fa, this message translates to:
  /// **'ادامه'**
  String get telegramContinue;

  /// No description provided for @telegramStarting.
  ///
  /// In fa, this message translates to:
  /// **'در حال برقراری اتصال امن…'**
  String get telegramStarting;

  /// No description provided for @telegramSetup.
  ///
  /// In fa, this message translates to:
  /// **'اتصال تلگرام نیاز به تنظیم دارد'**
  String get telegramSetup;

  /// No description provided for @telegramSetupHint.
  ///
  /// In fa, this message translates to:
  /// **'برنامه باید با TELEGRAM_API_ID و TELEGRAM_API_HASH از my.telegram.org ساخته شود. راهنما در README پروژه است.'**
  String get telegramSetupHint;

  /// No description provided for @telegramUnsupported.
  ///
  /// In fa, this message translates to:
  /// **'اتصال تلگرام در نسخه اندروید در دسترس است.'**
  String get telegramUnsupported;

  /// No description provided for @telegramOtherAuth.
  ///
  /// In fa, this message translates to:
  /// **'این حساب به مرحله تأیید دیگری نیاز دارد که هنوز در این برنامه پشتیبانی نمی‌شود. کتابخانه محلی ذخیره‌شده همچنان در دسترس است.'**
  String get telegramOtherAuth;

  /// No description provided for @telegramErrorNetwork.
  ///
  /// In fa, this message translates to:
  /// **'ارتباط با تلگرام برقرار نشد. اتصال اینترنت را بررسی و دوباره تلاش کن.'**
  String get telegramErrorNetwork;

  /// No description provided for @telegramErrorPhone.
  ///
  /// In fa, this message translates to:
  /// **'شماره تلفن معتبر را همراه با کد کشور وارد کن.'**
  String get telegramErrorPhone;

  /// No description provided for @telegramErrorCode.
  ///
  /// In fa, this message translates to:
  /// **'کد نادرست است یا منقضی شده. کد را بررسی و دوباره تلاش کن.'**
  String get telegramErrorCode;

  /// No description provided for @telegramErrorPassword.
  ///
  /// In fa, this message translates to:
  /// **'رمز نادرست است. دوباره تلاش کن.'**
  String get telegramErrorPassword;

  /// No description provided for @telegramErrorFlood.
  ///
  /// In fa, this message translates to:
  /// **'تلگرام درخواست‌ها را محدود کرده است. کمی صبر کن و دوباره تلاش کن.'**
  String get telegramErrorFlood;

  /// No description provided for @telegramErrorGeneric.
  ///
  /// In fa, this message translates to:
  /// **'عملیات تلگرام انجام نشد. دوباره تلاش کن.'**
  String get telegramErrorGeneric;

  /// No description provided for @telegramLocal.
  ///
  /// In fa, this message translates to:
  /// **'روی این دستگاه'**
  String get telegramLocal;

  /// No description provided for @telegramAllAudio.
  ///
  /// In fa, this message translates to:
  /// **'همه آهنگ‌ها'**
  String get telegramAllAudio;

  /// No description provided for @telegramLocalCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ محلی'**
  String telegramLocalCount(int count);

  /// No description provided for @telegramNoAudio.
  ///
  /// In fa, this message translates to:
  /// **'هنوز آهنگ محلی در این چت نیست'**
  String get telegramNoAudio;

  /// No description provided for @telegramNoAudioHint.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فایل قابل‌دسترسی مطابق با آهنگ‌های بارگذاری‌شده پیدا نشده است. در «همه آهنگ‌ها» آهنگ دانلود کن یا پیام‌های قدیمی‌تر را بارگذاری کن. فایل‌های داخل کش خصوصی برنامه اصلی تلگرام اینجا قابل‌دسترسی نیستند.'**
  String get telegramNoAudioHint;

  /// No description provided for @telegramLocalMatchesCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ محلی در انتظار اتصال'**
  String telegramLocalMatchesCount(int count);

  /// No description provided for @telegramLocalMatchesHint.
  ///
  /// In fa, this message translates to:
  /// **'این فایل‌ها روی دستگاه پیدا شده‌اند. برای تأیید فایل مطابق و فعال‌شدن پخش آن در این چت، دکمه اتصال را بزن.'**
  String get telegramLocalMatchesHint;

  /// No description provided for @telegramEmptyChat.
  ///
  /// In fa, this message translates to:
  /// **'در پیام‌های بارگذاری‌شده آهنگی پیدا نشد'**
  String get telegramEmptyChat;

  /// No description provided for @telegramDownload.
  ///
  /// In fa, this message translates to:
  /// **'دانلود در Music/Telegram'**
  String get telegramDownload;

  /// No description provided for @telegramErrorStorage.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره آهنگ در Music/Telegram انجام نشد. فضای خالی و دسترسی حافظه را بررسی و دوباره تلاش کن.'**
  String get telegramErrorStorage;

  /// No description provided for @telegramDownloading.
  ///
  /// In fa, this message translates to:
  /// **'در حال دانلود…'**
  String get telegramDownloading;

  /// No description provided for @telegramLink.
  ///
  /// In fa, this message translates to:
  /// **'اتصال فایل محلی'**
  String get telegramLink;

  /// No description provided for @telegramLinkTitle.
  ///
  /// In fa, this message translates to:
  /// **'فایل مطابق را انتخاب کن'**
  String get telegramLinkTitle;

  /// No description provided for @telegramLinkHint.
  ///
  /// In fa, this message translates to:
  /// **'نام و حجم این فایل‌ها یکسان است. پیش از نسبت دادن فایل به این چت، مورد درست را تأیید کن.'**
  String get telegramLinkHint;

  /// No description provided for @telegramCloud.
  ///
  /// In fa, this message translates to:
  /// **'فایل محلی در دسترس نیست'**
  String get telegramCloud;

  /// No description provided for @telegramSuggested.
  ///
  /// In fa, this message translates to:
  /// **'فایل محلی احتمالی پیدا شد'**
  String get telegramSuggested;

  /// No description provided for @telegramPlayLocal.
  ///
  /// In fa, this message translates to:
  /// **'پخش آهنگ‌های محلی'**
  String get telegramPlayLocal;

  /// No description provided for @telegramSyncAudio.
  ///
  /// In fa, this message translates to:
  /// **'به‌روزرسانی آهنگ‌ها'**
  String get telegramSyncAudio;

  /// No description provided for @telegramChannelOrGroup.
  ///
  /// In fa, this message translates to:
  /// **'گروه / کانال'**
  String get telegramChannelOrGroup;

  /// No description provided for @telegramConversation.
  ///
  /// In fa, this message translates to:
  /// **'گفتگو'**
  String get telegramConversation;

  /// No description provided for @undoAction.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی'**
  String get undoAction;

  /// No description provided for @trashRestoreFailed.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی آهنگ انجام نشد.'**
  String get trashRestoreFailed;

  /// No description provided for @trashTitle.
  ///
  /// In fa, this message translates to:
  /// **'زباله‌دان'**
  String get trashTitle;

  /// No description provided for @trashSettingsSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی یا حذف دائمی آهنگ‌ها'**
  String get trashSettingsSubtitle;

  /// No description provided for @trashEmpty.
  ///
  /// In fa, this message translates to:
  /// **'زباله‌دان خالی است'**
  String get trashEmpty;

  /// No description provided for @restoreAction.
  ///
  /// In fa, this message translates to:
  /// **'بازگردانی'**
  String get restoreAction;

  /// No description provided for @deletePermanentlyAction.
  ///
  /// In fa, this message translates to:
  /// **'حذف دائمی'**
  String get deletePermanentlyAction;

  /// No description provided for @trashRestoredToast.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ بازگردانی شد'**
  String get trashRestoredToast;

  /// No description provided for @trashDeletedToast.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ برای همیشه حذف شد'**
  String get trashDeletedToast;

  /// No description provided for @songDeleteFailedGeneric.
  ///
  /// In fa, this message translates to:
  /// **'عملیات روی فایل انجام نشد.'**
  String get songDeleteFailedGeneric;

  /// No description provided for @trashPermanentDeleteWarning.
  ///
  /// In fa, this message translates to:
  /// **'این آهنگ برای همیشه حذف می‌شود و قابل بازگردانی نیست.'**
  String get trashPermanentDeleteWarning;

  /// No description provided for @emptyTrashAction.
  ///
  /// In fa, this message translates to:
  /// **'خالی کردن زباله‌دان'**
  String get emptyTrashAction;

  /// No description provided for @trashEmptyWarning.
  ///
  /// In fa, this message translates to:
  /// **'همه آهنگ‌های زباله‌دان برای همیشه حذف می‌شوند.'**
  String get trashEmptyWarning;

  /// No description provided for @importPlaylists.
  ///
  /// In fa, this message translates to:
  /// **'درون‌ریزی پلی‌لیست‌ها'**
  String get importPlaylists;

  /// No description provided for @exportPlaylists.
  ///
  /// In fa, this message translates to:
  /// **'برون‌بری پلی‌لیست‌ها'**
  String get exportPlaylists;

  /// No description provided for @playlistsExported.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست‌ها برون‌بری شدند'**
  String get playlistsExported;

  /// No description provided for @playlistsImported.
  ///
  /// In fa, this message translates to:
  /// **'{count} پلی‌لیست درون‌ریزی شد'**
  String playlistsImported(int count);

  /// No description provided for @importedPlaylistName.
  ///
  /// In fa, this message translates to:
  /// **'پلی‌لیست درون‌ریزی‌شده'**
  String get importedPlaylistName;

  /// No description provided for @playlistFileInvalid.
  ///
  /// In fa, this message translates to:
  /// **'فایل پلی‌لیست معتبر نیست.'**
  String get playlistFileInvalid;

  /// No description provided for @playlistTransferFailed.
  ///
  /// In fa, this message translates to:
  /// **'انتقال پلی‌لیست انجام نشد.'**
  String get playlistTransferFailed;

  /// No description provided for @sharePlaylists.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک‌گذاری پلی‌لیست‌ها'**
  String get sharePlaylists;

  /// No description provided for @playlistsShared.
  ///
  /// In fa, this message translates to:
  /// **'پنجره اشتراک‌گذاری باز شد'**
  String get playlistsShared;

  /// No description provided for @shareSongAction.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک‌گذاری آهنگ'**
  String get shareSongAction;

  /// No description provided for @songShareOpened.
  ///
  /// In fa, this message translates to:
  /// **'پنجره اشتراک‌گذاری باز شد'**
  String get songShareOpened;

  /// No description provided for @songShareFailed.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک‌گذاری این آهنگ انجام نشد.'**
  String get songShareFailed;

  /// No description provided for @setAsRingtoneAction.
  ///
  /// In fa, this message translates to:
  /// **'تنظیم به‌عنوان زنگ تماس'**
  String get setAsRingtoneAction;

  /// No description provided for @ringtoneSetToast.
  ///
  /// In fa, this message translates to:
  /// **'زنگ تماس تغییر کرد'**
  String get ringtoneSetToast;

  /// No description provided for @ringtonePermissionRequired.
  ///
  /// In fa, this message translates to:
  /// **'مجوز تغییر تنظیمات سیستم را بدهید و دوباره تلاش کنید.'**
  String get ringtonePermissionRequired;

  /// No description provided for @ringtoneSetFailed.
  ///
  /// In fa, this message translates to:
  /// **'تنظیم این آهنگ به‌عنوان زنگ تماس انجام نشد.'**
  String get ringtoneSetFailed;

  /// No description provided for @sortApplied.
  ///
  /// In fa, this message translates to:
  /// **'مرتب‌سازی بر اساس {value}'**
  String sortApplied(String value);

  /// No description provided for @filterApplied.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر به‌روزرسانی شد'**
  String get filterApplied;

  /// No description provided for @historyClearedToast.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه پخش پاک شد'**
  String get historyClearedToast;

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

  /// No description provided for @scrollToTop.
  ///
  /// In fa, this message translates to:
  /// **'بازگشت به ابتدای لیست'**
  String get scrollToTop;

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

  /// No description provided for @homeTabsTitle.
  ///
  /// In fa, this message translates to:
  /// **'تب‌ها و صفحه شروع'**
  String get homeTabsTitle;

  /// No description provided for @homeTabsDescription.
  ///
  /// In fa, this message translates to:
  /// **'برای تغییر ترتیب، دستگیره کنار تب‌ها را بکشید. دایره کنار هر تب را انتخاب کنید تا هنگام باز کردن برنامه نمایش داده شود.'**
  String get homeTabsDescription;

  /// No description provided for @homeTabsDefaultSummary.
  ///
  /// In fa, this message translates to:
  /// **'صفحه شروع: {tab}'**
  String homeTabsDefaultSummary(String tab);

  /// No description provided for @homeTabsDefaultBadge.
  ///
  /// In fa, this message translates to:
  /// **'نمایش هنگام شروع برنامه'**
  String get homeTabsDefaultBadge;

  /// No description provided for @homeTabsDragHint.
  ///
  /// In fa, this message translates to:
  /// **'برای جابه‌جایی بکشید'**
  String get homeTabsDragHint;

  /// No description provided for @homeTabsReset.
  ///
  /// In fa, this message translates to:
  /// **'بازنشانی'**
  String get homeTabsReset;

  /// No description provided for @homeTabsSaving.
  ///
  /// In fa, this message translates to:
  /// **'در حال ذخیره…'**
  String get homeTabsSaving;

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

  /// No description provided for @primaryColorTitle.
  ///
  /// In fa, this message translates to:
  /// **'رنگ اصلی'**
  String get primaryColorTitle;

  /// No description provided for @widgetBackgroundTitle.
  ///
  /// In fa, this message translates to:
  /// **'پس‌زمینه ویجت صفحه اصلی'**
  String get widgetBackgroundTitle;

  /// No description provided for @widgetBackgroundDynamic.
  ///
  /// In fa, this message translates to:
  /// **'پویا'**
  String get widgetBackgroundDynamic;

  /// No description provided for @widgetBackgroundCustom.
  ///
  /// In fa, this message translates to:
  /// **'رنگ دلخواه'**
  String get widgetBackgroundCustom;

  /// No description provided for @widgetBackgroundUseDynamic.
  ///
  /// In fa, this message translates to:
  /// **'استفاده از پس‌زمینه پویا'**
  String get widgetBackgroundUseDynamic;

  /// No description provided for @colorHue.
  ///
  /// In fa, this message translates to:
  /// **'فام'**
  String get colorHue;

  /// No description provided for @colorSaturation.
  ///
  /// In fa, this message translates to:
  /// **'اشباع'**
  String get colorSaturation;

  /// No description provided for @colorBrightness.
  ///
  /// In fa, this message translates to:
  /// **'روشنایی'**
  String get colorBrightness;

  /// No description provided for @colorSuggested.
  ///
  /// In fa, this message translates to:
  /// **'رنگ‌های پیشنهادی'**
  String get colorSuggested;

  /// No description provided for @colorFineAdjustments.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات دقیق'**
  String get colorFineAdjustments;

  /// No description provided for @colorBefore.
  ///
  /// In fa, this message translates to:
  /// **'قبلی'**
  String get colorBefore;

  /// No description provided for @colorAfter.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب‌شده'**
  String get colorAfter;

  /// No description provided for @colorFieldHint.
  ///
  /// In fa, this message translates to:
  /// **'اشباع و روشنایی را انتخاب کنید یا برای تنظیم دقیق از لغزنده‌های زیر استفاده کنید.'**
  String get colorFieldHint;

  /// No description provided for @colorChoice.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب رنگ {hex}'**
  String colorChoice(String hex);

  /// No description provided for @colorDegrees.
  ///
  /// In fa, this message translates to:
  /// **'{value} درجه'**
  String colorDegrees(String value);

  /// No description provided for @colorPercent.
  ///
  /// In fa, this message translates to:
  /// **'{value}٪'**
  String colorPercent(String value);

  /// No description provided for @colorRed.
  ///
  /// In fa, this message translates to:
  /// **'قرمز'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In fa, this message translates to:
  /// **'سبز'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In fa, this message translates to:
  /// **'آبی'**
  String get colorBlue;

  /// No description provided for @primaryColorSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'رنگ تأکیدی برنامه را انتخاب کنید'**
  String get primaryColorSubtitle;

  /// No description provided for @primaryColorOption.
  ///
  /// In fa, this message translates to:
  /// **'گزینه رنگ اصلی {index}'**
  String primaryColorOption(int index);

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

  /// No description provided for @settingsLanguageSection.
  ///
  /// In fa, this message translates to:
  /// **'زبان'**
  String get settingsLanguageSection;

  /// No description provided for @languageTitle.
  ///
  /// In fa, this message translates to:
  /// **'زبان برنامه'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In fa, this message translates to:
  /// **'سیستم'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In fa, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePersian.
  ///
  /// In fa, this message translates to:
  /// **'فارسی'**
  String get languagePersian;

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

  /// No description provided for @lockScreenTimeoutTitle.
  ///
  /// In fa, this message translates to:
  /// **'زمان نمایش پخش‌کننده روی صفحه قفل'**
  String get lockScreenTimeoutTitle;

  /// No description provided for @screenLockAccessTitle.
  ///
  /// In fa, this message translates to:
  /// **'خاموش کردن صفحه با دوبار لمس فعال شود؟'**
  String get screenLockAccessTitle;

  /// No description provided for @screenLockAccessMessage.
  ///
  /// In fa, this message translates to:
  /// **'این قابلیت اختیاری برای خاموش کردن نمایشگر و قفل کردن گوشی با دوبار لمس پس‌زمینه پخش‌کننده، یا پایان زمان بی‌فعالیتی انتخاب‌شده هنگامی که گوشی قفل است، از دسترسی Accessibility اندروید استفاده می‌کند. محتوای صفحه خوانده نمی‌شود و داده‌ای جمع‌آوری یا ارسال نمی‌شود. در تنظیمات دسترس‌پذیری، بخش برنامه‌های نصب‌شده، «خاموش کردن صفحه با دوبار لمس» را فعال کنید. در صورت درخواست، ابتدا قفل گوشی را باز کنید. هر زمان می‌توانید این دسترسی را لغو کنید. پس از فعال‌سازی برگردید و دوباره پس‌زمینه را دوبار لمس کنید.'**
  String get screenLockAccessMessage;

  /// No description provided for @screenLockUnsupported.
  ///
  /// In fa, this message translates to:
  /// **'قفل کردن صفحه با دوبار لمس به اندروید ۹ یا جدیدتر نیاز دارد.'**
  String get screenLockUnsupported;

  /// No description provided for @screenLockFailed.
  ///
  /// In fa, this message translates to:
  /// **'خاموش کردن صفحه انجام نشد. سرویس دسترس‌پذیری را بررسی و دوباره تلاش کنید.'**
  String get screenLockFailed;

  /// No description provided for @lockScreenTimeoutSeconds.
  ///
  /// In fa, this message translates to:
  /// **'{seconds} ثانیه'**
  String lockScreenTimeoutSeconds(int seconds);

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

  /// No description provided for @hideQuickDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'مخفی کردن دکمه حذف سریع'**
  String get hideQuickDeleteTitle;

  /// No description provided for @hideQuickDeleteSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'با روشن بودن، دکمه حذف آهنگ از صفحه پخش نمایش داده نمی‌شود.'**
  String get hideQuickDeleteSubtitle;

  /// No description provided for @audioFocusTitle.
  ///
  /// In fa, this message translates to:
  /// **'رفتار هنگام وقفه صوتی'**
  String get audioFocusTitle;

  /// No description provided for @audioFocusPause.
  ///
  /// In fa, this message translates to:
  /// **'توقف و ادامه خودکار'**
  String get audioFocusPause;

  /// No description provided for @audioFocusDuck.
  ///
  /// In fa, this message translates to:
  /// **'کاهش موقت صدا'**
  String get audioFocusDuck;

  /// No description provided for @audioFocusIgnore.
  ///
  /// In fa, this message translates to:
  /// **'ادامه پخش'**
  String get audioFocusIgnore;

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

  /// No description provided for @removedFromPlaylistToast.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ از «{name}» حذف شد'**
  String removedFromPlaylistToast(int count, Object name);

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

  /// No description provided for @playbackOptionsTitle.
  ///
  /// In fa, this message translates to:
  /// **'گزینه‌های پخش'**
  String get playbackOptionsTitle;

  /// No description provided for @playbackSpeed.
  ///
  /// In fa, this message translates to:
  /// **'سرعت پخش'**
  String get playbackSpeed;

  /// No description provided for @sleepTimer.
  ///
  /// In fa, this message translates to:
  /// **'تایمر خواب'**
  String get sleepTimer;

  /// No description provided for @sleepTimerOff.
  ///
  /// In fa, this message translates to:
  /// **'خاموش'**
  String get sleepTimerOff;

  /// No description provided for @sleepTimerSongEnd.
  ///
  /// In fa, this message translates to:
  /// **'پایان این آهنگ'**
  String get sleepTimerSongEnd;

  /// No description provided for @sleepTimerMinutes.
  ///
  /// In fa, this message translates to:
  /// **'{minutes} دقیقه'**
  String sleepTimerMinutes(Object minutes);

  /// No description provided for @sleepTimerRemaining.
  ///
  /// In fa, this message translates to:
  /// **'تایمر خواب: {time}'**
  String sleepTimerRemaining(Object time);

  /// No description provided for @equalizerTitle.
  ///
  /// In fa, this message translates to:
  /// **'اکولایزر'**
  String get equalizerTitle;

  /// No description provided for @equalizerEnabled.
  ///
  /// In fa, this message translates to:
  /// **'فعال‌سازی اکولایزر'**
  String get equalizerEnabled;

  /// No description provided for @equalizerSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'افکت صوتی اندروید برای پخش‌کننده فعلی'**
  String get equalizerSubtitle;

  /// No description provided for @equalizerUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'اکولایزر روی این دستگاه در دسترس نیست.'**
  String get equalizerUnavailable;

  /// No description provided for @equalizerFlat.
  ///
  /// In fa, this message translates to:
  /// **'تخت'**
  String get equalizerFlat;

  /// No description provided for @equalizerBassBoost.
  ///
  /// In fa, this message translates to:
  /// **'تقویت بیس'**
  String get equalizerBassBoost;

  /// No description provided for @equalizerRange.
  ///
  /// In fa, this message translates to:
  /// **'محدوده: {min} تا {max} دسی‌بل'**
  String equalizerRange(Object max, Object min);

  /// No description provided for @gaplessPlaybackTitle.
  ///
  /// In fa, this message translates to:
  /// **'پخش بدون فاصله'**
  String get gaplessPlaybackTitle;

  /// No description provided for @gaplessPlaybackSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'حذف سکوت بین آهنگ‌های آلبوم'**
  String get gaplessPlaybackSubtitle;

  /// No description provided for @lyricsTitle.
  ///
  /// In fa, this message translates to:
  /// **'متن آهنگ'**
  String get lyricsTitle;

  /// No description provided for @lyricsUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'فایل متن .lrc کنار این آهنگ پیدا نشد.'**
  String get lyricsUnavailable;

  /// No description provided for @historyTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه پخش'**
  String get historyTitle;

  /// No description provided for @historySettingsSubtitle.
  ///
  /// In fa, this message translates to:
  /// **'آهنگ‌هایی را که اخیراً گوش داده‌اید ببینید'**
  String get historySettingsSubtitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ای وجود ندارد'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In fa, this message translates to:
  /// **'پس از شروع پخش، آهنگ‌ها اینجا نمایش داده می‌شوند.'**
  String get historyEmptyMessage;

  /// No description provided for @clearHistory.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن تاریخچه'**
  String get clearHistory;

  /// No description provided for @clearHistoryTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه پخش پاک شود؟'**
  String get clearHistoryTitle;

  /// No description provided for @clearHistoryMessage.
  ///
  /// In fa, this message translates to:
  /// **'فعالیت‌های اخیر حذف می‌شوند؛ تعداد پخش و علاقه‌مندی‌ها باقی می‌مانند.'**
  String get clearHistoryMessage;

  /// No description provided for @clearAction.
  ///
  /// In fa, this message translates to:
  /// **'پاک‌کردن'**
  String get clearAction;

  /// No description provided for @today.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fa, this message translates to:
  /// **'دیروز'**
  String get yesterday;

  /// No description provided for @playNext.
  ///
  /// In fa, this message translates to:
  /// **'پخش بعدی'**
  String get playNext;

  /// No description provided for @addToQueue.
  ///
  /// In fa, this message translates to:
  /// **'افزودن به صف'**
  String get addToQueue;

  /// No description provided for @reorderQueueTooltip.
  ///
  /// In fa, this message translates to:
  /// **'تغییر ترتیب صف'**
  String get reorderQueueTooltip;

  /// No description provided for @genresTab.
  ///
  /// In fa, this message translates to:
  /// **'سبک‌ها'**
  String get genresTab;

  /// No description provided for @foldersTab.
  ///
  /// In fa, this message translates to:
  /// **'پوشه‌ها'**
  String get foldersTab;

  /// No description provided for @unknownGenre.
  ///
  /// In fa, this message translates to:
  /// **'سبک نامشخص'**
  String get unknownGenre;

  /// No description provided for @unknownFolder.
  ///
  /// In fa, this message translates to:
  /// **'پوشه نامشخص'**
  String get unknownFolder;

  /// No description provided for @sortByAlbum.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس آلبوم'**
  String get sortByAlbum;

  /// No description provided for @sortBySize.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس حجم فایل'**
  String get sortBySize;

  /// No description provided for @sortByTrack.
  ///
  /// In fa, this message translates to:
  /// **'بر اساس شماره ترک'**
  String get sortByTrack;

  /// No description provided for @filterTitle.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر آهنگ‌ها'**
  String get filterTitle;

  /// No description provided for @filterAll.
  ///
  /// In fa, this message translates to:
  /// **'همه آهنگ‌ها'**
  String get filterAll;

  /// No description provided for @filterMissingMetadata.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات ناقص'**
  String get filterMissingMetadata;

  /// No description provided for @filterShortTracks.
  ///
  /// In fa, this message translates to:
  /// **'کوتاه‌تر از یک دقیقه'**
  String get filterShortTracks;

  /// No description provided for @filterLongTracks.
  ///
  /// In fa, this message translates to:
  /// **'ده دقیقه یا بیشتر'**
  String get filterLongTracks;

  /// No description provided for @filterLossless.
  ///
  /// In fa, this message translates to:
  /// **'صدای بدون افت کیفیت'**
  String get filterLossless;

  /// No description provided for @moreActions.
  ///
  /// In fa, this message translates to:
  /// **'گزینه‌های بیشتر'**
  String get moreActions;

  /// No description provided for @songDetailsTitle.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات آهنگ'**
  String get songDetailsTitle;

  /// No description provided for @songNotFound.
  ///
  /// In fa, this message translates to:
  /// **'این آهنگ دیگر در کتابخانه وجود ندارد'**
  String get songNotFound;

  /// No description provided for @artistLabel.
  ///
  /// In fa, this message translates to:
  /// **'خواننده'**
  String get artistLabel;

  /// No description provided for @albumLabel.
  ///
  /// In fa, this message translates to:
  /// **'آلبوم'**
  String get albumLabel;

  /// No description provided for @genreLabel.
  ///
  /// In fa, this message translates to:
  /// **'سبک'**
  String get genreLabel;

  /// No description provided for @composerLabel.
  ///
  /// In fa, this message translates to:
  /// **'آهنگساز'**
  String get composerLabel;

  /// No description provided for @trackNumberLabel.
  ///
  /// In fa, this message translates to:
  /// **'شماره ترک'**
  String get trackNumberLabel;

  /// No description provided for @durationLabel.
  ///
  /// In fa, this message translates to:
  /// **'مدت'**
  String get durationLabel;

  /// No description provided for @fileFormatLabel.
  ///
  /// In fa, this message translates to:
  /// **'فرمت'**
  String get fileFormatLabel;

  /// No description provided for @fileSizeLabel.
  ///
  /// In fa, this message translates to:
  /// **'حجم'**
  String get fileSizeLabel;

  /// No description provided for @folderLabel.
  ///
  /// In fa, this message translates to:
  /// **'پوشه'**
  String get folderLabel;

  /// No description provided for @filePathLabel.
  ///
  /// In fa, this message translates to:
  /// **'مسیر فایل'**
  String get filePathLabel;

  /// No description provided for @modifiedDateLabel.
  ///
  /// In fa, this message translates to:
  /// **'آخرین تغییر'**
  String get modifiedDateLabel;

  /// No description provided for @unknownValue.
  ///
  /// In fa, this message translates to:
  /// **'نامشخص'**
  String get unknownValue;

  /// No description provided for @editTagsTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش تگ‌ها'**
  String get editTagsTitle;

  /// No description provided for @tagEditorTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش اطلاعات آهنگ'**
  String get tagEditorTitle;

  /// No description provided for @titleLabel.
  ///
  /// In fa, this message translates to:
  /// **'عنوان'**
  String get titleLabel;

  /// No description provided for @lyricsEditorHint.
  ///
  /// In fa, this message translates to:
  /// **'متن زمان‌بندی‌شده را با فرمت .lrc وارد کنید'**
  String get lyricsEditorHint;

  /// No description provided for @titleRequired.
  ///
  /// In fa, this message translates to:
  /// **'عنوان الزامی است'**
  String get titleRequired;

  /// No description provided for @trackNumberInvalid.
  ///
  /// In fa, this message translates to:
  /// **'شماره ترک باید بین ۰ و ۹۹۹ باشد'**
  String get trackNumberInvalid;

  /// No description provided for @tagsSavedToast.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات آهنگ ذخیره شد'**
  String get tagsSavedToast;

  /// No description provided for @tagsSaveFailed.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره اطلاعات آهنگ انجام نشد'**
  String get tagsSaveFailed;

  /// No description provided for @renameFileTitle.
  ///
  /// In fa, this message translates to:
  /// **'تغییر نام فایل'**
  String get renameFileTitle;

  /// No description provided for @fileNameLabel.
  ///
  /// In fa, this message translates to:
  /// **'نام فایل'**
  String get fileNameLabel;

  /// No description provided for @fileRenamedToast.
  ///
  /// In fa, this message translates to:
  /// **'نام فایل تغییر کرد'**
  String get fileRenamedToast;

  /// No description provided for @fileRenameFailed.
  ///
  /// In fa, this message translates to:
  /// **'تغییر نام فایل انجام نشد'**
  String get fileRenameFailed;

  /// No description provided for @fileNameRequired.
  ///
  /// In fa, this message translates to:
  /// **'نام فایل الزامی است'**
  String get fileNameRequired;

  /// No description provided for @fileNameInvalid.
  ///
  /// In fa, this message translates to:
  /// **'نام فایل دارای نویسه نامعتبر است'**
  String get fileNameInvalid;

  /// No description provided for @fileExtensionCannotChange.
  ///
  /// In fa, this message translates to:
  /// **'تغییر پسوند فایل از اینجا مجاز نیست'**
  String get fileExtensionCannotChange;

  /// No description provided for @fileAlreadyExists.
  ///
  /// In fa, this message translates to:
  /// **'فایلی با این نام از قبل وجود دارد'**
  String get fileAlreadyExists;

  /// No description provided for @fileActionsTitle.
  ///
  /// In fa, this message translates to:
  /// **'عملیات فایل'**
  String get fileActionsTitle;

  /// No description provided for @copyFileAction.
  ///
  /// In fa, this message translates to:
  /// **'کپی به پوشه'**
  String get copyFileAction;

  /// No description provided for @moveFileAction.
  ///
  /// In fa, this message translates to:
  /// **'انتقال به پوشه'**
  String get moveFileAction;

  /// No description provided for @fileCopiedToast.
  ///
  /// In fa, this message translates to:
  /// **'فایل کپی شد'**
  String get fileCopiedToast;

  /// No description provided for @fileMovedToast.
  ///
  /// In fa, this message translates to:
  /// **'فایل منتقل شد'**
  String get fileMovedToast;

  /// No description provided for @fileTransferFailed.
  ///
  /// In fa, this message translates to:
  /// **'عملیات فایل انجام نشد'**
  String get fileTransferFailed;

  /// No description provided for @chooseFolderTitle.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب پوشه مقصد'**
  String get chooseFolderTitle;

  /// No description provided for @chooseThisFolder.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب این پوشه'**
  String get chooseThisFolder;

  /// No description provided for @parentFolder.
  ///
  /// In fa, this message translates to:
  /// **'پوشه والد'**
  String get parentFolder;

  /// No description provided for @selectedCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} مورد انتخاب‌شده'**
  String selectedCount(Object count);

  /// No description provided for @selectAll.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب همه'**
  String get selectAll;

  /// No description provided for @noCollectionsMessage.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات مرتبطی در فایل‌های موسیقی پیدا نشد.'**
  String get noCollectionsMessage;

  /// No description provided for @deleteSelectedTitle.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ حذف شوند؟'**
  String deleteSelectedTitle(Object count);

  /// No description provided for @deleteSelectedMessage.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های انتخاب‌شده برای همیشه از دستگاه حذف می‌شوند.'**
  String get deleteSelectedMessage;

  /// No description provided for @deletedSongsCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ حذف شد'**
  String deletedSongsCount(Object count);

  /// No description provided for @libraryInsightsTitle.
  ///
  /// In fa, this message translates to:
  /// **'تحلیل کتابخانه'**
  String get libraryInsightsTitle;

  /// No description provided for @librarySummary.
  ///
  /// In fa, this message translates to:
  /// **'{count} آهنگ · {duration}'**
  String librarySummary(Object count, Object duration);

  /// No description provided for @missingMetadataMetric.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات ناقص'**
  String get missingMetadataMetric;

  /// No description provided for @shortTracksMetric.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های کوتاه'**
  String get shortTracksMetric;

  /// No description provided for @losslessMetric.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های بدون افت'**
  String get losslessMetric;

  /// No description provided for @largeFilesMetric.
  ///
  /// In fa, this message translates to:
  /// **'فایل‌های بالای ۵۰ مگابایت'**
  String get largeFilesMetric;

  /// No description provided for @duplicatesTitle.
  ///
  /// In fa, this message translates to:
  /// **'نسخه‌های مشابه احتمالی'**
  String get duplicatesTitle;

  /// No description provided for @potentialDuplicatesCount.
  ///
  /// In fa, this message translates to:
  /// **'{count} نسخه قابل حذف پیدا شد'**
  String potentialDuplicatesCount(Object count);

  /// No description provided for @recoverableSpace.
  ///
  /// In fa, this message translates to:
  /// **'تا {size} فضا قابل آزادسازی است'**
  String recoverableSpace(Object size);

  /// No description provided for @formatsTitle.
  ///
  /// In fa, this message translates to:
  /// **'فرمت‌های صوتی'**
  String get formatsTitle;

  /// No description provided for @duplicateScannerTitle.
  ///
  /// In fa, this message translates to:
  /// **'اسکن آهنگ‌های تکراری'**
  String get duplicateScannerTitle;

  /// No description provided for @noDuplicatesTitle.
  ///
  /// In fa, this message translates to:
  /// **'نسخه مشابهی پیدا نشد'**
  String get noDuplicatesTitle;

  /// No description provided for @noDuplicatesMessage.
  ///
  /// In fa, this message translates to:
  /// **'آهنگی با عنوان، خواننده مشخص و مدت مشابه در کتابخانه وجود ندارد.'**
  String get noDuplicatesMessage;

  /// No description provided for @duplicateGroupSummary.
  ///
  /// In fa, this message translates to:
  /// **'{count} نسخه · {size} قابل آزادسازی'**
  String duplicateGroupSummary(Object count, Object size);

  /// No description provided for @recommendedToKeep.
  ///
  /// In fa, this message translates to:
  /// **'نسخه پیشنهادی برای نگهداری'**
  String get recommendedToKeep;

  /// No description provided for @deleteDuplicateMessage.
  ///
  /// In fa, this message translates to:
  /// **'«{title}» از دستگاه حذف شود؟ پیش از ادامه، فرمت، حجم و مسیر فایل را بررسی کنید.'**
  String deleteDuplicateMessage(Object title);
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
