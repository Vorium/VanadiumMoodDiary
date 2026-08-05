# Task 6 Brief — 5/7 栏 wizard UI

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: 0adeb52 (task 1-5 + 2 fixes 完成)
- Task 1-5 已完成: schema 16→17 + ThoughtRecordLevel + CbtDraftState + 公共 widget + 3 栏 mode UI
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0 error
- 现有 widget test 走 ProviderScope override + MaterialApp + tester.pumpAndSettle
- **已知坑**: Task 5 fix #1 已修 SegmentedButton SP sync 跟 dispose() reset 冲突, wizard 也走同一 dialog 路径, 同样要遵循

## 已有文件 / 上下文

- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart` (orchestrator, 已在 task 5 接 CbtThreeColumnMode)
- `lib/presentation/pages/mood/widgets/cbt_section_field.dart` (StatefulWidget, task 4 fix 修过 leak)
- `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`
- `lib/presentation/providers/cbt_providers.dart` (含 cbtDraftProvider / thoughtRecordLevelProvider)
- 新建文件: `lib/presentation/pages/mood/widgets/cbt_wizard.dart` (替换 task 5 的 stub)
- 新建测试: `test/presentation/pages/mood/cbt_wizard_round84_test.dart`

## 5 步 / 7 步映射 (来自 plan, 严格遵守)

**5 栏 5 步**:
- Step 0: situation
- Step 1: automaticThought
- Step 2: score (1-5) + evidenceFor + evidenceAgainst
- Step 3: alternativeThought + reratedScore (1-5)
- Step 4: 确认

**7 栏 7 步** (5 基础上加 2 步):
- Step 4: coreBelief
- Step 5: behaviorResponse
- Step 6: 确认

注意 step 编号从 0 开始 (5 栏 step 0..4, 7 栏 step 0..6).

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 6 内部有 2 个 step (wizard 渲染 / step 切换)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-6-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 6: 5/7 鏍?wizard UI

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_wizard.dart`
- Test: `test/presentation/pages/mood/cbt_wizard_round84_test.dart`

**Interfaces:**
- Consumes: `cbtDraftProvider`, `CbtSectionField`, `CbtExplainerCard`
- Produces: `CbtWizard` widget 鈥?5/7 鏍忔?楠ゅ紡甯冨眬

- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?wizard 姝ラ?鍒囨崲**

`test/presentation/pages/mood/cbt_wizard_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_wizard.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  testWidgets('5 鏍?wizard step 1 鏄剧ず 鎯呭? section', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
          return const Scaffold(body: CbtWizard());
        }),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('鎯呭?'), findsWidgets);
    expect(find.textContaining('绗?), findsOneWidget);  // Step X / 5
  });

  testWidgets('5 鏍?wizard step 鍒囨崲: 鐐瑰嚮涓嬩竴姝ヤ粠 鎯呭? 鈫?鑷?姩鎬濈淮', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
          return const Scaffold(body: CbtWizard());
        }),
      ),
    ));
    await tester.pumpAndSettle();
    // step 1: 鎯呭?, 濉?竴涓嬭Е鍙?firstEmptyStep 鈫?step 1
    await tester.enterText(find.byType(TextField).first, '寮€浼氳繜鍒?);
    await tester.tap(find.text('涓嬩竴姝?));
    await tester.pumpAndSettle();
    expect(find.text('閭ｄ竴鍒昏剳娴蜂腑闂?繃鐨勬兂娉?), findsOneWidget);
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/presentation/pages/mood/cbt_wizard_round84_test.dart
```

Expected: FAIL 鈥?`CbtWizard` 涓嶅瓨鍦ㄣ€?
- [ ] **Step 3: 瀹炵幇 CbtWizard**

`lib/presentation/pages/mood/widgets/cbt_wizard.dart`:

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 5/7 鏍?wizard
//
// 姝ラ?寮? 杩涘害鏉?+ 褰撳墠 step section + 涓婁竴/涓嬩竴姝ユ寜閽?// 5 鏍?5 姝? 7 鏍?7 姝?// 鍒囨。鐢辩埗缁勪欢 (mood_recorder_page) 閫氳繃 SegmentedButton 瑙﹀彂

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';

class CbtWizard extends ConsumerWidget {
  const CbtWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final totalSteps = state.level.columnCount;
    final isLastStep = state.stepIndex == totalSteps - 1;

    return Column(
      children: [
        // 杩涘害鏉?        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: LinearProgressIndicator(
            value: (state.stepIndex + 1) / totalSteps,
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            '绗?${state.stepIndex + 1} 姝?/ 鍏?$totalSteps 姝?,
            style: AppTokens.textStyleMicro(context),
          ),
        ),
        // 椤堕儴 鈩癸笍 鎶樺彔鍗?        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: CbtExplainerCard(
            title: '浠€涔堟槸 CBT 鎬濈淮璁板綍锛?,
            body: 'CBT锛堣?鐭ヨ?涓虹枟娉曪級鎬濈淮璁板綍甯?綘璇嗗埆骞堕噸鏋勮礋闈㈣嚜鍔ㄦ€濈淮銆俓n鎸?5 鏍忔爣鍑嗭細鍏堣?褰曟儏澧冧笌鎯虫硶锛屽啀鎵捐瘉鎹?敮鎸?鍙嶅?锛屾渶鍚庡啓涓嬫洿骞宠　鐨勬浛浠ｆ兂娉曘€?,
            expanded: state.showExplainer,
            onToggle: notifier.toggleExplainer,
          ),
        ),
        // 褰撳墠 step section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: _buildStep(context, state, notifier, l10n),
          ),
        ),
        // 涓婁竴/涓嬩竴姝?        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: state.stepIndex == 0
                    ? null
                    : () => notifier.setStep(state.stepIndex - 1),
                child: const Text('涓婁竴姝?),
              ),
              FilledButton(
                onPressed: () {
                  if (isLastStep) {
                    // 鎻愪氦 - 鐢辩埗缁勪欢 (mood_recorder_page) 鐩戝惉
                    Navigator.of(context).pop();
                  } else {
                    notifier.setStep(state.stepIndex + 1);
                  }
                },
                child: Text(isLastStep ? '淇濆瓨' : '涓嬩竴姝?),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, CbtDraftState state,
      CbtDraftNotifier notifier, AppLocalizations l10n) {
    final step = state.stepIndex;
    final level = state.level;

    // 5 鏍?5 姝?/ 7 鏍?7 姝?鏄犲皠
    if (step == 0) {
      return CbtSectionField(
        title: '鎯呭?',
        hint: '瑙﹀彂杩欎釜鎯虫硶鐨勪簨浠舵槸浠€涔堬紵鍙戠敓鍦ㄥ摢銆佷粈涔堟椂鍊欍€佹湁璋侊紵',
        prompts: const [],
        initialValue: state.draft.situation,
        onChanged: (v) => notifier.updateField(situation: v),
      );
    }
    if (step == 1) {
      return CbtSectionField(
        title: '鑷?姩鎬濈淮',
        hint: '閭ｄ竴鍒昏剳娴蜂腑闂?繃鐨勬兂娉曘€佸嵃璞℃垨淇″康鏄?粈涔堬紵',
        prompts: const [
          '濡傛灉浣犵殑濂芥湅鍙嬮亣鍒拌繖浜嬶紝浣犱細鎬庝箞鍔漈A锛?,
          '鏈€鍧?鏈€濂?鏈€鐜板疄鐨勭粨鏋滄槸浠€涔堬紵',
          '涓€骞村悗浣犺繕浼氳繖涔堟兂鍚楋紵',
        ],
        initialValue: state.draft.automaticThought,
        onChanged: (v) => notifier.updateField(automaticThought: v),
      );
    }
    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('鎯呯华 + 璇佹嵁', style: AppTokens.textStyleLabel(context)),
          const SizedBox(height: AppTokens.spacingSm),
          // score 閫夋嫨
          Wrap(
            spacing: AppTokens.spacingSm,
            children: List.generate(5, (i) {
              final score = i + 1;
              return ChoiceChip(
                label: Text('$score'),
                selected: state.draft.score == score,
                onSelected: (_) {
                  // notifier.updateScore(score) - 璧?score 鐜版湁璺?緞
                },
              );
            }),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '鏀?寔杩欎釜鎯虫硶鐨勮瘉鎹?,
            hint: '浠€涔堜簨鏀?寔杩欎釜鎯虫硶锛?,
            prompts: const [],
            initialValue: state.draft.evidenceFor,
            onChanged: (v) => notifier.updateField(evidenceFor: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '鍙嶅?杩欎釜鎯虫硶鐨勮瘉鎹?,
            hint: '浠€涔堜簨涓嶆敮鎸佽繖涓?兂娉曪紵',
            prompts: const [],
            initialValue: state.draft.evidenceAgainst,
            onChanged: (v) => notifier.updateField(evidenceAgainst: v),
          ),
        ],
      );
    }
    if (step == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CbtSectionField(
            title: '鏇夸唬鎬濈淮',
            hint: '濡傛灉浣犵殑濂芥湅鍙嬮亣鍒拌繖浜嬶紝浣犱細鎬庝箞鍔漈A锛?,
            prompts: const ['涓€骞村悗浣犺繕浼氳繖涔堟兂鍚楋紵', '鏈€鐜板疄鐨勭粨鏋滄槸浠€涔堬紵'],
            initialValue: state.draft.alternativeThought,
            onChanged: (v) => notifier.updateField(alternativeThought: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text('閲嶆柊璇勫垎 (1-5)', style: AppTokens.textStyleLabel(context)),
          Wrap(
            spacing: AppTokens.spacingSm,
            children: List.generate(5, (i) {
              final score = i + 1;
              return ChoiceChip(
                label: Text('$score'),
                selected: state.draft.reratedScore == score,
                onSelected: (_) {
                  notifier.updateField(reratedScore: score);
                },
              );
            }),
          ),
        ],
      );
    }
    if (step == 4 && level == ThoughtRecordLevel.five) {
      return Text('纭??: ${state.draft.situation ?? "(鏈?～)"}', style: AppTokens.textStyleBody(context));
    }
    if (step == 4 && level == ThoughtRecordLevel.seven) {
      return CbtSectionField(
        title: '鏍稿績淇″康',
        hint: '杩欎釜鎯虫硶鑳屽悗鏇存繁灞傜殑淇″康鏄?粈涔堬紵锛堝? "鎴戜笉澶熷ソ"锛?,
        prompts: const [],
        initialValue: state.draft.coreBelief,
        onChanged: (v) => notifier.updateField(coreBelief: v),
      );
    }
    if (step == 5) {
      return CbtSectionField(
        title: '琛屼负搴斿?',
        hint: '鎺ヤ笅鏉ヤ綘鎵撶畻鎬庝箞鍋氾紵',
        prompts: const ['娣卞懠鍚?5 娆?, '涓庝俊浠荤殑浜鸿亰鑱?, '鍋?10 鍒嗛挓姝ｅ康'],
        initialValue: state.draft.behaviorResponse,
        onChanged: (v) => notifier.updateField(behaviorResponse: v),
      );
    }
    if (step == 6) {
      return Text('纭??: ${state.draft.situation ?? "(鏈?～)"}', style: AppTokens.textStyleBody(context));
    }
    return const SizedBox.shrink();
  }
}
```

- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/presentation/pages/mood/cbt_wizard_round84_test.dart
```

Expected: PASS 2/2銆?
- [ ] **Step 5: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1181 + 2 = 1183 cases pass銆?
- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_wizard.dart \
        test/presentation/pages/mood/cbt_wizard_round84_test.dart
git commit -m 'v0.29 round 84 (ui): 5/7 鏍?wizard 姝ラ?寮?+ 杩涘害鏉?+ 寮曞?'
```

---


