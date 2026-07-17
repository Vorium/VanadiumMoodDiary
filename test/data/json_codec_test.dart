import 'package:chroniccare/shared/json_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonCodec.encodeStringList / decodeStringList', () {
    test('空列表 → "[]"', () {
      expect(JsonCodec.encodeStringList(const []), '[]');
    });

    test('中文列表', () {
      final encoded = JsonCodec.encodeStringList(['焦虑', '抑郁']);
      final decoded = JsonCodec.decodeStringList(encoded);
      expect(decoded, ['焦虑', '抑郁']);
    });

    test('空字符串/[] 容错', () {
      expect(JsonCodec.decodeStringList(''), isEmpty);
      expect(JsonCodec.decodeStringList('[]'), isEmpty);
      expect(JsonCodec.decodeStringList(null), isEmpty);
    });

    test('非法 JSON 不抛异常', () {
      // 容错：返回空列表而不是抛
      expect(JsonCodec.decodeStringList('not json'), isEmpty);
      expect(JsonCodec.decodeStringList('{"x":1}'), isEmpty);
    });

    test('特殊字符正确转义', () {
      // 包含引号和反斜杠
      final encoded = JsonCodec.encodeStringList(['a"b', 'c\\d']);
      final decoded = JsonCodec.decodeStringList(encoded);
      expect(decoded, ['a"b', 'c\\d']);
    });
  });

  group('JsonCodec.parseTempMedNote - 向后兼容', () {
    test('新格式 JSON：完整解析', () {
      final result = JsonCodec.parseTempMedNote(
        '{"name":"布洛芬","desc":"头痛"}',
      );
      expect(result.name, '布洛芬');
      expect(result.description, '头痛');
    });

    test('老格式 "name: desc"：fallback 解析', () {
      final result = JsonCodec.parseTempMedNote('布洛芬: 头痛');
      expect(result.name, '布洛芬');
      expect(result.description, '头痛');
    });

    test('老格式 没有冒号：整段作为 name', () {
      final result = JsonCodec.parseTempMedNote('阿普唑仑 0.4mg');
      expect(result.name, '阿普唑仑 0.4mg');
      expect(result.description, '');
    });

    test('空/null：空字符串', () {
      expect(JsonCodec.parseTempMedNote('').name, '');
      expect(JsonCodec.parseTempMedNote(null).name, '');
      expect(JsonCodec.parseTempMedNote(null).description, '');
    });

    test('JSON 但 name 缺失：name 为空', () {
      final result = JsonCodec.parseTempMedNote('{"desc":"头痛"}');
      expect(result.name, '');
      expect(result.description, '头痛');
    });

    test('buildTempMedNote → parseTempMedNote 往返一致', () {
      final note = JsonCodec.buildTempMedNote(
        name: '右佐匹克隆',
        description: '失眠',
      );
      final parsed = JsonCodec.parseTempMedNote(note);
      expect(parsed.name, '右佐匹克隆');
      expect(parsed.description, '失眠');
    });

    test('buildTempMedNote description 为空', () {
      final note = JsonCodec.buildTempMedNote(name: '布洛芬');
      final parsed = JsonCodec.parseTempMedNote(note);
      expect(parsed.name, '布洛芬');
      expect(parsed.description, '');
    });
  });
}
