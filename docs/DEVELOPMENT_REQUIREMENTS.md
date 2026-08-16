# 开发需求文档 (v2.0, R117 综合审视后)

**Date**: 2026-08-17
**Source**: [docs/audit/2026-08-17-comprehensive/00-FINAL-CONSOLIDATION.md](audit/2026-08-17-comprehensive/00-FINAL-CONSOLIDATION.md)
**Baseline**: 1.1.0+154 (R115 + R116 累计), 2515 tests pass, 27/27 现有 gatekeepers + 5/5 上架新 gatekeepers (资源到位即跑), 1340 ARB keys
**Status**: 加权综合 **7.0/10** (R31 6.5 → +0.5)

---

## 1. 项目核心定位

**emotion-first 精神心理自我关怀 App** (1.1.0 round 4b 后定版):
- **主**: vent (树洞) + mood (情绪日记) — 视觉/交互/路径优先
- **辅**: medication + assessment — 弱化 (2x2 tile → "更多" entry, R115)
- **禁**: SMS / Email / Contacts / IAP / SafetyWatch / 失联通知 (1.1.0 round 4b 全删)
- **零外联**: lib/ 0 网络 import, release 0 域名, 6 Android + 4 iOS 严格白名单

---

## 2. 架构硬约束 (4 层 + 5 umbrella, AGENTS.md 必读)

```
lib/
├── core/                # 基础设施 umbrella (data/shared/theme/routing/l10n)
├── domain/              # 0 Flutter 0 Drift
├── presentation/        # UI 层
└── l10n/                # presentation 层 flutter_localizations
```

**架构守门员** (`dart scripts/check_all.dart`):
- domain/shared 0 flutter / 0 drift / 0 data / 0 presentation
- data 不依赖 presentation
- shared/ 每个文件至少被 2 层用
- domain *Entity ↔ drift @DataClassName 1:1
- 违规 → exit 1, CI fail

**4 FeatureFlag 编译期锁定** (R93 阶段 2 + round 4b 收):
1. `ventAudioEnabled=true` (R104 翻 true)
2. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月)
3. `phqGad7I18nEnabled=false` (等法务 + 临床)
4. `bootReceiverEnabled=false` (等 WorkManager 完善)

---

## 3. 32 守门员 (CI 必跑, R117 新增 5 上架)

26 Python + 1 Dart = 27 现有守门员 (R31 R108 R115 R117 累计) + 5 上架新守门员 (R117 综合审视 P0-1~P0-5):

| 类别 | 守门员 | 状态 |
|---|---|---|
| 架构 | `check_all.dart` (4 层 + 跨 feature import) | ✓ |
| 架构 | `check_cross_feature.py` | ✓ |
| 架构 | `check_drift_namespace.py` | ✓ |
| 架构 | `check_widget_dispose.py` | ✓ |
| 架构 | `check_usecase_layer.py` (R109) | ✓ |
| i18n | `check_arb_keys.py` (3 语同步) | ✓ |
| i18n | `check_orphan_arb_keys.py` (R56e) | ✓ |
| i18n | `check_zh_hant_consistency.py` (R57) | ✓ |
| i18n | `check_strings_hardcoded.py` (R57 + R110 inline) | ✓ |
| i18n | `check_fullwidth_punctuation.py` (warn-only) | ✓ |
| 隐私 | `check_no_pua.py` | ✓ |
| 隐私 | `check_no_hardcoded_utc.py` | ✓ |
| 隐私 | `check_pii_in_assets.py` (R115) | ✓ |
| 隐私 | `check_pii_in_title.py` (R32) | ✓ |
| 隐私 | `check_encryption_at_rest.py` (R115) | ✓ |
| 隐私 | `check_no_network_io.py` (R115) | ✓ |
| 隐私 | `check_release_no_network.py` (R115) | ✓ |
| 隐私 | `check_permissions_whitelist.py` (R115) | ✓ |
| 隐私 | `check_legal_consent.py` (R57, 1.1.0 round 4b 删 §13) | ✓ |
| 上架 | `check_apple_health_claim.py` (R31) | ✓ |
| 上架 | `check_review_information_todo.py` (R111) | ✓ |
| 上架 | `check_appstore_screenshots.py` (R117 P0-1, 资源到位即跑) | ⏳ |
| 上架 | `check_ios_launchimage.py` (R117 P0-2, 资源到位即跑) | ⏳ |
| 上架 | `check_appicon_size.py` (R117 P0-5, 资源到位即跑) | ⏳ |
| 上架 | `check_domain_icp.py` (R117 P0-4, 域名 ICP 到位即跑) | ⏳ |
| 上架 | `check_appstore_metadata.py` (R117 P0-5 配套, review_information / notes / description) | ⏳ |
| 测试 | `check_datetime_race.py` (R19B) | ✓ |
| 测试 | `check_datetime_race2.py` (R19B) | ✓ |
| 测试 | `check_changelog.py` | ✓ |
| 测试 | `check_coverage.py` (R95, 18 gatekeeper 阈值) | ✓ |
| 工具链 | `check_16kb_alignment.py` (R77) | ✓ |
| 视觉 | `check_home_quick_actions.py` (R115) | ✓ |

> 每次 `git commit` 前必跑 27 现有守门员 (5 上架脚本等资源到位才跑, 当前 expected fail)

---

## 4. P0/P1/P2/P3 修复需求清单

### 🔴 P0 (7 项) — 上架硬阻塞, 全部外部依赖

| # | 内容 | 资源 | 预计 | 状态 |
|---|---|---|---|---|
| P0-1 | iOS 截图 0 张 (6.7"/6.1"/5.5" 3 套 × 5 张) | 设计师 | - | 阻塞 |
| P0-2 | iOS LaunchImage 68B (缺多尺寸) | 设计师 | - | 阻塞 |
| P0-3 | Android 截图 67B + feature_graphic 67B (缺分辨率) | 设计师 | - | 阻塞 |
| P0-4 | chroniccare.app 域名 + 4 邮箱 ICP | 域名商 | 7-20d | 阻塞 |
| P0-5 | AppIcon 1024×1024 ≥ 200KB | 设计师 | - | 阻塞 |
| P0-6 | 5 厂商 push SDK (米/华/OPP/vivo/魅族) | 5 厂商 | 1-2 月 | 阻塞 |
| P0-7 | 阿里云 SMS | 阿里云 | 1-2 月 | 阻塞 |

> **5 上架脚本就绪**: 等 P0-1~P0-5 资源到位, 跑 `scripts/check_appstore_screenshots.py` / `check_ios_launchimage.py` / `check_appicon_size.py` / `check_domain_icp.py` / `check_appstore_metadata.py`

### 🟠 P1 (6 项) — 架构 + 续拆 (R117 R1-R2)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P1-1 | `app_database.dart` 564L 拆 4 (tables/migrations/DAOs/connection) | Medium 4h | R117 R1 |
| P1-2 | `notification_service.dart` 417L 拆 4 facade | Medium 4h | R117 R1 |
| P1-3 | `setup_page_state.dart` 513L 拆 4 步 | Medium 3h | R117 R2 |
| P1-4 | `spring.dart` 145L 0 caller, 接 `_EntrySpring` | Small 1.5h | R117 R1 |
| P1-5 | 5.1.3 抽审流程 (PS-12 / AS-12 / AH-8) | Medium 4h | R117 R2 |
| P1-6 | iOS 16KB 真机验证 | Small 1h | R117 R2 (上架前 1 周) |

### 🟡 P2 (9 项) — 单元 test + EN 摘要 + 半成品 (R117 R1-R2)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P2-1 | `medication_slot_entry_row.dart` widget test | Small 1h | R117 R1 |
| P2-2 | `feature_flags.dart` 4 个 `_currentXxx` 单元 test | Trivial 0.5h | R117 R1 |
| P2-3 | `encryption_service.dart` smoke test | Small 1h | R117 R1 |
| P2-4 | `docs/PRIVACY_HARDENING.md` EN 版 | Small 1.5h | R117 R2 |
| P2-5 | `docs/design/.../spec.md` 22KB EN 摘要 | Small 2h | R117 R2 |
| P2-6 | `scale_registry.dart` hybrid 决策 | Small 1h | R117 R2 |
| P2-7 | `static_scale_translations.dart` 785L 拆 12 子文件 | Medium 3h | R117 R2 |
| P2-8 | `vent_list_page.dart` 684L 拆 3 | Medium 3h | R117 R2 |
| P2-9 | AppleHealthTile 视觉 vs 数据 gap 加 tooltip | Small 1h | R117 R2 |

### 🟢 P3 (8 项) — 细节优化 + 长期 (R117 R3+)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P3-1 | `HomePageState` 简化 ConsumerWidget | Trivial 0.5h | R117 R3 |
| P3-2 | `loading_skeleton.dart` 3 variant enum 统一 | Trivial 0.5h | R117 R3 |
| P3-3 | vent 录音态 spring 进场 | Small 1h | R117 R3 |
| P3-4 | dark mode 主色对齐 iOS | Small 2h | R117 R3 |
| P3-5 | `audio_lifecycle.dart` 659L 拆 4 | Medium 4h | R117 R3+ |
| P3-6 | `assessment_center_page.dart` 12 量表加趋势图 | Medium 3h | R117 R3+ |
| P3-7 | `app_theme.dart` 1 TODO 主题细节 | Trivial 0.5h | R117 R3 |
| P3-8 | `AGENTS.md` / `CHANGELOG.md` EN 摘要 | Trivial 0.5h | R117 R3 |

---

## 5. 路线图 (R117 → v1.0)

| 阶段 | 时间 | 目标 | 评分 | 跨期 |
|---|---|---|---|---|
| **R117 R1** | 本周 (1 周) | P1-1~P1-4 + P2-1~P2-3 (god class 续拆 + spring + 单元 test) | 7.5/10 | - |
| **R117 R2** | 1-2 周 | P1-5~P1-6 + P2-4~P2-9 (5.1.3 抽审 + EN 摘要 + 2 半成品) | 8.0/10 | - |
| **R117 R3+** | 3-4 周 | P3-1~P3-8 (细节优化) | 8.5/10 | - |
| **R118** | 1-2 月 | 等 7 P0 外部资源 + 5 god class 续拆 | 8.5/10 | 设计师资产 + 域名 ICP |
| **R119** | 2-3 月 | R110 feature-first 重构 + pub workspace 3 package | 9.0/10 | 内部 |
| **v1.0** | 2027-Q1 | HealthKit + 鸿蒙 + 5 厂商 push + AliyunSms + IAP + 5 token 转 pub workspace | 9.5/10 | 全部外部 |

---

## 6. 已知坑 (从 AGENTS.md 累计)

### R31 R108 R115 闭环
- ❌ raw IconButton (7 处) → PressFeedbackIconButton
- ❌ hardcoded 中文 → ARB key
- ❌ 隐式排序 → 显式 sort
- ❌ 跨 midnight race → AppRoot midnight timer
- ❌ DateTime.now() 多次调用 → 函数入口固化
- ❌ Stream subscription leak → dispose() 取消
- ❌ BuildContext 跨 async gap → this.context
- ❌ schemaVersion 漏 migration → 守门员
- ❌ Material 3 ink_sparkle shader → 复制到 assets/shaders/

### R117 待清
- ⚠️ `spring.dart` 0 caller (P1-4)
- ⚠️ 6 god class 续拆 (P1-1~P1-3, P2-7, P2-8, P3-5)
- ⚠️ 4 半成品 TODO (P2-3, P2-6, P3-6, P3-7)
- ⚠️ EN 摘要 4 文档 (P2-4, P2-5, P3-8)
- ⚠️ 7 P0 跨期残留 (等外部)

---

## 7. 4 个跨期残留 FeatureFlag 详细

| Flag | 当前 | 翻 true 条件 | 阻塞 | 优先级 |
|---|---|---|---|---|
| `ventAudioEnabled` | **true** | R104 启用 | - | - |
| `fiveVendorPushEnabled` | **false** | 5 厂商 push SDK 接入 | 1-2 月 (P0-6) | P1 |
| `phqGad7I18nEnabled` | **false** | PHQ-9/GAD-7 16 题 i18n 走完 ARB | 法务 + 临床 | P2 |
| `bootReceiverEnabled` | **false** | WorkManager 完善 (R55 阶段) | R55 | P3 |

---

## 8. 文档索引 (按类型)

| 类型 | 文档 | 备注 |
|---|---|---|
| 入口 | `AGENTS.md` (32KB) | 项目必读, 4 层架构 + 21 守门员 + 已知坑 |
| 路线图 | `docs/VERSION_1.0_PLAN.md` (1879L) | v0.30 R95+ 阶段 1+2+3+4 实施后路线图 |
| **本文件** | `docs/DEVELOPMENT_REQUIREMENTS.md` | **R117 综合审视后需求文档** |
| 隐私 | `docs/PRIVACY_HARDENING.md` (R115) | 5 守门员 + 隐私硬化落地证据 |
| 设计 | `docs/design/2026-08-10-apple-health-redesign/spec.md` (22KB) | iOS 17/18 视觉语言 spec |
| 决策 | `docs/decisions/v0.{17,22,24,30}_*.md` (5 文件) | 架构决策记录 (ADR) |
| 评估 | `docs/evaluations/*_r79.md` (2 文件) | god class 评估 |
| 上架 | `docs/PLAYSTORE_SIGNING_GUIDE.md` (R67) | Play App Signing 5 步指南 |
| 上架 | `docs/SUBMISSION_INFO.md` (R67) | 上架元数据 |
| 上架 | `docs/STOREFRONT_RELEASE_SOP.md` (R67) | 上架 SOP |
| 部署 | `docs/DEPLOYMENT.md` (R67) | 部署指南 |
| 法务 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent,medical_disclaimer}.md` | 4 法务文档 |
| 综合审视 | `docs/audit/2026-08-17-comprehensive/` (12 文件) | **R117 11 视角综合审视** |

---

## 9. CI/CD 必跑命令

```bash
flutter analyze                   # 0 error / 0 warning (info-level 历史 require_trailing_commas OK)
flutter test                      # 2515 pass / 0 fail / 1 skip
flutter test --coverage           # 必带, coverage 守门员
for s in scripts/check_*.py; do python "$s"; done   # 31 守门员 (26 现有 + 5 上架新)
dart scripts/check_all.dart       # 4 层架构守门员 (1 个)
flutter build apk --release       # Android release build (R117 round 5 适配 3.47)
```

---

## 10. 跨期遗留 (1.1.0 round 4b 删除业务)

> 这些业务 1.1.0 round 4b 已全删, 不再实现:
- ❌ 紧急联系人 (含 SMS / 失联通知 / 5 厂商 push)
- ❌ 阿里云 SMS
- ❌ EmailService (SendGrid)
- ❌ 失联检测 + 关爱引擎 (CareEngine)
- ❌ IAP (内购, 永久免费)
- ❌ SafetyWatchService
- ❌ WorkManager boot receiver (待 R55 阶段)
- ❌ PHQ-9 / GAD-7 16 题 i18n (待法务 + 临床审核)

---

**Maintainer**: Mavis (mavis agent)
**Last Updated**: 2026-08-17 (R117 综合审视后)
**Next Review**: R117 R1 完成后 (本周内)
