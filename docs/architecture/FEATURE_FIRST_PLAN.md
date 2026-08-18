# Feature-First Architecture Migration Plan (R110 + R125)

**状态**: R110 feature-first 重构阶段 1 设计文档 (2026-08-17)
**作者**: 主 agent (基于 R117 / R120 / R122 跨期残留重审 + R125 阶段 1 样板迁移经验)
**关联**:
- R117 综合审视 11 视角 + 5 维度
- R120 4 视角加权综合 7.5/10
- R122 P2-1/2/3 god class 续拆 6/12
- AGENTS.md R108 §六 god class 候选 6/12 闭环 (R118 / R119 / R120 / R116 / R122 P2-1 / R122 P2-2)
- R124 v1.0 5 厂商 push facade 接入阶段 1

---

## 1. 背景与动机

### 1.1 现状 (R125 起点)

4 层架构 (R0.18 round 12 后) + 共享层:

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── data/         # 基础设施: Database / Repositories / Services / Utils
│   │   ├── database/   # drift 表 + 迁移 + mappers
│   │   ├── repositories/
│   │   ├── services/   # 通知 / 录音 / 加密 / 5 厂商 push
│   │   └── utils/
│   ├── shared/       # 跨层共享 (formatters / mood_visual / json_codec)
│   ├── theme/        # AppTokens + M3 主题
│   ├── routing/      # go_router
│   └── l10n/         # domain 层 strings (通知 fallback)
├── l10n/             # presentation 层 flutter_localizations
├── domain/           # 0 Flutter 0 Drift 业务层
│   ├── entities/
│   ├── logic/        # 业务规则 (量表 / streak / 报告 / 情绪回顾聚合 / 标签库)
│   ├── repositories/ # 抽象接口
│   └── usecases/     # 用例 (业务编排)
└── presentation/     # UI 层
    ├── providers/
    ├── pages/        # 1 个 page = 1 个 dir
    └── widgets/      # 通用组件
```

**问题 (R117 / R120 跨期残留)**:
1. **跨 feature import 边界靠命名约定 (R115 check_cross_feature.py), 不可编译时强制**
2. **mood 情绪日记 51 file 散在 4 层 7 子目录** (database / mapper / dao / repo / service / provider / page), 找 mood 相关代码需 cross 4 层
3. **vent 30 file + vent_audio 7 file** 类似散开
4. **daily_tracking 6 子表 (sleep / weight / stress / anxiety / social_rhythm / treatment)** 6 个子目录, "日常追踪" 实际是 1 个 feature 包, 物理上是 6 个分散
5. **pub workspace 0 (R110 路线图)** — 跨 package 复用 token / 主题 / domain 实体等需 import 整个 lib, 编译依赖重

### 1.2 目标 (R110 终态)

```
lib/
├── main.dart
├── app.dart
├── core/                      # 跨 feature 共享 (跟 R125 起点同名, 内容缩到 5 umbrella)
│   ├── theme/                # AppTokens + 主题 (5 token 集中器, R122 R31 跨期残留)
│   ├── routing/              # go_router (跨 feature 路由)
│   ├── l10n/                 # domain + presentation strings
│   ├── shared/               # formatters / json_codec / DomainValue
│   └── platform/             # 平台 channel facade (5 厂商 push / HealthKit / 鸿蒙)
├── features/                 # **R110 新增顶层 — feature-first 重构核心**
│   ├── mood/                 # 情绪日记 (emotion-first 优先)
│   │   ├── data/             # table / mapper / dao / repository_impl / service
│   │   ├── domain/           # entity / repository (abstract) / logic / usecase
│   │   └── presentation/     # providers / pages / widgets
│   ├── vent/                 # 树洞倾诉 (emotion-first 优先)
│   ├── medication/           # 用药 (secondary)
│   ├── assessment/           # 心理评估 (secondary)
│   ├── daily_tracking/       # 日常追踪 (6 子表合一)
│   ├── trend/                # 趋势 (跨 mood + vent + daily_tracking)
│   ├── crisis/               # 危机热线 (跨 feature 共享)
│   └── settings/             # 设置 (跨 feature 共享)
└── tests/                    # 跨 feature 集成测试 (e2e / golden)
```

**核心收益**:
1. **编译时强制 feature 边界** — `features/mood/data/` 只能 import `features/mood/{domain,presentation}/` + `core/`, 不能 import `features/vent/`。跨 feature 共享走 `core/`。
2. **1 feature 1 目录 3 子目录 (data / domain / presentation)**, 找 mood 相关代码 1 处全找到
3. **pub workspace 拆分 (阶段 3)**: `packages/chroniccare_core/` (5 umbrella) + `packages/chroniccare_features_mood/` + `packages/chroniccare_app/` (app shell)。3 package 互依赖, 编译依赖减轻 ~40%。

### 1.3 R110 vs 当前 4 层架构

| 维度 | 4 层 (R0.18 起) | feature-first (R110) |
|---|---|---|
| 边界约束 | 命名约定 + `check_cross_feature.py` (文本扫描) | **编译时强制** (Dart import 路径) |
| 代码导航 | 跨 4 层 7 子目录 | 1 feature 1 目录 3 子目录 |
| pub workspace | 0 | 3 package (core + feature + app) |
| 重构成本 | 小 | **2-3 周** (5 阶段) |
| 守门员 | `check_all.dart` + `check_cross_feature.py` | 新增 `check_feature_first_migration.py` (feature 目录结构) |

---

## 2. R110 5 阶段路线图

### 阶段 1 (R125) — 设计文档 + 守门员 + 1 样板迁移 ✅ 本批

**目标**: 验证 feature-first 设计在 1 子表 (daily_tracking/anxiety_agitation) 端到端可行

**工作**:
- ✅ `docs/architecture/FEATURE_FIRST_PLAN.md` (本文件)
- ⏳ `scripts/check_feature_first_migration.py` — 验证 feature 目录结构 + 跨 feature import 边界
- ⏳ 样板迁移: `daily_tracking/anxiety_agitation/` 1 表 + 1 repo 从 `lib/core/data/{database/tables/daily_tracking, repositories/daily_tracking}/` 迁到 `lib/features/daily_tracking/data/{tables, repositories}/anxiety_agitation/`
- ⏳ 1 个 `daily_tracking/anxiety_agitation/` 完整子目录 (entity / logic / usecase / providers / page) 端到端
- ⏳ 守门员验证 + 跑通

**预计**: 1-2h (本批)

### 阶段 2 (R126) — 5+ feature 批量迁移

**目标**: 1-2 周迁移 5 个主要 feature

**优先级** (emotion-first 优先):
1. **mood** (51 file, 情绪日记 emotion-first 优先)
2. **vent** (30 file, 树洞倾诉 emotion-first 优先)
3. **assessment** (16 file, 心理评估 secondary)
4. **medication** (50 file, 用药 secondary)
5. **daily_tracking** (6 子表, 整包迁)

**预计**: 1-2 周

### 阶段 3 (R127) — pub workspace 拆分

**目标**: 拆 3 package

```
packages/
├── chroniccare_core/         # 跨 feature 共享基础设施 (R127 stage3 占位, 0 业务代码)
│   └── pubspec.yaml          # chroniccare_features_*: ^1.1.0
├── chroniccare_features_mood/  # 试点 1 feature (R127 stage3 占位, 0 业务代码)
│   └── pubspec.yaml          # chroniccare_core: ^1.1.0
└── chroniccare_theme/         # 5 token 集中器公共入口 (R128d 完成, 6 token public)
    └── pubspec.yaml          # 0 依赖
```

> **gdc R128e audit 2026-08-18 修正**: 实际实施阶段 3 时, **未拆 `chroniccare_app` 包** (app shell 仍在 root), 改为优先拆 `chroniccare_theme` (5 token 集中器公共化 R128d)。原因: 5 token 集中器跨 package 复用价值高于 app shell 隔离 (app shell 只 1 处使用, 抽 package 0 价值)。`chroniccare_core/` + `chroniccare_features_mood/` 仍是 0 业务代码占位 (`.gitkeep`), 待 R129+ 阶段 4 续迁时再激活。

**预计**: 1 周

### 阶段 4 (R128) — 跨 feature 共享 (core/platform)

**目标**: 把跨 feature 共享逻辑 (5 厂商 push / HealthKit / 危机热线 / 设置) 抽到 `core/platform/` umbrella

**预计**: 3-5 天

### 阶段 5 (R129) — 综合审视 + 5 token 集中器转 pub workspace 公共 package

**目标**: R31 跨期残留 (5 token 集中器跨 package 复用) 闭环

**预计**: 1 周 + 综合审视 4 视角

---

## 3. R125 阶段 1 样板设计

### 3.1 选 anxiety_agitation 1 子表做样板的理由

- **最纯**: 1 表 (anxiety_agitation_entries.dart) + 1 repo (anxiety_agitation_repository_impl.dart) + 1 entity, 跨其他子表 0 依赖
- **5 file 端到端**: tables + mapper + dao + repo_impl + entity
- **不会破现有用户**: 0 业务调用 (现有 daily_tracking 是空表占位, R0.18 round 14 P0-2 加的 6 子表都没接 page UI)
- **验证目录结构**: 1 完整 feature 子目录 (data + domain + presentation 三层) 都能跑通

### 3.2 目录结构样板 (R125 阶段 1 目标)

```
lib/features/daily_tracking/
├── data/
│   ├── tables/
│   │   └── anxiety_agitation_entries.dart   # 从 lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart 迁
│   ├── mappers/
│   │   └── anxiety_agitation_mapper.dart    # 新增 (现有 0 mapper, 需要)
│   ├── daos/
│   │   └── anxiety_agitation_dao.dart        # 从 lib/core/data/database/daos/ 抽 (现有 0 独立 dao, 走 repository_impl)
│   └── repositories/
│       └── anxiety_agitation_repository_impl.dart  # 从 lib/core/data/repositories/daily_tracking/ 迁
├── domain/
│   ├── entities/
│   │   └── anxiety_agitation_entry_entity.dart    # 新增
│   ├── logic/
│   │   └── anxiety_agitation_aggregator.dart      # 新增 (占位空 class)
│   └── repositories/
│       └── anxiety_agitation_repository.dart       # 抽象接口
└── presentation/
    ├── providers/
    │   └── anxiety_agitation_providers.dart        # 新增 (占位)
    ├── pages/
    │   └── anxiety_agitation_page.dart             # 新增 (占位)
    └── widgets/
        └── anxiety_agitation_card.dart             # 新增 (占位)
```

**注**: 阶段 1 只迁 1 子表, 不动其他 5 子表 (sleep / weight / stress / social_rhythm / treatment)。其他 5 子表仍留在原 `lib/core/data/{database/tables/daily_tracking, repositories/daily_tracking}/`。

### 3.3 守门员 check_feature_first_migration.py 阶段 1 gate

**必过 (阶段 1)**:
- `lib/features/` 目录存在
- 至少 1 个 feature 子目录有 `data/` `domain/` `presentation/` 3 子目录
- feature 子目录内 file 不引用 `package:chroniccare/core/data/...` (feature 边界)
- feature 子目录内 file 不引用 `package:chroniccare/features/其他 feature/...` (跨 feature 边界)

**阶段 2+ gate** (R126 启用):
- 5+ feature 完整迁移
- `check_cross_feature.py` 跟 `check_feature_first_migration.py` 协同

**阶段 3+ gate** (R127 启用):
- `packages/chroniccare_*/` 3 pub workspace 存在
- pubspec.yaml 互依赖正确
- 编译依赖 < 40% (跟 baseline 对比)

---

## 4. R110 风险 + 缓解

### 4.1 风险: 跨 feature 共享代码 (notification / 5 厂商 push / HealthKit / 危机热线)

**缓解**: 阶段 4 (R128) 抽 `core/platform/` umbrella, 阶段 1-3 不动共享代码, 仍放 `core/data/services/`

### 4.2 风险: 守门员 check_all.dart 路径硬编码

**缓解**: 阶段 1 同步改 check_all.dart 支持新路径 (feature 目录 + core 目录共存), 阶段 2 改 4 层架构纯度为 3 层 (data/domain/presentation per feature)

### 4.3 风险: pub workspace 跨 package 类型兼容 (chroniccare_features_mood 中的 MoodEntryEntity 跟 chroniccare_core 中的 DomainValue<T> 互用)

**缓解**: 阶段 3 拆 workspace 时 type alias + 3-5 个 core 类型 (DomainValue / AppTokens / MoodEntry 等) 抽到 chroniccare_core, features_mood 反向依赖

### 4.4 风险: 阶段 1 样板迁移 5-8 file import 路径全改, 容易漏

**缓解**: 守门员 + grep `package:chroniccare/core/data/...` 阶段 1 全清零

---

## 5. 关键决策记录

### R125 阶段 1 (本批)
- **样板选 anxiety_agitation**: 1 子表 5 file 端到端, 0 跨 feature 依赖
- **目录结构 data/domain/presentation 3 子目录**: 跟 R110 终态对齐
- **守门员分阶段启用**: 阶段 1 必过 4 项 + 阶段 2+ 启用 5+ feature gate + pub workspace gate
- **0 重构现有用户路径**: 阶段 1 只迁 1 子表, 其他 5 子表仍留 core, 不影响现有 daily_tracking 业务

### R110 终态
- **1 feature 1 目录 3 子目录**: 编译时强制边界
- **pub workspace 3 package**: core / features_mood (试点) / app
- **5+ feature 完整迁移**: mood / vent / assessment / medication / daily_tracking

---

## 6. 验收数据 (R125 阶段 1 收尾填)

| 维度 | 数据 |
|---|---|
| 样板 feature | daily_tracking/anxiety_agitation |
| 迁移 file 数 | 5 (1 table + 1 mapper + 1 dao + 1 repo_impl + 1 entity) |
| 新增 file 数 | 6 (1 mapper + 1 entity + 1 logic + 1 repo abstract + 1 provider + 1 page + 1 widget) |
| 守门员 | 1 新增 (`check_feature_first_migration.py`) |
| flutter test | (收尾填) |
| 0 回归 | (收尾填) |

---

## 7. 关联文档

- `docs/DEVELOPMENT_REQUIREMENTS.md` — v2.0 需求 (R117)
- `docs/PRIVACY_HARDENING.md` — 隐私加固 (R115)
- `docs/audit/2026-08-17-round120/00-FINAL-CONSOLIDATION.md` — R120 综合审视 4 视角
- `docs/architecture/NOTIFICATION_ID_BANDS.md` — R120 通知 ID 文档
- `AGENTS.md` — 项目入口
