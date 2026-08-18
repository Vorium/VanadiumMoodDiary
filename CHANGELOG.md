# ChronicCare (慢病管家) — Changelog

> **当前版本**: 1.1.0+185 (2026-08-18, gdc R128e audit 后)
> **历史**: 从 v0.18 ~ v0.32 ~ v1.0.0+147 (永久免费定版) ~ v1.1.0 (情绪优先重构)
> **格式**: 语义化版本 (semver): MAJOR.MINOR.PATCH+BUILD
> **本 changelog 由 R128e audit (gdc R128e audit 2026-08-18) 重建**, 原始 v0.32 round 48 + v1.0.0+147 等历史 changelog 已随 322 份含'修'字文档 commit 删除 (见 b2d9744f)。

---

## v1.1.0+185 (2026-08-18, R128e audit) — 当前版本

### R128e gdc 多视角审计修复 (本 changelog 配套 release)
- 7 视角深度扫描 (emil-kowalski / superpowers / flutter-audit / gdc / AppStore / Google Play / Apple Health), 输出 66 项发现 (10 P0 + 25 P1 + 25 P2 + 6 P3)
- R93 spec 矛盾修正: 5 vendor flag → 1 聚合 flag, 4 → 3 删除 flag
- 3 prod-false flag 加翻 true 检查清单 (bootReceiver / fiveVendorPush / healthKit)
- Apple Health 守门员 5 → 7 规则 (加 entitlement + pbxproj)
- 14 文件 token 化 (hero fontSize / padding / Colors.white → AppColors / 0.125 → 0.5 turns)
- 文档-代码一致性 gap 修复 (spec.md §6 moodToAppleHealthSyncEnabled 删除, user_agreement.md TODO → PENDING_LAWYER_REVIEW)

### R128d step 1-3 (R110 feature-first 阶段 5) — 5 token 集中器转 pub workspace
- `packages/chroniccare_theme/` (v1.1.0+1) — AppColors / AppTypography / AppSpacing / AppMotion / Spring 6 集中器 public
- AGENTS.md 加 R128d 章节 + R128d 收官

### R128c — HealthKit stub 骨架 + FeatureFlags.healthKitEnabled
- `lib/core/platform/health_kit/health_kit_service.dart` 204 行 — abstract + NoOp + factory + facade 4 段式
- `_prodHealthKitEnabled = false` 默认, 5-6 月后真接窗口
- 守门员加 3 规则 (HealthAndFitness PrivacyInfo / import health_kit / NSHealthShareUsageDescription)

### R128b — crisis 5/5 收官 迁 features/crisis/

### R128a — notification 体系抽 core/platform/notification/ umbrella

### R127 stage3 — pub workspace 骨架 (3 package: core + features_mood + theme)
- 2 个 package (core + features_mood) 仍为空 (.gitkeep), R128e audit P0 待决

### R126 — feature-first 阶段 2 step 3-7
- daily_tracking 6/6 子表 100% 迁移 → features/daily_tracking/
- assessment 完整迁移 → features/assessment/
- mood 完整迁移 → features/mood/
- vent 完整迁移 → features/vent/
- medication 完整迁移 → features/medication/ (R126 续 step 7 收官)

### R110 — feature-first 重构 5 阶段路线
- 阶段 1: daily_tracking 子树隔离
- 阶段 2: 6 feature 完整迁移 (assessment / mood / vent / medication / daily_tracking / crisis)
- 阶段 3: pub workspace 骨架
- 阶段 4: notification / crisis / HealthKit 抽象
- 阶段 5: theme workspace 转公共 package

---

## v1.1.0+115 ~ +147 (2026-08-12 ~ 14, emotion-first refactor)

### emotion-first refactor 1.1.0 round 4b (R115 + R127 续)
- 项目定位: 慢病管理 → **情绪日记 + 树洞倾诉优先**
- 删除失联通知 / 紧急联系人 / SMS / Email Service 4 外联业务
- 主页 4 tab: Mood / Vent / Trend / Settings (R110 round 3)
- pubspec.yaml 描述改双语
- 数据库迁移: deleteTable('contacts') (v0.23 → v1.1.0)

### R114 Wave A/B/C/D/E — 体验细节
- Wave A: 主页 bug-batch
- Wave B: route transitions (主导航 fade 250ms / 子页 slide-right / 全屏 slide-up 400ms)
- Wave C: 树洞体验
- Wave D: 主页 5 档 mood score 按钮 (moodScoreButtonSize 72pt)
- Wave E: 各种 polish

---

## v1.0.0+147 (2026-08-14, 永久免费定版)

### v1.0.0 R70-R95 (上架冲刺收尾)
- iOS App Store + Google Play 双 store 上架准备度收尾
- Apple Health visual redesign (R31) 5 阶段完成
- 11+ feature 视觉重设 (主页 / 用药 / 评估 / 情绪 / 趋势 / 树洞 / 设置 / 提醒 / 续方 / 危机 / 启动)
- 16KB page size 配置 (sqlcipher_flutter_libs 0.6.5+, Google Play 2025-11 强制对齐)
- PrivacyInfo.xcprivacy 完整 (5 NSPrivacyAccessedAPITypes + 2 NSPrivacyCollectedDataTypes)
- 中文 commit message 规范 (CHINESE_COMMIT_GUIDE.md)

### v1.0.0+147 永久免费定版 commit
- 删除所有 IAP 代码 / 依赖 / 文案
- Fastfile precheck_include_in_app_purchases: false
- assets/legal/privacy_policy.md "永久免费定版" 段
- 客服话术 / marketing 描述 同步

### v0.32 round 108 (R108 revisit) — 13 P0 + 4 god class 拆 + 24 error 清
- R108 P0 必修 13 项 (含 release-mode error 守卫 + DB key 失配探测)
- P1 4 god class 拆 (medication / mood / assessment / home)
- 24 error 全清 (8 P0 引入 + 17 in-progress 残留)

### v0.32 R112 round 8 — iOS App Store 抽审防御
- 删 NSPrivacyCollectedDataTypeHealthAndFitness
- 4 description 5 病名 R72 修正
- 8 raw IconButton 加 PressFeedback 集中
- review_information 4 TODO placeholder

### v0.32 R114 — DB 可读性探测
- B1-8: probeDatabaseReadable 检测 key-DB 失配
- 引导重试 / 重置

### v0.31 R31 — Apple Health 视觉重设 (5 阶段)
- Phase 1: 5 token 集中器 (colors/typography/spacing/motion/spring)
- Phase 2: 6 widget 集中器 (AppleHealthTile / AppleListSection / SectionHeader / PrimaryButton / CheckInButton / StatCard)
- Phase 3: 11+ feature 重设
- Phase 4: 9 follow-up (PageScaffold translucent / Apple cubic-bezier / MotionScheme / reduce-motion / 3 transition / 入场动画 / Page transitions / SnackBar duration / iOS ALL CAPS)
- Phase 5: 5 守门员 lock-in

### v0.30 round 95-R101 — God Page 拆分 + 子 spec 闭环
- R95: MoodTrendPage 653L → 4 文件
- R95-R101: assessment / medication / daily_tracking / vent 7 sub-spec 闭环
- R101: Apple Health 视觉 audit, R128 AH-16 tintedMetricSoft 0 caller 删

### v0.30 R99-R108 — R110 feature-first 重构前期
- 4 层架构纯净度守门员 (check_all.dart 18KB)
- 21 守门员 (cross-feature / ARB / zh-Hant / drift / datetime / fullwidth / UTC / PUA / widget dispose / legal consent / strings / changelog / 16KB / PII / apple-health claim / usecase / review-info / coverage)

### v0.27 R65-R69 — R65b i18n + R67 P0 集中修复 + R69 emotion-first 启动
- PHQ-9 / GAD-7 16 题 i18n 起步
- R67 法律文档删失联/联系人 + 5 ARB 文案 ×3 语
- R69 round 6d: 项目描述改双语, 启动 emotion-first 定位

### v0.18 ~ v0.27 — 早-中期迭代
- v0.18 round 14: i18n 集中器 + EmptyState 抽出
- v0.22 round 29-36: emil 系列 polish (P0-4 / P1-3 / P2-7 等)
- v0.23 round 40: chip icon-text spacing 集中器
- v0.24 round 43-48: emil P1-01 H-01 + chip padding + text length warning
- v0.25 round 50: textStyleScoreLg/Xl/Xxl (后 R57 删 0 caller)
- v0.25 round 56: shimmer pause + chart height token
- v0.27 round 60: medication calendar label 列宽
- v0.27 round 65: app_tokens 644L god 拆 4 文件 (typography / spacing / motion / tokens)

---

## 上版本对照表

| pubspec version | commit 阶段 | 主要变化 |
|---|---|---|
| 1.1.0+185 | R128e audit | gdc 多视角审计修复 |
| 1.1.0+147 | R129 hotfix | P0 修真 8 项 |
| 1.1.0+115~+147 | R115-R127 | emotion-first refactor |
| 1.0.0+147 | R70-R95 + 永久免费定版 | 上架冲刺收尾 |
| 0.32.0+142 | R111 hotfix round 8 | R110 P0#13 紧急修 |
| 0.32.0+140 | R110 | R108 revisit 闭环 |
| 0.32.0+129 | R110 round 3 | 主页 4 tab 简化 |
| 0.31.1+111 | R32 hotfix round 4 | 11 P0 全闭环 |
| 0.31.1+108 | R32 bug-batch | 11 P0 修 |
| 0.31.0+107 | R31 | Apple Health 视觉重设 (5 阶段) |
| 0.30.0+85 | R95 | 11+ feature 视觉改 |
| 0.27.0+64 | R67 | 法律文档删失联 + i18n |
| 0.27.0+33 | R32 | 11 P0 闭环 |
| 0.18.x | R0-R32 | 早期迭代 |

---

## 局限

- ❌ 原始 5245L CHANGELOG (含每 round P0-P3 详细 changelog) 已随 322 文档删除不可恢复
- ❌ R0-R110 共 100+ round 的逐次 changelog 缺失
- ✅ 本 changelog 是从 git log + pubspec.yaml + R-number 注释重建的关键里程碑版本
- ✅ v1.1.0+185 当前最新是 R128e audit, 后续 commit 增量修改直接 commit