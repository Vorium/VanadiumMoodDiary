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
      buffer.writeln('🕐 ${Strings.emailLastMed(_formatDateTime(lastCheckIn))}');
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

  /// HTML 版本
  static String buildHtml({
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
    required int cycleHours,
  }) {
    final lastMedHtml = lastCheckIn != null
        ? '''
        <tr>
          <td style="padding: 8px 0; color: #666; font-size: 14px;">🕐 最后吃药</td>
          <td style="padding: 8px 0; color: #1a1a1a; font-size: 14px; text-align: right;">${_formatDateTime(lastCheckIn)}</td>
        </tr>'''
        : '';

    final medicationHtml = medication != null
        ? '''
        <tr>
          <td style="padding: 8px 0; color: #666; font-size: 14px;">💊 常吃药</td>
          <td style="padding: 8px 0; color: #1a1a1a; font-size: 14px; text-align: right;">${Strings.emailMedInfo(medication.name, medication.dosage, medication.dosageUnit)}</td>
        </tr>'''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', 'PingFang SC', 'Microsoft YaHei', sans-serif; background: #fafafa; padding: 24px; margin: 0;">
  <div style="max-width: 480px; margin: 0 auto; background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.08);">
    <div style="text-align: center; padding: 40px 24px 24px; border-bottom: 1px solid #f0f0f0;">
      <div style="font-size: 32px; margin-bottom: 8px;">🌱</div>
      <div style="font-size: 20px; font-weight: 600; color: #1a1a1a;">慢病管家 · 停药提醒</div>
    </div>
    <div style="padding: 32px 24px; color: #1a1a1a; font-size: 16px; line-height: 1.6;">
      <p style="margin: 0 0 24px 0;">你好，</p>
      <p style="margin: 0 0 24px 0;">我是 $userName。我已经 $daysWithoutCheckIn 天没在 App 里打卡了。请你方便的时候<strong>提醒我按时吃药</strong>，避免复发。</p>
      <div style="background: #f8f8f8; border-radius: 12px; padding: 16px 20px; margin: 24px 0;">
        <table style="width: 100%; border-collapse: collapse;">
          $lastMedHtml
          $medicationHtml
          <tr>
            <td style="padding: 8px 0; color: #666; font-size: 14px;">📅 签到周期</td>
            <td style="padding: 8px 0; color: #1a1a1a; font-size: 14px; text-align: right;">$cycleHours 小时</td>
          </tr>
        </table>
      </div>
    </div>
    <div style="padding: 24px; border-top: 1px solid #f0f0f0; color: #999; font-size: 12px; line-height: 1.5;">
      <p style="margin: 0 0 4px 0;">这是一条自动通知，由慢病管家 App 发送。</p>
      <p style="margin: 0 0 4px 0;">本通知不包含任何医疗建议。</p>
      <p style="margin: 0;">如需停止接收，请在 App 设置中修改。</p>
    </div>
  </div>
</body>
</html>
''';
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
