// v0.32 R109 round 6 part 2: 失联告警测试 helper 集中器
//
// 把 R108 跨期散落到 `feature_flags_round66_test.dart` / `safety_watch_service_round12_test.dart`
// 重复定义的 `_CountingNotificationService` 抽到一处, 2 个 test 都 import,
// 避免 R109 改 `NotificationService.showSafetyAlert` 签名时两边都要同步
// (跨期 R108 helper 已被 R109 round 2 改 sender 接口打破, 现在 2 个 test
// 都缺 1 个能 track `showSafetyAlert` 调用的 NotifService mock).
//
// 设计:
// - `alertsShown`: 每次 `showSafetyAlert` 调记录 1 条 (record typedef, 跟
//   `SmsDispatchOutcome` 同款 shared record)
// - `showSafetyAlertCalls`: 调用次数计数
// - 不调父类 `showSafetyAlert` (避免 plugin 副作用 + `init()` timezone 报错),
//   只记录 + 返回
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';

/// R109 round 6 part 2: showSafetyAlert 调用的快照
typedef SafetyAlertCall = ({
  int daysWithoutCheckIn,
  DateTime? lastCheckIn,
  SmsDispatchOutcome outcome,
});

/// R109 round 6 part 2: 跟踪 showSafetyAlert 调用的 mock NotifService
///
/// 替代 R108 跨期 helper (R109 round 2 改 `showSafetyAlert` 接受
/// `SafetyAlertL10nResolver` 后, 旧 helper 签名失效).
///
/// v0.32 R112 (R112-09): userName 死参数删后同步 (body 0 引用).
class CountingNotificationService extends NotificationService {
  final List<SafetyAlertCall> alertsShown = [];
  int showSafetyAlertCalls = 0;

  CountingNotificationService() : super(onNotificationTap: (_) {});

  @override
  Future<void> showSafetyAlert({
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required SmsDispatchOutcome outcome,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    showSafetyAlertCalls++;
    alertsShown.add((
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      outcome: outcome,
    ),);
  }
}
