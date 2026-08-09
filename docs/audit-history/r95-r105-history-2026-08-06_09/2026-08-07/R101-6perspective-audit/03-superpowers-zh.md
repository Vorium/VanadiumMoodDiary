# superpowers-zh 审计报告 — R101

**审计时间**: 2026-08-07 | **总体评分**: 8.0/10

---

## 守护脚本验证

| 脚本 | 结果 |
|------|------|
| check_cross_feature.py | ✅ 118 files, 0 violations |
| check_arb_keys.py | ✅ zh/en/zh_Hant 各 1091 key 同步 |
| check_strings_hardcoded.py | ✅ 32 处均为 override 配对模式 |
| check_legal_consent.py | ✅ 无 TODO / 无 PIPL §13 遗漏 |
| check_orphan_arb_keys.py | ✅ 1091 key, 0 orphan |
| check_datetime_race.py | ✅ 0 处重复调用 |
| check_all.dart | ✅ 双检全过 |

---

## P0 — 阻塞发布 (1 项)

### SMS 未接入 — 核心安全功能空壳
- **文件**: `lib/core/data/services/sms_service.dart:137`
- **问题**: AliyunSmsProvider._isFullyImplemented=false, send() 抛 StateError
- **影响**: 精神心理患者连续 N 天不吃药无人知晓

---

## P1 — 影响体验/合规 (4 项)

| # | 问题 | 文件 |
|---|------|------|
| 1 | 8 个新量表硬编码中文 (ASRM/ISI/PSS/WHODAS/Level2×4) | domain/logic/asrm/isi/pss/whodas/level2_*.dart |
| 2 | care_copy.dart 关怀文案硬编码中文 | domain/logic/care_copy.dart:34-57 |
| 3 | 安全警报通知锁屏暴露敏感健康信息 | safety_alert_builder.dart:80-93 |
| 4 | 邮件通知暴露药名+剂量 (SMS 已修 R74, 邮件未同步) | email_template.dart:71-74 |

---

## P2 — 需关注 (5 项)

| # | 问题 | 文件 |
|---|------|------|
| 1 | SQLCipher PRAGMA key 字符串拼接 | connection/native.dart:27 |
| 2 | 数据导出明文暴露树洞加密内容 | data_export_service.dart:27 |
| 3 | SQLite ALTER TABLE DROP COLUMN 兼容性 | app_database.dart:338-340 |
| 4 | 通知 Channel 名称硬编码中文 | core/l10n/strings.dart:72-75 |
| 5 | PHQ-9/GAD-7 const fallback 仍是中文 | domain/logic/phq9.dart:34-39 |

---

## P3 — 技术债 (4 项)

| # | 问题 |
|---|------|
| 1 | TODO/半成品: SMS/量表/Email/IAP 空壳 (FeatureFlag=false) |
| 2 | DateTime.now() 防御性默认值 (email_template.dart:99) |
| 3 | PII 日志覆盖范围 (新开发者可能忘用 piiSafeLog) |
| 4 | 中国节假日模块硬编码中文 (不直接展示) |

---

## 业务逻辑完整性

- **失联检测**: ✅ 完备 (8 种 early-return + sealed class)
- **连续打卡**: ✅ 完备 (36h 阈值 + 显式排序)
- **评估量表**: ⚠️ 基本正确但 8 个新量表缺 i18n
- **安全信号**: ✅ 覆盖全面 (8 类判定 + 5s timeout)

## 中国法规合规

- 隐私政策 ✅ / 用户协议 ✅ / PIPL §13 ✅ / PIPL §14 ✅ / PIPL §28 ✅ / PIPL §31 ✅
- 短信确认流程 ⚠️ 待 SMS 接入
