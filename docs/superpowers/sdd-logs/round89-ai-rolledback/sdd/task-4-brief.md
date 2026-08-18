# Task 4 Brief — CbtWizard 集成 3 个 AI 按钮

> Source of truth.

## Context
- Worktree: D:\Batch\chroniccare\.worktrees\feat-cbt-ai
- Task 1+2+3 done: AiService + DeepSeekProvider + AiSettings (commit a6cdd33, 1502 pass)
- baseline 1502 pass / 0 fail (R89 Task 3 fix 后)
- Goal: 3 个 AI 按钮插入 wizard — step 3 替代思维 / step 4 (7 栏) 核心信念 / step 5 行为应对
- 用户点按钮 → 调 AiService.generateAll → 拿对应字段 → 填到 CbtSectionField → toast 反馈
- 复用模式: 跟 R85 cbt_wizard + cbt_section_field 模式一致

## Global Constraints
- Flutter 3.41.9 / Dart 3.12.2 / 4-layer architecture
- 守门员: `flutter analyze` 0 error, `flutter test` 全过, 16+ 守门全绿
- TDD: red → green → commit
- 复用现有 cbt_wizard.dart 结构 (R85 落地) — 不重构,只插入 3 个按钮
- 不引入新的 service (AiService 已由 Task 1 完成,通过 Riverpod 注入)
- 不动 wizard 主流程 (state machine, step transition, save logic 都不变)
- ARB keys: 3 个 wizard 按钮 label 中文 placeholder ("AI 建议替代思维" / "AI 提取核心信念" / "AI 建议行动" + "AI 生成中..."), Task 5 一次性换 l10n key

## TDD
red → green → commit. 1 commit.

## Report
Write to: `.superpowers/sdd/task-4-report.md`
Reply: Status + commit SHA + 1-line test summary + concerns.

---

## Task 4: CbtWizard 集成 3 个 AI 按钮

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart` (reusable button)
- Create: `lib/presentation/providers/ai_service_provider.dart` (Riverpod 注入 AiService)
- Modify: `lib/presentation/pages/mood/widgets/cbt_wizard.dart` (3 处插入 CbtAiGenerateButton)
- Test: `test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart` (3 case)

**Interfaces (summary):**
- `CbtAiGenerateButton({required _CbtAiField field, required String label})` — StatelessWidget
  - `_CbtAiField` enum: alternativeThought / coreBelief / actionSuggestion
  - 内置 loading / disabled 状态
  - 点 → 调 `ref.read(aiServiceProvider).generateAll(...)` → 拿对应字段 → `notifier.updateField(...)` → snackbar 反馈
- `aiServiceProvider` — Provider<AiService> 注入 DeepSeekProvider(apiKey, modelName) (apiKey 走 aiSettingsRepositoryProvider.getApiKey())
- 复用 Task 1 `AiService` + Task 2 `DeepSeekProvider` + Task 3 `AiSettings` + `aiSettingsRepositoryProvider`

### Step 1: 写失败测试

`test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/services/ai/ai_provider.dart';
import 'package:chroniccare/core/data/services/ai/ai_response.dart';
import 'package:chroniccare/core/data/services/ai/ai_service.dart';
import 'package:chroniccare/domain/entities/ai_settings.dart';  // 修复后重命名
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_ai_generate_button.dart';
import 'package:chroniccare/presentation/providers/ai_service_provider.dart';
import 'package:chroniccare/presentation/providers/ai_settings_provider.dart';

class _MockProvider implements AiProvider {
  String response;
  _MockProvider(this.response);
  @override
  Future<String> call(String systemPrompt, String userPrompt) async => response;
}

class _FakeSettingsNotifier extends AsyncNotifier<AiSettings>
    implements AiSettingsNotifier {
  @override
  Future<AiSettings> build() async => const AiSettings(
        enabled: true,
        provider: 'deepseek',
        modelName: 'deepseek-chat',
        consentVersion: '1.0',
        consentAcceptedAt: '2026-08-05T00:00:00Z',
      );
  @override
  Future<void> setEnabled(bool v) async {}
  @override
  Future<void> setApiKey(String key) async {}
  @override
  Future<void> setModelName(String name) async {}
  @override
  Future<void> recordConsent() async {}
  @override
  Future<void> clear() async {}
}

void main() {
  testWidgets('CbtAiGenerateButton(alternativeThought) 点 → 填入 CbtSectionField', (tester) async {
    final mock = _MockProvider('{"text": "平衡一点的想法"}');
    final svc = AiService(provider: mock);
    final fieldKey = GlobalKey<_TestFieldState>();  // see below

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSettingsProvider.overrideWith(() => _FakeSettingsNotifier()),
          aiServiceProvider.overrideWithValue(svc),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _TestField(key: fieldKey, initialValue: ''),
                CbtAiGenerateButton(
                  field: CbtAiField.alternativeThought,
                  label: 'AI 建议替代思维',
                  onGenerate: (text) => fieldKey.currentState!.setValue(text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('AI 建议替代思维'));
    await tester.pump();  // start loading
    await tester.pumpAndSettle();
    // mockProvider 返回 '{"text": "平衡一点的想法"}' — service 不解析, 直接 string 写入
    // 测试 verify 写入 string (不是只 strip 了 {"text": ...} 的 value)
    expect(fieldKey.currentState!.value, contains('平衡一点的想法'));
  });

  testWidgets('AI 未启用 (enabled=false) 时按钮 disabled', (tester) async {
    // override _FakeSettingsNotifier return enabled=false
    // ...
  });

  testWidgets('API key 未设置 时按钮 disabled', (tester) async {
    // override getApiKey() return null
    // ...
  });
}

// 测试用 _TestField
class _TestField extends StatefulWidget {
  const _TestField({super.key, required this.initialValue});
  final String initialValue;
  @override
  State<_TestField> createState() => _TestFieldState();
}

class _TestFieldState extends State<_TestField> {
  late String _value = widget.initialValue;
  String get value => _value;
  void setValue(String v) => setState(() => _value = v);
  @override
  Widget build(BuildContext context) => Text(_value);
}
```

> 简化的 1 case 草图,实际写 3 case (alternativeThought 填入 / enabled=false 禁用 / apiKey 缺失禁用)。

### Step 2: 跑测试验证失败

```bash
flutter test test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
```

Expected: FAIL (CbtAiGenerateButton / aiServiceProvider not found).

### Step 3: 实现 aiServiceProvider (Riverpod 注入)

`lib/presentation/providers/ai_service_provider.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): AiService Riverpod provider
//
// 注入: DeepSeekProvider(apiKey: ..., modelName: ...) → 包 AiService
// apiKey 从 aiSettingsRepositoryProvider.getApiKey() 拿 (FlutterSecureStorage)
// 若 apiKey 为空 → provider 抛 StateError (UI 显示 "请先设置 API Key")

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/ai/ai_service.dart';
import 'package:chroniccare/core/data/services/ai/deepseek_provider.dart';
import 'package:chroniccare/presentation/providers/ai_settings_provider.dart';

final aiServiceProvider = FutureProvider<AiService>((ref) async {
  final settings = await ref.watch(aiSettingsProvider.future);
  if (!settings.enabled) {
    throw StateError('AI 未启用');
  }
  final repo = ref.read(aiSettingsRepositoryProvider);
  final apiKey = await repo.getApiKey();
  if (apiKey == null || apiKey.isEmpty) {
    throw StateError('请先设置 API Key');
  }
  return AiService(
    provider: DeepSeekProvider(apiKey: apiKey, modelName: settings.modelName),
  );
});
```

### Step 4: 实现 CbtAiGenerateButton

`lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): CBT wizard AI 按钮
//
// 3 处插入: step 3 替代思维 / step 4 (7 栏) 核心信念 / step 5 行为应对
// 模式: 跟 cbt_section_field.dart 同 ConsumerStatefulWidget + _Generating 状态
// 点 → 调 aiServiceProvider → 拿对应字段 → onGenerate callback (填到 CbtSectionField)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/ai/ai_response.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/ai_service_provider.dart';

enum CbtAiField { alternativeThought, coreBelief, actionSuggestion }

class CbtAiGenerateButton extends ConsumerStatefulWidget {
  final CbtAiField field;
  final String label;
  final void Function(String text) onGenerate;

  const CbtAiGenerateButton({
    super.key,
    required this.field,
    required this.label,
    required this.onGenerate,
  });

  @override
  ConsumerState<CbtAiGenerateButton> createState() => _CbtAiGenerateButtonState();
}

class _CbtAiGenerateButtonState extends ConsumerState<CbtAiGenerateButton> {
  bool _generating = false;

  String? _extractField(AiResponse response) {
    switch (widget.field) {
      case CbtAiField.alternativeThought: return response.alternativeThought;
      case CbtAiField.coreBelief:          return response.coreBelief;
      case CbtAiField.actionSuggestion:    return response.actionSuggestion;
    }
  }

  Future<void> _onTap() async {
    setState(() => _generating = true);
    try {
      final svcAsync = ref.read(aiServiceProvider);
      final svc = await svcAsync.future;
      // 1 失败不阻塞: 拿 5 字段, 哪个非空填哪个
      final response = await svc.generateAll(
        score: 0,  // wizard 调用时拿当前 score (Task 4 implementer 决定怎么传)
        tags: const [],
        cbtLevel: 7,
      );
      final text = _extractField(response);
      if (text != null && text.isNotEmpty && mounted) {
        widget.onGenerate(text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.label} 已生成')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.label} 暂不可用, 请稍后再试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 生成失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final svcAsync = ref.watch(aiServiceProvider);
    final disabled = _generating || svcAsync.hasError;

    return FilledButton.tonalIcon(
      onPressed: disabled ? null : _onTap,
      icon: _generating
          ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome),
      label: Text(_generating ? 'AI 生成中...' : widget.label),
    );
  }
}
```

### Step 5: 修改 cbt_wizard.dart 插入 3 处按钮

`lib/presentation/pages/mood/widgets/cbt_wizard.dart`:

在 step 3 (替代思维) CbtSectionField 后插入:
```dart
CbtAiGenerateButton(
  field: CbtAiField.alternativeThought,
  label: 'AI 建议替代思维',
  onGenerate: (text) => notifier.updateField(alternativeThought: text),
),
```

在 step 4 (7 栏) 核心信念 CbtSectionField 后插入:
```dart
CbtAiGenerateButton(
  field: CbtAiField.coreBelief,
  label: 'AI 提取核心信念',
  onGenerate: (text) => notifier.updateField(coreBelief: text),
),
```

在 step 5 行为应对 CbtSectionField 后插入:
```dart
CbtAiGenerateButton(
  field: CbtAiField.actionSuggestion,
  label: 'AI 建议行动',
  onGenerate: (text) => notifier.updateField(behaviorResponse: text),
),
```

(具体插入位置看 cbt_wizard.dart step 3 / 4 / 5 现有结构。)

### Step 6: 跑测试验证通过

```bash
flutter test test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
```

Expected: PASS (3 case)。

### Step 7: 跑全测 + analyze + 守门员

```bash
flutter test
flutter analyze
python scripts/check_*.py
```

Expected: 1505+ pass (1502 + 3 new), 0 fail, 0 analyzer error, 16+ 守门全绿。

### Step 8: Commit

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
git add lib/presentation/providers/ai_service_provider.dart \
        lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart \
        lib/presentation/pages/mood/widgets/cbt_wizard.dart \
        test/presentation/pages/mood/cbt_ai_generate_button_round89_test.dart
git commit -m "v0.30 round 89 (wizard): 3 个 AI 按钮 (替代思维 / 核心信念 / 行动建议) + aiServiceProvider + 3 test"
```

---

## 已知坑 (R89 Task 4)

1. **cbt_wizard.dart 已 247 行, 改 3 处要小心**: 改动只在 step 3 / 4 (7 栏) / 5 现有 CbtSectionField 后加一行 Column child。不要重构 step 逻辑。
2. **aiServiceProvider 抛 StateError**: UI 看 `svcAsync.hasError` 决定 disabled。要看 Task 3 修后是否已稳定。
3. **3 字段独立**: 1 个 AI 失败 (e.g. 核心信念 null) 不应影响其他 2 个 — CbtAiGenerateButton 各自 try/catch, 不共享一次 generateAll。**或者**: 共享一次 generateAll (省 4 次 HTTP), 各自提取对应字段 — Task 4 implementer 决定哪个更优。
4. **score 参数**: wizard 调用时 score 是用户当前情绪分数 (R85 draft 已有)。Task 4 决定怎么传 (constructor 参数 / ref.read moodDraft / 全局等)。
5. **mounted check**: `_onTap` 内多次 `mounted` check, 避免 `use_build_context_synchronously` analyzer warning。
6. **Loading 状态**: 用 `CircularProgressIndicator` 内嵌 button (16x16), 跟 R85 其他 loading 一致 (emil 设计 token)。
7. **跨 feature import**: wizard 改 3 处 + widget 新建, 都是 `presentation/pages/mood/`, 0 跨 feature (✓ R17 守门员)。
8. **ARB key 占位**: 3 个按钮 label + "AI 生成中" 4 个 string 中英 placeholder, Task 5 一次性换 16 个 l10n key。

## 跟其他 task 的契约

- Task 1+2 (AiService + DeepSeekProvider) — 不动,通过 Riverpod 注入
- Task 3 (AiSettings) — 读 `aiSettingsRepositoryProvider.getApiKey()` 拿 key
- Task 5 (i18n) — 4 个 wizard string placeholder 待换
- 不动 cbt_wizard 的 step 逻辑 / 状态机 / 保存流程

## 不在 scope

- ❌ cbt_wizard.dart 重构
- ❌ wizard 保存流程改动
- ❌ ARB 国际化 (Task 5)
- ❌ 流式响应 (普通 POST + Future.wait)
- ❌ 多 provider (DeepSeek only)
