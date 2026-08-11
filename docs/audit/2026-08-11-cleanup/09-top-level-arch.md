# 顶层架构审视报告 · 2026-08-11 (R109)

## 元信息
- 跑时间: 2026-08-11
- baseline: master `20670f3` v0.31.1+107
- 上游参考: [R108 整合](docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md) (8.4/10) + [8-11 整合 §5](docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md) (8.5/10) + [c 阶段 10 条架构债](docs/audit/2026-08-11-cleanup/08-line-by-line.md) (D-01~D-10)
- 评估视角: 高内聚低耦合 / 4 层架构纯度 / god class / 跨 feature 边界 / 跨平台兼容
- **高内聚低耦合度: 8.5/10 (持平 R108 8.4 + 8-11 8.5)** — 5 token 集中器 + 6 widget 集中器 + 4 层架构 1:1 落地, 但 13 god class 候选 + 0 个 R110 feature-first 落地

## 1. 当前架构概览

### 1.1 5 层 + 共享 umbrella (跟 AGENTS.md 对齐)
```
lib/
├── main.dart                 # 入口 (R108 488→276L)
├── app.dart                  # App 根 + ProviderScope
├── core/                     # 基础设施 umbrella
│   ├── data/                 # database / repositories / services / utils
│   ├── shared/               # 跨层共享 (formatters / json_codec / mood_visual / domain_value)
│   ├── theme/                # AppTokens + M3 + spring.dart (Apple Health 新增 145L 死代码)
│   ├── routing/              # go_router
│   └── l10n/                 # domain 层 strings
├── l10n/                     # presentation 层 flutter_localizations
├── domain/                   # 0 Flutter 0 Drift 业务层
└── presentation/             # UI 层
    ├── providers/            # Riverpod (3 文件拆分)
    ├── pages/                # 1 个页面 = 1 个目录 (8 个 feature)
    └── widgets/              # 通用 + animations/
```

### 1.2 4 层架构纯度验证 (8-11 + R108 共识)
- `dart scripts/check_all.dart` 跑通 ✅
- domain 0 flutter / 0 drift / 0 data / 0 presentation ✅
- shared/ 工具被 ≥2 层使用 ✅
- domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应 ✅
- 跨 feature import 0 violation (pre-existing medication → setup_widgets 是 R108 baseline, R31 0 新引入) ✅

### 1.3 启动顺序
`main.dart` (R108 减重 488→276L) → `app.dart` (ProviderScope) → 路由 `app_router.dart` (go_router 14.6) → 主页 `home_page_state.dart` (R108 拆 3 controller: deep_link 10.5KB / care_engine 8.3KB / celebration 4.2KB)

## 2. 顶层架构评价

### 2.1 优点 (跟 8-11 §5 + R108 §顶层架构 对照)
1. **4 层架构 1:1 落地** — domain/data/presentation/shared 边界清晰, `check_all.dart` 守门员 0 违规
2. **5 token 集中器** — app_colors / app_typography / app_spacing / app_motion / app_tokens facade, 跟 widget 内零硬编码 `Color(0x` (flutter-spec 验证)
3. **6 widget 集中器** — PrimaryButton / CheckInButton / StatCard / AppleHealthTile / AppleListSection / SectionHeader, R31 23 commit 100% 走集中器
4. **iCloud Backup 4 路径排除** — R108 SkipBackup 集中器 + iOS MethodChannel 跨期 0 引入
5. **R108 god class 拆 4/6 大完成** — main.dart (-43%) / home_page_state (-14%) / vent_compose (-10%) / daily_tracking 7 widget 抽公共 helper
6. **跨平台 0 退步** — Apple Health 23 commit 100% UI 主题层, 0 android/ 0 ios/ 0 pubspec 依赖 0 native 改动 (GooglePlay 报告验证)
7. **TDD 实践度 12/13** — R31 改写 commit 跟 test 同步, lock-in test 守门员

### 2.2 缺点 (跟 R108 + 8-11 + c 阶段 共识)
1. **13 god class 候选 (跨期累计去重)** — 见 §3, R108 拆 4/6 仍剩 11 个候选, R31 新增 setup_page_state 513L 反涨 +7
2. **presentation 集中 vs domain/data 分散** — R31 23 commit 100% 在 `lib/presentation/widgets/`, 业务层 0 改动 → token facade 370L 转发 80+ 字段, emil "good defaults matter more than options" 警告 token 体系饱和
3. **半成品 (P0)**:
   - `lib/core/theme/spring.dart` 145 行 0 caller 死代码 (3 视角共识: emil P0-E + superpowers-en P1 + Apple Health P0-3)
   - `curveAppleSheet` / `curveAppleDrawer` 2 个 Apple cubic-bezier 0 调用
   - `lib/presentation/widgets/page_scaffold.dart` 未改, AppBar 仍是默认 M3 不透明, spec §4.9 translucent AppBar 落地 0
4. **跨 feature import pre-existing** — `medication/7 个文件 → setup_widgets.dart` 是 R108 baseline, R31 0 新引入但 0 修复
5. **PII 防护 4 处缺** — 5 个 DarwinNotificationDetails 3 个空构造, 5 个 AndroidNotificationDetails 缺 visibility (8-11 列 4 + c 阶段 C-07 标 5)
6. **R31 自我违反 4 处** — medication_page.dart 4 硬编码中文 + 1 Colors.white + 1 新漏 IconButton 包装, "新引入抵消了 token 化改善" (emil 评)

### 2.3 R108 → R109 变化
- **5 token 集中器 + 6 widget 集中器** 100% 落地 (R108 0 → R109 11 个集中器) — 这是 R65 后最成熟 "design engineering" 时刻
- **god class 拆 4/6** (R108 → R109 持平) — R31 没新拆, 但反涨 1 个 (setup_page_state 506→513L)
- **跨平台兼容 0 退步** — Apple Health 23 commit 100% UI 主题层 (GooglePlay 验证)
- **新引入 P0 5 个** — 4 处硬编码中文 + 1 Colors.white + 1 新漏 IconButton + 1 spring.dart 死代码 + 1 page_scaffold 未改 (R31 半成品)
- **新引入 P0 上架阻塞 4 个** — iOS keywords.txt "mental,health" + promotional_text "mental health" + zh-Hans/zh-Hant/Android zh-CN 5 病名 5.1.1 抽审 (c 阶段 C-01~C-04, 8-11 漏扫 4 locale)
- **新引入 P1 bug 6 个** — 10 scale ID 3 处硬编码 + watchToday 跨 midnight + recordConsent 静默丢失 + mood_audio_service 漏 dispose _stt + iOS Podfile target 不一致 + 5 处 notification visibility 缺 (c 阶段 A-01~A-09)

## 3. 13 god class 候选清单 (按修复优先级, 跨期累计去重)

| # | 文件 | 当前行数 | 分类 | 难度 | 优先级 | 拆解建议 | 来源 |
|---|------|---------|------|------|--------|---------|------|
| 1 | `lib/presentation/pages/setup/setup_step_medication.dart` | **614L** | presentation | L 1-2d | P1 R109 第 2 周 | 拆 2-3 widget + 1 controller | 8-11 P1-09 + superpowers-zh P1-3 |
| 2 | `lib/presentation/pages/medication/refill_manage_page.dart` | **779L** | presentation | XL 1w+ | P1 R109 第 2-3 周 | 拆 controllers/ + dialogs/ + helpers/ | 8-11 P1-10 + flutter-spec P1 |
| 3 | `lib/presentation/pages/setup/setup_page_state.dart` | **513L** (+7 跨期) | presentation | L 1-2d | P1 R109 第 2 周 | 拆 4 controller (跟 home_page_state R108 拆 3 controller 同款) | 8-11 P1-08 |
| 4 | `lib/presentation/pages/medication/medication_page.dart` | 524L | presentation | L 1-2d | P1 R109 第 2 周 | 拆 4 controller (AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection) | 8-11 P1-10 + emil 哲学 |
| 5 | `lib/presentation/pages/mood/mood_trend_page.dart` | 517L | presentation | L 1-2d | P2 R110 | 拆 chart + list 2 controller | 8-11 P1-10 + R108 |
| 6 | `lib/core/data/services/notification_service.dart` | 359L (R108 拆后) | service facade | L 1-2d | P1 R109 第 2-3 周 | 4 sub-service 已拆 (Snooze/Reminder/Assessment/Safety), facade 仍 308L 主 + 160L delegate | c D-03 + 8-11 跨视角共识 |
| 7 | `lib/core/data/services/safety_watch_service.dart` | 338L | service | L 1-2d | P1 R109 第 2-3 周 | 拆 detector + dispatcher + config | c D-02 + R108 §六 |
| 8 | `lib/core/data/services/mood_audio_service.dart` | 311L | service | L 1-2d | P1 R109 第 3 周 | 拆 recorder + STT + storage 3 sub | R108 §六 + c E-01 (0 test) |
| 9 | `lib/core/data/database/app_database.dart` | 494L (onUpgrade 块 240L) | data | M 1-2d | P2 R110 | 抽 `database/migrations/migration_v{1..22}.dart` 每文件 ≤30L | c D-01 |
| 10 | `lib/presentation/pages/legal/legal_page.dart` | 460L | presentation | L 1-2d | P2 R110 | 拆 privacy/terms/consent 3 sub-page | R108 §六 |
| 11 | `lib/presentation/pages/settings/reminders_hub_page.dart` | 441L | presentation | L 1-2d | P2 R110 | 拆 3 list controller (medication/assessment/safety) | R108 §六 |
| 12 | `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | 529L | presentation widget | L 1-2d | P2 R110 | audio_lifecycle mixin 已用, 抽 sub-widget 4 个 | R108 §六 + R108 半成品 |
| 13 | `lib/domain/entities/static_scale_translations.dart` | 659L (PHQ-9/GAD-7 16 题 × 3 语言) | domain | M 1-2d | P2 R110 | lazy load + 放 `assets/` 按需 (phqGad7I18nEnabled=false) | c D-06 + 8-11 P1-08 |

**总预计 R109 god class 专项**: 13 个 × 平均 1.5d = ~20d = 4 周 (1 人月)

## 4. 重构建议 (按 R109+ 路线图)

### 4.1 短期 R109 第 1-3 周 (god class 专项 + P0 闭环合并)
**Week 1 (P0 闭环, 5-7h)**:
- 8-11 P0-01~P0-07 上架/合规 (3.5h)
- 8-11 P0-08 Spring 接 _EntrySpring (1-2h) — 跨视角共识
- 8-11 P0-09 lock-in test 扩 lib/**/*.dart (1h)
- 8-11 P0-10 PageScaffold translucent AppBar (1-2h)
- 8-11 P0-11 dart format 2 文件 (5min)
- 8-11 P0-12 设计文档入库 (5min)
- **c 阶段 C-01~C-04** 5 病名 5 locale 1:1 删 (1h) — 跨期 100% 漏
- **c 阶段 C-07** 5 处 AndroidNotificationDetails visibility (30min)
- **c 阶段 A-01~A-09** 9 条 bug (2-3h)

**Week 2-3 (god class 拆 #1-#4 + 重构 + 11 feature 改写)**:
- god class #1 setup_step_medication 614L 拆 (1-2d)
- god class #3 setup_page_state 513L 拆 (1-2d)
- god class #4 medication_page 524L 拆 (1-2d)
- flutter-spec P1-12 `_StreakCounter` / `_TweenNumber` 抽 `tween_number.dart` 公共 widget (1-2h)
- 8-11 P1-01~P1-07 跨期硬编码修 (1-2h 总和)
- 8-11 P1-13~P1-16 11 feature Apple Health 化 (选 2-3 个高 ROI)

### 4.2 中期 R110 (2-3 周) — feature-first 重构
- `lib/features/{feature}/{domain,data,presentation}/` 迁移
- pub workspace 3 package 拆解:
  - `package:chroniccare_core` (core/ + shared/ + theme/)
  - `package:chroniccare_data` (data/ + drift/)
  - `package:chroniccare_app` (presentation/ + features/)
- god class #5~#13 继续拆 (R110 第 2-3 周)
- SF Symbol 字体集成 + brand color 跨平台对齐
- 8 metric icon 跟 SF Symbol 一一对应

### 4.3 长期 v1.0 (2027-Q1)
- HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP 真接
- 5 token 集中器转 pub workspace 公共 package
- `lib/features/{feature}/` 全部迁移到 `package:chroniccare_features_*/`
- 微服务化 (如果 v1.0 用户量到 10w+)

## 5. 跨层耦合度评估

### 5.1 domain ↔ data 渗透
- `dart scripts/check_all.dart` [1/2] 纯度检查 ✅
- domain 层 0 flutter / 0 drift / 0 data / 0 presentation import
- 唯一例外: `domain/logic/scale_registry.dart` 引用 `core/shared/domain_value.dart` (合规, shared/ 跨层)

### 5.2 跨 feature import 边界
- `python scripts/check_cross_feature.py` 0 violation
- pre-existing: `medication/7 个文件 → setup_widgets.dart` (R108 baseline, R95 文档化 public naming 解决循环 import)
- R31 0 新引入跨 feature

### 5.3 shared/ 工具使用层数
- `lib/core/shared/formatters.dart` 被 domain + data + presentation 3 层用 ✅
- `lib/core/shared/json_codec.dart` 被 data + presentation 2 层用 ✅
- `lib/core/shared/mood_visual.dart` 被 domain + presentation 2 层用 ✅
- `lib/core/shared/domain_value.dart` 被 domain + data 2 层用 ✅

## 6. 跟主流 Flutter 架构对比

### 6.1 Clean Architecture (Uncle Bob)
- 当前 4 层 = Clean Architecture 简化版 (省略 enterprise/entities outer ring)
- 优点: 4 层清晰, 业务规则集中在 domain/logic
- 缺点: god class 集中在 presentation, use case 层薄 (8-11 R108 缺 8 usecase)

### 6.2 BLoC pattern
- 当前用 Riverpod 3.x (跟 BLoC 是替代品)
- 优点: Provider/StreamProvider 比 BLoC 简洁, 异步流天然
- 缺点: state 分散到多个 provider, 大页面 (medication 4 controller) 难管

### 6.3 Riverpod 3.x 推荐
- 当前用 Provider<X>(...) 暴露 XRepository (domain 接口), 不暴露 impl ✅
- 3 文件拆分 (core_providers / service_providers / vent_providers) 合理
- 缺: Notifier 模式用得少 (大部分是 Provider/StreamProvider), R109 god class 拆可考虑用 Notifier

### 6.4 feature-first 跟 current 4-layer 对比
- 当前: 4 层 + 共享 umbrella, 跨 feature 走 `presentation/pages/{feature}/` (8 个 feature 目录)
- feature-first: `lib/features/{feature}/{domain,data,presentation}/` 每个 feature 自包含
- 优点: feature-first 更适合 pub workspace 拆 package, god class 易拆
- 缺点: 当前 4 层结构稳定, 迁移到 feature-first 需 ~2-3 周重构 (R110)

## 7. 顶层架构 VERDICT

**当前 8.5/10 (跟 R108 持平)**: 4 层架构 1:1 落地 + 5 token 集中器 + 6 widget 集中器是 R65 后最成熟 "design engineering" 时刻, 跨 feature 0 violation, 跨平台 0 退步。

**核心矛盾**: 视觉层 9.5/10 优秀 (Apple Health 23 commit) — 但 god class 13 个候选 (R108 拆 4/6 后仍剩 11 个新增/反涨) + 5 个 P0 半成品 (spring.dart 死代码 / PageScaffold 未改 / 3 Apple curve 0 caller / 4 硬编码中文 / 1 Colors.white) + 上架/合规 21 P0 (8-11 17 + c 4 漏扫 5 locale) + 6 大跨视角共识 issue。

**预期提升**:
- R109 第 1 周闭环 21 P0 → 8.5/10 → 9.0/10
- R109 god class 专项拆 5-6 个 → 9.0/10 → 9.5/10
- R110 feature-first 重构 + pub workspace 3 package → 9.5/10 → 9.7/10
- v1.0 跨平台 + 微服务 → 9.7/10 → 9.9/10
