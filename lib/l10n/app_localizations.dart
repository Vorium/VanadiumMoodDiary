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
  String homeLastMed(Object time);

  /// No description provided for @homeNextReminder.
  ///
  /// In zh, this message translates to:
  /// **'下次提醒：{time}'**
  String homeNextReminder(Object time);

  /// No description provided for @homeStillOnline.
  ///
  /// In zh, this message translates to:
  /// **'🌱 您还在线'**
  String get homeStillOnline;

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
  /// **'✓ 漏 2 天提醒会升级，请及时打卡'**
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

  /// No description provided for @settingsMedication.
  ///
  /// In zh, this message translates to:
  /// **'常吃药'**
  String get settingsMedication;

  /// No description provided for @settingsHealthData.
  ///
  /// In zh, this message translates to:
  /// **'健康数据'**
  String get settingsHealthData;

  /// v1.1.0 round 11 (R115): 设置-健康数据-用药副标题
  ///
  /// In zh, this message translates to:
  /// **'{total} 种药物 · 今日 {done}/{total} 已服'**
  String settingsHealthDataMedSub(int total, int done);

  /// v1.1.0 round 11 (R115): 设置-健康数据-心理评估副标题
  ///
  /// In zh, this message translates to:
  /// **'{count} 个量表'**
  String settingsHealthDataAssSub(int count);

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
  /// **'管理所有提醒：每日打卡、用药时间、续方、心理评估'**
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

  /// R99 (BUG-2): 關於頁版本行， version 走 kPubspecVersion 動態注入 （不再硬編碼）
  ///
  /// In zh, this message translates to:
  /// **'v{version} · 我今天吃了药'**
  String settingsAboutVersion(String version);

  /// No description provided for @settingsDisclaimerText.
  ///
  /// In zh, this message translates to:
  /// **'本应用不提供医疗建议，所有功能仅供参考。'**
  String get settingsDisclaimerText;

  /// No description provided for @settingsExportRiskTitle.
  ///
  /// In zh, this message translates to:
  /// **'明文风险提示'**
  String get settingsExportRiskTitle;

  /// No description provided for @settingsExportRiskBody.
  ///
  /// In zh, this message translates to:
  /// **'您即将导出的数据为明文文件，含您的个人健康等敏感信息（用药、打卡、树洞文字）。请务必保存到安全、可信的位置（加密 U 盘 / 私人云盘），避免上传至公共云盘或发送给不可信的第三方。'**
  String get settingsExportRiskBody;

  /// No description provided for @settingsExportRiskLiability.
  ///
  /// In zh, this message translates to:
  /// **'一旦导出，文件的安全与保密由您自行负责，本 App 不再承担保护责任（PIPL §17 明确告知 + 用户确认）。'**
  String get settingsExportRiskLiability;

  /// No description provided for @settingsExportRiskAcknowledge.
  ///
  /// In zh, this message translates to:
  /// **'我已了解风险，继续导出'**
  String get settingsExportRiskAcknowledge;

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
  String settingsImportSuccess(Object summary);

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
  /// **'以下数据将被永久删除，无法恢复：\n• 打卡记录\n• 用药与服药历史\n• 心理评估结果\n• 情绪日记\n• 树洞（文字+录音）\n\n清空后 App 会跳回首次设置流程。建议先导出 JSON 备份。'**
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

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

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
  String commonLoadFailed(Object error);

  /// Generic error snackbar: '<action> failed: <error>'. Action is the user-facing action （保存／刪除／導出／…………)
  ///
  /// In zh, this message translates to:
  /// **'{action}失败：{error}'**
  String snackbarErrorTemplate(Object action, Object error);

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
  String medsRefillSet(Object date, int days);

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
  String medsRefillUpcoming(Object date, int days, int reminderDays);

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

  /// No description provided for @notificationStatusCardPermissionDeniedTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知权限已关闭'**
  String get notificationStatusCardPermissionDeniedTitle;

  /// No description provided for @notificationStatusCardPermissionDeniedBody.
  ///
  /// In zh, this message translates to:
  /// **'无法发送用药提醒。请在系统设置中允许通知，或点击下方按钮前往设置。'**
  String get notificationStatusCardPermissionDeniedBody;

  /// No description provided for @notificationStatusCardPermissionGoSettings.
  ///
  /// In zh, this message translates to:
  /// **'前往系统设置'**
  String get notificationStatusCardPermissionGoSettings;

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
  /// **'集中管理所有提醒：每天打卡、用药时间、续方日期、心理评估。'**
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

  /// No description provided for @reminderHubNDays.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天'**
  String reminderHubNDays(int days);

  /// No description provided for @ventListTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的树洞'**
  String get ventListTitle;

  /// No description provided for @legalVentWithdrawTitle.
  ///
  /// In zh, this message translates to:
  /// **'撤回树洞同意'**
  String get legalVentWithdrawTitle;

  /// No description provided for @legalVentWithdrawBody.
  ///
  /// In zh, this message translates to:
  /// **'树洞内容是您最私密的数据。撤回同意后，您可选择以下方式处理已有数据：'**
  String get legalVentWithdrawBody;

  /// No description provided for @legalVentWithdrawDelete.
  ///
  /// In zh, this message translates to:
  /// **'立即删除'**
  String get legalVentWithdrawDelete;

  /// No description provided for @legalVentWithdrawDeleteDesc.
  ///
  /// In zh, this message translates to:
  /// **'所有树洞文字 + 录音文件立即物理删除，不可恢复'**
  String get legalVentWithdrawDeleteDesc;

  /// No description provided for @legalVentWithdrawSeal.
  ///
  /// In zh, this message translates to:
  /// **'加密封存'**
  String get legalVentWithdrawSeal;

  /// No description provided for @legalVentWithdrawSealDesc.
  ///
  /// In zh, this message translates to:
  /// **'数据保留在本地但加密，UI 不可见，重新同意后可恢复'**
  String get legalVentWithdrawSealDesc;

  /// No description provided for @legalVentWithdrawnDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count, plural, =0{0 条} =1{1 条} other{{count} 条}}树洞'**
  String legalVentWithdrawnDeleted(num count);

  /// No description provided for @legalVentWithdrawnSealed.
  ///
  /// In zh, this message translates to:
  /// **'已加密封存，数据保留在本地'**
  String get legalVentWithdrawnSealed;

  /// No description provided for @legalVentDeleteRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试删除'**
  String get legalVentDeleteRetry;

  /// No description provided for @ventSealedTitle.
  ///
  /// In zh, this message translates to:
  /// **'已加密封存'**
  String get ventSealedTitle;

  /// No description provided for @ventSealedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'您已撤回树洞同意。所有数据已加密封存，UI 不可见。重新同意后可恢复。'**
  String get ventSealedSubtitle;

  /// No description provided for @ventSealedAction.
  ///
  /// In zh, this message translates to:
  /// **'前往法律与隐私'**
  String get ventSealedAction;

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

  /// R97-P1-4 (2026-08-07): 樹洞詳情頁舉報 / 反饋按鈕 tooltip (Apple 1.2.1 UGC 報告機制要求）
  ///
  /// In zh, this message translates to:
  /// **'举报或反馈'**
  String get ventReportTooltip;

  /// R97-P1-4: 舉報 / 反饋對話框標題
  ///
  /// In zh, this message translates to:
  /// **'私密倾诉说明'**
  String get ventReportDialogTitle;

  /// R97-P1-4: 舉報 / 反饋對話框正文， 說明 vent 是本地私密內容 + 引導到 legal 頁反饋
  ///
  /// In zh, this message translates to:
  /// **'树洞内容仅存储在您的设备， 不会上传任何服务器， 不存在用户间互相看到的情况。\n\n如发现 App 本身的不当内容或想反馈问题， 请前往「法律与隐私」页面联系开发者。'**
  String get ventReportDialogBody;

  /// R97-P1-4: 舉報對話框跳轉 legal 頁按鈕
  ///
  /// In zh, this message translates to:
  /// **'前往法律与隐私'**
  String get ventReportDialogAction;

  /// R97-P1-4: 舉報對話框關閉按鈕
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get ventReportDialogClose;

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

  /// No description provided for @ventTagSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get ventTagSectionTitle;

  /// No description provided for @ventTagCustomHint.
  ///
  /// In zh, this message translates to:
  /// **'自定义标签……'**
  String get ventTagCustomHint;

  /// No description provided for @ventTagFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get ventTagFilterAll;

  /// No description provided for @ventTagFilterEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有带这个标签的树洞'**
  String get ventTagFilterEmpty;

  /// No description provided for @ventRecordIdle.
  ///
  /// In zh, this message translates to:
  /// **'按一下开始录音'**
  String get ventRecordIdle;

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

  /// No description provided for @audioRecordPauseTooltip.
  ///
  /// In zh, this message translates to:
  /// **'暂停录音'**
  String get audioRecordPauseTooltip;

  /// No description provided for @audioRecordResumeTooltip.
  ///
  /// In zh, this message translates to:
  /// **'继续录音'**
  String get audioRecordResumeTooltip;

  /// No description provided for @audioRecordStopTooltip.
  ///
  /// In zh, this message translates to:
  /// **'停止录音'**
  String get audioRecordStopTooltip;

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
  String ventDurationMinutesSeconds(int m, Object sec);

  /// No description provided for @moodDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'今天怎么样？'**
  String get moodDialogTitle;

  /// No description provided for @moodScoreSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪评分'**
  String get moodScoreSectionTitle;

  /// No description provided for @moodRecordSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'记录内容'**
  String get moodRecordSectionTitle;

  /// No description provided for @moodDialogPeriodLabel.
  ///
  /// In zh, this message translates to:
  /// **'时段'**
  String get moodDialogPeriodLabel;

  /// No description provided for @moodPeriodMorning.
  ///
  /// In zh, this message translates to:
  /// **'早上'**
  String get moodPeriodMorning;

  /// No description provided for @moodPeriodNoon.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get moodPeriodNoon;

  /// No description provided for @moodPeriodEvening.
  ///
  /// In zh, this message translates to:
  /// **'晚上'**
  String get moodPeriodEvening;

  /// No description provided for @moodPeriodNight.
  ///
  /// In zh, this message translates to:
  /// **'夜间'**
  String get moodPeriodNight;

  /// No description provided for @moodPeriodUnspecified.
  ///
  /// In zh, this message translates to:
  /// **'未指定'**
  String get moodPeriodUnspecified;

  /// No description provided for @moodListFilterPeriod.
  ///
  /// In zh, this message translates to:
  /// **'时段'**
  String get moodListFilterPeriod;

  /// No description provided for @moodPeriodChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'心境 4 段趋势（近 30 天）'**
  String get moodPeriodChartTitle;

  /// No description provided for @moodDimensionMood.
  ///
  /// In zh, this message translates to:
  /// **'情绪'**
  String get moodDimensionMood;

  /// No description provided for @moodDimensionEnergy.
  ///
  /// In zh, this message translates to:
  /// **'精力'**
  String get moodDimensionEnergy;

  /// No description provided for @moodDimensionSleep.
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get moodDimensionSleep;

  /// No description provided for @moodDimensionAnxiety.
  ///
  /// In zh, this message translates to:
  /// **'焦虑'**
  String get moodDimensionAnxiety;

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

  /// No description provided for @moodStatusPhraseTitle.
  ///
  /// In zh, this message translates to:
  /// **'状态短语'**
  String get moodStatusPhraseTitle;

  /// No description provided for @moodStatusPhraseHint.
  ///
  /// In zh, this message translates to:
  /// **'或输入一句此刻的心情……'**
  String get moodStatusPhraseHint;

  /// No description provided for @moodStatusPhraseShowAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get moodStatusPhraseShowAll;

  /// No description provided for @moodAudioRecordButton.
  ///
  /// In zh, this message translates to:
  /// **'录语音'**
  String get moodAudioRecordButton;

  /// No description provided for @moodAudioRecorded.
  ///
  /// In zh, this message translates to:
  /// **'已录 {duration}'**
  String moodAudioRecorded(Object duration);

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

  /// No description provided for @refillManageMedsList.
  ///
  /// In zh, this message translates to:
  /// **'药物列表'**
  String get refillManageMedsList;

  /// No description provided for @refillManageSummary.
  ///
  /// In zh, this message translates to:
  /// **'续方汇总'**
  String get refillManageSummary;

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
      Object date, Object suffix, int reminderDays);

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
  String assessmentQuestionLabel(int index, Object text, Object selected);

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
  String homeHeaderKeepGoing(Object name);

  /// No description provided for @ventSwipeHint.
  ///
  /// In zh, this message translates to:
  /// **'左滑或长按条目可删除'**
  String get ventSwipeHint;

  /// No description provided for @homeStreakRestart.
  ///
  /// In zh, this message translates to:
  /// **'今天重新开始 🌱'**
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
  /// **'已坚持 {days} 天 🌳'**
  String homeStreakGreat(int days);

  /// No description provided for @homeStreakAmazing.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天连击 🌲'**
  String homeStreakAmazing(int days);

  /// No description provided for @homeStreakMaster.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天 🏔️'**
  String homeStreakMaster(int days);

  /// No description provided for @navMood.
  ///
  /// In zh, this message translates to:
  /// **'心情'**
  String get navMood;

  /// No description provided for @navVent.
  ///
  /// In zh, this message translates to:
  /// **'树洞'**
  String get navVent;

  /// No description provided for @navTrend.
  ///
  /// In zh, this message translates to:
  /// **'趋势'**
  String get navTrend;

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
  String errorPageNotFound(Object path);

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
  /// **'稳定期 ／ 月度覆盘'**
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
  String assessmentAverageScore(Object score);

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
  /// **'几乎没有'**
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

  /// No description provided for @setupPresetTitle.
  ///
  /// In zh, this message translates to:
  /// **'📋 选择预置方案'**
  String get setupPresetTitle;

  /// No description provided for @setupPresetDescription.
  ///
  /// In zh, this message translates to:
  /// **'预置方案会填好药名 + 时间，您可以接著改。最终服药请按医嘱核对。'**
  String get setupPresetDescription;

  /// No description provided for @setupPresetLoaded.
  ///
  /// In zh, this message translates to:
  /// **'已载入：{name}（{count} 个药）请核对药名和剂量'**
  String setupPresetLoaded(Object name, int count);

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

  /// No description provided for @reportHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有报告历史\n生成一次报告后会自动记录'**
  String get reportHistoryEmpty;

  /// No description provided for @reportHistoryItemTitle.
  ///
  /// In zh, this message translates to:
  /// **'{date} · 近 {days} 天'**
  String reportHistoryItemTitle(Object date, int days);

  /// No description provided for @reportHistoryItemPatient.
  ///
  /// In zh, this message translates to:
  /// **'患者：{name}'**
  String reportHistoryItemPatient(Object name);

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
  /// **'已记录！{days} 天 🏔️'**
  String homeCelebrationStreakMaster(int days);

  /// No description provided for @homeAutofireCelebration.
  ///
  /// In zh, this message translates to:
  /// **'已打卡：{name} ✅'**
  String homeAutofireCelebration(Object name);

  /// No description provided for @homeAutofireFallbackName.
  ///
  /// In zh, this message translates to:
  /// **'该药'**
  String get homeAutofireFallbackName;

  /// No description provided for @homeMedHint.
  ///
  /// In zh, this message translates to:
  /// **'💊 准备打卡药物 {name}'**
  String homeMedHint(String name);

  /// No description provided for @homeSnoozeTitle.
  ///
  /// In zh, this message translates to:
  /// **'⏰ 该打卡了（5min 后）'**
  String get homeSnoozeTitle;

  /// Android 通知 channel 名 (medication) — v0.27 R77 修 (R76-N1): 之前 const 硬編碼中文， en/zh_Hant 系統設置看中文
  ///
  /// In zh, this message translates to:
  /// **'吃药提醒'**
  String get notifChannelMedicationName;

  /// Android 通知 channel 描述 (medication) — v0.27 R77 修 (R76-N1)
  ///
  /// In zh, this message translates to:
  /// **'到点提醒你吃药打卡'**
  String get notifChannelMedicationDesc;

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
  String themeTooltip(Object mode);

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
  /// **'你撤回了「趋势分析」同意（PIPL §14）。趋势数据未删除， 重新开启后即可恢复。'**
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
  String trendMoodEntriesSame(int count, Object emoji);

  /// No description provided for @trendMoodEntriesRange.
  ///
  /// In zh, this message translates to:
  /// **'情绪 {count} 条 · {lowEmoji}→{highEmoji}'**
  String trendMoodEntriesRange(int count, Object lowEmoji, Object highEmoji);

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

  /// No description provided for @trendCbtReratedChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'重评效果'**
  String get trendCbtReratedChartTitle;

  /// No description provided for @trendCbtReratedEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有 5/7 栏 CBT 数据'**
  String get trendCbtReratedEmptyTitle;

  /// No description provided for @trendCbtReratedEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'先用 5/7 栏 CBT 填表， 才能看到重评效果'**
  String get trendCbtReratedEmptyHint;

  /// No description provided for @contactConsentReject.
  ///
  /// In zh, this message translates to:
  /// **'暂不同意'**
  String get contactConsentReject;

  /// No description provided for @dataExportConsentTitle.
  ///
  /// In zh, this message translates to:
  /// **'数据导出同意'**
  String get dataExportConsentTitle;

  /// PIPL §13 數據可攜權 dialog 正文， 用戶導出 JSON 前取得單獨同意 (R82 加）
  ///
  /// In zh, this message translates to:
  /// **'您即将导出本地数据库中的所有数据。\n\n**目的**：{purpose}\n**数据范围**：{dataCategories}\n**保留方式**：{retention}\n\n**根据《个人信息保护法》第 13 条**（数据可携权 + 单独同意），请确认您已了解上述用途，并同意本次导出。'**
  String dataExportConsentBody(
      Object purpose, Object dataCategories, Object retention);

  /// No description provided for @dataExportConsentConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我了解并同意导出'**
  String get dataExportConsentConfirm;

  /// No description provided for @dataExportConsentVersion.
  ///
  /// In zh, this message translates to:
  /// **'v1 · 2026-08-15'**
  String get dataExportConsentVersion;

  /// 1.1.0 round 6d: vent/analytics fallback 中性标题 (不再复用联系人 §13 措辞)
  ///
  /// In zh, this message translates to:
  /// **'知情同意'**
  String get consentDialogGenericTitle;

  /// 1.1.0 round 6d: vent/analytics fallback 中性同意按钮
  ///
  /// In zh, this message translates to:
  /// **'我已了解并同意'**
  String get consentDialogGenericAgree;

  /// 1.1.0 round 6d: vent/analytics fallback 中性拒绝按钮
  ///
  /// In zh, this message translates to:
  /// **'暂不同意'**
  String get consentDialogGenericReject;

  /// 1.1.0 round 6d: vent/analytics fallback 同意留痕版本脚注
  ///
  /// In zh, this message translates to:
  /// **'v1 · 2026-08-15'**
  String get consentDialogGenericVersion;

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
  String editMedSaveFailed(Object error);

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
  String editMedStoppedDate(Object date);

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

  /// No description provided for @tempMedNoLink.
  ///
  /// In zh, this message translates to:
  /// **'不关联'**
  String get tempMedNoLink;

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

  /// No description provided for @medsCalendarWindowTitle.
  ///
  /// In zh, this message translates to:
  /// **'时间窗口'**
  String get medsCalendarWindowTitle;

  /// No description provided for @medsCalendarLoadCheckinFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载打卡失败：{error}'**
  String medsCalendarLoadCheckinFailed(Object error);

  /// No description provided for @medsCalendarLoadMedFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载药物失败：{error}'**
  String medsCalendarLoadMedFailed(Object error);

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

  /// No description provided for @medsCalendarLegendTitle.
  ///
  /// In zh, this message translates to:
  /// **'图例'**
  String get medsCalendarLegendTitle;

  /// No description provided for @medsCalendarLegendMissed.
  ///
  /// In zh, this message translates to:
  /// **'漏服'**
  String get medsCalendarLegendMissed;

  /// No description provided for @medsCalendarDayDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'{date} 的打卡'**
  String medsCalendarDayDetailTitle(String date);

  /// No description provided for @medsCalendarDayDetailEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当天还没有打卡'**
  String get medsCalendarDayDetailEmpty;

  /// No description provided for @medCalendarBackfillConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认补打卡'**
  String get medCalendarBackfillConfirm;

  /// v0.32 round 8 (R111-03): 用药日历 补打卡成功 SnackBar
  ///
  /// In zh, this message translates to:
  /// **'已补打卡 {date}'**
  String medCalendarBackfillSuccess(Object date);

  /// No description provided for @medsCalendarDayDetailAddLog.
  ///
  /// In zh, this message translates to:
  /// **'补打卡'**
  String get medsCalendarDayDetailAddLog;

  /// No description provided for @medsCalendarDayDetailAddLogHint.
  ///
  /// In zh, this message translates to:
  /// **'为今天补一次服药记录'**
  String get medsCalendarDayDetailAddLogHint;

  /// No description provided for @medsCalendarDayDetailLogItem.
  ///
  /// In zh, this message translates to:
  /// **'{time} · {name}'**
  String medsCalendarDayDetailLogItem(String time, String name);

  /// No description provided for @medsCalendarLegendPartial.
  ///
  /// In zh, this message translates to:
  /// **'< 50%'**
  String get medsCalendarLegendPartial;

  /// No description provided for @medsCalendarLegendAlmost.
  ///
  /// In zh, this message translates to:
  /// **'< 100%'**
  String get medsCalendarLegendAlmost;

  /// No description provided for @medsCalendarLegendFull.
  ///
  /// In zh, this message translates to:
  /// **'100%'**
  String get medsCalendarLegendFull;

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

  /// No description provided for @snackbarActionCheckin.
  ///
  /// In zh, this message translates to:
  /// **'打卡'**
  String get snackbarActionCheckin;

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

  /// No description provided for @medicationDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除药物'**
  String get medicationDeleted;

  /// 情绪分数 1/5 的本地化标签 (R112-07 emil metadata 补)
  ///
  /// In zh, this message translates to:
  /// **'很差'**
  String get moodLabel1;

  /// 情绪分数 2/5 的本地化标签 (R112-07 emil metadata 补)
  ///
  /// In zh, this message translates to:
  /// **'差'**
  String get moodLabel2;

  /// 情绪分数 3/5 的本地化标签 (R112-07 emil metadata 补)
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get moodLabel3;

  /// 情绪分数 4/5 的本地化标签 (R112-07 emil metadata 补)
  ///
  /// In zh, this message translates to:
  /// **'好'**
  String get moodLabel4;

  /// 情绪分数 5/5 的本地化标签 (R112-07 emil metadata 补)
  ///
  /// In zh, this message translates to:
  /// **'很好'**
  String get moodLabel5;

  /// No description provided for @medReportFileName.
  ///
  /// In zh, this message translates to:
  /// **'用药报告_{date}'**
  String medReportFileName(Object date);

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

  /// No description provided for @dayDetailCheckInWith.
  ///
  /// In zh, this message translates to:
  /// **'打卡 · {name}'**
  String dayDetailCheckInWith(Object name);

  /// No description provided for @dayDetailDailyCheckIn.
  ///
  /// In zh, this message translates to:
  /// **'每日打卡'**
  String get dayDetailDailyCheckIn;

  /// No description provided for @dayDetailTempWith.
  ///
  /// In zh, this message translates to:
  /// **'临时 · {name}'**
  String dayDetailTempWith(Object name);

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

  /// No description provided for @scaleHotlineCn.
  ///
  /// In zh, this message translates to:
  /// **'全国 24 小时心理援助热线'**
  String get scaleHotlineCn;

  /// No description provided for @scaleHotlineCn2.
  ///
  /// In zh, this message translates to:
  /// **'北京心理危机研究与干预中心'**
  String get scaleHotlineCn2;

  /// No description provided for @scaleHotlineUs.
  ///
  /// In zh, this message translates to:
  /// **'988 Suicide & Crisis Lifeline (US)'**
  String get scaleHotlineUs;

  /// No description provided for @scaleHotlineUs2.
  ///
  /// In zh, this message translates to:
  /// **'Crisis Text Line (text HOME to 741741)'**
  String get scaleHotlineUs2;

  /// No description provided for @scaleHotlineHk.
  ///
  /// In zh, this message translates to:
  /// **'撒玛利亚防止自杀会（24h 多语言）'**
  String get scaleHotlineHk;

  /// No description provided for @scaleHotlineTw.
  ///
  /// In zh, this message translates to:
  /// **'生命线（24h）'**
  String get scaleHotlineTw;

  /// No description provided for @scaleHotlineTw2.
  ///
  /// In zh, this message translates to:
  /// **'安心专线（心理咨商）'**
  String get scaleHotlineTw2;

  /// No description provided for @scaleHotlineSg.
  ///
  /// In zh, this message translates to:
  /// **'Samaritans of Singapore (24h)'**
  String get scaleHotlineSg;

  /// No description provided for @scaleHotlineUk.
  ///
  /// In zh, this message translates to:
  /// **'Samaritans UK & ROI (24h 免费)'**
  String get scaleHotlineUk;

  /// No description provided for @scaleHotlineIntl.
  ///
  /// In zh, this message translates to:
  /// **'国际通用 · 请联系当地急救或心理援助'**
  String get scaleHotlineIntl;

  /// PHQ-9 第 9 題陽性時彈窗的標題（'我們關心你'）
  ///
  /// In zh, this message translates to:
  /// **'我们关心你'**
  String get scaleCrisisTitle;

  /// PHQ-9 第 9 題陽性時彈窗的正文， 含換行
  ///
  /// In zh, this message translates to:
  /// **'你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。'**
  String get scaleCrisisMessage;

  /// No description provided for @phq9Item0.
  ///
  /// In zh, this message translates to:
  /// **'做事时提不起劲或没有兴趣'**
  String get phq9Item0;

  /// No description provided for @phq9Item1.
  ///
  /// In zh, this message translates to:
  /// **'感到心情低落、沮丧或绝望'**
  String get phq9Item1;

  /// No description provided for @phq9Item2.
  ///
  /// In zh, this message translates to:
  /// **'入睡困难、睡不安稳或睡得过多'**
  String get phq9Item2;

  /// No description provided for @phq9Item3.
  ///
  /// In zh, this message translates to:
  /// **'感觉疲倦或没有活力'**
  String get phq9Item3;

  /// No description provided for @phq9Item4.
  ///
  /// In zh, this message translates to:
  /// **'食欲不振或吃太多'**
  String get phq9Item4;

  /// No description provided for @phq9Item5.
  ///
  /// In zh, this message translates to:
  /// **'觉得自己很糟、很失败，或让自己和家人失望'**
  String get phq9Item5;

  /// No description provided for @phq9Item6.
  ///
  /// In zh, this message translates to:
  /// **'对事物专注有困难，例如看报纸或看电视时'**
  String get phq9Item6;

  /// No description provided for @phq9Item7.
  ///
  /// In zh, this message translates to:
  /// **'动作或说话速度缓慢到别人能察觉？\n或正好相反——烦躁或坐立不安'**
  String get phq9Item7;

  /// No description provided for @phq9Item8.
  ///
  /// In zh, this message translates to:
  /// **'有不如死掉或用某种方式伤害自己的念头'**
  String get phq9Item8;

  /// No description provided for @phq9Option0.
  ///
  /// In zh, this message translates to:
  /// **'完全不会'**
  String get phq9Option0;

  /// No description provided for @phq9Option1.
  ///
  /// In zh, this message translates to:
  /// **'好几天'**
  String get phq9Option1;

  /// No description provided for @phq9Option2.
  ///
  /// In zh, this message translates to:
  /// **'一半以上的天数'**
  String get phq9Option2;

  /// No description provided for @phq9Option3.
  ///
  /// In zh, this message translates to:
  /// **'几乎每天'**
  String get phq9Option3;

  /// No description provided for @phq9SeverityLabel0.
  ///
  /// In zh, this message translates to:
  /// **'几乎没有抑郁'**
  String get phq9SeverityLabel0;

  /// No description provided for @phq9SeverityLabel1.
  ///
  /// In zh, this message translates to:
  /// **'轻度抑郁'**
  String get phq9SeverityLabel1;

  /// No description provided for @phq9SeverityLabel2.
  ///
  /// In zh, this message translates to:
  /// **'中度抑郁'**
  String get phq9SeverityLabel2;

  /// No description provided for @phq9SeverityLabel3.
  ///
  /// In zh, this message translates to:
  /// **'中重度抑郁'**
  String get phq9SeverityLabel3;

  /// No description provided for @phq9SeverityLabel4.
  ///
  /// In zh, this message translates to:
  /// **'重度抑郁'**
  String get phq9SeverityLabel4;

  /// No description provided for @phq9SeveritySummary0.
  ///
  /// In zh, this message translates to:
  /// **'几乎没有抑郁倾向'**
  String get phq9SeveritySummary0;

  /// No description provided for @phq9SeveritySummary1.
  ///
  /// In zh, this message translates to:
  /// **'轻度抑郁倾向'**
  String get phq9SeveritySummary1;

  /// No description provided for @phq9SeveritySummary2.
  ///
  /// In zh, this message translates to:
  /// **'中度抑郁倾向'**
  String get phq9SeveritySummary2;

  /// No description provided for @phq9SeveritySummary3.
  ///
  /// In zh, this message translates to:
  /// **'中重度抑郁倾向'**
  String get phq9SeveritySummary3;

  /// No description provided for @phq9SeveritySummary4.
  ///
  /// In zh, this message translates to:
  /// **'重度抑郁倾向'**
  String get phq9SeveritySummary4;

  /// No description provided for @phq9Instruction.
  ///
  /// In zh, this message translates to:
  /// **'过去两周内，你有多经常被以下问题困扰？'**
  String get phq9Instruction;

  /// No description provided for @phq9ShortDescription.
  ///
  /// In zh, this message translates to:
  /// **'过去两周的抑郁倾向筛查'**
  String get phq9ShortDescription;

  /// No description provided for @gad7Item0.
  ///
  /// In zh, this message translates to:
  /// **'感到紧张、焦虑或急切'**
  String get gad7Item0;

  /// No description provided for @gad7Item1.
  ///
  /// In zh, this message translates to:
  /// **'不能停止或控制担忧'**
  String get gad7Item1;

  /// No description provided for @gad7Item2.
  ///
  /// In zh, this message translates to:
  /// **'对各种事情担忧过多'**
  String get gad7Item2;

  /// No description provided for @gad7Item3.
  ///
  /// In zh, this message translates to:
  /// **'难以放松'**
  String get gad7Item3;

  /// No description provided for @gad7Item4.
  ///
  /// In zh, this message translates to:
  /// **'心情烦躁以至坐不住'**
  String get gad7Item4;

  /// No description provided for @gad7Item5.
  ///
  /// In zh, this message translates to:
  /// **'变得容易烦恼或急躁'**
  String get gad7Item5;

  /// No description provided for @gad7Item6.
  ///
  /// In zh, this message translates to:
  /// **'感到似乎将有可怕的事情发生而害怕'**
  String get gad7Item6;

  /// No description provided for @gad7SeverityLabel0.
  ///
  /// In zh, this message translates to:
  /// **'几乎没有焦虑'**
  String get gad7SeverityLabel0;

  /// No description provided for @gad7SeverityLabel1.
  ///
  /// In zh, this message translates to:
  /// **'轻度焦虑'**
  String get gad7SeverityLabel1;

  /// No description provided for @gad7SeverityLabel2.
  ///
  /// In zh, this message translates to:
  /// **'中度焦虑'**
  String get gad7SeverityLabel2;

  /// No description provided for @gad7SeverityLabel3.
  ///
  /// In zh, this message translates to:
  /// **'重度焦虑'**
  String get gad7SeverityLabel3;

  /// No description provided for @gad7SeveritySummary0.
  ///
  /// In zh, this message translates to:
  /// **'几乎没有焦虑倾向'**
  String get gad7SeveritySummary0;

  /// No description provided for @gad7SeveritySummary1.
  ///
  /// In zh, this message translates to:
  /// **'轻度焦虑倾向'**
  String get gad7SeveritySummary1;

  /// No description provided for @gad7SeveritySummary2.
  ///
  /// In zh, this message translates to:
  /// **'中度焦虑倾向'**
  String get gad7SeveritySummary2;

  /// No description provided for @gad7SeveritySummary3.
  ///
  /// In zh, this message translates to:
  /// **'重度焦虑倾向'**
  String get gad7SeveritySummary3;

  /// No description provided for @gad7Instruction.
  ///
  /// In zh, this message translates to:
  /// **'过去两周内，你有多经常被以下问题困扰？'**
  String get gad7Instruction;

  /// No description provided for @gad7ShortDescription.
  ///
  /// In zh, this message translates to:
  /// **'过去两周的焦虑倾向筛查'**
  String get gad7ShortDescription;

  /// No description provided for @homeFabVent.
  ///
  /// In zh, this message translates to:
  /// **'树洞'**
  String get homeFabVent;

  /// No description provided for @homeMoodHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'今日心情'**
  String get homeMoodHeroTitle;

  /// No description provided for @homeMoodHeroRecord.
  ///
  /// In zh, this message translates to:
  /// **'记录心情'**
  String get homeMoodHeroRecord;

  /// No description provided for @homeMoodHeroReview.
  ///
  /// In zh, this message translates to:
  /// **'回顾'**
  String get homeMoodHeroReview;

  /// No description provided for @homeMoodHeroViewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get homeMoodHeroViewAll;

  /// No description provided for @homeMoodHeroNoData.
  ///
  /// In zh, this message translates to:
  /// **'今天还没记录心情'**
  String get homeMoodHeroNoData;

  /// 1.1.0 round 5b: 情绪大卡上次记录时间 (Task 12)
  ///
  /// In zh, this message translates to:
  /// **'上次记录 {time}'**
  String homeMoodHeroLastRecorded(String time);

  /// No description provided for @homeVentHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'树洞'**
  String get homeVentHeroTitle;

  /// No description provided for @homeVentHeroWrite.
  ///
  /// In zh, this message translates to:
  /// **'写心事'**
  String get homeVentHeroWrite;

  /// No description provided for @homeVentHeroNoData.
  ///
  /// In zh, this message translates to:
  /// **'还没有倾诉, 写第一条心事'**
  String get homeVentHeroNoData;

  /// No description provided for @homeActionMoodReview.
  ///
  /// In zh, this message translates to:
  /// **'情绪回顾'**
  String get homeActionMoodReview;

  /// No description provided for @homeActionDailyTracking.
  ///
  /// In zh, this message translates to:
  /// **'日常追踪'**
  String get homeActionDailyTracking;

  /// No description provided for @homeActionTips.
  ///
  /// In zh, this message translates to:
  /// **'心理技巧'**
  String get homeActionTips;

  /// No description provided for @homeActionTipsSub.
  ///
  /// In zh, this message translates to:
  /// **'5 个小练习 · 当下可学'**
  String get homeActionTipsSub;

  /// v1.1.0 round 11 (R115 视觉重构): 情绪回顾快捷操作副标题
  ///
  /// In zh, this message translates to:
  /// **'本周 {count} 次记录 · 均分 {avg}'**
  String homeActionMoodReviewSub(int count, String avg);

  /// No description provided for @homeActionDailyTrackingSub.
  ///
  /// In zh, this message translates to:
  /// **'睡眠 / 体重 / 社交节律'**
  String get homeActionDailyTrackingSub;

  /// No description provided for @homeMoreEntryTitle.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get homeMoreEntryTitle;

  /// No description provided for @homeMoreEntrySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用药 · 量表 · 危机热线'**
  String get homeMoreEntrySubtitle;

  /// No description provided for @homeMoreSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'更多入口'**
  String get homeMoreSheetTitle;

  /// No description provided for @homeMoreMedication.
  ///
  /// In zh, this message translates to:
  /// **'用药管理'**
  String get homeMoreMedication;

  /// v1.1.0 round 11 (R115): BottomSheet 用药管理副标题
  ///
  /// In zh, this message translates to:
  /// **'{total} 种药物 · 今日 {done}/{total} 已服'**
  String homeMoreMedicationSub(int total, int done);

  /// No description provided for @homeMoreAssessment.
  ///
  /// In zh, this message translates to:
  /// **'心理评估'**
  String get homeMoreAssessment;

  /// v1.1.0 round 11 (R115): BottomSheet 心理评估副标题
  ///
  /// In zh, this message translates to:
  /// **'{count} 个量表'**
  String homeMoreAssessmentSub(int count);

  /// No description provided for @homeMoreCrisis.
  ///
  /// In zh, this message translates to:
  /// **'危机热线'**
  String get homeMoreCrisis;

  /// No description provided for @homeMoreCrisisSub.
  ///
  /// In zh, this message translates to:
  /// **'5 区域 · 一键拨打'**
  String get homeMoreCrisisSub;

  /// No description provided for @homeMoreWorry.
  ///
  /// In zh, this message translates to:
  /// **'烦恼闭环'**
  String get homeMoreWorry;

  /// v1.1.0 round 11 (R115): BottomSheet 烦恼闭环副标题
  ///
  /// In zh, this message translates to:
  /// **'进行中 {active} · 已闭环 {closed}'**
  String homeMoreWorrySub(int active, int closed);

  /// No description provided for @homeTodayOverview.
  ///
  /// In zh, this message translates to:
  /// **'今日概览'**
  String get homeTodayOverview;

  /// No description provided for @todaySummarySleep.
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get todaySummarySleep;

  /// No description provided for @todaySummaryWorry.
  ///
  /// In zh, this message translates to:
  /// **'烦恼'**
  String get todaySummaryWorry;

  /// No description provided for @homeFabHotline.
  ///
  /// In zh, this message translates to:
  /// **'紧急热线'**
  String get homeFabHotline;

  /// No description provided for @homeFabTop.
  ///
  /// In zh, this message translates to:
  /// **'回到顶端'**
  String get homeFabTop;

  /// No description provided for @trendChip30Day.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get trendChip30Day;

  /// No description provided for @crisisHotlineCnLabel.
  ///
  /// In zh, this message translates to:
  /// **'全国 24 小时心理援助热线'**
  String get crisisHotlineCnLabel;

  /// No description provided for @crisisHotlineCnNumber.
  ///
  /// In zh, this message translates to:
  /// **'400-161-9995'**
  String get crisisHotlineCnNumber;

  /// No description provided for @crisisHotlineCnDesc.
  ///
  /// In zh, this message translates to:
  /// **'中国大陆 24 小时免费'**
  String get crisisHotlineCnDesc;

  /// No description provided for @crisisHotlineTwLabel.
  ///
  /// In zh, this message translates to:
  /// **'安心专线 (24 小时）'**
  String get crisisHotlineTwLabel;

  /// No description provided for @crisisHotlineTwNumber.
  ///
  /// In zh, this message translates to:
  /// **'1925'**
  String get crisisHotlineTwNumber;

  /// No description provided for @crisisHotlineTwDesc.
  ///
  /// In zh, this message translates to:
  /// **'中国台湾 24 小时心理咨商'**
  String get crisisHotlineTwDesc;

  /// No description provided for @crisisHotlineHkLabel.
  ///
  /// In zh, this message translates to:
  /// **'撒玛利亚防止自杀会 (24 小时）'**
  String get crisisHotlineHkLabel;

  /// No description provided for @crisisHotlineHkNumber.
  ///
  /// In zh, this message translates to:
  /// **'2389 2222'**
  String get crisisHotlineHkNumber;

  /// No description provided for @crisisHotlineHkDesc.
  ///
  /// In zh, this message translates to:
  /// **'中国香港 24 小时多语言'**
  String get crisisHotlineHkDesc;

  /// No description provided for @crisisHotlineMoLabel.
  ///
  /// In zh, this message translates to:
  /// **'明爱生命热线 (24 小时）'**
  String get crisisHotlineMoLabel;

  /// No description provided for @crisisHotlineMoNumber.
  ///
  /// In zh, this message translates to:
  /// **'2826 1122'**
  String get crisisHotlineMoNumber;

  /// No description provided for @crisisHotlineMoDesc.
  ///
  /// In zh, this message translates to:
  /// **'中国澳门 24 小时'**
  String get crisisHotlineMoDesc;

  /// v0.30 round 92 (audit-fixes / P0 #12): crisis_hotline_page 標題
  ///
  /// In zh, this message translates to:
  /// **'紧急心理援助热线'**
  String get crisisHotlineTitle;

  /// v0.30 round 92 (audit-fixes / P0 #12): crisis_hotline_page 副標題
  ///
  /// In zh, this message translates to:
  /// **'如果你或身边的人正在经历心理危机， 请拨打以下热线'**
  String get crisisHotlineSubtitle;

  /// v0.30 round 92 (audit-fixes / P0 #12): 800-810-1117 24h 免費
  ///
  /// In zh, this message translates to:
  /// **'全国 24 小时免费心理援助热线'**
  String get crisisHotlineCn2Label;

  /// No description provided for @crisisHotlineCn2Number.
  ///
  /// In zh, this message translates to:
  /// **'800-810-1117'**
  String get crisisHotlineCn2Number;

  /// No description provided for @crisisHotlineCn2Desc.
  ///
  /// In zh, this message translates to:
  /// **'中国大陆 24 小时免费拨打'**
  String get crisisHotlineCn2Desc;

  /// v0.30 round 92 (audit-fixes / P0 #12): US 988 Lifeline
  ///
  /// In zh, this message translates to:
  /// **'988 Suicide & Crisis Lifeline'**
  String get crisisHotlineUsLabel;

  /// No description provided for @crisisHotlineUsNumber.
  ///
  /// In zh, this message translates to:
  /// **'988'**
  String get crisisHotlineUsNumber;

  /// No description provided for @crisisHotlineUsDesc.
  ///
  /// In zh, this message translates to:
  /// **'美国 / 加拿大 24 小时英文 / 西班牙文'**
  String get crisisHotlineUsDesc;

  /// v0.30 round 92 (audit-fixes / P0 #12): 國際通用 fallback
  ///
  /// In zh, this message translates to:
  /// **'国际通用'**
  String get crisisHotlineIntlLabel;

  /// No description provided for @crisisHotlineIntlDesc.
  ///
  /// In zh, this message translates to:
  /// **'请联系当地急救或心理援助机构'**
  String get crisisHotlineIntlDesc;

  /// v0.30 round 92: 國際通用緊急號碼
  ///
  /// In zh, this message translates to:
  /// **'112 / 911'**
  String get crisisHotlineIntlNumber;

  /// v0.30 round 92: crisis_hotline_page 5 地區 section title
  ///
  /// In zh, this message translates to:
  /// **'中国大陆'**
  String get crisisHotlineRegionCn;

  /// No description provided for @crisisHotlineRegionTw.
  ///
  /// In zh, this message translates to:
  /// **'中国台湾'**
  String get crisisHotlineRegionTw;

  /// No description provided for @crisisHotlineRegionHk.
  ///
  /// In zh, this message translates to:
  /// **'中国香港'**
  String get crisisHotlineRegionHk;

  /// No description provided for @crisisHotlineRegionUs.
  ///
  /// In zh, this message translates to:
  /// **'美国 / 加拿大'**
  String get crisisHotlineRegionUs;

  /// No description provided for @crisisHotlineRegionIntl.
  ///
  /// In zh, this message translates to:
  /// **'国际通用'**
  String get crisisHotlineRegionIntl;

  /// v0.30 round 92: 北京心理危機研究與幹預中心
  ///
  /// In zh, this message translates to:
  /// **'北京心理危机研究与干预中心'**
  String get crisisHotlineCnBeijingLabel;

  /// No description provided for @crisisHotlineCnBeijingNumber.
  ///
  /// In zh, this message translates to:
  /// **'010-82951332'**
  String get crisisHotlineCnBeijingNumber;

  /// No description provided for @crisisHotlineCnBeijingDesc.
  ///
  /// In zh, this message translates to:
  /// **'北京 24 小时'**
  String get crisisHotlineCnBeijingDesc;

  /// v0.30 round 92: 臺灣生命線 (1995)
  ///
  /// In zh, this message translates to:
  /// **'生命线 (24 小时）'**
  String get crisisHotlineTw1995Label;

  /// No description provided for @crisisHotlineTw1995Number.
  ///
  /// In zh, this message translates to:
  /// **'1995'**
  String get crisisHotlineTw1995Number;

  /// No description provided for @crisisHotlineTw1995Desc.
  ///
  /// In zh, this message translates to:
  /// **'中国台湾 24 小时'**
  String get crisisHotlineTw1995Desc;

  /// v0.30 round 92: US Crisis Text Line (741741)
  ///
  /// In zh, this message translates to:
  /// **'Crisis Text Line (text HOME)'**
  String get crisisHotlineUsTextLineLabel;

  /// No description provided for @crisisHotlineUsTextLineNumber.
  ///
  /// In zh, this message translates to:
  /// **'741741'**
  String get crisisHotlineUsTextLineNumber;

  /// No description provided for @crisisHotlineUsTextLineDesc.
  ///
  /// In zh, this message translates to:
  /// **'美国 24 小时短信'**
  String get crisisHotlineUsTextLineDesc;

  /// v0.30 round 92: 複製號碼後 snackbar 提示
  ///
  /// In zh, this message translates to:
  /// **'已复制： {number}'**
  String crisisHotlineSnackbarCopied(Object number);

  /// R97-P1-11 (2026-08-07): 危機熱線撥打按鈕 tooltip
  ///
  /// In zh, this message translates to:
  /// **'拨打'**
  String get crisisHotlineDialTooltip;

  /// R97-P1-11 (2026-08-07): 危機熱線複製按鈕 tooltip
  ///
  /// In zh, this message translates to:
  /// **'复制号码'**
  String get crisisHotlineCopyTooltip;

  /// R97-P1-11 (2026-08-07): tel: intent 啟動失敗 snackbar 提示
  ///
  /// In zh, this message translates to:
  /// **'无法启动拨号， 请手动拨打： {number}'**
  String crisisHotlineDialFailed(Object number);

  /// No description provided for @setupLegalAgeAttestation.
  ///
  /// In zh, this message translates to:
  /// **'本人郑重承诺：我已年满 18 周岁。如本人为 14-18 周岁，本人保证已取得监护人代为同意，并愿意承担虚假陈述的一切法律后果。'**
  String get setupLegalAgeAttestation;

  /// No description provided for @moodCbtLevelLabel3.
  ///
  /// In zh, this message translates to:
  /// **'3 栏'**
  String get moodCbtLevelLabel3;

  /// No description provided for @moodCbtLevelLabel5.
  ///
  /// In zh, this message translates to:
  /// **'5 栏'**
  String get moodCbtLevelLabel5;

  /// No description provided for @moodCbtLevelLabel7.
  ///
  /// In zh, this message translates to:
  /// **'7 栏'**
  String get moodCbtLevelLabel7;

  /// No description provided for @moodCbtExpandExplain.
  ///
  /// In zh, this message translates to:
  /// **'什么是 CBT 思维记录？'**
  String get moodCbtExpandExplain;

  /// No description provided for @moodCbtSectionSituation.
  ///
  /// In zh, this message translates to:
  /// **'情境'**
  String get moodCbtSectionSituation;

  /// No description provided for @moodCbtSectionAutomaticThought.
  ///
  /// In zh, this message translates to:
  /// **'自动思维'**
  String get moodCbtSectionAutomaticThought;

  /// No description provided for @moodCbtSectionEvidenceFor.
  ///
  /// In zh, this message translates to:
  /// **'支持证据'**
  String get moodCbtSectionEvidenceFor;

  /// No description provided for @moodCbtSectionEvidenceAgainst.
  ///
  /// In zh, this message translates to:
  /// **'反对证据'**
  String get moodCbtSectionEvidenceAgainst;

  /// No description provided for @moodCbtSectionAlternative.
  ///
  /// In zh, this message translates to:
  /// **'替代思维'**
  String get moodCbtSectionAlternative;

  /// No description provided for @moodCbtSectionRerated.
  ///
  /// In zh, this message translates to:
  /// **'重新评分'**
  String get moodCbtSectionRerated;

  /// No description provided for @moodCbtSectionCoreBelief.
  ///
  /// In zh, this message translates to:
  /// **'核心信念'**
  String get moodCbtSectionCoreBelief;

  /// No description provided for @moodCbtSectionBehavior.
  ///
  /// In zh, this message translates to:
  /// **'行为应对'**
  String get moodCbtSectionBehavior;

  /// No description provided for @moodCbtExplainerBody.
  ///
  /// In zh, this message translates to:
  /// **'CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准：先记录情境与想法，再找证据支持／反对，最后写下更平衡的替代想法。'**
  String get moodCbtExplainerBody;

  /// No description provided for @moodCbtFieldHintSituation.
  ///
  /// In zh, this message translates to:
  /// **'触发这个想法的事件是什么？发生在哪里、什么时候、有谁？'**
  String get moodCbtFieldHintSituation;

  /// No description provided for @moodCbtFieldHintAutomaticThought.
  ///
  /// In zh, this message translates to:
  /// **'那一瞬间脑中闪过的想法、印象或意象是什么？'**
  String get moodCbtFieldHintAutomaticThought;

  /// No description provided for @moodCbtFieldHintEvidenceFor.
  ///
  /// In zh, this message translates to:
  /// **'什么事支持这个想法？'**
  String get moodCbtFieldHintEvidenceFor;

  /// No description provided for @moodCbtFieldHintEvidenceAgainst.
  ///
  /// In zh, this message translates to:
  /// **'什么事不支持这个想法？'**
  String get moodCbtFieldHintEvidenceAgainst;

  /// No description provided for @moodCbtFieldHintAlternative.
  ///
  /// In zh, this message translates to:
  /// **'如果你的好朋友遇到这事，你会怎么想？'**
  String get moodCbtFieldHintAlternative;

  /// No description provided for @moodCbtFieldHintCoreBelief.
  ///
  /// In zh, this message translates to:
  /// **'这个想法背后更深层的信念是什么？（如 \"我不够好\"）'**
  String get moodCbtFieldHintCoreBelief;

  /// No description provided for @moodCbtFieldHintBehavior.
  ///
  /// In zh, this message translates to:
  /// **'接下来你打算怎么做？'**
  String get moodCbtFieldHintBehavior;

  /// No description provided for @moodCbtPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'引导问题'**
  String get moodCbtPromptTitle;

  /// No description provided for @moodCbtStepOf.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} 步 / 共 {total} 步'**
  String moodCbtStepOf(int current, int total);

  /// No description provided for @moodCbtReratedComparison.
  ///
  /// In zh, this message translates to:
  /// **'重新评分：{newScore}（原 {oldScore}）'**
  String moodCbtReratedComparison(int newScore, int oldScore);

  /// No description provided for @settingsCbtLevel.
  ///
  /// In zh, this message translates to:
  /// **'思维记录档位'**
  String get settingsCbtLevel;

  /// No description provided for @settingsCbtLevelDescription.
  ///
  /// In zh, this message translates to:
  /// **'选择每次记录情绪时使用的思维记录模板'**
  String get settingsCbtLevelDescription;

  /// No description provided for @settingsCbtLevel3Desc.
  ///
  /// In zh, this message translates to:
  /// **'入门版，1-2 分钟可填完'**
  String get settingsCbtLevel3Desc;

  /// No description provided for @settingsCbtLevel5Desc.
  ///
  /// In zh, this message translates to:
  /// **'标准 Beck 思维记录，含认知重构关键步骤'**
  String get settingsCbtLevel5Desc;

  /// No description provided for @settingsCbtLevel7Desc.
  ///
  /// In zh, this message translates to:
  /// **'深度版，含核心信念识别和行为应对'**
  String get settingsCbtLevel7Desc;

  /// No description provided for @moodCbtScoreReratedLabel.
  ///
  /// In zh, this message translates to:
  /// **'重新评分'**
  String get moodCbtScoreReratedLabel;

  /// No description provided for @moodCbtChipBadge5.
  ///
  /// In zh, this message translates to:
  /// **'CBT 5 栏'**
  String get moodCbtChipBadge5;

  /// No description provided for @moodCbtChipBadge7.
  ///
  /// In zh, this message translates to:
  /// **'CBT 7 栏'**
  String get moodCbtChipBadge7;

  /// No description provided for @moodCbtThreeSituationTitle.
  ///
  /// In zh, this message translates to:
  /// **'发生了什么？'**
  String get moodCbtThreeSituationTitle;

  /// No description provided for @moodCbtThreeAutoTitle.
  ///
  /// In zh, this message translates to:
  /// **'那一刻脑海里闪过什么想法？'**
  String get moodCbtThreeAutoTitle;

  /// No description provided for @moodCbtPrevStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get moodCbtPrevStep;

  /// No description provided for @moodCbtNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get moodCbtNextStep;

  /// No description provided for @moodCbtComplete.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get moodCbtComplete;

  /// No description provided for @moodCbtStep2Header.
  ///
  /// In zh, this message translates to:
  /// **'情绪 + 证据'**
  String get moodCbtStep2Header;

  /// No description provided for @moodCbtConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get moodCbtConfirm;

  /// No description provided for @moodCbtConfirmEmpty.
  ///
  /// In zh, this message translates to:
  /// **'（未填）'**
  String get moodCbtConfirmEmpty;

  /// No description provided for @moodCbtAutoThoughtPrompt0.
  ///
  /// In zh, this message translates to:
  /// **'如果你的好朋友遇到这事，你会怎么劝TA？'**
  String get moodCbtAutoThoughtPrompt0;

  /// No description provided for @moodCbtAutoThoughtPrompt1.
  ///
  /// In zh, this message translates to:
  /// **'最坏／最好／最现实的结果是什么？'**
  String get moodCbtAutoThoughtPrompt1;

  /// No description provided for @moodCbtAutoThoughtPrompt2.
  ///
  /// In zh, this message translates to:
  /// **'一年后你还会这么想吗？'**
  String get moodCbtAutoThoughtPrompt2;

  /// No description provided for @moodCbtAlternativePrompt0.
  ///
  /// In zh, this message translates to:
  /// **'一年后你还会这么想吗？'**
  String get moodCbtAlternativePrompt0;

  /// No description provided for @moodCbtAlternativePrompt1.
  ///
  /// In zh, this message translates to:
  /// **'最现实的结果是什么？'**
  String get moodCbtAlternativePrompt1;

  /// No description provided for @moodCbtBehaviorPrompt0.
  ///
  /// In zh, this message translates to:
  /// **'深呼吸 5 次'**
  String get moodCbtBehaviorPrompt0;

  /// No description provided for @moodCbtBehaviorPrompt1.
  ///
  /// In zh, this message translates to:
  /// **'与信任的人聊聊'**
  String get moodCbtBehaviorPrompt1;

  /// No description provided for @moodCbtBehaviorPrompt2.
  ///
  /// In zh, this message translates to:
  /// **'做 10 分钟正念'**
  String get moodCbtBehaviorPrompt2;

  /// No description provided for @moodListFilterDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get moodListFilterDate;

  /// No description provided for @moodListFilterScore.
  ///
  /// In zh, this message translates to:
  /// **'分数'**
  String get moodListFilterScore;

  /// No description provided for @moodListFilterCbt.
  ///
  /// In zh, this message translates to:
  /// **'CBT 档位'**
  String get moodListFilterCbt;

  /// No description provided for @moodListSortBy.
  ///
  /// In zh, this message translates to:
  /// **'排序'**
  String get moodListSortBy;

  /// No description provided for @moodListSortTimestamp.
  ///
  /// In zh, this message translates to:
  /// **'时间倒序'**
  String get moodListSortTimestamp;

  /// No description provided for @moodListSortScoreAsc.
  ///
  /// In zh, this message translates to:
  /// **'分数升序'**
  String get moodListSortScoreAsc;

  /// No description provided for @moodListSortScoreDesc.
  ///
  /// In zh, this message translates to:
  /// **'分数降序'**
  String get moodListSortScoreDesc;

  /// No description provided for @moodListPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'Mood 历史'**
  String get moodListPageTitle;

  /// No description provided for @moodListSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索 note……'**
  String get moodListSearchHint;

  /// No description provided for @moodListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有 mood 记录'**
  String get moodListEmpty;

  /// No description provided for @moodListNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的记录'**
  String get moodListNoMatch;

  /// mood 列表條目數，佔位 {count}
  ///
  /// In zh, this message translates to:
  /// **'{count} 条记录'**
  String moodListEntryCount(int count);

  /// No description provided for @moodReviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪回顾'**
  String get moodReviewTitle;

  /// No description provided for @moodReviewWeek.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get moodReviewWeek;

  /// No description provided for @moodReviewMonth.
  ///
  /// In zh, this message translates to:
  /// **'月'**
  String get moodReviewMonth;

  /// No description provided for @moodReviewEntriesCount.
  ///
  /// In zh, this message translates to:
  /// **'记录天数'**
  String get moodReviewEntriesCount;

  /// No description provided for @moodReviewAvgScore.
  ///
  /// In zh, this message translates to:
  /// **'平均心情'**
  String get moodReviewAvgScore;

  /// No description provided for @moodReviewDelta.
  ///
  /// In zh, this message translates to:
  /// **'较上期变化'**
  String get moodReviewDelta;

  /// No description provided for @moodReviewDeltaNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无上期数据'**
  String get moodReviewDeltaNoData;

  /// No description provided for @moodReviewTopTags.
  ///
  /// In zh, this message translates to:
  /// **'高频标签'**
  String get moodReviewTopTags;

  /// No description provided for @moodReviewTopFactors.
  ///
  /// In zh, this message translates to:
  /// **'高频影响因素'**
  String get moodReviewTopFactors;

  /// No description provided for @moodReviewPeriod.
  ///
  /// In zh, this message translates to:
  /// **'心境时段'**
  String get moodReviewPeriod;

  /// No description provided for @moodReviewCbtCount.
  ///
  /// In zh, this message translates to:
  /// **'CBT 记录数'**
  String get moodReviewCbtCount;

  /// No description provided for @moodReviewViewTrend.
  ///
  /// In zh, this message translates to:
  /// **'查看趋势图'**
  String get moodReviewViewTrend;

  /// No description provided for @cbtExportPdfEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有 5/7 栏 CBT 数据可导出'**
  String get cbtExportPdfEmpty;

  /// settings 數據管理 — 導出 5/7 欄 CBT 思維記錄為 PDF 的按鈕標題
  ///
  /// In zh, this message translates to:
  /// **'导出 CBT 思维记录 PDF'**
  String get cbtExportPdfButton;

  /// No description provided for @cbtExportPdfDialogTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择日期范围生成 PDF'**
  String get cbtExportPdfDialogTitle;

  /// SnackBar 成功提示， 佔位 {count} 表示實際導出的條數
  ///
  /// In zh, this message translates to:
  /// **'已导出 {count} 条 CBT 思维记录'**
  String cbtExportPdfSuccess(int count);

  /// No description provided for @cbtExportPdfFailed.
  ///
  /// In zh, this message translates to:
  /// **'PDF 导出失败，请重试'**
  String get cbtExportPdfFailed;

  /// Assessment center page title
  ///
  /// In zh, this message translates to:
  /// **'量表中心'**
  String get assessmentCenterTitle;

  /// Last assessment score (placeholder {score} is the numeric total)
  ///
  /// In zh, this message translates to:
  /// **'上次 {score} 分'**
  String assessmentCenterLastScore(int score);

  /// When the last assessment was taken (placeholder {time} is the formatted date)
  ///
  /// In zh, this message translates to:
  /// **'{time} 填写'**
  String assessmentCenterLastTime(Object time);

  /// Empty state for assessment card when user has not yet taken the scale
  ///
  /// In zh, this message translates to:
  /// **'尚未填写过'**
  String get assessmentCenterNoData;

  /// Button on assessment card to start filling the scale
  ///
  /// In zh, this message translates to:
  /// **'开始评估'**
  String get assessmentCenterStartButton;

  /// Multi-line trend chart title showing all scales at once
  ///
  /// In zh, this message translates to:
  /// **'全部量表趋势'**
  String get assessmentCenterMultiLineTitle;

  /// Unavailable scale card reason (NSESSS / CRDPSS)
  ///
  /// In zh, this message translates to:
  /// **'需法务／临床审核'**
  String get assessmentCenterNotAvailable;

  /// Coming soon status label for unavailable scale cards
  ///
  /// In zh, this message translates to:
  /// **'敬请期待'**
  String get assessmentCenterComingSoon;

  /// ISI Insomnia Severity Index scale name
  ///
  /// In zh, this message translates to:
  /// **'ISI 失眠严重指数'**
  String get isiName;

  /// ISI Insomnia Severity Index short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'Morin 1993 失眠严重指数 7 题'**
  String get isiShortDescription;

  /// ISI Insomnia Severity Index top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 2 周内， 您的睡眠问题有多严重？'**
  String get isiInstruction;

  /// ISI Insomnia Severity Index option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get isiOption0;

  /// ISI Insomnia Severity Index option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'轻度'**
  String get isiOption1;

  /// ISI Insomnia Severity Index option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get isiOption2;

  /// ISI Insomnia Severity Index option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'重度'**
  String get isiOption3;

  /// ISI Insomnia Severity Index option 4 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'极重度'**
  String get isiOption4;

  /// ISI Insomnia Severity Index severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无失眠'**
  String get isiSeverityLabel0;

  /// ISI Insomnia Severity Index severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'阈下失眠'**
  String get isiSeverityLabel1;

  /// ISI Insomnia Severity Index severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度失眠'**
  String get isiSeverityLabel2;

  /// ISI Insomnia Severity Index severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度失眠'**
  String get isiSeverityLabel3;

  /// ISI Insomnia Severity Index severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无临床失眠'**
  String get isiSeveritySummary0;

  /// ISI Insomnia Severity Index severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'亚临床失眠， 建议关注'**
  String get isiSeveritySummary1;

  /// ISI Insomnia Severity Index severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度失眠， 建议就医'**
  String get isiSeveritySummary2;

  /// ISI Insomnia Severity Index severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度失眠， 强烈建议就医'**
  String get isiSeveritySummary3;

  /// PSS Perceived Stress Scale scale name
  ///
  /// In zh, this message translates to:
  /// **'PSS 压力量表'**
  String get pssName;

  /// PSS Perceived Stress Scale short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'Cohen 1983 压力量表 (10 题， 含 4 题反向）'**
  String get pssShortDescription;

  /// PSS Perceived Stress Scale top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 1 个月里， 您有多经常有下列感受？'**
  String get pssInstruction;

  /// PSS Perceived Stress Scale option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'从未'**
  String get pssOption0;

  /// PSS Perceived Stress Scale option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几乎不'**
  String get pssOption1;

  /// PSS Perceived Stress Scale option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'有时'**
  String get pssOption2;

  /// PSS Perceived Stress Scale option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'经常'**
  String get pssOption3;

  /// PSS Perceived Stress Scale option 4 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'总是'**
  String get pssOption4;

  /// PSS Perceived Stress Scale severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'低压力'**
  String get pssSeverityLabel0;

  /// PSS Perceived Stress Scale severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度压力'**
  String get pssSeverityLabel1;

  /// PSS Perceived Stress Scale severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'高压力'**
  String get pssSeverityLabel2;

  /// PSS Perceived Stress Scale severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'低压力'**
  String get pssSeveritySummary0;

  /// PSS Perceived Stress Scale severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度压力'**
  String get pssSeveritySummary1;

  /// PSS Perceived Stress Scale severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'高压力， 建议关注和寻求支持'**
  String get pssSeveritySummary2;

  /// WHODAS 2.0 Disability Assessment scale name
  ///
  /// In zh, this message translates to:
  /// **'WHODAS 2.0 残疾评定'**
  String get whodasName;

  /// WHODAS 2.0 Disability Assessment short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'WHO 通用残疾评估 12 题简化版'**
  String get whodasShortDescription;

  /// WHODAS 2.0 Disability Assessment top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 30 天内， 您在以下活动中遇到多大困难？'**
  String get whodasInstruction;

  /// WHODAS 2.0 Disability Assessment option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'没有'**
  String get whodasOption0;

  /// WHODAS 2.0 Disability Assessment option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'轻微'**
  String get whodasOption1;

  /// WHODAS 2.0 Disability Assessment option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get whodasOption2;

  /// WHODAS 2.0 Disability Assessment option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'重度'**
  String get whodasOption3;

  /// WHODAS 2.0 Disability Assessment option 4 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'极重度'**
  String get whodasOption4;

  /// WHODAS 2.0 Disability Assessment severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无残疾'**
  String get whodasSeverityLabel0;

  /// WHODAS 2.0 Disability Assessment severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度残疾'**
  String get whodasSeverityLabel1;

  /// WHODAS 2.0 Disability Assessment severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度残疾'**
  String get whodasSeverityLabel2;

  /// WHODAS 2.0 Disability Assessment severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度残疾'**
  String get whodasSeverityLabel3;

  /// WHODAS 2.0 Disability Assessment severity label rank 4 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'极重度残疾'**
  String get whodasSeverityLabel4;

  /// WHODAS 2.0 Disability Assessment severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无残疾'**
  String get whodasSeveritySummary0;

  /// WHODAS 2.0 Disability Assessment severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度残疾'**
  String get whodasSeveritySummary1;

  /// WHODAS 2.0 Disability Assessment severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度残疾， 建议就医评估'**
  String get whodasSeveritySummary2;

  /// WHODAS 2.0 Disability Assessment severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度残疾， 建议就医'**
  String get whodasSeveritySummary3;

  /// WHODAS 2.0 Disability Assessment severity summary rank 4 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'极重度残疾， 强烈建议就医'**
  String get whodasSeveritySummary4;

  /// DSM-5 Level 2 Depression Severity scale name
  ///
  /// In zh, this message translates to:
  /// **'DSM-5 Level 2 抑郁严重度'**
  String get level2DepressionName;

  /// DSM-5 Level 2 Depression Severity short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版）'**
  String get level2DepressionShortDescription;

  /// DSM-5 Level 2 Depression Severity top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 7 天内， 您有多经常被以下情绪困扰？'**
  String get level2DepressionInstruction;

  /// DSM-5 Level 2 Depression Severity option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'完全没有'**
  String get level2DepressionOption0;

  /// DSM-5 Level 2 Depression Severity option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几天'**
  String get level2DepressionOption1;

  /// DSM-5 Level 2 Depression Severity option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'一半以上的天数'**
  String get level2DepressionOption2;

  /// DSM-5 Level 2 Depression Severity option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几乎每天'**
  String get level2DepressionOption3;

  /// DSM-5 Level 2 Depression Severity severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无抑郁'**
  String get level2DepressionSeverityLabel0;

  /// DSM-5 Level 2 Depression Severity severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度抑郁'**
  String get level2DepressionSeverityLabel1;

  /// DSM-5 Level 2 Depression Severity severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度抑郁'**
  String get level2DepressionSeverityLabel2;

  /// DSM-5 Level 2 Depression Severity severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度抑郁'**
  String get level2DepressionSeverityLabel3;

  /// DSM-5 Level 2 Depression Severity severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无抑郁倾向'**
  String get level2DepressionSeveritySummary0;

  /// DSM-5 Level 2 Depression Severity severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度抑郁倾向'**
  String get level2DepressionSeveritySummary1;

  /// DSM-5 Level 2 Depression Severity severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度抑郁， 建议就医'**
  String get level2DepressionSeveritySummary2;

  /// DSM-5 Level 2 Depression Severity severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度抑郁， 强烈建议就医'**
  String get level2DepressionSeveritySummary3;

  /// DSM-5 Level 2 Anxiety Severity scale name
  ///
  /// In zh, this message translates to:
  /// **'DSM-5 Level 2 焦虑严重度'**
  String get level2AnxietyName;

  /// DSM-5 Level 2 Anxiety Severity short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'成人焦虑严重度 7 题 (DSM-5 PROMIS 简化版）'**
  String get level2AnxietyShortDescription;

  /// DSM-5 Level 2 Anxiety Severity top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 7 天内， 您有多经常被以下感受困扰？'**
  String get level2AnxietyInstruction;

  /// DSM-5 Level 2 Anxiety Severity option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'完全没有'**
  String get level2AnxietyOption0;

  /// DSM-5 Level 2 Anxiety Severity option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几天'**
  String get level2AnxietyOption1;

  /// DSM-5 Level 2 Anxiety Severity option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'一半以上的天数'**
  String get level2AnxietyOption2;

  /// DSM-5 Level 2 Anxiety Severity option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几乎每天'**
  String get level2AnxietyOption3;

  /// DSM-5 Level 2 Anxiety Severity severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无焦虑'**
  String get level2AnxietySeverityLabel0;

  /// DSM-5 Level 2 Anxiety Severity severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度焦虑'**
  String get level2AnxietySeverityLabel1;

  /// DSM-5 Level 2 Anxiety Severity severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度焦虑'**
  String get level2AnxietySeverityLabel2;

  /// DSM-5 Level 2 Anxiety Severity severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度焦虑'**
  String get level2AnxietySeverityLabel3;

  /// DSM-5 Level 2 Anxiety Severity severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无焦虑倾向'**
  String get level2AnxietySeveritySummary0;

  /// DSM-5 Level 2 Anxiety Severity severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度焦虑倾向'**
  String get level2AnxietySeveritySummary1;

  /// DSM-5 Level 2 Anxiety Severity severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度焦虑， 建议就医'**
  String get level2AnxietySeveritySummary2;

  /// DSM-5 Level 2 Anxiety Severity severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度焦虑， 强烈建议就医'**
  String get level2AnxietySeveritySummary3;

  /// DSM-5 Level 2 Mania Severity scale name
  ///
  /// In zh, this message translates to:
  /// **'DSM-5 Level 2 躁狂严重度'**
  String get level2ManiaName;

  /// DSM-5 Level 2 Mania Severity short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'成人躁狂严重度 5 题 (DSM-5 PROMIS 简化版）'**
  String get level2ManiaShortDescription;

  /// DSM-5 Level 2 Mania Severity top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 7 天内， 您有多经常体验以下情况？'**
  String get level2ManiaInstruction;

  /// DSM-5 Level 2 Mania Severity option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'完全没有'**
  String get level2ManiaOption0;

  /// DSM-5 Level 2 Mania Severity option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几天'**
  String get level2ManiaOption1;

  /// DSM-5 Level 2 Mania Severity option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'一半以上的天数'**
  String get level2ManiaOption2;

  /// DSM-5 Level 2 Mania Severity option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'几乎每天'**
  String get level2ManiaOption3;

  /// DSM-5 Level 2 Mania Severity severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无躁狂'**
  String get level2ManiaSeverityLabel0;

  /// DSM-5 Level 2 Mania Severity severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度躁狂'**
  String get level2ManiaSeverityLabel1;

  /// DSM-5 Level 2 Mania Severity severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度躁狂'**
  String get level2ManiaSeverityLabel2;

  /// DSM-5 Level 2 Mania Severity severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度躁狂'**
  String get level2ManiaSeverityLabel3;

  /// DSM-5 Level 2 Mania Severity severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无躁狂倾向'**
  String get level2ManiaSeveritySummary0;

  /// DSM-5 Level 2 Mania Severity severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度躁狂倾向'**
  String get level2ManiaSeveritySummary1;

  /// DSM-5 Level 2 Mania Severity severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度躁狂， 建议就医'**
  String get level2ManiaSeveritySummary2;

  /// DSM-5 Level 2 Mania Severity severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度躁狂， 强烈建议就医'**
  String get level2ManiaSeveritySummary3;

  /// ASRM Altman Self-Rating Mania Scale scale name
  ///
  /// In zh, this message translates to:
  /// **'ASRM 自评躁狂量表'**
  String get asrmName;

  /// ASRM Altman Self-Rating Mania Scale short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'Altman 1997 自评躁狂量表 (5 题）'**
  String get asrmShortDescription;

  /// ASRM Altman Self-Rating Mania Scale top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 1 周内， 您有 （或感觉到） 以下情况的程度？'**
  String get asrmInstruction;

  /// ASRM Altman Self-Rating Mania Scale option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'完全没有'**
  String get asrmOption0;

  /// ASRM Altman Self-Rating Mania Scale option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'轻微'**
  String get asrmOption1;

  /// ASRM Altman Self-Rating Mania Scale option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get asrmOption2;

  /// ASRM Altman Self-Rating Mania Scale option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'明显'**
  String get asrmOption3;

  /// ASRM Altman Self-Rating Mania Scale option 4 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'严重'**
  String get asrmOption4;

  /// ASRM Altman Self-Rating Mania Scale severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无症状'**
  String get asrmSeverityLabel0;

  /// ASRM Altman Self-Rating Mania Scale severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度'**
  String get asrmSeverityLabel1;

  /// ASRM Altman Self-Rating Mania Scale severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get asrmSeverityLabel2;

  /// ASRM Altman Self-Rating Mania Scale severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度'**
  String get asrmSeverityLabel3;

  /// ASRM Altman Self-Rating Mania Scale severity label rank 4 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'极重度'**
  String get asrmSeverityLabel4;

  /// ASRM Altman Self-Rating Mania Scale severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无症状'**
  String get asrmSeveritySummary0;

  /// ASRM Altman Self-Rating Mania Scale severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度躁狂倾向'**
  String get asrmSeveritySummary1;

  /// ASRM Altman Self-Rating Mania Scale severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度躁狂， 建议就医'**
  String get asrmSeveritySummary2;

  /// ASRM Altman Self-Rating Mania Scale severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度躁狂， 建议就医'**
  String get asrmSeveritySummary3;

  /// ASRM Altman Self-Rating Mania Scale severity summary rank 4 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'极重度躁狂， 强烈建议就医'**
  String get asrmSeveritySummary4;

  /// DSM-5 Level 2 Psychotic Symptoms scale name
  ///
  /// In zh, this message translates to:
  /// **'DSM-5 Level 2 精神病性症状'**
  String get level2PsychosisName;

  /// DSM-5 Level 2 Psychotic Symptoms short description for cards/list
  ///
  /// In zh, this message translates to:
  /// **'成人精神病性症状 8 题 (DSM-5 简化版）'**
  String get level2PsychosisShortDescription;

  /// DSM-5 Level 2 Psychotic Symptoms top instruction before items
  ///
  /// In zh, this message translates to:
  /// **'过去 7 天内， 您有多经常体验以下情况？'**
  String get level2PsychosisInstruction;

  /// DSM-5 Level 2 Psychotic Symptoms option 0 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'从来没有'**
  String get level2PsychosisOption0;

  /// DSM-5 Level 2 Psychotic Symptoms option 1 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'很少'**
  String get level2PsychosisOption1;

  /// DSM-5 Level 2 Psychotic Symptoms option 2 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'有时'**
  String get level2PsychosisOption2;

  /// DSM-5 Level 2 Psychotic Symptoms option 3 (0-based)
  ///
  /// In zh, this message translates to:
  /// **'经常'**
  String get level2PsychosisOption3;

  /// DSM-5 Level 2 Psychotic Symptoms severity label rank 0 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'无症状'**
  String get level2PsychosisSeverityLabel0;

  /// DSM-5 Level 2 Psychotic Symptoms severity label rank 1 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'轻度'**
  String get level2PsychosisSeverityLabel1;

  /// DSM-5 Level 2 Psychotic Symptoms severity label rank 2 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'中度'**
  String get level2PsychosisSeverityLabel2;

  /// DSM-5 Level 2 Psychotic Symptoms severity label rank 3 (short, for charts)
  ///
  /// In zh, this message translates to:
  /// **'重度'**
  String get level2PsychosisSeverityLabel3;

  /// DSM-5 Level 2 Psychotic Symptoms severity summary rank 0 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'无精神病性症状'**
  String get level2PsychosisSeveritySummary0;

  /// DSM-5 Level 2 Psychotic Symptoms severity summary rank 1 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'轻度精神病性症状'**
  String get level2PsychosisSeveritySummary1;

  /// DSM-5 Level 2 Psychotic Symptoms severity summary rank 2 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'中度精神病性症状， 建议就医'**
  String get level2PsychosisSeveritySummary2;

  /// DSM-5 Level 2 Psychotic Symptoms severity summary rank 3 (full, for result page)
  ///
  /// In zh, this message translates to:
  /// **'重度精神病性症状， 强烈建议就医'**
  String get level2PsychosisSeveritySummary3;

  /// v0.30 R91: 日常追蹤整合入口頁 title
  ///
  /// In zh, this message translates to:
  /// **'日常追踪'**
  String get dailyTrackingTitle;

  /// v0.30 R91: 主頁 FAB 跳日常追蹤入口頁時的提示
  ///
  /// In zh, this message translates to:
  /// **'日常追踪'**
  String get dailyTrackingFab;

  /// v0.30 R91: 多指標趨勢圖標題
  ///
  /// In zh, this message translates to:
  /// **'近 30 天 4 指标'**
  String get dailyTrackingMultiChartTitle;

  /// R102: 多指標趨勢圖 — 體重指標名
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get chartMetricWeight;

  /// R102: 多指標趨勢圖 — 睡眠指標名
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get chartMetricSleep;

  /// R102: 多指標趨勢圖 — 心境指標名
  ///
  /// In zh, this message translates to:
  /// **'心境'**
  String get chartMetricMood;

  /// R102: 多指標趨勢圖 — 應激源指標名
  ///
  /// In zh, this message translates to:
  /// **'应激源'**
  String get chartMetricStress;

  /// v0.30 R91: 卡片 lastValue 時間佔位 (placeholder {time} 是 formatted date)
  ///
  /// In zh, this message translates to:
  /// **'{time} 记录'**
  String dailyTrackingLastTime(Object time);

  /// v0.30 R91: 整合入口頁卡片 CTA 按鈕
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get dailyTrackingRecord;

  /// v0.30 R91: 情緒日記 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'情绪日记'**
  String get moodDiaryName;

  /// v0.30 R91: 情緒日記 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'心境 4 段 + score, 趋势分析'**
  String get moodDiaryShortDesc;

  /// v0.30 R91: 情緒日記 lastValue 摘要 (placeholder {score} 是 1-5)
  ///
  /// In zh, this message translates to:
  /// **'心境 {score}/5'**
  String moodDiaryScore(int score);

  /// v0.30 R91: 情緒日記 整合卡片 lastValue 完整摘要
  ///
  /// In zh, this message translates to:
  /// **'{time} · {score} ({period})'**
  String moodDiaryLast(Object time, Object score, Object period);

  /// v0.30 R91: 焦慮急躁 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'焦虑急躁'**
  String get anxietyAgitationName;

  /// v0.30 R91: 焦慮急躁 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'焦虑 + 急躁 双维度 5 档'**
  String get anxietyAgitationShortDesc;

  /// v0.30 R91: 焦慮急躁 提示 （對話框說明）
  ///
  /// In zh, this message translates to:
  /// **'焦虑反向 1=严重 5=平静； 急躁正向 1=平静 5=极急'**
  String get anxietyAgitationHint;

  /// v0.30 R91: 焦慮急躁 列表頁 添加按鈕
  ///
  /// In zh, this message translates to:
  /// **'添加评估'**
  String get anxietyAgitationAddButton;

  /// v0.30 R91: 焦慮急躁 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无焦虑急躁记录'**
  String get anxietyAgitationNoData;

  /// v0.30 R91: 焦慮急躁 焦慮維度 lastValue 摘要 (placeholder {score} 是 1-5)
  ///
  /// In zh, this message translates to:
  /// **'焦虑 {score}'**
  String anxietyAgitationAnxietyScore(int score);

  /// v0.30 R91: 焦慮急躁 急躁維度 lastValue 摘要 (placeholder {score} 是 1-5)
  ///
  /// In zh, this message translates to:
  /// **'急躁 {score}'**
  String anxietyAgitationAgitationScore(int score);

  /// v0.30 R91: 焦慮急躁 整合卡片 lastValue 完整摘要
  ///
  /// In zh, this message translates to:
  /// **'焦虑 {anxiety} / 急躁 {agitation}'**
  String anxietyAgitationLast(int anxiety, int agitation);

  /// v0.30 R91: 睡眠 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'睡眠'**
  String get sleepName;

  /// v0.30 R91: 睡眠 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'入睡 + 时长 + 规律性'**
  String get sleepShortDesc;

  /// v0.30 R91: 睡眠 提示 （對話框 / 列表頁說明）
  ///
  /// In zh, this message translates to:
  /// **'记录每晚入睡 + 起床， 跨午夜自动算时长'**
  String get sleepHint;

  /// v0.30 R91: 睡眠 列表頁 添加按鈕
  ///
  /// In zh, this message translates to:
  /// **'添加睡眠记录'**
  String get sleepAddButton;

  /// v0.30 R91: 睡眠 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无睡眠记录'**
  String get sleepNoData;

  /// v0.30 R91: 睡眠 入睡時間 lastValue 摘要 (placeholder {time} 是 HH:mm)
  ///
  /// In zh, this message translates to:
  /// **'入睡 {time}'**
  String sleepBedtime(Object time);

  /// v0.30 R91: 睡眠 起床時間 lastValue 摘要 (placeholder {time} 是 HH:mm)
  ///
  /// In zh, this message translates to:
  /// **'起床 {time}'**
  String sleepWakeTime(Object time);

  /// v0.30 R91: 睡眠 整合卡片 lastValue 完整摘要 (duration 是 8h00min, regularity 是 1-5)
  ///
  /// In zh, this message translates to:
  /// **'{duration} · 规律 {regularity}/5'**
  String sleepLast(Object duration, int regularity);

  /// v0.30 R91: 社會節律 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'社会节律'**
  String get socialRhythmName;

  /// v0.30 R91: 社會節律 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'起床 + 第一餐 + 最后一餐 + 时长'**
  String get socialRhythmShortDesc;

  /// v0.30 R91: 社會節律 提示 （對話框 / 列表頁說明）
  ///
  /// In zh, this message translates to:
  /// **'记录每天的作息， 帮医生判断节律稳定性'**
  String get socialRhythmHint;

  /// v0.30 R91: 社會節律 列表頁 添加按鈕
  ///
  /// In zh, this message translates to:
  /// **'添加社会节律'**
  String get socialRhythmAddButton;

  /// v0.30 R91: 社會節律 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无社会节律记录'**
  String get socialRhythmNoData;

  /// v0.30 R91: 社會節律 起床時間 lastValue 摘要
  ///
  /// In zh, this message translates to:
  /// **'起床 {time}'**
  String socialRhythmWakeTime(Object time);

  /// v0.30 R91: 社會節律 第一餐 lastValue 摘要
  ///
  /// In zh, this message translates to:
  /// **'第一餐 {time}'**
  String socialRhythmFirstMeal(Object time);

  /// v0.30 R91: 社會節律 最後一餐 lastValue 摘要
  ///
  /// In zh, this message translates to:
  /// **'最后一餐 {time}'**
  String socialRhythmLastMeal(Object time);

  /// v0.30 R91: 社會節律 整合卡片 lastValue 完整摘要
  ///
  /// In zh, this message translates to:
  /// **'起床 {wake} · 社交 {social}h · 工作 {work}h'**
  String socialRhythmLast(Object wake, int social, int work);

  /// v0.30 R91: 應激源 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'应激源'**
  String get stressEventName;

  /// v0.30 R91: 應激源 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'事件类型 + 强度评分'**
  String get stressEventShortDesc;

  /// v0.30 R91: 應激源 提示 （對話框 / 列表頁說明）
  ///
  /// In zh, this message translates to:
  /// **'记录生活中的压力事件， 帮医生判断触发因素'**
  String get stressEventHint;

  /// v0.30 R91: 應激源 列表頁 添加按鈕
  ///
  /// In zh, this message translates to:
  /// **'添加应激源'**
  String get stressEventAddButton;

  /// v0.30 R91: 應激源 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无应激源记录'**
  String get stressEventNoData;

  /// v0.30 R91: 應激源 事件類型 標籤 （對話框 dropdown)
  ///
  /// In zh, this message translates to:
  /// **'事件类型'**
  String get stressEventEventType;

  /// v0.30 R91: 應激源 強度評分 標籤
  ///
  /// In zh, this message translates to:
  /// **'强度'**
  String get stressEventIntensity;

  /// v0.30 R91: 應激源 整合卡片 lastValue 摘要
  ///
  /// In zh, this message translates to:
  /// **'强度 {intensity}/5'**
  String stressEventLast(int intensity);

  /// v0.30 R91: 治療 子功能名 （整合頁 + 列表頁 placeholder)
  ///
  /// In zh, this message translates to:
  /// **'治疗'**
  String get treatmentName;

  /// v0.30 R91: 治療 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'用药 / 咨询 / 物理治疗， 关联 medication'**
  String get treatmentShortDesc;

  /// v0.30 R91: 治療 提示 （列表頁說明）
  ///
  /// In zh, this message translates to:
  /// **'治疗条目可关联 medication, 写入功能 v0.31+'**
  String get treatmentHint;

  /// v0.30 R91: 治療 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无治疗记录'**
  String get treatmentNoData;

  /// v0.30 round 92 (audit-fixes / P0 #15): 治療 添加按鈕 （列表頁右上角）
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get treatmentAddButton;

  /// v0.30 round 92: 治療 AddTreatmentDialog title
  ///
  /// In zh, this message translates to:
  /// **'添加治疗记录'**
  String get treatmentAddTitle;

  /// v0.30 round 92: 治療 日期 field
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get treatmentDate;

  /// v0.30 round 92: 治療 類別 field (4 選 1)
  ///
  /// In zh, this message translates to:
  /// **'类别'**
  String get treatmentCategory;

  /// v0.30 round 92: 治療 類別 1/4 藥物調整
  ///
  /// In zh, this message translates to:
  /// **'药物调整'**
  String get treatmentCategoryMedicationAdjustment;

  /// v0.30 round 92: 治療 類別 2/4 心理諮詢
  ///
  /// In zh, this message translates to:
  /// **'心理咨询'**
  String get treatmentCategoryConsultation;

  /// v0.30 round 92: 治療 類別 3/4 住院
  ///
  /// In zh, this message translates to:
  /// **'住院'**
  String get treatmentCategoryHospitalization;

  /// v0.30 round 92: 治療 類別 4/4 其他
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get treatmentCategoryOther;

  /// v0.30 round 92: 治療 醫療機構 / 醫生 (description 字段）
  ///
  /// In zh, this message translates to:
  /// **'医疗机构 / 医生'**
  String get treatmentProvider;

  /// v0.30 round 92: 治療 醫療機構 hint
  ///
  /// In zh, this message translates to:
  /// **'例如： 心理医生王医生 / 北京协和医院'**
  String get treatmentProviderHint;

  /// v0.30 round 92: 治療 醫療機構為空 snackbar 提示
  ///
  /// In zh, this message translates to:
  /// **'请填写医疗机构 / 医生'**
  String get treatmentProviderRequired;

  /// v0.30 round 92: 治療 備註 field
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get treatmentNote;

  /// v0.30 round 92: 治療 備註 hint
  ///
  /// In zh, this message translates to:
  /// **'可选， 简短记录治疗要点'**
  String get treatmentNoteHint;

  /// v0.30 R91: 治療 治療類型 標籤 （對話框 dropdown)
  ///
  /// In zh, this message translates to:
  /// **'治疗类型'**
  String get treatmentType;

  /// v0.30 R91: 治療 整合卡片 lastValue 摘要
  ///
  /// In zh, this message translates to:
  /// **'{type} · {description}'**
  String treatmentLast(Object type, Object description);

  /// v0.30 R91: 體重 子功能名 （整合頁 + 列表頁）
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get weightName;

  /// v0.30 R91: 體重 子功能簡短描述 （卡片用）
  ///
  /// In zh, this message translates to:
  /// **'体重 + BMI （需 profile.height)'**
  String get weightShortDesc;

  /// v0.30 R91: 體重 提示 （對話框 / 列表頁說明）
  ///
  /// In zh, this message translates to:
  /// **'记录每天的体重， 帮医生判断生理状态'**
  String get weightHint;

  /// v0.30 R91: 體重 列表頁 添加按鈕
  ///
  /// In zh, this message translates to:
  /// **'添加体重记录'**
  String get weightAddButton;

  /// v0.30 R91: 體重 列表頁 空狀態
  ///
  /// In zh, this message translates to:
  /// **'暂无体重记录'**
  String get weightNoData;

  /// v0.30 R91: 體重 lastValue 摘要 (placeholder {kg} 是 1 decimal)
  ///
  /// In zh, this message translates to:
  /// **'体重 {kg} kg'**
  String weightWeight(Object kg);

  /// v0.30 R91: 體重 BMI lastValue 摘要 (placeholder {bmi} 是 1 decimal)
  ///
  /// In zh, this message translates to:
  /// **'BMI {bmi}'**
  String weightBmi(Object bmi);

  /// v0.30 R91: 體重 整合卡片 lastValue 摘要 (bmi 可選）
  ///
  /// In zh, this message translates to:
  /// **'{kg} kg · BMI {bmi}'**
  String weightLast(Object kg, Object bmi);

  /// v0.30 R91: 心境 period 早 (morning)
  ///
  /// In zh, this message translates to:
  /// **'早'**
  String get periodMorning;

  /// v0.30 R91: 心境 period 中 (noon)
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get periodNoon;

  /// v0.30 R91: 心境 period 晚 (evening)
  ///
  /// In zh, this message translates to:
  /// **'晚'**
  String get periodEvening;

  /// v0.30 R91: 心境 period 夜 (night)
  ///
  /// In zh, this message translates to:
  /// **'夜'**
  String get periodNight;

  /// v0.30 R91: 心境 period fallback (R91 老 entry 兼容）
  ///
  /// In zh, this message translates to:
  /// **'未指定'**
  String get periodUnspecified;

  /// v0.30 R91: 應激源事件類型 1/5 工作
  ///
  /// In zh, this message translates to:
  /// **'工作'**
  String get stressEventTypeWork;

  /// v0.30 R91: 應激源事件類型 2/5 關係
  ///
  /// In zh, this message translates to:
  /// **'关系'**
  String get stressEventTypeRelationship;

  /// v0.30 R91: 應激源事件類型 3/5 健康
  ///
  /// In zh, this message translates to:
  /// **'健康'**
  String get stressEventTypeHealth;

  /// v0.30 R91: 應激源事件類型 4/5 財務
  ///
  /// In zh, this message translates to:
  /// **'财务'**
  String get stressEventTypeFinancial;

  /// v0.30 R91: 應激源事件類型 5/5 其他
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get stressEventTypeOther;

  /// v0.30 R91: regularity 1/5 很不規律
  ///
  /// In zh, this message translates to:
  /// **'很不规律'**
  String get regularityVeryIrregular;

  /// v0.30 R91: regularity 2/5 不規律
  ///
  /// In zh, this message translates to:
  /// **'不规律'**
  String get regularityIrregular;

  /// v0.30 R91: regularity 3/5 一般
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get regularityNormal;

  /// v0.30 R91: regularity 4/5 規律
  ///
  /// In zh, this message translates to:
  /// **'规律'**
  String get regularityRegular;

  /// v0.30 R91: regularity 5/5 很規律
  ///
  /// In zh, this message translates to:
  /// **'很规律'**
  String get regularityVeryRegular;

  /// v0.30 R91: 卡片 lastValue null 時 fallback
  ///
  /// In zh, this message translates to:
  /// **'尚未记录'**
  String get cardStatusNoData;

  /// v0.30 R92: sleepBedtimeTitle title 標籤 (R91 daily_tracking l10n 漏 title 模式 key, R92 補）
  ///
  /// In zh, this message translates to:
  /// **'入睡时间'**
  String get sleepBedtimeTitle;

  /// v0.30 R92: sleepWakeTimeTitle title 標籤 (R91 daily_tracking l10n 漏 title 模式 key, R92 補）
  ///
  /// In zh, this message translates to:
  /// **'起床时间'**
  String get sleepWakeTimeTitle;

  /// v0.30 R92: socialRhythmWakeTimeTitle title 標籤 (R91 daily_tracking l10n 漏 title 模式 key, R92 補）
  ///
  /// In zh, this message translates to:
  /// **'起床时间'**
  String get socialRhythmWakeTimeTitle;

  /// v0.30 R92: socialRhythmFirstMealTitle title 標籤 (R91 daily_tracking l10n 漏 title 模式 key, R92 補）
  ///
  /// In zh, this message translates to:
  /// **'第一餐时间'**
  String get socialRhythmFirstMealTitle;

  /// v0.30 R92: socialRhythmLastMealTitle title 標籤 (R91 daily_tracking l10n 漏 title 模式 key, R92 補）
  ///
  /// In zh, this message translates to:
  /// **'最后一餐时间'**
  String get socialRhythmLastMealTitle;

  /// v0.30 R91: 卡片時間狀態 今天
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get cardStatusToday;

  /// v0.30 R92: 睡眠 規律性 slider 標題 (R91 daily_tracking l10n 漏， R92 補）
  ///
  /// In zh, this message translates to:
  /// **'规律性'**
  String get sleepRegularityTitle;

  /// v0.30 R92: 焦慮急躁 焦慮分數 slider 標籤 (R91 daily_tracking l10n 漏， R92 補）
  ///
  /// In zh, this message translates to:
  /// **'焦虑分数'**
  String get anxietyAgitationAnxietyLabel;

  /// v0.30 R92: 焦慮急躁 急躁分數 slider 標籤 (R91 daily_tracking l10n 漏， R92 補）
  ///
  /// In zh, this message translates to:
  /// **'急躁分数'**
  String get anxietyAgitationAgitationLabel;

  /// v0.30 R92: mood_list 情緒列表時段過濾 chip '全部' (R87 mood_list page l10n 漏， R92 補）
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get moodListPeriodAll;

  /// v0.30 R95 sub-spec 7 task 53: 啟動時本地數據初始化失敗的短消息 (main.dart 205 行原硬編碼）
  ///
  /// In zh, this message translates to:
  /// **'无法初始化本地数据'**
  String get migrationFailedInitData;

  /// v0.30 R95 sub-spec 7 task 53: 數據初始化失敗後給用戶可操作提示
  ///
  /// In zh, this message translates to:
  /// **'请尝试重启 App，或卸载后重新安装'**
  String get migrationFailedActionHint;

  /// v0.30 R95 sub-spec 7 task 53: 失敗頁底部技術信息， 內部異常脫敏後展示
  ///
  /// In zh, this message translates to:
  /// **'技术信息： {error}'**
  String migrationFailedFooter(String error);

  /// v0.30 R95 sub-spec 7 task 53: 失敗頁重試按鈕 (v1.0 加按鈕用）
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get migrationFailedRetryButton;

  /// v0.30 R95 sub-spec 7 task 53: 失敗頁關閉按鈕 (v1.0 加按鈕用）
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get migrationFailedCloseButton;

  /// v0.30 R95 sub-spec 7 task 53: 啟動時 loading 文案 (_MigrationPromptApp 內部）
  ///
  /// In zh, this message translates to:
  /// **'启动中，请稍候……'**
  String get migrationStartingHint;

  /// v0.30 R95 sub-spec 7 task 53: 彈 dialog 時 navigator context 仍 null 的兜底消息
  ///
  /// In zh, this message translates to:
  /// **'启动上下文尚未就绪，请稍后再试'**
  String get migrationNavContextNull;

  /// v0.30 R95 sub-spec 7 task 53: 錯誤前綴標籤 (e.g. '錯誤： xxx')
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get migrationFailedErrorPrefix;

  /// v0.30 R95 sub-spec 7 task 55: daily_tracking 6 widget 通用 note label (anxiety_agitation / sleep / stress_event / treatment / weight 5 處共享）
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get dailyTrackingNoteLabel;

  /// v0.30 R95 sub-spec 7 task 55: daily_tracking 6 widget 通用 note hint, 提示用戶非必填
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get dailyTrackingNoteHint;

  /// v0.30 R95 sub-spec 7 task 55: assessment_center_card 等相對時間顯示 '剛剛' (just now)
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeAgoJustNow;

  /// v0.30 R95 sub-spec 7 task 55: 相對時間 '{N} 天前' (N days ago)
  ///
  /// In zh, this message translates to:
  /// **'{days} 天前'**
  String timeAgoDaysAgo(int days);

  /// v0.30 R95 sub-spec 7 task 55: 相對時間 '{N} 小時前' (N hours ago)
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时前'**
  String timeAgoHoursAgo(int hours);

  /// v0.30 R100 (P1#9): 體重 tile BMI 缺失後綴 （暫無身高檔案）
  ///
  /// In zh, this message translates to:
  /// **'暂无 BMI'**
  String get weightNoBmi;

  /// v0.30 R100 (P1#9): 體重 dialog 體重輸入框 label
  ///
  /// In zh, this message translates to:
  /// **'体重 (kg)'**
  String get weightKgLabel;

  /// v0.30 R100 (P1#9): 體重 dialog 體重輸入框 hint
  ///
  /// In zh, this message translates to:
  /// **'如 60.5'**
  String get weightKgHint;

  /// v0.30 R100 (P1#9): 體重 dialog BMI 實時行 缺身高檔案時兜底文案
  ///
  /// In zh, this message translates to:
  /// **'暂无 （需填写身高）'**
  String get weightBmiNeedHeight;

  /// v0.30 R100 (P1#9): 社會節律 tile 摘要行 3 分鐘數段
  ///
  /// In zh, this message translates to:
  /// **'社交 {social}min · 工作 {work}min · 运动 {exercise}min'**
  String socialRhythmMinutesSummary(
      Object social, Object work, Object exercise);

  /// v0.30 R100 (P1#9): 社會節律 dialog 社交分鐘輸入框 label
  ///
  /// In zh, this message translates to:
  /// **'社交时长 （分钟）'**
  String get socialRhythmSocialMinLabel;

  /// v0.30 R100 (P1#9): 社會節律 dialog 工作分鐘輸入框 label
  ///
  /// In zh, this message translates to:
  /// **'工作时长 （分钟）'**
  String get socialRhythmWorkMinLabel;

  /// v0.30 R100 (P1#9): 社會節律 dialog 運動分鐘輸入框 label
  ///
  /// In zh, this message translates to:
  /// **'运动时长 （分钟）'**
  String get socialRhythmExerciseMinLabel;

  /// v0.30 R100 (P1#9): 焦慮急躁 dialog 焦慮分數刻度提示 （反向）
  ///
  /// In zh, this message translates to:
  /// **'1=严重 5=平静'**
  String get anxietyAgitationAnxietyScaleHint;

  /// v0.30 R100 (P1#9): 焦慮急躁 dialog 急躁分數刻度提示 （正向）
  ///
  /// In zh, this message translates to:
  /// **'1=平静 5=极急'**
  String get anxietyAgitationAgitationScaleHint;

  /// v0.30 R100 (P1#9): 睡眠 tile 摘要行 規律性分數段
  ///
  /// In zh, this message translates to:
  /// **'规律 {score}/5'**
  String sleepRegularityScore(int score);

  /// v0.30 R100 (P1#9): 睡眠 dialog 時長只讀行 (duration 是 HH h MM m 格式）
  ///
  /// In zh, this message translates to:
  /// **'时长： {duration}'**
  String sleepDurationLabel(Object duration);

  /// v0.30 R100 (P1#9): 壓力事件 tile 標題 強度分數段
  ///
  /// In zh, this message translates to:
  /// **'强度 {intensity}/5'**
  String stressIntensityScore(int intensity);

  /// v0.30 R100 (P1#9): CBT 欄數參數化 (settings cbt_section + mood_list filter sheet 共用）
  ///
  /// In zh, this message translates to:
  /// **'{count} 栏'**
  String moodCbtColumns(int count);

  /// v0.30 R100 (P1#9): 用藥報告 dialog 標題 （含時間窗口）
  ///
  /// In zh, this message translates to:
  /// **'用药报告（近 {days} 天）'**
  String medReportTitleWindow(int days);

  /// v0.30 R100 (P1#9): setup 法務 dialog 危機熱線區塊標題
  ///
  /// In zh, this message translates to:
  /// **'🆘 心理危机干预热线 (24h)'**
  String get setupCrisisHotlineTitle;

  /// v0.30 R100 (P1#9): §14 撤回 vent 同意 fallback body （法律文案）
  ///
  /// In zh, this message translates to:
  /// **'树洞 （私密倾诉） 功能将停用。新增树洞记录会被拒绝， 已有记录保留。'**
  String get consentWithdrawVentBody;

  /// v0.30 R100 (P1#9): §14 撤回 analytics 同意 fallback body （法律文案）
  ///
  /// In zh, this message translates to:
  /// **'评估 / 情绪相关分析图表将不再展示。已有数据保留， 重新开启后恢复。'**
  String get consentWithdrawAnalyticsBody;

  /// v0.30 R100 (P1#9): 導出 consent dialog purpose placeholder
  ///
  /// In zh, this message translates to:
  /// **'本地备份 / 跨设备迁移'**
  String get dataExportPurposeBackup;

  /// v0.30 R100 (P1#9): 導出 consent dialog dataCategories placeholder
  ///
  /// In zh, this message translates to:
  /// **'用药记录、打卡记录、情绪日记、树洞文字 （录音不导出）'**
  String get dataExportDataCategories;

  /// v0.30 R100 (P1#9): 導出 consent dialog retention placeholder
  ///
  /// In zh, this message translates to:
  /// **'剪贴板 + 用户自行保存到加密存储'**
  String get dataExportRetentionClipboard;

  /// v0.30 R101: 用藥主頁標題
  ///
  /// In zh, this message translates to:
  /// **'用药'**
  String get medPageTitle;

  /// v0.30 R101: 用藥主頁添加按鈕 tooltip
  ///
  /// In zh, this message translates to:
  /// **'添加药物'**
  String get medAddTooltip;

  /// v0.30 R101: 今日服藥計劃 section 標題
  ///
  /// In zh, this message translates to:
  /// **'今日服药'**
  String get medTodaySchedule;

  /// v0.30 R101: 我的藥物 section 標題
  ///
  /// In zh, this message translates to:
  /// **'我的药物'**
  String get medMyMedications;

  /// v0.30 R101: 快捷操作 section 標題
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get medQuickActions;

  /// v0.30 R101: 時間段標籤 - 早上
  ///
  /// In zh, this message translates to:
  /// **'早上'**
  String get medSlotMorning;

  /// v0.30 R101: 時間段標籤 - 下午
  ///
  /// In zh, this message translates to:
  /// **'下午'**
  String get medSlotAfternoon;

  /// v0.30 R101: 時間段標籤 - 晚上
  ///
  /// In zh, this message translates to:
  /// **'晚上'**
  String get medSlotEvening;

  /// v0.30 R101: 時間段標籤 - 睡前
  ///
  /// In zh, this message translates to:
  /// **'睡前'**
  String get medSlotBedtime;

  /// No description provided for @medEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有添加药物'**
  String get medEmptyTitle;

  /// No description provided for @medEmptySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 添加你的第一种药物'**
  String get medEmptySubtitle;

  /// No description provided for @medNoScheduleToday.
  ///
  /// In zh, this message translates to:
  /// **'今天没有服药计划'**
  String get medNoScheduleToday;

  /// No description provided for @medAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加药物'**
  String get medAddTitle;

  /// No description provided for @medAddStep1Title.
  ///
  /// In zh, this message translates to:
  /// **'药物信息'**
  String get medAddStep1Title;

  /// No description provided for @medAddConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认信息'**
  String get medAddConfirm;

  /// No description provided for @medAddColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get medAddColor;

  /// No description provided for @medAddTime.
  ///
  /// In zh, this message translates to:
  /// **'用药时间'**
  String get medAddTime;

  /// No description provided for @medAddBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get medAddBasicInfo;

  /// No description provided for @medAddStep2Title.
  ///
  /// In zh, this message translates to:
  /// **'剂量与时间'**
  String get medAddStep2Title;

  /// No description provided for @medAddStep3Title.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get medAddStep3Title;

  /// No description provided for @medAddNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'药物名称'**
  String get medAddNameLabel;

  /// No description provided for @medAddNameHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：舍曲林'**
  String get medAddNameHint;

  /// No description provided for @medAddFormLabel.
  ///
  /// In zh, this message translates to:
  /// **'剂型'**
  String get medAddFormLabel;

  /// No description provided for @medAddDosageLabel.
  ///
  /// In zh, this message translates to:
  /// **'每次剂量'**
  String get medAddDosageLabel;

  /// No description provided for @medAddTimeLabel.
  ///
  /// In zh, this message translates to:
  /// **'服药时间'**
  String get medAddTimeLabel;

  /// No description provided for @medAddTimeAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加时间'**
  String get medAddTimeAdd;

  /// No description provided for @medAddColorLabel.
  ///
  /// In zh, this message translates to:
  /// **'药物颜色（可选，帮助识别）'**
  String get medAddColorLabel;

  /// No description provided for @medAddConfirmName.
  ///
  /// In zh, this message translates to:
  /// **'药名'**
  String get medAddConfirmName;

  /// No description provided for @medAddConfirmForm.
  ///
  /// In zh, this message translates to:
  /// **'剂型'**
  String get medAddConfirmForm;

  /// No description provided for @medAddConfirmDosage.
  ///
  /// In zh, this message translates to:
  /// **'剂量'**
  String get medAddConfirmDosage;

  /// No description provided for @medAddConfirmTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get medAddConfirmTime;

  /// No description provided for @medAddPrev.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get medAddPrev;

  /// No description provided for @medAddNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get medAddNext;

  /// No description provided for @medAddSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get medAddSave;

  /// No description provided for @medAddColorN.
  ///
  /// In zh, this message translates to:
  /// **'药物颜色 {n}'**
  String medAddColorN(Object n);

  /// v0.30 R101: 劑型 - 片劑
  ///
  /// In zh, this message translates to:
  /// **'片剂'**
  String get medFormTablet;

  /// v0.30 R101: 劑型 - 膠囊
  ///
  /// In zh, this message translates to:
  /// **'胶囊'**
  String get medFormCapsule;

  /// v0.30 R101: 劑型 - 口服液
  ///
  /// In zh, this message translates to:
  /// **'口服液'**
  String get medFormLiquid;

  /// No description provided for @medFormPatch.
  ///
  /// In zh, this message translates to:
  /// **'贴剂'**
  String get medFormPatch;

  /// No description provided for @medFormInjection.
  ///
  /// In zh, this message translates to:
  /// **'注射'**
  String get medFormInjection;

  /// No description provided for @medFormOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get medFormOther;

  /// No description provided for @medDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'药物详情'**
  String get medDetailTitle;

  /// No description provided for @medNotFound.
  ///
  /// In zh, this message translates to:
  /// **'药物未找到'**
  String get medNotFound;

  /// No description provided for @moodInfluenceTitle.
  ///
  /// In zh, this message translates to:
  /// **'影响因素'**
  String get moodInfluenceTitle;

  /// No description provided for @moodInfluenceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'什么影响了你的心情？（可多选）'**
  String get moodInfluenceSubtitle;

  /// No description provided for @moodInfluenceRelationships.
  ///
  /// In zh, this message translates to:
  /// **'关系'**
  String get moodInfluenceRelationships;

  /// No description provided for @moodInfluenceHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康'**
  String get moodInfluenceHealth;

  /// No description provided for @moodInfluenceActivities.
  ///
  /// In zh, this message translates to:
  /// **'活动'**
  String get moodInfluenceActivities;

  /// No description provided for @moodInfluenceMindfulness.
  ///
  /// In zh, this message translates to:
  /// **'正念'**
  String get moodInfluenceMindfulness;

  /// No description provided for @moodInfluenceWeather.
  ///
  /// In zh, this message translates to:
  /// **'天气'**
  String get moodInfluenceWeather;

  /// No description provided for @moodInfluenceOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get moodInfluenceOther;

  /// No description provided for @influenceFactorFamily.
  ///
  /// In zh, this message translates to:
  /// **'家人'**
  String get influenceFactorFamily;

  /// No description provided for @influenceFactorFriend.
  ///
  /// In zh, this message translates to:
  /// **'朋友'**
  String get influenceFactorFriend;

  /// No description provided for @influenceFactorPartner.
  ///
  /// In zh, this message translates to:
  /// **'伴侣'**
  String get influenceFactorPartner;

  /// No description provided for @influenceFactorChild.
  ///
  /// In zh, this message translates to:
  /// **'孩子'**
  String get influenceFactorChild;

  /// No description provided for @influenceFactorColleague.
  ///
  /// In zh, this message translates to:
  /// **'同事'**
  String get influenceFactorColleague;

  /// No description provided for @influenceFactorExercise.
  ///
  /// In zh, this message translates to:
  /// **'运动'**
  String get influenceFactorExercise;

  /// No description provided for @influenceFactorSick.
  ///
  /// In zh, this message translates to:
  /// **'生病'**
  String get influenceFactorSick;

  /// No description provided for @influenceFactorGoodSleep.
  ///
  /// In zh, this message translates to:
  /// **'睡眠好'**
  String get influenceFactorGoodSleep;

  /// No description provided for @influenceFactorHealthyDiet.
  ///
  /// In zh, this message translates to:
  /// **'饮食健康'**
  String get influenceFactorHealthyDiet;

  /// No description provided for @influenceFactorWork.
  ///
  /// In zh, this message translates to:
  /// **'工作'**
  String get influenceFactorWork;

  /// No description provided for @influenceFactorHobby.
  ///
  /// In zh, this message translates to:
  /// **'爱好'**
  String get influenceFactorHobby;

  /// No description provided for @influenceFactorTravel.
  ///
  /// In zh, this message translates to:
  /// **'旅行'**
  String get influenceFactorTravel;

  /// No description provided for @influenceFactorCommute.
  ///
  /// In zh, this message translates to:
  /// **'通勤'**
  String get influenceFactorCommute;

  /// No description provided for @influenceFactorShopping.
  ///
  /// In zh, this message translates to:
  /// **'购物'**
  String get influenceFactorShopping;

  /// No description provided for @influenceFactorGaming.
  ///
  /// In zh, this message translates to:
  /// **'游戏'**
  String get influenceFactorGaming;

  /// No description provided for @influenceFactorReading.
  ///
  /// In zh, this message translates to:
  /// **'阅读'**
  String get influenceFactorReading;

  /// No description provided for @influenceFactorEntertainment.
  ///
  /// In zh, this message translates to:
  /// **'娱乐'**
  String get influenceFactorEntertainment;

  /// No description provided for @influenceFactorMeditation.
  ///
  /// In zh, this message translates to:
  /// **'冥想'**
  String get influenceFactorMeditation;

  /// No description provided for @influenceFactorBreathing.
  ///
  /// In zh, this message translates to:
  /// **'呼吸练习'**
  String get influenceFactorBreathing;

  /// No description provided for @influenceFactorJournaling.
  ///
  /// In zh, this message translates to:
  /// **'写日记'**
  String get influenceFactorJournaling;

  /// No description provided for @influenceFactorYoga.
  ///
  /// In zh, this message translates to:
  /// **'瑜伽'**
  String get influenceFactorYoga;

  /// No description provided for @influenceFactorSunny.
  ///
  /// In zh, this message translates to:
  /// **'晴天'**
  String get influenceFactorSunny;

  /// No description provided for @influenceFactorCloudy.
  ///
  /// In zh, this message translates to:
  /// **'多云'**
  String get influenceFactorCloudy;

  /// No description provided for @influenceFactorRainy.
  ///
  /// In zh, this message translates to:
  /// **'雨天'**
  String get influenceFactorRainy;

  /// No description provided for @influenceFactorSnowy.
  ///
  /// In zh, this message translates to:
  /// **'雪天'**
  String get influenceFactorSnowy;

  /// No description provided for @influenceFactorWindy.
  ///
  /// In zh, this message translates to:
  /// **'刮风'**
  String get influenceFactorWindy;

  /// No description provided for @moodDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪详情'**
  String get moodDetailTitle;

  /// No description provided for @moodDetailFactors.
  ///
  /// In zh, this message translates to:
  /// **'影响因素'**
  String get moodDetailFactors;

  /// No description provided for @moodDetailMoodState.
  ///
  /// In zh, this message translates to:
  /// **'情绪状态'**
  String get moodDetailMoodState;

  /// No description provided for @moodDetailCbtRecord.
  ///
  /// In zh, this message translates to:
  /// **'CBT 思维记录'**
  String get moodDetailCbtRecord;

  /// No description provided for @moodEntryNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到这条情绪记录'**
  String get moodEntryNotFound;

  /// No description provided for @moodTrendTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪趋势'**
  String get moodTrendTitle;

  /// No description provided for @moodTrendWeek.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天'**
  String get moodTrendWeek;

  /// No description provided for @moodTrendDistribution.
  ///
  /// In zh, this message translates to:
  /// **'分数分布'**
  String get moodTrendDistribution;

  /// No description provided for @moodTrendNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get moodTrendNoData;

  /// No description provided for @moodDeleteTooltip.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get moodDeleteTooltip;

  /// No description provided for @moodDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除这条记录吗？'**
  String get moodDeleteConfirm;

  /// No description provided for @moodFactorAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'因素关联分析'**
  String get moodFactorAnalysis;

  /// No description provided for @moodModeMomentary.
  ///
  /// In zh, this message translates to:
  /// **'此刻'**
  String get moodModeMomentary;

  /// No description provided for @moodModeDaily.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get moodModeDaily;

  /// No description provided for @moodTrendDistTitle.
  ///
  /// In zh, this message translates to:
  /// **'分数分布'**
  String get moodTrendDistTitle;

  /// No description provided for @moodTrendCbtTitle.
  ///
  /// In zh, this message translates to:
  /// **'CBT 重评效果'**
  String get moodTrendCbtTitle;

  /// No description provided for @moodTrendCbtHint.
  ///
  /// In zh, this message translates to:
  /// **'正值 = 情绪改善， 负值 = 恶化'**
  String get moodTrendCbtHint;

  /// No description provided for @moodTrendCbtEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无 CBT 重评数据'**
  String get moodTrendCbtEmpty;

  /// No description provided for @moodTrendSemanticsLine.
  ///
  /// In zh, this message translates to:
  /// **'情绪趋势折线图，近 {days} 天'**
  String moodTrendSemanticsLine(Object days);

  /// No description provided for @moodTrendSemanticsDist.
  ///
  /// In zh, this message translates to:
  /// **'情绪分数分布图，最常见 {score} 分，共 {count} 条记录'**
  String moodTrendSemanticsDist(Object count, Object score);

  /// No description provided for @moodTrendSemanticsCbt.
  ///
  /// In zh, this message translates to:
  /// **'CBT 重评效果图，{count} 条重评记录'**
  String moodTrendSemanticsCbt(Object count);

  /// No description provided for @medDetailActive.
  ///
  /// In zh, this message translates to:
  /// **'在用'**
  String get medDetailActive;

  /// No description provided for @medDetailStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停'**
  String get medDetailStopped;

  /// No description provided for @medDetailAdherence.
  ///
  /// In zh, this message translates to:
  /// **'依从性'**
  String get medDetailAdherence;

  /// No description provided for @medDetailLast30.
  ///
  /// In zh, this message translates to:
  /// **'近30天'**
  String get medDetailLast30;

  /// No description provided for @medDetailDays.
  ///
  /// In zh, this message translates to:
  /// **'服药天数'**
  String get medDetailDays;

  /// No description provided for @medDetailLast30Record.
  ///
  /// In zh, this message translates to:
  /// **'近30天记录'**
  String get medDetailLast30Record;

  /// No description provided for @medDetailEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get medDetailEdit;

  /// No description provided for @medDetailSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get medDetailSettings;

  /// No description provided for @medDetailHistory.
  ///
  /// In zh, this message translates to:
  /// **'用药历史'**
  String get medDetailHistory;

  /// No description provided for @medDetailBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get medDetailBasicInfo;

  /// No description provided for @medDetailRefill.
  ///
  /// In zh, this message translates to:
  /// **'续方'**
  String get medDetailRefill;

  /// No description provided for @moodCbtSituation.
  ///
  /// In zh, this message translates to:
  /// **'情境'**
  String get moodCbtSituation;

  /// No description provided for @moodCbtAutoThought.
  ///
  /// In zh, this message translates to:
  /// **'自动思维'**
  String get moodCbtAutoThought;

  /// No description provided for @moodCbtEvidenceFor.
  ///
  /// In zh, this message translates to:
  /// **'支持证据'**
  String get moodCbtEvidenceFor;

  /// No description provided for @moodCbtEvidenceAgainst.
  ///
  /// In zh, this message translates to:
  /// **'反对证据'**
  String get moodCbtEvidenceAgainst;

  /// No description provided for @moodCbtAltThought.
  ///
  /// In zh, this message translates to:
  /// **'替代思维'**
  String get moodCbtAltThought;

  /// No description provided for @moodCbtRerated.
  ///
  /// In zh, this message translates to:
  /// **'重新评分'**
  String get moodCbtRerated;

  /// No description provided for @moodCbtCoreBelief.
  ///
  /// In zh, this message translates to:
  /// **'核心信念'**
  String get moodCbtCoreBelief;

  /// No description provided for @moodCbtBehavior.
  ///
  /// In zh, this message translates to:
  /// **'行为应对'**
  String get moodCbtBehavior;

  /// No description provided for @moodDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get moodDeleted;

  /// No description provided for @moodPeriodAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午'**
  String get moodPeriodAfternoon;

  /// No description provided for @settingsProfileTitle.
  ///
  /// In zh, this message translates to:
  /// **'个人资料'**
  String get settingsProfileTitle;

  /// No description provided for @settingsProfileSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'健康档案、医疗信息'**
  String get settingsProfileSubtitle;

  /// No description provided for @todaySummaryMood.
  ///
  /// In zh, this message translates to:
  /// **'心情'**
  String get todaySummaryMood;

  /// No description provided for @setupConsentMedicalDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并理解《医学免责声明》：本 App 不提供医疗建议、诊断或治疗，不能替代专业医疗服务'**
  String get setupConsentMedicalDisclaimer;

  /// No description provided for @trackingCustomize.
  ///
  /// In zh, this message translates to:
  /// **'自定义追踪项'**
  String get trackingCustomize;

  /// No description provided for @trackingUnknownItem.
  ///
  /// In zh, this message translates to:
  /// **'未知项目'**
  String get trackingUnknownItem;

  /// No description provided for @trackingPin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get trackingPin;

  /// No description provided for @trackingUnpin.
  ///
  /// In zh, this message translates to:
  /// **'取消置顶'**
  String get trackingUnpin;

  /// No description provided for @trackingHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏此项'**
  String get trackingHide;

  /// No description provided for @trackingPinned.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get trackingPinned;

  /// No description provided for @trackingCategoryEmotional.
  ///
  /// In zh, this message translates to:
  /// **'情绪状态'**
  String get trackingCategoryEmotional;

  /// No description provided for @trackingCategoryPhysical.
  ///
  /// In zh, this message translates to:
  /// **'身体指标'**
  String get trackingCategoryPhysical;

  /// No description provided for @trackingCategoryBehavioral.
  ///
  /// In zh, this message translates to:
  /// **'行为节律'**
  String get trackingCategoryBehavioral;

  /// No description provided for @trackingCategoryMedical.
  ///
  /// In zh, this message translates to:
  /// **'医疗记录'**
  String get trackingCategoryMedical;

  /// R100: 今日追蹤彙總 (placeholders: tracked=已追蹤數， total=總數）
  ///
  /// In zh, this message translates to:
  /// **'今日已追踪 {tracked}/{total} 项'**
  String todayTrackingSummary(int tracked, int total);

  /// R104: 情緒詳情頁錄音標籤 (placeholder {duration} 是時長）
  ///
  /// In zh, this message translates to:
  /// **'录音 {duration}'**
  String moodRecordingLabel(String duration);

  /// No description provided for @medicationNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入药物名称'**
  String get medicationNameRequired;

  /// R104: 添加藥物成功提示 (placeholder {name} 是藥名）
  ///
  /// In zh, this message translates to:
  /// **'已添加 {name}'**
  String medicationAdded(String name);

  /// No description provided for @medicationStatusInUse.
  ///
  /// In zh, this message translates to:
  /// **'在用'**
  String get medicationStatusInUse;

  /// No description provided for @medicationStatusStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停'**
  String get medicationStatusStopped;

  /// R104: 影響因素分析記錄數 (placeholder {count} 是數量）
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String factorAnalysisCount(int count);

  /// No description provided for @setupConsentAgreeAll.
  ///
  /// In zh, this message translates to:
  /// **'我已阅读并同意以上所有协议'**
  String get setupConsentAgreeAll;

  /// No description provided for @assessmentComparisonImproved.
  ///
  /// In zh, this message translates to:
  /// **'好转'**
  String get assessmentComparisonImproved;

  /// No description provided for @assessmentComparisonWorsened.
  ///
  /// In zh, this message translates to:
  /// **'恶化'**
  String get assessmentComparisonWorsened;

  /// No description provided for @assessmentComparisonUnchanged.
  ///
  /// In zh, this message translates to:
  /// **'持平'**
  String get assessmentComparisonUnchanged;

  /// No description provided for @assessmentComparisonFirst.
  ///
  /// In zh, this message translates to:
  /// **'首次评估'**
  String get assessmentComparisonFirst;

  /// 評估對比： 分數差為 0 時的文案
  ///
  /// In zh, this message translates to:
  /// **'和上次一样（{delta}）'**
  String assessmentDeltaSame(int delta);

  /// 評估對比： 分數比上次高
  ///
  /// In zh, this message translates to:
  /// **'比上次高 {delta} 分'**
  String assessmentDeltaHigher(int delta);

  /// 評估對比： 分數比上次低
  ///
  /// In zh, this message translates to:
  /// **'比上次低 {delta} 分'**
  String assessmentDeltaLower(int delta);

  /// 評估對比： 未知量表的嚴重度等級兜底
  ///
  /// In zh, this message translates to:
  /// **'等级 {rank}'**
  String assessmentSeverityRank(int rank);

  /// No description provided for @checkInTypeAssessment.
  ///
  /// In zh, this message translates to:
  /// **'心理量表评估'**
  String get checkInTypeAssessment;

  /// 日曆詳情： 評估事件副標題 （總分）
  ///
  /// In zh, this message translates to:
  /// **'总分 {total}'**
  String dayDetailTotalScore(int total);

  /// No description provided for @dayDetailScaleAssessment.
  ///
  /// In zh, this message translates to:
  /// **'心理量表评估'**
  String get dayDetailScaleAssessment;

  /// No description provided for @medTodayPending.
  ///
  /// In zh, this message translates to:
  /// **'待服'**
  String get medTodayPending;

  /// No description provided for @medTodayTaken.
  ///
  /// In zh, this message translates to:
  /// **'已服'**
  String get medTodayTaken;

  /// No description provided for @medTodayRefill.
  ///
  /// In zh, this message translates to:
  /// **'需续方'**
  String get medTodayRefill;

  /// No description provided for @homeQuickActionView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get homeQuickActionView;

  /// No description provided for @ventTagFamily.
  ///
  /// In zh, this message translates to:
  /// **'家庭'**
  String get ventTagFamily;

  /// No description provided for @ventTagWork.
  ///
  /// In zh, this message translates to:
  /// **'工作'**
  String get ventTagWork;

  /// No description provided for @ventTagStudy.
  ///
  /// In zh, this message translates to:
  /// **'学业'**
  String get ventTagStudy;

  /// No description provided for @ventTagRelationship.
  ///
  /// In zh, this message translates to:
  /// **'亲密关系'**
  String get ventTagRelationship;

  /// No description provided for @ventTagFriends.
  ///
  /// In zh, this message translates to:
  /// **'朋友'**
  String get ventTagFriends;

  /// No description provided for @ventTagHealth.
  ///
  /// In zh, this message translates to:
  /// **'身体'**
  String get ventTagHealth;

  /// No description provided for @ventTagMood.
  ///
  /// In zh, this message translates to:
  /// **'情绪'**
  String get ventTagMood;

  /// No description provided for @ventTagOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get ventTagOther;

  /// No description provided for @statusPhraseLow1.
  ///
  /// In zh, this message translates to:
  /// **'有点难过'**
  String get statusPhraseLow1;

  /// No description provided for @statusPhraseLow2.
  ///
  /// In zh, this message translates to:
  /// **'心情很低落'**
  String get statusPhraseLow2;

  /// No description provided for @statusPhraseLow3.
  ///
  /// In zh, this message translates to:
  /// **'想哭'**
  String get statusPhraseLow3;

  /// No description provided for @statusPhraseLow4.
  ///
  /// In zh, this message translates to:
  /// **'提不起劲'**
  String get statusPhraseLow4;

  /// No description provided for @statusPhraseTired1.
  ///
  /// In zh, this message translates to:
  /// **'疲惫但平静'**
  String get statusPhraseTired1;

  /// No description provided for @statusPhraseTired2.
  ///
  /// In zh, this message translates to:
  /// **'好累'**
  String get statusPhraseTired2;

  /// No description provided for @statusPhraseTired3.
  ///
  /// In zh, this message translates to:
  /// **'身体被掏空'**
  String get statusPhraseTired3;

  /// No description provided for @statusPhraseTired4.
  ///
  /// In zh, this message translates to:
  /// **'只想躺着'**
  String get statusPhraseTired4;

  /// No description provided for @statusPhraseCalm1.
  ///
  /// In zh, this message translates to:
  /// **'平静'**
  String get statusPhraseCalm1;

  /// No description provided for @statusPhraseCalm2.
  ///
  /// In zh, this message translates to:
  /// **'安稳'**
  String get statusPhraseCalm2;

  /// No description provided for @statusPhraseCalm3.
  ///
  /// In zh, this message translates to:
  /// **'淡淡的'**
  String get statusPhraseCalm3;

  /// No description provided for @statusPhraseCalm4.
  ///
  /// In zh, this message translates to:
  /// **'没什么特别'**
  String get statusPhraseCalm4;

  /// No description provided for @statusPhrasePositive1.
  ///
  /// In zh, this message translates to:
  /// **'被治愈了'**
  String get statusPhrasePositive1;

  /// No description provided for @statusPhrasePositive2.
  ///
  /// In zh, this message translates to:
  /// **'心情不错'**
  String get statusPhrasePositive2;

  /// No description provided for @statusPhrasePositive3.
  ///
  /// In zh, this message translates to:
  /// **'充满能量'**
  String get statusPhrasePositive3;

  /// No description provided for @statusPhrasePositive4.
  ///
  /// In zh, this message translates to:
  /// **'有盼头'**
  String get statusPhrasePositive4;

  /// No description provided for @statusPhrasePositive5.
  ///
  /// In zh, this message translates to:
  /// **'很快乐'**
  String get statusPhrasePositive5;

  /// No description provided for @moodReviewEncouragementEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这周还没记录心情，从现在开始吧'**
  String get moodReviewEncouragementEmpty;

  /// No description provided for @moodReviewEncouragementLow.
  ///
  /// In zh, this message translates to:
  /// **'最近有些辛苦，记得照顾自己'**
  String get moodReviewEncouragementLow;

  /// No description provided for @moodReviewEncouragementMid.
  ///
  /// In zh, this message translates to:
  /// **'情绪有起伏，倾诉会好受些'**
  String get moodReviewEncouragementMid;

  /// No description provided for @moodReviewEncouragementHigh.
  ///
  /// In zh, this message translates to:
  /// **'状态不错，继续保持'**
  String get moodReviewEncouragementHigh;

  /// No description provided for @moodReviewEncouragementNoAvg.
  ///
  /// In zh, this message translates to:
  /// **'继续记录，慢慢了解自己的情绪'**
  String get moodReviewEncouragementNoAvg;

  /// 1.1.0 round 7b: 导入摘要 - 药条数
  ///
  /// In zh, this message translates to:
  /// **'{n} 药'**
  String importSummaryMedication(int n);

  /// 1.1.0 round 7b: 导入摘要 - 打卡条数
  ///
  /// In zh, this message translates to:
  /// **'{n} 打卡'**
  String importSummaryCheckIn(int n);

  /// 1.1.0 round 7b: 导入摘要 - 报告条数
  ///
  /// In zh, this message translates to:
  /// **'{n} 报告'**
  String importSummaryReport(int n);

  /// 1.1.0 round 7b: 导入摘要 - 情绪条数
  ///
  /// In zh, this message translates to:
  /// **'{n} 情绪'**
  String importSummaryMood(int n);

  /// 1.1.0 round 7b: 导入摘要 - 树洞条数
  ///
  /// In zh, this message translates to:
  /// **'{n} 树洞'**
  String importSummaryVent(int n);

  /// CBT PDF header — mood score label (R113 BUG A: 硬编码中文 PDF 头本地化)
  ///
  /// In zh, this message translates to:
  /// **'情绪'**
  String get cbtExportPdfMoodLabel;

  /// CBT PDF rerated section — original score prefix label (R113 BUG A)
  ///
  /// In zh, this message translates to:
  /// **'原'**
  String get cbtExportPdfOriginalScoreLabel;

  /// No description provided for @psychoTipsTitle.
  ///
  /// In zh, this message translates to:
  /// **'心理技巧'**
  String get psychoTipsTitle;

  /// No description provided for @psychoTipBreathTitle.
  ///
  /// In zh, this message translates to:
  /// **'正念呼吸'**
  String get psychoTipBreathTitle;

  /// No description provided for @psychoTipBreathSummary.
  ///
  /// In zh, this message translates to:
  /// **'通过关注呼吸回到当下，缓解焦虑与紧张'**
  String get psychoTipBreathSummary;

  /// No description provided for @psychoTipBreathStep1.
  ///
  /// In zh, this message translates to:
  /// **'找个舒适的位置坐下，轻轻闭上眼睛'**
  String get psychoTipBreathStep1;

  /// No description provided for @psychoTipBreathStep2.
  ///
  /// In zh, this message translates to:
  /// **'深吸气 4 秒，感受空气充满身体'**
  String get psychoTipBreathStep2;

  /// No description provided for @psychoTipBreathStep3.
  ///
  /// In zh, this message translates to:
  /// **'屏住呼吸 2 秒'**
  String get psychoTipBreathStep3;

  /// No description provided for @psychoTipBreathStep4.
  ///
  /// In zh, this message translates to:
  /// **'缓缓呼气 6 秒，让肩膀和身体放松'**
  String get psychoTipBreathStep4;

  /// No description provided for @psychoTipBreathStep5.
  ///
  /// In zh, this message translates to:
  /// **'重复 3-5 分钟，让注意力回到呼吸上'**
  String get psychoTipBreathStep5;

  /// No description provided for @psychoTipNameTitle.
  ///
  /// In zh, this message translates to:
  /// **'情绪命名'**
  String get psychoTipNameTitle;

  /// No description provided for @psychoTipNameSummary.
  ///
  /// In zh, this message translates to:
  /// **'给情绪贴上名字，能有效降低它的强度'**
  String get psychoTipNameSummary;

  /// No description provided for @psychoTipNameStep1.
  ///
  /// In zh, this message translates to:
  /// **'停下来，感受此刻身体有哪些反应'**
  String get psychoTipNameStep1;

  /// No description provided for @psychoTipNameStep2.
  ///
  /// In zh, this message translates to:
  /// **'在心里问自己：我现在的情绪是什么'**
  String get psychoTipNameStep2;

  /// No description provided for @psychoTipNameStep3.
  ///
  /// In zh, this message translates to:
  /// **'用一个词描述它，比如「烦躁」「难过」「紧张」'**
  String get psychoTipNameStep3;

  /// No description provided for @psychoTipNameStep4.
  ///
  /// In zh, this message translates to:
  /// **'说出来或写下来：「我感到……」'**
  String get psychoTipNameStep4;

  /// No description provided for @psychoTipNameStep5.
  ///
  /// In zh, this message translates to:
  /// **'观察情绪的变化，不去评判它'**
  String get psychoTipNameStep5;

  /// No description provided for @psychoTipCbtTitle.
  ///
  /// In zh, this message translates to:
  /// **'认知重构'**
  String get psychoTipCbtTitle;

  /// No description provided for @psychoTipCbtSummary.
  ///
  /// In zh, this message translates to:
  /// **'识别并调整不合理的自动思维，可搭配 CBT 思维记录'**
  String get psychoTipCbtSummary;

  /// No description provided for @psychoTipCbtStep1.
  ///
  /// In zh, this message translates to:
  /// **'记录引发情绪的具体情境'**
  String get psychoTipCbtStep1;

  /// No description provided for @psychoTipCbtStep2.
  ///
  /// In zh, this message translates to:
  /// **'写下脑海中冒出的自动思维'**
  String get psychoTipCbtStep2;

  /// No description provided for @psychoTipCbtStep3.
  ///
  /// In zh, this message translates to:
  /// **'列出支持与反对这个想法的证据'**
  String get psychoTipCbtStep3;

  /// No description provided for @psychoTipCbtStep4.
  ///
  /// In zh, this message translates to:
  /// **'写出更平衡、更符合事实的替代想法'**
  String get psychoTipCbtStep4;

  /// No description provided for @psychoTipCbtStep5.
  ///
  /// In zh, this message translates to:
  /// **'在情绪日记中使用 5 栏 CBT 记录练习'**
  String get psychoTipCbtStep5;

  /// No description provided for @psychoTipGroundTitle.
  ///
  /// In zh, this message translates to:
  /// **'5-4-3-2-1 感官接地'**
  String get psychoTipGroundTitle;

  /// No description provided for @psychoTipGroundSummary.
  ///
  /// In zh, this message translates to:
  /// **'用五种感官觉察当下，把注意力从焦虑中拉回来'**
  String get psychoTipGroundSummary;

  /// No description provided for @psychoTipGroundStep1.
  ///
  /// In zh, this message translates to:
  /// **'说出你看到的 5 样东西'**
  String get psychoTipGroundStep1;

  /// No description provided for @psychoTipGroundStep2.
  ///
  /// In zh, this message translates to:
  /// **'感受你触碰到的 4 种触感'**
  String get psychoTipGroundStep2;

  /// No description provided for @psychoTipGroundStep3.
  ///
  /// In zh, this message translates to:
  /// **'仔细听你听到的 3 种声音'**
  String get psychoTipGroundStep3;

  /// No description provided for @psychoTipGroundStep4.
  ///
  /// In zh, this message translates to:
  /// **'闻到你周围的 2 种气味'**
  String get psychoTipGroundStep4;

  /// No description provided for @psychoTipGroundStep5.
  ///
  /// In zh, this message translates to:
  /// **'感受口中的 1 种味道'**
  String get psychoTipGroundStep5;

  /// No description provided for @psychoTipPmrTitle.
  ///
  /// In zh, this message translates to:
  /// **'渐进式肌肉放松'**
  String get psychoTipPmrTitle;

  /// No description provided for @psychoTipPmrSummary.
  ///
  /// In zh, this message translates to:
  /// **'依次收紧再放松身体各肌肉群，释放身体的紧张'**
  String get psychoTipPmrSummary;

  /// No description provided for @psychoTipPmrStep1.
  ///
  /// In zh, this message translates to:
  /// **'坐或躺下，找一个舒适的姿势'**
  String get psychoTipPmrStep1;

  /// No description provided for @psychoTipPmrStep2.
  ///
  /// In zh, this message translates to:
  /// **'从脚趾开始，用力收紧 5 秒'**
  String get psychoTipPmrStep2;

  /// No description provided for @psychoTipPmrStep3.
  ///
  /// In zh, this message translates to:
  /// **'松开，体会放松的感觉约 10 秒'**
  String get psychoTipPmrStep3;

  /// No description provided for @psychoTipPmrStep4.
  ///
  /// In zh, this message translates to:
  /// **'依次向上：小腿、大腿、腹部、手臂、肩膀'**
  String get psychoTipPmrStep4;

  /// No description provided for @psychoTipPmrStep5.
  ///
  /// In zh, this message translates to:
  /// **'最后放松面部与头皮，完成全身扫描'**
  String get psychoTipPmrStep5;

  /// No description provided for @ventAgreementTitle.
  ///
  /// In zh, this message translates to:
  /// **'树洞使用公约'**
  String get ventAgreementTitle;

  /// No description provided for @ventAgreementBody.
  ///
  /// In zh, this message translates to:
  /// **'你的树洞是只属于你的私密空间，请了解这几点：\n· 所有倾诉内容仅保存在本机并加密，绝不外传\n· 树洞内容不参与任何分析、推荐或通知\n· 请温柔地对待自己，尊重每一份情绪\n· 若感到极度痛苦或有自伤念头，请使用危机热线寻求帮助'**
  String get ventAgreementBody;

  /// No description provided for @ventAgreementConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get ventAgreementConfirm;

  /// No description provided for @worryTimelineTitle.
  ///
  /// In zh, this message translates to:
  /// **'烦恼时间线'**
  String get worryTimelineTitle;

  /// No description provided for @worryArchiveTitle.
  ///
  /// In zh, this message translates to:
  /// **'忆往昔'**
  String get worryArchiveTitle;

  /// No description provided for @worrySectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'烦恼心事'**
  String get worrySectionTitle;

  /// No description provided for @worrySectionArchiveAction.
  ///
  /// In zh, this message translates to:
  /// **'忆往昔'**
  String get worrySectionArchiveAction;

  /// No description provided for @worryEntryCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条记录'**
  String worryEntryCount(Object count);

  /// No description provided for @worryContinueAction.
  ///
  /// In zh, this message translates to:
  /// **'继续倾诉'**
  String get worryContinueAction;

  /// No description provided for @worryResolveAction.
  ///
  /// In zh, this message translates to:
  /// **'不再烦恼啦'**
  String get worryResolveAction;

  /// No description provided for @worryReopenAction.
  ///
  /// In zh, this message translates to:
  /// **'又烦恼了'**
  String get worryReopenAction;

  /// No description provided for @worryResolveConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'放下这个烦恼？'**
  String get worryResolveConfirmTitle;

  /// No description provided for @worryResolveConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'确认后它会被收藏到「忆往昔」，随时可以「又烦恼了」重新打开。'**
  String get worryResolveConfirmBody;

  /// No description provided for @worryResolveConfirmOk.
  ///
  /// In zh, this message translates to:
  /// **'放下啦'**
  String get worryResolveConfirmOk;

  /// No description provided for @worryResolveDone.
  ///
  /// In zh, this message translates to:
  /// **'🎉 恭喜，你放下了一个烦恼'**
  String get worryResolveDone;

  /// No description provided for @worryReopenDone.
  ///
  /// In zh, this message translates to:
  /// **'已重新打开，需要的时候随时来倾诉'**
  String get worryReopenDone;

  /// No description provided for @worryRenameTitle.
  ///
  /// In zh, this message translates to:
  /// **'重命名烦恼'**
  String get worryRenameTitle;

  /// No description provided for @worryRenameAction.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get worryRenameAction;

  /// No description provided for @worryNewOption.
  ///
  /// In zh, this message translates to:
  /// **'新建烦恼'**
  String get worryNewOption;

  /// No description provided for @worryNoWorry.
  ///
  /// In zh, this message translates to:
  /// **'没有关联烦恼'**
  String get worryNoWorry;

  /// No description provided for @worryDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'未命名烦恼'**
  String get worryDefaultTitle;

  /// No description provided for @worryFieldLabel.
  ///
  /// In zh, this message translates to:
  /// **'关联烦恼'**
  String get worryFieldLabel;

  /// No description provided for @worryFieldHint.
  ///
  /// In zh, this message translates to:
  /// **'选择或新建一个烦恼，把这次心情记到它的时间线上'**
  String get worryFieldHint;

  /// No description provided for @worryTimelineEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这个烦恼还没有记录，从「继续倾诉」开始吧'**
  String get worryTimelineEmpty;

  /// No description provided for @worryArchiveEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有放下过的烦恼。把心情记成烦恼时间线，成长会被珍藏。'**
  String get worryArchiveEmpty;

  /// No description provided for @worryArchiveCount.
  ///
  /// In zh, this message translates to:
  /// **'已放下 {count} 个烦恼'**
  String worryArchiveCount(Object count);

  /// No description provided for @worryOpenCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个进行中'**
  String worryOpenCount(Object count);

  /// No description provided for @worryStatusOpen.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get worryStatusOpen;

  /// No description provided for @worryStatusResolved.
  ///
  /// In zh, this message translates to:
  /// **'已放下'**
  String get worryStatusResolved;

  /// No description provided for @worryThreadNotFound.
  ///
  /// In zh, this message translates to:
  /// **'这个烦恼找不到了，可能已经删除'**
  String get worryThreadNotFound;

  /// No description provided for @dbResetPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'无法打开本地数据库'**
  String get dbResetPromptTitle;

  /// No description provided for @dbResetPromptBody.
  ///
  /// In zh, this message translates to:
  /// **'本地加密数据与密钥不匹配（常见于系统备份恢复只还原了数据、未还原密钥）。你可以先点「重试」看看数据是否恢复；若仍无法打开，可重置本地数据重新开始。'**
  String get dbResetPromptBody;

  /// No description provided for @dbResetPromptReset.
  ///
  /// In zh, this message translates to:
  /// **'重置本地数据'**
  String get dbResetPromptReset;

  /// No description provided for @dbResetPromptConfirm.
  ///
  /// In zh, this message translates to:
  /// **'重置将删除本机全部记录，且无法恢复。确认重置吗？'**
  String get dbResetPromptConfirm;

  /// No description provided for @moodTrendSemanticsAvg.
  ///
  /// In zh, this message translates to:
  /// **'平均 {average} 分'**
  String moodTrendSemanticsAvg(Object average);
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
