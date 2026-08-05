# Task 3 Brief — AiSettings + 同意 dialog (PIPL §13) + settings AI section

> Source of truth.

## Context
- Worktree: D:\Batch\chroniccare\.worktrees\feat-cbt-ai
- Task 1+2 done: AiService + DeepSeekProvider (commit 757c70a, 1494 pass)
- baseline 1494 pass / 0 fail (R89 Task 2 后)
- Goal: 用户在 settings 页面配置 AI — toggle 开关 + API key 输入 + model 选择,首次启用弹同意 dialog (PIPL §13 单独同意)
- 复用现有模式: db_key_service (FlutterSecureStorage) + legal_consent_provider (SP 状态 + timestamp) + cbt_section (settings widget 模式)

## Global Constraints
- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
  - domain 层: `AiSettingsEntity` (零 Flutter / 零 drift)
  - data 层: `AiSettingsRepositoryImpl` (走 flutter_secure_storage + SP)
  - presentation 层: `aiSettingsProvider` + 2 个 widget (section + consent dialog)
- 守门员: `flutter analyze` 0 error, `flutter test` 全过, 16+ 守门全绿, **PIPL §13 单独同意** (R57 check_legal_consent.py 守门)
- TDD: red → green → commit
- 复用模式 (先看现有代码再写):
  - `lib/core/data/services/db_key_service.dart` — FlutterSecureStorage pattern (aOptions: AndroidOptions(encryptedSharedPreferences: true))
  - `lib/presentation/providers/legal_consent_provider.dart` — SP 状态 + millis timestamp
  - `lib/presentation/pages/settings/widgets/cbt_section.dart` — settings Card widget pattern
- ARB keys: 16 个 (zh/en/zh_Hant) — **本 task 暂用中文 placeholder,Task 5 一次性补完**

## TDD
red → green → commit. 1 commit (允许 2 个子 commit 合并)。

## Report
Write to: `.superpowers/sdd/task-3-report.md`
Reply: Status + commit SHA + 1-line test summary + concerns.

---

## Task 3: AiSettings + 同意 dialog + settings AI section

**Files:**
- Create: `lib/domain/entities/ai_settings_entity.dart` (domain layer)
- Create: `lib/core/data/repositories/ai_settings/ai_settings_repository_impl.dart` (data layer)
- Create: `lib/presentation/providers/ai_settings_provider.dart` (presentation layer)
- Create: `lib/presentation/pages/settings/widgets/ai_section.dart` (settings section widget)
- Create: `lib/presentation/pages/settings/widgets/ai_consent_dialog.dart` (PIPL §13 dialog)
- Modify: `lib/presentation/pages/settings/settings_page.dart` (加 AiSection)
- Test: `test/presentation/pages/settings/ai_section_round89_test.dart`
- Test: `test/presentation/pages/settings/ai_consent_dialog_round89_test.dart`

**Interfaces (summary):**
- `AiSettingsEntity` — enabled / provider / modelName / apiKey / consentAcceptedAt / consentVersion
- `AiSettingsRepository` — load() / save() / clearApiKey()
- `aiSettingsProvider` — NotifierProvider<AsyncValue<AiSettingsEntity>>
- `AiSection` — ConsumerWidget (Card + toggle + TextField + dropdown + "测试连接" button)
- `AiConsentDialog` — StatelessWidget (PIPL §13 同意内容 + accept/decline 按钮)

### Step 1: 写失败测试 — section 渲染

`test/presentation/pages/settings/ai_section_round89_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/ai_settings_entity.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/ai_section.dart';
import 'package:chroniccare/presentation/providers/ai_settings_provider.dart';

void main() {
  testWidgets('AiSection 渲染 toggle + 字段', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSettingsProvider.overrideWith(() => _StubNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AiSection(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 标题
    expect(find.text('AI 辅助 (CBT 思维记录)'), findsOneWidget);
    // Toggle (SwitchListTile)
    expect(find.byType(Switch), findsOneWidget);
    // 字段 (enabled = false 时也显示,只是 disabled)
    expect(find.text('API Key'), findsOneWidget);
    expect(find.text('模型'), findsOneWidget);
  });

  testWidgets('AiSection enabled = true 时字段可编辑', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSettingsProvider.overrideWith(() => _StubNotifierEnabled()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AiSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // TextField 应该可输入
    final tf = find.byType(TextField);
    expect(tf, findsAtLeastNWidgets(1));
  });
}

class _StubNotifier extends AsyncNotifier<AiSettingsEntity>
    implements AiSettingsNotifier {
  @override
  Future<AiSettingsEntity> build() async => const AiSettingsEntity(
        enabled: false,
        provider: 'deepseek',
        modelName: 'deepseek-chat',
        consentVersion: '1.0',
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

class _StubNotifierEnabled extends _StubNotifier {
  @override
  Future<AiSettingsEntity> build() async => const AiSettingsEntity(
        enabled: true,
        provider: 'deepseek',
        modelName: 'deepseek-chat',
        consentVersion: '1.0',
        consentAcceptedAt: '2026-08-05T12:00:00Z',
      );
}
```

### Step 2: 跑测试验证失败

```bash
flutter test test/presentation/pages/settings/ai_section_round89_test.dart
```

Expected: FAIL (AiSection / aiSettingsProvider / AiSettingsEntity not found).

### Step 3: 实现 AiSettingsEntity (domain)

`lib/domain/entities/ai_settings_entity.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): AI 设置实体
//
// 字段:
// - enabled: 是否启用 AI 辅助 (PIPL §13 默认 false, 需用户主动开启)
// - provider: LLM provider, 当前只支持 'deepseek'
// - modelName: 模型名, 默认 'deepseek-chat'
// - apiKey: API key (脱敏存储, 不在 entity 暴露, 由 repo 单独管理)
// - consentAcceptedAt: 用户首次同意 PIPL §13 的 ISO8601 UTC timestamp
// - consentVersion: 同意版本号, 法务审核用 (本 task 写 '1.0')

class AiSettingsEntity {
  final bool enabled;
  final String provider;
  final String modelName;
  final String? consentAcceptedAt;
  final String consentVersion;

  const AiSettingsEntity({
    required this.enabled,
    required this.provider,
    required this.modelName,
    this.consentAcceptedAt,
    required this.consentVersion,
  });

  bool get hasConsent => consentAcceptedAt != null;

  AiSettingsEntity copyWith({
    bool? enabled,
    String? provider,
    String? modelName,
    String? consentAcceptedAt,
    String? consentVersion,
  }) {
    return AiSettingsEntity(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      consentVersion: consentVersion ?? this.consentVersion,
    );
  }
}
```

### Step 4: 实现 AiSettingsRepositoryImpl (data)

`lib/core/data/repositories/ai_settings/ai_settings_repository_impl.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): AI 设置仓库
//
// apiKey → FlutterSecureStorage (跟 db_key_service 同 pattern)
// enabled / provider / modelName / consentAcceptedAt / consentVersion → SharedPreferences

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/ai_settings_entity.dart';

class AiSettingsRepository {
  static const _kApiKey = 'ai_api_key';
  static const _kEnabled = 'ai_enabled';
  static const _kProvider = 'ai_provider';
  static const _kModelName = 'ai_model_name';
  static const _kConsentAt = 'ai_consent_accepted_at';
  static const _kConsentVersion = 'ai_consent_version';
  static const _consentVersion = '1.0';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<AiSettingsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AiSettingsEntity(
      enabled: prefs.getBool(_kEnabled) ?? false,
      provider: prefs.getString(_kProvider) ?? 'deepseek',
      modelName: prefs.getString(_kModelName) ?? 'deepseek-chat',
      consentAcceptedAt: prefs.getString(_kConsentAt),
      consentVersion: prefs.getString(_kConsentVersion) ?? _consentVersion,
    );
  }

  /// 仅存 metadata, 不存 apiKey
  Future<void> save(AiSettingsEntity settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, settings.enabled);
    await prefs.setString(_kProvider, settings.provider);
    await prefs.setString(_kModelName, settings.modelName);
    if (settings.consentAcceptedAt != null) {
      await prefs.setString(_kConsentAt, settings.consentAcceptedAt!);
    }
    await prefs.setString(_kConsentVersion, settings.consentVersion);
  }

  /// apiKey 单独存 FlutterSecureStorage (脱敏)
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _kApiKey, value: apiKey);
  }

  /// 拿 apiKey — 单独方法, 不在 load() 里, 避免 entity 暴露
  Future<String?> getApiKey() async {
    return _secureStorage.read(key: _kApiKey);
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _kApiKey);
  }
}
```

### Step 5: 实现 aiSettingsProvider (presentation)

`lib/presentation/providers/ai_settings_provider.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): AI 设置 Riverpod provider
//
// AsyncNotifierProvider<AiSettingsEntity> — load() 读 repo, set 方法写 repo
// watch 时 UI 自动 rebuild

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/repositories/ai_settings/ai_settings_repository_impl.dart';
import 'package:chroniccare/domain/entities/ai_settings_entity.dart';

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  return AiSettingsRepository();
});

class AiSettingsNotifier extends AsyncNotifier<AiSettingsEntity> {
  @override
  Future<AiSettingsEntity> build() async {
    final repo = ref.read(aiSettingsRepositoryProvider);
    return repo.load();
  }

  Future<void> setEnabled(bool v) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(aiSettingsRepositoryProvider);
      final current = await future;  // 等当前 load 完成
      final next = current.copyWith(enabled: v);
      await repo.save(next);
      return next;
    });
  }

  Future<void> setApiKey(String key) async {
    final repo = ref.read(aiSettingsRepositoryProvider);
    await repo.saveApiKey(key);
  }

  Future<void> setModelName(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(aiSettingsRepositoryProvider);
      final current = await future;
      final next = current.copyWith(modelName: name);
      await repo.save(next);
      return next;
    });
  }

  Future<void> recordConsent() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(aiSettingsRepositoryProvider);
      final current = await future;
      final next = current.copyWith(
        consentAcceptedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await repo.save(next);
      return next;
    });
  }

  Future<void> clear() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(aiSettingsRepositoryProvider);
      await repo.clearApiKey();
      return const AiSettingsEntity(
        enabled: false,
        provider: 'deepseek',
        modelName: 'deepseek-chat',
        consentVersion: '1.0',
      ).let((e) async {
        await repo.save(e);
        return e;
      });
    });
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

final aiSettingsProvider = AsyncNotifierProvider<AiSettingsNotifier, AiSettingsEntity>(
  AiSettingsNotifier.new,
);
```

### Step 6: 实现 AiSection widget

`lib/presentation/pages/settings/widgets/ai_section.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): 设置页 AI 入口
//
// 模式: 跟 cbt_section.dart / reminders_section.dart 同 — Card + Consumer
// 内部: Switch (enable) + TextField (api key) + Dropdown (model) + 测试连接按钮
// 首次 toggle on 时弹 AiConsentDialog (PIPL §13 单独同意)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/ai_settings_entity.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/ai_consent_dialog.dart';
import 'package:chroniccare/presentation/providers/ai_settings_provider.dart';

class AiSection extends ConsumerWidget {
  const AiSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(aiSettingsProvider);
    final notifier = ref.read(aiSettingsProvider.notifier);

    return settingsAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Text('加载 AI 设置失败: $e'),
        ),
      ),
      data: (settings) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI 辅助 (CBT 思维记录)', style: AppTokens.textStyleTitle(context)),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(
                '启用后, 可在思维记录向导生成 AI 建议 (国内 DeepSeek, 数据脱敏后传输).',
                style: AppTokens.textStyleCaption(context),
              ),
              SwitchListTile(
                title: const Text('启用 AI 辅助'),
                value: settings.enabled,
                onChanged: (v) async {
                  if (v && !settings.hasConsent) {
                    final accepted = await showDialog<bool>(
                      context: context,
                      builder: (_) => const AiConsentDialog(),
                    );
                    if (accepted != true) return;
                    await notifier.recordConsent();
                  }
                  await notifier.setEnabled(v);
                },
              ),
              if (settings.enabled) ...[
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onSubmitted: (v) => notifier.setApiKey(v),
                ),
                const SizedBox(height: AppTokens.spacingXs),
                DropdownButtonFormField<String>(
                  initialValue: settings.modelName,
                  decoration: const InputDecoration(
                    labelText: '模型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'deepseek-chat', child: Text('deepseek-chat')),
                  ],
                  onChanged: (v) {
                    if (v != null) notifier.setModelName(v);
                  },
                ),
                const SizedBox(height: AppTokens.spacingXs),
                FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('测试连接功能待 Task 5/6 接入')),
                    );
                  },
                  child: const Text('测试连接'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
```

### Step 7: 实现 AiConsentDialog

`lib/presentation/pages/settings/widgets/ai_consent_dialog.dart`:

```dart
// v0.30 round 89 (sub-spec 5 CBT AI 辅助): PIPL §13 同意 dialog
//
// 法务要求: AI 单独同意, 用户必看 + 必点 accept/decline。
// 内容: 4 项 — 数据脱敏 (只发 score/tags/level) / 国内 API / 第三方处理 / 可随时撤回

import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

class AiConsentDialog extends StatelessWidget {
  const AiConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('启用 AI 辅助 (CBT)'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('请阅读以下条款, 同意后方可启用:'),
            const SizedBox(height: AppTokens.spacingSm),
            _bullet('1. 数据脱敏: AI 收到的仅含情绪分数 / 标签 / CBT 档位, 不含你的笔记或自动思维原文。'),
            _bullet('2. 国内传输: 数据通过 DeepSeek API 传输 (api.deepseek.com), 不出境。'),
            _bullet('3. 第三方处理: DeepSeek 按其隐私政策处理 (链接可在 设置 → 法律与隐私 查看)。'),
            _bullet('4. 可随时撤回: 在本节关闭开关即可, 历史 AI 建议保留在本地。'),
            const SizedBox(height: AppTokens.spacingSm),
            const Text('同意版本: 1.0', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('拒绝'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('同意并启用'),
        ),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingXxs),
      child: Text(text, style: const TextStyle(fontSize: 13)),
    );
  }
}
```

### Step 8: 在 settings_page.dart 加 AiSection

`lib/presentation/pages/settings/settings_page.dart` — 找到合适的插入位置 (在 cbt_section 后面),加 `const AiSection()`。

### Step 9: 写失败测试 — dialog

`test/presentation/pages/settings/ai_consent_dialog_round89_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/ai_consent_dialog.dart';

void main() {
  testWidgets('AiConsentDialog 显示 4 项 + 同意/拒绝按钮', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) => const AiConsentDialog(),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('启用 AI 辅助 (CBT)'), findsOneWidget);
    expect(find.textContaining('数据脱敏'), findsOneWidget);
    expect(find.textContaining('国内传输'), findsOneWidget);
    expect(find.textContaining('第三方处理'), findsOneWidget);
    expect(find.textContaining('可随时撤回'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
    expect(find.text('同意并启用'), findsOneWidget);
    await tester.tap(find.text('同意并启用'));
    await tester.pumpAndSettle();
    expect(result, true);
  });
}
```

### Step 10: 跑测试验证通过

```bash
flutter test test/presentation/pages/settings/ai_section_round89_test.dart
flutter test test/presentation/pages/settings/ai_consent_dialog_round89_test.dart
```

Expected: PASS (2 + 1 = 3 tests).

### Step 11: 跑全测 + analyze + 守门员

```bash
flutter test
flutter analyze
python scripts/check_*.py
```

Expected: 1497 pass (1494 + 3 new), 0 fail, 0 analyzer error, 16+ 守门全绿。

### Step 12: Commit

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
git add lib/domain/entities/ai_settings_entity.dart \
        lib/core/data/repositories/ai_settings/ \
        lib/presentation/providers/ai_settings_provider.dart \
        lib/presentation/pages/settings/widgets/ai_section.dart \
        lib/presentation/pages/settings/widgets/ai_consent_dialog.dart \
        lib/presentation/pages/settings/settings_page.dart \
        test/presentation/pages/settings/ai_section_round89_test.dart \
        test/presentation/pages/settings/ai_consent_dialog_round89_test.dart
git commit -m "v0.30 round 89 (settings): AiSettings + 同意 dialog (PIPL §13) + settings AI section + 2 widget test"
```

---

## 已知坑 (R89 Task 3)

1. **AsyncValue.guard + state = loading() pattern**: 跟 R85 reminders_hub 模式一致。看 `lib/presentation/providers/reminders_hub_provider.dart` 现有 Notifier pattern。
2. **let extension**: Dart 3 没内置 `let`,自己加。`lib/core/shared/` 已有的 utility 检查一下,没就本地 extension。
3. **apiKey 走 FlutterSecureStorage**: 跟 db_key_service 一致,Android 用 EncryptedSharedPreferences。**绝不**存 SP 或 entity。
4. **PIPL §13 守门员**: `python scripts/check_legal_consent.py` R57 加的 — 会扫代码里所有"同意"相关字串。本 task 加了 `AiConsentDialog` 必须走 dialog 模式,不能 inline 同意。
5. **首次同意 timestamp**: 同意 dialog 返回 true 才 `recordConsent()` (写 SP),false 不动 settings。dialog 状态独立于 settings 持久化。
6. **R88 cbt_section RadioListTile 用了 deprecated_member_use** (Flutter 4.x warning) — 本 task 用 `SwitchListTile` / `DropdownButtonFormField` 没问题,但要 awareness 9 个 pre-existing info-level 不变。
7. **Dropdown 只放 1 个 model (deepseek-chat)**: 单 provider MVP, 加 OpenAI/Claude 是 v0.31+。
8. **"测试连接"按钮**: 本 task 只占位 (ScaffoldMessenger snackbar "待 Task 5/6 接入"), 实际 HTTP 验证放 wizard 集成 (Task 4) 或 i18n (Task 5) 时再补。
9. **ARB keys**: 本 task 中文 placeholder ("AI 辅助 (CBT 思维记录)" / "启用 AI 辅助" / "API Key" / "模型" / "数据脱敏..."), Task 5 一次性换 16 个 l10n key (zh/en/zh_Hant)。
10. **Widget test mock AsyncNotifier**: 上面 `_StubNotifier` 模式 — 必须 implements AiSettingsNotifier (不能用 super class),override build() 返回 stub 状态。

## 跟其他 task 的契约

- Task 1+2 (AiService + DeepSeekProvider) — 不动
- Task 4 (CbtWizard) — 用 `aiSettingsProvider` 读 enabled + `aiSettingsRepositoryProvider.getApiKey()` 拿 key
- Task 5 (i18n) — 16 个 ARB key
- 不动 wizard 文件 (Task 4 scope)

## 不在 scope

- ❌ Wizard 集成 (Task 4)
- ❌ ARB 国际化 (Task 5)
- ❌ 真实"测试连接"按钮逻辑 (占位, Task 5/6 再补)
- ❌ OpenAI / Claude / 其他 provider
- ❌ 流式响应
- ❌ 同意版本升级流程 (v0.31+ 法务审核时再做)
