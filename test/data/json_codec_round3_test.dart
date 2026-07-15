import 'package:chroniccare/data/utils/json_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonCodec.parseTempMedNote 第二轮回归', () {
    test('空 JSON 对象 "{}" → fallback 到老格式 "name: desc" 解析（不会 crash）', () {
      // 之前 decodeMap 对 "{}" 返回空 map (isEmpty=true),走 fallback 老格式。
      // 修复:这里 assert 老格式解析也正确处理空 map
      final r = JsonCodec.parseTempMedNote('{}');
      // raw='{}', indexOf(':') 找不到,sepIdx=-1,不进入 if,返回 (raw.trim(), '')
      expect(r.name, '{}');
      expect(r.description, '');
    });

    test('非法 JSON → fallback 老格式 "name: desc" 解析', () {
      final r = JsonCodec.parseTempMedNote('布洛芬: 头痛');
      expect(r.name, '布洛芬');
      expect(r.description, '头痛');
    });

    test('老格式 "name: desc" 含 name 中的冒号被截断（已知遗留）', () {
      final r = JsonCodec.parseTempMedNote('洛尔: 200mg: 头痛');
      // 旧行为:第一个 : 切
      expect(r.name, '洛尔');
      expect(r.description, '200mg: 头痛');
    });

    test('新格式: name 缺失 / null → name 空字符串', () {
      // decodeMap 返回 {"desc":"头痛"}, asMap['name'] is null
      final r = JsonCodec.parseTempMedNote('{"desc":"头痛"}');
      expect(r.name, '');
      expect(r.description, '头痛');
    });

    test('name 含 emoji', () {
      final r = JsonCodec.parseTempMedNote('{"name":"布洛芬 💊","desc":"头痛"}');
      expect(r.name, '布洛芬 💊');
      expect(r.description, '头痛');
    });
  });
}
