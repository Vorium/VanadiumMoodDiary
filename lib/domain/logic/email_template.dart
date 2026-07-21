import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/user_name_helper.dart';
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
  static String buildSubject({
    String? userName,
    required int daysWithoutCheckIn,
  }) {
    final name = safeUserName(userName, fallback: '您的家人');
    return Strings.emailSubject(name, daysWithoutCheckIn);
  }

  /// 正文
  static String buildBody({
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
    required int cycleHours,
  }) {
    final buffer = StringBuffer();

    final name = safeUserName(userName, fallback: '您的家人');
    buffer.writeln(Strings.emailBody(name, daysWithoutCheckIn));
    buffer.writeln();

    buffer.writeln('┌─────────────────────────────────┐');

    if (lastCheckIn != null) {
      buffer
          .writeln('🕐 ${Strings.emailLastMed(_formatDateTime(lastCheckIn))}');
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
    buffer.writeln(Strings.emailFooter);

    return buffer.toString();
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
