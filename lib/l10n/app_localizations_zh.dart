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
  String homeLastMed(String time) {
    return '最后吃药：$time';
  }

  @override
  String homeNextReminder(String time) {
    return '下次提醒：$time';
  }

  @override
  String get homeStillOnline => '🌱 您还在线';

  @override
  String get homeTempMed => '临时吃药 +';

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
  String get setupContacts => '紧急联系人手机号（至少 1 个）';

  @override
  String get setupAddContact => '+ 添加另一个联系人';

  @override
  String get setupContactConsent => '我已告知上述联系人，App 会在我失联时给他们发通知';

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
  String get setupReminder3 => '✓ 漏 2 天我会联系紧急人';

  @override
  String get setupPrivacy => '您的数据：';

  @override
  String get setupPrivacy1 => '• 本地加密';

  @override
  String get setupPrivacy2 => '• 不会上传到任何云端服务器';

  @override
  String get setupPrivacy3 => '• 您可以随时导出';

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
  String get settingsAboutVersion => 'v0.23.0 · 我今天吃了药';

  @override
  String get settingsDisclaimerText => '本应用不提供医疗建议，所有功能仅供参考。';

  @override
  String get settingsExportDialogTitle => '导出数据';

  @override
  String get settingsExportInstruction => '把下面这串 JSON 保存到安全的地方：';

  @override
  String get settingsExportVentWarning =>
      '说明：树洞（私密倾诉）的文字会导出，但录音文件不导出——录音存在 App 本地，重装后路径失效，无法跨设备复用。';

  @override
  String get settingsExportVentConfirmTitle => '导出含敏感内容';

  @override
  String get settingsExportVentConfirmBody =>
      '即将导出树洞的文字内容。精神心理患者的倾诉可能涉及个人隐私或敏感话题，导出的 JSON 是明文，存放在剪贴板或文件里都可能被他人看到。\n\n请确认:\n• 您将把它存到安全的地方（如加密磁盘）\n• 不会分享给未授权的人\n• 树洞录音文件不包含在导出中';

  @override
  String get settingsExportVentConfirmConfirm => '我了解，继续导出';

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
  String commonLoadFailed(String error) {
    return '加载失败：$error';
  }

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
  String get snackbarPhoneInvalid => '号码格式不对（支持大陆／港澳台／国际）';

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

  @override
  String get ventListTitle => '我的树洞';

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
  String get ventRecordActive => '正在录音……点停止';

  @override
  String get ventAudioLabel => '录音';

  @override
  String get ventAudioPlayTooltip => '播放录音';

  @override
  String get ventAudioPauseTooltip => '暂停录音';

  @override
  String get ventRerecord => '重录';

  @override
  String get moodDialogTitle => '今天怎么样？';

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
  String moodAudioRecorded(String duration) {
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
      String date, String suffix, int reminderDays) {
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
  String assessmentQuestionLabel(int index, String text, String selected) {
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
  String homeHeaderKeepGoing(String name) {
    return '$name 还在坚持';
  }

  @override
  String get homeTooltipTrend => '查看趋势';

  @override
  String get homeTooltipAssessmentHistory => '评估历史';

  @override
  String get homeStreakRestart => '今天重新开始，加油 🌱';

  @override
  String get homeStreakDay1 => '第 1 天，迈出第一步 🌱';

  @override
  String homeStreakDays(int days) {
    return '坚持 $days 天，继续 🌿';
  }

  @override
  String homeStreakGreat(int days) {
    return '已坚持 $days 天，真棒 🌳';
  }

  @override
  String homeStreakAmazing(int days) {
    return '$days 天连击，太厉害了 🌲';
  }

  @override
  String homeStreakMaster(int days) {
    return '$days 天--您已经是这个习惯的主人了 🏔️';
  }

  @override
  String get navCheckIn => '打卡';

  @override
  String get navSettings => '设置';

  @override
  String get navAppName => '慢病管家';

  @override
  String errorPageNotFound(String path) {
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
  String get assessmentReminderHintStable => '稳定期 ／ 月度复盘';

  @override
  String get assessmentReminderHintMaintenance => '维持治疗期';

  @override
  String get assessmentReminderHintLongTerm => '长期随访';

  @override
  String get assessmentHistoryTrend => '历史趋势';

  @override
  String assessmentAverageScore(String score) {
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
  String get assessmentSeverityNormal => '正常';

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
  String get setupValidationContactRequired => '至少填 1 个紧急联系人手机号';

  @override
  String get setupValidationPhoneInvalid => '手机号格式不对';

  @override
  String get setupValidationPhoneDuplicate => '紧急联系人手机号不能重复';

  @override
  String get setupPresetTitle => '📋 选择预置方案';

  @override
  String get setupPresetDescription => '预置方案会填好药名 + 时间，您可以接着改。最终服药请按医嘱核对。';

  @override
  String setupPresetLoaded(String name, int count) {
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
  String get setupWelcomeContactHint => '（至少填 1 个手机号，用于失联时通知）';

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
  String get legalPageWithdrawSafety => '撤回失联通知同意';

  @override
  String get legalPageWithdrawSafetySubtitle => '不再因漏打卡触发短信／邮件通知给紧急联系人';

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
  String get emailPreviewTitle => '通知预览';

  @override
  String get emailPreviewSetupRequired => '请先完成首次设置';

  @override
  String get emailPreviewDescription => '这是您将收到的失联通知预览：';

  @override
  String get emailPreviewNoContact => '（无联系人）';

  @override
  String get emailPreviewDisclaimer =>
      '💡 这只是预览。实际短信通知在您漏 2 天没打卡后自动发送（v0.6 mock 阶段只打日志，v1.0+ 接真实 SMS provider）。';

  @override
  String get reportHistoryEmpty => '还没有报告历史\n生成一次报告后会自动记录';

  @override
  String reportHistoryItemTitle(String date, int days) {
    return '$date · 近 $days 天';
  }

  @override
  String reportHistoryItemPatient(String name) {
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
    return '已记录！$days 天--您太厉害了 🏔️';
  }

  @override
  String homeAutofireCelebration(String name) {
    return '已打卡：$name ✅';
  }

  @override
  String get homeAutofireFallbackName => '该药';

  @override
  String homeMedHint(int id) {
    return '💊 准备打卡药物 #$id';
  }

  @override
  String get homeSafetyAlertSuffix => '（请尽快打卡或联系家人）';

  @override
  String safetyAlertBodySent(String date) {
    return '上次打卡: $date。已自动通知紧急联系人，请确认安全。';
  }

  @override
  String safetyAlertBodyMocked(String date) {
    return '上次打卡: $date。失联检测已触发，但当前为开发模式，**未实际通知**紧急联系人。';
  }

  @override
  String safetyAlertBodyFailed(String date) {
    return '上次打卡: $date。失联检测已触发，但通知发送失败。请检查网络。';
  }

  @override
  String get homeSnoozeTitle => '⏰ 该打卡了（5min 后）';

  @override
  String get homeSnoozeBody => '刚才您点了「snooze」，是时候点一下 = 打卡了';

  @override
  String get homeSnoozeConfirmed => '好，5 分钟后会再提醒您 👌';

  @override
  String get homeSnoozeButton => '⏰ 5 分钟后再提醒';

  @override
  String get homeVentButton => '倾诉 🌲';

  @override
  String get homeNotifBannerText => '提醒没设上，可能错过打卡。请到系统设置允许通知。';

  @override
  String get homeNotifBannerDismiss => '知道了';

  @override
  String themeTooltip(String mode) {
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
  String trendMoodEntriesSame(int count, String emoji) {
    return '$count 条情绪记录 · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, String lowEmoji, String highEmoji) {
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
  String get contactEmptyList => '还没有联系人，请先添加';

  @override
  String get contactAddAction => '添加联系人';

  @override
  String get contactAddTitle => '添加紧急联系人';

  @override
  String get contactConsentTitle => '知情同意';

  @override
  String contactConsentBody(int threshold) {
    return '您即将把这位联系人的手机号保存在本地数据库中。当您连续 $threshold 天未在 App 内打卡时，App 会通过 SMS 短信自动通知该联系人。\n\n**根据《个人信息保护法》第 13 条**，请确认您已告知该联系人上述用途，并取得其同意。';
  }

  @override
  String get contactConsentAgree => '已告知并取得同意';

  @override
  String get contactConsentReject => '暂不同意';

  @override
  String get contactConsentVersion => 'v1 · 2026-07-31';

  @override
  String get contactDefaultName => '联系人';

  @override
  String get contactNameLabel => '姓名';

  @override
  String get contactPhoneLabel => '手机号';

  @override
  String get commonActionDelete => '删除';

  @override
  String get commonActionSave => '保存';

  @override
  String get editMedDialogTitle => '编辑药物';

  @override
  String get editMedValidationNameRequired => '请填写药名';

  @override
  String get editMedValidationDosageInvalid => '剂量必须是大于 0 的数字';

  @override
  String get editMedValidationUnitInvalid => '单位必须是 mg 或 片';

  @override
  String editMedSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get editMedStatusActive => '正在使用';

  @override
  String get editMedStatusStopped => '已停药';

  @override
  String editMedStoppedDate(String date) {
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
  String get tempMedDialogTitle => '添加临时吃药';

  @override
  String get tempMedLinkLabel => '关联到常吃药（可选）';

  @override
  String get tempMedLinkHint => '不选 = 临时事件';

  @override
  String get tempMedNoLink => '不关联';

  @override
  String get tempMedNameHint => '如：布洛芬';

  @override
  String get tempMedReasonLabel => '原因';

  @override
  String get tempMedReasonHint => '如：感冒';

  @override
  String get medsCalendarHeatmapDesc => '以药为单位的依从性热力图。颜色越深 = 当天打卡次数越接近期望次数。';

  @override
  String get medsCalendarWindow7 => '7 天';

  @override
  String get medsCalendarWindow30 => '30 天';

  @override
  String get medsCalendarWindow90 => '90 天';

  @override
  String medsCalendarLoadCheckinFailed(String error) {
    return '加载打卡失败：$error';
  }

  @override
  String medsCalendarLoadMedFailed(String error) {
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
  String get medsCalendarLegendMissed => '漏服';

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
  String get snackbarActionRecord => '录音';

  @override
  String get snackbarActionStartRecording => '开始录音';

  @override
  String get snackbarActionCheckin => '打卡';

  @override
  String get snackbarActionSnooze => '推迟提醒';

  @override
  String get snackbarActionAutoCheckin => '自动打卡';

  @override
  String get snackbarActionFinishSetup => '完成设置';

  @override
  String get snackbarActionUndo => '撤销';

  @override
  String get ventEntryDeleted => '已删除树洞条目';

  @override
  String get contactDeleted => '已删除联系人';

  @override
  String get medicationDeleted => '已删除药物';

  @override
  String get moodTodayLabel => '今日情绪：';

  @override
  String get moodRecordButton => '记一下情绪 ✏️';

  @override
  String medReportFileName(String date) {
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
  String setupContactFallbackName(int index) {
    return '联系人 $index';
  }

  @override
  String emailBodyI18n(String name, int days) {
    return '我是 $name，已经 $days 天没在 App 里打卡了。\n请你方便的时候提醒我按时吃药，避免复发。';
  }

  @override
  String get emailFooterI18n =>
      '这是一条自动通知，由慢病管家 App 发送。\n本通知不包含任何医疗建议。\n如需停止接收，请在 App 设置中修改。';

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => '片';

  @override
  String get safetyCheckResultDisabled => '安全开关已关闭';

  @override
  String safetyCheckResultOk(int days) {
    return '正常（$days 天前打卡）';
  }

  @override
  String get safetyCheckResultNoData => '新用户，暂无打卡';

  @override
  String safetyCheckResultAlertedToday(int days) {
    return '今天已经发过告警（$days 天前打卡）';
  }

  @override
  String get safetyCheckResultDndSuppressed => 'DND 时段，跳过告警';

  @override
  String get safetyCheckResultNoContacts => '无紧急联系人，未发送';

  @override
  String safetyCheckResultAlertedMocked(int mocked) {
    return '**开发模式**，未实际通知联系人（mock: $mocked）';
  }

  @override
  String safetyCheckResultAlerted(int days, int notified, int failed) {
    return '已告警：$days 天前打卡，已通知 $notified 位联系人（$failed 失败）';
  }

  @override
  String safetyCheckResultError(String message) {
    return '错误：$message';
  }

  @override
  String get settingsIapUpgradeTitle => '升级到 Pro';

  @override
  String get settingsIapUpgradeSubtitle => '¥8 一次性买断 · 解锁全部高级功能';

  @override
  String get settingsIapProOwnedTitle => '已是 Pro 版本';

  @override
  String get settingsIapProOwnedSubtitle => '感谢支持 · 全部高级功能已解锁';

  @override
  String get iapPurchaseSuccess => '升级成功！欢迎使用 Pro。';

  @override
  String get iapPurchaseFailed => '购买未完成，请稍后再试。';

  @override
  String get phoneRegionCn => '中国大陆';

  @override
  String get phoneRegionHk => '中国香港';

  @override
  String get phoneRegionMo => '中国澳门';

  @override
  String get phoneRegionTw => '中国台湾';

  @override
  String get phoneRegionIntl => '国际';

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
  String get checkInTypeDaily => '每日打卡';

  @override
  String get checkInTypeTemp => '临时吃药';

  @override
  String get checkInTypePhq9 => 'PHQ-9 评估';

  @override
  String get checkInTypeGad7 => 'GAD-7 评估';

  @override
  String dayDetailCheckInWith(String name) {
    return '打卡 · $name';
  }

  @override
  String get dayDetailDailyCheckIn => '每日打卡';

  @override
  String dayDetailTempWith(String name) {
    return '临时 · $name';
  }

  @override
  String get dayDetailTempMed => '临时吃药';

  @override
  String get dayDetailPhq9 => 'PHQ-9 抑郁筛查';

  @override
  String get dayDetailGad7 => 'GAD-7 焦虑筛查';

  @override
  String ventDurationSeconds(int sec) {
    return '$sec秒';
  }

  @override
  String ventDurationMinutes(int m) {
    return '$m分';
  }

  @override
  String ventDurationMinutesSeconds(int m, String sec) {
    return '$m分$sec秒';
  }

  @override
  String get scaleHotlineCn => '全国 24 小时心理援助热线';

  @override
  String get scaleHotlineUs => '988 Suicide & Crisis Lifeline (US)';

  @override
  String get scaleHotlineHk => '撒玛利亚防止自杀会（24h 多语言）';

  @override
  String get scaleHotlineIntl => '国际通用 · 请联系当地急救或心理援助';
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
  String homeLastMed(String time) {
    return '最後吃藥：$time';
  }

  @override
  String homeNextReminder(String time) {
    return '下次提醒：$time';
  }

  @override
  String get homeStillOnline => '🌱 您還在線';

  @override
  String get homeTempMed => '臨時吃藥 +';

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
  String get setupContacts => '緊急聯繫人手機號（至少 1 個）';

  @override
  String get setupAddContact => '+ 添加另一個聯繫人';

  @override
  String get setupContactConsent => '我已告知上述聯繫人，App 會在我失聯時給他們發通知';

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
  String get setupReminder3 => '✓ 漏 2 天我會聯繫緊急人';

  @override
  String get setupPrivacy => '您的數據：';

  @override
  String get setupPrivacy1 => '• 本地加密';

  @override
  String get setupPrivacy2 => '• 不會上傳到任何雲端服務器';

  @override
  String get setupPrivacy3 => '• 您可以隨時導出';

  @override
  String get settingsContacts => '緊急聯繫人';

  @override
  String get settingsMedication => '常吃藥';

  @override
  String get settingsEmailPreview => '預覽停藥通知郵件';

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
  String get settingsAboutVersion => 'v0.23.0 · 我今天吃了藥';

  @override
  String get settingsDisclaimerText => '本應用不提供醫療建議，所有功能僅供參考。';

  @override
  String get settingsExportDialogTitle => '導出數據';

  @override
  String get settingsExportInstruction => '把下面這串 JSON 保存到安全的地方：';

  @override
  String get settingsExportVentWarning =>
      '說明：樹洞（私密傾訴）的文字會導出，但錄音文件不導出——錄音存在 App 本地，重裝後路徑失效，無法跨設備複用。';

  @override
  String get settingsExportVentConfirmTitle => '導出含敏感內容';

  @override
  String get settingsExportVentConfirmBody =>
      '即將導出樹洞的文字內容。精神心理患者的傾訴可能涉及個人隱私或敏感話題，導出的 JSON 是明文，存放在剪貼板或文件裡都可能被他人看到。\n\n請確認:\n• 您將把它存到安全的地方（如加密磁盤）\n• 不會分享給未授權的人\n• 樹洞錄音文件不包含在導出中';

  @override
  String get settingsExportVentConfirmConfirm => '我瞭解，繼續導出';

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
  String settingsImportSuccess(String summary) {
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
  String commonLoadFailed(String error) {
    return '加載失敗：$error';
  }

  @override
  String snackbarErrorTemplate(String action, String error) {
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
  String get snackbarPhoneInvalid => '號碼格式不對（支持大陸／港澳臺／國際）';

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
  String medsRefillSet(String date, int days) {
    return '已設置：$date 續方，提前 $days 天提醒';
  }

  @override
  String get medsActionRefill => '設置續方';

  @override
  String medsRefillOverdue(int days, int reminderDays) {
    return '已過期 $days 天 · 提前 $reminderDays 天提醒';
  }

  @override
  String medsRefillUpcoming(String date, int days, int reminderDays) {
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
  String get reminderHubDailyAction => '查看通知預覽';

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
  String get reminderHubSafetyTitle => '失聯通知（安全開關）';

  @override
  String get reminderHubSmsMockWarning =>
      'SMS 通道未接通（當前使用 Mock）。失聯觸發時只會推本地通知，不會真發短信給緊急聯繫人。上 store 前必須接入真實 SMS provider。';

  @override
  String reminderHubSafetyDescEnabled(int threshold) {
    return '連續 $threshold 天沒打卡 → 自動 SMS 通知緊急聯繫人 + 本地推送';
  }

  @override
  String get reminderHubSafetyDescDisabled => '關閉 · 不會自動通知緊急聯繫人';

  @override
  String reminderHubSafetyStatusEnabled(int threshold) {
    return '已啟用 · 閾值 $threshold 天';
  }

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
  String get reminderHubSafetyDescription =>
      '連續 N 天沒打卡 → 自動 SMS 通知所有啟用的緊急聯繫人 + 本地推送';

  @override
  String get reminderHubTriggerThreshold => '觸發閾值（連續 N 天沒打卡）';

  @override
  String reminderHubNDays(int days) {
    return '$days 天';
  }

  @override
  String setupContactNameLabel(int index) {
    return '聯繫人 $index 姓名';
  }

  @override
  String get setupContactNameHint => '稱呼（選填）';

  @override
  String setupContactPhoneLabel(int index) {
    return '緊急聯繫人手機號 $index';
  }

  @override
  String get setupContactPhoneHint => '13800138000';

  @override
  String get ventListTitle => '我的樹洞';

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
  String get ventRecordActive => '正在錄音……點停止';

  @override
  String get ventAudioLabel => '錄音';

  @override
  String get ventAudioPlayTooltip => '播放錄音';

  @override
  String get ventAudioPauseTooltip => '暫停錄音';

  @override
  String get ventRerecord => '重錄';

  @override
  String get moodDialogTitle => '今天怎麼樣？';

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
  String moodAudioRecorded(String duration) {
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
      String date, String suffix, int reminderDays) {
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
  String assessmentQuestionLabel(int index, String text, String selected) {
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
  String homeHeaderKeepGoing(String name) {
    return '$name 還在堅持';
  }

  @override
  String get homeTooltipTrend => '查看趨勢';

  @override
  String get homeTooltipAssessmentHistory => '評估歷史';

  @override
  String get homeStreakRestart => '今天重新開始，加油 🌱';

  @override
  String get homeStreakDay1 => '第 1 天，邁出第一步 🌱';

  @override
  String homeStreakDays(int days) {
    return '堅持 $days 天，繼續 🌿';
  }

  @override
  String homeStreakGreat(int days) {
    return '已堅持 $days 天，真棒 🌳';
  }

  @override
  String homeStreakAmazing(int days) {
    return '$days 天連擊，太厲害了 🌲';
  }

  @override
  String homeStreakMaster(int days) {
    return '$days 天--您已經是這個習慣的主人了 🏔️';
  }

  @override
  String get navCheckIn => '打卡';

  @override
  String get navSettings => '設置';

  @override
  String get navAppName => '慢病管家';

  @override
  String errorPageNotFound(String path) {
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
  String assessmentAverageScore(String score) {
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
  String get assessmentSeverityNormal => '正常';

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
  String get setupValidationContactRequired => '至少填 1 個緊急聯繫人手機號';

  @override
  String get setupValidationPhoneInvalid => '手機號格式不對';

  @override
  String get setupValidationPhoneDuplicate => '緊急聯繫人手機號不能重複';

  @override
  String get setupPresetTitle => '📋 選擇預置方案';

  @override
  String get setupPresetDescription => '預置方案會填好藥名 + 時間，您可以接著改。最終服藥請按醫囑核對。';

  @override
  String setupPresetLoaded(String name, int count) {
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
  String get setupWelcomeContactHint => '（至少填 1 個手機號，用於失聯時通知）';

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
  String get legalPageWithdrawSafety => '撤回失聯通知同意';

  @override
  String get legalPageWithdrawSafetySubtitle => '不再因漏打卡觸發短信／郵件通知給緊急聯繫人';

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
  String get emailPreviewTitle => '通知預覽';

  @override
  String get emailPreviewSetupRequired => '請先完成首次設置';

  @override
  String get emailPreviewDescription => '這是您將收到的失聯通知預覽：';

  @override
  String get emailPreviewNoContact => '（無聯繫人）';

  @override
  String get emailPreviewDisclaimer =>
      '💡 這只是預覽。實際短信通知在您漏 2 天沒打卡後自動發送（v0.6 mock 階段只打日誌，v1.0+ 接真實 SMS provider）。';

  @override
  String get reportHistoryEmpty => '還沒有報告歷史\n生成一次報告後會自動記錄';

  @override
  String reportHistoryItemTitle(String date, int days) {
    return '$date · 近 $days 天';
  }

  @override
  String reportHistoryItemPatient(String name) {
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
    return '已記錄！$days 天--您太厲害了 🏔️';
  }

  @override
  String homeAutofireCelebration(String name) {
    return '已打卡：$name ✅';
  }

  @override
  String get homeAutofireFallbackName => '該藥';

  @override
  String homeMedHint(int id) {
    return '💊 準備打卡藥物 #$id';
  }

  @override
  String get homeSafetyAlertSuffix => '（請儘快打卡或聯繫家人）';

  @override
  String safetyAlertBodySent(String date) {
    return '上次打卡: $date。已自動通知緊急聯繫人，請確認安全。';
  }

  @override
  String safetyAlertBodyMocked(String date) {
    return '上次打卡: $date。失聯檢測已觸發，但當前為開發模式，**未實際通知**緊急聯繫人。';
  }

  @override
  String safetyAlertBodyFailed(String date) {
    return '上次打卡: $date。失聯檢測已觸發，但通知發送失敗。請檢查網絡。';
  }

  @override
  String get homeSnoozeTitle => '⏰ 該打卡了（5min 後）';

  @override
  String get homeSnoozeBody => '剛才您點了「snooze」，是時候點一下 = 打卡了';

  @override
  String get homeSnoozeConfirmed => '好，5 分鐘後會再提醒您 👌';

  @override
  String get homeSnoozeButton => '⏰ 5 分鐘後再提醒';

  @override
  String get homeVentButton => '傾訴 🌲';

  @override
  String get homeNotifBannerText => '提醒沒設上，可能錯過打卡。請到系統設置允許通知。';

  @override
  String get homeNotifBannerDismiss => '知道了';

  @override
  String themeTooltip(String mode) {
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
  String trendMoodEntriesSame(int count, String emoji) {
    return '$count 條情緒記錄 · $emoji';
  }

  @override
  String trendMoodEntriesRange(int count, String lowEmoji, String highEmoji) {
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
  String get contactEmptyList => '還沒有聯繫人，請先添加';

  @override
  String get contactAddAction => '添加聯繫人';

  @override
  String get contactAddTitle => '添加緊急聯繫人';

  @override
  String get contactConsentTitle => '知情同意';

  @override
  String contactConsentBody(int threshold) {
    return '您即將把這位聯繫人的手機號保存在本地數據庫中。當您連續 $threshold 天未在 App 內打卡時，App 會通過 SMS 短信自動通知該聯繫人。\n\n**根據《個人信息保護法》第 13 條**，請確認您已告知該聯繫人上述用途，並取得其同意。';
  }

  @override
  String get contactConsentAgree => '已告知並取得同意';

  @override
  String get contactConsentReject => '暫不同意';

  @override
  String get contactConsentVersion => 'v1 · 2026-07-31';

  @override
  String get contactDefaultName => '聯繫人';

  @override
  String get contactNameLabel => '姓名';

  @override
  String get contactPhoneLabel => '手機號';

  @override
  String get commonActionDelete => '刪除';

  @override
  String get commonActionSave => '保存';

  @override
  String get editMedDialogTitle => '編輯藥物';

  @override
  String get editMedValidationNameRequired => '請填寫藥名';

  @override
  String get editMedValidationDosageInvalid => '劑量必須是大於 0 的數字';

  @override
  String get editMedValidationUnitInvalid => '單位必須是 mg 或 片';

  @override
  String editMedSaveFailed(String error) {
    return '保存失敗：$error';
  }

  @override
  String get editMedStatusActive => '正在使用';

  @override
  String get editMedStatusStopped => '已停藥';

  @override
  String editMedStoppedDate(String date) {
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
  String get tempMedDialogTitle => '添加臨時吃藥';

  @override
  String get tempMedLinkLabel => '關聯到常吃藥（可選）';

  @override
  String get tempMedLinkHint => '不選 = 臨時事件';

  @override
  String get tempMedNoLink => '不關聯';

  @override
  String get tempMedNameHint => '如：布洛芬';

  @override
  String get tempMedReasonLabel => '原因';

  @override
  String get tempMedReasonHint => '如：感冒';

  @override
  String get medsCalendarHeatmapDesc => '以藥為單位的依從性熱力圖。顏色越深 = 當天打卡次數越接近期望次數。';

  @override
  String get medsCalendarWindow7 => '7 天';

  @override
  String get medsCalendarWindow30 => '30 天';

  @override
  String get medsCalendarWindow90 => '90 天';

  @override
  String medsCalendarLoadCheckinFailed(String error) {
    return '加載打卡失敗：$error';
  }

  @override
  String medsCalendarLoadMedFailed(String error) {
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
  String get medsCalendarLegendMissed => '漏服';

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
  String get snackbarActionRecord => '錄音';

  @override
  String get snackbarActionStartRecording => '開始錄音';

  @override
  String get snackbarActionCheckin => '打卡';

  @override
  String get snackbarActionSnooze => '推遲提醒';

  @override
  String get snackbarActionAutoCheckin => '自動打卡';

  @override
  String get snackbarActionFinishSetup => '完成設置';

  @override
  String get snackbarActionUndo => '撤銷';

  @override
  String get ventEntryDeleted => '已刪除樹洞條目';

  @override
  String get contactDeleted => '已刪除聯繫人';

  @override
  String get medicationDeleted => '已刪除藥物';

  @override
  String get moodTodayLabel => '今日情緒：';

  @override
  String get moodRecordButton => '記一下情緒 ✏️';

  @override
  String medReportFileName(String date) {
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
  String setupContactFallbackName(int index) {
    return '聯繫人 $index';
  }

  @override
  String emailBodyI18n(String name, int days) {
    return '我是 $name，已經 $days 天沒在 App 裡打卡了。\n請你方便的時候提醒我按時吃藥，避免復發。';
  }

  @override
  String get emailFooterI18n =>
      '這是一條自動通知，由慢病管家 App 發送。\n本通知不包含任何醫療建議。\n如需停止接收，請在 App 設置中修改。';

  @override
  String get medicationUnitMg => 'mg';

  @override
  String get medicationUnitTablet => '片';

  @override
  String get safetyCheckResultDisabled => '安全開關已關閉';

  @override
  String safetyCheckResultOk(int days) {
    return '正常（$days 天前打卡）';
  }

  @override
  String get safetyCheckResultNoData => '新用戶，暫無打卡';

  @override
  String safetyCheckResultAlertedToday(int days) {
    return '今天已經發過告警（$days 天前打卡）';
  }

  @override
  String get safetyCheckResultDndSuppressed => 'DND 時段，跳過告警';

  @override
  String get safetyCheckResultNoContacts => '無緊急聯繫人，未發送';

  @override
  String safetyCheckResultAlertedMocked(int mocked) {
    return '**開發模式**，未實際通知聯繫人（mock: $mocked）';
  }

  @override
  String safetyCheckResultAlerted(int days, int notified, int failed) {
    return '已告警：$days 天前打卡，已通知 $notified 位聯繫人（$failed 失敗）';
  }

  @override
  String safetyCheckResultError(String message) {
    return '錯誤：$message';
  }

  @override
  String get settingsIapUpgradeTitle => '升級到 Pro';

  @override
  String get settingsIapUpgradeSubtitle => '¥8 一次性買斷 · 解鎖全部進階功能';

  @override
  String get settingsIapProOwnedTitle => '已是 Pro 版本';

  @override
  String get settingsIapProOwnedSubtitle => '感謝支持 · 全部進階功能已解鎖';

  @override
  String get iapPurchaseSuccess => '升級成功！歡迎使用 Pro。';

  @override
  String get iapPurchaseFailed => '購買未完成，請稍後再試。';

  @override
  String get phoneRegionCn => '中國大陸';

  @override
  String get phoneRegionHk => '中國香港';

  @override
  String get phoneRegionMo => '中國澳門';

  @override
  String get phoneRegionTw => '中國臺灣';

  @override
  String get phoneRegionIntl => '國際';

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
  String get checkInTypeDaily => '每日打卡';

  @override
  String get checkInTypeTemp => '臨時吃藥';

  @override
  String get checkInTypePhq9 => 'PHQ-9 評估';

  @override
  String get checkInTypeGad7 => 'GAD-7 評估';

  @override
  String dayDetailCheckInWith(String name) {
    return '打卡 · $name';
  }

  @override
  String get dayDetailDailyCheckIn => '每日打卡';

  @override
  String dayDetailTempWith(String name) {
    return '臨時 · $name';
  }

  @override
  String get dayDetailTempMed => '臨時吃藥';

  @override
  String get dayDetailPhq9 => 'PHQ-9 抑鬱篩查';

  @override
  String get dayDetailGad7 => 'GAD-7 焦慮篩查';

  @override
  String ventDurationSeconds(int sec) {
    return '$sec秒';
  }

  @override
  String ventDurationMinutes(int m) {
    return '$m分';
  }

  @override
  String ventDurationMinutesSeconds(int m, String sec) {
    return '$m分$sec秒';
  }

  @override
  String get scaleHotlineCn => '全國 24 小時心理援助熱線';

  @override
  String get scaleHotlineUs => '988 Suicide & Crisis Lifeline (US)';

  @override
  String get scaleHotlineHk => '撒瑪利亞防止自殺會（24h 多語言）';

  @override
  String get scaleHotlineIntl => '國際通用 · 請聯繫當地急救或心理援助';
}
