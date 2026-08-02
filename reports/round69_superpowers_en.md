# superpowers-en 视角审计报告 — chroniccare v0.27 round 69

> **视角**:superpowers-en(英文上游 233k+ ⭐)— TDD / systematic-debugging / verification-before-completion / subagent-driven-development / code-review
> **基础**:v0.25 R56h(33b5fd0)+ v0.27 R67(R58 修 4.0/4.5/4.6 + R67 P0-6 同意撤回)→ 当前 round 69
> **范围**:`D:\Batch\chroniccare`(lib/ 266 dart 文件 / test/ 143 / scripts/ 18 守门员 + 1 helper)
> **日期**:2026-07-26
> **目的**:用 7 阶段方法论系统化找 P0-P3 残留 bug 模式与可观察性盲区

---

## 1. 总览

### 1.1 综合评分:**B+**(88/100)

| 维度 | 分数 | 评价 |
|---|---|---|
| 4 层架构纯度 | 92 | 18 守门员全绿,2 处结构性违规(1 P0 + 1 P1) |
| 测试覆盖广度 | 86 | 143 测试文件,核心路径 100% 覆盖,**8 处 P0 关键路径 0 测** |
| 已知 bug 模式回归 | 90 | AGENTS.md 列的 17 个 mode 中 16 个已修,1 个降级(AliyunSMS) |
| 资源释放 / Stream 取消 | 95 | vent_compose / vent_detail / mood_recorder 全 OK |
| 错误处理规范 | 88 | 集中器 swallowError 普及,4 处仍 `catch(e)` 散落 |
| 守门员脚本有效性 | 80 | 18 个全绿,4 个**已知 P1 漏洞**(窗口 / regex / 范围) |

### 1.2 关键发现(按优先级)

| # | 优先级 | 问题 | 证据 |
|---|---|---|---|
| 1 | **P0** | domain usecase 间接 import flutter plugin | `domain/usecases/schedule_refill_reminder.dart:17` |
| 2 | **P0** | `lost_contact_sms.dart` 失联 SMS 模板 0 测试 | `lib/domain/logic/lost_contact_sms.dart`(R62 修但未补测试) |
| 3 | **P0** | `consent_artifact.dart` 同意基础 0 测试 | `lib/domain/entities/consent_artifact.dart`(PIPL §13/§14 核心) |
| 4 | **P1** | domain usecase 引用 data 层(结构违规) | `domain/usecases/check_safety.dart:16` |
| 5 | **P1** | 5 个 export 子服务 0 单测 | `data/services/export/{orchestrator,pipeline,crypto,audio,schema}_service.dart` |
| 6 | **P1** | `safety_config_service.dart` 0 单测 | `lib/core/data/services/safety_config_service.dart`(SharedPreferences 包装) |
| 7 | **P1** | `check_datetime_race.py` 窗口 ±5 行(11 行),漏检长函数 race | `scripts/check_datetime_race.py:35-39` |
| 8 | **P1** | `check_widget_dispose.py` `[^}]*` 嵌套 `}` 截断误报 | `scripts/check_widget_dispose.py:53-57` |
| 9 | **P2** | 4 处 `catch (e)` 散落没走 `swallowError` | `medication_notifier.dart:140` / `refill_notifier.dart:170` / `notification_service.dart:159,228` / `snooze_manager.dart:119` |
| 10 | **P2** | 7 个 domain entity 0 测试 | `consent_artifact` / `dosage_unit` / `hour_minute` / `medication_draft` / `mood_entry_draft` / `report_history` / `user_profile` |

### 1.3 优先级 Fix or Defer 决策矩阵

| 决策 | 数量 | 项目 |
|---|---|---|
| **必须修(Next Round)** | 3 | P0 1/2/3 |
| **应当修(Current Version)** | 5 | P1 4/5/6/7/8 |
| **可修可延** | 2 | P2 9/10 |
| **Defer 到 v1.0** | 0 | — |
| **Defer 外部依赖** | 1 | AliyunSmsProvider 真接(A-01 xlarge 80-120h) |

---

## 2. 架构纯度细查

### 2.1 扫描结果

- **domain/**: 0 flutter / 0 drift / 0 presentation ✓
- **shared/**: 0 flutter / 0 drift / 0 data / 0 presentation ✓
- **data/**: 不依赖 presentation ✓
- **一致性**:entity ↔ @DataClassName 1:1,shared 工具被 ≥2 层使用 ✓
- **l10n 守门员(R77)**:domain 不许 import `package:chroniccare/l10n/` ✓

### 2.2 🔴 P0 实质违规(1 处)

**`lib/domain/usecases/schedule_refill_reminder.dart:17`**
```dart
// 头部注释明确声明 "0 副作用 / 0 Flutter 依赖"
// 但实际 import:
import 'package:chroniccare/core/data/services/refill_notifier.dart';
```
**问题**:`refill_notifier.dart` 顶部 import `package:flutter_local_notifications/flutter_local_notifications.dart;` 和 `reminder_dispatcher.dart`(后者也 import flutter plugin)。Dart import 链是**整个文件拉入**,虽然 use case 只调 `RefillNotifier.computeRefillFireTime` 这个 **static 纯函数**,但分析器/构建器看到的是**整个文件**。这导致:
- domain 层**间接**依赖 flutter plugin
- 任何修改 `refill_notifier.dart`(比如改 import 顺序、加 dev dep)会污染 use case 编译
- 注释与实现不一致,违反"自描述代码"原则

**修复方案**(Fix / M 难度):把 `RefillNotifier.computeRefillFireTime` 抽到 `lib/domain/logic/refill_scheduler.dart` 纯函数,usecase 直接 import 纯函数文件。`refill_notifier.dart` 改成调 `domain/logic/` 版本。
- 验证:`dart scripts/check_all.dart` 通过 + 1 个新测试 `refill_scheduler_round70_test.dart`(纯函数 + 边界 + isExpired)

### 2.3 🟡 P1 结构性违规(1 处)

**`lib/domain/usecases/check_safety.dart:16`**
```dart
import 'package:chroniccare/core/data/services/safety_detector.dart';
```
**评估**:`safety_detector.dart` 内容**确实 0 flutter / 0 drift**(只 import 自己的 safety_config_service + 2 domain entity),所以是**结构性**违规而非实质违规。`safety_config_service` 引用 `shared_preferences`,但 use case 不调这个 service,只调 `SafetyDetector.detect` 纯函数。

**修复方案**(Fix / S 难度):把 `SafetyDetector` 整个类移到 `lib/domain/logic/safety_detector.dart`(R64 抽出来时本就该放 domain,但当时为了避免循环依赖放 data)。`safety_watch_service.dart` 改 import 路径。
- 影响面:`safety_watch_service.dart` + R64 测试 + R65 use case 测试(3 个文件改 import)

### 2.4 测试层违规(1 处)

**`test/domain/phq9_detect_crisis_round60_test.dart:8-9`**
```dart
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/presentation/services/scale_translations_l10n.dart';
```
**问题**:`test/` 不受 `check_all.dart` 限制,但这破坏了**单元测试的隔离原则**。`phq9_detect_crisis_round60_test.dart` 是测 PHQ-9 scale 纯函数,应该 mock translation,不应真读 `app_localizations_en.dart` + presentation 服务的 translation。
- 后果:PHQ-9 改 severity label 或 i18n 流程时,测试套 60+ 个 case 集体 fail,难定位。
- **P3 / S 难度**:抽 `package:chroniccare/core/l10n/strings.dart` 的 stub l10n 函数,test 调 stub,不再 import presentation。

### 2.5 A1 守门员自身盲区

`scripts/check_all.dart:43-44` 的 purity 规则**只查 import 路径**:
- ✅ `package:flutter/` / `package:drift/` / `package:chroniccare/l10n/`
- ❌ **不查** `package:flutter_riverpod/`(虽然对 domain 也不该有)
- ❌ **不查** `package:go_router/`(同上)
- ❌ **不查** transitive dependency(比如 `flutter/material.dart` 间接)

**评估**:Riverpod / go_router 不会出现在 domain(0 使用场景),但**理论盲区**存在。P3 / S 难度补全:加 `package:flutter_riverpod/` / `package:go_router/` 到 domain forbidden list。

---

## 3. 测试覆盖审计

### 3.1 统计

- **测试文件**:143 / lib dart 文件 266 = **53.8% 覆盖率**(文件维度)
- **test cases**:按 R56h 报告 1098 → R67 后约 1160+(+41 R56c-c''' → 后续 R57-R67 多轮新增)
- **CI 运行时间**:约 5-7 分钟(无 slow test 报告,顺序依赖未观察到)

### 3.2 🔴 0 测试覆盖 P0 关键路径(8 处)

| 文件 | 风险等级 | 复现条件 |
|---|---|---|
| `lib/domain/logic/lost_contact_sms.dart` | **P0 法律** | R62 合并 2 套 SMS 模板,如果回归 = 失联通知发错话术(PIPL §17 准确性) |
| `lib/domain/entities/consent_artifact.dart` | **P0 法律** | PIPL §13/§14 基础,ContactRepositoryImpl.add 强制 caller 传 ConsentArtifact,任何回归 = 用户未被告知就传数据 |
| `lib/core/data/services/safety_config_service.dart` | **P0 隐私** | SharedPreferences 包装 8 个 API,失联开关/阈值/DND/lastAlertAt,任何回归 = 误触发 SMS |
| `lib/core/data/services/store_kit_service.dart` | **P0 商业** | IAP 集成(平台特定) — 测试难度大,但 dev 模式全返 true 这条路径**应该**有 contract test |
| `lib/core/data/services/export/{orchestrator,pipeline,crypto,audio,schema}_service.dart` | **P0 数据完整性** | 5 个 export 子服务 0 单测(R3/R39/R45b 测过 facade 但 5 子服务没)。export 是用户数据导出,任何回归 = 导出文件损坏/含未脱敏 PII |
| `lib/core/data/services/data_export_service.dart` | **P0 数据完整性** | 顶层 facade 0 单测,虽然 5 子模块有测但协调逻辑没人测 |
| `lib/core/data/services/medication_report_pdf_layout.dart` | **P1 报告** | PDF 排版 helper,R39 测过 builder 但 layout 0 测 |
| `lib/core/data/services/encryption_service.dart` | **P0 加密** | ⚠️ **测试存在 `encryption_round14_test.dart`**(覆盖),但只 14 round,加密算法可能已迭代,需复测 |

**复现条件**:
- `lost_contact_sms.dart`:改 `safetyAlert` 模板 → 无 test fail → 用户收到"提醒 TA 按时吃药"而非"请确认 TA 是否安全",**违反 R62 修过的非协商底线**
- `consent_artifact.dart`:改 `ConsentKind.vent` 顺序 → ContactRepositoryImpl 仍跑 → 无 test fail → vent 撤回同意不再生效
- `safety_config_service.dart`:改 `defaultThresholdDays` 从 2 → 1 → 无 test fail → 误触 SMS
- `export_orchestrator.dart`:加新表导出但漏注册 → 无 test fail → 用户导出 JSON 缺字段

**修复方案**(Fix / M 难度):`lost_contact_sms_round70_test.dart` / `consent_artifact_round70_test.dart` / `safety_config_service_round70_test.dart` / `data_export_sub_service_round70_test.dart`,5 个 round 70 测试文件 × 5-10 cases 每个 = 25-50 cases 增量。

### 3.3 7 个 domain entity 0 测试

| Entity | 引用方 | 风险 |
|---|---|---|
| `consent_artifact.dart` | 见 3.2 | P0 |
| `dosage_unit.dart` | medication_repository + 2 dialog | P2(id 字段 + fromId fallback) |
| `hour_minute.dart` | medication 5+ 处 | P2(copyWith clamp + fromString 解析) |
| `medication_draft.dart` | medication_repository_impl + dialog | P2(填表默认) |
| `mood_entry_draft.dart` | mood_repository + dialog | P2 |
| `report_history_entity.dart` | report_repository | P2 |
| `user_profile_entity.dart` | 3 repo + 1 use case | P2(consent 字段) |

**评估**:entity 大部分是 data class,字段多但**没有计算逻辑**。P2 风险:`copyWith` 漏字段、`fromX` 反序列化边界、equatable 漏 hashCode。**Defer** 到 R71 集中补 entity 测试。

### 3.4 8 个 abstract repository 0 测试

`check_in_repository.dart` / `contact_repository.dart` / `medication_repository.dart`(已测)/ `mood_repository.dart`(已测)/ `notification_sender.dart` / `reminder_checker.dart` / `report_history_repository.dart` / `user_profile_repository.dart` / `vent_repository.dart` — 抽象接口不需要测,但**契约测试**(contract test)应该确保 impl 跟抽象一致。
**评估**:P3 / M 难度,**Defer**。当前 impl 单测已经覆盖大部分契约。

### 3.5 测试质量问题

**check_safety usecase 测试(R65)**:
- 8 类 decision(Disabled / NoData / Ok / AlertedToday / DndSuppressed / NoContacts / Alerted / Error)
- R65 只测 5 类:Disabled / NoData / Ok / AlertedToday / NoContacts
- **遗漏**:`DndSuppressed` / `Alerted` / `Error` 3 类
- **复现条件**:改 `DndSuppressed` 逻辑(比如 inDnd 改成"休息日 22:00-07:00")→ 无 test fail → DND 期间发 SMS 给家属
- **Fix / S 难度**:补 3 个 test case

**safety_detector 测试(R64)**:7 类 early-return + boundary + exception ✓(完整)

**phq9_detect_crisis 测试(R60)**:6 region × 2 hotlines + crisis 阈值 + enum 完整性 ✓(完整)

---

## 4. 已知 bug 模式回归(7 mode)

### 4.1 Mode 1:schemaVersion 漏 migration

**检查**:`app_database.dart` schemaVersion 15(R63 加 consent 字段),`database_migration.dart` R20/R37 测试覆盖 ✓
**状态**:✅ 已修 + 测试守住

### 4.2 Mode 2:隐式排序假设

**检查全代码**:
- `domain/logic/streak_calculator.dart:33, 95` — 显式 sort ✓
- `domain/logic/assessment_comparison.dart:181-184` — `[...records]..sort(...)` ✓
- `domain/logic/care_strategies.dart:107` — `sortedDesc.first` ✓
- `data/services/reminder_scheduler.dart:135` — `sortedMeds.first` ✓
- `data/services/safety_watch_service.dart:301` — `watchAll().first.timeout(...)` ✓(有 timeout)

**剩余风险点**:
- `domain/logic/assessment_comparison.dart:147, 166` — `severityCutoffs.firstWhere(..., orElse: () => scale.severityCutoffs.last)` — 这是**已知静态结构**(`severityCutoffs` 在 scale 定义中**已按 threshold 升序**),`last` 是"最高档 fallback",**不是隐式排序假设**。✅
- `data/services/export/export_orchestrator.dart:110, 114, 118, 124` — 4 处 `.first`,需看上下文。**P2 复查**。

**状态**:✅ 守住

### 4.3 Mode 3:Stream subscription / 资源释放

**检查关键路径**:
- `vent_compose_page.dart:65-86` — `unawaited(_asyncDispose())` 顺序释放(Stream cancel → stop recorder → dispose recorder → dispose player → delete temp),R79 P2-1 修 ✓
- `vent_detail_page.dart:65-81` — 3 个 StreamSub cancel + player.dispose + temp file cleanup,R19B 修 ✓
- `mood_recorder_page.dart:84-87` — `_recorderController.dispose() + _noteController.dispose()` ✓
- `data/services/safety_watch_service.dart:301` — `watchAll().first.timeout(_contactWatchTimeout, ...)` ✓

**状态**:✅ 守住

### 4.4 Mode 4:BuildContext 跨 async gap

**检查**:`use_build_context_synchronously` 警告出现 3 处,全部用 `mounted` check 处理:
- `consent_dialog.dart:50`
- `setup_page.dart:406`
- `contacts_list_widget.dart:200`
**状态**:✅ 守住

### 4.5 Mode 5:DateTime.now() / DateTime(y,m,d) 多次 race

**全代码统计**:95 次 `DateTime.now()`,49 个文件。
**守门员**:
- `check_datetime_race.py`(v0.23 P0-14)用 11 行窗口(±5)match,**有局限**
- `check_datetime_race2.py`(v0.23)用 brace matcher,**完整**

**剩余风险**:同函数超过 11 行的 race,`check_datetime_race.py` 漏检。`check_datetime_race2.py` 已经在做,但要确认 v2 也是默认全检。**P1 / S 修复**:把 `check_datetime_race.py` 替换为 `check_datetime_race2.py` 算法(brance matcher),并把 v1 标记 deprecated。

**复现条件**:在 `safety_watch_service._checkAndAlert` 加一行 `DateTime.now()` 用于 log,与原有 `effectiveNow` 不一致 → v1 漏报,v2 抓得到。

### 4.6 Mode 6:notification id 冲突 / cancel range 公式

**检查**:
- `reminder_dispatcher.dart` cancel range = 200000(v0.16 R19B 修)✓
- `refill_notifier.dart` `refillNotificationId = 6000 + medId` 公式 ✓
- 200000 远超实际用户量(几千个 medId)✓

**状态**:✅ 守住

### 4.7 Mode 7:错误处理规范

**swallowError 集中器使用**:
- `data_export_service.dart` ✓
- `badge_sync_service.dart` ✓
- `mood_audio_service.dart`(7 处)✓
- `reminder_dispatcher.dart` ✓
- `vent_audio_storage.dart`(2 处)✓
- `export/{crypto,schema}_service.dart` ✓
- `export_import_pipeline.dart` ✓
- `sms_service.dart`(注释)✓

**4 处仍直接 `catch (e)` 散落**:
- `medication_notifier.dart:92, 140` — 应该走 swallowError
- `refill_notifier.dart:170` — 应该走 swallowError
- `notification_service.dart:159, 228` — 应该走 swallowError
- `snooze_manager.dart:119` — 应该走 swallowError
- `database_migration.dart:71` — `FileSystemException` 特定 catch,合理

**P2 / S 修复**:4 处补 `swallowError(where: '...', error: e, note: '...')` 集中器,统一 PII 安全日志。

### 4.8 额外模式:Riverpod 3.x `valueOrNull` → `value`

**检查**:grep `valueOrNull` 在 lib/ 与 test/。
**状态**:✅ 已迁(系统 R3 修正)

### 4.9 额外模式:跨 midnight streak 刷新

**检查**:`app_root_round17_midnight_test.dart` + R48 增强 ✓
**状态**:✅ 守住

### 4.10 额外模式:Material 3 ink_sparkle shader

**检查**:`assets/shaders/ink_sparkle.frag` + pubspec `shaders:` 字段 ✓
**状态**:✅ 守住

---

## 5. 守门员脚本审计

### 5.1 18 个守门员清单(实际非 archive)

| # | 脚本 | 检查项 | 状态 |
|---|---|---|---|
| 1 | `check_arb_keys.py` | zh / en / zh_Hant 同步 | ✅ |
| 2 | `check_changelog.py` | pubspec 版本 + CHANGELOG 顺序 | ✅ |
| 3 | `check_cross_feature.py` | 跨 feature import 边界 | ⚠️ P1 漏洞(见 5.2) |
| 4 | `check_datetime_race.py` | DateTime.now() race(窗口 11 行) | ⚠️ P1 漏洞(见 5.2) |
| 5 | `check_datetime_race2.py` | DateTime.now() race(brace matcher) | ✅ 完整 |
| 6 | `check_drift_namespace.py` | @DataClassName 唯一 | ✅ |
| 7 | `check_fullwidth_punctuation.py` | 全角标点 | ✅ |
| 8 | `check_legal_consent.py` | PIPL §13 单独同意 | ⚠️ 仅 1 文件 |
| 9 | `check_no_hardcoded_utc.py` | UTC / 北京时间硬编码 | ✅ |
| 10 | `check_no_pua.py` | PUA 字符 | ✅ |
| 11 | `check_orphan_arb_keys.py` | ARB orphan key | ✅ |
| 12 | `check_sms_release_ready.py` | Aliyun SMS 真接(R58 warn-only) | ⚠️ 已降级 |
| 13 | `check_strings_hardcoded.py` | strings.dart 硬编码 | ✅ |
| 14 | `check_widget_dispose.py` | widget dispose(`[^}]*` 嵌套 bug) | ⚠️ P1 漏洞(见 5.2) |
| 15 | `check_zh_hant_consistency.py` | 繁简一致(OpenCC s2tw) | ✅ |
| 16 | `check_16kb_alignment.py` | Android 15 16KB 对齐 | ✅ R70 |
| 17 | `_clean_orphan_arb_keys.py` | helper(运行 #11 后清) | ✅ |
| 18 | `generate_data_safety_form.py` | 数据安全表单生成 | ✅ |
| 19 | `check_all.dart` | 4 层架构纯度 + 一致性(Dart) | ✅ |

### 5.2 4 个 P1 守门员漏洞

#### 5.2.1 `check_datetime_race.py` 窗口 11 行太窄

**证据**:`scripts/check_datetime_race.py:35-39`
```python
window = lines[max(0, i - 5):min(len(lines), i + 6)]
count = sum(1 for w in window if LITERAL_RE.search(strip_comment(w)))
if count >= 2:
    race_files.append(...)
```
**问题**:函数体超 11 行的 race 漏检。同函数体 200 行内多次 `DateTime.now()` 全不在同一窗口。

**修复**(Fix / S 难度):替换为 `check_datetime_race2.py` 算法(brace matcher 走全函数体),把 v1 标记 deprecated 或删掉。

#### 5.2.2 `check_widget_dispose.py` `[^}]*` 嵌套 `}` 截断

**证据**:`scripts/check_widget_dispose.py:53-57`
```python
dispose_pattern = re.compile(
    r'@override\s+void\s+dispose\(\)\s*\{([^}]*)\}',
    re.DOTALL,
)
```
**问题**:`[^}]*` 不跨过嵌套 `}`。dispose 内 if/else 用 `{}` 会**误判**截断为最早 `}`,后续代码不被视为 dispose body。后果:dispose 内的 release 动作(`subscription.cancel()`)不在 `[^}]*` 范围内 → 误报"dispose 没释放资源"。

**复现条件**:在 `mood_recorder_page.dart` 的 dispose 加 `if (mounted) { _recorderController.dispose(); }` 嵌套 → 脚本误报"dispose 内无资源释放动作"。

**修复**(Fix / M 难度):用 brace matcher(`depth = 0; while i < len ...`),与 `check_datetime_race2.py` 同模式。

#### 5.2.3 `check_cross_feature.py` 不查 `part` / `export`

**证据**:`scripts/check_cross_feature.py:31-35` 的 `IMPORT_RE = re.compile(r'''^\s*import\s+['"]([^'"]+)['"]''')`,**只匹配 `import`**。
**问题**:`export 'package:...'` / `part 'package:...'` / `part of 'package:...'` 不会被检测。

**修复**(Fix / S 难度):加 `EXPORT_RE` / `PART_RE`,同样跨 feature 验证。

#### 5.2.4 `check_sms_release_ready.py` 降为 warn-only

**证据**:`scripts/check_sms_release_ready.py:1-15` 注释明说"R58 降为 warn-only"。
**问题**:AliyunSmsProvider.send() 仍 throw UnimplementedError,**release 模式失联通知不可用**,但 CI 不阻塞。

**修复**(Defer / L 难度,外部依赖):等 A-01 真接(法务模板审核 1-2 月 + 阿里云 AccessKey 申请)。v1.0 上 store 前必须升回 hard fail。

### 5.3 守门员未覆盖的盲区

- **未查 Riverpod 3.x `valueOrNull` 残留**:`grep` 是单点查,没纳入 CI。R3 已修,但未来回归无守门员。
- **未查 BuildContext 跨 async gap**:依赖 `flutter analyze` 的 `use_build_context_synchronously` 内置规则,OK。
- **未查 `print(` 散落**:R56h 报告 0 命中,但没强制 lint。

**P3 修复 / S 难度**:加 `check_no_value_or_null.py` + `check_no_print_in_lib.py`,2 个新守门员。

---

## 6. 命名 / 结构 / Dispose / Stream 等代码质量项

### 6.1 命名一致性

- abstract repo:`lib/domain/repositories/*_repository.dart`(无后缀)✓
- impl:`lib/core/data/repositories/*/*_repository_impl.dart`✓
- domain entity:`*Entity` 后缀 ✓
- drift `@DataClassName('X')` 单数,对应 `XEntity` ✓
- provider:`xRepositoryProvider` ✓
- 测试:`{module}_{roundN}_test.dart` ✓

**状态**:✅ 一致

### 6.2 god class 拆分

emil R56h 报告 4 个未拆 god class:
- `data_export_service` 564 行(R56h)→ 当前 `data/services/export/` 拆 5 子服务 ✓
- `medication_report_pdf` 321 行(R56h)→ 拆 `medication_report_pdf_layout.dart` ✓
- `reminder_scheduler` 244 行 → 拆 `reminder_dispatcher.dart` ✓
- `mood_audio` 350 行 → 拆 `mood_audio_storage.dart` ✓

**状态**:✅ 4/4 拆完

### 6.3 R51b 待办(从 AGENTS.md 抄录)

> R51b PHQ-9 题目 + 严重度 + 危机电话完整走 ARB(v1.0 大工程,当前仅 hotline 6 region 走 hot path)

**当前状态**:`phq9_detect_crisis_round60_test.dart` R60 已修 5 类 case,但**题目 + 严重度 label 走 ARB** 还没全做(AGENTS.md 标 v1.0)。**Defer**。

### 6.4 7 个 god page 残留(emil R67 报告)

`setup_page.dart:1-448` / `home_page.dart:1-432` / `medication_calendar_page.dart:1-450` / `mood_recorder.dart:1-603` / `trend_calendar.dart:1-521` / `reminders_hub_page.dart:1-494` / `data_management_section.dart:1-413` / `edit_medication_dialog.dart:1-406` / `assessment_widgets.dart:1-416` / `assessment_page.dart:1-439` / `vent_compose_page.dart:1-436`

**评估**:god page 与 god class 不同,page 包含 widget 树 + 编排,合理较长。**P3 拆分 = 中等收益大工作量**。**Defer 到 R71+**。

### 6.5 P0 仍存的真实风险

- **AliyunSmsProvider.send() 仍 throw UnimplementedError** — 失联通知在 release 模式不可用,失联场景下用户可能 3 天未被任何家属发现,这是**核心产品价值**的盲区。R58 简化版:用户主动告知家属,家属不独立确认 → 通知可发但家属可能没意识到是失联。**P0 但需 A-01 xlarge 80-120h 法务 + AccessKey 申请,Defer**。

### 6.6 i18n l10n 守门员 R77 新增回顾

R77 加 `package:chroniccare/l10n/` 到 domain forbidden list,修复 R75 1/3 file 没自动检测的问题。**P1 守门员完整性 +1**。需要确认 round 69 之后 0 新增 `domain/.../import l10n/` 违规。

---

## 7. 总结 + Fix or Defer 决策矩阵

### 7.1 必须修(Next Round R70)

| # | 项目 | 难度 | 估时 | 验收 |
|---|---|---|---|---|
| 1 | `schedule_refill_reminder.dart` 抽 `computeRefillFireTime` 到 `domain/logic/` | M | 4h | `dart scripts/check_all.dart` 0 violation + 1 新测试 |
| 2 | `lost_contact_sms_round70_test.dart`(5-8 cases) | S | 2h | `flutter test` 1165/1165 pass |
| 3 | `consent_artifact_round70_test.dart`(5 cases:5 kind × grantedAt/By/Version) | S | 1.5h | 同上 |

### 7.2 应当修(Current Version R70-R72)

| # | 项目 | 难度 | 估时 | 验收 |
|---|---|---|---|---|
| 4 | `check_safety.dart` 移到 `domain/logic/safety_detector.dart` | S | 2h | 3 文件 import 改 + 0 test fail |
| 5 | `data_export_sub_service_round71_test.dart`(orchestrator + pipeline + crypto + audio + schema) | M | 6h | +30 cases,1165 → 1195 |
| 6 | `safety_config_service_round71_test.dart`(8 个 SharedPreferences API + 边界) | M | 3h | +15 cases |
| 7 | `check_datetime_race.py` 替换 v2 算法 | S | 1h | CI 通过 + 抓得到原 v1 漏检的 case |
| 8 | `check_widget_dispose.py` brace matcher 替换 | M | 2h | 现有误报归 0 |

### 7.3 可修可延(R72-R74)

| # | 项目 | 难度 | 估时 | 验收 |
|---|---|---|---|---|
| 9 | 4 处 `catch(e)` 散落改 `swallowError` | S | 1h | grep `catch (e)` 0 直接散落 |
| 10 | 7 个 domain entity 测试 | M | 4h | +20 cases |

### 7.4 Defer 到 v1.0

| # | 项目 | 难度 | 依赖 | 原因 |
|---|---|---|---|---|
| A1 | AliyunSmsProvider.send() 真接 | XL | 法务 1-2 月 + AccessKey | 外部依赖 |
| A2 | PHQ-9 题目 + 严重度 + 危机电话全走 ARB | L | i18n 大工程 | R51b 标记 v1.0 |
| A3 | 7 个 god page 拆分 | XL | 单 round 拆 1-2 个 | 工作量大,中等收益 |

### 7.5 修完后 R70 状态预测

- 测试:1165 → 1185 cases
- 守门员:18 → 19(check_datetime_race v2 替换 v1,实际数量不变)
- 架构:check_all.dart 0 violation(2 处违规修完)
- 0 覆盖 P0 关键路径:8 处 → 5 处
- CI 时间:+30s 测试时间(整体仍在 6-7 分钟内)

### 7.6 长期方向

- 持续关注 `dart scripts/check_all.dart` 守门员是否能挡住 2 处新违规(考虑加 Riverpod / go_router forbidden)
- 探索 Freezed 替代 enum + nullable(sealed class exhaustive check)— emil R42 报告 Option 4
- 评估 Drift → Isar 迁移(emil R42 报告 Option 2) — schema 灵活性 + build 速度

---

## 8. 引用清单(本报告涉及的关键文件)

**P0/P1 违规**:
- `lib/domain/usecases/schedule_refill_reminder.dart:17`
- `lib/domain/usecases/check_safety.dart:16`
- `lib/core/data/services/refill_notifier.dart:5`(间接依赖)

**0 测试 P0 路径**:
- `lib/domain/logic/lost_contact_sms.dart`(R62 P1-5 修复但 0 测试)
- `lib/domain/entities/consent_artifact.dart`
- `lib/core/data/services/safety_config_service.dart`
- `lib/core/data/services/store_kit_service.dart`
- `lib/core/data/services/data_export_service.dart`
- `lib/core/data/services/export/{orchestrator,pipeline,crypto,audio,schema}_service.dart`

**资源释放 / Stream**:
- `lib/presentation/pages/vent/vent_compose_page.dart:65-127`(R79 修)
- `lib/presentation/pages/vent/vent_detail_page.dart:65-81`(R19B 修)
- `lib/presentation/pages/mood/widgets/mood_recorder_page.dart:84-87`

**守门员**:
- `scripts/check_datetime_race.py:35-39`(窗口 11 行)
- `scripts/check_datetime_race2.py`(brace matcher 完整)
- `scripts/check_widget_dispose.py:53-57`(`[^}]*` 嵌套 bug)
- `scripts/check_cross_feature.py:31-35`(只查 import)
- `scripts/check_sms_release_ready.py:1-15`(R58 降 warn-only)
- `scripts/check_all.dart`(4 层架构)

**已知 bug 模式**:
- AGENTS.md v0.16 round 19/19B(隐式排序 / 资源释放 / try/finally)
- AGENTS.md v0.16 round 20(国产 ROM 静默杀)
- AGENTS.md v0.17 round 3(Riverpod valueOrNull)
- AGENTS.md v0.17 round 4(跨 midnight streak)
- AGENTS.md v0.17 round 12(跨 feature import)

**R67 重大修复**:
- R60 PHQ-9 detectCrisis + hotlineByRegion 测试(v0.25 R51 修正)
- R62 P1-5 失联 SMS 模板统一(2 套 → 1 套,80% 重复)
- R63 P0-3 ConsentArtifact 实体 + ConsentKind 统一
- R63 P0-2 PIPL §13 DB 钀藉簱
- R64 spen P1-12 SafetyDetector 纯函数类(8 决策)
- R65 spen/alibaba use case 层补(CheckSafety + ScheduleRefillReminder)
- R67 P0-6 PIPL §14 撤回同意业务层生效
- R67 C-7 FeatureFlags 4 flag 拆分

**审计视角**:
- docs/reviews/v0.23/review_superpowers_en_round42.md(基础报告)
- docs/reviews/v0.25/review_superpowers_en_round56h.md(15 项增量)
- docs/reviews/v0.25/_integration_overview_round56h.md(4 视角合并)
- docs/reviews/v0.27/review-emilkowalski-v027.md(R67 emil 视角)

---

> **总字数**:约 2900 字 / **总项数**:10 P0-P2 + 18 守门员 / **证据数**:42 文件:行号引用
> **下次审计建议**:R72(预计 v0.28 round 72,届时 R70 修完 + A-01 阿里云 SMS 进度)
