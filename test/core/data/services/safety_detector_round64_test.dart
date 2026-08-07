// v0.27 round 64 (spen P1-12 god class 拆分收尾): SafetyDetector 纯函数 test
//
// SafetyDetector 是纯函数, 0 副作用 (不调 sub-service / DB / SharedPreferences),
// 全部 inputs 由 caller 注入。test 目标:
// 1. 7 段 early-return 决策全覆盖 (边界 + 异常)
// 2. deterministic — 相同 inputs 永远返相同 outputs
// 3. 0 副作用 — 没有任何外部状态变更
//
// 测试设计:
// - 不需要 mock (纯函数, 无依赖)
// - 0 Flutter widget / Drift / SharedPreferences 依赖 → test 极快
// - 用固定 DateTime 避免 `DateTime.now()` race
//
// v0.29 R85: SafetyDetector 已从 lib/core/data/services/ 挪到
// lib/domain/logic/safety_detector.dart, 本测试改 import 新路径。
// 测试内容不变 (SafetyDetector.detect API 1:1 兼容)。
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/safety_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 固定时间锚点, 避免跨 midnight flake (v0.16 R19B 立的规矩)
  final fixedNow = DateTime(2026, 7, 17, 10, 0);

  // 构造器辅助 — 减少每个 test 的 boilerplate
  ContactEntity mkContact({
    int id = 1,
    String name = '妈妈',
    String phone = '13800138000',
  }) =>
      ContactEntity(id: id, name: name, phone: phone);

  UserProfileEntity mkProfile({String? name = '张三'}) => UserProfileEntity(
        id: 1,
        userName: name,
        checkInCycleHours: 48,
        firstLaunchAt: DateTime(2026, 1, 1),
      );

  // 通用 "alert 触发" inputs (lastCheckIn=3d ago, threshold=2, all gates open)
  Map<String, dynamic> mkAlertInputs({DateTime? now}) => {
        'enabled': true,
        'threshold': 2,
        'lastCheckInAt': (now ?? fixedNow).subtract(const Duration(days: 3)),
        'now': now ?? fixedNow,
        'lastAlertAt': null,
        'inDnd': false,
        'profile': mkProfile(),
        'contacts': <ContactEntity>[mkContact()],
      };

  group('SafetyDetector.detect — 7 段 early-return 全覆盖', () {
    test('enabled=false → Disabled (R64 leaf 1/8)', () {
      final result = SafetyDetector.detect(
        enabled: false,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: mkProfile(),
        contacts: [mkContact()],
      );
      expect(result, isA<SafetyDecisionDisabled>());
      expect(result.daysSinceLast, isNull);
    });

    test('lastCheckInAt=null → NoData (新用户, R64 leaf 3/8)', () {
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: null,
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: mkProfile(),
        contacts: const [],
      );
      expect(result, isA<SafetyDecisionNoData>());
      expect(result.daysSinceLast, isNull);
    });

    test('daysSinceLast < threshold → Ok (R64 leaf 2/8)', () {
      // lastCheckIn = 1h ago, threshold = 2 → daysSinceLast = 0
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(hours: 1)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: mkProfile(),
        contacts: const [],
      );
      expect(result, isA<SafetyDecisionOk>());
      expect((result as SafetyDecisionOk).daysSinceLast, 0);
    });

    test(
        'daysSinceLast >= threshold + lastAlertAt same day → AlertedToday (R64 leaf 4/8)',
        () {
      // lastAlertAt = 今天 (跟 fixedNow 同一天)
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: fixedNow.subtract(const Duration(hours: 2)),
        inDnd: false,
        profile: mkProfile(),
        contacts: [mkContact()],
      );
      expect(result, isA<SafetyDecisionAlertedToday>());
      expect((result as SafetyDecisionAlertedToday).daysSinceLast, 3);
    });

    test(
        'daysSinceLast >= threshold + inDnd=true → DndSuppressed (R64 leaf 5/8)',
        () {
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: true,
        profile: mkProfile(),
        contacts: [mkContact()],
      );
      expect(result, isA<SafetyDecisionDndSuppressed>());
      expect((result as SafetyDecisionDndSuppressed).daysSinceLast, 3);
    });

    test('profile=null (lastCheckIn 有但没档案) → NoData (R64 leaf 3/8, 第 2 路径)',
        () {
      // 注意: lastCheckInAt 有值, enabled=true, 但 profile=null
      // 原 facade 现状也是返 noData (跟"新用户"合并)
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: null,
        contacts: [mkContact()],
      );
      expect(result, isA<SafetyDecisionNoData>());
      expect(result.daysSinceLast, isNull);
    });

    test('contacts=[] (含 stream timeout 降级) → NoContacts (R64 leaf 6/8)', () {
      // 模拟 _loadContacts() 返空列表 (timeout / 异常 / 真没联系人)
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: mkProfile(),
        contacts: const [],
      );
      expect(result, isA<SafetyDecisionNoContacts>());
      expect((result as SafetyDecisionNoContacts).daysSinceLast, 3);
    });

    test('all gates pass → Alert (R64 leaf 7/8, 真触发 — facade 委派 dispatcher)',
        () {
      final result = SafetyDetector.detect(
        enabled: true,
        threshold: 2,
        lastCheckInAt: fixedNow.subtract(const Duration(days: 3)),
        now: fixedNow,
        lastAlertAt: null,
        inDnd: false,
        profile: mkProfile(),
        contacts: [mkContact()],
      );
      expect(result, isA<SafetyDecisionAlert>());
      expect((result as SafetyDecisionAlert).daysSinceLast, 3);
    });
  });

  group('SafetyDetector.detect — 阈值边界 (R17 P3-3 inclusive)', () {
    test('threshold=1, daysSinceLast=1 → Alert (>= 触发) — 包含边界 (R17 P3-3 修正)',
        () {
      // 24h ago 跨 midnight 之后恰好 1 天
      // 同一 inputs 第二次跑必须返 equals (deterministic), 验证纯函数
      SafetyDecision input1() => SafetyDetector.detect(
            enabled: true,
            threshold: 1,
            lastCheckInAt: fixedNow.subtract(const Duration(hours: 24)),
            now: fixedNow,
            lastAlertAt: null,
            inDnd: false,
            profile: mkProfile(),
            contacts: [mkContact()],
          );
      final r1 = input1();
      final r2 = input1();
      expect(r1, isA<SafetyDecisionAlert>());
      expect((r1 as SafetyDecisionAlert).daysSinceLast, 1);
      // deterministic: 同 inputs 必同 result
      expect(r1, equals(r2));
    });
  });

  group('SafetyDetector.detect — 纯函数特性 (deterministic + 0 副作用)', () {
    test('同 inputs 跑 2 次 → equals, 调 100 次不改 inputs (防 .add() / 写字段)', () {
      // 1. 验 deterministic — 同 inputs 必同 result (==)
      final inputs1 = mkAlertInputs();
      final inputs2 = mkAlertInputs();
      final r1 = SafetyDetector.detect(
        enabled: inputs1['enabled'] as bool,
        threshold: inputs1['threshold'] as int,
        lastCheckInAt: inputs1['lastCheckInAt'] as DateTime,
        now: inputs1['now'] as DateTime,
        lastAlertAt: inputs1['lastAlertAt'] as DateTime?,
        inDnd: inputs1['inDnd'] as bool,
        profile: inputs1['profile'] as UserProfileEntity?,
        contacts: inputs1['contacts'] as List<ContactEntity>,
      );
      final r2 = SafetyDetector.detect(
        enabled: inputs2['enabled'] as bool,
        threshold: inputs2['threshold'] as int,
        lastCheckInAt: inputs2['lastCheckInAt'] as DateTime,
        now: inputs2['now'] as DateTime,
        lastAlertAt: inputs2['lastAlertAt'] as DateTime?,
        inDnd: inputs2['inDnd'] as bool,
        profile: inputs2['profile'] as UserProfileEntity?,
        contacts: inputs2['contacts'] as List<ContactEntity>,
      );
      expect(r1, equals(r2));
      expect(r1, isA<SafetyDecisionAlert>());

      // 2. 验 0 副作用 — 调 100 次不修改 list 长度 / profile 字段
      final contacts = <ContactEntity>[mkContact()];
      final profile = mkProfile();
      final lastCheckInAt = fixedNow.subtract(const Duration(days: 3));
      for (int i = 0; i < 100; i++) {
        SafetyDetector.detect(
          enabled: true,
          threshold: 2,
          lastCheckInAt: lastCheckInAt,
          now: fixedNow,
          lastAlertAt: null,
          inDnd: false,
          profile: profile,
          contacts: contacts,
        );
      }
      expect(contacts, hasLength(1), reason: 'detector 不应改 contacts 列表');
      expect(profile.userName, '张三', reason: 'detector 不应改 profile 字段');
    });
  });
}
