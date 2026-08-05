# Task 8 Brief — trend_calendar 集成

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: 2dacff2 (task 1-7 完成)
- Task 1-7 已完成: schema + ThoughtRecordLevel + CbtDraftState + 公共 widget + 3/5/7 栏 UI + settings radio
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0 error
- 现有 trend_calendar `_DayDetailCard` 在 `lib/presentation/pages/trend/trend_calendar.dart`, 渲染当天 mood entry
- 跨 feature import: trend 可引用 presentation/widgets 和 presentation/providers, 不可引用 mood 私有 widget; 也不可 import domain/ 之外 (因为已 OK)

## 已有文件 / 上下文

- `lib/presentation/pages/trend/trend_calendar.dart` (要改 _DayDetailCard)
- `lib/domain/entities/mood_entry_entity.dart` (Task 1 加了 isCbtRecord / cbtLevel / scoreShift)
- 新建测试: `test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart`

## i18n 注意

- "CBT 5 栏" / "CBT 7 栏" badge 用 ARB `moodCbtChipBadge5` / `moodCbtChipBadge7` (Task 9 才加)
- 临时用硬编码中文字符串, 注释留 TODO

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 8 内部有 1 个 step (DayDetailCard 集成 + test)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-8-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 8: trend_calendar 闆嗘垚

**Files:**
- Modify: `lib/presentation/pages/trend/trend_calendar.dart`
- Test: `test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart`

**Interfaces:**
- Consumes: `MoodEntryEntity.isCbtRecord` / `cbtLevel` / `scoreShift`, ARB `moodCbtChipBadge*` / `moodCbtSection*`
- Produces: trend_calendar 鍗曞厓鏍?+ `_DayDetailCard` 灞曠ず 5/7 鏍?mood entry 鐨?CBT 鎽樿?

- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?DayDetailCard 鏄剧ず CBT 瀛楁?**

`test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/trend/trend_calendar.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  testWidgets('5 鏍?mood entry 鍦?_DayDetailCard 鏄剧ず CBT 鎽樿?', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1, timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 4,
        situation: '寮€浼氳繜鍒?, automaticThought: '澶у?瑙夊緱鎴戜笉鍙?潬',
        evidenceFor: '涓婃?涔熻繜鍒?, evidenceAgainst: '杩囧幓涓€骞村彧杩熷埌涓€娆?,
        alternativeThought: '鍋跺皵涓€娆℃?甯?, reratedScore: 3,
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400, height: 600,
          child: _TestDayDetailCard(
            date: DateTime(2026, 8, 4),
            moodEntries: entries,
          ),
        ),
      ),
    ));
    expect(find.text('CBT 5 鏍?), findsOneWidget);
    expect(find.text('鎯呭?: 寮€浼氳繜鍒?), findsOneWidget);
    expect(find.text('鑷?姩鎬濈淮: 澶у?瑙夊緱鎴戜笉鍙?潬'), findsOneWidget);
  });

  testWidgets('3 鏍?mood entry 涓嶆樉绀?CBT 瑙掓爣', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1, timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 3, note: '鏅?€氳?褰?,
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400, height: 600,
          child: _TestDayDetailCard(
            date: DateTime(2026, 8, 4),
            moodEntries: entries,
          ),
        ),
      ),
    ));
    expect(find.text('CBT 5 鏍?), findsNothing);
  });
}

class _TestDayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<MoodEntryEntity> moodEntries;
  const _TestDayDetailCard({required this.date, required this.moodEntries});
  @override
  Widget build(BuildContext context) {
    return _DayDetailCard(
      date: date,
      allCheckIns: const [],
      moodEntries: moodEntries,
      medications: const [],
    );
  }
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
```

Expected: FAIL 鈥?`_DayDetailCard` 涓嶆樉绀?CBT 瀛楁?銆?
- [ ] **Step 3: 鏀?_DayDetailCard 娓叉煋 CBT 鎽樿?**

`lib/presentation/pages/trend/trend_calendar.dart` 鍦?`_DayDetailCard.build` 鍐咃紙moodEntries 鍒楄〃娓叉煋澶勶級鍔狅細

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 鍦?mood entry 琛屼笅灞曞紑 CBT 鎽樿?
if (entry.isCbtRecord) ...[
  const SizedBox(height: AppTokens.spacingXxs),
  Wrap(
    spacing: AppTokens.spacingXxs,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTokens.tintedPrimaryDeep(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          entry.cbtLevel == 7 ? 'CBT 7 鏍? : 'CBT 5 鏍?,
          style: AppTokens.textStyleMicro(context).copyWith(
            color: AppTokens.primaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  ),
  if (entry.situation != null) Text('鎯呭?: ${entry.situation}'),
  if (entry.automaticThought != null) Text('鑷?姩鎬濈淮: ${entry.automaticThought}'),
  if (entry.evidenceFor != null) Text('鏀?寔璇佹嵁: ${entry.evidenceFor}'),
  if (entry.evidenceAgainst != null) Text('鍙嶅?璇佹嵁: ${entry.evidenceAgainst}'),
  if (entry.alternativeThought != null) Text('鏇夸唬鎬濈淮: ${entry.alternativeThought}'),
  if (entry.reratedScore != null)
    Text('閲嶆柊璇勫垎: ${entry.reratedScore} (鍘?${entry.score})'),
  if (entry.coreBelief != null) Text('鏍稿績淇″康: ${entry.coreBelief}'),
  if (entry.behaviorResponse != null) Text('琛屼负搴斿?: ${entry.behaviorResponse}'),
],
```

- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
```

Expected: PASS 2/2銆?
- [ ] **Step 5: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1185 + 2 = 1187 cases pass銆?
- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/trend/trend_calendar.dart \
        test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
git commit -m 'v0.29 round 84 (trend): _DayDetailCard 鏄剧ず CBT 5/7 鏍忔憳瑕?
```

---


