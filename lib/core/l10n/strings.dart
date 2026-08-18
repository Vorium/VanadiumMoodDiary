import 'package:chroniccare/domain/entities/dosage_unit.dart';

/// 国际化字符串 — domain 层专用 fallback
///
/// v0.17 round 14 (P1-6): presentation 文字迁到 flutter_localizations
/// (`lib/l10n/app_zh.arb` / `app_en.arb`)。
/// 但 domain 层不能 import flutter,所以通知模板仍用
/// 这里 hardcode 字符串。
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
/// 1.1.0 round 4b (emotion-first refactor): email* 段 (停药提醒邮件模板)
/// 随 EmailService 整摘, careCopy* 段随 care_copy.dart 整摘,
/// importSummaryContact 随导出 contacts 段整摘, notifChannelSafety*
/// 随 showSafetyAlert 整摘, userNameFamily 随失联 SMS/邮件模板整摘。
class Strings {
  Strings._();

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

  // 每日打卡提醒 (20:00) — const 保留 (medication_notifier 用 const Strings.notifDailyCheckInTitle)
  static const notifDailyCheckInTitle = '🌱 今天吃了药吗？';
  // v0.27 R72 (spzh R66 P0-4 续): 中性化, 不提 '家人' (避免病耻感)
  // 原: '点一下 = 打卡，让家人放心'
  static const notifDailyCheckInBody = '点一下 = 打卡，留个今天的踏实';
  static String notifDailyCheckInTitleText({String? override}) =>
      override ?? notifDailyCheckInTitle;
  static String notifDailyCheckInBodyText({String? override}) =>
      override ?? notifDailyCheckInBody;

  // 用药提醒 (按 medication 单独排) — v0.26 R57: 加 override 参数
  //
  // v0.30 R108 (P0#3): 锁屏 body 暴露药名 + 剂量 = 隐私泄漏 (PIPL §6 PII 最小化)
  // 修前: notifMedicationBody(2.5, mg) → "2.5mg · 点一下 = 打卡" — 锁屏可见
  //   任何旁人 (同事 / 家人 / 公共交通) 都看到用户吃的药 + 剂量, 暴露
  //   精神心理 / 慢性病身份, 触发病耻感 + 隐私侵犯。
  // 修后: body 改通用文案 ("该吃药了 · 点一下打卡"), 不再含 dosage / unit。
  //   药名只在 title (💊 该吃药了：<name>) 出现 — 用户主动解锁后才看 title。
  //   实际: iOS 通知 title 在锁屏横幅也显示, 药名仍可见 — 进一步修法
  //   见 v1.0+ (用户可配置 title 是否脱敏, 跟锁屏可见性独立)。
  static String notifMedicationTitle({String? override}) =>
      override ?? '💊 该吃药了';
  // R108 P0-3: body 改常量 (无 dosage / unit 入参), 锁屏不暴露药名
  // 保留 [override] 参数支持 i18n (presentation 层可注入 l10n override)
  static String notifMedicationBody({String? override}) =>
      override ?? '该吃药了 · 点一下 = 打卡';

  /// R108 P0-3: 保留旧版函数 (deprecated) 用于历史调用方 / 测试
  ///
  /// 签名跟新版不同 (有 dosage / unit 参数), 但**返回脱敏后的固定文案**,
  /// 不再返回含 dosage 的字符串。这样老的 caller (medication_notifier
  /// 历史 / 第三方 plugin) 不会因签名变更 crash, 同时新行为安全。
  ///
  /// 后续 R109+ 全面移除: 把所有 caller 改用 [notifMedicationBody] 无参版。
  @Deprecated('R108 P0-3: 改用 notifMedicationBody() 无参版 — 锁屏 body '
      '不再暴露 dosage / unit, 避免 PII 泄漏')
  static String notifMedicationBodyLegacy(
    double dosage,
    DosageUnit unit, {
    String? override,
  }) =>
      override ?? '该吃药了 · 点一下 = 打卡';

  // 续方提醒 — v0.26 R57: 加 override 参数
  static String notifRefillTitle({String? override}) => override ?? '💊 该续方了';
  static String notifRefillBody(int daysLeft, {String? override}) =>
      override ?? '还剩约 $daysLeft 天断药，记得去医院或线上开药';

  // 心理评估提醒 — v0.26 R57: 加 override 参数
  static String notifAssessmentTitle({String? override}) =>
      override ?? '🌿 心理评估时间到';

  /// R113 (BUG 8): body 不再含量表名 (scale id) — 修前
  /// "已经 X 天没做 PHQ9 了" 的 PHQ9 是精神健康量表名, iOS 锁屏横幅
  /// 可见 = 健康 PII (病耻感 + 隐私侵犯)。修后通用文案, 不点名任何量表。
  /// 同步删掉 scale id 参数 (签名不收 PII 数据 = 编译期防泄漏,
  /// 跟 R108 P0-3 notifMedicationBody 同款模式)。
  static String notifAssessmentBody(int days, {String? override}) =>
      override ?? '已经 $days 天没做心理评估了，花 2 分钟完成一次';

  // 情绪记录提醒 — v0.30 R101: 参照 MedicationNotifier 模式
  static const notifMoodReminderTitle = '🌿 今天心情怎么样？';
  static const notifMoodReminderBody = '花 1 分钟记录一下，帮自己更好地了解情绪';
  static String notifMoodReminderTitleText({String? override}) =>
      override ?? notifMoodReminderTitle;
  static String notifMoodReminderBodyText({String? override}) =>
      override ?? notifMoodReminderBody;

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
  static const pdfTitle = 'MoodDiary 心情日记 · 用药报告';
  static const pdfAuthor = 'MoodDiary 心情日记';
  static String pdfTitleText({String? override}) => override ?? pdfTitle;
  static String pdfAuthorText({String? override}) => override ?? pdfAuthor;
  static String pdfSubject(int days, {String? override}) =>
      override ?? '$days 天用药情况';
  static String pdfRecentDays(int days, {String? override}) =>
      override ?? '近 $days 天';
  static const pdfFooterNotice = '本报告由「MoodDiary 心情日记」自动生成 · 本应用不提供医疗建议';
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

  // ============== v0.31 P1-5: 评估对比 (assessment_comparison.dart) i18n ==============
  static String assessmentComparisonImproved({String? override}) =>
      override ?? '好转';
  static String assessmentComparisonWorsened({String? override}) =>
      override ?? '恶化';
  static String assessmentComparisonUnchanged({String? override}) =>
      override ?? '持平';
  static String assessmentComparisonFirst({String? override}) =>
      override ?? '首次评估';
  static String assessmentDeltaSame(int delta, {String? override}) =>
      override ?? '和上次一样（$delta）';
  static String assessmentDeltaHigher(int delta, {String? override}) =>
      override ?? '比上次高 $delta 分';
  static String assessmentDeltaLower(int delta, {String? override}) =>
      override ?? '比上次低 $delta 分';
  static String assessmentSeverityRank(int rank, {String? override}) =>
      override ?? '等级 $rank';

  // ============== v0.31 P1-5: 打卡类型 (check_in_entity.dart) i18n ==============
  static String checkInTypeAssessment({String? override}) =>
      override ?? '心理量表评估';

  // ============== v0.31 P1-5: 日历详情 (day_detail.dart) i18n ==============
  static String dayDetailTotalScore(int total, {String? override}) =>
      override ?? '总分 $total';
  static String dayDetailScaleAssessment({String? override}) =>
      override ?? '心理量表评估';
}
