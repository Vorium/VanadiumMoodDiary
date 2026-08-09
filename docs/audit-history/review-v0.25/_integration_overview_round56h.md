# 整合总览表（v0.25 round 56h）— 三视角 + 底层排查 + 顶层架构

> **作者**：Mavis（root orchestrator）
> **HEAD**：`33b5fd0 v0.25 round 56h`（2026-07-26）
> **4 视角合并**：emil v0.25（12）+ spen v0.25（15）+ spzh v0.25（15）+ owner 底层排查（85）+ owner 顶层架构
> **目的**：把 4 视角合并成一张**可执行的**总览表（按 skill / 架构 vs 底层 / 修复难度 / 优先级 + 高内聚低耦合）

---

## 0. 4 视角交付物

| 视角 | 报告 | 增量发现 | 关键判断 |
|---|---|---|---|
| **emil** | `docs/reviews/v0.25/review_emil_round56h.md` (149 行) | **12**（P0 2 + P1 3 + P2 1 + P3 6） | dark mode 颜色 100% / spacing 100% / icon 100% 收口，**文字 36% 退步**（R50b 未做）+ 8 dead token + 17 IconButton 触感残留 |
| **superpowers-en** | `docs/reviews/v0.25/review_superpowers_en_round56h.md` (267 行) | **15**（P0 1 + P1 4 + P2 10） | R56c-c''' 实际 **+46 tests**（不是 AGENTS.md 写的 41）+ 4 god class 拆完，**仍 4 个未拆**（data_export 564 / medication_report_pdf 321 / reminder_scheduler 244 / mood_audio 350）+ systematic-debugging 5 类 regression 漏 |
| **superpowers-zh** | `docs/reviews/v0.25/review_superpowers_zh_round56h.md` (255 行) | **15**（P0 6 + P1 5 + P2 3 + P3 1） | **R55 5 厂商 push 半做**（plan + 骨架 / AliyunSmsProvider.send() 仍 throw UnimplementedError）+ R54 4 store 合规半做（privacy ✅ / user_agreement 3 份 ❌）+ strings.dart 21 处硬编 14 round 0 动作 |
| **owner（底层排查）** | `docs/reviews/v0.25/_bottom_up_audit_round56h.md` (26.6KB) | **85**（P0 8 + P1 10 + P2 12 + P3 10） | 22 类 grep 模式 + 关键 8 文件 read + 全 499 文件 100% 覆盖 |
| **owner（顶层架构）** | `_top_level_architecture_round42.md` (旧，需更新 v0.25) | 8 架构选项 | 4/5 健康度，god class 4 拆分范式（横向 / 拆 3 文件 / 抽基类 / value object） |
| **合并去重** | `docs/reviews/v0.25/_integration_overview_round56h.md`（本文件）| **~100** | 4 视角完全互补，spen 找工程 P0 / emil 找 UI P0 / spzh 找合规 P0 / owner 找架构 + 硬扫 |

---

## 1. 总览统计

| 视角 | 总问题 | P0 | P1 | P2 | P3 |
|---|---|---|---|---|---|
| emil v0.25 | 12 | 2 | 3 | 1 | 6 |
| superpowers-en v0.25 | 15 | 1 | 4 | 10 | 0 |
| superpowers-zh v0.25 | 15 | 6 | 5 | 3 | 1 |
| owner 底层 | 85 | 8 | 10 | 12 | 10 |
| owner 顶层 | 13 | 0 | 5 | 3 | 5 |
| **去重合并** | **~100** | **~22** | **~32** | **~26** | **~18** |
| 重复项 | （AliyunSms / 4 god class / 量表 i18n / strings.dart / 半角标点 / 4 守门员） | | | | |

**关键观察**：
- **emil 0 + spen 0 + spzh 6 + owner 0 = 6 P0 必修**（其中 5 个 P0 在 spzh 报告里）
- **emil 2 P0** = R50b 49+ 处 inline TextStyle 替换未做（文字 36%→退步）+ 8 dead token
- **spen 1 P0** = TDD 漏 systematic-debugging 5 类
- **owner 8 P0** = AliyunSmsProvider 真接 + 量表 i18n + strings.dart 21 处 + 量表 i18n + PIPL §13 + 11 处 Colors.white/black + 半角标点 + 5 厂商 SDK pubspec
- **3 视角 100% 互补**：emil 找 UI P0，spen 找工程 P0，spzh 找合规 P0，owner 找架构 + 硬扫

---

## 2. P0 必修清单（22 项，按"架构 vs 底层"分类）

### 2.1 架构层面 P0（5 项）—— **上架阻塞 / 合规红线**

| ID | Skill | 标题 | 位置 | 修复难度 | 关键阻塞 |
|---|---|---|---|---|---|
| **A-01** | spzh / owner B-01 | **5 厂商 push 通道 + AliyunSmsProvider 真接** | `lib/core/data/services/sms_service.dart:114-145`<br>`pubspec.yaml` | xlarge(80-120h) | 90% 国产 ROM 杀进程后 0 通知，**R55 半做** |
| **A-02** | spzh / owner B-03 | **量表 PHQ-9 + GAD-7 题目 + 严重度 i18n 化** | `lib/domain/logic/phq9.dart:19-103`<br>`gad7.dart:10-63` | medium(1d) | 海外医生 / 港澳台用户做评估看到中文，**医疗法律风险** |
| **A-03** | spzh / owner B-05 | **PIPL §13 单独同意实施** | `lib/presentation/pages/setup/setup_legal_dialog.dart:5-24`<br>contact 表 | medium(0.5-1d, 需 R57 后) | contact 表无 `consentConfirmedAt` 字段，**1.5 round TODO** |
| **A-04** | spzh / owner B-08 | **危机电话 region 默认 cn**（海外华人打不通中国电话） | `lib/domain/logic/assessment_scale.dart:50`<br>`assessment_page.dart:199` | small(0.5d) | detectCrisis 默认 cn，**R51b 0 动作** |
| **A-05** | spzh | **DEPLOYMENT 附录 A 4 类合规声明模板未法务 review** | `docs/DEPLOYMENT.md 附录 A` | medium(1-2 周法务) | HIPAA / GDPR 涉及 "not subject to" 法律断言，**自填风险高** |

### 2.2 底层 P0（11 项）—— **单文件 / 单行 / 版本号 / 命名 / 标点**

| ID | Skill | 标题 | 位置 | 修复难度 |
|---|---|---|---|---|
| **B-06** | spzh / owner B-04 | **`core/l10n/strings.dart` 21 处硬编中文**（emailSubject/Body/Footer、notifChannel/Title/Body、pdfTitle/Subject） | `lib/core/l10n/strings.dart:17-145` | medium(0.5-1d, 21 处 + caller 改 5 处) |
| **B-07** | owner B-06 | **`medication_report_pdf.dart` 11 处 Colors.white/black 反白失效** | `lib/core/data/services/medication_report_pdf.dart` | small(1d) |
| **B-08** | owner B-07 | **`app_zh.arb` 9 处半角 / + 14 处半角 …** | `lib/l10n/app_zh.arb` | trivial(0.5h) |
| **B-09** | emil EMIL-INC-01 | **R50 加 3 个 score 集中器（textStyleScoreLg/Xl/Xxl）0 处引用** | `lib/core/theme/app_tokens.dart:634-660` | 极小（grep 替换 ~11 处） |
| **B-10** | emil EMIL-INC-04 | **R50b 49+ 处 inline TextStyle 替换未做**（文字 36%→退步） | 全 presentation/ | medium(1 round, ~120 处替换) |
| **B-11** | spen #2 | **TDD 漏跨 midnight race** | `medication_notifier_round61c2_test.dart` 10 + `refill_notifier_round61c_test.dart` 10 | low(加 1-2 case) |
| **B-12** | spen #3 | **TDD 漏隐式序回归** | `medication_notifier_round61c2_test.dart` | low(加 1-2 case) |
| **B-13** | spen #4 | **TDD 漏 dispose race** | `mood_audio_service_round61c3_test.dart` 10 | low(加 2-3 case) |
| **B-14** | owner B-05 | **隐私政策 §3 "用户姓名" → "用户昵称"** | `assets/legal/privacy_policy.md:60` | trivial(0.1h) |
| **B-15** | owner B-08 | **detectCrisis region 默认 cn** | `lib/domain/logic/assessment_scale.dart:50` | small(0.5d) |
| **B-16** | owner B-06 | **`medication_report_pdf.dart` 11 处 Colors.white/black** | 同上 B-07 | small(1d) |

### 2.3 P0 必修工作量

- **不含 push 通道**：17 项 P0（架构 5 + 底层 12），总耗时 **30-50h（4-6 工作日）**
- **含 push 通道**：**110-170h（14-21 工作日）**
- **必杀点**：A-01（5 厂商 push 真接，xlarge）+ A-02（量表 i18n，medium）+ A-03（PIPL §13，medium）= **80-120h 上 store 阻塞**

---

## 3. P1 应修清单（32 项，重点项）

### 3.1 架构层面 P1（15 项）

| ID | Skill | 标题 | 位置 | 修复难度 |
|---|---|---|---|---|
| **C-01** | owner B-09 | **4 个 spzh 专属守门员缺位**（strings / legal_consent / sms_release / zh_hant） | `scripts/` | small(0.5d) |
| **C-02** | owner B-10 | **拆 medication_report_pdf.dart god class** | `lib/core/data/services/medication_report_pdf.dart:321` | medium(0.5-1d) |
| **C-03** | owner B-11 | **拆 reminder_scheduler.dart god class** | `lib/core/data/services/reminder_scheduler.dart:244` | medium(0.5-1d) |
| **C-04** | spen #1 | **拆 data_export_service.dart facade 564 行**（抽 ExportOrchestrator） | `lib/core/data/services/data_export_service.dart:564` | medium(1d) |
| **C-05** | owner B-14 | **data_export_service facade 仍 515 行可继续瘦** | `data_export_service.dart:515` | medium(1d) |
| **C-06** | owner B-15 | **notification_service facade 仍 251 行可继续瘦** | `notification_service.dart:251` | small(0.5d) |
| **C-07** | owner B-16 | **safety_watch_service 横向拆 3 service 后仍 283 行可继续瘦** | `safety_watch_service.dart:283` | medium(1d) |
| **C-08** | owner B-17 | **2 份法律文档仍 v0.22 草稿**（R54 只升 privacy） | `assets/legal/user_agreement.md`<br>`sensitive_data_consent.md` | medium(0.5-1d) |
| **C-09** | owner B-18 | **失联通知 SMS 模板 2 处硬编中文** | `safety_watch_service.dart:311-312`<br>`reminder_scheduler.dart:220-230` | medium(等 R57 后 0.5d) |
| **C-10** | emil EMIL-INC-02 | **5 个 dead token**（chartPlaceholderHeight / sparklineHeight / heatmapLabelWidth / eventTimeColWidth / shimmerPauseMs） | `lib/core/theme/app_tokens.dart` | 极小（grep 替换 ~8 处） |
| **C-11** | emil EMIL-INC-05 | **17 处 IconButton 没用 PressFeedbackIconButton 集中器** | 14 文件 17 处 | 极小（1 round, 17 处替换） |
| **C-12** | emil EMIL-INC-07 | **AppListTile 49% 覆盖率**（20 处裸 ListTile 集中器采用率债务） | `presentation/` 多文件 | small（多 round） |
| **C-13** | spen #6 | **safety_watch 8 个 config 1-line facade 公开 API 重复** | `safety_watch_service.dart:74-92` | medium(deprecate 8 个 facade) |
| **C-14** | spen #7 | **app_routes.dart 14 路由 monolith**（subagent 想加新 route 必须碰 289 行） | `app_routes.dart:289` | medium(按 feature 拆 5 个文件) |
| **C-15** | owner / emil | **riverpod_generator 引入**（v0.25 仍 0 决策） | 全 presentation/providers/ | small(1d) |

### 3.2 底层 P1（10 项）

| ID | Skill | 标题 | 位置 | 修复难度 |
|---|---|---|---|---|
| **D-01** | spen #5 | **TDD 漏 stream subscription leak** | `safety_alert_dispatcher_round61c3_test.dart` 7 | low(加 1-2 case) |
| **D-02** | spen #11 | **safety_alert_dispatcher SMS body 中文硬编** | `safety_alert_dispatcher.dart:42-43` | medium(加 `buildAlertSms` override) |
| **D-03** | spen #13 | **flutter build apk/web 验证未跑** | CI | medium(加 CI workflow) |
| **D-04** | spen #14 | **routerProvider 性能隐患**（profile 变化时整个 GoRouter 重建） | `app_router.dart:33-49` | medium(改 `ref.read` + 内部 cache) |
| **D-05** | owner B-12 | **force unwrap (!) 8 文件 15 处** | 8 文件 15 处 | trivial(1-2h) |
| **D-06** | owner B-13 | **catch (_) 7 文件 10 处** | 7 文件 10 处 | trivial(1-2h) |
| **D-07** | owner / emil | **20 处裸 ListTile 走 AppListTile 集中器** | `medication_list_view` / `medication_row` / `setup_step_welcome` 等 | small（1 round） |
| **D-08** | owner B-19 | **EdgeInsets 裸数字 5 文件 10 处**（v0.25 round 56b 修过 46 剩 10） | 5 文件 10 处 | trivial(0.5h) |
| **D-09** | owner B-20 | **AGENTS.md R23 R41 段"v0.23 round 41 P3-30 zh_Hant stub" 错** | `AGENTS.md` | trivial(5min) |
| **D-10** | owner B-23 | **commitlint / lefthook 全无**（git commit 风格混双轨 14 round 0 动作） | `commitlint / lefthook` | medium(0.5d) |

### 3.3 P1 应修工作量

- **架构 P1（15 项）**：20-30h（2.5-4 工作日）
- **底层 P1（10 项）**：5-10h（0.5-1 工作日）
- **总计**：**25-40h（3-5 工作日）**

---

## 4. 按"架构 vs 底层"分类总览（用户特别要求 + 高内聚低耦合）

### 4.1 架构层面（顶层设计 / 跨模块 / 跨 feature / 流程 / god class）

| # | Skill | 标题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| 1 | spzh / owner | **5 厂商 push 通道架构化**（已有 plan + 骨架 / 缺真接） | xlarge(80-120h) | 🟠 P0 |
| 2 | spzh | **3 份法律文档 v0.22 草稿 + 法务 review** | large(8-16h) | 🟠 P0 |
| 3 | spzh | **量表 i18n 化**（抽 ARB 注入） | medium(1d) | 🟠 P0 |
| 4 | spzh | **PIPL §13 单独同意实施**（contact.consentConfirmedAt + SMS 接入） | medium(0.5-1d) | 🟠 P0 |
| 5 | spzh | **危机电话 region 默认 cn**（R51b 0 动作） | small(0.5d) | 🟠 P0 |
| 6 | spzh | **DEPLOYMENT 附录 A 4 类合规声明模板未法务 review** | medium(1-2 周) | 🟠 P0 |
| 7 | spzh / owner | **4 个 spzh 专属守门员**（strings / legal_consent / sms_release / zh_hant） | small(0.5d) | 🟡 P1 |
| 8 | spen | **拆 data_export_service 564 行**（抽 ExportOrchestrator） | medium(1d) | 🟡 P1 |
| 9 | spen | **拆 medication_report_pdf 321 行**（抽 PdfFontLoader + PdfLayout） | medium(0.5-1d) | 🟡 P1 |
| 10 | spen | **拆 reminder_scheduler 244 行**（拆 CycleHoursRule + DndRule） | medium(0.5-1d) | 🟡 P1 |
| 11 | spen | **拆 app_routes 14 路由按 feature 5 文件**（subagent 友好度） | medium(1d) | 🟡 P1 |
| 12 | spen | **safety_watch 8 config facade deprecate** | medium(0.5d) | 🟡 P1 |
| 13 | spen | **flutter build apk/web CI workflow + golden test** | medium(1d) | 🟡 P1 |
| 14 | owner | **riverpod_generator 引入**（v0.25 仍 0 决策） | small(1d) | 🟡 P1 |
| 15 | owner | **privacy 子包扩展**（已建 `core/data/privacy/encrypted_audio_storage.dart`） | small(0.5d) | 🟢 P2 |
| 16 | owner | **widget library 子目录化** | small(2-3h) | 🟢 P2 |
| 17 | owner | **application/ 中间层** | medium(8-12h) | 🟢 P2 |

### 4.2 底层层面（单文件 / 单函数 / 单行 / 命名 / 注释 / 标点 / 版本号）

| # | Skill | 标题 | 修复难度 | 优先级 |
|---|---|---|---|---|
| 1 | spzh / owner | **`core/l10n/strings.dart` 21 处硬编中文** | medium(0.5-1d) | 🟠 P0 |
| 2 | owner | **`medication_report_pdf.dart` 11 处 Colors.white/black** | small(1d) | 🟠 P0 |
| 3 | owner | **`app_zh.arb` 9 处半角 / + 14 处半角 …** | trivial(0.5h) | 🟠 P0 |
| 4 | emil | **R50 3 个 score 集中器 dead token** | 极小（~11 处替换） | 🟠 P0 |
| 5 | emil | **R50b 49+ 处 inline TextStyle 替换** | medium(1 round, ~120 处) | 🟠 P0 |
| 6 | spen | **TDD 漏跨 midnight / 隐式序 / dispose race** | low(加 4-5 case) | 🟠 P0 |
| 7 | spen | **safety_alert_dispatcher SMS body 中文硬编** | medium(加 override) | 🟡 P1 |
| 8 | spen | **routerProvider 性能隐患** | medium(ref.read + cache) | 🟡 P1 |
| 9 | owner | **force unwrap 8 文件 15 处** | trivial(1-2h) | 🟡 P1 |
| 10 | owner | **catch (_) 7 文件 10 处** | trivial(1-2h) | 🟡 P1 |
| 11 | emil | **17 处 IconButton 触感集中器** | 极小（1 round, 17 处） | 🟡 P1 |
| 12 | emil | **20 处裸 ListTile 走 AppListTile** | small（1 round） | 🟡 P1 |
| 13 | owner | **EdgeInsets 裸数字 5 文件 10 处** | trivial(0.5h) | 🟢 P2 |
| 14 | owner | **AGENTS.md "v0.23 R41 P3-30 zh_Hant stub" 错** | trivial(5min) | 🟢 P2 |
| 15 | owner | **commitlint / lefthook 全无** | medium(0.5d) | 🟢 P2 |
| 16 | emil | **5 个 dead token**（chartPlaceholderHeight 等） | 极小 | 🟡 P1 |
| 17 | emil | **`textStyleMono` 集中器缺失** + 3 处 `'monospace'` 硬编 | 极小 | 🟢 P2 |
| 18 | emil | **2 处 SegmentedButton 缺 :active feedback** | small | 🟢 P2 |
| 19 | emil | **3 处 hintText 硬编**（'13800138000' / '40'） | 极小 | 🟢 P3 |
| 20 | owner | **11 份文件注释含 v0.7 / v0.11 / v0.16 / v0.22 旧版本号** | trivial(0.5d) | 🟢 P2 |

---

## 5. 按修复难度 分布

| 难度 | 工作量 | 总数 | 代表性问题 |
|---|---|---|---|
| trivial | < 1h | ~25 | B-08 半角标点 / B-09 dead token / B-14 §3 改昵称 / C-10 5 dead token / D-05 force unwrap / D-06 catch (_) / D-08 EdgeInsets / D-09 AGENTS.md 改 1 行 |
| small | 1-4h | ~35 | A-04 region 默认 cn / B-07 PDF 11 处 Colors / C-01 4 守门员 / C-06 notification facade 瘦 / D-07 20 处 AppListTile / C-11 17 处 IconButton / 等等 |
| medium | 4-8h | ~20 | A-02 量表 i18n / A-03 PIPL §13 / B-06 strings 21 处 / B-10 inline TextStyle 49 处 / C-04 data_export 拆 / C-05 data_export 继续瘦 / C-07 safety_watch 继续瘦 / C-08 法律文档升级 / C-09 SMS 模板硬编 / C-11 app_routes 拆 5 / C-14 riverpod_generator |
| large | 8-16h | ~3 | A-05 DEPLOYMENT 附录 A 法务 / C-15 全部法务 review / 等等 |
| xlarge | > 16h | 1 | A-01 5 厂商 push 通道（80-120h） |

---

## 6. 按 skill 互补性（4 视角分工）

| 视角 | 强项 | 弱项 | 互补 |
|---|---|---|---|
| **emil** | UI / 动效 / 组件设计 / token 化 | **不查 P0 必修**（仅看设计 feel） | 找 UI P0（dead token / inline TextStyle 退步 / 触感集中器） |
| **spen** | P0 工程 / TDD / systematic-debugging / god class 拆分 | UI / 文案 / 中文规范 | 找工程 P0（god class 拆后剩 / TDD 漏 systematic-debugging 5 类 / 公开 API 重复） |
| **spzh** | 国内合规 / 法律 / 5 厂商 push / 中文 i18n / 文档 | 通用工程（不深入 systematic-debugging 6 类） | 找合规 P0（5 厂商 push 半做 / 法律文档 / 量表 i18n / PIPL §13） |
| **owner** | 顶层架构 / god class / 高内聚低耦合 / 跨边界耦合 | 单文件 bug 细节 | 找架构 P0（4 类合规架构 + god class 剩余 + 守门员缺位） |

**4 视角完全互补**：emil 找 UI 问题，spen 找工程 P0，spzh 找合规 P0，owner 找架构 + 硬扫

---

## 7. v0.26 立项建议（按 P0 → P1 → P2 → P3 排序）

### Round 57（spzh P0 收尾 — 真接 AliyunSmsProvider，0.5-1d）
- 改 `throw UnimplementedError` → 真实 POST（sms_service.dart:114-145）
- pubspec 加 `dio: ^5.0.0` + `crypto: ^3.0.0`
- accessKey / signName / templateCode 走 env
- 加 `check_sms_release_ready.py` 守门员

### Round 58（spzh P0 — 量表 i18n 化，1d）
- `domain/logic/assessment_scale.dart` 加 `List<AssessmentItem> items` 字段
- `Phq9Scale` / `Gad7Scale` 不再硬编，数据从 ARB `phq9Items` / `gad7Items` / `phq9Severity` / `gad7Severity` 拿
- 收益：海外医生 / 港澳台用户做评估能看懂，**医疗法律风险降至 0**

### Round 59（spzh P1 — strings.dart override 模式，0.5-1d）
- 21 处 static String 改 static String Function(...) { return bodyOverride ?? '我是 $name...'; }
- caller (`safety_watch_service` / `reminder_scheduler` / `notification_service`) 传 `AppLocalizations.of(context).emailBody`
- 收益：海外用户用 en locale 调 `Strings.emailBody` 走 override 走 AppLocalizations

### Round 60（spzh P0 — PIPL §13 单独同意实施，等 R57 后，0.5-1d）
- contact 表加 `consentConfirmedAt` 字段 + schema migration
- setup 阶段发 SMS "Y 确认您是 $name 的紧急联系人，回复 N 拒绝"
- 联系人回复 Y → 标记 confirmed
- 30 天未确认 → 提醒用户重发
- 加 `check_legal_consent.py` 守门员

### Round 61（spen P0 — 继续 TDD 补 systematic-debugging 5 类，1-2d）
- 跨 midnight race regression test（medication_notifier / refill_notifier 各 +1-2 case）
- 隐式序回归（已 v0.16 R19 立规矩，补 1-2 case 锁）
- mood_audio_service dispose race（R52 修了，加 widget test 锁）
- stream subscription leak（mood_recorder / vent_compose widget test 锁）
- setState after dispose（类似）

### Round 62（spen P1 — 拆 data_export_service 564 行 god class，medium 1d）
- 抽 `ExportOrchestrator` 隔离 importData/exportData
- facade 留 5 类编排入口
- 预期减到 ~250 行

### Round 63（emil P0 — R50b 49+ 处 inline TextStyle 替换，1 round）
- 替换为 `textStyleXxx(context).copyWith(color: ...)`
- 文字 token 化从 36% 推到 80%+
- 删除 5+3 = 8 个 dead token（替换后自然删除）

### Round 64（spen P1 — 拆 medication_report_pdf 321 行，medium 0.5-1d）
- 抽 `PdfFontLoader` + `PdfLayout` 2 个 pure helper
- 11 处 Colors.white/black 修正 → 用 PdfColor 库自身

### Round 65（emil P1 — 触感集中器 17 处 IconButton + 20 处 AppListTile，1 round）
- 17 处 IconButton 走 `PressFeedbackIconButton` 集中器
- 20 处 ListTile 走 `AppListTile.standard/carded/destructive` 集中器
- 2 处 SegmentedButton 包 `PressFeedback` + `MotionScheme.subtle`

### Round 66（spen P1 — app_routes 拆 5 文件，medium 1d）
- `app_route_main.dart` / `app_route_assessment.dart` / `app_route_medication.dart` / `app_route_vent.dart` / `app_route_check_in.dart`
- `AppRoutes.all()` 改成 `final all = [...AppRouteMain.all(), ...]`
- subagent 加 route 只碰 1 个 feature 文件

### Round 67（owner P1 — 4 个 spzh 专属守门员 + riverpod_generator，1-2d）
- `check_strings_hardcoded.py` / `check_legal_consent.py` / `check_sms_release_ready.py` / `check_zh_hant_consistency.py`
- riverpod_generator 引入（24 provider boilerplate 减 30%）

### Round 68（spen P1 — CI workflow + golden test，1d）
- `.github/workflows/ci.yml` 跑 12 守护脚本 + flutter analyze + flutter test + flutter build apk --debug
- golden test 起步：R49 dark mode 改 60+ 处 color → 加 `test/golden/` 锁 home_page / settings_page

### Round 69+（P2 / P3 nice-to-have，3-4 round）
- 拆 reminder_scheduler 244 行
- 拆 mood_audio_service 350 行
- 拆 safety_watch 283 行（继续瘦）
- 5 厂商 push 真接
- commitlint + lefthook
- Freezed union types
- application/ 中间层

**总成本**：3-4 round 走完 spzh P0 全部遗留 + 6-8 round 走完 P1

---

## 8. 高内聚低耦合 评估（owner 视角，4/5 健康度）

| 维度 | 评价 |
|---|---|
| 4 层架构 | ⭐⭐⭐⭐⭐ 守住（domain 0 flutter 0 drift，cross_feature 0 violation） |
| 跨 feature 解耦 | ⭐⭐⭐⭐⭐ 守住 |
| 隐私边界 | ⭐⭐⭐⭐⭐ 守住（vent 独立 / 树洞不分析 / 通知 / 关怀） |
| facade 模式 | ⭐⭐⭐⭐ 已落地（notification 6 sub / data_export 3 sub / 7 DAO / app_router 3 文件） |
| 单文件粒度 | ⭐⭐⭐ 部分 god class 仍 > 10KB（4 个未拆：data_export 564 / medication_report_pdf 321 / reminder_scheduler 244 / mood_audio 350） |
| i18n 双层架构 | ⭐⭐ 仍有 gap（strings.dart 21 处硬编 14 round 0 动作） |
| 合规架构 | ⭐⭐ 文档 vs 实施 6 月 gap（privacy §11/§12 写但 PIPL §13 0 实施） |
| 守门员 | ⭐⭐⭐⭐ 12 个全绿（R56e 验证），但 4 个 spzh 专属缺位 |
| **整体** | **⭐⭐⭐⭐ (4/5)** —— 4 层架构 + 守门员成熟，但 god class + 合规实施是 2 个 P0 风险 |

**"该不该重构" 决策树 9 条**（v0.23 round 42 owner 草稿，v0.25 round 56h 仍适用）：
1. 文件 > 500 行 → 拆（v0.25 已拆 4 个，仍剩 4 个）
2. 模式重复 3+ 处 → 抽通用 widget（emil 5 widget 集中器采用率债务）
3. 跨 feature import 跨 pages/ → 不允许（守门）
4. domain 引用 flutter / drift → 不允许（守门）
5. service 公开 API > 10 个 → 考虑 facade 模式（safety_watch 8 config 重复）
6. P0 必修 ≥ 3 项 → 一个 round 集中清理（v0.25 round 38 / 56c / 56e 是范例）
7. P1 应修 ≥ 5 项 → 下一个 round 处理
8. P2 可修 ≥ 10 项 → 一个 round 集中清理（v0.25 round 40 / 56b / 56g 是范例）
9. 新 feature / 重大架构 → brainstorming + writing-plans 流程（spzh T-23 硬规则）

---

## 9. 关键观察（4 视角合并后）

### 9.1 v0.25 round 43-56h 14 round 整体进展
- ✅ `flutter analyze` 0 error
- ✅ `flutter test` 1098/1098 pass（+41 vs round 30 703 cases）
- ✅ 12 守门员全绿
- ✅ 4 god class 拆完（app_database 559→373 / safety_watch 425→325 / medication_report 347→281 / app_router 418→51）
- ✅ dark mode 颜色 token 化 100%（v0.25 round 49）
- ✅ spacing / icon-size 100%（v0.25 round 56b + 56）

**但 14 round 修复率仅 5.4%**（3/56 spzh 报告发现真修）：
- 🟠 **R55 5 厂商 push = 0 真接**（plan + 骨架 / AliyunSmsProvider.send() 仍 throw UnimplementedError）
- 🟠 strings.dart 21 处硬编 + 量表 i18n + PIPL §13 + 3 份法律文档 + 半角标点 = **0 动作**
- 🟠 4 个 spzh 视角专属守门员 = 0 动作

### 9.2 god class 拆分"渐进 facade 模式"成熟
R53a → R57 → R58 → R59 → R60 5 round 形成清晰模式：
1. 抽 sub-class / service / value object
2. facade 改成 1-line 委托
3. 保留公开 API 兼容 caller
4. sub-class 用 testable 注入

但 **R49-R60 期间仍有 4 个未拆**（data_export 564 / medication_report_pdf 321 / reminder_scheduler 244 / mood_audio 350），R61+ 建议按此模式继续。

### 9.3 TDD 补全是 spen P0 #15 成功示范但 systematic-debugging 5 类漏
- R56c-c''' 共 **+46 tests**（AGENTS.md 写的 41 实际为 46）
- 4 sub-service 之前 0 test → 全部覆盖（Mock MethodChannel / StateNotifier / scripted provider）
- **漏洞**：偏 happy path，**没补"跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose"5 类 regression guard**

### 9.4 i18n 双层架构结构性 gap 14 round 没人敢下
- `core/l10n/strings.dart` 50+ 处硬编中文（domain 0 flutter 边界硬约束）
- 3 种解法都是大工程，14 round 没人敢下这步棋
- **v1.0 必须决策**：(A) Strings 改 AppLocalizations 注入（破坏 domain 0 flutter） (B) 加 override 参数到每个 String 函数 (C) 接受现状，把所有用 Strings 的地方都改 AppLocalizations.of(context)

### 9.5 合规"文档 vs 实施"6 月 gap 是最大风险
- R54 升了 privacy §11/§12
- R55 加了 plan + 骨架
- 但 **PIPL §13 单独同意 0 实施 / AliyunSmsProvider 真接 0 实施 / 5 厂商 push 0 真接**
- **上 store 审核风险高**：4 store 隐私 URL + PIPL §13/§38/§39/§40 + NMPA 联合审

### 9.6 守门员推进 vs spzh 专属守门员缺位
- 12 守门员全绿（R56e 验证）
- **4 个 spzh 视角"无对应守门员"**：strings / legal_consent / sms_release / zh_hant
- 加这 4 个成本 1 round，但能让 spzh 报告 56 个发现从"靠人审"变"自动检测"

### 9.7 emil "taste = subtraction" 在 v0.25 反而退步
- dark mode / spacing / icon-size 100% 收口 ✅
- 文字 36% 退步（R50b 未做）❌
- 8 dead token（R50 3 个 + R56 5 个）❌
- emil "加 token 必须同 round 替换"原则被破坏

### 9.8 subagent 友好度从 60% → 85%
- 14 round 期间 god class 拆分 + value object 抽离让大多数剩余工作可并行
- 但 `app_routes.dart` 14 路由仍 monolith（spen #7 P1）
- 3 个未拆 god class（medication_report_pdf / reminder_scheduler / mood_audio）跨多文件

---

## 10. 给用户的 1 句话总结

> **v0.25 round 56h 整体质量守住**（dark mode 颜色 100% / spacing 100% / icon 100% / 4 god class 拆完 / 1098 tests / 12 守门员全绿），**但 14 round 修复率仅 5.4%**（3/56 spzh 真修），**最大风险仍是"5 厂商 push 真接 + 量表 i18n + PIPL §13 单独同意 + 3 份法律文档"上架阻塞**，**v0.26 round 57-60 必做"AliyunSmsProvider 真接 + 量表 i18n 化 + strings override + PIPL §13"4 件合规 P0 收尾**（xlarge ~3-4 round，1 个半月内），配套 4 个 spzh 专属守门员（strings / legal_consent / sms_release / zh_hant）+ TDD 补 systematic-debugging 5 类 regression。
