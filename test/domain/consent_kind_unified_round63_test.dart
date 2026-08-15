// v0.27 round 63 (P0-3 修复): ConsentKind 双 enum 统一测试
//
// 修复前 domain / presentation 各有同名不同值的 enum (domain: emergencyContactSharing
// / dataExport; presentation: safety / vent / analytics)。同 source 走 2 路导致
// 类型推断踩雷风险。
//
// 修复后 domain 是 single source of truth, 5 值统一在一处, presentation 通过
// re-export (legal_consent_provider.dart) 拿到。
//
// 1.1.0 round 4b (emotion-first refactor): emergencyContactSharing / safety
// 2 值整摘 (外联通信业务删除定版), 剩 3 值 (dataExport / vent / analytics)。
//
// 本测试:
// 1. 验证 enum 3 值存在 + name 正确
// 2. 验证 domain / presentation re-export 同 identity (避免 2 个 enum 同时存在)
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';

void main() {
  group('ConsentKind 统一 (P0-3)', () {
    test('enum 3 值 name 正确 (round 4b: 外联 2 值已摘)', () {
      expect(
        ConsentKind.values.length,
        3,
        reason: '应包含 dataExport + vent + analytics '
            '(emergencyContactSharing / safety 已随外联服务整摘)',
      );
      expect(ConsentKind.values.map((k) => k.name).toList(), [
        'dataExport',
        'vent',
        'analytics',
      ]);
    });

    test('domain import 与 presentation re-export 同一 identity', () {
      // re-export 让老 caller 不用改 import, 但 runtime identity 必须一致 —
      // 否则存 SharedPreferences 的 `kind.name` 反序列化时类型不匹配会丢数据。
      expect(ConsentKind.vent.name, 'vent');
      expect(ConsentKind.analytics.name, 'analytics');
      expect(ConsentKind.dataExport.name, 'dataExport');
    });

    test('PIPL §13 强场景 (dataExport) 在 enum 内', () {
      // export_tile 的 ConsentDialog.dataExport 路径强制传这 kind,
      // enum 缺值会让数据导出同意流程编译失败。
      expect(ConsentKind.values, contains(ConsentKind.dataExport));
    });

    test('PIPL §14 撤回场景 (vent/analytics) 在 enum 内', () {
      // legal_page 2 toggle 用这些 kind, 缺值会让法律与隐私页编译失败。
      expect(ConsentKind.values, contains(ConsentKind.vent));
      expect(ConsentKind.values, contains(ConsentKind.analytics));
    });
  });
}
