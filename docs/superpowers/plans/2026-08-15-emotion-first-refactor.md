# v1.1.0 情绪优先重构 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把慢性病管家从"吃药打卡优先"重构为"树洞 + 情绪日记优先"，彻底删除一切外联推送（联系人/SMS/邮件/失联检测/Care Engine），新增树洞标签、情绪状态短语、情绪回顾页三个功能。

**Architecture:** 4 层架构不变（presentation → domain ← data + core/ umbrella）。一次性 schema 22→23（drop contacts + 加 2 列）、export v5→v6（删 contacts 段 + 补新字段 + v5 文件兼容）、/vent 与 /trend 移入 ShellRoute 后导航改 4 tab、首页双主卡。6 个 round 系列 / 16 个 task，每 task 结束独立可验证。

**Tech Stack:** Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6。

**Spec:** `docs/superpowers/specs/2026-08-15-emotion-first-refactor-design.md`

## Global Constraints

- 4 层纯度：domain 0 Flutter / 0 Drift；data 层禁 import `presentation/`、`l10n/`、`core/routing/`；验证 `dart scripts/check_all.dart`（注：用 `dart` 直接跑，不用 `dart run`）
- 每个 task 结束必跑 `flutter analyze`（0 error / 0 warning）且相关测试全绿，再 commit
- commit 风格：`1.1.0 round <N><后缀>: <标题>`——同一 round 内多个 commit 用字母后缀（`1`/`1b`/`1c`、`5`/`5b`…），沿用仓库 `round 56b-e` 惯例；N = 本计划 round 编号
- 守门员全程护航：删除代码的 task 同步改对应守门员脚本（Task 8→check_legal_consent、Task 9→check_sms_release_ready、Task 10→check_pii_in_title），不留跨 task 红灯
- drift 表改动后必跑 `dart run build_runner build --delete-conflicting-outputs`；ARB 改动后必跑 `flutter gen-l10n`（生成文件 app_database.g.dart / app_localizations*.dart 不手改）
- widget 层硬编码中文必须走 ARB key（守门员 check_strings_hardcoded 规则 2）；domain 层常量中文允许（如 care_copy 先例）
- 隐私边界：树洞数据（含新标签）不进趋势/分析/通知
- 测试文件命名：`{module}_round{n}_test.dart`（n = v1.1.0 round 编号）
- working tree 现有 43 个未提交改动（fastlane/ 资产、AppIcon 等）**不属于本计划**，`git add` 只加本计划涉及文件
- 基线：master `55f9dda5`（v1.0.0+147），pubspec 最终版本 `1.1.0+148`

---

## Round 1 — domain 新功能纯函数（Tasks 1-3）

### Task 1: 树洞预设标签库

**Files:**
- Create: `lib/domain/logic/vent_tag_library.dart`
- Test: `test/domain/logic/vent_tag_library_round1_test.dart`

**Interfaces:**
- Produces: `VentTagLibrary.presetTags` (`List<String>`, 8 个中文标签)、`VentTagLibrary.isValidTag(String)` (`bool`)、`VentTagLibrary.maxCustomTagLength` (`int` = 12)。Task 14（compose UI）消费。

- [ ] **Step 1: 写失败测试**

```dart
// test/domain/logic/vent_tag_library_round1_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/vent_tag_library.dart';

void main() {
  group('VentTagLibrary', () {
    test('presetTags 8 个且非空不重复', () {
      expect(VentTagLibrary.presetTags.length, 8);
      for (final t in VentTagLibrary.presetTags) {
        expect(t.trim().isEmpty, isFalse);
      }
      expect(VentTagLibrary.presetTags.toSet().length, 8);
    });

    test('isValidTag: 空串/纯空格/超长 false, 正常 true', () {
      expect(VentTagLibrary.isValidTag(''), isFalse);
      expect(VentTagLibrary.isValidTag('   '), isFalse);
      expect(VentTagLibrary.isValidTag('x' * 13), isFalse);
      expect(VentTagLibrary.isValidTag('家庭'), isTrue);
      expect(VentTagLibrary.isValidTag('  自定义标签  '), isTrue);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/logic/vent_tag_library_round1_test.dart`
Expected: FAIL（`vent_tag_library.dart` 不存在，import error）

- [ ] **Step 3: 写实现**

```dart
// lib/domain/logic/vent_tag_library.dart
/// 树洞预设标签库（v1.1.0）
///
/// 隐私边界：标签仅用于本地整理检索，不进任何分析/趋势/通知。
/// 预置 8 标签 + 自定义标签长度上限 12。
class VentTagLibrary {
  VentTagLibrary._();

  static const List<String> presetTags = [
    '家庭',
    '工作',
    '学业',
    '亲密关系',
    '朋友',
    '身体',
    '情绪',
    '其他',
  ];

  /// 自定义标签最大长度（字符）
  static const int maxCustomTagLength = 12;

  /// 标签合法性：非空 + 不超过 [maxCustomTagLength]
  static bool isValidTag(String tag) {
    final t = tag.trim();
    return t.isNotEmpty && t.length <= maxCustomTagLength;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/logic/vent_tag_library_round1_test.dart`
Expected: PASS（2 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/domain/logic/vent_tag_library.dart test/domain/logic/vent_tag_library_round1_test.dart
git commit -m "1.1.0 round 1: 树洞预设标签库 vent_tag_library + 测试"
```

---

### Task 2: 情绪状态短语库

**Files:**
- Create: `lib/domain/logic/status_phrase_library.dart`
- Test: `test/domain/logic/status_phrase_library_round1_test.dart`

**Interfaces:**
- Produces: `StatusPhraseLibrary.low/tired/calm/positive`（各 `List<String>`）、`StatusPhraseLibrary.all`、`StatusPhraseLibrary.phrasesForScore(int score)`（1-2 → low+tired；3 → calm；4-5 → positive）。Task 15（记录 dialog）消费。

- [ ] **Step 1: 写失败测试**

```dart
// test/domain/logic/status_phrase_library_round1_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/status_phrase_library.dart';

void main() {
  group('StatusPhraseLibrary', () {
    test('4 组短语非空且不重复', () {
      for (final group in [
        StatusPhraseLibrary.low,
        StatusPhraseLibrary.tired,
        StatusPhraseLibrary.calm,
        StatusPhraseLibrary.positive,
      ]) {
        expect(group.length, greaterThanOrEqualTo(4));
        expect(group.toSet().length, group.length);
        for (final p in group) {
          expect(p.trim().isEmpty, isFalse);
        }
      }
    });

    test('all = 4 组拼接', () {
      expect(StatusPhraseLibrary.all, [
        ...StatusPhraseLibrary.low,
        ...StatusPhraseLibrary.tired,
        ...StatusPhraseLibrary.calm,
        ...StatusPhraseLibrary.positive,
      ]);
    });

    test('phrasesForScore 分组规则', () {
      expect(StatusPhraseLibrary.phrasesForScore(1),
          [...StatusPhraseLibrary.low, ...StatusPhraseLibrary.tired]);
      expect(StatusPhraseLibrary.phrasesForScore(2),
          [...StatusPhraseLibrary.low, ...StatusPhraseLibrary.tired]);
      expect(StatusPhraseLibrary.phrasesForScore(3),
          StatusPhraseLibrary.calm);
      expect(StatusPhraseLibrary.phrasesForScore(4),
          StatusPhraseLibrary.positive);
      expect(StatusPhraseLibrary.phrasesForScore(5),
          StatusPhraseLibrary.positive);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/logic/status_phrase_library_round1_test.dart`
Expected: FAIL（文件不存在）

- [ ] **Step 3: 写实现**

```dart
// lib/domain/logic/status_phrase_library.dart
/// 情绪状态短语库（v1.1.0）— 预设短语 + 自定义输入
///
/// 记录 dialog 按当前所选 score 方向优先展示对应组。
class StatusPhraseLibrary {
  StatusPhraseLibrary._();

  static const List<String> low = ['有点难过', '心情很低落', '想哭', '提不起劲'];

  static const List<String> tired = ['疲惫但平静', '好累', '身体被掏空', '只想躺着'];

  static const List<String> calm = ['平静', '安稳', '淡淡的', '没什么特别'];

  static const List<String> positive = ['被治愈了', '心情不错', '充满能量', '有盼头', '很快乐'];

  static const List<String> all = [...low, ...tired, ...calm, ...positive];

  /// score 1-5 → 优先展示的短语组
  /// - 1-2: 低落 + 疲惫
  /// - 3: 平静
  /// - 4-5: 积极
  static List<String> phrasesForScore(int score) {
    if (score <= 2) return [...low, ...tired];
    if (score == 3) return calm;
    return positive;
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/logic/status_phrase_library_round1_test.dart`
Expected: PASS（3 tests）

- [ ] **Step 5: 提交**

```bash
git add lib/domain/logic/status_phrase_library.dart test/domain/logic/status_phrase_library_round1_test.dart
git commit -m "1.1.0 round 1b: 情绪状态短语库 status_phrase_library + 测试"
```

---

### Task 3: 情绪回顾聚合器（纯函数）

**Files:**
- Create: `lib/domain/logic/mood_review_aggregator.dart`
- Test: `test/domain/logic/mood_review_aggregator_round1_test.dart`

**Interfaces:**
- Consumes: `MoodEntryEntity`（现有, `lib/domain/entities/mood_entry_entity.dart`，字段含 `tagsJson`/`influenceFactorsJson`/`period`/CBT 8 字段）
- Produces: `filterByRange(List<MoodEntryEntity>, DateTime start, DateTime endInclusive)`、`MoodReviewSummary`（fields: `entriesCount` int、`avgScore/avgEnergy/avgSleep/avgAnxiety` double?、`scoreDelta` double?、`topTags` List<String> top5、`topInfluenceFactors` List<String> top5、`periodCounts` Map<String,int>、`cbtCount` int、`encouragement` String）、`summarize(List<MoodEntryEntity> current, List<MoodEntryEntity> previous)`。Task 16（回顾页）消费。

- [ ] **Step 1: 写失败测试**

```dart
// test/domain/logic/mood_review_aggregator_round1_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';

MoodEntryEntity _e({
  required int id,
  required DateTime ts,
  int score = 3,
  int? energy,
  int? sleep,
  int? anxiety,
  String tagsJson = '[]',
  String influenceFactorsJson = '[]',
  String? period,
  String? situation,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: ts,
    score: score,
    energy: energy,
    sleep: sleep,
    anxiety: anxiety,
    tagsJson: tagsJson,
    influenceFactorsJson: influenceFactorsJson,
    period: period,
    situation: situation,
  );
}

void main() {
  final start = DateTime(2026, 8, 3);
  final end = DateTime(2026, 8, 9, 23, 59, 59);

  group('filterByRange', () {
    test('边界含 start 和 end', () {
      final entries = [
        _e(id: 1, ts: start),
        _e(id: 2, ts: end),
        _e(id: 3, ts: start.subtract(const Duration(seconds: 1))),
        _e(id: 4, ts: end.add(const Duration(seconds: 1))),
      ];
      final got = filterByRange(entries, start, end);
      expect(got.map((e) => e.id), [1, 2]);
    });
  });

  group('summarize', () {
    test('空集: 计数 0, 均分 null, 鼓励文案空态', () {
      final s = summarize(const [], const []);
      expect(s.entriesCount, 0);
      expect(s.avgScore, isNull);
      expect(s.scoreDelta, isNull);
      expect(s.topTags, isEmpty);
      expect(s.cbtCount, 0);
      expect(s.encouragement, contains('记录'));
    });

    test('单条: 均分 = 该条分数, delta null', () {
      final s = summarize([_e(id: 1, ts: start, score: 4)], const []);
      expect(s.entriesCount, 1);
      expect(s.avgScore, 4.0);
      expect(s.scoreDelta, isNull);
    });

    test('均分取非 null 维度平均, null 维度忽略', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, score: 2, energy: 2),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), score: 4, energy: 4, sleep: 5),
        ],
        const [],
      );
      expect(s.avgScore, 3.0);
      expect(s.avgEnergy, 3.0);
      expect(s.avgSleep, 5.0);
      expect(s.avgAnxiety, isNull);
    });

    test('topTags top5 按频次降序, 同频次按出现顺序', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, tagsJson: '["焦虑","失眠"]'),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), tagsJson: '["焦虑","平静"]'),
          _e(id: 3, ts: start.add(const Duration(hours: 2)), tagsJson: '["焦虑","失眠","易怒","低落","疲惫"]'),
        ],
        const [],
      );
      expect(s.topTags.first, '焦虑');
      expect(s.topTags.length, 5);
    });

    test('topInfluenceFactors 频次降序', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, influenceFactorsJson: '["工作压力"]'),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), influenceFactorsJson: '["工作压力","睡眠不足"]'),
        ],
        const [],
      );
      expect(s.topInfluenceFactors.first, '工作压力');
    });

    test('periodCounts 统计 4 时段', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, period: 'morning'),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), period: 'morning'),
          _e(id: 3, ts: start.add(const Duration(hours: 2)), period: 'evening'),
        ],
        const [],
      );
      expect(s.periodCounts, {'morning': 2, 'evening': 1});
    });

    test('cbtCount: 任一 CBT 字段非 null 计 1', () {
      final s = summarize(
        [
          _e(id: 1, ts: start),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), situation: '开会'),
        ],
        const [],
      );
      expect(s.cbtCount, 1);
    });

    test('scoreDelta = 本周均分 - 上周均分', () {
      final prev = [
        _e(id: 1, ts: start.subtract(const Duration(days: 1)), score: 2),
        _e(id: 2, ts: start.subtract(const Duration(days: 2)), score: 4),
      ];
      final s = summarize([_e(id: 3, ts: start, score: 4)], prev);
      expect(s.scoreDelta, closeTo(1.0, 0.001));
    });

    test('上周空 → delta null', () {
      final s = summarize([_e(id: 1, ts: start, score: 3)], const []);
      expect(s.scoreDelta, isNull);
    });

    test('鼓励文案分档: 低/中/高', () {
      final low = summarize([_e(id: 1, ts: start, score: 2)], const []);
      expect(low.encouragement, contains('照顾自己'));
      final mid = summarize([_e(id: 2, ts: start, score: 3)], const []);
      expect(mid.encouragement, contains('倾诉'));
      final high = summarize([_e(id: 3, ts: start, score: 4)], const []);
      expect(high.encouragement, contains('保持'));
    });

    test('本月跨日多条: entriesCount 正确', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, score: 3),
          _e(id: 2, ts: start.add(const Duration(days: 1)), score: 3),
          _e(id: 3, ts: start.add(const Duration(days: 6)), score: 3),
        ],
        const [],
      );
      expect(s.entriesCount, 3);
    });
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/domain/logic/mood_review_aggregator_round1_test.dart`
Expected: FAIL（文件不存在）

- [ ] **Step 3: 写实现**

```dart
// lib/domain/logic/mood_review_aggregator.dart
/// 情绪回顾聚合器（v1.1.0）— 周/月统计摘要纯函数
///
/// 0 Flutter / 0 Drift 依赖, 输入 entity 列表输出摘要。
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 周/月情绪摘要
class MoodReviewSummary {
  final int entriesCount;
  final double? avgScore;
  final double? avgEnergy;
  final double? avgSleep;
  final double? avgAnxiety;

  /// 本周均分 - 上周均分, 上周无数据 = null
  final double? scoreDelta;
  final List<String> topTags;
  final List<String> topInfluenceFactors;
  final Map<String, int> periodCounts;
  final int cbtCount;

  /// 鼓励文案 (按均分分档)
  final String encouragement;

  const MoodReviewSummary({
    required this.entriesCount,
    this.avgScore,
    this.avgEnergy,
    this.avgSleep,
    this.avgAnxiety,
    this.scoreDelta,
    this.topTags = const [],
    this.topInfluenceFactors = const [],
    this.periodCounts = const {},
    this.cbtCount = 0,
    this.encouragement = '',
  });
}

/// 过滤 [start, endInclusive] 闭区间内的 entries
List<MoodEntryEntity> filterByRange(
  List<MoodEntryEntity> entries,
  DateTime start,
  DateTime endInclusive,
) {
  return entries
      .where((e) => !e.timestamp.isBefore(start) && !e.timestamp.isAfter(endInclusive))
      .toList(growable: false);
}

double? _mean(List<int?> values) {
  final nonNull = values.whereType<int>().toList();
  if (nonNull.isEmpty) return null;
  return nonNull.reduce((a, b) => a + b) / nonNull.length;
}

List<String> _topN(List<String> values, int n) {
  final counts = <String, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(n).map((e) => e.key).toList(growable: false);
}

String _encouragement(double? avgScore, int entriesCount) {
  if (entriesCount == 0) return '这周还没记录心情，从现在开始吧';
  if (avgScore == null) return '继续记录，慢慢了解自己的情绪';
  if (avgScore < 2.5) return '最近有些辛苦，记得照顾自己';
  if (avgScore < 3.5) return '情绪有起伏，倾诉会好受些';
  return '状态不错，继续保持';
}

MoodReviewSummary summarize(
  List<MoodEntryEntity> current,
  List<MoodEntryEntity> previous,
) {
  final avgScore = _mean(current.map((e) => e.score).toList());
  final avgEnergy = _mean(current.map((e) => e.energy).toList());
  final avgSleep = _mean(current.map((e) => e.sleep).toList());
  final avgAnxiety = _mean(current.map((e) => e.anxiety).toList());
  final prevAvgScore = _mean(previous.map((e) => e.score).toList());

  final allTags = <String>[
    for (final e in current) ...JsonCodec.decodeStringList(e.tagsJson),
  ];
  final allFactors = <String>[
    for (final e in current) ...JsonCodec.decodeStringList(e.influenceFactorsJson),
  ];
  final periodCounts = <String, int>{};
  for (final e in current) {
    final p = e.period;
    if (p == null || p == 'unspecified') continue;
    periodCounts[p] = (periodCounts[p] ?? 0) + 1;
  }
  final cbtCount = current.where((e) =>
      e.situation != null ||
      e.automaticThought != null ||
      e.evidenceFor != null ||
      e.evidenceAgainst != null ||
      e.alternativeThought != null ||
      e.coreBelief != null ||
      e.behaviorResponse != null).length;

  return MoodReviewSummary(
    entriesCount: current.length,
    avgScore: avgScore,
    avgEnergy: avgEnergy,
    avgSleep: avgSleep,
    avgAnxiety: avgAnxiety,
    scoreDelta: (avgScore != null && prevAvgScore != null)
        ? avgScore - prevAvgScore
        : null,
    topTags: _topN(allTags, 5),
    topInfluenceFactors: _topN(allFactors, 5),
    periodCounts: periodCounts,
    cbtCount: cbtCount,
    encouragement: _encouragement(avgScore, current.length),
  );
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/domain/logic/mood_review_aggregator_round1_test.dart`
Expected: PASS（12 tests）

- [ ] **Step 5: 验证 + 提交**

```bash
flutter analyze && git add lib/domain/logic/mood_review_aggregator.dart test/domain/logic/mood_review_aggregator_round1_test.dart && git commit -m "1.1.0 round 1c: 情绪回顾聚合器 mood_review_aggregator + 12 case 测试"
```

---

## Round 2 — schema 22→23 + entity/mapper（Tasks 4-5）

### Task 4: schema 23（vent.tagsJson + mood.statusPhrase）+ migration

**Files:**
- Modify: `lib/core/data/database/tables/vent/vent_entries.dart`（表尾加列）
- Modify: `lib/core/data/database/tables/mood/mood_entries.dart`（表尾加列）
- Modify: `lib/core/data/database/app_database.dart:136-137`（schemaVersion 23）+ `:367-372` 后加 migration block
- Test: `test/data/database_migration_round37_test.dart`（更新版本断言 + 新增 2 列 PRAGMA 检查）

**Interfaces:**
- Produces: drift 生成 `VentEntry.tagsJson` (String, default `'[]'`)、`MoodEntry.statusPhrase` (String?)。Task 5/7/14/15 消费。

- [ ] **Step 1: 改两张表定义**

`vent_entries.dart` 在 `audioSizeBytes` 列后加：

```dart
  /// 标签 JSON 数组：'["家庭","工作"]'（v1.1.0）
  ///
  /// 隐私边界：仅本地整理检索，不进任何分析/趋势/通知。
  /// 老数据 = '[]'（空列表）。
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
```

`mood_entries.dart` 在 `recordingMode` 列后加：

```dart
  /// 状态短语（v1.1.0）— 预设短语或自定义一句话, 可空
  ///
  /// 记录 dialog 的"此刻状态"section 写入; 主页情绪大卡展示。
  /// 老数据 = null（大卡退化显示 4 维概括）。
  TextColumn get statusPhrase => text().nullable()();
```

- [ ] **Step 2: 改 app_database.dart**

`schemaVersion` 22 → 23；在 `if (from < 22)` block 之后、`onUpgrade` 末尾加：

```dart
          // v22 to v23: vent_entries +tagsJson, mood_entries +statusPhrase
          // (v1.1.0 情绪优先重构)
          // - tagsJson: 默认 '[]', 老数据自动空列表
          // - statusPhrase: nullable, 老数据自动 null
          if (from < 23) {
            await m.addColumn(ventEntries, ventEntries.tagsJson);
            await m.addColumn(moodEntries, moodEntries.statusPhrase);
          }
```

并更新文件头 doc comment（schemaVersion 23 = v22 + 2 列）。

- [ ] **Step 3: 重生成 drift 代码**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: 更新 migration 测试**

`test/data/database_migration_round37_test.dart`：
1. `schemaVersion == 22` 断言改 `23`
2. `expectedSteps = 21` 改 `22`
3. 新增 group 内测试（仿照现有 `PRAGMA table_info` 模式，在 `AppDatabase key columns` group 尾部追加）：

```dart
    test('vent_entries 加 tags_json 字段 (v22 → v23)', () async {
      final cols = await db.customSelect(
        'PRAGMA table_info(vent_entries)',
        readsFrom: {db.ventEntries},
      ).get();
      final names = cols.map((r) => r.read<String>('name')).toSet();
      expect(names.contains('tags_json'), isTrue,
          reason: 'v23 vent_entries.tagsJson 列缺失');
    });

    test('mood_entries 加 status_phrase 字段 (v22 → v23)', () async {
      final cols = await db.customSelect(
        'PRAGMA table_info(mood_entries)',
        readsFrom: {db.moodEntries},
      ).get();
      final names = cols.map((r) => r.read<String>('name')).toSet();
      expect(names.contains('status_phrase'), isTrue,
          reason: 'v23 mood_entries.statusPhrase 列缺失');
    });
```

若该文件 `5 个核心表都存在` 测试包含 `contacts` 断言，本次不动（Task 9 再删）。

- [ ] **Step 5: 跑测试 + analyze**

Run: `flutter test test/data/database_migration_round37_test.dart && flutter analyze`
Expected: PASS + 0 error

- [ ] **Step 6: 提交**

```bash
git add lib/core/data/database/tables/vent/vent_entries.dart lib/core/data/database/tables/mood/mood_entries.dart lib/core/data/database/app_database.dart lib/core/data/database/app_database.g.dart test/data/database_migration_round37_test.dart
git commit -m "1.1.0 round 2: schema 23 — vent.tagsJson + mood.statusPhrase 两列 + migration + 测试"
```

---

### Task 5: entity + mapper 接新列

**Files:**
- Modify: `lib/domain/entities/vent_entry_entity.dart`（+`tagsJson` 字段 + copyWith + ==）
- Modify: `lib/domain/entities/mood_entry_entity.dart`（+`statusPhrase` 字段 + copyWith + ==）
- Modify: `lib/core/data/database/mappers/vent/vent_mapper.dart`（toEntity/toCompanion 双向）
- Modify: `lib/core/data/database/mappers/mood/mood_entry_mapper.dart`（toEntity/toCompanion/buildMoodEntryEntity）
- Test: `test/data/vent_tag_roundtrip_round2_test.dart`、`test/data/mood_status_phrase_roundtrip_round2_test.dart`

**Interfaces:**
- Produces: `VentEntryEntity.tagsJson` (String 默认 `'[]'`)、`MoodEntryEntity.statusPhrase` (String?)。Task 7/14/15/16 消费。

- [ ] **Step 1: 写失败测试**

```dart
// test/data/vent_tag_roundtrip_round2_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => await db.close());

  test('vent tagsJson round-trip: insert 带标签 → 读出还原', () async {
    final id = await db.ventDao.insert(
      await VentEntryEntity(
        timestamp: DateTime(2026, 8, 15, 12),
        contentText: '今天好累',
        tagsJson: '["家庭","工作"]',
      ).toCompanion(),
    );
    final row = await db.ventDao.getById(id);
    final entity = await row!.toEntity();
    expect(entity.tagsJson, '["家庭","工作"]');
  });

  test('老数据默认 tagsJson = []', () async {
    final id = await db.ventDao.insert(
      await VentEntryEntity(
        timestamp: DateTime(2026, 8, 15, 12),
        contentText: '无标签',
      ).toCompanion(),
    );
    final row = await db.ventDao.getById(id);
    final entity = await row!.toEntity();
    expect(entity.tagsJson, '[]');
  });
}
```

注意：`db.ventDao` 若无 `getById`，按现有 vent repository impl 里取单条的方式（`watchAll` first + where id）改写测试。同理 `mood_status_phrase_roundtrip_round2_test.dart`（insert statusPhrase → 读出相等；null → 读出 null；buildMoodEntryEntity 新参数 statusPhrase 透传）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/vent_tag_roundtrip_round2_test.dart test/data/mood_status_phrase_roundtrip_round2_test.dart`
Expected: FAIL（entity 构造参数不存在）

- [ ] **Step 3: 改两个 entity**

`vent_entry_entity.dart`：加字段

```dart
  /// 标签 JSON 数组（默认 '[]'）
  final String tagsJson;
```

构造参数 `this.tagsJson = '[]'`，copyWith 加 `String? tagsJson`，`==` 比较加 `other.tagsJson == tagsJson`。

`mood_entry_entity.dart`：加字段

```dart
  /// 状态短语（预设或自定义, 可空）
  final String? statusPhrase;
```

构造参数 `this.statusPhrase`，copyWith 加 `String? statusPhrase`，`==` 加比较。

- [ ] **Step 4: 改两个 mapper**

`vent_mapper.dart`：

```dart
// toEntity 内:
    return VentEntryEntity(
      id: id,
      timestamp: timestamp,
      contentText: text,
      audioPath: audioPath,
      audioDurationSec: audioDurationSec,
      audioSizeBytes: audioSizeBytes,
      tagsJson: tagsJson,
    );
// toCompanion 内:
    return VentEntriesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      timestamp: Value(timestamp),
      contentTextEnc: Value(encText),
      audioPath: Value(audioPath),
      audioDurationSec: Value(audioDurationSec),
      audioSizeBytes: Value(audioSizeBytes),
      tagsJson: Value(tagsJson),
    );
```

`mood_entry_mapper.dart`：toEntity 加 `statusPhrase: statusPhrase`；toCompanion 加 `statusPhrase: Value(statusPhrase)`；`buildMoodEntryEntity` 加参数 `String? statusPhrase` 并透传。

- [ ] **Step 5: 跑测试 + analyze（会报其他编译错, 逐个修）**

Run: `flutter test test/data/vent_tag_roundtrip_round2_test.dart test/data/mood_status_phrase_roundtrip_round2_test.dart`
Expected: PASS。`flutter analyze` 若有老调用方报错（entity 构造调用缺新参），确认新参数都有默认值即可，0 改动。

- [ ] **Step 6: 提交**

```bash
git add lib/domain/entities/vent_entry_entity.dart lib/domain/entities/mood_entry_entity.dart lib/core/data/database/mappers/vent/vent_mapper.dart lib/core/data/database/mappers/mood/mood_entry_mapper.dart test/data/vent_tag_roundtrip_round2_test.dart test/data/mood_status_phrase_roundtrip_round2_test.dart
git commit -m "1.1.0 round 2b: entity + mapper 接 vent.tagsJson / mood.statusPhrase + round-trip 测试"
```

---

## Round 3 — export v5→v6（Task 6, 导出+导入合并, 避免中间态红灯）

### Task 6: export v6 全量 — 删 contacts 段 + 补新字段 + v5 文件兼容

**Files:**
- Modify: `lib/core/data/services/export/export_schema_service.dart:51`（currentVersion 5 → 6 + 注释）
- Modify: `lib/core/data/services/export/export_orchestrator.dart`（L108-111 删 contacts 读取；L183-198 删 `'contacts':` 段；L241-282 moodEntries 加 statusPhrase；L283-298 ventEntries 加 tagsJson；L391-421 ExportCounts 删 contactCount；L440 删 importSummaryContact 行）
- Modify: `lib/core/data/services/export/export_import_pipeline.dart`（L45/53 contactCount 删；L132 删 `db.delete(db.contacts)`；L264-321 删 contacts 导入循环；mood 导入段加 statusPhrase；vent 导入段加 tagsJson）
- Test: 新 `test/data/data_export_v6_round3_test.dart`、`test/data/data_export_v6_import_round3_test.dart`；改 `test/data/data_export_v5_round8_test.dart` / `test/data/export_import_pipeline_round99_test.dart` 中 contacts 相关断言

**Interfaces:**
- Consumes: Task 5 的 `tagsJson`/`statusPhrase` entity 字段。
- Produces: v6 JSON（无 `contacts` key；mood 有 `statusPhrase`、vent 有 `tagsJson`）；导入器接受 v1-v6 文件（v5 含 contacts key 时忽略）。

- [ ] **Step 1: 写失败测试**

参考 `test/data/data_export_v5_round8_test.dart`（导出侧）与 `export_import_pipeline_round99_test.dart`（导入侧）的 setup 模式（in-memory db + 填充数据）。新测试：

```dart
// test/data/data_export_v6_round3_test.dart（导出侧）
// 1. json['version'] == 6
// 2. json.containsKey('contacts') == false
// 3. mood entry 带 statusPhrase '被治愈了' → json['moodEntries'][0]['statusPhrase'] == '被治愈了'
// 4. vent entry 带 tagsJson '["家庭"]' → json['ventEntries'][0]['tagsJson'] == '["家庭"]'
// 5. 导出的 summary 字符串不含 '联系人'（contactCount 已删）

// test/data/data_export_v6_import_round3_test.dart（导入侧）
// 1. 构造 v6 JSON (mood statusPhrase / vent tagsJson) → import → 查 DB 还原
// 2. v5 兼容: 构造含 'contacts' key 的 v5 风格 JSON (version: 5)
//    → import 成功 (contacts 忽略, 其他表照常), importSummary 不含 '联系人'
// 3. 老 v4 风格 mood 无 statusPhrase → 导入后 null
```

（测试内填充 mood/vent 用 Task 5 的 entity + companion 方式。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/data/data_export_v6_round3_test.dart test/data/data_export_v6_import_round3_test.dart`
Expected: FAIL（version 断言 6 != 5 / contacts key 存在 / 导入 contacts 断言失败）

- [ ] **Step 3: 改 orchestrator（导出侧）**

1. 删 `final contacts = await _db.contactDao.watchActive()...`（L108-111）
2. 删 `'contacts': [ ... ],` 整段（L183-198）
3. moodEntries 段 `if (m.recordingMode != null) 'recordingMode': m.recordingMode,` 后加：

```dart
            // v1.1.0: 状态短语 (预设或自定义)
            if (m.statusPhrase != null) 'statusPhrase': m.statusPhrase,
```

4. ventEntries 段 `contentText` 行后加：

```dart
            'tagsJson': v.tagsJson,
```

5. `ExportCounts` 删 `contactCount` 字段与构造参数；buildSummary 里删 `Strings.importSummaryContact(contactCount)` 那一行。

- [ ] **Step 4: 改 schema service**

```dart
  /// 当前 schema 版本 (v6: v1.1.0 情绪优先重构 — 删 contacts 段,
  /// mood +statusPhrase, vent +tagsJson)
  static const int currentVersion = 6;
```

- [ ] **Step 5: 改 import pipeline（导入侧）**

1. 删 contacts 导入循环（L264-321）与 `db.delete(db.contacts)`（L132）、`contactCount` 字段/赋值/摘要
2. mood 导入段（找 moodEntries 反序列化循环, 在 recordingMode 附近）加：

```dart
        statusPhrase: Value(
          ExportSchemaService.validateString(
            m['statusPhrase'],
            'mood.statusPhrase',
            maxLen: 100,
          ),
        ),
```

3. vent 导入段加：

```dart
        tagsJson: Value(
          ExportSchemaService.validateString(
            m['tagsJson'],
            'vent.tagsJson',
            maxLen: 1000,
          ) ??
          '[]',
        ),
```

4. v5 文件兼容：`data['contacts']` 段不再被引用即自动忽略；版本校验 `validateVersion` 已接受 1..6。注意本 task 时 `db.contacts` 表尚在（Task 9 才删表），删 `db.delete(db.contacts)` 后导入不清 contacts 是刻意行为。

- [ ] **Step 6: 改老测试**

`data_export_v5_round8_test.dart` / `export_import_pipeline_round99_test.dart`：删 contacts 相关断言与填充；v5 文件 fixture 若含 contacts key 可保留（验证忽略）。

- [ ] **Step 7: 跑 data 层全部测试 + analyze**

Run: `flutter test test/data/ && flutter analyze`
Expected: PASS（data 层全绿）+ 0 error

- [ ] **Step 8: 提交**

```bash
git add lib/core/data/services/export/ test/data/
git commit -m "1.1.0 round 3: export v6 — 删 contacts 段 + statusPhrase/tagsJson + v5 文件兼容 + 测试"
```

---

## Round 4 — 外联全链删除（Tasks 8-10）

> 纯删除任务不用 TDD（先删测试再删代码, analyze 驱动清理残留引用）。顺序：先删/改测试 → 删 lib 文件 → `flutter analyze` 列出残留 → 修 → 测试绿 → commit。

### Task 8: presentation 摘除（setup/settings/home/contact 页）

**Files:**
- Delete: `lib/presentation/pages/contact/`（整目录, 仅 contacts_list_widget.dart）、`lib/presentation/pages/setup/setup_contact_consent_flow.dart`、`lib/presentation/services/safety_check_result_l10n.dart`、`lib/presentation/providers/care_strategy_providers.dart`、`lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart`
- Modify: `lib/presentation/pages/settings/widgets/profile_group.dart`（删联系人 section L84-98）、`lib/presentation/pages/settings/reminders_hub_page.dart`（删 safety 卡 + `_SafetyReminderSheet` + imports）、`lib/presentation/pages/settings/reminders_hub_provider.dart`（删 safety 配置）、`lib/presentation/pages/setup/setup_step_welcome.dart`（删联系人表单 + 参数）、`lib/presentation/pages/setup/setup_page_state.dart`（删 contact controllers）、`lib/presentation/pages/setup/setup_submit_flow.dart`、`lib/core/data/services/setup_committer.dart`（删 contact 参数 + insert + 调用）、`lib/presentation/pages/setup/setup_legal_dialog.dart`（删 SMS 同意文案, 保留热线 section）、`lib/presentation/pages/home/home_page_state.dart`（删 `_runSafetyCheck` + safety imports + initState/deep link 里调用 + `_onCheckIn` 里 care 编排）、`lib/presentation/pages/home/home_page.dart`（HomeLifecycleState 简化为 2 态）、`lib/presentation/pages/home/controllers/home_deep_link_handler.dart`（删 `scheduleSafetyRerun` + `reason=safety` 分支）、`lib/presentation/providers/check_in_notifier.dart`（删 TriggerReminderUseCase 调试入口）、`lib/presentation/widgets/consent_dialog.dart` + `lib/core/shared/consent_gate.dart`（删 emergencyContactSharing/safety 2 分支）、`lib/domain/logic/setup_welcome_form_validator.dart`（删 contact 校验函数, 若无其他 caller）

**HomeLifecycleState 简化（home_page.dart）：**

```dart
enum HomeLifecycleState {
  initial,
  deepLinkHandled;

  HomeLifecycleState onDeepLinkHandled() => switch (this) {
        HomeLifecycleState.initial => HomeLifecycleState.deepLinkHandled,
        HomeLifecycleState.deepLinkHandled => this,
      };
}
```

home_page_state.dart 里所有 `_lifecycle = _lifecycle.onSafetyCheckCompleted()` 调用删；`_lifecycle == HomeLifecycleState.bothHandled` 判断改成 2 态对应。

**测试文件（删/改）**：整删 `test/presentation/widgets/contacts_list_widget_round45_test.dart`、`test/presentation/pages/contact/contact_add_3_step_round95_test.dart`、`test/presentation/reminders_hub_safety_gate_round8_test.dart`。改：`test/presentation/pages/settings/settings_page_r93_hide_test.dart`（删联系人 section case）、`test/presentation/home_lifecycle_round67_test.dart`（改 2 态）、`test/presentation/home_emil_round81_test.dart`（删 care/safety case）、`test/presentation/pages/home/home_fab_toolbar_r93_hide_test.dart`（热线仍保留, 只删 safety 相关）、`test/presentation/pages/home/controllers_round108_test.dart`（删 dispatcher case）、`test/presentation/pages/setup/*`（删 contact 相关 case）。

**守门员同步（全程护航约束）**：`scripts/check_legal_consent.py` 删扫描 `setup_contact_consent_flow` 与 §13 紧急联系人单独同意的检测逻辑（保留 dataExport/vent 检测），本 task 结束跑 `python scripts/check_legal_consent.py` 必须绿。

- [ ] **Step 1: 删/改测试文件**
- [ ] **Step 2: 删 lib 文件（git rm）**
- [ ] **Step 3: 逐文件改 Modify 清单**（每改一个跑 `flutter analyze` 看残留引用, 以 analyze 0 error 为驱动）
- [ ] **Step 4: 同步 check_legal_consent.py + 跑 presentation 测试**

Run: `python scripts/check_legal_consent.py && flutter test test/presentation/`
Expected: 守门员绿 + PASS

- [ ] **Step 5: 提交**

```bash
git add -A lib/presentation test/presentation lib/core/data/services/setup_committer.dart lib/core/shared/consent_gate.dart lib/domain/logic/setup_welcome_form_validator.dart scripts/check_legal_consent.py
git commit -m "1.1.0 round 4: presentation 摘除外联 — contact 页/setup 联系人表单/settings 失联卡/home safety check 全删 + legal_consent 守门员同步"
```

---

### Task 9: data/domain 服务删除 + contacts 表 + providers + flags

**Files:**
- Delete（`git rm`）:
  - `lib/core/data/services/sms_service.dart`、`email_service.dart`、`safety_watch_service.dart`、`safety_alert_builder.dart`、`safety_alert_sender_impl.dart`、`safety_config_service.dart`、`reminder_scheduler.dart`（**已证实 = `ReminderService` 失联通知服务本体**, 文件头自述"失联通知服务（应用层）", 无药物提醒逻辑）
  - `lib/domain/logic/care_engine.dart`、`care_strategies.dart`、`care_copy.dart`、`lost_contact_sms.dart`、`safety_alert_policy.dart`、`safety_detector.dart`、`email_template.dart`
  - `lib/domain/usecases/check_safety.dart`、`dispatch_safety_alert.dart`、`fire_care_strategy.dart`
  - `lib/domain/repositories/safety_alert_sender.dart`、`lib/domain/repositories/reminder_checker.dart`（**删除链闭环**：实现者 ReminderService 本 task 删, 消费者 TriggerReminderUseCase 本 task 删, 抽象无存在意义）
  - `lib/core/data/database/tables/contact/contacts.dart`、`lib/core/data/database/daos/contact_dao.dart`
  - `lib/core/data/repositories/contact/contact_repository_impl.dart`、`lib/core/data/database/mappers/contact/contact_mapper.dart`
  - `lib/domain/entities/contact_entity.dart`、`lib/domain/repositories/contact_repository.dart`
- Modify: `lib/core/data/database/app_database.dart`（删 Contacts/contactDao/imports；migration `if (from < 23)` 块**首行**加 `await m.deleteTable('contacts');`）、`lib/presentation/providers/service_providers.dart`（删 **6 个 provider**：safetyAlertSenderProvider / dispatchSafetyAlertUseCaseProvider / safetyWatchServiceProvider / safetyConfigServiceProvider / **reminderServiceProvider / reminderCheckerProvider**, 连同 ReminderService 构造的 contactRepo/smsService 参数）、`lib/presentation/providers/core_providers.dart`（删 contactRepositoryProvider / smsServiceProvider / smsProviderNameProvider / emailServiceProvider）、`lib/main.dart`（删 sms/email imports + validateForRelease 块 + 2 个 override）、`lib/core/data/feature_flags.dart`（删 3 flag + setter + 注释）、`lib/core/data/services/consent_preference_store.dart`（删 contactId 段 + safety 偏好）、`lib/domain/entities/consent_artifact.dart`（ConsentKind 删 2 值）、`lib/domain/usecases/check_in_usecases.dart`（删 TriggerReminderUseCase）、`lib/core/data/services/reminder_dispatcher.dart`（若 import reminder_scheduler 或 safety, 修正）
- Delete: `scripts/check_sms_release_ready.py`（只扫 sms_service.dart, 同步删, 守门员 22→21）

**app_database.dart migration 改动：**

```dart
          if (from < 23) {
            // v1.1.0: 彻底删除外联推送 — contacts 表整删 (用户决策 D1, 不可逆)
            await m.deleteTable('contacts');
            await m.addColumn(ventEntries, ventEntries.tagsJson);
            await m.addColumn(moodEntries, moodEntries.statusPhrase);
          }
```

**测试文件**：整删所有 safety/sms/email/contact/care 命名的测试（Task 8 已删部分 presentation 侧, 本 task 删 data/domain 侧：`test/data/sms_service_round38_test.dart`、`test/data/email_service_round67_test.dart`、`test/data/email_service_round9_test.dart`、`test/data/safety_watch_service_round12_test.dart`、`test/data/contact_consent_persist_round63_test.dart`、`test/data/safety_test_helpers.dart`、`test/core/data/services/safety_config_service_round92_test.dart`、`test/core/data/services/safety_detector_round64_test.dart`、`test/core/data/services/safety_alert_builder_round65_test.dart`、`test/core/data/services/sms_service_round14_test.dart`、`test/core/data/services/aliyun_sms_provider_round57_test.dart`、`test/domain/care_engine_round3_test.dart`、`test/domain/email_template_round19_test.dart`、`test/domain/lost_contact_sms_round82_test.dart`、`test/domain/care_engine_copy_round18_test.dart`、`test/domain/contact_entity_round12_test.dart`、`test/domain/contact_entity_round18_test.dart`、`test/domain/usecases/check_safety_round65_test.dart`、`test/domain/usecases/fire_care_strategy_round65_test.dart`、`test/domain/logic/care_strategies_round43_test.dart`、`test/domain/logic/care_strategies_perf_round48_test.dart`、`test/core/shared/care_copy_round18_test.dart` 等——以 `git ls-files | grep -E "test/.*(safety|sms|email|contact|care|lost_contact)"` 为准全删）。改：`test/core/data/feature_flags_round93_test.dart`、`test/data/feature_flags_round66_test.dart`、`test/data/feature_flags_round67_test.dart`（删 3 flag case）、`test/data/sort_assumption_round19b_test.dart`、`test/integration/end_to_end_flows_round95_test.dart`（删 contact 步骤）、`test/data/legal_consent_enforcement_round67_test.dart`、`test/data/database_migration_round37_test.dart`（"5 个核心表"测试删 contacts 断言, 新增反向断言：`PRAGMA table_list` 或 `sqlite_master` 查询确认 `contacts` 表不存在）。

- [ ] **Step 1: 整删测试文件 + 改 feature flag 相关测试**
- [ ] **Step 2: git rm 全部 Delete 清单**
- [ ] **Step 3: 改 app_database.dart（migration + 表注册）→ 重跑 build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: 改 providers / main.dart / feature_flags / consent / usecases**（以 `flutter analyze` 0 error 驱动）
- [ ] **Step 5: 跑 data + domain 测试 + 守门员**

Run: `flutter test test/data/ test/domain/ && flutter analyze && ls scripts/check_sms_release_ready.py 2>/dev/null && echo "FAIL: script 还在" || echo "OK: check_sms_release_ready.py 已删"`

Expected: PASS + 0 error + script 不存在

- [ ] **Step 6: 提交**

```bash
git add -A lib test scripts/check_sms_release_ready.py
git commit -m "1.1.0 round 4b: 外联服务全删 — SMS/邮件/SafetyWatch/CareEngine/ReminderChecker/contacts 表 + migration drop + flags 7→4 + 守门员 22→21"
```

---

### Task 10: 通知/路由/consent 清理 + i18n 删除 + gen-l10n

**Files:**
- Modify: `lib/core/data/services/notification_service.dart`（删 showSafetyAlert L348-402、safety 频道 3 const、id band 5000000 注释）、`lib/core/data/services/notification_payload.dart`（删 safetyAlert 枚举 4 处）、`lib/core/data/services/notification_delegate.dart`（注释同步）、`lib/domain/logic/notification_deep_link_resolver.dart`（删 safety-alert 映射）、`lib/core/routing/app_route_check_in.dart`（删 reason=safety 重定向）、`lib/core/data/services/badge_sync_service.dart`（注释同步）、`lib/core/l10n/strings.dart`（删 safety/lost-contact/careCopy/userNameFamily/importSummaryContact 段）、`lib/presentation/pages/settings/legal_page.dart`（删 safety 撤回卡 + ConsentKind.safety 路径, 页面保留）
- Modify: `scripts/check_pii_in_title.py`（守门员同步：删 `safetyAlertTitle` 与 contactName 相关黑名单项, 保留 vent/mood 检测）
- ARB: `l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` 删 key（`safety*` / `contact*` / `emergency*` / `careCopy*` / `lostContact*` / `reminderHubSafety*` / `legalPageWithdrawSafety*` / `setupContact*` / `importSummaryContact`；`homeFabHotline` 除外）
- 生成：重跑 `flutter gen-l10n`
- Test: `test/data/notification_payload_round18_test.dart`、`test/data/notification_navigation_round20_test.dart`、`test/core/data/services/notification_service_round4_test.dart` / `_round19b` / `_split_round45b`、`test/core/data/services/notification_id_band_round110_test.dart`、`test/core/data/services/android_notification_pii_round7_test.dart`、`test/core/data/services/darwin_notification_pii_round6_test.dart`（删 safety 相关 case）、`test/ios/info_plist_background_modes_round108_test.dart`（删 aliyunSms 引用）

**ARB 删除方法**：先跑 `python scripts/check_orphan_arb_keys.py`（会列出已无引用的 orphan），把 orphan 中 safety/contact 相关 key 从 3 个 arb 删除；剩余 grep `safety|contact|emergency|careCopy|lostContact` 在 arb 中逐个确认。

- [ ] **Step 1: 删测试中 safety case（先测试红）**
- [ ] **Step 2: 改 lib 文件清单（analyze 驱动）**
- [ ] **Step 3: 删 ARB key × 3 语言 → `flutter gen-l10n`**
- [ ] **Step 4: 验证 l10n 同步 + 守门员**

Run: `python scripts/check_arb_keys.py && python scripts/check_orphan_arb_keys.py && python scripts/check_zh_hant_consistency.py && python scripts/check_pii_in_title.py`
Expected: 全绿

- [ ] **Step 5: 跑全量测试**

Run: `flutter test && flutter analyze`
Expected: 全过（除 4 个 iOS 资产 fail / 1 skip）+ 0e/0w

- [ ] **Step 6: 提交**

```bash
git add -A lib l10n test scripts/check_pii_in_title.py
git commit -m "1.1.0 round 4c: 通知/路由/consent 清理 + ARB 删 ~80 key + gen-l10n + pii 守门员同步"
```

---

## Round 5 — UI 重构 + 新功能 UI（Tasks 11-15）

### Task 11: 导航 4 tab（心情/树洞/趋势/设置）+ /vent /trend 移入 ShellRoute

**Files:**
- Modify: `lib/core/routing/app_shell.dart:30-73`（`_destinations` + `_currentIndex`）
- Modify: `lib/core/routing/app_route_vent.dart`（`all()` 3 路由改名为 `shellRoutes()`, 删 `all()`）
- Modify: `lib/core/routing/app_route_assessment.dart`（`/trend` 路由从 `all()` 移到新增的 `shellRoutes()`, 其余 4 路由留 `all()`）
- Modify: `lib/core/routing/app_route_main.dart`（ShellRoute.routes 加 `...AppRouteVent.shellRoutes()` 与 `...AppRouteAssessment.shellRoutes()` + imports）
- Modify: `lib/core/routing/app_routes.dart`（`all()` 删 `...AppRouteVent.all(),` 行——vent 已并入 main 的 ShellRoute）
- Modify: `l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb`（删 `navCheckIn`/`navMedication`, 加 `navMood`/`navVent`/`navTrend`）→ `flutter gen-l10n`
- Test: `test/presentation/app_shell_round5_test.dart`

**Interfaces:**
- Produces: tab 路径 `'/'`（心情）/ `'/vent'`（树洞）/ `'/trend'`（趋势）/ `'/settings'`（设置）；`/vent` 3 路由与 `/trend` 在 ShellRoute 内（底栏常驻 + tab 高亮）。

**背景（已证实）**：当前 ShellRoute 只包 `'/'`、`'/settings'`、medication 4 路由（`app_route_main.dart:49-72`, R110 B2-04 模式 `AppRouteMedication.shellRoutes()`）。`/vent` 3 路由（app_route_vent.dart, 全在 `all()`）与 `/trend`（app_route_assessment.dart `all()` L20-24）都在顶层——不移入 shell 则 tab 高亮和底栏常驻全部失效。

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/app_shell_round5_test.dart
// ProviderScope + MaterialApp 包 AppShell(child, currentLocation), 断言:
// 1. NavigationBar 4 个 destination, label 顺序 = 心情/树洞/趋势/设置
// 2. currentLocation '/vent' → selectedIndex == 1
// 3. currentLocation '/vent/compose' → selectedIndex == 1 (前缀匹配)
// 4. currentLocation '/mood-review' → selectedIndex == 0 (心情 tab)
// 5. 宽屏 (surfaceSize 1200x800) 走 NavigationRail, 同样 4 destination
// 另加路由集成断言 (需 MaterialApp.router + routerProvider, 参考 app_route_main 相关测试):
// 6. context.go('/vent') 后 NavigationBar 仍可见 (find.byType(NavigationBar) 非空)
// 7. context.go('/trend') 后 NavigationBar 仍可见
// 8. context.go('/vent/compose') 后 NavigationBar 仍可见
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/presentation/app_shell_round5_test.dart`
Expected: FAIL（当前 3 tab / 集成断言失败）

- [ ] **Step 3: 改 app_shell.dart**

```dart
  static List<_NavDest> _destinations(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return [
      _NavDest(
        label: l10n?.navMood ?? 'Mood',
        icon: Icons.sentiment_satisfied_outlined,
        selectedIcon: Icons.sentiment_satisfied,
        path: '/',
      ),
      _NavDest(
        label: l10n?.navVent ?? 'Vent',
        icon: Icons.forum_outlined,
        selectedIcon: Icons.forum,
        path: '/vent',
      ),
      _NavDest(
        label: l10n?.navTrend ?? 'Trends',
        icon: Icons.show_chart,
        selectedIcon: Icons.show_chart,
        path: '/trend',
      ),
      _NavDest(
        label: l10n?.navSettings ?? 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        path: '/settings',
      ),
    ];
  }
```

`_currentIndex` 更新：`/settings` 前缀 → 3；`/vent` 前缀 → 1；`/trend` 前缀 → 2；其余 → 0。删 `/medication` 分支。

- [ ] **Step 4: 路由移入 ShellRoute**

1. `app_route_vent.dart`：`static List<RouteBase> all()` 改名为 `static List<RouteBase> shellRoutes()`，文件头注释同步（"R110 同款：树洞 3 路由移进 ShellRoute"）
2. `app_route_assessment.dart`：新增

```dart
  /// 趋势路由 (v1.1.0 移进 ShellRoute, 底栏常驻 + tab 高亮)
  static List<RouteBase> shellRoutes() {
    return [
      GoRoute(
        path: '/trend',
        pageBuilder: (context, state) =>
            AppRoutes.slideRightPage(state.pageKey, const TrendPage(), context),
      ),
    ];
  }
```

并把 `all()` 里的 `/trend` GoRoute 删掉（其余 4 路由留 `all()`）
3. `app_route_main.dart`：ShellRoute 的 `routes:` 里 medication 行后加：

```dart
          // v1.1.0: 树洞 + 趋势入 shell (导航 tab 高亮 + 底栏常驻)
          ...AppRouteVent.shellRoutes(),
          ...AppRouteAssessment.shellRoutes(),
```

imports 加 `app_route_vent.dart` / `app_route_assessment.dart`
4. `app_routes.dart`：`all()` 删 `...AppRouteVent.all(),`（vent 已并入 main 的 ShellRoute, 避免重复注册导致 go_router 抛 duplicate path）

- [ ] **Step 5: 改 ARB + gen-l10n**

zh: `"navMood": "心情"`, `"navVent": "树洞"`, `"navTrend": "趋势"`；en: Mood / Vent / Trends；zh_Hant: 心情 / 樹洞 / 趨勢。删 `navCheckIn`/`navMedication`。Run: `flutter gen-l10n`

- [ ] **Step 6: 跑测试 + analyze**

Run: `flutter test test/presentation/app_shell_round5_test.dart && flutter analyze && python scripts/check_arb_keys.py && python scripts/check_orphan_arb_keys.py`
Expected: PASS + 0 error + 守门员绿

- [ ] **Step 7: 提交**

```bash
git add lib/core/routing/ l10n/ lib/l10n/ test/presentation/app_shell_round5_test.dart
git commit -m "1.1.0 round 5: 导航 4 tab — 心情/树洞/趋势/设置 + /vent /trend 入 ShellRoute + ARB nav key + 测试"
```

---

### Task 12: 首页双主卡（MoodHeroCard / VentHeroCard）+ 打卡降级

**Files:**
- Create: `lib/presentation/pages/home/widgets/mood_hero_card.dart`、`lib/presentation/pages/home/widgets/vent_hero_card.dart`
- Modify: `lib/presentation/pages/home/home_page_state.dart`（build 顺序重构：删 QuickMoodCarousel/SecondaryActionRow, 插入 2 张 hero 卡, CheckInButton 降级）、`lib/presentation/widgets/check_in_button.dart`（加 `compact` 参数）、`lib/presentation/pages/home/widgets/primary_action_row.dart`（2x2 改 用药/量表/情绪回顾/日常追踪 + 回调）、`lib/presentation/pages/home/widgets/quick_mood_carousel.dart` 与 `secondary_action_row.dart`（删文件 + 删 import）
- ARB: 新 key `homeMoodHeroTitle/homeMoodHeroRecord/homeMoodHeroReview/homeMoodHeroNoData/homeMoodHeroLastRecorded`、`homeVentHeroTitle/homeVentHeroWrite/homeVentHeroNoData`、`homeActionMedication/homeActionAssessment/homeActionMoodReview/homeActionDailyTracking` → gen-l10n；值微调：`homeFabVent` zh "心情树洞" → "树洞"（与 navVent 一致, 仅改值不改 key）
- Test: `test/presentation/pages/home/home_hero_cards_round5_test.dart`

**Interfaces:**
- Consumes: `moodRepositoryProvider`（core_providers.dart:63, 有 `watchLatest()` → Stream<MoodEntryEntity?>）、`ventEntriesProvider`（vent_providers.dart:51, StreamProvider）、`MoodRecorderPage.show(context, ref)`（mood_recorder_page.dart:69 静态方法）、`/vent/compose`、`/mood-review`（Task 15）
- Produces: MoodHeroCard / VentHeroCard（无参数 ConsumerWidget, 内部取数据）

- [ ] **Step 1: 写失败测试**

```dart
// test/presentation/pages/home/home_hero_cards_round5_test.dart
// ProviderScope overrides (moodRepositoryProvider 返 1 条带 statusPhrase '被治愈了' 的
// entry 流, ventEntriesProvider 返 1 条 contentText '今天想聊聊工作' 的列表),
// pump HomePage 断言:
// 1. 找到 '被治愈了' 文本 (MoodHeroCard 显示短语)
// 2. 找到 '今天想聊聊工作' 截断预览
// 3. 空数据: mood/vent 返空 → 显示 homeMoodHeroNoData / homeVentHeroNoData
// 4. CheckInButton 渲染 compact 尺寸:
//    final size = tester.getSize(find.byType(CheckInButton));
//    expect(size.height, lessThan(64));
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/presentation/pages/home/home_hero_cards_round5_test.dart`
Expected: FAIL（widget 不存在）

- [ ] **Step 3: 写 MoodHeroCard**

```dart
// lib/presentation/pages/home/widgets/mood_hero_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 情绪大卡 — 最新状态短语 + 4 维迷你分 + 记录/回顾入口
class MoodHeroCard extends ConsumerWidget {
  const MoodHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final latestAsync = ref.watch(moodRepositoryProvider).watchLatest();
    return latestAsync.maybeWhen(
      data: (entry) => entry == null
          ? _empty(context, l10n)
          : _loaded(context, l10n, entry),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return AppleListSection(
      title: l10n.homeMoodHeroTitle,
      children: [
        ListTile(
          leading: const Icon(Icons.sentiment_satisfied_outlined),
          title: Text(l10n.homeMoodHeroNoData),
          trailing: FilledButton(
            onPressed: () => MoodRecorderPage.show(context, ref),
            child: Text(l10n.homeMoodHeroRecord),
          ),
        ),
      ],
    );
  }

  Widget _loaded(
    BuildContext context,
    AppLocalizations l10n,
    MoodEntryEntity entry,
  ) {
    final phrase = entry.statusPhrase;
    final summary = phrase ?? _dimensionSummary(l10n, entry);
    return AppleListSection(
      title: l10n.homeMoodHeroTitle,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary, style: AppTokens.textStyleHeadline(context)),
              const SizedBox(height: 4),
              Text(
                l10n.homeMoodHeroLastRecorded(
                  DateFormat('HH:mm').format(entry.timestamp),
                ),
                style: AppTokens.textStyleCaption(context),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => MoodRecorderPage.show(context, ref),
                    child: Text(l10n.homeMoodHeroRecord),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  TextButton(
                    onPressed: () => context.push('/mood-review'),
                    child: Text(l10n.homeMoodHeroReview),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _dimensionSummary(AppLocalizations l10n, MoodEntryEntity e) {
    // 无短语退化: '心情 4 · 精力 3 · 睡眠 3 · 平静 3' 样式, 用 mood_score_chooser
    // 里现有 4 维 label helper (l10n.moodEnergy 等), null 维度跳过
    final parts = <String>[
      '${l10n.moodScore} ${e.score}',
      if (e.energy != null) '${l10n.moodEnergy} ${e.energy}',
      if (e.sleep != null) '${l10n.moodSleep} ${e.sleep}',
      if (e.anxiety != null) '${l10n.moodAnxiety} ${e.anxiety}',
    ];
    return parts.join(' · ');
  }
}
```

注意：`moodScore/moodEnergy/moodSleep/moodAnxiety` 若 ARB 里没有, 用 mood_score_chooser 里实际的 4 维 label key。需要 import `intl` 的 `DateFormat`（或走 `core/shared/formatters.dart` 现有 time 格式化 helper, 执行时看 formatters.dart 用哪个）。

- [ ] **Step 4: 写 VentHeroCard**

```dart
// lib/presentation/pages/home/widgets/vent_hero_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 树洞卡 — 最新倾诉 1 行预览 + 写心事入口
class VentHeroCard extends ConsumerWidget {
  const VentHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(ventEntriesProvider).maybeWhen(
          data: (list) => list,
          orElse: () => const <VentEntryEntity>[],
        );
    final latest = entries.isEmpty ? null : entries.first;
    return AppleListSection(
      title: l10n.homeVentHeroTitle,
      children: [
        ListTile(
          leading: const Icon(Icons.forum_outlined),
          title: latest == null || latest.contentText == null
              ? Text(l10n.homeVentHeroNoData)
              : Text(
                  latest.contentText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: FilledButton.tonal(
            onPressed: () => context.push('/vent/compose'),
            child: Text(l10n.homeVentHeroWrite),
          ),
          onTap: () => context.push('/vent'),
        ),
      ],
    );
  }
}
```

（需要 import `vent_entry_entity.dart`; `ventEntriesProvider` 在 vent_providers.dart:51 已存在。）

- [ ] **Step 5: CheckInButton compact 变体**

`check_in_button.dart` 加 `final bool compact;`（默认 false），height: `compact ? 48 : 64`，字体相应缩小。home 调用 `CheckInButton(compact: true, ...)`。

- [ ] **Step 6: 改 home_page_state.dart build 顺序**

新顺序：banner → HomeHeader → **MoodHeroCard** → **VentHeroCard** → CheckInButton(compact) → TodaySummaryCard → PrimaryActionRow（改回调 `onMedicationTap: /medication`、`onAssessmentTap: /assessment-center`、`onMoodReviewTap: /mood-review`、`onDailyTrackingTap: /daily-tracking`）→ EncouragementText → HomeFooter。删 QuickMoodCarousel / SecondaryActionRow 引用。

- [ ] **Step 7: ARB 新 key × 3 语言 + gen-l10n**

zh 示例：`"homeMoodHeroTitle": "今日心情"`, `"homeMoodHeroRecord": "记录心情"`, `"homeMoodHeroReview": "回顾"`, `"homeMoodHeroNoData": "今天还没记录心情"`, `"homeMoodHeroLastRecorded": "上次记录 {time}"`, `"homeVentHeroTitle": "树洞"`, `"homeVentHeroWrite": "写心事"`, `"homeVentHeroNoData": "还没有倾诉, 写第一条心事"`, `"homeVentHeroLatest": "最新"`, `"homeActionMedication": "用药"`, `"homeActionAssessment": "量表"`, `"homeActionMoodReview": "情绪回顾"`, `"homeActionDailyTracking": "日常追踪"`。（带参 key 用 ARB placeholders 格式 `{time}`）

- [ ] **Step 8: 跑测试 + analyze**

Run: `flutter test test/presentation/pages/home/ && flutter analyze`
Expected: PASS + 0 error（home 老测试如有 QuickMoodCarousel 断言, 同步改）

- [ ] **Step 9: 提交**

```bash
git add -A lib/presentation/pages/home lib/presentation/widgets/check_in_button.dart l10n/ lib/l10n/ test/presentation/pages/home/
git commit -m "1.1.0 round 5b: 首页双主卡 — 情绪大卡+树洞卡, 打卡降级 compact, 快捷操作换血 + 测试"
```

---

### Task 13: 树洞标签 UI（compose 选择 + 列表筛选 + 详情显示）

**Files:**
- Create: `lib/presentation/pages/vent/widgets/vent_tag_picker.dart`
- Modify: `lib/presentation/pages/vent/vent_compose_page.dart`（state 加 `Set<String> _selectedTags`; build 加 VentTagPicker section; 保存时 `tagsJson: JsonCodec.encodeStringList(_selectedTags.toList()..sort())`）
- Modify: `lib/presentation/pages/vent/vent_list_page.dart`（顶部筛选 chips: 全部 + 已用标签; 客户端过滤）
- Modify: `lib/presentation/pages/vent/vent_detail_page.dart`（显示只读标签 chips）
- ARB: `ventTagSectionTitle/ventTagCustomHint/ventTagFilterAll/ventTagFilterEmpty` × 3 → gen-l10n
- Test: `test/presentation/pages/vent/vent_tag_picker_round5_test.dart`、`vent_tag_filter_round5_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// vent_tag_picker_round5_test.dart: pump VentTagPicker(selected: {'家庭'}, onChanged: ...),
// 断言 8 个预设 chip 渲染; tap '工作' → onChanged 收到 {'家庭','工作'};
// TextField 输入 '考研' + onSubmitted → onChanged 含 '考研'
// vent_tag_filter_round5_test.dart: pump 带 mock repo 的 VentListPage (3 条: 2 条带 家庭,
// 1 条带 工作), tap 筛选 chip '家庭' → 列表只显示 2 条
```

- [ ] **Step 2: 跑测试确认失败**
- [ ] **Step 3: 写 vent_tag_picker.dart**

```dart
// lib/presentation/pages/vent/widgets/vent_tag_picker.dart
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/vent_tag_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 树洞标签多选（预置 chips + 自定义输入）
class VentTagPicker extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  const VentTagPicker({super.key, required this.selected, required this.onChanged});

  @override
  State<VentTagPicker> createState() => _VentTagPickerState();
}

class _VentTagPickerState extends State<VentTagPicker> {
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _toggle(String tag) {
    final next = {...widget.selected};
    next.contains(tag) ? next.remove(tag) : next.add(tag);
    widget.onChanged(next);
  }

  void _addCustom(String raw) {
    final tag = raw.trim();
    if (!VentTagLibrary.isValidTag(tag)) return;
    _toggle(tag);
    _customCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allTags = {...VentTagLibrary.presetTags, ...widget.selected};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ventTagSectionTitle, style: AppTokens.textStyleLabelStrong(context)),
        const SizedBox(height: AppTokens.spacingXs),
        Wrap(
          spacing: AppTokens.spacingXs,
          runSpacing: 4,
          children: [
            for (final tag in allTags)
              FilterChip(
                label: Text(tag),
                selected: widget.selected.contains(tag),
                onSelected: (_) => _toggle(tag),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        TextField(
          controller: _customCtrl,
          maxLength: VentTagLibrary.maxCustomTagLength,
          decoration: InputDecoration(hintText: l10n.ventTagCustomHint),
          onSubmitted: _addCustom,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 接入 compose 页**（state 加 `_selectedTags`; 提交入口构造 VentEntryEntity 时加 `tagsJson`; build 在文字输入 section 之后插 `<VentTagPicker>`）
- [ ] **Step 5: 列表筛选**（`vent_list_page.dart` 加 `String? _filterTag` state; 顶部一行 `FilterChip('全部')` + 每个在列表 entries 里出现过的标签一个 chip; entries 按 `JsonCodec.decodeStringList(e.tagsJson).contains(_filterTag)` 过滤; 空结果显示 `ventTagFilterEmpty`）
- [ ] **Step 6: 详情显示**（`vent_detail_page.dart` 文字内容下方只读 Wrap chips, 无标签不显示）
- [ ] **Step 7: ARB × 3 + gen-l10n → 跑测试**

Run: `flutter test test/presentation/pages/vent/ && flutter analyze && python scripts/check_cross_feature.py`
Expected: PASS + 0 error + 0 violation

- [ ] **Step 8: 提交**

```bash
git add -A lib/presentation/pages/vent l10n/ lib/l10n/ test/presentation/pages/vent/
git commit -m "1.1.0 round 5c: 树洞标签 — compose 选择 + 列表筛选 + 详情显示 + 测试"
```

---

### Task 14: 情绪状态短语 UI（记录 dialog + 列表/详情显示）

**Files:**
- Create: `lib/presentation/pages/mood/widgets/status_phrase_field.dart`
- Modify: `lib/presentation/pages/mood/widgets/mood_recorder_page.dart`（state 加 `String? _statusPhrase`; build 在 mood_tags section 后插 StatusPhraseField; 提交时 buildMoodEntryEntity 加 `statusPhrase: _statusPhrase`）
- Modify: `lib/presentation/pages/mood_list/mood_list_page.dart` / `mood_detail_page.dart`（行内显示短语）
- Test: `test/presentation/pages/mood/status_phrase_field_round5_test.dart`、`test/presentation/pages/mood/mood_recorder_status_phrase_round5_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// status_phrase_field_round5_test.dart: pump StatusPhraseField(score: 4, value: null, onChanged: ...)
// 断言 positive 组 5 个 chip 渲染; tap '被治愈了' → onChanged('被治愈了')
// TextField 输入 '自定义一句' → onChanged('自定义一句')
// mood_recorder_status_phrase_round5_test.dart: 打开 MoodRecorderPage → 选短语 → 提交 →
// mock repo 收到的 entity.statusPhrase == 所选短语
```

- [ ] **Step 2: 跑测试确认失败**
- [ ] **Step 3: 写 status_phrase_field.dart**

```dart
// lib/presentation/pages/mood/widgets/status_phrase_field.dart
// StatefulWidget: score + value + onChanged(String?)
// build: 标题 (l10n.moodStatusPhraseTitle) + Wrap of FilterChip
//   (StatusPhraseLibrary.phrasesForScore(score), selected = value)
//   + "全部" 展开 (StatefulBuilder 或 setState 显示 StatusPhraseLibrary.all)
//   + TextField (hint l10n.moodStatusPhraseHint, onSubmitted → onChanged(text.trim()))
// 清除: 已选 chip 再 tap 一次 → onChanged(null)
```

- [ ] **Step 4: 接入 mood_recorder_page.dart**（找到现有 tags/note state 定义处, 照同样模式加 `_statusPhrase`; 找到 `buildMoodEntryEntity(...)` 或 insert 调用点, 加 `statusPhrase: _statusPhrase`; build 中 mood tags section 之后插入 `StatusPhraseField(score: _score, value: _statusPhrase, onChanged: (v) => setState(...))`）
- [ ] **Step 5: 列表/详情显示**（mood_list item: 若 `entry.statusPhrase != null` 显示在标签行前; detail 同理）
- [ ] **Step 6: ARB 新 key × 3 + gen-l10n → 跑测试**

Run: `flutter test test/presentation/pages/mood/ test/presentation/pages/mood_list/ && flutter analyze`
Expected: PASS + 0 error

- [ ] **Step 7: 提交**

```bash
git add -A lib/presentation/pages/mood lib/presentation/pages/mood_list l10n/ lib/l10n/ test/presentation/pages/mood/
git commit -m "1.1.0 round 5d: 状态短语 — 记录 dialog 预设+自定义, 列表/详情显示 + 测试"
```

---

### Task 15: 情绪回顾页 + 路由

**Files:**
- Create: `lib/presentation/pages/mood_list/mood_review_page.dart`
- Modify: `lib/core/routing/app_route_mood_list.dart`（加 `/mood-review` GoRoute, slide-right 过渡）
- ARB: `moodReviewTitle/moodReviewWeek/moodReviewMonth/moodReviewEntriesCount/moodReviewAvgScore/moodReviewAvgEnergy/moodReviewAvgSleep/moodReviewAvgAnxiety/moodReviewDelta/moodReviewTopTags/moodReviewTopFactors/moodReviewPeriod/moodReviewCbtCount/moodReviewDeltaNoData` × 3 → gen-l10n
- Test: `test/presentation/pages/mood_list/mood_review_page_round5_test.dart`

**Interfaces:**
- Consumes: Task 3 的 `filterByRange` / `summarize` / `MoodReviewSummary`; 取数方式同 mood_list_page.dart（复用其 provider/watch）

- [ ] **Step 1: 写失败测试**

```dart
// mood_review_page_round5_test.dart: ProviderScope override mood repo 返固定 3 条
// (本周 2 条: score 2/4 + tags; 上周 1 条: score 3),
// pump MoodReviewPage 断言:
// 1. 标题 moodReviewTitle 渲染
// 2. 记录天数 2 渲染
// 3. 均分 3.0 渲染
// 4. delta (3.0 - 3.0 = 0) 或上周数据场景验证
// 5. SegmentedButton 切 '月' → 过滤范围变化 (entriesCount 变化)
// 6. 空数据 → 空态文案 (domain encouragement 空态文案显示)
```

- [ ] **Step 2: 跑测试确认失败**
- [ ] **Step 3: 写 mood_review_page.dart**

```dart
// lib/presentation/pages/mood_list/mood_review_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class MoodReviewPage extends ConsumerStatefulWidget {
  const MoodReviewPage({super.key});

  @override
  ConsumerState<MoodReviewPage> createState() => _MoodReviewPageState();
}

class _MoodReviewPageState extends ConsumerState<MoodReviewPage> {
  bool _monthly = false;

  DateTime _weekStart(DateTime now) {
    final d = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ref.watch(Stream) → AsyncValue<List<MoodEntryEntity>>
    final entriesAsync = ref.watch(moodRepositoryProvider).watchAll();
    return PageScaffold(
      title: l10n.moodReviewTitle,
      child: entriesAsync.when(
        data: (entries) {
          final now = DateTime.now();
          final start = _monthly
              ? DateTime(now.year, now.month, 1)
              : _weekStart(now);
          final prevStart = _monthly
              ? DateTime(now.year, now.month - 1, 1)
              : _weekStart(now).subtract(const Duration(days: 7));
          final current = filterByRange(entries, start, now);
          final previous = filterByRange(
            entries,
            prevStart,
            start.subtract(const Duration(milliseconds: 1)),
          );
          final s = summarize(current, previous);
          return ListView(
            padding: const EdgeInsets.only(bottom: AppTokens.spacingLg),
            children: [
              const SizedBox(height: AppTokens.spacingSm),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.moodReviewWeek)),
                  ButtonSegment(value: true, label: Text(l10n.moodReviewMonth)),
                ],
                selected: {_monthly},
                onSelectionChanged: (sel) =>
                    setState(() => _monthly = sel.first),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              AppleListSection(
                title: l10n.moodReviewTitle,
                children: [
                  ListTile(
                    title: Text(l10n.moodReviewEntriesCount),
                    trailing: Text(
                      '${s.entriesCount}',
                      style: AppTokens.textStyleHeadline(context),
                    ),
                  ),
                  if (s.avgScore != null)
                    ListTile(
                      title: Text(l10n.moodReviewAvgScore),
                      trailing: Text(s.avgScore!.toStringAsFixed(1)),
                    ),
                  if (s.scoreDelta != null)
                    ListTile(
                      title: Text(l10n.moodReviewDelta),
                      trailing: Text(
                        s.scoreDelta! >= 0
                            ? '+${s.scoreDelta!.toStringAsFixed(1)}'
                            : s.scoreDelta!.toStringAsFixed(1),
                      ),
                    )
                  else
                    ListTile(
                      title: Text(l10n.moodReviewDelta),
                      trailing: Text(l10n.moodReviewDeltaNoData),
                    ),
                ],
              ),
              if (s.topTags.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewTopTags,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: AppTokens.spacingXs,
                        children: [
                          for (final t in s.topTags) Chip(label: Text(t)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (s.topInfluenceFactors.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewTopFactors,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: AppTokens.spacingXs,
                        children: [
                          for (final f in s.topInfluenceFactors)
                            Chip(label: Text(f)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (s.periodCounts.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewPeriod,
                  children: [
                    for (final e in s.periodCounts.entries)
                      ListTile(
                        title: Text(e.key),
                        trailing: Text('${e.value}'),
                      ),
                  ],
                ),
              if (s.cbtCount > 0)
                AppleListSection(
                  children: [
                    ListTile(
                      title: Text(l10n.moodReviewCbtCount),
                      trailing: Text('${s.cbtCount}'),
                    ),
                  ],
                ),
              const SizedBox(height: AppTokens.spacingMd),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  s.encouragement,
                  textAlign: TextAlign.center,
                  style: AppTokens.textStyleCaption(context),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
```

（`ref.watch(moodRepositoryProvider).watchAll()` 是 Riverpod 3 的 `ref.watch(Stream)` 模式, 返回 `AsyncValue<List<MoodEntryEntity>>`; 若 analyzer 提示 watch 不支持直接 Stream, 改为现有 `moodEntriesProvider`-style 的 `StreamProvider` 或在 `core_providers.dart` 加一个 `allMoodEntriesProvider = StreamProvider((ref) => ref.watch(moodRepositoryProvider).watchAll())`。）

- [ ] **Step 4: 加路由**

`app_route_mood_list.dart` 加：

```dart
  GoRoute(
    path: '/mood-review',
    pageBuilder: (context, state) => AppRoutes.slideRightPage(
      const ValueKey('mood-review'),
      const MoodReviewPage(),
      context,
    ),
  ),
```

（用现有 mood-list 路由同款写法与 import。）

- [ ] **Step 5: ARB × 3 + gen-l10n → 跑测试**

Run: `flutter test test/presentation/pages/mood_list/ && flutter analyze && python scripts/check_cross_feature.py`
Expected: PASS + 0 error + 0 violation

- [ ] **Step 6: 提交**

```bash
git add lib/presentation/pages/mood_list/mood_review_page.dart lib/core/routing/app_route_mood_list.dart l10n/ lib/l10n/ test/presentation/pages/mood_list/mood_review_page_round5_test.dart
git commit -m "1.1.0 round 5e: 情绪回顾页 — 周/月统计摘要 + /mood-review 路由 + 测试"
```

---

## Round 6 — 守门员 + 文档 + 终验（Tasks 16-17）

### Task 16: 守门员变更 + 文档 + 版本号

**Files:**
- Delete: `scripts/check_sms_release_ready.py`
- Modify: `scripts/check_pii_in_title.py`（删 safetyAlertTitle / contactName 黑名单项）、`scripts/check_legal_consent.py`（删紧急联系人 §13 检测）、`README.md`（副标题删"失联通知"、定位改情绪优先）、`docs/CHANGELOG.md`（新 `[1.1.0]` 条目：删除外联 + 3 新功能 + UI 权重）、`AGENTS.md`（隐私边界表 / FeatureFlag 7→4 / 守门员 22→21 / 路线图）、`pubspec.yaml`（`1.1.0+148`）
- Test: `test/scripts/data_safety_form_round108_test.py`（若断言涉及 sms/safety 删之）

- [ ] **Step 1: 改守门员脚本**

`check_pii_in_title.py`：读脚本找到 `title_func_names` 列表与 PII 黑名单, 删 `safetyAlertTitle` 与 contact 相关项（vent/mood 相关保留）。`check_legal_consent.py`：删扫描 `setup_contact_consent_flow` 的逻辑与 §13 联系人断言, 保留 dataExport/vent 检测。删 `check_sms_release_ready.py`。

- [ ] **Step 2: 跑守门员验证**

```bash
for f in scripts/check_arb_keys.py scripts/check_changelog.py scripts/check_cross_feature.py scripts/check_datetime_race.py scripts/check_datetime_race2.py scripts/check_drift_namespace.py scripts/check_fullwidth_punctuation.py scripts/check_no_hardcoded_utc.py scripts/check_no_pua.py scripts/check_widget_dispose.py scripts/check_orphan_arb_keys.py scripts/check_legal_consent.py scripts/check_strings_hardcoded.py scripts/check_zh_hant_consistency.py scripts/check_16kb_alignment.py scripts/check_coverage.py scripts/check_apple_health_claim.py scripts/check_pii_in_title.py scripts/check_usecase_layer.py scripts/check_review_information_todo.py; do python "$f" || echo "FAIL: $f"; done
dart scripts/check_all.dart
```

Expected: 全部 OK（check_16kb_alignment 允许 skip 待重 build；check_fullwidth_punctuation 为 warn-only；check_coverage 若 presentation 覆盖率掉到阈值下, 补齐测试再继续）

- [ ] **Step 3: 文档 + 版本**

README 定位段改：情绪日记 + 树洞倾诉优先、用药记录辅助；删除失联通知功能描述。CHANGELOG 按 Keep a Changelog 格式加 `[1.1.0]`（Added: 树洞标签/状态短语/情绪回顾页; Changed: 导航 4 tab/首页双主卡; Removed: 紧急联系人/失联通知/SMS/邮件/Care Engine）。AGENTS.md 同步（隐私边界表删"失联通知"行、flag 清单 4 个、守门员清单 21 个）。pubspec `version: 1.1.0+148`。

- [ ] **Step 4: 提交**

```bash
git add scripts/ README.md docs/CHANGELOG.md AGENTS.md pubspec.yaml test/scripts/
git commit -m "1.1.0 round 6: 文档/版本收尾 — README/CHANGELOG/AGENTS 同步 + 版本 1.1.0+148"
```

---

### Task 17: 全量终验

**Files:** 无新文件（若有 fail 就地修）

- [ ] **Step 1: 全量测试 + analyze**

```bash
flutter analyze
flutter test
```

Expected: analyze 0e/0w；test 全过除 4 个 iOS 资产占位 fail + 1 skip（数值与 CHANGELOG 记录一致）

- [ ] **Step 2: 全部守门员 + 架构检查**

Run: Task 16 Step 2 同款命令
Expected: 全绿

- [ ] **Step 3: 冒烟清单核对（spec §11）**

1. 记录心情带短语 → 首页大卡显示 ✓（Task 12/14 widget test 覆盖）
2. 回顾页有数据（Task 15 test 覆盖）
3. 树洞带标签可筛选（Task 13 test 覆盖）
4. 吃药提醒照常触发（`flutter test test/core/data/services/reminder_dispatcher_round37_test.dart` + notification 系列仍绿）
5. 热线页可开（`crisis_hotline_page` 未动, 路由 `/crisis-hotline` 仍在）
6. schema 22→23 升级测试绿（Task 4）
7. export v5 文件可导入（Task 7）

- [ ] **Step 4: 最终提交（若 Step 1-3 有修复）**

```bash
git add -A lib test && git commit -m "1.1.0 round 6b: 全量终验收尾修复"
```

- [ ] **Step 5: 汇报**

向用户报告：净删行数（`git diff --shortstat 55f9dda5..HEAD`）、最终 test 计数、21 守门员状态、剩余已知 fail（iOS 资产 4 项）。

---

## Self-Review 备注

- **编号说明**：Task 7 已并入 Task 6（export 导出+导入合并, 避免中间态红灯），共 16 个 task，后续编号不变（8-17）。
- **Spec 覆盖核对**：§3 A1-A7 → Tasks 8/9/10；§4 B1-B3 → Tasks 11/12（B1 的 ShellRoute 前置条件已写入 Task 11 步骤）；§5 C1-C3 → Tasks 1/3/13/14/15；§6 i18n → Tasks 10/11/12/13/14/15；§7 测试 → 各 task 内嵌；§8 守门员 → Tasks 8/9/10（同步改）+ 16（终验）；§9 文档 → Task 16；§10 r1-r6 → Round 1-6 对应；§11 验收 → Task 17。
- **类型一致性**：`filterByRange(entries, start, endInclusive)` / `summarize(current, previous)` 在 Task 3 定义、Task 15 消费，签名一致；`VentTagLibrary.presetTags` Task 1 定义、Task 13 消费；`StatusPhraseLibrary.phrasesForScore(score)` Task 2 定义、Task 14 消费；`tagsJson`/`statusPhrase` 字段名 Task 4/5 定义、Task 6/13/14 消费。
- **已知依赖顺序**：Task 13/14/15 依赖 Round 1 的 domain 库与 Round 2 的 schema；Task 8/9 删除会破坏老测试, 必须同 task 内删/改测试；`Strings.importSummaryContact` 在 Task 6 停止使用、Task 10 从 strings.dart 删除。
- **审计修正记录（2026-08-15 自审）**：① 证实 reminder_scheduler.dart = ReminderService 失联服务本体（spec A1 + Task 9 已写实锤）；② 补 ReminderChecker 删除链（Task 9）；③ phone_validator 已在 core/shared, spec 更正；④ /vent /trend 移入 ShellRoute 补入 Task 11；⑤ 守门员变更前置到 8/9/10；⑥ export 任务合并；⑦ FAB 文案"心情测试"已过时（R91 已改日常追踪）, spec B2 该条作废, Task 12 仅微调 homeFabVent 值。
