# Task 2 Brief — DeepSeekProvider HTTP impl

> Source of truth.

## Context
- Worktree: D:\Batch\chroniccare\.worktrees\feat-cbt-ai
- Task 1 done: AiService + abstract + 5 prompt + 3 mock test (commit 3aa357b, Approved)
- baseline 1490 pass / 0 fail (R89 Task 1 后)
- Goal: 实现唯一 AiProvider — DeepSeekProvider,国内 API (https://api.deepseek.com/v1/chat/completions),不测真实 LLM (mock HTTP)

## Global Constraints
- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture (本 task 在 `core/data/services/ai/`)
- 守门员: `flutter analyze` 0 error, `flutter test` 全过
- TDD: red → green → commit
- **不测真实 LLM** — mock http.Client 注入,避免真实 HTTP 调用
- 复用 Task 1 `AiProvider` interface (无改动)
- 复用 Task 1 `AiService` (无改动) — DeepSeekProvider 通过构造参数注入
- 跟 R85 已有的 `http.Client` 用法对齐 (e.g. `data_export_service` 已有,先看现有 pattern)

## TDD
red → green → commit. 1 commit.

## Report
Write to: `.superpowers/sdd/task-2-report.md`
Reply: Status (DONE / DONE_WITH_CONCERNS / BLOCKED) + commit SHA + 1-line test summary + concerns.

---

## Task 2: DeepSeekProvider HTTP impl

**Files:**
- Create: `lib/core/data/services/ai/deepseek_provider.dart`
- Test: `test/core/data/services/ai/deepseek_provider_round89_test.dart`

**Interfaces:**
- `class DeepSeekProvider implements AiProvider`
- 构造参数: `apiKey` (String, required), `modelName` (String, required), `client` (http.Client, optional default = http.Client())
- 私有常量: `_endpoint = 'https://api.deepseek.com/v1/chat/completions'`
- 复用 Task 1 `AiProvider.call(systemPrompt, userPrompt) -> Future<String>`

### Step 1: 写失败测试

`test/core/data/services/ai/deepseek_provider_round89_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chroniccare/core/data/services/ai/deepseek_provider.dart';

void main() {
  test('DeepSeek 200: 解析 choices[0].message.content', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.toString(), 'https://api.deepseek.com/v1/chat/completions');
      expect(request.headers['Authorization'], 'Bearer test-key');
      expect(request.headers['Content-Type'], contains('application/json'));
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'deepseek-chat');
      expect((body['messages'] as List).length, 2);
      expect(body['messages'][0]['role'], 'system');
      expect(body['messages'][1]['role'], 'user');
      return http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': '示例 AI 回复'}}
          ]
        }),
        200,
      );
    });
    final provider = DeepSeekProvider(
      apiKey: 'test-key',
      modelName: 'deepseek-chat',
      client: mockClient,
    );
    final result = await provider.call('system', 'user');
    expect(result, '示例 AI 回复');
  });

  test('DeepSeek 401: 抛 Exception, 包含 statusCode + body', () async {
    final mockClient = MockClient((request) async {
      return http.Response('Unauthorized', 401);
    });
    final provider = DeepSeekProvider(
      apiKey: 'bad-key',
      modelName: 'deepseek-chat',
      client: mockClient,
    );
    expect(
      () => provider.call('system', 'user'),
      throwsA(isA<Exception>()),
    );
  });

  test('DeepSeek 500: 抛 Exception', () async {
    final mockClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });
    final provider = DeepSeekProvider(
      apiKey: 'test-key',
      modelName: 'deepseek-chat',
      client: mockClient,
    );
    expect(
      () => provider.call('system', 'user'),
      throwsA(isA<Exception>()),
    );
  });

  test('DeepSeek 200 但 choices 空: 抛 Exception (防御)', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'choices': []}),
        200,
      );
    });
    final provider = DeepSeekProvider(
      apiKey: 'test-key',
      modelName: 'deepseek-chat',
      client: mockClient,
    );
    expect(
      () => provider.call('system', 'user'),
      throwsA(isA<Exception>()),
    );
  });
}
```

### Step 2: 跑测试验证失败

```bash
flutter test test/core/data/services/ai/deepseek_provider_round89_test.dart
```

Expected: FAIL (DeepSeekProvider not found).

### Step 3: 实现 DeepSeekProvider

`lib/core/data/services/ai/deepseek_provider.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): DeepSeek HTTP impl
//
// 国内 API: https://api.deepseek.com/v1/chat/completions
// 数据不出境 — 隐私边界第一道 (脱敏在 AiService, 传输在 DeepSeekProvider)
//
// 失败模式:
// - statusCode != 200 → throw Exception
// - choices 为空 → throw Exception (防御)
// - 网络错误 / 超时 → http.Client 自带抛, 上层 AiService._safeCall catch

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:chroniccare/core/data/services/ai/ai_provider.dart';

class DeepSeekProvider implements AiProvider {
  final String apiKey;
  final String modelName;
  final http.Client _client;
  static const _endpoint = 'https://api.deepseek.com/v1/chat/completions';

  DeepSeekProvider({
    required this.apiKey,
    required this.modelName,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<String> call(String systemPrompt, String userPrompt) async {
    final response = await _client.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      developer.log(
        'DeepSeek API failed: ${response.statusCode} ${response.body}',
        name: 'DeepSeekProvider',
      );
      throw Exception('DeepSeek API ${response.statusCode}: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('DeepSeek API: empty choices');
    }
    final content = choices.first['message']?['content'] as String?;
    if (content == null) {
      throw Exception('DeepSeek API: empty content');
    }
    return content;
  }
}
```

### Step 4: 跑测试验证通过

```bash
flutter test test/core/data/services/ai/deepseek_provider_round89_test.dart
```

Expected: PASS (4 tests).

### Step 5: 跑 Task 1 测试 + analyze + 全测

```bash
flutter test test/core/data/services/ai/   # Task 1 + 2 都过
flutter analyze
flutter test   # 全测,期望 1494 pass (1490 + 4 new)
```

Expected: 0 analyzer error, 1494 pass.

### Step 6: Commit

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
git add lib/core/data/services/ai/deepseek_provider.dart \
        test/core/data/services/ai/deepseek_provider_round89_test.dart
git commit -m "v0.30 round 89 (data): DeepSeekProvider HTTP impl (https://api.deepseek.com/v1/chat/completions) + 4 mock test"
```

---

## 已知坑 (R89 Task 2)

1. **`http` package 已在 pubspec.yaml?**: 先 `grep "^http:" pubspec.yaml` 确认,R85 已有的话直接用;没就 `flutter pub add http`。
2. **MockClient import**: `import 'package:http/testing.dart';` (http package 自带)。别用 mockito 或 mocktail,跟项目 R85 风格一致 (优先 stdlib + http 内置)。
3. **header case sensitivity**: Dart `http` package header lookup 走小写, `'Authorization'` → `request.headers['Authorization']` 可能 null。Mock 端写 `request.headers['authorization']` 小写 (保险起见,测试里不强 assert case,只 assert `'Bearer test-key'` 内容)。**修法**: 测试用 `request.headers['authorization']` 小写 (跟 Dart http package 行为一致),同时 `expect(request.headers['Authorization']?.toLowerCase(), 'bearer test-key')` 太严格。建议简单点: test 只 verify header 含 "Bearer" + endpoint 对。
4. **apiKey 安全性**: 测试用 'test-key' 即可,不要在源码里硬编码真实 key。**注意**: `developer.log` 不打 apiKey (R89 改 logging 默认不带敏感信息)。
5. **Task 1 reviewer 建议 #4 (无 logging on swallow)**: 已在 Step 3 加上 `developer.log` 在 statusCode != 200 分支。`developer.log` 不进 release 包 (dart:developer 仅 debug 模式)。
6. **网络超时 / DNS 失败**: `http.Client.post` 自带抛 SocketException / TimeoutException,上层 AiService._safeCall catch → null。这块**不**在本 task 测试 scope (mock 不会触发),R88 同款。

## 跟其他 task 的契约

- Task 1 (AiService) — 不动,DeepSeekProvider 通过构造参数注入
- Task 3 (AiSettings + 同意) — 调 `DeepSeekProvider(apiKey: settings.apiKey, modelName: settings.modelName)` 注入
- Task 4 (CbtWizard) — 通过 Riverpod 拿 AiService,内部用 DeepSeekProvider

## 不在 scope

- ❌ AiService 改动 (Task 1 已定稿)
- ❌ AiProvider 改动 (Task 1 已定稿)
- ❌ 设置 UI (Task 3)
- ❌ Wizard 集成 (Task 4)
- ❌ JSON 解析 (在 DeepSeekProvider 内部)
- ❌ 流式响应 (YAGNI,普通 POST 够用)
- ❌ 重试逻辑 (上层 AiService 不 retry,失败 toast 该能力)
- ❌ 多 provider (OpenAI/Claude 留 v0.31+)
