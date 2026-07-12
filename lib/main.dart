import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/services/notification_service.dart';

/// 慢病管家 · App 入口
///
/// 启动顺序：
/// 1. 加载 .env（缺失不阻断，走代码默认值）
/// 2. 初始化通知服务（申请权限 + 设每日 20:00 提醒）
/// 3. 启动 Riverpod + GoRouter
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 加载 .env（缺失时静默跳过，EmailService 默认走 mock）
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env 加载失败（首次启动正常）：$e');
  }

  // 2. 初始化通知服务
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.scheduleDailyReminder(hour: 20, minute: 0);

  // 3. 启动 App
  runApp(
    const ProviderScope(
      child: AppRoot(),
    ),
  );
}
