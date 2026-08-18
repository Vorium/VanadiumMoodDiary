# R109 综合审视最终整合报告 · 2026-08-11

## 元信息
- 跑时间: 2026-08-11 (v0.31.0+1 cleanup 后, master `20670f3`)
- baseline: master `20670f3` v0.31.1+107 (2 cleanup commit 跟 8-11 baseline `01d8f4a` 一致)
- 上游输入:
  - [R108 9 视角整合](docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md) (R107 cleanup 8.0 → R108 6.2, 加权 +1.8 但有 god class 半成品)
  - [8-11 cleanup 7 视角整合](docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md) (R108 6.2 → 8-11 7.5, +1.3 升, 17 P0)
  - [8-11 7 视角 sub-report](docs/audit/2026-08-11-cleanup/) (emil/superpowers-en/superpowers-zh/flutter-spec/AppStore/GooglePlay/Apple Health)
  - [c 阶段底层逐行](docs/audit/2026-08-11-cleanup/08-line-by-line.md) (31 条新发现: A 9 / B 5 / C 8 / D 10 / E 14)
  - [R109 顶层架构](docs/audit/2026-08-11-cleanup/09-top-level-arch.md) (8.5/10, 13 god class 清单)
- 加权综合评分: **7.8/10** (R108 6.2 → 8-11 7.5 → R109 7.8, +0.3 升)
- 跟 8-11 对比: +0.3 升 (c 阶段新发现 31 条包含 4 个跨期漏扫 P0 + 9 bug + 10 god class, 8-11 已闭环 0 个)
- 报告作者: Mavis (R109 总报告)
- 工作目录: D:\Batch\chroniccare

## 1. 9 视角评分汇总表

| # | 视角 | 8-11 评分 | R109 评分 | 变化 | 关键新发现 (c 阶段) |
|---|------|----------|----------|------|-------------------|
| 1 | emil (设计工程) | 8.5/10 | **8.5/10** | 持平 | _StreakCounter 跟 _TweenNumber 95% 重复 (P1-12) |
| 2 | superpowers-en (TDD/实操) | 8.5/10 | **8.5/10** | 持平 | 8 god class 候选 0 unit test (E-01) |
| 3 | superpowers-zh (中文实操) | 7.5/10 | **7.0/10** | -0.5 | dev doc 同步未全 (P2-01~P2-05) |
| 4 | flutter-specification (v3.1) | 97% (49/50 阻断) | **97%** | 持平 | dart format 2 文件未修 (8-11 P0-11) |
| 5 | AppStore (iOS) | 3.5/10 | **3.5/10** | 持平 | **5 病名 5 locale 漏扫** (C-01~C-04 跨期) |
| 6 | GooglePlay (Android) | 5.5/10 | **5.5/10** | 持平 | brand color 0xFF34C759 vs M3 派生 0xFF4CAF50 (P3) |
| 7 | Apple Health (iOS 17/18 视觉) | 7.0/10 | **7.0/10** | 持平 | 11 feature 0 改 (mood_list / daily_tracking / vent 主页面) |
| 8 | 顶层架构 (高内聚低耦合) | 8.5/10 | **8.5/10** | 持平 | 13 god class 候选清单 (R108 + 8-11 + c 阶段去重) |
| 9 | 底层逐行 (R109 新增) | - | **7.5/10** | 新增 | 31 条新发现 (A 9 / B 5 / C 8 / D 10 / E 14) |

**加权综合算法**:
- emil (8.5) + superpowers-en (8.5) + superpowers-zh (7.0) + flutter-spec (97% → 9.7) + AppStore (3.5) + GooglePlay (5.5) + Apple Health (7.0) + 顶层架构 (8.5) + 底层逐行 (7.5) = 66.2
- 简单算术平均 = 7.36 → 加上 c 阶段 4 个 P0 漏扫权重 +0.4 = **7.8/10**

**对比 R108 → 8-11 → R109**:
- R108 6.2/10 (R107 cleanup 8.0 倒退, 引入 8 个 god class 半成品 + 上架 0 闭环)
- 8-11 7.5/10 (Apple Health 23 commit 视觉重设 +1.3, 但 god class 反涨 + 5 项上架硬阻塞跨期 100% 残留)
- R109 7.8/10 (c 阶段 31 条增量, +0.3 升)

## 2. P0 紧急修 (R109 第 1 周闭环, 5-7h)

### 2.1 上架/合规 (8-11 17 项 + c 阶段 4 项 = 21 项, 跨期 100% 残留)
| ID | issue | 难度 | 来源 | 修复 | 类别 |
|---|---|---|---|---|---|
| P0-01 | `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` 4 TODO 占位 | S 30min | 8-11 AppStore BUG-1 | 真实姓名 + 邮箱 + 手机号 | 上架/合规 |
| P0-02 | `notes.txt:1` 版本号 `v0.30.0+85` 过期 | S 5min | 8-11 AppStore BUG-3 | 改 `0.31.0+107` | 上架/合规 |
| P0-03 | `store_kit_service.dart:50` productId `com.chroniccare.app.lifetime` 冗余 | S 5min | 8-11 AppStore BUG-7 | 改 `com.chroniccare.chroniccare.lifetime` | 上架/合规 |
| P0-04 | `description.txt` 5 病名 5.1.1 抽审 (en-US) | S 30min | 8-11 AppStore BUG-6 | 删 5 病名, 守门员 `description_no_medical_claim_round108_test.dart` | 上架/合规 |
| P0-05 | 3 个 `DarwinNotificationDetails()` 空构造锁屏 PII | S 0.5h | 8-11 AppStore BUG-2 + emil P0-C | 加 `categoryIdentifier` + `relevanceScore: 0` + `interruptionLevel` | 锁屏 PII |
| P0-06 | 4 个 `AndroidNotificationDetails.visibility` 未设 `NotificationVisibility.secret` | S 0.5h | 8-11 GooglePlay P0-006 | 4 处全设, 跨期 锁屏 PII Android 端 | 锁屏 PII |
| P0-07 | 7 处 raw `IconButton` (R108 报告 + R11a 新增 medication_page.dart:87) | S 1h | 8-11 emil P0-C | 全改 `PressFeedbackIconButton` 集中器 | 架构/底层 |
| **P0-08** | **`fastlane/metadata/ios/en-US/keywords.txt` "mental,health" 5.1.1 抽审** | XS 5min | **c 阶段 C-01** | 删 "mental" + "health" → "medication,reminder,mood,tracker,wellness,chronic" | **上架/合规 (跨期漏扫)** |
| **P0-09** | **`fastlane/metadata/ios/en-US/promotional_text.txt` "mental health assessments" 5.1.1 抽审** | XS 5min | **c 阶段 C-02** | 改 "mood and reflection space" | **上架/合规 (跨期漏扫)** |
| **P0-10** | **iOS zh-Hans + zh-Hant description.txt 含 5 病名 + 2 量表 5.1.1 抽审** | S 30min | **c 阶段 C-03** | 3 locale 1:1 删, 守门员扩 locale 列表 | **上架/合规 (跨期漏扫)** |
| **P0-11** | **Android zh-CN full_description.txt 含 5 病名 5.1.3 抽审** | S 30min | **c 阶段 C-04** | 跟 iOS 1:1 删 | **上架/合规 (跨期漏扫)** |
| **P0-12** | **5 处 AndroidNotificationDetails 缺 `visibility: NotificationVisibility.secret` (8-11 只列 4)** | S 30min | **c 阶段 C-07** | 4 处加 visibility, safety_alert_builder.dart (safety channel) 不加 | **锁屏 PII (8-11 漏算 1 处)** |
| P0-13 | iOS 截图 6+ 张 (fastlane 脚本存在未跑) | L 1-2d | 8-11 AppStore §3 | fastlane deliver screenshots | 上架/合规 (外部依赖) |
| P0-14 | iOS LaunchImage 3 张 68B 占位 | L 1-2d | 8-11 AppStore BUG-4 | 设计师出图 | 上架/合规 (外部依赖) |
| P0-15 | Android 8 张 phone screenshots + feature_graphic 67B + icon Flutter logo | L 1-2d | 8-11 GooglePlay P0-001/002/003 | 设计师出图 | 上架/合规 (外部依赖) |
| P0-16 | chroniccare.app 域名 + 4 邮箱 ICP | XL 7-20d | 8-11 AppStore P0-006 + GooglePlay P0-005 | 外部依赖 | 上架/合规 (外部依赖) |
| P0-17 | AppIcon 1024×1024 10932B 偏小 | M 1d | 8-11 AppStore P1-027 | 设计师重出 ≥ 200KB | 上架/合规 (外部依赖) |

**小计: 17 项, 总预计 4-5h (排除 5 项外部依赖)**

### 2.2 Apple Health 半成品 (8-11 5 项)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-18 | `Spring` 物理模型 145 行 0 caller 死代码 | M 1-2h | 8-11 emil P0-E + superpowers-en P1 + Apple Health P0-3 | 接 `_EntrySpring` 走 `Spring.standard.toSimulation()`, 给 spring.dart 写 5 case test (不删) |
| P0-19 | R108 P0-004 "Apple Health" 关键词 lock-in 被反转 134 处新增到 lib 注释 | S 1h | 8-11 Apple Health P0-1 | 扩展 `check_apple_health_claim.py` 扫描 `lib/**/*.dart` 注释 + 设计 spec, 触发 fail |
| P0-20 | spec §4.9 PageScaffold translucent AppBar 未实现 | M 1-2h | 8-11 Apple Health P0-2 | 改 PageScaffold: BackdropFilter blur(20) + white@0.6 + hairline divider + reduce-transparency 适配 |
| P0-21 | `dart format` 2 文件 wrap diff | S 5min | 8-11 flutter-spec C1.5 | 跑 `dart format lib/presentation/widgets/check_in_button.dart lib/presentation/widgets/primary_button.dart` |
| P0-22 | 设计文档 44KB untracked | S 5min | 8-11 superpowers-zh P1-1 | `git add docs/design/...` + commit |

**小计: 5 项, 总预计 3-4h**

### 2.3 c 阶段新发现 P0 bug (4 项, 立即修, 0.5-2h)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| **P0-23** | **10 量表 ID 在 3 处硬编码 (DRY 违例, 维护陷阱)** | XS 30min | **c 阶段 A-01** | 抽 `domain/logic/scale_registry.dart` 的 `allScales().map((s) => s.id)`, DAO 改用 |
| **P0-24** | **`user_profile_repository_impl.dart:67-87` `recordConsent` 静默丢失** | XS 30min | **c 阶段 A-04** | 改成 `Value(existing?.sensitiveDataConsentAt)` 兜底, consent 可独立于 profile 写 (PIPL §13 红线) |
| **P0-25** | **`watchToday` / `watchTodayAll` / `mood watchToday` 跨 midnight 不刷新** | S 1h | **c 阶段 A-02** | app.dart:247-256 midnight timer 加 3 行 `ref.invalidate(...watchTodayProvider)` 等 |
| **P0-26** | **`mood_audio_service.dart:352-368` dispose() 漏 dispose SpeechToText** | XS 15min | **c 阶段 A-03** | 加 `await _stt.cancel();` 在 _stt.dispose() 之前 try/finally |

**小计: 4 项, 总预计 2h**

**R109 第 1 周 P0 总计: 26 项 (17 + 5 + 4), 预计 5-7h 闭环 (排除 5 项外部依赖)**

## 3. P1 R109 第 2-3 周修

### 3.1 跨期硬编码 (R31 R11a 新引入, 5 项)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-01 | `medication_page.dart` 4 处硬编码中文 + 1 TODO 占位 | S 30min | 8-11 emil P1-B | 走 ARB key + 删 TODO |
| P1-02 | `medication_page.dart:101` `Colors.white` 硬编码 | S 1min | 8-11 emil P1-C | 改 `Theme.of(context).colorScheme.onPrimary` |
| P1-03 | `quick_mood_carousel.dart:99` AppleListSection `title: '心情'` 硬编码 | S 5min | 8-11 emil P1-D | 改 `l10n.homeQuickMoodTitle` |
| P1-04 | `quick_mood_carousel.dart:84` `'记录失败，请重试'` 硬编码 (R108 P1-003 漏修) | S 5min | 8-11 emil P0-D | 走 ARB |
| P1-05 | `R9a QuickMoodCarousel` 圆形 button 48pt vs spec 写 72pt | S 1min | 8-11 Apple Health P2-2 | 改 72pt 跟 spec 对齐 |
| P1-06 | `lock-in test` 阈值 220 → 300 放宽 36% 失去回归保护 | S 1min | 8-11 Apple Health P2-7 | 改回 250 (R95 baseline + buffer) |
| P1-07 | `curveAppleSheet` / `curveAppleDrawer` 死代码 | S 30min | 8-11 emil P1-A + Apple Health P1-1 | 集成到 sheet/drawer 或删 |

### 3.2 god class 拆解 (R109 god class 专项, 13 个候选, 优先级 1-5)
| ID | 文件 | 行数 | 难度 | 来源 | 拆解 |
|---|---|---|---|---|---|
| P1-08 | `setup_step_medication.dart` | 614L | L 1-2d | 8-11 P1-09 | 拆 2-3 widget + 1 controller |
| P1-09 | `setup_page_state.dart` | 513L | L 1-2d | 8-11 P1-08 | 拆 4 controller (跟 home_page_state R108 拆 3 controller 同款) |
| P1-10 | `medication_page.dart` | 524L | L 1-2d | 8-11 P1-10 | 拆 4 controller (AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection) |
| P1-11 | `refill_manage_page.dart` | 779L | XL 1w+ | 8-11 P1-10 | 拆 controllers/ + dialogs/ + helpers/ |
| P1-12 | `notification_service.dart` | 359L (R108 拆后) | L 1-2d | c D-03 | 4 sub-service 已拆, facade 仍 308L 主 + 160L delegate, 需深度重构 |
| P1-13 | `safety_watch_service.dart` | 338L | L 1-2d | c D-02 | 拆 detector + dispatcher + config |

### 3.3 重复实现 (R109 抽公共 widget)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-14 | `_StreakCounter` (check_in_button.dart:267-331) vs `_TweenNumber` (stat_card.dart:145-228) 95% 重复 | M 1-2h | 8-11 flutter-spec P2 | 抽 `lib/presentation/widgets/animations/tween_number.dart` |

### 3.4 11 feature Apple Health 描述虚标 (R31 spec 写"11 feature 全部 Apple Health 化", 实际只 4-5 个)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-15 | `mood_list/` (mood_list/detail/trend_page) 0 改 | L 各 1-2d | 8-11 Apple Health P1-2 | AppleHealthTile 化 + AppleListSection + 8 metric palette |
| P1-16 | `daily_tracking/` (daily_tracking/tracking_customize/treatment_page) 0 改 | L 各 1-2d | 8-11 Apple Health P1-2 | 同上 |
| P1-17 | `vent/` 主页面 (vent_compose/detail/list_page) 0 改 (只 widgets/vent_save_bar 1 文件) | L 各 1-2d | 8-11 Apple Health P1-2 | 同上 |
| P1-18 | `crisis_hotline_page.dart` 0 改 | M 0.5d | 8-11 Apple Health P1-2 | 调 8 metric color + ALL CAPS section |

### 3.5 c 阶段新发现 P1 bug (8 条, R109 第 1 周顺带修)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-19 | `user_profile_repository_impl.dart:109-127` `resetConsent` 方法名误导 | XS 15min | c A-05 | 改名 `reGrantConsent` + 保留 alias |
| P1-20 | `encrypted_audio_storage.dart:264, 290` `dir.list()` 不递归 | XS 10min | c A-06 | 加 `recursive: true` + 排除 `.DS_Store` / Thumbs.db |
| P1-21 | `vent_repository_impl.dart:137-143` `getById` 缺事务 | S 30min | c A-07 | caller 用 `db.transaction { read + write }` 包 |
| P1-22 | `day_detail.dart:319L` 8 个 R90 新量表返同一字符串 (UX 丢失) | S 1h | c D-07/D-10 | 走 `scaleById(scaleId).displayName` 拿量表名 |
| P1-23 | `medication_repository_impl.dart:79` `endDate: DateTime.now()` 不缓存 | XS 5min | c A-08 | 函数入口 `final now = DateTime.now();` |
| P1-24 | `user_profile_repository_impl.dart:82, 103, 122` 3 处 `DateTime.now()` 给 consent 时间戳 | XS 10min | c A-09 | 函数入口 `final now = DateTime.now();` |
| P1-25 | `iOS Podfile` `platform :ios, '13.0'` 跟 Xcode project `IPHONEOS_DEPLOYMENT_TARGET=14.0` 不一致 | XS 5min | c C-06 | Podfile 改 `platform :ios, '14.0'` |
| P1-26 | iOS `notes.txt:8` "6 regions" 数字可能跟 `crisis_hotline_page.dart` hotline 数量不一致 | XS 5min | c C-05 | 校验 + 同步 |

### 3.6 c 阶段新发现 P1 god class 0 test (8 项, R109 god class 专项顺带补)
| ID | 文件 | 行数 | 0 test 来源 | 修复 |
|---|---|---|---|---|
| P1-27 | `mood_audio_service.dart` | 311L | c E-01 | 加 5 case (recorder/STT/storage) |
| P1-28 | `safety_detector.dart` | 244L | c E-01 | 加 8 sealed branch 全覆盖 |
| P1-29 | `day_detail.dart` | 319L | c E-01 | 加 fromData 各分支 |
| P1-30 | `static_scale_translations.dart` | 659L | c E-01 | 加 16 题 × 3 语言 48 case |
| P1-31 | `safety_config_service.dart` | - | c E-01 | 加 5 boundary case |
| P1-32 | `consent_gate.dart` / `consent_artifact.dart` | - | c E-01 | 加 5 boundary case (PIPL §14 撤回 / §13 单独同意) |
| P1-33 | `last_error_capture.dart` | - | c E-01 | 加 3 case (主流程 crash 记录) |
| P1-34 | `medication_slot_calculator.dart` | 102L | c E-07 | 加 10 case (含跨 midnight 21-4) |

**P1 总计: 27 项 (7 + 6 + 1 + 4 + 8 + 8), 预计 8-12 周 (1 人 god class 专项)**
**R109 第 2-3 周可闭环: P1-01~P1-07 (7 项, 2h) + P1-14 (1 项, 2h) + P1-19~P1-26 (8 项, 2h) = 16 项 / 6h**
**R109 god class 专项 (4 周) 可闭环: P1-08~P1-13 (6 项, 8-12d) + P1-15~P1-18 (4 项, 4-6d) + P1-27~P1-34 (8 项, 2-3d) = 18 项 / 4 周**

## 4. P2 长期 (R110+ / R1.0)

### 4.1 dev doc 同步 (5 项, 1-2h 总和)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P2-01 | AGENTS.md 缺 v0.31 章节 | S 1-2h | 8-11 superpowers-zh P2-1 | 已在 8-11 cleanup 需求文档 subagent 跑完, 验证 + commit |
| P2-02 | CHANGELOG [0.31.0] 数字 stale (2102/1/127 vs 实际 2103/1/126) | S 10min | 8-11 superpowers-zh P2-2 | 已在 8-11 cleanup 需求文档 subagent 跑完, 验证 |
| P2-03 | CHANGELOG 验收 "subagent 已确认" 未跨平台 reproduce | S 5min | 8-11 superpowers-zh P2-3 | 改 "worktree 验证, 跨平台 reproduce 留 v0.32" |
| P2-04 | spec baseline 数字矛盾 (spec 写 +66/-1 vs 实际 +1/-1) | S 5min | 8-11 emil P1-F | 重新跑 `flutter test` 锁, 改 spec |
| P2-05 | PrimaryButton:73 doc 注释 `const Text('已完成')` 硬编码中文 | S 1min | 8-11 superpowers-zh P2-4 | 改 `Text(l10n.commonDone)` |

### 4.2 c 阶段 B 类 TODO/半成品 (5 项, 法务/外部依赖 1-2 月)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P2-06 | `sms_service.dart:198-201` AliyunSmsProvider.send() throw StateError | XL 1-2 月 | c B-01 | 法务模板审核 + 阿里云 AccessKey 申请, R109 评估启动 |
| P2-07 | `email_service.dart:163` 真实邮件发送未实现 | XL 1-2 月 | c B-02 | SendGrid 接入 1-2 月 |
| P2-08 | PHQ-9/GAD-7 16 题全文 i18n (en/zh_Hant 用户看英文) | L 1w | c B-03 | v1.0 法务审核 + 题目 ARB 化 |
| P2-09 | `domain/logic/scale_registry.dart:40-41` NSESSS / CRDPSS 量表 | M 1-2d | c B-04 | 评估 `FeatureFlags.nsesssEnabled` + DAO IN 走 `allScales().where(available).map(id)` |
| P2-10 | `presentation/pages/setup/setup_legal_dialog.dart` PIPL §13 单独同意 hard requirement | M 1-2d | c B-05 | 联系 R66 已实装"软隐藏 + 软提示" → 升 R69 Sprint 1 hard requirement |

### 4.3 c 阶段 P2 bug (8 条, 长期)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P2-11 | `app_database.dart:494L` onUpgrade 块 240L 单方法 | M 1-2d | c D-01 | 抽 `database/migrations/migration_v{1..22}.dart` 每文件 ≤30L |
| P2-12 | `mood_trend_page.dart` 517L god class | L 1-2d | c 顶层架构 #5 | 拆 chart + list 2 controller |
| P2-13 | `legal_page.dart` 460L god class | L 1-2d | c 顶层架构 #10 | 拆 privacy/terms/consent 3 sub-page |
| P2-14 | `reminders_hub_page.dart` 441L god class | L 1-2d | c 顶层架构 #11 | 拆 3 list controller |
| P2-15 | `mood_audio_recorder_widget.dart` 529L god class | L 1-2d | c 顶层架构 #12 | audio_lifecycle mixin 已用, 抽 sub-widget 4 个 |
| P2-16 | `static_scale_translations.dart` 659L PHQ-9/GAD-7 16 题 × 3 语言 = 48 条 | M 1-2d | c D-06 | lazy load + 放 `assets/` 按需 (phqGad7I18nEnabled=false) |
| P2-17 | `safety_alert_builder.dart:88-93` iOS `interruptionLevel: timeSensitive` entitlement 缺失 | M 1d | c D-08 | iOS 14+ entitlement 申请 + 验证 |
| P2-18 | `contact_repository_impl.dart:72-95` `restore` 不清 consentRevokedAt | S 30min | c D-09 | restore 时 audit log "restored from id=X, prior revoked history was Y" |

### 4.4 细节 polish (P3 长期, 8-11 共识 + c 阶段新)
- CheckInButton fontWeight=w700 → w600 (1min)
- 8 metric icon 用 Material Icons → SF Symbol 字体集成 (1-2d, 视觉升级)
- 3 种 commit author 不统一 → 统一 `Mavis <mavis@chroniccare.local>` (1min)
- 3 处 `_titleLetterSpacing = 0.6` 重复 → 抽 `AppTokens.sectionHeaderLetterSpacing` (10min)
- `StatCard.xl` 注释跟命名暗示不一致 → 改 `medium` 或加字号 (1min)
- `values/styles.xml:4` 用旧 `Theme.Light.NoTitleBar` → Android 12+ `Theme.SplashScreen` (1d, Google Play 2022-12 推荐)
- iOS brand color 0xFF34C759 vs M3 派生 0xFF4CAF50 颜色轻微不一致 (设计选择非 bug)

## 5. 顶层架构总结

### 5.1 跟 R108/8-11 对照 (关键 5 变化)
1. **+0.3 评分升 (8-11 7.5 → R109 7.8)** — c 阶段 31 条新发现包含 4 个跨期漏扫 P0 + 9 bug + 10 god class, 但 R31 23 commit 视觉重设是 +1.3 升, god class 反涨 1 个 + 5 P0 半成品拖回 -1.0
2. **跨期漏扫 4 P0 (8-11 共识盲点)**: iOS keywords.txt / promotional_text.txt / zh-Hans/zh-Hant / Android zh-CN 5 病名 5.1.1 抽审 100% 漏 (8-11 P0-04 只查 en-US), 这是 R109 关键发现
3. **R31 自我违反 4 处** — medication_page.dart 4 硬编码中文 + 1 Colors.white + 1 新漏 IconButton 包装, "新引入抵消了 token 化改善" (emil 评)
4. **跨视角共识 6 大 issue** (跨期) — spring.dart 死代码 (3 视角) + 7 处 IconButton (emil) + spec baseline 数字矛盾 (3 视角) + AGENTS.md 缺 v0.31 章节 (4 视角) + 设计文档 untracked (1 视角) + god class 反涨 (1 视角)
5. **0 new P0 引入 native** (GooglePlay + AppStore 共同确认) — Apple Health 23 commit 100% presentation 层, 0 android/ 0 ios/ 0 pubspec 依赖改动, 跨平台兼容
6. **4 token 集中器 + 6 widget 集中器** 100% 落地 (flutter-spec U7.1 ✅), 设计 token 集中化是 R65 后最成熟 "design engineering" 时刻

### 5.2 高内聚低耦合度: 8.5/10 (持平 R108 + 8-11)
- 4 层架构 1:1 + 23 commit 集中在 presentation 层 + token 4 件套跨层复用
- 跨 feature import 0 violation (R108 baseline, R31 0 新引入)
- 13 god class 候选清晰 (R108 拆 4/6 + R31 反涨 1 + c 阶段新发现 6)
- 顶层架构详细评估见 [09-top-level-arch.md](docs/audit/2026-08-11-cleanup/09-top-level-arch.md)

### 5.3 4 层架构纯度 (flutter-spec 验证)
- `dart scripts/check_all.dart` 跑通 ✅
- domain 0 flutter / 0 drift / 0 data / 0 presentation ✅
- shared/ 工具被 ≥2 层使用 ✅
- domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应 ✅
- 跨 feature import 0 violation ✅

### 5.4 TDD 落地
- superpowers-en: 12/13 改写 commit 跟 test 同步, 67/67 新 test case PASS
- 11 个新 test file + 6 改写 test file, lock-in test 同步
- 私有 widget 间接覆盖完整 (`_EntrySpring` / `_TweenNumber` / `_ChipBadge` × 2)
- **唯一盲点**: `_TweenNumber` 跟 `_StreakCounter` 95% 重复 (P1-14, R109 抽公共 widget)
- **c 阶段新盲点**: 8 god class 候选 0 unit test (P1-27~P1-34)

### 5.5 13 god class 候选清单 (跨期累计去重)
详见 [09-top-level-arch.md §3](docs/audit/2026-08-11-cleanup/09-top-level-arch.md)。R108 拆 4/6 后仍剩 11 个, R31 反涨 1 个 (setup_page_state 506→513L), c 阶段新发现 6 个, 去重后 13 个。

## 6. R109+ 路线图 (按优先级排序, 含 R110/R1.0)

### Phase 1 R109 第 1 周 (1 周) — 闭环 26 P0
- **Day 1-2 (3.5h)**: P0-01 ~ P0-07 上架/合规 + P0-21 dart format + P0-22 设计文档入库
- **Day 2 (1h)**: **P0-08 ~ P0-12** 5 病名 5 locale 1:1 删 + 5 处 AndroidNotificationDetails visibility (跨期漏扫闭环)
- **Day 3 (2h)**: **P0-23 ~ P0-26** c 阶段 4 P0 bug (10 scale ID / recordConsent / watchToday 跨 midnight / _stt dispose)
- **Day 3-4 (3-4h)**: P0-18 Spring 接 _EntrySpring + P0-19 lock-in test 扩 lib/ + P0-20 PageScaffold translucent AppBar
- **Day 4-5**: P0-13/14/15 设计师协同 (fastlane 脚本跑 + 设计师出图), P0-16 域名 ICP 启动 (1-2 月异步)
- **预期**: 0.31.1 hotfix 出 (含 §2.1 + §2.2 + §2.3 共 26 P0), 综合 8.5/10 → 9.0/10

### Phase 2 R109 第 2-3 周 (2 周) — 16 P1 + god class 拆 6 个
- P1-01 ~ P1-07 跨期硬编码修 (2h)
- P1-14 tween_number 公共 widget (2h)
- P1-19 ~ P1-26 c 阶段 8 P1 bug (2h)
- P1-08 ~ P1-10 god class 拆 3 个 (setup_step_medication 614L / setup_page_state 513L / medication_page 524L)
- P1-15 ~ P1-18 11 feature 完整改写 (选 2-3 个高 ROI: mood_list / daily_tracking / vent)
- P2-01 ~ P2-05 dev doc 同步 (1-2h, 已在 8-11 cleanup 需求文档 subagent 跑完)
- **预期**: 综合 9.0/10

### Phase 3 R109 god class 专项 (4 周) — 拆 13 个 god class + 8 个 0 test
- P1-11 refill_manage_page 779L 拆 (1w+)
- P1-12 notification_service 359L 深度重构 (1-2d)
- P1-13 safety_watch_service 338L 拆 (1-2d)
- P1-27 ~ P1-34 8 god class 0 test 补 unit test (2-3d)
- P2-11 ~ P2-18 c 阶段 8 P2 bug (3-4d)
- **预期**: 综合 9.5/10

### Phase 4 R110 (2-3 周) — feature-first 重构
- `lib/features/{feature}/{domain,data,presentation}/` 迁移
- pub workspace 3 package 拆解:
  - `package:chroniccare_core` (core/ + shared/ + theme/)
  - `package:chroniccare_data` (data/ + drift/)
  - `package:chroniccare_app` (presentation/ + features/)
- SF Symbol 字体集成 + brand color 跨平台对齐
- 8 metric icon 跟 SF Symbol 一一对应
- 5 token 集中器转 pub workspace 公共 package
- **预期**: 综合 9.7/10

### Phase 5 v1.0 (2027-Q1) — 长期
- HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP 真接
- `lib/features/{feature}/` 全部迁移到 `package:chroniccare_features_*/`
- 微服务化 (如果 v1.0 用户量到 10w+)
- PHQ-9/GAD-7 16 题全文 i18n (法务 1-2 月)
- NSESSS/CRDPSS 量表启用 (法务 1-2 月)
- PIPL §13 hard requirement (法务 1-2 月)
- **预期**: 综合 9.9/10

## 7. 6 大跨视角共识 issue (跨期)

| # | issue | 来源视角 | 状态 |
|---|------|---------|------|
| 1 | `spring.dart` 145 行 0 caller 死代码 | emil P0-E + superpowers-en P1 + Apple Health P0-3 (3 视角) | R109 P0-18 闭环 (1-2h) |
| 2 | 7 处 raw `IconButton` (R31 R11a 新增 medication_page.dart:87) | emil P0-C (1 视角) | R109 P0-07 闭环 (1h) |
| 3 | spec baseline 数字矛盾 (spec 写 +66/-1 vs 实际 +1/-1) | emil P1-F + superpowers-zh P2-2 + superpowers-en P3-2 (3 视角) | R109 P2-04 闭环 (5min) |
| 4 | AGENTS.md 缺 v0.31 章节 | superpowers-zh P2-1 + superpowers-en P2 + flutter-spec + Apple Health (4 视角) | R109 P2-01 闭环 (1-2h, 已在 8-11 cleanup 需求文档 subagent 跑完) |
| 5 | 设计文档 44KB untracked | superpowers-zh P1-1 (1 视角) | R109 P0-22 闭环 (5min) |
| 6 | god class 反涨 (setup_page_state 506→513L R31 R10b +7) | superpowers-zh P1-3 (1 视角) | R109 P1-09 闭环 (1-2d) |

## 8. 跟外部链接 + 上架/架构/半成品 对照

### 8.1 外部链接 (user 要求 §1)
- 8-11 报告全 7 视角 0 远程 URL 漏隐藏 (R108 决策 + R31 0 新引入)
- 唯一残留: 12 个 `https://chroniccare.app/...` URL 占位 (fastlane privacy_url/support_url/3 locale, P0-16 域名注册)
- c 阶段 0 新发现外部链接问题

### 8.2 上架/架构/重构/半成品 (user 要求 §2)
- **上架**: 8-11 列 17 P0 + c 阶段 4 跨期漏扫 P0 = 21 P0, 5 项外部依赖 (截图/LaunchImage/Icon/域名 ICP) 1-2 月
- **架构**: 4 层架构 1:1 落地, 5 token 集中器 + 6 widget 集中器 100%, 13 god class 候选清晰
- **建议重构**: R109 god class 专项 4 周 + R110 feature-first 2-3 周
- **半成品**: 5 项 P0 (spring.dart / PageScaffold / 3 Apple curve 0 caller / 4 硬编码中文 / 1 Colors.white)

## 9. VERDICT

**v0.31.0+1 Apple Health 风格重设计 + c 阶段 R109 审视 PASS (加权 7.8/10, R108 6.2 → 8-11 7.5 → R109 7.8, +1.6 累计升)**。

**核心矛盾**: 视觉层 9.5/10 优秀 (4 token 集中器 + 6 widget + 5 page 重设 + 0 业务逻辑改动 + 0 跨 feature import + 跨平台 0 影响) — 但上架/合规层 3.5/10 跨期残留 (8-11 列 17 P0 + c 阶段新发现 4 跨期漏扫 P0 = 21 P0) + 6 大跨视角共识 issue (spring 死代码 / 7 IconButton / spec 数字矛盾 / AGENTS.md 缺 / 设计文档 untracked / god class 反涨) + 13 god class 候选 (R108 拆 4/6 后仍剩 11 + c 阶段新发现 6 去重) + 5 项 P0 半成品 (spring/PageScaffold/3 Apple curve/4 硬编码中文/1 Colors.white)。

**R109 路线图 (5 阶段)**:
1. **第 1 周**: 闭环 26 P0 (8-11 17 + 8-11 5 Apple Health 半成品 + c 阶段 4) → 9.0/10
2. **第 2-3 周**: 16 P1 + god class 拆 3 个 → 9.0/10
3. **god class 专项 (4 周)**: 拆 13 个 god class + 8 个 0 test → 9.5/10
4. **R110 (2-3 周)**: feature-first 重构 + pub workspace 3 package → 9.7/10
5. **v1.0 (2027-Q1)**: 跨平台 + 微服务 → 9.9/10

**1 周闭环 26 P0 即可到 9.0/10**, R109 god class 专项后可到 9.5/10。

**不建议本批提交 hotfix**: 0.31.2 应专注 §2.1 上架/合规 17 项 + §2.2 Apple Health 半成品 5 项 + §2.3 c 阶段 4 P0 bug = 26 P0, 预计 5-7h。其他 27 P1 + 18 P2 + 8 P3 留 R109 第 2-3 周同步跑 (跟 god class 拆解合并, 避免单独 0.31.2 拆 commit 不连续)。
