# superpowers-zh 视角审计 (v2, 2026-07-21 第二轮)

> 审计基线：v0.22 round 36 / schemaVersion 12 / 178 commit (100% Mavis) / 748 test cases
> 工具：grep-first + `dart scripts/check_all.dart` (✅) + `python scripts/check_cross_feature.py` (✅) + `python scripts/check_arb_keys.py` (6 missing) + git 历史分析
> 上次审计（v1, 7/20）后已修 9 轮 (round 28-36)，本轮聚焦"剩余 + 新发现"

---

## 1. 顶层架构审视（5 条）

### 1.1 4 层架构 + 隐私边界 + CI 守门员 = 项目皇冠保持 ⭐⭐⭐
- v0.18 round 19 把 `data/shared/theme/routing/l10n` 5 个子层并入 `lib/core/` umbrella 仍是教科书。`dart check_all.dart` 双报告 0 violation + `python check_cross_feature.py` 50 files 0 violation。
- **隐私边界 100% 守住**（v0.22 round 29 重新 verify）：
  - `vent_entries` / `VentEntryEntity` / `ventRepositoryProvider` / `ventEntriesProvider` — 11 个文件命中，**全部**在 `pages/vent/*` + `providers/vent_providers.dart` + `core/data/repositories/vent/*` + `core/data/database/tables/vent/*` + `core/data/services/data_export_service.dart`（用户主动 export 入口）
  - `notification_service.dart` / `care_engine.dart` / `safety_watch_service.dart` — grep `vent|树洞` 0 匹配
  - `domain/logic/` grep `vent|tree.?hole|树洞` 0 匹配
- ✅ vent 隔离 v0.18 P0 修过，v0.22 round 29 仍完整。

### 1.2 vent 文字导出已加敏感提示（v0.22 round 32 sp-zh 合规）⭐
- 上次 P0-2 报告：`_exportData` 缺二次确认。v0.22 round 32 (e872ff9) sp-zh 合规 + 文档版本号 10 项，已加敏感提示。
- 现状：导出 vent 明文前弹"含敏感文字"二次确认。✅

### 1.3 2 处时区 race bug 已修（v0.22 round 28 df3f015 范围？）⭐⭐
- 上次 P1-1 报告：`safety_watch_service.dart:116` + `assessment_reminder_service.dart:88` 调 `when.toIso8601String()` 没 toUtc。
- **现状**（grep 验证）：
  - `safety_watch_service.dart:121` `await prefs.setString(_kLastAlertAt, when.toUtc().toIso8601String());` ✅
  - `assessment_reminder_service.dart:94` `await prefs.setString(_kLastAssessmentAt, when.toUtc().toIso8601String());` ✅
  - `data_export_service.dart:37` 抽 `_isoUtc(DateTime d) => d.toUtc().toIso8601String();` 集中器 ✅
  - `last_error_capture.dart:37` 错误日志（`DateTime.now().toIso8601String()`）— **日志场景合理，无需 UTC**（仅用于 crash log 定位，本地时间更易读）
- ✅ 2 处全部已修。

### 1.4 en.arb 缺 6 个 OEM key（v0.22 round 33 漏 en 翻译）— 新 P0 ⭐⭐⭐
- **事实**：`scripts/check_arb_keys.py` 检测 zh 555 / en 549，**en 缺 6 个 OEM key**：
  - `notificationStatusCardOemBrandOthers`
  - `notificationStatusCardOemBrandSamsung`
  - `notificationStatusCardOemStepOthers1`
  - `notificationStatusCardOemStepOthers2`
  - `notificationStatusCardOemStepSamsung1`
  - `notificationStatusCardOemStepSamsung2`
- **根因**：v0.22 round 33 (5c56ce0) "ROM 7 品牌" 加 zh 翻译时漏 en。`check_arb_keys.py` v0.22 round 30 加的脚本已自动抓到。
- **严重度**：🔥 P0。en 模式国产 ROM 自检卡降级中文 = **l10n 一致性 bug**。
- **修法**：补 6 个 en 翻译。10 分钟。

### 1.5 trend 系列 l10n 接入已修（v0.22 round 30 419b71c）⭐⭐
- 上次 P0-1 报告：trend 系列 4 文件 12+ 处 hardcode 中文，l10n key 全部 dead。
- **现状**（grep `Text('[^']*[\x{4e00}-\x{9fff}]` 验证）：
  - trend_page / trend_summary / trend_calendar / trend_charts **全部 0 命中**（之前 12+ 处 hardcode）
  - 仅剩 11 处 hardcode 全部在 `main.dart:178-205` 升级到 v0.9 dialog（pre-encryption 老用户升级路径，单次出现，合理）
  - 2 处 widget 注释（`empty_state.dart:9` / `error_state.dart:8`，"使用模式"说明，合理）
- ✅ trend 系列 l10n 100% 接入。

---

## 2. 底层逐行排查

### 🔴 P0 — 必修（1 条）

**P0-1. en.arb 缺 6 个 OEM key**（见顶层 1.4）
- 修法：补 6 个 en 翻译。10 分钟。
- 用户感知：⭐⭐⭐ — en 模式国产 ROM 自检卡降级中文。

### 🟡 P1 — 应修（10 条）

**P1-1. `main.dart:178-205` 11 处 hardcode 中文升级 dialog**
- 升级到 v0.9 dialog 11 处全 hardcode："升级到 v0.9" / "检测到本地有旧版本数据" / "本次升级会：" / "• 启用数据库加密（保护你的隐私）" / "• 清空旧版本的所有打卡记录" / "（旧版本没有"导出数据"功能，原始数据无法恢复）" / "建议：先在旧版 App 内完成"导出数据"备份，再升级。" / "若旧版已卸载无法导出，可以直接点"继续升级"。" / "取消" / "继续升级" / "已备份，继续升级"。
- **严重度**：🟡 P1。en 模式升级 dialog 全中文。pre-encryption 老用户升级路径，单次出现，但**全量升级 = 1.0 之前必经**。
- **修法**：加 11 个 ARB key + replace。1-2 小时。

**P1-2. zh-only 4 个 l10n key（en 缺翻译）— 上次报告残留**
- 上次 P1-2 报告："zh-only (4): current, description, action, error"。本轮 `check_arb_keys.py` 检测 en 缺 6 个 OEM key = 修后仍 6 zh-only。
- **严重度**：🟡 P1。en 模式降级显示 key 字符串或中文。
- **修法**：补 6 个 en 翻译（合并到 P0-1 一起做）。

**P1-3. `mood_dialog.dart` 838 行 god class**
- 见 spen 报告 P0-2。1-2 天拆 4 子组件。

**P1-4. `notification_service.dart` 631 行 facade 仍偏厚**
- 见 spen 报告 P1-3。1-2 天抽 MedicationNotifier / AssessmentNotifier / RefillNotifier。

**P1-5. `Semantics()` 仅 6 处 vs 上百个 ListTile**
- 见 emil 报告 P1-3。1-2 天批量加。

**P1-6. `ScaffoldMessenger.of(ctx).showSnackBar(...)` 55 处直接调用**
- 见 emil 报告 P1-1。半天批量换 `AppSnackBar.xxx(...)`。

**P1-7. `withValues(alpha:)` 21 处散落 8 文件**
- 见 emil 报告顶层 1.4。半天换 `AppTokens.tintedXxx`。

**P1-8. `legal_page.dart:64-67` SnackBar 2 个 l10n key 缺**
- `SnackBar(content: Text(withdraw ? '已撤回 (1/3)' : '已重新同意 (1/3)'))` — 2 个 zh-only key。
- **修法**：加 2 个 ARB key + replace。30 分钟。

**P1-9. `setup_step_medication.dart:248/252/307/313` InputChip / ActionChip / FilterChip 无 PressFeedback**
- 4 处 chip 缺 :active scale 反馈。
- **修法**：外包 PressFeedback。15 分钟。

**P1-10. `medication_report_dialog.dart:118/149` `Colors.black54` 反白漏 dark mode**
- PDF 端合理，但对话框是 UI 应走 `cs.onError` / `AppTokens.surfaceInverseColor(context)`。
- **修法**：2 处换 token。5 分钟。

### 🟢 P2 — 应该改（10 条）

**P2-1**. `assessment_widgets.dart:202` '未选' hardcode 中文（zh-only）
**P2-2**. `medication 'mg' / '片' DropdownMenuItem display hardcode`（setup_step_medication + edit_medication_dialog 共 4 处）
**P2-3**. 缺 golden test（视觉回归）— 0 golden
**P2-4**. `catch (_)` 8 处剩 2 处 best-effort 应走 swallowError（见 spen 1.2）
**P2-5**. `BorderRadius.circular(4)` 6 处漏 token（trend_charts:66/94）
**P2-6**. `medications_list_widget.dart` 536 行 god class
**P2-7**. `assessment_history_page.dart` 624 行 god class
**P2-8**. `trend_charts.dart` 595 行 god class（之前 4 个 placeholder 文件已合并，注释说"SpotKey typedef 来自 fl_chart 未导出"）
**P2-9**. `vent_compose_page.dart` 530 行 god class
**P2-10**. `medication_calendar_page.dart` 398 行

### ⚪ P3 — 锦上添花
- **P3-1**. `data_export_service.dart` 488 行 — 导出 + 加密 + 音频 + JSON schema 全在 1 个 service
- **P3-2**. `medication_report_pdf.dart` 488 行 — PDF 端 god class
- **P3-3**. `whitenoise / blank-state 文案 polish` — 几个空态"点击 + 添加你的第一条" 类文案偏工具化，精神心理患者需要更温暖
- **P3-4**. `legal_page.dart` 协议版本号 `v0.22-2026-08-01` 跟 pubspec.yaml version 字段未自动同步
- **P3-5**. `setup_page.dart` 429 行 — 4 步骤全在 1 个 state
- **P3-6**. `app_tokens.dart` 483 行 token 集中器本身偏厚，但功能完整
- **P3-7**. `vent_list_page` "添加"按钮缺 voice/record 快捷入口（长按 + 弹选择菜单）— UX 改进
- **P3-8**. 文档 `docs/WHITEPAPER.md` 是否跟 v0.22 同步？（v0.22 round 28 spzh-bug-07 同步过 schemaVersion / Flutter / 测试数）
- **P3-9**. `check_arb_keys.py` 已自动检测，但 CI 没强制 fail（应加 `--ci` 模式）

---

## 3. 整体评级
**A-**。上次 P0/P1 几乎全部修完（trend l10n 接入 / 时区 2 处漏修全 toUtc / vent 导出敏感提示 / 4 zh-only key 走脚本检测），**新发现 1 条 P0 (6 个 OEM key 缺 en)** + 6 个 god class 待拆 + a11y 仍稀疏。

## 4. 关键 3 个发现
1. 🔥 **P0-1 l10n**：en.arb 缺 6 个 OEM key（v0.22 round 33 加 zh 时漏 en），`check_arb_keys.py` 已自动检测。10 分钟修。
2. 🔥 **P1-1 升级 dialog**：main.dart 11 处 hardcode 中文升级 dialog，en 模式降级。1-2 小时补 11 个 ARB key。
3. ⚠️ **P1-3 结构**：mood_dialog 838 行 god class 是 v0.22 round 31 加录音后涨出来的真 god class，1-2 天拆 4 子组件。
