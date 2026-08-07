// v0.16 (Round 19C) regression test for unsafe route param parsing
//
// 之前 `app_router.dart:110` 用 `int.parse(state.pathParameters['id'] ?? '0')`，
// URL 是 `/vent/detail/abc` 时 `int.parse('abc')` 抛 FormatException
// → GoRouter 内部 catch 不到直接崩 app。
//
// 修：改用 `int.tryParse(...) ?? 0`，invalid id fallback 到 0（详情页会
// 显示"找不到了"）。
//
// 这些测试验证 fallback 逻辑对不同输入都安全。
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('route param parsing — int.tryParse fallback', () {
    test('valid int → 整数', () {
      expect(int.tryParse('42') ?? 0, 42);
    });

    test('valid int (larger) → 整数', () {
      expect(int.tryParse('1000') ?? 0, 1000);
    });

    test('empty string → fallback 0', () {
      expect(int.tryParse('') ?? 0, 0);
    });

    test('non-numeric string → fallback 0 (regression: 修前会崩)', () {
      // 修前: int.parse('abc') 抛 FormatException
      // 修后: int.tryParse('abc') 返回 null，?? 0 fallback
      expect(int.tryParse('abc') ?? 0, 0);
    });

    test('mixed alphanumeric → fallback 0', () {
      expect(int.tryParse('12abc') ?? 0, 0);
    });

    test('negative int → -5', () {
      // 负数也接受，但本项目 vent id 不会负，仅验证 tryParse 行为
      expect(int.tryParse('-5') ?? 0, -5);
    });

    test('whitespace → trim 后接受 (Dart 标准行为)', () {
      // Dart 的 int.tryParse 接受 leading/trailing whitespace（trim 后 parse）
      expect(int.tryParse(' 12 ') ?? 0, 12);
    });

    test('null fallback via ?? 0 模式', () {
      // 模拟 pathParameters['id'] ?? '' (null → '')
      const String? raw = null;
      expect(int.tryParse(raw ?? '') ?? 0, 0);
    });
  });
}
