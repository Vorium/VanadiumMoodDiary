import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'慢病管家'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In zh, this message translates to:
  /// **'我今天吃了药'**
  String get appTagline;

  /// No description provided for @homeCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'我今天吃了药'**
  String get homeCheckIn;

  /// No description provided for @homeCheckedIn.
  ///
  /// In zh, this message translates to:
  /// **'今天已打卡 ✓'**
  String get homeCheckedIn;

  /// No description provided for @homeStreak.
  ///
  /// In zh, this message translates to:
  /// **'已坚持 {days} 天'**
  String homeStreak(int days);

  /// No description provided for @homeLastMed.
  ///
  /// In zh, this message translates to:
  /// **'最后吃药：{time}'**
  String homeLastMed(String time);

  /// No description provided for @homeNextReminder.
  ///
  /// In zh, this message translates to:
  /// **'下次提醒：{time}'**
  String homeNextReminder(String time);

  /// No description provided for @homeStillOnline.
  ///
  /// In zh, this message translates to:
  /// **'🌱 你还在线'**
  String get homeStillOnline;

  /// No description provided for @homeTempMed.
  ///
  /// In zh, this message translates to:
  /// **'临时吃药 +'**
  String get homeTempMed;

  /// No description provided for @homeStreakBroken.
  ///
  /// In zh, this message translates to:
  /// **'少 1 次没关系，明天继续'**
  String get homeStreakBroken;

  /// No description provided for @setupStep.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} 步 / 共 {total} 步'**
  String setupStep(int current, int total);

  /// No description provided for @setupHello.
  ///
  /// In zh, this message translates to:
  /// **'你好，我是慢病管家'**
  String get setupHello;

  /// No description provided for @setupIntro.
  ///
  /// In zh, this message translates to:
  /// **'1 分钟设置好，然后每天 1 次打卡'**
  String get setupIntro;

  /// No description provided for @setupName.
  ///
  /// In zh, this message translates to:
  /// **'你的名字'**
  String get setupName;

  /// No description provided for @setupNameHint.
  ///
  /// In zh, this message translates to:
  /// **'小明'**
  String get setupNameHint;

  /// No description provided for @setupContacts.
  ///
  /// In zh, this message translates to:
  /// **'紧急联系人邮箱（至少 1 个）'**
  String get setupContacts;

  /// No description provided for @setupContactHint.
  ///
  /// In zh, this message translates to:
  /// **'mom@example.com'**
  String get setupContactHint;

  /// No description provided for @setupAddContact.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加另一个联系人'**
  String get setupAddContact;

  /// No description provided for @setupNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步 →'**
  String get setupNext;

  /// No description provided for @setupMedName.
  ///
  /// In zh, this message translates to:
  /// **'药名'**
  String get setupMedName;

  /// No description provided for @setupMedNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入药盒上的名称（选填）'**
  String get setupMedNameHint;

  /// No description provided for @setupMedFrequency.
  ///
  /// In zh, this message translates to:
  /// **'每日次数'**
  String get setupMedFrequency;

  /// No description provided for @setupMedTimes1.
  ///
  /// In zh, this message translates to:
  /// **'1次'**
  String get setupMedTimes1;

  /// No description provided for @setupMedTimes2.
  ///
  /// In zh, this message translates to:
  /// **'2次'**
  String get setupMedTimes2;

  /// No description provided for @setupMedTimes3.
  ///
  /// In zh, this message translates to:
  /// **'3次'**
  String get setupMedTimes3;

  /// No description provided for @setupMedSchedule.
  ///
  /// In zh, this message translates to:
  /// **'吃药时间（可填）'**
  String get setupMedSchedule;

  /// No description provided for @setupStart.
  ///
  /// In zh, this message translates to:
  /// **'开始我的第 1 天'**
  String get setupStart;

  /// No description provided for @setupDoneTitle.
  ///
  /// In zh, this message translates to:
  /// **'全部完成！'**
  String get setupDoneTitle;

  /// No description provided for @setupDoneSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'明天开始你的第 1 天'**
  String get setupDoneSubtitle;

  /// No description provided for @setupDailyRoutine.
  ///
  /// In zh, this message translates to:
  /// **'我每天会做：'**
  String get setupDailyRoutine;

  /// No description provided for @setupReminder1.
  ///
  /// In zh, this message translates to:
  /// **'✓ 推送 1 次提醒'**
  String get setupReminder1;

  /// No description provided for @setupReminder2.
  ///
  /// In zh, this message translates to:
  /// **'✓ 你点 1 下 = 打卡'**
  String get setupReminder2;

  /// No description provided for @setupReminder3.
  ///
  /// In zh, this message translates to:
  /// **'✓ 漏 2 天我会联系紧急人'**
  String get setupReminder3;

  /// No description provided for @setupPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'你的数据：'**
  String get setupPrivacy;

  /// No description provided for @setupPrivacy1.
  ///
  /// In zh, this message translates to:
  /// **'• 本地加密'**
  String get setupPrivacy1;

  /// No description provided for @setupPrivacy2.
  ///
  /// In zh, this message translates to:
  /// **'• 不会上传云端（除邮件通知）'**
  String get setupPrivacy2;

  /// No description provided for @setupPrivacy3.
  ///
  /// In zh, this message translates to:
  /// **'• 你可以随时导出'**
  String get setupPrivacy3;

  /// No description provided for @settingsContacts.
  ///
  /// In zh, this message translates to:
  /// **'紧急联系人'**
  String get settingsContacts;

  /// No description provided for @settingsMedication.
  ///
  /// In zh, this message translates to:
  /// **'常吃药'**
  String get settingsMedication;

  /// No description provided for @settingsEmailPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览停药通知邮件'**
  String get settingsEmailPreview;

  /// No description provided for @settingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get settingsAbout;

  /// No description provided for @settingsDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get settingsDisclaimer;

  /// No description provided for @settingsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get settingsExport;

  /// No description provided for @settingsMedReport.
  ///
  /// In zh, this message translates to:
  /// **'用药报告'**
  String get settingsMedReport;

  /// No description provided for @settingsMedReportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选时间窗口（7/14/30 天），给医生看'**
  String get settingsMedReportSubtitle;

  /// No description provided for @settingsMedReportChooseTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择时间窗口'**
  String get settingsMedReportChooseTitle;

  /// No description provided for @settingsMedReportChooseSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'会统计这段时间内的所有常吃药 + 临时用药'**
  String get settingsMedReportChooseSubtitle;

  /// No description provided for @settingsMedReportWindow7.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天'**
  String get settingsMedReportWindow7;

  /// No description provided for @settingsMedReportWindow14.
  ///
  /// In zh, this message translates to:
  /// **'近 14 天'**
  String get settingsMedReportWindow14;

  /// No description provided for @settingsMedReportWindow30.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get settingsMedReportWindow30;

  /// No description provided for @settingsReportHistory.
  ///
  /// In zh, this message translates to:
  /// **'报告历史'**
  String get settingsReportHistory;

  /// No description provided for @settingsReportHistorySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看过去生成的用药报告'**
  String get settingsReportHistorySubtitle;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In zh, this message translates to:
  /// **'出错了，请重试'**
  String get commonError;

  /// Generic error snackbar: '<action> failed: <error>'. Action is the user-facing action (保存/删除/导出/...)
  ///
  /// In zh, this message translates to:
  /// **'{action}失败：{error}'**
  String snackbarErrorTemplate(String action, String error);

  /// No description provided for @snackbarCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get snackbarCopied;

  /// No description provided for @snackbarNeedMicPermission.
  ///
  /// In zh, this message translates to:
  /// **'需要麦克风权限'**
  String get snackbarNeedMicPermission;

  /// No description provided for @snackbarEmptyVent.
  ///
  /// In zh, this message translates to:
  /// **'写点东西或录一段吧'**
  String get snackbarEmptyVent;

  /// No description provided for @snackbarStopRecording.
  ///
  /// In zh, this message translates to:
  /// **'请先停止录音'**
  String get snackbarStopRecording;

  /// No description provided for @snackbarPhoneInvalid.
  ///
  /// In zh, this message translates to:
  /// **'手机号格式不对（11 位数字）'**
  String get snackbarPhoneInvalid;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
