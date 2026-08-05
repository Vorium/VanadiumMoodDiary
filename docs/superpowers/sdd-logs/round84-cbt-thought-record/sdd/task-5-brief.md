# Task 5 Brief — 3 栏 mode UI 改造

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: dcc1ef6 (task 1-4 + fix 完成)
- Task 1-4 已完成: schema + ThoughtRecordLevel + CbtDraftState + 公共 widget
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读 (已知坑: 跨 midnight DateTime 一次取, StreamSubscription 必 cancel, etc.)

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture (presentation 引用 widgets/pages 不引用 pages/{A}/)
- 守门员: `flutter analyze` 0 error
- 现有 widget test 走 ProviderScope override + MaterialApp + tester.pumpAndSettle
- 现有 4 维度 score chooser 在 `lib/presentation/pages/mood/widgets/mood_score_chooser.dart`, 复用现有 score 1-5 选择器, 不要重写

## 已有文件 / 上下文

- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` (orchestrator, 要改)
- `lib/presentation/pages/mood/widgets/mood_score_chooser.dart` (复用)
- `lib/presentation/pages/mood/widgets/cbt_section_field.dart` (Task 4)
- `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart` (新建)
- `lib/presentation/providers/cbt_providers.dart` (含 cbtDraftProvider, Task 3)
- `lib/presentation/pages/mood/mood_dialog.dart` (薄壳, 不动)

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 5 内部有 3 个 step (CbtThreeColumnMode 渲染 / mood_recorder_page 集成 / SegmentedButton)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-5-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 5: 3 鏍?mode UI 鏀归€?
**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart`
- Modify: `lib/presentation/pages/mood/widgets/mood_recorder_page.dart`
- Test: `test/presentation/pages/mood/cbt_three_column_round84_test.dart`

**Interfaces:**
- Consumes: `cbtDraftProvider` (NotifierProvider), `CbtSectionField` (Task 4)
- Produces: `CbtThreeColumnMode` widget 鈥?3 鏍?mode 涓嬬殑鍐呭?甯冨眬

- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?3 鏍?mode 娓叉煋**

`test/presentation/pages/mood/cbt_three_column_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_three_column_mode.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  testWidgets('3 鏍?mode 鏄剧ず score + situation + automaticThought 涓変釜 section', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (ctx, ref, _) {
            // 寮哄埗 3 鏍?mode
            ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.three);
            return const CbtThreeColumnMode();
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('浣犵幇鍦ㄧ殑鎰熷彈锛?), findsOneWidget);
    expect(find.text('鍙戠敓浜嗕粈涔堬紵'), findsOneWidget);
    expect(find.text('閭ｄ竴鍒昏剳娴烽噷闂?繃浠€涔堟兂娉曪紵'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/presentation/pages/mood/cbt_three_column_round84_test.dart
```

Expected: FAIL 鈥?`CbtThreeColumnMode` 涓嶅瓨鍦ㄣ€?
- [ ] **Step 3: 瀹炵幇 CbtThreeColumnMode**

`lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart`:

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 3 鏍?mode 鍐呭?甯冨眬
//
// 鍗曞睆闀胯〃鍗? score 鈶?+ situation 鈶?+ automaticThought 鈶?// 褰曢煶 + 鏍囩? + 淇濆瓨鎸夐挳鐢?mood_recorder_page 鍦ㄥ簳閮ㄦ彁渚?
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';

class CbtThreeColumnMode extends ConsumerWidget {
  const CbtThreeColumnMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      children: [
        // 鈶?鎯呯华鍒嗘暟 1-5
        Text('鈶?浣犵幇鍦ㄧ殑鎰熷彈锛?, style: AppTokens.textStyleLabel(context)),
        const SizedBox(height: AppTokens.spacingXs),
        // 澶嶇敤鐜版湁 score chooser
        Wrap(
          spacing: AppTokens.spacingSm,
          children: List.generate(5, (i) {
            final score = i + 1;
            return ChoiceChip(
              label: Text('$score'),
              selected: state.draft.score == score,
              onSelected: (_) {
                notifier.updateField();  // score 鏇存柊璧扮幇鏈夎矾寰?              },
            );
          }),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        // 鈶?鎯呭?
        CbtSectionField(
          title: '鈶?鍙戠敓浜嗕粈涔堬紵',
          hint: '瑙﹀彂杩欎釜鎯虫硶鐨勪簨浠舵槸浠€涔堬紵鍙戠敓鍦ㄥ摢銆佷粈涔堟椂鍊欍€佹湁璋侊紵',
          prompts: const [],
          initialValue: state.draft.situation,
          onChanged: (v) => notifier.updateField(situation: v),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        // 鈶?鑷?姩鎬濈淮
        CbtSectionField(
          title: '鈶?閭ｄ竴鍒昏剳娴烽噷闂?繃浠€涔堟兂娉曪紵',
          hint: '閭ｄ竴鍒昏剳娴蜂腑闂?繃鐨勬兂娉曘€佸嵃璞℃垨淇″康鏄?粈涔堬紵',
          prompts: const [
            '濡傛灉浣犵殑濂芥湅鍙嬮亣鍒拌繖浜嬶紝浣犱細鎬庝箞鍔漈A锛?,
            '鏈€鍧?鏈€濂?鏈€鐜板疄鐨勭粨鏋滄槸浠€涔堬紵',
            '涓€骞村悗浣犺繕浼氳繖涔堟兂鍚楋紵',
          ],
          initialValue: state.draft.automaticThought,
          onChanged: (v) => notifier.updateField(automaticThought: v),
        ),
      ],
    );
  }
}
```

> **娉?*锛歴core 閫?chip 鐨?`onSelected` 瀹為檯瑕佽蛋 `medication_notifier` 鎴?`mood_score_chooser` 宸叉湁鐨勭姸鎬併€?*杩欓噷鍏堝崰浣?`notifier.updateField()`锛孴ask 8 闆嗘垚鏃舵敼鎴?`notifier.updateScore(score)` 璧扮幇鏈夎矾寰?*銆?
- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/presentation/pages/mood/cbt_three_column_round84_test.dart
```

Expected: PASS 1/1锛?*娉?*锛歴core 娓叉煋鍙?兘鍥?`mood_score_chooser` 澶嶇敤闇€瑕佸井璋冿紝浣嗘湰娴嬭瘯鍙??鏌?3 涓?section 鏍囬?锛夈€?
- [ ] **Step 5: 鍦?mood_recorder_page.dart 闆嗘垚 3 鏍?mode**

`lib/presentation/pages/mood/widgets/mood_recorder_page.dart`:

- 椤堕儴鍔?`SegmentedButton<ThoughtRecordLevel>` (3 鏍?/ 5 鏍?/ 7 鏍?
- dialog 鍐呭?: `level == three` 鈫?`CbtThreeColumnMode`, `level == five/seven` 鈫?`CbtWizard` (Task 6)
- 褰曢煶 / 鏍囩? / 淇濆瓨鎸夐挳淇濇寔鐜版湁琛屼负

浠ｇ爜缁撴瀯锛?
```dart
class _MoodRecorderPageState extends ConsumerState<MoodRecorderPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cbtState = ref.watch(cbtDraftProvider);
    final cbtNotifier = ref.read(cbtDraftProvider.notifier);
    final levelNotifier = ref.read(thoughtRecordLevelProvider.notifier);

    return Dialog(
      child: Column(
        children: [
          // 椤堕儴: 妗ｄ綅鍒囨崲 + 褰曢煶鎸夐挳
          _buildHeader(cbtState, cbtNotifier, levelNotifier),
          // 涓?棿: 鍐呭? (3 鏍?vs wizard)
          Expanded(
            child: switch (cbtState.level) {
              ThoughtRecordLevel.three => const CbtThreeColumnMode(),
              ThoughtRecordLevel.five || ThoughtRecordLevel.seven =>
                const CbtWizard(),
            },
          ),
          // 搴曢儴: 鏍囩? + 淇濆瓨
          _buildFooter(...),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1180 + 1 = 1181 cases pass銆?
- [ ] **Step 7: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart \
        lib/presentation/pages/mood/widgets/mood_recorder_page.dart \
        test/presentation/pages/mood/cbt_three_column_round84_test.dart
git commit -m 'v0.29 round 84 (ui): 3 鏍?mode 鍗曞睆闀胯〃鍗?+ SegmentedButton'
```

---


