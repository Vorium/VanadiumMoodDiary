# flutter-specification 视角报告 (2026-08-09)

**评分**: 88%
**基线**: R103 (2026-08-08)

## Flutter 规范审查

### 优点
- 0 analyzer error
- 18 守门员全绿
- catch 集中器化 (swallowError)
- Token 化 102+ 处
- 集成测试 6 个
- Coverage 阈值设定

### 问题

| # | 问题 | 文件 | 难度 | 优先级 |
|---|------|------|------|--------|
| F1 | PRAGMA key SQL 注入 — password 拼接 | native.dart:27 | 简单 | P0 |
| F2 | 空 setState 每次击键整页重建 | vent_compose_page.dart:441 | 简单 | P1 |
| F3 | 100ms setState 每秒 10 次重建 | mood_audio_recorder_widget.dart:197 | 简单 | P1 |
| F4 | 硬编码 Apple 系统颜色不适应 dark mode | cbt_three_column_mode.dart:96-111 | 简单 | P1 |
| F5 | 硬编码颜色无 dark mode | mood_factor_analysis.dart:105-109 | 简单 | P1 |
| F6 | 8 新量表显示 raw ID | day_detail.dart:364-387 | 简单 | P2 |
| F7 | scale IDs 硬编码重复 | check_in_entity.dart:80-91 | 简单 | P2 |
| F8 | 4 analyzer warning | 多文件 | 简单 | P2 |
| F9 | 30 info (trailing commas) | 多文件 | 简单 | P3 |
| F10 | dead code _VentWithdrawChoice | legal_page.dart:448 | 简单 | P3 |
