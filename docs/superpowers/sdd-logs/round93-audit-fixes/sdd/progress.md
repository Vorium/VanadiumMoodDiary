# R93 (audit-fixes 阶段 2) Progress

> v0.30 round 93 (audit-fixes) sub-spec 9
> Started: 2026-08-06
> Branch: `feat/audit-fixes-r93`
> Worktree: `.worktrees/feat-audit-fixes-r93/`
> Spec: `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md` (15KB, v1)
> **Plan v2**: `docs/superpowers/plans/2026-08-06-audit-fixes-r93.md` (12KB, 2026-08-06 策略调整)

## Master baseline (跑前)

- master commit: 1220c16 (R92 merge 后)
- R93 task 1 done: baseline 1636 → 1646 pass (+10 R93)
- 1 pre-existing fail (mood_period_aggregator 跟 R93 无关, 留 R95+)
- 17 守门员全绿 (2 WARN: fullwidth_punctuation --warn-only / widget_dispose R92 task 2 已知)

## v1 → v2 策略调整 (2026-08-06)

| 维度 | v1 | v2 |
|------|-----|-----|
| 范围 | 20 项 M 难度, 5-7 task, 25-35 commit, 1-2 周 | 7 task, 12-18 commit, 3-5 天 |
| 主线 | 拆 medication_calendar 642 + data_management 606 god page | 隐藏未真接业务 (FeatureFlag 守护 + UI 完全 hidden) |
| 拆 god page | ✅ (v1 主线) | 拆 medication_calendar 保留 (task 1 done), data_management 留 R95+ |
| 业务加固 | 启动 health check + AudioController + safety test | 全部跳过, 留 R95+ |
| UI/UX | 主页重排 + trend narrative + tooltip | 全部跳过, 留 R95+ |
| 文档 | 30 处中文 l10n + DEPLOYMENT + progress 整理 | 3 法律 md 业务暂停说明 + README 红 banner + DEPLOYMENT + 删 fastlane 占位 |

## Tasks (7 task, 12-18 commit, 3-5 天)

### Task 1: 拆 medication_calendar god page (6 commit, 2-3d) — _DONE_ ✅

> v1 主线保留 (commit 22df332)

- [x] snapshot test baseline (commit f3712d0)
- [x] 拆 CalendarGrid (commit 3a8d333)
- [x] 拆 DayDetail (commit 6955324)
- [x] 拆 Legend (commit fdcba20)
- [x] cell tap 详情 (commit b639ac7)
- [x] test 局部函数名去下划线前缀 (commit 22df332)

### Task 2: FeatureFlags 11 项硬 false (2-3 commit, 0.5d) — _pending_

> 7 个真接业务没接, 业务不能默认开

- [ ] 改 `_prodBootReceiverEnabled = true` → `false`
- [ ] 加 4 个新 flag (AliyunSms / EmailService / FiveVendorPush / VentAudio)
- [ ] TDD 写 `test/core/data/feature_flags_round93_test.dart` (8 case)

### Task 3: 设置页 4 section 隐藏 (2-3 commit, 0.5-1d) — _pending_

> Apple 2.1 + PIPL §17 上架 blocker

- [ ] 隐藏 IAP 商业卡 + 失联通知 section (`settings_page.dart`)
- [ ] 隐藏 5 厂商 push + EmailService 邮件 (`settings_page.dart` + `notification_status_card.dart`)
- [ ] TDD 写 4 widget test

### Task 4: 联系人入口 + 主页失联 FAB 隐藏 (1-2 commit, 0.5d) — _pending_

> 病耻感 + 失联通信业务暂停 (R66 一致)

- [ ] 联系人设置入口 hidden (`contacts_list_page.dart`, setup 保留)
- [ ] 主页 homeFabHotline hidden (`home_fab_toolbar.dart`, homeFabTop 保留)
- [ ] TDD 写 2 widget test

### Task 5: PHQ-9 / GAD-7 量表隐藏 (1 commit, 0.5d) — _pending_

> en / zh_Hant 法律责任 + 翻译不完整

- [ ] 8 量表 → 6 显 (`assessment_center_page.dart`)
- [ ] TDD 写 1 widget test

### Task 6: vent + mood audio 录音隐藏 (1-2 commit, 0.5d) — _pending_

> vent 录音业务闭环不全

- [ ] vent 录音 icon hidden (`vent_compose_page.dart`)
- [ ] mood 录音 icon hidden (`mood_recorder_page.dart`)
- [ ] TDD 写 2 widget test

### Task 7: 文档 + 删 fastlane 占位 (3-4 commit, 0.5-1d) — _pending_

> 文档一致性 + Apple 拒审点清理

- [ ] 3 法律 md 业务暂停说明 (commit 1)
- [ ] README 红 banner + DEPLOYMENT 阶段 5/6/7 (commit 2)
- [ ] 删 fastlane 51 张 67 字节占位 png (commit 3)
- [ ] TDD 写 doc consistency test (commit 4)

### Final review + merge (1-2 commit) — _pending_

- [ ] Whole-branch review
- [ ] merge master
- [ ] cleanup worktree
- [ ] Save SDD workspace
- [ ] update `docs/CHANGELOG.md` [0.30.0] 增 R93 entry

## Findings (累计)

### Task 1 (commit 22df332)

- ✅ medication_calendar_page.dart 642 → 209 行 (< 250, 满足 brief)
- ✅ 3 sub-widget: CalendarGrid (317) + DayDetail (144) + Legend (96) = 557 行
- ✅ 10 R93 测试 pass, 0 regression
- ✅ 8 新 ARB key × 3 lang 同步, 0 orphan
- ⚠️ pre-existing 2 守门员 warning (fullwidth_punctuation / widget_dispose) 与本任务无关

## Final ledger (master merge 后填)

- 最终 commit 数: TBD (目标 12-18)
- baseline 1646 → TBD pass (目标 ≥1660)
- 17 守门员全绿 ✓
- 0 catch (_) 残留 ✓
- 0 TODO 半成品 widget ✓
- 0 硬编码中文 ✓
- FeatureFlags 11 项 `_prodXxxEnabled = const false` ✓
- 设置页 4 section hidden (IAP/失联/5 厂商/EmailService) ✓
- 量表入口 hidden (PHQ-9/GAD-7) ✓
- vent + mood 录音 hidden ✓
- README 红 banner 存在 ✓
- DEPLOYMENT.md 阶段 5/6/7 都有 ✓
- 3 法律 md "v0.30 业务暂停" section 都有 ✓
- fastlane 51 占位 png 全部 deleted ✓
