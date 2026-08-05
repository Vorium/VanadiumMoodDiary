# Task 7 Brief — 设置页 radio 入口

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: 0bc7c4a (task 1-6 + fixes 完成)
- Task 1-6 已完成: schema + ThoughtRecordLevel + CbtDraftState + 公共 widget + 3 栏 mode UI + 5/7 栏 wizard + score chip 接入
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0 error
- 现有 settings page 在 `lib/presentation/pages/settings/page.dart`, 复用 SettingsPage widget + AppTokens
- 跨 feature import: settings 可引用 presentation/widgets 和 presentation/providers, 不可引用 mood 私有 widget

## 已有文件 / 上下文

- `lib/presentation/pages/settings/page.dart` (要加 "思维记录档位" section)
- `lib/domain/entities/thought_record_level.dart` (Task 2)
- `lib/presentation/providers/cbt_providers.dart` (含 thoughtRecordLevelProvider, Task 2)
- 新建测试: `test/presentation/pages/settings/thought_record_level_round84_test.dart`

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 7 内部有 2 个 step (settings 渲染 / radio 改后写 SP)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-7-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 7: 璁剧疆椤?radio 鍏ュ彛

**Files:**
- Modify: `lib/presentation/pages/settings/page.dart`
- Test: `test/presentation/pages/settings/thought_record_level_round84_test.dart`

**Interfaces:**
- Consumes: `thoughtRecordLevelProvider`, ARB key `settingsCbtLevel*`
- Produces: 璁剧疆椤?鎬濈淮璁板綍妗ｄ綅" radio section

- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?璁剧疆椤?radio**

`test/presentation/pages/settings/thought_record_level_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/settings/page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('璁剧疆椤垫樉绀烘€濈淮璁板綍妗ｄ綅 3 閫?1', (tester) async {
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('鎬濈淮璁板綍妗ｄ綅'), findsOneWidget);
    expect(find.text('3 鏍?), findsOneWidget);
    expect(find.text('5 鏍?), findsOneWidget);
    expect(find.text('7 鏍?), findsOneWidget);
  });

  testWidgets('鐐瑰嚮 5 鏍?radio 绔嬪嵆鍐欏叆 SP', (tester) async {
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 鏍?));
    await tester.pumpAndSettle();
    expect(sp.getInt('mood.thought_record_level'), 5);
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/presentation/pages/settings/thought_record_level_round84_test.dart
```

Expected: FAIL 鈥?璁剧疆椤垫病鏈?鎬濈淮璁板綍妗ｄ綅"銆?
- [ ] **Step 3: 鍦?settings/page.dart 鏂板? section**

`lib/presentation/pages/settings/page.dart`:

鍦ㄥ悎閫備綅缃?紙"鐢ㄨ嵂"鎴?鎻愰啋"section 鍚庯級鍔狅細

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 鎬濈淮璁板綍妗ｄ綅璁剧疆
Consumer(
  builder: (ctx, ref, _) {
    final level = ref.watch(thoughtRecordLevelProvider);
    final notifier = ref.read(thoughtRecordLevelProvider.notifier);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('鎬濈淮璁板綍妗ｄ綅', style: AppTokens.textStyleTitleSmall(ctx)),
            const SizedBox(height: AppTokens.spacingXxs),
            Text('閫夋嫨姣忔?璁板綍鎯呯华鏃朵娇鐢ㄧ殑鎬濈淮璁板綍妯℃澘', style: AppTokens.textStyleBodySmall(ctx)),
            const SizedBox(height: AppTokens.spacingSm),
            ...ThoughtRecordLevel.values.map((lv) => RadioListTile<ThoughtRecordLevel>(
                  title: Text('${lv.columnCount} 鏍?),
                  subtitle: Text(_descriptionFor(lv)),
                  value: lv,
                  groupValue: level,
                  onChanged: (newVal) {
                    if (newVal != null) notifier.setLevel(newVal);
                  },
                )),
          ],
        ),
      ),
    );
  },
),

String _descriptionFor(ThoughtRecordLevel lv) {
  switch (lv) {
    case ThoughtRecordLevel.three: return '鍏ラ棬鐗堬紝1-2 鍒嗛挓鍙?～瀹?;
    case ThoughtRecordLevel.five: return '鏍囧噯 Beck 鎬濈淮璁板綍锛屽惈璁ょ煡閲嶆瀯鍏抽敭姝ラ?';
    case ThoughtRecordLevel.seven: return '娣卞害鐗堬紝鍚?牳蹇冧俊蹇佃瘑鍒?拰琛屼负搴斿?';
  }
}
```

- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/presentation/pages/settings/thought_record_level_round84_test.dart
```

Expected: PASS 2/2銆?
- [ ] **Step 5: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1183 + 2 = 1185 cases pass銆?
- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/settings/page.dart \
        test/presentation/pages/settings/thought_record_level_round84_test.dart
git commit -m 'v0.29 round 84 (settings): 鎬濈淮璁板綍妗ｄ綅 radio section'
```

---


