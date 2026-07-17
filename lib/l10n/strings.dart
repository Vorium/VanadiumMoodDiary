/// 国际化字符串（v1.0+ 改用 ARB）
class Strings {
  Strings._();

  // App
  static const appName = '慢病管家';
  static const appTagline = '我今天吃了药';

  // 主页
  static const homeCheckIn = '我今天吃了药';
  static const homeCheckedIn = '今天已打卡 ✓';
  static String homeStreak(int days) => '已坚持 $days 天';
  static String homeLastMed(String time) => '最后吃药：$time';
  static String homeNextReminder(String time) => '下次提醒：$time';
  static const homeStillOnline = '🌱 你还在线';
  static const homeTempMed = '临时吃药 +';
  static const homeStreakBroken = '少 1 次没关系，明天继续';

  // 首次设置
  static String setupStep(int current, int total) =>
      '第 $current 步 / 共 $total 步';
  static const setupHello = '你好，我是慢病管家';
  static const setupIntro = '1 分钟设置好，然后每天 1 次打卡';
  static const setupName = '你的名字';
  static const setupNameHint = '小明';
  static const setupContacts = '紧急联系人邮箱（至少 1 个）';
  static const setupContactHint = 'mom@example.com';
  static const setupAddContact = '+ 添加另一个联系人';
  static const setupNext = '下一步 →';
  static const setupMedName = '药名';
  static const setupMedNameHint = '舍曲林';
  static const setupMedFrequency = '每日次数';
  static const setupMedTimes1 = '1次';
  static const setupMedTimes2 = '2次';
  static const setupMedTimes3 = '3次';
  static const setupMedSchedule = '吃药时间（可填）';
  static const setupStart = '开始我的第 1 天';
  static const setupDoneTitle = '全部完成！';
  static const setupDoneSubtitle = '明天开始你的第 1 天';
  static const setupDailyRoutine = '我每天会做：';
  static const setupReminder1 = '✓ 推送 1 次提醒';
  static const setupReminder2 = '✓ 你点 1 下 = 打卡';
  static const setupReminder3 = '✓ 漏 2 天我会联系紧急人';
  static const setupPrivacy = '你的数据：';
  static const setupPrivacy1 = '• 本地加密';
  static const setupPrivacy2 = '• 不会上传云端（除邮件通知）';
  static const setupPrivacy3 = '• 你可以随时导出';

  // 设置
  static const settingsContacts = '紧急联系人';
  static const settingsMedication = '常吃药';
  static const settingsEmailPreview = '预览停药通知邮件';
  static const settingsAbout = '关于';
  static const settingsDisclaimer = '免责声明';
  static const settingsExport = '导出数据';
  static const settingsMedReport = '用药报告';
  static const settingsMedReportSubtitle = '选时间窗口（7/14/30 天），给医生看';
  static const settingsMedReportChooseTitle = '选择时间窗口';
  static const settingsMedReportChooseSubtitle = '会统计这段时间内的所有常吃药 + 临时用药';
  static const settingsMedReportWindow7 = '近 7 天';
  static const settingsMedReportWindow14 = '近 14 天';
  static const settingsMedReportWindow30 = '近 30 天';
  static const settingsReportHistory = '报告历史';
  static const settingsReportHistorySubtitle = '查看过去生成的用药报告';

  // 通知（v0.6：邮件改 mock 短信，文案保留）
  static String emailSubject(String name, int days) =>
      '[停药提醒] $name 已经 $days 天没吃药了';
  static String emailBody(String userName, int days) =>
      '我是 $userName，已经 $days 天没在 App 里打卡了。\n'
      '请你方便的时候提醒我按时吃药，避免复发。';
  static String emailLastMed(String time) => '最后吃药：$time';
  static String emailMedInfo(String name, double dosage, String unit) =>
      '$name $dosage$unit';
  static String emailCycle(int hours) => '签到周期：$hours 小时';
  static const emailFooter = '这是一条自动通知，由慢病管家 App 发送。\n'
      '本通知不包含任何医疗建议。\n'
      '如需停止接收，请在 App 设置中修改。';

  // 通用
  static const commonSave = '保存';
  static const commonCancel = '取消';
  static const commonDelete = '删除';
  static const commonEdit = '编辑';
  static const commonDone = '完成';
  static const commonConfirm = '确认';
  static const commonLoading = '加载中...';
  static const commonError = '出错了，请重试';
}
