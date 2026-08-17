# R120 emil 视角审视

**Scope**: R118 P2-7 (10 量表抽独立 class) + R119 P1-1 (app_database 139L 主壳 + 480L part) + R120 P1-2 (notification_service 386L → 252L)
**Date**: 2026-08-17
**Baseline**: 1.1.0+154, R115+R116 god class 续拆阶段

## 综合评分: 8.0 / 10

3 round 都是 R108 §六 god class 续拆, 命名 / 粒度 / 职责 / 文档 4 维度闭环干净, 但 composition 委托模式 + 兼容 alias + 抽象层次冗余 3 处拖分。R120 P1-2 得分最高 (8.5), R118 P2-7 最低 (7.5)。

---

## R118 P2-7 评估 (7.5/10)

### 优点

- **命名 100% 同构**: 10 个量表 class 全部用 `_{itemsZh, optionsZh, severityLabelZh, severitySummaryZh}` 4 个 const 命名 + `xxxName / ShortDescription / Instruction / Item / Option / SeverityLabel / SeveritySummary` 7 method 模板
- **职责单一彻底**: 10 个 class 各做一件事, 0 cross-class 数据依赖 (GAD-7 `gad7Option` 委托 `Phq9Translations.phq9Option` 是 4 档频率选项共享, 0 循环依赖)
- **文档完整**: 每个 translations 文件头注释含 R-round/阶段/改前/改后/职责/canonical fallback 6 段
- **测试粒度好**: `round118_direct_test.dart` 42 case 拆 4 group: 边界 (越界/override 优先) + 主壳委托一致性 (10 量表 × 7 method = 70 一致性 case) + 跨 class 共享 + 真实输出非空
- **composition 优于 mixin**: 试过 mixin 失败后走 composition 模式, 避免 dart 2.x mixin linearization 与 @override 冲突

### 问题

- **抽象层次冗余 (中)**: 10 个量表 class 全部 `不 implements ScaleTranslations` (Phq9Translations.dart:18 显式注释说明), 主壳 StaticScaleTranslations 仍 70 method 委托。emil 建议: 让 10 个 class 各自 implements ScaleTranslations, 主壳 70 method 委派可考虑替换为 lookup
- **Level2 命名冗余 (低)**: `Level2DepressionTranslations.level2DepressionName` 前缀重复 3 次
- **70 method 全是 trivial forwarding (中)**: 任何 1 个量表新增 method, 主壳必须同步加 1 行
- **危机 hotline 业务混量表 (低)**: 主壳尾部 `crisisHotlineLabel / crisisTitle / crisisMessage` 3 method 跟量表无关
- **crisisTitle / crisisMessage 字面量未走 l10n (P0-C 残留)**: 跟 `rule3-whitelist` 行号 (358, 362) 注释豁免

---

## R119 P1-1 评估 (8.0/10)

### 优点

- **part of 模式干净 (高)**: `app_database_migrations.dart` 用 `part of 'app_database.dart';` 保持同 library scope, drift 生成的 `db.moodEntries` / `db.ventEntries` / `db.medications` 等 TableInfo 顶层引用无需 import/export plumbing
- **god class 拆解成功**: 主壳 139L (vs 564L, -75%), 符合 < 200L 守门阈值
- **migrations 集中器设计**: 24 个 `if (from ...)` guard 全部外移到 part 文件, 主壳只剩 1-line 委托
- **错误处理统一**: 顶层函数 `_columnExists / _addColumnIfMissing` 提供列存在性幂等守卫
- **测试结构性回归好**: `app_database_split_round119_test.dart` 5 case 走"source-parsing"模式
- **3 顶层函数命名清晰**: `_runAppDatabaseMigrations` / `_columnExists` / `_addColumnIfMissing` — 名称完整描述行为

### 问题

- **part 文件仍 480L (低)**: `_runAppDatabaseMigrations` 函数体 24 个 if guard 仍内联在一处, 平均每 guard 16-20L
- **注释密度 30% (中)**: part 文件 480L 中 ~150L 是注释
- **顶层函数 vs class method 选型 (低)**: 3 个 helper 都用顶层函数, 不放 class method
- **类职责轻飘 (低)**: 拆后主壳只剩 139L (skeleton + 15 DAO facade), 严格意义上不再是 god class
- **3 helper 都未 @visibleForTesting (低)**: 顶层函数没有 @visibleForTesting 标注
- **schemaVersion 24 硬编码 (低)**: 主壳 `int get schemaVersion => 24;` 硬编码 24, 没走 const 集中器

---

## R120 P1-2 评估 (8.5/10)

### 优点

- **拆分干净**: 252L 主壳 (vs 386L, -35%) + 14L 私有方法 `_buildNotificationDetails()` + 53L 外部 markdown `NOTIFICATION_ID_BANDS.md`
- **命名表意精准**: `_buildNotificationDetails()` 单一目的, 1 私有方法封装 30L Android+iOS 平台差异构造
- **公开 API 收口干净**: 主壳 5 facade + 1 orchestrator + 1 sendNow + 1 pendingCount getter = 8 公开 method
- **PI 配置外移 doc (中-高)**: 40L 跨 sub-service ID range 文档外移到 `docs/architecture/NOTIFICATION_ID_BANDS.md`, 6 行 markdown table
- **错误处理统一 (中)**: 3 处 piiSafeLog + 1 处 swallowError 全部走集中器, 0 `catch (_)` silent
- **DI 注入 (高)**: 构造函数体内 7 sub-service + 1 delegate + 1 initializer 全部 const constructor 注入
- **测试结构性回归好**: `notification_service_split_round120_test.dart` 5 case

### 问题

- **2 个 @visibleForTesting 兼容 alias 未 @Deprecated (中)**: line 238 `refillNotificationId` + line 243 `computeRefillFireTime` 仍暴露公开 API, dartdoc 标"新代码请用"但没用 @Deprecated 注解
- **callback 字段 vs method (低)**: line 64-67 `onNotificationTap` / `onLaunchPayload` 是字段, 非 method
- **`_onResponse` 命名 (低)**: 跟 NotificationInitializer 内部 callback 同名
- **ID band doc 与代码未自动同步 (中)**: doc 6 行 ID 范围表, 跟代码 const 必须手动保持一致
- **`_buildNotificationDetails` 内 PII 决策未独立 doc (低)**: 含 visibility: secret + interruptionLevel: timeSensitive, 决策 rationale 写在 dartdoc 注释里
- **`pendingCount` 返回 -1 不显式 (低)**: -1 是 magic number
- **NotificationInitializer 仍是 god class (中)**: facade 虽缩到 252L 但 R120 没拆 NotificationInitializer

---

## 跨 R-round 一致性

| 维度 | R118 P2-7 | R119 P1-1 | R120 P1-2 | 一致性 |
|---|---|---|---|---|
| 拆解模式 | composition (10 instance) | part of (顶层函数) | 私有方法 + doc 外移 | **3 模式不同** ⚠ |
| 主壳行数 | 391L | 139L | 252L | 3 主壳角色各异 |
| 公开 API 变化 | 0 | 0 | 0 | ✅ 全 0 |
| drift / schema 风险 | 0 | 0 | 0 | ✅ 0 schema |
| 测试模式 | 42 case 行为 | 5 case 结构 | 5 case 结构 | ⚠ R118 行为 / R119 R120 结构 |
| 守门员 | 0 (42 行为) | < 200L 主壳 | < 350L 主壳 | ✓ R119/R120 size guard |
| 错误处理 | 0 catch | 1 swallowError | 3 piiSafeLog | R120 最佳 (统一集中器) |

---

## R121 建议

### 优先级 1 (≤2h, 必做)

- **R120 P1-2 alias @Deprecated 标记**: `notification_service.dart:238 / 243` 加 `@Deprecated('新代码请用 RefillNotifier.xxx; 此 alias 将在 v1.1 移除')`
- **R119 P1-1 part 文件拆 4 子文件**: `app_database_migrations.dart` 480L 拆 4 part (`_migrations_v1_v5.dart` / `_v6_v12.dart` / `_v13_v18.dart` / `_v19_v24.dart`), 每文件 < 150L
- **R118 P2-7 量表 class 各自 implements ScaleTranslations**: 让 10 个 class 各自 `implements ScaleTranslations`, 主壳 70 method 委派可缩到 < 200L

### 优先级 2 (≤4h, 建议)

- **NOTIFICATION_ID_BANDS.md 与代码 const 自动同步 test**: parse markdown table + parse Dart const, assert 一致
- **R118 量表主壳 391L size guard**: 加 1 case "StaticScaleTranslations 主壳 < 400L"
- **3 round 模式决策树补 AGENTS.md**: "10+ 同质 class → composition; 同 library generated code → part of; 单函数内联配置 → 私有方法"
- **R119/R120 补行为测试 (1-2 case)**: R119 mock 跑 `from=5` migration; R120 mock platform 验证 visibility / interruptionLevel
- **R118 crisisHotlineLabel / crisisTitle / crisisMessage 抽 CrisisHotlineTranslations 独立 class**

### 优先级 3 (文档 / 一致性)

- **`pendingCount` -1 magic number 改 const**: 加 `static const pendingCountUnsupported = -1;`
- **`_onResponse` 重命名 `_handleNotificationTap`**
- **R120 PII 决策外移 doc**: `docs/architecture/NOTIFICATION_PII_DECISIONS.md`
- **R119 `_runAppDatabaseMigrations` / `_columnExists` / `_addColumnIfMissing` 加 @visibleForTesting**
- **schemaVersion 抽 const 集中器**: `static const currentSchemaVersion = 24;`

---

## 附录: 8 维度交叉评分

| 维度 | R118 P2-7 | R119 P1-1 | R120 P1-2 |
|---|---|---|---|
| 命名清晰度 | 9/10 | 9/10 | 9/10 |
| 函数粒度 | 9/10 | 7/10 | 9/10 |
| 类职责单一 | 6/10 | 8/10 | 8/10 |
| 抽象层次一致 | 6/10 | 7/10 | 8/10 |
| 公开 API 暴露 | 7/10 | 8/10 | 7/10 |
| 死代码 / 重复 | 7/10 | 8/10 | 7/10 |
| 错误处理统一 | 9/10 | 9/10 | 9/10 |
| 文档完整性 | 9/10 | 8/10 | 9/10 |
| **平均** | **7.5/10** | **8.0/10** | **8.25/10** |

---

**总行数**: 230 行 markdown
**视角纯度**: 0 跨视角内容
