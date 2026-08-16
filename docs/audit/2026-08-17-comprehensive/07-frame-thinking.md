# Lens 7: frame-thinking (7 cognitive frameworks 顶层架构审视)

**Date**: 2026-08-17
**Scope**: 7 认知框架 (First Principles / Contradiction / Protracted War 等) + 顶层架构可重构模块
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**8.0/10** (持平 R31 顶层架构, R116 4 rounds 拆解后明显改善)

## 7 框架逐项打分

### 1. First Principles (第一性原理) — 8/10
- **核心问题**: 项目核心目的 (情绪优先精神心理自我关怀) 是否每层架构都服务?
- **现状**: 4 层 (data/domain/presentation) + 5 umbrella (core) 都服务 emotion-first
- **gap**: `setup_page_state` 513L 仍是 god class, 4 步 setup 串行耦合 (R108 §六 候选)

### 2. Contradiction (矛盾论) — 7/10
- **核心矛盾**: emotion-first (轻) vs medication/assessment (重) 视觉权重
- **现状**: R115 batch 1 已弱化 medication/assessment (从 2x2 tile → 1 个 "更多" entry)
- **gap**: medication_page 仍 281L, 主页 entry 弱但子 page 重, 路径有断点

### 3. Protracted War (持久战) — 9/10
- **战略**: emotion-first + 零外联 (1.1.0 round 4b 删除) 是正确长期方向
- **战术**: 27 守门员 + 4 FeatureFlag 编译期锁定 + 100% 本地
- **gap**: HealthKit / 5 厂商 push / SMS 是 v1.0 长期, 0 启动无压

### 4. 第一 / 第二 / 第三 矛盾优先级 — 8/10
- **第一**: 业务完整性 (4 半成品 Z-11~Z-14)
- **第二**: 架构 (god class 6 个待拆)
- **第三**: 文档 (EN 摘要 4 个, 半成品待清)
- **现状**: R116 已拆 4 个, R117 继续拆

### 5. 主动 vs 被动 (initiative) — 8/10
- **主动**: 27 守门员主动拦截 100+ 类违规
- **被动**: 上架硬阻塞 7 个等外部资源
- **gap**: 主动权 90%, 被动等待 10% (合理)

### 6. 量变 → 质变 — 9/10
- **量**: 1340 ARB key + 2515 test + 27 守门员 + 11 god class 拆 4
- **质**: emotion-first 重构完成 + 0 外联 + 100% 本地加密
- **gap**: R117 量到质 1-2 步 (spring 接入 / god class 续拆 / EN 摘要)

### 7. 实践 → 认识 → 再实践 — 9/10
- **R108 → R111 → R113 → R114 → R115 → R116**: 6 轮迭代, 每轮都修正前轮问题
- **R115 batch 2 privacy hardening**: 实践发现 5 个隐私风险 → 认识 → 5 守门员
- **gap**: R117 待 R116 round 4 实践 (清 9 orphan) → 认识 (lock-in 同步) → 再实践

## 顶层架构审视 (高内聚低耦合)

### 当前架构 4 层
```
lib/
├── core/                # 基础设施 umbrella
│   ├── data/            # data 层
│   ├── shared/          # 跨层共享
│   ├── theme/           # 主题
│   ├── routing/         # 路由
│   └── l10n/            # domain 层 strings
├── domain/              # 0 Flutter 0 Drift
│   ├── entities/
│   ├── logic/
│   ├── repositories/
│   └── usecases/
└── presentation/        # UI 层
    ├── providers/
    ├── pages/           # 1 page = 1 dir
    └── widgets/
```

### 高内聚现状 (5 项)
1. **domain 0 Flutter / 0 Drift**: `check_all.dart` 守门员强约束
2. **data 不依赖 presentation**: 守门员已验
3. **shared/ 至少被 2 层用**: 守门员已验
4. **presentation provider 用 abstract 暴露**: XRepository (domain 接口), 不暴露 impl
5. **4 FeatureFlag 编译期锁定**: prod const + nullable override 模式

### 低耦合现状 (4 项)
1. **跨 feature import 边界**: `check_cross_feature.py` 守门员禁止 pages/{A} import pages/{B}
2. **route 表稳定**: R115+ 0 改路由 (无 data migration 风险)
3. **4 mapper (row ↔ entity) 集中**: data/database/*_mapper.dart
4. **widget 集中器**: PrimaryButton / PressFeedbackIconButton / AppleListSection 等

### ⚠️ 可重构模块 (3 项)

| # | 模块 | 现状 | 建议 | 优先级 |
|---|---|---|---|---|
| FT-1 | `lib/l10n/app_localizations*.dart` | 8755L+8189L+4587L generated | 不重构 (auto-generated), 但 ARB 模板 1328→1340 维护 | - |
| FT-2 | `lib/core/data/database/app_database.dart` | 564L (god class 候选) | 拆 4 文件 (tables / migrations / DAOs / connection) | P1 |
| FT-3 | `lib/domain/entities/scale_translations/static_scale_translations.dart` | 785L (12 量表 inline) | 拆 12 子文件 + 1 index | P2 |

### 跨周期顶层架构结论

- **R110+ feature-first 重构** (2-3 周): `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package → 9.0/10
- **R109 god class 续拆** (1-2 月): 6 个 god class 拆 + use case 层厚化 (8 usecase) → 9.0/10
- **v1.0 (2027-Q1)**: pub workspace + 5 厂商 push + AliyunSms + EmailService + HealthKit + 鸿蒙 + IAP → 9.5/10

## 跨 Lens 共识

- **跟 emil / superpowers**: 顶层架构服务 emotion-first 一致
- **跟 gdc-audit**: 鸿蒙 + desktop 0 启动是 v1.0 长期
- **跟 pull-on-shelf**: 7 P0 跨期残留 = 第一矛盾优先级

## 下轮建议 (R117 frame focus)

1. **P1**: FT-2 app_database 拆 4 文件 (4h)
2. **P2**: FT-3 scale_translations 拆 12 子文件 (3h)
3. **P2**: setup_page_state 拆 (R108 §六 候选) (3h)
