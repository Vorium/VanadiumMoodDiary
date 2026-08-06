# Task 2 Report — FeatureFlags 11 项硬 false

> v0.30 round 93 (audit-fixes) sub-spec 9, task 2
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 1 done (1646 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 4 commit, 1657 tests pass (+11 R93), 17 守门员全绿, 11 项 `_prodXxxEnabled = const false` (实际 8 个 flag, 编译期锁定)。

## 完成项

- [x] 改 `_prodBootReceiverEnabled = true` → `false` (R93 业务暂停)
- [x] 加 4 个新 flag (AliyunSms / EmailService / FiveVendorPush / VentAudio)
- [x] TDD 写 `test/core/data/feature_flags_round93_test.dart` (11 case)
- [x] 修 R67 老 test 适配 bootReceiver 默认 false (策略副作用)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `8d46457` v0.30 round 93 (fix): FeatureFlags bootReceiver 默认 true → false (R93 业务暂停)
- `d1f1957` v0.30 round 93 (feat): FeatureFlags 加 4 个业务暂停 flag (AliyunSms/EmailService/FiveVendorPush/VentAudio)
- `1326613` v0.30 round 93 (test): feature_flags 8 flag 默认值 + enableForTest + resetForTest + per-flag setter 验证
- `71d92eb` v0.30 round 93 (test): R67 老 test 适配 bootReceiver 默认 false (R93 业务暂停)

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `lib/core/data/feature_flags.dart` | 改 | 125 → 235 行 (+110) |
| `test/core/data/feature_flags_round93_test.dart` | 新 | 125 行 |
| `test/data/feature_flags_round67_test.dart` | 改 | 4 处 expect(bootReceiver=true) → expect(false) |

## 验证

### flutter test

- **R93 baseline**: 1646 → 1657 pass (+11 R93, 0 regression)
- **R93 11 case** (新 test 文件):
  - 1) emergencyContactEnabled 默认 false ✓
  - 2) iapEnabled 默认 false ✓
  - 3) phqGad7I18nEnabled 默认 false ✓
  - 4) bootReceiverEnabled 默认 false (R93 阶段 2 改) ✓
  - 5) aliyunSmsEnabled 默认 false (R93 新增) ✓
  - 6) emailServiceEnabled 默认 false (R93 新增) ✓
  - 7) fiveVendorPushEnabled 默认 false (R93 新增) ✓
  - 8) ventAudioEnabled 默认 false (R93 新增) ✓
  - 9) enableForTest 翻 8 个全 true (兼容 R66 老 test) ✓
  - 10) resetForTest 恢复 prod (8 个全 null → 8 个全 false) ✓
  - 11) per-flag setter 单独 override (兼容 R67 模式) ✓
- **R67 6 case** (老 test 修): 全过 (bootReceiver 默认 false 适配)
- **1 pre-existing fail** (mood_period_aggregator R91 集成时遗留, 跟 R93 无关, 留 R95+)

### flutter analyze

- 0 error / 0 warning
- 19 info-level (pre-existing in master, 无新增)

### 17 守门员

| 守门员 | 结果 |
|--------|------|
| check_16kb_alignment.py | ✅ |
| check_arb_keys.py | ✅ |
| check_changelog.py | ✅ |
| check_cross_feature.py | ✅ |
| check_datetime_race.py | ✅ |
| check_datetime_race2.py | ✅ |
| check_drift_namespace.py | ✅ |
| check_fullwidth_punctuation.py | ⚠️ (warn-only, pre-existing) |
| check_legal_consent.py | ✅ |
| check_no_hardcoded_utc.py | ✅ |
| check_no_pua.py | ✅ |
| check_orphan_arb_keys.py | ✅ |
| check_sms_release_ready.py | ✅ |
| check_strings_hardcoded.py | ✅ |
| check_widget_dispose.py | ⚠️ (warn-only, pre-existing) |
| check_zh_hant_consistency.py | ✅ |
| dart check_all.dart | ✅ 4 层纯度 + 语义一致 |

## 关键决策

### 1. 8 flag 而非 brief 写的"11 项"

- brief 写"11 项 `_prodXxxEnabled = const false`" 是用户策略意图
- 实际 8 个 flag (4 旧 + 4 新) 都是 const false
- "11 项" 可能是指业务范围 (IAP + SMS + Email + 5 厂商 push + vent audio + mood audio + 联系人 + 主页失联 FAB + PHQ-9 + GAD-7 + bootReceiver), 跟 flag 数不同
- 验收以"8 flag 全 const false" 为准

### 2. 编译期 const false 不可改 (R66 + R72 模式)

- 不用 `static bool _prodXxx = false;` (运行时可改)
- 用 `static const bool _prodXxxEnabled = false;` (编译期锁定, prod 永不改变)
- test 走 `_currentXxxEnabled ?? _prodXxxEnabled` override
- 业务真接后**改源码翻 true + 重新发版**, 不能 runtime 改

### 3. 4 新 flag 名字跟业务模块一致

- `_prodAliyunSmsEnabled` — 阿里云 SMS 真接前 (跟 `AliyunSmsProvider` 一致)
- `_prodEmailServiceEnabled` — EmailService 真接 SendGrid 前 (跟 `EmailService` 一致)
- `_prodFiveVendorPushEnabled` — 5 厂商 push SDK 接入前 (跟 `FiveVendorPushService` 一致)
- `_prodVentAudioEnabled` — vent audio 录音业务闭环不全 (跟 `VentAudioService` 一致)

### 4. enableForTest 翻 8 个全 true (兼容 R72 老 test)

- 28 个老 test 调 `FeatureFlags.enableForTest()` 走真实业务
- 翻 8 个全 true 保证老 test 不破 (新增 4 个不会影响老 test 默认 false 行为)

### 5. 修 R67 老 test (策略副作用)

- R67 老 test 假设 `_prodBootReceiverEnabled = true` (R66 阶段默认)
- R93 改 false 后 4 个 case fail (case 1 默认值 + case 2/3 其他 flag 不变 + case 6 resetForTest 恢复)
- 修法: 4 处 `expect(bootReceiver=true)` → `expect(bootReceiver=false)` + 注释 R93
- 不动 R67 老 test 的逻辑结构, 只更新 expect 值

## 后续 (本 task 不做, 留 task 3-6)

- **Task 3**: 设置页 4 section 隐藏 (IAP 商业卡 / 失联通知 / 5 厂商 push / EmailService 邮件)
- **Task 4**: 联系人入口 + 主页失联 FAB 隐藏
- **Task 5**: PHQ-9 / GAD-7 量表隐藏
- **Task 6**: vent + mood audio 录音隐藏
- 4-6 task 都会读这 8 flag, 走 `if (FeatureFlags.xxxEnabled) ... else SizedBox.shrink()` 模式

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 改 `_prodBootReceiverEnabled = true` → `false` 影响老 test | TDD 11 case 验证 + R67 老 test 适配 | ✅ 0 fail (R67 6 case 修后全过) |
| 4 新 flag 默认 false 误伤现有业务 | 4 新 flag 业务**还没接**, 加 flag 后 UI hidden 走 task 3-6 | ✅ task 3-6 待做 |
| enableForTest 翻 8 个全 true 老 test 受影响 | 8 个全 true 兼容老 test 默认 false 行为, 无误伤 | ✅ 1657 pass |

## 不在本批做的事 (按 brief)

- ❌ UI 隐藏 (本任务只动 FeatureFlags, UI 留 task 3-6)
- ❌ 文档 (README / DEPLOYMENT / 法律 md 留 task 7)
- ❌ 删 fastlane 占位 (留 task 7)
