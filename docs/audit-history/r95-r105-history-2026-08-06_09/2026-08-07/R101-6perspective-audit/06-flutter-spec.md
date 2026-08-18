# flutter-specification 审计报告 — R101

**审计时间**: 2026-08-07 | **合规率**: 88%

---

## P0 — 严重问题 (3 项)

### 1. dart format 149 文件不一致
- **描述**: `dart format --output=none --set-exit-if-changed .` 报告 149 个文件格式不一致
- **修复**: `dart fix --apply && dart format .`

### 2. shared_providers.dart 反向 import (providers → pages)
- **文件**: `lib/presentation/providers/shared_providers.dart:1`
- **问题**: import pages/medication/today_med_schedule.dart
- **修复**: TodayMedSchedule 移到 widgets/

### 3. check_in_entity.dart labelL10n 硬编码中文 fallback
- **文件**: `lib/domain/entities/check_in_entity.dart:116-137`
- **修复**: 默认 fallback 改英文或 key

---

## P1 — 重要问题 (7 项)

| # | 问题 | 文件 |
|---|------|------|
| 4 | var 使用不一致 24 处 | 多处 |
| 5 | LoadingScrim 返回 Positioned.fill 但非 Stack 子级未定义 | loading_skeleton.dart:139 |
| 6 | home_page_state 590 行仍偏大 | home_page_state.dart |
| 7 | app_tokens.dart 306 行纯转发过重 | app_tokens.dart |
| 8 | check_in_dao.dart DAO 层调 DateTime.now() | check_in_dao.dart:62 |
| 9 | native.dart SQL 注入风险 (PRAGMA key 字符串拼接) | native.dart:27 |
| 10 | pubspec_overrides.yaml 未确认 gitignore | 根目录 |

---

## P2 — 改进建议 (7 项)

| # | 问题 |
|---|------|
| 11 | 部分 ListView 未使用 .builder (数据量小时可接受) |
| 12 | 8 个新量表 labelL10n 硬编码 fallback |
| 13 | NotificationService 构造函数初始化 6 个 sub-service |
| 14 | streakSummaryProvider 内 DateTime.now() 未 watch dayChangeTickProvider |
| 15 | todayProvider 返回 DateTime.now() 非 tz.TZDateTime |
| 16 | .g.dart 8557 行已 commit (确认 CI 步骤) |
| 17 | AppTokens 中 4 size 常量未放 AppSpacing |

---

## P3 — 低优先级 (5 项)

18-22: press_feedback Listener vs GestureDetector / EncryptionService 单例测试 / NavigationRail 2 目的地 / check_in_entity isAssessment Set.contains / LoadingShimmer AnimatedBuilder vs AnimatedWidget

---

## 亮点

| 指标 | 状态 |
|------|------|
| flutter analyze | ✅ No issues found |
| 4 层架构纯度 | ✅ domain 0 flutter import |
| Riverpod 规范 | ✅ Provider scoping + autoDispose + family |
| Drift 迁移 | ✅ 19 版本 migration 全覆盖 |
| 测试覆盖 | ✅ 2019+ cases, 18 守门员 |
| 安全设计 | ✅ SQLCipher + AES-256 + FlutterSecureStorage |
| 错误处理 | ✅ runZonedGuarded + LastErrorCapture + swallowError |
