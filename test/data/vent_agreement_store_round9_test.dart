// v1.1.0 round 9 (F4 树洞使用公约): VentAgreementStore data 层 unit test
//
// SharedPreferences.setMockInitialValues() 隔离每个 case 的 store。
// 覆盖: 默认未确认 / acknowledge 后已确认 / 持久化 (新实例读到 true)。
import 'package:chroniccare/core/data/services/vent_agreement_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<VentAgreementStore> makeStore() async =>
      VentAgreementStore(await SharedPreferences.getInstance());

  test('默认未确认: isAcknowledged() == false', () async {
    final store = await makeStore();
    expect(await store.isAcknowledged(), isFalse);
  });

  test('acknowledge 后已确认: isAcknowledged() == true', () async {
    final store = await makeStore();
    await store.acknowledge();
    expect(await store.isAcknowledged(), isTrue);
  });

  test('持久化: 新实例 (同 SharedPreferences 后端) 读到 true', () async {
    final store = await makeStore();
    await store.acknowledge();
    final store2 = await makeStore();
    expect(await store2.isAcknowledged(), isTrue);
  });

  test('预置已读 (换机/重装后 restore 或测试): isAcknowledged() == true', () async {
    SharedPreferences.setMockInitialValues({
      'vent_agreement_acknowledged': true,
    });
    final store = await makeStore();
    expect(await store.isAcknowledged(), isTrue);
  });
}
