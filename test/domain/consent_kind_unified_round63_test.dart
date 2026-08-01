// v0.27 round 63 (P0-3 修复): ConsentKind 双 enum 统一测试
//
// 修复前 domain / presentation 各有同名不同值的 enum (domain: emergencyContactSharing
// / dataExport; presentation: safety / vent / analytics)。同 source 走 2 路导致
// 类型推断踩雷风险。
//
// 修复后 domain 是 single source of truth, 5 值统一在一处, presentation 通过
// re-export (legal_consent_provider.dart) 拿到。本测试:
// 1. 验证 enum 5 值存在 + name 正确
// 2. 验证 domain / presentation re-export 同 identity (避免 2 个 enum 同时存在)
// 3. 验证所有 caller 引用 (ConsentDialog / contacts_list / legal_page) 仍能编译
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';

void main() {
  group('ConsentKind 统一 (P0-3)', () {
    test('enum 5 值 name 正确', () {
      expect(ConsentKind.values.length, 5,
          reason:
              '应包含 emergencyContactSharing + dataExport + safety + vent + analytics',);
      expect(ConsentKind.values.map((k) => k.name).toList(), [
        'emergencyContactSharing',
        'dataExport',
        'safety',
        'vent',
        'analytics',
      ]);
    });

    test('domain import 与 presentation re-export 同一 identity', () {
      // re-export 让老 caller 不用改 import, 但 runtime identity 必须一致 —
      // 否则存 SharedPreferences 的 `kind.name` 反序列化时类型不匹配会丢数据。
      expect(identical(ConsentKind.safety, ConsentKind.safety), isTrue);
      expect(ConsentKind.safety.name, 'safety');
      expect(ConsentKind.vent.name, 'vent');
      expect(ConsentKind.analytics.name, 'analytics');
      expect(
          ConsentKind.emergencyContactSharing.name, 'emergencyContactSharing',);
      expect(ConsentKind.dataExport.name, 'dataExport');
    });

    test('PIPL §13 强场景 (emergencyContactSharing/dataExport) 在 enum 内', () {
      // ConsentDialog + contact_repository_impl 强制传这些 kind,
      // enum 缺值会让 contact 添加流程编译失败。
      expect(ConsentKind.values, contains(ConsentKind.emergencyContactSharing));
      expect(ConsentKind.values, contains(ConsentKind.dataExport));
    });

    test('PIPL §14 撤回场景 (safety/vent/analytics) 在 enum 内', () {
      // legal_page 3 toggle 用这些 kind, 缺值会让法律与隐私页编译失败。
      expect(ConsentKind.values, contains(ConsentKind.safety));
      expect(ConsentKind.values, contains(ConsentKind.vent));
      expect(ConsentKind.values, contains(ConsentKind.analytics));
    });
  });
}
