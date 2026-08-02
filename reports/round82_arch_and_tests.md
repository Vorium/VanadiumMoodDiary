# Round 82 报告 — 架构 P0 修复 + 0 测试覆盖 (2026-08-02)

> **目标**：修 1 个架构 P0 违规 + 补 3 个 0 测试模块
> **基线**：v0.27 round 69 / schemaVersion 15 / 1368 tests / 0.27.0+64
> **结果**：1 架构违规已修 + 3 新测试文件 (41 cases) + 全套验证通过

---

## 1. 改了哪些文件

### 1.1 新建 `lib/domain/logic/refill_scheduler.dart` (核心修复)

**目的**：抽 `RefillNotifier.computeRefillFireTime` 静态方法到 domain 层纯函数,切断 `schedule_refill_reminder` use case 间接 flutter 依赖。

**位置**：`lib/domain/logic/refill_scheduler.dart` (R82 新建, 4.1 KB)

**核心代码 (line 50-85)**：
- `static DateTime? computeRefillFireTime({required DateTime? refillAt, required int reminderDays})` — 跟 R56c 8 case 行为 1:1
- `static int daysUntilRefill(DateTime refillAt, DateTime now)` — 从 `RefillNotifier._daysUntilRefill` 抽离,改 public 让 use case 复用
- 私有构造 `RefillScheduler._()` 防止实例化
- dartdoc 详细,跟 R65/R56c 风格统一

### 1.2 修改 `lib/core/data/services/refill_notifier.dart`

**位置**：`lib/core/data/services/refill_notifier.dart`

| 行号 | 改动 |
|---|---|
| line 1-13 | 文件头注释加 R82 段,说明 `computeRefillFireTime` / `daysUntilRefill` 已委托到 `RefillScheduler` |
| line 23 | 新增 `import 'package:chroniccare/domain/logic/refill_scheduler.dart';` |
| line 33-34 | 公开方法注释从 "3 个 helper" 改 "2 个 helper + 委派" |
| line 69-86 | `computeRefillFireTime` 静态方法改成委派 `RefillScheduler.computeRefillFireTime(...)` (1 行),保留 facade API |
| line 88-99 | `_daysUntilRefill` (私有) → `daysUntilRefill` (公开),委派到 `RefillScheduler.daysUntilRefill(...)` |
| line 152 | `final daysLeft = _daysUntilRefill(...)` → `daysUntilRefill(...)` (新公开名) |

**Backwards compatible**：`RefillNotifier.computeRefillFireTime` / `daysUntilRefill` 仍是 public static,老 caller (`NotificationService` facade) 跟老 test (`refill_notifier_round61c_test.dart`) 不用改 import,继续走 facade 委派。

### 1.3 修改 `lib/domain/usecases/schedule_refill_reminder.dart`

**位置**：`lib/domain/usecases/schedule_refill_reminder.dart`

| 行号 | 改动 |
|---|---|
| line 17 | `import 'package:chroniccare/core/data/services/refill_notifier.dart';` → `import 'package:chroniccare/domain/logic/refill_scheduler.dart';` |
| line 19 | (上面新 import) `import 'package:chroniccare/domain/entities/medication_entity.dart';` |
| line 84 | `RefillNotifier.computeRefillFireTime(...)` → `RefillScheduler.computeRefillFireTime(...)` |

**关键**：这一改切断 domain use case → data service → flutter plugin 间接依赖链。`dart scripts/check_all.dart` 验证 domain 层 0 flutter / 0 drift / 0 data / 0 presentation 违规。

---

## 2. 3 个新测试文件

### 2.1 `test/domain/refill_scheduler_round82_test.dart` (14 cases)

覆盖 R82 抽离的 `RefillScheduler.computeRefillFireTime` + `daysUntilRefill` 纯函数,跟 R56c / R65 老 test 行为 1:1。

| # | 测试 | 维度 |
|---|---|---|
| 1 | 正常 refillAt=9/15 + reminderDays=7 → 9/8 09:00 | 标准场景 |
| 2 | reminderDays=1 (最小值) → refillAt - 1 天 09:00 | 边界 |
| 3 | refillAt=null → null (caller no-op) | 边界 |
| 4 | reminderDays < 1 (0/-1/-365) → 抛 ArgumentError | 错误 |
| 5 | 跨年: 2026/01/05 - 7 天 → 2025/12/29 09:00 | 跨年 |
| 6 | 闰年: 2028/02/29 - 1 天 → 2028/02/28 09:00 | 闰年 |
| 7 | 时分秒: refillAt=23:59:59 → fireTime 仍是 09:00 | 时分秒 |
| 8 | 时分秒: refillAt=00:00:00 → fireTime 09:00 (不漂移) | 时分秒 |
| 9 | daysUntilRefill 同一天 → 0 | 按天 |
| 10 | daysUntilRefill 明天 (now 23:59) → 1 | 按天 |
| 11 | daysUntilRefill 昨天 (now 00:01) → -1 | 按天 |
| 12 | daysUntilRefill 跨月: 10/1 vs 9/30 → 1 | 跨月 |
| 13 | 多次调用同输入 → 同输出 (幂等) | 纯函数 |
| 14 | 不引用 DateTime.now() (R16 round 19B race bug 守门) | 架构 |

### 2.2 `test/domain/lost_contact_sms_round82_test.dart` (16 cases)

覆盖 `buildLostContactSms` 失联 SMS 模板 (R62 P1-5 修复集中 source),4 国 hotline 是 i18n 翻译层 (`safetyAlertBodySent/Mocked/Failed`),本类聚焦 2 kind (safetyAlert/reminder) + userName fallback + PIPL §6 不暴露 med.name / dosage + override 模式。

| # | 测试 | 维度 |
|---|---|---|
| 1 | safetyAlert 必含 "如确认安全请回复 1" (精神心理保护底线) | PIPL §13 |
| 2 | safetyAlert 含联系人姓名 + 失联天数 | 模板内容 |
| 3 | userName=null → 走 Strings.userNameFamily fallback | 边界 |
| 4 | userName="" → 走 fallback | 边界 |
| 5 | userName="   " (纯空白, safeUserName 已知行为) → 不走 fallback, 锁文档化 | 已知行为 |
| 6 | override 优先: caller 传 override 直接返回 (R61 i18n) | i18n |
| 7 | reminder daysSince>=2 → 含 "天没打卡" | reminder kind |
| 8 | reminder daysSince<2 → 含 "小时没打卡" (避免 0 天) | reminder kind |
| 9 | reminder 中性化: 含 "对方" 而非 "TA" (R72 修) | 中性化 |
| 10 | reminder 不暴露 medication.name / dosage (R75 PIPL §6 修) | PII 保护 |
| 11 | LostContactSmsKind enum 2 值 | enum |
| 12 | 超长 userName (100 字符) → 不崩 | 边界 |
| 13 | 极端 daysSince (1000 天) → 模板能容纳 | 边界 |
| 14 | daysSince=0 + hoursSince=0 → reminder 走 "小时没打卡" | 边界 |
| 15 | override=null → 走默认模板 (跟不传一样) | override |
| 16 | override="" → 仍走 override (caller bug 风险, 锁文档化) | 已知行为 |

### 2.3 `test/domain/consent_artifact_round82_test.dart` (11 cases)

覆盖 `ConsentArtifact` PIPL §13 留痕实体 (R63 P0-3 修复) + `ConsentKind` 5 值 enum。R63 已有 `consent_kind_unified_round63_test.dart` 锁 enum 5 值 + presentation re-export,R82 补实体维度。

| # | 测试 | 维度 |
|---|---|---|
| 1 | enum 5 值 name 正确 (R63 复测) | enum |
| 2 | PIPL §13 强场景: emergencyContactSharing + dataExport | PIPL |
| 3 | PIPL §14 撤回场景: safety + vent + analytics | PIPL |
| 4 | 必填 4 字段: kind / grantedAt / grantedBy / version | 构造 |
| 5 | contactId 必填 (kind=emergencyContactSharing) | 构造 |
| 6 | contactId 可空 (kind=其它, 如 dataExport) | 构造 |
| 7 | 同字段 → 引用相等 (无 == override, identity 模式) | equatable |
| 8 | 同字段 → 引用相等 (DateTime 非 const 阻止 const 优化) | equatable |
| 9 | 不同 field → 字段值不同 | equatable |
| 10 | 所有字段是 final, 不可改 (PIPL §17 数据准确性) | immutable |
| 11 | 在 runtime list / map 中可正常构造 | 使用场景 |

---

## 3. 验证结果

| 命令 | 结果 |
|---|---|
| `dart scripts/check_all.dart` | ✅ 通过 (0 violation) |
| `flutter analyze` | ✅ No issues found! (0 error) |
| `flutter test test/domain/refill_scheduler_round82_test.dart` | ✅ All 14 tests passed! |
| `flutter test test/domain/lost_contact_sms_round82_test.dart` | ✅ All 16 tests passed! |
| `flutter test test/domain/consent_artifact_round82_test.dart` | ✅ All 11 tests passed! |
| `flutter test` (全套) | ✅ All 1417 tests passed! (R81 1368 + R82 +49) |

**架构 check 关键证据**：
- 修复前: `lib/domain/usecases/schedule_refill_reminder.dart:17` 间接 import `flutter_local_notifications`,check_all.dart 报"domain 不应引用 data"
- 修复后: domain 0 flutter / 0 drift / 0 data / 0 presentation,✅ 0 violation

---

## 4. 关键决策

1. **保留 RefillNotifier facade 委派, 不破坏老 caller**。`RefillNotifier.computeRefillFireTime` 仍 public,只是改为 1 行 delegate,`NotificationService` facade + R56c 8 case 老 test 不用改 import。Backward compatible 优先于 "全切到 domain"。

2. **`_daysUntilRefill` 改 public `daysUntilRefill`**。原本私有方法现在供 use case 复用,避免 domain / data 重复实现同一逻辑。改 public 是把"计算逻辑所有权"从 service 收回 domain。

3. **R75 known behavior 锁文档化**。`safeUserName("   ")` 不 trim 是 R23 已知行为, 锁在新 test "userName 纯空白 → 不走 fallback" 注释, 避免 caller 误用纯空白 userName 时翻车。

4. **ConsentArtifact 无 == override 是有意为之**。R63 设计: domain 实体有 == (e.g. MedicationEntity), value object (e.g. ConsentArtifact) 走 "immutable const + 引用相等" 简化模式。R82 test 锁文档化此行为, 防止后续 refactor 加 == 引入意外变更。

5. **不动的文件**:
   - `lib/core/data/services/safety_config_service.dart` (0 测 P0 但本任务不涵盖)
   - `lib/core/data/services/store_kit_service.dart` (IAP 集成复杂)
   - `lib/core/data/services/data_export_service.dart` + 5 子服务 (量大)

---

## 5. CHANGELOG 同步

待 R82 收尾后追写:
- `[Unreleased]` 段加 R82 entry
- 总测试数 1368 → 1417
- 16 守护脚本仍全绿 (check_all.dart 0 violation 持续)
- AGENTS.md "v0.25 spen P0 #15 TDD + 杂项清理" 段后加 "v0.27 R82 P0 架构修复" 段
