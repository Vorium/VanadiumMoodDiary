import 'package:chroniccare/core/data/services/pii_safe_log.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/email_template.dart';

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
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您的家人",保持邮件/短信语法自然
  Future<bool> sendMedicationReminder({
    required String to,
    String? userName,
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
      piiSafeLog('EmailService', '=' * 60);
      piiSafeLog('EmailService', '📱 [MOCK] 发送失联通知');
      piiSafeLog('EmailService', '  To (phone): ${maskPhone(to)}');
      piiSafeLog('EmailService', '  Subject: $subject');
      piiSafeLog('EmailService', '  ---');
      piiSafeLog('EmailService', body);
      piiSafeLog('EmailService', '=' * 60);
      return true;
    }

    // 真实 SMS provider 占位——v1.0+ 替换
    // 注：v1.0 接入真实 SDK 时，try/catch 应包住实际网络调用（参考 AliyunSmsProvider）
    piiSafeLog('EmailService', '真实 SMS 发送未实现（v1.0+ TODO）');
    return false;
  }
}
