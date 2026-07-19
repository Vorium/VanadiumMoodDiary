// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '慢病管家';

  @override
  String get appTagline => '我今天吃了药';

  @override
  String get homeCheckIn => '我今天吃了药';

  @override
  String get homeCheckedIn => '今天已打卡 ✓';

  @override
  String homeStreak(int days) {
    return '已坚持 $days 天';
  }

  @override
  String homeLastMed(String time) {
    return '最后吃药：$time';
  }

  @override
  String homeNextReminder(String time) {
    return '下次提醒：$time';
  }

  @override
  String get homeStillOnline => '🌱 你还在线';

  @override
  String get homeTempMed => '临时吃药 +';

  @override
  String get homeStreakBroken => '少 1 次没关系，明天继续';

  @override
  String setupStep(int current, int total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String get setupHello => '你好，我是慢病管家';

  @override
  String get setupIntro => '1 分钟设置好，然后每天 1 次打卡';

  @override
  String get setupName => '你的名字';

  @override
  String get setupNameHint => '小明';

  @override
  String get setupContacts => '紧急联系人邮箱（至少 1 个）';

  @override
  String get setupContactHint => 'mom@example.com';

  @override
  String get setupAddContact => '+ 添加另一个联系人';

  @override
  String get setupNext => '下一步 →';

  @override
  String get setupMedName => '药名';

  @override
  String get setupMedNameHint => '请输入药盒上的名称（选填）';

  @override
  String get setupMedFrequency => '每日次数';

  @override
  String get setupMedTimes1 => '1次';

  @override
  String get setupMedTimes2 => '2次';

  @override
  String get setupMedTimes3 => '3次';

  @override
  String get setupMedSchedule => '吃药时间（可填）';

  @override
  String get setupStart => '开始我的第 1 天';

  @override
  String get setupDoneTitle => '全部完成！';

  @override
  String get setupDoneSubtitle => '明天开始你的第 1 天';

  @override
  String get setupDailyRoutine => '我每天会做：';

  @override
  String get setupReminder1 => '✓ 推送 1 次提醒';

  @override
  String get setupReminder2 => '✓ 你点 1 下 = 打卡';

  @override
  String get setupReminder3 => '✓ 漏 2 天我会联系紧急人';

  @override
  String get setupPrivacy => '你的数据：';

  @override
  String get setupPrivacy1 => '• 本地加密';

  @override
  String get setupPrivacy2 => '• 不会上传云端（除邮件通知）';

  @override
  String get setupPrivacy3 => '• 你可以随时导出';

  @override
  String get settingsContacts => '紧急联系人';

  @override
  String get settingsMedication => '常吃药';

  @override
  String get settingsEmailPreview => '预览停药通知邮件';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsDisclaimer => '免责声明';

  @override
  String get settingsExport => '导出数据';

  @override
  String get settingsMedReport => '用药报告';

  @override
  String get settingsMedReportSubtitle => '选时间窗口（7/14/30 天），给医生看';

  @override
  String get settingsMedReportChooseTitle => '选择时间窗口';

  @override
  String get settingsMedReportChooseSubtitle => '会统计这段时间内的所有常吃药 + 临时用药';

  @override
  String get settingsMedReportWindow7 => '近 7 天';

  @override
  String get settingsMedReportWindow14 => '近 14 天';

  @override
  String get settingsMedReportWindow30 => '近 30 天';

  @override
  String get settingsReportHistory => '报告历史';

  @override
  String get settingsReportHistorySubtitle => '查看过去生成的用药报告';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDataManagement => '数据管理';

  @override
  String get settingsExportData => '导出数据';

  @override
  String get settingsExportSubtitle => '生成 JSON，复制到安全地方';

  @override
  String get settingsImportData => '导入数据';

  @override
  String get settingsImportSubtitle => '从 JSON 恢复（覆盖现有数据）';

  @override
  String get settingsReminders => '提醒';

  @override
  String get settingsReminderCenter => '提醒中心';

  @override
  String get settingsReminderCenterSubtitle => '管理所有提醒：每日打卡、用药时间、续方、心理评估、失联通知';

  @override
  String get settingsRefillManagement => '续方管理';

  @override
  String get settingsRefillManagementSubtitle => '集中查看所有药物的续方状态';

  @override
  String get settingsAssessment => '心理评估';

  @override
  String get settingsAssessmentHistory => '评估历史';

  @override
  String get settingsAssessmentHistorySubtitle =>
      '查看所有 PHQ-9 / GAD-7 评估的折线图与对比';

  @override
  String get settingsAboutVersion => 'v0.1.0 · 我今天吃了药';

  @override
  String get settingsDisclaimerText => '本应用不提供医疗建议，所有功能仅供参考。';

  @override
  String get settingsExportDialogTitle => '导出数据';

  @override
  String get settingsExportInstruction => '把下面这串 JSON 保存到安全的地方：';

  @override
  String get settingsExportVentWarning =>
      '说明：树洞(私密倾诉)的文字会导出，但录音文件不导出——录音存在 App 本地，重装后路径失效，无法跨设备复用。';

  @override
  String get settingsCopy => '复制';

  @override
  String get settingsActionExport => '导出';

  @override
  String get settingsActionGenerateReport => '生成报告';

  @override
  String get settingsImportDialogTitle => '导入数据';

  @override
  String get settingsImportWarning => '⚠️ 会覆盖现有所有数据，确定后再继续';

  @override
  String get settingsImportHint => '把导出的 JSON 粘贴到这里';

  @override
  String settingsImportSuccess(String summary) {
    return '导入完成：$summary';
  }

  @override
  String get settingsActionImport => '导入';

  @override
  String get settingsImportAndOverwrite => '导入并覆盖';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonDone => '完成';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonError => '出错了，请重试';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonGotIt => '我知道了';

  @override
  String get commonConfirmDelete => '删除这条？';

  @override
  String commonLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get commonDeleteWarning => '删除后无法恢复';

  @override
  String get commonEmpty => '还没有';

  @override
  String snackbarErrorTemplate(String action, String error) {
    return '$action失败：$error';
  }

  @override
  String get snackbarCopied => '已复制到剪贴板';

  @override
  String get snackbarNeedMicPermission => '需要麦克风权限';

  @override
  String get snackbarEmptyVent => '写点东西或录一段吧';

  @override
  String get snackbarStopRecording => '请先停止录音';

  @override
  String get snackbarPhoneInvalid => '号码格式不对（支持大陆/港澳台/国际）';

  @override
  String get commonConfirmOk => '确定';

  @override
  String get commonTakePhoto => '拍照';

  @override
  String get commonMedName => '药名';

  @override
  String get commonDoseUnit => '片';

  @override
  String get commonSetup => '设置';

  @override
  String commonAutoCheckinFailed(String error) {
    return '自动打卡失败：$error';
  }

  @override
  String commonCheckinFailed(String error) {
    return '打卡失败：$error';
  }

  @override
  String get commonVentDeleteWarning => '删了就没了。文字和录音都会一起删。';

  @override
  String get medsListEmpty => '还没添加常吃药';

  @override
  String get medsCalendarTitle => '用药日历';

  @override
  String get medsCalendarSubtitle => '医生视角依从性热力图 · 7/30/90 天';

  @override
  String get medsListNoActive => '没有在用的药';

  @override
  String get medsListStoppedSection => '已停药';

  @override
  String get medsSnackUpdated => '已更新';

  @override
  String get medsSnackUpdatedSoftStop => '已更新 · 软停';

  @override
  String get medsRefillPickDate => '选择续方日期';

  @override
  String medsRefillSet(String date, int days) {
    return '已设置：$date 续方，提前 $days 天提醒';
  }

  @override
  String get medsActionRefill => '设置续方';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return '已过期 $days 天 · 提前 $reminderDays 天提醒';
  }

  @override
  String medsRefillUpcoming(String date, int days, int reminderDays) {
    return '续方：$date（$days 天后）· 提前 $reminderDays 天提醒';
  }

  @override
  String get medsRefillDaysTitle => '提前几天提醒？';

  @override
  String medsRefillDaysUnit(int days) {
    return '$days 天';
  }

  @override
  String get medsRefillHint3 => '最后冲刺期';

  @override
  String get medsRefillHint5 => '比较紧';

  @override
  String get medsRefillHint7 => '推荐（默认）';

  @override
  String get medsRefillHint14 => '两周时间挂号';

  @override
  String get medsRefillHint30 => '一个月周期';

  @override
  String get notificationStatusCardTestTitle => '🔔 通知自检';

  @override
  String get notificationStatusCardTestBody => '看到这条 = 通知工作正常。如果没看到，看下面的国产手机设置';

  @override
  String get notificationStatusCardTestSent => '已发送测试通知 — 几秒内应该能收到';

  @override
  String get notificationStatusCardActionSend => '发送';

  @override
  String get notificationStatusCardQueuedTitle => '已排队的通知';

  @override
  String get notificationStatusCardEmpty => '当前没有任何待发通知。\n可能是没设提醒，或被系统后台清理了。';

  @override
  String get notificationStatusCardNoTitle => '(无标题)';

  @override
  String get notificationStatusCardWebTitle => '通知功能仅在 Android / iOS 上可用';

  @override
  String get notificationStatusCardWebSubtitle =>
      '当前是 web 端，通知由浏览器控制。请在手机上打开 App 测试。';

  @override
  String get notificationStatusCardStatusLoading => '加载中…';

  @override
  String get notificationStatusCardStatusUnsupported => '当前平台不支持查询';

  @override
  String get notificationStatusCardStatusNone => '⚠️ 没有待发通知 — 提醒可能没设上';

  @override
  String notificationStatusCardStatusCount(int count) {
    return '✓ 已排队 $count 条待发通知';
  }

  @override
  String get notificationStatusCardTitle => '通知与提醒';

  @override
  String get notificationStatusCardTestButtonTitle => '测试通知';

  @override
  String get notificationStatusCardTestButtonSubtitle => '点一下立即推一条，确认通知能正常弹出';

  @override
  String get notificationStatusCardViewButtonTitle => '查看已排队通知';

  @override
  String get notificationStatusCardViewButtonSubtitle => '展示当前所有待发的提醒';

  @override
  String get notificationStatusCardOemTitle => '国产手机没收到通知?';

  @override
  String get notificationStatusCardOemSubtitle =>
      '小米/华为/OPPO/Vivo 默认会杀后台，点这里看怎么设';

  @override
  String get notificationStatusCardOemBrandXiaomi => '小米 / Redmi';

  @override
  String get notificationStatusCardOemStepXiaomi1 =>
      '设置 → 应用 → 慢病管家 → 自启动 → 开启';

  @override
  String get notificationStatusCardOemStepXiaomi2 =>
      '设置 → 应用 → 慢病管家 → 省电策略 → 无限制';

  @override
  String get notificationStatusCardOemStepXiaomi3 =>
      '设置 → 通知 → 慢病管家 → 允许通知 + 锁屏通知';

  @override
  String get notificationStatusCardOemBrandHuawei => '华为 / 荣耀';

  @override
  String get notificationStatusCardOemStepHuawei1 =>
      '设置 → 应用 → 慢病管家 → 电池 → 启动管理 → 允许自启动';

  @override
  String get notificationStatusCardOemStepHuawei2 =>
      '设置 → 应用 → 慢病管家 → 通知 → 全部开启';

  @override
  String get notificationStatusCardOemStepHuawei3 => '手机管家 → 应用启动管理 → 关闭「自动管理」';

  @override
  String get notificationStatusCardOemBrandOppo => 'OPPO / realme / 一加';

  @override
  String get notificationStatusCardOemStepOppo1 =>
      '设置 → 电池 → 耗电保护 → 慢病管家 → 允许后台运行';

  @override
  String get notificationStatusCardOemStepOppo2 => '设置 → 通知 → 慢病管家 → 全部开启';

  @override
  String get notificationStatusCardOemStepOppo3 => '「最近任务」界面上锁 App（下滑小锁图标）';

  @override
  String get notificationStatusCardOemBrandVivo => 'Vivo / iQOO';

  @override
  String get notificationStatusCardOemStepVivo1 =>
      '设置 → 电池 → 后台高耗电 → 慢病管家 → 允许';

  @override
  String get notificationStatusCardOemStepVivo2 => '设置 → 通知 → 慢病管家 → 全部开启';

  @override
  String get notificationStatusCardOemStepVivo3 => '「最近任务」界面上锁 App';

  @override
  String get notificationStatusCardOemBrandMeizu => '魅族';

  @override
  String get notificationStatusCardOemStepMeizu1 =>
      '设置 → 应用管理 → 慢病管家 → 权限管理 → 自启动 → 允许';

  @override
  String get notificationStatusCardOemStepMeizu2 => '设置 → 通知管理 → 慢病管家 → 全部开启';

  @override
  String get notificationStatusCardOemGeneralTip =>
      '通用建议：精确闹钟被某些 ROM 静默拒绝时,首次启动 App 时系统会弹「是否允许」,请选「允许」。';

  @override
  String get reminderHubDescription => '集中管理所有提醒：每天打卡、用药时间、续方日期、心理评估、失联通知。';

  @override
  String get reminderHubDailyTitle => '每日打卡提醒';

  @override
  String get reminderHubDailyDesc => '每天 20:00 推送「记得打卡」，漏 1 次没关系';

  @override
  String get reminderHubDailyStatus => '已启用 · 每天 20:00';

  @override
  String get reminderHubDailyAction => '查看通知预览';

  @override
  String get reminderHubMedicationTitle => '用药提醒';

  @override
  String get reminderHubStatusError => '出错';

  @override
  String get reminderHubRefillTitle => '续方提醒';

  @override
  String get reminderHubAssessmentTitle => '周期评估提醒';

  @override
  String reminderHubAssessmentDescEnabled(int days) {
    return '每 $days 天提醒做心理评估（PHQ-9 / GAD-7）';
  }

  @override
  String get reminderHubAssessmentDescDisabled => '关闭 · 不会推送评估提醒';

  @override
  String reminderHubAssessmentStatusEnabled(int days) {
    return '已启用 · 每 $days 天';
  }

  @override
  String get reminderHubStatusDisabled => '未启用';

  @override
  String get reminderHubConfigure => '配置';

  @override
  String get reminderHubSafetyTitle => '失联通知（安全开关）';

  @override
  String get reminderHubSmsMockWarning =>
      'SMS 通道未接通（当前使用 Mock）。失联触发时只会推本地通知，不会真发短信给紧急联系人。上 store 前必须接入真实 SMS provider。';

  @override
  String reminderHubSafetyDescEnabled(int threshold) {
    return '连续 $threshold 天没打卡 → 自动 SMS 通知紧急联系人 + 本地推送';
  }

  @override
  String get reminderHubSafetyDescDisabled => '关闭 · 不会自动通知紧急联系人';

  @override
  String reminderHubSafetyStatusEnabled(int threshold) {
    return '已启用 · 阈值 $threshold 天';
  }

  @override
  String reminderHubMedicationDescActive(int count, int times) {
    return '共 $count 种在用药物，$times 个时间点会推送提醒';
  }

  @override
  String get reminderHubMedicationDescInactive => '还没有在用药物 · 添加后会自动启用';

  @override
  String reminderHubMedicationStatusActive(int count, int times) {
    return '已启用 · $count 种 / $times 时间点';
  }

  @override
  String get reminderHubStatusNotConfigured => '未配置';

  @override
  String get reminderHubManageMedication => '管理用药';

  @override
  String get reminderHubRefillDescNone => '未给任何药物设置续方日期 · 在「用药设置」中可加';

  @override
  String reminderHubRefillDescOverdue(int overdue, int inWindow) {
    return '$overdue 种已过期续方 · $inWindow 种在提醒窗口内';
  }

  @override
  String reminderHubRefillDescActive(int count) {
    return '$count 种药物已设续方 · 临近时会推送提醒';
  }

  @override
  String reminderHubRefillStatusOverdue(int count) {
    return '已过期 $count';
  }

  @override
  String reminderHubRefillStatusInWindow(int count) {
    return '提醒中 $count';
  }

  @override
  String reminderHubRefillStatusActive(int count) {
    return '已启用 · $count 种';
  }

  @override
  String get reminderHubManageRefill => '管理续方';

  @override
  String get reminderHubEnable => '启用';

  @override
  String get reminderHubAssessmentSubtitle => '每隔 N 天推送一次心理评估';

  @override
  String get reminderHubInterval => '提醒间隔';

  @override
  String reminderHubEveryNDays(int days) {
    return '每 $days 天';
  }

  @override
  String get reminderHubSafetyDescription =>
      '连续 N 天没打卡 → 自动 SMS 通知所有启用的紧急联系人 + 本地推送';

  @override
  String get reminderHubTriggerThreshold => '触发阈值（连续 N 天没打卡）';

  @override
  String reminderHubNDays(int days) {
    return '$days 天';
  }

  @override
  String setupContactNameLabel(int index) {
    return '联系人 $index 姓名';
  }

  @override
  String get setupContactNameHint => '称呼（选填）';

  @override
  String setupContactPhoneLabel(int index) {
    return '紧急联系人手机号 $index';
  }

  @override
  String get setupContactPhoneHint => '13800138000';
}
