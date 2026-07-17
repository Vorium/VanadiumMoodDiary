import '../../l10n/strings.dart';
import '../entities/medication_entity.dart';

/// 通知文案模板生成器
///
/// v0.6：从邮件改 mock 短信，文案保持温柔、主动、可操作。
///
/// v0.16：参数 Medication (drift row) → MedicationEntity (domain entity)，
/// domain 层不再 import data 层。
class EmailTemplate {
  EmailTemplate._();

  /// 主题
  static String buildSubject({
    required String userName,
    required int daysWithoutCheckIn,
  }) {
    return Strings.emailSubject(userName, daysWithoutCheckIn);
  }

  /// 正文
  static String buildBody({
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
    required int cycleHours,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(Strings.emailBody(userName, daysWithoutCheckIn));
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
