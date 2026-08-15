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
  String get homeCheckIn => '我今天吃了药';

  @override
  String get homeCheckedIn => '今天已打卡 ✓';

  @override
  String homeStreak(int days) {
    return '已坚持 $days 天';
  }

  @override
  String homeLastMed(Object time) {
    return '最后吃药：$time';
  }

  @override
  String homeNextReminder(Object time) {
    return '下次提醒：$time';
  }

  @override
  String get homeStillOnline => '🌱 您还在线';

  @override
  String get homeStreakBroken => '少 1 次没关系，明天继续';

  @override
  String setupStep(int current, int total) {
    return '第 $current 步 ／ 共 $total 步';
  }

  @override
  String get setupHello => '您好，我是慢病管家';

  @override
  String get setupIntro => '1 分钟设置好，然后每天 1 次打卡';

  @override
  String get setupName => '您的名字（选填）';

  @override
  String get setupNameHint => '小明';

  @override
  String get setupNext => '下一步 →';

  @override
  String get setupMedNameHint => '请输入药盒上的名称（选填）';

  @override
  String get setupStart => '开始我的第 1 天';

  @override
  String get setupDoneTitle => '全部完成！';

  @override
  String get setupDoneSubtitle => '明天开始您的第 1 天';

  @override
  String get setupDailyRoutine => '我每天会做：';

  @override
  String get setupReminder1 => '✓ 推送 1 次提醒';

  @override
  String get setupReminder2 => '✓ 您点 1 下 = 打卡';

  @override
  String get setupReminder3 => '✓ 漏 2 天提醒会升级，请及时打卡';

  @override
  String get setupPrivacy => '您的数据：';

  @override
  String get setupPrivacy1 => '• 本地加密';

  @override
  String get setupPrivacy2 => '• 不会上传到任何云端服务器';

  @override
  String get setupPrivacy3 => '• 您可以随时导出';

  @override
  String get settingsMedication => '常吃药';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsDisclaimer => '免责声明';

  @override
  String get settingsMedReport => '用药报告';

  @override
  String get settingsMedReportSubtitle => '选时间窗口（7／14／30 天），给医生看';

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
      '查看所有 PHQ-9 ／ GAD-7 评估的折线图与对比';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version · 我今天吃了药';
  }

  @override
  String get settingsDisclaimerText => '本应用不提供医疗建议，所有功能仅供参考。';

  @override
  String get settingsExportRiskTitle => '明文风险提示';

  @override
  String get settingsExportRiskBody =>
      '您即将导出的数据为明文文件，含您的个人健康等敏感信息（用药、打卡、紧急联系人、树洞文字）。请务必保存到安全、可信的位置（加密 U 盘 / 私人云盘），避免上传至公共云盘或发送给不可信的第三方。';

  @override
  String get settingsExportRiskLiability =>
      '一旦导出，文件的安全与保密由您自行负责，本 App 不再承担保护责任（PIPL §17 明确告知 + 用户确认）。';

  @override
  String get settingsExportRiskAcknowledge => '我已了解风险，继续导出';

  @override
  String get settingsExportDialogTitle => '导出数据';

  @override
  String get settingsExportInstruction => '把下面这串 JSON 保存到安全的地方：';

  @override
  String get settingsExportVentWarning =>
      '说明：树洞（私密倾诉）的文字会导出，但录音文件不导出——录音存在 App 本地，重装后路径失效，无法跨设备复用。';

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
  String settingsImportSuccess(Object summary) {
    return '导入完成：$summary';
  }

  @override
  String get settingsActionImport => '导入';

  @override
  String get settingsImportAndOverwrite => '导入并覆盖';

  @override
  String get settingsClearAllData => '清空所有数据';

  @override
  String get settingsClearAllDataSubtitle =>
      '删除全部打卡 ／ 用药 ／ 评估 ／ 树洞 ／ 联系人（无法恢复）';

  @override
  String get settingsClearAllDataDialogTitle => '确认清空所有数据？';

  @override
  String get settingsClearAllDataDialogBody =>
      '以下数据将被永久删除，无法恢复：\n• 打卡记录\n• 用药与服药历史\n• 心理评估结果\n• 情绪日记\n• 树洞（文字+录音）\n• 紧急联系人\n\n清空后 App 会跳回首次设置流程。建议先导出 JSON 备份。';

  @override
  String get settingsClearAllDataConfirm => '我已备份，确认清空';

  @override
  String get settingsClearAllDataSuccess => '已清空所有数据';

  @override
  String get commonSave => '保存';

  @override
  String get commonBack => '返回';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonLoading => '加载中……';

  @override
  String get lastStartupErrorBannerBody => '上次启动出错，请截图反馈';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonRetry => '重试';

  @override
  String get commonGotIt => '我知道了';

  @override
  String get commonConfirmDelete => '删除这条？';

  @override
  String get commonOptionNotSelected => '未选';

  @override
  String legalConsentWithdrawn(int current, int total) {
    return '已撤回 ($current/$total)';
  }

  @override
  String legalConsentReAgreed(int current, int total) {
    return '已重新同意 ($current/$total)';
  }

  @override
  String commonLoadFailed(Object error) {
    return '加载失败：$error';
  }

  @override
  String snackbarErrorTemplate(Object action, Object error) {
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
  String get commonConfirmOk => '确定';

  @override
  String get commonMedName => '药名';

  @override
  String get commonDoseUnit => '片';

  @override
  String get commonSetup => '设置';

  @override
  String get commonVentDeleteWarning => '删了就没了。文字和录音都会一起删。';

  @override
  String get medsListEmpty => '还没添加常吃药';

  @override
  String get medsCalendarTitle => '用药日历';

  @override
  String get medsCalendarSubtitle => '医生视角依从性热力图 · 7／30／90 天';

  @override
  String get medsListNoActive => '没有在用的药';

  @override
  String get medsListNoActiveHint => '所有药物都已停用，去添加新药物开始新一阶段。';

  @override
  String get medsListAddAction => '添加药物';

  @override
  String get medsListStoppedSection => '已停药';

  @override
  String get medsSnackUpdated => '已更新';

  @override
  String get medsSnackUpdatedSoftStop => '已更新 · 软停';

  @override
  String get medsRefillPickDate => '选择续方日期';

  @override
  String medsRefillSet(Object date, int days) {
    return '已设置：$date 续方，提前 $days 天提醒';
  }

  @override
  String get medsActionRefill => '设置续方';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return '已过期 $days 天 · 提前 $reminderDays 天提醒';
  }

  @override
  String medsRefillUpcoming(Object date, int days, int reminderDays) {
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
  String get notificationStatusCardPermissionDeniedTitle => '通知权限已关闭';

  @override
  String get notificationStatusCardPermissionDeniedBody =>
      '无法发送用药提醒。请在系统设置中允许通知，或点击下方按钮前往设置。';

  @override
  String get notificationStatusCardPermissionGoSettings => '前往系统设置';

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
  String get notificationStatusCardNoTitle => '（无标题）';

  @override
  String get notificationStatusCardWebTitle => '通知功能仅在 Android ／ iOS 上可用';

  @override
  String get notificationStatusCardWebSubtitle =>
      '当前是 web 端，通知由浏览器控制。请在手机上打开 App 测试。';

  @override
  String get notificationStatusCardStatusLoading => '加载中……';

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
  String get notificationStatusCardOemTitle => '国产手机没收到通知？';

  @override
  String get notificationStatusCardOemSubtitle =>
      '小米／华为／OPPO／Vivo／三星 默认会杀后台，点这里看怎么设';

  @override
  String get notificationStatusCardOemBrandXiaomi => '小米 ／ Redmi';

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
  String get notificationStatusCardOemBrandHuawei => '华为 ／ 荣耀';

  @override
  String get notificationStatusCardOemStepHuawei1 =>
      '设置 → 应用 → 慢病管家 → 电池 → 启动管理 → 允许自启动';

  @override
  String get notificationStatusCardOemStepHuawei2 =>
      '设置 → 应用 → 慢病管家 → 通知 → 全部开启';

  @override
  String get notificationStatusCardOemStepHuawei3 => '手机管家 → 应用启动管理 → 关闭「自动管理」';

  @override
  String get notificationStatusCardOemBrandOppo => 'OPPO ／ realme ／ 一加';

  @override
  String get notificationStatusCardOemStepOppo1 =>
      '设置 → 电池 → 耗电保护 → 慢病管家 → 允许后台运行';

  @override
  String get notificationStatusCardOemStepOppo2 => '设置 → 通知 → 慢病管家 → 全部开启';

  @override
  String get notificationStatusCardOemStepOppo3 => '「最近任务」界面上锁 App（下滑小锁图标）';

  @override
  String get notificationStatusCardOemBrandVivo => 'Vivo ／ iQOO';

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
  String get notificationStatusCardOemBrandSamsung => '三星 (OneUI)';

  @override
  String get notificationStatusCardOemStepSamsung1 =>
      '设置 → 应用程序 → 慢病管家 → 通知 → 全部开启';

  @override
  String get notificationStatusCardOemStepSamsung2 =>
      '设置 → 电池 → 后台使用限制 → 慢病管家 → 改为「不受限」';

  @override
  String get notificationStatusCardOemBrandOthers => '其他（中兴／努比亚／红魔／联想／三星 Knox）';

  @override
  String get notificationStatusCardOemStepOthers1 =>
      '设置 → 应用 → 慢病管家 → 通知 → 全部开启';

  @override
  String get notificationStatusCardOemStepOthers2 => '设置 → 电池 → 后台运行 → 改为「允许」';

  @override
  String get notificationStatusCardOemGeneralTip =>
      '通用建议：精确闹钟被某些 ROM 静默拒绝时，首次启动 App 时系统会弹「是否允许」，请选「允许」。';

  @override
  String get reminderHubDescription => '集中管理所有提醒：每天打卡、用药时间、续方日期、心理评估、失联通知。';

  @override
  String get reminderHubDailyTitle => '每日打卡提醒';

  @override
  String get reminderHubDailyDesc => '每天 20:00 推送「记得打卡」，漏 1 次没关系';

  @override
  String get reminderHubDailyStatus => '已启用 · 每天 20:00';

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
    return '每 $days 天提醒做心理评估（PHQ-9 ／ GAD-7）';
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
  String reminderHubMedicationDescActive(int count, int times) {
    return '共 $count 种在用药物，$times 个时间点会推送提醒';
  }

  @override
  String get reminderHubMedicationDescInactive => '还没有在用药物 · 添加后会自动启用';

  @override
  String reminderHubMedicationStatusActive(int count, int times) {
    return '已启用 · $count 种 ／ $times 时间点';
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
  String reminderHubNDays(int days) {
    return '$days 天';
  }

  @override
  String get ventListTitle => '我的树洞';

  @override
  String get legalVentWithdrawTitle => '撤回树洞同意';

  @override
  String get legalVentWithdrawBody => '树洞内容是您最私密的数据。撤回同意后，您可选择以下方式处理已有数据：';

  @override
  String get legalVentWithdrawDelete => '立即删除';

  @override
  String get legalVentWithdrawDeleteDesc => '所有树洞文字 + 录音文件立即物理删除，不可恢复';

  @override
  String get legalVentWithdrawSeal => '加密封存';

  @override
  String get legalVentWithdrawSealDesc => '数据保留在本地但加密，UI 不可见，重新同意后可恢复';

  @override
  String legalVentWithdrawnDeleted(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条',
      one: '1 条',
      zero: '0 条',
    );
    return '已删除 $_temp0树洞';
  }

  @override
  String get legalVentWithdrawnSealed => '已加密封存，数据保留在本地';

  @override
  String get legalVentDeleteRetry => '重试删除';

  @override
  String get ventSealedTitle => '已加密封存';

  @override
  String get ventSealedSubtitle => '您已撤回树洞同意。所有数据已加密封存，UI 不可见。重新同意后可恢复。';

  @override
  String get ventSealedAction => '前往法律与隐私';

  @override
  String get ventListWriteTooltip => '写一条';

  @override
  String get ventEmptyTitle => '树洞还是空的';

  @override
  String get ventEmptySubtitle => '想说什么就说出来。文字、语音都可以。\n这些话只有您自己能看到。';

  @override
  String get ventEmptyAction => '写第一句';

  @override
  String get ventVoiceLabel => '🎙️ 语音';

  @override
  String get ventDetailTitle => '树洞';

  @override
  String get ventDetailNotFound => '找不到了';

  @override
  String get ventDetailPrivacy => '🔒 私密 · 只有您能看到';

  @override
  String get ventReportTooltip => '举报或反馈';

  @override
  String get ventReportDialogTitle => '私密倾诉说明';

  @override
  String get ventReportDialogBody =>
      '树洞内容仅存储在您的设备， 不会上传任何服务器， 不存在用户间互相看到的情况。\n\n如发现 App 本身的不当内容或想反馈问题， 请前往「法律与隐私」页面联系开发者。';

  @override
  String get ventReportDialogAction => '前往法律与隐私';

  @override
  String get ventReportDialogClose => '关闭';

  @override
  String get ventToday => '今天';

  @override
  String get ventYesterday => '昨天';

  @override
  String get ventComposeTitle => '放进树洞';

  @override
  String get ventComposeHint => '今天过得怎么样……';

  @override
  String get ventRecordIdle => '按一下开始录音';

  @override
  String get ventAudioLabel => '录音';

  @override
  String get ventAudioPlayTooltip => '播放录音';

  @override
  String get audioRecordPauseTooltip => '暂停录音';

  @override
  String get audioRecordResumeTooltip => '继续录音';

  @override
  String get audioRecordStopTooltip => '停止录音';

  @override
  String get ventAudioPauseTooltip => '暂停录音';

  @override
  String get ventRerecord => '重录';

  @override
  String ventDurationSeconds(int sec) {
    return '$sec秒';
  }

  @override
  String ventDurationMinutes(int m) {
    return '$m分';
  }

  @override
  String ventDurationMinutesSeconds(int m, Object sec) {
    return '$m分$sec秒';
  }

  @override
  String get moodDialogTitle => '今天怎么样？';

  @override
  String get moodDialogPeriodLabel => '时段';

  @override
  String get moodPeriodMorning => '早上';

  @override
  String get moodPeriodNoon => '中';

  @override
  String get moodPeriodEvening => '晚上';

  @override
  String get moodPeriodNight => '夜间';

  @override
  String get moodPeriodUnspecified => '未指定';

  @override
  String get moodListFilterPeriod => '时段';

  @override
  String get moodPeriodChartTitle => '心境 4 段趋势（近 30 天）';

  @override
  String get moodDimensionMood => '情绪';

  @override
  String get moodDimensionMoodHint => '1=很差 5=很好';

  @override
  String get moodDimensionEnergy => '精力';

  @override
  String get moodDimensionEnergyHint => '1=很低 5=充沛';

  @override
  String get moodDimensionSleep => '睡眠';

  @override
  String get moodDimensionSleepHint => '1=很差 5=很好';

  @override
  String get moodDimensionAnxiety => '焦虑';

  @override
  String get moodDimensionAnxietyHint => '1=严重 5=平静';

  @override
  String get moodTagAnxiety => '焦虑';

  @override
  String get moodTagDepression => '抑郁';

  @override
  String get moodTagCalm => '平静';

  @override
  String get moodTagInsomnia => '失眠';

  @override
  String get moodTagIrritable => '烦躁';

  @override
  String get moodTagLowEnergy => '能量低';

  @override
  String get moodNoteLabel => '备注（可选）';

  @override
  String get moodNoteHint => '今天发生什么？';

  @override
  String get moodAudioRecordButton => '录语音';

  @override
  String moodAudioRecorded(Object duration) {
    return '已录 $duration';
  }

  @override
  String get moodAudioRerecord => '重录';

  @override
  String get moodAudioTranscriptLabel => '识别文字';

  @override
  String get moodAudioTranscriptPartialHint => '（仅识别前 60 秒）';

  @override
  String get moodAudioSttListening => '识别中……';

  @override
  String get moodAudioSttFailed => '识别失败，已仅保存录音';

  @override
  String get moodAudioSttUnavailable => '该设备暂不支持语音转文字';

  @override
  String get moodAudioMaxReached => '已达 3 分钟上限';

  @override
  String get moodAudioSavedWithPlay => '情绪已保存';

  @override
  String get moodAudioPlayAction => '回放';

  @override
  String get moodAudioErrorStart => '开始录音失败';

  @override
  String get moodAudioErrorStop => '停止录音失败';

  @override
  String get moodAudioErrorEncrypt => '加密录音失败';

  @override
  String get moodAudioErrorPlay => '播放失败';

  @override
  String get medsTodaySchedule => '今日服药计划';

  @override
  String get medsTotal => '总药数';

  @override
  String get medsRefillSetCount => '已设续方';

  @override
  String get medsRefillReminding => '提醒中';

  @override
  String get refillManageOverdue => '已过期';

  @override
  String get refillManageMedsList => '药物列表';

  @override
  String get refillManageSummary => '续方汇总';

  @override
  String get medsNoMedicationsAdded => '还没有添加药物';

  @override
  String get medsRefillEditHint => '点击任一行可编辑续方日期。提醒窗口：续方前 N 天（N=reminderDays）。';

  @override
  String get medsRefillStatusNotConfigured => '未设置';

  @override
  String get medsRefillStatusSet => '已设';

  @override
  String get medsRefillStatusReminding => '提醒中';

  @override
  String get medsRefillStatusOverdue => '已过期';

  @override
  String medsRefillNotSetSubtitle(int days) {
    return '未设续方日期 · 提醒窗口 $days 天';
  }

  @override
  String medsRefillExpiredDays(int days) {
    return '已过 $days 天';
  }

  @override
  String get medsRefillToday => '今天';

  @override
  String medsRefillRemainingDays(int days) {
    return '还有 $days 天';
  }

  @override
  String medsRefillSubtitleTemplate(
      Object date, Object suffix, int reminderDays) {
    return '$date $suffix · 提前 $reminderDays 天提醒';
  }

  @override
  String get assessmentLoadingBack => '正在返回上一页……';

  @override
  String assessmentAnsweredProgress(int answered, int total) {
    return '已答 $answered ／ $total';
  }

  @override
  String get assessmentSubmit => '提交并查看结果';

  @override
  String assessmentQuestionLabel(int index, Object text, Object selected) {
    return '评估题 $index：$text，4 项单选，当前：$selected';
  }

  @override
  String assessmentScoreTotal(int max) {
    return '总分（0-$max）';
  }

  @override
  String get assessmentRecommendUrgent => '强烈建议您尽快联系医生或心理治疗师。';

  @override
  String get assessmentRecommend => '建议您联系医生做进一步评估。';

  @override
  String get assessmentDisclaimer => '⚠️ 本评估仅供参考，不能代替专业诊断。\n如感到困扰，请咨询医生。';

  @override
  String get assessmentBack => '返回';

  @override
  String get assessmentRetake => '再做一次';

  @override
  String get homeHeaderDefaultTitle => '慢病管家';

  @override
  String homeHeaderKeepGoing(Object name) {
    return '$name 还在坚持';
  }

  @override
  String get ventSwipeHint => '左滑或长按条目可删除';

  @override
  String get homeStreakRestart => '今天重新开始 🌱';

  @override
  String get homeStreakDay1 => '第 1 天，迈出第一步 🌱';

  @override
  String homeStreakDays(int days) {
    return '坚持 $days 天，继续 🌿';
  }

  @override
  String homeStreakGreat(int days) {
    return '已坚持 $days 天 🌳';
  }

  @override
  String homeStreakAmazing(int days) {
    return '$days 天连击 🌲';
  }

  @override
  String homeStreakMaster(int days) {
    return '$days 天 🏔️';
  }

  @override
  String get navMood => '心情';

  @override
  String get navVent => '树洞';

  @override
  String get navTrend => '趋势';

  @override
  String get navSettings => '设置';

  @override
  String get navAppName => '慢病管家';

  @override
  String errorPageNotFound(Object path) {
    return '页面不存在：$path';
  }

  @override
  String get errorPageHint => '这个地址可能已经失效，或者链接有误。';

  @override
  String get errorPageBackHome => '返回首页';

  @override
  String assessmentReminderEnabled(int days) {
    return '已开启：每 $days 天提醒做心理评估';
  }

  @override
  String assessmentReminderChanged(int days) {
    return '已改为：每 $days 天提醒';
  }

  @override
  String assessmentReminderSubtitleEnabled(int days) {
    return '每 $days 天提醒我做一次心理评估';
  }

  @override
  String get assessmentReminderHelpText =>
      '完成一次评估后，下次提醒会从今天重新算起。\n评估结果仅您自己看得到。';

  @override
  String get assessmentReminderHintAcute => '高强度监测（适合急性期）';

  @override
  String get assessmentReminderHintCommon => '推荐（精神科常用）';

  @override
  String get assessmentReminderHintStable => '稳定期 ／ 月度覆盘';

  @override
  String get assessmentReminderHintMaintenance => '维持治疗期';

  @override
  String get assessmentReminderHintLongTerm => '长期随访';

  @override
  String get assessmentHistoryTrend => '历史趋势';

  @override
  String assessmentAverageScore(Object score) {
    return '平均 $score';
  }

  @override
  String assessmentTotalRecords(int count) {
    return '共 $count 次';
  }

  @override
  String assessmentScoreRange(int min, int max) {
    return '最低 $min ／ 最高 $max';
  }

  @override
  String get assessmentComparePrevious => '对比上次';

  @override
  String get assessmentFirstAssessmentHint => '这是您的第一次评估。下次评估后会显示和这次的对比。';

  @override
  String get assessmentPrevious => '上次';

  @override
  String get assessmentCurrent => '本次';

  @override
  String assessmentDaysSincePrevious(int days) {
    return '距上次 $days 天';
  }

  @override
  String get assessmentHistoryEmpty => '还没有评估记录';

  @override
  String get assessmentHistoryEmptyHint => '完成一次心理评估后，记录会显示在这里';

  @override
  String get assessmentHistoryStartFirst => '开始第一次评估';

  @override
  String get assessmentHistoryTotalAssessments => '总评估';

  @override
  String get assessmentHistoryTimes => '次';

  @override
  String get assessmentHistoryLatestPhq9 => '最近 PHQ-9';

  @override
  String get assessmentHistoryLatestGad7 => '最近 GAD-7';

  @override
  String get assessmentHistoryNotDone => '未做';

  @override
  String get assessmentChartNoData => '还没有数据';

  @override
  String get assessmentChartNeedMore => '只有 1 次评估，无法画趋势 — 至少需要 2 次';

  @override
  String assessmentChartRecordCount(int count) {
    return '$count 次评估';
  }

  @override
  String assessmentChartTotalScore(int score, int max) {
    return '总分 $score/$max';
  }

  @override
  String get assessmentHistoryFullRecord => '完整记录';

  @override
  String get assessmentSeverityNormal => '几乎没有';

  @override
  String get assessmentSeverityMild => '轻度';

  @override
  String get assessmentSeverityModerate => '中度';

  @override
  String get assessmentSeverityModeratelySevere => '中重度';

  @override
  String get assessmentSeveritySevere => '重度';

  @override
  String get assessmentSeverityUnknown => '未知';

  @override
  String get assessmentScalePhq9 => 'PHQ-9 抑郁筛查';

  @override
  String get assessmentScaleGad7 => 'GAD-7 焦虑筛查';

  @override
  String get setupConsentRequired => '请先完成法律文件阅读与同意';

  @override
  String get setupValidationNameRequired => '请输入您的名字';

  @override
  String get setupPresetTitle => '📋 选择预置方案';

  @override
  String get setupPresetDescription => '预置方案会填好药名 + 时间，您可以接著改。最终服药请按医嘱核对。';

  @override
  String setupPresetLoaded(Object name, int count) {
    return '已载入：$name（$count 个药）请核对药名和剂量';
  }

  @override
  String get setupMedWhatDoYouTake => '您常吃什么药？';

  @override
  String get setupMedMultiDrugHint => '（可加多个药，每个药配自己的时间和剂量；跳过不影响打卡）';

  @override
  String get setupMedEmptyHint => '还没添加药物。可以跳过——打卡不需要药物信息。';

  @override
  String get setupMedAddDrug => '+ 添加药物';

  @override
  String get setupMedLoadPreset => '📋 载入预置方案（4 种常见模式）';

  @override
  String get setupBack => '← 上一步';

  @override
  String setupMedDrugNumber(int number) {
    return '药物 $number';
  }

  @override
  String get setupMedDeleteDrug => '删除这个药';

  @override
  String get setupMedDosage => '剂量';

  @override
  String get setupMedUnit => '单位';

  @override
  String get setupMedTimeHint => '吃药时间（点 + 加）';

  @override
  String get setupMedAddTime => '加时间';

  @override
  String get setupMedTimeOptional => '（不设置时间 = 不调度提醒，仅记录）';

  @override
  String get setupConsentTitle => '使用前请阅读';

  @override
  String get setupConsentDescription =>
      '为遵守《个人信息保护法》(PIPL)，本 App 处理您的健康医疗等敏感个人信息前，需要您明确、单独同意以下 3 份文件。';

  @override
  String get setupConsentUserAgreement => '我已阅读并同意《用户协议》';

  @override
  String get setupConsentPrivacyPolicy => '我已阅读并同意《隐私政策》';

  @override
  String get setupConsentSensitiveData => '我已阅读并同意《敏感个人信息处理同意书》';

  @override
  String get setupConsentStart => '开始设置';

  @override
  String get setupConsentWithdrawHint =>
      '提示：您可以随时在「设置 → 法律与隐私」撤回同意。拒绝或撤回后，App 的相关功能将无法使用。';

  @override
  String get setupLegalUserAgreement => '用户协议';

  @override
  String get setupLegalPrivacyPolicy => '隐私政策';

  @override
  String get setupLegalSensitiveData => '敏感个人信息处理同意书';

  @override
  String get setupLegalLoadFailed => '加载失败，请检查网络或重新打开 App';

  @override
  String get setupConsentView => '查看';

  @override
  String get settingsLegalAndPrivacy => '法律与隐私';

  @override
  String get settingsLegalAndPrivacySubtitle => '查看协议、隐私政策、撤回同意';

  @override
  String get legalPageTitle => '法律与隐私';

  @override
  String get legalPageDocuments => '法律文档';

  @override
  String get legalPageWithdrawTitle => '撤回同意';

  @override
  String get legalPageWithdrawDescription => '撤回某项同意后，相关功能立即停用（数据不删除，可重新打开）。';

  @override
  String get legalPageWithdrawVent => '撤回树洞（敏感倾诉）处理同意';

  @override
  String get legalPageWithdrawVentSubtitle => '停止存储新树洞文字／录音（已有数据保留，需手动删除）';

  @override
  String get legalPageWithdrawAnalytics => '撤回评估／情绪分析同意';

  @override
  String get legalPageWithdrawAnalyticsSubtitle =>
      '停止将评估／情绪记录纳入趋势分析（数据保留，不再入图表）';

  @override
  String legalPageConsentRecorded(Object time) {
    return '撤回时间：$time';
  }

  @override
  String get legalPageConsentNever => '从未撤回';

  @override
  String get reportHistoryEmpty => '还没有报告历史\n生成一次报告后会自动记录';

  @override
  String reportHistoryItemTitle(Object date, int days) {
    return '$date · 近 $days 天';
  }

  @override
  String reportHistoryItemPatient(Object name) {
    return '患者：$name';
  }

  @override
  String get reportHistoryItemNotSet => '未设置';

  @override
  String get reportHistoryDeleteTitle => '删除这条报告？';

  @override
  String get reportHistoryDeleteContent => '删除后无法恢复，但可以重新生成。';

  @override
  String get homeCelebrationDay1 => '已记录！第 1 天 🌱';

  @override
  String homeCelebrationStreakShort(int days) {
    return '已记录！连击 $days 天 🌿';
  }

  @override
  String homeCelebrationStreakMedium(int days) {
    return '已记录！连击 $days 天 🌳';
  }

  @override
  String homeCelebrationStreakLong(int days) {
    return '已记录！$days 天连击 🌲';
  }

  @override
  String homeCelebrationStreakMaster(int days) {
    return '已记录！$days 天 🏔️';
  }

  @override
  String homeAutofireCelebration(Object name) {
    return '已打卡：$name ✅';
  }

  @override
  String get homeAutofireFallbackName => '该药';

  @override
  String homeMedHint(int id) {
    return '💊 准备打卡药物 #$id';
  }

  @override
  String get homeSnoozeTitle => '⏰ 该打卡了（5min 后）';

  @override
  String get notifChannelMedicationName => '吃药提醒';

  @override
  String get notifChannelMedicationDesc => '到点提醒你吃药打卡';

  @override
  String get homeNotifBannerText => '提醒没设上，可能错过打卡。请到系统设置允许通知。';

  @override
  String get homeNotifBannerDismiss => '知道了';

  @override
  String themeTooltip(Object mode) {
    return '主题：$mode（点击切换）';
  }

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '亮色';

  @override
  String get themeModeDark => '暗色';

  @override
  String get trendTitle => '我的趋势';

  @override
  String get trendLast30Days => '最近 30 天';

  @override
  String get trendLast6Months => '最近 6 个月';

  @override
  String get trendAssessmentHistory => '心理评估历史';

  @override
  String get trendMoodHistory => '情绪日记历史';

  @override
  String get trendViewList => '列表';

  @override
  String get trendViewCalendar => '日历';

  @override
  String get trendWithdrawnTitle => '趋势分析已撤回';

  @override
  String get trendWithdrawnSubtitle =>
      '你撤回了「趋势分析」同意（PIPL §14）。趋势数据未删除， 重新开启后即可恢复。';

  @override
  String get trendWithdrawnAction => '去重新开启';

  @override
  String get trendWeekdayMon => '一';

  @override
  String get trendWeekdayTue => '二';

  @override
  String get trendWeekdayWed => '三';

  @override
  String get trendWeekdayThu => '四';

  @override
  String get trendWeekdayFri => '五';

  @override
  String get trendWeekdaySat => '六';

  @override
  String get trendWeekdaySun => '日';

  @override
  String get trendPrevMonth => '上个月';

  @override
  String get trendNextMonth => '下个月';

  @override
  String trendMonthYear(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String get trendCheckedIn => '已打卡';

  @override
  String get trendNotCheckedIn => '未打卡';

  @override
  String trendEventCount(int count) {
    return '$count 个事件';
  }

  @override
  String trendMoodEntriesSame(int count, Object emoji) {
    return '$count 条情绪记录 · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, Object lowEmoji, Object highEmoji) {
    return '情绪 $count 条 · $lowEmoji→$highEmoji';
  }

  @override
  String get trendNoRecords => '这一天没有记录';

  @override
  String get trendStatCurrentStreak => '当前连续';

  @override
  String get trendStatLongestStreak => '最长连续';

  @override
  String get trendStatTotalCheckIns => '总打卡';

  @override
  String get trendStatTotalDays => '总天数';

  @override
  String trendStatDaysValue(int count) {
    return '$count 天';
  }

  @override
  String trendMonthLabel(int month) {
    return '$month月';
  }

  @override
  String get trendNoAssessments => '还没有评估记录';

  @override
  String get trendNoAssessmentsHint => '完成一次心理评估后，折线图会自动出现在这里';

  @override
  String get trendNoMoodEntries => '还没有情绪记录';

  @override
  String get trendNoMoodEntriesHint => '在主页点击「记一下情绪」开始记录';

  @override
  String get trendCbtReratedChartTitle => '重评效果';

  @override
  String get trendCbtReratedEmptyTitle => '还没有 5/7 栏 CBT 数据';

  @override
  String get trendCbtReratedEmptyHint => '先用 5/7 栏 CBT 填表， 才能看到重评效果';

  @override
  String get contactConsentTitle => '知情同意';

  @override
  String get contactConsentAgree => '已告知并取得同意';

  @override
  String get contactConsentReject => '暂不同意';

  @override
  String get contactConsentVersion => 'v1 · 2026-07-31';

  @override
  String get dataExportConsentTitle => '数据导出同意';

  @override
  String dataExportConsentBody(
      Object purpose, Object dataCategories, Object retention) {
    return '您即将导出本地数据库中的所有数据。\n\n**目的**：$purpose\n**数据范围**：$dataCategories\n**保留方式**：$retention\n\n**根据《个人信息保护法》第 13 条**（数据可携权 + 单独同意），请确认您已了解上述用途，并同意本次导出。';
  }

  @override
  String get dataExportConsentConfirm => '我了解并同意导出';

  @override
  String get dataExportConsentVersion => 'v1 · 2026-08-15';

  @override
  String get editMedDialogTitle => '编辑药物';

  @override
  String get editMedValidationNameRequired => '请填写药名';

  @override
  String get editMedValidationDosageInvalid => '剂量必须是大于 0 的数字';

  @override
  String get editMedValidationUnitInvalid => '单位必须是 mg 或 片';

  @override
  String editMedSaveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get editMedStatusActive => '正在使用';

  @override
  String get editMedStatusStopped => '已停药';

  @override
  String editMedStoppedDate(Object date) {
    return '$date 停药';
  }

  @override
  String get editMedNameHint => '请输入药盒上的名称（选填）';

  @override
  String get editMedDosageLabel => '剂量';

  @override
  String get editMedUnitLabel => '单位';

  @override
  String get editMedTimeSectionLabel => '吃药时间（点 + 加）';

  @override
  String get editMedAddTime => '加时间';

  @override
  String get editMedNoTimeHint => '（不设置时间 = 不调度提醒，仅记录）';

  @override
  String get editMedStopAction => '停用此药';

  @override
  String get editMedResumeAction => '重新启用';

  @override
  String get editMedStopHint => '软停：保留所有打卡历史，不再推送提醒';

  @override
  String get editMedResumeHint => '恢复：清空停药日期，恢复每日提醒';

  @override
  String get medReportCopyHint => '可全选复制、生成 PDF 或分享给医生';

  @override
  String get medReportPdfLabel => 'PDF';

  @override
  String get medReportShareLabel => '分享';

  @override
  String get medReportPdfLoading => '生成 PDF 中……';

  @override
  String get medReportShareSubject => '慢病管家 · 用药报告';

  @override
  String get tempMedNoLink => '不关联';

  @override
  String get medsCalendarHeatmapDesc => '以药为单位的依从性热力图。颜色越深 = 当天打卡次数越接近期望次数。';

  @override
  String get medsCalendarWindow7 => '7 天';

  @override
  String get medsCalendarWindow30 => '30 天';

  @override
  String get medsCalendarWindow90 => '90 天';

  @override
  String get medsCalendarWindowTitle => '时间窗口';

  @override
  String medsCalendarLoadCheckinFailed(Object error) {
    return '加载打卡失败：$error';
  }

  @override
  String medsCalendarLoadMedFailed(Object error) {
    return '加载药物失败：$error';
  }

  @override
  String get medsCalendarNoActive => '还没有在用药物';

  @override
  String get medsCalendarNoSchedule => '在用药物未设置服用时间，无法生成依从性日历';

  @override
  String get medsCalendarNoScheduleHint => '在设置页给药物加上服药时间后，这里会显示服药日历';

  @override
  String get medsCalendarNoActiveAction => '添加药物';

  @override
  String get medsCalendarNoScheduleAction => '去设置时间';

  @override
  String get medsCalendarLegendLabel => '依从：';

  @override
  String get medsCalendarLegendTitle => '图例';

  @override
  String get medsCalendarLegendMissed => '漏服';

  @override
  String medsCalendarDayDetailTitle(String date) {
    return '$date 的打卡';
  }

  @override
  String get medsCalendarDayDetailEmpty => '当天还没有打卡';

  @override
  String get medCalendarBackfillConfirm => '确认补打卡';

  @override
  String medCalendarBackfillSuccess(Object date) {
    return '已补打卡 $date';
  }

  @override
  String get medsCalendarDayDetailAddLog => '补打卡';

  @override
  String get medsCalendarDayDetailAddLogHint => '为今天补一次服药记录';

  @override
  String medsCalendarDayDetailLogItem(String time, String name) {
    return '$time · $name';
  }

  @override
  String get medsCalendarLegendPartial => '< 50%';

  @override
  String get medsCalendarLegendAlmost => '< 100%';

  @override
  String get medsCalendarLegendFull => '100%';

  @override
  String get window7Subtitle => '一周内（适合周复诊）';

  @override
  String get window14Subtitle => '两周内（推荐）';

  @override
  String get window30Subtitle => '一个月内（适合月度评估）';

  @override
  String get snackbarActionSave => '保存';

  @override
  String get snackbarActionShare => '分享';

  @override
  String get snackbarActionGeneratePdf => '生成 PDF';

  @override
  String get snackbarActionPlay => '播放';

  @override
  String get snackbarActionEncryptRecording => '加密录音';

  @override
  String get snackbarActionCheckin => '打卡';

  @override
  String get snackbarActionAutoCheckin => '自动打卡';

  @override
  String get snackbarActionFinishSetup => '完成设置';

  @override
  String get snackbarActionUndo => '撤销';

  @override
  String get ventEntryDeleted => '已删除树洞条目';

  @override
  String get medicationDeleted => '已删除药物';

  @override
  String get moodTodayLabel => '今日情绪：';

  @override
  String moodTodayLabelWithValue(String value) {
    return '今日情绪：$value';
  }

  @override
  String get moodLabel1 => '很差';

  @override
  String get moodLabel2 => '差';

  @override
  String get moodLabel3 => '一般';

  @override
  String get moodLabel4 => '好';

  @override
  String get moodLabel5 => '很好';

  @override
  String get moodRecordButton => '记一下情绪 ✏️';

  @override
  String medReportFileName(Object date) {
    return '用药报告_$date';
  }

  @override
  String get migrationPromptTitle => '升级到 v0.9';

  @override
  String get migrationPromptDetectedOld => '检测到本地有旧版本数据。';

  @override
  String get migrationPromptChangesTitle => '本次升级会：';

  @override
  String get migrationPromptChangeEncrypt => '• 启用数据库加密（保护您的隐私）';

  @override
  String get migrationPromptChangeClear => '• 清空旧版本的所有打卡记录';

  @override
  String get migrationPromptChangeWarning => '（旧版本没有\"导出数据\"功能，原始数据无法恢复）';

  @override
  String get migrationPromptRecommendExport => '建议：先在旧版 App 内完成\"导出数据\"备份，再升级。';

  @override
  String get migrationPromptDirectContinue => '若旧版已卸载无法导出，可以直接点\"继续升级\"。';

  @override
  String get migrationPromptCancel => '取消';

  @override
  String get migrationPromptContinue => '继续升级';

  @override
  String get migrationAbortedTitle => '升级已取消';

  @override
  String get migrationAbortedBody =>
      '请先在旧版本 App 内完成\"导出数据\"备份，\n备份完成后点下方按钮继续升级。';

  @override
  String get migrationAbortedRetry => '已备份，继续升级';

  @override
  String get migrationFailedTitle => '启动失败';

  @override
  String get migrationFailedBody =>
      '无法初始化本地数据。\n请尝试：\n1) 重启 App\n2) 卸载后重装\n如反复出现，请反馈给我们。';

  @override
  String get migrationFailedReassure => '请别担心，您的数据是加密的。我们会尽快解决。';

  @override
  String get moodRatingSemantics => '情绪评分，1 到 5 分制，5 分最积极';

  @override
  String moodRatingButtonSemantics(Object score, String selected) {
    String _temp0 = intl.Intl.selectLogic(
      selected,
      {
        'true': '，已选',
        'other': '',
      },
    );
    return '$score 分$_temp0';
  }

  @override
  String medicationTimeWindowSemantics(Object days) {
    return '时间窗口 $days 天，7／30／90 单选';
  }

  @override
  String get assessmentSaveFailed => '评估结果已显示，但保存失败。请稍后重试。';

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => '片';

  @override
  String get safetyCheckResultDisabled => '安全开关已关闭';

  @override
  String get presetMedSsriMorningTitle => '单药 · SSRI 早一次';

  @override
  String get presetMedSsriMorningDesc => '1 种药，每天早 8 点服用（适用 SSRI ／ SNRI 类）';

  @override
  String get presetMedMoodStabilizerTwiceTitle => '情绪稳定剂 · 早晚两次';

  @override
  String get presetMedMoodStabilizerTwiceDesc => '1 种药，每天早 8 点 + 晚 20 点';

  @override
  String get presetMedComboSsriBedtimeTitle => '联合 · 早抗抑郁 + 晚助眠';

  @override
  String get presetMedComboSsriBedtimeDesc => '2 种药：早 8 点 SSRI + 晚 21 点助眠';

  @override
  String get presetMedComboAntipsychoticFullTitle => '重性 · 早中晚三次';

  @override
  String get presetMedComboAntipsychoticFullDesc =>
      '2 种药：早 8 ／ 午 13 ／ 晚 20，覆盖全天';

  @override
  String get presetMedSsriName => 'SSRI 类抗抑郁药';

  @override
  String get presetMedSsriHint => '常见 SSRI ／ SNRI 类抗抑郁药（具体药名以医生处方为准）';

  @override
  String get presetMedMoodStabilizerName => '情绪稳定剂';

  @override
  String get presetMedMoodStabilizerHint => '常见情绪稳定剂类（具体药名以医生处方为准）';

  @override
  String get presetMedSleepAidName => '助眠药';

  @override
  String get presetMedSleepAidHint => '常见苯二氮卓类／助眠药（具体药名以医生处方为准）';

  @override
  String get presetMedAntipsychoticName => '抗精神病药';

  @override
  String get presetMedAntipsychoticHint => '常见非典型抗精神病药（具体药名以医生处方为准）';

  @override
  String get presetMedSedativeAnxiolyticName => '镇静／抗焦虑辅助';

  @override
  String get presetMedSedativeAnxiolyticHint => '常见镇静／抗焦虑辅助药（具体药名以医生处方为准）';

  @override
  String dayDetailCheckInWith(Object name) {
    return '打卡 · $name';
  }

  @override
  String get dayDetailDailyCheckIn => '每日打卡';

  @override
  String dayDetailTempWith(Object name) {
    return '临时 · $name';
  }

  @override
  String get dayDetailTempMed => '临时吃药';

  @override
  String get dayDetailPhq9 => 'PHQ-9 抑郁筛查';

  @override
  String get dayDetailGad7 => 'GAD-7 焦虑筛查';

  @override
  String get scaleHotlineCn => '全国 24 小时心理援助热线';

  @override
  String get scaleHotlineCn2 => '北京心理危机研究与干预中心';

  @override
  String get scaleHotlineUs => '988 Suicide & Crisis Lifeline (US)';

  @override
  String get scaleHotlineUs2 => 'Crisis Text Line (text HOME to 741741)';

  @override
  String get scaleHotlineHk => '撒玛利亚防止自杀会（24h 多语言）';

  @override
  String get scaleHotlineTw => '生命线（24h）';

  @override
  String get scaleHotlineTw2 => '安心专线（心理咨商）';

  @override
  String get scaleHotlineSg => 'Samaritans of Singapore (24h)';

  @override
  String get scaleHotlineUk => 'Samaritans UK & ROI (24h 免费)';

  @override
  String get scaleHotlineIntl => '国际通用 · 请联系当地急救或心理援助';

  @override
  String get scaleCrisisTitle => '我们关心你';

  @override
  String get scaleCrisisMessage => '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。';

  @override
  String get phq9Item0 => '做事时提不起劲或没有兴趣';

  @override
  String get phq9Item1 => '感到心情低落、沮丧或绝望';

  @override
  String get phq9Item2 => '入睡困难、睡不安稳或睡得过多';

  @override
  String get phq9Item3 => '感觉疲倦或没有活力';

  @override
  String get phq9Item4 => '食欲不振或吃太多';

  @override
  String get phq9Item5 => '觉得自己很糟、很失败，或让自己和家人失望';

  @override
  String get phq9Item6 => '对事物专注有困难，例如看报纸或看电视时';

  @override
  String get phq9Item7 => '动作或说话速度缓慢到别人能察觉？\n或正好相反——烦躁或坐立不安';

  @override
  String get phq9Item8 => '有不如死掉或用某种方式伤害自己的念头';

  @override
  String get phq9Option0 => '完全不会';

  @override
  String get phq9Option1 => '好几天';

  @override
  String get phq9Option2 => '一半以上的天数';

  @override
  String get phq9Option3 => '几乎每天';

  @override
  String get phq9SeverityLabel0 => '几乎没有抑郁';

  @override
  String get phq9SeverityLabel1 => '轻度抑郁';

  @override
  String get phq9SeverityLabel2 => '中度抑郁';

  @override
  String get phq9SeverityLabel3 => '中重度抑郁';

  @override
  String get phq9SeverityLabel4 => '重度抑郁';

  @override
  String get phq9SeveritySummary0 => '几乎没有抑郁倾向';

  @override
  String get phq9SeveritySummary1 => '轻度抑郁倾向';

  @override
  String get phq9SeveritySummary2 => '中度抑郁倾向';

  @override
  String get phq9SeveritySummary3 => '中重度抑郁倾向';

  @override
  String get phq9SeveritySummary4 => '重度抑郁倾向';

  @override
  String get phq9Instruction => '过去两周内，你有多经常被以下问题困扰？';

  @override
  String get phq9ShortDescription => '过去两周的抑郁倾向筛查';

  @override
  String get gad7Item0 => '感到紧张、焦虑或急切';

  @override
  String get gad7Item1 => '不能停止或控制担忧';

  @override
  String get gad7Item2 => '对各种事情担忧过多';

  @override
  String get gad7Item3 => '难以放松';

  @override
  String get gad7Item4 => '心情烦躁以至坐不住';

  @override
  String get gad7Item5 => '变得容易烦恼或急躁';

  @override
  String get gad7Item6 => '感到似乎将有可怕的事情发生而害怕';

  @override
  String get gad7SeverityLabel0 => '几乎没有焦虑';

  @override
  String get gad7SeverityLabel1 => '轻度焦虑';

  @override
  String get gad7SeverityLabel2 => '中度焦虑';

  @override
  String get gad7SeverityLabel3 => '重度焦虑';

  @override
  String get gad7SeveritySummary0 => '几乎没有焦虑倾向';

  @override
  String get gad7SeveritySummary1 => '轻度焦虑倾向';

  @override
  String get gad7SeveritySummary2 => '中度焦虑倾向';

  @override
  String get gad7SeveritySummary3 => '重度焦虑倾向';

  @override
  String get gad7Instruction => '过去两周内，你有多经常被以下问题困扰？';

  @override
  String get gad7ShortDescription => '过去两周的焦虑倾向筛查';

  @override
  String get homeFabVent => '树洞';

  @override
  String get homeMoodHeroTitle => '今日心情';

  @override
  String get homeMoodHeroRecord => '记录心情';

  @override
  String get homeMoodHeroReview => '回顾';

  @override
  String get homeMoodHeroNoData => '今天还没记录心情';

  @override
  String homeMoodHeroLastRecorded(String time) {
    return '上次记录 $time';
  }

  @override
  String get homeVentHeroTitle => '树洞';

  @override
  String get homeVentHeroWrite => '写心事';

  @override
  String get homeVentHeroNoData => '还没有倾诉, 写第一条心事';

  @override
  String get homeActionMedication => '用药';

  @override
  String get homeActionAssessment => '量表';

  @override
  String get homeActionMoodReview => '情绪回顾';

  @override
  String get homeActionDailyTracking => '日常追踪';

  @override
  String get homeFabHotline => '紧急热线';

  @override
  String get homeFabTop => '回到顶端';

  @override
  String get trendChip30Day => '近 30 天';

  @override
  String get assessmentChipCurrent => '本周';

  @override
  String get crisisHotlineCnLabel => '全国 24 小时心理援助热线';

  @override
  String get crisisHotlineCnNumber => '400-161-9995';

  @override
  String get crisisHotlineCnDesc => '中国大陆 24 小时免费';

  @override
  String get crisisHotlineTwLabel => '安心专线 (24 小时）';

  @override
  String get crisisHotlineTwNumber => '1925';

  @override
  String get crisisHotlineTwDesc => '中国台湾 24 小时心理咨商';

  @override
  String get crisisHotlineHkLabel => '撒玛利亚防止自杀会 (24 小时）';

  @override
  String get crisisHotlineHkNumber => '2389 2222';

  @override
  String get crisisHotlineHkDesc => '中国香港 24 小时多语言';

  @override
  String get crisisHotlineMoLabel => '明爱生命热线 (24 小时）';

  @override
  String get crisisHotlineMoNumber => '2826 1122';

  @override
  String get crisisHotlineMoDesc => '中国澳门 24 小时';

  @override
  String get crisisHotlineTitle => '紧急心理援助热线';

  @override
  String get crisisHotlineSubtitle => '如果你或身边的人正在经历心理危机， 请拨打以下热线';

  @override
  String get crisisHotlineCn2Label => '全国 24 小时免费心理援助热线';

  @override
  String get crisisHotlineCn2Number => '800-810-1117';

  @override
  String get crisisHotlineCn2Desc => '中国大陆 24 小时免费拨打';

  @override
  String get crisisHotlineUsLabel => '988 Suicide & Crisis Lifeline';

  @override
  String get crisisHotlineUsNumber => '988';

  @override
  String get crisisHotlineUsDesc => '美国 / 加拿大 24 小时英文 / 西班牙文';

  @override
  String get crisisHotlineIntlLabel => '国际通用';

  @override
  String get crisisHotlineIntlDesc => '请联系当地急救或心理援助机构';

  @override
  String get crisisHotlineIntlNumber => '112 / 911';

  @override
  String get crisisHotlineRegionCn => '中国大陆';

  @override
  String get crisisHotlineRegionTw => '中国台湾';

  @override
  String get crisisHotlineRegionHk => '中国香港';

  @override
  String get crisisHotlineRegionUs => '美国 / 加拿大';

  @override
  String get crisisHotlineRegionIntl => '国际通用';

  @override
  String get crisisHotlineCnBeijingLabel => '北京心理危机研究与干预中心';

  @override
  String get crisisHotlineCnBeijingNumber => '010-82951332';

  @override
  String get crisisHotlineCnBeijingDesc => '北京 24 小时';

  @override
  String get crisisHotlineTw1995Label => '生命线 (24 小时）';

  @override
  String get crisisHotlineTw1995Number => '1995';

  @override
  String get crisisHotlineTw1995Desc => '中国台湾 24 小时';

  @override
  String get crisisHotlineUsTextLineLabel => 'Crisis Text Line (text HOME)';

  @override
  String get crisisHotlineUsTextLineNumber => '741741';

  @override
  String get crisisHotlineUsTextLineDesc => '美国 24 小时短信';

  @override
  String crisisHotlineSnackbarCopied(Object number) {
    return '已复制： $number';
  }

  @override
  String get crisisHotlineDialTooltip => '拨打';

  @override
  String get crisisHotlineCopyTooltip => '复制号码';

  @override
  String crisisHotlineDialFailed(Object number) {
    return '无法启动拨号， 请手动拨打： $number';
  }

  @override
  String get setupLegalAgeAttestation =>
      '本人郑重承诺：我已年满 18 周岁。如本人为 14-18 周岁，本人保证已取得监护人代为同意，并愿意承担虚假陈述的一切法律后果。';

  @override
  String get moodCbtLevelLabel3 => '3 栏';

  @override
  String get moodCbtLevelLabel5 => '5 栏';

  @override
  String get moodCbtLevelLabel7 => '7 栏';

  @override
  String get moodCbtExpandExplain => '什么是 CBT 思维记录？';

  @override
  String get moodCbtSectionSituation => '情境';

  @override
  String get moodCbtSectionAutomaticThought => '自动思维';

  @override
  String get moodCbtSectionEvidenceFor => '支持证据';

  @override
  String get moodCbtSectionEvidenceAgainst => '反对证据';

  @override
  String get moodCbtSectionAlternative => '替代思维';

  @override
  String get moodCbtSectionRerated => '重新评分';

  @override
  String get moodCbtSectionCoreBelief => '核心信念';

  @override
  String get moodCbtSectionBehavior => '行为应对';

  @override
  String get moodCbtExplainerBody =>
      'CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准：先记录情境与想法，再找证据支持／反对，最后写下更平衡的替代想法。';

  @override
  String get moodCbtFieldHintSituation => '触发这个想法的事件是什么？发生在哪里、什么时候、有谁？';

  @override
  String get moodCbtFieldHintAutomaticThought => '那一瞬间脑中闪过的想法、印象或意象是什么？';

  @override
  String get moodCbtFieldHintEvidenceFor => '什么事支持这个想法？';

  @override
  String get moodCbtFieldHintEvidenceAgainst => '什么事不支持这个想法？';

  @override
  String get moodCbtFieldHintAlternative => '如果你的好朋友遇到这事，你会怎么想？';

  @override
  String get moodCbtFieldHintCoreBelief => '这个想法背后更深层的信念是什么？（如 \"我不够好\"）';

  @override
  String get moodCbtFieldHintBehavior => '接下来你打算怎么做？';

  @override
  String get moodCbtPromptTitle => '引导问题';

  @override
  String moodCbtStepOf(int current, int total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String moodCbtReratedComparison(int newScore, int oldScore) {
    return '重新评分：$newScore（原 $oldScore）';
  }

  @override
  String get settingsCbtLevel => '思维记录档位';

  @override
  String get settingsCbtLevelDescription => '选择每次记录情绪时使用的思维记录模板';

  @override
  String get settingsCbtLevel3Desc => '入门版，1-2 分钟可填完';

  @override
  String get settingsCbtLevel5Desc => '标准 Beck 思维记录，含认知重构关键步骤';

  @override
  String get settingsCbtLevel7Desc => '深度版，含核心信念识别和行为应对';

  @override
  String get moodCbtScoreReratedLabel => '重新评分';

  @override
  String get moodCbtChipBadge5 => 'CBT 5 栏';

  @override
  String get moodCbtChipBadge7 => 'CBT 7 栏';

  @override
  String get moodCbtThreeScoreTitle => '你现在的感受？';

  @override
  String get moodCbtThreeSituationTitle => '发生了什么？';

  @override
  String get moodCbtThreeAutoTitle => '那一刻脑海里闪过什么想法？';

  @override
  String get moodCbtPrevStep => '上一步';

  @override
  String get moodCbtNextStep => '下一步';

  @override
  String get moodCbtComplete => '完成';

  @override
  String get moodCbtStep2Header => '情绪 + 证据';

  @override
  String get moodCbtConfirm => '确认';

  @override
  String get moodCbtConfirmEmpty => '（未填）';

  @override
  String get moodCbtAutoThoughtPrompt0 => '如果你的好朋友遇到这事，你会怎么劝TA？';

  @override
  String get moodCbtAutoThoughtPrompt1 => '最坏／最好／最现实的结果是什么？';

  @override
  String get moodCbtAutoThoughtPrompt2 => '一年后你还会这么想吗？';

  @override
  String get moodCbtAlternativePrompt0 => '一年后你还会这么想吗？';

  @override
  String get moodCbtAlternativePrompt1 => '最现实的结果是什么？';

  @override
  String get moodCbtBehaviorPrompt0 => '深呼吸 5 次';

  @override
  String get moodCbtBehaviorPrompt1 => '与信任的人聊聊';

  @override
  String get moodCbtBehaviorPrompt2 => '做 10 分钟正念';

  @override
  String get moodListFilterDate => '日期';

  @override
  String get moodListFilterScore => '分数';

  @override
  String get moodListFilterCbt => 'CBT 档位';

  @override
  String get moodListSortBy => '排序';

  @override
  String get moodListSortTimestamp => '时间倒序';

  @override
  String get moodListSortScoreAsc => '分数升序';

  @override
  String get moodListSortScoreDesc => '分数降序';

  @override
  String get moodListPageTitle => 'Mood 历史';

  @override
  String get moodListSearchHint => '搜索 note……';

  @override
  String get moodListEmpty => '还没有 mood 记录';

  @override
  String get moodListNoMatch => '没有匹配的记录';

  @override
  String moodListEntryCount(int count) {
    return '$count 条记录';
  }

  @override
  String get cbtExportPdfEmpty => '还没有 5/7 栏 CBT 数据可导出';

  @override
  String get cbtExportPdfButton => '导出 CBT 思维记录 PDF';

  @override
  String get cbtExportPdfDialogTitle => '选择日期范围生成 PDF';

  @override
  String cbtExportPdfSuccess(int count) {
    return '已导出 $count 条 CBT 思维记录';
  }

  @override
  String get cbtExportPdfFailed => 'PDF 导出失败，请重试';

  @override
  String get assessmentCenterTitle => '量表中心';

  @override
  String assessmentCenterLastScore(int score) {
    return '上次 $score 分';
  }

  @override
  String assessmentCenterLastTime(Object time) {
    return '$time 填写';
  }

  @override
  String get assessmentCenterNoData => '尚未填写过';

  @override
  String get assessmentCenterStartButton => '开始评估';

  @override
  String get assessmentCenterMultiLineTitle => '全部量表趋势';

  @override
  String get assessmentCenterNotAvailable => '需法务／临床审核';

  @override
  String get assessmentCenterComingSoon => '敬请期待';

  @override
  String get isiName => 'ISI 失眠严重指数';

  @override
  String get isiShortDescription => 'Morin 1993 失眠严重指数 7 题';

  @override
  String get isiInstruction => '过去 2 周内， 您的睡眠问题有多严重？';

  @override
  String get isiOption0 => '无';

  @override
  String get isiOption1 => '轻度';

  @override
  String get isiOption2 => '中度';

  @override
  String get isiOption3 => '重度';

  @override
  String get isiOption4 => '极重度';

  @override
  String get isiSeverityLabel0 => '无失眠';

  @override
  String get isiSeverityLabel1 => '阈下失眠';

  @override
  String get isiSeverityLabel2 => '中度失眠';

  @override
  String get isiSeverityLabel3 => '重度失眠';

  @override
  String get isiSeveritySummary0 => '无临床失眠';

  @override
  String get isiSeveritySummary1 => '亚临床失眠， 建议关注';

  @override
  String get isiSeveritySummary2 => '中度失眠， 建议就医';

  @override
  String get isiSeveritySummary3 => '重度失眠， 强烈建议就医';

  @override
  String get pssName => 'PSS 压力量表';

  @override
  String get pssShortDescription => 'Cohen 1983 压力量表 (10 题， 含 4 题反向）';

  @override
  String get pssInstruction => '过去 1 个月里， 您有多经常有下列感受？';

  @override
  String get pssOption0 => '从未';

  @override
  String get pssOption1 => '几乎不';

  @override
  String get pssOption2 => '有时';

  @override
  String get pssOption3 => '经常';

  @override
  String get pssOption4 => '总是';

  @override
  String get pssSeverityLabel0 => '低压力';

  @override
  String get pssSeverityLabel1 => '中度压力';

  @override
  String get pssSeverityLabel2 => '高压力';

  @override
  String get pssSeveritySummary0 => '低压力';

  @override
  String get pssSeveritySummary1 => '中度压力';

  @override
  String get pssSeveritySummary2 => '高压力， 建议关注和寻求支持';

  @override
  String get whodasName => 'WHODAS 2.0 残疾评定';

  @override
  String get whodasShortDescription => 'WHO 通用残疾评估 12 题简化版';

  @override
  String get whodasInstruction => '过去 30 天内， 您在以下活动中遇到多大困难？';

  @override
  String get whodasOption0 => '没有';

  @override
  String get whodasOption1 => '轻微';

  @override
  String get whodasOption2 => '中度';

  @override
  String get whodasOption3 => '重度';

  @override
  String get whodasOption4 => '极重度';

  @override
  String get whodasSeverityLabel0 => '无残疾';

  @override
  String get whodasSeverityLabel1 => '轻度残疾';

  @override
  String get whodasSeverityLabel2 => '中度残疾';

  @override
  String get whodasSeverityLabel3 => '重度残疾';

  @override
  String get whodasSeverityLabel4 => '极重度残疾';

  @override
  String get whodasSeveritySummary0 => '无残疾';

  @override
  String get whodasSeveritySummary1 => '轻度残疾';

  @override
  String get whodasSeveritySummary2 => '中度残疾， 建议就医评估';

  @override
  String get whodasSeveritySummary3 => '重度残疾， 建议就医';

  @override
  String get whodasSeveritySummary4 => '极重度残疾， 强烈建议就医';

  @override
  String get level2DepressionName => 'DSM-5 Level 2 抑郁严重度';

  @override
  String get level2DepressionShortDescription =>
      '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版）';

  @override
  String get level2DepressionInstruction => '过去 7 天内， 您有多经常被以下情绪困扰？';

  @override
  String get level2DepressionOption0 => '完全没有';

  @override
  String get level2DepressionOption1 => '几天';

  @override
  String get level2DepressionOption2 => '一半以上的天数';

  @override
  String get level2DepressionOption3 => '几乎每天';

  @override
  String get level2DepressionSeverityLabel0 => '无抑郁';

  @override
  String get level2DepressionSeverityLabel1 => '轻度抑郁';

  @override
  String get level2DepressionSeverityLabel2 => '中度抑郁';

  @override
  String get level2DepressionSeverityLabel3 => '重度抑郁';

  @override
  String get level2DepressionSeveritySummary0 => '无抑郁倾向';

  @override
  String get level2DepressionSeveritySummary1 => '轻度抑郁倾向';

  @override
  String get level2DepressionSeveritySummary2 => '中度抑郁， 建议就医';

  @override
  String get level2DepressionSeveritySummary3 => '重度抑郁， 强烈建议就医';

  @override
  String get level2AnxietyName => 'DSM-5 Level 2 焦虑严重度';

  @override
  String get level2AnxietyShortDescription => '成人焦虑严重度 7 题 (DSM-5 PROMIS 简化版）';

  @override
  String get level2AnxietyInstruction => '过去 7 天内， 您有多经常被以下感受困扰？';

  @override
  String get level2AnxietyOption0 => '完全没有';

  @override
  String get level2AnxietyOption1 => '几天';

  @override
  String get level2AnxietyOption2 => '一半以上的天数';

  @override
  String get level2AnxietyOption3 => '几乎每天';

  @override
  String get level2AnxietySeverityLabel0 => '无焦虑';

  @override
  String get level2AnxietySeverityLabel1 => '轻度焦虑';

  @override
  String get level2AnxietySeverityLabel2 => '中度焦虑';

  @override
  String get level2AnxietySeverityLabel3 => '重度焦虑';

  @override
  String get level2AnxietySeveritySummary0 => '无焦虑倾向';

  @override
  String get level2AnxietySeveritySummary1 => '轻度焦虑倾向';

  @override
  String get level2AnxietySeveritySummary2 => '中度焦虑， 建议就医';

  @override
  String get level2AnxietySeveritySummary3 => '重度焦虑， 强烈建议就医';

  @override
  String get level2ManiaName => 'DSM-5 Level 2 躁狂严重度';

  @override
  String get level2ManiaShortDescription => '成人躁狂严重度 5 题 (DSM-5 PROMIS 简化版）';

  @override
  String get level2ManiaInstruction => '过去 7 天内， 您有多经常体验以下情况？';

  @override
  String get level2ManiaOption0 => '完全没有';

  @override
  String get level2ManiaOption1 => '几天';

  @override
  String get level2ManiaOption2 => '一半以上的天数';

  @override
  String get level2ManiaOption3 => '几乎每天';

  @override
  String get level2ManiaSeverityLabel0 => '无躁狂';

  @override
  String get level2ManiaSeverityLabel1 => '轻度躁狂';

  @override
  String get level2ManiaSeverityLabel2 => '中度躁狂';

  @override
  String get level2ManiaSeverityLabel3 => '重度躁狂';

  @override
  String get level2ManiaSeveritySummary0 => '无躁狂倾向';

  @override
  String get level2ManiaSeveritySummary1 => '轻度躁狂倾向';

  @override
  String get level2ManiaSeveritySummary2 => '中度躁狂， 建议就医';

  @override
  String get level2ManiaSeveritySummary3 => '重度躁狂， 强烈建议就医';

  @override
  String get asrmName => 'ASRM 自评躁狂量表';

  @override
  String get asrmShortDescription => 'Altman 1997 自评躁狂量表 (5 题）';

  @override
  String get asrmInstruction => '过去 1 周内， 您有 （或感觉到） 以下情况的程度？';

  @override
  String get asrmOption0 => '完全没有';

  @override
  String get asrmOption1 => '轻微';

  @override
  String get asrmOption2 => '中度';

  @override
  String get asrmOption3 => '明显';

  @override
  String get asrmOption4 => '严重';

  @override
  String get asrmSeverityLabel0 => '无症状';

  @override
  String get asrmSeverityLabel1 => '轻度';

  @override
  String get asrmSeverityLabel2 => '中度';

  @override
  String get asrmSeverityLabel3 => '重度';

  @override
  String get asrmSeverityLabel4 => '极重度';

  @override
  String get asrmSeveritySummary0 => '无症状';

  @override
  String get asrmSeveritySummary1 => '轻度躁狂倾向';

  @override
  String get asrmSeveritySummary2 => '中度躁狂， 建议就医';

  @override
  String get asrmSeveritySummary3 => '重度躁狂， 建议就医';

  @override
  String get asrmSeveritySummary4 => '极重度躁狂， 强烈建议就医';

  @override
  String get level2PsychosisName => 'DSM-5 Level 2 精神病性症状';

  @override
  String get level2PsychosisShortDescription => '成人精神病性症状 8 题 (DSM-5 简化版）';

  @override
  String get level2PsychosisInstruction => '过去 7 天内， 您有多经常体验以下情况？';

  @override
  String get level2PsychosisOption0 => '从来没有';

  @override
  String get level2PsychosisOption1 => '很少';

  @override
  String get level2PsychosisOption2 => '有时';

  @override
  String get level2PsychosisOption3 => '经常';

  @override
  String get level2PsychosisSeverityLabel0 => '无症状';

  @override
  String get level2PsychosisSeverityLabel1 => '轻度';

  @override
  String get level2PsychosisSeverityLabel2 => '中度';

  @override
  String get level2PsychosisSeverityLabel3 => '重度';

  @override
  String get level2PsychosisSeveritySummary0 => '无精神病性症状';

  @override
  String get level2PsychosisSeveritySummary1 => '轻度精神病性症状';

  @override
  String get level2PsychosisSeveritySummary2 => '中度精神病性症状， 建议就医';

  @override
  String get level2PsychosisSeveritySummary3 => '重度精神病性症状， 强烈建议就医';

  @override
  String get dailyTrackingTitle => '日常追踪';

  @override
  String get dailyTrackingFab => '日常追踪';

  @override
  String get dailyTrackingMultiChartTitle => '近 30 天 4 指标';

  @override
  String get chartMetricWeight => '体重';

  @override
  String get chartMetricSleep => '睡眠';

  @override
  String get chartMetricMood => '心境';

  @override
  String get chartMetricStress => '应激源';

  @override
  String dailyTrackingLastTime(Object time) {
    return '$time 记录';
  }

  @override
  String get dailyTrackingRecord => '记录';

  @override
  String get moodDiaryName => '情绪日记';

  @override
  String get moodDiaryShortDesc => '心境 4 段 + score, 趋势分析';

  @override
  String moodDiaryScore(int score) {
    return '心境 $score/5';
  }

  @override
  String moodDiaryLast(Object time, Object score, Object period) {
    return '$time · $score ($period)';
  }

  @override
  String get anxietyAgitationName => '焦虑急躁';

  @override
  String get anxietyAgitationShortDesc => '焦虑 + 急躁 双维度 5 档';

  @override
  String get anxietyAgitationHint => '焦虑反向 1=严重 5=平静； 急躁正向 1=平静 5=极急';

  @override
  String get anxietyAgitationAddButton => '添加评估';

  @override
  String get anxietyAgitationNoData => '暂无焦虑急躁记录';

  @override
  String anxietyAgitationAnxietyScore(int score) {
    return '焦虑 $score';
  }

  @override
  String anxietyAgitationAgitationScore(int score) {
    return '急躁 $score';
  }

  @override
  String anxietyAgitationLast(int anxiety, int agitation) {
    return '焦虑 $anxiety / 急躁 $agitation';
  }

  @override
  String get sleepName => '睡眠';

  @override
  String get sleepShortDesc => '入睡 + 时长 + 规律性';

  @override
  String get sleepHint => '记录每晚入睡 + 起床， 跨午夜自动算时长';

  @override
  String get sleepAddButton => '添加睡眠记录';

  @override
  String get sleepNoData => '暂无睡眠记录';

  @override
  String sleepBedtime(Object time) {
    return '入睡 $time';
  }

  @override
  String sleepWakeTime(Object time) {
    return '起床 $time';
  }

  @override
  String sleepLast(Object duration, int regularity) {
    return '$duration · 规律 $regularity/5';
  }

  @override
  String get socialRhythmName => '社会节律';

  @override
  String get socialRhythmShortDesc => '起床 + 第一餐 + 最后一餐 + 时长';

  @override
  String get socialRhythmHint => '记录每天的作息， 帮医生判断节律稳定性';

  @override
  String get socialRhythmAddButton => '添加社会节律';

  @override
  String get socialRhythmNoData => '暂无社会节律记录';

  @override
  String socialRhythmWakeTime(Object time) {
    return '起床 $time';
  }

  @override
  String socialRhythmFirstMeal(Object time) {
    return '第一餐 $time';
  }

  @override
  String socialRhythmLastMeal(Object time) {
    return '最后一餐 $time';
  }

  @override
  String socialRhythmLast(Object wake, int social, int work) {
    return '起床 $wake · 社交 ${social}h · 工作 ${work}h';
  }

  @override
  String get stressEventName => '应激源';

  @override
  String get stressEventShortDesc => '事件类型 + 强度评分';

  @override
  String get stressEventHint => '记录生活中的压力事件， 帮医生判断触发因素';

  @override
  String get stressEventAddButton => '添加应激源';

  @override
  String get stressEventNoData => '暂无应激源记录';

  @override
  String get stressEventEventType => '事件类型';

  @override
  String get stressEventIntensity => '强度';

  @override
  String stressEventLast(int intensity) {
    return '强度 $intensity/5';
  }

  @override
  String get treatmentName => '治疗';

  @override
  String get treatmentShortDesc => '用药 / 咨询 / 物理治疗， 关联 medication';

  @override
  String get treatmentHint => '治疗条目可关联 medication, 写入功能 v0.31+';

  @override
  String get treatmentNoData => '暂无治疗记录';

  @override
  String get treatmentAddButton => '添加';

  @override
  String get treatmentAddTitle => '添加治疗记录';

  @override
  String get treatmentDate => '日期';

  @override
  String get treatmentCategory => '类别';

  @override
  String get treatmentCategoryMedicationAdjustment => '药物调整';

  @override
  String get treatmentCategoryConsultation => '心理咨询';

  @override
  String get treatmentCategoryHospitalization => '住院';

  @override
  String get treatmentCategoryOther => '其他';

  @override
  String get treatmentProvider => '医疗机构 / 医生';

  @override
  String get treatmentProviderHint => '例如： 心理医生王医生 / 北京协和医院';

  @override
  String get treatmentProviderRequired => '请填写医疗机构 / 医生';

  @override
  String get treatmentNote => '备注';

  @override
  String get treatmentNoteHint => '可选， 简短记录治疗要点';

  @override
  String get treatmentType => '治疗类型';

  @override
  String treatmentLast(Object type, Object description) {
    return '$type · $description';
  }

  @override
  String get weightName => '体重';

  @override
  String get weightShortDesc => '体重 + BMI （需 profile.height)';

  @override
  String get weightHint => '记录每天的体重， 帮医生判断生理状态';

  @override
  String get weightAddButton => '添加体重记录';

  @override
  String get weightNoData => '暂无体重记录';

  @override
  String weightWeight(Object kg) {
    return '体重 $kg kg';
  }

  @override
  String weightBmi(Object bmi) {
    return 'BMI $bmi';
  }

  @override
  String weightLast(Object kg, Object bmi) {
    return '$kg kg · BMI $bmi';
  }

  @override
  String get periodMorning => '早';

  @override
  String get periodNoon => '中';

  @override
  String get periodEvening => '晚';

  @override
  String get periodNight => '夜';

  @override
  String get periodUnspecified => '未指定';

  @override
  String get stressEventTypeWork => '工作';

  @override
  String get stressEventTypeRelationship => '关系';

  @override
  String get stressEventTypeHealth => '健康';

  @override
  String get stressEventTypeFinancial => '财务';

  @override
  String get stressEventTypeOther => '其他';

  @override
  String get regularityVeryIrregular => '很不规律';

  @override
  String get regularityIrregular => '不规律';

  @override
  String get regularityNormal => '一般';

  @override
  String get regularityRegular => '规律';

  @override
  String get regularityVeryRegular => '很规律';

  @override
  String get cardStatusNoData => '尚未记录';

  @override
  String get sleepBedtimeTitle => '入睡时间';

  @override
  String get sleepWakeTimeTitle => '起床时间';

  @override
  String get socialRhythmWakeTimeTitle => '起床时间';

  @override
  String get socialRhythmFirstMealTitle => '第一餐时间';

  @override
  String get socialRhythmLastMealTitle => '最后一餐时间';

  @override
  String get cardStatusToday => '今天';

  @override
  String get sleepRegularityTitle => '规律性';

  @override
  String get anxietyAgitationAnxietyLabel => '焦虑分数';

  @override
  String get anxietyAgitationAgitationLabel => '急躁分数';

  @override
  String get moodListPeriodAll => '全部';

  @override
  String get migrationFailedInitData => '无法初始化本地数据';

  @override
  String get migrationFailedActionHint => '请尝试重启 App，或卸载后重新安装';

  @override
  String migrationFailedFooter(String error) {
    return '技术信息： $error';
  }

  @override
  String get migrationFailedRetryButton => '重试';

  @override
  String get migrationFailedCloseButton => '关闭';

  @override
  String get migrationStartingHint => '启动中，请稍候……';

  @override
  String get migrationNavContextNull => '启动上下文尚未就绪，请稍后再试';

  @override
  String get migrationFailedErrorPrefix => '错误';

  @override
  String get dailyTrackingNoteLabel => '备注';

  @override
  String get dailyTrackingNoteHint => '可选';

  @override
  String get timeAgoJustNow => '刚刚';

  @override
  String timeAgoDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String timeAgoHoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String get weightNoBmi => '暂无 BMI';

  @override
  String get weightKgLabel => '体重 (kg)';

  @override
  String get weightKgHint => '如 60.5';

  @override
  String get weightBmiNeedHeight => '暂无 （需填写身高）';

  @override
  String socialRhythmMinutesSummary(
      Object social, Object work, Object exercise) {
    return '社交 ${social}min · 工作 ${work}min · 运动 ${exercise}min';
  }

  @override
  String get socialRhythmSocialMinLabel => '社交时长 （分钟）';

  @override
  String get socialRhythmWorkMinLabel => '工作时长 （分钟）';

  @override
  String get socialRhythmExerciseMinLabel => '运动时长 （分钟）';

  @override
  String get anxietyAgitationAnxietyScaleHint => '1=严重 5=平静';

  @override
  String get anxietyAgitationAgitationScaleHint => '1=平静 5=极急';

  @override
  String sleepRegularityScore(int score) {
    return '规律 $score/5';
  }

  @override
  String sleepDurationLabel(Object duration) {
    return '时长： $duration';
  }

  @override
  String stressIntensityScore(int intensity) {
    return '强度 $intensity/5';
  }

  @override
  String moodCbtColumns(int count) {
    return '$count 栏';
  }

  @override
  String medReportTitleWindow(int days) {
    return '用药报告（近 $days 天）';
  }

  @override
  String get setupCrisisHotlineTitle => '🆘 心理危机干预热线 (24h)';

  @override
  String get consentWithdrawVentBody => '树洞 （私密倾诉） 功能将停用。新增树洞记录会被拒绝， 已有记录保留。';

  @override
  String get consentWithdrawAnalyticsBody =>
      '评估 / 情绪相关分析图表将不再展示。已有数据保留， 重新开启后恢复。';

  @override
  String get dataExportPurposeBackup => '本地备份 / 跨设备迁移';

  @override
  String get dataExportDataCategories => '用药记录、打卡记录、紧急联系人、情绪日记、树洞文字 （录音不导出）';

  @override
  String get dataExportRetentionClipboard => '剪贴板 + 用户自行保存到加密存储';

  @override
  String get medPageTitle => '用药';

  @override
  String get medAddTooltip => '添加药物';

  @override
  String get medTodaySchedule => '今日服药';

  @override
  String get medMyMedications => '我的药物';

  @override
  String get medQuickActions => '快捷操作';

  @override
  String get medSlotMorning => '早上';

  @override
  String get medSlotAfternoon => '下午';

  @override
  String get medSlotEvening => '晚上';

  @override
  String get medSlotBedtime => '睡前';

  @override
  String get medEmptyTitle => '还没有添加药物';

  @override
  String get medEmptySubtitle => '点击右上角 + 添加你的第一种药物';

  @override
  String get medNoScheduleToday => '今天没有服药计划';

  @override
  String get medAddTitle => '添加药物';

  @override
  String get medAddStep1Title => '药物信息';

  @override
  String get medAddConfirm => '确认信息';

  @override
  String get medAddColor => '颜色';

  @override
  String get medAddTime => '用药时间';

  @override
  String get medAddBasicInfo => '基本信息';

  @override
  String get medAddStep2Title => '剂量与时间';

  @override
  String get medAddStep3Title => '确认';

  @override
  String get medAddNameLabel => '药物名称';

  @override
  String get medAddNameHint => '例如：舍曲林';

  @override
  String get medAddFormLabel => '剂型';

  @override
  String get medAddDosageLabel => '每次剂量';

  @override
  String get medAddTimeLabel => '服药时间';

  @override
  String get medAddTimeAdd => '添加时间';

  @override
  String get medAddColorLabel => '药物颜色（可选，帮助识别）';

  @override
  String get medAddConfirmName => '药名';

  @override
  String get medAddConfirmForm => '剂型';

  @override
  String get medAddConfirmDosage => '剂量';

  @override
  String get medAddConfirmTime => '时间';

  @override
  String get medAddPrev => '上一步';

  @override
  String get medAddNext => '下一步';

  @override
  String get medAddSave => '保存';

  @override
  String medAddColorN(Object n) {
    return '药物颜色 $n';
  }

  @override
  String get medFormTablet => '片剂';

  @override
  String get medFormCapsule => '胶囊';

  @override
  String get medFormLiquid => '口服液';

  @override
  String get medFormPatch => '贴剂';

  @override
  String get medFormInjection => '注射';

  @override
  String get medFormOther => '其他';

  @override
  String get medDetailTitle => '药物详情';

  @override
  String get medNotFound => '药物未找到';

  @override
  String get moodInfluenceTitle => '影响因素';

  @override
  String get moodInfluenceSubtitle => '什么影响了你的心情？（可多选）';

  @override
  String get moodInfluenceRelationships => '关系';

  @override
  String get moodInfluenceHealth => '健康';

  @override
  String get moodInfluenceActivities => '活动';

  @override
  String get moodInfluenceMindfulness => '正念';

  @override
  String get moodInfluenceWeather => '天气';

  @override
  String get moodInfluenceOther => '其他';

  @override
  String get influenceFactorFamily => '家人';

  @override
  String get influenceFactorFriend => '朋友';

  @override
  String get influenceFactorPartner => '伴侣';

  @override
  String get influenceFactorChild => '孩子';

  @override
  String get influenceFactorColleague => '同事';

  @override
  String get influenceFactorExercise => '运动';

  @override
  String get influenceFactorSick => '生病';

  @override
  String get influenceFactorGoodSleep => '睡眠好';

  @override
  String get influenceFactorHealthyDiet => '饮食健康';

  @override
  String get influenceFactorWork => '工作';

  @override
  String get influenceFactorHobby => '爱好';

  @override
  String get influenceFactorTravel => '旅行';

  @override
  String get influenceFactorCommute => '通勤';

  @override
  String get influenceFactorShopping => '购物';

  @override
  String get influenceFactorGaming => '游戏';

  @override
  String get influenceFactorReading => '阅读';

  @override
  String get influenceFactorEntertainment => '娱乐';

  @override
  String get influenceFactorMeditation => '冥想';

  @override
  String get influenceFactorBreathing => '呼吸练习';

  @override
  String get influenceFactorJournaling => '写日记';

  @override
  String get influenceFactorYoga => '瑜伽';

  @override
  String get influenceFactorSunny => '晴天';

  @override
  String get influenceFactorCloudy => '多云';

  @override
  String get influenceFactorRainy => '雨天';

  @override
  String get influenceFactorSnowy => '雪天';

  @override
  String get influenceFactorWindy => '刮风';

  @override
  String get moodDetailTitle => '情绪详情';

  @override
  String get moodDetailFactors => '影响因素';

  @override
  String get moodDetailMoodState => '情绪状态';

  @override
  String get moodDetailCbtRecord => 'CBT 思维记录';

  @override
  String get moodEntryNotFound => '找不到这条情绪记录';

  @override
  String get moodTrendTitle => '情绪趋势';

  @override
  String get moodTrendWeek => '近 7 天';

  @override
  String get moodTrendDistribution => '分数分布';

  @override
  String get moodTrendNoData => '暂无数据';

  @override
  String get moodDeleteTooltip => '删除';

  @override
  String get moodDeleteConfirm => '确定删除这条记录吗？';

  @override
  String get moodFactorAnalysis => '因素关联分析';

  @override
  String get moodModeMomentary => '此刻';

  @override
  String get moodModeDaily => '今天';

  @override
  String get moodTrendDistTitle => '分数分布';

  @override
  String get moodTrendCbtTitle => 'CBT 重评效果';

  @override
  String get moodTrendCbtHint => '正值 = 情绪改善， 负值 = 恶化';

  @override
  String get moodTrendCbtEmpty => '暂无 CBT 重评数据';

  @override
  String get medDetailActive => '在用';

  @override
  String get medDetailStopped => '已停';

  @override
  String get medDetailAdherence => '依从性';

  @override
  String get medDetailLast30 => '近30天';

  @override
  String get medDetailDays => '服药天数';

  @override
  String get medDetailLast30Record => '近30天记录';

  @override
  String get medDetailEdit => '编辑';

  @override
  String get medDetailSettings => '设置';

  @override
  String get medDetailHistory => '用药历史';

  @override
  String get medDetailBasicInfo => '基本信息';

  @override
  String get medDetailRefill => '续方';

  @override
  String get moodCbtSituation => '情境';

  @override
  String get moodCbtAutoThought => '自动思维';

  @override
  String get moodCbtEvidenceFor => '支持证据';

  @override
  String get moodCbtEvidenceAgainst => '反对证据';

  @override
  String get moodCbtAltThought => '替代思维';

  @override
  String get moodCbtRerated => '重新评分';

  @override
  String get moodCbtCoreBelief => '核心信念';

  @override
  String get moodCbtBehavior => '行为应对';

  @override
  String get moodDeleted => '已删除';

  @override
  String get moodPeriodAfternoon => '下午';

  @override
  String get settingsProfileTitle => '个人资料';

  @override
  String get settingsProfileSubtitle => '健康档案、医疗信息';

  @override
  String get todaySummaryCheckIn => '打卡';

  @override
  String get todaySummaryMeds => '药物';

  @override
  String get todaySummaryMood => '心情';

  @override
  String get todaySummaryStreak => '连续';

  @override
  String get setupConsentMedicalDisclaimer =>
      '我已阅读并理解《医学免责声明》：本 App 不提供医疗建议、诊断或治疗，不能替代专业医疗服务';

  @override
  String get trackingCustomize => '自定义追踪项';

  @override
  String get trackingUnknownItem => '未知项目';

  @override
  String get trackingPin => '置顶';

  @override
  String get trackingUnpin => '取消置顶';

  @override
  String get trackingHide => '隐藏此项';

  @override
  String get trackingPinned => '收藏';

  @override
  String get trackingCategoryEmotional => '情绪状态';

  @override
  String get trackingCategoryPhysical => '身体指标';

  @override
  String get trackingCategoryBehavioral => '行为节律';

  @override
  String get trackingCategoryMedical => '医疗记录';

  @override
  String todayTrackingSummary(int tracked, int total) {
    return '今日已追踪 $tracked/$total 项';
  }

  @override
  String moodRecordingLabel(String duration) {
    return '录音 $duration';
  }

  @override
  String get medicationNameRequired => '请输入药物名称';

  @override
  String medicationAdded(String name) {
    return '已添加 $name';
  }

  @override
  String get medicationStatusInUse => '在用';

  @override
  String get medicationStatusStopped => '已停';

  @override
  String factorAnalysisCount(int count) {
    return '$count 条';
  }

  @override
  String get setupConsentAgreeAll => '我已阅读并同意以上所有协议';

  @override
  String get assessmentComparisonImproved => '好转';

  @override
  String get assessmentComparisonWorsened => '恶化';

  @override
  String get assessmentComparisonUnchanged => '持平';

  @override
  String get assessmentComparisonFirst => '首次评估';

  @override
  String assessmentDeltaSame(int delta) {
    return '和上次一样（$delta）';
  }

  @override
  String assessmentDeltaHigher(int delta) {
    return '比上次高 $delta 分';
  }

  @override
  String assessmentDeltaLower(int delta) {
    return '比上次低 $delta 分';
  }

  @override
  String assessmentSeverityRank(int rank) {
    return '等级 $rank';
  }

  @override
  String get checkInTypeAssessment => '心理量表评估';

  @override
  String dayDetailTotalScore(int total) {
    return '总分 $total';
  }

  @override
  String get dayDetailScaleAssessment => '心理量表评估';

  @override
  String get medTodayPending => '待服';

  @override
  String get medTodayTaken => '已服';

  @override
  String get medTodayRefill => '需续方';

  @override
  String get homeQuickActionView => '查看';

  @override
  String get homeQuickActionRecord => '记录';

  @override
  String get homeQuickActionStart => '开始';

  @override
  String get homeTodayMetrics => '今日指标';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appName => '慢病管家';

  @override
  String get homeCheckIn => '我今天吃了藥';

  @override
  String get homeCheckedIn => '今天已打卡 ✓';

  @override
  String homeStreak(int days) {
    return '已堅持 $days 天';
  }

  @override
  String homeLastMed(Object time) {
    return '最後吃藥：$time';
  }

  @override
  String homeNextReminder(Object time) {
    return '下次提醒：$time';
  }

  @override
  String get homeStillOnline => '🌱 您還在線';

  @override
  String get homeStreakBroken => '少 1 次沒關係，明天繼續';

  @override
  String setupStep(int current, int total) {
    return '第 $current 步 ／ 共 $total 步';
  }

  @override
  String get setupHello => '您好，我是慢病管家';

  @override
  String get setupIntro => '1 分鐘設置好，然後每天 1 次打卡';

  @override
  String get setupName => '您的名字（選填）';

  @override
  String get setupNameHint => '小明';

  @override
  String get setupNext => '下一步 →';

  @override
  String get setupMedNameHint => '請輸入藥盒上的名稱（選填）';

  @override
  String get setupStart => '開始我的第 1 天';

  @override
  String get setupDoneTitle => '全部完成！';

  @override
  String get setupDoneSubtitle => '明天開始您的第 1 天';

  @override
  String get setupDailyRoutine => '我每天會做：';

  @override
  String get setupReminder1 => '✓ 推送 1 次提醒';

  @override
  String get setupReminder2 => '✓ 您點 1 下 = 打卡';

  @override
  String get setupReminder3 => '✓ 漏 2 天提醒會升級，請及時打卡';

  @override
  String get setupPrivacy => '您的數據：';

  @override
  String get setupPrivacy1 => '• 本地加密';

  @override
  String get setupPrivacy2 => '• 不會上傳到任何雲端服務器';

  @override
  String get setupPrivacy3 => '• 您可以隨時導出';

  @override
  String get settingsMedication => '常吃藥';

  @override
  String get settingsAbout => '關於';

  @override
  String get settingsDisclaimer => '免責聲明';

  @override
  String get settingsMedReport => '用藥報告';

  @override
  String get settingsMedReportSubtitle => '選時間窗口（7／14／30 天），給醫生看';

  @override
  String get settingsMedReportChooseTitle => '選擇時間窗口';

  @override
  String get settingsMedReportChooseSubtitle => '會統計這段時間內的所有常吃藥 + 臨時用藥';

  @override
  String get settingsMedReportWindow7 => '近 7 天';

  @override
  String get settingsMedReportWindow14 => '近 14 天';

  @override
  String get settingsMedReportWindow30 => '近 30 天';

  @override
  String get settingsReportHistory => '報告歷史';

  @override
  String get settingsReportHistorySubtitle => '查看過去生成的用藥報告';

  @override
  String get settingsTitle => '設置';

  @override
  String get settingsDataManagement => '數據管理';

  @override
  String get settingsExportData => '導出數據';

  @override
  String get settingsExportSubtitle => '生成 JSON，複製到安全地方';

  @override
  String get settingsImportData => '導入數據';

  @override
  String get settingsImportSubtitle => '從 JSON 恢復（覆蓋現有數據）';

  @override
  String get settingsReminders => '提醒';

  @override
  String get settingsReminderCenter => '提醒中心';

  @override
  String get settingsReminderCenterSubtitle => '管理所有提醒：每日打卡、用藥時間、續方、心理評估、失聯通知';

  @override
  String get settingsRefillManagement => '續方管理';

  @override
  String get settingsRefillManagementSubtitle => '集中查看所有藥物的續方狀態';

  @override
  String get settingsAssessment => '心理評估';

  @override
  String get settingsAssessmentHistory => '評估歷史';

  @override
  String get settingsAssessmentHistorySubtitle =>
      '查看所有 PHQ-9 ／ GAD-7 評估的折線圖與對比';

  @override
  String settingsAboutVersion(String version) {
    return 'v$version · 我今天吃了藥';
  }

  @override
  String get settingsDisclaimerText => '本應用不提供醫療建議，所有功能僅供參考。';

  @override
  String get settingsExportRiskTitle => '明文風險提示';

  @override
  String get settingsExportRiskBody =>
      '您即將導出的數據為明文文件，含您的個人健康等敏感信息（用藥、打卡、緊急聯繫人、樹洞文字）。請務必保存到安全、可信的位置（加密 U 盤 / 私人云盤），避免上傳至公共雲盤或發送給不可信的第三方。';

  @override
  String get settingsExportRiskLiability =>
      '一旦導出，文件的安全與保密由您自行負責，本 App 不再承擔保護責任（PIPL §17 明確告知 + 用戶確認）。';

  @override
  String get settingsExportRiskAcknowledge => '我已瞭解風險，繼續導出';

  @override
  String get settingsExportDialogTitle => '導出數據';

  @override
  String get settingsExportInstruction => '把下面這串 JSON 保存到安全的地方：';

  @override
  String get settingsExportVentWarning =>
      '說明：樹洞（私密傾訴）的文字會導出，但錄音文件不導出——錄音存在 App 本地，重裝後路徑失效，無法跨設備複用。';

  @override
  String get settingsCopy => '複製';

  @override
  String get settingsActionExport => '導出';

  @override
  String get settingsActionGenerateReport => '生成報告';

  @override
  String get settingsImportDialogTitle => '導入數據';

  @override
  String get settingsImportWarning => '⚠️ 會覆蓋現有所有數據，確定後再繼續';

  @override
  String get settingsImportHint => '把導出的 JSON 粘貼到這裡';

  @override
  String settingsImportSuccess(Object summary) {
    return '導入完成：$summary';
  }

  @override
  String get settingsActionImport => '導入';

  @override
  String get settingsImportAndOverwrite => '導入並覆蓋';

  @override
  String get settingsClearAllData => '清空所有數據';

  @override
  String get settingsClearAllDataSubtitle =>
      '刪除全部打卡 ／ 用藥 ／ 評估 ／ 樹洞 ／ 聯繫人（無法恢復）';

  @override
  String get settingsClearAllDataDialogTitle => '確認清空所有數據？';

  @override
  String get settingsClearAllDataDialogBody =>
      '以下數據將被永久刪除，無法恢復：\n• 打卡記錄\n• 用藥與服藥歷史\n• 心理評估結果\n• 情緒日記\n• 樹洞（文字+錄音）\n• 緊急聯繫人\n\n清空後 App 會跳回首次設置流程。建議先導出 JSON 備份。';

  @override
  String get settingsClearAllDataConfirm => '我已備份，確認清空';

  @override
  String get settingsClearAllDataSuccess => '已清空所有數據';

  @override
  String get commonSave => '保存';

  @override
  String get commonBack => '返回';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '刪除';

  @override
  String get commonEdit => '編輯';

  @override
  String get commonLoading => '加載中……';

  @override
  String get lastStartupErrorBannerBody => '上次啟動出錯，請截圖反饋';

  @override
  String get commonClose => '關閉';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonRetry => '重試';

  @override
  String get commonGotIt => '我知道了';

  @override
  String get commonConfirmDelete => '刪除這條？';

  @override
  String get commonOptionNotSelected => '未選';

  @override
  String legalConsentWithdrawn(int current, int total) {
    return '已撤回 ($current/$total)';
  }

  @override
  String legalConsentReAgreed(int current, int total) {
    return '已重新同意 ($current/$total)';
  }

  @override
  String commonLoadFailed(Object error) {
    return '加載失敗：$error';
  }

  @override
  String snackbarErrorTemplate(Object action, Object error) {
    return '$action失敗：$error';
  }

  @override
  String get snackbarCopied => '已複製到剪貼板';

  @override
  String get snackbarNeedMicPermission => '需要麥克風權限';

  @override
  String get snackbarEmptyVent => '寫點東西或錄一段吧';

  @override
  String get snackbarStopRecording => '請先停止錄音';

  @override
  String get commonConfirmOk => '確定';

  @override
  String get commonMedName => '藥名';

  @override
  String get commonDoseUnit => '片';

  @override
  String get commonSetup => '設置';

  @override
  String get commonVentDeleteWarning => '刪了就沒了。文字和錄音都會一起刪。';

  @override
  String get medsListEmpty => '還沒添加常吃藥';

  @override
  String get medsCalendarTitle => '用藥日曆';

  @override
  String get medsCalendarSubtitle => '醫生視角依從性熱力圖 · 7／30／90 天';

  @override
  String get medsListNoActive => '沒有在用的藥';

  @override
  String get medsListNoActiveHint => '所有藥物都已停用，去添加新藥物開始新一階段。';

  @override
  String get medsListAddAction => '添加藥物';

  @override
  String get medsListStoppedSection => '已停藥';

  @override
  String get medsSnackUpdated => '已更新';

  @override
  String get medsSnackUpdatedSoftStop => '已更新 · 軟停';

  @override
  String get medsRefillPickDate => '選擇續方日期';

  @override
  String medsRefillSet(Object date, int days) {
    return '已設置：$date 續方，提前 $days 天提醒';
  }

  @override
  String get medsActionRefill => '設置續方';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return '已過期 $days 天 · 提前 $reminderDays 天提醒';
  }

  @override
  String medsRefillUpcoming(Object date, int days, int reminderDays) {
    return '續方：$date（$days 天后）· 提前 $reminderDays 天提醒';
  }

  @override
  String get medsRefillDaysTitle => '提前幾天提醒？';

  @override
  String medsRefillDaysUnit(int days) {
    return '$days 天';
  }

  @override
  String get medsRefillHint3 => '最後衝刺期';

  @override
  String get medsRefillHint5 => '比較緊';

  @override
  String get medsRefillHint7 => '推薦（默認）';

  @override
  String get medsRefillHint14 => '兩週時間掛號';

  @override
  String get medsRefillHint30 => '一個月週期';

  @override
  String get notificationStatusCardPermissionDeniedTitle => '通知權限已關閉';

  @override
  String get notificationStatusCardPermissionDeniedBody =>
      '無法發送用藥提醒。請在系統設置中允許通知，或點擊下方按鈕前往設置。';

  @override
  String get notificationStatusCardPermissionGoSettings => '前往系統設置';

  @override
  String get notificationStatusCardTestTitle => '🔔 通知自檢';

  @override
  String get notificationStatusCardTestBody => '看到這條 = 通知工作正常。如果沒看到，看下面的國產手機設置';

  @override
  String get notificationStatusCardTestSent => '已發送測試通知 — 幾秒內應該能收到';

  @override
  String get notificationStatusCardActionSend => '發送';

  @override
  String get notificationStatusCardQueuedTitle => '已排隊的通知';

  @override
  String get notificationStatusCardEmpty => '當前沒有任何待發通知。\n可能是沒設提醒，或被系統後臺清理了。';

  @override
  String get notificationStatusCardNoTitle => '（無標題）';

  @override
  String get notificationStatusCardWebTitle => '通知功能僅在 Android ／ iOS 上可用';

  @override
  String get notificationStatusCardWebSubtitle =>
      '當前是 web 端，通知由瀏覽器控制。請在手機上打開 App 測試。';

  @override
  String get notificationStatusCardStatusLoading => '加載中……';

  @override
  String get notificationStatusCardStatusUnsupported => '當前平臺不支持查詢';

  @override
  String get notificationStatusCardStatusNone => '⚠️ 沒有待發通知 — 提醒可能沒設上';

  @override
  String notificationStatusCardStatusCount(int count) {
    return '✓ 已排隊 $count 條待發通知';
  }

  @override
  String get notificationStatusCardTitle => '通知與提醒';

  @override
  String get notificationStatusCardTestButtonTitle => '測試通知';

  @override
  String get notificationStatusCardTestButtonSubtitle => '點一下立即推一條，確認通知能正常彈出';

  @override
  String get notificationStatusCardViewButtonTitle => '查看已排隊通知';

  @override
  String get notificationStatusCardViewButtonSubtitle => '展示當前所有待發的提醒';

  @override
  String get notificationStatusCardOemTitle => '國產手機沒收到通知？';

  @override
  String get notificationStatusCardOemSubtitle =>
      '小米／華為／OPPO／Vivo／三星 默認會殺後臺，點這裡看怎麼設';

  @override
  String get notificationStatusCardOemBrandXiaomi => '小米 ／ Redmi';

  @override
  String get notificationStatusCardOemStepXiaomi1 =>
      '設置 → 應用 → 慢病管家 → 自啟動 → 開啟';

  @override
  String get notificationStatusCardOemStepXiaomi2 =>
      '設置 → 應用 → 慢病管家 → 省電策略 → 無限制';

  @override
  String get notificationStatusCardOemStepXiaomi3 =>
      '設置 → 通知 → 慢病管家 → 允許通知 + 鎖屏通知';

  @override
  String get notificationStatusCardOemBrandHuawei => '華為 ／ 榮耀';

  @override
  String get notificationStatusCardOemStepHuawei1 =>
      '設置 → 應用 → 慢病管家 → 電池 → 啟動管理 → 允許自啟動';

  @override
  String get notificationStatusCardOemStepHuawei2 =>
      '設置 → 應用 → 慢病管家 → 通知 → 全部開啟';

  @override
  String get notificationStatusCardOemStepHuawei3 => '手機管家 → 應用啟動管理 → 關閉「自動管理」';

  @override
  String get notificationStatusCardOemBrandOppo => 'OPPO ／ realme ／ 一加';

  @override
  String get notificationStatusCardOemStepOppo1 =>
      '設置 → 電池 → 耗電保護 → 慢病管家 → 允許後臺運行';

  @override
  String get notificationStatusCardOemStepOppo2 => '設置 → 通知 → 慢病管家 → 全部開啟';

  @override
  String get notificationStatusCardOemStepOppo3 => '「最近任務」界面上鎖 App（下滑小鎖圖標）';

  @override
  String get notificationStatusCardOemBrandVivo => 'Vivo ／ iQOO';

  @override
  String get notificationStatusCardOemStepVivo1 =>
      '設置 → 電池 → 後臺高耗電 → 慢病管家 → 允許';

  @override
  String get notificationStatusCardOemStepVivo2 => '設置 → 通知 → 慢病管家 → 全部開啟';

  @override
  String get notificationStatusCardOemStepVivo3 => '「最近任務」界面上鎖 App';

  @override
  String get notificationStatusCardOemBrandMeizu => '魅族';

  @override
  String get notificationStatusCardOemStepMeizu1 =>
      '設置 → 應用管理 → 慢病管家 → 權限管理 → 自啟動 → 允許';

  @override
  String get notificationStatusCardOemStepMeizu2 => '設置 → 通知管理 → 慢病管家 → 全部開啟';

  @override
  String get notificationStatusCardOemBrandSamsung => '三星 (OneUI)';

  @override
  String get notificationStatusCardOemStepSamsung1 =>
      '設置 → 應用程序 → 慢病管家 → 通知 → 全部開啟';

  @override
  String get notificationStatusCardOemStepSamsung2 =>
      '設置 → 電池 → 後臺使用限制 → 慢病管家 → 改為「不受限」';

  @override
  String get notificationStatusCardOemBrandOthers => '其他（中興／努比亞／紅魔／聯想／三星 Knox）';

  @override
  String get notificationStatusCardOemStepOthers1 =>
      '設置 → 應用 → 慢病管家 → 通知 → 全部開啟';

  @override
  String get notificationStatusCardOemStepOthers2 => '設置 → 電池 → 後臺運行 → 改為「允許」';

  @override
  String get notificationStatusCardOemGeneralTip =>
      '通用建議：精確鬧鐘被某些 ROM 靜默拒絕時，首次啟動 App 時系統會彈「是否允許」，請選「允許」。';

  @override
  String get reminderHubDescription => '集中管理所有提醒：每天打卡、用藥時間、續方日期、心理評估、失聯通知。';

  @override
  String get reminderHubDailyTitle => '每日打卡提醒';

  @override
  String get reminderHubDailyDesc => '每天 20:00 推送「記得打卡」，漏 1 次沒關係';

  @override
  String get reminderHubDailyStatus => '已啟用 · 每天 20:00';

  @override
  String get reminderHubMedicationTitle => '用藥提醒';

  @override
  String get reminderHubStatusError => '出錯';

  @override
  String get reminderHubRefillTitle => '續方提醒';

  @override
  String get reminderHubAssessmentTitle => '週期評估提醒';

  @override
  String reminderHubAssessmentDescEnabled(int days) {
    return '每 $days 天提醒做心理評估（PHQ-9 ／ GAD-7）';
  }

  @override
  String get reminderHubAssessmentDescDisabled => '關閉 · 不會推送評估提醒';

  @override
  String reminderHubAssessmentStatusEnabled(int days) {
    return '已啟用 · 每 $days 天';
  }

  @override
  String get reminderHubStatusDisabled => '未啟用';

  @override
  String get reminderHubConfigure => '配置';

  @override
  String reminderHubMedicationDescActive(int count, int times) {
    return '共 $count 種在用藥物，$times 個時間點會推送提醒';
  }

  @override
  String get reminderHubMedicationDescInactive => '還沒有在用藥物 · 添加後會自動啟用';

  @override
  String reminderHubMedicationStatusActive(int count, int times) {
    return '已啟用 · $count 種 ／ $times 時間點';
  }

  @override
  String get reminderHubStatusNotConfigured => '未配置';

  @override
  String get reminderHubManageMedication => '管理用藥';

  @override
  String get reminderHubRefillDescNone => '未給任何藥物設置續方日期 · 在「用藥設置」中可加';

  @override
  String reminderHubRefillDescOverdue(int overdue, int inWindow) {
    return '$overdue 種已過期續方 · $inWindow 種在提醒窗口內';
  }

  @override
  String reminderHubRefillDescActive(int count) {
    return '$count 種藥物已設續方 · 臨近時會推送提醒';
  }

  @override
  String reminderHubRefillStatusOverdue(int count) {
    return '已過期 $count';
  }

  @override
  String reminderHubRefillStatusInWindow(int count) {
    return '提醒中 $count';
  }

  @override
  String reminderHubRefillStatusActive(int count) {
    return '已啟用 · $count 種';
  }

  @override
  String get reminderHubManageRefill => '管理續方';

  @override
  String get reminderHubEnable => '啟用';

  @override
  String get reminderHubAssessmentSubtitle => '每隔 N 天推送一次心理評估';

  @override
  String get reminderHubInterval => '提醒間隔';

  @override
  String reminderHubEveryNDays(int days) {
    return '每 $days 天';
  }

  @override
  String reminderHubNDays(int days) {
    return '$days 天';
  }

  @override
  String get ventListTitle => '我的樹洞';

  @override
  String get legalVentWithdrawTitle => '撤回樹洞同意';

  @override
  String get legalVentWithdrawBody => '樹洞內容是您最私密的數據。撤回同意後，您可選擇以下方式處理已有數據：';

  @override
  String get legalVentWithdrawDelete => '立即刪除';

  @override
  String get legalVentWithdrawDeleteDesc => '所有樹洞文字 + 錄音文件立即物理刪除，不可恢復';

  @override
  String get legalVentWithdrawSeal => '加密封存';

  @override
  String get legalVentWithdrawSealDesc => '數據保留在本地但加密，UI 不可見，重新同意後可恢復';

  @override
  String legalVentWithdrawnDeleted(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 條',
      one: '1 條',
      zero: '0 條',
    );
    return '已刪除 $_temp0樹洞';
  }

  @override
  String get legalVentWithdrawnSealed => '已加密封存，數據保留在本地';

  @override
  String get legalVentDeleteRetry => '重試刪除';

  @override
  String get ventSealedTitle => '已加密封存';

  @override
  String get ventSealedSubtitle => '您已撤回樹洞同意。所有數據已加密封存，UI 不可見。重新同意後可恢復。';

  @override
  String get ventSealedAction => '前往法律與隱私';

  @override
  String get ventListWriteTooltip => '寫一條';

  @override
  String get ventEmptyTitle => '樹洞還是空的';

  @override
  String get ventEmptySubtitle => '想說什麼就說出來。文字、語音都可以。\n這些話只有您自己能看到。';

  @override
  String get ventEmptyAction => '寫第一句';

  @override
  String get ventVoiceLabel => '🎙️ 語音';

  @override
  String get ventDetailTitle => '樹洞';

  @override
  String get ventDetailNotFound => '找不到了';

  @override
  String get ventDetailPrivacy => '🔒 私密 · 只有您能看到';

  @override
  String get ventReportTooltip => '舉報或反饋';

  @override
  String get ventReportDialogTitle => '私密傾訴說明';

  @override
  String get ventReportDialogBody =>
      '樹洞內容僅存儲在您的設備， 不會上傳任何服務器， 不存在用戶間互相看到的情況。\n\n如發現 App 本身的不當內容或想反饋問題， 請前往「法律與隱私」頁面聯繫開發者。';

  @override
  String get ventReportDialogAction => '前往法律與隱私';

  @override
  String get ventReportDialogClose => '關閉';

  @override
  String get ventToday => '今天';

  @override
  String get ventYesterday => '昨天';

  @override
  String get ventComposeTitle => '放進樹洞';

  @override
  String get ventComposeHint => '今天過得怎麼樣……';

  @override
  String get ventRecordIdle => '按一下開始錄音';

  @override
  String get ventAudioLabel => '錄音';

  @override
  String get ventAudioPlayTooltip => '播放錄音';

  @override
  String get audioRecordPauseTooltip => '暫停錄音';

  @override
  String get audioRecordResumeTooltip => '繼續錄音';

  @override
  String get audioRecordStopTooltip => '停止錄音';

  @override
  String get ventAudioPauseTooltip => '暫停錄音';

  @override
  String get ventRerecord => '重錄';

  @override
  String ventDurationSeconds(int sec) {
    return '$sec秒';
  }

  @override
  String ventDurationMinutes(int m) {
    return '$m分';
  }

  @override
  String ventDurationMinutesSeconds(int m, Object sec) {
    return '$m分$sec秒';
  }

  @override
  String get moodDialogTitle => '今天怎麼樣？';

  @override
  String get moodDialogPeriodLabel => '時段';

  @override
  String get moodPeriodMorning => '早上';

  @override
  String get moodPeriodNoon => '中';

  @override
  String get moodPeriodEvening => '晚上';

  @override
  String get moodPeriodNight => '夜間';

  @override
  String get moodPeriodUnspecified => '未指定';

  @override
  String get moodListFilterPeriod => '時段';

  @override
  String get moodPeriodChartTitle => '心境 4 段趨勢（近 30 天）';

  @override
  String get moodDimensionMood => '情緒';

  @override
  String get moodDimensionMoodHint => '1=很差 5=很好';

  @override
  String get moodDimensionEnergy => '精力';

  @override
  String get moodDimensionEnergyHint => '1=很低 5=充沛';

  @override
  String get moodDimensionSleep => '睡眠';

  @override
  String get moodDimensionSleepHint => '1=很差 5=很好';

  @override
  String get moodDimensionAnxiety => '焦慮';

  @override
  String get moodDimensionAnxietyHint => '1=嚴重 5=平靜';

  @override
  String get moodTagAnxiety => '焦慮';

  @override
  String get moodTagDepression => '抑鬱';

  @override
  String get moodTagCalm => '平靜';

  @override
  String get moodTagInsomnia => '失眠';

  @override
  String get moodTagIrritable => '煩躁';

  @override
  String get moodTagLowEnergy => '能量低';

  @override
  String get moodNoteLabel => '備註（可選）';

  @override
  String get moodNoteHint => '今天發生什麼？';

  @override
  String get moodAudioRecordButton => '錄語音';

  @override
  String moodAudioRecorded(Object duration) {
    return '已錄 $duration';
  }

  @override
  String get moodAudioRerecord => '重錄';

  @override
  String get moodAudioTranscriptLabel => '識別文字';

  @override
  String get moodAudioTranscriptPartialHint => '（僅識別前 60 秒）';

  @override
  String get moodAudioSttListening => '識別中……';

  @override
  String get moodAudioSttFailed => '識別失敗，已僅保存錄音';

  @override
  String get moodAudioSttUnavailable => '該設備暫不支持語音轉文字';

  @override
  String get moodAudioMaxReached => '已達 3 分鐘上限';

  @override
  String get moodAudioSavedWithPlay => '情緒已保存';

  @override
  String get moodAudioPlayAction => '回放';

  @override
  String get moodAudioErrorStart => '開始錄音失敗';

  @override
  String get moodAudioErrorStop => '停止錄音失敗';

  @override
  String get moodAudioErrorEncrypt => '加密錄音失敗';

  @override
  String get moodAudioErrorPlay => '播放失敗';

  @override
  String get medsTodaySchedule => '今日服藥計劃';

  @override
  String get medsTotal => '總藥數';

  @override
  String get medsRefillSetCount => '已設續方';

  @override
  String get medsRefillReminding => '提醒中';

  @override
  String get refillManageOverdue => '已過期';

  @override
  String get refillManageMedsList => '藥物列表';

  @override
  String get refillManageSummary => '續方彙總';

  @override
  String get medsNoMedicationsAdded => '還沒有添加藥物';

  @override
  String get medsRefillEditHint => '點擊任一行可編輯續方日期。提醒窗口：續方前 N 天（N=reminderDays）。';

  @override
  String get medsRefillStatusNotConfigured => '未設置';

  @override
  String get medsRefillStatusSet => '已設';

  @override
  String get medsRefillStatusReminding => '提醒中';

  @override
  String get medsRefillStatusOverdue => '已過期';

  @override
  String medsRefillNotSetSubtitle(int days) {
    return '未設續方日期 · 提醒窗口 $days 天';
  }

  @override
  String medsRefillExpiredDays(int days) {
    return '已過 $days 天';
  }

  @override
  String get medsRefillToday => '今天';

  @override
  String medsRefillRemainingDays(int days) {
    return '還有 $days 天';
  }

  @override
  String medsRefillSubtitleTemplate(
      Object date, Object suffix, int reminderDays) {
    return '$date $suffix · 提前 $reminderDays 天提醒';
  }

  @override
  String get assessmentLoadingBack => '正在返回上一頁……';

  @override
  String assessmentAnsweredProgress(int answered, int total) {
    return '已答 $answered ／ $total';
  }

  @override
  String get assessmentSubmit => '提交併查看結果';

  @override
  String assessmentQuestionLabel(int index, Object text, Object selected) {
    return '評估題 $index：$text，4 項單選，當前：$selected';
  }

  @override
  String assessmentScoreTotal(int max) {
    return '總分（0-$max）';
  }

  @override
  String get assessmentRecommendUrgent => '強烈建議您儘快聯繫醫生或心理治療師。';

  @override
  String get assessmentRecommend => '建議您聯繫醫生做進一步評估。';

  @override
  String get assessmentDisclaimer => '⚠️ 本評估僅供參考，不能代替專業診斷。\n如感到困擾，請諮詢醫生。';

  @override
  String get assessmentBack => '返回';

  @override
  String get assessmentRetake => '再做一次';

  @override
  String get homeHeaderDefaultTitle => '慢病管家';

  @override
  String homeHeaderKeepGoing(Object name) {
    return '$name 還在堅持';
  }

  @override
  String get ventSwipeHint => '左滑或長按條目可刪除';

  @override
  String get homeStreakRestart => '今天重新開始 🌱';

  @override
  String get homeStreakDay1 => '第 1 天，邁出第一步 🌱';

  @override
  String homeStreakDays(int days) {
    return '堅持 $days 天，繼續 🌿';
  }

  @override
  String homeStreakGreat(int days) {
    return '已堅持 $days 天 🌳';
  }

  @override
  String homeStreakAmazing(int days) {
    return '$days 天連擊 🌲';
  }

  @override
  String homeStreakMaster(int days) {
    return '$days 天 🏔️';
  }

  @override
  String get navMood => '心情';

  @override
  String get navVent => '樹洞';

  @override
  String get navTrend => '趨勢';

  @override
  String get navSettings => '設置';

  @override
  String get navAppName => '慢病管家';

  @override
  String errorPageNotFound(Object path) {
    return '頁面不存在：$path';
  }

  @override
  String get errorPageHint => '這個地址可能已經失效，或者鏈接有誤。';

  @override
  String get errorPageBackHome => '返回首頁';

  @override
  String assessmentReminderEnabled(int days) {
    return '已開啟：每 $days 天提醒做心理評估';
  }

  @override
  String assessmentReminderChanged(int days) {
    return '已改為：每 $days 天提醒';
  }

  @override
  String assessmentReminderSubtitleEnabled(int days) {
    return '每 $days 天提醒我做一次心理評估';
  }

  @override
  String get assessmentReminderHelpText =>
      '完成一次評估後，下次提醒會從今天重新算起。\n評估結果僅您自己看得到。';

  @override
  String get assessmentReminderHintAcute => '高強度監測（適合急性期）';

  @override
  String get assessmentReminderHintCommon => '推薦（精神科常用）';

  @override
  String get assessmentReminderHintStable => '穩定期 ／ 月度覆盤';

  @override
  String get assessmentReminderHintMaintenance => '維持治療期';

  @override
  String get assessmentReminderHintLongTerm => '長期隨訪';

  @override
  String get assessmentHistoryTrend => '歷史趨勢';

  @override
  String assessmentAverageScore(Object score) {
    return '平均 $score';
  }

  @override
  String assessmentTotalRecords(int count) {
    return '共 $count 次';
  }

  @override
  String assessmentScoreRange(int min, int max) {
    return '最低 $min ／ 最高 $max';
  }

  @override
  String get assessmentComparePrevious => '對比上次';

  @override
  String get assessmentFirstAssessmentHint => '這是您的第一次評估。下次評估後會顯示和這次的對比。';

  @override
  String get assessmentPrevious => '上次';

  @override
  String get assessmentCurrent => '本次';

  @override
  String assessmentDaysSincePrevious(int days) {
    return '距上次 $days 天';
  }

  @override
  String get assessmentHistoryEmpty => '還沒有評估記錄';

  @override
  String get assessmentHistoryEmptyHint => '完成一次心理評估後，記錄會顯示在這裡';

  @override
  String get assessmentHistoryStartFirst => '開始第一次評估';

  @override
  String get assessmentHistoryTotalAssessments => '總評估';

  @override
  String get assessmentHistoryTimes => '次';

  @override
  String get assessmentHistoryLatestPhq9 => '最近 PHQ-9';

  @override
  String get assessmentHistoryLatestGad7 => '最近 GAD-7';

  @override
  String get assessmentHistoryNotDone => '未做';

  @override
  String get assessmentChartNoData => '還沒有數據';

  @override
  String get assessmentChartNeedMore => '只有 1 次評估，無法畫趨勢 — 至少需要 2 次';

  @override
  String assessmentChartRecordCount(int count) {
    return '$count 次評估';
  }

  @override
  String assessmentChartTotalScore(int score, int max) {
    return '總分 $score/$max';
  }

  @override
  String get assessmentHistoryFullRecord => '完整記錄';

  @override
  String get assessmentSeverityNormal => '幾乎沒有';

  @override
  String get assessmentSeverityMild => '輕度';

  @override
  String get assessmentSeverityModerate => '中度';

  @override
  String get assessmentSeverityModeratelySevere => '中重度';

  @override
  String get assessmentSeveritySevere => '重度';

  @override
  String get assessmentSeverityUnknown => '未知';

  @override
  String get assessmentScalePhq9 => 'PHQ-9 抑鬱篩查';

  @override
  String get assessmentScaleGad7 => 'GAD-7 焦慮篩查';

  @override
  String get setupConsentRequired => '請先完成法律文件閱讀與同意';

  @override
  String get setupValidationNameRequired => '請輸入您的名字';

  @override
  String get setupPresetTitle => '📋 選擇預置方案';

  @override
  String get setupPresetDescription => '預置方案會填好藥名 + 時間，您可以接著改。最終服藥請按醫囑核對。';

  @override
  String setupPresetLoaded(Object name, int count) {
    return '已載入：$name（$count 個藥）請核對藥名和劑量';
  }

  @override
  String get setupMedWhatDoYouTake => '您常吃什麼藥？';

  @override
  String get setupMedMultiDrugHint => '（可加多個藥，每個藥配自己的時間和劑量；跳過不影響打卡）';

  @override
  String get setupMedEmptyHint => '還沒添加藥物。可以跳過——打卡不需要藥物信息。';

  @override
  String get setupMedAddDrug => '+ 添加藥物';

  @override
  String get setupMedLoadPreset => '📋 載入預置方案（4 種常見模式）';

  @override
  String get setupBack => '← 上一步';

  @override
  String setupMedDrugNumber(int number) {
    return '藥物 $number';
  }

  @override
  String get setupMedDeleteDrug => '刪除這個藥';

  @override
  String get setupMedDosage => '劑量';

  @override
  String get setupMedUnit => '單位';

  @override
  String get setupMedTimeHint => '吃藥時間（點 + 加）';

  @override
  String get setupMedAddTime => '加時間';

  @override
  String get setupMedTimeOptional => '（不設置時間 = 不調度提醒，僅記錄）';

  @override
  String get setupConsentTitle => '使用前請閱讀';

  @override
  String get setupConsentDescription =>
      '為遵守《個人信息保護法》(PIPL)，本 App 處理您的健康醫療等敏感個人信息前，需要您明確、單獨同意以下 3 份文件。';

  @override
  String get setupConsentUserAgreement => '我已閱讀並同意《用戶協議》';

  @override
  String get setupConsentPrivacyPolicy => '我已閱讀並同意《隱私政策》';

  @override
  String get setupConsentSensitiveData => '我已閱讀並同意《敏感個人信息處理同意書》';

  @override
  String get setupConsentStart => '開始設置';

  @override
  String get setupConsentWithdrawHint =>
      '提示：您可以隨時在「設置 → 法律與隱私」撤回同意。拒絕或撤回後，App 的相關功能將無法使用。';

  @override
  String get setupLegalUserAgreement => '用戶協議';

  @override
  String get setupLegalPrivacyPolicy => '隱私政策';

  @override
  String get setupLegalSensitiveData => '敏感個人信息處理同意書';

  @override
  String get setupLegalLoadFailed => '加載失敗，請檢查網絡或重新打開 App';

  @override
  String get setupConsentView => '查看';

  @override
  String get settingsLegalAndPrivacy => '法律與隱私';

  @override
  String get settingsLegalAndPrivacySubtitle => '查看協議、隱私政策、撤回同意';

  @override
  String get legalPageTitle => '法律與隱私';

  @override
  String get legalPageDocuments => '法律文檔';

  @override
  String get legalPageWithdrawTitle => '撤回同意';

  @override
  String get legalPageWithdrawDescription => '撤回某項同意後，相關功能立即停用（數據不刪除，可重新打開）。';

  @override
  String get legalPageWithdrawVent => '撤回樹洞（敏感傾訴）處理同意';

  @override
  String get legalPageWithdrawVentSubtitle => '停止存儲新樹洞文字／錄音（已有數據保留，需手動刪除）';

  @override
  String get legalPageWithdrawAnalytics => '撤回評估／情緒分析同意';

  @override
  String get legalPageWithdrawAnalyticsSubtitle =>
      '停止將評估／情緒記錄納入趨勢分析（數據保留，不再入圖表）';

  @override
  String legalPageConsentRecorded(Object time) {
    return '撤回時間：$time';
  }

  @override
  String get legalPageConsentNever => '從未撤回';

  @override
  String get reportHistoryEmpty => '還沒有報告歷史\n生成一次報告後會自動記錄';

  @override
  String reportHistoryItemTitle(Object date, int days) {
    return '$date · 近 $days 天';
  }

  @override
  String reportHistoryItemPatient(Object name) {
    return '患者：$name';
  }

  @override
  String get reportHistoryItemNotSet => '未設置';

  @override
  String get reportHistoryDeleteTitle => '刪除這條報告？';

  @override
  String get reportHistoryDeleteContent => '刪除後無法恢復，但可以重新生成。';

  @override
  String get homeCelebrationDay1 => '已記錄！第 1 天 🌱';

  @override
  String homeCelebrationStreakShort(int days) {
    return '已記錄！連擊 $days 天 🌿';
  }

  @override
  String homeCelebrationStreakMedium(int days) {
    return '已記錄！連擊 $days 天 🌳';
  }

  @override
  String homeCelebrationStreakLong(int days) {
    return '已記錄！$days 天連擊 🌲';
  }

  @override
  String homeCelebrationStreakMaster(int days) {
    return '已記錄！$days 天 🏔️';
  }

  @override
  String homeAutofireCelebration(Object name) {
    return '已打卡：$name ✅';
  }

  @override
  String get homeAutofireFallbackName => '該藥';

  @override
  String homeMedHint(int id) {
    return '💊 準備打卡藥物 #$id';
  }

  @override
  String get homeSnoozeTitle => '⏰ 該打卡了（5min 後）';

  @override
  String get notifChannelMedicationName => '吃藥提醒';

  @override
  String get notifChannelMedicationDesc => '到點提醒你吃藥打卡';

  @override
  String get homeNotifBannerText => '提醒沒設上，可能錯過打卡。請到系統設置允許通知。';

  @override
  String get homeNotifBannerDismiss => '知道了';

  @override
  String themeTooltip(Object mode) {
    return '主題：$mode（點擊切換）';
  }

  @override
  String get themeModeSystem => '跟隨系統';

  @override
  String get themeModeLight => '亮色';

  @override
  String get themeModeDark => '暗色';

  @override
  String get trendTitle => '我的趨勢';

  @override
  String get trendLast30Days => '最近 30 天';

  @override
  String get trendLast6Months => '最近 6 個月';

  @override
  String get trendAssessmentHistory => '心理評估歷史';

  @override
  String get trendMoodHistory => '情緒日記歷史';

  @override
  String get trendViewList => '列表';

  @override
  String get trendViewCalendar => '日曆';

  @override
  String get trendWithdrawnTitle => '趨勢分析已撤回';

  @override
  String get trendWithdrawnSubtitle =>
      '你撤回了「趨勢分析」同意（PIPL §14）。趨勢數據未刪除， 重新開啟後即可恢復。';

  @override
  String get trendWithdrawnAction => '去重新開啟';

  @override
  String get trendWeekdayMon => '一';

  @override
  String get trendWeekdayTue => '二';

  @override
  String get trendWeekdayWed => '三';

  @override
  String get trendWeekdayThu => '四';

  @override
  String get trendWeekdayFri => '五';

  @override
  String get trendWeekdaySat => '六';

  @override
  String get trendWeekdaySun => '日';

  @override
  String get trendPrevMonth => '上個月';

  @override
  String get trendNextMonth => '下個月';

  @override
  String trendMonthYear(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String get trendCheckedIn => '已打卡';

  @override
  String get trendNotCheckedIn => '未打卡';

  @override
  String trendEventCount(int count) {
    return '$count 個事件';
  }

  @override
  String trendMoodEntriesSame(int count, Object emoji) {
    return '$count 條情緒記錄 · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, Object lowEmoji, Object highEmoji) {
    return '情緒 $count 條 · $lowEmoji→$highEmoji';
  }

  @override
  String get trendNoRecords => '這一天沒有記錄';

  @override
  String get trendStatCurrentStreak => '當前連續';

  @override
  String get trendStatLongestStreak => '最長連續';

  @override
  String get trendStatTotalCheckIns => '總打卡';

  @override
  String get trendStatTotalDays => '總天數';

  @override
  String trendStatDaysValue(int count) {
    return '$count 天';
  }

  @override
  String trendMonthLabel(int month) {
    return '$month月';
  }

  @override
  String get trendNoAssessments => '還沒有評估記錄';

  @override
  String get trendNoAssessmentsHint => '完成一次心理評估後，折線圖會自動出現在這裡';

  @override
  String get trendNoMoodEntries => '還沒有情緒記錄';

  @override
  String get trendNoMoodEntriesHint => '在主頁點擊「記一下情緒」開始記錄';

  @override
  String get trendCbtReratedChartTitle => '重評效果';

  @override
  String get trendCbtReratedEmptyTitle => '還沒有 5/7 欄 CBT 數據';

  @override
  String get trendCbtReratedEmptyHint => '先用 5/7 欄 CBT 填表， 才能看到重評效果';

  @override
  String get contactConsentTitle => '知情同意';

  @override
  String get contactConsentAgree => '已告知並取得同意';

  @override
  String get contactConsentReject => '暫不同意';

  @override
  String get contactConsentVersion => 'v1 · 2026-07-31';

  @override
  String get dataExportConsentTitle => '數據導出同意';

  @override
  String dataExportConsentBody(
      Object purpose, Object dataCategories, Object retention) {
    return '您即將導出本地數據庫中的所有數據。\n\n**目的**：$purpose\n**數據範圍**：$dataCategories\n**保留方式**：$retention\n\n**根據《個人信息保護法》第 13 條**（數據可攜權 + 單獨同意），請確認您已瞭解上述用途，並同意本次導出。';
  }

  @override
  String get dataExportConsentConfirm => '我瞭解並同意導出';

  @override
  String get dataExportConsentVersion => 'v1 · 2026-08-15';

  @override
  String get editMedDialogTitle => '編輯藥物';

  @override
  String get editMedValidationNameRequired => '請填寫藥名';

  @override
  String get editMedValidationDosageInvalid => '劑量必須是大於 0 的數字';

  @override
  String get editMedValidationUnitInvalid => '單位必須是 mg 或 片';

  @override
  String editMedSaveFailed(Object error) {
    return '保存失敗：$error';
  }

  @override
  String get editMedStatusActive => '正在使用';

  @override
  String get editMedStatusStopped => '已停藥';

  @override
  String editMedStoppedDate(Object date) {
    return '$date 停藥';
  }

  @override
  String get editMedNameHint => '請輸入藥盒上的名稱（選填）';

  @override
  String get editMedDosageLabel => '劑量';

  @override
  String get editMedUnitLabel => '單位';

  @override
  String get editMedTimeSectionLabel => '吃藥時間（點 + 加）';

  @override
  String get editMedAddTime => '加時間';

  @override
  String get editMedNoTimeHint => '（不設置時間 = 不調度提醒，僅記錄）';

  @override
  String get editMedStopAction => '停用此藥';

  @override
  String get editMedResumeAction => '重新啟用';

  @override
  String get editMedStopHint => '軟停：保留所有打卡歷史，不再推送提醒';

  @override
  String get editMedResumeHint => '恢復：清空停藥日期，恢復每日提醒';

  @override
  String get medReportCopyHint => '可全選複製、生成 PDF 或分享給醫生';

  @override
  String get medReportPdfLabel => 'PDF';

  @override
  String get medReportShareLabel => '分享';

  @override
  String get medReportPdfLoading => '生成 PDF 中……';

  @override
  String get medReportShareSubject => '慢病管家 · 用藥報告';

  @override
  String get tempMedNoLink => '不關聯';

  @override
  String get medsCalendarHeatmapDesc => '以藥為單位的依從性熱力圖。顏色越深 = 當天打卡次數越接近期望次數。';

  @override
  String get medsCalendarWindow7 => '7 天';

  @override
  String get medsCalendarWindow30 => '30 天';

  @override
  String get medsCalendarWindow90 => '90 天';

  @override
  String get medsCalendarWindowTitle => '時間窗口';

  @override
  String medsCalendarLoadCheckinFailed(Object error) {
    return '加載打卡失敗：$error';
  }

  @override
  String medsCalendarLoadMedFailed(Object error) {
    return '加載藥物失敗：$error';
  }

  @override
  String get medsCalendarNoActive => '還沒有在用藥物';

  @override
  String get medsCalendarNoSchedule => '在用藥物未設置服用時間，無法生成依從性日曆';

  @override
  String get medsCalendarNoScheduleHint => '在設置頁給藥物加上服藥時間後，這裡會顯示服藥日曆';

  @override
  String get medsCalendarNoActiveAction => '添加藥物';

  @override
  String get medsCalendarNoScheduleAction => '去設置時間';

  @override
  String get medsCalendarLegendLabel => '依從：';

  @override
  String get medsCalendarLegendTitle => '圖例';

  @override
  String get medsCalendarLegendMissed => '漏服';

  @override
  String medsCalendarDayDetailTitle(String date) {
    return '$date 的打卡';
  }

  @override
  String get medsCalendarDayDetailEmpty => '當天還沒有打卡';

  @override
  String get medCalendarBackfillConfirm => '確認補打卡';

  @override
  String medCalendarBackfillSuccess(Object date) {
    return '已補打卡 $date';
  }

  @override
  String get medsCalendarDayDetailAddLog => '補打卡';

  @override
  String get medsCalendarDayDetailAddLogHint => '為今天補一次服藥記錄';

  @override
  String medsCalendarDayDetailLogItem(String time, String name) {
    return '$time · $name';
  }

  @override
  String get medsCalendarLegendPartial => '< 50%';

  @override
  String get medsCalendarLegendAlmost => '< 100%';

  @override
  String get medsCalendarLegendFull => '100%';

  @override
  String get window7Subtitle => '一週內（適合周複診）';

  @override
  String get window14Subtitle => '兩週內（推薦）';

  @override
  String get window30Subtitle => '一個月內（適合月度評估）';

  @override
  String get snackbarActionSave => '保存';

  @override
  String get snackbarActionShare => '分享';

  @override
  String get snackbarActionGeneratePdf => '生成 PDF';

  @override
  String get snackbarActionPlay => '播放';

  @override
  String get snackbarActionEncryptRecording => '加密錄音';

  @override
  String get snackbarActionCheckin => '打卡';

  @override
  String get snackbarActionAutoCheckin => '自動打卡';

  @override
  String get snackbarActionFinishSetup => '完成設置';

  @override
  String get snackbarActionUndo => '撤銷';

  @override
  String get ventEntryDeleted => '已刪除樹洞條目';

  @override
  String get medicationDeleted => '已刪除藥物';

  @override
  String get moodTodayLabel => '今日情緒：';

  @override
  String moodTodayLabelWithValue(String value) {
    return '今日情緒：$value';
  }

  @override
  String get moodLabel1 => '很差';

  @override
  String get moodLabel2 => '差';

  @override
  String get moodLabel3 => '一般';

  @override
  String get moodLabel4 => '好';

  @override
  String get moodLabel5 => '很好';

  @override
  String get moodRecordButton => '記一下情緒 ✏️';

  @override
  String medReportFileName(Object date) {
    return '用藥報告_$date';
  }

  @override
  String get migrationPromptTitle => '升級到 v0.9';

  @override
  String get migrationPromptDetectedOld => '檢測到本地有舊版本數據。';

  @override
  String get migrationPromptChangesTitle => '本次升級會：';

  @override
  String get migrationPromptChangeEncrypt => '• 啟用數據庫加密（保護您的隱私）';

  @override
  String get migrationPromptChangeClear => '• 清空舊版本的所有打卡記錄';

  @override
  String get migrationPromptChangeWarning => '（舊版本沒有\"導出數據\"功能，原始數據無法恢復）';

  @override
  String get migrationPromptRecommendExport => '建議：先在舊版 App 內完成\"導出數據\"備份，再升級。';

  @override
  String get migrationPromptDirectContinue => '若舊版已卸載無法導出，可以直接點\"繼續升級\"。';

  @override
  String get migrationPromptCancel => '取消';

  @override
  String get migrationPromptContinue => '繼續升級';

  @override
  String get migrationAbortedTitle => '升級已取消';

  @override
  String get migrationAbortedBody =>
      '請先在舊版本 App 內完成\"導出數據\"備份，\n備份完成後點下方按鈕繼續升級。';

  @override
  String get migrationAbortedRetry => '已備份，繼續升級';

  @override
  String get migrationFailedTitle => '啟動失敗';

  @override
  String get migrationFailedBody =>
      '無法初始化本地數據。\n請嘗試：\n1) 重啟 App\n2) 卸載後重裝\n如反覆出現，請反饋給我們。';

  @override
  String get migrationFailedReassure => '請別擔心，您的數據是加密的。我們會盡快解決。';

  @override
  String get moodRatingSemantics => '情緒評分，1 到 5 分制，5 分最積極';

  @override
  String moodRatingButtonSemantics(Object score, String selected) {
    String _temp0 = intl.Intl.selectLogic(
      selected,
      {
        'true': '，已選',
        'other': '',
      },
    );
    return '$score 分$_temp0';
  }

  @override
  String medicationTimeWindowSemantics(Object days) {
    return '時間窗口 $days 天，7／30／90 單選';
  }

  @override
  String get assessmentSaveFailed => '評估結果已顯示，但保存失敗。請稍後重試。';

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => '片';

  @override
  String get safetyCheckResultDisabled => '安全開關已關閉';

  @override
  String get presetMedSsriMorningTitle => '單藥 · SSRI 早一次';

  @override
  String get presetMedSsriMorningDesc => '1 種藥，每天早 8 點服用（適用 SSRI ／ SNRI 類）';

  @override
  String get presetMedMoodStabilizerTwiceTitle => '情緒穩定劑 · 早晚兩次';

  @override
  String get presetMedMoodStabilizerTwiceDesc => '1 種藥，每天早 8 點 + 晚 20 點';

  @override
  String get presetMedComboSsriBedtimeTitle => '聯合 · 早抗抑鬱 + 晚助眠';

  @override
  String get presetMedComboSsriBedtimeDesc => '2 種藥：早 8 點 SSRI + 晚 21 點助眠';

  @override
  String get presetMedComboAntipsychoticFullTitle => '重性 · 早中晚三次';

  @override
  String get presetMedComboAntipsychoticFullDesc =>
      '2 種藥：早 8 ／ 午 13 ／ 晚 20，覆蓋全天';

  @override
  String get presetMedSsriName => 'SSRI 類抗抑鬱藥';

  @override
  String get presetMedSsriHint => '常見 SSRI ／ SNRI 類抗抑鬱藥（具體藥名以醫生處方為準）';

  @override
  String get presetMedMoodStabilizerName => '情緒穩定劑';

  @override
  String get presetMedMoodStabilizerHint => '常見情緒穩定劑類（具體藥名以醫生處方為準）';

  @override
  String get presetMedSleepAidName => '助眠藥';

  @override
  String get presetMedSleepAidHint => '常見苯二氮卓類／助眠藥（具體藥名以醫生處方為準）';

  @override
  String get presetMedAntipsychoticName => '抗精神病藥';

  @override
  String get presetMedAntipsychoticHint => '常見非典型抗精神病藥（具體藥名以醫生處方為準）';

  @override
  String get presetMedSedativeAnxiolyticName => '鎮靜／抗焦慮輔助';

  @override
  String get presetMedSedativeAnxiolyticHint => '常見鎮靜／抗焦慮輔助藥（具體藥名以醫生處方為準）';

  @override
  String dayDetailCheckInWith(Object name) {
    return '打卡 · $name';
  }

  @override
  String get dayDetailDailyCheckIn => '每日打卡';

  @override
  String dayDetailTempWith(Object name) {
    return '臨時 · $name';
  }

  @override
  String get dayDetailTempMed => '臨時吃藥';

  @override
  String get dayDetailPhq9 => 'PHQ-9 抑鬱篩查';

  @override
  String get dayDetailGad7 => 'GAD-7 焦慮篩查';

  @override
  String get scaleHotlineCn => '全國 24 小時心理援助熱線';

  @override
  String get scaleHotlineCn2 => '北京心理危機研究與干預中心';

  @override
  String get scaleHotlineUs => '988 Suicide & Crisis Lifeline (US)';

  @override
  String get scaleHotlineUs2 => 'Crisis Text Line (text HOME to 741741)';

  @override
  String get scaleHotlineHk => '撒瑪利亞防止自殺會（24h 多語言）';

  @override
  String get scaleHotlineTw => '生命線（24h）';

  @override
  String get scaleHotlineTw2 => '安心專線（心理諮商）';

  @override
  String get scaleHotlineSg => 'Samaritans of Singapore (24h)';

  @override
  String get scaleHotlineUk => 'Samaritans UK & ROI (24h 免費)';

  @override
  String get scaleHotlineIntl => '國際通用 · 請聯繫當地急救或心理援助';

  @override
  String get scaleCrisisTitle => '我們關心你';

  @override
  String get scaleCrisisMessage => '你提到了想傷害自己的念頭。\n請記住：尋求幫助是勇敢的，不是軟弱。';

  @override
  String get phq9Item0 => '做事時提不起勁或沒有興趣';

  @override
  String get phq9Item1 => '感到心情低落、沮喪或絕望';

  @override
  String get phq9Item2 => '入睡困難、睡不安穩或睡得過多';

  @override
  String get phq9Item3 => '感覺疲倦或沒有活力';

  @override
  String get phq9Item4 => '食慾不振或吃太多';

  @override
  String get phq9Item5 => '覺得自己很糟、很失敗，或讓自己和家人失望';

  @override
  String get phq9Item6 => '對事物專注有困難，例如看報紙或看電視時';

  @override
  String get phq9Item7 => '動作或說話速度緩慢到別人能察覺？\n或正好相反——煩躁或坐立不安';

  @override
  String get phq9Item8 => '有不如死掉或用某種方式傷害自己的念頭';

  @override
  String get phq9Option0 => '完全不會';

  @override
  String get phq9Option1 => '好幾天';

  @override
  String get phq9Option2 => '一半以上的天數';

  @override
  String get phq9Option3 => '幾乎每天';

  @override
  String get phq9SeverityLabel0 => '幾乎沒有抑鬱';

  @override
  String get phq9SeverityLabel1 => '輕度抑鬱';

  @override
  String get phq9SeverityLabel2 => '中度抑鬱';

  @override
  String get phq9SeverityLabel3 => '中重度抑鬱';

  @override
  String get phq9SeverityLabel4 => '重度抑鬱';

  @override
  String get phq9SeveritySummary0 => '幾乎沒有抑鬱傾向';

  @override
  String get phq9SeveritySummary1 => '輕度抑鬱傾向';

  @override
  String get phq9SeveritySummary2 => '中度抑鬱傾向';

  @override
  String get phq9SeveritySummary3 => '中重度抑鬱傾向';

  @override
  String get phq9SeveritySummary4 => '重度抑鬱傾向';

  @override
  String get phq9Instruction => '過去兩週內，你有多經常被以下問題困擾？';

  @override
  String get phq9ShortDescription => '過去兩週的抑鬱傾向篩查';

  @override
  String get gad7Item0 => '感到緊張、焦慮或急切';

  @override
  String get gad7Item1 => '不能停止或控制擔憂';

  @override
  String get gad7Item2 => '對各種事情擔憂過多';

  @override
  String get gad7Item3 => '難以放鬆';

  @override
  String get gad7Item4 => '心情煩躁以至坐不住';

  @override
  String get gad7Item5 => '變得容易煩惱或急躁';

  @override
  String get gad7Item6 => '感到似乎將有可怕的事情發生而害怕';

  @override
  String get gad7SeverityLabel0 => '幾乎沒有焦慮';

  @override
  String get gad7SeverityLabel1 => '輕度焦慮';

  @override
  String get gad7SeverityLabel2 => '中度焦慮';

  @override
  String get gad7SeverityLabel3 => '重度焦慮';

  @override
  String get gad7SeveritySummary0 => '幾乎沒有焦慮傾向';

  @override
  String get gad7SeveritySummary1 => '輕度焦慮傾向';

  @override
  String get gad7SeveritySummary2 => '中度焦慮傾向';

  @override
  String get gad7SeveritySummary3 => '重度焦慮傾向';

  @override
  String get gad7Instruction => '過去兩週內，你有多經常被以下問題困擾？';

  @override
  String get gad7ShortDescription => '過去兩週的焦慮傾向篩查';

  @override
  String get homeFabVent => '樹洞';

  @override
  String get homeMoodHeroTitle => '今日心情';

  @override
  String get homeMoodHeroRecord => '記錄心情';

  @override
  String get homeMoodHeroReview => '回顧';

  @override
  String get homeMoodHeroNoData => '今天還沒記錄心情';

  @override
  String homeMoodHeroLastRecorded(String time) {
    return '上次記錄 $time';
  }

  @override
  String get homeVentHeroTitle => '樹洞';

  @override
  String get homeVentHeroWrite => '寫心事';

  @override
  String get homeVentHeroNoData => '還沒有傾訴, 寫第一條心事';

  @override
  String get homeActionMedication => '用藥';

  @override
  String get homeActionAssessment => '量表';

  @override
  String get homeActionMoodReview => '情緒回顧';

  @override
  String get homeActionDailyTracking => '日常追蹤';

  @override
  String get homeFabHotline => '緊急熱線';

  @override
  String get homeFabTop => '回到頂端';

  @override
  String get trendChip30Day => '近 30 天';

  @override
  String get assessmentChipCurrent => '本週';

  @override
  String get crisisHotlineCnLabel => '全國 24 小時心理援助熱線';

  @override
  String get crisisHotlineCnNumber => '400-161-9995';

  @override
  String get crisisHotlineCnDesc => '中國大陸 24 小時免費';

  @override
  String get crisisHotlineTwLabel => '安心專線 (24 小時）';

  @override
  String get crisisHotlineTwNumber => '1925';

  @override
  String get crisisHotlineTwDesc => '中國臺灣 24 小時心理諮商';

  @override
  String get crisisHotlineHkLabel => '撒瑪利亞防止自殺會 (24 小時）';

  @override
  String get crisisHotlineHkNumber => '2389 2222';

  @override
  String get crisisHotlineHkDesc => '中國香港 24 小時多語言';

  @override
  String get crisisHotlineMoLabel => '明愛生命熱線 (24 小時）';

  @override
  String get crisisHotlineMoNumber => '2826 1122';

  @override
  String get crisisHotlineMoDesc => '中國澳門 24 小時';

  @override
  String get crisisHotlineTitle => '緊急心理援助熱線';

  @override
  String get crisisHotlineSubtitle => '如果你或身邊的人正在經歷心理危機， 請撥打以下熱線';

  @override
  String get crisisHotlineCn2Label => '全國 24 小時免費心理援助熱線';

  @override
  String get crisisHotlineCn2Number => '800-810-1117';

  @override
  String get crisisHotlineCn2Desc => '中國大陸 24 小時免費撥打';

  @override
  String get crisisHotlineUsLabel => '988 Suicide & Crisis Lifeline';

  @override
  String get crisisHotlineUsNumber => '988';

  @override
  String get crisisHotlineUsDesc => '美國 / 加拿大 24 小時英文 / 西班牙文';

  @override
  String get crisisHotlineIntlLabel => '國際通用';

  @override
  String get crisisHotlineIntlDesc => '請聯繫當地急救或心理援助機構';

  @override
  String get crisisHotlineIntlNumber => '112 / 911';

  @override
  String get crisisHotlineRegionCn => '中國大陸';

  @override
  String get crisisHotlineRegionTw => '中國臺灣';

  @override
  String get crisisHotlineRegionHk => '中國香港';

  @override
  String get crisisHotlineRegionUs => '美國 / 加拿大';

  @override
  String get crisisHotlineRegionIntl => '國際通用';

  @override
  String get crisisHotlineCnBeijingLabel => '北京心理危機研究與干預中心';

  @override
  String get crisisHotlineCnBeijingNumber => '010-82951332';

  @override
  String get crisisHotlineCnBeijingDesc => '北京 24 小時';

  @override
  String get crisisHotlineTw1995Label => '生命線 (24 小時）';

  @override
  String get crisisHotlineTw1995Number => '1995';

  @override
  String get crisisHotlineTw1995Desc => '中國臺灣 24 小時';

  @override
  String get crisisHotlineUsTextLineLabel => 'Crisis Text Line (text HOME)';

  @override
  String get crisisHotlineUsTextLineNumber => '741741';

  @override
  String get crisisHotlineUsTextLineDesc => '美國 24 小時短信';

  @override
  String crisisHotlineSnackbarCopied(Object number) {
    return '已複製： $number';
  }

  @override
  String get crisisHotlineDialTooltip => '撥打';

  @override
  String get crisisHotlineCopyTooltip => '複製號碼';

  @override
  String crisisHotlineDialFailed(Object number) {
    return '無法啟動撥號， 請手動撥打： $number';
  }

  @override
  String get setupLegalAgeAttestation =>
      '本人鄭重承諾：我已年滿 18 週歲。如本人為 14-18 週歲，本人保證已取得監護人代為同意，並願意承擔虛假陳述的一切法律後果。';

  @override
  String get moodCbtLevelLabel3 => '3 欄';

  @override
  String get moodCbtLevelLabel5 => '5 欄';

  @override
  String get moodCbtLevelLabel7 => '7 欄';

  @override
  String get moodCbtExpandExplain => '什麼是 CBT 思維記錄？';

  @override
  String get moodCbtSectionSituation => '情境';

  @override
  String get moodCbtSectionAutomaticThought => '自動思維';

  @override
  String get moodCbtSectionEvidenceFor => '支持證據';

  @override
  String get moodCbtSectionEvidenceAgainst => '反對證據';

  @override
  String get moodCbtSectionAlternative => '替代思維';

  @override
  String get moodCbtSectionRerated => '重新評分';

  @override
  String get moodCbtSectionCoreBelief => '核心信念';

  @override
  String get moodCbtSectionBehavior => '行為應對';

  @override
  String get moodCbtExplainerBody =>
      'CBT（認知行為療法）思維記錄幫你識別並重構負面自動思維。\n按 5 欄標準：先記錄情境與想法，再找證據支持／反對，最後寫下更平衡的替代想法。';

  @override
  String get moodCbtFieldHintSituation => '觸發這個想法的事件是什麼？發生在哪裡、什麼時候、有誰？';

  @override
  String get moodCbtFieldHintAutomaticThought => '那一瞬間腦中閃過的想法、印象或意象是什麼？';

  @override
  String get moodCbtFieldHintEvidenceFor => '什麼事支持這個想法？';

  @override
  String get moodCbtFieldHintEvidenceAgainst => '什麼事不支持這個想法？';

  @override
  String get moodCbtFieldHintAlternative => '如果你的好朋友遇到這事，你會怎麼想？';

  @override
  String get moodCbtFieldHintCoreBelief => '這個想法背後更深層的信念是什麼？（如 \"我不夠好\"）';

  @override
  String get moodCbtFieldHintBehavior => '接下來你打算怎麼做？';

  @override
  String get moodCbtPromptTitle => '引導問題';

  @override
  String moodCbtStepOf(int current, int total) {
    return '第 $current 步 / 共 $total 步';
  }

  @override
  String moodCbtReratedComparison(int newScore, int oldScore) {
    return '重新評分：$newScore（原 $oldScore）';
  }

  @override
  String get settingsCbtLevel => '思維記錄檔位';

  @override
  String get settingsCbtLevelDescription => '選擇每次記錄情緒時使用的思維記錄模板';

  @override
  String get settingsCbtLevel3Desc => '入門版，1-2 分鐘可填完';

  @override
  String get settingsCbtLevel5Desc => '標準 Beck 思維記錄，含認知重構關鍵步驟';

  @override
  String get settingsCbtLevel7Desc => '深度版，含核心信念識別和行為應對';

  @override
  String get moodCbtScoreReratedLabel => '重新評分';

  @override
  String get moodCbtChipBadge5 => 'CBT 5 欄';

  @override
  String get moodCbtChipBadge7 => 'CBT 7 欄';

  @override
  String get moodCbtThreeScoreTitle => '你現在的感受？';

  @override
  String get moodCbtThreeSituationTitle => '發生了什麼？';

  @override
  String get moodCbtThreeAutoTitle => '那一刻腦海裡閃過什麼想法？';

  @override
  String get moodCbtPrevStep => '上一步';

  @override
  String get moodCbtNextStep => '下一步';

  @override
  String get moodCbtComplete => '完成';

  @override
  String get moodCbtStep2Header => '情緒 + 證據';

  @override
  String get moodCbtConfirm => '確認';

  @override
  String get moodCbtConfirmEmpty => '（未填）';

  @override
  String get moodCbtAutoThoughtPrompt0 => '如果你的好朋友遇到這事，你會怎麼勸TA？';

  @override
  String get moodCbtAutoThoughtPrompt1 => '最壞／最好／最現實的結果是什麼？';

  @override
  String get moodCbtAutoThoughtPrompt2 => '一年後你還會這麼想嗎？';

  @override
  String get moodCbtAlternativePrompt0 => '一年後你還會這麼想嗎？';

  @override
  String get moodCbtAlternativePrompt1 => '最現實的結果是什麼？';

  @override
  String get moodCbtBehaviorPrompt0 => '深呼吸 5 次';

  @override
  String get moodCbtBehaviorPrompt1 => '與信任的人聊聊';

  @override
  String get moodCbtBehaviorPrompt2 => '做 10 分鐘正念';

  @override
  String get moodListFilterDate => '日期';

  @override
  String get moodListFilterScore => '分數';

  @override
  String get moodListFilterCbt => 'CBT 檔位';

  @override
  String get moodListSortBy => '排序';

  @override
  String get moodListSortTimestamp => '時間倒序';

  @override
  String get moodListSortScoreAsc => '分數升序';

  @override
  String get moodListSortScoreDesc => '分數降序';

  @override
  String get moodListPageTitle => 'Mood 歷史';

  @override
  String get moodListSearchHint => '搜索 note……';

  @override
  String get moodListEmpty => '還沒有 mood 記錄';

  @override
  String get moodListNoMatch => '沒有匹配的記錄';

  @override
  String moodListEntryCount(int count) {
    return '$count 條記錄';
  }

  @override
  String get cbtExportPdfEmpty => '還沒有 5/7 欄 CBT 數據可導出';

  @override
  String get cbtExportPdfButton => '導出 CBT 思維記錄 PDF';

  @override
  String get cbtExportPdfDialogTitle => '選擇日期範圍生成 PDF';

  @override
  String cbtExportPdfSuccess(int count) {
    return '已導出 $count 條 CBT 思維記錄';
  }

  @override
  String get cbtExportPdfFailed => 'PDF 導出失敗，請重試';

  @override
  String get assessmentCenterTitle => '量表中心';

  @override
  String assessmentCenterLastScore(int score) {
    return '上次 $score 分';
  }

  @override
  String assessmentCenterLastTime(Object time) {
    return '$time 填寫';
  }

  @override
  String get assessmentCenterNoData => '尚未填寫過';

  @override
  String get assessmentCenterStartButton => '開始評估';

  @override
  String get assessmentCenterMultiLineTitle => '全部量表趨勢';

  @override
  String get assessmentCenterNotAvailable => '需法務／臨床審核';

  @override
  String get assessmentCenterComingSoon => '敬請期待';

  @override
  String get isiName => 'ISI 失眠嚴重指數';

  @override
  String get isiShortDescription => 'Morin 1993 失眠嚴重指數 7 題';

  @override
  String get isiInstruction => '過去 2 周內， 您的睡眠問題有多嚴重？';

  @override
  String get isiOption0 => '無';

  @override
  String get isiOption1 => '輕度';

  @override
  String get isiOption2 => '中度';

  @override
  String get isiOption3 => '重度';

  @override
  String get isiOption4 => '極重度';

  @override
  String get isiSeverityLabel0 => '無失眠';

  @override
  String get isiSeverityLabel1 => '閾下失眠';

  @override
  String get isiSeverityLabel2 => '中度失眠';

  @override
  String get isiSeverityLabel3 => '重度失眠';

  @override
  String get isiSeveritySummary0 => '無臨床失眠';

  @override
  String get isiSeveritySummary1 => '亞臨床失眠， 建議關注';

  @override
  String get isiSeveritySummary2 => '中度失眠， 建議就醫';

  @override
  String get isiSeveritySummary3 => '重度失眠， 強烈建議就醫';

  @override
  String get pssName => 'PSS 壓力量表';

  @override
  String get pssShortDescription => 'Cohen 1983 壓力量表 (10 題， 含 4 題反向）';

  @override
  String get pssInstruction => '過去 1 個月裡， 您有多經常有下列感受？';

  @override
  String get pssOption0 => '從未';

  @override
  String get pssOption1 => '幾乎不';

  @override
  String get pssOption2 => '有時';

  @override
  String get pssOption3 => '經常';

  @override
  String get pssOption4 => '總是';

  @override
  String get pssSeverityLabel0 => '低壓力';

  @override
  String get pssSeverityLabel1 => '中度壓力';

  @override
  String get pssSeverityLabel2 => '高壓力';

  @override
  String get pssSeveritySummary0 => '低壓力';

  @override
  String get pssSeveritySummary1 => '中度壓力';

  @override
  String get pssSeveritySummary2 => '高壓力， 建議關注和尋求支持';

  @override
  String get whodasName => 'WHODAS 2.0 殘疾評定';

  @override
  String get whodasShortDescription => 'WHO 通用殘疾評估 12 題簡化版';

  @override
  String get whodasInstruction => '過去 30 天內， 您在以下活動中遇到多大困難？';

  @override
  String get whodasOption0 => '沒有';

  @override
  String get whodasOption1 => '輕微';

  @override
  String get whodasOption2 => '中度';

  @override
  String get whodasOption3 => '重度';

  @override
  String get whodasOption4 => '極重度';

  @override
  String get whodasSeverityLabel0 => '無殘疾';

  @override
  String get whodasSeverityLabel1 => '輕度殘疾';

  @override
  String get whodasSeverityLabel2 => '中度殘疾';

  @override
  String get whodasSeverityLabel3 => '重度殘疾';

  @override
  String get whodasSeverityLabel4 => '極重度殘疾';

  @override
  String get whodasSeveritySummary0 => '無殘疾';

  @override
  String get whodasSeveritySummary1 => '輕度殘疾';

  @override
  String get whodasSeveritySummary2 => '中度殘疾， 建議就醫評估';

  @override
  String get whodasSeveritySummary3 => '重度殘疾， 建議就醫';

  @override
  String get whodasSeveritySummary4 => '極重度殘疾， 強烈建議就醫';

  @override
  String get level2DepressionName => 'DSM-5 Level 2 抑鬱嚴重度';

  @override
  String get level2DepressionShortDescription =>
      '成人抑鬱嚴重度 8 題 (DSM-5 PROMIS 簡化版）';

  @override
  String get level2DepressionInstruction => '過去 7 天內， 您有多經常被以下情緒困擾？';

  @override
  String get level2DepressionOption0 => '完全沒有';

  @override
  String get level2DepressionOption1 => '幾天';

  @override
  String get level2DepressionOption2 => '一半以上的天數';

  @override
  String get level2DepressionOption3 => '幾乎每天';

  @override
  String get level2DepressionSeverityLabel0 => '無抑鬱';

  @override
  String get level2DepressionSeverityLabel1 => '輕度抑鬱';

  @override
  String get level2DepressionSeverityLabel2 => '中度抑鬱';

  @override
  String get level2DepressionSeverityLabel3 => '重度抑鬱';

  @override
  String get level2DepressionSeveritySummary0 => '無抑鬱傾向';

  @override
  String get level2DepressionSeveritySummary1 => '輕度抑鬱傾向';

  @override
  String get level2DepressionSeveritySummary2 => '中度抑鬱， 建議就醫';

  @override
  String get level2DepressionSeveritySummary3 => '重度抑鬱， 強烈建議就醫';

  @override
  String get level2AnxietyName => 'DSM-5 Level 2 焦慮嚴重度';

  @override
  String get level2AnxietyShortDescription => '成人焦慮嚴重度 7 題 (DSM-5 PROMIS 簡化版）';

  @override
  String get level2AnxietyInstruction => '過去 7 天內， 您有多經常被以下感受困擾？';

  @override
  String get level2AnxietyOption0 => '完全沒有';

  @override
  String get level2AnxietyOption1 => '幾天';

  @override
  String get level2AnxietyOption2 => '一半以上的天數';

  @override
  String get level2AnxietyOption3 => '幾乎每天';

  @override
  String get level2AnxietySeverityLabel0 => '無焦慮';

  @override
  String get level2AnxietySeverityLabel1 => '輕度焦慮';

  @override
  String get level2AnxietySeverityLabel2 => '中度焦慮';

  @override
  String get level2AnxietySeverityLabel3 => '重度焦慮';

  @override
  String get level2AnxietySeveritySummary0 => '無焦慮傾向';

  @override
  String get level2AnxietySeveritySummary1 => '輕度焦慮傾向';

  @override
  String get level2AnxietySeveritySummary2 => '中度焦慮， 建議就醫';

  @override
  String get level2AnxietySeveritySummary3 => '重度焦慮， 強烈建議就醫';

  @override
  String get level2ManiaName => 'DSM-5 Level 2 躁狂嚴重度';

  @override
  String get level2ManiaShortDescription => '成人躁狂嚴重度 5 題 (DSM-5 PROMIS 簡化版）';

  @override
  String get level2ManiaInstruction => '過去 7 天內， 您有多經常體驗以下情況？';

  @override
  String get level2ManiaOption0 => '完全沒有';

  @override
  String get level2ManiaOption1 => '幾天';

  @override
  String get level2ManiaOption2 => '一半以上的天數';

  @override
  String get level2ManiaOption3 => '幾乎每天';

  @override
  String get level2ManiaSeverityLabel0 => '無躁狂';

  @override
  String get level2ManiaSeverityLabel1 => '輕度躁狂';

  @override
  String get level2ManiaSeverityLabel2 => '中度躁狂';

  @override
  String get level2ManiaSeverityLabel3 => '重度躁狂';

  @override
  String get level2ManiaSeveritySummary0 => '無躁狂傾向';

  @override
  String get level2ManiaSeveritySummary1 => '輕度躁狂傾向';

  @override
  String get level2ManiaSeveritySummary2 => '中度躁狂， 建議就醫';

  @override
  String get level2ManiaSeveritySummary3 => '重度躁狂， 強烈建議就醫';

  @override
  String get asrmName => 'ASRM 自評躁狂量表';

  @override
  String get asrmShortDescription => 'Altman 1997 自評躁狂量表 (5 題）';

  @override
  String get asrmInstruction => '過去 1 周內， 您有 （或感覺到） 以下情況的程度？';

  @override
  String get asrmOption0 => '完全沒有';

  @override
  String get asrmOption1 => '輕微';

  @override
  String get asrmOption2 => '中度';

  @override
  String get asrmOption3 => '明顯';

  @override
  String get asrmOption4 => '嚴重';

  @override
  String get asrmSeverityLabel0 => '無症狀';

  @override
  String get asrmSeverityLabel1 => '輕度';

  @override
  String get asrmSeverityLabel2 => '中度';

  @override
  String get asrmSeverityLabel3 => '重度';

  @override
  String get asrmSeverityLabel4 => '極重度';

  @override
  String get asrmSeveritySummary0 => '無症狀';

  @override
  String get asrmSeveritySummary1 => '輕度躁狂傾向';

  @override
  String get asrmSeveritySummary2 => '中度躁狂， 建議就醫';

  @override
  String get asrmSeveritySummary3 => '重度躁狂， 建議就醫';

  @override
  String get asrmSeveritySummary4 => '極重度躁狂， 強烈建議就醫';

  @override
  String get level2PsychosisName => 'DSM-5 Level 2 精神病性症狀';

  @override
  String get level2PsychosisShortDescription => '成人精神病性症狀 8 題 (DSM-5 簡化版）';

  @override
  String get level2PsychosisInstruction => '過去 7 天內， 您有多經常體驗以下情況？';

  @override
  String get level2PsychosisOption0 => '從來沒有';

  @override
  String get level2PsychosisOption1 => '很少';

  @override
  String get level2PsychosisOption2 => '有時';

  @override
  String get level2PsychosisOption3 => '經常';

  @override
  String get level2PsychosisSeverityLabel0 => '無症狀';

  @override
  String get level2PsychosisSeverityLabel1 => '輕度';

  @override
  String get level2PsychosisSeverityLabel2 => '中度';

  @override
  String get level2PsychosisSeverityLabel3 => '重度';

  @override
  String get level2PsychosisSeveritySummary0 => '無精神病性症狀';

  @override
  String get level2PsychosisSeveritySummary1 => '輕度精神病性症狀';

  @override
  String get level2PsychosisSeveritySummary2 => '中度精神病性症狀， 建議就醫';

  @override
  String get level2PsychosisSeveritySummary3 => '重度精神病性症狀， 強烈建議就醫';

  @override
  String get dailyTrackingTitle => '日常追蹤';

  @override
  String get dailyTrackingFab => '日常追蹤';

  @override
  String get dailyTrackingMultiChartTitle => '近 30 天 4 指標';

  @override
  String get chartMetricWeight => '體重';

  @override
  String get chartMetricSleep => '睡眠';

  @override
  String get chartMetricMood => '心境';

  @override
  String get chartMetricStress => '應激源';

  @override
  String dailyTrackingLastTime(Object time) {
    return '$time 記錄';
  }

  @override
  String get dailyTrackingRecord => '記錄';

  @override
  String get moodDiaryName => '情緒日記';

  @override
  String get moodDiaryShortDesc => '心境 4 段 + score, 趨勢分析';

  @override
  String moodDiaryScore(int score) {
    return '心境 $score/5';
  }

  @override
  String moodDiaryLast(Object time, Object score, Object period) {
    return '$time · $score ($period)';
  }

  @override
  String get anxietyAgitationName => '焦慮急躁';

  @override
  String get anxietyAgitationShortDesc => '焦慮 + 急躁 雙維度 5 檔';

  @override
  String get anxietyAgitationHint => '焦慮反向 1=嚴重 5=平靜； 急躁正向 1=平靜 5=極急';

  @override
  String get anxietyAgitationAddButton => '添加評估';

  @override
  String get anxietyAgitationNoData => '暫無焦慮急躁記錄';

  @override
  String anxietyAgitationAnxietyScore(int score) {
    return '焦慮 $score';
  }

  @override
  String anxietyAgitationAgitationScore(int score) {
    return '急躁 $score';
  }

  @override
  String anxietyAgitationLast(int anxiety, int agitation) {
    return '焦慮 $anxiety / 急躁 $agitation';
  }

  @override
  String get sleepName => '睡眠';

  @override
  String get sleepShortDesc => '入睡 + 時長 + 規律性';

  @override
  String get sleepHint => '記錄每晚入睡 + 起床， 跨午夜自動算時長';

  @override
  String get sleepAddButton => '添加睡眠記錄';

  @override
  String get sleepNoData => '暫無睡眠記錄';

  @override
  String sleepBedtime(Object time) {
    return '入睡 $time';
  }

  @override
  String sleepWakeTime(Object time) {
    return '起床 $time';
  }

  @override
  String sleepLast(Object duration, int regularity) {
    return '$duration · 規律 $regularity/5';
  }

  @override
  String get socialRhythmName => '社會節律';

  @override
  String get socialRhythmShortDesc => '起床 + 第一餐 + 最後一餐 + 時長';

  @override
  String get socialRhythmHint => '記錄每天的作息， 幫醫生判斷節律穩定性';

  @override
  String get socialRhythmAddButton => '添加社會節律';

  @override
  String get socialRhythmNoData => '暫無社會節律記錄';

  @override
  String socialRhythmWakeTime(Object time) {
    return '起床 $time';
  }

  @override
  String socialRhythmFirstMeal(Object time) {
    return '第一餐 $time';
  }

  @override
  String socialRhythmLastMeal(Object time) {
    return '最後一餐 $time';
  }

  @override
  String socialRhythmLast(Object wake, int social, int work) {
    return '起床 $wake · 社交 ${social}h · 工作 ${work}h';
  }

  @override
  String get stressEventName => '應激源';

  @override
  String get stressEventShortDesc => '事件類型 + 強度評分';

  @override
  String get stressEventHint => '記錄生活中的壓力事件， 幫醫生判斷觸發因素';

  @override
  String get stressEventAddButton => '添加應激源';

  @override
  String get stressEventNoData => '暫無應激源記錄';

  @override
  String get stressEventEventType => '事件類型';

  @override
  String get stressEventIntensity => '強度';

  @override
  String stressEventLast(int intensity) {
    return '強度 $intensity/5';
  }

  @override
  String get treatmentName => '治療';

  @override
  String get treatmentShortDesc => '用藥 / 諮詢 / 物理治療， 關聯 medication';

  @override
  String get treatmentHint => '治療條目可關聯 medication, 寫入功能 v0.31+';

  @override
  String get treatmentNoData => '暫無治療記錄';

  @override
  String get treatmentAddButton => '添加';

  @override
  String get treatmentAddTitle => '添加治療記錄';

  @override
  String get treatmentDate => '日期';

  @override
  String get treatmentCategory => '類別';

  @override
  String get treatmentCategoryMedicationAdjustment => '藥物調整';

  @override
  String get treatmentCategoryConsultation => '心理諮詢';

  @override
  String get treatmentCategoryHospitalization => '住院';

  @override
  String get treatmentCategoryOther => '其他';

  @override
  String get treatmentProvider => '醫療機構 / 醫生';

  @override
  String get treatmentProviderHint => '例如： 心理醫生王醫生 / 北京協和醫院';

  @override
  String get treatmentProviderRequired => '請填寫醫療機構 / 醫生';

  @override
  String get treatmentNote => '備註';

  @override
  String get treatmentNoteHint => '可選， 簡短記錄治療要點';

  @override
  String get treatmentType => '治療類型';

  @override
  String treatmentLast(Object type, Object description) {
    return '$type · $description';
  }

  @override
  String get weightName => '體重';

  @override
  String get weightShortDesc => '體重 + BMI （需 profile.height)';

  @override
  String get weightHint => '記錄每天的體重， 幫醫生判斷生理狀態';

  @override
  String get weightAddButton => '添加體重記錄';

  @override
  String get weightNoData => '暫無體重記錄';

  @override
  String weightWeight(Object kg) {
    return '體重 $kg kg';
  }

  @override
  String weightBmi(Object bmi) {
    return 'BMI $bmi';
  }

  @override
  String weightLast(Object kg, Object bmi) {
    return '$kg kg · BMI $bmi';
  }

  @override
  String get periodMorning => '早';

  @override
  String get periodNoon => '中';

  @override
  String get periodEvening => '晚';

  @override
  String get periodNight => '夜';

  @override
  String get periodUnspecified => '未指定';

  @override
  String get stressEventTypeWork => '工作';

  @override
  String get stressEventTypeRelationship => '關係';

  @override
  String get stressEventTypeHealth => '健康';

  @override
  String get stressEventTypeFinancial => '財務';

  @override
  String get stressEventTypeOther => '其他';

  @override
  String get regularityVeryIrregular => '很不規律';

  @override
  String get regularityIrregular => '不規律';

  @override
  String get regularityNormal => '一般';

  @override
  String get regularityRegular => '規律';

  @override
  String get regularityVeryRegular => '很規律';

  @override
  String get cardStatusNoData => '尚未記錄';

  @override
  String get sleepBedtimeTitle => '入睡時間';

  @override
  String get sleepWakeTimeTitle => '起床時間';

  @override
  String get socialRhythmWakeTimeTitle => '起床時間';

  @override
  String get socialRhythmFirstMealTitle => '第一餐時間';

  @override
  String get socialRhythmLastMealTitle => '最後一餐時間';

  @override
  String get cardStatusToday => '今天';

  @override
  String get sleepRegularityTitle => '規律性';

  @override
  String get anxietyAgitationAnxietyLabel => '焦慮分數';

  @override
  String get anxietyAgitationAgitationLabel => '急躁分數';

  @override
  String get moodListPeriodAll => '全部';

  @override
  String get migrationFailedInitData => '無法初始化本地數據';

  @override
  String get migrationFailedActionHint => '請嘗試重啟 App，或卸載後重新安裝';

  @override
  String migrationFailedFooter(String error) {
    return '技術信息： $error';
  }

  @override
  String get migrationFailedRetryButton => '重試';

  @override
  String get migrationFailedCloseButton => '關閉';

  @override
  String get migrationStartingHint => '啟動中，請稍候……';

  @override
  String get migrationNavContextNull => '啟動上下文尚未就緒，請稍後再試';

  @override
  String get migrationFailedErrorPrefix => '錯誤';

  @override
  String get dailyTrackingNoteLabel => '備註';

  @override
  String get dailyTrackingNoteHint => '可選';

  @override
  String get timeAgoJustNow => '剛剛';

  @override
  String timeAgoDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String timeAgoHoursAgo(int hours) {
    return '$hours 小時前';
  }

  @override
  String get weightNoBmi => '暫無 BMI';

  @override
  String get weightKgLabel => '體重 (kg)';

  @override
  String get weightKgHint => '如 60.5';

  @override
  String get weightBmiNeedHeight => '暫無 （需填寫身高）';

  @override
  String socialRhythmMinutesSummary(
      Object social, Object work, Object exercise) {
    return '社交 ${social}min · 工作 ${work}min · 運動 ${exercise}min';
  }

  @override
  String get socialRhythmSocialMinLabel => '社交時長 （分鐘）';

  @override
  String get socialRhythmWorkMinLabel => '工作時長 （分鐘）';

  @override
  String get socialRhythmExerciseMinLabel => '運動時長 （分鐘）';

  @override
  String get anxietyAgitationAnxietyScaleHint => '1=嚴重 5=平靜';

  @override
  String get anxietyAgitationAgitationScaleHint => '1=平靜 5=極急';

  @override
  String sleepRegularityScore(int score) {
    return '規律 $score/5';
  }

  @override
  String sleepDurationLabel(Object duration) {
    return '時長： $duration';
  }

  @override
  String stressIntensityScore(int intensity) {
    return '強度 $intensity/5';
  }

  @override
  String moodCbtColumns(int count) {
    return '$count 欄';
  }

  @override
  String medReportTitleWindow(int days) {
    return '用藥報告（近 $days 天）';
  }

  @override
  String get setupCrisisHotlineTitle => '🆘 心理危機干預熱線 (24h)';

  @override
  String get consentWithdrawVentBody => '樹洞 （私密傾訴） 功能將停用。新增樹洞記錄會被拒絕， 已有記錄保留。';

  @override
  String get consentWithdrawAnalyticsBody =>
      '評估 / 情緒相關分析圖表將不再展示。已有數據保留， 重新開啟後恢復。';

  @override
  String get dataExportPurposeBackup => '本地備份 / 跨設備遷移';

  @override
  String get dataExportDataCategories => '用藥記錄、打卡記錄、緊急聯繫人、情緒日記、樹洞文字 （錄音不導出）';

  @override
  String get dataExportRetentionClipboard => '剪貼板 + 用戶自行保存到加密存儲';

  @override
  String get medPageTitle => '用藥';

  @override
  String get medAddTooltip => '添加藥物';

  @override
  String get medTodaySchedule => '今日服藥';

  @override
  String get medMyMedications => '我的藥物';

  @override
  String get medQuickActions => '快捷操作';

  @override
  String get medSlotMorning => '早上';

  @override
  String get medSlotAfternoon => '下午';

  @override
  String get medSlotEvening => '晚上';

  @override
  String get medSlotBedtime => '睡前';

  @override
  String get medEmptyTitle => '還沒有添加藥物';

  @override
  String get medEmptySubtitle => '點擊右上角 + 添加你的第一種藥物';

  @override
  String get medNoScheduleToday => '今天沒有服藥計劃';

  @override
  String get medAddTitle => '添加藥物';

  @override
  String get medAddStep1Title => '藥物信息';

  @override
  String get medAddConfirm => '確認信息';

  @override
  String get medAddColor => '顏色';

  @override
  String get medAddTime => '用藥時間';

  @override
  String get medAddBasicInfo => '基本信息';

  @override
  String get medAddStep2Title => '劑量與時間';

  @override
  String get medAddStep3Title => '確認';

  @override
  String get medAddNameLabel => '藥物名稱';

  @override
  String get medAddNameHint => '例如：舍曲林';

  @override
  String get medAddFormLabel => '劑型';

  @override
  String get medAddDosageLabel => '每次劑量';

  @override
  String get medAddTimeLabel => '服藥時間';

  @override
  String get medAddTimeAdd => '添加時間';

  @override
  String get medAddColorLabel => '藥物顏色（可選，幫助識別）';

  @override
  String get medAddConfirmName => '藥名';

  @override
  String get medAddConfirmForm => '劑型';

  @override
  String get medAddConfirmDosage => '劑量';

  @override
  String get medAddConfirmTime => '時間';

  @override
  String get medAddPrev => '上一步';

  @override
  String get medAddNext => '下一步';

  @override
  String get medAddSave => '保存';

  @override
  String medAddColorN(Object n) {
    return '藥物顏色 $n';
  }

  @override
  String get medFormTablet => '片劑';

  @override
  String get medFormCapsule => '膠囊';

  @override
  String get medFormLiquid => '口服液';

  @override
  String get medFormPatch => '貼劑';

  @override
  String get medFormInjection => '注射';

  @override
  String get medFormOther => '其他';

  @override
  String get medDetailTitle => '藥物詳情';

  @override
  String get medNotFound => '藥物未找到';

  @override
  String get moodInfluenceTitle => '影響因素';

  @override
  String get moodInfluenceSubtitle => '什麼影響了你的心情？（可多選）';

  @override
  String get moodInfluenceRelationships => '關係';

  @override
  String get moodInfluenceHealth => '健康';

  @override
  String get moodInfluenceActivities => '活動';

  @override
  String get moodInfluenceMindfulness => '正念';

  @override
  String get moodInfluenceWeather => '天氣';

  @override
  String get moodInfluenceOther => '其他';

  @override
  String get influenceFactorFamily => '家人';

  @override
  String get influenceFactorFriend => '朋友';

  @override
  String get influenceFactorPartner => '伴侶';

  @override
  String get influenceFactorChild => '孩子';

  @override
  String get influenceFactorColleague => '同事';

  @override
  String get influenceFactorExercise => '運動';

  @override
  String get influenceFactorSick => '生病';

  @override
  String get influenceFactorGoodSleep => '睡眠好';

  @override
  String get influenceFactorHealthyDiet => '飲食健康';

  @override
  String get influenceFactorWork => '工作';

  @override
  String get influenceFactorHobby => '愛好';

  @override
  String get influenceFactorTravel => '旅行';

  @override
  String get influenceFactorCommute => '通勤';

  @override
  String get influenceFactorShopping => '購物';

  @override
  String get influenceFactorGaming => '遊戲';

  @override
  String get influenceFactorReading => '閱讀';

  @override
  String get influenceFactorEntertainment => '娛樂';

  @override
  String get influenceFactorMeditation => '冥想';

  @override
  String get influenceFactorBreathing => '呼吸練習';

  @override
  String get influenceFactorJournaling => '寫日記';

  @override
  String get influenceFactorYoga => '瑜伽';

  @override
  String get influenceFactorSunny => '晴天';

  @override
  String get influenceFactorCloudy => '多雲';

  @override
  String get influenceFactorRainy => '雨天';

  @override
  String get influenceFactorSnowy => '雪天';

  @override
  String get influenceFactorWindy => '颳風';

  @override
  String get moodDetailTitle => '情緒詳情';

  @override
  String get moodDetailFactors => '影響因素';

  @override
  String get moodDetailMoodState => '情緒狀態';

  @override
  String get moodDetailCbtRecord => 'CBT 思維記錄';

  @override
  String get moodEntryNotFound => '找不到這條情緒記錄';

  @override
  String get moodTrendTitle => '情緒趨勢';

  @override
  String get moodTrendWeek => '近 7 天';

  @override
  String get moodTrendDistribution => '分數分佈';

  @override
  String get moodTrendNoData => '暫無數據';

  @override
  String get moodDeleteTooltip => '刪除';

  @override
  String get moodDeleteConfirm => '確定刪除這條記錄嗎？';

  @override
  String get moodFactorAnalysis => '因素關聯分析';

  @override
  String get moodModeMomentary => '此刻';

  @override
  String get moodModeDaily => '今天';

  @override
  String get moodTrendDistTitle => '分數分佈';

  @override
  String get moodTrendCbtTitle => 'CBT 重評效果';

  @override
  String get moodTrendCbtHint => '正值 = 情緒改善， 負值 = 惡化';

  @override
  String get moodTrendCbtEmpty => '暫無 CBT 重評數據';

  @override
  String get medDetailActive => '在用';

  @override
  String get medDetailStopped => '已停';

  @override
  String get medDetailAdherence => '依從性';

  @override
  String get medDetailLast30 => '近30天';

  @override
  String get medDetailDays => '服藥天數';

  @override
  String get medDetailLast30Record => '近30天記錄';

  @override
  String get medDetailEdit => '編輯';

  @override
  String get medDetailSettings => '設置';

  @override
  String get medDetailHistory => '用藥歷史';

  @override
  String get medDetailBasicInfo => '基本信息';

  @override
  String get medDetailRefill => '續方';

  @override
  String get moodCbtSituation => '情境';

  @override
  String get moodCbtAutoThought => '自動思維';

  @override
  String get moodCbtEvidenceFor => '支持證據';

  @override
  String get moodCbtEvidenceAgainst => '反對證據';

  @override
  String get moodCbtAltThought => '替代思維';

  @override
  String get moodCbtRerated => '重新評分';

  @override
  String get moodCbtCoreBelief => '核心信念';

  @override
  String get moodCbtBehavior => '行為應對';

  @override
  String get moodDeleted => '已刪除';

  @override
  String get moodPeriodAfternoon => '下午';

  @override
  String get settingsProfileTitle => '個人資料';

  @override
  String get settingsProfileSubtitle => '健康檔案、醫療信息';

  @override
  String get todaySummaryCheckIn => '打卡';

  @override
  String get todaySummaryMeds => '藥物';

  @override
  String get todaySummaryMood => '心情';

  @override
  String get todaySummaryStreak => '連續';

  @override
  String get setupConsentMedicalDisclaimer =>
      '我已閱讀並理解《醫學免責聲明》：本 App 不提供醫療建議、診斷或治療，不能替代專業醫療服務';

  @override
  String get trackingCustomize => '自定義追蹤項';

  @override
  String get trackingUnknownItem => '未知項目';

  @override
  String get trackingPin => '置頂';

  @override
  String get trackingUnpin => '取消置頂';

  @override
  String get trackingHide => '隱藏此項';

  @override
  String get trackingPinned => '收藏';

  @override
  String get trackingCategoryEmotional => '情緒狀態';

  @override
  String get trackingCategoryPhysical => '身體指標';

  @override
  String get trackingCategoryBehavioral => '行為節律';

  @override
  String get trackingCategoryMedical => '醫療記錄';

  @override
  String todayTrackingSummary(int tracked, int total) {
    return '今日已追蹤 $tracked/$total 項';
  }

  @override
  String moodRecordingLabel(String duration) {
    return '錄音 $duration';
  }

  @override
  String get medicationNameRequired => '請輸入藥物名稱';

  @override
  String medicationAdded(String name) {
    return '已添加 $name';
  }

  @override
  String get medicationStatusInUse => '在用';

  @override
  String get medicationStatusStopped => '已停';

  @override
  String factorAnalysisCount(int count) {
    return '$count 條';
  }

  @override
  String get setupConsentAgreeAll => '我已閱讀並同意以上所有協議';

  @override
  String get assessmentComparisonImproved => '好轉';

  @override
  String get assessmentComparisonWorsened => '惡化';

  @override
  String get assessmentComparisonUnchanged => '持平';

  @override
  String get assessmentComparisonFirst => '首次評估';

  @override
  String assessmentDeltaSame(int delta) {
    return '和上次一樣（$delta）';
  }

  @override
  String assessmentDeltaHigher(int delta) {
    return '比上次高 $delta 分';
  }

  @override
  String assessmentDeltaLower(int delta) {
    return '比上次低 $delta 分';
  }

  @override
  String assessmentSeverityRank(int rank) {
    return '等級 $rank';
  }

  @override
  String get checkInTypeAssessment => '心理量表評估';

  @override
  String dayDetailTotalScore(int total) {
    return '總分 $total';
  }

  @override
  String get dayDetailScaleAssessment => '心理量表評估';

  @override
  String get medTodayPending => '待服';

  @override
  String get medTodayTaken => '已服';

  @override
  String get medTodayRefill => '需續方';

  @override
  String get homeQuickActionView => '查看';

  @override
  String get homeQuickActionRecord => '記錄';

  @override
  String get homeQuickActionStart => '開始';

  @override
  String get homeTodayMetrics => '今日指標';
}
