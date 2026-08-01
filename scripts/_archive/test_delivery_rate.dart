// 一次性脚本：测试 SMS 通知的送达率（v0.6 mock 阶段只打日志）
// 用法：dart run scripts/test_delivery_rate.dart
//
// v0.6：联系人改 phone 字段，此脚本暂用 mock 模式跑。
// v1.0+ 接入真实 SMS provider 后再启用真实送达率测试。

// ignore_for_file: avoid_print

import 'package:chroniccare/core/data/services/email_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const testPhones = <String>[
  '13800138000',
  '13900139000',
  // 至少 10 个，混合不同号段
];

Future<void> main() async {
  await dotenv.load(fileName: '.env');

  final service = EmailService(
    apiKey: dotenv.env['SMS_API_KEY'],
    useMock: true, // v0.6 强制 mock
  );

  print('🚀 开始 mock 通知测试（${testPhones.length} 个手机号）');
  print('=' * 60);

  int success = 0;
  for (var i = 0; i < testPhones.length; i++) {
    final phone = testPhones[i];
    print('[$i/${testPhones.length}] $phone ... ');

    try {
      final ok = await service.sendMedicationReminder(
        to: phone,
        userName: '测试用户',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime.now().subtract(const Duration(days: 2)),
        medication: MedicationEntity(
          id: 0,
          name: '氟西汀',
          dosage: 40,
          dosageUnit: DosageUnit.mg,
          times: const [HourMinute(hour: 8, minute: 0)],
          startDate: DateTime.now(),
          endDate: null,
          isActive: true,
          refillAt: null,
          refillReminderDays: 7,
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
  print('结果：$success / ${testPhones.length} 成功（mock 模式始终返回 true）');
}
