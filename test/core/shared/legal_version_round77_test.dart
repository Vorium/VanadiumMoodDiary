// v0.27 round 77 (R76-N6 修): 法律协议版本号集中器测试
//
// 覆盖:
// - computeLegalVersionAt(now) 格式 = `v{major.minor}-{YYYY-MM-DD}`
// - 跨日/跨月/跨年日期 padding 正确 (e.g. 2026-01-05 不会变成 2026-1-5)
// - 跨午夜同一 session 仍按调用方传入的 now 算 (caller 负责缓存)
// - kPubspecVersion const 跟 pubspec.yaml 同步 (编译期 check)
//
// 守护: 升级 pubspec.yaml 漏改 kPubspecVersion → test 也能 catch 一部分
// (但需手动加 regex)。R78+ 引入 package_info_plus 自动读可彻底根除。

import 'package:chroniccare/core/shared/legal_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeLegalVersionAt (v0.27 round 77)', () {
    test('基本格式: 0.27.0+64+65 + 2026-08-01 → v0.27-2026-08-01', () {
      final result = computeLegalVersionAt(DateTime(2026, 8, 1));
      expect(result, 'v0.27-2026-08-01');
    });

    test('日期月份 padding (1 → 01, 9 → 09)', () {
      final result = computeLegalVersionAt(DateTime(2026, 1, 5));
      expect(result, 'v0.27-2026-01-05');
    });

    test('日期日 padding (5 → 05)', () {
      final result = computeLegalVersionAt(DateTime(2027, 9, 9));
      expect(result, 'v0.27-2027-09-09');
    });

    test('跨年 (2026-12-31 → 2027-01-01) padding 正确', () {
      final result = computeLegalVersionAt(DateTime(2027, 1, 1));
      expect(result, 'v0.27-2027-01-01');
    });

    test('同日期多次调用返相同 string (caller 缓存无副作用)', () {
      final now = DateTime(2026, 8, 1, 23, 59, 59);
      final v1 = computeLegalVersionAt(now);
      final v2 = computeLegalVersionAt(now);
      expect(v1, v2);
    });

    test('返回 string 永远以 "v" 开头 (PIPL §17 协议标识)', () {
      final result = computeLegalVersionAt(DateTime.now());
      expect(result.startsWith('v'), isTrue);
    });

    test('返回 string 包含 "-" 分隔 version + date', () {
      final result = computeLegalVersionAt(DateTime(2026, 8, 1));
      expect(result.contains('-'), isTrue);
      // 3 个 "-" (v0.27-2026-08-01): v0.27 | 2026-08 | 08-01
      expect('.'.allMatches(result).length, 1);
      expect('-'.allMatches(result).length, 3);
    });
  });

  group('kPubspecVersion (compile-time const, 跟 pubspec.yaml 同步)', () {
    test('kPubspecVersion 不为空', () {
      expect(kPubspecVersion, isNotEmpty);
    });

    test('kPubspecVersion 包含 "." (semver 格式)', () {
      expect(kPubspecVersion.contains('.'), isTrue);
    });

    test('kPubspecVersion 不包含 "v" 前缀 (computeLegalVersionAt 负责加)', () {
      expect(kPubspecVersion.startsWith('v'), isFalse);
    });
  });
}
