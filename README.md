# MoodDiary 心情日记 (ChronicCare) — Flutter

> **项目版本**: 1.1.0+185 (`pubspec.yaml:6`)
> **Flutter / Dart**: `>=3.41.0` / `>=3.6.0 <4.0.0` (`pubspec.yaml:8-10`)
> **平台**: Android + iOS + Web
> **架构**: 4 层 + Feature-first 渐进重构 (R110/R125/R126/R127/R128)

---

## 一、项目定位

**情绪日记 + 树洞倾诉优先** — MoodDiary 心情日记 is a mood journal &
vent-first self-care app for emotional well-being.

1.1.0 round 6d 起改为"情绪优先" (emotion-first)。**永久完全免费** (v1.0.0+147 定版), 0 内购 / 0 第三方追踪 / 0 云端。

R128e (2026-08-18) 医疗声称降级: 从"慢病管理"定位改为个人情绪记录工具,
删诊断解读 / 危机弹窗 / 临床严重度标签, iOS 类别 healthcare-fitness → lifestyle。

---

## 二、核心功能

### 主线 (P0 · 情绪优先)

- **情绪日记 (mood)** — 4 维度评分 (mood/energy/sleep/anxiety) + CBT 思维记录 (3/5/7 栏 Beck 标准) + 影响因素 + 语音录入 + STT
- **树洞倾诉 (vent)** — 文字 + 录音 + 标签
- **趋势 (trend)** — 跨 mood/vent/daily_tracking 趋势图
- **设置 (settings)**

### 辅助 (P1)

- **用药管理 (medication)** — 3 步向导添加、4 段时间窗、Apple Health 风格页面
- **日常追踪 (daily_tracking)** — 6 子模块 (sleep/weight/stress/social_rhythm/treatment/anxiety_agitation)
- **心理评估 (assessment)** — 10 量表 (PHQ-9/GAD-7/ISI/PSS/WHODAS/DSM-5 Level2 × 4/ASRM)
- **危机热线 (crisis)** — 5 地区 + 1 全国 800-810-1117 一键拨打 (url_launcher tel: scheme)
- **烦恼闭环 (worry)** — 进行中 + 忆往昔 + 情绪日记联动
- **心理技巧 (tips)** — 知识库

### 工具

- **CBT 思维记录 PDF 导出** (`pdf` + `printing`)
- **用药报告 PDF** (`dataExport`)
- **数据导入导出** (v6 多版本格式)
- **通知** (medication refill / 每日提醒 / 用药 / 评估)
- **SQLCipher 加密** (`flutter_secure_storage` + `sqlcipher_flutter_libs` 0.6.5+ 16KB-aligned)

---

## 三、技术栈

| 类别 | 依赖 | 版本 |
|---|---|---|
| 状态管理 | flutter_riverpod | ^3.3.2 |
| 路由 | go_router | ^14.6.1 |
| 本地数据库 | drift | ^2.20.3 |
| SQLCipher | sqlcipher_flutter_libs | ^0.6.5 (16KB aligned) |
| PDF 生成 | pdf + printing | ^3.11.1 / ^5.13.4 |
| 趋势图 | fl_chart | ^0.69.0 |
| 国际化 | flutter_localizations + intl | ^0.20.2 (zh / en / zh_Hant) |
| 加密 | flutter_secure_storage + pointycastle | ^9.2.2 / ^3.9.1 |
| 通知 | flutter_local_notifications + flutter_timezone | ^17.2.3 / ^3.0.1 |
| 录音 | record + audioplayers | ^5.2.0 / ^6.1.0 |
| 语音识别 | speech_to_text | ^7.0.0 |
| url_launcher | — | ^6.3.1 (tel: 危机热线一键拨打) |
| 代码生成 | build_runner + drift_dev | ^2.4.13 / ^2.20.3 |

---

## 四、Pub workspace 结构

```
chroniccare/ (root, main app)
├── packages/chroniccare_core/         (v1.1.0+1) — 跨 feature 共享
├── packages/chroniccare_features_mood/ (v1.1.0+1) — 情绪日记 feature (R127 stage3)
└── packages/chroniccare_theme/         (v1.1.0+1) — 6 设计 token 集中器 (R128d)
```

---

## 五、4 层架构 + Feature-first 渐进重构

```
lib/
├── main.dart                              # 启动入口
├── main/boot_apps.dart                   # 启动期占位 App (R108 P1)
├── app.dart                              # AppRoot (ConsumerStatefulWidget)
├── core/                                 # 跨 feature 共享
│   ├── data/        (database / repositories / services / utils / privacy)
│   ├── theme/       (5 token 集中器 facade + spring re-export shim)
│   ├── routing/     (go_router 14 + 7 feature AppRoute*.dart)
│   ├── shared/      (formatters / json_codec / mood_visual / swallow_error)
│   ├── platform/    (notification + health_kit stub)
│   └── l10n/        (domain 层 strings)
├── features/                             # R110-R128 feature-first 重构
│   ├── assessment/   (心理评估 + 量表)
│   ├── crisis/       (危机热线)
│   ├── daily_tracking/ (6 子表)
│   ├── medication/   (用药管理)
│   ├── mood/         (情绪日记 · P0)
│   └── vent/         (树洞 · P0)
├── domain/                                # 0 Flutter 0 Drift 业务层
│   ├── entities/    (25 个 entity)
│   ├── logic/       (38 个业务规则)
│   ├── repositories/ (10 个 abstract)
│   └── usecases/    (用例)
├── presentation/                          # UI 层
│   ├── providers/   (Riverpod 3.3.2)
│   ├── pages/       (re-export shim → features/*/presentation/pages/)
│   ├── widgets/     (35+ 通用组件)
│   └── services/    (l10n 适配器)
└── l10n/                                  # flutter_localizations ARB
    ├── app_zh.arb      (zh, baseLocale)
    ├── app_en.arb      (en)
    └── app_zh_Hant.arb (zh_Hant)
```

---

## 六、快速开始

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
```

---

## 七、构建命令

```bash
# Debug APK
flutter build apk --debug

# Release Web
flutter build web --release

# iOS (需要 macOS + Xcode)
flutter build ios --release
```

---

## 八、目录结构

(精简 — 见五 4 层架构)

---

## 九、参考

- 设计 spec: `docs/design/2026-08-10-apple-health-redesign/spec.md` (Apple Health 视觉风格)
- 评估设计: `docs/specs/mood-module-adjustment-apple-health.md`
- 用药页重设: `docs/specs/medication-page-redesign.md`
- 评估中心: `docs/superpowers/specs/2026-08-05-assessment-center-design.md`
- CBT PDF 导出: `docs/superpowers/specs/2026-08-05-cbt-pdf-export-design.md`
- 日常追踪: `docs/superpowers/specs/2026-08-05-daily-tracking-design.md`
- R92 审计: `docs/superpowers/specs/2026-08-06-audit-fixes-r92-design.md`
- R93 审计: `docs/superpowers/specs/2026-08-06-audit-fixes-r93-design.md`
- god page 拆分: `docs/superpowers/specs/2026-08-06-r95-godpage-section-design.md`
- 情绪优先重构: `docs/superpowers/specs/2026-08-15-emotion-first-refactor-design.md`
- 架构计划: `docs/architecture/FEATURE_FIRST_PLAN.md` (R110 + R125)
- 守门员: `scripts/` (21 个 check_*)
- CI: `.github/workflows/ci.yml`