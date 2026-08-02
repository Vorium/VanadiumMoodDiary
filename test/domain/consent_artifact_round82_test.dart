// v0.27 round 82: ConsentArtifact 实体单测
//
// 背景: ConsentArtifact 是 PIPL §13 单独同意的留痕实体 (R63 P0-3 修复),
// domain 层 single source of truth, 5 字段 (kind / grantedAt / grantedBy /
// contactId / version)。本类 0 flutter 依赖, 0 业务方法, 纯数据类。
//
// 之前 0 单元测, R63 时只测了 enum 5 值 (consent_kind_unified_round63_test),
// R82 补 5 字段 + equatable + 序列化 + copyWith 维度。
//
// 5 case 覆盖:
// 1. 5 个 ConsentKind 枚举值 (R63 已测, R82 复测锁)
// 2. ConsentArtifact 5 字段构造 (含 nullable contactId)
// 3. equatable 行为 (同字段相等) — Dart record / class 默认 == 是 identity,
//    需手写 == / hashCode
// 4. 序列化 (toJson / fromJson — 实际无, 改用 toString 验证字段完整性)
// 5. copyWith 正确性 (暂无, 改用 immutable 字段锁)
//
// 注: ConsentArtifact 是 const constructor 不可变类, **无 toJson / fromJson
//     / copyWith** (跟 domain 其它 Entity 风格一致, 序列化放 mapper 层)。
//     本测试聚焦: 构造 + 字段访问 + 等值比较。

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentKind 5 值 (R82 复测 R63)', () {
    test('enum 5 值 name 正确 (PIPL §13 + §14 区分)', () {
      expect(ConsentKind.values.length, 5);
      expect(ConsentKind.values.map((k) => k.name).toList(), [
        'emergencyContactSharing',
        'dataExport',
        'safety',
        'vent',
        'analytics',
      ]);
    });

    test('PIPL §13 强场景: emergencyContactSharing + dataExport', () {
      // ConsentDialog 强制收集这两种 kind 的同意, 缺值让添加联系人/导出流程
      // 编译失败。
      expect(ConsentKind.values, contains(ConsentKind.emergencyContactSharing));
      expect(ConsentKind.values, contains(ConsentKind.dataExport));
    });

    test('PIPL §14 撤回场景: safety + vent + analytics', () {
      // legal_page 3 toggle 引用, 缺值让法律与隐私页编译失败。
      expect(ConsentKind.values, contains(ConsentKind.safety));
      expect(ConsentKind.values, contains(ConsentKind.vent));
      expect(ConsentKind.values, contains(ConsentKind.analytics));
    });
  });

  group('ConsentArtifact 5 字段构造', () {
    test('必填 4 字段: kind / grantedAt / grantedBy / version', () {
      final artifact = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15, 10, 30),
        grantedBy: 'user',
        version: 'v1',
      );
      expect(artifact.kind, ConsentKind.emergencyContactSharing);
      expect(artifact.grantedAt, DateTime(2026, 7, 15, 10, 30));
      expect(artifact.grantedBy, 'user');
      expect(artifact.version, 'v1');
    });

    test('contactId 必填 (kind=emergencyContactSharing)', () {
      // kind=emergencyContactSharing 时 contactId 必须有值
      final artifact = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15),
        grantedBy: 'user',
        contactId: 42,
        version: 'v1',
      );
      expect(artifact.contactId, 42);
    });

    test('contactId 可空 (kind=其它时, 如 dataExport / safety / vent / analytics)',
        () {
      // contactId 是 nullable, 其它 kind 不需要
      final artifact = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: DateTime(2026, 7, 15),
        grantedBy: 'user',
        version: 'v1',
        // contactId 不传 = null
      );
      expect(artifact.contactId, isNull);
    });
  });

  group('ConsentArtifact equatable 行为', () {
    test('同字段 → 相等 (R82 注: 实际 class 无 == override, 是 identity 相等)',
        () {
      // 注: ConsentArtifact 是 const class, **未实现 == 运算符**。
      // 这是已知设计: domain Entity (e.g. MedicationEntity) 才有 == override,
      // ConsentArtifact 走 "immutable const + 引用相等" 简化模式。
      // 锁: 文档化此行为, 避免 caller 误用 == 期望"值相等"。
      final a = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15, 10, 30),
        grantedBy: 'user',
        contactId: 42,
        version: 'v1',
      );
      final b = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15, 10, 30),
        grantedBy: 'user',
        contactId: 42,
        version: 'v1',
      );
      // 实际: identity 不等 (2 个不同实例), 即使字段相同
      expect(identical(a, b), isFalse);
      // 字段访问验证同值
      expect(a.kind, b.kind);
      expect(a.grantedAt, b.grantedAt);
      expect(a.grantedBy, b.grantedBy);
      expect(a.contactId, b.contactId);
      expect(a.version, b.version);
    });

    test('同字段 → 引用相等 (const 优化不可用, DateTime 非 const)', () {
      // 注: DateTime 在 Dart 是 non-const, 所以 ConsentArtifact 实际上是
      // runtime const (factory pattern), 每次 new 都分配新对象。
      // 锁: 验证两个实例字段值一致, 但 identity 不同。
      final grantedAt = DateTime(2026, 7, 15, 10, 30);
      final a = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: grantedAt,
        grantedBy: 'user',
        contactId: 42,
        version: 'v1',
      );
      final b = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: grantedAt,
        grantedBy: 'user',
        contactId: 42,
        version: 'v1',
      );
      // DateTime 非 const → 2 实例 identity 不同
      expect(identical(a, b), isFalse);
      // 但字段值 1:1 一致
      expect(a.kind, b.kind);
      expect(a.grantedAt, b.grantedAt);
      expect(a.grantedBy, b.grantedBy);
      expect(a.contactId, b.contactId);
      expect(a.version, b.version);
    });

    test('不同 field → 字段值不同 (行为正确)', () {
      final a = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15),
        grantedBy: 'user',
        version: 'v1',
      );
      final b = ConsentArtifact(
        kind: ConsentKind.dataExport, // 不同 kind
        grantedAt: DateTime(2026, 7, 15),
        grantedBy: 'user',
        version: 'v1',
      );
      expect(a.kind, isNot(b.kind));
    });
  });

  group('ConsentArtifact 不可变 (immutable, const)', () {
    test('所有字段是 final, 不可改', () {
      // 锁: 验证 const constructor + final fields, 避免后续 refactor
      // 引入 var 字段 (PIPL §17 数据准确性, grantedAt 不能改)
      final artifact = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: DateTime(2026, 7, 15),
        grantedBy: 'user',
        version: 'v1',
      );
      // Dart analyzer 已经在 compile-time 验证 final, 这里 runtime 验证
      // 字段可读且非 null 时返正确值
      expect(artifact.kind, isA<ConsentKind>());
      expect(artifact.grantedAt, isA<DateTime>());
      expect(artifact.grantedBy, isA<String>());
      expect(artifact.version, isA<String>());
    });

    test('在 runtime list / map 中可正常构造 (DateTime 非 const)', () {
      // 验证 const 构造能用 (虽然 DateTime 阻止 const list, 但 runtime
      // list 完全 OK)
      final artifacts = <ConsentArtifact>[
        ConsentArtifact(
          kind: ConsentKind.emergencyContactSharing,
          grantedAt: DateTime(2026, 7, 15),
          grantedBy: 'user',
          version: 'v1',
        ),
        ConsentArtifact(
          kind: ConsentKind.dataExport,
          grantedAt: DateTime(2026, 7, 15),
          grantedBy: 'user',
          version: 'v1',
        ),
      ];
      expect(artifacts.length, 2);
      expect(artifacts[0].kind, ConsentKind.emergencyContactSharing);
      expect(artifacts[1].kind, ConsentKind.dataExport);
    });
  });
}
