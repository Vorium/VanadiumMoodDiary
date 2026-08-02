// v0.27 round 82: ConsentArtifact dataExport 流程 + ConsentDialog 抽象化 测试
//
// 任务: ConsentDialog.show 抽象化支持 5 个 kind + 数据导出走 PIPL §13
// 单独同意 + LegalConsentStore.recordDataExportConsent 写 audit log
// (修复前 dataExport 只有"敏感文字警告" 通用 dialog, 没生成 ConsentArtifact,
// 法务复查时缺 §13 同意证据)
//
// 本测试覆盖 (8 cases):
// 1. ConsentKind.dataExport 枚举值存在
// 2. ConsentKind 5 kind 完整 (R63 同步验证 + R82 确认无回归)
// 3. ConsentArtifact 5 字段 (kind/grantedAt/grantedBy/contactId/version) 构造 + 读取
// 4. ConsentArtifact JSON round-trip (5 字段经 jsonEncode/jsonDecode 不丢)
// 5. 4 个新 i18n key (dataExportConsentTitle/Body/Confirm/Version) 在 3 个 ARB 同步
// 6. dataExportConsentBody 3 placeholder (purpose / dataCategories / retention) 声明
// 7. LegalConsentStore.recordDataExportConsent 写 SharedPreferences 后能读回
// 8. recordDataExportConsent 多次调用累积到 log (不覆盖, 满足 PIPL §17 同意记录)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';

void main() {
  setUp(() {
    // 每个 case 前清空 SharedPreferences mock — 防 case 间污染
    SharedPreferences.setMockInitialValues({});
  });

  group('ConsentKind.dataExport (PIPL §13 单独同意 — round 82)', () {
    test('dataExport 枚举值存在 + name 正确', () {
      expect(ConsentKind.values, contains(ConsentKind.dataExport));
      expect(ConsentKind.dataExport.name, 'dataExport');
    });

    test('5 kind 完整 (R63 同步验证 + R82 确认无回归)', () {
      // 跟 test/domain/consent_kind_unified_round63_test.dart 同步验证,
      // 确保 R82 抽象化 ConsentDialog 时没动 domain entity
      expect(ConsentKind.values.length, 5);
      expect(ConsentKind.values.map((k) => k.name).toSet(), {
        'emergencyContactSharing',
        'dataExport',
        'safety',
        'vent',
        'analytics',
      });
    });

    test('ConsentArtifact 5 字段 (kind/grantedAt/grantedBy/contactId/version) 构造 + 读取', () {
      // 模拟一次 dataExport 同意的完整 ConsentArtifact
      // 5 字段: kind / grantedAt / grantedBy / contactId / version
      final grantedAt = DateTime.utc(2026, 8, 15, 10, 30);
      final artifact = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: grantedAt,
        grantedBy: 'user',
        contactId: null, // dataExport 不关联 contact
        version: 'v0.27-2026-08-15',
      );

      // 5 字段读取 (即"反序列化"通过直接访问)
      expect(artifact.kind, ConsentKind.dataExport);
      expect(artifact.grantedAt, grantedAt);
      expect(artifact.grantedBy, 'user');
      expect(artifact.contactId, isNull);
      expect(artifact.version, 'v0.27-2026-08-15');
    });

    test('ConsentArtifact JSON round-trip (5 字段经 jsonEncode/jsonDecode 不丢)', () {
      // 跟 LegalConsentStore.recordDataExportConsent / readDataExportConsentLog
      // 内的 jsonEncode/jsonDecode 路径对齐, 验证序列化协议正确
      final original = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: DateTime.utc(2026, 8, 15, 10, 30, 45),
        grantedBy: 'user',
        contactId: null,
        version: 'v0.27-2026-08-15',
      );
      // 序列化 (走 Map, 跟 LegalConsentStore.recordDataExportConsent 同步)
      final encoded = jsonEncode({
        'kind': original.kind.name,
        'grantedAt': original.grantedAt.toIso8601String(),
        'grantedBy': original.grantedBy,
        'contactId': original.contactId,
        'version': original.version,
      });
      // 反序列化 (跟 readDataExportConsentLog 对称)
      final map = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = ConsentArtifact(
        kind: ConsentKind.values.firstWhere((k) => k.name == map['kind']),
        grantedAt: DateTime.parse(map['grantedAt'] as String),
        grantedBy: map['grantedBy'] as String,
        contactId: map['contactId'] as int?,
        version: map['version'] as String,
      );

      expect(restored.kind, original.kind);
      expect(restored.grantedAt, original.grantedAt);
      expect(restored.grantedBy, original.grantedBy);
      expect(restored.contactId, original.contactId);
      expect(restored.version, original.version);
    });

    test('4 个新 i18n key 在 zh / en / zh_Hant ARB 同步', () async {
      // 读 3 个 ARB 文件, 确认 4 个新 key 都在 (R82 加)
      const zhArb = 'lib/l10n/app_zh.arb';
      const enArb = 'lib/l10n/app_en.arb';
      const zhHantArb = 'lib/l10n/app_zh_Hant.arb';
      const expectedKeys = [
        'dataExportConsentTitle',
        'dataExportConsentBody',
        'dataExportConsentConfirm',
        'dataExportConsentVersion',
      ];

      for (final path in [zhArb, enArb, zhHantArb]) {
        final content = await File(path).readAsString();
        for (final key in expectedKeys) {
          expect(
            content.contains('"$key"'),
            isTrue,
            reason: '$path 缺 $key key (R82 加)',
          );
        }
      }
    });

    test('dataExportConsentBody 3 placeholder (purpose / dataCategories / retention) 在 ARB 声明', () async {
      for (final path in [
        'lib/l10n/app_zh.arb',
        'lib/l10n/app_en.arb',
        'lib/l10n/app_zh_Hant.arb',
      ]) {
        final content = await File(path).readAsString();
        // placeholder 字段名同时出现在 body 模板 ({purpose}) + @dataExportConsentBody
        // 元数据 (purpose: { type: String, ... })
        for (final ph in ['purpose', 'dataCategories', 'retention']) {
          expect(
            content.contains('{$ph}'),
            isTrue,
            reason: '$path 缺 {$ph} placeholder',
          );
        }
      }
    });

    test('LegalConsentStore.recordDataExportConsent 写 SharedPreferences 后能读回', () async {
      final store = LegalConsentStore();
      final artifact = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: DateTime.utc(2026, 8, 15, 12, 0),
        grantedBy: 'user',
        contactId: null,
        version: 'v0.27-2026-08-15',
      );

      // 写 (走 recordDataExportConsent, PIPL §17 留痕)
      await store.recordDataExportConsent(artifact);

      // 读 (走 readDataExportConsentLog, 法务复查用)
      final log = await store.readDataExportConsentLog();
      expect(log, hasLength(1));
      expect(log.first.kind, ConsentKind.dataExport);
      expect(log.first.grantedAt, DateTime.utc(2026, 8, 15, 12, 0));
      expect(log.first.grantedBy, 'user');
      expect(log.first.version, 'v0.27-2026-08-15');
    });

    test('recordDataExportConsent 多次调用累积到 log (不覆盖, PIPL §17 同意记录可追溯)', () async {
      final store = LegalConsentStore();
      final a1 = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: DateTime.utc(2026, 8, 15, 10),
        grantedBy: 'user',
        version: 'v0.27-2026-08-15',
      );
      final a2 = ConsentArtifact(
        kind: ConsentKind.dataExport,
        grantedAt: DateTime.utc(2026, 8, 15, 11),
        grantedBy: 'user',
        version: 'v0.27-2026-08-15',
      );

      await store.recordDataExportConsent(a1);
      await store.recordDataExportConsent(a2);

      final log = await store.readDataExportConsentLog();
      expect(log, hasLength(2));
      // FIFO 顺序 (写入顺序)
      expect(log[0].grantedAt, DateTime.utc(2026, 8, 15, 10));
      expect(log[1].grantedAt, DateTime.utc(2026, 8, 15, 11));
    });
  });
}
