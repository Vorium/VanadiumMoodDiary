import 'dart:developer' as developer;

import '../../domain/entities/medication_entity.dart';
import '../../domain/logic/email_template.dart';

/// 失联通知服务
///
/// v0.6：联系人改 phone 后，"邮件发送" 改成 mock 短信。
/// - MVP 阶段：useMock=true 时只打印日志，不发真实消息
/// - v1.0+：接入真实 SMS provider（阿里云/腾讯云），`to` 字段语义改成手机号
///
/// v0.16 简化: 删除未用的 Dio 字段和未用的 html 变量。
/// v0.16 抽象: 参数 Medication (drift row) → MedicationEntity (domain entity)。
class EmailService {
  final String? _apiKey;
  final bool _useMock;

  EmailService({
    String? apiKey,
    bool useMock = true,
  })  : _apiKey = apiKey,
        _useMock = useMock;

  /// 发送失联通知（mock 阶段只打日志）
  ///
  /// [to] 现在是手机号（v0.6 之前是 email）
  Future<bool> sendMedicationReminder({
    required String to,
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required MedicationEntity? medication,
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

    if (_useMock || _apiKey == null) {
      developer.log('=' * 60, name: 'EmailService');
      developer.log('📱 [MOCK] 发送失联通知', name: 'EmailService');
      developer.log('  To (phone): $to', name: 'EmailService');
      developer.log('  Subject: $subject', name: 'EmailService');
      developer.log('  ---', name: 'EmailService');
      developer.log(body, name: 'EmailService');
      developer.log('=' * 60, name: 'EmailService');
      return true;
    }

    // 真实 SMS provider 占位——v1.0+ 替换
    // 注：v1.0 接入真实 SDK 时，try/catch 应包住实际网络调用（参考 AliyunSmsProvider）
    developer.log('真实 SMS 发送未实现（v1.0+ TODO）', name: 'EmailService');
    return false;
  }
}
