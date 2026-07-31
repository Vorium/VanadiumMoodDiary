# Lens 06 — 阿里巴巴开发规范视角（Flutter / Dart 等价映射）

> **范围**：`lib/domain/entities/` (11) + `lib/domain/logic/` (18) + `lib/core/data/database/tables/` (7) + `lib/core/data/repositories/` (7) + `lib/core/data/services/` (31) + `lib/core/shared/` (6) + `lib/presentation/providers/` (10) + 抽 10+ test + `scripts/check_all.dart` + `pubspec.yaml` + `analysis_options.yaml`
>
> **结论一句话**：项目在「OOP 完整性 / 4 层架构 / 资源释放 / 安全加密 / 异常日志」上几乎满分，**P0 违反 0 处**；**P1 主要问题是 `analysis_options.yaml` 规则太宽松 + 2 个 entity 缺 `library;` 指令 + 主键索引完整但 `timestamp` 无索引**；P2/P3 大量 `prefer_const_constructors` / `require_trailing_commas` 风格待 `dart fix --apply`。

---

## 1. P0 强制规约 — 0 处违反

| 维度 | 阿里规约 | 本项目 | 状态 |
|---|---|---|---|
| 类名 UpperCamelCase | 必须 | `UserProfileEntity` / `MedicationEntity` / `CareEngine` / `StreakCalculator` | ✅ |
| 方法 lowerCamelCase | 必须 | `getLatestNormalCheckIn` / `evaluateLevel` / `dispatchAlert` | ✅ |
| 常量 | UPPER_SNAKE | Dart 规范 lowerCamelCase（`safetyAlertId` / `defaultThresholdDays`） | ✅ 符合 Dart 官方 |
| private `_` 前缀 | 必须 | `_db` / `_checkInRepo` / `_randomBytes` 全员 private | ✅ |
| 文件名 snake_case | 必须 | `medication_repository_impl.dart` / `user_profiles.dart` | ✅ |
| 不用拼音 | 必须 | 全部英文 + 极少量中文注释 | ✅ |
| `==` + `hashCode` 一起 | 强制 | 9 个 entity 全部手写（grep: 124 处 `==\|hashCode`） | ✅ |
| `toString` 强制 | 强制 | 9 个 entity 全部实现 | ✅ |
| `const` 构造 | 强制 | `const VentEntryEntity({...})` / `const HourMinute({...})` | ✅ |
| `@override` 注解 | 强制 | 9 个 entity 全部有 `@override` 标记 | ✅ |
| `@DataClassName` 唯一 | MySQL 规约 | drift 7 张表全用单数 PascalCase (CheckIn / Medication / VentEntry) | ✅ |
| 主键 id 必填 | MySQL 规约 | 7 表全 `integer().autoIncrement()` 或 `withDefault(Constant(1))` 单行 | ✅ |
| timestamp 默认值 | MySQL 规约 | `dateTime()` 显式无默认（业务驱动写时戳） | ✅ 合理 |
| `package:` 不用 wildcard | 强制 | 全部显式 import，0 wildcard | ✅ |
| import 不重复 | 强制 | 0 重复 | ✅ |
| 单元测试 AIR (Auto/Independent/Repeatable) | 强制 | 全用 `setUp` / `tearDown` + `NativeDatabase.memory()` + `SharedPreferences.setMockInitialValues({})` | ✅ |
| 不吞错 (`catch (_)`) | 强制 | 全 lib 只 5 处 `catch (_)`，全在 `swallow_error.dart` / `json_codec.dart` / `assessment_record.dart` / 2 个 mapper/export（按设计 0 production swallow） | ✅ |
| Flutter secure storage + SQLCipher | 强制 | `flutter_secure_storage: ^9.2.2` + `sqlcipher_flutter_libs: ^0.6.4` + AES-256-CBC | ✅ |
| 不打印 PII | 强制 | `pii_safe_log.dart` + `maskPhone()`（`sms_service.dart:76`） | ✅ |
| Resource cleanup | 强制 | `ref.onDispose(() => db.close())`（`core_providers.dart:31`）+ `autoDispose` 全员 + `Random.secure()` crypto | ✅ |
| 异常带 trace | 强制 | `swallowError(..., error: e, stack: st)` + `piiSafeLog(..., error: e, stackTrace: st)` | ✅ |

**4 层架构综合检查**（`scripts/check_all.dart` v0.18 R19）— **两次跑全绿**：
- [1/2] 纯度：domain/shared 0 flutter/0 drift/0 data/0 presentation；data 不依赖 presentation ✅
- [2/2] 一致性：所有 `*Entity` ↔ `@DataClassName('X')` 1:1 对应；shared 6 文件全被 ≥2 层用 ✅

---

## 2. P1 强制规约违反 — 4 处（建议修）

### 2.1 `analysis_options.yaml` 规则严重不足（**P1-1**）

阿里「强制 7+ 规约」本项目只开 4 条：
```yaml
linter:
  rules:
    - avoid_print                  # ✅ 强制
    - prefer_const_constructors    # ✅ 强制
    - prefer_const_literals_to_create_immutables  # ✅ 强制
    - require_trailing_commas      # ✅ 强制
```
**缺**（阿里强制）：
- `lines_longer_than_80_chars`（阿里 120 / Dart 80）
- `public_member_api_docs`（public API 必须 dartdoc）
- `document_ignores`（强制 TODO/FIXME 标 `@author + @date`）
- `always_declare_return_types`
- `avoid_dynamic_calls`
- `unawaited_futures`（异步 fire-and-forget 必查）

**修复方案**：补 6+ 条。`flutter_lints` 默认 `recommended.yaml` 35 条可直接继承。

### 2.2 2 个 entity 缺 `library;` 指令（**P1-2**，dangling doc comment）

flutter analyze 直接报：
- `lib/domain/entities/user_profile_entity.dart:1:1` — `info - Dangling library doc comment`
- `lib/domain/entities/report_history_entity.dart:1:1` — 同上

对比 `vent_entry_entity.dart:11` 正确写法：
```dart
/// 用户档案（domain 实体）   ← 这两条是 dangling (缺 library;)
///
/// 对应 Drift 表 `user_profiles`。
```
**修复**：开头加 `library;`，或去掉 `///` 改 `//` 注释（project convention 看 `vent_entry_entity` 是用 `library;`）。

### 2.3 `timestamp` 列无索引（**P1-3**）

Drift 7 表 5 张有 `DateTimeColumn timestamp`（`check_ins` / `medications` / `mood_entries` / `vent_entries` / `report_histories`），均无 index 声明。
高频查询 `getLatestNormalCheckIn`（`check_in_repository_impl.dart`）：
```sql
SELECT * FROM check_ins WHERE type = 'normal' ORDER BY timestamp DESC LIMIT 1
```
无 `idx_check_ins_type_ts` → 全表扫描，**1000+ 行后劣化**（精神心理患者长期用药 5+ 年 = 1800+ 行）。

**修复**（`check_ins.dart`）：
```dart
@DriftDatabase(tables: [CheckIns], ...)
class AppDatabase extends _$AppDatabase {
  // ...
}
// 或在 column 上:
@override
List<Set<Column>> get uniqueKeys => [{type, timestamp}];
```

### 2.4 MockSmsProvider.send() 仍 `throw UnimplementedError` 但被 catch（**P1-4**，设计缺陷）

`sms_service.dart:83` `MockSmsProvider.send()` 抛 `UnimplementedError` → `SmsService.send:286` `catch` 返 `SmsResult.fail`。
虽然 R52 改成 3 态 `SmsResultKind` (ok/fail/mock) 让 dispatcher 区分，但 **AliyunSmsProvider.send() 也 throw**（`sms_service.dart:156`），release 模式仍 catch 成 fail。
**修法**：跟 `isProductionReady` 一致，**alibaba 异常规约禁止捕获 unchecked Exception 静默**——release 应让 `AliyunSmsProvider.send` 真接或更早抛 `UnimplementedError` 阻断启动（参考 `validateForRelease` 模式）。

---

## 3. P2 推荐规约违反 — 7 处

### 3.1 68 个 info 警告未清（dart fix 一次性可消 50+）
- `prefer_const_constructors` 30+ 处（`home_footer.dart:33` / `loading_skeleton.dart:128` / `trend_page.dart:91` 等）
- `require_trailing_commas` 35+ 处（`medication_entity_hashcode_round60_test.dart` 6+、`phq9_detect_crisis_round60_test.dart` 12+）
- `unnecessary_brace_in_string_interps` 1 处

**修法**：`dart fix --apply && dart format .`

### 3.2 测试文件 `require_trailing_commas` 未统一（**P2-1**）
`analysis_options.yaml` 开 `require_trailing_commas` 但 round 60+ 新增 test 文件未格式（12+ 处）。**建议**：CI 跑 `dart format --set-exit-if-changed` 守门。

### 3.3 4 个 `TODO` 标在 `.dart` 文件但无 `@author` / `@since`（**P2-2**）
grep 找到 5 文件含 `TODO|FIXME`：`sms_service.dart`（R55 真接 SMS）、`notification_service.dart`、`email_service.dart`、`badge_sync_service.dart`、`app_theme.dart`。
阿里规约：必须 `@author 张三 @date 2026-07-13`。
**修法示例**（`sms_service.dart:156`）：
```dart
// TODO(@alibaba-style, 2026-07-13): 真接阿里云 SMS
//  - spzh P0 #6 / R55 计划
//  - 需法务模板审核 + 阿里云 AccessKey 申请
throw UnimplementedError(...);
```

### 3.4 `EncryptionService` 静态单例导致测试隔离问题（**P2-3**）
`encryption_service.dart:41-43`：
```dart
static final EncryptionService _shared = EncryptionService._internal();
factory EncryptionService() => _shared;
```
`setKeyForTest` 注入 key，但所有测试共享同一 instance → 测试间 key 缓存不隔离。
**修法**：测试用 `EncryptionService.forTesting()`（不走单例）or 每次 `setUp` 调 `resetForTest()`。

### 3.5 `MedicationEntity` `_listEq` 手写 list 相等（**P2-4**）
`medication_entity.dart:150-156` 手写 `List<HourMinute>` 比较，hashCode 也用 `Object.hashAll`。
阿里推荐用 `package:collection` 的 `ListEquality<T>()` 或扩展。
**现状**：可工作但**不通用**——其他 entity 需各自手写。**建议**：抽 `lib/core/shared/list_equality.dart` 集中。

### 3.6 `analyzer` 开了 `strict-casts/strict-inference/strict-raw-types` 但 `valid_annotation_target: ignore`（**P2-5**）
drift `@DataClassName` / `@override` 触发 `invalid_annotation_target`，所以 ignore——合理但**应加 `// ignore_for_file: comment` 注释解释**（search 全 lib 0 处有此注释）。

### 3.7 `sms_service.dart:1` 文件 BOM 残留（**P2-6**）
文件首字节 `\uFEFF`（grep 多个文件首字符是 BOM）：
- `sms_service.dart:1`  `\ufeff` BOM
- `safety_watch_service.dart:1`  `\ufeff` BOM
- `test/data/sort_assumption_round19b_test.dart:1`  `\ufeff` BOM
- `test/data/safety_watch_service_round12_test.dart:1`  `\ufeff` BOM
**修法**：`Get-ChildItem lib test -Recurse -Filter *.dart | ForEach-Object { (Get-Content $_.FullName -Encoding UTF8) | Set-Content -Encoding UTF8NoBOM }`（PowerShell `-Encoding UTF8NoBOM`，或 `dos2unix` 批量）。

---

## 4. P3 风格 / 建议 — 5 处

| # | 文件 | 问题 | 建议 |
|---|---|---|---|
| 1 | `mood_visual.dart:11` | `// ignore_for_file: prefer_const_constructors` | 加 `// reason: ...` 注释 |
| 2 | `mood_visual.dart:25-35` | emoji hardcoded（😢/😟/😐/🙂/😄） | 移到 `core/l10n/strings.dart` (跟 R2-7 Q1 fix 一致) |
| 3 | `check_in_entity.dart:53-60` | `CheckInTypeX.label` 硬编码中文 ('每日打卡' / '临时吃药' / 'PHQ-9 评估' / 'GAD-7 评估') | 跟 R2-7 同款 — 改 `AppLocalizations` |
| 4 | `safety_watch_service.dart:90-119` | doc comment 80+ 行（round 注释历史） | 拆 CHANGELOG / docs 目录，文件顶部只留 ≤10 行 summary |
| 5 | `medication_entity.dart:147` | `toString` 返 `'MedicationEntity(id=$id, name=$name, ...)'` 含 PII 风险 | `toString` 删 name（用户在 medication list 多行打印 stack） |

---

## 5. 守门员覆盖矩阵

| 阿里规约大类 | 对应守门员 | 状态 |
|---|---|---|
| 命名 | 人工 review（grep `^class \w+Entity` regex） | ⚠️ 无自动 |
| 类注释 | `analysis_options.yaml` 缺 `public_member_api_docs` | ❌ |
| 行宽 80 | 缺 `lines_longer_than_80_chars` | ❌ |
| import 纯净 | `python scripts/check_cross_feature.py` + `dart scripts/check_all.dart` | ✅ 双保险 |
| OOP (==+hashCode) | 1098 个 test case（`medication_entity_hashcode_round60_test.dart` 16 case 覆盖） | ✅ |
| catch(_) 0 吞错 | 人工 grep（项目实践"5 处全在 swallow 工具内"） | ⚠️ 无自动 |
| 资源释放 | 人工 review（`ref.onDispose` + `try/finally`） | ⚠️ 无自动 |
| SQL 规约 | 人工 review（`check_no_pua.py` + `check_drift_namespace.py`） | ⚠️ 部分 |
| 安全 | `check_legal_consent.py` + `check_sms_release_ready.py` + `check_legal_consent.py` | ✅ |
| 覆盖率 ≥ 80% | **未集成 coverage** | ❌ P0 缺 |
| 单测 AIR/BCDE | 86 → 116 文件（v0.27），1:1 round 编号 | ✅ |

---

## 6. 评分（5 分制）

| 维度 | 评分 | 说明 |
|---|---|---|
| 命名规范 | ⭐⭐⭐⭐⭐ | UpperCamelCase / lowerCamelCase / snake_case 全员一致，0 拼音 |
| OOP 完整性 | ⭐⭐⭐⭐⭐ | 9 entity 全 ==/hashCode/toString + const + copyWith + DomainValue 包装 |
| 注释覆盖率 | ⭐⭐⭐⭐ | public API 注释率高（377 处 `///` in domain/logic），但 2 entity 缺 library; |
| 代码风格 | ⭐⭐⭐ | `analysis_options.yaml` 4 条太松，68 info 警告 |
| import 纯净 | ⭐⭐⭐⭐⭐ | `check_all.dart` 双报告 + `check_cross_feature.py` 双保险 |
| 异常日志 | ⭐⭐⭐⭐⭐ | 5 处 catch(_) 全在 swallow 工具内 + piiSafeLog + developer.log + LastErrorCapture |
| 并发资源 | ⭐⭐⭐⭐⭐ | ref.onDispose + autoDispose + timeout 降级 + Random.secure 齐全 |
| 单元测试 | ⭐⭐⭐⭐ | 116 文件 / 1098+ case / AIR-BCDE 全员，但无 coverage 数据 |
| 安全 | ⭐⭐⭐⭐⭐ | AES-256 + SQLCipher + flutter_secure_storage + PII mask + PIPL §14/§28 |
| Drift 规约 | ⭐⭐⭐⭐ | 表名/主键/常量/nullable 全合规，timestamp 缺索引（**P1-3**） |
| Riverpod 规约 | ⭐⭐⭐⭐⭐ | 接口暴露 / autoDispose / 拆 10 个文件按职责 |
| **综合** | **⭐⭐⭐⭐ (4.5/5)** | 仅 P1-1（analysis_options 规则）+ P1-2（dangling doc）+ P1-3（timestamp 索引）需修 |

---

## 7. 立即可修清单（按 ROI 排序）

| 优先级 | 工作量 | 修复 |
|---|---|---|
| **P0-1** | 30 min | 集成 `flutter_lints/recommended.yaml` + 加 6+ 强制规则（`lines_longer_than_80_chars` / `public_member_api_docs` / `unawaited_futures` / `always_declare_return_types` / `avoid_dynamic_calls` / `document_ignores`） |
| **P0-2** | 2 min | 2 entity 顶部加 `library;`（`user_profile_entity.dart:1` + `report_history_entity.dart:1`） |
| **P0-3** | 1 hour | 7 表 `timestamp` 全部加 index（含 migration v13） |
| **P0-4** | 5 min | `dart fix --apply && dart format .` 一键清 50+ info |
| **P1-1** | 1 hour | coverage 集成：`flutter test --coverage` + `lcov` + CI fail 阈值 ≥ 70% |
| **P1-2** | 30 min | 4 个 TODO 加 `@author @date` 注释 |
| **P1-3** | 10 min | 4 个 `.dart` 去 BOM |

**总计**：3-4 小时 P0+P1 全部可清。完成后项目从 4.5/5 升到 4.8/5，逼近阿里 Java 规约的"满分"标准。
