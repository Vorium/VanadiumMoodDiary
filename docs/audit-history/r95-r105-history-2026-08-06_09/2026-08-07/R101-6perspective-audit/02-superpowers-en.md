# superpowers-en 架构审计报告 — R101

**审计时间**: 2026-08-07 | **总体评分**: 9.0/10

---

## P0 — Critical (3 项)

### 1. check_all.dart 守护脚本 bug — domain→core/data/ 违规静默忽略
- **文件**: `scripts/check_all.dart:231-233`
- **问题**: `_isForbiddenImport()` 只处理 `'package:chroniccare/data/'` 但规则写 `'package:chroniccare/core/data/'`，条件永远不匹配
- **修复**: 加 `if (forbidden == 'package:chroniccare/core/data/')` case

### 2. vent_repository.dart domain 导入 data 层 VentAudioStorage
- **文件**: `lib/domain/repositories/vent_repository.dart:6`
- **修复**: 删除 import，改注释引用

### 3. safety_detector.dart domain 导入 data 层 SafetyCheckKind
- **文件**: `lib/domain/logic/safety_detector.dart:49`
- **修复**: SafetyCheckKind 枚举移到 domain 层

---

## P1 — High (5 项)

| # | 问题 | 文件 |
|---|------|------|
| 4 | data 层导入 flutter/material.dart (DateTimeRange) | cbt_thought_record_pdf.dart:15 |
| 5 | SafetyCheckResult 93 行业务类型留在 data 层 | safety_watch_service.dart:320-413 |
| 6 | tz.initializeTimeZones() 双调用 | main.dart:139 + notification_service.dart:168 |
| 7 | daysBetween 三处重复实现 | reminder_scheduler + safety_config_service + safety_detector |
| 8 | SafetyConfigService 每次方法调 SharedPreferences.getInstance() | safety_config_service.dart:31-101 |

---

## P2 — Medium (12 项)

| # | 问题 | 文件 |
|---|------|------|
| 9 | 7 个 data 文件导入 l10n/app_localizations.dart | 多个 service |
| 10 | home_page_state 656 行 god class | home_page_state.dart |
| 11 | catch(e) 裸捕获 9 处 | 多个 notifier |
| 12 | swallowError release 模式完全静默 | swallow_error.dart:39 |
| 13 | VentRepositoryImpl 传 null EncryptionService | vent_providers.dart:40 |
| 14 | SafetyWatchService 仍 413 行 | safety_watch_service.dart |
| 15 | NotificationService 480 行 facade 仍大 | notification_service.dart |
| 16 | settings→assessment 跨 feature import | assessment_section.dart:10 |
| 17 | home→mood 跨 feature import | home_page_state.dart:58 |
| 18 | 6 个新 daily tracking entity 零测试 | 多个 entity 文件 |
| 19 | check_in_entity isNormal 用字符串比较 | check_in_entity.dart |
| 20 | daysBetween/isSameDay 重复未清理 | safety_config_service:109 + safety_detector:54 |

---

## P3 — Low (6 项)

21-26: main.dart 500 行多职责 / VentEntryEntity.durationLabel 硬编码中文 / EmailService 死代码 / ConsentGate shared_preferences 导入 / 无 consent flow 集成测试 / AliyunSmsProvider StateError 语义错误
