# AGENTS.md — ChronicCare 项目记忆

> **本文件重建日期**: 2026-08-18 (gdc R128e audit)
> **原始 AGENTS.md 已随 322 份含'修'字文档 commit 删除 (b2d9744f)**, 本文档从 `.opencode/standards/` + `pubspec.yaml` + 当前代码状态重建
> **当前版本**: 1.1.0+185 (pubspec.yaml:6)
> **Flutter / Dart**: >= 3.41.0 / >= 3.6.0 <4.0.0 (pubspec.yaml:8-10)

---

## 一、项目一句话

**慢性照护 (ChronicCare)** — 情绪日记 + 树洞倾诉优先 (mood journal & vent-first self-care app for mental wellness, with medication tracking as support)

1.1.0 round 6d 起改为"情绪优先" (emotion-first refactor)。永久免费定版 (v1.0.0+147), 0 IAP / 0 第三方追踪 / 0 云端。

---

## 二、目录结构 (4 层 + feature-first)

```
chroniccare/ (root, main app)
├── lib/                              # 主 app 源码
│   ├── main.dart                     # 启动入口 (262L, 5 并行任务)
│   ├── main/boot_apps.dart           # 启动期占位 App (R108 P1 god 拆)
│   ├── app.dart                      # AppRoot (MaterialApp.router + builder)
│   ├── core/                         # 跨 feature 共享
│   │   ├── data/        (database + repositories + services + feature_flags + privacy)
│   │   ├── theme/       (5 token facade + spring re-export shim)
│   │   ├── routing/     (go_router 14 + 7 feature AppRoute*.dart)
│   │   ├── shared/      (formatters / json_codec / mood_visual / swallow_error)
│   │   ├── platform/    (notification umbrella + health_kit stub)
│   │   └── l10n/        (domain 层 strings)
│   ├── features/                     # R110-R128 feature-first 重构
│   │   ├── assessment/   (心理评估 + 量表)
│   │   ├── crisis/       (危机热线 + 5 地区 + tel: scheme)
│   │   ├── daily_tracking/ (6 子表: sleep/weight/stress/social_rhythm/treatment/anxiety_agitation)
│   │   ├── medication/   (用药管理 + Apple Health 风格)
│   │   ├── mood/         (情绪日记 · P0)
│   │   └── vent/         (树洞 · P0)
│   ├── domain/                       # 0 Flutter 0 Drift 业务层
│   │   ├── entities/    (25 个 entity)
│   │   ├── logic/       (38 个业务规则)
│   │   ├── repositories/ (10 个 abstract)
│   │   └── usecases/    (用例)
│   ├── presentation/                 # UI 层
│   │   ├── providers/   (Riverpod 3.3.2)
│   │   ├── pages/       (re-export shim → features/*/presentation/pages/)
│   │   ├── widgets/     (35+ 通用组件)
│   │   └── services/    (l10n 适配器 + PDF l10n)
│   └── l10n/                         # flutter_localizations ARB
│       ├── app_zh.arb      (zh, baseLocale)
│       ├── app_en.arb      (en)
│       └── app_zh_Hant.arb (zh_Hant)
├── packages/                         # Pub workspace (Dart 3.6+)
│   ├── chroniccare_core/         (v1.1.0+1, R127 stage3) — .gitkeep only
│   ├── chroniccare_features_mood/ (v1.1.0+1, R127 stage3) — .gitkeep only
│   └── chroniccare_theme/         (v1.1.0+1, R128d) — 6 token 集中器 public
├── ios/                             # iOS Runner (Info.plist + PrivacyInfo + entitlements)
├── android/                         # Android Runner (build.gradle + AndroidManifest)
├── web/                             # Flutter Web 通用适配
├── fastlane/                        # Fastfile + metadata/ (App Store + Google Play)
├── assets/
│   ├── icons/                       # iOS / Android icon assets
│   ├── legal/                       # 4 法律文档 (隐私政策 / 用户协议 / 敏感数据同意 / 医疗免责)
│   └── shaders/ink_*.clip. (ink_sparkle.frag shader)
├── docs/                            # 文档 (含 R128e 重建 12 文件)
│   ├── specs/                       # feature specs
│   ├── superpowers/specs/           # SDD task briefs/reports
│   ├── design/                      # 设计 spec + mockup
│   ├── architecture/                # FEATURE_FIRST_PLAN 等
│   └── audit/                       # 审计报告 (含 R128e 2026-08-17 comprehensive)
├── scripts/                         # 58 个脚本 (含 21 守门员 + 5 fastlane 集成)
├── test/                            # 200+ 测试文件 (380 dart)
└── coverage/ + reports/              # 覆盖率 + 报告
```

---

## 三、技术栈

| 类别 | 依赖 | 版本 |
|---|---|---|
| 状态管理 | flutter_riverpod | ^3.3.2 |
| 路由 | go_router | ^14.6.1 |
| 本地数据库 | drift | ^2.20.3 |
| SQLCipher | sqlcipher_flutter_libs | ^0.6.5 (16KB aligned) |
| PDF 生成 | pdf + printing | ^3.11.1 / / ^5.13.4 |
| 趋势图 | fl_chart | ^0.69.0 |
| 国际化 | flutter_localizations + intl | ^0.20.2 (zh / en / zh_Hant) |
| 加密 | flutter_secure_storage + pointycastle | ^9.2.2 / ^3.9.1 |
| 通知 | flutter_local_notifications + flutter_timezone + timezone + permission_handler | ^17.2.3 / ^3.0.1 / ^0.9.4 / ^11.3.1 |
| 录音 | record + audioplayers | ^5.2.0 / ^6.1.0 |
| 语音识别 | speech_to_text | ^7.0.0 |
| url_launcher | (tel: 危机热线一键拨打) | ^6.3.1 |
| 代码生成 | build_runner + drift_sql | ^2.4.13 / ^2.20.3 |
| flutter_lints | — | ^5.0.0 |

---

## 四、4 层架构 (纯净度守门员 `scripts/check_all.dart`)

```
presentation (UI)  →  domain (业务, 0 Flutter)  ←  data (基础设施)
                        ↑
              core/ umbrella (data/shared/theme/routing/l10n/platform)
```

- **presentation**: `lib/features/<feature>/presentation/pages/` + `lib/presentation/widgets/` + `lib/presentation/providers/`
- **domain**: `lib/domain/entities/` + `lib/domain/logic/` + `lib/domain/repositories/` + `lib/domain/usecases/` (0 Flutter import)
- **data**: `lib/core/data/database/` (Drift + SQLCipher) + `lib/core/data/repositories/` (impl) + `lib/core/data/services/` (37 个 service)
- **core/**: umbrella, 跨 feature 共享 (notification / health_kit / theme / routing / l10n)

依赖方向: presentation → domain ← data, **绝无反向依赖**

---

## 五、21 个守门员 (`scripts/check_*.py` + `scripts/check_*.dart`)

| 守门员 | 行数 | 职责 |
|---|---|---|
| `check_all.dart` | 18KB | 4 层架构 layer purity (跨 feature import) |
| `check_apple_health_claim.py` | 154L (扩 7 规则) | Apple Health / HealthKit 假声明防御 (5.1.3 抽审) |
| `check_cross_feature.py` | 5.3KB | 跨 feature import 检查 |
| `check_arb_keys.py` | 5.3KB | ARB 双向同步 |
| `check_orphan_arb_keys.py` | 4.5KB | 孤立 ARB 键 |
| `check_zh_hant_consistency.py` | 4.7KB | zh-Hant 翻译一致性 |
| `check_drift_namespace.py` | 2.4KB | Drift 表命名空间 |
| `check_datetime_race.py` + `check_datetime_race2.py` | — | DateTime race |
| `check_fullwidth_punctuation.py` | 6.5KB | 全角标点 |
| `check_no_hardcoded_utc.py` | 3.6KB | UTC 硬编码 |
| `check_no_pua.py` | 3.5KB | PUA 字符 |
| `check_widget_dispose.py` | 4.9KB | widget dispose 资源泄漏 |
| `check_legal_consent.py` | 3.9KB | 法律同意 |
| `check_strings_hardcoded.py` | 15KB | 硬编码字符串 |
| `check_changelog.py` | 3.1KB | CHANGELOG 版本 |
| `check_16kb_alignment.py` | 10KB | 16KB page size |
| `check_pii_in_title.py` | 7.2KB | 通知 PII 锁屏 |
| `check_usecase_layer.py` | 9.7KB | usecase 层纯度 |
| `check_review_information_todo.py` | 7.7KB | review info TODO |
| `check_coverage.py` | 12.2KB | 覆盖率阈值 |
| `check_no_network_io.py` | 5.1KB | 0 网络 IO |
| `check_release_no_network.py` | 5.4KB | release 0 网络 |
| `check_encryption_at_rest.py` | 5.4KB | 静态加密 |
| `check_five_vendor_push_ready.py` | 7.0KB | 5 厂商 push 准备 |
| `check_feature_first_migration.py` | 6.6KB | feature 第一迁移 |

CI 入口: `.github/workflows/ci.yml` (175 行, 3 jobs: test / architecture / build)

---

## 六、God Class 候选 (gdc R128e audit 2026-08-18 状态)

| 文件 | 行数 | 风险 | 状态 |
|---|---|---|---|
| `lib/main/boot_apps.dart` | 466L | R108 拆完还超 400 阈值 | 待续拆 |
| `lib/features/mood/presentation/pages/mood_list/mood_detail_page.dart` | 431L | `_content` 265L (audio+cbt+delete+view 4 职责) | R116+ 后续拆 |
| `lib/presentation/pages/home/home_page_state.dart` | 430L | Home State 复杂 | R117+ 后续拆 |
| `lib/domain/logic/day_detail.dart` | 426L | 业务逻辑 (复杂可接受) | 维持 |
| `lib/features/medication/presentation/pages/medication/widgets/edit_medication_dialog.dart` | 417L | 编辑弹窗 | UI 复杂可接受 |
| `lib/features/medication/presentation/pages/medication/refill_manage_page.dart` | 392L | 续方管理 | 接近 400 |
| `lib/features/medication/presentation/pages/medication/medication_calendar_page.dart` | 332L | 日历页 | 接近 400 |
| `lib/features/assessment/presentation/pages/assessment_widgets.dart` | 434L | 量表 widgets | 接近 400 |
| `lib/core/platform/notification/notification_service.dart` | 278L | 通知 facade | R120 已拆 |
| `lib/core/platform/notification/five_vendor_push_service.dart` | 316L | 5 厂商 push 抽象 | R124 加 |

---

## 七、FeatureFlag 状态 (`lib/core/data/feature_flags.dart`)

5 个 flag, 1 个真业务开 + 4 个 prod-false 等真接:

| flag | prod 默认 | 业务 | 触发条件 |
|---|---|---|---|
| `phqGad7I18nEnabled` | false | PHQ-9 / GAD-7 16 题 i18n 开启 | i18n 翻译完整 (R65b 阶段) |
| `bootReceiverEnabled` | false | 设备重启 WorkManager 重排 | WorkManager 完善 (v0.28) |
| `fiveVendorPushEnabled` | false | 5 厂商 push 真接 (米/华/OPP/vivo/魅族) | 5 SDK 全部审核通过 (1-2 月) |
| `healthKitEnabled` | false | HealthKit 真接 (5-6 月后) | entitlement + Info.plist + pub 依赖齐备 |
| `ventAudioEnabled` | **true** | vent audio 录音 (R104 启用) | 已闭环 |

gdc R128e audit (2026-08-18): 加 翻 true 检查清单 (gdc 决策严谨度补强)

---

## 八、上架准备度状态 (gdc R128e audit 2026-08-18)

### Apple App Store
- **代码合规** 9/10 — 5 守门员 (含 Apple Health 7 规则) + PrivacyInfo + Project.pbxproj 全绿
- **元数据 / 视觉资产** 0/10 — 5 P0 硬阻断: iOS Screenshots / Privacy URL / Support URL / review_information 4 字段 / Podfile 占位

### Google Play
- **代码合规** 9/10 — 16KB / targetSdk 36 / AAB / Play App Signing / 权限最小化 全绿
- **元数据** 0/10 — 1 P0 硬阻断: 域名 + ICP (中国上架必备, 7-20 天流程)

### Apple Health 集成
- **视觉重设** 9/10 — 5 token + 6 widget + 11+ feature 完整
- **集成** 0/10 — HealthKit stub (204L), 5-6 月后真接窗口

---

## 九、构建命令

```bash
# 1. flutter pub get
flutter pub get

# 2. 生成 drift 代码 (app_database.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 3. 运行 dev
flutter run

# 4. 跑测试 + 守门员
flutter test
dart scripts/check_all.dart
python scripts/check_apple_health_claim.py
python scripts/check_cross_feature.py --ci
python scripts/check_16kb_alignment.py
# ... 21 守门员 (见 .github/workflows/ci.yml)

# 5. 构建
flutter build apk --debug         # Android Debug
flutter build web --release      # Web Release
flutter build ios --release      # iOS Release (需 macOS + Xcode)
flutter build appbundle          # Android AAB (Google Play 强制)
```

---

## 十、关键决策 (R-number 历史)

| Round | 阶段 | 主要决策 |
|---|---|---|
| R0-R32 | 早期 | 4 层架构 + god class 拆分 + Apple Health 视觉重设 |
| R55-R72 | Sprint 1-3 | i18n + 法律文档 + 危机热线 + 多视角审计启动 |
| R95-R101 | god page 拆 | MoodTrendPage 653L → 4 文件 + 11+ feature 视觉改 |
| R108 | revisit | 13 P0 必修 + 4 god class 拆 + 24 error 清 |
| R110 | feature-first | 5 阶段路线 (daily_tracking / assessment / mood / vent / medication 完整迁移) |
| R114 | Wave A/B/C/D/E | 主页 bug + route transitions + 主页 5 档 mood score + 各种 polish |
| R115 | emotion-first 启动 | 项目定位改"情绪日记 + 树洞倾诉优先" |
| R124 | 5 厂商 push | 5 抽象 + NoOp + 5 占位 impl |
| R126-R128 | R110 feature-first 收官 | 6 feature 完整迁移 + pub workspace + HealthKit stub + 5 token 转 package |
| R129 | hotfix | P0 修真 8 项 |
| R128e | gdc audit | 7 视角多视角审计 + 66 项发现 + 本 AGENTS.md 重建 |

---

## 十一、局限

- ❌ 原始 AGENTS.md (1268L 含 R0-R115 每 round 详细决策) 已随 322 文档删除不可恢复
- ❌ 详细 commit-by-commit history 缺失 (见 `git log`` + `CHANGELOG.md` 重建版)
- ❌ 2 个空 package (`chroniccare_core/` + `chroniccare_features_mood/`) 状态待用户决断 (gdc P0 #3)
- ✅ 本 AGENTS.md 是从 `.opencode/standards/` + `pubspec.yaml` + 当前代码 + `git log` 重建的精简版
- ✅ R128e 后续 commit 增量修改直接 commit (本文件不需要再重写)