# R93 Audit Fixes — Design Spec

> **重建日期**: 2026-08-18 (从代码注释 + audit 目录推断)
> **原始 spec 已删**, 基于代码内 R93 注释推断

## 1. 背景

R93 阶段 2 是 2026-08-05 ~ 08-10 期间的多视角审计修复阶段, 重点是 PHQ-9 / GAD-7 量表 i18n 不充分, 5 厂商 push 集成未就绪, 4 外联 flag 删除。

## 2. 范围 (基于可推断修复痕迹)

### 2.1 PHQ-9 / GAD-7 量表 i18n 隐藏

**位置**: `lib/features/assessment/presentation/pages/assessment_center_page.dart:34-37, 47-49`

**修复**: 加 `FeatureFlags.phqGad7I18nEnabled` 默认 `false`, 隐藏 PHQ-9 / GAD-7 卡片
- 原因: 16 题翻译不充分 (R65b 阶段开启但完成度不足)
- 入口: 仅 admin 可开启

```dart
FeatureFlags.phqGad7I18nEnabled  // default: false
```

### 2.2 5 厂商 push flag 新增

**位置**: `lib/core/data/feature_flags.dart:53` (`_prodFiveVendorPushEnabled`)

**新增 1 个聚合 flag** (`fiveVendorPushEnabled`, 默认 `false`), 而非 5 个独立厂商 flag:
- 单一总开关: `fiveVendorPushEnabled`
- 内部封装: `FiveVendorPushService` 内部已含 5 厂商抽象 + NoOp (`lib/core/platform/notification/five_vendor_push_service.dart:316`, R124 1.1.0+170)
- 触发条件: "v1.0 真接后翻 true" (代码注释 `feature_flags.dart:92`)
- 5 厂商覆盖: 米/华/OPP/vivo/魅族 (`feature_flags.dart:50` 注释)

**为何用 1 个聚合 flag 而非 5 独立**: R93 阶段 2 计划用 5 个独立 flag, 实际实施收敛为 1 个总开关 (降低 feature flag 数量, 跟 "bootReceiverEnabled" 等单业务单 flag 模式一致)。

### 2.3 3 个外联 flag 删除 (R93 阶段 2 → 1.1.0 round 4b emotion-first refactor)

**实际删除 3 个** (非 4 个):

| 删除 flag | 业务 | 删除时机 |
|---|---|---|
| `emergencyContactEnabled` | 紧急联系人 | 1.1.0 round 4b emotion-first 闭环 |
| `aliyunSmsEnabled` | 阿里云 SMS | 同上 |
| `emailServiceEnabled` | Email Service | 同上 |

数量: 7 → 4 flag (非 8 → 4, 见 `feature_flags.dart:12-16` 注释)。

**影响**:
- `Contacts` 表 (数据库迁移 `< 23 → deleteTable('contacts')`)
- 主页 `safety check` 路径删除
- `setup_page.dart` 删 SMS/Email 验证

### 2.4 开放量表数 10 → 8

`assessment_center_page.dart:97-99` 从 10 张卡片减到 8 张, 配合 2 张 unavailable。

## 3. 实施状态

✅ 全部实施。emotion-first refactor 闭环 (1.1.0 round 4b)。

## 4. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `lib/core/data/feature_flags.dart` | — | 5+4 FeatureFlags |
| `lib/features/assessment/presentation/pages/assessment_center_page.dart` | 125 | Assessment Center (含 R93 P0#14 修复) |
| `lib/domain/logic/scale_registry.dart` | — | 10 量表注册 + 2 unavailable |
| `lib/main.dart` | — | DB migration logic (deleteTable contacts) |
| `lib/features/home/presentation/pages/home_page.dart` | — | 删 safety check 路径 |
| `lib/features/setup/presentation/pages/setup_page.dart` | — | 删 SMS/Email 验证 |
| `lib/core/routing/app_route_check_in.dart` | — | 删 reason=safety 分支 |

## 5. 关键设计决策

- **emotion-first 闭环**: 项目从"慢病管理" → "情绪日记 + 树洞倾诉优先"
- **4 外联 flag 删除**: 配套主页 safety check + setup 路径简化
- **5 厂商 push 占位**: flag 默认全 false, 5 厂商 SDK 真接待外部依赖
- **量表渐进开放**: 8 开放 + 2 unavailable + PHQ-9/GAD-7 admin-only

## 7. 关联

- emotion-first refactor: `docs/superpowers/specs/2026-08-15-emotion-first-refactor-design.md`
- Apple Health 视觉风格: `docs/design/2026-08-10-apple-health-redesign/spec.md`
- R92 audit-fixes: `docs/superpowers/specs/2026-08-06-audit-fixes-r92-design.md`

## 8. 局限

- ❌ R93 阶段 2 完整 P0/P1 清单
- ❌ 5 厂商 push 集成的具体技术选型
- ❌ PHQ-9 / GAD-7 i18n 完成度标准