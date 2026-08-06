# Task 2 Brief — FeatureFlags 11 项硬 false

> v0.30 round 93 (audit-fixes) sub-spec 9, task 2
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 1 done (1646 tests pass)
> 实施日期: 2026-08-06

## Goal

按 R93 v2 plan "所有需要真接的内容先隐藏" 策略, 把 `feature_flags.dart` 从 4 项 flag 扩到 11 项, 11 项全 `_prodXxxEnabled = const false`, 编译期不可改, 真接业务后翻 true。

## 现状 (跑前)

- `lib/core/data/feature_flags.dart` L35-40 有 4 项 flag:
  - L35: `_prodEmergencyContactEnabled = false` ✓ (R66 阶段)
  - L38: `_prodIapEnabled = false` ✓ (R68 阶段)
  - L39: `_prodPhqGad7I18nEnabled = false` ✓ (R65b 阶段)
  - L40: `_prodBootReceiverEnabled = true` ✗ (待改 false, v0.28 WorkManager 完善前)
- 4 个 getter + 4 个 per-flag setter + enableForTest/resetForTest helper

## 范围 (3 commit)

### Commit 1: 改 `_prodBootReceiverEnabled = true` → `false`

- 改 `lib/core/data/feature_flags.dart` L40
- 理由: BootReceiver 完善前 (R55 阶段), 设备重启后 WorkManager 触发可能 crash
- 跟现有 R72 Sprint 撤回逻辑一致 (Sprint 1 撤回后默认不开)
- 1 commit: `v0.30 round 93 (fix): FeatureFlags bootReceiver 默认 true → false (R93 业务暂停)`

### Commit 2: 加 4 个新 FeatureFlag

- 改 `lib/core/data/feature_flags.dart`:
  - L41 新增: `static const bool _prodAliyunSmsEnabled = false;` (阿里云 SMS 真接前)
  - L42 新增: `static const bool _prodEmailServiceEnabled = false;` (EmailService 真接 SendGrid 前)
  - L43 新增: `static const bool _prodFiveVendorPushEnabled = false;` (5 厂商 push SDK 接入前, 米/华/OPP/vivo/魅族)
  - L44 新增: `static const bool _prodVentAudioEnabled = false;` (vent audio 录音业务闭环不全)
- 同步加 4 个 `_currentXxxEnabled` nullable + 4 个 getter + 4 个 per-flag setter
- 同步更新 `enableForTest` 翻 8 个全 true + `resetForTest` 清 8 个
- 11 项 `_prodXxxEnabled = const false` (8 个 false + 加 3 个原有 false)
- 1 commit: `v0.30 round 93 (feat): FeatureFlags 加 4 个业务暂停 flag (AliyunSms/EmailService/FiveVendorPush/VentAudio)`

### Commit 3 (TDD): 写 `test/core/data/feature_flags_round93_test.dart`

- 8 case: 4 旧 flag (emergencyContact / iap / phqGad7I18n / bootReceiver) + 4 新 flag (aliyunSms / emailService / fiveVendorPush / ventAudio) 各自默认值 false
- 1 case: enableForTest 翻 8 个全 true
- 1 case: resetForTest 恢复 prod (8 个全 null)
- 1 case: 11 项 prod 常量全 false (compile-time 验证)
- 1 commit: `v0.30 round 93 (test): feature_flags 8 flag 默认值 + enableForTest + resetForTest + 11 常量全 false 验证`

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/core/data/feature_flags.dart` | 改 | 125 → ~200 行 (+75) |
| `test/core/data/feature_flags_round93_test.dart` | 新 | ~120 行 |

## 验证

- `flutter analyze` 0 error / 0 warning
- `flutter test test/core/data/feature_flags_round93_test.dart` 11 case pass
- `flutter test` baseline 1646 → 1657 pass (+11 R93)
- 17 守门员全绿 (无新增, 跟 task 1 一致)

## 复用 helper (跟 R66 + R72 一致, 不重写)

- 现有 `setXxxEnabledForTest(bool? v)` per-flag setter 模式 (L86-96)
- 现有 `enableForTest()` 全开模式 (L110-115)
- 现有 `resetForTest()` 全清模式 (L119-124)
- 4 新 flag 复用同模式, 0 重写

## 关键决策

### 1. 编译期 const false 不可改 (R66 + R72 模式)

- 不用 `static bool _prodXxx = false;` (运行时可改)
- 用 `static const bool _prodXxxEnabled = false;` (编译期锁定, prod 永不改变)
- test 走 `_currentXxxEnabled ?? _prodXxxEnabled` override
- 业务真接后**改源码翻 true + 重新发版**, 不能 runtime 改

### 2. 4 新 flag 名字跟业务模块一致

- `_prodAliyunSmsEnabled` — 阿里云 SMS 真接前 (跟 `AliyunSmsProvider` 一致)
- `_prodEmailServiceEnabled` — EmailService 真接前 (跟 `EmailService` 一致)
- `_prodFiveVendorPushEnabled` — 5 厂商 push SDK 接入前 (跟 `FiveVendorPushService` 一致)
- `_prodVentAudioEnabled` — vent audio 录音业务闭环不全 (跟 `VentAudioService` 一致)

### 3. enableForTest 翻 8 个全 true (兼容 R72 老 test)

- 28 个老 test 调 `FeatureFlags.enableForTest()` 走真实业务
- 翻 8 个全 true 保证老 test 不破 (新增 4 个不会影响老 test 默认 false 行为)

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 改 `_prodBootReceiverEnabled = true` → `false` 影响老 test | TDD 11 case 验证 | 待跑 |
| 4 新 flag 默认 false 误伤现有业务 | 4 新 flag 业务**已经默认隐藏** (compile-time UI hidden), 加 flag 后再显 hidden | 待验证 |
| enableForTest 翻 8 个全 true 老 test 受影响 | 8 个全 true 兼容老 test 默认 false 行为, 无误伤 | 待跑 |

## 后续 (本 task 不做, 留 task 3-6)

- **Task 3**: 设置页 4 section 隐藏 (IAP/失联/5 厂商 push/EmailService 邮件)
- **Task 4**: 联系人入口 + 主页失联 FAB 隐藏
- **Task 5**: PHQ-9 / GAD-7 量表隐藏
- **Task 6**: vent + mood audio 录音隐藏
- 4-6 task 都会读这 4 新 flag, 走 `if (FeatureFlags.xxxEnabled) ... else SizedBox.shrink()` 模式

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ 在 master 工作区做 (本任务在 worktree `feat/audit-fixes-r93`)
- ❌ 跑 `flutter pub get` (worktree bootstrap OK)
- ❌ 跑 build_runner schema 改动 (本任务无 schema 改动)
- ❌ UI 隐藏 (本任务只动 FeatureFlags, UI 留 task 3-6)
- ❌ 文档 (README / DEPLOYMENT / 法律 md 留 task 7)
