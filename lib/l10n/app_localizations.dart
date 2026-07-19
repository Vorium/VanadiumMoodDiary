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

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsDataManagement.
  ///
  /// In zh, this message translates to:
  /// **'数据管理'**
  String get settingsDataManagement;

  /// No description provided for @settingsExportData.
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get settingsExportData;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'生成 JSON，复制到安全地方'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImportData.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get settingsImportData;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从 JSON 恢复（覆盖现有数据）'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsReminders.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get settingsReminders;

  /// No description provided for @settingsReminderCenter.
  ///
  /// In zh, this message translates to:
  /// **'提醒中心'**
  String get settingsReminderCenter;

  /// No description provided for @settingsReminderCenterSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理所有提醒：每日打卡、用药时间、续方、心理评估、失联通知'**
  String get settingsReminderCenterSubtitle;

  /// No description provided for @settingsRefillManagement.
  ///
  /// In zh, this message translates to:
  /// **'续方管理'**
  String get settingsRefillManagement;

  /// No description provided for @settingsRefillManagementSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'集中查看所有药物的续方状态'**
  String get settingsRefillManagementSubtitle;

  /// No description provided for @settingsAssessment.
  ///
  /// In zh, this message translates to:
  /// **'心理评估'**
  String get settingsAssessment;

  /// No description provided for @settingsAssessmentHistory.
  ///
  /// In zh, this message translates to:
  /// **'评估历史'**
  String get settingsAssessmentHistory;

  /// No description provided for @settingsAssessmentHistorySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看所有 PHQ-9 / GAD-7 评估的折线图与对比'**
  String get settingsAssessmentHistorySubtitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'v0.1.0 · 我今天吃了药'**
  String get settingsAboutVersion;

  /// No description provided for @settingsDisclaimerText.
  ///
  /// In zh, this message translates to:
  /// **'本应用不提供医疗建议，所有功能仅供参考。'**
  String get settingsDisclaimerText;

  /// No description provided for @settingsExportDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出数据'**
  String get settingsExportDialogTitle;

  /// No description provided for @settingsExportInstruction.
  ///
  /// In zh, this message translates to:
  /// **'把下面这串 JSON 保存到安全的地方：'**
  String get settingsExportInstruction;

  /// No description provided for @settingsExportVentWarning.
  ///
  /// In zh, this message translates to:
  /// **'说明：树洞(私密倾诉)的文字会导出，但录音文件不导出——录音存在 App 本地，重装后路径失效，无法跨设备复用。'**
  String get settingsExportVentWarning;

  /// No description provided for @settingsCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get settingsCopy;

  /// No description provided for @settingsActionExport.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get settingsActionExport;

  /// No description provided for @settingsActionGenerateReport.
  ///
  /// In zh, this message translates to:
  /// **'生成报告'**
  String get settingsActionGenerateReport;

  /// No description provided for @settingsImportDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入数据'**
  String get settingsImportDialogTitle;

  /// No description provided for @settingsImportWarning.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 会覆盖现有所有数据，确定后再继续'**
  String get settingsImportWarning;

  /// No description provided for @settingsImportHint.
  ///
  /// In zh, this message translates to:
  /// **'把导出的 JSON 粘贴到这里'**
  String get settingsImportHint;

  /// No description provided for @settingsImportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'导入完成：{summary}'**
  String settingsImportSuccess(String summary);

  /// No description provided for @settingsActionImport.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get settingsActionImport;

  /// No description provided for @settingsImportAndOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'导入并覆盖'**
  String get settingsImportAndOverwrite;

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

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonGotIt.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get commonGotIt;

  /// No description provided for @commonConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除这条？'**
  String get commonConfirmDelete;

  /// No description provided for @commonLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{error}'**
  String commonLoadFailed(String error);

  /// No description provided for @commonDeleteWarning.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复'**
  String get commonDeleteWarning;

  /// No description provided for @commonEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有'**
  String get commonEmpty;

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
  /// **'号码格式不对（支持大陆/港澳台/国际）'**
  String get snackbarPhoneInvalid;

  /// No description provided for @commonConfirmOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirmOk;

  /// No description provided for @commonTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get commonTakePhoto;

  /// No description provided for @commonMedName.
  ///
  /// In zh, this message translates to:
  /// **'药名'**
  String get commonMedName;

  /// No description provided for @commonDoseUnit.
  ///
  /// In zh, this message translates to:
  /// **'片'**
  String get commonDoseUnit;

  /// No description provided for @commonSetup.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get commonSetup;

  /// No description provided for @commonAutoCheckinFailed.
  ///
  /// In zh, this message translates to:
  /// **'自动打卡失败：{error}'**
  String commonAutoCheckinFailed(String error);

  /// No description provided for @commonCheckinFailed.
  ///
  /// In zh, this message translates to:
  /// **'打卡失败：{error}'**
  String commonCheckinFailed(String error);

  /// No description provided for @commonVentDeleteWarning.
  ///
  /// In zh, this message translates to:
  /// **'删了就没了。文字和录音都会一起删。'**
  String get commonVentDeleteWarning;

  /// No description provided for @medsListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没添加常吃药'**
  String get medsListEmpty;

  /// No description provided for @medsCalendarTitle.
  ///
  /// In zh, this message translates to:
  /// **'用药日历'**
  String get medsCalendarTitle;

  /// No description provided for @medsCalendarSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'医生视角依从性热力图 · 7/30/90 天'**
  String get medsCalendarSubtitle;

  /// No description provided for @medsListNoActive.
  ///
  /// In zh, this message translates to:
  /// **'没有在用的药'**
  String get medsListNoActive;

  /// No description provided for @medsListStoppedSection.
  ///
  /// In zh, this message translates to:
  /// **'已停药'**
  String get medsListStoppedSection;

  /// No description provided for @medsSnackUpdated.
  ///
  /// In zh, this message translates to:
  /// **'已更新'**
  String get medsSnackUpdated;

  /// No description provided for @medsSnackUpdatedSoftStop.
  ///
  /// In zh, this message translates to:
  /// **'已更新 · 软停'**
  String get medsSnackUpdatedSoftStop;

  /// No description provided for @medsRefillPickDate.
  ///
  /// In zh, this message translates to:
  /// **'选择续方日期'**
  String get medsRefillPickDate;

  /// No description provided for @medsRefillSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置：{date} 续方，提前 {days} 天提醒'**
  String medsRefillSet(String date, int days);

  /// No description provided for @medsActionRefill.
  ///
  /// In zh, this message translates to:
  /// **'设置续方'**
  String get medsActionRefill;

  /// No description provided for @medsRefillOverdue.
  ///
  /// In zh, this message translates to:
  /// **'已过期 {days} 天 · 提前 {reminderDays} 天提醒'**
  String medsRefillOverdue(int days, int reminderDays);

  /// No description provided for @medsRefillUpcoming.
  ///
  /// In zh, this message translates to:
  /// **'续方：{date}（{days} 天后）· 提前 {reminderDays} 天提醒'**
  String medsRefillUpcoming(String date, int days, int reminderDays);

  /// No description provided for @medsRefillDaysTitle.
  ///
  /// In zh, this message translates to:
  /// **'提前几天提醒？'**
  String get medsRefillDaysTitle;

  /// No description provided for @medsRefillDaysUnit.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天'**
  String medsRefillDaysUnit(int days);

  /// No description provided for @medsRefillHint3.
  ///
  /// In zh, this message translates to:
  /// **'最后冲刺期'**
  String get medsRefillHint3;

  /// No description provided for @medsRefillHint5.
  ///
  /// In zh, this message translates to:
  /// **'比较紧'**
  String get medsRefillHint5;

  /// No description provided for @medsRefillHint7.
  ///
  /// In zh, this message translates to:
  /// **'推荐（默认）'**
  String get medsRefillHint7;

  /// No description provided for @medsRefillHint14.
  ///
  /// In zh, this message translates to:
  /// **'两周时间挂号'**
  String get medsRefillHint14;

  /// No description provided for @medsRefillHint30.
  ///
  /// In zh, this message translates to:
  /// **'一个月周期'**
  String get medsRefillHint30;

  /// No description provided for @notificationStatusCardTestTitle.
  ///
  /// In zh, this message translates to:
  /// **'🔔 通知自检'**
  String get notificationStatusCardTestTitle;

  /// No description provided for @notificationStatusCardTestBody.
  ///
  /// In zh, this message translates to:
  /// **'看到这条 = 通知工作正常。如果没看到，看下面的国产手机设置'**
  String get notificationStatusCardTestBody;

  /// No description provided for @notificationStatusCardTestSent.
  ///
  /// In zh, this message translates to:
  /// **'已发送测试通知 — 几秒内应该能收到'**
  String get notificationStatusCardTestSent;

  /// No description provided for @notificationStatusCardActionSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get notificationStatusCardActionSend;

  /// No description provided for @notificationStatusCardQueuedTitle.
  ///
  /// In zh, this message translates to:
  /// **'已排队的通知'**
  String get notificationStatusCardQueuedTitle;

  /// No description provided for @notificationStatusCardEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前没有任何待发通知。\n可能是没设提醒，或被系统后台清理了。'**
  String get notificationStatusCardEmpty;

  /// No description provided for @notificationStatusCardNoTitle.
  ///
  /// In zh, this message translates to:
  /// **'(无标题)'**
  String get notificationStatusCardNoTitle;

  /// No description provided for @notificationStatusCardWebTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知功能仅在 Android / iOS 上可用'**
  String get notificationStatusCardWebTitle;

  /// No description provided for @notificationStatusCardWebSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'当前是 web 端，通知由浏览器控制。请在手机上打开 App 测试。'**
  String get notificationStatusCardWebSubtitle;

  /// No description provided for @notificationStatusCardStatusLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get notificationStatusCardStatusLoading;

  /// No description provided for @notificationStatusCardStatusUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不支持查询'**
  String get notificationStatusCardStatusUnsupported;

  /// No description provided for @notificationStatusCardStatusNone.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 没有待发通知 — 提醒可能没设上'**
  String get notificationStatusCardStatusNone;

  /// No description provided for @notificationStatusCardStatusCount.
  ///
  /// In zh, this message translates to:
  /// **'✓ 已排队 {count} 条待发通知'**
  String notificationStatusCardStatusCount(int count);

  /// No description provided for @notificationStatusCardTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知与提醒'**
  String get notificationStatusCardTitle;

  /// No description provided for @notificationStatusCardTestButtonTitle.
  ///
  /// In zh, this message translates to:
  /// **'测试通知'**
  String get notificationStatusCardTestButtonTitle;

  /// No description provided for @notificationStatusCardTestButtonSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点一下立即推一条，确认通知能正常弹出'**
  String get notificationStatusCardTestButtonSubtitle;

  /// No description provided for @notificationStatusCardViewButtonTitle.
  ///
  /// In zh, this message translates to:
  /// **'查看已排队通知'**
  String get notificationStatusCardViewButtonTitle;

  /// No description provided for @notificationStatusCardViewButtonSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'展示当前所有待发的提醒'**
  String get notificationStatusCardViewButtonSubtitle;

  /// No description provided for @notificationStatusCardOemTitle.
  ///
  /// In zh, this message translates to:
  /// **'国产手机没收到通知?'**
  String get notificationStatusCardOemTitle;

  /// No description provided for @notificationStatusCardOemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'小米/华为/OPPO/Vivo 默认会杀后台，点这里看怎么设'**
  String get notificationStatusCardOemSubtitle;

  /// No description provided for @notificationStatusCardOemBrandXiaomi.
  ///
  /// In zh, this message translates to:
  /// **'小米 / Redmi'**
  String get notificationStatusCardOemBrandXiaomi;

  /// No description provided for @notificationStatusCardOemStepXiaomi1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用 → 慢病管家 → 自启动 → 开启'**
  String get notificationStatusCardOemStepXiaomi1;

  /// No description provided for @notificationStatusCardOemStepXiaomi2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用 → 慢病管家 → 省电策略 → 无限制'**
  String get notificationStatusCardOemStepXiaomi2;

  /// No description provided for @notificationStatusCardOemStepXiaomi3.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 通知 → 慢病管家 → 允许通知 + 锁屏通知'**
  String get notificationStatusCardOemStepXiaomi3;

  /// No description provided for @notificationStatusCardOemBrandHuawei.
  ///
  /// In zh, this message translates to:
  /// **'华为 / 荣耀'**
  String get notificationStatusCardOemBrandHuawei;

  /// No description provided for @notificationStatusCardOemStepHuawei1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用 → 慢病管家 → 电池 → 启动管理 → 允许自启动'**
  String get notificationStatusCardOemStepHuawei1;

  /// No description provided for @notificationStatusCardOemStepHuawei2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用 → 慢病管家 → 通知 → 全部开启'**
  String get notificationStatusCardOemStepHuawei2;

  /// No description provided for @notificationStatusCardOemStepHuawei3.
  ///
  /// In zh, this message translates to:
  /// **'手机管家 → 应用启动管理 → 关闭「自动管理」'**
  String get notificationStatusCardOemStepHuawei3;

  /// No description provided for @notificationStatusCardOemBrandOppo.
  ///
  /// In zh, this message translates to:
  /// **'OPPO / realme / 一加'**
  String get notificationStatusCardOemBrandOppo;

  /// No description provided for @notificationStatusCardOemStepOppo1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 电池 → 耗电保护 → 慢病管家 → 允许后台运行'**
  String get notificationStatusCardOemStepOppo1;

  /// No description provided for @notificationStatusCardOemStepOppo2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 通知 → 慢病管家 → 全部开启'**
  String get notificationStatusCardOemStepOppo2;

  /// No description provided for @notificationStatusCardOemStepOppo3.
  ///
  /// In zh, this message translates to:
  /// **'「最近任务」界面上锁 App（下滑小锁图标）'**
  String get notificationStatusCardOemStepOppo3;

  /// No description provided for @notificationStatusCardOemBrandVivo.
  ///
  /// In zh, this message translates to:
  /// **'Vivo / iQOO'**
  String get notificationStatusCardOemBrandVivo;

  /// No description provided for @notificationStatusCardOemStepVivo1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 电池 → 后台高耗电 → 慢病管家 → 允许'**
  String get notificationStatusCardOemStepVivo1;

  /// No description provided for @notificationStatusCardOemStepVivo2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 通知 → 慢病管家 → 全部开启'**
  String get notificationStatusCardOemStepVivo2;

  /// No description provided for @notificationStatusCardOemStepVivo3.
  ///
  /// In zh, this message translates to:
  /// **'「最近任务」界面上锁 App'**
  String get notificationStatusCardOemStepVivo3;

  /// No description provided for @notificationStatusCardOemBrandMeizu.
  ///
  /// In zh, this message translates to:
  /// **'魅族'**
  String get notificationStatusCardOemBrandMeizu;

  /// No description provided for @notificationStatusCardOemStepMeizu1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用管理 → 慢病管家 → 权限管理 → 自启动 → 允许'**
  String get notificationStatusCardOemStepMeizu1;

  /// No description provided for @notificationStatusCardOemStepMeizu2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 通知管理 → 慢病管家 → 全部开启'**
  String get notificationStatusCardOemStepMeizu2;

  /// No description provided for @notificationStatusCardOemGeneralTip.
  ///
  /// In zh, this message translates to:
  /// **'通用建议：精确闹钟被某些 ROM 静默拒绝时,首次启动 App 时系统会弹「是否允许」,请选「允许」。'**
  String get notificationStatusCardOemGeneralTip;

  /// No description provided for @reminderHubDescription.
  ///
  /// In zh, this message translates to:
  /// **'集中管理所有提醒：每天打卡、用药时间、续方日期、心理评估、失联通知。'**
  String get reminderHubDescription;

  /// No description provided for @reminderHubDailyTitle.
  ///
  /// In zh, this message translates to:
  /// **'每日打卡提醒'**
  String get reminderHubDailyTitle;

  /// No description provided for @reminderHubDailyDesc.
  ///
  /// In zh, this message translates to:
  /// **'每天 20:00 推送「记得打卡」，漏 1 次没关系'**
  String get reminderHubDailyDesc;

  /// No description provided for @reminderHubDailyStatus.
  ///
  /// In zh, this message translates to:
  /// **'已启用 · 每天 20:00'**
  String get reminderHubDailyStatus;

  /// No description provided for @reminderHubDailyAction.
  ///
  /// In zh, this message translates to:
  /// **'查看通知预览'**
  String get reminderHubDailyAction;

  /// No description provided for @reminderHubMedicationTitle.
  ///
  /// In zh, this message translates to:
  /// **'用药提醒'**
  String get reminderHubMedicationTitle;

  /// No description provided for @reminderHubStatusError.
  ///
  /// In zh, this message translates to:
  /// **'出错'**
  String get reminderHubStatusError;

  /// No description provided for @reminderHubRefillTitle.
  ///
  /// In zh, this message translates to:
  /// **'续方提醒'**
  String get reminderHubRefillTitle;

  /// No description provided for @reminderHubAssessmentTitle.
  ///
  /// In zh, this message translates to:
  /// **'周期评估提醒'**
  String get reminderHubAssessmentTitle;

  /// No description provided for @reminderHubAssessmentDescEnabled.
  ///
  /// In zh, this message translates to:
  /// **'每 {days} 天提醒做心理评估（PHQ-9 / GAD-7）'**
  String reminderHubAssessmentDescEnabled(int days);

  /// No description provided for @reminderHubAssessmentDescDisabled.
  ///
  /// In zh, this message translates to:
  /// **'关闭 · 不会推送评估提醒'**
  String get reminderHubAssessmentDescDisabled;

  /// No description provided for @reminderHubAssessmentStatusEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用 · 每 {days} 天'**
  String reminderHubAssessmentStatusEnabled(int days);

  /// No description provided for @reminderHubStatusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'未启用'**
  String get reminderHubStatusDisabled;

  /// No description provided for @reminderHubConfigure.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get reminderHubConfigure;

  /// No description provided for @reminderHubSafetyTitle.
  ///
  /// In zh, this message translates to:
  /// **'失联通知（安全开关）'**
  String get reminderHubSafetyTitle;

  /// No description provided for @reminderHubSmsMockWarning.
  ///
  /// In zh, this message translates to:
  /// **'SMS 通道未接通（当前使用 Mock）。失联触发时只会推本地通知，不会真发短信给紧急联系人。上 store 前必须接入真实 SMS provider。'**
  String get reminderHubSmsMockWarning;

  /// No description provided for @reminderHubSafetyDescEnabled.
  ///
  /// In zh, this message translates to:
  /// **'连续 {threshold} 天没打卡 → 自动 SMS 通知紧急联系人 + 本地推送'**
  String reminderHubSafetyDescEnabled(int threshold);

  /// No description provided for @reminderHubSafetyDescDisabled.
  ///
  /// In zh, this message translates to:
  /// **'关闭 · 不会自动通知紧急联系人'**
  String get reminderHubSafetyDescDisabled;

  /// No description provided for @reminderHubSafetyStatusEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用 · 阈值 {threshold} 天'**
  String reminderHubSafetyStatusEnabled(int threshold);

  /// No description provided for @reminderHubMedicationDescActive.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 种在用药物，{times} 个时间点会推送提醒'**
  String reminderHubMedicationDescActive(int count, int times);

  /// No description provided for @reminderHubMedicationDescInactive.
  ///
  /// In zh, this message translates to:
  /// **'还没有在用药物 · 添加后会自动启用'**
  String get reminderHubMedicationDescInactive;

  /// No description provided for @reminderHubMedicationStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'已启用 · {count} 种 / {times} 时间点'**
  String reminderHubMedicationStatusActive(int count, int times);

  /// No description provided for @reminderHubStatusNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get reminderHubStatusNotConfigured;

  /// No description provided for @reminderHubManageMedication.
  ///
  /// In zh, this message translates to:
  /// **'管理用药'**
  String get reminderHubManageMedication;

  /// No description provided for @reminderHubRefillDescNone.
  ///
  /// In zh, this message translates to:
  /// **'未给任何药物设置续方日期 · 在「用药设置」中可加'**
  String get reminderHubRefillDescNone;

  /// No description provided for @reminderHubRefillDescOverdue.
  ///
  /// In zh, this message translates to:
  /// **'{overdue} 种已过期续方 · {inWindow} 种在提醒窗口内'**
  String reminderHubRefillDescOverdue(int overdue, int inWindow);

  /// No description provided for @reminderHubRefillDescActive.
  ///
  /// In zh, this message translates to:
  /// **'{count} 种药物已设续方 · 临近时会推送提醒'**
  String reminderHubRefillDescActive(int count);

  /// No description provided for @reminderHubRefillStatusOverdue.
  ///
  /// In zh, this message translates to:
  /// **'已过期 {count}'**
  String reminderHubRefillStatusOverdue(int count);

  /// No description provided for @reminderHubRefillStatusInWindow.
  ///
  /// In zh, this message translates to:
  /// **'提醒中 {count}'**
  String reminderHubRefillStatusInWindow(int count);

  /// No description provided for @reminderHubRefillStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'已启用 · {count} 种'**
  String reminderHubRefillStatusActive(int count);

  /// No description provided for @reminderHubManageRefill.
  ///
  /// In zh, this message translates to:
  /// **'管理续方'**
  String get reminderHubManageRefill;

  /// No description provided for @reminderHubEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get reminderHubEnable;

  /// No description provided for @reminderHubAssessmentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每隔 N 天推送一次心理评估'**
  String get reminderHubAssessmentSubtitle;

  /// No description provided for @reminderHubInterval.
  ///
  /// In zh, this message translates to:
  /// **'提醒间隔'**
  String get reminderHubInterval;

  /// No description provided for @reminderHubEveryNDays.
  ///
  /// In zh, this message translates to:
  /// **'每 {days} 天'**
  String reminderHubEveryNDays(int days);

  /// No description provided for @reminderHubSafetyDescription.
  ///
  /// In zh, this message translates to:
  /// **'连续 N 天没打卡 → 自动 SMS 通知所有启用的紧急联系人 + 本地推送'**
  String get reminderHubSafetyDescription;

  /// No description provided for @reminderHubTriggerThreshold.
  ///
  /// In zh, this message translates to:
  /// **'触发阈值（连续 N 天没打卡）'**
  String get reminderHubTriggerThreshold;

  /// No description provided for @reminderHubNDays.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天'**
  String reminderHubNDays(int days);
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
