// 一次性脚本：测试 10 个邮箱的送达率
// 用法：dart run scripts/test_delivery_rate.dart
//
// ⚠️ 使用前请：
// 1. 复制 .env.example 为 .env
// 2. 填入真实 SendGrid API Key
// 3. 修改下面的 TEST_EMAILS 列表

// ignore_for_file: avoid_print

import 'package:chroniccare/data/services/email_service.dart';
import 'package:chroniccare/data/database/app_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const testEmails = <String>[
  'your-own-email@gmail.com',
  'friend1@example.com',
  // 至少 10 个，混合 Gmail / QQ / 163 / Outlook / 企业邮箱
];

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  final apiKey = dotenv.env['SENDGRID_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ 请先在 .env 填入 SENDGRID_API_KEY');
    return;
  }

  final service = EmailService(
    dio: Dio(),
    apiKey: apiKey,
    fromEmail: dotenv.env['SENDGRID_FROM_EMAIL'] ?? 'noreply@chroniccare.app',
    fromName: dotenv.env['SENDGRID_FROM_NAME'] ?? '慢病管家',
    useMock: false,
  );

  print('🚀 开始送达率测试（${testEmails.length} 个邮箱）');
  print('=' * 60);

  int success = 0;
  for (var i = 0; i < testEmails.length; i++) {
    final email = testEmails[i];
    print('[$i/${testEmails.length}] $email ... ');

    try {
      final ok = await service.sendMedicationReminder(
        to: email,
        userName: '测试用户',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime.now().subtract(const Duration(days: 2)),
        medication: Medication(
          id: 0,
          name: '舍曲林',
          frequencyPerDay: 1,
          timesJson: '[]',
          startDate: DateTime.now(),
          endDate: null,
          isActive: true,
        ),
        cycleHours: 48,
      );

      if (ok) {
        print('✅');
        success++;
      } else {
        print('❌');
      }
    } catch (e) {
      print('❌ ($e)');
    }

    await Future<void>.delayed(const Duration(seconds: 1));
  }

  print('=' * 60);
  print('结果：$success / ${testEmails.length} 成功');
  if (success < testEmails.length * 0.95) {
    print('⚠️ 送达率 < 95%，请检查 SendGrid 配置');
  } else {
    print('🎉 送达率 ≥ 95%，配置成功');
  }
}
