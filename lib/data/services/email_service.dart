import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../data/database/app_database.dart';
import '../../domain/logic/email_template.dart';

/// 邮件发送服务
///
/// MVP 阶段：Mock 实现，只打印日志
/// v1.0+：接入 SendGrid API
class EmailService {
  final Dio _dio;
  final String? _apiKey;
  final String _fromEmail;
  final String _fromName;
  final bool _useMock;

  EmailService({
    Dio? dio,
    String? apiKey,
    String fromEmail = 'noreply@chroniccare.app',
    String fromName = '慢病管家',
    bool useMock = true,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey,
        _fromEmail = fromEmail,
        _fromName = fromName,
        _useMock = useMock;

  /// 发送停药通知
  Future<bool> sendMedicationReminder({
    required String to,
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required Medication? medication,
    required int cycleHours,
  }) async {
    final subject = EmailTemplate.buildSubject(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
    );

    final body = EmailTemplate.buildBody(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      medication: medication,
      cycleHours: cycleHours,
    );

    final html = EmailTemplate.buildHtml(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      medication: medication,
      cycleHours: cycleHours,
    );

    if (_useMock || _apiKey == null) {
      developer.log('=' * 60, name: 'EmailService');
      developer.log('📧 [MOCK] 发送邮件', name: 'EmailService');
      developer.log('  To: $to', name: 'EmailService');
      developer.log('  Subject: $subject', name: 'EmailService');
      developer.log('  ---', name: 'EmailService');
      developer.log(body, name: 'EmailService');
      developer.log('=' * 60, name: 'EmailService');
      return true;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.sendgrid.com/v3/mail/send',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'personalizations': [
            {
              'to': [{'email': to}],
            }
          ],
          'from': {'email': _fromEmail, 'name': _fromName},
          'subject': subject,
          'content': [
            {'type': 'text/plain', 'value': body},
            {'type': 'text/html', 'value': html},
          ],
        },
      );

      return response.statusCode == 202;
    } catch (e) {
      developer.log('❌ 发送邮件失败: $e', name: 'EmailService');
      return false;
    }
  }
}
