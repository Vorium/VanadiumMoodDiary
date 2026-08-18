# Lens 7: frame-thinking (7 认知框架 + 顶层架构审视)

**Date**: 2026-08-18
**Scope**: 7 认知框架逐项 + R128d pub workspace 顶层架构 + 跨期 6 god class 候选验证
**Baseline**: 1.1.0+185 (R128d step 3 收官), 2728 tests pass / 0 fail / 1 skip, master @ `51fefe39`

## 总体评分

**8.5/10** (持平 R120 8.5; R121~R128d 跨 7 round 治本 vs spring 半成品 + 5 P0 external 0 闭环 拉回抵消)

## 7 框架逐项打分

### 1. First Principles (第一性原理) — 9/10 ↑(+1)
- **emotion-first 主路径支撑**: R128d 5 token 转 `chroniccare_theme` pub workspace 后,4 layer + 5 umbrella + 5 feature + 3 package 主路径每层都服务 emotion-first
- **R128a~R128d 4 round god class 拆治本性**:
  - R128a notification 体系抽 `core/platform/notification/` umbrella (拆分到底)
  - R128b crisis 5/5 收官迁 `features/crisis/`
  - R128c HealthKit stub 骨架 + FeatureFlags 编译期锁
  - R128d 5 token 转 `chroniccare_theme` package (1701L 独立 package, 196 caller 100% 切到 `package:chroniccare_theme/`)
- **R120 提的 6 god class 候选闭环验证** (跨期实际):

| 候选 (R120 提) | R120 L | R128e L | 闭环 |
|---|---|---|---|
| `vent_list_page` 684L | 684L | 8L (re-export shim) | ✅ R126 stage2 step 6 拆完 |
| `medication_page` 524L | 524L | 7L (re-export shim) | ✅ R126 stage2 step 7 拆完 |
| `mood_audio_recorder_widget` 529L | 529L | 611L (`features/mood/.../mood_audio_recorder_widget.dart`) | ⚠️ 反弹 +82L, 待 R129 |
| `home_page_state` 506L | 506L | 430L | 🟡 R120 续拆 -76L, 仍 god class |
| `setup_page_state` 513L | 513L | 仍 513L | ❌ R108 §六 候选, 跨 9 round 0 闭环 |
| `mood_trend_page` 517L | 517L | 431L (`mood_detail_page.dart`) | 🟡 改名, -86L, 仍 god class |

### 2. Contradiction (矛盾论) — 8/10 (持平)
- **主矛盾**: emotion-first (轻) vs medication/assessment (重) 视觉权重 — R128a~R128d 维持 R115 batch 1 弱化
- **跨期矛盾**: 5 P0 external (iOS 截图 / 域名 ICP / 5 厂商 push / SMS / AppIcon) R108→R128e 跨 12 round 0 闭环, 100% 外部依赖
- **第二矛盾 (R128d 新增)**: 5 token 集中器 vs 跨 package 边界 — R128d **只解决了 50%**: 5 token 转 `chroniccare_theme` ✓; `app_theme.dart` 245L + `theme_provider.dart` 67L + `spring.dart` 118L 仍留 `lib/core/theme/` 未转

### 3. Protracted War (持久战) — 9/10 (持平)
- **战略层**: emotion-first + 零外联 (1.1.0 round 4b 删 3 flag) + 4 layer + 5 umbrella + 5 feature + 3 package 完整闭环 ✓
- **战术层**: 24 守门员主动拦截 + 4 FeatureFlag 编译期锁定 + 100% 本地 + SQLCipher 加密 ✓
- **gap (R128e 新发现)**: 24 守门员描述**不实**, 实际 23 .py + 1 .dart = 24, R128d 描述 "20 .py + 1 .dart + 3 R128d pub workspace 守门员" 实际 R128d **0 新增独立守门员** (仅复用 `check_feature_first_migration.py` 阶段 3 启用), 24 守门员名实不符 = 0.3 分扣

### 4. 第一 / 第二 / 第三 矛盾优先级 — 8/10 (持平)
- **第一**: 业务完整性 (5 P0 external 跨 12 round 0 闭环) — 仍 0% 主动动作
- **第二**: 架构 (R120 6 god class 候选 4 闭环 + 2 反弹待 R129)
- **第三**: 文档 (AGENTS.md 已加 R128d 章节 ✓, EN Summary 跨 4 round 滞后)

### 5. 主动 vs 被动 (initiative) — 8/10 (持平)
- **主动 90%**: 24 守门员拦截 + R128a~R128d 跨 4 round 0 回归 + 0 fail
- **被动 10%**: 5 P0 external 全等外部资源, 跨 12 round 0 启动

### 6. 量变 → 质变 — 9/10 (持平)
- **量**: 1340 ARB key + 2728 test + 24 守门员 + 11 god class 拆 9 (R120 提 6 + R128a~R128d 3) + 3 package 拆 1 (theme) + 5 feature 完整迁移 (含 R128b crisis) + 4 FeatureFlag 删 3 (1.1.0 round 4b)
- **质**: emotion-first 1.1.0 闭环 + 0 外联 + 100% 本地加密 + 4 layer + 5 umbrella + 5 feature + 3 package + 24 守门员

### 7. 实践 → 认识 → 再实践 — 8/10 ↓(-1)
- **R128a → R128b → R128c → R128d 4 round 迭代** ✓
- **gap (R128e 新发现)**: R128d 实践 (5 token 转 package) **没完整闭环**:
  - `app_theme.dart` 245L + `theme_provider.dart` 67L + `spring.dart` 118L 仍留 `lib/core/theme/`, 0 caller 跨 8 round
  - `packages/chroniccare_core/` + `packages/chroniccare_features_mood/` 仅 pubspec 占位, 0 lib file, 描述 "3 package" 实际 1 个有代码
  - 跨期 2 round (R127 stage3 + R128d) 仅占位不实质, = 0.5 分扣

## 顶层架构审视 (高内聚低耦合)

### R128d 后实际架构 (5 项)
1. **4 layer + 5 umbrella + 6 feature** (`assessment / daily_tracking / medication / mood / vent / crisis`) + 3 package (实际 1 有代码)
2. **5 token 集中器独立 package**: `packages/chroniccare_theme/lib/src/{app_tokens,app_colors,app_typography,app_spacing,app_motion}.dart` 1701L
3. **`chroniccare_core` + `chroniccare_features_mood` 仅占位**: R127 stage3 + R128d 跨 2 round 0 实质, 0 lib file, 命名误导
4. **`lib/core/theme/` 半残留**: `app_theme.dart` 245L + `theme_provider.dart` 67L + `spring.dart` 118L + 5 个 3L re-export shim = 430L
5. **provider 暴露方式**: `Provider<XRepository>(...)` 暴露 domain 接口 ✓ 100% 保持

### 高内聚现状 (5 项验证 ✓)
1. **domain 0 Flutter / 0 Drift / 0 data / 0 presentation**: `dart scripts/check_all.dart` 100% 绿
2. **data 不依赖 presentation**: 同上
3. **shared/ 至少被 2 层用**: 同上
4. **presentation provider 用 abstract**: 100% 保持
5. **4 FeatureFlag 编译期锁定**: `prod const + nullable override` 模式保持

### 低耦合现状 (4 项验证 ✓)
1. **跨 feature import 边界**: `check_cross_feature.py` 167 files 0 violation ✓
2. **feature-first 阶段 1 完整**: `check_feature_first_migration.py` 6 feature (含 R128b crisis) 100% 通过
3. **drift schema 0 破坏**: schemaVersion 24 不变, R128a~R128d 0 引入
4. **0 网络外联**: `check_no_network_io.py` + `check_release_no_network.py` 0 violation

### ✅ 优点 / 强项 (5 项)

| # | 强项 | 验证 |
|---|---|---|
| FT-A | R120 提的 6 god class 候选 4 闭环 (vent_list/medication/mood_audio -部分/趋势改) | 跨 R121~R126 9 round 治本 |
| FT-B | 5 token 集中器独立 package 干净 1701L | `packages/chroniccare_theme/` 196 caller 100% 切 |
| FT-C | crisis feature R128b 5/5 收官 0 漏 | `check_feature_first_migration.py` 6 feature ✓ |
| FT-D | HealthKit stub 骨架 + FeatureFlag 编译期锁 R128c | `FeatureFlags.healthKitEnabled=false` + 3 守门员规则 ✓ |
| FT-E | 4 layer + 5 umbrella + 6 feature + 1 package 真实文件 + 24 守门员主动拦截 | 0 架构 violation |

### ⚠️ 待优化 (6 项)

| # | 位置 | 问题 | 估时 | 优先级 |
|---|---|---|---|---|
| FT-1 | `lib/core/theme/spring.dart` 118L | 跨 8 round 0 caller 半成品, R31 提 → R108 → R117 → R120 → R128e | 2h (接 `_EntrySpring` 走 `Spring.standard.toSimulation()`) | P1 |
| FT-2 | `lib/core/theme/app_theme.dart` 245L | R128d 5 token 转 package 但 app_theme + theme_provider 留 lib, 半拆 | 1.5h (转 `chroniccare_theme` 收尾) | P1 |
| FT-3 | `packages/chroniccare_core/` + `packages/chroniccare_features_mood/` | 仅 pubspec 占位 0 lib file, 跨 R127 stage3 + R128d 2 round 0 实质, 名实不符 | 6h (迁 `lib/core/data/services` + 1 feature 完整迁移) | P1 |
| FT-4 | `lib/features/mood/.../mood_audio_recorder_widget.dart` 611L | R120 提 529L, R128e 反弹 +82L, god class 续 | 4h (拆 4 facade) | P1 |
| FT-5 | `lib/presentation/pages/home/home_page_state.dart` 430L | R120 提 506L, -76L 续拆, 仍 god class | 3h (拆 3 widget) | P2 |
| FT-6 | `lib/core/l10n/strings.dart` 298L + `lib/l10n/` 8755L+8189L+4587L | domain l10n 走 generated 路径 (跨 R128 仍 298L 难维护) | 2h (R128 续规整) | P2 |

### 🚫 红线 (0 项)
R128a~R128d 跨 4 round 0 引入红线 (schema 0 破坏 / 4 layer 0 破坏 / 守门员 0 突破 / 网络外联 0 引入)

## 跨 Lens 共识

| # | 共识 | 关联 lens |
|---|---|---|
| 1 | **spring.dart 半成品跨 8 round 0 闭环** (R31 P0-08 → R108 → R117 → R120 → R128e) | frame + flutter + emil (FT-1 = F-1) |
| 2 | **3 package 描述不实 (1 个有代码)** | frame + gdc-audit (v1.0 pub workspace 完整) |
| 3 | **5 P0 external 跨 12 round 0 闭环** | frame + gdc-audit + pull-on-shelf + 9-appstore + 10-googleplay |

## R128a~R128d 改动验证

| 改动 | 期望 | 实际 | 状态 |
|---|---|---|---|
| R128a notification umbrella | 抽 4 facade | `core/platform/notification/` 5 facade (delegate/dispatcher/initializer/scheduler/5_vendor_push) | ✅ |
| R128b crisis 5/5 收官 | 完整 feature | `lib/features/crisis/` 6 子目录 (data/domain/presentation) | ✅ |
| R128c HealthKit stub | 骨架 + FeatureFlag | `FeatureFlags.healthKitEnabled=false` + `lib/core/data/services/health_kit/` 3 stub file | ✅ |
| R128d 5 token 转 package | 完整转 `chroniccare_theme` | 5 token ✓ (1701L), 但 `app_theme.dart` 245L + `theme_provider.dart` 67L + `spring.dart` 118L 留 lib | ⚠️ 50% |
| R128d "3 package" | 3 package 实质代码 | theme ✓, core + features_mood 0 lib file | ⚠️ 名实不符 |

## R129+ 建议

1. **P1**: FT-3 补 2 package 实质 (迁 `lib/core/data/services` + mood feature 完整迁) (6h) → frame 8.5 → 9.0 (+0.5)
2. **P1**: FT-1 spring.dart 接 `_EntrySpring` (2h) → 跨 8 round 半成品闭环
3. **P1**: FT-2 R128d 收尾 (app_theme + theme_provider 转 `chroniccare_theme`) (1.5h) → 顶层架构 100% package 化
4. **P1**: FT-4 mood_audio_recorder_widget 611L 拆 4 facade (4h) → 反弹 82L 治本
5. **P2**: FT-5 home_page_state 430L 拆 3 widget (3h) → R120 续拆
6. **P2**: 24 守门员描述修正 (实际 23 .py + 1 .dart = 24, "20 + 1 + 3" 描述不实) (0.5h) → AGENTS.md 同步

**R129 frame 估时合计**: 17h, frame 估分 8.5 → 9.0 (+0.5)
