import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/logic/user_name_helper.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// 通知文案模板生成器
///
/// v0.6：从邮件改 mock 短信，文案保持温柔、主动、可操作。
///
/// v0.16：参数 Medication (drift row) → MedicationEntity (domain entity)，
/// domain 层不再 import data 层。
class EmailTemplate {
  EmailTemplate._();

  /// 主题
  ///
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您的家人",保持邮件/短信语法自然
  ///
  /// v0.24 round 48 (spzh P0-5 fix): 加可选 `subjectOverride` 参数,
  /// presentation caller 传 AppLocalizations 拿 i18n 字符串(海外用户看英文)。
  /// 缺省用 Strings.emailSubject fallback(domain 层兼容)。
  static String buildSubject({
    String? userName,
    required int daysWithoutCheckIn,
    String? subjectOverride,
  }) {
    if (subjectOverride != null) return subjectOverride;
    final name = safeUserName(userName, fallback: Strings.userNameFamily);
    return Strings.emailSubject(name, daysWithoutCheckIn);
  }

  /// 正文
  ///
  /// [referenceNow] 可选 — 用于推断 caller 所在时区（PIPL §17 数据准确性）。
  /// v0.24 round 48 (spen P0-4 fix): 之前 `_formatDateTime` 硬编码 "UTC+8 北京时间"
  /// 在海外紧急联系人收到邮件时显示错误时区（→ "未来时间已发生" 误读）。
  /// 现在用 referenceNow.timeZoneOffset 推断 caller 视角的时区。
  /// 缺省时用 `DateTime.now()` 兜底,但 caller 应传 `DateTime.now()` 一次避免 race。
  ///
  /// [bodyOverride] / [footerOverride] 可选 — v0.24 round 48 (spzh P0-5):
  /// presentation caller 传 AppLocalizations 拿 i18n 字符串(海外用户看英文)。
  /// 缺省用 Strings.emailBody/emailFooter fallback(domain 层兼容)。
  static String buildBody({
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
    required int cycleHours,
    DateTime? referenceNow,
    String? bodyOverride,
    String? footerOverride,
  }) {
    final buffer = StringBuffer();

    final name = safeUserName(userName, fallback: Strings.userNameFamily);
    if (bodyOverride != null) {
      buffer.writeln(bodyOverride);
    } else {
      buffer.writeln(Strings.emailBody(name, daysWithoutCheckIn));
    }
    buffer.writeln();

    buffer.writeln('┌─────────────────────────────────┐');

    if (lastCheckIn != null) {
      buffer.writeln(
        '🕐 ${Strings.emailLastMed(_formatDateTime(lastCheckIn, referenceNow: referenceNow))}',
      );
    }

    if (medication != null) {
      buffer.writeln(
        '💊 ${Strings.emailMedInfo(medication.name, medication.dosage, medication.dosageUnit)}',
      );
    }

    buffer.writeln('📅 ${Strings.emailCycle(cycleHours)}');
    buffer.writeln('└─────────────────────────────────┘');
    buffer.writeln();

    buffer.writeln('─────────────────────────────');
    if (footerOverride != null) {
      buffer.writeln(footerOverride);
    } else {
      buffer.writeln(Strings.emailFooter);
    }

    return buffer.toString();
  }

  static String _formatDateTime(DateTime dt, {DateTime? referenceNow}) {
    // v0.24 round 48 (spen P0-4 fix):
    // PIPL §17 数据准确性 + 海外紧急联系人看到正确时区
    // 之前 v0.23 round 39 硬编码 "(UTC+8 北京时间)" 是 bug:
    //   - 海外紧急联系人看到错误时区,会误读"未来时间已发生"
    //   - 跨时区失联通知无意义
    // 现在用 referenceNow.timeZoneOffset 推断 caller 视角的时区
    //   - 缺省 DateTime.now() 兜底,但 caller 应传 referenceNow 一次避免 race
    final ref = referenceNow ?? DateTime.now();
    final offset = ref.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)} '
        '(UTC$sign$hours:$minutes)';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
