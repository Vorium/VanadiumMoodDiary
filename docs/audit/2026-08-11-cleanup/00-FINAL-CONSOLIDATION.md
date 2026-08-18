# v0.31.0 Apple Health 风格重设计 · 7 视角综合审视整合报告

## 元信息
- 跑时间: 2026-08-11
- baseline: master HEAD `01d8f4a` v0.31.0+107 (23 commit, 净 +7447/-3504)
- 7 视角 subagent: emil / superpowers-en / superpowers-zh / flutter-spec / AppStore / GooglePlay / Apple Health
- 评分范围: 5.5/10 (GooglePlay) ~ 9.7/10 (flutter-spec 97% 合规) — 加权综合 **7.5/10** (R108 6.2 → +1.3 升)

## 1. 7 视角评分汇总

| 视角 | 评分 | 关键产出 |
|---|---|---|
| flutter-spec | 97% (49/50 阻断项) | 1 阻断 (dart format 2 文件 5min) + 1 新 P2 (tween 重复) |
| emil | 8.5/10 | 16 发现 (5 P0 + 6 P1 + 5 P2) — 动效 + 设计 + iOS HIG 哲学 |
| superpowers-en | 8.5/10 | 1 P1 (Spring orphan) + 1 P2 + 3 P3 — TDD 红绿蓝 12/13 |
| Apple Health | 7.0/10 (R107 倒退 1.0) | 3 P0 gap + 11 feature 描述虚标 |
| superpowers-zh | 7.5/10 PASS | 3 P1 阻塞中文协作 + 3 P2 stale |
| AppStore | 3.5/10 (持平 R108) | 7 新 bug (5 P0 + 1 P1 + 1 5.1.1 抽审) + 5 R108 残留 |
| GooglePlay | 5.5/10 (持平 R108) | 0 新 P0, R108 26 P0 中 12 仍阻塞 |

## 2. P0 紧急修 (本周 / R109 第 1 周)

### 2.1 上架/合规 (跨期 100% 残留, 立即修, 0.5-2h 总和)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-01 | `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` 4 TODO 占位 | S 30min | AppStore BUG-1 | 真实姓名 + 邮箱 + 手机号 |
| P0-02 | `notes.txt:1` 版本号 `v0.30.0+85` 过期 | S 5min | AppStore BUG-3 | 改 `0.31.0+107` |
| P0-03 | `store_kit_service.dart:50` productId `com.chroniccare.app.lifetime` 冗余 | S 5min | AppStore BUG-7 | 改 `com.chroniccare.chroniccare.lifetime` |
| P0-04 | `description.txt:17,27` PHQ-9/GAD-7/depression/anxiety/bipolar/PTSD/ADHD 5.1.1 抽审 | S 30min | AppStore BUG-6 | 删 5 病名, 守门员 `description_no_medical_claim_round108_test.dart` |
| P0-05 | 3 个 `DarwinNotificationDetails()` 空构造 (notification_service:229 / reminder_dispatcher:110 / snooze_manager:95) 锁屏 PII | S 0.5h | AppStore BUG-2 + emil P0-C 跨视角 | 加 `categoryIdentifier` + `relevanceScore: 0` + `interruptionLevel` |
| P0-06 | 4 个 `AndroidNotificationDetails.visibility` 未设 `NotificationVisibility.secret` | S 0.5h | GooglePlay P0-006 | 4 处全设, 跨期 锁屏 PII Android 端 |
| P0-07 | 7 处 raw `IconButton` (R108 报告 + R11a 新增 medication_page.dart:87) | S 1h | emil P0-C | 全改 `PressFeedbackIconButton` 集中器 |

### 2.2 Apple Health 半成品 (本批引入)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-08 | `Spring` 物理模型 145 行 0 caller 死代码 (spec §3.4.3 双轨制空跑) | M 1-2h | emil P0-E + superpowers-en P1 + Apple Health P0-3 | 接 `_EntrySpring` 走 `Spring.standard.toSimulation()`, 给 spring.dart 写 5 case test (不删) |
| P0-09 | R108 P0-004 "Apple Health" 关键词 lock-in 被反转 134 处新增到 lib 注释 | S 1h | Apple Health P0-1 | 扩展 `check_apple_health_claim.py` 扫描 `lib/**/*.dart` 注释 + 设计 spec, 触发 fail |
| P0-10 | spec §4.9 PageScaffold translucent AppBar 未实现 (page_scaffold.dart 0 改) | M 1-2h | Apple Health P0-2 | 改 PageScaffold: BackdropFilter blur(20) + white@0.6 + hairline divider + reduce-transparency 适配 |
| P0-11 | `dart format` 2 文件 wrap diff (check_in_button + primary_button 各 1-2 行) | S 5min | flutter-spec C1.5 | 跑 `dart format lib/presentation/widgets/check_in_button.dart lib/presentation/widgets/primary_button.dart` |
| P0-12 | 设计文档 44KB untracked (`docs/design/2026-08-10-apple-health-redesign/{spec,plan,NEXT-SESSION-START-HERE}.md`) | S 5min | superpowers-zh P1-1 | `git add docs/design/...` + commit "0.31.0: 入库 Apple Health 设计文档" |

### 2.3 上架硬阻塞 (跨期, 设计师/外部依赖, 1-2 月)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P0-13 | iOS 截图 6+ 张 (fastlane 脚本存在未跑) | L 1-2d | AppStore §3 | fastlane deliver screenshots |
| P0-14 | iOS LaunchImage 3 张 68B 占位 | L 1-2d | AppStore BUG-4 | 设计师出图 |
| P0-15 | Android 8 张 phone screenshots + feature_graphic 67B + icon Flutter logo | L 1-2d | GooglePlay P0-001/002/003 | 设计师出图 |
| P0-16 | chroniccare.app 域名 + 4 邮箱 ICP | XL 7-20d | AppStore P0-006 + GooglePlay P0-005 | 外部依赖 |
| P0-17 | AppIcon 1024×1024 10932B 偏小 | M 1d | AppStore P1-027 | 设计师重出 ≥ 200KB |

## 3. P1 R109 第 2-3 周修

### 3.1 跨期硬编码 (R11a 新引入, 反 Apple Health l10n 原则)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-01 | `medication_page.dart` 4 处硬编码中文 ('待服'/'已服'/'需续方'/'查看') + 1 TODO 占位 | S 30min | emil P1-B | 走 ARB key + 删 TODO |
| P1-02 | `medication_page.dart:101` `Colors.white` 硬编码 | S 1min | emil P1-C | 改 `Theme.of(context).colorScheme.onPrimary` |
| P1-03 | `quick_mood_carousel.dart:99` AppleListSection `title: '心情'` 硬编码 (line 108 已用 l10n 但 99 漏) | S 5min | emil P1-D | 改 `l10n.homeQuickMoodTitle` |
| P1-04 | `quick_mood_carousel.dart:84` `'记录失败，请重试'` 硬编码 (R108 P1-003 漏修) | S 5min | emil P0-D | 走 ARB |
| P1-05 | `R9a QuickMoodCarousel` 圆形 button 48pt vs spec 写 72pt | S 1min | Apple Health P2-2 | 改 72pt 跟 spec 对齐 |
| P1-06 | `lock-in test` 阈值 220 → 300 放宽 36% 失去回归保护 | S 1min | Apple Health P2-7 | 改回 250 (R95 baseline + buffer) |
| P1-07 | `curveAppleSheet` / `curveAppleDrawer` 死代码 (spec §3.4.2 modal/drawer) | S 30min | emil P1-A + Apple Health P1-1 | 集成到 sheet/drawer 或删 |

### 3.2 god class 反涨 (R109 god class 专项重点)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-08 | `setup_page_state.dart` R108 标 506L → v0.31 R10b +7 → **513L** | L 1-2d | superpowers-zh P1-3 | 拆 4 controller (跟 home_page_state R108 拆 3 controller 同款) |
| P1-09 | `setup_step_medication.dart` **614L** 比 R108 标 add_medication_page 506L 还大 108L | L 1-2d | superpowers-zh P1-3 | 拆 2-3 widget + 1 controller |
| P1-10 | `medication_page.dart` 524L / `medication_detail_page` 287L / `refill_manage_page` 779L (R108 §六, 跨期) | XL 各 1-3d | flutter-spec P1 + R108 | 拆 controllers/ 模式 |
| P1-11 | `medication_page.dart` 4 AppleHealthTile 横滚 + 4 时间段分组 + 2 AppleListSection 拆 controller (emil 哲学) | XL 1w | emil 重构建议 | 跟 R108 home_page_state 拆 3 controller 同款 |

### 3.3 重复实现 (R109 抽公共 widget)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-12 | `_StreakCounter` (check_in_button.dart:267-331) vs `_TweenNumber` (stat_card.dart:145-228) 95% 重复 | M 1-2h | flutter-spec 新发现 P2 | 抽 `lib/presentation/widgets/animations/tween_number.dart` |

### 3.4 11 feature 描述虚标 (Apple Health spec §5.1-5.7 跨期)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P1-13 | `mood_list/` (mood_list/detail/trend_page) 0 改 | L 各 1-2d | Apple Health P1-2 | AppleHealthTile 化 + AppleListSection + 8 metric palette |
| P1-14 | `daily_tracking/` (daily_tracking/tracking_customize/treatment_page) 0 改 | L 各 1-2d | Apple Health P1-2 | 同上 |
| P1-15 | `vent/` 主页面 (vent_compose/detail/list_page) 0 改 (只 widgets/vent_save_bar 1 文件) | L 各 1-2d | Apple Health P1-2 | 同上 |
| P1-16 | `crisis_hotline_page.dart` 0 改 | M 0.5d | Apple Health P1-2 | 调 8 metric color + ALL CAPS section |

## 4. P2 长期 (R110+ / R1.0)

### 4.1 dev doc 同步 (1-2h 总和, R108 收尾)
| ID | issue | 难度 | 来源 | 修复 |
|---|---|---|---|---|
| P2-01 | AGENTS.md 缺 v0.31.0 章节 (5 phase / 13 task / 5 token + 6 widget 摘要) | S 1-2h | superpowers-zh P2-1 + superpowers-en P2 + flutter-spec + Apple Health | 加 "v0.31 R1-R13 视觉重设" 章节, 跟 R108 顶部格式一致 |
| P2-02 | CHANGELOG [0.31.0] 数字 stale (2104/1/126 vs 2095/1/123, 91 vs 87) | S 10min | superpowers-zh P2-2 | 跑 `flutter test` 重新锁定, 改 3 处数字 |
| P2-03 | CHANGELOG 验收 "subagent 已确认" 未跨平台 reproduce | S 5min | superpowers-zh P2-3 | 改 "worktree 验证, 跨平台 reproduce 留 v0.32" |
| P2-04 | spec baseline 数字矛盾 (spec 写 2102/1/127+66/-1 vs 实际 2103/1/126+1/-1) | S 5min | emil P1-F | 重新跑 `flutter test` 锁, 改 spec |
| P2-05 | PrimaryButton:73 doc 注释 `const Text('已完成')` 硬编码中文 | S 1min | superpowers-zh P2-4 | 改 `Text(l10n.commonDone)` |
| P2-06 | R12b global sanity test 改用 AST 而非 regex (避免注释假阳性) | M 1-2h | superpowers-en P3-2 | dart analyzer AST migration |

### 4.2 细节 polish (P3 长期, 不阻塞)
- CheckInButton fontWeight=w700 → w600 跟 Apple Health semibold 一致 (1min)
- CheckInButton 3 hardcode 64/32/20 抽 token (P2-D emil 建议) — 注释充分, 决策合理, 建议保留"故意留 magic" 决策但加 lock-in test
- PressFeedback 不调 Haptics → R109 评估加 `hapticOnTap` enum 参数
- `_StreakCounter` vs `_EntrySpring` 动画模式 (addListener+setState vs AnimatedBuilder) 不一致 → 选一种统一
- AppleListSection:144 `title!.toUpperCase()` 对中文 no-op → 注释显式说明 i18n 限制
- 8 metric icon 用 Material Icons 而非 SF Symbol → SF Symbol 字体集成 1-2d
- 3 种 commit author 不统一 (Mavis / Apple Health Redesign Agent / Mavis (AI Agent)) → 统一 `Mavis <mavis@chroniccare.local>`
- 3 处 `_titleLetterSpacing = 0.6` 重复 (AppleListSection + SectionHeader) → 抽 `AppTokens.sectionHeaderLetterSpacing`
- `StatCard.xl` 注释 "字号 28 跟 default 相同" 跟命名暗示不一致 → 改 `medium` 或加字号
- Android brand color 0xFF34C759 vs M3 派生 0xFF4CAF50 颜色轻微不一致 (设计选择非 bug)
- `values/styles.xml:4` 用旧 `Theme.Light.NoTitleBar` 而非 Android 12+ `Theme.SplashScreen` (Flutter 旧 Theme 仍可上架)

## 5. 顶层架构总结

### 5.1 跟 R108 baseline 对照 (关键 5 变化)
1. **+1.3 评分升 (6.2 → 7.5)** — Apple Health 23 commit 视觉重设表现优秀, 但 5 项上架硬阻塞跨期 100% 残留 (0 闭环)
2. **3 P0 跨期架构债**: R108 P0-001/002/P1-001/P1-003 0 闭环, 反而 R11a 新引入 4 硬编码中文 + 1 `Colors.white` + 1 新漏 IconButton 包装 (emil 验证: "新引入抵消了 token 化改善")
3. **跨视角共识**: spring.dart 死代码 (emil P0-E + superpowers-en P1 + Apple Health P0-3) + 7 处 IconButton (emil) + spec baseline 数字矛盾 (emil + superpowers-zh + superpowers-en) + AGENTS.md 缺 v0.31 章节 (superpowers-zh + superpowers-en + flutter-spec + Apple Health) = **6 大共识级 issue**
4. **0 new P0 引入 native** (GooglePlay + AppStore 共同确认) — Apple Health 23 commit 100% presentation 层, 0 android/ 0 ios/ 0 pubspec 依赖改动, 跨平台兼容
5. **4 token 集中器 + 6 widget 集中器** 100% 落地 (flutter-spec U7.1 ✅), 设计 token 集中化是 R65 后最成熟 "design engineering" 时刻

### 5.2 高内聚低耦合度
- emil: 8.5/10
- flutter-spec: 9/10
- Apple Health: 8/10
- superpowers-zh: 8.5/10
- **加权综合 8.5/10** (跟 R108 持平, 略升 — Apple Health widget 集中化)

### 5.3 4 层架构纯度 (flutter-spec 验证)
- `dart scripts/check_all.dart` 跑通 ✅
- domain 0 flutter / 0 drift / 0 data / 0 presentation ✅
- shared/ 工具被 ≥2 层使用 ✅
- domain `*Entity` ↔ drift `@DataClassName` 一一对应 ✅
- 跨 feature import 0 violation (pre-existing medication → setup_widgets 是 R108 baseline, Apple Health 23 commit 0 引入新跨 feature) ✅

### 5.4 TDD 落地
- superpowers-en: 12/13 改写 commit 跟 test 同步, 67/67 新 test case PASS
- 11 个新 test file + 6 改写 test file, lock-in test 同步
- 私有 widget 间接覆盖完整 (`_EntrySpring` / `_TweenNumber` / `_ChipBadge` × 2)
- **唯一盲点**: `_TweenNumber` 跟 `_StreakCounter` 95% 重复 (P1-12, R109 抽公共 widget)

## 6. R109+ 路线图建议 (优先级排序)

### Phase 1 R109 第 1 周 (1 周) — 闭环 17 P0
- **Day 1-2**: P0-01 ~ P0-07 上架/合规 (3.5h 总和) + P0-11 dart format (5min) + P0-12 设计文档入库 (5min)
- **Day 2-3**: P0-08 Spring 接 _EntrySpring (1-2h) + P0-09 lock-in test 扩 lib/**/*.dart (1h) + P0-10 PageScaffold translucent AppBar (1-2h)
- **Day 4-5**: P0-13/14/15 设计师协同 (fastlane 脚本跑 + 设计师出图), P0-16 域名 ICP 启动 (1-2 月异步)
- **预期**: 0.31.1 hotfix 出, 综合 8.5/10 (R109 闭环后)

### Phase 2 R109 第 2-3 周 (2 周) — 拆 god class + 抽公共 widget
- P1-08/09 setup_page_state 513L + setup_step_medication 614L 拆 controller (3-4d)
- P1-12 tween_number 公共 widget (1-2h)
- P1-01 ~ P1-07 跨期硬编码修 (1-2h 总和)
- P1-13/14/15/16 11 feature 完整改写 (各 1-2d, 选 2-3 个高 ROI)
- P2-01/02/03/04/05 dev doc 同步 (3h 总和)
- **预期**: 综合 9.0/10

### Phase 3 R110+ (2-3 周) — feature-first 重构
- `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package
- 4 个 R108 §六 god class 候选: notification_service 417 / mood_audio_service 311 / app_database 494 / legal_page 460 (跟 medication/setup 拆解合并)
- SF Symbol 字体集成 + brand color 跨平台对齐
- 8 metric icon 跟 SF Symbol 一一对应

### Phase 4 v1.0 (2027-Q1) — 长期
- HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP 真接
- 5 token 集中器转 pub workspace 公共 package

## 7. VERDICT

**v0.31.0 Apple Health 风格重设计 PASS (加权 7.5/10, R108 6.2 → +1.3)**。

**核心矛盾**: 视觉层 9.5/10 优秀 (4 token 集中器 + 6 widget + 5 page 重设 + 0 业务逻辑改动 + 0 跨 feature import + 跨平台 0 影响) — 但上架/合规层 0/10 跨期残留 (5 项硬阻塞 + 7 个新 bug) + 6 大跨视角共识 issue (spring 死代码 / 7 IconButton / spec 数字矛盾 / AGENTS.md 缺 / 设计文档 untracked / god class 反涨)。

**1 周闭环 17 P0 即可到 8.5/10**, R109 god class 专项后可到 9.0/10。

**不建议本批提交 hotfix**: 0.31.1 应专注 §2.1 上架/合规 7 项 (P0-01~07) + P0-11 dart format, 其他 10 P0 留 R109 第 1 周同步跑 (跟 god class 拆解合并, 避免单独 0.31.1 拆 commit 不连续)。
