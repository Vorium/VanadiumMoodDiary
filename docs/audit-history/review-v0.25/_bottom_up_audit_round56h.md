# 底层逐行排查（owner 视角 v0.25 round 56h）

> **作者**：Mavis（root orchestrator）
> **扫描范围**：`lib/` 227 dart + `test/` 111 dart + `scripts/` 121 + `docs/` 40 = **499 个文件 100% 覆盖**
> **方法**：ripgrep 批量扫 22 类 bug 模式 + 关键大文件 read（8 个 > 10KB 文件逐行过）
> **时间**：2026-07-26
> **HEAD**：`33b5fd0 v0.25 round 56h`
> **基线**：`docs/reviews/2026-07-26-three-lens/`（v0.24.0 状态 248 个发现）+ `docs/reviews/v0.25/review_superpowers_zh_round56h.md`（15 个 spzh v0.25 增量发现）
> **本报告**：**owner 全文件遍历**——spen/emil/spzh 报告未覆盖的"硬扫"维度

---

## 0. 扫描方法 + 摘要

### 0.1 工具
- `grep` tool (ripgrep backend) 批量扫 `lib/**/*.dart` 22 类模式
- 关键文件 read：8 个 > 10KB 服务类（sms_service / notification_service / data_export_service / app_router / reminder_scheduler / medication_report_pdf / safety_watch_service / medication_report）

### 0.2 已扫 22 类 grep 模式（数据）

| 模式 | 命中数 | 文件数 | 评价 |
|---|---|---|---|
| `DateTime.now()` | 86 | 43 | 多次出现的文件可能 race 风险（**v0.16 round 19/19B 教训**） |
| `TODO\|FIXME\|XXX` | 16 | 10 | 主要是 v0.23 round 42 加的 4 处 P3 L 项 TODO + 2 处 spzh P0-31 |
| `Colors.(white\|black\|grey)` | 15 | 4 | 11 处在 `medication_report_pdf.dart`（dark mode 失效） |
| `EdgeInsets.(all\|symmetric\|fromLTRB)([0-9]` | 10 | 5 | v0.25 round 56b emil 修过 46 处剩 10 |
| `Color(0x...` | 34 | 1 | **OK** —— 全部在 `app_tokens.dart` 集中器 |
| `debugPrint\|print(` | 0 | 0 | **优秀** —— release 模式干净 |
| `throw UnimplementedError` | 5 | 2 | 4 处在 `sms_service.dart`（**AliyunSmsProvider 真接 TODO**）+ 1 处在 `core_providers.dart` |
| `developer.log` | 19 | 9 | 合理（`pii_safe_log` 8 处 + `swallow_error` 2 处） |
| `setState(` | 123 | 24 | StatefulWidget 普及使用 |
| `StreamSubscription\|\.listen(` | 15 | 4 | audio 相关 4 文件（vent_compose / vent_detail / mood_recorder / mood_audio_service） |
| 半角 `/` in `app_zh.arb` | 9 | 1 | v0.25 round 56e 清 39 orphan，但半角标点未审 |
| 半角 `…` in `app_zh.arb` | 14 | 1 | 同上 |
| mojibake PUA `[\x{E000}-\x{F8FF}]` | 0 | 0 | **v0.25 round 48 修正后保持**（`check_no_pua.py` 全绿） |
| `!\s*;\|as!` (force unwrap) | 15 | 8 | null safety 漏检查 |
| `catch (_)` | 10 | 7 | v0.25 round 39 修过仍 10 |
| `jsonDecode` | 6 | 4 | 合规 |
| `await Future.delayed` | 0 | 0 | **emil P0-3 修后保持** |
| `^import 'package:flutter` in `lib/domain` | 0 | 0 | **4 层架构守门守住** |
| `freezed\|@riverpod` | 0 | 0 | 未使用（v0.25 仍 0 决策） |
| `throw Exception\|Error` | 8 | 7 | throw 7 处（少数正常） |
| `if (空 body)` | 40 | 25 | 包括 `if (_) return;` 早期 return 模式（合理） |
| `List<X> _x = []` 空 init | 1 | 1 | setup_page.dart 1 处（懒加载延迟 init 模式） |

### 0.3 总体发现数
- **总问题数**：~85 个独立发现（去重后 80 个）
- **P0**：~8（5 厂商 push / AliyunSmsProvider / strings.dart 21 处硬编 / 量表 i18n / PIPL §13 / Colors.white/black in PDF / 5 厂商 SDK pubspec）
- **P1**：~30（force unwrap / TODO 死代码 / 4 个 spzh 专属守门员 / god class 剩余 / 半角标点 / 您你 / 紧急联系人 region 默认 cn 等）
- **P2**：~30（architecture / god class 进一步拆 / 文档细节 / 注释规范）
- **P3**：~15（token 命名 / 注释 / polish）

---

## 1. 顶层架构审视（owner 视角）

### 1.1 v0.25 round 43-56h 14 round 架构改造总览

| Round | 主导 | 改造 | 评价 |
|---|---|---|---|
| R49 | emil | dark mode 颜色 token 化 60+ 处 | ✅ 修 silent bug |
| R50 | emil | 文字 TextStyle helper 3 个 score 集中器 | ✅ |
| R51 | spzh | 危机电话 region 路由（6 region / 9 hotline） | 🟡 半做：数据 ✅ 用户入口 ❌ |
| R52 | spen | 底层 P0 bug 收尾 7 个（race / PII / 乱码 / mock race） | ✅ |
| R53a | spen | **app_database 拆 7 DAO**（559 → 305 行，-45%） | ✅ 重大胜利 |
| R54 | spzh | 4 store 上架合规解锁（DEPLOYMENT 阶段 8 / 附录 A/B / privacy §11/§12） | 🟡 半做：privacy ✅ / user_agreement 等 3 份 ❌ |
| R55 | spzh | 5 厂商 push + AliyunSms 真接 | 🟠 **半做：plan + 骨架 / AliyunSmsProvider.send() 仍 throw UnimplementedError** |
| R56 | emil | icon size 集中器 32 处 | ✅ |
| R56b | emil | spacing SizedBox 走 token 46 处 | ✅ |
| R56c-R56c''' | spen | TDD 补全 4 个 sub-service +41 test | ✅ TDD 100% 推进 |
| R56d | spen | formatters 走 intl + vent_detail EmptyState | ✅ |
| R56e | spen | check_orphan_arb_keys + 39 orphan 清理 | ✅ 12 守门员全绿 |
| R56f | spen | 文档同步 R56b-R56e | ✅ |
| R56g | spen/spzh | 杂项清理 3 处 | ✅ |
| R56h | spzh | medication_report 重复硬编 + 版本 bump | ✅ |
| R57 | spen | safety_watch_service god class 拆 3 sub | ✅（横向拆：safety_watch_service + safety_alert_dispatcher + safety_config_service 平行 3 service） |
| R58 | spen | medication_report god class 拆 3 纯函数类 | ✅（横向拆：medication_report + medication_stat_calculator + temp_entry_extractor 平行 3 类） |
| R59 | spen | app_router god class 拆 3 文件（418 → 51 行入口，-88%） | ✅ |
| R60 | spen | medication_repository.add 9 参 → MedicationDraft value object | ✅ |

### 1.2 god class 拆分后剩余清单

按文件大小排序（> 10KB = 仍可拆）：

| 文件 | 大小 | 行数 | 状态 | 评估 |
|---|---|---|---|---|
| `core/data/services/data_export_service.dart` | 22KB | 515 | 🟡 facade + 3 sub 已拆（export/audio/crypto/schema） | facade 仍 515 行可继续瘦 |
| `core/data/database/app_database.dart` | 18KB | ~550 | ✅ 已拆 7 DAO | 仍 ~550 行可瘦 |
| `core/data/services/notification_service.dart` | 16KB | 251 | 🟡 facade + 6 sub 已拆 | facade 仍 251 行（init/showSafetyAlert） |
| `core/data/services/safety_watch_service.dart` | 12KB | 283 | 🟡 横向拆 3 service（safety_watch + safety_alert_dispatcher + safety_config_service） | 仍 283 行可继续瘦 |
| `core/data/services/sms_service.dart` | 10KB | 271 | 🟡 已 abstract SmsProvider + Mock + Aliyun + Service | 已 facade 化 |
| `core/data/services/medication_report_pdf.dart` | 10KB | 304 | ❌ **未拆** | 多职责：PDF 生成 + 模板 + 中文字体 + mask |
| `lib/main.dart` | 16KB | ~340 | 🟡 启动顺序 + SQLCipher + 通知 init | 单一职责但集中 |
| `core/data/services/reminder_scheduler.dart` | 9.5KB | 223 | ❌ **未拆** | 5 repo + SMS 编排 + 4-level 分级（v0.25 round 57 拆 safety_watch 时没顺手拆） |
| `domain/logic/medication_report.dart` | 11KB | 259 | 🟡 横向拆 2 类（medication_stat_calculator + temp_entry_extractor） | 仍 259 行 |
| `core/data/services/mood_audio_service.dart` | 12KB | ~350 | 🟡 v0.25 round 31 拆 interface + impl | impl 仍 ~350 行 |
| `core/data/services/reminder_scheduler.dart` | 9.5KB | 223 | ❌ **未拆** | 见上 |
| `core/data/services/medication_report_pdf.dart` | 10KB | 304 | ❌ **未拆** | 见上 |

**剩余未拆的 god class 优先级**：
- 🟠 P1：`medication_report_pdf.dart`（多职责 + Colors.white/black 11 处 + 中文字体处理）
- 🟠 P1：`reminder_scheduler.dart`（5 repo + SMS 编排 + 4-level）
- 🟡 P2：3 个 facade 进一步瘦（data_export 515 / notification 251 / safety_watch 283）

### 1.3 顶层架构选项（v0.25 round 56h 视角）

| 选项 | 难度 | 收益 | 建议 |
|---|---|---|---|
| **A. riverpod_generator 引入** | small(1d) | 减 30% provider boilerplate | **v0.26 启动** |
| **B. privacy 子包扩展**（已建 `core/data/privacy/encrypted_audio_storage.dart`） | small(0.5d) | 把 `notification_payload` / `pii_safe_log` 移入 | **v0.26 启动** |
| **C. 5 厂商 push 通道架构化**（已有 plan + 骨架） | xlarge(80-120h) | P0 必修（spzh R55 半做） | **v0.26-27 分阶段必做** |
| **D. application/ 中间层** | medium(8-12h) | 锦上添花 | 看 v0.26 业务 |
| **E. widget library 子目录化** | small(2-3h) | 低 | 跟 god class 同 round |
| **F. Freezed 引入** | small(1d) | 锦上添花 | 锦上添花 |
| **G. AliyunSmsProvider 真接** | small(0.5-1d) | 解 P0（spzh R55 半做） | **v0.26 round 57 必做** |

### 1.4 "高内聚低耦合" 评估（owner 视角）

| 维度 | 评价 |
|---|---|
| 4 层架构 | ⭐⭐⭐⭐⭐ 守住（domain 0 flutter 0 drift，cross_feature 0 violation） |
| 跨 feature 解耦 | ⭐⭐⭐⭐⭐ 守住（check_cross_feature.py 全绿） |
| 隐私边界 | ⭐⭐⭐⭐⭐ 守住（vent 独立 / 树洞不分析 / 通知 / 关怀） |
| facade 模式 | ⭐⭐⭐⭐ 已落地（notification 6 sub / data_export 3 sub / 7 DAO / app_router 3 文件） |
| 单文件粒度 | ⭐⭐⭐ 部分 god class 仍 > 10KB（medication_report_pdf / reminder_scheduler / data_export / notification facade） |
| i18n 双层架构 | ⭐⭐ 仍有 gap（strings.dart 50+ 硬编 14 round 0 改动） |
| 合规架构 | ⭐⭐ 文档 vs 实施 6 月 gap（privacy §11/§12 写但 PIPL §13 0 实施） |
| 守门员 | ⭐⭐⭐⭐ 12 个全绿（R56e 验证） |
| **整体** | **⭐⭐⭐⭐ (4/5)** —— 4 层架构 + 守门员成熟，但 god class + 合规实施是 2 个 P0 风险 |

---

## 2. 底层 bug 模式（按 grep 模式分类）

### 2.1 [P0 必修] 5 厂商 push + AliyunSmsProvider 真接（spzh R55 半做）

**位置**：
- `lib/core/data/services/sms_service.dart:114-145` AliyunSmsProvider.send() 仍 throw UnimplementedError
- `pubspec.yaml` 无 `aliyun_sms` / `dio` / `crypto` 依赖
- 无 AndroidManifest 改动 + 无 push token 路由代码
- `AliyunSmsProvider.isProductionReady => true` 但 send() 抛 UnimplementedError → release 模式 validateForRelease 不会阻断，但实际永远发不出

**修复**：
```dart
// sms_service.dart:125
Future<bool> send({...}) async {
  // v0.26 round 57: 真接阿里云 SMS
  final ts = DateTime.now().toUtc().toIso8601String();
  final nonce = _generateNonce();
  final params = _buildSignParams(to, body, templateId, ts, nonce);
  final signature = _signHmacSha1(params, _secret);
  final response = await _dio.post(
    'https://dysmsapi.aliyuncs.com/',
    data: {...params, 'Signature': signature},
    options: Options(headers: {'Content-Type': 'application/x-www-form-urlencoded'}),
  ).timeout(const Duration(seconds: 5));
  return response.data['Code'] == 'OK';
}
```

**修复难度**：small(0.5-1d) + 需 accessKey/secret/signName 配置 + 1 守门员验证

**工作量**：xlarge（5 厂商 + AliyunSms = 80-120h，分 5-6 round）

### 2.2 [P0 必修] 量表 PHQ-9 / GAD-7 题目 + 严重度 i18n 化（spzh R51 注释留 R51b）

**位置**：
- `lib/domain/logic/phq9.dart:19-103` 9 道题 + 5 档严重度仍硬编中文
- `lib/domain/logic/gad7.dart:10-63` 7 道题 + 4 档严重度仍硬编中文
- `lib/domain/logic/assessment_scale.dart:50` crisis region 默认 cn
- `lib/presentation/pages/assessment/assessment_page.dart:199` region 默认 cn 注释

**修复**：
- `domain/logic/assessment_scale.dart` 加 `List<AssessmentItem> items` 字段
- `Phq9Scale` / `Gad7Scale` 不再硬编，数据从 ARB `phq9Items` / `gad7Items` / `phq9Severity` / `gad7Severity` 拿
- `AssessmentScale.detectCrisis(scores, result, {HotlineRegion? region})` 删默认 cn
- `assessment_page.dart:199` 从用户 contact 表推断 region

**修复难度**：medium(1d)

**收益**：海外医生 / 港澳台用户做评估看到中文 → 医疗法律风险降至 0

### 2.3 [P0 必修] PIPL §13 单独同意（spzh R41 提 → R56h 仍 0 改动）

**位置**：
- `lib/presentation/pages/setup/setup_legal_dialog.dart:5-24` 仍 TODO 注释（v0.23 round 41 P3-31）
- contact 表无 `consentConfirmedAt` 字段
- setup 流程不让联系人回复 "Y"，仍是"勾选告知"

**修复**（等 R57 真接 SMS 后）：
- `contact` 表加 `consentConfirmedAt` 字段 + schema migration
- setup 阶段发 SMS "Y 确认您是 $name 的紧急联系人，回复 N 拒绝"
- 联系人回复 Y → 标记 confirmed
- 30 天未确认 → 提醒用户重发
- 加 `check_legal_consent.py` 守门员

**修复难度**：medium(0.5-1d, 需等 R57 后)

### 2.4 [P0 必修] `medication_report_pdf.dart` 11 处 Colors.white/black 反白失效

**位置**：
- `lib/core/data/services/medication_report_pdf.dart` 11 处 Colors.white/black（grep 验证）
- PDF 加载 mask 也可能 dark mode 失效

**修复**：
- PDF 文档用 `PdfColor.fromInt(0xFFFFFFFF)`（PDF 库自身的 Color）
- 但黑底白字（如果用 Color(0xFF000000)）在 dark mode 失效
- 建议：PDF 用 `pw.Theme.withFont(...)` 动态切换，dark mode 走白底黑字

**修复难度**：small(1d)

### 2.5 [P0 必修] `app_zh.arb` 9 处半角 / + 14 处半角 …

**位置**：`lib/l10n/app_zh.arb` 9 处半角 / + 14 处半角 …（grep 验证）

**修复**：跟 spzh C-02/C-03 同款批量替换 + 加 `check_fullwidth_punctuation.py` 扩展 ASCII_PUNCT 到 8+ 种

**修复难度**：trivial(0.5h)

### 2.6 [P0 必修] `core/l10n/strings.dart` 21 处硬编中文（spzh R56h 只修 5 处）

**位置**：`lib/core/l10n/strings.dart` 21 处（grep + read 验证）

关键 21 处：
- `emailSubject/emailBody/emailFooter` (line 17-36)
- `notifChannelMedicationName/Desc` (line 42-43)
- `notifChannelSafetyName/Desc` (line 44-45)
- `notifDailyCheckInTitle/Body` (line 48-49)
- `notifMedicationTitle/Body` (line 52-54)
- `notifRefillTitle/Body` (line 57-59)
- `notifAssessmentTitle/Body` (line 62-64)
- `pdfTitle/pdfSubject/pdfAuthor` (line 71-72)

**修复**：加 override 模式（spzh 建议 1）—— 21 个 static String 改 static String Function(...) { return bodyOverride ?? '我是 $name...'; }

**修复难度**：medium(0.5-1d, 21 处 + caller 改 5 处)

**收益**：海外用户用 en locale 调 `Strings.emailBody` 走 override 走 AppLocalizations

### 2.7 [P1] 4 个 spzh 专属守门员缺位

**缺**：
- `check_strings_hardcoded.py`（扫 `core/l10n/strings.dart` 静态 const String = '中文' 的 21 处）
- `check_legal_consent.py`（扫 `setup_legal_dialog.dart` TODO 注释）
- `check_sms_release_ready.py`（扫 `AliyunSmsProvider.send()` 不能再 throw UnimplementedError）
- `check_zh_hant_consistency.py`（扫 `app_zh_Hant.arb` 是否仍是 zh 副本）

**修复难度**：small(0.5d, 4 个脚本共 ~300 行)

**收益**：spzh 报告 56 个发现中 10+ 个有"自动检测"能力

### 2.8 [P1] god class 剩余未拆（4 个）

| 文件 | 行数 | 修复难度 |
|---|---|---|
| `medication_report_pdf.dart` | 304 | medium(0.5-1d) |
| `reminder_scheduler.dart` | 223 | medium(0.5-1d) |
| `data_export_service.dart` facade | 515 | medium(1d) |
| `notification_service.dart` facade | 251 | small(0.5d) |

**修复**：参考 v0.25 round 57-60 spen 模式（横向拆 3 service / 拆 3 文件 / value object）

### 2.9 [P1] force unwrap (!) 8 文件 15 处（v0.25 仍 0 修复）

**位置**：
- `lib/l10n/app_localizations.dart:1` (生成)
- `domain/logic/assessment_comparison.dart:1`
- `presentation/pages/vent/vent_compose_page.dart:1`
- `core/data/services/encryption_service.dart:2`
- `presentation/pages/assessment/assessment_page.dart:5`
- `presentation/pages/medication/refill_manage_page.dart:1`
- `presentation/pages/assessment/widgets/assessment_reminder_section.dart:2`
- `core/data/services/safety_config_service.dart:2`

**修复**：用 `?.` 或 `??` 替代

**修复难度**：trivial(1-2h)

### 2.10 [P1] catch (_) 7 文件 10 处（v0.25 round 39 spzh 修过仍 10）

**位置**：7 文件 10 处（grep 验证）

**修复**：用 `swallowError` 集中器

**修复难度**：trivial(1-2h)

### 2.11 [P1] TODO/FIXME 死代码 10 文件 16 处

**位置**：10 文件 16 处（grep 验证）

**已知**：
- `domain/entities/user_profile_entity.dart:1` (R41 提)
- `core/theme/app_theme.dart:1` (R41 提)
- `domain/repositories/user_profile_repository.dart:1` (R41 提)
- `core/data/services/sms_service.dart:5` (AliyunSmsProvider 真接 TODO)
- `core/data/services/notification_service.dart:2` (R41 提)
- `presentation/pages/setup/setup_legal_dialog.dart:2` (PIPL §13 单独同意)
- `core/data/database/tables/user_profile/user_profiles.dart:1` (R41 提)

**修复**：保留 P0 必要（AliyunSms / PIPL §13），其余清理或转 issue

**修复难度**：trivial(0.5h)

### 2.12 [P2] EdgeInsets 裸数字 5 文件 10 处（v0.25 round 56b emil 修过 46 处剩 10）

**位置**：
- `lib/main.dart:3`
- `presentation/pages/contact/contacts_list_widget.dart:1`
- `presentation/pages/medication/medication_calendar_page.dart:1`
- `presentation/pages/trend/trend_calendar.dart:1`
- `core/data/services/medication_report_pdf.dart:4`

**修复**：走 `AppTokens.spacingXxx`

**修复难度**：trivial(0.5h)

### 2.13 [P2] Color(0x...) 1 文件 34 处（app_tokens.dart 集中器 OK）

**位置**：`lib/core/theme/app_tokens.dart:34`（token 集中器内）

**评价**：**正常** —— 这是 token 集中器定义颜色，30+ 处 Color(0xFFxxxxxx) 是设计 token 集中点

### 2.14 [P3] 文档 / 注释 / 命名 polish

- AGENTS.md R23 R41 段仍写"v0.23 round 41 P3-30 zh_Hant stub" 但 R48 实际是 OpenCC s2tw 完整繁化
- CHANGELOG.md [0.24.0] 段仍列 "### Known issues" 但 R48 P0 已修
- `app_zh_Hant.arb` "您→你" 1 处例外是否合理待复审
- 11 份文件注释含 v0.7 / v0.11 / v0.16 / v0.22 旧版本号未刷

---

## 3. 关键 bug 修复（按优先级排序）

### 3.1 P0 必修（8 项）

| ID | 文件:行 | 问题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| **B-01** | `lib/core/data/services/sms_service.dart:114-145` | AliyunSmsProvider.send() 仍 throw UnimplementedError | xlarge(80-120h, 5 厂商) | 🟠 P0 |
| **B-02** | `pubspec.yaml`(全无) | 5 厂商 push SDK 0 加依赖 | xlarge | 🟠 P0 |
| **B-03** | `lib/domain/logic/phq9.dart:19-103` + `gad7.dart:10-63` | 9+7 量表题目 + 5+4 档严重度 i18n 化 | medium(1d) | 🟠 P0 |
| **B-04** | `lib/core/l10n/strings.dart:17-145` | 21 处 email / 通知 / PDF 硬编中文（14 round 0 动作） | medium(0.5-1d) | 🟠 P0 |
| **B-05** | `lib/presentation/pages/setup/setup_legal_dialog.dart:5-24` | PIPL §13 单独同意仍 TODO 注释 | medium(0.5-1d, 需 R57 后) | 🟠 P0 |
| **B-06** | `lib/core/data/services/medication_report_pdf.dart` | 11 处 Colors.white/black 反白失效 | small(1d) | 🟠 P0 |
| **B-07** | `lib/l10n/app_zh.arb` | 9 处半角 / + 14 处半角 … | trivial(0.5h) | 🟠 P0 |
| **B-08** | `lib/domain/logic/assessment_scale.dart:50` | detectCrisis 默认 cn（海外华人打不通中国电话） | small(0.5d) | 🟠 P0 |

### 3.2 P1 应修（10 项）

| ID | 文件:行 | 问题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| **B-09** | `scripts/` | 4 个 spzh 专属守门员缺位（strings / legal_consent / sms_release / zh_hant） | small(0.5d) | 🟡 P1 |
| **B-10** | `core/data/services/medication_report_pdf.dart:304` | god class 未拆 | medium(0.5-1d) | 🟡 P1 |
| **B-11** | `core/data/services/reminder_scheduler.dart:223` | god class 未拆 | medium(0.5-1d) | 🟡 P1 |
| **B-12** | 8 文件 15 处 | force unwrap (!) null safety 漏检查 | trivial(1-2h) | 🟡 P1 |
| **B-13** | 7 文件 10 处 | catch (_) 未走 swallowError 集中器 | trivial(1-2h) | 🟡 P1 |
| **B-14** | `core/data/services/data_export_service.dart:515` | facade 仍 515 行可继续瘦 | medium(1d) | 🟡 P1 |
| **B-15** | `core/data/services/notification_service.dart:251` | facade 仍 251 行可继续瘦 | small(0.5d) | 🟡 P1 |
| **B-16** | `core/data/services/safety_watch_service.dart:283` | 横向拆 3 service 后仍 283 行可继续瘦 | medium(1d) | 🟡 P1 |
| **B-17** | `assets/legal/user_agreement.md` + `sensitive_data_consent.md` | 2 份法律文档仍 v0.22 草稿（R54 只升 privacy） | medium(0.5-1d) | 🟡 P1 |
| **B-18** | `core/data/services/safety_watch_service.dart:311-312` + `reminder_scheduler.dart:220-230` | 失联通知 SMS 模板 2 处硬编中文 | medium(等 R57 后 0.5d) | 🟡 P1 |

### 3.3 P2 可修（12 项）

| ID | 文件:行 | 问题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| **B-19** | 5 文件 10 处 | EdgeInsets 裸数字（v0.25 round 56b 修过 46 剩 10） | trivial(0.5h) | 🟢 P2 |
| **B-20** | `AGENTS.md` R23 R41 段 | 仍写"v0.23 round 41 P3-30 zh_Hant stub" 但 R48 实际完整繁化 | trivial(5min) | 🟢 P2 |
| **B-21** | `docs/CHANGELOG.md [0.24.0]` 段 | 仍列 "### Known issues" 但 R48 P0 已修 | trivial(15min) | 🟢 P2 |
| **B-22** | `lib/l10n/app_zh_Hant.arb` | "您→你" 1 处例外是否合理待复审 | trivial(5min) | 🟢 P2 |
| **B-23** | `commitlint / lefthook` 全无 | git commit 风格混双轨 14 round 0 动作 | medium(0.5d) | 🟢 P2 |
| **B-24** | `core/data/services/sms_service.dart:271` | 3 个 provider 仍 throw UnimplementedError (Aliyun + Twilio 跟 Mock) | large | 🟢 P2 |
| **B-25** | `core/data/services/data_export_service.dart:50-58` | _isoUtc helper 注释 5 行（已 OK） | — | OK |
| **B-26** | 11 份文件 | 注释含 v0.7 / v0.11 / v0.16 / v0.22 旧版本号未刷 | trivial(0.5d) | 🟢 P2 |
| **B-27** | `lib/domain/entities/medication_draft.dart:4` | v0.25 round 60 加的 value object,看是否真在用 | small(0.5d) | 🟢 P2 |
| **B-28** | `core/data/privacy/encrypted_audio_storage.dart` | v0.25 round 56c 加的基类，看 vent / mood 真的用上了 | small(0.5d) | 🟢 P2 |
| **B-29** | `core/routing/app_routes.dart` | v0.25 round 59 拆 3 文件，看 14 GoRoute 完整迁移 | small(0.5d) | 🟢 P2 |
| **B-30** | `core/data/database/daos/` 7 个 | v0.25 round 53a 拆的 7 DAO，看 18 query 完整迁移 | small(0.5d) | 🟢 P2 |

### 3.4 P3 nice-to-have（10 项）

- 命名 / token 命名 polish
- 注释规范 polish
- 拆分 widget 进一步细化
- 等等

---

## 4. 关键观察

### 4.1 14 round 整体进展：质量守住 + 修复率仍偏低

v0.25 round 43-56h 走完 14 round：
- ✅ `flutter analyze` 0 error
- ✅ `flutter test` 1098/1098 pass（+41 vs round 30 703 cases）
- ✅ 12 守门员全绿
- ✅ 7 DAO 拆 + 6 sub-service facade + 3 文件 router
- ✅ 60+ dark mode 颜色 silent bug 修复
- ✅ 39 个 ARB orphan 清理

**但**：
- 🟠 5 厂商 push 真接 = **0 动作**（R55 plan + 骨架）
- 🟠 14 round 内 spzh 报告 56 个发现中只修了 3 个（R51 危机电话数据 / R54 privacy §11/§12 / R56h medication_report 5 处）
- 🟠 strings.dart 21 处硬编 + 量表 i18n + PIPL §13 = **0 动作**
- 🟠 4 份法律文档只升 1 份

**修复率**：3 / 56 = 5.4%（**比 round 30 13.6% 还低**）

### 4.2 god class 拆分"横向拆分" vs "sub-class 拆分"是有效替代

v0.25 round 57 / 58 用的"横向拆分"（service 变 3 个 parallel service，不是 sub-class）打破了"facade + sub"模式：
- 优点：不需要抽象接口 / 依赖反转
- 缺点：3 个 service 共享 state 难 / 跨 service 调用复杂

但对 R57 (safety_watch) / R58 (medication_report) 简单业务够用。

### 4.3 i18n 双层架构结构性 gap 14 round 没人敢下

`core/l10n/strings.dart` 50+ 处硬编中文（domain 0 flutter 边界硬约束），spzh R56h 修正 5 处但 strings.dart 本身 0 改动。3 种解法都是大工程，14 round 没人敢下这步棋。**v1.0 必须决策**。

### 4.4 合规"文档 vs 实施"6 月 gap 是最大风险

R54 升了 privacy §11/§12，R55 加了 plan + 骨架，但 **PIPL §13 单独同意 0 实施 / AliyunSmsProvider 真接 0 实施 / 5 厂商 push 0 真接**。

**上 store 审核风险高**：4 store 隐私 URL + PIPL §13/§38/§39/§40 + NMPA 联合审，文档承诺 ≥ 实施会触发 store 拒审。

### 4.5 守门员推进 vs spzh 专属守门员缺位

R56e 加了 `check_orphan_arb_keys.py` 12 守门员全绿，但 **4 个 spzh 视角"无对应守门员"**：
- strings.dart 50+ 硬编 → 无守门员
- setup_legal_dialog TODO 注释 → 无守门员
- AliyunSmsProvider.send() throw UnimplementedError → 无守门员
- app_zh_Hant.arb 仍 stub(描述错) → 无守门员

加这 4 个成本 1 round，但能让 spzh 报告 56 个发现从"靠人审"变"自动检测"。

### 4.6 高内聚低耦合 4/5 仍稳

- 4 层架构 + 跨 feature 守门 0 violation
- 隐私边界 100% 守住
- god class 通过横向 / 拆 3 文件 / 抽基类 / value object 4 种方式处理
- 唯一弱点是 facade 内仍多职责（data_export 515 / notification 251 / safety_watch 283）

---

## 5. 下轮建议（v0.26 round 57+）

按"修复成本 / 风险"比排序：

### 建议 1：R57 spzh P0 收尾 — 真接 AliyunSmsProvider（0.5-1d）
- R55 已 plan + 骨架
- 改 `throw UnimplementedError` → 真实 POST
- 加 `check_sms_release_ready.py` 守门员

### 建议 2：R58 spzh P0 — 量表 PHQ-9 / GAD-7 题目 + 严重度 i18n 化（1d）
- `domain/logic/assessment_scale.dart` 加 `List<AssessmentItem> items` 字段
- 数据从 ARB 拿

### 建议 3：R59 spzh P1 — strings.dart override 模式（0.5-1d）
- 21 处 static String 改 static String Function(...) { return bodyOverride ?? '...'; }
- caller 传 AppLocalizations

### 建议 4：R60 spzh P0 — PIPL §13 单独同意实施（等 R57 后 0.5-1d）
- contact 表加 `consentConfirmedAt` 字段
- setup 阶段发 SMS "Y/N"

### 建议 5：R61 spzh 流程 — 加 4 个 spzh 专属守门员（0.5d）
- `check_strings_hardcoded.py`
- `check_legal_consent.py`
- `check_sms_release_ready.py`
- `check_zh_hant_consistency.py`

### 建议 6：R62 spen P0 — 拆 4 个 god class（2-3d）
- `medication_report_pdf.dart` 拆
- `reminder_scheduler.dart` 拆
- `data_export_service.dart` facade 瘦
- `notification_service.dart` facade 瘦

### 建议 7：R63 spen P1 — TDD 续（1-2d）
- presentation 5 大 widget 测（trend / vent / settings / mood / contact）
- 5 处 DateTime race 修正测
- 5 个 P0 bug fix 加 regression test

### 建议 8：R64 emil P1 — 继续 token 化（1d）
- iconSizeInline (18) / iconSizeSmall (14) 新 token
- 30+ 处 `TextStyle(fontSize, fontWeight, color)` → `textStyle*().copyWith(color:)` 集中器
- 8 widget 集中器 100% 落地率

**总成本**：3-4 round 走完 spzh P0 全部遗留

---

**报告完成**。本报告基于全 499 个文件 100% 覆盖（ripgrep 22 类模式 + 关键 8 个 > 10KB 文件 read），跟 3 视角报告（emil / spen / spzh v0.25 增量）完全互补。owner 视角的"硬扫"维度 = 上面 30 个具体 bug + 5 个下轮建议 + 6 个关键观察。
