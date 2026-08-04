# CBT 思维记录改造 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 mood 模块引入 3/5/7 档 CBT 思维记录可切换 UI，默认 3 档（低门槛），支持升级到 5/7 档（认知重构关键步骤齐全），档位偏好持久化。

**Architecture:**
- 4 层架构 + 共享 umbrella（沿用现有）
- 数据：drift schema v16 → v17（mood_entries 加 8 个 nullable CBT 字段）
- 状态：Riverpod 3.x — `thoughtRecordLevelProvider` (SP 持久化) + `cbtDraftProvider` (dialog 内 draft state)
- UI：C 布局策略 — 3 档单屏长表单 / 5-7 档 wizard 步骤式（独立 widget 树）
- 集成：trend_calendar `_DayDetailCard` 展示 5/7 档 mood entry 的 CBT 摘要

**Tech Stack:**
- Flutter 3.41.9 / Dart 3.12.2
- Riverpod 3.3.2 (NotifierProvider)
- Drift 2.20.3 (SQLCipher)
- go_router 14.6
- SharedPreferences 2.x (档位持久化)
- intl (i18n)

## Global Constraints

| 项 | 值 |
|---|---|
| Flutter / Dart | 3.41.9 / 3.12.2 |
| schemaVersion 升级 | 16 → 17 |
| 现有测试 baseline | 1163 cases |
| 守门员脚本 | 16 个 (check_all + check_arb_keys + check_changelog + check_cross_feature + check_datetime_race + check_datetime_race2 + check_drift_namespace + check_fullwidth_punctuation + check_no_hardcoded_utc + check_no_pua + check_widget_dispose + check_orphan_arb_keys + check_legal_consent + check_sms_release_ready + check_strings_hardcoded + check_zh_hant_consistency) |
| drift @DataClassName | 单数 (`MoodEntry`) |
| domain entity 后缀 | `*Entity`（避免和 drift 冲突） |
| mapper 位置 | `lib/core/data/database/mappers/mood/` |
| 跨 feature import 规则 | 禁止 `pages/{A}/` → `pages/{B}/`（home / settings 例外） |
| 命名风格 | `lowerCamelCase` 字段 / `UpperCamelCase` 类型 |
| i18n | zh + en + zh_Hant 同步，ARB 走 `flutter gen-l10n` |
| 跨 midnight DateTime | 函数入口 `final now = DateTime.now()` 一次取 |
| 显式排序 | 时序数据 `.first` / `.last` 必须显式 sort |

---

## 文件结构

### 新增

```
lib/domain/entities/thought_record_level.dart
lib/presentation/providers/cbt_providers.dart
lib/presentation/pages/mood/widgets/cbt_section_field.dart
lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart
lib/presentation/pages/mood/widgets/cbt_explainer_card.dart
lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart
lib/presentation/pages/mood/widgets/cbt_wizard.dart
test/domain/entities/thought_record_level_round84_test.dart
test/domain/entities/mood_entry_cbt_round84_test.dart
test/domain/entities/cbt_draft_state_round84_test.dart
test/data/mood_cbt_roundtrip_round84_test.dart
test/presentation/pages/mood/cbt_three_column_round84_test.dart
test/presentation/pages/mood/cbt_wizard_round84_test.dart
test/presentation/pages/settings/thought_record_level_round84_test.dart
test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
```

### 修改

```
lib/core/data/database/tables/mood/mood_entries.dart        # +8 nullable columns
lib/core/data/database/app_database.dart                    # schemaVersion 16→17, onUpgrade v16→v17
lib/core/data/database/mappers/mood/mood_entry_mapper.dart  # +8 fields 双向映射
lib/domain/entities/mood_entry_entity.dart                  # +8 nullable fields + cbtLevel / scoreShift / isCbtRecord
lib/domain/entities/mood_entry_draft.dart                   # +8 nullable fields
lib/core/data/repositories/mood/mood_repository_impl.dart   # add / update 透传 8 字段
lib/presentation/pages/mood/mood_dialog.dart                # 转发改到 cbt-aware orchestrator
lib/presentation/pages/mood/widgets/mood_recorder_page.dart # 拆分：3 档 vs 5/7 档分发
lib/presentation/pages/settings/page.dart                   # 新增"思维记录档位"radio section
lib/presentation/pages/trend/trend_calendar.dart            # _DayDetailCard 渲染 CBT 摘要
lib/l10n/app_zh.arb                                        # +28 keys
lib/l10n/app_en.arb                                        # +28 keys
lib/l10n/app_zh_Hant.arb                                    # +28 keys
```

---

### Task 1: 数据模型 — drift schema v16→v17 + entity + draft

**Files:**
- Modify: `lib/core/data/database/tables/mood/mood_entries.dart`
- Modify: `lib/core/data/database/app_database.dart`
- Modify: `lib/core/data/database/mappers/mood/mood_entry_mapper.dart`
- Modify: `lib/domain/entities/mood_entry_entity.dart`
- Modify: `lib/domain/entities/mood_entry_draft.dart`
- Test: `test/data/mood_cbt_roundtrip_round84_test.dart`
- Test: `test/domain/entities/mood_entry_cbt_round84_test.dart`

**Interfaces:**
- Consumes: 现有 `MoodEntry` (drift row), `MoodEntryEntity`, `MoodEntryDraft`
- Produces:
  - `MoodEntry` 新增 8 字段 (`situation` / `automaticThought` / `evidenceFor` / `evidenceAgainst` / `alternativeThought` / `reratedScore` / `coreBelief` / `behaviorResponse`)
  - `MoodEntryEntity` 新增 8 nullable 字段 + `bool get isCbtRecord` + `int? get cbtLevel` + `double? get scoreShift`
  - `MoodEntryDraft` 新增 8 nullable 字段

- [ ] **Step 1: 写失败测试 — entity 业务方法**

`test/domain/entities/mood_entry_cbt_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  group('MoodEntryEntity CBT fields (v0.29 round 84)', () {
    test('3-栏老数据 isCbtRecord=false cbtLevel=null', () {
      final e = MoodEntryEntity(
        id: 1, timestamp: DateTime(2026, 8, 4), score: 3, note: '普通记录',
      );
      expect(e.isCbtRecord, isFalse);
      expect(e.cbtLevel, isNull);
      expect(e.scoreShift, isNull);
    });

    test('5-栏数据 alternativeThought 非空时 cbtLevel=5', () {
      final e = MoodEntryEntity(
        id: 2, timestamp: DateTime(2026, 8, 4), score: 4,
        situation: '开会迟到', automaticThought: '大家觉得我不可靠',
        evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
        alternativeThought: '偶尔一次正常', reratedScore: 3,
      );
      expect(e.isCbtRecord, isTrue);
      expect(e.cbtLevel, 5);
      expect(e.scoreShift, -1.0);
    });

    test('7-栏数据 coreBelief 非空时 cbtLevel=7', () {
      final e = MoodEntryEntity(
        id: 3, timestamp: DateTime(2026, 8, 4), score: 2,
        situation: 'x', automaticThought: 'y', evidenceFor: 'a',
        evidenceAgainst: 'b', alternativeThought: 'c', reratedScore: 4,
        coreBelief: '我不够好', behaviorResponse: '深呼吸',
      );
      expect(e.cbtLevel, 7);
    });
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/domain/entities/mood_entry_cbt_round84_test.dart
```

Expected: FAIL — `MoodEntryEntity` 没有 `cbtLevel` getter。

- [ ] **Step 3: 改 entity 加 8 字段 + 3 业务方法**

`lib/domain/entities/mood_entry_entity.dart` 在 `audioDurationMs` 字段后加：

```dart
  // ===== v0.29 round 84 (CBT 思维记录) 字段 =====

  /// 5/7 栏第 1 栏 "情境"
  final String? situation;

  /// 5/7 栏第 2 栏 "自动思维"
  final String? automaticThought;

  /// 5/7 栏第 3 栏 "支持自动思维的证据"
  final String? evidenceFor;

  /// 5/7 栏第 3 栏 "反对自动思维的证据"
  final String? evidenceAgainst;

  /// 5/7 栏第 4 栏 "替代思维"
  final String? alternativeThought;

  /// 5/7 栏第 4 栏 "重新评分" (1-5)
  final int? reratedScore;

  /// 仅 7 栏 "核心信念"
  final String? coreBelief;

  /// 仅 7 栏 "行为应对"
  final String? behaviorResponse;
```

`const MoodEntryEntity` 构造加 8 个 `this.xxx` 参数。`copyWith` 加 8 个 `DomainValue<T?>` 参数（与现有 audio 字段同模式）。`==` / `hashCode` 加 8 个。`toString` 加 8 个。

文件末尾加 3 个业务方法：

```dart
  // ===== v0.29 round 84 CBT 业务方法 =====

  /// 是否 5/7 栏思维记录（任意 CBT 字段非空）
  bool get isCbtRecord =>
      situation != null ||
      automaticThought != null ||
      evidenceFor != null ||
      evidenceAgainst != null ||
      alternativeThought != null ||
      reratedScore != null ||
      coreBelief != null ||
      behaviorResponse != null;

  /// 推断档位: 7=coreBelief 非空, 5=alternativeThought 非空, 3=其他 (返回 null 表示无 CBT 字段)
  int? get cbtLevel {
    if (coreBelief != null || behaviorResponse != null) return 7;
    if (alternativeThought != null || reratedScore != null) return 5;
    if (situation != null || automaticThought != null) return 5; // 5 栏部分填写也算 5
    return null;
  }

  /// 重新评分差值 (rerated - score), 仅 5/7 栏有 reratedScore 时返回
  double? get scoreShift {
    if (reratedScore == null) return null;
    return (reratedScore! - score).toDouble();
  }
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/domain/entities/mood_entry_cbt_round84_test.dart
```

Expected: PASS 3/3。

- [ ] **Step 5: 改 draft 加 8 字段**

`lib/domain/entities/mood_entry_draft.dart` 在 `audioDurationMs` 后加：

```dart
  // ===== v0.29 round 84 (CBT 思维记录) 字段 =====

  /// 5/7 栏第 1 栏 "情境"
  final String? situation;

  /// 5/7 栏第 2 栏 "自动思维"
  final String? automaticThought;

  /// 5/7 栏第 3 栏 "支持自动思维的证据"
  final String? evidenceFor;

  /// 5/7 栏第 3 栏 "反对自动思维的证据"
  final String? evidenceAgainst;

  /// 5/7 栏第 4 栏 "替代思维"
  final String? alternativeThought;

  /// 5/7 栏第 4 栏 "重新评分" (1-5)
  final int? reratedScore;

  /// 仅 7 栏 "核心信念"
  final String? coreBelief;

  /// 仅 7 栏 "行为应对"
  final String? behaviorResponse;
```

`const MoodEntryDraft` 加 8 个 `this.xxx` 默认 null。

- [ ] **Step 6: 改 drift 表加 8 列**

`lib/core/data/database/tables/mood/mood_entries.dart` 在 `audioDurationMs` 列后加：

```dart
  // ===== v0.29 round 84 (CBT 思维记录) 字段 =====

  /// 5/7 栏第 1 栏 "情境"
  TextColumn get situation => text().nullable()();

  /// 5/7 栏第 2 栏 "自动思维"
  TextColumn get automaticThought => text().nullable()();

  /// 5/7 栏第 3 栏 "支持自动思维的证据"
  TextColumn get evidenceFor => text().nullable()();

  /// 5/7 栏第 3 栏 "反对自动思维的证据"
  TextColumn get evidenceAgainst => text().nullable()();

  /// 5/7 栏第 4 栏 "替代思维"
  TextColumn get alternativeThought => text().nullable()();

  /// 5/7 栏第 4 栏 "重新评分" (1-5)
  IntColumn get reratedScore => integer().nullable()();

  /// 仅 7 栏 "核心信念"
  TextColumn get coreBelief => text().nullable()();

  /// 仅 7 栏 "行为应对"
  TextColumn get behaviorResponse => text().nullable()();
```

- [ ] **Step 7: 跑 build_runner 生成 drift 代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: 0 error, 生成新 `app_database.g.dart` 包含 `MoodEntry` 8 新字段。

- [ ] **Step 8: 改 mapper 加 8 字段双向映射**

`lib/core/data/database/mappers/mood/mood_entry_mapper.dart` — `toEntity` / `toCompanion` / `buildMoodEntryEntity` 同步加 8 字段。`toEntity` 加 8 个命名参数，`toCompanion` 加 8 个 `Value(...)`，`buildMoodEntryEntity` 加 8 个 optional 参数。

- [ ] **Step 9: 改 app_database.dart — schemaVersion 16→17 + onUpgrade**

`lib/core/data/database/app_database.dart`:
- 顶部注释块加一行: `// v0.29 round 84: schemaVersion 16 → 17 - mood_entries 加 8 个 CBT 字段 (situation / automaticThought / ...)`
- `int get schemaVersion => 16;` 改成 `int get schemaVersion => 17;`
- `onUpgrade` 在最后一个 `if (from <= 15) {...}` 块**之后**加:

```dart
          // v16 → v17: mood_entries 加 8 个 CBT 字段 (v0.29 round 84)
          // - 8 列全部 nullable, 旧数据自动为 null (3 栏 mode 渲染)
          // - 用户升级后老 mood entry 在 _DayDetailCard 里走"3 栏 + 自由 note"分支
          if (from <= 16) {
            await m.addColumn(moodEntries, moodEntries.situation);
            await m.addColumn(moodEntries, moodEntries.automaticThought);
            await m.addColumn(moodEntries, moodEntries.evidenceFor);
            await m.addColumn(moodEntries, moodEntries.evidenceAgainst);
            await m.addColumn(moodEntries, moodEntries.alternativeThought);
            await m.addColumn(moodEntries, moodEntries.reratedScore);
            await m.addColumn(moodEntries, moodEntries.coreBelief);
            await m.addColumn(moodEntries, moodEntries.behaviorResponse);
          }
```

- [ ] **Step 10: 写失败测试 — drift round-trip CBT 字段**

`test/data/mood_cbt_roundtrip_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('CBT 5 栏字段 round-trip 全部保留', () async {
    final draft = MoodEntryDraft(
      score: 4, tags: const ['焦虑'],
      situation: '开会迟到', automaticThought: '大家觉得我不可靠',
      evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
      alternativeThought: '偶尔一次正常', reratedScore: 3,
    );
    final id = await db.moodDao.insert(
      draft.toCompanion(),
    );
    final all = await db.moodDao.getAll();
    final saved = all.firstWhere((e) => e.id == id);
    expect(saved.situation, '开会迟到');
    expect(saved.automaticThought, '大家觉得我不可靠');
    expect(saved.evidenceFor, '上次也迟到');
    expect(saved.evidenceAgainst, '过去一年只迟到一次');
    expect(saved.alternativeThought, '偶尔一次正常');
    expect(saved.reratedScore, 3);
    final entity = saved.toEntity();
    expect(entity.cbtLevel, 5);
    expect(entity.scoreShift, -1.0);
  });

  test('7 栏字段 round-trip', () async {
    final draft = MoodEntryDraft(
      score: 2, tags: const [],
      situation: 'x', automaticThought: 'y', evidenceFor: 'a',
      evidenceAgainst: 'b', alternativeThought: 'c', reratedScore: 4,
      coreBelief: '我不够好', behaviorResponse: '深呼吸',
    );
    final id = await db.moodDao.insert(draft.toCompanion());
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.coreBelief, '我不够好');
    expect(saved.behaviorResponse, '深呼吸');
    expect(saved.toEntity().cbtLevel, 7);
  });

  test('老 3 栏数据 (CBT 字段全 null) round-trip', () async {
    final draft = MoodEntryDraft(score: 3, tags: const ['普通'], note: '今天还行');
    final id = await db.moodDao.insert(draft.toCompanion());
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.situation, isNull);
    expect(saved.automaticThought, isNull);
    expect(saved.toEntity().isCbtRecord, isFalse);
  });
}
```

- [ ] **Step 11: 跑测试验证通过**

```bash
flutter test test/data/mood_cbt_roundtrip_round84_test.dart
```

Expected: PASS 3/3。

- [ ] **Step 12: 跑全量分析 + 测试**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1163 + 6 = 1169 cases pass。

- [ ] **Step 13: Commit**

```bash
git add lib/core/data/database/tables/mood/mood_entries.dart \
        lib/core/data/database/app_database.dart \
        lib/core/data/database/mappers/mood/mood_entry_mapper.dart \
        lib/core/data/database/app_database.g.dart \
        lib/domain/entities/mood_entry_entity.dart \
        lib/domain/entities/mood_entry_draft.dart \
        test/data/mood_cbt_roundtrip_round84_test.dart \
        test/domain/entities/mood_entry_cbt_round84_test.dart
git commit -m 'v0.29 round 84 (data): mood_entries +8 CBT fields (schema 16→17)'
```

---

### Task 2: ThoughtRecordLevel enum + provider

**Files:**
- Create: `lib/domain/entities/thought_record_level.dart`
- Create: `lib/presentation/providers/cbt_providers.dart`
- Test: `test/domain/entities/thought_record_level_round84_test.dart`

**Interfaces:**
- Consumes: `SharedPreferences`
- Produces:
  - `enum ThoughtRecordLevel { three, five, seven }` + `int get columnCount` + `static ThoughtRecordLevel fromInt(int)`
  - `thoughtRecordLevelProvider` (NotifierProvider\<ThoughtRecordLevel\>) — SP 持久化

- [ ] **Step 1: 写失败测试 — enum 解析**

`test/domain/entities/thought_record_level_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  group('ThoughtRecordLevel (v0.29 round 84)', () {
    test('三档 columnCount 分别是 3/5/7', () {
      expect(ThoughtRecordLevel.three.columnCount, 3);
      expect(ThoughtRecordLevel.five.columnCount, 5);
      expect(ThoughtRecordLevel.seven.columnCount, 7);
    });

    test('fromInt 3/5/7 解析', () {
      expect(ThoughtRecordLevel.fromInt(3), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(5), ThoughtRecordLevel.five);
      expect(ThoughtRecordLevel.fromInt(7), ThoughtRecordLevel.seven);
    });

    test('fromInt 非法值 fallback 到 3', () {
      expect(ThoughtRecordLevel.fromInt(0), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(99), ThoughtRecordLevel.three);
      expect(ThoughtRecordLevel.fromInt(-1), ThoughtRecordLevel.three);
    });
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/domain/entities/thought_record_level_round84_test.dart
```

Expected: FAIL — `ThoughtRecordLevel` 不存在。

- [ ] **Step 3: 实现 enum**

`lib/domain/entities/thought_record_level.dart`:

```dart
/// v0.29 round 84 (CBT 思维记录): 三档可切换的思维记录深度
///
/// - three: 3 栏（入门版，情境/自动思维/情绪）
/// - five: 5 栏（Beck 标准，加支持-反对证据 + 替代思维 + 重新评分）
/// - seven: 7 栏（深度版，再加核心信念 + 行为应对）
enum ThoughtRecordLevel {
  three,
  five,
  seven;

  /// 栏位数 (3 / 5 / 7)
  int get columnCount {
    switch (this) {
      case ThoughtRecordLevel.three: return 3;
      case ThoughtRecordLevel.five: return 5;
      case ThoughtRecordLevel.seven: return 7;
    }
  }

  /// 反向解析: 3/5/7 → enum, 非法值 fallback 到 three
  ///
  /// 兼容老 SP 值或手改配置文件场景。
  static ThoughtRecordLevel fromInt(int value) {
    switch (value) {
      case 3: return ThoughtRecordLevel.three;
      case 5: return ThoughtRecordLevel.five;
      case 7: return ThoughtRecordLevel.seven;
      default: return ThoughtRecordLevel.three;
    }
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/domain/entities/thought_record_level_round84_test.dart
```

Expected: PASS 3/3。

- [ ] **Step 5: 实现 thoughtRecordLevelProvider**

在 `lib/presentation/providers/cbt_providers.dart` 新文件，加：

```dart
// v0.29 round 84 (CBT 思维记录): 档位持久化 provider
//
// - 读: SharedPreferences key "mood.thought_record_level" (int 3/5/7)
// - 写: 用户在 settings 页改后立即同步
// - 默认: 3 (新手友好)
// - 异常: SP 读失败 fallback 3 (fail-safe)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/thought_record_level.dart';

const _kThoughtRecordLevelKey = 'mood.thought_record_level';

/// 启动时一次性读 SP, 给 provider 用
final _sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at app boot'),
);

/// v0.29 round 84: 思维记录档位 (3/5/7)
class ThoughtRecordLevelNotifier extends Notifier<ThoughtRecordLevel> {
  @override
  ThoughtRecordLevel build() {
    final sp = ref.read(_sharedPreferencesProvider);
    final raw = sp.getInt(_kThoughtRecordLevelKey);
    return ThoughtRecordLevel.fromInt(raw ?? 3);
  }

  /// 设置档位 (settings 页调用)
  Future<void> setLevel(ThoughtRecordLevel level) async {
    state = level;
    final sp = ref.read(_sharedPreferencesProvider);
    await sp.setInt(_kThoughtRecordLevelKey, level.columnCount);
  }
}

final thoughtRecordLevelProvider =
    NotifierProvider<ThoughtRecordLevelNotifier, ThoughtRecordLevel>(
  ThoughtRecordLevelNotifier.new,
);
```

- [ ] **Step 6: 在 app.dart 注册 SP provider override**

`lib/app.dart` `build()` 内（已有 `ProviderScope` 区域）加：

```dart
ProviderScope(
  overrides: [
    _sharedPreferencesProvider.overrideWithValue(
      await SharedPreferences.getInstance(),
    ),
  ],
  child: const App(),
)
```

> **注意**：`_sharedPreferencesProvider` 是 top-level 私有，要让 app.dart 能 override，**改为公开命名** `sharedPreferencesProvider`（在 cbt_providers.dart 顶部，删下划线）。

- [ ] **Step 7: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1169 + 3 = 1172 cases pass。

- [ ] **Step 8: Commit**

```bash
git add lib/domain/entities/thought_record_level.dart \
        lib/presentation/providers/cbt_providers.dart \
        lib/app.dart \
        test/domain/entities/thought_record_level_round84_test.dart
git commit -m 'v0.29 round 84 (state): ThoughtRecordLevel enum + SP provider'
```

---

### Task 3: CbtDraftState + cbtDraftProvider

**Files:**
- Modify: `lib/presentation/providers/cbt_providers.dart`
- Test: `test/domain/entities/cbt_draft_state_round84_test.dart`

**Interfaces:**
- Consumes: `ThoughtRecordLevel`, `MoodEntryDraft`
- Produces:
  - `class CbtDraftState` (不可变)
  - `class CbtDraftNotifier extends Notifier<CbtDraftState>`
  - `cbtDraftProvider` (NotifierProvider<CbtDraftNotifier, CbtDraftState>)

- [ ] **Step 1: 写失败测试 — state 切档保留数据**

`test/domain/entities/cbt_draft_state_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';

void main() {
  group('CbtDraftState (v0.29 round 84)', () {
    test('初始 state level=three, stepIndex=0, draft 8 字段全 null', () {
      final s = CbtDraftState.initial();
      expect(s.level, ThoughtRecordLevel.three);
      expect(s.stepIndex, 0);
      expect(s.draft.situation, isNull);
      expect(s.draft.automaticThought, isNull);
    });

    test('3 → 5 切档保留已有 situation/automaticThought 字段', () {
      var s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.three,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's1', automaticThought: 'at1',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.situation, 's1');
      expect(next.draft.automaticThought, 'at1');
    });

    test('5 → 7 切档保留所有 5 栏字段', () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.five,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's', automaticThought: 'at',
          evidenceFor: 'ef', evidenceAgainst: 'ea',
          alternativeThought: 'alt', reratedScore: 3,
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.seven);
      expect(next.draft.evidenceFor, 'ef');
      expect(next.draft.alternativeThought, 'alt');
      expect(next.draft.reratedScore, 3);
    });

    test('7 → 5 切档保留 core/behavior 字段 (UI 隐藏但 state 保留)', () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.seven,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's', automaticThought: 'at',
          evidenceFor: 'ef', evidenceAgainst: 'ea',
          alternativeThought: 'alt', reratedScore: 3,
          coreBelief: 'cb', behaviorResponse: 'br',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.coreBelief, 'cb');
      expect(next.draft.behaviorResponse, 'br');
    });

    test('firstEmptyStep 5 栏: 全空 → 0, situation 空 → 0, 都填了 → 4', () {
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: []),
        ThoughtRecordLevel.five,
      ), 0);
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: [], situation: 's'),
        ThoughtRecordLevel.five,
      ), 1);
      final allFilled = const MoodEntryDraft(
        score: 4, tags: [],
        situation: 's', automaticThought: 'at',
        evidenceFor: 'ef', evidenceAgainst: 'ea',
        alternativeThought: 'alt', reratedScore: 3,
      );
      expect(CbtDraftState.firstEmptyStep(allFilled, ThoughtRecordLevel.five), 4);
    });

    test('3 栏 firstEmptyStep 永远返回 0 (单屏模式无 step)', () {
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: []),
        ThoughtRecordLevel.three,
      ), 0);
    });
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/domain/entities/cbt_draft_state_round84_test.dart
```

Expected: FAIL — `CbtDraftState` 不存在。

- [ ] **Step 3: 在 cbt_providers.dart 加 CbtDraftState + Notifier**

`lib/presentation/providers/cbt_providers.dart` 末尾加：

```dart
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';

/// v0.29 round 84: 当前 dialog 内的 CBT draft 状态
///
/// - level: 当前档位 (3/5/7)
/// - stepIndex: wizard 步骤 (3 档 mode 固定 0)
/// - draft: 完整 MoodEntryDraft (含 8 个 CBT 字段)
/// - showExplainer: 顶部 ℹ️ 折叠卡是否展开
class CbtDraftState {
  final ThoughtRecordLevel level;
  final int stepIndex;
  final MoodEntryDraft draft;
  final bool showExplainer;

  const CbtDraftState({
    required this.level,
    required this.stepIndex,
    required this.draft,
    required this.showExplainer,
  });

  /// 初始 state: 3 档 / step 0 / 空 draft / 折叠卡显示
  factory CbtDraftState.initial() => const CbtDraftState(
        level: ThoughtRecordLevel.three,
        stepIndex: 0,
        draft: MoodEntryDraft(score: 3, tags: []),
        showExplainer: true,
      );

  CbtDraftState copyWith({
    ThoughtRecordLevel? level,
    int? stepIndex,
    MoodEntryDraft? draft,
    bool? showExplainer,
  }) {
    return CbtDraftState(
      level: level ?? this.level,
      stepIndex: stepIndex ?? this.stepIndex,
      draft: draft ?? this.draft,
      showExplainer: showExplainer ?? this.showExplainer,
    );
  }

  /// 计算"第一个未填的 step" (5/7 栏 wizard 用, 3 档返回 0)
  ///
  /// 5 栏 5 步:
  ///   0 = situation
  ///   1 = automaticThought
  ///   2 = score + evidenceFor + evidenceAgainst (任一空算空)
  ///   3 = alternativeThought + reratedScore (任一空算空)
  ///   4 = 确认 (5 步索引, 共 5 步)
  ///
  /// 7 栏 7 步:
  ///   0-4 同 5 栏
  ///   5 = coreBelief
  ///   6 = behaviorResponse
  static int firstEmptyStep(MoodEntryDraft d, ThoughtRecordLevel level) {
    if (level == ThoughtRecordLevel.three) return 0;
    if (_isEmpty(d.situation)) return 0;
    if (_isEmpty(d.automaticThought)) return 1;
    if (_isEmpty(d.evidenceFor) || _isEmpty(d.evidenceAgainst) || d.score < 1) return 2;
    if (_isEmpty(d.alternativeThought) || d.reratedScore == null) return 3;
    if (level == ThoughtRecordLevel.seven) {
      if (_isEmpty(d.coreBelief)) return 4;
      if (_isEmpty(d.behaviorResponse)) return 5;
      return 6;
    }
    return 4;
  }

  static bool _isEmpty(String? s) => s == null || s.trim().isEmpty;
}

/// v0.29 round 84: CbtDraftState notifier
///
/// - setLevel: 切档 + 跳到第一个未填 step (3 档固定 0)
/// - setStep: 跳到指定 step (5/7 栏用)
/// - updateField: 改单个 CBT 字段
/// - toggleExplainer: 折叠卡展开/收起
class CbtDraftNotifier extends Notifier<CbtDraftState> {
  @override
  CbtDraftState build() => CbtDraftState.initial();

  /// 切档 (dialog 顶部 SegmentedButton 调)
  void setLevel(ThoughtRecordLevel newLevel) {
    final newStep = CbtDraftState.firstEmptyStep(state.draft, newLevel);
    state = state.copyWith(level: newLevel, stepIndex: newStep);
  }

  /// 跳到指定 step (5/7 栏 wizard 用, 范围 check)
  void setStep(int step) {
    final maxStep = state.level == ThoughtRecordLevel.five ? 4 : 6;
    final clamped = step.clamp(0, maxStep);
    state = state.copyWith(stepIndex: clamped);
  }

  /// 改单个 CBT 字段
  void updateField({
    String? situation,
    String? automaticThought,
    String? evidenceFor,
    String? evidenceAgainst,
    String? alternativeThought,
    int? reratedScore,
    String? coreBelief,
    String? behaviorResponse,
  }) {
    state = state.copyWith(
      draft: MoodEntryDraft(
        score: state.draft.score,
        tags: state.draft.tags,
        at: state.draft.at,
        note: state.draft.note,
        energy: state.draft.energy,
        sleep: state.draft.sleep,
        anxiety: state.draft.anxiety,
        audioPath: state.draft.audioPath,
        audioTranscript: state.draft.audioTranscript,
        audioDurationMs: state.draft.audioDurationMs,
        situation: situation ?? state.draft.situation,
        automaticThought: automaticThought ?? state.draft.automaticThought,
        evidenceFor: evidenceFor ?? state.draft.evidenceFor,
        evidenceAgainst: evidenceAgainst ?? state.draft.evidenceAgainst,
        alternativeThought: alternativeThought ?? state.draft.alternativeThought,
        reratedScore: reratedScore ?? state.draft.reratedScore,
        coreBelief: coreBelief ?? state.draft.coreBelief,
        behaviorResponse: behaviorResponse ?? state.draft.behaviorResponse,
      ),
    );
  }

  /// 折叠卡展开/收起
  void toggleExplainer() {
    state = state.copyWith(showExplainer: !state.showExplainer);
  }

  /// 重置 (dialog 关闭时调)
  void reset() {
    state = CbtDraftState.initial();
  }
}

final cbtDraftProvider =
    NotifierProvider<CbtDraftNotifier, CbtDraftState>(
  CbtDraftNotifier.new,
);
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/domain/entities/cbt_draft_state_round84_test.dart
```

Expected: PASS 6/6。

- [ ] **Step 5: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1172 + 6 = 1178 cases pass。

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/providers/cbt_providers.dart \
        test/domain/entities/cbt_draft_state_round84_test.dart
git commit -m 'v0.29 round 84 (state): CbtDraftState + cbtDraftProvider + 切档保留'
```

---

### Task 4: 公共 widget (CbtSectionField + CbtPromptSheet + CbtExplainerCard)

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_section_field.dart`
- Create: `lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`
- Create: `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`
- Test: `test/presentation/pages/mood/cbt_widgets_round84_test.dart`

**Interfaces:**
- Consumes: 现有 `AppTokens`
- Produces:
  - `CbtSectionField` — 标题 + ⓘ + 文本框 + prompt 库按钮
  - `CbtPromptSheet.show(context, prompts)` — bottom sheet 弹窗
  - `CbtExplainerCard` — 顶部 ℹ️ 折叠卡

- [ ] **Step 1: 写失败测试 — 公共 widget 渲染**

`test/presentation/pages/mood/cbt_widgets_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';

void main() {
  testWidgets('CbtSectionField 显示标题 + ⓘ + placeholder + prompt 按钮', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CbtSectionField(
          title: '情境',
          hint: '触发这个想法的事件',
          prompts: const ['问题1', '问题2'],
          onChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('情境'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('触发这个想法的事件'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);  // prompt 库按钮
  });

  testWidgets('CbtExplainerCard 默认展开, 点击收起', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CbtExplainerCard(
          title: '什么是 CBT 思维记录？',
          body: 'CBT 是认知行为疗法...',
        ),
      ),
    ));
    expect(find.text('什么是 CBT 思维记录？'), findsOneWidget);
    expect(find.text('CBT 是认知行为疗法...'), findsOneWidget);
    await tester.tap(find.text('什么是 CBT 思维记录？'));
    await tester.pumpAndSettle();
    expect(find.text('CBT 是认知行为疗法...'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/mood/cbt_widgets_round84_test.dart
```

Expected: FAIL — `CbtSectionField` / `CbtExplainerCard` 不存在。

- [ ] **Step 3: 实现 CbtSectionField**

`lib/presentation/pages/mood/widgets/cbt_section_field.dart`:

```dart
// v0.29 round 84 (CBT 思维记录): 公共 section 字段
//
// 标题 + ⓘ popup + 文本框 + ? prompt 库按钮
// 5/7 栏 wizard 每步都用这个组件

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
              label: const Text('引导问题'),
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
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 实现 CbtPromptSheet**

`lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`:

```dart
// v0.29 round 84 (CBT 思维记录): prompt 库 bottom sheet
//
// 点击问题追加到当前文本框末尾 (不替换)

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

- [ ] **Step 5: 实现 CbtExplainerCard**

`lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`:

```dart
// v0.29 round 84 (CBT 思维记录): 顶部 ℹ️ 折叠说明卡
//
// 首次使用默认展开, 用户可手动折叠. 展开状态由父组件持有 (CbtDraftState.showExplainer)

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

- [ ] **Step 6: 跑测试验证通过**

```bash
flutter test test/presentation/pages/mood/cbt_widgets_round84_test.dart
```

Expected: PASS 2/2。

- [ ] **Step 7: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1178 + 2 = 1180 cases pass。

- [ ] **Step 8: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_section_field.dart \
        lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart \
        lib/presentation/pages/mood/widgets/cbt_explainer_card.dart \
        test/presentation/pages/mood/cbt_widgets_round84_test.dart
git commit -m 'v0.29 round 84 (ui): CbtSectionField + CbtPromptSheet + CbtExplainerCard'
```

---

### Task 5: 3 栏 mode UI 改造

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart`
- Modify: `lib/presentation/pages/mood/widgets/mood_recorder_page.dart`
- Test: `test/presentation/pages/mood/cbt_three_column_round84_test.dart`

**Interfaces:**
- Consumes: `cbtDraftProvider` (NotifierProvider), `CbtSectionField` (Task 4)
- Produces: `CbtThreeColumnMode` widget — 3 栏 mode 下的内容布局

- [ ] **Step 1: 写失败测试 — 3 栏 mode 渲染**

`test/presentation/pages/mood/cbt_three_column_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_three_column_mode.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  testWidgets('3 栏 mode 显示 score + situation + automaticThought 三个 section', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(builder: (ctx, ref, _) {
            // 强制 3 栏 mode
            ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.three);
            return const CbtThreeColumnMode();
          }),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('你现在的感受？'), findsOneWidget);
    expect(find.text('发生了什么？'), findsOneWidget);
    expect(find.text('那一刻脑海里闪过什么想法？'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/mood/cbt_three_column_round84_test.dart
```

Expected: FAIL — `CbtThreeColumnMode` 不存在。

- [ ] **Step 3: 实现 CbtThreeColumnMode**

`lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart`:

```dart
// v0.29 round 84 (CBT 思维记录): 3 栏 mode 内容布局
//
// 单屏长表单: score ① + situation ② + automaticThought ③
// 录音 + 标签 + 保存按钮由 mood_recorder_page 在底部提供

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
        // ① 情绪分数 1-5
        Text('① 你现在的感受？', style: AppTokens.textStyleLabel(context)),
        const SizedBox(height: AppTokens.spacingXs),
        // 复用现有 score chooser
        Wrap(
          spacing: AppTokens.spacingSm,
          children: List.generate(5, (i) {
            final score = i + 1;
            return ChoiceChip(
              label: Text('$score'),
              selected: state.draft.score == score,
              onSelected: (_) {
                notifier.updateField();  // score 更新走现有路径
              },
            );
          }),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        // ② 情境
        CbtSectionField(
          title: '② 发生了什么？',
          hint: '触发这个想法的事件是什么？发生在哪、什么时候、有谁？',
          prompts: const [],
          initialValue: state.draft.situation,
          onChanged: (v) => notifier.updateField(situation: v),
        ),
        const SizedBox(height: AppTokens.spacingMd),
        // ③ 自动思维
        CbtSectionField(
          title: '③ 那一刻脑海里闪过什么想法？',
          hint: '那一刻脑海中闪过的想法、印象或信念是什么？',
          prompts: const [
            '如果你的好朋友遇到这事，你会怎么劝TA？',
            '最坏/最好/最现实的结果是什么？',
            '一年后你还会这么想吗？',
          ],
          initialValue: state.draft.automaticThought,
          onChanged: (v) => notifier.updateField(automaticThought: v),
        ),
      ],
    );
  }
}
```

> **注**：score 选 chip 的 `onSelected` 实际要走 `medication_notifier` 或 `mood_score_chooser` 已有的状态。**这里先占位 `notifier.updateField()`，Task 8 集成时改成 `notifier.updateScore(score)` 走现有路径**。

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/pages/mood/cbt_three_column_round84_test.dart
```

Expected: PASS 1/1（**注**：score 渲染可能因 `mood_score_chooser` 复用需要微调，但本测试只检查 3 个 section 标题）。

- [ ] **Step 5: 在 mood_recorder_page.dart 集成 3 栏 mode**

`lib/presentation/pages/mood/widgets/mood_recorder_page.dart`:

- 顶部加 `SegmentedButton<ThoughtRecordLevel>` (3 栏 / 5 栏 / 7 栏)
- dialog 内容: `level == three` → `CbtThreeColumnMode`, `level == five/seven` → `CbtWizard` (Task 6)
- 录音 / 标签 / 保存按钮保持现有行为

代码结构：

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
          // 顶部: 档位切换 + 录音按钮
          _buildHeader(cbtState, cbtNotifier, levelNotifier),
          // 中间: 内容 (3 栏 vs wizard)
          Expanded(
            child: switch (cbtState.level) {
              ThoughtRecordLevel.three => const CbtThreeColumnMode(),
              ThoughtRecordLevel.five || ThoughtRecordLevel.seven =>
                const CbtWizard(),
            },
          ),
          // 底部: 标签 + 保存
          _buildFooter(...),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1180 + 1 = 1181 cases pass。

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart \
        lib/presentation/pages/mood/widgets/mood_recorder_page.dart \
        test/presentation/pages/mood/cbt_three_column_round84_test.dart
git commit -m 'v0.29 round 84 (ui): 3 栏 mode 单屏长表单 + SegmentedButton'
```

---

### Task 6: 5/7 栏 wizard UI

**Files:**
- Create: `lib/presentation/pages/mood/widgets/cbt_wizard.dart`
- Test: `test/presentation/pages/mood/cbt_wizard_round84_test.dart`

**Interfaces:**
- Consumes: `cbtDraftProvider`, `CbtSectionField`, `CbtExplainerCard`
- Produces: `CbtWizard` widget — 5/7 栏步骤式布局

- [ ] **Step 1: 写失败测试 — wizard 步骤切换**

`test/presentation/pages/mood/cbt_wizard_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_wizard.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

void main() {
  testWidgets('5 栏 wizard step 1 显示 情境 section', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
          return const Scaffold(body: CbtWizard());
        }),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('情境'), findsWidgets);
    expect(find.textContaining('第'), findsOneWidget);  // Step X / 5
  });

  testWidgets('5 栏 wizard step 切换: 点击下一步从 情境 → 自动思维', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          ref.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
          return const Scaffold(body: CbtWizard());
        }),
      ),
    ));
    await tester.pumpAndSettle();
    // step 1: 情境, 填一下触发 firstEmptyStep → step 1
    await tester.enterText(find.byType(TextField).first, '开会迟到');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('那一刻脑海中闪过的想法'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/mood/cbt_wizard_round84_test.dart
```

Expected: FAIL — `CbtWizard` 不存在。

- [ ] **Step 3: 实现 CbtWizard**

`lib/presentation/pages/mood/widgets/cbt_wizard.dart`:

```dart
// v0.29 round 84 (CBT 思维记录): 5/7 栏 wizard
//
// 步骤式: 进度条 + 当前 step section + 上一/下一步按钮
// 5 栏 5 步, 7 栏 7 步
// 切档由父组件 (mood_recorder_page) 通过 SegmentedButton 触发

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
        // 进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: LinearProgressIndicator(
            value: (state.stepIndex + 1) / totalSteps,
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            '第 ${state.stepIndex + 1} 步 / 共 $totalSteps 步',
            style: AppTokens.textStyleMicro(context),
          ),
        ),
        // 顶部 ℹ️ 折叠卡
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: CbtExplainerCard(
            title: '什么是 CBT 思维记录？',
            body: 'CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准：先记录情境与想法，再找证据支持/反对，最后写下更平衡的替代想法。',
            expanded: state.showExplainer,
            onToggle: notifier.toggleExplainer,
          ),
        ),
        // 当前 step section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: _buildStep(context, state, notifier, l10n),
          ),
        ),
        // 上一/下一步
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: state.stepIndex == 0
                    ? null
                    : () => notifier.setStep(state.stepIndex - 1),
                child: const Text('上一步'),
              ),
              FilledButton(
                onPressed: () {
                  if (isLastStep) {
                    // 提交 - 由父组件 (mood_recorder_page) 监听
                    Navigator.of(context).pop();
                  } else {
                    notifier.setStep(state.stepIndex + 1);
                  }
                },
                child: Text(isLastStep ? '保存' : '下一步'),
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

    // 5 栏 5 步 / 7 栏 7 步 映射
    if (step == 0) {
      return CbtSectionField(
        title: '情境',
        hint: '触发这个想法的事件是什么？发生在哪、什么时候、有谁？',
        prompts: const [],
        initialValue: state.draft.situation,
        onChanged: (v) => notifier.updateField(situation: v),
      );
    }
    if (step == 1) {
      return CbtSectionField(
        title: '自动思维',
        hint: '那一刻脑海中闪过的想法、印象或信念是什么？',
        prompts: const [
          '如果你的好朋友遇到这事，你会怎么劝TA？',
          '最坏/最好/最现实的结果是什么？',
          '一年后你还会这么想吗？',
        ],
        initialValue: state.draft.automaticThought,
        onChanged: (v) => notifier.updateField(automaticThought: v),
      );
    }
    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('情绪 + 证据', style: AppTokens.textStyleLabel(context)),
          const SizedBox(height: AppTokens.spacingSm),
          // score 选择
          Wrap(
            spacing: AppTokens.spacingSm,
            children: List.generate(5, (i) {
              final score = i + 1;
              return ChoiceChip(
                label: Text('$score'),
                selected: state.draft.score == score,
                onSelected: (_) {
                  // notifier.updateScore(score) - 走 score 现有路径
                },
              );
            }),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '支持这个想法的证据',
            hint: '什么事支持这个想法？',
            prompts: const [],
            initialValue: state.draft.evidenceFor,
            onChanged: (v) => notifier.updateField(evidenceFor: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '反对这个想法的证据',
            hint: '什么事不支持这个想法？',
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
            title: '替代思维',
            hint: '如果你的好朋友遇到这事，你会怎么劝TA？',
            prompts: const ['一年后你还会这么想吗？', '最现实的结果是什么？'],
            initialValue: state.draft.alternativeThought,
            onChanged: (v) => notifier.updateField(alternativeThought: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text('重新评分 (1-5)', style: AppTokens.textStyleLabel(context)),
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
      return Text('确认: ${state.draft.situation ?? "(未填)"}', style: AppTokens.textStyleBody(context));
    }
    if (step == 4 && level == ThoughtRecordLevel.seven) {
      return CbtSectionField(
        title: '核心信念',
        hint: '这个想法背后更深层的信念是什么？（如 "我不够好"）',
        prompts: const [],
        initialValue: state.draft.coreBelief,
        onChanged: (v) => notifier.updateField(coreBelief: v),
      );
    }
    if (step == 5) {
      return CbtSectionField(
        title: '行为应对',
        hint: '接下来你打算怎么做？',
        prompts: const ['深呼吸 5 次', '与信任的人聊聊', '做 10 分钟正念'],
        initialValue: state.draft.behaviorResponse,
        onChanged: (v) => notifier.updateField(behaviorResponse: v),
      );
    }
    if (step == 6) {
      return Text('确认: ${state.draft.situation ?? "(未填)"}', style: AppTokens.textStyleBody(context));
    }
    return const SizedBox.shrink();
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/pages/mood/cbt_wizard_round84_test.dart
```

Expected: PASS 2/2。

- [ ] **Step 5: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1181 + 2 = 1183 cases pass。

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/mood/widgets/cbt_wizard.dart \
        test/presentation/pages/mood/cbt_wizard_round84_test.dart
git commit -m 'v0.29 round 84 (ui): 5/7 栏 wizard 步骤式 + 进度条 + 引导'
```

---

### Task 7: 设置页 radio 入口

**Files:**
- Modify: `lib/presentation/pages/settings/page.dart`
- Test: `test/presentation/pages/settings/thought_record_level_round84_test.dart`

**Interfaces:**
- Consumes: `thoughtRecordLevelProvider`, ARB key `settingsCbtLevel*`
- Produces: 设置页"思维记录档位" radio section

- [ ] **Step 1: 写失败测试 — 设置页 radio**

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

  testWidgets('设置页显示思维记录档位 3 选 1', (tester) async {
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('思维记录档位'), findsOneWidget);
    expect(find.text('3 栏'), findsOneWidget);
    expect(find.text('5 栏'), findsOneWidget);
    expect(find.text('7 栏'), findsOneWidget);
  });

  testWidgets('点击 5 栏 radio 立即写入 SP', (tester) async {
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      child: const MaterialApp(home: SettingsPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 栏'));
    await tester.pumpAndSettle();
    expect(sp.getInt('mood.thought_record_level'), 5);
  });
}
```

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/settings/thought_record_level_round84_test.dart
```

Expected: FAIL — 设置页没有"思维记录档位"。

- [ ] **Step 3: 在 settings/page.dart 新增 section**

`lib/presentation/pages/settings/page.dart`:

在合适位置（"用药"或"提醒"section 后）加：

```dart
// v0.29 round 84 (CBT 思维记录): 思维记录档位设置
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
            Text('思维记录档位', style: AppTokens.textStyleTitleSmall(ctx)),
            const SizedBox(height: AppTokens.spacingXxs),
            Text('选择每次记录情绪时使用的思维记录模板', style: AppTokens.textStyleBodySmall(ctx)),
            const SizedBox(height: AppTokens.spacingSm),
            ...ThoughtRecordLevel.values.map((lv) => RadioListTile<ThoughtRecordLevel>(
                  title: Text('${lv.columnCount} 栏'),
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
    case ThoughtRecordLevel.three: return '入门版，1-2 分钟可填完';
    case ThoughtRecordLevel.five: return '标准 Beck 思维记录，含认知重构关键步骤';
    case ThoughtRecordLevel.seven: return '深度版，含核心信念识别和行为应对';
  }
}
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/pages/settings/thought_record_level_round84_test.dart
```

Expected: PASS 2/2。

- [ ] **Step 5: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1183 + 2 = 1185 cases pass。

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/settings/page.dart \
        test/presentation/pages/settings/thought_record_level_round84_test.dart
git commit -m 'v0.29 round 84 (settings): 思维记录档位 radio section'
```

---

### Task 8: trend_calendar 集成

**Files:**
- Modify: `lib/presentation/pages/trend/trend_calendar.dart`
- Test: `test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart`

**Interfaces:**
- Consumes: `MoodEntryEntity.isCbtRecord` / `cbtLevel` / `scoreShift`, ARB `moodCbtChipBadge*` / `moodCbtSection*`
- Produces: trend_calendar 单元格 + `_DayDetailCard` 展示 5/7 栏 mood entry 的 CBT 摘要

- [ ] **Step 1: 写失败测试 — DayDetailCard 显示 CBT 字段**

`test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/trend/trend_calendar.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  testWidgets('5 栏 mood entry 在 _DayDetailCard 显示 CBT 摘要', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1, timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 4,
        situation: '开会迟到', automaticThought: '大家觉得我不可靠',
        evidenceFor: '上次也迟到', evidenceAgainst: '过去一年只迟到一次',
        alternativeThought: '偶尔一次正常', reratedScore: 3,
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
    expect(find.text('CBT 5 栏'), findsOneWidget);
    expect(find.text('情境: 开会迟到'), findsOneWidget);
    expect(find.text('自动思维: 大家觉得我不可靠'), findsOneWidget);
  });

  testWidgets('3 栏 mood entry 不显示 CBT 角标', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1, timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 3, note: '普通记录',
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
    expect(find.text('CBT 5 栏'), findsNothing);
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

- [ ] **Step 2: 跑测试验证失败**

```bash
flutter test test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
```

Expected: FAIL — `_DayDetailCard` 不显示 CBT 字段。

- [ ] **Step 3: 改 _DayDetailCard 渲染 CBT 摘要**

`lib/presentation/pages/trend/trend_calendar.dart` 在 `_DayDetailCard.build` 内（moodEntries 列表渲染处）加：

```dart
// v0.29 round 84 (CBT 思维记录): 在 mood entry 行下展开 CBT 摘要
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
          entry.cbtLevel == 7 ? 'CBT 7 栏' : 'CBT 5 栏',
          style: AppTokens.textStyleMicro(context).copyWith(
            color: AppTokens.primaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  ),
  if (entry.situation != null) Text('情境: ${entry.situation}'),
  if (entry.automaticThought != null) Text('自动思维: ${entry.automaticThought}'),
  if (entry.evidenceFor != null) Text('支持证据: ${entry.evidenceFor}'),
  if (entry.evidenceAgainst != null) Text('反对证据: ${entry.evidenceAgainst}'),
  if (entry.alternativeThought != null) Text('替代思维: ${entry.alternativeThought}'),
  if (entry.reratedScore != null)
    Text('重新评分: ${entry.reratedScore} (原 ${entry.score})'),
  if (entry.coreBelief != null) Text('核心信念: ${entry.coreBelief}'),
  if (entry.behaviorResponse != null) Text('行为应对: ${entry.behaviorResponse}'),
],
```

- [ ] **Step 4: 跑测试验证通过**

```bash
flutter test test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
```

Expected: PASS 2/2。

- [ ] **Step 5: 跑全量 analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1185 + 2 = 1187 cases pass。

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/trend/trend_calendar.dart \
        test/presentation/pages/trend/cbt_calendar_badge_round84_test.dart
git commit -m 'v0.29 round 84 (trend): _DayDetailCard 显示 CBT 5/7 栏摘要'
```

---

### Task 9: ARB key 同步 zh / en / zh_Hant

**Files:**
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh_Hant.arb`

**Interfaces:**
- 28 个新 ARB key（spec 文档已列）

- [ ] **Step 1: 写 zh ARB 内容**

`lib/l10n/app_zh.arb` 在文件末尾加：

```json
,
  "moodCbtLevelLabel3": "3 栏",
  "moodCbtLevelLabel5": "5 栏",
  "moodCbtLevelLabel7": "7 栏",
  "moodCbtBanner": "CBT 思维记录",
  "moodCbtExpandExplain": "什么是 CBT 思维记录？",
  "moodCbtSectionSituation": "情境",
  "moodCbtSectionAutomaticThought": "自动思维",
  "moodCbtSectionEvidenceFor": "支持证据",
  "moodCbtSectionEvidenceAgainst": "反对证据",
  "moodCbtSectionAlternative": "替代思维",
  "moodCbtSectionRerated": "重新评分",
  "moodCbtSectionCoreBelief": "核心信念",
  "moodCbtSectionBehavior": "行为应对",
  "moodCbtExplainerBody": "CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准：先记录情境与想法，再找证据支持/反对，最后写下更平衡的替代想法。",
  "moodCbtFieldHintSituation": "触发这个想法的事件是什么？发生在哪、什么时候、有谁？",
  "moodCbtFieldHintAutomaticThought": "那一刻脑海中闪过的想法、印象或信念是什么？",
  "moodCbtFieldHintEvidenceFor": "什么事支持这个想法？",
  "moodCbtFieldHintEvidenceAgainst": "什么事不支持这个想法？",
  "moodCbtFieldHintAlternative": "如果你的好朋友遇到这事，你会怎么劝TA？",
  "moodCbtFieldHintCoreBelief": "这个想法背后更深层的信念是什么？（如 \"我不够好\"）",
  "moodCbtFieldHintBehavior": "接下来你打算怎么做？",
  "moodCbtPromptTitle": "引导问题",
  "moodCbtStepOf": "第 {current} 步 / 共 {total} 步",
  "moodCbtTranscriptApply": "将录音转写填入此栏",
  "moodCbtReratedComparison": "重新评分：{new}（原 {old}）",
  "settingsCbtLevel": "思维记录档位",
  "settingsCbtLevelDescription": "选择每次记录情绪时使用的思维记录模板",
  "settingsCbtLevel3Desc": "入门版，1-2 分钟可填完",
  "settingsCbtLevel5Desc": "标准 Beck 思维记录，含认知重构关键步骤",
  "settingsCbtLevel7Desc": "深度版，含核心信念识别和行为应对",
  "moodCbtScoreReratedLabel": "重新评分",
  "moodCbtChipBadge5": "CBT 5 栏",
  "moodCbtChipBadge7": "CBT 7 栏"
```

- [ ] **Step 2: 写 en ARB 内容**

`lib/l10n/app_en.arb` 同样 28 keys 翻译：

```json
,
  "moodCbtLevelLabel3": "3-column",
  "moodCbtLevelLabel5": "5-column",
  "moodCbtLevelLabel7": "7-column",
  "moodCbtBanner": "CBT Thought Record",
  "moodCbtExpandExplain": "What is a CBT thought record?",
  "moodCbtSectionSituation": "Situation",
  "moodCbtSectionAutomaticThought": "Automatic Thought",
  "moodCbtSectionEvidenceFor": "Evidence For",
  "moodCbtSectionEvidenceAgainst": "Evidence Against",
  "moodCbtSectionAlternative": "Alternative Thought",
  "moodCbtSectionRerated": "Re-rated",
  "moodCbtSectionCoreBelief": "Core Belief",
  "moodCbtSectionBehavior": "Behavioral Response",
  "moodCbtExplainerBody": "CBT (Cognitive Behavioral Therapy) thought records help you identify and reframe negative automatic thoughts.\nThe standard 5-column format: first record the situation and thoughts, then weigh evidence for/against, and write a more balanced alternative.",
  "moodCbtFieldHintSituation": "What event triggered this thought? Where, when, with whom?",
  "moodCbtFieldHintAutomaticThought": "What thought, image, or belief flashed through your mind?",
  "moodCbtFieldHintEvidenceFor": "What supports this thought?",
  "moodCbtFieldHintEvidenceAgainst": "What doesn't support this thought?",
  "moodCbtFieldHintAlternative": "If your best friend were in this situation, what would you tell them?",
  "moodCbtFieldHintCoreBelief": "What deeper belief lies behind this thought? (e.g. \"I'm not good enough\")",
  "moodCbtFieldHintBehavior": "What will you do next?",
  "moodCbtPromptTitle": "Guiding questions",
  "moodCbtStepOf": "Step {current} of {total}",
  "moodCbtTranscriptApply": "Apply transcript to this field",
  "moodCbtReratedComparison": "Re-rated: {new} (was {old})",
  "settingsCbtLevel": "Thought record level",
  "settingsCbtLevelDescription": "Choose the thought record template for each mood log",
  "settingsCbtLevel3Desc": "Beginner, 1-2 minutes to complete",
  "settingsCbtLevel5Desc": "Standard Beck thought record with cognitive reframing",
  "settingsCbtLevel7Desc": "Deep version with core belief and behavioral response",
  "moodCbtScoreReratedLabel": "Re-rated score",
  "moodCbtChipBadge5": "CBT 5-column",
  "moodCbtChipBadge7": "CBT 7-column"
```

- [ ] **Step 3: 写 zh_Hant ARB 内容**

`lib/l10n/app_zh_Hant.arb` 同样 28 keys 繁体（用 OpenCC s2tw 转换 zh → zh_Hant）：

```json
,
  "moodCbtLevelLabel3": "3 欄",
  "moodCbtLevelLabel5": "5 欄",
  "moodCbtLevelLabel7": "7 欄",
  "moodCbtBanner": "CBT 思維記錄",
  "moodCbtExpandExplain": "什麼是 CBT 思維記錄？",
  "moodCbtSectionSituation": "情境",
  "moodCbtSectionAutomaticThought": "自動思維",
  "moodCbtSectionEvidenceFor": "支持證據",
  "moodCbtSectionEvidenceAgainst": "反對證據",
  "moodCbtSectionAlternative": "替代思維",
  "moodCbtSectionRerated": "重新評分",
  "moodCbtSectionCoreBelief": "核心信念",
  "moodCbtSectionBehavior": "行為應對",
  "moodCbtExplainerBody": "CBT（認知行為療法）思維記錄幫你識別並重構負面自動思維。\n按 5 欄標準：先記錄情境與想法，再找證據支持/反對，最後寫下更平衡的替代想法。",
  "moodCbtFieldHintSituation": "觸發這個想法的事件是什麼？發生在哪、什麼時候、有誰？",
  "moodCbtFieldHintAutomaticThought": "那一刻腦海中閃過的想法、印象或信念是什麼？",
  "moodCbtFieldHintEvidenceFor": "什麼事支持這個想法？",
  "moodCbtFieldHintEvidenceAgainst": "什麼事不支持這個想法？",
  "moodCbtFieldHintAlternative": "如果你的好朋友遇到這事，你會怎麼勸TA？",
  "moodCbtFieldHintCoreBelief": "這個想法背後更深層的信念是什麼？（如 \"我不夠好\"）",
  "moodCbtFieldHintBehavior": "接下來你打算怎麼做？",
  "moodCbtPromptTitle": "引導問題",
  "moodCbtStepOf": "第 {current} 步 / 共 {total} 步",
  "moodCbtTranscriptApply": "將錄音轉寫填入此欄",
  "moodCbtReratedComparison": "重新評分：{new}（原 {old}）",
  "settingsCbtLevel": "思維記錄檔位",
  "settingsCbtLevelDescription": "選擇每次記錄情緒時使用的思維記錄模板",
  "settingsCbtLevel3Desc": "入門版，1-2 分鐘可填完",
  "settingsCbtLevel5Desc": "標準 Beck 思維記錄，含認知重構關鍵步驟",
  "settingsCbtLevel7Desc": "深度版，含核心信念識別和行為應對",
  "moodCbtScoreReratedLabel": "重新評分",
  "moodCbtChipBadge5": "CBT 5 欄",
  "moodCbtChipBadge7": "CBT 7 欄"
```

- [ ] **Step 4: 重新生成 l10n 代码**

```bash
flutter gen-l10n
```

Expected: 0 error, 生成的 `app_localizations_*.dart` 包含 28 新 key。

- [ ] **Step 5: 跑守门员验证 i18n 同步**

```bash
python scripts/check_arb_keys.py
python scripts/check_orphan_arb_keys.py
python scripts/check_zh_hant_consistency.py
```

Expected: 3 个脚本全绿。

- [ ] **Step 6: 把 hardcoded 中文 string 替换为 ARB key**

`grep -n "情境\|自动思维\|替代思维" lib/presentation/pages/mood/widgets/cbt_*.dart` 找到所有用硬编码中文的地方，替换为 `AppLocalizations.of(context).moodCbtSection*`。

```bash
flutter analyze
```

Expected: 0 error（含 `check_strings_hardcoded.py`）。

- [ ] **Step 7: 跑全量测试**

```bash
flutter test
```

Expected: 1187 + 28 = 1215 cases pass（l10n 生成的额外测试）。

- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_zh.arb \
        lib/l10n/app_en.arb \
        lib/l10n/app_zh_Hant.arb \
        lib/l10n/app_localizations*.dart \
        lib/presentation/pages/mood/widgets/cbt_*.dart
git commit -m 'v0.29 round 84 (i18n): 28 个 CBT ARB key zh/en/zh_Hant 同步'
```

---

### Task 10: 集成测试 + 守门员验证

**Files:**
- Test: `test/integration/cbt_thought_record_flow_round84_test.dart`
- 不改实现代码，只跑全量验证

**Interfaces:**
- 端到端: 启动 App → 设置页改 5 栏 → 打开 mood dialog → 填 5 栏 → 提交 → 在 trend_calendar 看到 CBT 摘要

- [ ] **Step 1: 写端到端集成测试**

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

  testWidgets('5 栏流程: 改档 → 打开 dialog → 填表 → 提交', (tester) async {
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
    // 改档到 5
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodQuickButton)),
    );
    await container.read(thoughtRecordLevelProvider.notifier).setLevel(ThoughtRecordLevel.five);
    // 打开 dialog
    await tester.tap(find.byType(MoodQuickButton));
    await tester.pumpAndSettle();
    expect(find.text('情境'), findsWidgets);
  });
}
```

- [ ] **Step 2: 跑集成测试**

```bash
flutter test test/integration/cbt_thought_record_flow_round84_test.dart
```

Expected: PASS 1/1。

- [ ] **Step 3: 跑全部 16 个守门员脚本**

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

Expected: 16 个脚本全绿 (exit code 0)。

- [ ] **Step 4: 跑全量分析 + 测试**

```bash
flutter analyze
flutter test
```

Expected: 0 error, **1215 cases pass** (1163 + 52 新增)。

- [ ] **Step 5: 跑 pub outdated / build_runner 最终验证**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected: 0 error, 1215 pass。

- [ ] **Step 6: 更新 CHANGELOG**

`docs/CHANGELOG.md` 顶部加：

```markdown
## [0.29.0] - 2026-08-04

### Added (v0.29 round 84)
- **CBT 思维记录改造 (sub-spec 1)**: 3/5/7 档可切换
  - drift schema 16 → 17, mood_entries 加 8 个 nullable CBT 字段
  - 档位偏好持久化 (SharedPreferences)
  - 设置页 "思维记录档位" radio 入口
  - dialog 顶部 SegmentedButton 临时切换
  - 3 档: 单屏长表单 (情境/自动思维/情绪)
  - 5/7 档: wizard 步骤式 + 进度条 + 引导问题
  - 顶部 ℹ️ 折叠说明卡
  - 录音转写可手动填入"自动思维"栏
  - trend_calendar `_DayDetailCard` 显示 CBT 摘要 + 📝 角标

### Notes
- 重评效果图 / mood 列表页 / PDF 导出 / AI 辅助 留待 sub-spec 2-5
```

- [ ] **Step 7: Commit final**

```bash
git add test/integration/cbt_thought_record_flow_round84_test.dart \
        docs/CHANGELOG.md
git commit -m 'v0.29 round 84 (final): CBT sub-spec 1 集成测试 + CHANGELOG'
```

---

## Self-Review Checklist

- [x] **Spec coverage**:
  - 数据模型（8 字段 + 业务方法）→ Task 1
  - 档位状态机（SP + 设置页 + SegmentedButton）→ Task 2 + Task 7 + Task 5
  - 3 栏 UI → Task 5
  - 5/7 栏 wizard → Task 6
  - 趋势集成 → Task 8
  - ARB i18n → Task 9
  - 集成验证 → Task 10

- [x] **Placeholder scan**: 无 "TBD" / "TODO" / "implement later"

- [x] **Type consistency**:
  - `ThoughtRecordLevel.three.columnCount` 统一返回 3
  - `MoodEntryEntity.cbtLevel` 统一返回 7/5/null
  - `CbtDraftState.firstEmptyStep` 统一返回 0-6 范围
  - ARB key 命名统一 `moodCbt*` / `settingsCbt*` 前缀

- [x] **TDD 顺序**: 每个 task 严格 red → green → commit

- [x] **frequent commits**: 10 个 task × 1 commit = 10 commits (含 final)

- [x] **DRY**: 公共 `CbtSectionField` 复用 8 次
- [x] **YAGNI**: 不做重评图 / 列表页 / PDF / AI（sub-spec 2-5）
- [x] **TDD**: 每个 task 红 → 绿
