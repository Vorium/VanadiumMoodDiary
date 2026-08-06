# Task 3 Report — 文档同步 (AGENTS + App 混用 + 硬编码中文)

> v0.30 round 92 (audit-fixes) task 3
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r92\`
> Branch: `feat/audit-fixes-r92`
> Baseline: R92 task 1+2 (1636 pass / 0 fail)
> 实施日期: 2026-08-06

## Status

**DONE** — 3 同步完成, 1636 pass / 0 regression, 4 i18n 守门全绿。

## 完成项

### Step 3.1: AGENTS.md 17 守门员补 (commit f7264e1)

- [x] AGENTS.md 16 守门员 → 17 守门员
- [x] 加 `check_16kb_alignment.py` (R60+ 新增, AGENTS 漏列)
- [x] 描述: "Android 16KB page size 验证 (Google Play 2025-11-01 强制)"

### Step 3.2: 6 文档 "App" 混用修 (commit 1a7b490, 部分跳过)

- [x] `lib/core/l10n/strings.dart` L38/58/60/150 4 处 "App" 改 "本应用" / "慢病管家" (按 terminology.md §2)
- [ ] ~~6 文档其他位置~~ (按 brief L36/88/91 sensitive_data_consent + L73 privacy_policy + L33 SMS_PROVIDERS 跳过)
  - 跳过原因: privacy_policy 36 处 + sensitive_data_consent 11 处 改中文文案需法务过审 (按 spec §2.2 跳过); SMS_PROVIDERS L33 是技术参考文档, "App" 中性不影响用户

### Step 3.3: 8 文件 31 处硬编码中文 → 走 l10n (commit 2b59931)

- [x] 31 处硬编码中文改 `AppLocalizations.of(context).xxx` 调用
- [x] 8 文件 + 4 子文件:
  - `lib/presentation/pages/assessment/assessment_center_page.dart` (1 处)
  - `lib/presentation/pages/daily_tracking/treatment_page.dart` (1 处)
  - `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart` (4 处)
  - `lib/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart` (4 处)
  - `lib/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart` (7 处)
  - `lib/presentation/pages/daily_tracking/widgets/sleep_widgets.dart` (7 处)
  - `lib/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart` (6 处)
  - `lib/presentation/pages/mood_list/widgets/mood_list_period_filter_bar.dart` (1 处)
- [x] 加 9 个新 ARB key (zh + en + zh_Hant 3 语同步):
  - `sleepRegularityTitle` "规律性" / "Regularity" / "規律性"
  - `anxietyAgitationAnxietyLabel` "焦虑分数" / "Anxiety Score" / "焦慮分數"
  - `anxietyAgitationAgitationLabel` "急躁分数" / "Agitation Score" / "急躁分數"
  - `moodListPeriodAll` "全部" / "All" / "全部"
  - `sleepBedtimeTitle` "入睡时间" / "Bedtime" / "入睡時間"
  - `sleepWakeTimeTitle` "起床时间" / "Wake time" / "起床時間"
  - `socialRhythmWakeTimeTitle` "起床时间" / "Wake time" / "起床時間"
  - `socialRhythmFirstMealTitle` "第一餐时间" / "First meal time" / "第一餐時間"
  - `socialRhythmLastMealTitle` "最后一餐时间" / "Last meal time" / "最後一餐時間"
- [x] 5 个 R91 sleep/socialRhythm time placeholder type `String` → `Object` (gen-l10n 一致性 bug 修)

## commit 链

```
2b59931 v0.30 round 92 (i18n): 8 文件 31 处硬编码中文 → 走 l10n (新 9 ARB keys) + 5 R91 time placeholder type 修
1a7b490 v0.30 round 92 (docs): strings.dart 4 处 'App' 改 '本应用/慢病管家' (按 terminology.md §2)
f7264e1 v0.30 round 92 (docs): AGENTS.md 补 check_16kb_alignment.py (16→17 守门员)
```

## 验证

### Test baseline

| 指标 | 数值 | 备注 |
|---|---|---|
| baseline test | 1636 pass / 0 fail | R92 task 2 后 |
| task 3 实施后 test | **1636 pass / 0 fail** | 跟 baseline 一致, 0 regression |
| flutter analyze | 0 error | 跟 baseline 一致 |

### 守门员

| 守门员脚本 | 状态 | 备注 |
|---|---|---|
| `python scripts/check_arb_keys.py` | ✅ OK | zh / en / zh_Hant 同步 (1046 keys) |
| `python scripts/check_strings_hardcoded.py` | ✅ OK | 32 处中文 static const/String, 32 处 R57 override 配对模式 + 其余带 i18n 标记 |
| `python scripts/check_zh_hant_consistency.py` | ✅ OK | 1046 keys, 繁简 100% 一致 (OpenCC s2tw) |
| `python scripts/check_orphan_arb_keys.py` | ✅ OK | 1046 zh ARB key, 0 orphan |

## 跳过项 (含原因)

### 4 项法律文档 App 混用 (隐私政策 + 敏感数据 + 用户协议)

brief 列的 6 文档混用修, 实际只改了 `lib/core/l10n/strings.dart` 4 处. 其他 5 文档 (`assets/legal/privacy_policy.md` L73 + 36 处其他 + `assets/legal/sensitive_data_consent.md` L36/88/91 + 11 处其他 + `docs/SMS_PROVIDERS.md` L33) 跳过:

- **法律文档** (`assets/legal/privacy_policy.md` + `assets/legal/sensitive_data_consent.md` + `assets/legal/user_agreement.md`): 改中文文案需法务过审 (PIPL §13 同意 + §17 同意记录 + §47 删除权). 按 spec §2.2 "3 份法律 md 律师过审" 跳过, 留 R93+ 排期 (法务签字 + 修订跟踪).
- **技术参考文档** (`docs/SMS_PROVIDERS.md` L33): 是阿里云 SMS 模板示例, 实际 SMS 模板会经过法务审核, R55 真接阿里云时统一改. 当前 R55 TODO 状态无意义改.

## 关键发现 (供 R93+ 排期参考)

1. **法律文档混用是合规问题**: privacy_policy 36 处 + sensitive_data_consent 11 处 + user_agreement 类似数量 = ~50+ 处 "App" 待修, 但需法务全程过审, 估 1-2 周 (PIPL 法务 + 律师).
2. **4 R92 l10n 修复顺带修了 R91 l10n bug**: 5 个 sleep/socialRhythm time placeholder type `String` → `Object` 是 R91 daily_tracking 时遗留. R92 修了让 gen-l10n 通过, 后续 gen-l10n 不再 warn.
3. **R91 daily_tracking 子模块 + R87 mood_list period chip 漏 l10n**: R91 集成后 + 6 视角审计发现 31 处硬编码中文, 集中在 daily_tracking widget + 1 处 mood_list. 1 commit 全修.

## R92 分支状态

```
2b59931 v0.30 round 92 (i18n): 8 文件 31 处硬编码中文 → 走 l10n (新 9 ARB keys) + 5 R91 time placeholder type 修
1a7b490 v0.30 round 92 (docs): strings.dart 4 处 'App' 改 '本应用/慢病管家' (按 terminology.md §2)
f7264e1 v0.30 round 92 (docs): AGENTS.md 补 check_16kb_alignment.py (16→17 守门员)
7918d55 docs(sdd/r92): task-2 report
463e6d4 v0.30 round 92 (ui): treatment_page 真页面 (R91 placeholder 替换) + 4 字段 AddDialog
4ecb85b v0.30 round 92 (ui): assessment_center 顶部 mini 趋势图 (复用 R90 chart widget)
509f538 v0.30 round 92 (i18n): crisis_hotline_page + 5 地区热线 + 删 2 orphan todo key
c3e9cb6 v0.30 round 92 (fix): homeFabHotline / homeFabTop 真功能 (路由 + scroll)
6075654 v0.30 round 92 (fix): CBT wizard 5/7 栏完成按钮触发 save, 字段不丢
ca6f6e0 docs(sdd/r92): task-1 report
cb25cc1 v0.30 round 92 (cleanup): 软删 9 tracked 物理残留 + chroniccare.iml 兜底 .gitignore
cf91020 master HEAD
```

git status working tree clean, 9 commits ahead of master. 未碰 master, 未碰 R92 worktree 本身, 未碰 R84 之前 stash, 全部在 R92 分支 worktree 内完成。
