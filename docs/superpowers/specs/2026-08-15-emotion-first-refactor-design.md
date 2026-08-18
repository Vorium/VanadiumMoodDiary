# Emotion-First Refactor — Design Spec

> **重建日期**: 2026-08-18 (从代码注释推断)
> **原始 spec 已删**, 基于 `pubspec.yaml` 注释 + R93 audit-fixes + 代码 R115 注释推断

## 1. 背景

1.1.0 round 6d (R115 emotion-first refactor) 起, 项目定位从"慢病管理 (chronic disease management)" 改为 **"情绪日记 + 树洞倾诉优先 (mood journal & vent-first self-care)"**, 用药记录降为辅助。这一变化涉及 14 个 commit, 跨主页 / setup / 路由 / 数据库迁移 / i18n 多处。

## 2. 目标

- 突出 mood / vent 主线 (P0 emotion-first)
- 删除 safety check / 紧急联系人 / SMS / EmailService 路径
- 简化主页 4 tab (Mood / Vent / Trend / Settings)
- 数据库清理 Contacts 表
- pubspec.yaml 描述改双语

## 3. 关键改动

### 3.1 pubspec.yaml 描述 (pubspec.yaml:3-4)

**改动前**: "慢病管理 — ChronicCare: chronic disease management app"
**改动后**:
```
情绪日记 + 树洞倾诉优先 — ChronicCare: mood journal & vent-first
self-care app for mental wellness, with medication tracking as support
```

### 3.2 主页 4 tab 简化 (R110 round 3)

**位置**: `lib/core/routing/app_shell.dart:33-63`

**改动前**: 5 tab (Mood / Vent / Trend / Medication / Settings) 或其他组合
**改动后**: 4 tab (Mood `/` / Vent `/vent` / Trend `/trend` / Settings `/settings`)

### 3.3 删除 safety check 路径

**位置**:
- `lib/features/home/presentation/pages/home_page.dart` — 删 `care engine dispatcher` / `_runSafetyCheck` / `reason=safety` deep link
- `lib/core/routing/app_route_check_in.dart:24` — 删 `reason=safety` 分支

### 3.4 数据库 Contacts 表删除

**位置**: `lib/main.dart` + `lib/core/data/database/app_database_migrations.dart`

**改动**: migration `< 23 → deleteTable('contacts')`

### 3.5 FeatureFlags 简化

**位置**: `lib/core/data/feature_flags.dart`

**改动前**: 7 flag (含 emergencyContactEnabled / aliyunSmsEnabled / emailServiceEnabled)
**改动后**: 4 flag (5 厂商 push 默认 false 仍保留)

### 3.6 setup_page.dart 简化

**位置**: `lib/features/setup/presentation/pages/setup_page.dart`

**改动**: 删 SMS 验证 + Email 验证

### 3.7 baseLocale 显式 zh

**位置**: `l10n.yaml:8`

**原因**: 显式声明避免工具链升级时互换 baseLocale

## 4. 实施状态

✅ 闭环。1.1.0 round 4b emotion-first refactor 14 commits。

## 5. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `pubspec.yaml` | 123 | 描述双语 + baseLocale 注释 |
| `l10n.yaml` | — | baseLocale: zh |
| `lib/core/routing/app_shell.dart` | 179 | 4 tab NavigationBar |
| `lib/core/routing/app_route_check_in.dart` | — | 删 safety 分支 |
| `lib/features/home/presentation/pages/home_page.dart` | — | 删 safety check |
| `lib/features/setup/presentation/pages/setup_page.dart` | — | 删 SMS/Email 验证 |
| `lib/core/data/feature_flags.dart` | — | 4 flag |
| `lib/core/data/database/app_database_migrations.dart` | — | deleteTable contacts |

## 6. 业务影响

### 保留 (主线)
- mood / vent 主入口
- trend 跨 mood/vent/daily_tracking 趋势
- 4 tab 主页

### 降级 (辅助)
- 用药管理 (medication) — 保留但不是入口
- 日常追踪 (daily_tracking) — 保留
- 心理评估 (assessment) — 保留

### 删除
- 紧急联系人功能 (Contacts 表)
- SMS 验证 (aliyunSmsEnabled flag)
- EmailService 路径 (emailServiceEnabled flag)
- safety check dispatcher

## 7. 关联

- R93 audit-fixes 4 外联 flag 删除
- R110 + R125 feature-first 重构
- Apple Health 视觉风格: `docs/design/2026-08-10-apple-health-redesign/spec.md`

## 8. 局限

- ❌ R115 14 commits 具体 commit hash
- ❌ emotion-first 重新定位的市场决策
- ❌ 商业化影响 (用药降为辅助对 revenue 的影响)