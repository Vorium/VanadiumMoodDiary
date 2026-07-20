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
  String get setupContacts => '紧急联系人手机号（至少 1 个）';

  @override
  String get setupContactHint => '13800138000';

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
  String get setupPrivacy2 => '• 不会上传到任何云端服务器';

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
  String get settingsClearAllData => '清空所有数据';

  @override
  String get settingsClearAllDataSubtitle =>
      '删除全部打卡 / 用药 / 评估 / 树洞 / 联系人(无法恢复)';

  @override
  String get settingsClearAllDataDialogTitle => '确认清空所有数据?';

  @override
  String get settingsClearAllDataDialogBody =>
      '以下数据将被永久删除,无法恢复:\n• 打卡记录\n• 用药与服药历史\n• 心理评估结果\n• 情绪日记\n• 树洞(文字+录音)\n• 紧急联系人\n\n清空后 App 会跳回首次设置流程。建议先导出 JSON 备份。';

  @override
  String get settingsClearAllDataConfirm => '我已备份,确认清空';

  @override
  String get settingsClearAllDataSuccess => '已清空所有数据';

  @override
  String settingsClearAllDataFailed(Object error) {
    return '清空失败: $error';
  }

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
  String get medsListNoActiveHint => '所有药物都已停用,去添加新药物开始新一阶段';

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

  @override
  String get ventListTitle => '我的树洞';

  @override
  String get ventListWriteTooltip => '写一条';

  @override
  String get ventEmptyTitle => '树洞还是空的';

  @override
  String get ventEmptySubtitle => '想说什么就说出来。文字、语音都可以。\n这些话只有你自己能看到。';

  @override
  String get ventEmptyAction => '写第一句';

  @override
  String get ventVoiceLabel => '🎙️ 语音';

  @override
  String get ventDetailTitle => '树洞';

  @override
  String get ventDetailNotFound => '找不到了';

  @override
  String get ventDetailPrivacy => '🔒 私密 · 只有你能看到';

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
  String get ventRecordActive => '正在录音… 点停止';

  @override
  String get ventAudioLabel => '录音';

  @override
  String get ventRerecord => '重录';

  @override
  String ventDurationSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String ventDurationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String ventDurationMinutesSeconds(int minutes, int seconds) {
    return '$minutes分$seconds秒';
  }

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
  String get assessmentLoadingBack => '正在返回上一页...';

  @override
  String assessmentAnsweredProgress(int answered, int total) {
    return '已答 $answered / $total';
  }

  @override
  String get assessmentSubmit => '提交并查看结果';

  @override
  String assessmentScoreTotal(int max) {
    return '总分（0-$max）';
  }

  @override
  String get assessmentRecommendUrgent => '强烈建议你尽快联系医生或心理治疗师。';

  @override
  String get assessmentRecommend => '建议你联系医生做进一步评估。';

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
    return '$days 天--你已经是这个习惯的主人了 🏔️';
  }

  @override
  String get navCheckIn => '打卡';

  @override
  String get navSettings => '设置';

  @override
  String get navAppName => '慢病管家';

  @override
  String errorPageNotFound(String path) {
    return '页面不存在: $path';
  }

  @override
  String get errorPageHint => '这个地址可能已经失效,或者链接有误。';

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
      '完成一次评估后，下次提醒会从今天重新算起。\n评估结果仅你自己看得到。';

  @override
  String get assessmentReminderHintAcute => '高强度监测（适合急性期）';

  @override
  String get assessmentReminderHintCommon => '推荐（精神科常用）';

  @override
  String get assessmentReminderHintStable => '稳定期 / 月度复盘';

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
    return '最低 $min / 最高 $max';
  }

  @override
  String get assessmentComparePrevious => '对比上次';

  @override
  String get assessmentFirstAssessmentHint => '这是你的第一次评估。下次评估后会显示和这次的对比。';

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
  String get setupPresetDescription => '预置方案会填好药名 + 时间，你可以接着改。最终服药请按医嘱核对。';

  @override
  String setupPresetLoaded(String name, int count) {
    return '已载入：$name（$count 个药）请核对药名和剂量';
  }

  @override
  String setupSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get setupMedWhatDoYouTake => '你常吃什么药？';

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
      '为遵守《个人信息保护法》(PIPL),本 App 处理您的健康医疗等敏感个人信息前，需要您明确、单独同意以下 3 份文件。';

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
      '提示：您可以随时在「设置 → 法律与隐私」撤回同意。拒绝或撤回后,App 的相关功能将无法使用。';

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
  String get legalPageWithdrawDescription => '撤回某项同意后,相关功能立即停用(数据不删除,可重新打开)。';

  @override
  String get legalPageWithdrawSafety => '撤回失联通知同意';

  @override
  String get legalPageWithdrawSafetySubtitle => '不再因漏打卡触发短信/邮件通知给紧急联系人';

  @override
  String get legalPageWithdrawVent => '撤回树洞(敏感倾诉)处理同意';

  @override
  String get legalPageWithdrawVentSubtitle => '停止存储新树洞文字/录音(已有数据保留,需手动删除)';

  @override
  String get legalPageWithdrawAnalytics => '撤回评估/情绪分析同意';

  @override
  String get legalPageWithdrawAnalyticsSubtitle =>
      '停止将评估/情绪记录纳入趋势分析(数据保留,不再入图表)';

  @override
  String legalPageConsentRecorded(Object time) {
    return '撤回时间: $time';
  }

  @override
  String get legalPageConsentNever => '从未撤回';

  @override
  String get legalPageResetConsent => '重新同意';

  @override
  String get emailPreviewTitle => '通知预览';

  @override
  String get emailPreviewSetupRequired => '请先完成首次设置';

  @override
  String get emailPreviewDescription => '这是你将收到的失联通知预览：';

  @override
  String get emailPreviewNoContact => '（无联系人）';

  @override
  String get emailPreviewDisclaimer =>
      '💡 这只是预览。实际短信通知在你漏 2 天没打卡后自动发送（v0.6 mock 阶段只打日志，v1.0+ 接真实 SMS provider）。';

  @override
  String get reportHistoryEmpty => '还没有报告历史\n生成一次报告后会自动记录';

  @override
  String reportHistoryItemTitle(String date, int days) {
    return '$date · 近 $days 天';
  }

  @override
  String reportHistoryItemPatient(String name) {
    return '患者: $name';
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
    return '已记录!$days 天连击 🌲';
  }

  @override
  String homeCelebrationStreakMaster(int days) {
    return '已记录!$days 天--你太厉害了 🏔️';
  }

  @override
  String homeAutofireCelebration(String name) {
    return '已打卡:$name ✅';
  }

  @override
  String get homeAutofireFallbackName => '该药';

  @override
  String homeMedHint(int id) {
    return '💊 准备打卡药物 #$id';
  }

  @override
  String get homeSafetyAlertSuffix => '(请尽快打卡或联系家人)';

  @override
  String get homeSnoozeTitle => '⏰ 该打卡了(5min 后)';

  @override
  String get homeSnoozeBody => '刚才你点了「snooze」,是时候点一下 = 打卡了';

  @override
  String get homeSnoozeConfirmed => '好,5 分钟后会再提醒你 👌';

  @override
  String homeSnoozeFailed(String error) {
    return 'Snooze 失败:$error';
  }

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
  String get medReportPdfLoading => '生成 PDF 中...';

  @override
  String get medReportShareSubject => '慢病管家 · 用药报告';

  @override
  String get medReportGenPdfAction => '生成 PDF';

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
    return '加载打卡失败: $error';
  }

  @override
  String medsCalendarLoadMedFailed(String error) {
    return '加载药物失败: $error';
  }

  @override
  String get medsCalendarNoActive => '还没有在用药物';

  @override
  String get medsCalendarNoSchedule => '在用药物未设置服用时间，无法生成依从性日历';

  @override
  String get medsCalendarNoScheduleHint => '在设置页给药物加上服药时间后,这里会显示服药日历';

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
  String get snackbarActionUndo => '撤销';

  @override
  String get listSwipeDeleteHint => '左滑删除';

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
}
