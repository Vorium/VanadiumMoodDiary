# Task 2 Brief — ThoughtRecordLevel enum + provider

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 项目: D:\Batch\chroniccare (慢性病管家 Flutter App)
- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: ce2288d (task 1 完成)
- 4 层架构: presentation → domain ← data, domain 0 flutter 0 drift
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- Riverpod 3.3.2 (NotifierProvider pattern)
- SharedPreferences 2.x 持久化
- 现有测试 baseline (task 1 后): ~1424 pass + 16 pre-existing fail (跟 task 1 无关)
- 守门员: `flutter analyze` 0 error, `flutter test` 全过

## 已有文件 / 上下文

- task 1 已完成: schema 16→17 + entity 8 fields + 6 test cases
- 新建文件: `lib/domain/entities/thought_record_level.dart`, `lib/presentation/providers/cbt_providers.dart`
- 修改文件: `lib/app.dart` (注册 SP provider override)

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 2 内部有 3 个 step (enum 解析 / Notifier + 持久化 / app.dart override)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-2-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 2: ThoughtRecordLevel enum + provider

**Files:**
- Create: `lib/domain/entities/thought_record_level.dart`
- Create: `lib/presentation/providers/cbt_providers.dart`
- Test: `test/domain/entities/thought_record_level_round84_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces:
  - `enum ThoughtRecordLevel { three, five, seven }` + `int get columnCount` + `static ThoughtRecordLevel fromInt(int)`
  - `thoughtRecordLevelProvider` (NotifierProvider\<ThoughtRecordLevel\>) 鈥?SP 鎸佷箙鍖?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?enum 瑙ｆ瀽**

`test/domain/entities/thought_record_level_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  group('ThoughtRecordLevel (v0.29 round 84)', () {
    test('涓夋。 columnCount 鍒嗗埆鏄?3/5/7', () {
      expect(ThoughtRecordLevel.three.columnCount, 3);
      expect(ThoughtRecordLevel.five.columnCount, 5);
      expect(ThoughtRecordLevel.seven.columnCount, 7);
    });

    test('fromInt 3/5/7 瑙ｆ瀽', () {
      expect(ThoughtRecordLevel.fromInt(3), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(5), ThoughtRecordLevel.five);
      expect(ThoughtRecordLevel.fromInt(7), ThoughtRecordLevel.seven);
    });

    test('fromInt 闈炴硶鍊?fallback 鍒?3', () {
      expect(ThoughtRecordLevel.fromInt(0), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(99), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(-1), ThoughtRecordLevel.three);
    });
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/domain/entities/thought_record_level_round84_test.dart
```

Expected: FAIL 鈥?`ThoughtRecordLevel` 涓嶅瓨鍦ㄣ€?
- [ ] **Step 3: 瀹炵幇 enum**

`lib/domain/entities/thought_record_level.dart`:

```dart
/// v0.29 round 84 (CBT 鎬濈淮璁板綍): 涓夋。鍙?垏鎹㈢殑鎬濈淮璁板綍娣卞害
///
/// - three: 3 鏍忥紙鍏ラ棬鐗堬紝鎯呭?/鑷?姩鎬濈淮/鎯呯华锛?/// - five: 5 鏍忥紙Beck 鏍囧噯锛屽姞鏀?寔-鍙嶅?璇佹嵁 + 鏇夸唬鎬濈淮 + 閲嶆柊璇勫垎锛?/// - seven: 7 鏍忥紙娣卞害鐗堬紝鍐嶅姞鏍稿績淇″康 + 琛屼负搴斿?锛?enum ThoughtRecordLevel {
  three,
  five,
  seven;

  /// 鏍忎綅鏁?(3 / 5 / 7)
  int get columnCount {
    switch (this) {
      case ThoughtRecordLevel.three: return 3;
      case ThoughtRecordLevel.five: return 5;
      case ThoughtRecordLevel.seven: return 7;
    }
  }

  /// 鍙嶅悜瑙ｆ瀽: 3/5/7 鈫?enum, 闈炴硶鍊?fallback 鍒?three
  ///
  /// 鍏煎?鑰?SP 鍊兼垨鎵嬫敼閰嶇疆鏂囦欢鍦烘櫙銆?  static ThoughtRecordLevel fromInt(int value) {
    switch (value) {
      case 3: return ThoughtRecordLevel.three;
      case 5: return ThoughtRecordLevel.five;
      case 7: return ThoughtRecordLevel.seven;
      default: return ThoughtRecordLevel.three;
    }
  }
}
```

- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/domain/entities/thought_record_level_round84_test.dart
```

Expected: PASS 3/3銆?
- [ ] **Step 5: 瀹炵幇 thoughtRecordLevelProvider**

鍦?`lib/presentation/providers/cbt_providers.dart` 鏂版枃浠讹紝鍔狅細

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 妗ｄ綅鎸佷箙鍖?provider
//
// - 璇? SharedPreferences key "mood.thought_record_level" (int 3/5/7)
// - 鍐? 鐢ㄦ埛鍦?settings 椤垫敼鍚庣珛鍗冲悓姝?// - 榛樿?: 3 (鏂版墜鍙嬪ソ)
// - 寮傚父: SP 璇诲け璐?fallback 3 (fail-safe)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/thought_record_level.dart';

const _kThoughtRecordLevelKey = 'mood.thought_record_level';

/// 鍚?姩鏃朵竴娆℃€ц? SP, 缁?provider 鐢?final _sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at app boot'),
);

/// v0.29 round 84: 鎬濈淮璁板綍妗ｄ綅 (3/5/7)
class ThoughtRecordLevelNotifier extends Notifier<ThoughtRecordLevel> {
  @override
  ThoughtRecordLevel build() {
    final sp = ref.read(_sharedPreferencesProvider);
    final raw = sp.getInt(_kThoughtRecordLevelKey);
    return ThoughtRecordLevel.fromInt(raw ?? 3);
  }

  /// 璁剧疆妗ｄ綅 (settings 椤佃皟鐢?
  Future<void> setLevel(ThoughtRecordLevel level) async {
    state = level;
    final sp = ref.read(_sharedPreferencesProvider);
    await sp.setInt(_kThoughtRecordLevelKey, level.columnCount);
  }
}

final thoughtRecordLevelProvider =
    NotifierProvider<ThoughtRecordLevelNotifier, ThoughtRecordLevel>(
  ThoughtRecordLevelNotifier.new,
);
```

- [ ] **Step 6: 鍦?app.dart 娉ㄥ唽 SP provider override**

`lib/app.dart` `build()` 鍐咃紙宸叉湁 `ProviderScope` 鍖哄煙锛夊姞锛?
```dart
ProviderScope(
  overrides: [
    _sharedPreferencesProvider.overrideWithValue(
      await SharedPreferences.getInstance(),
    ),
  ],
  child: const App(),
)
```

> **娉ㄦ剰**锛歚_sharedPreferencesProvider` 鏄?top-level 绉佹湁锛岃?璁?app.dart 鑳?override锛?*鏀逛负鍏?紑鍛藉悕** `sharedPreferencesProvider`锛堝湪 cbt_providers.dart 椤堕儴锛屽垹涓嬪垝绾匡級銆?
- [ ] **Step 7: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1169 + 3 = 1172 cases pass銆?
- [ ] **Step 8: Commit**

```bash
git add lib/domain/entities/thought_record_level.dart \
        lib/presentation/providers/cbt_providers.dart \
        lib/app.dart \
        test/domain/entities/thought_record_level_round84_test.dart
git commit -m 'v0.29 round 84 (state): ThoughtRecordLevel enum + SP provider'
```

---


