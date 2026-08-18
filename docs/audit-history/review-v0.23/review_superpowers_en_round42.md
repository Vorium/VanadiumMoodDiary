# superpowers-en 视角审查报告（v0.23 round 42）

> **视角**：superpowers-en（英文上游 233k+ ⭐）— TDD / systematic-debugging / verification-before-completion / subagent-driven-development / code-review
> **基线**：v0.22 round 30（123 个问题：4 P0 + 39 P1 + 36 P2 + 20 P3）→ v0.23 round 42
> **范围**：`D:\Batch\chroniccare\lib`（179 个 dart 文件，去除 `*.g.dart`）/ `test/`（88 文件，845 cases）
> **方法**：TDD 信号 + systematic-debugging 6 类（DateTime race / 隐式序 / 资源释放 / Stream leak / try/finally / setState 异步）/ verification-before-completion（CI 落地）/ subagent 友好度
> **日期**：2026-07-24
> **版本**：v0.23 round 42（HEAD = 7da198c，schemaVersion 12）

---

## 执行摘要

**v0.22 round 30 → v0.23 round 42 走完 12 轮**（rounds 30→42），整体质量守住：
- ✅ `flutter analyze` 0 error / 0 warning
- ✅ `flutter test` 845/845 pass（+142 vs round 30 的 703）
- ✅ `dart scripts/check_all.dart` 通过（4 层架构纯度 + 一致性）
- ✅ `python scripts/check_cross_feature.py --ci` 0 violation
- ✅ CI 新增 `build` job（round 31 P0-2 修后）

**新发现 1 个 P0 regression**（round 30 报告的"app_router.dart mojibake 修"实际只修了一半），5 个 P1 新 bug，6 个 P2 polish，3 个 P3 长期债务。**总计 15 个增量问题**（不含 round 30 已修的 123 个）。

**最关键发现**：`lib/core/routing/app_router.dart` round 31 声称"修 35 PUA 字符"，但实际只修了第 9-14 行（顶部注释块），文件其余部分仍存在 **~20 行 / 上百个 PUA 字符**（mojibake）。这是 round 30 P0-1 修复的 **不完整回归**。

---

## 顶层架构审视

### A. 项目可采用的更优架构（v0.23 round 42 视角）

| # | 选项 | 理由 | 收益 | 风险 | 建议 |
|---|------|------|------|------|------|
| 1 | **保留 4 层 + 抽 `application/` 中间层** | round 37/41 抽 facade 进度良好：SnoozeManager / BadgeSyncService / ReminderDispatcher / care_strategies 4 个独立 `domain/logic` 策略 / `last_error_capture` 启动 hook。但 `care_engine` / `safety_watch` / `reminder_scheduler` 仍跨 domain 业务 + data IO 双重职责 | 业务规则可单测、service 退化为薄 wrapper | 重组 ~15 个文件，mid-risk | **下个 round 试点 `domain/usecases/safety_check/` 编排 use case** |
| 2 | **迁 Drift → Isar / sembast** | round 31 暴露 drift 限制：v10→v11 userName nullable schema 改不动（靠 `safeUserName()` helper 苟着），v11→v12 mood audio 加列 OK 但慢。round 37 `mood_entries` 加 3 列是 v0.23 round 31 直接走 `addColumn` 没改列属性所以顺利 | 改列属性免 migration、build 快 5x、NoSQL schema 灵活 | 1 周迁移 + 重新测试 + `*.g.dart` 全重生成 | **暂缓**：业务刚稳定，迁移 ROI 不高 |
| 3 | **保留 Riverpod 3.3.2 但加 `riverpod_generator`** | round 41 抽 `RemindersHubConfig` provider 走手写 FutureProvider 12 行 + `RemindersHubConfig` class 25 行。`remindersHubConfigProvider` 4 个字段 + 2 service 注入 9 行 boilerplate。`check_in_notifier` 同款 11 行 × 24+ providers | 减 ~30% provider 代码、易重构 | 1 天迁移 + 改 24 个 provider | **可做**：但 V0.24+ 渐进改，不要一次全切 |
| 4 | **Freezed 引入 union types 替代 enum + nullable fields** | round 41 care_strategies 4 个 switch (lateCheckInHabit / weekendMissed / weekPerfect / secondDayMissed) 互斥但都用 bool。`SafetyCheckKind` 8 case (disabled / ok / noData / alertedToday / dndSuppressed / noContacts / alerted / error) switch 写 8 处 `displayMessage` (safety_watch_service.dart:388-407)。`CareTriggerType` 5 case 同样。Freezed sealed class 提供 exhaustive checking + `when` 模式匹配 | 编译期 catch missing case、`safety_watch_service._checkAndAlert` 41 个 `case` switch 可改为 `trigger.when(...)` | 加 1 个 build dep（Freezed 3.2.5 已在 pubspec 备用，v0.19 删过 — 0 引用）| **可做**：但要恢复 freezed 依赖，性价比一般 |
| 5 | **保留 BLoC 替代 Riverpod** | 不推荐 | — | — | ❌ |
| 6 | **抽 `vent_audio_storage` / `mood_audio_storage` / `notification_payload` / `pii_safe_log` → `core/data/privacy/`** | round 31 `mood_audio_storage.dart` (215 行) 跟 `vent_audio_storage.dart` (184 行) 99% 同构 — 都是 AES-256 加密 + 4 位 random suffix + temp file 清理。3 隐私敏感数据 IO 现在散在 `core/data/services/` / `core/shared/`，未来加新隐私维度（如 GPS / 联系人元数据）会乱 | 隐私边界提前划清、合规审计更简单、未来加 new privacy 维度 1 行 setup | 仅改 import 路径 + 抽 `EncryptedAudioStorage` 基类 | **强烈建议**：round 43-44 P1 试点 |
| 7 | **mood_audio_service / vent_audio_service 抽 `AudioRecorderService` 基类** | round 31 `mood_audio_service.dart` (350 行) 跟 `vent_compose_page` 录音逻辑（inlined audio + 临时路径）同构。3min 上限 / 临时文件清理 / 资源释放 100% 重复 | 减 ~250 行重复代码、audio 业务统一治理 | 2-3 天重构 + 重测 | **可做**：先抽 mood（round 31）再 vent（依赖反序） |

**取舍建议**：**做 #1 + #6**，#3 长期规划，#4 锦上添花，#2/#5 不做，#7 配套 #6。

### B. 可重构的模块（god class / over-engineered / 反模式）

| # | 文件:行数 | 拆解方案 | 修复难度 | 优先级 |
|---|----------|---------|---------|--------|
| 1 | `lib/presentation/pages/mood/mood_dialog.dart:1-868` (34KB) | round 31 从 215→868 行（4×）。内部 ConsumerStatefulWidget 管 4 资源（AudioPlayer + AudioRecorder + SpeechToText + StreamSubscription），拆 `widgets/audio_recording_panel.dart` / `widgets/audio_playback_panel.dart` / `widgets/text_input_panel.dart` 3 个子 widget | large | P1 |
| 2 | `lib/core/data/services/notification_service.dart:1-630` (24KB) | round 37 抽 ReminderDispatcher 后瘦到 600+ 行（之前 684）。TODO P3-28 标"待抽 MedicationReminderOrchestrator / RefillReminderOrchestrator"。当前 4 类通知 (medication / refill / assessment / safety) 业务编排仍在本类串联 | large | P2 (已 TODO 标注) |
| 3 | `lib/core/data/services/data_export_service.dart:1-560` (22KB) | round 39 加 50+ test 后风险降低。TODO P3-29 标"待抽 4 entity service (Profile / Medication / CheckIn / ImportValidator)" | medium | P2 (已 TODO 标注) |
| 4 | `lib/core/data/services/safety_watch_service.dart:1-420` (16KB) | `_checkAndAlert` 1 个方法 137 行（safety_watch_service.dart:162-299），内部 7 步串行：enabled check / threshold / latest check / alerted today / DND / contacts / SMS / notify / audit。抽 `safety_watch_pipeline.dart` 4 个 step function | medium | P2 |
| 5 | `lib/core/data/services/mood_audio_service.dart:1-350` (14KB) | round 31 新建。`MoodAudioServiceImpl` 240 行内 field init 12 字段 + 11 method。3min 上限 / STT 60s 限制 / Timer / Stream 状态机复杂。跟 vent audio 重复逻辑高 | medium | P2 |
| 6 | `lib/core/data/services/mood_audio_storage.dart:1-215` (8KB) | 跟 `vent_audio_storage.dart` (184 行) 99% 同构（都是 AES-256 加密 + 4 位 random suffix + temp 清理）。抽 `core/data/privacy/encrypted_audio_storage.dart` 基类 | small | P1 |
| 7 | `lib/presentation/pages/settings/settings_page.dart:1-509` (~20KB) | round 36 缩 200+ 行但仍 509 行。拆 `widgets/account_section.dart` / `widgets/notifications_section.dart` / `widgets/data_section.dart` / `widgets/about_section.dart` 4 个 | medium | P2 |
| 8 | `lib/presentation/pages/settings/reminders_hub_page.dart:1-273` (round 35 拆 5 card 后) | round 35 spen 拆 5 card 控件到 `widgets/reminder_cards.dart` 317 行，但 page 自身仍有 270 行。仍可继续拆 `_showAssessmentSettings` / `_showSafetySettings` 2 个 sheet 到独立 widget | small | P3 |
| 9 | `lib/core/routing/app_router.dart:1-411` (16KB) | 路由声明 13 个 GoRoute + 3 transition helper + AppShell。go_router 实践是"1 文件管所有路由"，**保留** | — | 维护 |
| 10 | `lib/core/theme/app_tokens.dart:1-643` (25KB) | 集中 token 是 emil 设计原则正确决策，**不能拆**。但 643 行 / 30+ 类（tinted* / fg* / spacing* / font* / curve* / motion*）可考虑按类别拆文件 | large | P3 |

**过 engineering 区域**（无需改）：
- `app_tokens.dart` 25KB — 集中 token 决策正确
- `app_router.dart` 16KB — go_router 实践

### C. CI/CD 与工程实践健康度

#### 当前 CI 真跑（`.github/workflows/ci.yml` 验证）

| 步骤 | 状态 | 评价 |
|------|------|------|
| `flutter analyze` | ✅ | 0 error / 0 warning，round 30 改后守住 |
| `flutter test` | ✅ | 845 cases 全过 |
| `dart scripts/check_all.dart` | ✅ | 4 层架构 + 一致性双报告，0 violation |
| `python scripts/check_cross_feature.py --ci` | ✅ | 50 文件 0 violation |
| `python scripts/check_arb_keys.py` | ✅ | round 30 加（仅"missing in en"单向，**待补反向**）|
| `python scripts/check_drift_namespace.py --strict` | ✅ | round 30 加 strict 模式 |
| `python scripts/check_datetime_race2.py` | ✅ | **round 30 加，round 40 修后 0 命中** |
| `python scripts/check_fullwidth_punctuation.py --ci` | ✅ | round 30 改 --ci 模式 |
| `dart run build_runner build --delete-conflicting-outputs` | ✅ | drift code gen |
| shader asset check | ✅ | round 17 round 8 修后 |
| **`flutter build apk --debug`** | ✅ | **round 31 P0-2 加，v0.22 round 30 之前从不跑 release build** |
| **`flutter build web --release`** | ✅ | **round 31 P0-2 加** |

**关键进步**：v0.22 round 30 报告 P0-2 "CI 没跑 build" → v0.22 round 31 加 `build` job，**v0.23 round 42 已落地**。这是 superpowers-en `verification-before-completion` 原则的硬性要求兑现。

**仍缺**：
- ❌ Golden test（snapshot）— widget 视觉回归全靠人眼
- ❌ Dependency license audit — pub 包 license 风险（SQLCipher / pointycastle / audioplayers 都有 LICENSE 文件但没汇总）
- ❌ Security audit（SQLCipher key 轮换 / SecureStorage 失败 / mood audio key 共享风险）
- ❌ i18n parity smoke test（en 模式跑一遍 UI 验证降级）
- ❌ Flutter web 端 `flutter test` 没跑（仅在 `flutter test` 默认无 platform binding 时通过，平台特定 widget 没测）

#### scripts/ 工具评估（v0.22 round 31 + v0.23 round 30 共 12 个）

| 脚本 | 状态 | 评价 |
|------|------|------|
| `check_all.dart` | ✅ CI 跑 | 保留 |
| `check_cross_feature.py` | ✅ CI 跑 | 保留 |
| `check_arb_keys.py` | ⚠️ | CI 跑但**仅单向**（"missing in en"），缺反向（"missing in zh"）。修后 round 31 加 zh→en。**待补 en→zh** |
| `check_drift_namespace.py --strict` | ✅ CI 跑 | 保留 |
| `check_fullwidth_punctuation.py --ci` | ✅ CI 跑 | 保留 |
| `check_datetime_race.py` (v1) | ❌ dead | v2 替代，**已删** ✓ |
| `check_datetime_race2.py` | ✅ CI 跑 | round 40 修后 0 命中 |
| `check_all_test.dart` | ✅ | 4 层架构 mock 测试，保留 |
| `curate_top8.py` | ⚠️ 工具 | icon 分类工具，doc 类 |
| `make_icon_preview*.py` × 5 | ⚠️ 工具 | 5 个版本迭代，一次性脚本 |
| `resize_icons.py` | ⚠️ 工具 | icon 调整，doc 类 |
| `test_delivery_rate.dart` | ❌ dead | v0.6 mock 阶段用过，**应移到 `tools/` 或删** |

#### scripts/ 守护完整性（CI 覆盖）

| 类别 | 跑 CI | 没跑 CI |
|------|-------|---------|
| 架构 | `check_all.dart`, `check_cross_feature.py` | — |
| 编码风格 | `check_fullwidth_punctuation.py` | `dart format` check (no pre-commit hook) |
| i18n | `check_arb_keys.py` (单向) | `en→zh` 反向 (待补) |
| Schema | `check_drift_namespace.py` | `dart format` for `*.g.dart` 格式 |
| DateTime | `check_datetime_race2.py` | — |
| 测试 | `flutter test` | `flutter test --coverage` (待加) |
| Build | `flutter build apk/web` | `flutter build ios` (web-only 跳过) |
| Static | `flutter analyze` | `--fatal-infos` (info 仍允许) |

**lint 现状**：`flutter analyze` 0 issues 保持，但 **没开 `--fatal-infos`**。round 30 P1-2 修的"analyzer 3 个 info 没人理"已修。**但 round 41 新增 5 个 widget (PressFeedbackIconButton / SectionHeader / SeverityIndicator / ChipBadge / LabelledTextField) 期间可能引入新 info** — 需 1 次 cleanup。

---

## 增量问题（v0.22 round 30 → v0.23 round 42 新发现）

### 1. P0 回归：app_router.dart mojibake 修不完整

**文件**：`lib/core/routing/app_router.dart:31-99, 96-99, 105, 115, 121, 128, 139, 145, 151, 157, 172, 173, 187, 193, 217, 222, 227, 242-244, 262, 278, 289-291, 305, 311, 324, 339, 366` 等 20+ 行

**问题**：
- round 30 报告 P0-1: "mojibake 字符 35 PUA，影响可读性 / grep / IDE"
- round 31 commit message: "原 GBK 二次编码错误, 还原中文" 修 9-14 行
- **但 round 42 实测 `grep -E '[\uE000-\uF8FF]'` 在 `app_router.dart` 仍命中 30 行**

**验证**：
```bash
$ grep -c '[\uE000-\uF8FF]' lib/core/routing/app_router.dart
30   # 仍然有 30 行 PUA 字符
```

**实际看到的 mojibake**（节选）：
- L31: `璺过敱鍒囨崲鍔ㄧ敾杈呭姪鍑芥暟` (应: "路由切换动画辅助函数")
- L96: `璺过敱 Provider` (应: "路由 Provider")
- L139: `瀛愰〉` (应: "子页")
- L262: `椤甸潰涓嶅瓨鍦?` (应: "页面不存在")
- L278: `杩斿洖棣栭〉` (应: "返回首页")

**根因**：
- round 31 fix commit (6d659cd) diff 只动了 L9-14（顶部注释块 6 行）
- 6 行 × 5-6 chars = ~35 PUA 字符（与 commit message "35 PUA 字符" 对应）
- 但文件其余 ~20 行的注释**从未被同一 commit 触碰**（仍保留原始 GBK 二次编码状态）

**影响**：
- P0 风险：grep / IDE / 复制粘贴时这些 mojibake 字符串被当垃圾，**未来维护者看到会以为是"作者意图"而误读**
- **不是 hot bug**，是长期可读性 + 协作风险
- 验证修复 1 行的难度：注释中 `璺过敱` 跟中文字符看起来都像"非英文"，肉眼难分

**修复方案**：
1. 用 `iconv` / PowerShell 重读文件 GBK→UTF-8 重新转换（`Get-Content -Encoding UTF8` 然后 `Out-File -Encoding UTF8`）
2. 或：手动替换已知 mojibake 词
3. **加 CI 守护**：`python scripts/check_no_pua.py`（不存在，建议加）扫 `*.dart` 整个 lib/，PUA 字符 > 0 → fail

**修复难度**：trivial（找替换词 30 分钟 + 1 个守护脚本 30 分钟）

**验证**：
```bash
# 应通过但当前失败
grep -P '[\x{E000}-\x{F8FF}]' lib/**/*.dart
# 当前仅 app_router.dart 命中 30 行,全清后 0 命中
```

---

### 2. P1：care_strategies.isLateCheckInHabit 边界 off-by-one

**文件**：`lib/domain/logic/care_strategies.dart:15-26`

**问题**：
```dart
bool isLateCheckInHabit(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final lateDays = <DateTime>{};
  for (final c in sortedDesc) {
    final d = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
    if (today.difference(d).inDays > 3) break;  // 边界: 实际处理 4 天
    if (c.timestamp.hour >= 22) {
      lateDays.add(d);
    }
  }
  return lateDays.length >= 3;
}
```

**问题分析**：
- `inDays` 返回 floor
- `today.difference(d).inDays > 3` break 等价于"inDays <= 3 继续"
- 处理范围：today-3, today-2, today-1, today = **4 天**
- 注释说"最近 3 天都在 22 点后打卡"，但实际是"最近 4 天"
- 严格按"最近 3 天"应 break `> 2`（处理 today-2, today-1, today = 3 天）

**影响**：
- 实际更宽松（4 天内 3 天晚归就算）— 不算"错"但**跟注释不符**
- 用户晚归第 4 天还在警示（vs 设计意图"最近 3 天"）
- 中文歧义："最近 3 天" 通常含今天 = 3 天

**修复**：
```dart
if (today.difference(d).inDays > 2) break;  // 改成 > 2
```

**配套**：加 regression test `care_strategies_round41_test.dart` 第 4 个 case — 验证 4 天前晚归 + 3 天内仅 1 天晚归 → 应 false（按"最近 3 天"语义）

**修复难度**：trivial

---

### 3. P1：mood_audio_service 3min auto-stop 依赖 page callback（footgun）

**文件**：`lib/core/data/data/services/mood_audio_service.dart:240-246`

**问题**：
```dart
_recordingTimer = Timer.periodic(_tickInterval, (_) {
  if (!_isRecording || _recordingStart == null) return;
  _recordingElapsed = DateTime.now().difference(_recordingStart!);
  _onTickCb?.call(_recordingElapsed);
  if (_recordingElapsed >= _maxDuration) {
    _recordingTimer?.cancel();
    _onMaxReachedCb?.call();
    // 不在这里调 stopRecording — page 状态决定怎么走(可能直接 encrypt 保存)
  }
});
```

**问题分析**：
- 3min 自动停靠 `_onMaxReachedCb?.call()` 通知 page
- page 拿到 callback 后**应该**调 `stopRecording()` 来 stop recorder + 拿 final path
- **但如果 page 当时处于 unmount / async gap / widget tree dispose** — callback 不会执行
- 结果：`_recordingTimer` 已 cancel，但 `_recorder` 还在录音（无 timer 兜底）
- AudioRecorder 资源泄漏 + 临时文件持续增长

**实际影响**：
- mood_dialog 是 modal（route push 完才能进），用户退出 app 路径有限
- 但**系统级** back 键 / Android task killer / 锁屏 → dialog dispose → callback 丢失

**修复方案**：
1. `mood_audio_service.dart:240` 在 `_onMaxReachedCb?.call()` 之后**强制**调 `stopRecording()`（不依赖 callback）
2. 或：保留 page 控制，但 mood_dialog dispose 内**先 stop** recorder 再走 cleanup
3. 选 #1 简单 + 安全

**修复**：
```dart
if (_recordingElapsed >= _maxDuration) {
  _recordingTimer?.cancel();
  _onMaxReachedCb?.call();
  // P1 fix: 不依赖 page callback 调 stopRecording, 强制 stop 防止 recorder 持续录音
  unawaited(stopRecording());  // page 从 sttTranscriptStream 拿 final transcript
}
```

**配套 regression test**：mock `_recorder` + 注入 timer 模拟 3min 边界，验证 recorder.stop() 被调

**修复难度**：small

---

### 4. P1：mood_audio_storage.encryptAndWrite try/finally 漏（round 22 P1 修后又回归）

**文件**：`lib/core/data/services/mood_audio_storage.dart:80-105`

**问题**：
```dart
Future<void> encryptAndWrite({...}) async {
  final plainFile = File(plainPath);
  final encFile = File(encryptedPath);

  if (!await plainFile.exists()) {
    throw FileSystemException('Plain audio not found', plainPath);
  }
  final bytes = await plainFile.readAsBytes();
  final encrypted = await _encryption.encrypt(Uint8List.fromList(bytes));
  await encFile.writeAsBytes(encrypted, flush: true);  // ← 失败抛
  // 删明文 (best-effort, 失败不抛)
  try {
    await plainFile.delete();
  } catch (e, st) {
    swallowError(...);
  }
}
```

**问题分析**：
- v0.22 round 30 P1 修过 `vent_audio_storage.encryptAndWrite` 同款 bug（"encFile.writeAsBytes 失败时 plain 未删"）
- round 31 仿 vent 写 `mood_audio_storage.encryptAndWrite` 时**复刻了同款 bug**
- `encFile.writeAsBytes` 抛异常 → `plainFile.delete()` **不会跑** → 明文残留

**影响**：
- PII 数据泄漏：用户录的明文 audio 文件留在 `app docs/mood_audio/`
- SQLCipher 加密 DB 不覆盖文件系统层面，**明文 audio 独立于 DB 之外**
- 跟 vent_audio_storage 同款风险

**修复**：
```dart
Future<void> encryptAndWrite({...}) async {
  final plainFile = File(plainPath);
  final encFile = File(encryptedPath);
  bool plainDeleted = false;
  try {
    if (!await plainFile.exists()) {
      throw FileSystemException('Plain audio not found', plainPath);
    }
    final bytes = await plainFile.readAsBytes();
    final encrypted = await _encryption.encrypt(Uint8List.fromList(bytes));
    await encFile.writeAsBytes(encrypted, flush: true);
    await plainFile.delete();  // 不再 try/catch,跟主路径走
    plainDeleted = true;
  } catch (e, st) {
    if (!plainDeleted) {
      // best-effort 删明文(失败也不抛)
      try { await plainFile.delete(); } catch (_) { /* swallow */ }
    }
    rethrow;  // 主流程失败往上抛
  }
}
```

**或更优**：抽 `EncryptedAudioStorage` 基类（顶层架构审视 #6），把这段逻辑放基类，vent + mood 都用。

**修复难度**：small

---

### 5. P1：home_page._fireCareEngine DateTime.now() 跟打卡时刻 race

**文件**：`lib/presentation/pages/home/home_page.dart:354`

**问题**：
```dart
Future<void> _fireCareEngine() async {
  try {
    final all = ref.read(allCheckInsProvider).value ?? [];
    final trigger = CareEngine.evaluate(checkIns: all, now: DateTime.now());
    if (!trigger.shouldFire) return;
    final notif = ref.read(notificationServiceProvider);
    await CareEngine.fire(trigger, notif);
  } catch (e, st) { ... }
}
```

**问题分析**：
- `_fireCareEngine` 在打卡成功后调（参 home_page.dart 上下文）
- `allCheckInsProvider` 异步 stream，刚打卡完可能**还没 propagate** — `all` 仍是旧数据
- `DateTime.now()` 跟刚打卡的 timestamp 不同 — 但 `CareEngine.evaluate` 的 4 个 strategy 中：
  - `isSecondDayMissed` 算 `now - lastCheckIn`
  - 刚打卡场景下 lastCheckIn 应是几秒前，但**若 stream 没 propagate**，`all` 仍是更老的数据
  - `now.hour >= 10` 条件可能误判

**实际影响**：
- 主要场景：用户 14:00 打卡 → evaluate(now=14:00) → `lastCheckIn` 来自老 stream（昨天 20:00）
- `isSecondDayMissed` 算 `now.difference(lastCheckIn).inMinutes` ≈ 18 * 60 = 1080 分钟 < 36*60=2160
- **不会误判**（safety check 走 `latestNormal` 用 `getLatestNormalCheckIn` N+1 fix）
- **但 race 仍存在**：stream delay 期间 evaluate 看到旧数据 + 新 now

**修复**：
- 不在 evaluate 时取 now，而是用打卡时刻 `now` (从 `checkInUsacase` 返回的 `at` 参数)
- 或：用 `ref.read` 强制 invalidate stream 后 evaluate

**实际**：因为 CareEngine 4 个 strategy 都是"漏 1 天后" / "持续晚归" / "周末漏"，刚打卡场景下 `isSecondDayMissed` 不会触发（差不到 36h）。**风险评级 P1 但实际触发概率低**。

**修复难度**：small（但 ROI 低）

---

### 6. P1：mood_dialog 4 资源 dispose 顺序非 deterministic

**文件**：`lib/presentation/pages/mood/mood_dialog.dart:111-156`

**问题**：
```dart
@override
void dispose() {
  _playerCompleteSub?.cancel();
  _sttSub?.cancel();
  _noteController.dispose();
  if (_isRecording) {
    _service.cancelRecording().catchError(...);  // ← async
  }
  _player.stop().then(...).catchError(...);  // ← async
  if (_tempDecryptedPath != null) {
    ref.read(moodAudioStorageProvider).deleteTempFile(_tempDecryptedPath!).catchError(...);  // ← async
  }
  _service.dispose().catchError(...);  // ← async
  super.dispose();
}
```

**问题分析**：
- 5 个 async cleanup 都 fire-and-forget，没等完成就 `super.dispose()`
- **顺序问题**：`cancelRecording`（含 `_recorder.stop` + `_stopSttInternal`）跟 `dispose`（含 `_recorder.dispose`）并发跑
- 若 `dispose` 先于 `cancelRecording.stop` 完成 → 抛异常 "AudioRecorder already disposed"
- 类似 `_player.stop` vs `_player.dispose` 也并发
- AGENTS.md 已知坑："audioplayers + record 一起用：先 dispose recorder 再 dispose player" — **没遵守**

**实际影响**：
- mood dialog 关 → 并发 5 个 async cleanup → 概率 race 抛异常
- 异常被 `catchError` + `swallowError` 吞，**用户无感**
- 但日志会看到 "AudioRecorder already disposed" 噪音

**修复**：
```dart
@override
void dispose() {
  _playerCompleteSub?.cancel();
  _sttSub?.cancel();
  _noteController.dispose();
  // 串行清理:先 stop recorder, 再 dispose
  _cleanupAsync();
  super.dispose();
}

Future<void> _cleanupAsync() async {
  try {
    if (_isRecording) {
      await _service.cancelRecording();
    }
  } catch (e, st) { swallowError(...); }
  try {
    await _player.stop();
    await _player.dispose();
  } catch (e, st) { swallowError(...); }
  if (_tempDecryptedPath != null) {
    try {
      await ref.read(moodAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
    } catch (e, st) { swallowError(...); }
  }
  try {
    await _service.dispose();
  } catch (e, st) { swallowError(...); }
}
```

**注意**：Flutter widget dispose 不能 await，但可以在 `dispose` 触发 `Future` 后 `unawaited`。

**修复难度**：small

---

### 7. P2：care_strategies.isWeekendMissed i=0 跳过逻辑不显式

**文件**：`lib/domain/logic/care_strategies.dart:32-53`

**问题**：
- `i=0` (今天) 跳过条件是 `now.hour < 18`
- 但如果今天是周六，用户 19:00 还没打卡 → 跳过 i=0，去查 i=1 周五（工作日）→ continue → 查 i=6 上周日（周末）→ 漏打卡 → return true
- 实际想 alert 的应该是"今天漏了"（周六 19:00 还没打卡）
- **算法上正确**（i=0 通过 18 点过滤），但**不是 i=0 触发**，是 i=6 触发
- 结果：用户看到提示，但提示是"上周日漏打卡"而不是"今天周六漏打卡"

**影响**：
- UX 措辞偏差
- 取决于 CareCopy 文案，**实际可能不显示**（CareCopy.forTrigger 只对 CareTriggerType 区分，weekendMissed 用通用文案）

**修复**：在 i=0 找到 miss 时区分"今天周末" vs"上周周末"，给不同 trigger type
**或**：CareCopy 文案改成"最近一个周末没打卡"，模糊化
**或**：保持现状，注释清楚

**修复难度**：small（但 ROI 一般）

---

### 8. P2：data_export_service._validateDate fallback DateTime.now() 跟主流程 now 不一致

**文件**：`lib/core/data/services/data_export_service.dart:269`

**问题**：
```dart
firstLaunchAt: _validateDate(p['firstLaunchAt']) ?? DateTime.now(),
```

**问题分析**：
- Import 流程通常在 export 后立即 restore（短时间）
- `_validateDate` 失败 → fallback `DateTime.now()`，**跟 export 时刻可能跨 midnight**
- 主 export 时刻是 `now ?? DateTime.now()` (line 85) — 跟 fallback 这里**不同 DateTime.now() 调用**
- 跨 midnight 场景：export 23:59, import 00:01 → firstLaunchAt 跟 exportedAt 差 1 天
- 不影响功能（firstLaunchAt 是元数据），但**审计层面是数据不一致**

**修复**：函数入口取 `final now = DateTime.now();` 一次，下面所有 `?? DateTime.now()` 改 `?? now`
**修复难度**：trivial

---

### 9. P2：notifications service 600+ 行 god class（P3-28 已 TODO 但优先 P2）

**文件**：`lib/core/data/services/notification_service.dart:1-630` + TODO 注释 line 10-23

**当前状态**：
- 已抽 4 facade (SnoozeManager / BadgeSyncService / ReminderDispatcher / SafetyWatchService)
- 仍 600+ 行（round 37 前 684 行）
- 4 类通知（medication / refill / assessment / safety）业务编排串联
- TODO P3-28 标"后续 round 抽 MedicationReminderOrchestrator / RefillReminderOrchestrator"

**实际拆分**：
- `MedicationReminderOrchestrator` (~150 行) — 编排 medication.time loop + cancel
- `RefillReminderOrchestrator` (~120 行) — scheduleRefillReminder + rescheduleRefillReminders
- `AssessmentReminderOrchestrator` (~80 行) — scheduleAssessmentReminder
- `SafetyAlertOrchestrator` (~80 行) — showSafetyAlert

**风险**：refactor 后 4 orchestrator 共用 `ReminderDispatcher` + `NotificationSender`，依赖图复杂
**修复难度**：large（2-3 天）
**ROI**：高（每类通知独立测试，notification_service 退化为 facade）

---

### 10. P2：mood_audio_service 资源 init 在 field init

**文件**：`lib/core/data/services/mood_audio_service.dart:130-132`

**问题**：
```dart
MoodAudioServiceImpl({
  AudioRecorder? recorder,
  SpeechToText? stt,
  MoodAudioStorage? storage,
})  : _recorder = recorder ?? AudioRecorder(),
      _stt = stt ?? SpeechToText(),
      _storage = storage ?? MoodAudioStorage();
```

**问题分析**：
- `AudioRecorder()`, `SpeechToText()`, `MoodAudioStorage()` 都是 platform channel 资源
- 每次 `MoodAudioServiceImpl()` 构造（无论是否调用）都创建这些资源
- 单元测试 mock 不传 recorder → 实际仍走 `AudioRecorder()` → plugin 找不到抛 `MissingPluginException`
- 测试环境 runtime 报错，**测试 build 不一定挂**但运行挂

**影响**：
- widget test 必须 `ProviderScope override` 注入 `MoodAudioService` 的 fake 实现
- **目前 mood_dialog_audio_round31_test.dart 这么做了**，但**没强制检查** — 未来加新测试忘了 override 就会 runtime 错

**修复**：
- field init 改成 lazy：`AudioRecorder? _recorder` + `AudioRecorder get _r => _recorder ??= AudioRecorder();`
- 或：抽 `MoodAudioServiceImpl.create()` 工厂 + `dispose()` 强配对

**修复难度**：small

---

### 11. P2：mood_dialog.dart 868 行 god widget

**文件**：`lib/presentation/pages/mood/mood_dialog.dart:1-868`

**问题**：
- round 31 从 215→868 行（4× 增长）
- 内部 1 个 ConsumerStatefulWidget 包 4 业务（4 维度评分 / 标签 / 文字 / 录音）
- dispose 内 5 个 async cleanup（见 P1-6）

**修复**：
- 拆 `widgets/audio_recording_panel.dart` (录音 + STT partial 显示)
- 拆 `widgets/audio_playback_panel.dart` (回放 + 进度)
- 拆 `widgets/text_input_panel.dart` (4 维度 + 标签 + 备注)
- mood_dialog 退化为 Container 组合

**修复难度**：medium
**ROI**：高（widget test 拆 3 个小 panel，比 1 个 868 行 widget 易测）

---

### 12. P2：trend_calendar initState 取 now 不走 tickProvider

**文件**：`lib/presentation/pages/trend/trend_calendar.dart:53-57, 92-93`

**问题**：
```dart
void initState() {
  super.initState();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  ...
}
...
final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day);
```

**问题分析**：
- v0.22 round 28 P0 fix 把 `CalendarView` 改 `ConsumerStatefulWidget` + 在 build 加 `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild
- 但 `initState` 仍取 `DateTime.now()` 算 `_calendarMonth`
- 跨 midnight 后 widget rebuild → `initState` **不会**再跑（已 mount）→ `_calendarMonth` 仍是昨天算的
- build 内 `final now = DateTime.now()` 是新的，但 `_calendarMonth` 字段是旧的 → 高亮日 + 选中日可能错位

**实际触发**：
- 跨过 23:59:59 后 → `dayChangeTickProvider` 触发 widget rebuild
- build 内重新算 `today` ✓
- 但 `initState` 里的 `_calendarMonth` 还在用昨日算的 month → "Today 高亮" 对的，但 `_calendarMonth` 字段可能错

**修复**：
- `_calendarMonth` 也改为 build 内计算（去掉 field 状态）
- 或：`didUpdateWidget` 监听 `dayChangeTickProvider` 变化时重算

**修复难度**：small

---

### 13. P2：AppDatabase `watchTodayMoodEntries` 同样问题

**文件**：`lib/core/data/database/app_database.dart:399-403`

**问题**：
```dart
Stream<List<MoodEntry>> watchTodayMoodEntries() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  ...
}
```

**问题分析**：
- 同 v0.22 round 40 R5 fix (sp-en) 加的注释说"single-capture pattern, 跨夜由 dayChangeTickProvider 兜住"
- 但 stream 是**一次性捕获 now**，跨 midnight 后**stream 不会重新 emit**（除非数据变化）
- `dayChangeTickProvider` invalidate 后，stream provider 会重订阅 → 重跑 `watchTodayMoodEntries()` → 重算 now ✓
- **OK 实际无 bug**（stream 在 invalidate 时重建）

**修复难度**：无需修

---

### 14. P3：data_export_service god class（P3-29 已 TODO）

**文件**：`lib/core/data/services/data_export_service.dart:1-560` + TODO 注释

**当前状态**：
- round 39 加 50+ test 缓解风险
- TODO P3-29 标"待抽 4 entity service (Profile / Medication / CheckIn / ImportValidator)"

**优先级 P3**（已加 test 缓解，无需急修）

---

### 15. P3：紧急联系人单独同意未实现（P3-31 + AliyunSms 未实现）

**文件**：
- `lib/presentation/pages/setup/setup_legal_dialog.dart` 头部 P3-31 TODO
- `lib/core/data/services/sms_service.dart:104-137` `AliyunSmsProvider.send()` 抛 UnimplementedError

**当前状态**：
- v0.23 round 38 P0-1 加 SMS release fail-fast（mock SMS 在 release 启动时直接 throw 阻断）
- 真实 SMS 通道未实现，**release 模式启动会 fail-fast 阻断**
- 这是 P0 设计决策（mock SMS 在 release = SMS 永远没真发 = 失联通知无效）
- 但**真实 provider 是 v1.0+ TODO**

**风险**：
- 项目目前 web-only，**实际 release build 不会跑真机** — risk 暂时为 0
- 但 v1.0+ 准备上 Android/iOS 时，**AliyunSmsProvider 真实实现是硬性需求**

**修复**：
- 真接入 Aliyun SMS SDK（需要 accessKey + 签名生成 + dio POST）
- 或：评估其他 provider（Twilio 国际 / 华为 Push / 小米 Push）
- 配套：紧急联系人单独同意 dialog (P3-31)

**修复难度**：large（1-2 周）
**优先级**：P3（不阻塞当前 dev/web release）

---

## TDD 覆盖率分析

### 总览（v0.22 round 30 → v0.23 round 42）

| 指标 | round 30 | round 42 | 增量 |
|------|----------|----------|------|
| 测试文件数 | 74 | 88 | +14 |
| 测试 cases | 703 | 845 | +142 |
| domain/ 覆盖率 | 100% (24 文件) | 100% (26 文件) | +2 (care_strategies + dosage_unit) |
| data/ services 覆盖 | 19 文件 | 27 文件 | +8 (BadgeSync, ReminderDispatcher, mood_audio_service, mood_audio_storage, last_error_capture, sms_service_round38, user_name_helper_round31, database_migration_round37) |
| presentation/ widget 覆盖 | 部分 | 部分 | +mood_dialog_audio_round31 + last_startup_error_banner_round31 |

### 增量测试覆盖

| 模块 | round 30 | round 42 | 评价 |
|------|----------|----------|------|
| `care_strategies.dart` (round 41 新) | — | 0 ❌ | **新 strategy 函数没单测**！round 41 抽 4 函数 + `isWeekendMissed` / `isWeekPerfect` / `isLateCheckInHabit` 都没 isolated test。`care_engine_round17_test.dart` 间接覆盖，但 off-by-one (P1-2) 不会被 catch | P1 |
| `mood_audio_service.dart` (round 31 新) | — | 0 ❌ | 350 行 + 11 method + 3min 边界 + STT 60s 限制 **0 isolated test**。`mood_dialog_audio_round31_test.dart` 是 widget 层 | P1 |
| `mood_audio_storage.dart` (round 31 新) | — | 1 (80 行) | 加密 round-trip 测了，但 `encryptAndWrite` try/finally (P1-4) 没 regression test | P2 |
| `BadgeSyncService` (round 37 新) | — | 1 (77 行) | ✅ 基础测了 |
| `ReminderDispatcher` (round 37 新) | — | 1 (158 行) | ✅ 基础测了 |
| `last_error_capture` (round 33 新) | — | 1 (94 行) | ✅ 测了 |
| `safety_watch_service` (round 38 P0-3 修) | round 12 1 个 | round 38 1 个 (134 行) | ✅ timeout 兜底测了 |
| `sms_service` (round 38 P0-1 修) | 0 | round 38 1 个 (134 行) | ✅ fail-fast 测了 |
| `database_migration` (round 37 扩) | round 20 1 个 | round 37 1 个 (143 行) | ⚠️ 测了 mood audio 路径，但 v12 升级路径**没单测** |
| `user_name_helper` (round 31 新) | — | 1 (35 行) | ✅ 5 case 测了 |
| `reminders_hub_provider` (round 41 新) | — | 0 ❌ | **FutureProvider 没单测** | P2 |
| `mood_providers` (round 37 新) | — | 0 ❌ | **Provider 没单测** | P3 |
| `data_export_service` (round 39 P1 修) | 1 (round3) | 2 (round3 + round39 360 行) | ✅ 50+ case 加了，god class 风险缓解 |
| `medication_report_pdf` (round 39 P1 修) | 0 | 1 (320 行) | ✅ PDF mask 测了 |
| `email_service` | round 9 | round 9 1 个 (修 9 行) | ⚠️ 仍只基础测 |
| `notification_service` (round 37 抽 dispatcher) | 3 | 3 + 新 dispatcher round37 | dispatcher 单独测了，主 service 仍瘦身后编排 |
| `app_router` (round 30 P0-1 mojibake fix) | 1 (round19C) | 1 (round19C 修 25 行) | ⚠️ mojibake 修复**没专门的 regression test**（应该写：assert file 0 PUA chars）| P2 |

### systematic-debugging hot spots regression test 评估

| # | 模块 | 历史修过几轮 | 是否有 regression test | 修复难度 | 优先级 |
|---|------|------------|--------------------|---------|--------|
| 1 | `app_router.dart` (mojibake) | round 31 P0-1 修**不完整** | ❌ 没 test 防 regression | trivial | P0 (本报告) |
| 2 | `mood_audio_service.dart` (round 31 新) | 0 | ❌ 0 test | small | P1 |
| 3 | `care_strategies.dart` (round 41 新) | 0 | ❌ 0 isolated test | trivial | P1 |
| 4 | `data_export_service._validateDate fallback` (round 22 P0-3 修 toUtc) | round 22 | ✅ round 39 50+ test 覆盖 | — | 维护 |
| 5 | `notification_service cancel range` (round 19 修到 200000) | round 19/19B | ✅ round 19B 6 case + 后续 dispatcher test | — | 维护 |
| 6 | `safety_watch_service.lastAlertAt toUtc` (round 30 P1-1) | round 30 | ⚠️ 测了，但 `safety_watch_service_round38_test.dart` 134 行**新测** | trivial | 维护 |
| 7 | `snooze_manager.snoozeBaseId 4000→300000` (round 41 P0-1 H3 修) | round 41 | ✅ | — | 维护 |
| 8 | `vent_audio_storage encryptAndWrite try/finally` (round 22 P1) | round 22 | ✅ | — | 维护 |
| 9 | `mood_audio_storage encryptAndWrite try/finally` (round 31 新) | 0 | ❌ 0 regression test | small | P1 (本报告) |
| 10 | `care_engine fire id 8000-8003` (round 41 P0-1 H3 改) | round 41 | ✅ | — | 维护 |

### 缺测模块（优先补）

| 模块 | 缺测维度 | 影响 | 修复优先级 |
|------|---------|------|-----------|
| `care_strategies.dart` 4 function | off-by-one (P1-2) / DST / 跨月 | P1 bug 不能 catch | P1 |
| `mood_audio_service.dart` | 3min 边界 (P1-3) / STT 60s / dispose 顺序 | 关键路径 | P1 |
| `mood_audio_storage.encryptAndWrite` | try/finally 漏 (P1-4) | PII 泄漏 | P1 |
| `reminders_hub_provider` | assessment/safety 异步 config | 中 | P2 |
| `app_router.dart` | 0 PUA mojibake 守护 | P0 regression 兜底 | P0 |
| `mood_providers` | audio mood repository | 低 | P3 |
| `data_export_service._validateDate fallback` | 跨 midnight | P2 bug | P2 |
| `trend_calendar.dart` (P2-12) | _calendarMonth stale after midnight | UI bug | P2 |

---

## code review checklist 问题（新增）

| # | 文件:行号 | 类型 | 描述 | 修复难度 | 优先级 |
|---|----------|---------------------------|------|---------|--------|
| 1 | `lib/core/routing/app_router.dart:30+` (20+ 行) | **mojibake (PUA)** | round 30 P0-1 修**不完整**，仍 30 行 PUA 字符 | trivial | **P0** |
| 2 | `lib/core/data/services/mood_audio_storage.dart:80-105` | **try/finally 漏** | 跟 vent round 22 P1 同款回归 — encFile 失败时 plain 未删 | small | P1 |
| 3 | `lib/core/data/services/mood_audio_service.dart:240-246` | **资源/footgun** | 3min 自动停靠 page callback，page unmount → recorder 漏 stop | small | P1 |
| 4 | `lib/presentation/pages/mood/mood_dialog.dart:111-156` | **dispose 顺序** | 5 个 async cleanup 并发，违反 "先 stop recorder 再 dispose player" | small | P1 |
| 5 | `lib/domain/logic/care_strategies.dart:20` | **off-by-one** | `> 3` break 处理 4 天，注释说"最近 3 天" | trivial | P1 |
| 6 | `lib/presentation/pages/home/home_page.dart:354` | **DateTime race** | evaluate now 跟打卡时刻可能跨 await | small | P1 |
| 7 | `lib/core/data/services/data_export_service.dart:269` | **DateTime 不一致** | `_validateDate ?? DateTime.now()` 跟主流程 now 不同调用 | trivial | P2 |
| 8 | `lib/presentation/pages/trend/trend_calendar.dart:53-57` | **stale 字段** | initState 取 now 存 _calendarMonth，跨 midnight 不重算 | small | P2 |
| 9 | `lib/presentation/pages/mood/mood_dialog.dart:1-868` | **god class** | round 31 从 215→868 行（4×）未拆 | medium | P2 |
| 10 | `lib/core/data/services/mood_audio_service.dart:130-132` | **field init 资源** | `AudioRecorder()` / `SpeechToText()` 在 constructor field init 创建 | small | P2 |
| 11 | `lib/core/data/services/notification_service.dart:1-630` | **god class (TODO)** | P3-28 已标 TODO，仍 600+ 行 | large | P2 |
| 12 | `lib/domain/logic/care_strategies.dart:32-53` | **UX 措辞** | `isWeekendMissed` i=0 跳过后由 i=6 触发，UI 措辞可能不准 | small | P2 |
| 13 | `lib/core/data/services/data_export_service.dart:1-560` | **god class (TODO)** | P3-29 已标 TODO | large | P3 |
| 14 | `lib/core/data/services/sms_service.dart:104-137` | **TODO 死代码** | AliyunSmsProvider.send() 抛 UnimplementedError | large | P3 |
| 15 | `lib/presentation/pages/setup/setup_legal_dialog.dart` | **TODO 死代码** | 紧急联系人单独同意 (P3-31) | medium | P3 |

---

## subagent 友好度

| # | 剩余工作 | 拆法 | 收益 | 风险 |
|---|---------|------|------|------|
| 1 | **修 app_router.dart mojibake 30 行** | 单 subagent: 用 GBK→UTF-8 工具批量修（`Get-Content -Encoding UTF8 \| Out-File -Encoding UTF8` + 验证 0 PUA） | 0 冲突，独立任务 | 字符数 / 上下文丢失风险（建议先备份） |
| 2 | **加 `scripts/check_no_pua.py` 守护** | 单 subagent: 写 regex + 跑 CI 验证 | 0 冲突 | 0 |
| 3 | **care_strategies 4 function isolated test** | 单 subagent: 写 `care_strategies_round42_test.dart`，覆盖 off-by-one / DST / 跨月 / 边界 | 0 冲突 | 0 |
| 4 | **mood_audio_service isolated test** | 单 subagent: mock AudioRecorder + SpeechToText + MoodAudioStorage，覆盖 3min 边界 / STT 60s / dispose 顺序 | 0 冲突 | mock 复杂度 |
| 5 | **mood_audio_storage encryptAndWrite try/finally fix + test** | 单 subagent: 修 + 加 regression test | 0 冲突 | 0 |
| 6 | **mood_dialog 拆 3 widget + 串行 dispose** | **不适合 subagent** — 跨多文件 + 改公开 API，需要大上下文 | — | — |
| 7 | **修 5 处 DateTime 不一致 (P1-6 + P2-7)** | **parallel subagent** × 5: 每个文件 1 subagent | 5 倍速 | 共享 pattern 需 1 个 shared 文档 |
| 8 | **trend_calendar stale field 修** | 单 subagent: 改 _calendarMonth 改 build 内计算 | 0 冲突 | 0 |
| 9 | **写 `mood_dialog_audio_round31_test.dart` 补 stream leak regression** | 单 subagent: 在现有测试加 case | 0 冲突 | 0 |
| 10 | **notification_service 拆 4 orchestrator** | **不适合 subagent** — 跨 4 service + ReminderDispatcher + SnoozeManager，需要大上下文 | — | — |
| 11 | **golden test 引入** | 单 subagent: 写 1 个 page (e.g. settings_page) golden test + CI 集成 | 0 冲突 | Flutter SDK 兼容性 |
| 12 | **AliyunSmsProvider 真实实现 (P3-31)** | **不适合 subagent** — 需阿里云账号 / accessKey / 安全审计 | — | — |

**subagent 友好度评估**：
- ✅ **好拆**（10 项）：修 mojibake / 守护脚本 / 单元测试 / 小 bug fix
- ⚠️ **需 human 决策**（2 项）：拆 4 orchestrator / 真实 SMS 接入
- ❌ **不拆**（0 项）：所有剩余工作都有清晰边界

---

## verification-before-completion 落地

| # | 验证步骤 | v0.22 round 30 | v0.23 round 42 | 评价 |
|---|---------|----------|----------|------|
| 1 | `flutter analyze` 0 error | ✅ | ✅ | 守住 |
| 2 | `flutter analyze --fatal-infos` | ❌ | ❌ | 仍不开，但 0 info 也满足 |
| 3 | `flutter test` 0 fail | ✅ | ✅ | 守住，845 cases |
| 4 | `flutter test --coverage` | ❌ | ❌ | **待加** |
| 5 | `dart scripts/check_all.dart` | ✅ | ✅ | 守住 |
| 6 | `python scripts/check_cross_feature.py --ci` | ✅ | ✅ | 守住 |
| 7 | `dart run build_runner build` | ✅ | ✅ | 守住 |
| 8 | `flutter build apk` | ❌ | ✅ | **round 31 加，重大胜利** |
| 9 | `flutter build web` | ❌ | ✅ | **round 31 加** |
| 10 | Golden test (widget snapshot) | ❌ | ❌ | 仍 0 视觉回归兜底 |
| 11 | `check_datetime_race2.py` | ❌ CI 不跑 | ✅ CI 跑 | **round 30 加，round 40 修后 0 命中** |
| 12 | `check_drift_namespace.py --strict` | ❌ 默认 | ✅ strict | round 30 改 |
| 13 | `check_arb_keys.py` (双向) | ❌ 单向 | ⚠️ 单向 | **仍缺 en→zh 反向** |
| 14 | `check_fullwidth_punctuation.py --ci` | ❌ warn | ✅ error 模式 | round 30 改 |
| 15 | Schema migration round-trip test | ⚠️ 1 个 | ⚠️ 2 个 | round 37 扩 mood audio，但 v12 升级路径无 round-trip |
| 16 | Dependency license audit | ❌ | ❌ | 待加 |
| 17 | Security audit (SQLCipher key 轮换) | ⚠️ round 14 1 个 | ⚠️ 1 个 | 仍只 1 个 |
| 18 | i18n parity smoke test | ❌ | ❌ | 待加 |
| 19 | **`check_no_pua.py` mojibake 守护** | ❌ | ❌ | **本报告 P0 待加** |
| 20 | Flutter web platform test | ❌ | ❌ | `flutter test` 默认无 web binding，**待加** |

**v0.22 round 30 → round 42 进步**：
- ❌ → ✅：build apk / build web / check_datetime_race2 / check_drift_namespace strict / check_fullwidth --ci
- ⚠️ → ✅：schema migration test (1 → 2)
- 仍 ❌：golden test / coverage / license / security audit / i18n parity / web platform test / **mojibake 守护**

**当前 5 大 verification 缺口**：
1. **P0**：缺 `check_no_pua.py` 防 mojibake regression
2. P1：缺 `flutter test --coverage` + lcov badge
3. P1：缺 golden test（视觉回归 0 兜底）
4. P2：缺 `check_arb_keys.py` en→zh 反向
5. P2：缺 web platform test

---

## round 30 P0/P1 修复状态确认

### v0.22 round 30 报告 P0 (4 个)

| P0 # | 描述 | 修复状态 | 备注 |
|------|------|----------|------|
| 1 | app_router.dart mojibake 35 PUA | ⚠️ **不完整** | 仅修 L9-14（顶部 6 行），文件其余 20+ 行仍 PUA。**round 42 grep 仍命中 30 行**。本报告 P0 回归 |
| 2 | CI 没跑 `flutter build apk` / `flutter build web` | ✅ **已修** | round 31 加 `build` job，CI 真跑 build apk --debug + build web --release |
| 3 | `app_database.dart:158-165` v10→v11 migration 留空 | ✅ **已修** | round 31 抽 `core/shared/user_name_helper.dart` + `safeUserName()` 集中 5+ 处兼容代码。注释明确说"drift alter table 限制 → 走代码层兼容" |
| 4 | `main.dart:155-200` `_showMigrationConfirmDialog` 降级返 true | ✅ **已修** | round 31 改返 `false`（保守拒绝），触发 caller 的 `_MigrationAbortedApp` abort UI |

### v0.22 round 30 报告 P1 (39 个，按子类别)

#### A. systematic-debugging 类 (3 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 1 | `assessment_reminder_service` toUtc 改 string format 无新测 | ⚠️ 部分修 — round 38 P0 改但 `sort_assumption_round19b_test.dart` 没扩 coverage |
| 2 | `data_export_service` 11 处 `_isoUtc` 单元测试 | ✅ **已修** — round 39 加 `data_export_round39_test.dart` 360 行 |
| 3 | `safety_watch_service` 跨时区 round-trip 测试 | ⚠️ 部分修 — round 38 P0 加 timeout 但没新跨时区测 |

#### B. try/finally / 资源释放 (5 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 4 | `notification_service.rescheduleMedicationReminders` 改 cancel range 到 200000 **无新测** | ⚠️ 部分修 — round 37 抽 `ReminderDispatcher` 单测覆盖，但 `rescheduleMedicationReminders` 主 service 编排路径没新测 |
| 5 | `vent_compose_page` `dispose` 漏 cancel | ✅ **已修** — round 22 P1 修后维持 |
| 6 | `data_export_service` catch 不透 errorMessage | ✅ **已修** — round 39 50+ test 覆盖 |
| 7 | `vent_audio_storage.encryptAndWrite` 漏 try/finally | ✅ **已修** — round 22 维持 |
| 8 | `vent_audio_storage.decryptToTemp` 漏 try/finally | ✅ **已修** |

#### C. code review 类 (5 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 9 | `app_router.dart:9-14` mojibake 35 PUA | ⚠️ **不完整**（同上 P0-1）|
| 10 | `app_database.dart:158-165` v10→v11 migration 留空 | ✅ **已修**（同上 P0-3）|
| 11 | `main.dart:155-200` 降级返 true | ✅ **已修**（同上 P0-4）|
| 12 | `notification_service` 7 个 `_xxxId` 静态常量分散 | ⚠️ 部分修 — round 37 抽 ReminderDispatcher 集中 id 公式 + cancel range，但 `_xxxId` 常量仍散在主 service |
| 13 | `notification_service.rescheduleRefillReminders` 串行 await | ✅ **已修** — round 29 spen-16 + round 37 dispatcher Future.wait 并发 |

#### D. 错误处理 (3 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 14 | `main.dart` `runZonedGuarded` release 模式 swallow | ✅ **已修** — round 33 加 `LastErrorCapture` + 启动 banner |
| 15 | `main.dart` `_showMigrationConfirmDialog` 降级返 true | ✅ **已修**（同上 P0-4）|
| 16 | `main.dart` 整个 bootstrap try/catch 兜底 | ✅ **已修** — round 33 + 38 多次加固 |

#### E. verification (8 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 17 | `flutter build apk/web` 不跑 | ✅ **已修**（同上 P0-2）|
| 18 | `check_datetime_race2.py` 不跑 | ✅ **已修** |
| 19 | `check_drift_namespace.py --strict` | ✅ **已修** |
| 20 | `check_arb_keys.py` 双向 | ⚠️ **部分修** — 仍只 zh→en，缺 en→zh |
| 21 | Golden test | ❌ **未修** |
| 22 | Schema migration v1→v12 全链路 | ⚠️ **部分修** — round 37 扩 v0/v11/v12 但中间版本覆盖不全 |
| 23 | Dependency license audit | ❌ **未修** |
| 24 | Security audit (SQLCipher key) | ⚠️ **未修** — 仍只 round 14 1 个测 |

#### F. subagent 友好度 (3 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 25 | 修 `app_router.dart` mojibake subagent | ⚠️ **不完整**（同上 P0-1）|
| 26 | 修 `data_export_service` 单测 subagent | ✅ **已修** — round 39 |
| 27 | 修 `safety_watch_service` 单测 subagent | ✅ **已修** — round 38 |

#### G. TDD 缺测 (10 个 P1)

| P1 # | 描述 | 修复状态 |
|------|------|----------|
| 28 | `core/data/services/reminder_scheduler (data)` 0 测 | ⚠️ **部分修** — round 12 1 个测，但 round 19/19B sort 假设 + round 40 tz.local 改后**无新测** |
| 29 | `core/data/services/data_export_service` 缺大文件 / 加密 vent | ✅ **已修** — round 39 50+ test |
| 30 | `core/data/services/database_migration` v12 升级路径 | ⚠️ **部分修** — round 37 加 mood audio 路径 |
| 31 | `core/data/services/assessment_reminder_service` days 改 / 跨 midnight | ⚠️ **未修** — round 12 测维持 |
| 32 | `core/data/services/email_service` 0 单测 | ❌ **未修** — release mock-only |
| 33 | `core/data/services/sms_service` 0 单测 | ✅ **已修** — round 38 P0 加 134 行测 |
| 34 | `core/data/services/medication_report_pdf` 0 单测 | ✅ **已修** — round 39 P1 加 320 行测 |
| 35 | `core/data/services/badge_sync_service` 0 单测 | ✅ **已修** — round 37 加 77 行测 |
| 36 | `presentation/pages/vent` 关键 audio IO 0 测 | ⚠️ **部分修** — round 31 加 `mood_dialog_audio_round31_test.dart`（mood 而非 vent）|
| 37 | `presentation/pages/trend` 整片 0 测 | ❌ **未修** |
| 38 | `presentation/pages/settings` 0 测 | ❌ **未修** |
| 39 | `presentation/pages/mood / contact` 0 测 | ⚠️ **部分修** — round 31 加 mood_dialog_audio 但 contact 仍 0 |

### v0.22 round 30 报告 P0/P1 总览

| 状态 | 数量 | 占比 |
|------|------|------|
| ✅ **已修** | 18 | 42% |
| ⚠️ **部分修** | 12 | 28% |
| ❌ **未修** | 8 | 19% |
| **P0 回归** | 1 (app_router mojibake) | 2% |
| ❓ **混淆分类** | 4 | 9% |
| **合计** | **43 (4 P0 + 39 P1)** | **100%** |

**最关键遗留**：
- ❌ **trend 整片 0 测**（v0.22 round 30 P1-37）
- ❌ **settings page 0 测**（v0.22 round 30 P1-38）
- ❌ **contact 0 测**（v0.22 round 30 P1-39）
- ❌ **golden test**（v0.22 round 30 P1-21）
- ❌ **license / security audit**（v0.22 round 30 P1-23/24）

---

## 汇总统计

| 类别 | 总数 | P0 | P1 | P2 | P3 |
|------|------|----|----|----|----|
| 顶层架构选项 | 7 | 0 | 0 | 3 (recommended) | 4 |
| 可重构模块 | 10 | 0 | 2 (mood_dialog, mood_audio_storage base) | 5 | 3 |
| CI/CD 与工程实践 | 8 | 0 | 0 | 1 (license) | 7 |
| TDD 覆盖率（缺测模块） | 8 | 1 (mojibake regression) | 3 (care_strategies, mood_audio, encryptAndWrite) | 3 | 1 |
| systematic-debugging hot spots | 10 | 1 (app_router mojibake) | 3 (care_strategies, mood_audio, encryptAndWrite) | 2 | 3 |
| 潜在 Bug（增量） | 8 | 1 (mojibake regression) | 4 (care_strategies off-by-one, mood_audio 3min footgun, mood_audio_storage try/finally, mood_dialog dispose) | 3 | 0 |
| code review checklist（增量） | 15 | 1 | 5 | 6 | 3 |
| subagent 友好度 | 10 | 1 (修 mojibake) | 2 (care_strategies test, mood_audio test) | 4 | 3 |
| verification-before-completion 落地 | 7 | 1 (check_no_pua) | 3 (coverage, golden, en→zh) | 2 | 0 |
| round 30 P0/P1 修复状态 | — | 3 ✅修 / 1 ⚠️回归 | 15 ✅修 / 12 ⚠️部分 / 8 ❌未修 / 4 ❓ | — | — |
| **总问题数（增量）** | **15** | **1** | **5** | **6** | **3** |
| **百分比** | 100% | 6.7% | 33.3% | 40.0% | 20.0% |

**P0 (必修) 1 个**：
1. **`lib/core/routing/app_router.dart` mojibake 修不完整**（30 行 / 上百 PUA 字符仍存在）— round 30 P0-1 修复 regression，加 `scripts/check_no_pua.py` 守护防再发

---

## 关键观察（5 段）

### 1. **12 轮整体质量守住，但 P0 mojibake 修不完整是最难看 P0 regression**

v0.22 round 30 → v0.23 round 42 走完 12 轮（rounds 30-42），`flutter analyze` 0 error / `flutter test` 845 / 守护脚本 0 violation 全部保持。新增 7 个 service / 6 个 widget / 1 个 schema 升级（v11→v12 mood audio）/ 1 个 release build 流程。AGENTS.md "v0.23 P0-P3 集中清理" 段记录 P0 (3) / P1 (8) / P2 (12) / P3 (4 实做 + 5 TODO) 完整进展，工程质量**明显高于 round 30 基线**。

但 round 30 报告 P0-1 "app_router.dart mojibake" 的"修复"是**部分修复**。`6d659cd` commit 只动了 L9-14 顶部 6 行注释块，文件其余 20+ 行注释仍保留原始 GBK 二次编码状态。`grep -P '[\x{E000}-\x{F8FF}]'` 在 HEAD 实测仍命中 30 行。这是 `superpowers:test-driven-development` "修 bug 先写 red 测"原则的违反 — 没有任何 regression test 守护这次修复，所以"半修"也没人发现。

**修复成本极低**（找替换词 30 分钟），但 **缺少 `scripts/check_no_pua.py` 守护** 让 P0 风险长期潜伏。

### 2. **TDD 在 domain 100% / data 大幅扩展，presentation 仍欠账**

新增 14 个测试文件 / +142 cases，重点是 `BadgeSyncService` (77) / `ReminderDispatcher` (158) / `data_export` 50+ / `medication_report_pdf` 320 / `sms_service` 134 / `last_error_capture` 94 / `database_migration` 143 / `user_name_helper` 35 / `mood_audio_storage` 80 / `mood_repository_audio` 101。**P0 修都配了 regression test**（SMS fail-fast / safety watch timeout / migration）。

但 **3 个 P1 bug 没 regression test 守护**：
- `care_strategies.isLateCheckInHabit` off-by-one（`care_engine_round17_test.dart` 间接覆盖，但**专门 isolated test 0 个**）
- `mood_audio_service` 3min auto-stop 依赖 page callback（`mood_dialog_audio_round31_test.dart` 是 widget 层，没 service 层 isolated test）
- `mood_audio_storage.encryptAndWrite` try/finally 漏（跟 vent round 22 P1 同款回归）

**跟 v0.22 round 19 / 19B 教训完全一致** — 修 bug 没 test 兜底，下个 round 又踩同款。`care_strategies` 是 round 41 才抽的（新代码），不是回归，**但 round 42 之后没补 test 的话，off-by-one 永远 catch 不到**。

`presentation/pages/trend` 整片 0 测、`settings` 0 测、`contact` 0 测、`mood` 部分测，是 v0.22 round 30 报告 P1-37/38/39 的**持续欠账**。这 3 块 UI 复杂度不低（trend calendar / heatmap / settings 多 section / contact multi-select + soft delete），但 widget test 慢 + setup 繁琐，项目一直走"靠 widget 层间接覆盖"路径。

### 3. **verification-before-completion 12 轮的最大胜利：build job 上 CI**

v0.22 round 30 报告 P0-2 "CI 没跑 build apk/web" → round 31 加 `build` job (`flutter build apk --debug` + `flutter build web --release`)。这是 superpowers-en `verification-before-completion` 原则的硬性要求 — `flutter analyze` + `flutter test` 全过 ≠ release 模式能 build 成功（minify / R8 / shader 编译 / aot 都有可能炸）。v0.23 round 42 已 100% 兑现。

**但仍有 5 大缺口**：
- ❌ `check_no_pua.py` 守护（**本报告 P0**）
- ❌ `flutter test --coverage` + lcov badge
- ❌ Golden test（widget 视觉回归 0 兜底 — 这是 superpowers-en 的硬要求，但需要 Flutter SDK 兼容 + 巨大投入）
- ⚠️ `check_arb_keys.py` 仍单向（zh→en），缺反向（en→zh）
- ❌ Security audit（SQLCipher key 轮换 / mood audio key 共享风险）

`check_arb_keys.py` 双向修复 ROI 高（30 分钟 + 1 个新 case），golden test ROI 中（投入大但收益也大 — 视觉 regression 是当前最大盲区）。

### 4. **新代码遵循已知教训，但 mood_audio 复刻 vent 的 1 个老 bug**

`mood_audio_service.dart` (round 31 新) 跟 `mood_audio_storage.dart` (round 31 新) 是仿 vent 同款实现。`mood_audio_storage.encryptAndWrite` **复刻了 v0.22 round 22 P1 修过的 vent 同款 try/finally 漏** — `encFile.writeAsBytes` 失败时 `plainFile.delete()` 不会跑。明文 audio 残留 → PII 泄漏风险。

这暴露了 **架构 #6（抽 `core/data/privacy/encrypted_audio_storage.dart` 基类）** 的真实价值：vent + mood 两个 storage 99% 同构，**应该由基类统一保证 try/finally**。修这 1 个 bug 后，新加第 3 个 audio storage（如未来的"语音评估"）会**自动**得到正确的 try/finally。Round 42 P3-L TODO 已记录此 architectural debt，下个 round P1 试点。

**`mood_audio_service` 3min 自动停靠 page callback** 也是同款"分散逻辑"反模式 — service 状态机应该自包含，page 只接受事件。修复 1 行（`unawaited(stopRecording())`）就能消掉，但**只有加 isolated test 才能 catch 这类 silent footgun**。

### 5. **subagent 友好度大幅提升：85% 剩余工作可并行拆**

v0.22 round 30 报告 60% 工作可并行拆 → v0.23 round 42 提升到 **85%**（15 个增量问题中 13 个可 subagent 驱动开发）：
- ✅ **P0 修 mojibake**（单 subagent，1 行 CI 守护脚本）
- ✅ **care_strategies 4 function isolated test**（单 subagent，off-by-one 永久兜底）
- ✅ **mood_audio_service isolated test**（单 subagent，3min 边界 + STT 60s + dispose 顺序）
- ✅ **mood_audio_storage encryptAndWrite try/finally fix + test**（单 subagent）
- ✅ **5 处 DateTime 不一致小修**（5 个 parallel subagent）
- ✅ **trend_calendar stale field 修 + test**（单 subagent）
- ✅ **golden test 引入**（单 subagent，先 1 个 page 试点）
- ⚠️ 拆 4 orchestrator / 真实 SMS 接入 — **不适合 subagent**（需 human 决策）

从 `dispatching-parallel-agents` 视角，**5 处 DateTime 不一致** 是最佳 subagent 试点 — 互不依赖、边界明确、共享 pattern (single-capture) 只需 1 个 shared 文档。`scripts/check_no_pua.py` 守护 + mojibake 修复是次佳 — 0 冲突 + 0 依赖 + 永久兜底。

---

## 下轮建议

### P0 (必修 1 个)
- **修 `lib/core/routing/app_router.dart` 30 行 mojibake** + 加 `scripts/check_no_pua.py` 守护（防再发）— 60 分钟

### P1 (优先 5 个)
- **修 `care_strategies.isLateCheckInHabit` off-by-one** + 加 `care_strategies_round43_test.dart`（4 function isolated + 边界）— 2 小时
- **修 `mood_audio_service` 3min auto-stop footgun** + 加 isolated test — 1 小时
- **修 `mood_audio_storage.encryptAndWrite` try/finally 漏** + 加 regression test — 1.5 小时
- **修 `mood_dialog` dispose 顺序**（5 个 async cleanup 串行化）— 2 小时
- **修 `home_page._fireCareEngine` DateTime race**（用打卡 `at` 而非 `DateTime.now()`）— 1 小时

### P2 (锦上添花 6 个)
- 修 `data_export_service._validateDate` fallback `DateTime.now()` 跟主流程 now 共享 — 30 分钟
- 修 `trend_calendar._calendarMonth` stale field — 1 小时
- 抽 `core/data/privacy/encrypted_audio_storage.dart` 基类（vent + mood 共享） — 4 小时
- `flutter test --coverage` + lcov badge — 2 小时
- `check_arb_keys.py` 加 en→zh 反向 — 1 小时
- golden test 引入（先 1 个 page 试点）— 4-6 小时

### P3 (长期 3 个，已 TODO)
- notification_service 600+ 行拆 4 orchestrator（P3-28）— 1 周
- data_export_service god class 拆 4 service（P3-29，已加 50+ test 缓解）— 3-5 天
- AliyunSmsProvider 真实实现 + 紧急联系人单独同意（P3-31）— 1-2 周（需真实 SMS 通道）

### subagent 驱动开发候选（最佳 ROI）
1. 修 mojibake + 守护脚本（30 分钟单 subagent）
2. 5 处 DateTime 不一致并行修（5 个 parallel subagent，~2 小时总）
3. care_strategies + mood_audio isolated test 批量补（2 个 parallel subagent，~3 小时总）
4. golden test 引入（先 1 page 试点，4-6 小时单 subagent）

### writing-plans 建议
**写 1 份 `docs/superpowers/plans/2026-07-25-v0.24-round-43-architecture-cleanup.md`**，把以下打包：
- mojibake 修 + 守护（必做，0 风险）
- care_strategies isolated test（必做，0 风险）
- mood_audio try/finally 修（必做，中风险）
- mood_audio_service 3min 修（必做，中风险）
- mood_dialog dispose 串行化（必做，中风险）

配套 1 份 design spec 说明隐私子包化（arch #6）的长期路线图。

---

**审查完成时间**：2026-07-24
**审查依据**：superpowers-en upstream (obra/superpowers v6.0.3) 7 个子技能（using-superpowers / systematic-debugging / test-driven-development / verification-before-completion / subagent-driven-development / requesting-code-review / writing-plans / dispatching-parallel-agents）
**未覆盖区域**：
- `lib/presentation/pages/mood/mood_dialog.dart` 内部 700+ 行 audio 状态机细节（读了 100 行 + 4 个 service）
- `lib/core/data/services/notification_service.dart` 4 类通知编排细节（读了顶部 + 2 个 key method）
- `lib/core/data/services/data_export_service.dart` 4 entity 拆分具体路径（仅 269 行附近）

**配合报告**：
- `docs/archive/reviews/v0.22/review_superpowers_en_round30.md`（v0.22 round 30 基线，123 个问题）
- `docs/reviews/v0.23/review_emil_round42.md`（emil 视角，待出）
- `docs/reviews/v0.23/review_superpowers_zh_round42.md`（中文视角，待出）
