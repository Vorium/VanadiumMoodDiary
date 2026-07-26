import 'package:chroniccare/domain/entities/dosage_unit.dart';

/// 国际化字符串 — domain 层专用 fallback
///
/// v0.17 round 14 (P1-6): presentation 文字迁到 flutter_localizations
/// (`lib/l10n/app_zh.arb` / `app_en.arb`)。
/// 但 domain 层不能 import flutter,所以通知/邮件模板 (EmailTemplate) 仍用
/// 这里 hardcode 字符串 (v0.6 mock 短信中文文案)。
///
/// v0.23 round 39 (P1-9 fix): 通知标题/正文/Channel 名等也集中到本类,
/// 通知 service 不再 hardcode 中文。domain 层虽不能 import flutter, 但
/// **可以** import 一个常量字符串集合。后续接 i18n 时这里改多语言即可。
///
/// v1.0+ 计划: domain EmailTemplate 接收 i18n strings 作为参数，完全脱离本文件。
class Strings {
  Strings._();

  // 通知 / 邮件模板 (outgoing message, 通常单语言, 暂用中文)
  static String emailSubject(String name, int days) =>
      '[停药提醒] $name 已经 $days 天没吃药了';
  // v0.21 Round 22 (P0-7 修复): PIPL §6 最小化原则。
  // 之前强加 userName 字段,userName 为空 / 用户不想暴露真名时模板崩。
  // 现在 userName 走 fallback:空/纯空白 → "用户" (默认代称),不强行暴露。
  static String emailBody(String userName, int days) {
    final name = userName.trim().isEmpty ? '用户' : userName.trim();
    return '我是 $name，已经 $days 天没在 App 里打卡了。\n'
        '请你方便的时候提醒我按时吃药，避免复发。';
  }

  static String emailLastMed(String time) => '最后吃药：$time';
  static String emailMedInfo(String name, double dosage, DosageUnit unit) =>
      '$name $dosage${unit.id}';
  static String emailCycle(int hours) => '签到周期：$hours 小时';
  static const emailFooter = '这是一条自动通知，由慢病管家 App 发送。\n'
      '本通知不包含任何医疗建议。\n'
      '如需停止接收，请在 App 设置中修改。';

  // ============== v0.23 round 39 (P1-9 fix): 通知标题/正文/Channel ==============
  // 通知 service 之前 6 处 hardcode 中文,集中到本类,便于 i18n 化

  // 通知 Channel
  static const notifChannelMedicationName = '吃药提醒';
  static const notifChannelMedicationDesc = '到点提醒你吃药打卡';
  static const notifChannelSafetyName = '安全警报';
  static const notifChannelSafetyDesc = '长时间未打卡时提醒';

  // 每日打卡提醒 (20:00)
  static const notifDailyCheckInTitle = '🌱 今天吃了药吗？';
  static const notifDailyCheckInBody = '点一下 = 打卡，让家人放心';

  // 用药提醒 (按 medication 单独排)
  static String notifMedicationTitle(String medName) => '💊 该吃药了：$medName';
  static String notifMedicationBody(double dosage, DosageUnit unit) =>
      '$dosage${unit.id} · 点一下 = 打卡';

  // 续方提醒
  static String notifRefillTitle(String medName) => '💊 该续方了：$medName';
  static String notifRefillBody(int daysLeft) =>
      '还剩约 $daysLeft 天断药，记得去医院或线上开药';

  // 心理评估提醒
  static String notifAssessmentTitle() => '🌿 心理评估时间到';
  static String notifAssessmentBody(int days, String scaleIdUppercase) =>
      '已经 $days 天没做 $scaleIdUppercase 了，请花 2 分钟做一下评估';

  // ============== v0.23 round 39 (P1-9 fix): 医生 PDF 报告 ==============
  // medication_report_pdf 之前 20+ 处 hardcode 中文,集中到本类
  // 海外医生看 PDF 不能用,这里给每条文案一个 getter,后续接 i18n 时换实现

  // 报告头/页脚
  static const pdfTitle = '慢病管家 · 用药报告';
  static const pdfAuthor = '慢病管家';
  static String pdfSubject(int days) => '$days 天用药情况';
  static String pdfRecentDays(int days) => '近 $days 天';
  static const pdfFooterNotice =
      '本报告由「慢病管家」App 自动生成 · 本应用不提供医疗建议';
  static String pdfPageN(int page, int total) => '第 $page / $total 页';

  // 区块标题
  static const pdfSectionRoutineMeds = '常吃药方案';
  static const pdfSectionTempMeds = '临时用药';
  static const pdfSectionSummary = '总览';

  // 患者信息块
  static const pdfLabelPatient = '患者';
  static const pdfLabelReportPeriod = '报告周期';
  static const pdfLabelGeneratedAt = '生成时间';
  static const pdfUnset = '未设置';
  static String pdfReportPeriodValue(String start, String end, int days) =>
      '$start 至 $end（共 $days 天）';
  static const pdfNoValue = '（无）';

  // 用药项
  static const pdfLabelStart = '起始';
  static const pdfLabelMedicationStats = '服药统计';
  static const pdfLabelMissed = '漏服';
  static const pdfNoMissed = '✓ 无';
  static const pdfUnsetTime = '未设置时间';
  static String pdfDailyNTimes(int n, String times) => '每日 $n 次（$times）';
  static String pdfMedicationStatsValue(
    int actualDoseDays,
    int windowDays,
    int actualDoseCount,
    int expectedDoseCount,
  ) =>
      '$actualDoseDays/$windowDays 天 · $actualDoseCount/$expectedDoseCount 次';

  // 临时用药表
  static const pdfColumnDate = '日期';
  static const pdfColumnTime = '时间';
  static const pdfColumnMed = '药名';
  static const pdfColumnNote = '备注';

  // 总览
  static String pdfOnTime(int n) => '按时服药: $n 次';
  static String pdfMissed(int n) => '漏服: $n 次';
  static String pdfExtra(int n) => '补服: $n 次';
  static String pdfTempN(int n) => '临时用药: $n 次';
  static String pdfAdherencePct(int? pct) =>
      pct == null ? '依从率: —（无可比较的常吃药）' : '依从率: $pct%';

  // ============== v0.23 round 39 (P1-9 fix): 数据导入摘要 ==============
  // data_export_service ImportResult.summary 之前 7 处 hardcode 中文
  // 改成 Strings 给后续 i18n 留入口

  static String importSummaryContact(int n) => '$n 联系人';
  static String importSummaryMedication(int n) => '$n 药';
  static String importSummaryCheckIn(int n) => '$n 打卡';
  static String importSummaryReport(int n) => '$n 报告';
  static String importSummaryMood(int n) => '$n 情绪';
  static String importSummaryVent(int n) => '$n 树洞';

  // ============== 情绪标签（domain 层 fallback） ==============
  // presentation 层应使用 AppLocalizations 的 moodLabelN 键
  static String moodLabel(int score) => switch (score) {
        1 => '很差',
        2 => '差',
        3 => '一般',
        4 => '好',
        5 => '很好',
        _ => '一般',
      };

  // ============== Snooze 通知文案 ==============
  static const snoozeTitle = '💊 提醒吃药（snooze）';
  static const snoozeBody = '刚才您点了"稍后提醒"，该吃药了';
}
