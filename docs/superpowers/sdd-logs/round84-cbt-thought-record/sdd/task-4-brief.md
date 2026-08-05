# Task 4 Brief — 公共 widget (CbtSectionField + CbtPromptSheet + CbtExplainerCard)

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: ac75e7a (task 1+2+3 完成)
- Task 1-3 已完成: schema 16→17 + ThoughtRecordLevel + CbtDraftState/provider
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0 error
- 项目用 AppTokens 集中颜色/间距/字体 (`lib/core/theme/app_tokens.dart`)
- 现有 widget test 走 ProviderScope override + MaterialApp + tester.pumpAndSettle

## 已有文件 / 上下文

- `lib/core/theme/app_tokens.dart` 已读
- 新建文件:
  - `lib/presentation/pages/mood/widgets/cbt_section_field.dart`
  - `lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`
  - `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`
- 新建测试: `test/presentation/pages/mood/cbt_widgets_round84_test.dart`

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 4 内部有 2 个 step (CbtSectionField + CbtExplainerCard widget test, 拆 2 commits)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-4-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 4: 鍏?叡 widget (CbtSectionField + CbtPromptSheet + CbtExplainerCard)

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_section_field.dart`
- Create: `lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`
- Create: `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`
- Test: `test/presentation/pages/mood/cbt_widgets_round84_test.dart`

**Interfaces:**
- Consumes: 鐜版湁 `AppTokens`
- Produces:
  - `CbtSectionField` 鈥?鏍囬? + 鈸?+ 鏂囨湰妗?+ prompt 搴撴寜閽?  - `CbtPromptSheet.show(context, prompts)` 鈥?bottom sheet 寮圭獥
  - `CbtExplainerCard` 鈥?椤堕儴 鈩癸笍 鎶樺彔鍗?
- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?鍏?叡 widget 娓叉煋**

`test/presentation/pages/mood/cbt_widgets_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';

void main() {
  testWidgets('CbtSectionField 鏄剧ず鏍囬? + 鈸?+ placeholder + prompt 鎸夐挳', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CbtSectionField(
          title: '鎯呭?',
          hint: '瑙﹀彂杩欎釜鎯虫硶鐨勪簨浠?,
          prompts: const ['闂??1', '闂??2'],
          onChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('鎯呭?'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('瑙﹀彂杩欎釜鎯虫硶鐨勪簨浠?), findsOneWidget);
    expect(find.text('?'), findsOneWidget);  // prompt 搴撴寜閽?  });

  testWidgets('CbtExplainerCard 榛樿?灞曞紑, 鐐瑰嚮鏀惰捣', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CbtExplainerCard(
          title: '浠€涔堟槸 CBT 鎬濈淮璁板綍锛?,
          body: 'CBT 鏄??鐭ヨ?涓虹枟娉?..',
        ),
      ),
    ));
    expect(find.text('浠€涔堟槸 CBT 鎬濈淮璁板綍锛?), findsOneWidget);
    expect(find.text('CBT 鏄??鐭ヨ?涓虹枟娉?..'), findsOneWidget);
    await tester.tap(find.text('浠€涔堟槸 CBT 鎬濈淮璁板綍锛?));
    await tester.pumpAndSettle();
    expect(find.text('CBT 鏄??鐭ヨ?涓虹枟娉?..'), findsNothing);
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/presentation/pages/mood/cbt_widgets_round84_test.dart
```

Expected: FAIL 鈥?`CbtSectionField` / `CbtExplainerCard` 涓嶅瓨鍦ㄣ€?
- [ ] **Step 3: 瀹炵幇 CbtSectionField**

`lib/presentation/pages/mood/widgets/cbt_section_field.dart`:

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 鍏?叡 section 瀛楁?
//
// 鏍囬? + 鈸?popup + 鏂囨湰妗?+ ? prompt 搴撴寜閽?// 5/7 鏍?wizard 姣忔?閮界敤杩欎釜缁勪欢

import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_prompt_sheet.dart';

class CbtSectionField extends StatelessWidget {
  final String title;
  final String hint;
  final List<String> prompts;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const CbtSectionField({
    super.key,
    required this.title,
    required this.hint,
    required this.prompts,
    required this.onChanged,
    this.initialValue,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTokens.textStyleLabel(context)),
            const SizedBox(width: AppTokens.spacingXxs),
            InkWell(
              onTap: () => _showInfoDialog(context),
              child: Icon(
                Icons.info_outline,
                size: AppTokens.iconSizeMicro,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXxs),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          controller: TextEditingController(text: initialValue ?? '')
            ..selection = TextSelection.collapsed(offset: (initialValue ?? '').length),
          onChanged: onChanged,
        ),
        if (prompts.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingXxs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => CbtPromptSheet.show(
                context, prompts: prompts, onSelected: onChanged,
              ),
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('寮曞?闂??'),
            ),
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('濂界殑'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 瀹炵幇 CbtPromptSheet**

`lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`:

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): prompt 搴?bottom sheet
//
// 鐐瑰嚮闂??杩藉姞鍒板綋鍓嶆枃鏈??鏈?熬 (涓嶆浛鎹?

import 'package:flutter/material.dart';

class CbtPromptSheet {
  CbtPromptSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<String> prompts,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: prompts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(prompts[i]),
            onTap: () {
              onSelected(prompts[i]);
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 瀹炵幇 CbtExplainerCard**

`lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`:

```dart
// v0.29 round 84 (CBT 鎬濈淮璁板綍): 椤堕儴 鈩癸笍 鎶樺彔璇存槑鍗?//
// 棣栨?浣跨敤榛樿?灞曞紑, 鐢ㄦ埛鍙?墜鍔ㄦ姌鍙? 灞曞紑鐘舵€佺敱鐖剁粍浠舵寔鏈?(CbtDraftState.showExplainer)

import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

class CbtExplainerCard extends StatelessWidget {
  final String title;
  final String body;
  final bool expanded;
  final VoidCallback onToggle;

  const CbtExplainerCard({
    super.key,
    required this.title,
    required this.body,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTokens.tintedPrimarySoft(context),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: AppTokens.spacingXxs),
                  Expanded(child: Text(title, style: AppTokens.textStyleLabel(context))),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppTokens.spacingXs),
                Text(body, style: AppTokens.textStyleBody(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/presentation/pages/mood/cbt_widgets_round84_test.dart
```

Expected: PASS 2/2銆?
- [ ] **Step 7: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1178 + 2 = 1180 cases pass銆?
- [ ] **Step 8: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_section_field.dart \
        lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart \
        lib/presentation/pages/mood/widgets/cbt_explainer_card.dart \
        test/presentation/pages/mood/cbt_widgets_round84_test.dart
git commit -m 'v0.29 round 84 (ui): CbtSectionField + CbtPromptSheet + CbtExplainerCard'
```

---


