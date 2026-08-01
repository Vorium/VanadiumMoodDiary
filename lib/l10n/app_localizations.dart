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
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'慢病管家'**
  String get appName;

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
  /// **'🌱 您还在线'**
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
  /// **'第 {current} 步 ／ 共 {total} 步'**
  String setupStep(int current, int total);

  /// No description provided for @setupHello.
  ///
  /// In zh, this message translates to:
  /// **'您好，我是慢病管家'**
  String get setupHello;

  /// No description provided for @setupIntro.
  ///
  /// In zh, this message translates to:
  /// **'1 分钟设置好，然后每天 1 次打卡'**
  String get setupIntro;

  /// No description provided for @setupName.
  ///
  /// In zh, this message translates to:
  /// **'您的名字（选填）'**
  String get setupName;

  /// No description provided for @setupNameHint.
  ///
  /// In zh, this message translates to:
  /// **'小明'**
  String get setupNameHint;

  /// No description provided for @setupContacts.
  ///
  /// In zh, this message translates to:
  /// **'紧急联系人（可选）'**
  String get setupContacts;

  /// No description provided for @setupAddContact.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加另一个联系人'**
  String get setupAddContact;

  /// No description provided for @setupContactConsent.
  ///
  /// In zh, this message translates to:
  /// **'如添加联系人，请先告知对方可能收到的通知（法律要求）'**
  String get setupContactConsent;

  /// No description provided for @setupNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步 →'**
  String get setupNext;

  /// No description provided for @setupMedNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入药盒上的名称（选填）'**
  String get setupMedNameHint;

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
  /// **'明天开始您的第 1 天'**
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
  /// **'✓ 您点 1 下 = 打卡'**
  String get setupReminder2;

  /// No description provided for @setupReminder3.
  ///
  /// In zh, this message translates to:
  /// **'✓ 漏 2 天我会联系紧急人'**
  String get setupReminder3;

  /// No description provided for @setupPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'您的数据：'**
  String get setupPrivacy;

  /// No description provided for @setupPrivacy1.
  ///
  /// In zh, this message translates to:
  /// **'• 本地加密'**
  String get setupPrivacy1;

  /// No description provided for @setupPrivacy2.
  ///
  /// In zh, this message translates to:
  /// **'• 不会上传到任何云端服务器'**
  String get setupPrivacy2;

  /// No description provided for @setupPrivacy3.
  ///
  /// In zh, this message translates to:
  /// **'• 您可以随时导出'**
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

  /// No description provided for @settingsMedReport.
  ///
  /// In zh, this message translates to:
  /// **'用药报告'**
  String get settingsMedReport;

  /// No description provided for @settingsMedReportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选时间窗口（7／14／30 天），给医生看'**
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
  /// **'查看所有 PHQ-9 ／ GAD-7 评估的折线图与对比'**
  String get settingsAssessmentHistorySubtitle;

  /// No description provided for @settingsAboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'v0.23.0 · 我今天吃了药'**
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
  /// **'说明：树洞（私密倾诉）的文字会导出，但录音文件不导出——录音存在 App 本地，重装后路径失效，无法跨设备复用。'**
  String get settingsExportVentWarning;

  /// No description provided for @settingsExportVentConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出含敏感内容'**
  String get settingsExportVentConfirmTitle;

  /// No description provided for @settingsExportVentConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'即将导出树洞的文字内容。精神心理患者的倾诉可能涉及个人隐私或敏感话题，导出的 JSON 是明文，存放在剪贴板或文件里都可能被他人看到。\n\n请确认:\n• 您将把它存到安全的地方（如加密磁盘）\n• 不会分享给未授权的人\n• 树洞录音文件不包含在导出中'**
  String get settingsExportVentConfirmBody;

  /// No description provided for @settingsExportVentConfirmConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我了解，继续导出'**
  String get settingsExportVentConfirmConfirm;

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

  /// No description provided for @settingsClearAllData.
  ///
  /// In zh, this message translates to:
  /// **'清空所有数据'**
  String get settingsClearAllData;

  /// No description provided for @settingsClearAllDataSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'删除全部打卡 ／ 用药 ／ 评估 ／ 树洞 ／ 联系人（无法恢复）'**
  String get settingsClearAllDataSubtitle;

  /// No description provided for @settingsClearAllDataDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认清空所有数据？'**
  String get settingsClearAllDataDialogTitle;

  /// No description provided for @settingsClearAllDataDialogBody.
  ///
  /// In zh, this message translates to:
  /// **'以下数据将被永久删除，无法恢复：\n• 打卡记录\n• 用药与服药历史\n• 心理评估结果\n• 情绪日记\n• 树洞（文字+录音）\n• 紧急联系人\n\n清空后 App 会跳回首次设置流程。建议先导出 JSON 备份。'**
  String get settingsClearAllDataDialogBody;

  /// No description provided for @settingsClearAllDataConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我已备份，确认清空'**
  String get settingsClearAllDataConfirm;

  /// No description provided for @settingsClearAllDataSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已清空所有数据'**
  String get settingsClearAllDataSuccess;

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

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中……'**
  String get commonLoading;

  /// No description provided for @lastStartupErrorBannerBody.
  ///
  /// In zh, this message translates to:
  /// **'上次启动出错，请截图反馈'**
  String get lastStartupErrorBannerBody;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get commonRefresh;

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

  /// No description provided for @commonOptionNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选'**
  String get commonOptionNotSelected;

  /// No description provided for @legalConsentWithdrawn.
  ///
  /// In zh, this message translates to:
  /// **'已撤回 ({current}/{total})'**
  String legalConsentWithdrawn(int current, int total);

  /// No description provided for @legalConsentReAgreed.
  ///
  /// In zh, this message translates to:
  /// **'已重新同意 ({current}/{total})'**
  String legalConsentReAgreed(int current, int total);

  /// No description provided for @commonLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败：{error}'**
  String commonLoadFailed(String error);

  /// Generic error snackbar: '<action> failed: <error>'. Action is the user-facing action （保存/删除/导出/...)
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
  /// **'号码格式不对（支持大陆／港澳台／国际）'**
  String get snackbarPhoneInvalid;

  /// No description provided for @commonConfirmOk.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get commonConfirmOk;

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
  /// **'医生视角依从性热力图 · 7／30／90 天'**
  String get medsCalendarSubtitle;

  /// No description provided for @medsListNoActive.
  ///
  /// In zh, this message translates to:
  /// **'没有在用的药'**
  String get medsListNoActive;

  /// No description provided for @medsListNoActiveHint.
  ///
  /// In zh, this message translates to:
  /// **'所有药物都已停用，去添加新药物开始新一阶段。'**
  String get medsListNoActiveHint;

  /// No description provided for @medsListAddAction.
  ///
  /// In zh, this message translates to:
  /// **'添加药物'**
  String get medsListAddAction;

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
  /// **'（无标题）'**
  String get notificationStatusCardNoTitle;

  /// No description provided for @notificationStatusCardWebTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知功能仅在 Android ／ iOS 上可用'**
  String get notificationStatusCardWebTitle;

  /// No description provided for @notificationStatusCardWebSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'当前是 web 端，通知由浏览器控制。请在手机上打开 App 测试。'**
  String get notificationStatusCardWebSubtitle;

  /// No description provided for @notificationStatusCardStatusLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中……'**
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
  /// **'国产手机没收到通知？'**
  String get notificationStatusCardOemTitle;

  /// No description provided for @notificationStatusCardOemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'小米／华为／OPPO／Vivo／三星 默认会杀后台，点这里看怎么设'**
  String get notificationStatusCardOemSubtitle;

  /// No description provided for @notificationStatusCardOemBrandXiaomi.
  ///
  /// In zh, this message translates to:
  /// **'小米 ／ Redmi'**
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
  /// **'华为 ／ 荣耀'**
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
  /// **'OPPO ／ realme ／ 一加'**
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
  /// **'Vivo ／ iQOO'**
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

  /// No description provided for @notificationStatusCardOemBrandSamsung.
  ///
  /// In zh, this message translates to:
  /// **'三星 (OneUI)'**
  String get notificationStatusCardOemBrandSamsung;

  /// No description provided for @notificationStatusCardOemStepSamsung1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用程序 → 慢病管家 → 通知 → 全部开启'**
  String get notificationStatusCardOemStepSamsung1;

  /// No description provided for @notificationStatusCardOemStepSamsung2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 电池 → 后台使用限制 → 慢病管家 → 改为「不受限」'**
  String get notificationStatusCardOemStepSamsung2;

  /// No description provided for @notificationStatusCardOemBrandOthers.
  ///
  /// In zh, this message translates to:
  /// **'其他（中兴／努比亚／红魔／联想／三星 Knox）'**
  String get notificationStatusCardOemBrandOthers;

  /// No description provided for @notificationStatusCardOemStepOthers1.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 应用 → 慢病管家 → 通知 → 全部开启'**
  String get notificationStatusCardOemStepOthers1;

  /// No description provided for @notificationStatusCardOemStepOthers2.
  ///
  /// In zh, this message translates to:
  /// **'设置 → 电池 → 后台运行 → 改为「允许」'**
  String get notificationStatusCardOemStepOthers2;

  /// No description provided for @notificationStatusCardOemGeneralTip.
  ///
  /// In zh, this message translates to:
  /// **'通用建议：精确闹钟被某些 ROM 静默拒绝时，首次启动 App 时系统会弹「是否允许」，请选「允许」。'**
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
  /// **'每 {days} 天提醒做心理评估（PHQ-9 ／ GAD-7）'**
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
  /// **'已启用 · {count} 种 ／ {times} 时间点'**
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

  /// No description provided for @setupContactNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'联系人 {index} 姓名'**
  String setupContactNameLabel(int index);

  /// No description provided for @setupContactNameHint.
  ///
  /// In zh, this message translates to:
  /// **'称呼（选填）'**
  String get setupContactNameHint;

  /// No description provided for @setupContactPhoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'紧急联系人手机号 {index}'**
  String setupContactPhoneLabel(int index);

  /// No description provided for @setupContactPhoneHint.
  ///
  /// In zh, this message translates to:
  /// **'13800138000'**
  String get setupContactPhoneHint;

  /// No description provided for @ventListTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的树洞'**
  String get ventListTitle;

  /// No description provided for @ventListWriteTooltip.
  ///
  /// In zh, this message translates to:
  /// **'写一条'**
  String get ventListWriteTooltip;

  /// No description provided for @ventEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'树洞还是空的'**
  String get ventEmptyTitle;

  /// No description provided for @ventEmptySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'想说什么就说出来。文字、语音都可以。\n这些话只有您自己能看到。'**
  String get ventEmptySubtitle;

  /// No description provided for @ventEmptyAction.
  ///
  /// In zh, this message translates to:
  /// **'写第一句'**
  String get ventEmptyAction;

  /// No description provided for @ventVoiceLabel.
  ///
  /// In zh, this message translates to:
  /// **'🎙️ 语音'**
  String get ventVoiceLabel;

  /// No description provided for @ventDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'树洞'**
  String get ventDetailTitle;

  /// No description provided for @ventDetailNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到了'**
  String get ventDetailNotFound;

  /// No description provided for @ventDetailPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'🔒 私密 · 只有您能看到'**
  String get ventDetailPrivacy;

  /// No description provided for @ventToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get ventToday;

  /// No description provided for @ventYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get ventYesterday;

  /// No description provided for @ventComposeTitle.
  ///
  /// In zh, this message translates to:
  /// **'放进树洞'**
  String get ventComposeTitle;

  /// No description provided for @ventComposeHint.
  ///
  /// In zh, this message translates to:
  /// **'今天过得怎么样……'**
  String get ventComposeHint;

  /// No description provided for @ventRecordIdle.
  ///
  /// In zh, this message translates to:
  /// **'按一下开始录音'**
  String get ventRecordIdle;

  /// No description provided for @ventRecordActive.
  ///
  /// In zh, this message translates to:
  /// **'正在录音……点停止'**
  String get ventRecordActive;

  /// No description provided for @ventAudioLabel.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get ventAudioLabel;

  /// No description provided for @ventAudioPlayTooltip.
  ///
  /// In zh, this message translates to:
  /// **'播放录音'**
  String get ventAudioPlayTooltip;

  /// No description provided for @ventAudioPauseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'暂停录音'**
  String get ventAudioPauseTooltip;

  /// No description provided for @ventRerecord.
  ///
  /// In zh, this message translates to:
  /// **'重录'**
  String get ventRerecord;

  /// No description provided for @moodDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'今天怎么样？'**
  String get moodDialogTitle;

  /// No description provided for @moodDimensionMood.
  ///
  /// In zh, this message translates to:
  /// **'情绪'**
  String get moodDimensionMood;

  /// No description provided for @moodDimensionMoodHint.
  ///
  /// In zh, this message translates to:
  /// **'1=很差 5=很好'**
  String get moodDimensionMoodHint;

  /// No description provided for @moodDimensionEnergy.
  ///
  /// In zh, this message translates to:
  /// **'精力'**
  String get moodDimensionEnergy;

  /// No description provided for @moodDimensionEnergyHint.
  ///
  /// In zh, this message translates to:
  /// **'1=很低 5=充沛'**
  String get moodDimensionEnergyHint;

  /// No description provided for @moodDimensionSleep.
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get moodDimensionSleep;

  /// No description provided for @moodDimensionSleepHint.
  ///
  /// In zh, this message translates to:
  /// **'1=很差 5=很好'**
  String get moodDimensionSleepHint;

  /// No description provided for @moodDimensionAnxiety.
  ///
  /// In zh, this message translates to:
  /// **'焦虑'**
  String get moodDimensionAnxiety;

  /// No description provided for @moodDimensionAnxietyHint.
  ///
  /// In zh, this message translates to:
  /// **'1=严重 5=平静'**
  String get moodDimensionAnxietyHint;

  /// No description provided for @moodTagAnxiety.
  ///
  /// In zh, this message translates to:
  /// **'焦虑'**
  String get moodTagAnxiety;

  /// No description provided for @moodTagDepression.
  ///
  /// In zh, this message translates to:
  /// **'抑郁'**
  String get moodTagDepression;

  /// No description provided for @moodTagCalm.
  ///
  /// In zh, this message translates to:
  /// **'平静'**
  String get moodTagCalm;

  /// No description provided for @moodTagInsomnia.
  ///
  /// In zh, this message translates to:
  /// **'失眠'**
  String get moodTagInsomnia;

  /// No description provided for @moodTagIrritable.
  ///
  /// In zh, this message translates to:
  /// **'烦躁'**
  String get moodTagIrritable;

  /// No description provided for @moodTagLowEnergy.
  ///
  /// In zh, this message translates to:
  /// **'能量低'**
  String get moodTagLowEnergy;

  /// No description provided for @moodNoteLabel.
  ///
  /// In zh, this message translates to:
  /// **'备注（可选）'**
  String get moodNoteLabel;

  /// No description provided for @moodNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'今天发生什么？'**
  String get moodNoteHint;

  /// No description provided for @moodAudioRecordButton.
  ///
  /// In zh, this message translates to:
  /// **'录语音'**
  String get moodAudioRecordButton;

  /// No description provided for @moodAudioRecorded.
  ///
  /// In zh, this message translates to:
  /// **'已录 {duration}'**
  String moodAudioRecorded(String duration);

  /// No description provided for @moodAudioRerecord.
  ///
  /// In zh, this message translates to:
  /// **'重录'**
  String get moodAudioRerecord;

  /// No description provided for @moodAudioTranscriptLabel.
  ///
  /// In zh, this message translates to:
  /// **'识别文字'**
  String get moodAudioTranscriptLabel;

  /// No description provided for @moodAudioTranscriptPartialHint.
  ///
  /// In zh, this message translates to:
  /// **'（仅识别前 60 秒）'**
  String get moodAudioTranscriptPartialHint;

  /// No description provided for @moodAudioSttListening.
  ///
  /// In zh, this message translates to:
  /// **'识别中……'**
  String get moodAudioSttListening;

  /// No description provided for @moodAudioSttFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别失败，已仅保存录音'**
  String get moodAudioSttFailed;

  /// No description provided for @moodAudioSttUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'该设备暂不支持语音转文字'**
  String get moodAudioSttUnavailable;

  /// No description provided for @moodAudioMaxReached.
  ///
  /// In zh, this message translates to:
  /// **'已达 3 分钟上限'**
  String get moodAudioMaxReached;

  /// No description provided for @moodAudioSavedWithPlay.
  ///
  /// In zh, this message translates to:
  /// **'情绪已保存'**
  String get moodAudioSavedWithPlay;

  /// No description provided for @moodAudioPlayAction.
  ///
  /// In zh, this message translates to:
  /// **'回放'**
  String get moodAudioPlayAction;

  /// No description provided for @moodAudioErrorStart.
  ///
  /// In zh, this message translates to:
  /// **'开始录音失败'**
  String get moodAudioErrorStart;

  /// No description provided for @moodAudioErrorStop.
  ///
  /// In zh, this message translates to:
  /// **'停止录音失败'**
  String get moodAudioErrorStop;

  /// No description provided for @moodAudioErrorEncrypt.
  ///
  /// In zh, this message translates to:
  /// **'加密录音失败'**
  String get moodAudioErrorEncrypt;

  /// No description provided for @moodAudioErrorPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放失败'**
  String get moodAudioErrorPlay;

  /// No description provided for @medsTodaySchedule.
  ///
  /// In zh, this message translates to:
  /// **'今日服药计划'**
  String get medsTodaySchedule;

  /// No description provided for @medsTotal.
  ///
  /// In zh, this message translates to:
  /// **'总药数'**
  String get medsTotal;

  /// No description provided for @medsRefillSetCount.
  ///
  /// In zh, this message translates to:
  /// **'已设续方'**
  String get medsRefillSetCount;

  /// No description provided for @medsRefillReminding.
  ///
  /// In zh, this message translates to:
  /// **'提醒中'**
  String get medsRefillReminding;

  /// No description provided for @refillManageOverdue.
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get refillManageOverdue;

  /// No description provided for @medsNoMedicationsAdded.
  ///
  /// In zh, this message translates to:
  /// **'还没有添加药物'**
  String get medsNoMedicationsAdded;

  /// No description provided for @medsRefillEditHint.
  ///
  /// In zh, this message translates to:
  /// **'点击任一行可编辑续方日期。提醒窗口：续方前 N 天（N=reminderDays）。'**
  String get medsRefillEditHint;

  /// No description provided for @medsRefillStatusNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get medsRefillStatusNotConfigured;

  /// No description provided for @medsRefillStatusSet.
  ///
  /// In zh, this message translates to:
  /// **'已设'**
  String get medsRefillStatusSet;

  /// No description provided for @medsRefillStatusReminding.
  ///
  /// In zh, this message translates to:
  /// **'提醒中'**
  String get medsRefillStatusReminding;

  /// No description provided for @medsRefillStatusOverdue.
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get medsRefillStatusOverdue;

  /// No description provided for @medsRefillNotSetSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'未设续方日期 · 提醒窗口 {days} 天'**
  String medsRefillNotSetSubtitle(int days);

  /// No description provided for @medsRefillExpiredDays.
  ///
  /// In zh, this message translates to:
  /// **'已过 {days} 天'**
  String medsRefillExpiredDays(int days);

  /// No description provided for @medsRefillToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get medsRefillToday;

  /// No description provided for @medsRefillRemainingDays.
  ///
  /// In zh, this message translates to:
  /// **'还有 {days} 天'**
  String medsRefillRemainingDays(int days);

  /// No description provided for @medsRefillSubtitleTemplate.
  ///
  /// In zh, this message translates to:
  /// **'{date} {suffix} · 提前 {reminderDays} 天提醒'**
  String medsRefillSubtitleTemplate(
      String date, String suffix, int reminderDays);

  /// No description provided for @assessmentLoadingBack.
  ///
  /// In zh, this message translates to:
  /// **'正在返回上一页……'**
  String get assessmentLoadingBack;

  /// No description provided for @assessmentAnsweredProgress.
  ///
  /// In zh, this message translates to:
  /// **'已答 {answered} ／ {total}'**
  String assessmentAnsweredProgress(int answered, int total);

  /// No description provided for @assessmentSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交并查看结果'**
  String get assessmentSubmit;

  /// No description provided for @assessmentQuestionLabel.
  ///
  /// In zh, this message translates to:
  /// **'评估题 {index}：{text}，4 项单选，当前：{selected}'**
  String assessmentQuestionLabel(int index, String text, String selected);

  /// No description provided for @assessmentScoreTotal.
  ///
  /// In zh, this message translates to:
  /// **'总分（0-{max}）'**
  String assessmentScoreTotal(int max);

  /// No description provided for @assessmentRecommendUrgent.
  ///
  /// In zh, this message translates to:
  /// **'强烈建议您尽快联系医生或心理治疗师。'**
  String get assessmentRecommendUrgent;

  /// No description provided for @assessmentRecommend.
  ///
  /// In zh, this message translates to:
  /// **'建议您联系医生做进一步评估。'**
  String get assessmentRecommend;

  /// No description provided for @assessmentDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 本评估仅供参考，不能代替专业诊断。\n如感到困扰，请咨询医生。'**
  String get assessmentDisclaimer;

  /// No description provided for @assessmentBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get assessmentBack;

  /// No description provided for @assessmentRetake.
  ///
  /// In zh, this message translates to:
  /// **'再做一次'**
  String get assessmentRetake;

  /// No description provided for @homeHeaderDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'慢病管家'**
  String get homeHeaderDefaultTitle;

  /// No description provided for @homeHeaderKeepGoing.
  ///
  /// In zh, this message translates to:
  /// **'{name} 还在坚持'**
  String homeHeaderKeepGoing(String name);

  /// No description provided for @homeTooltipTrend.
  ///
  /// In zh, this message translates to:
  /// **'查看趋势'**
  String get homeTooltipTrend;

  /// No description provided for @homeTooltipAssessmentHistory.
  ///
  /// In zh, this message translates to:
  /// **'评估历史'**
  String get homeTooltipAssessmentHistory;

  /// No description provided for @homeStreakRestart.
  ///
  /// In zh, this message translates to:
  /// **'今天重新开始，加油 🌱'**
  String get homeStreakRestart;

  /// No description provided for @homeStreakDay1.
  ///
  /// In zh, this message translates to:
  /// **'第 1 天，迈出第一步 🌱'**
  String get homeStreakDay1;

  /// No description provided for @homeStreakDays.
  ///
  /// In zh, this message translates to:
  /// **'坚持 {days} 天，继续 🌿'**
  String homeStreakDays(int days);

  /// No description provided for @homeStreakGreat.
  ///
  /// In zh, this message translates to:
  /// **'已坚持 {days} 天，真棒 🌳'**
  String homeStreakGreat(int days);

  /// No description provided for @homeStreakAmazing.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天连击，太厉害了 🌲'**
  String homeStreakAmazing(int days);

  /// No description provided for @homeStreakMaster.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天--您已经是这个习惯的主人了 🏔️'**
  String homeStreakMaster(int days);

  /// No description provided for @navCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get navCheckIn;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @navAppName.
  ///
  /// In zh, this message translates to:
  /// **'慢病管家'**
  String get navAppName;

  /// No description provided for @errorPageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在：{path}'**
  String errorPageNotFound(String path);

  /// No description provided for @errorPageHint.
  ///
  /// In zh, this message translates to:
  /// **'这个地址可能已经失效，或者链接有误。'**
  String get errorPageHint;

  /// No description provided for @errorPageBackHome.
  ///
  /// In zh, this message translates to:
  /// **'返回首页'**
  String get errorPageBackHome;

  /// No description provided for @assessmentReminderEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启：每 {days} 天提醒做心理评估'**
  String assessmentReminderEnabled(int days);

  /// No description provided for @assessmentReminderChanged.
  ///
  /// In zh, this message translates to:
  /// **'已改为：每 {days} 天提醒'**
  String assessmentReminderChanged(int days);

  /// No description provided for @assessmentReminderSubtitleEnabled.
  ///
  /// In zh, this message translates to:
  /// **'每 {days} 天提醒我做一次心理评估'**
  String assessmentReminderSubtitleEnabled(int days);

  /// No description provided for @assessmentReminderHelpText.
  ///
  /// In zh, this message translates to:
  /// **'完成一次评估后，下次提醒会从今天重新算起。\n评估结果仅您自己看得到。'**
  String get assessmentReminderHelpText;

  /// No description provided for @assessmentReminderHintAcute.
  ///
  /// In zh, this message translates to:
  /// **'高强度监测（适合急性期）'**
  String get assessmentReminderHintAcute;

  /// No description provided for @assessmentReminderHintCommon.
  ///
  /// In zh, this message translates to:
  /// **'推荐（精神科常用）'**
  String get assessmentReminderHintCommon;

  /// No description provided for @assessmentReminderHintStable.
  ///
  /// In zh, this message translates to:
  /// **'稳定期 ／ 月度复盘'**
  String get assessmentReminderHintStable;

  /// No description provided for @assessmentReminderHintMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'维持治疗期'**
  String get assessmentReminderHintMaintenance;

  /// No description provided for @assessmentReminderHintLongTerm.
  ///
  /// In zh, this message translates to:
  /// **'长期随访'**
  String get assessmentReminderHintLongTerm;

  /// No description provided for @assessmentHistoryTrend.
  ///
  /// In zh, this message translates to:
  /// **'历史趋势'**
  String get assessmentHistoryTrend;

  /// No description provided for @assessmentAverageScore.
  ///
  /// In zh, this message translates to:
  /// **'平均 {score}'**
  String assessmentAverageScore(String score);

  /// No description provided for @assessmentTotalRecords.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 次'**
  String assessmentTotalRecords(int count);

  /// No description provided for @assessmentScoreRange.
  ///
  /// In zh, this message translates to:
  /// **'最低 {min} ／ 最高 {max}'**
  String assessmentScoreRange(int min, int max);

  /// No description provided for @assessmentComparePrevious.
  ///
  /// In zh, this message translates to:
  /// **'对比上次'**
  String get assessmentComparePrevious;

  /// No description provided for @assessmentFirstAssessmentHint.
  ///
  /// In zh, this message translates to:
  /// **'这是您的第一次评估。下次评估后会显示和这次的对比。'**
  String get assessmentFirstAssessmentHint;

  /// No description provided for @assessmentPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上次'**
  String get assessmentPrevious;

  /// No description provided for @assessmentCurrent.
  ///
  /// In zh, this message translates to:
  /// **'本次'**
  String get assessmentCurrent;

  /// No description provided for @assessmentDaysSincePrevious.
  ///
  /// In zh, this message translates to:
  /// **'距上次 {days} 天'**
  String assessmentDaysSincePrevious(int days);

  /// No description provided for @assessmentHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有评估记录'**
  String get assessmentHistoryEmpty;

  /// No description provided for @assessmentHistoryEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'完成一次心理评估后，记录会显示在这里'**
  String get assessmentHistoryEmptyHint;

  /// No description provided for @assessmentHistoryStartFirst.
  ///
  /// In zh, this message translates to:
  /// **'开始第一次评估'**
  String get assessmentHistoryStartFirst;

  /// No description provided for @assessmentHistoryTotalAssessments.
  ///
  /// In zh, this message translates to:
  /// **'总评估'**
  String get assessmentHistoryTotalAssessments;

  /// No description provided for @assessmentHistoryTimes.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get assessmentHistoryTimes;

  /// No description provided for @assessmentHistoryLatestPhq9.
  ///
  /// In zh, this message translates to:
  /// **'最近 PHQ-9'**
  String get assessmentHistoryLatestPhq9;

  /// No description provided for @assessmentHistoryLatestGad7.
  ///
  /// In zh, this message translates to:
  /// **'最近 GAD-7'**
  String get assessmentHistoryLatestGad7;

  /// No description provided for @assessmentHistoryNotDone.
  ///
  /// In zh, this message translates to:
  /// **'未做'**
  String get assessmentHistoryNotDone;

  /// No description provided for @assessmentChartNoData.
  ///
  /// In zh, this message translates to:
  /// **'还没有数据'**
  String get assessmentChartNoData;

  /// No description provided for @assessmentChartNeedMore.
  ///
  /// In zh, this message translates to:
  /// **'只有 1 次评估，无法画趋势 — 至少需要 2 次'**
  String get assessmentChartNeedMore;

  /// No description provided for @assessmentChartRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次评估'**
  String assessmentChartRecordCount(int count);

  /// No description provided for @assessmentChartTotalScore.
  ///
  /// In zh, this message translates to:
  /// **'总分 {score}/{max}'**
  String assessmentChartTotalScore(int score, int max);

  /// No description provided for @assessmentHistoryFullRecord.
  ///
  /// In zh, this message translates to:
  /// **'完整记录'**
  String get assessmentHistoryFullRecord;

  /// No description provided for @assessmentSeverityNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get assessmentSeverityNormal;

  /// No description provided for @assessmentSeverityMild.
  ///
  /// In zh, this message translates to:
  /// **'轻度'**
  String get assessmentSeverityMild;

  /// No description provided for @assessmentSeverityModerate.
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get assessmentSeverityModerate;

  /// No description provided for @assessmentSeverityModeratelySevere.
  ///
  /// In zh, this message translates to:
  /// **'中重度'**
  String get assessmentSeverityModeratelySevere;

  /// No description provided for @assessmentSeveritySevere.
  ///
  /// In zh, this message translates to:
  /// **'重度'**
  String get assessmentSeveritySevere;

  /// No description provided for @assessmentSeverityUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get assessmentSeverityUnknown;

  /// No description provided for @assessmentScalePhq9.
  ///
  /// In zh, this message translates to:
  /// **'PHQ-9 抑郁筛查'**
  String get assessmentScalePhq9;

  /// No description provided for @assessmentScaleGad7.
  ///
  /// In zh, this message translates to:
  /// **'GAD-7 焦虑筛查'**
  String get assessmentScaleGad7;

  /// No description provided for @setupConsentRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先完成法律文件阅读与同意'**
  String get setupConsentRequired;

  /// No description provided for @setupValidationNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的名字'**
  String get setupValidationNameRequired;

  /// No description provided for @setupValidationPhoneInvalid.
  ///
  /// In zh, this message translates to:
  /// **'手机号格式不对'**
  String get setupValidationPhoneInvalid;

  /// No description provided for @setupValidationPhoneDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'紧急联系人手机号不能重复'**
  String get setupValidationPhoneDuplicate;

  /// No description provided for @setupPresetTitle.
  ///
  /// In zh, this message translates to:
  /// **'📋 选择预置方案'**
  String get setupPresetTitle;

  /// No description provided for @setupPresetDescription.
  ///
  /// In zh, this message translates to:
  /// **'预置方案会填好药名 + 时间，您可以接着改。最终服药请按医嘱核对。'**
  String get setupPresetDescription;

  /// No description provided for @setupPresetLoaded.
  ///
  /// In zh, this message translates to:
  /// **'已载入：{name}（{count} 个药）请核对药名和剂量'**
  String setupPresetLoaded(String name, int count);

  /// No description provided for @setupMedWhatDoYouTake.
  ///
  /// In zh, this message translates to:
  /// **'您常吃什么药？'**
  String get setupMedWhatDoYouTake;

  /// No description provided for @setupMedMultiDrugHint.
  ///
  /// In zh, this message translates to:
  /// **'（可加多个药，每个药配自己的时间和剂量；跳过不影响打卡）'**
  String get setupMedMultiDrugHint;

  /// No description provided for @setupMedEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'还没添加药物。可以跳过——打卡不需要药物信息。'**
  String get setupMedEmptyHint;

  /// No description provided for @setupMedAddDrug.
  ///
  /// In zh, this message translates to:
  /// **'+ 添加药物'**
  String get setupMedAddDrug;

  /// No description provided for @setupMedLoadPreset.
  ///
  /// In zh, this message translates to:
  /// **'📋 载入预置方案（4 种常见模式）'**
  String get setupMedLoadPreset;

  /// No description provided for @setupBack.
  ///
  /// In zh, this message translates to:
  /// **'← 上一步'**
  String get setupBack;

  /// No description provided for @setupMedDrugNumber.
  ///
  /// In zh, this message translates to:
  /// **'药物 {number}'**
  String setupMedDrugNumber(int number);

  /// No description provided for @setupMedDeleteDrug.
  ///
  /// In zh, this message translates to:
  /// **'删除这个药'**
  String get setupMedDeleteDrug;

  /// No description provided for @setupMedDosage.
  ///
  /// In zh, this message translates to:
  /// **'剂量'**
  String get setupMedDosage;

  /// No description provided for @setupMedUnit.
  ///
  /// In zh, this message translates to:
  /// **'单位'**
  String get setupMedUnit;

  /// No description provided for @setupMedTimeHint.
  ///
  /// In zh, this message translates to:
  /// **'吃药时间（点 + 加）'**
  String get setupMedTimeHint;

  /// No description provided for @setupMedAddTime.
  ///
  /// In zh, this message translates to:
  /// **'加时间'**
  String get setupMedAddTime;

  /// No description provided for @setupMedTimeOptional.
  ///
  /// In zh, this message translates to:
  /// **'（不设置时间 = 不调度提醒，仅记录）'**
  String get setupMedTimeOptional;

  /// No description provided for @setupConsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'使用前请阅读'**
  String get setupConsentTitle;

  /// No description provided for @setupConsentDescription.
  ///
  /// In zh, this message translates to:
  /// **'为遵守《个人信息保护法》(PIPL)，本 App 处理您的健康医疗等敏感个人信息前，需要您明确、单独同意以下 3 份文件。'**
  String get setupConsentDescription;

  /// No description provided for @setupConsentUserAgreement.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意《用户协议》'**
  String get setupConsentUserAgreement;

  /// No description provided for @setupConsentPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意《隐私政策》'**
  String get setupConsentPrivacyPolicy;

  /// No description provided for @setupConsentSensitiveData.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意《敏感个人信息处理同意书》'**
  String get setupConsentSensitiveData;

  /// No description provided for @setupConsentStart.
  ///
  /// In zh, this message translates to:
  /// **'开始设置'**
  String get setupConsentStart;

  /// No description provided for @setupConsentWithdrawHint.
  ///
  /// In zh, this message translates to:
  /// **'提示：您可以随时在「设置 → 法律与隐私」撤回同意。拒绝或撤回后，App 的相关功能将无法使用。'**
  String get setupConsentWithdrawHint;

  /// No description provided for @setupWelcomeContactHint.
  ///
  /// In zh, this message translates to:
  /// **'（可选,后续可在设置中添加）'**
  String get setupWelcomeContactHint;

  /// No description provided for @setupLegalUserAgreement.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get setupLegalUserAgreement;

  /// No description provided for @setupLegalPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get setupLegalPrivacyPolicy;

  /// No description provided for @setupLegalSensitiveData.
  ///
  /// In zh, this message translates to:
  /// **'敏感个人信息处理同意书'**
  String get setupLegalSensitiveData;

  /// No description provided for @setupLegalLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，请检查网络或重新打开 App'**
  String get setupLegalLoadFailed;

  /// No description provided for @setupConsentView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get setupConsentView;

  /// No description provided for @settingsLegalAndPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'法律与隐私'**
  String get settingsLegalAndPrivacy;

  /// No description provided for @settingsLegalAndPrivacySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看协议、隐私政策、撤回同意'**
  String get settingsLegalAndPrivacySubtitle;

  /// No description provided for @legalPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'法律与隐私'**
  String get legalPageTitle;

  /// No description provided for @legalPageDocuments.
  ///
  /// In zh, this message translates to:
  /// **'法律文档'**
  String get legalPageDocuments;

  /// No description provided for @legalPageWithdrawTitle.
  ///
  /// In zh, this message translates to:
  /// **'撤回同意'**
  String get legalPageWithdrawTitle;

  /// No description provided for @legalPageWithdrawDescription.
  ///
  /// In zh, this message translates to:
  /// **'撤回某项同意后，相关功能立即停用（数据不删除，可重新打开）。'**
  String get legalPageWithdrawDescription;

  /// No description provided for @legalPageWithdrawSafety.
  ///
  /// In zh, this message translates to:
  /// **'撤回失联通知同意'**
  String get legalPageWithdrawSafety;

  /// No description provided for @legalPageWithdrawSafetySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'不再因漏打卡触发短信／邮件通知给紧急联系人'**
  String get legalPageWithdrawSafetySubtitle;

  /// No description provided for @legalPageWithdrawVent.
  ///
  /// In zh, this message translates to:
  /// **'撤回树洞（敏感倾诉）处理同意'**
  String get legalPageWithdrawVent;

  /// No description provided for @legalPageWithdrawVentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'停止存储新树洞文字／录音（已有数据保留，需手动删除）'**
  String get legalPageWithdrawVentSubtitle;

  /// No description provided for @legalPageWithdrawAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'撤回评估／情绪分析同意'**
  String get legalPageWithdrawAnalytics;

  /// No description provided for @legalPageWithdrawAnalyticsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'停止将评估／情绪记录纳入趋势分析（数据保留，不再入图表）'**
  String get legalPageWithdrawAnalyticsSubtitle;

  /// No description provided for @legalPageConsentRecorded.
  ///
  /// In zh, this message translates to:
  /// **'撤回时间：{time}'**
  String legalPageConsentRecorded(Object time);

  /// No description provided for @legalPageConsentNever.
  ///
  /// In zh, this message translates to:
  /// **'从未撤回'**
  String get legalPageConsentNever;

  /// No description provided for @emailPreviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知预览'**
  String get emailPreviewTitle;

  /// No description provided for @emailPreviewSetupRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先完成首次设置'**
  String get emailPreviewSetupRequired;

  /// No description provided for @emailPreviewDescription.
  ///
  /// In zh, this message translates to:
  /// **'这是您将收到的失联通知预览：'**
  String get emailPreviewDescription;

  /// No description provided for @emailPreviewNoContact.
  ///
  /// In zh, this message translates to:
  /// **'（无联系人）'**
  String get emailPreviewNoContact;

  /// No description provided for @emailPreviewDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'💡 这只是预览。实际短信通知在您漏 2 天没打卡后自动发送（v0.6 mock 阶段只打日志，v1.0+ 接真实 SMS provider）。'**
  String get emailPreviewDisclaimer;

  /// No description provided for @reportHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有报告历史\n生成一次报告后会自动记录'**
  String get reportHistoryEmpty;

  /// No description provided for @reportHistoryItemTitle.
  ///
  /// In zh, this message translates to:
  /// **'{date} · 近 {days} 天'**
  String reportHistoryItemTitle(String date, int days);

  /// No description provided for @reportHistoryItemPatient.
  ///
  /// In zh, this message translates to:
  /// **'患者：{name}'**
  String reportHistoryItemPatient(String name);

  /// No description provided for @reportHistoryItemNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get reportHistoryItemNotSet;

  /// No description provided for @reportHistoryDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这条报告？'**
  String get reportHistoryDeleteTitle;

  /// No description provided for @reportHistoryDeleteContent.
  ///
  /// In zh, this message translates to:
  /// **'删除后无法恢复，但可以重新生成。'**
  String get reportHistoryDeleteContent;

  /// No description provided for @homeCelebrationDay1.
  ///
  /// In zh, this message translates to:
  /// **'已记录！第 1 天 🌱'**
  String get homeCelebrationDay1;

  /// No description provided for @homeCelebrationStreakShort.
  ///
  /// In zh, this message translates to:
  /// **'已记录！连击 {days} 天 🌿'**
  String homeCelebrationStreakShort(int days);

  /// No description provided for @homeCelebrationStreakMedium.
  ///
  /// In zh, this message translates to:
  /// **'已记录！连击 {days} 天 🌳'**
  String homeCelebrationStreakMedium(int days);

  /// No description provided for @homeCelebrationStreakLong.
  ///
  /// In zh, this message translates to:
  /// **'已记录！{days} 天连击 🌲'**
  String homeCelebrationStreakLong(int days);

  /// No description provided for @homeCelebrationStreakMaster.
  ///
  /// In zh, this message translates to:
  /// **'已记录！{days} 天--您太厉害了 🏔️'**
  String homeCelebrationStreakMaster(int days);

  /// No description provided for @homeAutofireCelebration.
  ///
  /// In zh, this message translates to:
  /// **'已打卡：{name} ✅'**
  String homeAutofireCelebration(String name);

  /// No description provided for @homeAutofireFallbackName.
  ///
  /// In zh, this message translates to:
  /// **'该药'**
  String get homeAutofireFallbackName;

  /// No description provided for @homeMedHint.
  ///
  /// In zh, this message translates to:
  /// **'💊 准备打卡药物 #{id}'**
  String homeMedHint(int id);

  /// Snackbar 后缀 — 跟 displayMessage 组合显示，提醒用户尽快打卡或联系家人
  ///
  /// In zh, this message translates to:
  /// **'（请尽快打卡或联系家人）'**
  String get homeSafetyAlertSuffix;

  /// SafetyAlert 通知 body — SMS 实际发送成功分支（P0-3 三态修正，v0.27 R60）
  ///
  /// In zh, this message translates to:
  /// **'上次打卡: {date}。已自动通知紧急联系人，请确认安全。'**
  String safetyAlertBodySent(String date);

  /// SafetyAlert 通知 body — SMS mock 模式分支（避免 dev/release 模式混淆，P0-3 三态修正）
  ///
  /// In zh, this message translates to:
  /// **'上次打卡: {date}。失联检测已触发，但当前为开发模式，**未实际通知**紧急联系人。'**
  String safetyAlertBodyMocked(String date);

  /// SafetyAlert 通知 body — SMS 实际发送失败分支（P0-3 三态修正）
  ///
  /// In zh, this message translates to:
  /// **'上次打卡: {date}。失联检测已触发，但通知发送失败。请检查网络。'**
  String safetyAlertBodyFailed(String date);

  /// No description provided for @homeSnoozeTitle.
  ///
  /// In zh, this message translates to:
  /// **'⏰ 该打卡了（5min 后）'**
  String get homeSnoozeTitle;

  /// No description provided for @homeSnoozeBody.
  ///
  /// In zh, this message translates to:
  /// **'刚才您点了「snooze」，是时候点一下 = 打卡了'**
  String get homeSnoozeBody;

  /// No description provided for @homeSnoozeConfirmed.
  ///
  /// In zh, this message translates to:
  /// **'好，5 分钟后会再提醒您 👌'**
  String get homeSnoozeConfirmed;

  /// No description provided for @homeSnoozeButton.
  ///
  /// In zh, this message translates to:
  /// **'⏰ 5 分钟后再提醒'**
  String get homeSnoozeButton;

  /// No description provided for @homeVentButton.
  ///
  /// In zh, this message translates to:
  /// **'倾诉 🌲'**
  String get homeVentButton;

  /// No description provided for @homeNotifBannerText.
  ///
  /// In zh, this message translates to:
  /// **'提醒没设上，可能错过打卡。请到系统设置允许通知。'**
  String get homeNotifBannerText;

  /// No description provided for @homeNotifBannerDismiss.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get homeNotifBannerDismiss;

  /// No description provided for @themeTooltip.
  ///
  /// In zh, this message translates to:
  /// **'主题：{mode}（点击切换）'**
  String themeTooltip(String mode);

  /// No description provided for @themeModeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get themeModeDark;

  /// No description provided for @trendTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的趋势'**
  String get trendTitle;

  /// No description provided for @trendLast30Days.
  ///
  /// In zh, this message translates to:
  /// **'最近 30 天'**
  String get trendLast30Days;

  /// No description provided for @trendLast6Months.
  ///
  /// In zh, this message translates to:
  /// **'最近 6 个月'**
  String get trendLast6Months;

  /// No description provided for @trendAssessmentHistory.
  ///
  /// In zh, this message translates to:
  /// **'心理评估历史'**
  String get trendAssessmentHistory;

  /// No description provided for @trendMoodHistory.
  ///
  /// In zh, this message translates to:
  /// **'情绪日记历史'**
  String get trendMoodHistory;

  /// No description provided for @trendViewList.
  ///
  /// In zh, this message translates to:
  /// **'列表'**
  String get trendViewList;

  /// No description provided for @trendViewCalendar.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get trendViewCalendar;

  /// No description provided for @trendWithdrawnTitle.
  ///
  /// In zh, this message translates to:
  /// **'趋势分析已撤回'**
  String get trendWithdrawnTitle;

  /// No description provided for @trendWithdrawnSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'你撤回了「趋势分析」同意（PIPL §14）。趋势数据未删除, 重新开启后即可恢复。'**
  String get trendWithdrawnSubtitle;

  /// No description provided for @trendWithdrawnAction.
  ///
  /// In zh, this message translates to:
  /// **'去重新开启'**
  String get trendWithdrawnAction;

  /// No description provided for @trendWeekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get trendWeekdayMon;

  /// No description provided for @trendWeekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get trendWeekdayTue;

  /// No description provided for @trendWeekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get trendWeekdayWed;

  /// No description provided for @trendWeekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get trendWeekdayThu;

  /// No description provided for @trendWeekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get trendWeekdayFri;

  /// No description provided for @trendWeekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get trendWeekdaySat;

  /// No description provided for @trendWeekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get trendWeekdaySun;

  /// No description provided for @trendPrevMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get trendPrevMonth;

  /// No description provided for @trendNextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下个月'**
  String get trendNextMonth;

  /// No description provided for @trendMonthYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年 {month} 月'**
  String trendMonthYear(int year, int month);

  /// No description provided for @trendCheckedIn.
  ///
  /// In zh, this message translates to:
  /// **'已打卡'**
  String get trendCheckedIn;

  /// No description provided for @trendNotCheckedIn.
  ///
  /// In zh, this message translates to:
  /// **'未打卡'**
  String get trendNotCheckedIn;

  /// No description provided for @trendEventCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个事件'**
  String trendEventCount(int count);

  /// No description provided for @trendMoodEntriesSame.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条情绪记录 · {emoji}'**
  String trendMoodEntriesSame(int count, String emoji);

  /// No description provided for @trendMoodEntriesRange.
  ///
  /// In zh, this message translates to:
  /// **'情绪 {count} 条 · {lowEmoji}→{highEmoji}'**
  String trendMoodEntriesRange(int count, String lowEmoji, String highEmoji);

  /// No description provided for @trendNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'这一天没有记录'**
  String get trendNoRecords;

  /// No description provided for @trendStatCurrentStreak.
  ///
  /// In zh, this message translates to:
  /// **'当前连续'**
  String get trendStatCurrentStreak;

  /// No description provided for @trendStatLongestStreak.
  ///
  /// In zh, this message translates to:
  /// **'最长连续'**
  String get trendStatLongestStreak;

  /// No description provided for @trendStatTotalCheckIns.
  ///
  /// In zh, this message translates to:
  /// **'总打卡'**
  String get trendStatTotalCheckIns;

  /// No description provided for @trendStatTotalDays.
  ///
  /// In zh, this message translates to:
  /// **'总天数'**
  String get trendStatTotalDays;

  /// No description provided for @trendStatDaysValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天'**
  String trendStatDaysValue(int count);

  /// No description provided for @trendMonthLabel.
  ///
  /// In zh, this message translates to:
  /// **'{month}月'**
  String trendMonthLabel(int month);

  /// No description provided for @trendNoAssessments.
  ///
  /// In zh, this message translates to:
  /// **'还没有评估记录'**
  String get trendNoAssessments;

  /// No description provided for @trendNoAssessmentsHint.
  ///
  /// In zh, this message translates to:
  /// **'完成一次心理评估后，折线图会自动出现在这里'**
  String get trendNoAssessmentsHint;

  /// No description provided for @trendNoMoodEntries.
  ///
  /// In zh, this message translates to:
  /// **'还没有情绪记录'**
  String get trendNoMoodEntries;

  /// No description provided for @trendNoMoodEntriesHint.
  ///
  /// In zh, this message translates to:
  /// **'在主页点击「记一下情绪」开始记录'**
  String get trendNoMoodEntriesHint;

  /// No description provided for @contactEmptyList.
  ///
  /// In zh, this message translates to:
  /// **'还没有联系人，请先添加'**
  String get contactEmptyList;

  /// No description provided for @contactAddAction.
  ///
  /// In zh, this message translates to:
  /// **'添加联系人'**
  String get contactAddAction;

  /// No description provided for @contactAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加紧急联系人'**
  String get contactAddTitle;

  /// No description provided for @contactConsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'知情同意'**
  String get contactConsentTitle;

  /// PIPL §13 单独同意 dialog 正文, 精神心理患者保护专用
  ///
  /// In zh, this message translates to:
  /// **'您即将把这位联系人的手机号保存在本地数据库中。当您连续 {threshold} 天未在 App 内打卡时，App 会通过 SMS 短信自动通知该联系人。\n\n**根据《个人信息保护法》第 13 条**，请确认您已告知该联系人上述用途，并取得其同意。'**
  String contactConsentBody(int threshold);

  /// No description provided for @contactConsentAgree.
  ///
  /// In zh, this message translates to:
  /// **'已告知并取得同意'**
  String get contactConsentAgree;

  /// No description provided for @contactConsentReject.
  ///
  /// In zh, this message translates to:
  /// **'暂不同意'**
  String get contactConsentReject;

  /// No description provided for @contactConsentVersion.
  ///
  /// In zh, this message translates to:
  /// **'v1 · 2026-07-31'**
  String get contactConsentVersion;

  /// No description provided for @contactDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'联系人'**
  String get contactDefaultName;

  /// No description provided for @contactNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get contactNameLabel;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get contactPhoneLabel;

  /// No description provided for @commonActionDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonActionDelete;

  /// No description provided for @commonActionSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonActionSave;

  /// No description provided for @editMedDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑药物'**
  String get editMedDialogTitle;

  /// No description provided for @editMedValidationNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写药名'**
  String get editMedValidationNameRequired;

  /// No description provided for @editMedValidationDosageInvalid.
  ///
  /// In zh, this message translates to:
  /// **'剂量必须是大于 0 的数字'**
  String get editMedValidationDosageInvalid;

  /// No description provided for @editMedValidationUnitInvalid.
  ///
  /// In zh, this message translates to:
  /// **'单位必须是 mg 或 片'**
  String get editMedValidationUnitInvalid;

  /// No description provided for @editMedSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String editMedSaveFailed(String error);

  /// No description provided for @editMedStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'正在使用'**
  String get editMedStatusActive;

  /// No description provided for @editMedStatusStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停药'**
  String get editMedStatusStopped;

  /// No description provided for @editMedStoppedDate.
  ///
  /// In zh, this message translates to:
  /// **'{date} 停药'**
  String editMedStoppedDate(String date);

  /// No description provided for @editMedNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入药盒上的名称（选填）'**
  String get editMedNameHint;

  /// No description provided for @editMedDosageLabel.
  ///
  /// In zh, this message translates to:
  /// **'剂量'**
  String get editMedDosageLabel;

  /// No description provided for @editMedUnitLabel.
  ///
  /// In zh, this message translates to:
  /// **'单位'**
  String get editMedUnitLabel;

  /// No description provided for @editMedTimeSectionLabel.
  ///
  /// In zh, this message translates to:
  /// **'吃药时间（点 + 加）'**
  String get editMedTimeSectionLabel;

  /// No description provided for @editMedAddTime.
  ///
  /// In zh, this message translates to:
  /// **'加时间'**
  String get editMedAddTime;

  /// No description provided for @editMedNoTimeHint.
  ///
  /// In zh, this message translates to:
  /// **'（不设置时间 = 不调度提醒，仅记录）'**
  String get editMedNoTimeHint;

  /// No description provided for @editMedStopAction.
  ///
  /// In zh, this message translates to:
  /// **'停用此药'**
  String get editMedStopAction;

  /// No description provided for @editMedResumeAction.
  ///
  /// In zh, this message translates to:
  /// **'重新启用'**
  String get editMedResumeAction;

  /// No description provided for @editMedStopHint.
  ///
  /// In zh, this message translates to:
  /// **'软停：保留所有打卡历史，不再推送提醒'**
  String get editMedStopHint;

  /// No description provided for @editMedResumeHint.
  ///
  /// In zh, this message translates to:
  /// **'恢复：清空停药日期，恢复每日提醒'**
  String get editMedResumeHint;

  /// No description provided for @medReportCopyHint.
  ///
  /// In zh, this message translates to:
  /// **'可全选复制、生成 PDF 或分享给医生'**
  String get medReportCopyHint;

  /// No description provided for @medReportPdfLabel.
  ///
  /// In zh, this message translates to:
  /// **'PDF'**
  String get medReportPdfLabel;

  /// No description provided for @medReportShareLabel.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get medReportShareLabel;

  /// No description provided for @medReportPdfLoading.
  ///
  /// In zh, this message translates to:
  /// **'生成 PDF 中……'**
  String get medReportPdfLoading;

  /// No description provided for @medReportShareSubject.
  ///
  /// In zh, this message translates to:
  /// **'慢病管家 · 用药报告'**
  String get medReportShareSubject;

  /// No description provided for @tempMedDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加临时吃药'**
  String get tempMedDialogTitle;

  /// No description provided for @tempMedLinkLabel.
  ///
  /// In zh, this message translates to:
  /// **'关联到常吃药（可选）'**
  String get tempMedLinkLabel;

  /// No description provided for @tempMedLinkHint.
  ///
  /// In zh, this message translates to:
  /// **'不选 = 临时事件'**
  String get tempMedLinkHint;

  /// No description provided for @tempMedNoLink.
  ///
  /// In zh, this message translates to:
  /// **'不关联'**
  String get tempMedNoLink;

  /// No description provided for @tempMedNameHint.
  ///
  /// In zh, this message translates to:
  /// **'如：布洛芬'**
  String get tempMedNameHint;

  /// No description provided for @tempMedReasonLabel.
  ///
  /// In zh, this message translates to:
  /// **'原因'**
  String get tempMedReasonLabel;

  /// No description provided for @tempMedReasonHint.
  ///
  /// In zh, this message translates to:
  /// **'如：感冒'**
  String get tempMedReasonHint;

  /// No description provided for @medsCalendarHeatmapDesc.
  ///
  /// In zh, this message translates to:
  /// **'以药为单位的依从性热力图。颜色越深 = 当天打卡次数越接近期望次数。'**
  String get medsCalendarHeatmapDesc;

  /// No description provided for @medsCalendarWindow7.
  ///
  /// In zh, this message translates to:
  /// **'7 天'**
  String get medsCalendarWindow7;

  /// No description provided for @medsCalendarWindow30.
  ///
  /// In zh, this message translates to:
  /// **'30 天'**
  String get medsCalendarWindow30;

  /// No description provided for @medsCalendarWindow90.
  ///
  /// In zh, this message translates to:
  /// **'90 天'**
  String get medsCalendarWindow90;

  /// No description provided for @medsCalendarLoadCheckinFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载打卡失败：{error}'**
  String medsCalendarLoadCheckinFailed(String error);

  /// No description provided for @medsCalendarLoadMedFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载药物失败：{error}'**
  String medsCalendarLoadMedFailed(String error);

  /// No description provided for @medsCalendarNoActive.
  ///
  /// In zh, this message translates to:
  /// **'还没有在用药物'**
  String get medsCalendarNoActive;

  /// No description provided for @medsCalendarNoSchedule.
  ///
  /// In zh, this message translates to:
  /// **'在用药物未设置服用时间，无法生成依从性日历'**
  String get medsCalendarNoSchedule;

  /// No description provided for @medsCalendarNoScheduleHint.
  ///
  /// In zh, this message translates to:
  /// **'在设置页给药物加上服药时间后，这里会显示服药日历'**
  String get medsCalendarNoScheduleHint;

  /// No description provided for @medsCalendarNoActiveAction.
  ///
  /// In zh, this message translates to:
  /// **'添加药物'**
  String get medsCalendarNoActiveAction;

  /// No description provided for @medsCalendarNoScheduleAction.
  ///
  /// In zh, this message translates to:
  /// **'去设置时间'**
  String get medsCalendarNoScheduleAction;

  /// No description provided for @medsCalendarLegendLabel.
  ///
  /// In zh, this message translates to:
  /// **'依从：'**
  String get medsCalendarLegendLabel;

  /// No description provided for @medsCalendarLegendMissed.
  ///
  /// In zh, this message translates to:
  /// **'漏服'**
  String get medsCalendarLegendMissed;

  /// No description provided for @window7Subtitle.
  ///
  /// In zh, this message translates to:
  /// **'一周内（适合周复诊）'**
  String get window7Subtitle;

  /// No description provided for @window14Subtitle.
  ///
  /// In zh, this message translates to:
  /// **'两周内（推荐）'**
  String get window14Subtitle;

  /// No description provided for @window30Subtitle.
  ///
  /// In zh, this message translates to:
  /// **'一个月内（适合月度评估）'**
  String get window30Subtitle;

  /// No description provided for @snackbarActionSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get snackbarActionSave;

  /// No description provided for @snackbarActionShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get snackbarActionShare;

  /// No description provided for @snackbarActionGeneratePdf.
  ///
  /// In zh, this message translates to:
  /// **'生成 PDF'**
  String get snackbarActionGeneratePdf;

  /// No description provided for @snackbarActionPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get snackbarActionPlay;

  /// No description provided for @snackbarActionEncryptRecording.
  ///
  /// In zh, this message translates to:
  /// **'加密录音'**
  String get snackbarActionEncryptRecording;

  /// No description provided for @snackbarActionRecord.
  ///
  /// In zh, this message translates to:
  /// **'录音'**
  String get snackbarActionRecord;

  /// No description provided for @snackbarActionStartRecording.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get snackbarActionStartRecording;

  /// No description provided for @snackbarActionCheckin.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get snackbarActionCheckin;

  /// No description provided for @snackbarActionSnooze.
  ///
  /// In zh, this message translates to:
  /// **'推迟提醒'**
  String get snackbarActionSnooze;

  /// No description provided for @snackbarActionAutoCheckin.
  ///
  /// In zh, this message translates to:
  /// **'自动打卡'**
  String get snackbarActionAutoCheckin;

  /// No description provided for @snackbarActionFinishSetup.
  ///
  /// In zh, this message translates to:
  /// **'完成设置'**
  String get snackbarActionFinishSetup;

  /// No description provided for @snackbarActionUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get snackbarActionUndo;

  /// No description provided for @ventEntryDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除树洞条目'**
  String get ventEntryDeleted;

  /// No description provided for @contactDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除联系人'**
  String get contactDeleted;

  /// No description provided for @medicationDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除药物'**
  String get medicationDeleted;

  /// No description provided for @moodTodayLabel.
  ///
  /// In zh, this message translates to:
  /// **'今日情绪：'**
  String get moodTodayLabel;

  /// No description provided for @moodRecordButton.
  ///
  /// In zh, this message translates to:
  /// **'记一下情绪 ✏️'**
  String get moodRecordButton;

  /// No description provided for @medReportFileName.
  ///
  /// In zh, this message translates to:
  /// **'用药报告_{date}'**
  String medReportFileName(String date);

  /// No description provided for @migrationPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级到 v0.9'**
  String get migrationPromptTitle;

  /// No description provided for @migrationPromptDetectedOld.
  ///
  /// In zh, this message translates to:
  /// **'检测到本地有旧版本数据。'**
  String get migrationPromptDetectedOld;

  /// No description provided for @migrationPromptChangesTitle.
  ///
  /// In zh, this message translates to:
  /// **'本次升级会：'**
  String get migrationPromptChangesTitle;

  /// No description provided for @migrationPromptChangeEncrypt.
  ///
  /// In zh, this message translates to:
  /// **'• 启用数据库加密（保护您的隐私）'**
  String get migrationPromptChangeEncrypt;

  /// No description provided for @migrationPromptChangeClear.
  ///
  /// In zh, this message translates to:
  /// **'• 清空旧版本的所有打卡记录'**
  String get migrationPromptChangeClear;

  /// No description provided for @migrationPromptChangeWarning.
  ///
  /// In zh, this message translates to:
  /// **'（旧版本没有\"导出数据\"功能，原始数据无法恢复）'**
  String get migrationPromptChangeWarning;

  /// No description provided for @migrationPromptRecommendExport.
  ///
  /// In zh, this message translates to:
  /// **'建议：先在旧版 App 内完成\"导出数据\"备份，再升级。'**
  String get migrationPromptRecommendExport;

  /// No description provided for @migrationPromptDirectContinue.
  ///
  /// In zh, this message translates to:
  /// **'若旧版已卸载无法导出，可以直接点\"继续升级\"。'**
  String get migrationPromptDirectContinue;

  /// No description provided for @migrationPromptCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get migrationPromptCancel;

  /// No description provided for @migrationPromptContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续升级'**
  String get migrationPromptContinue;

  /// No description provided for @migrationAbortedTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级已取消'**
  String get migrationAbortedTitle;

  /// No description provided for @migrationAbortedBody.
  ///
  /// In zh, this message translates to:
  /// **'请先在旧版本 App 内完成\"导出数据\"备份，\n备份完成后点下方按钮继续升级。'**
  String get migrationAbortedBody;

  /// No description provided for @migrationAbortedRetry.
  ///
  /// In zh, this message translates to:
  /// **'已备份，继续升级'**
  String get migrationAbortedRetry;

  /// No description provided for @migrationFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get migrationFailedTitle;

  /// No description provided for @migrationFailedBody.
  ///
  /// In zh, this message translates to:
  /// **'无法初始化本地数据。\n请尝试：\n1) 重启 App\n2) 卸载后重装\n如反复出现，请反馈给我们。'**
  String get migrationFailedBody;

  /// No description provided for @migrationFailedReassure.
  ///
  /// In zh, this message translates to:
  /// **'请别担心，您的数据是加密的。我们会尽快解决。'**
  String get migrationFailedReassure;

  /// No description provided for @moodRatingSemantics.
  ///
  /// In zh, this message translates to:
  /// **'情绪评分，1 到 5 分制，5 分最积极'**
  String get moodRatingSemantics;

  /// No description provided for @moodRatingButtonSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{score} 分{selected, select, true{，已选} other{}}'**
  String moodRatingButtonSemantics(Object score, String selected);

  /// No description provided for @medicationTimeWindowSemantics.
  ///
  /// In zh, this message translates to:
  /// **'时间窗口 {days} 天，7／30／90 单选'**
  String medicationTimeWindowSemantics(Object days);

  /// No description provided for @assessmentSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'评估结果已显示，但保存失败。请稍后重试。'**
  String get assessmentSaveFailed;

  /// No description provided for @setupContactFallbackName.
  ///
  /// In zh, this message translates to:
  /// **'联系人 {index}'**
  String setupContactFallbackName(int index);

  /// No description provided for @setupConsentRejected.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝该联系人的知情同意，未写入。可重新填写后继续。'**
  String get setupConsentRejected;

  /// No description provided for @emailBodyI18n.
  ///
  /// In zh, this message translates to:
  /// **'我是 {name}，已经 {days} 天没在 App 里打卡了。\n请你方便的时候提醒我按时吃药，避免复发。'**
  String emailBodyI18n(String name, int days);

  /// No description provided for @emailFooterI18n.
  ///
  /// In zh, this message translates to:
  /// **'这是一条自动通知，由慢病管家 App 发送。\n本通知不包含任何医疗建议。\n如需停止接收，请在 App 设置中修改。'**
  String get emailFooterI18n;

  /// No description provided for @medicationUnitMg.
  ///
  /// In zh, this message translates to:
  /// **'mg'**
  String get medicationUnitMg;

  /// No description provided for @medicationUnitTablet.
  ///
  /// In zh, this message translates to:
  /// **'片'**
  String get medicationUnitTablet;

  /// No description provided for @safetyCheckResultDisabled.
  ///
  /// In zh, this message translates to:
  /// **'安全开关已关闭'**
  String get safetyCheckResultDisabled;

  /// No description provided for @safetyCheckResultOk.
  ///
  /// In zh, this message translates to:
  /// **'正常（{days} 天前打卡）'**
  String safetyCheckResultOk(int days);

  /// No description provided for @safetyCheckResultNoData.
  ///
  /// In zh, this message translates to:
  /// **'新用户，暂无打卡'**
  String get safetyCheckResultNoData;

  /// No description provided for @safetyCheckResultAlertedToday.
  ///
  /// In zh, this message translates to:
  /// **'今天已经发过告警（{days} 天前打卡）'**
  String safetyCheckResultAlertedToday(int days);

  /// No description provided for @safetyCheckResultDndSuppressed.
  ///
  /// In zh, this message translates to:
  /// **'DND 时段，跳过告警'**
  String get safetyCheckResultDndSuppressed;

  /// No description provided for @safetyCheckResultNoContacts.
  ///
  /// In zh, this message translates to:
  /// **'无紧急联系人，未发送'**
  String get safetyCheckResultNoContacts;

  /// No description provided for @safetyCheckResultAlertedMocked.
  ///
  /// In zh, this message translates to:
  /// **'**开发模式**，未实际通知联系人（mock: {mocked}）'**
  String safetyCheckResultAlertedMocked(int mocked);

  /// No description provided for @safetyCheckResultAlerted.
  ///
  /// In zh, this message translates to:
  /// **'已告警：{days} 天前打卡，已通知 {notified} 位联系人（{failed} 失败）'**
  String safetyCheckResultAlerted(int days, int notified, int failed);

  /// No description provided for @safetyCheckResultError.
  ///
  /// In zh, this message translates to:
  /// **'错误：{message}'**
  String safetyCheckResultError(String message);

  /// No description provided for @settingsIapUpgradeTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级到 Pro'**
  String get settingsIapUpgradeTitle;

  /// No description provided for @settingsIapUpgradeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'¥8 一次性买断 · 解锁全部高级功能'**
  String get settingsIapUpgradeSubtitle;

  /// No description provided for @settingsIapProOwnedTitle.
  ///
  /// In zh, this message translates to:
  /// **'已是 Pro 版本'**
  String get settingsIapProOwnedTitle;

  /// No description provided for @settingsIapProOwnedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'感谢支持 · 全部高级功能已解锁'**
  String get settingsIapProOwnedSubtitle;

  /// No description provided for @iapPurchaseSuccess.
  ///
  /// In zh, this message translates to:
  /// **'升级成功！欢迎使用 Pro。'**
  String get iapPurchaseSuccess;

  /// No description provided for @iapPurchaseFailed.
  ///
  /// In zh, this message translates to:
  /// **'购买未完成，请稍后再试。'**
  String get iapPurchaseFailed;

  /// No description provided for @phoneRegionCn.
  ///
  /// In zh, this message translates to:
  /// **'中国大陆'**
  String get phoneRegionCn;

  /// No description provided for @phoneRegionHk.
  ///
  /// In zh, this message translates to:
  /// **'中国香港'**
  String get phoneRegionHk;

  /// No description provided for @phoneRegionMo.
  ///
  /// In zh, this message translates to:
  /// **'中国澳门'**
  String get phoneRegionMo;

  /// No description provided for @phoneRegionTw.
  ///
  /// In zh, this message translates to:
  /// **'中国台湾'**
  String get phoneRegionTw;

  /// No description provided for @phoneRegionIntl.
  ///
  /// In zh, this message translates to:
  /// **'国际'**
  String get phoneRegionIntl;

  /// No description provided for @presetMedSsriMorningTitle.
  ///
  /// In zh, this message translates to:
  /// **'单药 · SSRI 早一次'**
  String get presetMedSsriMorningTitle;

  /// No description provided for @presetMedSsriMorningDesc.
  ///
  /// In zh, this message translates to:
  /// **'1 种药，每天早 8 点服用（适用 SSRI ／ SNRI 类）'**
  String get presetMedSsriMorningDesc;

  /// No description provided for @presetMedMoodStabilizerTwiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪稳定剂 · 早晚两次'**
  String get presetMedMoodStabilizerTwiceTitle;

  /// No description provided for @presetMedMoodStabilizerTwiceDesc.
  ///
  /// In zh, this message translates to:
  /// **'1 种药，每天早 8 点 + 晚 20 点'**
  String get presetMedMoodStabilizerTwiceDesc;

  /// No description provided for @presetMedComboSsriBedtimeTitle.
  ///
  /// In zh, this message translates to:
  /// **'联合 · 早抗抑郁 + 晚助眠'**
  String get presetMedComboSsriBedtimeTitle;

  /// No description provided for @presetMedComboSsriBedtimeDesc.
  ///
  /// In zh, this message translates to:
  /// **'2 种药：早 8 点 SSRI + 晚 21 点助眠'**
  String get presetMedComboSsriBedtimeDesc;

  /// No description provided for @presetMedComboAntipsychoticFullTitle.
  ///
  /// In zh, this message translates to:
  /// **'重性 · 早中晚三次'**
  String get presetMedComboAntipsychoticFullTitle;

  /// No description provided for @presetMedComboAntipsychoticFullDesc.
  ///
  /// In zh, this message translates to:
  /// **'2 种药：早 8 ／ 午 13 ／ 晚 20，覆盖全天'**
  String get presetMedComboAntipsychoticFullDesc;

  /// No description provided for @presetMedSsriName.
  ///
  /// In zh, this message translates to:
  /// **'SSRI 类抗抑郁药'**
  String get presetMedSsriName;

  /// No description provided for @presetMedSsriHint.
  ///
  /// In zh, this message translates to:
  /// **'常见 SSRI ／ SNRI 类抗抑郁药（具体药名以医生处方为准）'**
  String get presetMedSsriHint;

  /// No description provided for @presetMedMoodStabilizerName.
  ///
  /// In zh, this message translates to:
  /// **'情绪稳定剂'**
  String get presetMedMoodStabilizerName;

  /// No description provided for @presetMedMoodStabilizerHint.
  ///
  /// In zh, this message translates to:
  /// **'常见情绪稳定剂类（具体药名以医生处方为准）'**
  String get presetMedMoodStabilizerHint;

  /// No description provided for @presetMedSleepAidName.
  ///
  /// In zh, this message translates to:
  /// **'助眠药'**
  String get presetMedSleepAidName;

  /// No description provided for @presetMedSleepAidHint.
  ///
  /// In zh, this message translates to:
  /// **'常见苯二氮卓类／助眠药（具体药名以医生处方为准）'**
  String get presetMedSleepAidHint;

  /// No description provided for @presetMedAntipsychoticName.
  ///
  /// In zh, this message translates to:
  /// **'抗精神病药'**
  String get presetMedAntipsychoticName;

  /// No description provided for @presetMedAntipsychoticHint.
  ///
  /// In zh, this message translates to:
  /// **'常见非典型抗精神病药（具体药名以医生处方为准）'**
  String get presetMedAntipsychoticHint;

  /// No description provided for @presetMedSedativeAnxiolyticName.
  ///
  /// In zh, this message translates to:
  /// **'镇静／抗焦虑辅助'**
  String get presetMedSedativeAnxiolyticName;

  /// No description provided for @presetMedSedativeAnxiolyticHint.
  ///
  /// In zh, this message translates to:
  /// **'常见镇静／抗焦虑辅助药（具体药名以医生处方为准）'**
  String get presetMedSedativeAnxiolyticHint;

  /// No description provided for @checkInTypeDaily.
  ///
  /// In zh, this message translates to:
  /// **'每日打卡'**
  String get checkInTypeDaily;

  /// No description provided for @checkInTypeTemp.
  ///
  /// In zh, this message translates to:
  /// **'临时吃药'**
  String get checkInTypeTemp;

  /// No description provided for @checkInTypePhq9.
  ///
  /// In zh, this message translates to:
  /// **'PHQ-9 评估'**
  String get checkInTypePhq9;

  /// No description provided for @checkInTypeGad7.
  ///
  /// In zh, this message translates to:
  /// **'GAD-7 评估'**
  String get checkInTypeGad7;

  /// No description provided for @dayDetailCheckInWith.
  ///
  /// In zh, this message translates to:
  /// **'打卡 · {name}'**
  String dayDetailCheckInWith(String name);

  /// No description provided for @dayDetailDailyCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'每日打卡'**
  String get dayDetailDailyCheckIn;

  /// No description provided for @dayDetailTempWith.
  ///
  /// In zh, this message translates to:
  /// **'临时 · {name}'**
  String dayDetailTempWith(String name);

  /// No description provided for @dayDetailTempMed.
  ///
  /// In zh, this message translates to:
  /// **'临时吃药'**
  String get dayDetailTempMed;

  /// No description provided for @dayDetailPhq9.
  ///
  /// In zh, this message translates to:
  /// **'PHQ-9 抑郁筛查'**
  String get dayDetailPhq9;

  /// No description provided for @dayDetailGad7.
  ///
  /// In zh, this message translates to:
  /// **'GAD-7 焦虑筛查'**
  String get dayDetailGad7;

  /// No description provided for @ventDurationSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{sec}秒'**
  String ventDurationSeconds(int sec);

  /// No description provided for @ventDurationMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{m}分'**
  String ventDurationMinutes(int m);

  /// No description provided for @ventDurationMinutesSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{m}分{sec}秒'**
  String ventDurationMinutesSeconds(int m, String sec);

  /// No description provided for @scaleHotlineCn.
  ///
  /// In zh, this message translates to:
  /// **'全国 24 小时心理援助热线'**
  String get scaleHotlineCn;

  /// No description provided for @scaleHotlineUs.
  ///
  /// In zh, this message translates to:
  /// **'988 Suicide & Crisis Lifeline (US)'**
  String get scaleHotlineUs;

  /// No description provided for @scaleHotlineHk.
  ///
  /// In zh, this message translates to:
  /// **'撒玛利亚防止自杀会（24h 多语言）'**
  String get scaleHotlineHk;

  /// No description provided for @scaleHotlineIntl.
  ///
  /// In zh, this message translates to:
  /// **'国际通用 · 请联系当地急救或心理援助'**
  String get scaleHotlineIntl;

  /// PHQ-9 第 9 题阳性时弹窗的标题（'我们关心你'）
  ///
  /// In zh, this message translates to:
  /// **'我们关心你'**
  String get scaleCrisisTitle;

  /// PHQ-9 第 9 题阳性时弹窗的正文, 含换行
  ///
  /// In zh, this message translates to:
  /// **'你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。'**
  String get scaleCrisisMessage;
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
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

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
