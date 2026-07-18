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
  String get commonClose => '关闭';

  @override
  String get commonRetry => '重试';

  @override
  String get commonGotIt => '我知道了';

  @override
  String get commonConfirmDelete => '删除这条？';

  @override
  String commonLoadFailed(String error) => '加载失败：$error';

  @override
  String get commonDeleteWarning => '删除后无法恢复';

  @override
  String get commonEmpty => '还没有';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonError => '出错了，请重试';

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
  String commonAutoCheckinFailed(String error) => '自动打卡失败：$error';

  @override
  String commonCheckinFailed(String error) => '打卡失败：$error';

  @override
  String get commonVentDeleteWarning => '删了就没了。文字和录音都会一起删。';
}
