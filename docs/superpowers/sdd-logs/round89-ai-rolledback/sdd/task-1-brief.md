# Task 1 Brief — AiService + abstract + 5 prompts + mock test

> Source of truth.

## Context
- Worktree: D:\Batch\chroniccare\.worktrees\feat-cbt-ai
- Task 0 done: spec/plan committed (e42efcf)
- baseline 1487 pass / 0 fail (R88)
- Goal: 5 个 AI 能力 (替代思维 / 情绪识别 / 认知扭曲 / 核心信念 / 行动建议) 的核心 — AiService + abstract AiProvider + 5 prompt + mock test

## Global Constraints
- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture (本 task 全在 `core/data/services/ai/`,零 presentation 依赖)
- 守门员: `flutter analyze` 0 error, `flutter test` 全过
- TDD: red → green → commit
- **不测真实 LLM** — mock HTTP response
- 脱敏: 只发 {score, tags, cbtLevel} 给 LLM, 不发 note / 自动思维原文

## TDD
red → green → commit. 1 commit. **1 失败不阻塞其他** 是本 task 关键设计.

## Report
Write to: `.superpowers/sdd/task-1-report.md`
Reply: Status (DONE / DONE_WITH_CONCERNS / BLOCKED) + commit SHA + 1-line test summary + concerns.

---

## Task 1: AiService + abstract + 5 prompt + mock test

**Files:**
- Create: `lib/core/data/services/ai/ai_service.dart`
- Create: `lib/core/data/services/ai/ai_provider.dart`
- Create: `lib/core/data/services/ai/ai_response.dart`
- Create: `lib/core/data/services/ai/prompts/_loader.dart` (5 prompt 硬编码常量,跟 md 文件同步)
- Create: `lib/core/data/services/ai/prompts/alternative_thought.md` (5 prompt 文档备份,人读)
- Create: `lib/core/data/services/ai/prompts/emotion_recognition.md`
- Create: `lib/core/data/services/ai/prompts/cognitive_distortion.md`
- Create: `lib/core/data/services/ai/prompts/core_belief.md`
- Create: `lib/core/data/services/ai/prompts/action_suggestion.md`
- Test: `test/core/data/services/ai/ai_service_round89_test.dart`

**Interfaces:**
- `class AiResponse { final String? alternativeThought; final String? emotion; final String? cognitiveDistortion; final String? coreBelief; final String? actionSuggestion; }` — 全 nullable
- `abstract class AiProvider { Future<String> call(String systemPrompt, String userPrompt); }`
- `class AiService { final AiProvider provider; Future<AiResponse> generateAll({required int score, required List<String> tags, int? cbtLevel}); }`

### Step 1: 写失败测试

`test/core/data/services/ai/ai_service_round89_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/ai/ai_service.dart';
import 'package:chroniccare/core/data/services/ai/ai_response.dart';
import 'package:chroniccare/core/data/services/ai/ai_provider.dart';

class _MockProvider implements AiProvider {
  String? lastSystemPrompt;
  String? lastUserPrompt;
  String? mockResponse;
  Exception? mockException;
  int callCount = 0;

  @override
  Future<String> call(String systemPrompt, String userPrompt) async {
    callCount++;
    lastSystemPrompt = systemPrompt;
    lastUserPrompt = userPrompt;
    if (mockException != null) throw mockException!;
    return mockResponse ?? '';
  }
}

class _CountingProvider implements AiProvider {
  // 第 1 个 call 抛, 其他 4 个正常 — 验证 1 失败不阻塞其他
  final bool alternatingException;
  int callCount = 0;
  _CountingProvider({this.alternatingException = false});

  @override
  Future<String> call(String systemPrompt, String userPrompt) async {
    callCount++;
    if (alternatingException && callCount == 1) {
      throw Exception('mock fail on first call');
    }
    return '{"text": "示例回复"}';
  }
}

void main() {
  test('5 prompt 并行调用, 5 字段全有', () async {
    final mock = _MockProvider();
    mock.mockResponse = '{"text": "示例回复"}';
    final svc = AiService(provider: mock);
    final result = await svc.generateAll(score: 2, tags: ['焦虑'], cbtLevel: 5);
    expect(mock.callCount, 5);
    expect(result.alternativeThought, isNotNull);
    expect(result.emotion, isNotNull);
    expect(result.cognitiveDistortion, isNotNull);
    expect(result.coreBelief, isNotNull);
    expect(result.actionSuggestion, isNotNull);
  });

  test('1 prompt 失败, 其他 4 个继续', () async {
    final mock = _CountingProvider(alternatingException: true);
    final svc = AiService(provider: mock);
    final result = await svc.generateAll(score: 3, tags: [], cbtLevel: 7);
    expect(mock.callCount, 5);
    expect(result.alternativeThought, isNull);  // 第 1 个失败
    expect(result.emotion, isNotNull);
    expect(result.cognitiveDistortion, isNotNull);
    expect(result.coreBelief, isNotNull);
    expect(result.actionSuggestion, isNotNull);
  });

  test('user prompt 脱敏 — 不含 note / automaticThought', () async {
    final mock = _MockProvider();
    mock.mockResponse = 'ok';
    final svc = AiService(provider: mock);
    await svc.generateAll(score: 1, tags: ['失眠'], cbtLevel: 5);
    // user prompt 只应含 {score, tags, cbtLevel}, 不含任何 user note 字段
    expect(mock.lastUserPrompt, contains('情绪分数'));
    expect(mock.lastUserPrompt, contains('失眠'));
    expect(mock.lastUserPrompt, contains('CBT 档位'));
    expect(mock.lastUserPrompt, isNot(contains('note')));
    expect(mock.lastUserPrompt, isNot(contains('automaticThought')));
    expect(mock.lastUserPrompt, isNot(contains('situation')));
  });
}
```

### Step 2: 跑测试验证失败

```bash
flutter test test/core/data/services/ai/ai_service_round89_test.dart
```

Expected: FAIL (AiService / AiResponse / AiProvider not found).

### Step 3: 实现 AiResponse + abstract AiProvider

`lib/core/data/services/ai/ai_response.dart`:

```dart
/// v0.30 round 89 (sub-spec 5 CBT AI 辅助): 5 个能力 DTO
///
/// 5 字段全部 nullable — 单 prompt 失败只影响对应字段, 其他 4 个字段继续.
class AiResponse {
  final String? alternativeThought;  // 替代思维
  final String? emotion;             // 情绪识别
  final String? cognitiveDistortion; // 认知扭曲
  final String? coreBelief;          // 核心信念
  final String? actionSuggestion;    // 行动建议

  const AiResponse({
    this.alternativeThought,
    this.emotion,
    this.cognitiveDistortion,
    this.coreBelief,
    this.actionSuggestion,
  });

  /// 5 字段中至少 1 个非空
  bool get hasAny =>
      alternativeThought != null ||
      emotion != null ||
      cognitiveDistortion != null ||
      coreBelief != null ||
      actionSuggestion != null;
}
```

`lib/core/data/services/ai/ai_provider.dart`:

```dart
/// v0.30 round 89: AI provider 抽象接口
///
/// 单方法: system prompt + user prompt → 完整 LLM 回复 (string).
/// 实现方负责 HTTP 细节 (DeepSeekProvider) 或 mock (test).
abstract class AiProvider {
  Future<String> call(String systemPrompt, String userPrompt);
}
```

### Step 4: 实现 AiService

`lib/core/data/services/ai/ai_service.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): 5 个 prompt 并行调用
//
// 脱敏: 只发 {score, tags, cbtLevel} 给 LLM, 不发 note / 自动思维原文
// Fail-safe: 1 个失败只 toast 该能力, 其他 4 个继续
// 设计: Future.wait(eagerError: false) + _safeCall 内部 try-catch 双层保护

import 'package:chroniccare/core/data/services/ai/ai_provider.dart';
import 'package:chroniccare/core/data/services/ai/ai_response.dart';
import 'package:chroniccare/core/data/services/ai/prompts/_loader.dart';

class AiService {
  final AiProvider provider;
  AiService({required this.provider});

  Future<AiResponse> generateAll({
    required int score,
    required List<String> tags,
    int? cbtLevel,
  }) async {
    final userPrompt = _buildUserPrompt(score: score, tags: tags, cbtLevel: cbtLevel);
    final prompts = await PromptLoader.loadAll();

    final results = await Future.wait(
      [
        _safeCall(prompts.alternativeThought, userPrompt),
        _safeCall(prompts.emotionRecognition, userPrompt),
        _safeCall(prompts.cognitiveDistortion, userPrompt),
        _safeCall(prompts.coreBelief, userPrompt),
        _safeCall(prompts.actionSuggestion, userPrompt),
      ],
      eagerError: false,  // 1 个失败不阻塞其他
    );

    return AiResponse(
      alternativeThought: results[0],
      emotion: results[1],
      cognitiveDistortion: results[2],
      coreBelief: results[3],
      actionSuggestion: results[4],
    );
  }

  Future<String?> _safeCall(String systemPrompt, String userPrompt) async {
    try {
      return await provider.call(systemPrompt, userPrompt);
    } catch (_) {
      return null;
    }
  }

  String _buildUserPrompt({
    required int score,
    required List<String> tags,
    int? cbtLevel,
  }) {
    return '用户输入 (脱敏后,仅含元数据):\n'
        '- 情绪分数: $score / 5\n'
        '- 情绪标签: ${tags.isEmpty ? "(无)" : tags.join(", ")}\n'
        '- CBT 档位: ${cbtLevel ?? "(未选)"}\n'
        '\n请根据以上信息生成回复。';
  }
}
```

### Step 5: 5 prompt 文件 + loader

`lib/core/data/services/ai/prompts/_loader.dart`:

```dart
/// v0.30 round 89: 5 个 CBT AI 能力 prompt 集中管理
///
/// 每个 prompt 是一段 CBT 治疗师角色指令,要求 LLM 输出 JSON {"text": "..."}.
/// 5 个 prompt 共享同一 user prompt (脱敏后的 {score, tags, cbtLevel}).
class Prompts {
  final String alternativeThought;
  final String emotionRecognition;
  final String cognitiveDistortion;
  final String coreBelief;
  final String actionSuggestion;

  const Prompts({
    required this.alternativeThought,
    required this.emotionRecognition,
    required this.cognitiveDistortion,
    required this.coreBelief,
    required this.actionSuggestion,
  });
}

class PromptLoader {
  static Future<Prompts> loadAll() async {
    return const Prompts(
      alternativeThought:
          '你是 CBT 治疗助手. 根据用户给定的情绪分数+标签+CBT 档位, '
          '生成 1 个更平衡的替代思维 (50 字以内). '
          '只输出 JSON {"text": "..."},不要其他文字.',
      emotionRecognition:
          '你是 CBT 治疗助手. 根据用户给定的情绪分数+标签, '
          '识别具体情绪词 (如 焦虑/沮丧/愤怒/悲伤). '
          '只输出 JSON {"text": "..."},不要其他文字.',
      cognitiveDistortion:
          '你是 CBT 治疗助手. 从 11 种 Beck 认知扭曲 '
          '(全或无/灾难化/过度概括/心理过滤/贬低正面/跳跃式结论/'
          '放大或缩小/情绪化推理/应该论/标签化/个人化) 中识别 1 个最可能的. '
          '只输出 JSON {"text": "..."},不要其他文字.',
      coreBelief:
          '你是 CBT 治疗助手. 根据用户给定的情绪分数+标签+7 档 CBT, '
          '提取可能的核心信念 (15 字以内). '
          '只输出 JSON {"text": "..."},不要其他文字.',
      actionSuggestion:
          '你是 CBT 治疗助手. 根据用户给定的情绪分数+标签+7 档 CBT, '
          '给出 3 个具体行动建议 (CBT 行为激活). '
          '只输出 JSON {"text": "..."},不要其他文字.',
    );
  }
}
```

5 个 prompt 文件 `lib/core/data/services/ai/prompts/*.md` 内容跟 `_loader.dart` 5 个常量同步 (人读备份,方便 review + 调优):
- `alternative_thought.md` — 替代思维
- `emotion_recognition.md` — 情绪识别
- `cognitive_distortion.md` — 认知扭曲
- `core_belief.md` — 核心信念
- `action_suggestion.md` — 行动建议

每个文件内容跟 `_loader.dart` 对应常量完全一致 (中英双标头,prompt 内容)。**loader 是 source of truth,md 是文档备份**。

### Step 6: 跑测试验证通过

```bash
flutter test test/core/data/services/ai/ai_service_round89_test.dart
```

Expected: PASS (3 tests).

### Step 7: 跑全测 + 守门员

```bash
flutter test
flutter analyze
python scripts/check_*.py
```

Expected: 1490 pass (1487 + 3 new), 0 fail, 0 analyzer error, 16 守门全绿.

### Step 8: Commit

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
git add lib/core/data/services/ai/ \
        test/core/data/services/ai/ai_service_round89_test.dart
git commit -m "v0.30 round 89 (data): AiService + abstract AiProvider + 5 prompt + Future.wait partial fail-safe"
```

---

## 已知坑 (R89)

1. **`_CountingProvider` 替代方案**: plan 里说"第 1 个 prompt 抛",但具体实现需 implementer 决定。推荐 callCount == 1 抛,其他正常。
2. **prompt md 文件 vs loader 同步**: 5 md 是人读备份,loader 是 source of truth。改 prompt 改 loader,md 同步更新 (避免 drift)。
3. **Future.wait order 跟 AiResponse 字段顺序严格对应**:
   - results[0] → alternativeThought
   - results[1] → emotion
   - results[2] → cognitiveDistortion
   - results[3] → coreBelief
   - results[4] → actionSuggestion
4. **不要在 service 层做 JSON 解析** — provider 返回 string,service 存 string。Task 2 DeepSeekProvider 负责解析 `choices[0].message.content`。
5. **脱敏 test**: user prompt 不应含 `note` / `automaticThought` / `situation` 字段 (用户原始内容零外传)。

## 跟其他 task 的契约

- Task 2 (DeepSeekProvider) 复用本 task 的 `AiProvider` interface
- Task 3 (AiSettings) 跟本 task 无关,但 AiService 的 provider 实例由 Riverpod 注入
- Task 4 (CbtWizard) 调 `aiService.generateAll(...)` 并把 5 字段填到对应栏位
- Task 5 (i18n) 加 ~16 ARB key

## 不在 scope

- ❌ JSON 解析 (Task 2+4 层做)
- ❌ 设置 + 同意 (Task 3)
- ❌ Wizard 集成 (Task 4)
- ❌ 真实 HTTP 调用 (Task 2)
- ❌ i18n (Task 5)
- ❌ 其他 provider (OpenAI/Claude) — v0.31+ 再说
