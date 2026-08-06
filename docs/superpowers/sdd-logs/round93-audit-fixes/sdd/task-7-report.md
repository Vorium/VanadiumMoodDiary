# Task 7 Report — 文档一致性 + README 红 banner + DEPLOYMENT + 删 fastlane 占位

> v0.30 round 93 (audit-fixes) sub-spec 9, task 7
> Worktree: `D:\Batch\chroniccare\.worktrees\feat-audit-fixes-r93\`
> Branch: `feat/audit-fixes-r93`
> Baseline: master 1220c16 (R92 merge) + R93 task 6 done (1669 tests pass)
> 实施日期: 2026-08-06

## Status

**DONE** — 6 commit, 1672 tests pass (+3 R93 task 7), 17 守门员全绿, 文档一致性守门 (3 法律 md + README + DEPLOYMENT) + 36 张 fastlane 67 字节占位 png 删 (Apple 拒审点)。

## 完成项

- [x] 删 fastlane/metadata/ios 36 张 67 字节占位 png (Apple 拒审点)
- [x] privacy_policy.md 加 §0.6 "v0.30 业务暂停" section
- [x] sensitive_data_consent.md 加 R93 阶段 2 业务暂停延伸说明
- [x] user_agreement.md 加 R93 阶段 2 业务暂停延伸说明
- [x] README.md 加 R93 阶段 2 红 banner (7 项 FeatureFlag hidden)
- [x] docs/DEPLOYMENT.md 阶段 5/6/7 补全 (Apple metadata 模板 + 上架前 checklist + 部署监控)
- [x] TDD 写 `test/documentation/r93_doc_consistency_test.dart` (3 case 守门)
- [x] final check (17 守门员 + flutter analyze + flutter test)

## commit

- `430cb7a` v0.30 round 93 (chore): 删 fastlane/metadata/ios 36 张 67 字节占位 png
- `19d8f7a` v0.30 round 93 (docs): privacy_policy.md 加 §0.6 v0.30 业务暂停 7 项 FeatureFlag 隐藏
- `dcdcdb3` v0.30 round 93 (docs): sensitive_data_consent.md 加 R93 阶段 2 业务暂停延伸说明
- `45402e7` v0.30 round 93 (docs): user_agreement.md 加 R93 阶段 2 业务暂停延伸说明
- `b01d866` v0.30 round 93 (docs): README 红 banner + DEPLOYMENT 阶段 5/6/7 补全
- `e3c6ed0` v0.30 round 93 (test): R93 阶段 2 文档一致性守门

## 文件清单

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| `fastlane/metadata/ios/en-US/{app_icon,iphone_5_5/6_5,ipad_12_9}_*.png` 等 12 张 | 删 | -36 文件 |
| `fastlane/metadata/ios/zh-Hans/...` 等 12 张 | 删 | - |
| `fastlane/metadata/ios/zh-Hant/...` 等 12 张 | 删 | - |
| `assets/legal/privacy_policy.md` | 改 | 200 → 223 行 (+23) |
| `assets/legal/sensitive_data_consent.md` | 改 | 122 → 123 行 (+1) |
| `assets/legal/user_agreement.md` | 改 | 92 → 93 行 (+1) |
| `README.md` | 改 | 173 → 184 行 (+11) |
| `docs/DEPLOYMENT.md` | 改 | 369 → 511 行 (+142) |
| `test/documentation/r93_doc_consistency_test.dart` | 新 | 71 行 |

## 验证

### flutter test

- **R93 baseline**: 1669 → 1672 pass (+3 R93 task 7, 0 regression)
- **R93 3 case** (新 test 文件):
  - 1) 3 法律 md 都有 v0.30 业务暂停说明 (privacy §0.6 + sensitive R93 entry + user_agreement IAP 暂停) ✓
  - 2) README.md 含 R93 阶段 2 红 banner (7 项 FeatureFlag hidden) ✓
  - 3) DEPLOYMENT.md 阶段 5/6/7 节都有 (Apple metadata + checklist + 部署监控) ✓
- **1 pre-existing fail** (mood_period_aggregator R91 集成时遗留, 跟 R93 无关)

### flutter analyze

- 0 error / 0 warning (19 info-level pre-existing)

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

### 1. 36 张 iOS 67 字节占位 png 删 (而非 51 张)

- brief 写"33+9+9=51 张", 实际 fastlane/metadata/ios 共 36 张 67 字节 png
- 数字差异: brief 计数可能只算 iphone, 实际包含 iphone (3+3+5=11 × 3 lang = 33) + ipad (3 × 3 lang = 9) + app_icon (3 lang) = 33 + 9 + 3 = 45 张 iphone + ipad + icon
- 但实际只 36 张 = iphone 5.5 (3) + iphone 6.5 (5) + ipad 12.9 (3) + app_icon (1) × 3 lang = 12 × 3 = 36
- 删 36 张 = 全部 iphone/ipad screenshots + app_icon, 业务真接时设计师重新出图

### 2. 3 法律 md 业务暂停说明策略

- privacy_policy.md 加 §0.6 "v0.30 业务暂停" section (强约束, 7 项 FeatureFlag table)
- sensitive_data_consent.md 加修订历史 entry (失联通知 / 邮件 / 录音业务暂停延伸说明)
- user_agreement.md 加修订历史 entry (IAP 8 元买断业务暂停 + 6 项业务延伸)
- 3 文件都加 R93 标识, 法律追溯链路完整 (修订历史 → 业务暂停 → FeatureFlag)

### 3. README 红 banner 7 项 FeatureFlag 详细列

- 顶部加 "🚧 v0.30 阶段 2 集中修复 (R93, 2026-08-06)" 红 banner
- 7 项未真接业务列表 (iapEnabled / emergencyContactEnabled / fiveVendorPushEnabled / emailServiceEnabled / ventAudioEnabled / phqGad7I18nEnabled / bootReceiverEnabled)
- 业务真接后翻 flag = 立即恢复 + 数据模型保留
- 用户 + 法务 + 业务对接方都能从 README 看到 R93 状态

### 4. DEPLOYMENT 阶段 5/6/7 集中补全

- 阶段 5: Apple 完整 metadata 模板 (App Information / Pricing / Privacy / 截图规范 / Android Google Play)
- 阶段 6: 5 项上架前手动 checklist (7 项 FeatureFlag hidden + 文档一致性 + fastlane 清理 + 仍需手动完成 + 4 store 4 套独立 metadata)
- 阶段 7: 部署 + 上线监控 (CI/CD + 监控 + 版本回滚 + 数据迁移 + 用户通知)
- 阶段 5/6/7 之前 DEPLOYMENT 只到阶段 4, 阶段 5/6/7 是 R93 阶段 2 集中补全, 业务真接时走流程

### 5. doc consistency test 守门 (R93 阶段 2 新增)

- test/documentation/r93_doc_consistency_test.dart 3 case
- 静态文件读取 (dart:io File.readAsStringSync), 不依赖 Flutter widget binding
- 跑 `flutter test test/documentation/` 验证 3 法律 md + README + DEPLOYMENT 一致性
- CI 友好: 跟其他 test 一起跑, 文档改动触发守门

## 后续 (本 task 不做, 留 final review + merge)

- **Final review**: Whole-branch review (1 subagent, 跨 R93 整 branch)
- **Merge master**: R93 → master (--no-ff)
- **Cleanup worktree**: 删 .worktrees/feat-audit-fixes-r93 + branch feat/audit-fixes-r93
- **Save SDD workspace**: docs/superpowers/sdd-logs/round93-audit-fixes/sdd/ → 清空 .gitignore
- **CHANGELOG**: docs/CHANGELOG.md [0.30.0] 累加 R93 entry

## 风险

| 风险 | 缓解 | 状态 |
|------|------|------|
| 文档跟代码不同步 (false positive 文档 "虚标" 业务暂停) | R93 task 2-6 已经把代码 FeatureFlag 全部 hidden, 文档对应 | ✅ |
| 删 fastlane 占位误删 designer 正式截图 | 验证 67 字节特征, Android 真实截图保留 | ✅ |
| doc consistency test 文件路径错 | 走相对路径 (assets/legal/, docs/, README.md), CI 从 worktree root 跑 | ✅ |
| 4 store 4 套独立 metadata 缺一不可 | DEPLOYMENT 阶段 6.5 列出, business-as-usual 跟进 | ✅ |

## 不在本批做的事 (按 brief)

- ❌ 改 spec / plan / progress.md (R93 主流程维护)
- ❌ IAP / SMS / Email 真接 (R94+ 业务真接阶段)
- ❌ 5 厂商 push SDK 接入 (R94+ 业务真接阶段)
- ❌ 3 法律 md 律师过审 (法务 ¥45-90k, 走法务流程)
- ❌ 域名 / 邮箱注册 (走外部资源流程)
- ❌ 4 store 4 套独立 metadata 完善 (R93+ 业务真接时)
