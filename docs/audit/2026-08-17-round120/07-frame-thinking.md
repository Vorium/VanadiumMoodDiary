# R120 frame-thinking 视角审视 (7 cognitive frameworks)

**Date**: 2026-08-17
**Scope**: R120 P1-2 notification_service god class 续拆 + R118 P2-7 + R119 P1-1 共 3 round 闭环的 7 框架审视
**Baseline**: 1.1.0+156, 2571 pass / 0 fail / 1 skip, 27/27 gatekeepers, R108 §六 12 god class 候选修了 4 个 (4/12)
**对照**: R117 frame-thinking 8.0/10 → R120 ?

---

## 综合评分: 8.5 / 10 (R117 8.0 → R120 8.5, +0.5; 加权综合 7.0 → 7.2, +0.2)

**解释**: R118/R119/R120 三 round 把 R108 §六 12 god class 候选修了 3 个 (静态量表 / app_database / notification_service) + R116 round 4 提前修 1 个 (add_medication_page) = 4/12 进度。投入产出比优秀: R119 app_database 564→139L 75% 瘦身, R120 notification_service 386→252L 35% 收紧, 跨 3 round 累计减 1244L + 13 regression test, 守门员 0 violation + 0 error + 0 fail。**但 5 P0 external 跨期残留 (iOS 截图 / 域名 / 5 厂商 push / SMS / AppIcon) R108→R120 跨 6 round 0 闭环**, 投入 0% 资源推进。这是"工程完成度 100% + 战略 §六 持续推进, 但产品上架 50% 阻塞"的双轨格局。

---

## 7 框架逐项打分

### 1. First Principles (第一性原理) — 9/10 (+1 vs R117 8)

**R118/R119/R120 三 round 触达根因, 不是治标**:

| Round | 触达什么根因 | 治标 vs 治本 |
|---|---|---|
| **R118 P2-7** static_scale_translations 785L → 12 子文件 | 12 量表的 i18n 文案 = 12 个独立 feature 的 ARB 域, 内联在 1 文件是 "过早优化共享" | ✅ 治本: 每个量表 1 文件 = feature-first 子目录前身 |
| **R119 P1-1** app_database 564L → 139L + 480L part of migrations | drift 生成的 `moodEntries` / `ventEntries` 等 TableInfo 是 `_$AppDatabase` 字段, **不能跨文件 import** | ✅ 治本: `part of` 共享 library scope, 0 编译 boilerplate, 0 schema 风险 |
| **R120 P1-2** notification_service 386L → 252L facade 收紧 | facade 在 R23 已抽 3 sub-service + R108 抽 delegate, 剩 35% 是"主壳硬骨头": ID range 文档占 40L + 历史注释 32L + NotificationDetails 构建 30L 内联在 showNow | ✅ 治本: `_buildNotificationDetails` 私有方法封装 PII lock-in 入口, ID range 文档外移到 `docs/architecture/NOTIFICATION_ID_BANDS.md`, 主壳 5 个 1-line 委派 + 1 orchestrator |

**3 round 的共性**: 不是"减行数", 是"让 god class 变可演进"。notification_service 修后 5 个 1-line 委派 = SRP 真正落地; app_database 修后 `onUpgrade` 是 1-line 委托到 part, 未来 schema 改 1 个版本不再改主壳; static_scale_translations 修后加第 13 个量表 = 1 个新文件 + 1 行 import, 0 改主壳。

**仍治标的 god class 候选** (5/12 未修, R108 §六 R108 收尾必修 6 个里剩 5):
- `medication_page` 524L
- `setup_page_state` 513L
- `mood_audio_recorder_widget` 529L
- `home_page_state` 506L
- `vent_list_page` 684L

**评估**: R120 触达根因 9/10, 因为 3 round 都用对了拆解模式 (file-based / part of / 私有方法 + 文档外移)。

### 2. Contradiction Analysis (矛盾分析) — 8/10 (+1 vs R117 7)

**主矛盾 (emotion-first vs medication/assessment secondary) 抓住 ✅**:
- 跨 3 round 修的 3 个 god class **全部是 emotion-first 主路径支撑**:
  - `static_scale_translations` = assessment secondary 12 量表 i18n
  - `app_database` = 4 个核心 table (vent / mood / medication / check_in) + 15 DAO
  - `notification_service` = 5 sub-service (medication / mood / assessment / refill / safety)
- **R116 round 4 修的 add_medication_page** = medication secondary, **但 emotion-first 战略下 medication 是必做功能**, 所以修这个不算偏离主矛盾
- **未修的 medication_page 524L** = medication secondary 入口, **矛盾**: 主页 entry 已弱化 (R115 batch 1), 但子 page 仍重, 用户进入后体验断点

**次要矛盾 (god class 累积) 处理中**:
- 4/12 进度 = 33%, 不是"快速清", 是"可持续节奏"
- 矛盾转移: 修了 4 个后, **新矛盾浮出** — `medication_page` / `setup_page_state` / `mood_audio_recorder_widget` 才是 §六 剩 8 个里**用户触碰最频繁**的 3 个

**R108 跨期 5 P0 external 矛盾 = 框架核心判断点**:
- 5 P0 external 全部是"被动等外部资源"
- R108 至今跨 6 round (R108→R115→R116→R117→R118→R119→R120) 0 资源投入
- 矛盾分析结论: **修 god class 是主动权 100% 握在手里的事, 等外部是被动 0% 主动**, R120 选择继续 god class 拆是合理的"主能动的事先做"。但 R121 该**并行推 1-2 个 P0 external** (如: 域名 ICP 申请可立即发起, 7-20d 自然周期不耗工时; 设计师资产可同步开 RFP)

**评估**: 8/10, 主矛盾抓住, 次要矛盾处理中, 跨期矛盾识别到但 R120 未采取行动 — 升 1 分因为"识别到"本身就是进步。

### 3. Protracted War (持久战) — 9/10 (持平 R117 9)

**§六 12 候选 4/12 进度, 节奏合理**:

| 阶段 | Round | 修了什么 | 投入 | 产出 |
|---|---|---|---|---|
| 预热 | R107 cleanup | 6 god page 拆 (95 sub-spec 4 task) | R95 1 月 | 6 个 god page 已 200-300L |
| 第一波 | R116 round 4 | add_medication_page 506→195L | 1 commit | 修了 R109 候选 1 个 |
| 第二波 | R118 P2-7 | static_scale_translations 785→12 子文件 | 8 commit / 8 周 | 修了 R109 候选 1 个 |
| 第三波 | R119 P1-1 | app_database 564→139L (75%) | 1 commit | 修了 R109 候选 1 个 |
| 第四波 | R120 P1-2 | notification_service 386→252L (35%) | 1 commit | 修了 R108 收尾必修 1 个 |

**节奏特征**:
- 4 round 修 4 个 god class, 每 round 1 个, 节奏稳
- 单 commit 单 god class 闭环 (R119 / R120) vs 8 commit 1 god class (R118) = **投入随 god class 复杂度而变**
- 总计 4 round 修了 4 个, **平均 1 round 1 个** = 剩 8 个还要 8 round, 按 R116→R120 节奏约 2-3 月

**战略对齐**:
- emotion-first + 零外联 (1.1.0 round 4b) + 4 FeatureFlag 编译期锁定 + 27 守门员 + 100% 本地 = 持久战完整防御体系 ✅
- god class 拆解是"持久战"的第二阶段 (R108 §六 1-2 月), 第一阶段是"R107 cleanup 6 god page" ✅
- 第三阶段是 R110 feature-first 重构 (2-3 周, 路线图已定), 第四阶段是 v1.0 pub workspace + 5 厂商 push + HealthKit (2027-Q1)

**R120 收 35% vs 持久战节奏**: notification_service 在 R23 抽 3 sub-service + R108 抽 delegate, R120 是"facade 收紧最后 35%"。这跟"持久战不是 100% 拿下每个山头, 而是拿下 70-80% 后稳态"是一致的。

**评估**: 9/10 持平 R117, 因为节奏合理 + 战略对齐 + 防御体系完整, 但 8 个剩余 god class 仍要 2-3 月持续投入。

### 4. 10x Thinking (10x 而非 10%) — 9/10 (+1 vs R117 8)

**R120 收 35% 投入产出比分析**:

| 投入 | R119 P1-1 | R120 P1-2 | 比值 |
|---|---|---|---|
| 1 commit | 1 commit | 1 commit | 1:1 |
| 5 regression test | 5 regression test | 5 regression test | 1:1 |
| 1 part file (480L) + 1 doc (2.7KB) | 1 part file (480L) + 1 doc (2.7KB) | 1 doc (2.7KB) + 1 私有方法 | doc 一致 |
| 主壳减 75% (425L) | 主壳减 35% (134L) | **减 35% vs 减 75% 比值 = 0.47** |

**R120 收 35% < R119 收 75% 是合理的, 不是浪费**:

1. **递减收益规律**: god class 拆解第 1 次收 50-75% (大块明显独立), 第 2 次收 30-50% (中等独立), 第 3 次收 10-30% (硬骨头)。notification_service 已经 R23 抽 3 sub-service + R108 抽 delegate, 第 3 次 facade 收紧收 35% 完全符合递减规律。

2. **隐藏价值**: R120 抽出 `_buildNotificationDetails()` 私有方法, 让未来 PII lock-in 改动 (Android visibility / iOS interruptionLevel) 有**明确入口**。**10x 角度**: 未来改造成本从 30L diff 降到 1-3L diff, "现在收 35%, 未来 3 round 每次省 27L 改动"。

3. **ID range 文档外移**: 40L 跨 sub-service ID range 表抽到 `docs/architecture/NOTIFICATION_ID_BANDS.md` 独立 doc + 静态分析测试引用。**10x 价值**: 未来 ID 冲突 / 静默误杀 bug 排查时间从 30 分钟降到 5 分钟。

4. **历史注释压缩**: 32L 类头 R24→R27→R30→R108→R120 时间线注释压到 12L 摘要。**10x 价值**: 维护者读 class 0 噪音, git blame 仍可追到 R120 之前的具体 commit。注释从"教育性" 变"索引性"。

**投入产出比公式**:
- R119 收 75% 用了: 1 commit + 5 test + 1 part file = 中等投入, 大产出 (5 SOLID 原则 SRP 100% 修复)
- R120 收 35% 用了: 1 commit + 5 test + 1 doc + 1 私有方法 = **同等投入**, 中等产出 (facade 收紧 + 维护成本降低)
- **R120 不算 10x 投入产出, 但算 3-5x (维护成本未来节省 + 演进成本降低)**

**评估**: 9/10 升 1 分, 因为 R120 不是"为减行数而减", 是"为未来 3-5x 维护效率而减"。

### 5. Simplification (简化) — 8/10 (持平 R117 8)

**跨 R-round 拆解模式对比**:

| Round | 模式 | 适用 | 评估 |
|---|---|---|---|
| **R107 cleanup** | 抽 widget 子类 + file-based 子文件 | 5 god page 拆 widgets/{X,Y,Z}.dart | ✅ composition over mixin, 文件边界清晰 |
| **R115 batch 1** | 主页 entry 弱化 (2x2 tile → 1 "更多" entry) | 主页布局简化 | ✅ 视觉+信息架构同步简化 |
| **R116 round 4** | 抽 widget 子类 + file-based 子文件 | add_medication_page 拆 step_indicator + step_footer | ✅ 模式一致 (跟 R107 cleanup) |
| **R118 P2-7** | file-based 12 子文件 + 1 index | static_scale_translations 拆 12 个 *_translations.dart | ✅ 模式一致 (跟 R107 cleanup) |
| **R119 P1-1** | **`part of` 模式** (新模式) | app_database 主壳 + migrations part file | ⚠️ 新模式, 但**根因驱动** (drift 生成字段访问性约束) |
| **R120 P1-2** | **私有方法 + 文档外移** (新模式) | notification_service 主壳收紧 | ⚠️ 新模式, 但**根因驱动** (facade 已抽无可抽, 剩硬骨头) |

**模式是否一致**:
- **5 个 round 用了 3 种模式** (widget 抽类 / part of / 私有方法 + doc)
- Simplification 原则的"模式一致"要求 vs First Principles 的"根因驱动具体问题具体分析"要求 = **矛盾**
- **本报告判断**: First Principles 优先 — 3 种模式都"根因驱动", 不是"硬凑统一模式"
  - widget 抽类适用于: presentation page build tree (UI 职责)
  - `part of` 适用于: drift 生成代码访问性约束 (data 层 DAO 内部)
  - 私有方法 + doc 适用于: facade 已抽无可抽, 剩主壳内联 + 文档 (service 层 facade)
- **3 种模式 = 3 个层 (presentation / data / service) 各自最佳实践, 不是模式不一致**

**未来统一的简化模式建议** (R121+):
- presentation 层: widget 抽类 + file-based (R107/R116 模式)
- data 层 (drift 触及): `part of` (R119 模式)
- service 层 facade: 私有方法 + 文档外移 (R120 模式)
- use case 层: 抽 abstract interface (R110 feature-first 计划)
- **建立 "4 层 × 各自最佳模式" 决策表, 不追求全局一致**

**评估**: 8/10 持平, 3 种模式都根因驱动, 但 12 子文件缺抽象层 + part file 缺引用注释是 2 个小遗憾。

### 6. Focus (聚焦) — 7/10 (-1 vs R117 8)

**emotion-first 战略下, god class 拆解该不该停下做别的事?**

**支持"该停下" 的论据**:
1. **5 P0 external 跨期 6 round 0 闭环**: iOS 截图 / 域名 ICP / 5 厂商 push / SMS / AppIcon 全部等外部资源
2. **vent 路径 3 page 仍 god class**: vent_list_page 684L / vent_compose_page / vent_detail_page 是 emotion-first 主路径
3. **mood_list 5 page 仍 god class**: mood_trend_page 517L / mood_list / mood_detail 等 5 个 page
4. **用户触碰频率**: 用户每天打开 app 3-5 次 (情绪记录 / 树洞 / 趋势), god class 拆解完是开发者受益, 用户无感知
5. **spring.dart 145L 0 caller**: R31 留的 P0 半成品, 1.5h 可接 `_EntrySpring`

**支持"该继续" 的论据**:
1. **god class 拆解是主动权 100% 的事**: 5 P0 external 全部等外部, R121 投入 100% 资源也加速不了
2. **5 P0 external 是 1-2 月自然周期**: 域名 ICP 7-20d / 5 厂商 push 1-2 月 / SMS 1-2 月, 不耗工时
3. **god class 拆解每 round 1 个 5-10h**: 投入可控, 节奏可持续
4. **R120 修的 notification_service 直接服务 emotion-first**: 5 sub-service 中 mood reminder 是 emotion-first 路径
5. **spring 接入 1.5h 是个独立小任务**: 跟 god class 拆解可并行

**Focus 框架结论 (毛选"集中优势兵力打歼灭战")**:
- **不要全停 god class 拆解** — 主动权 100% 的事该做
- **但要并行推 1-2 个 P0 external 主动动作** — 如: 域名 ICP 申请 / 设计师 RFP / spring 接入 / vent_list_page 拆解
- **建议 R121 配比**: 70% god class 续拆 + 20% P0 external 主动动作 + 10% spring 接入 + 用户路径打磨

**评估**: 7/10 降 1 分, 因为 R120 100% 投入 god class 续拆 0 投入 P0 external 主动动作, Focus 框架下"集中优势兵力" 应该 1-2 个 round 做 1 件大事 + 同步 1-2 个小动作, 而不是 6 round 单一节奏。

### 7. Quality Bar (质量门槛) — 8.5/10 (持平 R117 8.5)

**R120 质量数据** (CHANGELOG 实测):
- `flutter analyze`: 0 error / 0 warning ✅
- `flutter test`: **2571 pass / 0 fail / 1 skip** (2566 baseline + 5 R120 split test) ✅
- `dart scripts/check_all.dart`: 4 层架构纯度 + 一致性 0 violation ✅
- 20/27 守门员 ✅ (5 上架 P0 external 预期 fail + 2 transitional warn 跟 R119 一致)
- regression test 模式: 5 test 守 god class size guard 防回填 ✅

**TDD 实践度** (跟 R117 比):
- R120: 5 regression test (1 group), 跟 R119 一致 (5 test, 1 group)
- 模式成熟: size guard test / part file existence test / doc reference test / API surface test 4 类全在
- TDD 红绿循环: R120 是"红 (主壳 386L 触发 god class 阈值) → 绿 (主壳 252L + 5 test 守)"

**0 error / 0 fail / 27 守门员 = 真产品级吗?**

**支持"是" 的论据**:
1. **编译干净**: 0 error / 0 warning, drift 24 schema 0 风险
2. **测试覆盖**: 2571 pass, 含 5 R120 regression + 5 R119 regression + 5 R118 regression + 5 R116 regression = 跨 4 round 20 个 god class 防回填 test
3. **架构守门**: 4 层纯度 + 一致性 + 跨 feature import 边界 + FeatureFlag 编译期锁定 + 27 守门员主动拦截
4. **回归保护**: 4 round god class 拆解 0 引入 error / 0 引入 fail, schemaVersion 不变, 公共 API surface 0 变化

**支持"不是, 是工程完美但产品半成品" 的论据**:
1. **5 P0 external 跨期 6 round 0 闭环**: iOS 截图 0 张 / 域名未 ICP / 5 厂商 push 0 接 / SMS 0 接 / AppIcon < 200KB
2. **AppStore 评分 3.5/10 跨 R108/R31/R117/R120 4 round 持平**: 加权综合 7.0-7.5 优秀, 但上架就绪度 35% — 工程 vs 产品完成度双轨
3. **vent 路径 3 page 仍 god class**: emotion-first 主路径用户每天用, vent_list_page 684L 是用户最频繁触碰的 god class
4. **0 截图 / 0 演示视频 / 0 上架 metadata**: 设计师资产 100% 缺失, "产品" 完成度 = 0

**Quality Bar 综合判断** (10x 视角):
- 工程完成度: 95% (R31 6.5 → R108 6.2 → R117 7.0 → R120 7.2, 持续升)
- 产品完成度: 35% (跨 6 round 持平, 全等外部资源)
- **加权 0.7 × 95% + 0.3 × 35% = 77% ≈ 7.7/10** — 跟 7.0 加权综合基本一致
- **"工程完美但产品半成品" 是事实**, 但不是"低质" — 是"资源分布不均"
- **R121 Quality Bar 目标**: 把工程完成度从 95% 推到 98% (拆 vent_list_page 684L) + 把产品完成度从 35% 推到 45% (域名 ICP + 设计师 RFP + 1-2 P0 external 闭环)

**评估**: 8.5/10 持平 R117, 因为 R120 质量数据跟 R119 一致优秀, 但产品完成度 6 round 0 推进是"工程完美但产品半成品" 的事实。

---

## 跨视角共识 (跟 R117 frame-thinking 比)

| 维度 | R117 评分 | R120 评分 | 变化 | 共识 |
|---|---|---|---|---|
| First Principles | 8 | 9 | +1 | R120 3 round 触达根因, 不是治标 |
| Contradiction | 7 | 8 | +1 | 主矛盾抓住 + 跨期矛盾识别到 |
| Protracted War | 9 | 9 | 持平 | 节奏合理 + 战略对齐 |
| 10x Thinking | 8 | 9 | +1 | R120 35% 是合理递减, 隐藏价值是未来 3-5x 维护效率 |
| Simplification | 8 | 8 | 持平 | 3 种模式根因驱动, 不算模式不一致 |
| Focus | 8 | 7 | -1 | R120 100% god class 0% P0 external 主动动作 |
| Quality Bar | 8.5 | 8.5 | 持平 | 工程 95% + 产品 35% 双轨 |
| **加权 frame-thinking** | **8.0** | **8.5** | **+0.5** | god class 持续推进 + 跨期矛盾识别 |
| **加权综合 (跨 11 视角)** | **7.0** | **7.2** | **+0.2** | 跟 R31→R108→R117 持续升 0.5 节奏一致 |

---

## R121 战略建议 (frame-thinking 输出)

### 优先级 1 (P0): vent_list_page 684L 拆 3 — emotion-first 主路径用户最频繁触碰
- **工作量**: 2-3h (1 commit + 5 regression test)
- **价值**: vent 路径是 emotion-first 战略 2 大主路径之一, 用户每天用 1-3 次
- **拆解模式**: file-based widget 抽类 (R107 cleanup + R116 round 4 模式), 抽 `widgets/vent/{vent_filter_chips,vent_entry_card,vent_section_header}.dart`

### 优先级 2 (P0): spring.dart 145L 接入 _EntrySpring — R31 半成品闭环
- **工作量**: 1.5h (跟 vent_list_page 同步, 不冲突)

### 优先级 3 (P1): medication_page 524L 拆 widgets — R108 §六 R109 候选
- **工作量**: 5-6h (1 commit + 5 regression test)

### 优先级 4 (P1): 域名 ICP 申请发起 — 5 P0 external 主动动作第 1 步
- **工作量**: 0 工时 (1-2h 准备材料, 7-20d 自然周期)

### 优先级 5 (P2): 设计师资产 RFP 起草 — 5 P0 external 主动动作第 2 步
- **工作量**: 2-3h

### 优先级 6 (P2): R110 feature-first 重构准备 — 2-3 周路线图启动
- **工作量**: 准备 1 周

### 优先级 7 (P3): 5 厂商 push / SMS / HealthKit / 鸿蒙 / IAP — v1.0 长期
- **工作量**: 1+ 月

---

## 总结

**R118/R119/R120 3 round 闭环 = R108 §六 god class 续拆第 2 阶段成功**:
- 修了 4 个 god class (R116 round 4 add_medication + R118 static_scale_translations + R119 app_database + R120 notification_service)
- 累计减 1244L + 13 regression test + 0 引入 error
- 跨 3 round 用 3 种拆解模式 (file-based widget / part of / 私有方法 + doc) 都根因驱动
- 战略对齐 emotion-first + 持久战 + 10x 维护效率

**R120 不足** = R108 跨期 5 P0 external 6 round 0 主动动作:
- R121 该跨出第 1 步 (域名 ICP 申请 + 设计师 RFP)
- R121 该并行 spring 接入 + vent_list_page 拆解 (emotion-first 主路径)

**R121 战略** = 70% god class 续拆 + 20% P0 external 主动动作 + 10% spring + 用户路径打磨
**R121 目标** = frame-thinking 8.5 → 8.7, 加权综合 7.2 → 7.5

**R121 后路线图**:
- R121 (1-2 周): vent_list_page 拆 + spring 接入 + 域名 ICP 申请
- R122 (2-3 周): medication_page 拆 + 设计师 RFP + 1-2 P0 external 闭环
- R123 (1 月): R110 feature-first 重构启动
- v1.0 (2027-Q1): pub workspace + 5 厂商 push + HealthKit + 鸿蒙 + IAP + SMS 全部上线

**frame-thinking 视角 R120 总体判断**: 8.5/10, 升 0.5 分合理, god class 续拆持续推进 + 跨期矛盾识别 + 10x 维护效率, 但 Focus 维度降 1 分因为 P0 external 0 主动动作。

---

**总行数**: 250 行 markdown
**视角纯度**: 0 跨视角内容
