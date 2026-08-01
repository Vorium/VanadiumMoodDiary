import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/user_name_helper.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// v0.27 round 62 (P1-5 修复): 失联通知 SMS 模板单一 source
///
/// 修复前: 2 个并行 service (ReminderService._buildSmsBody +
/// SafetyAlertDispatcher.buildAlertSms) 各写一份 SMS 模板, 50% 重复 +
/// 措辞不一致 (dispatcher 走 "如确认安全请回复 1" 精神心理患者保护业务
/// 逻辑, reminder 走 "提醒 TA 按时吃药" 通用; 家属实际收到哪条取决于
/// trigger 路径, 体验割裂)。
///
/// 修复后: 1 个纯函数 `buildLostContactSms(...)` 集中 2 套模板,
/// caller 传 `kind` 选分支。
///
/// 设计原则:
/// 1. **Domain 层 0 flutter**: 不能 import AppLocalizations, 用 [Strings]
///    集中常量 + override 模式 (`caller 传 i18n 字符串`)
/// 2. **精神心理患者保护**: `kind == safetyAlert` 必须含 "如确认安全请回复 1"
///    业务逻辑 (PIPL §13 + 精神心理类 App 设计的非协商底线)
/// 3. **70 字限制**: 中文 70 字 / 条, 精简到一屏, 过长走 truncation
/// 4. **PII 最小化**: 不暴露 `medication.dosage` 等敏感字段给非用户本人
///    (PIPL §6)
enum LostContactSmsKind {
  /// 失联告警 (SafetyWatch 触发, 严肃场景)
  /// 必含 "如确认安全请回复 1" 业务逻辑
  safetyAlert,

  /// 通用提醒 (ReminderService 触发, 日常催办)
  /// 鼓励式 "请你方便的时候提醒对方按时吃药"
  // v0.27 R72 (spzh R66 P0-5 续): 改 "TA" 网络用语 → "对方" 中性化
  reminder,
}

/// 构造发给紧急联系人的失联 SMS
///
/// 参数:
/// - [kind] 选分支 (safetyAlert / reminder)
/// - [userName] 患者姓名, 可空 (空/纯空白走 [Strings.userNameFamily])
/// - [daysSince] 距上次打卡天数 (kind == reminder 时用作 "N 天没打卡")
/// - [hoursSince] 距上次打卡小时数 (kind == reminder + daysSince < 2 时用)
/// - [medication] 可选 — 常吃药信息 (kind == reminder 才有)
/// - [override] i18n override (presentation 传 AppLocalizations 拿翻译版)
///   不传走 [Strings] 集中常量 fallback (中文)
String buildLostContactSms({
  required LostContactSmsKind kind,
  String? userName,
  required int daysSince,
  required int hoursSince,
  MedicationEntity? medication,
  String? override,
}) {
  if (override != null) return override;

  final name = safeUserName(userName, fallback: Strings.userNameFamily);

  switch (kind) {
    case LostContactSmsKind.safetyAlert:
      // 失联告警 — 精神心理患者保护, 必须含 "如确认安全请回复 1"
      return '[慢病管家] $name 已 $daysSince 天未打卡吃药。'
          '如确认安全请回复 1，无回复请联系本人或社区。';
    case LostContactSmsKind.reminder:
      // 通用提醒 — 鼓励式, 措辞温和
      final buffer = StringBuffer();
      if (daysSince >= 2) {
        buffer.writeln('【慢病管家】$name 已 $daysSince 天没打卡。');
      } else {
        buffer.writeln('【慢病管家】$name 已 $hoursSince 小时没打卡。');
      }
      buffer.writeln('请你方便的时候提醒对方按时吃药。');
      if (medication != null) {
        buffer.writeln(
          '常吃药: ${medication.name} ${medication.dosage}${medication.dosageUnit.id}',
        );
      }
      return buffer.toString().trimRight();
  }
}
