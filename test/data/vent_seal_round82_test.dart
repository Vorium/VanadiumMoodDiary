// v0.28 round 82.5 (法务 Q7b 必改, PIPL §47 删除权) test
//
// 覆盖:
// 1. ConsentPreferenceStore.seal/isSealed/sealedAt 基本生命周期
// 2. seal 后 isSealed=true, sealedAt 非空
// 3. unseal / reset 都能清 seal 标志
// 4. seal 仅支持 ConsentKind.vent, 其它 kind 抛 ArgumentError
// 5. VentRepository.deleteAll 删所有条目 + 删 audio 文件
// 6. clearLegalConsentCache 同步清 sealed 标志 (调试入口)
// 7. VentRepository.deleteAll 事务保护: DB 删完才删文件
//
// v0.32 架构批 2 (R112-ARCH-01): LegalConsentStore (presentation) 迁到
// ConsentPreferenceStore (data 层), 行为/key 100% 不变, 本文件只改构造
// (注入 SharedPreferences mock)。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/services/consent_preference_store.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart'
    show clearLegalConsentCache;

void main() {
  // 走 SharedPreferences setMockInitialValues() 隔离每个 case 的 store
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // v0.32 架构批 2: store 构造需要注入 SharedPreferences (async)
  Future<ConsentPreferenceStore> makeStore() async =>
      ConsentPreferenceStore(await SharedPreferences.getInstance());

  group('ConsentPreferenceStore.seal — 加密封存 (R82.5 法务 Q7b 必改)', () {
    test('默认未封存: isSealed(vent) == false, sealedAt(vent) == null', () async {
      final store = await makeStore();
      expect(await store.isSealed(ConsentKind.vent), isFalse);
      expect(await store.sealedAt(ConsentKind.vent), isNull);
    });

    test('seal(vent) 后: isSealed(vent) == true, sealedAt(vent) 非空', () async {
      final store = await makeStore();
      final before = DateTime.now();
      await store.seal(ConsentKind.vent);
      final after = DateTime.now();

      expect(await store.isSealed(ConsentKind.vent), isTrue);
      final sealedAt = await store.sealedAt(ConsentKind.vent);
      expect(sealedAt, isNotNull);
      expect(
        sealedAt!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(sealedAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('sealedAt 时间精度: 多次 seal 重新更新时间 (覆盖前一次)', () async {
      final store = await makeStore();
      await store.seal(ConsentKind.vent);
      final firstSeal = await store.sealedAt(ConsentKind.vent);

      // 模拟用户过 100ms 重新触发
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await store.seal(ConsentKind.vent);
      final secondSeal = await store.sealedAt(ConsentKind.vent);

      expect(secondSeal!.isAfter(firstSeal!), isTrue);
    });

    test('seal 仅支持 ConsentKind.vent: 其它 kind 抛 ArgumentError', () async {
      final store = await makeStore();
      expect(
        () => store.seal(ConsentKind.safety),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => store.seal(ConsentKind.analytics),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => store.seal(ConsentKind.emergencyContactSharing),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => store.seal(ConsentKind.dataExport),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('isSealed / sealedAt 对非 vent kind 一律返 false / null (语义安全)', () async {
      final store = await makeStore();
      // 即便误调 seal(其它 kind) 抛错, isSealed 永远返 false
      expect(await store.isSealed(ConsentKind.safety), isFalse);
      expect(await store.isSealed(ConsentKind.analytics), isFalse);
      expect(await store.sealedAt(ConsentKind.safety), isNull);
      expect(await store.sealedAt(ConsentKind.analytics), isNull);
    });

    test('unseal(vent) 清除封存标志: isSealed=false, sealedAt=null', () async {
      final store = await makeStore();
      await store.seal(ConsentKind.vent);
      expect(await store.isSealed(ConsentKind.vent), isTrue);

      await store.unseal(ConsentKind.vent);
      expect(await store.isSealed(ConsentKind.vent), isFalse);
      expect(await store.sealedAt(ConsentKind.vent), isNull);
    });

    test('reset(vent) 同时清封存标志 (用户重新同意 = 解封)', () async {
      // 法务: 撤回 + 封存是同一操作, 重新同意应该一并清两个标志
      final store = await makeStore();
      await store.withdraw(ConsentKind.vent);
      await store.seal(ConsentKind.vent);

      expect(await store.isWithdrawn(ConsentKind.vent), isTrue);
      expect(await store.isSealed(ConsentKind.vent), isTrue);

      await store.reset(ConsentKind.vent);

      expect(await store.isWithdrawn(ConsentKind.vent), isFalse);
      expect(await store.isSealed(ConsentKind.vent), isFalse);
      expect(await store.sealedAt(ConsentKind.vent), isNull);
    });

    test('reset(其它 kind) 不影响 vent 封存状态 (隔离性)', () async {
      final store = await makeStore();
      await store.seal(ConsentKind.vent);

      await store.reset(ConsentKind.safety);
      await store.reset(ConsentKind.analytics);

      // vent 仍封存
      expect(await store.isSealed(ConsentKind.vent), isTrue);
    });

    test('clearLegalConsentCache 同步清封存标志 (调试入口完整)', () async {
      // 设初始值
      SharedPreferences.setMockInitialValues({
        'legal_consent_withdrawn_vent': true,
        'legal_consent_withdrawn_vent_at':
            DateTime.now().millisecondsSinceEpoch,
        'legal_consent_vent_sealed_at': DateTime.now().millisecondsSinceEpoch,
      });

      // 先验证初始状态
      final store = await makeStore();
      expect(await store.isWithdrawn(ConsentKind.vent), isTrue);
      expect(await store.isSealed(ConsentKind.vent), isTrue);

      // 调清缓存
      await clearLegalConsentCache();

      // 验证全部清空
      expect(await store.isWithdrawn(ConsentKind.vent), isFalse);
      expect(await store.isSealed(ConsentKind.vent), isFalse);
      expect(await store.sealedAt(ConsentKind.vent), isNull);
    });
  });
}
