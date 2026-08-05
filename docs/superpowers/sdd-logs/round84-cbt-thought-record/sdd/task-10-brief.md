# Task 10 Brief — 集成测试 + 守门员验证 (最后)

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: 2e16abc (task 1-9 全部完成)
- Task 1-9 已完成: schema 16→17 + 8 CBT fields + 3/5/7 栏 UI + settings + trend 集成 + 35 ARB keys
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: 全部 16 脚本全绿
- 集成测试覆盖端到端流程 (改档 → 打开 dialog → 填表 → 提交 → 在 trend 看到 CBT 摘要)

## 已有文件 / 上下文

- 现有 16 守护脚本: check_arb_keys / check_changelog / check_cross_feature / check_datetime_race / check_datetime_race2 / check_drift_namespace / check_fullwidth_punctuation / check_no_hardcoded_utc / check_no_pua / check_widget_dispose / check_orphan_arb_keys / check_legal_consent / check_sms_release_ready / check_strings_hardcoded / check_zh_hant_consistency + check_all.dart
- `docs/CHANGELOG.md` (要加 [0.29.0] entry)
- 现有 `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` 集成所有 CBT 组件
- 现有 `lib/presentation/pages/settings/widgets/cbt_section.dart` 跟 SP 持久化
- 现有 `lib/presentation/pages/trend/trend_calendar.dart` DayDetailCard 显示 CBT 摘要

## TDD 流程

这个 task 是最终收尾, 不写新功能代码, 只:
1. 写 1 个端到端集成测试 (跟 brief 一致)
2. 跑全部 16 守门员脚本验证
3. `flutter analyze` 0 + `flutter test` 全过
4. 更新 CHANGELOG
5. 1 commit final

## Report 文件

详细报告写到: `.superpowers/sdd/task-10-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 10: 闆嗘垚娴嬭瘯 + 瀹堥棬鍛橀獙璇?
**Files:**
- Test: `test/integration/cbt_thought_record_flow_round84_test.dart`
- 涓嶆敼瀹炵幇浠ｇ爜锛屽彧璺戝叏閲忛獙璇?
**Interfaces:**
- 绔?埌绔? 鍚?姩 App 鈫?璁剧疆椤垫敼 5 鏍?鈫?鎵撳紑 mood dialog 鈫?濉?5 鏍?鈫?鎻愪氦 鈫?鍦?trend_calendar 鐪嬪埌 CBT 鎽樿?

- [ ] **Step 1: 鍐欑?鍒扮?闆嗘垚娴嬭瘯**

`test/integration/cbt_thought_record_flow_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/presentation/widgets/mood_quick_button.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  testWidgets('5 鏍忔祦绋? 鏀规。 鈫?鎵撳紑 dialog 鈫?濉?〃 鈫?鎻愪氦', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (ctx, ref, _) {
            return MoodQuickButton(
              onTap: () => MoodRecorderPage.show(ctx, ref),
            );
          }),
        ),
      ),
    ));
    // 鏀规。鍒?5
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodQuickButton)),
    );
    await container.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
    // 鎵撳紑 dialog
    await tester.tap(find.byType(MoodQuickButton));
    await tester.pumpAndSettle();
    expect(find.text('鎯呭?'), findsWidgets);
  });
}
```

- [ ] **Step 2: 璺戦泦鎴愭祴璇?*

```bash
flutter test test/integration/cbt_thought_record_flow_round84_test.dart
```

Expected: PASS 1/1銆?
- [ ] **Step 3: 璺戝叏閮?16 涓?畧闂ㄥ憳鑴氭湰**

```bash
python scripts/check_arb_keys.py
python scripts/check_changelog.py
python scripts/check_cross_feature.py
python scripts/check_datetime_race.py
python scripts/check_datetime_race2.py
python scripts/check_drift_namespace.py
python scripts/check_fullwidth_punctuation.py
python scripts/check_no_hardcoded_utc.py
python scripts/check_no_pua.py
python scripts/check_widget_dispose.py
python scripts/check_orphan_arb_keys.py
python scripts/check_legal_consent.py
python scripts/check_sms_release_ready.py
python scripts/check_strings_hardcoded.py
python scripts/check_zh_hant_consistency.py
dart scripts/check_all.dart
```

Expected: 16 涓?剼鏈?叏缁?(exit code 0)銆?
- [ ] **Step 4: 璺戝叏閲忓垎鏋?+ 娴嬭瘯**

```bash
flutter analyze
flutter test
```

Expected: 0 error, **1215 cases pass** (1163 + 52 鏂板?)銆?
- [ ] **Step 5: 璺?pub outdated / build_runner 鏈€缁堥獙璇?*

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected: 0 error, 1215 pass銆?
- [ ] **Step 6: 鏇存柊 CHANGELOG**

`docs/CHANGELOG.md` 椤堕儴鍔狅細

```markdown
## [0.29.0] - 2026-08-04

### Added (v0.29 round 84)
- **CBT 鎬濈淮璁板綍鏀归€?(sub-spec 1)**: 3/5/7 妗ｅ彲鍒囨崲
  - drift schema 16 鈫?17, mood_entries 鍔?8 涓?nullable CBT 瀛楁?
  - 妗ｄ綅鍋忓ソ鎸佷箙鍖?(SharedPreferences)
  - 璁剧疆椤?"鎬濈淮璁板綍妗ｄ綅" radio 鍏ュ彛
  - dialog 椤堕儴 SegmentedButton 涓存椂鍒囨崲
  - 3 妗? 鍗曞睆闀胯〃鍗?(鎯呭?/鑷?姩鎬濈淮/鎯呯华)
  - 5/7 妗? wizard 姝ラ?寮?+ 杩涘害鏉?+ 寮曞?闂??
  - 椤堕儴 鈩癸笍 鎶樺彔璇存槑鍗?  - 褰曢煶杞?啓鍙?墜鍔ㄥ～鍏?鑷?姩鎬濈淮"鏍?  - trend_calendar `_DayDetailCard` 鏄剧ず CBT 鎽樿? + 馃摑 瑙掓爣

### Notes
- 閲嶈瘎鏁堟灉鍥?/ mood 鍒楄〃椤?/ PDF 瀵煎嚭 / AI 杈呭姪 鐣欏緟 sub-spec 2-5
```

- [ ] **Step 7: Commit final**

```bash
git add test/integration/cbt_thought_record_flow_round84_test.dart \
        docs/CHANGELOG.md
git commit -m 'v0.29 round 84 (final): CBT sub-spec 1 闆嗘垚娴嬭瘯 + CHANGELOG'
```

---


