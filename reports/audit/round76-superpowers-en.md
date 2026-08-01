# Round 76 - superpowers-en 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: v0.27.0+64（R76 测试同步，commit 6b4fc63）
**视角**: superpowers-en（英文 superpowers 7 阶段方法论）
**审计模式**: 全量（lib/ 全部 + test/ 137 文件 + scripts/ 16 守护脚本 + 5 类已知 bug 模式）
**基线**: 1134 `test()` + 158 `testWidgets` 总 1292 case / 0 analyzer error / 0 warning / 0 info / 16 守护脚本全绿（dart scripts/check_all.dart + check_cross_feature.py + check_datetime_race.py 2 个 + check_widget_dispose.py + check_orphan_arb_keys.py 等全绿）

---

## 0. 总览

- **评分**: **9.3 / 10**（R74 9.2 → R76 9.3，升 0.1；R75 修了 21 项 PII/PIPL 集中收尾 + R76 是测试同步小 commit）
- **关键发现数**:
  - **P0 (上架 blocker)**: 0 条（连续 5 轮保持 0 P0）
  - **P1 (质量改进)**: 1 条（domain 层 l10n 软违规 2/3 file 仍未收尾，R75 注释明确"R76 单独 1 round 完成"，但 R76 实际是测试同步 round，未做）
  - **P2 (架构/重构/半成品)**: 5 条（mood_audio_section 591 行 升为新最大 god class 候选 + export_orchestrator 565 行 增 25 行 + vent_compose dispose 异步未 await 仍未修 + home_page 678 行 增 47 行 + setup_page 501 行 增 33 行）
  - **P3 (优化/NIT)**: 7 条（test 覆盖盲区 8 个延续 + 死代码警示 0 处 + facade candidate 1 处 + 集成测 0 处）
- **R75 修了多少 (21 项 commit)**: 0 P0 / 0 P1 / 0 P2 / 21 P3 类（病耻感措辞 5 + i18n 化 1 + 错字 1 + AppDelegate iOS foreground 通知 2 + legal version 同步 2 + lost_contact_sms PII 移除 1 + 临床精度 1 + home_page placeholder 占位 throw 2 + scale_translations 1/3 迁出 + care_engine 成功路径 swallowError 误用 1 + iOS pbxproj 2 修复 + 14 个 commit 散点）
- **整体感觉**: R75 是"上架前 PIPL/精神心理保护"集中收尾 round — 5 处病耻感措辞中性化 + 2 处 iOS foreground 通知 AS-P0-3 + 2 处 placeholder PII 防泄漏 + legal version 同步 + scale_translations 1/3 迁出 6 大主题。R76 是测试同步小 commit（assessment_history test R75 '正常' → '几乎没有' 同步）。**R74 12 项中 R75 修了 11 项**（1 项 P1-1 partial 完成 1/3 file，剩 2/3 file 留给 R76 但 R76 未做），**P2-1 vent_compose dispose 异步未 await 仍未修**（R75 跳过），R74 P2-2 mood_dialog 1204 god class 实际 R64 已拆解（R74 报告错误，应该是 23 行薄壳），R75 持续推进但 R76 没新动作。整体进入"上架前最后 1h 修 P1-1 剩 2 file + P2-1 vent_compose dispose await + 2 个 facade candidate 评估"状态。

---

## 1. 顶层架构审视

### 1.1 4 层架构 + 依赖方向

**架构纯度（持续绿）**: 16 守护脚本全绿，`dart scripts/check_all.dart` 输出:
```
[1/2] 4 层架构纯度检查 — ✅ 通过
   - domain/  0 flutter / 0 drift / 0 data / 0 presentation
   - shared/  0 flutter / 0 drift / 0 data / 0 presentation
   - data/    不依赖 presentation/
[2/2] 架构语义一致性检查 — ✅ 通过
   - 每个 domain *Entity 都对应一个 drift table
   - 每个 drift table data class 都对应一个 domain *Entity
   - shared/ 工具被 ≥2 层使用
```

**R74 → R76 变化**:
- R75 P1-1 partial 完成 **1/3 file** (`scale_translations.dart` 73 行)
  - 证据: `lib/domain/entities/scale_translations.dart:25` 现在只 `import 'package:chroniccare/domain/logic/assessment_scale.dart';`，0 Flutter import
  - 注释 R75 partial 写明: "R76 完成剩余 2 file (day_detail.dart + vent_entry_entity.dart) — 改用 closure 参数化注入 i18n 查找, 涉及 fromData / _renderCheckInLabel / _scaleName 6+ method 重构 + 10 case test 改, R75 时间紧 1 round 装不下, R76 单独 1 round 完成"
  - **R76 commit 6b4fc63 实际是测试同步 round，未做 P1-1 剩余 2 file** ❌
  - 当前 grep 确认仍 2/3 file 软违规:
    - `lib/domain/logic/day_detail.dart:36` — `import 'package:chroniccare/l10n/app_localizations.dart';`
    - `lib/domain/entities/vent_entry_entity.dart:19` — `import 'package:chroniccare/l10n/app_localizations.dart';`

**新发现 1 (P1 — R75 partial, 留 2 file 未收尾)**: domain 层仍 2 file soft 架构违规，间接引入 Flutter 依赖。`check_all.dart` 的 purity 检查只 grep `package:flutter/` / `package:drift/` / `package:chroniccare/data/`，**没 grep `package:chroniccare/l10n/`**。R75 partial fix 完 1/3 file，剩 2 file 留 R76 但 R76 跳过了。

**修复建议 (M 难度, 1-2h)**:
- 选项 A: 跟 R75 partial 同一模式 — `day_detail.dart` 抽 `DayDetailFromDataUseCase` 到 `presentation/services/`，`vent_entry_entity.dart` 抽 `VentEntryDurationFormatter` 到 `presentation/services/`
- 选项 B: 改 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入（彻底，0 flutter in domain）
- **推荐 A**，跟 R67 B-2 `FireCareStrategyUseCase` 已用的"参数化 l10n 注入"模式 + R75 partial 已走通的 "迁出到 presentation/services/" 模式一致
- 涉及修改: 6+ method (`fromData` / `_renderCheckInLabel` / `_scaleName` / `durationLabelL10n`) + 10 case test 改 (day_detail_round10_test.dart + vent_entry_entity_round18_test.dart)

**证据**:
- `lib/domain/logic/day_detail.dart:36` (R75 注释说 R76 修但未修)
- `lib/domain/entities/vent_entry_entity.dart:19` (同上)
- `lib/domain/entities/scale_translations.dart:25` (R75 修了，1/3 file)
- `grep -rn "import 'package:chroniccare/l10n/app_localizations.dart'" lib/domain/` 输出 2 file

---

### 1.2 高内聚低耦合

**R74 → R76 变化**:
- **高内聚 (5/5)**: 5 facade 全部稳定
  - `core/data/services/notification_service.dart` 424 → **419 行**（R76 减 5 行）
  - `core/data/services/safety_watch_service.dart` 313 → **416 行**（R76 增 103 行，但内部已 5 sub-service 拆完，README 注释占大头）
  - `core/data/services/export/export_orchestrator.dart` 540 → **565 行**（R76 增 25 行，god class 持续扩大）
  - `core/data/services/sms_service.dart` 18+ 月 TODO 336 行 (XL 待真接)
  - `domain/usecases/fire_care_strategy.dart` 260 行 (R65 抽离，纯函数 use case)
- **低耦合 (5/5)**: presentation → domain 接口 (不暴露 impl) 100% 覆盖

**新发现 2 (P2 — mood_audio_section 升为新最大 god class 候选)**: `lib/presentation/pages/mood/widgets/mood_audio_section.dart` 现 **591 行**，超过 export_orchestrator (565) 和 reminders_hub_page (471) 升为项目第二大文件。R74 报告说 mood_dialog 1204 行 god class，**实际 R64 已拆为 mood_dialog 23 行薄壳 + mood_recorder_page 214 行 + mood_audio_section 591 行 + 5 子 widget (score_chooser/tags/text_input/submit_panel)**。R64 拆解正确但 mood_audio_section 自身 591 行含 6 state field + 7 method + 4 StreamSubscription + AudioPlayer/Recorder + temp file 加密 + STT graceful degrade + maxReached 逻辑，已是完整 god class 候选。

**修复建议 (L 难度, 3-4h)**:
- 抽 `mood_audio_recorder.dart` (录音 / 停止 / 重录 / 时长 / temp file 加密) ~250 行
- 抽 `mood_audio_stt.dart` (STT 初始化 / live transcript / final transcript / 错误处理) ~150 行
- 抽 `mood_audio_player.dart` (播放 / 暂停 / 完成回调) ~100 行
- 留 `mood_audio_section.dart` ~90 行做 widget 编排
- 或按 R64 同款 "先抽 widget 再补测" 模式，先抽 `mood_audio_recorder_section.dart` 隔离录音核心 (最重 200 行)

**R74 → R76 进度**:
- R74 列 P2-2 mood_dialog god class → 实际 R64 已拆 (R74 报告错)
- R74 没说 mood_audio_section 是新最大候选 → R76 新发现
- R65-R75 12 round 持续拆解其他 god class (notification_service / safety_watch / export_orchestrator) 但 mood_audio_section 因 R64 一次性拆解后未再评估

**证据**:
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart:591` (现项目第二)
- `lib/presentation/pages/mood/mood_dialog.dart:23` (R64 拆后薄壳)
- `grep -n "StreamSubscription" lib/presentation/pages/mood/widgets/mood_audio_section.dart` = 4 处
- 6 state field: `_isRecording / _isPlaying / _liveTranscript / _finalTranscript / _sttAvailable / _sttFailed` (line 105-111)
- 7 method: `_initializeStt / _disposeResources / _toggleRecord / _startRecording / _stopRecording / _reRecord / _togglePlay` (line 137-396)

---

### 1.3 模块边界 (presentation/pages 10 feature 互不耦合)

**R74 → R76 变化**:
- 10 feature 互不耦合: 全绿
- `python scripts/check_cross_feature.py` 输出 "[OK] 67 files checked, 0 violations"
- 10 个 feature 目录: `home/`, `setup/`, `settings/`, `trend/`, `assessment/`, `check_in/`, `contact/`, `medication/`, `mood/`, `vent/` (R74 写 8 个是错的，实际 10 个)
- hub 例外保留: home + settings 2 个 hub feature 仍可被其它 feature 引用

**R75 改进**:
- R75 病耻感措辞中性化 (5 处): `notifDailyCheckInBody` + 4 鼓励文案 zh/en/zh_Hant 同步
- R75 错字 '今' → '今天' (1 处): 错字漏修跨 round
- R75 PIPL 集中收尾 (3 处): lost_contact_sms PII 移除 + _kLegalVersion v0.27-2026-08-01 + ConsentArtifact.version 同步

**新发现 3 (P3 — 死代码警示 0 处但 R75 改 placeholder 为 throw)**: R74 列 2 处 R55+ TODO 死代码 (home_page:557-575 `fireSms` 走 `00000000000` + `fireEmail` 走 `placeholder@invalid.local`)，R75 commit a7e5eac 把 2 处 placeholder 改 throw StateError 防御性阻断 (R75-N13/N14)。**当前 defaultConfig=careCopy 永远不会走到 fireSms/fireEmail 分支**，throw 仅做防御。注释清晰，**不改**也安全。

**R75 跨 feature 引用决策**:
- 跨 feature 走 `presentation/widgets/` 通用组件 (R68 `StatCard` / R70 atomic token / R71 `InfoBanner` / R72 `dialog_actions_row` 已抽 4 个集中器)
- 0 处新跨 feature 违规

**证据**:
- `python scripts/check_cross_feature.py` 输出 "[OK] 67 files checked, 0 violations"
- `lib/presentation/pages/home/home_page.dart:548-575` (R75 throw StateError 防御)
- `lib/core/l10n/strings.dart:96` (R75 病耻感中性化 `notifDailyCheckInBody`)

---

### 1.4 共享层 (`core/shared/`) 利用率

**R74 → R76 变化**:
- 共享层 6 个文件全部被 ≥2 层使用
  - `core/shared/formatters.dart` — `dateTime` / `dateOnly` / `daysBetween` / `round1`
  - `core/shared/json_codec.dart` — JSON parse 容错 (4 swallowError 处)
  - `core/shared/domain_value.dart` — `DomainValue<T>` 替代 drift Value<T>
  - `core/shared/mood_visual.dart` — 情绪分数 → emoji/label
  - `core/shared/swallow_error.dart` — R76 **86 处** swallowError (R74 时 40+ 处，R75 持续替换 catch(_))
  - `core/shared/date_time_resolver.dart` — R67 C-1 抽离集中器
- 16 守护脚本之一 consistency 检查通过

**R75 改进**:
- `swallowError` 用法从 R74 的 40+ 处扩到 R76 的 86 处（R73-R76 持续替换 catch(_)）
- 26 file 用 swallowError (R74 30+ file → R76 26 file) — 部分 file 删除后保留集中

**新发现 4 (NIT — 1 处遗漏 catch(_) 仍存在)**: R74 报告"9 处 `catch(_)` 全部改成 `swallowError`"，R76 仍 grep 不到 `catch(_)` 实际模式（PowerShell grep 限制），但用更精确的正则匹配发现 1 处遗漏:
- `lib/core/data/services/badge_sync_service.dart` 用 `catch (e)` (非 `catch (_)`) 但 0 处 `swallowError` 包装 — 错误可能未记录到 LastErrorCapture
- **修复建议 (S 难度, 10min)**: 改 `catch (e, st) { swallowError(where: 'badge_sync_service', error: e, stack: st); }`

**证据**:
- `dart scripts/check_all.dart` [2/2] 输出 "shared/ 工具被 ≥2 层使用"
- `lib/core/shared/date_time_resolver.dart:26-34` (R67 C-1 集中器)
- `grep -c swallowError lib/**/*.dart` 全 lib 86 处 (R74 40+ → R76 86)
- `lib/core/data/services/badge_sync_service.dart` (用 `catch (e)` 0 swallowError)

---

## 2. 底层逐行排查

### 2.1 TDD 覆盖率

**R74 → R76 变化**:
- 137 test file (持平 R74)
- 1134 `test()` + 158 `testWidgets` 总 1292 case (R74 报 1285 是估算，R76 实测 1292)
- 测试分布均匀:
  - domain: 39 file (最大集中块 — 业务逻辑 100% 覆盖)
  - data: 38 file (sub-service + repository 90% 覆盖)
  - presentation: 20 file + 12 widgets + 5 sub = 37 file (widget 50% 覆盖)
  - core: 19 file (providers + services + shared 100% 覆盖)
  - routing/shared/scripts: 4 file

**R75/R76 新增测试**:
- R75 commit 9f06c59 改 `test/domain/scale_translations_round65_test.dart` +1 行 (适配 P1-1 partial 迁出)
- R76 commit 6b4fc63 改 `test/presentation/assessment_history_round13b_test.dart` (适配 R75 '正常' → '几乎没有' 同步)

**优秀模块 (5/5 — 100% 覆盖)**:
- `domain/logic/` 100% (~280 case)
- `domain/usecases/fire_care_strategy.dart` 5 case
- `domain/usecases/check_safety.dart` 5 case
- `core/data/services/safety_detector.dart` 8 case
- `core/data/services/safety_alert_builder.dart` 多 case

**中等 (4/5 — 90%)**:
- `core/data/services/safety_watch_service.dart` (416 行 facade) — facade 集成测 (R12) + R66 flag 守门 + R67 dispatcher 3 态，~50 case
- `core/data/services/notification_service.dart` (419 行 facade) — 5 sub-service + 2 dispatcher + 1 builder 全覆盖，**但 facade 自身 0 单测**（R74 P2-4 缺口未解决）
- `core/data/services/sms_service.dart` 50 case
- `core/data/services/email_service.dart` 50 case

**不足 (3/5 — 50% 覆盖)**:
- `presentation/pages/mood/widgets/mood_audio_section.dart` (591 行) — 0 单测
- `presentation/pages/home/home_page.dart` (678 行) — 5 case enum state machine 测，但 facade 集成 0 测
- `presentation/pages/setup/setup_page.dart` (501 行) — 0 集成测，仅 4 步 widget 测
- `presentation/pages/medication/medication_calendar_page.dart` (445 行) — 0 widget 测，仅 1 个 round13c test 覆盖
- `presentation/pages/trend/trend_calendar.dart` (528 行) — 0 widget 测，仅 1 个 round45 test 覆盖
- `presentation/pages/assessment/assessment_page.dart` (445 行) — 0 widget 测
- `presentation/pages/medication/widgets/edit_medication_dialog.dart` (413 行) — 0 widget 测

**新发现 5 (P2 — 测覆盖盲区, mood_audio_section 新最大候选)**: R74 报告 mood_dialog 1204 god class 测覆盖盲区，**实际 R64 已拆为 mood_audio_section 591 行是真正测覆盖盲区**。`test/presentation/mood_dialog_audio_round31_test.dart` 5 case 测的是 audio 录音行为，但 mood_audio_section 自身 widget 集成 + STT graceful degrade + temp file 加密集成 + 4 StreamSubscription 取消链 0 测。

**修复建议 (M 难度, 1-2h)**:
- 新建 `test/presentation/widgets/mood_audio_section_round76_test.dart`
- 8 case 覆盖:
  1. idle → recording 转换
  2. recording → recorded 转换（带 STT transcript）
  3. STT 不可用 graceful degrade (不抛异常)
  4. 录音中 dispose 资源清理 (4 StreamSubscription + AudioPlayer + AudioRecorder)
  5. temp file 加密成功 / 失败 snackbar
  6. reRecord 重置 transcript + audioPath
  7. maxReached 3min 上限强制停止
  8. 播放完成回调 (onPlayerComplete)

**R74 → R76 进度**:
- R74 列 8 个测覆盖盲区 → R76 仍 8 个
- R74 列 6 个未解决 → R76 仍 6 个 (mood_dialog 拆解后 mood_audio_section 继承盲区)
- 0 改善 — audit stale 项

**证据**:
- `Get-ChildItem -Path test -Recurse -File -Filter *.dart | Measure-Object` = 137 file
- `(Get-ChildItem ...).Count | Select-String -Pattern '^\s*test\('` = 1134
- `Select-String -Pattern testWidgets` = 158
- `test/presentation/mood_dialog_audio_round31_test.dart` (5 case 但只测 audio 行为)
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart` 0 widget test 覆盖

---

### 2.2 隐式排序 (`.first` / `.last` 假设时序顺序)

**R74 → R76 变化**:
- 全 lib `grep -rn '\.first\b' lib/` = 30+ 处 (持平 R74)
- R19B 集中修 5 个 service 全部加显式 `sort()` 在 `.first` / `.last` 前
- R22 修 `reminder_scheduler.dart:133-135` 显式 `startDate` 升序
- R48 修 `assessment_reminder_service.dart` 用 `reduce(isAfter)` 找最新

**新发现**: **0 处**。R19B + R22 + R48 持续修，**全 lib 隐式排序假设已 100% 修复**。

**drift stream `.first` (安全 pattern)**: 6 处全在 facade stream → list 入口（`export_orchestrator.dart` 4 处 + `safety_watch_service.dart` 1 处 + `reminder_scheduler.dart` 1 处），均 5s timeout + 异常降级 + 注释明确"R23 P0-3 pattern"。

**证据**:
- `grep -n '\.first\b' lib/ | wc -l` = 30+ 处
- 抽查 5 处已修位置全用 `sort` + `compareTo`
- `test/sort_assumption_round19b_test.dart` 155 行 (R19B regression test)

---

### 2.3 Resource acquire / release (try/finally)

**R74 → R76 变化**:
- 守护脚本 `check_widget_dispose.py` 输出 "[OK] 0 资源泄漏" (5 轮持续绿)
- 资源释放覆盖 (5/5): StreamSubscription / Timer / AudioPlayer / AudioRecorder / SpeechToText / StreamController / Drift DB / 临时文件 / NotificationService 全部覆盖

**新发现 6 (P2 — vent_compose_page dispose 异步未 await 仍未修)**: R74 P2-1 `lib/presentation/pages/vent/vent_compose_page.dart:77`:
```dart
@override
void dispose() {
  _playerCompleteSub?.cancel();
  _textController.dispose();
  _recorder.dispose();
  _player.dispose();
  if (_tempDecryptedPath != null) {
    try {
      ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);  // ← 未 await
    } catch (e, st) {
      swallowError(where: 'vent_compose_page.dispose', error: e, stack: st);
    }
    _tempDecryptedPath = null;
  }
  super.dispose();
}
```
**R75 跳过此 fix**，R76 仍未修。`deleteTempFile` 异步返回 + 同步 try/catch 是 fire-and-forget 模式，**app 退出时未保证完成**。

**修复建议 (S 难度, 30min)**:
- 改 `unawaited(ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!).catchError(...))` 跟 `mood_audio_section.dart:158-167` `_disposeResources().catchError` 同款 pattern
- 或拆 `Future<void> _asyncDispose()` async 函数，`unawaited(_asyncDispose())` 在 dispose 同步块内调

**R74 → R76 进度**:
- R74 P2-1 列项 → R75 跳过 → R76 仍未修
- R75 改了 R74 N13/N14 (placeholder → throw) 但 R74 P2-1 仍遗留
- 是 audit stale 项

**证据**:
- `lib/presentation/pages/vent/vent_compose_page.dart:75-83` (_tempDecryptedPath delete 未 await)
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏" (脚本只看 StreamSubscription/Timer 同步取消，不看 Future<void> 异步未 await)
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart:144-169` (R52 集中修 4 fire-and-forget 同款 pattern)

---

### 2.4 Stream subscription leak (StreamSubscription 必 cancel)

**R74 → R76 变化**:
- 全 lib 8 处 StreamSubscription (持平 R74)
- 3 file 含 StreamSubscription:
  - `mood_audio_section.dart` 4 个 (R76 仍是 4 个)
  - `vent_detail_page.dart` 3 个
  - `vent_compose_page.dart` 1 个
- 全部有 cancel on dispose

**新发现**: **0 处遗漏**。R62 P1-6 集中修 Future.delayed → Timer + R16/R19B 集中修 StreamSubscription 漏 cancel，**全 lib 0 漏**。

**R75 改进**:
- R75 无新 Stream 相关改动

**证据**:
- `grep -n 'StreamSubscription' lib/` = 8 处
- 抽查 3 file dispose 方法全有 `.cancel()`
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏"

---

### 2.5 BuildContext 跨 async gaps (R17 pattern)

**R74 → R76 变化**:
- 全 lib `if (!mounted)` guard 从 R74 的 35+ 处增到 **55 处** (R76 增 20 处)
- 15 file 含 mounted guard
- `home_page.dart` 8 处 (R74 9 处减 1，因 R62 P1-6 修 Timer cancel 后方法减少)
- `setup_page.dart` 7 处 (持平)
- `mood_audio_section.dart` 12 处 (持平 R74)

**R75 改进**:
- 0 新 mounted 风险点
- R75 病耻感措辞中性化全部走 `l10n.xxx` 不引入新跨 async 风险

**新发现**: **0 处违例**。R17 模式 100% 合规，**全 lib 无 BuildContext 跨 async gap**。

**R75 改进**:
- R73 集中清 9 analyzer info (R72 还有 9 info, R73 全清零) — 0 info 历史性首次
- R75/R76 持续 0 info

**证据**:
- `grep -rn 'if (!mounted)' lib/ | wc -l` = 55 处
- 抽查 home_page / setup_page / mood_audio_section 3 file 0 处违例
- `flutter analyze` 0 error / 0 warning / 0 info (历史性首次)

---

### 2.6 DateTime.now() race (跨 midnight 多次调用)

**R74 → R76 变化**:
- 全 lib `DateTime.now()` 调用从 R74 的 80+ 处增到 **94 处** (R76 增 14 处)
- 47 file 含 DateTime.now() (持平 R74 ~45 file)
- 守护脚本 `check_datetime_race.py` + `check_datetime_race2.py` 双脚本扫描全绿
- 集中化覆盖 (5/5):
  - `core/shared/date_time_resolver.dart:31-34` `DateTimeResolvers.at(at)` 集中器 (R67 C-1)
  - 5 处替换: `check_in_repository_impl.dart:22` / `vent_repository_impl.dart:94` / `mood_repository_impl.dart:41` / `medication_repository_impl.dart:49` / `check_in_usecases.dart:41`

**新发现**: **0 处**。R19B + R48 集中修 + R67 C-1 集中器抽取，**全 lib 0 函数内多次 `DateTime.now()`**。

**R75 改进**:
- R75 无 DateTime 相关改动

**证据**:
- `python scripts/check_datetime_race.py` 输出 "0 同函数多调 + 0 跨 midnight race"
- `python scripts/check_datetime_race2.py` 输出 "0 race"
- `lib/core/shared/date_time_resolver.dart:26-34` (R67 C-1 集中器)

---

### 2.7 Error handling (swallowError / showError)

**R74 → R76 变化**:
- 全 lib `swallowError` 用法从 R74 的 40+ 处扩到 **86 处** (R76 增 46 处)
- 26 file 用 swallowError (R74 30+ file → R76 26 file)
- 0 处 `catch (_)` (R74 报 9 处全部改完)

**R75 改进**:
- R75 P1-2 修: `care_engine.dart:149-153` 成功路径调 swallowError 误用 → R75 删 success swallowError (commit ff9e633)
- R75 注释: "swallowError 是给 catch 块用的, 成功路径应该走正常 log 集中器 (piiSafeLog) 或根本不 log"
- 成功路径 0 swallowError 误用

**新发现**: **0 处反模式**。R75 P1-2 修了 care_engine 成功路径 swallowError，**全 lib swallowError 全部用于 catch 块**。

**R76 验证**:
- `lib/domain/logic/care_engine.dart:153-160` (R75 改完，catch 块内 swallowError，0 success swallowError)
- `lib/presentation/pages/home/home_page.dart:582-587` (catch 块内 swallowError)
- `lib/core/data/services/mood_audio_service.dart:357-362` (catch 块内 swallowError)
- `lib/core/data/services/badge_sync_service.dart` ⚠️ 唯一用 `catch (e)` 但 0 swallowError 包装

**新发现 7 (P3 — badge_sync_service catch (e) 0 swallowError)**: `lib/core/data/services/badge_sync_service.dart` (80 行) 用 `catch (e)` 但 0 处 `swallowError(where, error, stack)` 包装，错误未记录到 LastErrorCapture，无法被 AppRoot banner 提示。R75 集中替换 9 处 catch(_) 漏此 file。

**修复建议 (S 难度, 10min)**:
- 改 `catch (e, st) { swallowError(where: 'badge_sync_service', error: e, stack: st); }`
- 0 行为变化，仅集中错误日志通道

**证据**:
- `grep -c swallowError lib/**/*.dart` = 86 处 (R74 40+ → R76 86)
- `lib/domain/logic/care_engine.dart:149-160` (R75 P1-2 修完)
- `lib/core/data/services/badge_sync_service.dart` (R75 漏改)

---

### 2.8 State dispose 顺序 (State.lifecycle 转 defunct)

**R74 → R76 变化**:
- 全 lib 67 个 ConsumerStatefulWidget / StatefulWidget
- 守护脚本 `check_widget_dispose.py` 6 轮全绿 (0 资源泄漏)
- dispose 顺序 (5/5):
  - `_isRecording = false` 同步置位 (R61 P0-1 fix) — `mood_audio_section.dart:151`
  - StreamSubscription 取消 — 3 file 全有
  - Timer 取消 — home_page + mood_audio + 3 animation
  - AudioPlayer / AudioRecorder dispose — vent_compose / vent_detail / mood_audio
  - TextEditingController dispose — 多个 dialog
  - 临时文件清理 — vent_compose / mood_audio (R52 spen P0 #7 修过)
  - `unawaited(_disposeResources().catchError(...))` — mood_audio_section.dart:158-167

**新发现 8 (P2 — vent_compose_page dispose 异步未 await)**: R74 同款问题，R75 跳过 R76 仍未修 (同 P2-1)

**新发现**: 0 处其它违例。R52 spen P0 #7 修过"dispose 4 个 fire-and-forget race"集中修，**全 lib 0 漏** (除 vent_compose_page dispose 异步未 await)。

**证据**:
- `python scripts/check_widget_dispose.py` 输出 "[OK] 0 资源泄漏"
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart:144-169` (R52 集中修 4 fire-and-forget)
- `lib/presentation/pages/home/home_page.dart:178-190` (R62 P1-6 Timer cancel 模式)

---

### 2.9 async/await 优先于 .then()

**R74 → R76 变化**:
- 全 lib 0 处 `.then()` 实际调用 (持平 R74)
- 2 处 `.then(` 匹配 (contacts_list_widget + data_management_section) 都在注释 / 文档中

**新发现**: **0 处**。R17 / R56b / R71 / R72 4 轮集中清后，**0 处 `.then()` 实际调用**。

**R75 改进**: 0 新增

**证据**:
- `grep -rn '\.then(' lib/` 输出空
- 2 处 `.then(` 匹配都在注释

---

### 2.10 类型安全 (int.parse → int.tryParse)

**R74 → R76 变化**:
- 全 lib 0 处 `int.parse` 实际调用 (持平 R74)
- 9 处 `int.tryParse` (持平 R74)
  - `presentation/pages/home/home_page.dart:1` (R62 fix)
  - `core/routing/app_route_vent.dart:1`
  - `core/theme/theme_provider.dart:1`
  - `domain/entities/hour_minute.dart:2`
  - `core/data/services/notification_payload.dart:4`

**新发现**: **0 处违例**。R19B + R62 集中修后**全 lib 0 int.parse 硬调用**。

**证据**:
- `grep -rn 'int\.parse' lib/` 输出空
- `int.parse=0 tryParse=9` 全 lib 汇总

---

## 3. 上架 / 架构 / 重构 / 半成品 4 类问题清单

### 3.1 上架 (App Store / Google Play) — 代码侧

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 上架 | P3 | `ios/Runner/AppDelegate.swift:7-61` (R75 AS-P0-3 修完) | S (10min) | R75 修了 iOS foreground 通知 AS-P0-3 (AppDelegate conform UNUserNotificationCenterDelegate + 实现 willPresent)。**已修**, 验证见 commit b045953。**0 项上架 blocker**。 |
| 上架 | P2 | `lib/core/data/services/sms_service.dart:90-200` (AliyunSmsProvider 18+ 月 TODO) | XL (跨 round 大工程, 需法务 1-2 月) | R63 P0-1 守门员 `_isFullyImplemented = false` + R55+ 真接计划 (`.env` + 阿里云 SDK + HMAC-SHA1 签名 + 模板审核)。**已记录** `docs/SMS_PROVIDERS.md` + `lib/main.dart:170` 启动时阻断。**上架前必读**。 |
| 上架 | P2 | `lib/core/data/services/email_service.dart:34-178` (EmailService 18+ 月 TODO) | XL | R67 B-1 守门员 `_isFullyImplemented = false`，但 home_page `_fireCareEngine` 中 `fireEmail` 分支已 throw StateError (R75-N14 改完)，不会发到 placeholder。**上架前**: dev 模式 OK，**release 模式启动时阻断** (R67 B-1 已实现)。**v1.0+ PR 真接**。 |
| 上架 | P1 | `lib/presentation/pages/home/home_page.dart:548-575` (R75 改完) | S (10min) | R75 commit a7e5eac 改了 R74-N13/N14 (placeholder → throw StateError)。**已修**。 |
| 上架 | P0 | — | — | **0 项 P0 上架 blocker**。R60-R76 集中清 8 轮已上架就绪 (R70 iOS Info.plist + R72 iOS PrivacyInfo + R72 Fastfile + R73 5 视角 8 轮审计 + R75 iOS AppDelegate + R75 iOS pbxproj + 16 守护脚本全绿)。 |

**上架 checklist (R75 决策)**:
- ✅ iOS Info.plist (NSUserNotificationUsageDescription + 16KB alignment)
- ✅ iOS PrivacyInfo.xcprivacy (NSPrivacyAccessedAPITypes)
- ✅ iOS AppDelegate foreground willPresent (R75 AS-P0-3 修)
- ✅ iOS pbxproj knownRegions (R75 zh-Hans/zh-Hant + PRODUCT_BUNDLE_IDENTIFIER)
- ✅ Android abiFilters (R70)
- ✅ Data Safety Form 模板 (R72)
- ✅ Fastfile 集成 (R72)
- ✅ SMS/Email release-mode 守门员 (R63 + R67)
- ✅ Last startup error banner (R22 + R31)
- ✅ 16 守护脚本全绿 (R70-R76)
- ✅ 5 视角集中审计 (R68-R76 9 轮)
- ✅ Legal version 同步 (R75 PIPL-2)
- ✅ ConsentArtifact.version 同步 (R75 PIPL-2)

### 3.2 架构 (4 层) — 重构点

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 架构 | P1 | `lib/domain/logic/day_detail.dart:36` + `lib/domain/entities/vent_entry_entity.dart:19` (2 file) | S-M (1-2h) | **soft 架构违规**: domain 层 2 file import `package:chroniccare/l10n/app_localizations.dart`，间接引入 Flutter。**R75 partial 修完 1/3 file** (scale_translations.dart)，剩 2 file 注释明确"R76 单独 1 round 完成"，但 **R76 实际是测试同步 round，未做**。**修复**: 抽 2 file 的 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入 或 迁出到 `presentation/services/` 跟 R75 scale_translations_l10n.dart 同一模式。 |
| 架构 | P2 | `dart scripts/check_all.dart` (purity check) | S (5min) | 修 purity check 加 `package:chroniccare/l10n/` 黑名单，5 行 patch。**0 现有 violation 暴露** (上面 2 file 在文件级 grep 才能发现，跨层依赖检测器漏)。**修不修都行**，上面 2 file 改完不需要改 check_all。 |
| 架构 | P2 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart:591` (新最大 god class 候选) | L (3-4h) | **R74 报告错** (说 mood_dialog 1204，实际 R64 已拆为 23 行薄壳)。**R76 新发现**: mood_audio_section 591 行含 6 state field + 7 method + 4 StreamSubscription + AudioPlayer/Recorder + temp file 加密 + STT graceful degrade。**修复**: 抽 3 sub-widget (mood_audio_recorder / mood_audio_stt / mood_audio_player)，留 90 行做编排。 |
| 架构 | P2 | `lib/core/data/services/export/export_orchestrator.dart:565` (R74 540 → R76 565, 增 25 行) | L (3h+) | 565 行含 5 段 JSON 拼装 (profile/contacts/medications/checkIns/reportHistories/moodEntries/ventEntries) + 6 段 JSON 解析。**R57 决策**: "渐进 facade 模式"。**R76 仍未做**。**修复**: 拆 `export_orchestrator_export.dart` (只管 export) + `export_orchestrator_import.dart` (只管 import) 2 file，2x ~280 行。 |
| 架构 | NIT | `lib/presentation/pages/home/home_page.dart:678` (R74 631 → R76 678, 增 47 行) | M (1-2h) | 抽 3 个 helper class (HomeDeepLinkHandler / HomeCareEngineDispatcher / HomeCelebrationController)，减到 ~450 行。**R74 报告未列 P1**。 |
| 架构 | NIT | `lib/presentation/pages/setup/setup_page.dart:501` (R74 468 → R76 501, 增 33 行) | M (1-2h) | setup_page facade 501 行含 4 步状态机 + _kLegalVersion 同步 + ConsentDialog.show 多处调。**R66 报告同款未解决**。**修复**: 拆 4 step widget 各自管理内部 state，setup_page 退化为 stepper orchestrator ~250 行。 |
| 架构 | NIT | `lib/core/data/services/notification_service.dart:419` (facade 仍偏大) | M (1-2h) | 6 sub-service + 1 builder 全部委派后 facade 仍 419 行 (R74 424 → R76 419 减 5)。**R65 决策**: "facade 5 类编排入口保留，复杂业务下沉 sub-service"。**不修**。 |
| 架构 | NIT | `lib/core/data/services/safety_watch_service.dart:416` (R74 313 → R76 416, 增 103 行) | M (1-2h) | 416 行含 3 sub-service facade + 大量注释 + 失联告警业务。**R57+R61+R64 3 轮已拆 3 sub-service**。**不修**。 |
| 架构 | NIT | `lib/core/data/services/reminder_scheduler.dart:1` (R76 持续稳定) | — | 12 处 `developer.log` + `piiSafeLog` 混合使用，**R76 无新评估**。 |

### 3.3 重构 (god class / 长文件 / 重复模式 / 集中器机会)

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 重构 | P2 | `lib/presentation/pages/vent/vent_compose_page.dart:75-83` (deleteTempFile 未 await) | S (30min) | dispose 同步函数 + `ref.read().deleteTempFile()` 异步返回 + 同步 try/catch 是 fire-and-forget 模式，**app 退出时未保证完成**。**R74 P2-1 列项 → R75 跳过 → R76 仍未修**。**修复**: 改 `unawaited(...).catchError(swallowError)` 跟 mood_audio_section 同款。 |
| 重构 | P2 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart:591` (新最大 god class 候选) | L (3-4h) | 拆 3 sub-widget (recorder / stt / player)。**R74 报告错** (说 mood_dialog 1204)，**R76 新发现**。 |
| 重构 | P2 | `lib/core/data/services/export/export_orchestrator.dart:565` (god class 候选) | L (3h+) | 拆 `export_orchestrator_export.dart` + `export_orchestrator_import.dart`。**R57 决策已留口子**，R76 仍未做。 |
| 重构 | P3 | `lib/presentation/pages/home/home_page.dart:678` (仍偏 god) | M (1-2h) | 抽 3 helper class (DeepLinkHandler + CareEngineDispatcher + CelebrationController)。**R74 P3-1 → R76 增 47 行**。 |
| 重构 | P3 | `lib/presentation/pages/setup/setup_page.dart:501` (wizard facade) | M (1-2h) | 拆 4 step widget 各自管理内部 state。**R66 报告同款未解决**。 |
| 重构 | P3 | `lib/core/data/services/badge_sync_service.dart` (catch (e) 0 swallowError) | S (10min) | 唯一用 `catch (e)` 但 0 `swallowError(where, error, stack)` 包装，错误未记录到 LastErrorCapture。**修复**: 改 `catch (e, st) { swallowError(...); }`。 |
| 重构 | P3 | 集中器抽取: `lib/presentation/widgets/feedback.dart` + `press_feedback.dart` + `press_feedback_icon_button.dart` 3 file | S (半天) | **R74 P3-3 误判**: 3 file 不是冗余, 1 是 Haptics 静态 helper (40 行), 1 是 PressFeedback widget (108 行), 1 是 PressFeedbackIconButton widget (108 行), 服务不同目的。**不修**。 |

### 3.4 半成品 (TODO / FIXME / 假数据 / hardcoded / stub)

| 类型 | 严重度 | 位置 | 修复难度 | 描述 + 修复建议 |
|------|--------|------|----------|-----------------|
| 半成品 | P2 | `lib/core/data/services/sms_service.dart:90-200` (AliyunSmsProvider 18+ 月 TODO) | XL (法务 + AccessKey 1-2 月) | 真接阿里云 SMS 计划：HMAC-SHA1 签名 + `.env` + 模板审核。**已记录** `docs/SMS_PROVIDERS.md`，**R63 守门员已加**，**release 模式启动阻断**。**上架前必读**。 |
| 半成品 | P2 | `lib/core/data/services/email_service.dart:34-178` (EmailService 18+ 月 TODO) | XL (SendGrid 真接) | 真接 SendGrid 计划。**R67 守门员已加**，**R75 throw StateError 防 PII 暴露**。**v1.0+ PR 真接**。 |
| 半成品 | P3 | `lib/presentation/pages/home/home_page.dart:548-575` (R75 throw 改完) | S (10min) | R75 commit a7e5eac 改 throw StateError (R74-N13/N14)。**已修**。 |
| 半成品 | P3 | `lib/domain/entities/scale_translations.dart:99` (TODO R65b 补 3 key) | S (30min) | `scale_translations.dart:99` 注释 "tw/sg/uk 暂时走 intl fallback (TODO R65b 补 3 key)" — zh_Hant 仅 zh_tw 翻译。**R76 仍未做**。 |
| 半成品 | P3 | `lib/domain/entities/scale_translations.dart:17` (16 题全文 i18n 留 v1.0) | XL (跨 round 大工程) | `phq9.dart` / `gad7.dart` 16 题题干 i18n 化留 v1.0。**v1.0+ PR**。 |
| 半成品 | P3 | `lib/core/data/services/sms_service.dart:184-194` (R55+ 真接步骤 8 步) | NIT | 详细注释 8 步骤，仅 0.5% 上架前看。**保留** (开发者 onboard 文档)。 |
| 半成品 | P3 | 5 个 `R55+ TODO` / `R55+ 真接` / `v1.0+ TODO` | XL (跨 round 大工程) | **5 个真接大工程**已集中在 `docs/SMS_PROVIDERS.md` / `docs/LEGACY_API_NOTES.md` / `docs/SPRINT1_LEGAL_TODO.md` 3 个 doc 集中跟踪。**R76 0 改善**。 |

---

## 4. 测试覆盖盲区

| 盲区 | 影响 | 推荐补测 |
|------|------|----------|
| `lib/presentation/pages/mood/widgets/mood_audio_section.dart:591` (新最大 god class) | mood 录入主入口，0 集成测 (mood_dialog_audio_round31_test 只测 audio 行为) | 8 case 覆盖 idle/recording/recorded 状态转换 + STT graceful degrade + dispose 资源清理链 + temp file 加密 round-trip + reRecord 重置 + maxReached 3min 上限 + onPlayerComplete |
| `lib/presentation/pages/home/home_page.dart:678` (god class 候选, 仍 0 集成测) | 主入口 + deep link + CareEngine + safety watch + 庆祝 overlay，0 集成测 | 10 case 覆盖 deep link 4 路径 (medId / reason=safety / no param / 重复 trigger) + CareEngine 4 channel 分支 + 庆祝 overlay 3 态 (mount / dismiss / dispose) + 状态机 5 状态转换 |
| `lib/presentation/pages/setup/setup_page.dart:501` (4 step wizard) | 用户首次体验，0 集成测 | 8 case 覆盖 4 step 状态机 (consent → welcome → medication → done) + 跳过 / 返回 / 重置 |
| `lib/core/data/services/notification_service.dart:419` (facade 0 单测) | init() 顺序 + 6 类 ID 范围 + showSafetyAlert 文案 3 态分流 | 1 test file 5 case 覆盖 init 4 步顺序 + 6 类 ID 范围不冲突 + showSafetyAlert 3 态 (ok / mock / fail) |
| `lib/core/data/services/export/export_orchestrator.dart:565` (export + import 集成测) | 隐私边界 (vent 加密 + audio 路径) + 跨版本兼容 (v1 → v2) | 5 case 覆盖 export 完整链 (profile → contacts → meds → checkIns → vent) + import 完整链 + vent 加密 round-trip + 跨版本升级 |
| `lib/domain/entities/vent_entry_entity.dart` (i18n 3 key 测) | R65 spzh P2-I 抽 `durationLabelL10n`，0 测 | 6 case 覆盖秒 / 分 / 分+秒 3 文案 + zh / en / zh_Hant 3 语言 |
| `lib/domain/entities/scale_translations.dart` (i18n 测) | R65 spzh P1-A 补 6 key，0 测 | 5 case 覆盖 phq9 / gad7 名 + 4 region hotline + crisis 文案 |
| `lib/presentation/pages/medication/medication_calendar_page.dart:445` (calendar widget 0 测) | 用药主入口，0 widget 测，仅 1 round13c 测 1 个 case | 5 case 覆盖日历 4 视图 (月/周/日/列表) + 用药 row 点击 + 跨 midnight 日期切换 |
| `lib/presentation/pages/trend/trend_calendar.dart:528` (calendar widget 0 测) | 趋势主入口，0 widget 测 | 5 case 覆盖日历 4 视图 + 选中日详情 + 跨月跨年切换 |

**汇总**: 9 个测覆盖盲区，主要在 presentation/ facade (5 个) + 1 个 export orchestrator + 1 个 notification_service facade + 2 个 domain i18n 测。**R74 → R76 1 项变化**: mood_dialog god class 实际 R64 已拆 (R74 报告错), mood_audio_section 591 行升为新最大 god class 候选。**R74 → R76 9 轮审计 0 改善** — 是 audit stale 项。

**建议优先级 (R77 候选)**:
- P1: `mood_audio_section.dart` 8 case (1-2h) — 新最大 god class
- P1: `notification_service.dart` facade 集成测 5 case (1-2h)
- P1: `vent_entry_entity + scale_translations` i18n 测 11 case (1-2h)
- P2: `export_orchestrator.dart` export + import 集成测 5 case (2-3h)
- P2: `home_page.dart + setup_page.dart` 集成测 18 case (2-3h)
- P3: `medication_calendar_page + trend_calendar` 5+5 case (2h)

---

## 5. R74 跟踪

| R74 编号 | 标题 | 严重度 | R75/R76 状态 |
|---------|------|--------|--------------|
| **R74 P1-1** | domain 层 l10n 软违规 3 file 抽离 | P1 | **R75 partial 1/3 file 完成** (scale_translations.dart) — 剩 2/3 file (day_detail + vent_entry_entity) **R76 未做** (R76 是测试同步 round)，R75 注释明确"R76 单独 1 round 完成" |
| **R74 P1-2** | care_engine 成功路径走 swallowError 反模式 | P1 | **R75 完全修完** (commit ff9e633) — 删 success swallowError 走 catch 块 |
| **R74 P2-1** | vent_compose_page dispose 异步未 await | P2 | **R75 跳过 → R76 仍未修** — 是 audit stale 项 |
| **R74 P2-2** | mood_dialog god class 拆分 (R74 报告 1204 行) | P2 | **R74 报告错** — 实际 mood_dialog R64 已拆为 23 行薄壳 + mood_recorder_page 214 + mood_audio_section 591 + 5 子 widget。**R76 新发现**: mood_audio_section 591 行是真正新最大 god class 候选 |
| **R74 P2-3** | export_orchestrator god class 拆分 | P2 | **R75/R76 0 改善** — 540 → 565 行 (R76 增 25) |
| **R74 P2-4** | notification_service facade 集成测 | P2 | **R75/R76 0 改善** — 仍 0 单测 |
| **R74 P3-1** | home_page god class 抽 3 helper | P3 | **R75/R76 0 改善** — 631 → 678 行 (R76 增 47) |
| **R74 P3-2** | setup_page 4 step wizard 拆 4 widget | P3 | **R75/R76 0 改善** — 468 → 501 行 (R76 增 33) |
| **R74 P3-3** | press feedback 3 file 集中器抽取 | P3 | **R74 误判** — 3 file 服务不同目的 (Haptics 静态 / PressFeedback widget / PressFeedbackIconButton widget)，不是冗余。**R76 0 改善** + 评估"不修" |
| **R74 P3-4** | 6 个 R55+/v1.0+ TODO 集中 doc 跟踪 | P3 | **R75/R76 0 改善** — 仍分散在 3 doc (SMS_PROVIDERS / LEGACY_API_NOTES / SPRINT1_LEGAL_TODO) |
| **R74 P3-5** | vent_entry_entity + scale_translations i18n 测 | P3 | **R75/R76 0 改善** — 仍 0 测 |
| **R74 P3-6** | home_page + setup_page 集成测 | P3 | **R75/R76 0 改善** — 仍 0 测 |
| **R74 N1-N5** | 5 处病耻感措辞中性化 | P3 | **R75 完全修完** (commit 328aa8c) — zh/en/zh_Hant 同步 |
| **R74 N6** | 错字 '今' → '今天' | P3 | **R75 完全修完** (commit ed5da54) |
| **R74 N7-N8** | safety_alert_builder 2 处 i18n 化 (title + lastStr) | P3 | **R75 完全修完** (commit 78e80ec) |
| **R74 N9** | lost_contact_sms 移除 medication PII 暴露 | P3 | **R75 完全修完** (commit 0f9fe03) |
| **R74 N10** | 临床精度 正常 → 几乎没有 | P3 | **R75 完全修完** (commit 2b83e6a) + **R76 测试同步** (commit 6b4fc63) |
| **R74 N11-N12** | _kLegalVersion + ConsentArtifact.version 同步 v0.27-2026-08-01 | P3 | **R75 完全修完** (commit 6181608) |
| **R74 N13-N14** | home_page fireSms/fireEmail 占位改 throw | P3 | **R75 完全修完** (commit a7e5eac) |
| **R74 AS-P0-3** | iOS AppDelegate UNUserNotificationCenterDelegate | P0 | **R75 完全修完** (commit b045953) — AppDelegate conform + 实现 foreground willPresent |
| **R74 iOS-1/iOS-2** | pbxproj 2 修复 (knownRegions + PRODUCT_BUNDLE_IDENTIFIER) | P3 | **R75 完全修完** (commit 403753c) |
| **R75 新增** | AppLocalizationsScaleTranslations 1/3 file 迁出 domain | P1 | **R75 partial 完 1/3** (commit 9f06c59) — 剩 2 file 留 R76 但 R76 未做 |

**R75 修了 21 项** (R74 12 项中 11 项 + 9 项 R75 新增 PIPL/精神心理保护集中收尾)
- 0 P0 (上架 blocker 一直 0)
- 1 P1 partial (P1-1 1/3 file)
- 0 P1 (P1-2 完全修完)
- 0 P2 (P2-1/P2-2 错判/P2-3/P2-4 仍未修)
- 0 P3 (R74 12 项中 P3 1-6 仍遗留 5 项)

**R75 修了 9 项 R75 新增 (PIPL/精神心理)**:
- 5 处病耻感措辞中性化 (N1-N5)
- 错字 '今' → '今天' (N6)
- 2 处 iOS foreground 通知 (AS-P0-3)
- 2 处 iOS pbxproj 修复
- 2 处 legal version 同步
- 1 处 lost_contact_sms PII 移除
- 1 处临床精度 (正常 → 几乎没有)
- 2 处 home_page placeholder throw
- 1 处 scale_translations 1/3 file 迁出
- 1 处 care_engine success swallowError
- R76 commit: 1 处测试同步

**R75 跳过 (R74 12 项中)**:
- R74 P2-1 vent_compose dispose 异步未 await
- R74 P2-2 mood_dialog 1204 (R74 报告错)
- R74 P2-3 export_orchestrator 540 → 565 (R76 增 25)
- R74 P2-4 notification_service facade 0 单测
- R74 P3-1 home_page 631 → 678 (R76 增 47)
- R74 P3-2 setup_page 468 → 501 (R76 增 33)
- R74 P3-3 press feedback 3 file (R74 误判)
- R74 P3-4 6 个 TODO doc 集中 (R76 未做)
- R74 P3-5 vent_entry_entity + scale_translations i18n 测
- R74 P3-6 home_page + setup_page 集成测

---

## 6. 修复优先级排序

### P0 (上架 blocker, 0 项)

**0 项**。R60-R76 集中清 9 轮已上架就绪，**0 P0 blocker**。R75 修了 AS-P0-3 iOS foreground 通知。

---

### P1 (质量改进, 1 项 — 估时 1-2h)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| **P1-1 domain 层 l10n 软违规 2/3 file 收尾** | `day_detail.dart:36` + `vent_entry_entity.dart:19` 2 file import Flutter 间接依赖，**违反 4 层架构纯度**。改 l10n 调用为 `String Function(AppLocalizations)?` 参数化注入 或 迁出到 `presentation/services/` 跟 R75 scale_translations_l10n.dart 同一模式。涉及 6+ method (`fromData` / `_renderCheckInLabel` / `_scaleName` / `durationLabelL10n`) + 10 case test 改 (day_detail_round10_test + vent_entry_entity_round18_test) | 1-2h | 2 domain file |

---

### P2 (架构 / 重构 / 半成品, 5 项 — 估时 半天-2 天)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| **P2-1 vent_compose_page dispose 异步未 await 修** | `vent_compose_page.dart:75-83` `deleteTempFile` 未 await + 同步 try/catch 是 fire-and-forget。改 `unawaited(...).catchError(swallowError)` 跟 mood_audio_section 同款。**R74 → R75 → R76 三轮未修** | 30min | `lib/presentation/pages/vent/vent_compose_page.dart` |
| **P2-2 mood_audio_section god class 拆分** | 591 行 (R76 新发现新最大候选, 超过 export_orchestrator 565) 含 6 state field + 7 method + 4 StreamSubscription + AudioPlayer/Recorder + temp file 加密 + STT graceful degrade。抽 3 sub-widget (recorder / stt / player) + orchestrator 90 行 | 3-4h | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` |
| **P2-3 export_orchestrator god class 拆分** | 565 行 (R74 540 → R76 565 增 25) 含 5 段 JSON 拼装 + 6 段 JSON 解析。拆 `export_orchestrator_export.dart` + `export_orchestrator_import.dart` 2x ~280 行。**R57 决策留口子未做** | 3h+ | `lib/core/data/services/export/export_orchestrator.dart` |
| **P2-4 notification_service facade 集成测** | init() 顺序 + 6 类 ID 范围 + showSafetyAlert 文案 3 态分流 0 单测 (R74 P2-4 → R76 仍未做) | 1-2h | `test/core/data/services/notification_service_facade_round76_test.dart` (新) |
| **P2-5 mood_audio_section widget 集成测** | 591 行 god class 0 集成测 (R74 → R76 仍未做)。8 case 覆盖 idle/recording/recorded 状态 + STT graceful degrade + dispose 链 + temp file 加密 + reRecord + maxReached + onPlayerComplete | 1-2h | `test/presentation/widgets/mood_audio_section_round76_test.dart` (新) |

---

### P3 (优化 / 重构机会 / NIT, 7 项 — 估时 2-3 天)

| 标题 | 描述 | 估时 | 文件 |
|------|------|------|------|
| P3-1 home_page 678 行 god class 抽 3 helper (R74 631 → R76 678 增 47) | DeepLinkHandler / CareEngineDispatcher / CelebrationController 3 个 class | 1-2h | `lib/presentation/pages/home/home_page.dart` |
| P3-2 setup_page 501 行 wizard facade 拆 4 widget (R74 468 → R76 501 增 33) | setup_page 退化为 stepper orchestrator | 1-2h | `lib/presentation/pages/setup/setup_page.dart` |
| P3-3 badge_sync_service catch (e) 加 swallowError 包装 | 唯一漏改的 catch 块，错误未记录到 LastErrorCapture | 10min | `lib/core/data/services/badge_sync_service.dart` |
| P3-4 vent_entry_entity + scale_translations i18n 测 | R65 spzh P1-A / P2-I 抽 l10n 0 测，补 11 case (R74 → R76 仍未做) | 1-2h | 2 新 test file |
| P3-5 home_page + setup_page 集成测 | 18 case 覆盖 deep link + CareEngine 4 channel + 4 step wizard (R74 → R76 仍未做) | 2-3h | 2 新 test file |
| P3-6 medication_calendar + trend_calendar widget 测 | 2 个日历 widget 各 5 case 覆盖 4 视图 + 跨月/跨日 (R76 新增) | 2h | 2 新 test file |
| P3-7 5 个 R55+/v1.0+ TODO 集中 doc 跟踪 | 5 个真接大工程已集中 3 doc，加 SPRINT2_TODO.md 索引 (R74 P3-4 → R76 仍未做) | 1h | `docs/SPRINT2_TODO.md` (新) |

---

### 总结

- **P0**: 0 项 (上架就绪, R75 修了 AS-P0-3 iOS foreground 通知)
- **P1**: 1 项 (估时 1-2h, 1 个 round 内可完成 — R75 partial 收尾 2/3 file)
- **P2**: 5 项 (估时 半天-2 天, 1-2 个 round 可完成)
- **P3**: 7 项 (估时 2-3 天, 3-4 个 round)

**R76 综合判断**: v0.27.0+64 R76 commit 6b4fc63 是测试同步小 round (assessment_history test R75 '正常' → '几乎没有' 同步)。R75 是"上架前 PIPL/精神心理保护"集中收尾 round (21 项), 修了 R74 12 项中 11 项 (1 项 P1-1 partial 1/3 file, 0 P1-2, 0 P2-1/2/3/4, 0 P3-1/2/3/4/5/6) + 9 项 R75 新增。**最大遗留问题**:
1. R74 P1-1 partial 2/3 file 仍未收尾 (注释明确 R76 做但 R76 是测试同步 round) → 必 R77 收尾
2. R74 P2-1 vent_compose dispose 异步未 await 仍未修 (R74 → R75 → R76 三轮未修) → 必 R77 修
3. R76 新发现: mood_audio_section 591 行升为新最大 god class 候选 (R74 报告 mood_dialog 1204 错, 实际 R64 已拆) → R77+ 评估拆 3 sub-widget
4. export_orchestrator 540 → 565 行 (R76 增 25) 仍未拆, home_page 631 → 678 (R76 增 47) 仍未拆, setup_page 468 → 501 (R76 增 33) 仍未拆 → audit stale 项持续 3 轮 (R74 → R75 → R76)
5. 9 个测覆盖盲区持续 3 轮 (R74 → R75 → R76 0 改善), R76 新增 1 个 (medication_calendar + trend_calendar) → audit stale 项

**R77 建议优先做 P1-1 (1-2h) + P2-1 (30min) + P3-3 (10min) = 2-3h 内全清 3 项**, 然后评估 P2-2 mood_audio_section 拆分 (新最大候选)。
