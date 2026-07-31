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
/// v0.26 round 57 (spzh P0 #6 fix): 加 `String? override` 参数
/// 允许 caller (presentation 层) 传 `AppLocalizations.of(context).xxx`
/// 走 ARB i18n 路径,fallback 仍是这里的中文 (domain 0 flutter 边界)。
/// 不传 override = 完全 backward compatible (老 caller 不动)。
/// 这样做的好处:
///   1) domain 层继续 0 flutter (override 是 String? 注入,不是 import)
///   2) presentation 层可选择性升级到 i18n, 不破坏其它 caller
///   3) 测试可注入 mock override
///
/// v1.0+ 计划: domain EmailTemplate 接收 i18n strings 作为参数，完全脱离本文件。
class Strings {
  Strings._();

  // 通知 / 邮件模板 (outgoing message, 通常单语言, 暂用中文)
  // v0.26 R57 (spzh P0 #6): 加 override 参数 (向后兼容)
  static String emailSubject(String name, int days, {String? override}) =>
      override ?? '[停药提醒] $name 已经 $days 天没吃药了';
  // v0.21 Round 22 (P0-7 修复): PIPL §6 最小化原则。
  // 之前强加 userName 字段,userName 为空 / 用户不想暴露真名时模板崩。
  // 现在 userName 走 fallback:空/纯空白 → "用户" (默认代称),不强行暴露。
  // v0.26 R57: 加 override 参数 (向后兼容)
  static String emailBody(String userName, int days, {String? override}) {
    if (override != null) return override;
    final name = userName.trim().isEmpty ? '用户' : userName.trim();
    return '我是 $name，已经 $days 天没在 App 里打卡了。\n'
        '请你方便的时候提醒我按时吃药，避免复发。';
  }

  static String emailLastMed(String time, {String? override}) =>
      override ?? '最后吃药：$time';
  static String emailMedInfo(
    String name,
    double dosage,
    DosageUnit unit, {
    String? override,
  }) =>
      override ?? '$name $dosage${unit.id}';
  static String emailCycle(int hours, {String? override}) =>
      override ?? '签到周期：$hours 小时';
  // v0.26 R57: const 保留 (老 caller snooze_manager 等仍用
  // `static const Strings.emailFooter`); 同时加
  // `emailFooterText({String? override})` 函数供新 caller 走 i18n override。
  // v0.27 round 63 (P1-8 修复): 注释与代码同步 — const 字段 + i18n 函数并存
  // (老 caller 用 const, 新 caller 用函数), 行为不变。
  static const emailFooter = '这是一条自动通知，由慢病管家 App 发送。\n'
      '本通知不包含任何医疗建议。\n'
      '如需停止接收，请在 App 设置中修改。';
  static String emailFooterText({String? override}) => override ?? emailFooter;

  // ============== v0.23 round 39 (P1-9 fix): 通知标题/正文/Channel ==============
  // 通知 service 之前 hardcode 中文, 集中到本类, 便于 i18n 化。
  // v0.27 round 63 (P1-8 修复): 注释"6 处"已过时 — v0.23 起步 6 项
  // (4 channel + 2 daily), v0.26 R57 加 med/refill/assessment 4 段, 实际
  // 10+ 项 i18n 化函数 + 4 项 const 字段。删误导性数字。

  // 通知 Channel — const 保留 (badge_sync_service / notification_service
  // 用 static const _channelName = Strings.notifChannelMedicationName)
  // 新 caller 走函数版 with override
  static const notifChannelMedicationName = '吃药提醒';
  static const notifChannelMedicationDesc = '到点提醒你吃药打卡';
  static const notifChannelSafetyName = '安全警报';
  static const notifChannelSafetyDesc = '长时间未打卡时提醒';

  /// v0.26 R57: 新 caller 走 i18n 路径用此 i18n 化函数 (presentation 层可注入 override)
  /// 与上面的 [notifChannelMedicationName] const 字段并存 — 老 caller
  /// (badge_sync_service / notification_service) 用 const 编译期常量,
  /// 新 caller 走 `*Text({override})` 函数拿 i18n 文案。
  /// v0.27 round 63 (P1-8 修复): dartdoc 跟代码同步, 注明"函数版"指 const
  /// 字段的 i18n 化函数版, 而非 dart getter 含义。
  static String notifChannelMedicationNameText({String? override}) =>
      override ?? notifChannelMedicationName;
  static String notifChannelMedicationDescText({String? override}) =>
      override ?? notifChannelMedicationDesc;
  static String notifChannelSafetyNameText({String? override}) =>
      override ?? notifChannelSafetyName;
  static String notifChannelSafetyDescText({String? override}) =>
      override ?? notifChannelSafetyDesc;

  // 每日打卡提醒 (20:00) — const 保留 (medication_notifier 用 const Strings.notifDailyCheckInTitle)
  static const notifDailyCheckInTitle = '🌱 今天吃了药吗？';
  static const notifDailyCheckInBody = '点一下 = 打卡，让家人放心';
  static String notifDailyCheckInTitleText({String? override}) =>
      override ?? notifDailyCheckInTitle;
  static String notifDailyCheckInBodyText({String? override}) =>
      override ?? notifDailyCheckInBody;

  // 用药提醒 (按 medication 单独排) — v0.26 R57: 加 override 参数
  static String notifMedicationTitle(
    String medName, {
    String? override,
  }) =>
      override ?? '💊 该吃药了：$medName';
  static String notifMedicationBody(
    double dosage,
    DosageUnit unit, {
    String? override,
  }) =>
      override ?? '$dosage${unit.id} · 点一下 = 打卡';

  // 续方提醒 — v0.26 R57: 加 override 参数
  static String notifRefillTitle(String medName, {String? override}) =>
      override ?? '💊 该续方了：$medName';
  static String notifRefillBody(int daysLeft, {String? override}) =>
      override ?? '还剩约 $daysLeft 天断药，记得去医院或线上开药';

  // 心理评估提醒 — v0.26 R57: 加 override 参数
  static String notifAssessmentTitle({String? override}) =>
      override ?? '🌿 心理评估时间到';
  static String notifAssessmentBody(
    int days,
    String scaleIdUppercase, {
    String? override,
  }) =>
      override ?? '已经 $days 天没做 $scaleIdUppercase 了，请花 2 分钟做一下评估';

  // ============== v0.23 round 39 (P1-9 fix): 医生 PDF 报告 ==============
  // medication_report_pdf 之前 20+ 处 hardcode 中文, 集中到本类
  // 海外医生看 PDF 不能用, 这里给每条文案: (1) const 字段 (caller 用
  // `const Strings.pdfTitle` 等编译期常量) + (2) i18n 化函数
  // `*Text({String? override})` (新 caller 传 l10n 拿多语言)。后续接 i18n
  // 时换函数实现, const 字段保留作中文 fallback。
  // v0.27 round 63 (P1-8 修复): 删误导性"一个 getter" — 实际是 const
  // 字段 + i18n 函数 pair, "getter" 在 Dart 是 `get xxx =>` 语法, 跟
  // 本类的 `static String xxxText` 函数不同义。

  // 报告头/页脚 — const 保留 (caller 用 const Strings.pdfTitle 等)
  static const pdfTitle = '慢病管家 · 用药报告';
  static const pdfAuthor = '慢病管家';
  static String pdfTitleText({String? override}) => override ?? pdfTitle;
  static String pdfAuthorText({String? override}) => override ?? pdfAuthor;
  static String pdfSubject(int days, {String? override}) =>
      override ?? '$days 天用药情况';
  static String pdfRecentDays(int days, {String? override}) =>
      override ?? '近 $days 天';
  static const pdfFooterNotice = '本报告由「慢病管家」App 自动生成 · 本应用不提供医疗建议';
  static String pdfFooterNoticeText({String? override}) =>
      override ?? pdfFooterNotice;
  static String pdfPageN(int page, int total, {String? override}) =>
      override ?? '第 $page / $total 页';

  // 区块标题 — const 保留
  static const pdfSectionRoutineMeds = '常吃药方案';
  static const pdfSectionTempMeds = '临时用药';
  static const pdfSectionSummary = '总览';
  static String pdfSectionRoutineMedsText({String? override}) =>
      override ?? pdfSectionRoutineMeds;
  static String pdfSectionTempMedsText({String? override}) =>
      override ?? pdfSectionTempMeds;
  static String pdfSectionSummaryText({String? override}) =>
      override ?? pdfSectionSummary;

  // 患者信息块 — const 保留
  static const pdfLabelPatient = '患者';
  static const pdfLabelReportPeriod = '报告周期';
  static const pdfLabelGeneratedAt = '生成时间';
  static const pdfUnset = '未设置';
  static String pdfLabelPatientText({String? override}) =>
      override ?? pdfLabelPatient;
  static String pdfLabelReportPeriodText({String? override}) =>
      override ?? pdfLabelReportPeriod;
  static String pdfLabelGeneratedAtText({String? override}) =>
      override ?? pdfLabelGeneratedAt;
  static String pdfUnsetText({String? override}) => override ?? pdfUnset;
  static String pdfReportPeriodValue(
    String start,
    String end,
    int days, {
    String? override,
  }) =>
      override ?? '$start 至 $end（共 $days 天）';
  static const pdfNoValue = '（无）';
  static String pdfNoValueText({String? override}) => override ?? pdfNoValue;

  // 用药项 — const 保留
  static const pdfLabelStart = '起始';
  static const pdfLabelMedicationStats = '服药统计';
  static const pdfLabelMissed = '漏服';
  static const pdfNoMissed = '✓ 无';
  static const pdfUnsetTime = '未设置时间';
  static String pdfLabelStartText({String? override}) =>
      override ?? pdfLabelStart;
  static String pdfLabelMedicationStatsText({String? override}) =>
      override ?? pdfLabelMedicationStats;
  static String pdfLabelMissedText({String? override}) =>
      override ?? pdfLabelMissed;
  static String pdfNoMissedText({String? override}) => override ?? pdfNoMissed;
  static String pdfUnsetTimeText({String? override}) =>
      override ?? pdfUnsetTime;
  static String pdfDailyNTimes(int n, String times, {String? override}) =>
      override ?? '每日 $n 次（$times）';
  static String pdfMedicationStatsValue(
    int actualDoseDays,
    int windowDays,
    int actualDoseCount,
    int expectedDoseCount, {
    String? override,
  }) =>
      override ??
      '$actualDoseDays/$windowDays 天 · $actualDoseCount/$expectedDoseCount 次';

  // 临时用药表 — const 保留
  static const pdfColumnDate = '日期';
  static const pdfColumnTime = '时间';
  static const pdfColumnMed = '药名';
  static const pdfColumnNote = '备注';
  static String pdfColumnDateText({String? override}) =>
      override ?? pdfColumnDate;
  static String pdfColumnTimeText({String? override}) =>
      override ?? pdfColumnTime;
  static String pdfColumnMedText({String? override}) =>
      override ?? pdfColumnMed;
  static String pdfColumnNoteText({String? override}) =>
      override ?? pdfColumnNote;

  // 总览 — v0.26 R57: 加 override 参数
  static String pdfOnTime(int n, {String? override}) =>
      override ?? '按时服药: $n 次';
  static String pdfMissed(int n, {String? override}) => override ?? '漏服: $n 次';
  static String pdfExtra(int n, {String? override}) => override ?? '补服: $n 次';
  static String pdfTempN(int n, {String? override}) => override ?? '临时用药: $n 次';
  static String pdfAdherencePct(int? pct, {String? override}) =>
      override ?? (pct == null ? '依从率: —（无可比较的常吃药）' : '依从率: $pct%');

  // ============== v0.23 round 39 (P1-9 fix): 数据导入摘要 ==============
  // data_export_service ImportResult.summary 之前 7 处 hardcode 中文,
  // 改成本类的 i18n 化函数 (`static String xxx({String? override})`,
  // 无 const 字段 — 这 6 项都是参数化函数, 不需要 const 缓存), 给后续
  // i18n 留入口。
  // v0.26 R57: 加 override 参数 (callers 可传 l10n 拿多语言, fallback
  // 仍是本类的中文)。
  // v0.27 round 63 (P1-8 修复): 注释与代码同步 — 这 6 项是函数, 没 const
  // 字段; 跟上面的 channel / daily / snooze 模式 (const + 函数 pair) 不同。

  static String importSummaryContact(int n, {String? override}) =>
      override ?? '$n 联系人';
  static String importSummaryMedication(int n, {String? override}) =>
      override ?? '$n 药';
  static String importSummaryCheckIn(int n, {String? override}) =>
      override ?? '$n 打卡';
  static String importSummaryReport(int n, {String? override}) =>
      override ?? '$n 报告';
  static String importSummaryMood(int n, {String? override}) =>
      override ?? '$n 情绪';
  static String importSummaryVent(int n, {String? override}) =>
      override ?? '$n 树洞';

  // ============== 情绪标签（domain 层 fallback） =============
  // presentation 层应使用 AppLocalizations 的 moodLabelN 键
  // v0.26 R57: 加 override 参数 (整段替换场景)
  static String moodLabel(int score, {String? override}) {
    if (override != null) return override;
    return switch (score) {
      1 => '很差',
      2 => '差',
      3 => '一般',
      4 => '好',
      5 => '很好',
      _ => '一般',
    };
  }

  // ============== Snooze 通知文案 =============
  static const snoozeTitle = '💊 提醒吃药（snooze）';
  static const snoozeBody = '刚才您点了"稍后提醒"，该吃药了';
  static String snoozeTitleText({String? override}) => override ?? snoozeTitle;
  static String snoozeBodyText({String? override}) => override ?? snoozeBody;

  // ============== v0.27 round 62 (P1-8 修复): 用户名 fallback 集中 ==============
  // 之前 user_name_helper / email_template / reminder_scheduler /
  // safety_alert_dispatcher / notification_service 5+ 处 hardcode "您" /
  // "您的家人" / "用户" 中文字符串, 集中到本类: 3 个 const 字段 (中文
  // fallback, 老 caller 直接用) + 3 个 i18n 化函数 `*Text({String?
  // override})` (新 caller 传 l10n 拿多语言)。
  // 注: SMS / 邮件场景发的是中国紧急联系人, 中文是合理 fallback;
  //   en 模式 UI 显示走 AppLocalizations (override 模式)。
  // v0.27 round 63 (P1-8 修复): 注释与代码同步 — 删上面"override 模式"
  // 笼统说法, 明确 override 只适用 `*Text` 函数, const 字段无 override
  // (本身就是常量, 不可注入)。
  static const userNameDefault = '用户';
  static const userNamePolite = '您';
  static const userNameFamily = '您的家人';
  static String userNameDefaultText({String? override}) =>
      override ?? userNameDefault;
  static String userNamePoliteText({String? override}) =>
      override ?? userNamePolite;
  static String userNameFamilyText({String? override}) =>
      override ?? userNameFamily;
}
