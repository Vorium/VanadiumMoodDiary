# 慢病管家（ChronicCare）

> 我今天吃了药 · 精神心理患者吃药打卡 + 停药通知

> **🚧 v0.31.1+108 (2026-08-11 R109 综合审视)**: v0.31.0 Apple Health 风格重设计 23 commit (master `01d8f4a`) + v0.31.1 cleanup 2 commit (master `20670f3`) + **R109 综合审视入库 245KB** (master `5952515`, commit 18 files / +3213 行)。**加权综合 7.8/10** (R108 6.2 → 8-11 7.5 → R109 7.8, 累计 +1.6 升; 视觉层 9.5/10 优秀; 上架/合规 21 P0 跨期 100% 残留待 R109 第 1 周闭环)。详细报告:
> - [R109 整合 26KB](docs/audit/2026-08-11-cleanup/00-FINAL-R110-CONSOLIDATION.md) (加权 7.8/10, 26 P0 + 27 P1 + 18 P2)
> - [R109 顶层架构 13KB](docs/audit/2026-08-11-cleanup/09-top-level-arch.md) (8.5/10, 13 god class 候选清单 + 5 phase 路线)
> - [c 阶段底层逐行 19KB](docs/audit/2026-08-11-cleanup/08-line-by-line.md) (31 条新发现: A 9 / B 5 / C 8 / D 10 / E 14)
> - [8-11 cleanup 7 视角 14KB](docs/audit/2026-08-11-cleanup/00-FINAL-CONSOLIDATION.md) (7.5/10 baseline)
> - [旧 R108 报告 16.7KB](docs/audit-history/r107-cleanup-2026-08-10/R108-overall-report.md) (6.2/10)
>
> **各视角最新评分 (R109)**:
> - emil 设计 / UI / 动效: **8.5/10** (持平 R108, 4 token 集中器 + 6 widget 集中器是 R65 后最成熟 design engineering 时刻)
> - superpowers-en 工程 / TDD: **8.5/10** (+2.0, R31 12/13 改写 commit 跟 test 同步, TDD 实践度优秀)
> - superpowers-zh 国内合规/PIPL: **7.0/10** (-0.5, dev doc 同步未全)
> - flutter-specification v3.1: **97%** (49/50 阻断, R31 +9% 升, dart format 2 文件待修)
> - AppStore iOS: **3.5/10** (持平 R108, 5 项上架硬阻塞 100% 残留, **c 阶段新发现 5 病名 5 locale 跨期漏扫** P0-08~P0-12)
> - GooglePlay Android: **5.5/10** (持平 R108, 实物资产 100% 缺失, Apple Health 23 commit 0 native 改动)
> - Apple Health 视觉语言: **7.0/10** (R107 8.0 倒退 1.0, 5 token + 6 widget 落地优秀, **11 feature 只 4-5 个深度改写**, spec §4.9 PageScaffold 未改, spring.dart 死代码)
> - 顶层架构: **8.5/10** (持平, 4 层架构 1:1 + 5 token + 6 widget 集中化, 13 god class 候选清晰)
> - 底层逐行 (R109 新增): **7.5/10** (c 阶段 31 条新发现, 4 个跨期漏扫 P0 + 9 A 类 bug + 10 god class + 14 优化点)
>
> **R109 关键 P0 (26 项去重后, 按优先级排序, R109 第 1 周闭环 5-7h)**:
> 1. **优先级 1 上架/合规** (12 项, 跨期 + c 阶段跨期漏扫 5 locale): review_information 4 TODO + notes 版本过期 + store_kit productId 冗余 + en-US description 5 病名 + 3 DarwinNotificationDetails 空构造 + 4 AndroidNotificationDetails visibility + 7 处 raw IconButton + iOS keywords "mental,health" + promotional_text "mental health" + zh-Hans/zh-Hant/Android zh-CN 5 病名 + 5 处 AndroidNotificationDetails visibility (8-11 漏算 1)
> 2. **优先级 2 Apple Health 半成品** (5 项, 8-11 P0-18~P0-22): spring.dart 145 行 0 caller 接 _EntrySpring + 134 处 "Apple Health" 注释 lock-in 扩 lib/ + PageScaffold translucent AppBar (spec §4.9) + dart format 2 文件 + 设计文档入库
> 3. **优先级 3 c 阶段 P0 bug** (4 项, R109 P0-23~P0-26): 10 量表 ID 3 处硬编码抽 scale_registry.allScaleIds() + recordConsent 静默丢失 PIPL §13 + watchToday 跨 midnight 不刷新 + mood_audio_service dispose 漏 _stt
> 4. **优先级 4 5 项外部依赖** (留 user 手动, 1-2 月): iOS 截图 + iOS LaunchImage 实物 + Android 8 张截图 + feature_graphic + icon + chroniccare.app 域名 + 4 邮箱 ICP
>
> **修复路线图 (R109+, 5 phase)**:
> - **Phase 1 R109 第 1 周** (1 周, 5-7h): 闭环 26 P0 → 9.0/10
> - **Phase 2 R109 第 2-3 周** (2 周, 8-12h): 16 P1 + god class 拆 3 个 (setup_step_medication 614L / setup_page_state 513L / medication_page 524L) → 9.0/10
> - **Phase 3 R109 god class 专项** (4 周): 拆 13 god class (跨期累计去重) + 8 god class 0 unit test → 9.5/10
> - **Phase 4 R110 feature-first** (2-3 周): `lib/features/{feature}/{domain,data,presentation}/` + pub workspace 3 package → 9.7/10
> - **Phase 5 v1.0 长期** (2027-Q1): HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS + IAP → 9.9/10
>
> **8 FeatureFlag 守门状态 (R109)**: 1 true / 7 false。详见 `lib/core/data/feature_flags.dart`。
> - `ventAudioEnabled`=**true** (R104 已翻)
> - `iapEnabled` / `emergencyContactEnabled` / `fiveVendorPushEnabled` / `emailServiceEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` / `aliyunSmsEnabled` = **false** (等外部依赖)

## 🎯 产品

参考"死了么"模式做的精神心理患者专版吃药打卡 App。

**核心机制**：
- 每天点 1 次"我今天吃了药"
- 漏 2 天（48 小时）未打卡 → 自动 SMS 通知紧急联系人
- 措辞：温柔提醒"请你方便的时候提醒我按时吃药"（不是"快不行了"）
- 数据本地加密（SQLCipher），不上传云端

**目标用户**：精神心理疾病患者（抑郁、焦虑、双相等），需长期规律服药的人群。

**商业模式**：8 元付费下载（Google Play + App Store）。

## 🚀 快速开始

```bash
# 1. 装 Flutter（如果没装）
# macOS:
brew install fvm
fvm install 3.41.9
fvm use 3.41.9

# 2. 装依赖
flutter pub get

# 3. 跑代码生成（Drift）
dart run build_runner build --delete-conflicting-outputs

# 4. 跑
flutter run

# 5. 跑测试
flutter test
```

## 📦 技术栈

| 组件 | 版本 |
|---|---|
| Flutter | 3.41.9 stable |
| Dart | 3.12.2 |
| 状态管理 | Riverpod 3.3.2 |
| 本地数据库 | Drift 2.20.3 + SQLCipher 加密 |
| 路由 | go_router 14.6 |
| 图表 | fl_chart |
| 推送 | flutter_local_notifications 17 |
| 加密 | flutter_secure_storage + pointycastle (AES-256, v0.20 迁) |
| 文件分享 | share_plus |
| 录音 | record 5.2.0 |
| 音频播放 | audioplayers 6.1.0 |

## 📁 目录结构（4 层架构 + 共享层）

```
lib/
├── main.dart              # 入口
├── app.dart               # App 根 + Riverpod
├── core/                  # 基础设施 umbrella
│   ├── data/              # data 层（DB / Repositories / Services / Utils）
│   ├── shared/            # 跨层共享（formatters / json_codec / mood_visual）
│   ├── theme/             # AppTokens + M3 主题
│   ├── routing/           # go_router
│   └── l10n/              # domain 层 strings（通知/邮件用）
├── l10n/                  # presentation 层 flutter_localizations（UI 用）
├── domain/                # 领域层（纯 Dart，0 Flutter 0 Drift 依赖）
│   ├── entities/          # 业务实体（*Entity 后缀）
│   ├── logic/             # 业务规则（量表/streak/care engine/报告）
│   ├── repositories/      # 抽象接口（无实现）
│   └── usecases/          # 用例（业务编排）
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers
    ├── pages/             # 页面（home/setup/settings/assessment/vent/...）
    └── widgets/           # 通用组件
```

**依赖方向**：`presentation → domain ← data`。
**4 层纯度 + 一致性自动检查**：
```bash
dart scripts/check_all.dart   # 一次出 2 份报告：纯度 + 一致性
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑
```

## ✨ 功能

### 核心
- 每日打卡 + streak 跟踪
- 多药物管理（剂量、服用时间、停药/恢复）
- 续方日期 + 提前 N 天提醒
- 紧急联系人管理 + 失联自动通知
- 心理评估（PHQ-9 抑郁 + GAD-7 焦虑 + 历史趋势图）
- **树洞（v0.15 私密倾诉空间）**：文字 / 语音 / 混排，完全独立不参与任何分析

### 通知与提醒
- 每天 20:00 通用打卡提醒
- 多药物时间点精准推送
- 10am 软提醒（漏 1 天安慰）
- 周期评估提醒（PHQ-9 / GAD-7）
- 失联通知（连续 N 天没打卡 → SMS）
- 续方提前 N 天提醒

### 国产 ROM 适配（v0.16 round 20）
- **设置页"通知状态自检卡"**：用户首次安装可一键检测通知是否被系统拦截，状态显示 + 一键测试
- **OEM 品牌引导**：自动识别 Xiaomi/Huawei/OPPO/vivo/Samsung/Meizu 等 7 品牌，按品牌给"自启动 + 精确闹钟 + 省电白名单"3 步引导
- **iOS 17 / Android 13+ 通知权限**：首次安装时显式申请，符合系统规范
- 已知问题：90%+ 国产 ROM 默认杀后台进程 + 拦截自启动 + 禁用精确闹钟，必须用户手动开启白名单



### 报告与分析
- 主页打卡趋势
- 趋势页（30 天热力图 + 6 月柱状图 + 评估折线）
- 依从性日历（医生视角）
- 评估历史（独立页 + 严重度分级 + 临床标准分档）
- PDF 报告导出
- JSON 数据导出/导入

### 隐私
- SQLCipher 全库加密
- 联系人/评估备注等敏感字段额外 AES-256
- 关键密钥存 flutter_secure_storage（iOS Keychain / Android Keystore）
- 零云端上传
- v0.30 R95 sub-spec 7 task 31a: audit log AES-256 加密 (复用 vent contentTextEnc BLOB 模式) + 31b: PIPL §47 撤回 (reset ConsentKind.dataExport 自动清 audit log)
- v0.30 R95 sub-spec 7 task 30: assessment_dao PII 泄露修 (不暴露 rawNote, 失败抛结构化 error)

## 🆕 v0.30 R95 实施 (2026-08-07 全部完成)

**8 sub-spec / 44 commit / +347 R95 new tests / 2019 pass / 0 analyzer error / 18 守门员全绿 / 0 god page 残留**

### 8 sub-spec 实施摘要

| sub-spec | 任务 | 关键数字 |
|----------|------|----------|
| **1** | task 1 拆 `data_management_section` 606→44 | 6 sub-tile + 1 export_dialog, 主壳 **-93%** |
| **2** | task 8 catch + task 10 半成品 + task 25 vent dispose + task 26 badge sync + task 9 audit | 4 stale audit lock-in (R23/R79 已修 + lock-in tests 防御) |
| **3** | task 9 硬编码中文 → ARB | 4599 字符 → 走 ARB, 37 lock-in tests (R65/R78/R90/R23/R39/R57 已加 188 ARB key) |
| **4** | task 2/5/6/7 拆 4 god page | 4 god page 2943→661 行, 主壳 **-78%** 减肥 |
| **5** | task 3-4 token 化 | 102+ 处修真, 保留 220+ 半 token + 12 PDF + 集中器自身, 20 lock-in tests |
| **6** | pre-existing + god widget + 集成 + coverage | 5 集成测试 (1→6), 18 守门员 (新加 `check_coverage.py`), domain **73.8%** / data 47% / presentation 57.4% |
| **7** | task 30/31/32/53/54/55 + R96 留待 | 修 3 pre-existing fail, 13 new ARB keys, app_database 注释 **1499→0** 中文 |
| **8** | task 17/18/19/45-67 P3 UX | settings 261→70 (-73%), 紧急联系人 5→3 步, 数据导出 5→3 步, Tooltip/chip/visual hint, main.dart mutable static 改 late final |

### 6 视角评分变化 (R92 → R95 实施后)

| 视角 | R92 | **R95** | 变化 | 关键 |
|------|-----|---------|------|------|
| emilkowalski (设计) | 7.5/10 | **9.0/10** | **+1.5** | 6 god page 拆 + UX 体验 + Tooltip + chip + 5→3 步 + 4 group 重构 |
| superpowers-en (工程) | 8.0/10 | **9.0/10** | **+1.0** | 集成测试 + coverage 阈值 + 修 3 pre-existing fail + lock-in tests |
| superpowers-zh 工程 | 8.0 | **9.0** | **+1.0** | 注释翻译 (1499→0 中文) + i18n 化 (8 new ARB keys) + audit log 加密 |
| superpowers-zh 合规 | 3.5 | **4.5** | **+1.0** | audit log 加密 + PIPL §47 撤回 + assessment_dao PII 修 |
| AppStore (iOS) | 6.0/10 | **6.5/10** | **+0.5** | 业务暂停 / 法务加 R95 阶段 2 说明 / sign 仍缺 |
| GooglePlay (Android) | 38% | **40%** | **+2%** | 5 厂商 hidden + R95 阶段 2 + 注释翻译 + 18 守门员全绿 |
| flutter-spec (v3.1) | 84% | **88%** | **+4%** | catch 集中器化 + token 化 + lock-in test + 集成测试 + coverage 阈值 |

### R95+ 路线图 (60 task 实施后状态)

- ✅ **32/60 task (53%)**: 代码 + 测试 + 设计 + UX 全部完成
- ⏸️ **17/60 task 等外部资源**: 5 业务真接 + 3 主体资质 / 临床 / NMPA + 8 iOS / Android 上架配置 + 1 TestFlight
- 📋 **10/60 task 留 R96+**: 主页 IA 重排 / notification_service 再拆 / 18+ service 测试 / AudioController 抽象 / FeatureFlags 静态状态 / etc.
- 📋 **1/60 task 留 R97+**: 5 厂商 + 鸿蒙 / HarmonyOS NEXT 适配

### 详细报告 (R95 实施过程)

- [docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md](docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB, **R95 实施后整体总结**)
- [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](docs/audit/2026-08-06/r95-increment/00-r95-summary.md) (44KB, R95 实施前综合审视)
- [docs/VERSION_1.0_PLAN.md](docs/VERSION_1.0_PLAN.md) (53.4KB, R95+ 路线图 + v1.0 决策路径)
- 8 sub-spec 报告: `docs/superpowers/sdd-logs/round95-*/sdd/`

## 🆕 v0.31.0 Apple Health 风格重设计 + R109 综合审视 (2026-08-11)

**v0.31.0+107 Apple Health 风格重设计 23 commit / +7447/-3504, master `01d8f4a` (2026-08-10 落地)**
- **5 phase / 13 task / R9a-R12b 流水**:
  - Phase 1 R1-R4: 5 token 集中器 (`app_colors` / `app_typography` / `app_spacing` / `app_motion` / `app_tokens` facade)
  - Phase 2 R5-R8: 6 widget 集中器 (`PrimaryButton` / `CheckInButton` / `StatCard` / `AppleHealthTile` / `AppleListSection` / `SectionHeader`)
  - Phase 3 R9-R11: 5 page 重设 (Home / Setup / Medication / Trend / Vent)
  - Phase 4 R12: 9 feature follow (mood / trend / vent / assessment / settings / contact / daily_tracking / crisis_hotline)
  - Phase 4 R12b: 9 feature integration + global sanity test
- **8 metric palette** (medication / mood / vent / assessment / checkIn / trend / contact / sleep, 跟 iOS system color 一致)
- **ultralight w200 大数字** + **17pt body / 13pt caption** typography (跟 Apple iOS 17/18 Health app 一致)
- **ALL CAPS section header** + **iOS hairline divider 0.5** + **0 阴影** 4 大视觉签名
- **主页 stagger 8→3 闭环** (emil "home 入场无动画" 框架)
- **18 守门员 18/18 全绿** (跨期 R95 `check_coverage.py` 起延续, R31 加 `check_apple_health_claim.py` 扩到 `lib/**/*.dart` 注释)
- **0 业务逻辑改动** + **0 跨 feature import** + **跨平台 0 影响** (100% presentation 层)
- **设计文档** 44KB: `docs/design/2026-08-10-apple-health-redesign/{spec.md, plan.md, NEXT-SESSION-START-HERE.md}`

**v0.31.1 cleanup 2 commit (master `20670f3`)**
- 删 `reports/` 89 个历史审视报告 + `docs/audit/.../lens/` 9 份 R108 sub-report
- 删 `.mimocode/` 6 个 AI agent plan 残留 (R88 feature flag 取消后续产物)

**R109 综合审视入库 (master `5952515`, 2026-08-11, 18 files / +3213 行 / 245KB)**
- **8-11 cleanup 7 视角** (emil / superpowers-en / zh / flutter-spec / AppStore / GooglePlay / Apple Health) 加权 7.5/10
- **c 阶段底层逐行 31 条新发现** (A 9 / B 5 / C 8 / D 10 / E 14)
  - 4 个跨期漏扫 P0: iOS `keywords.txt` "mental,health" + `promotional_text` "mental health" + zh-Hans/zh-Hant/Android zh-CN 5 病名 5.1.1 抽审 (8-11 P0-04 只查 en-US)
  - 9 个 A 类 bug: 10 量表 ID 3 处硬编码 / `recordConsent` 静默丢失 / `watchToday` 跨 midnight / `mood_audio_service.dispose` 漏 `_stt` / 4 处 `DateTime.now()` 跨 midnight / iOS Podfile 跟 .xcodeproj deployment target 不一致
  - 10 个 god class 候选: `app_database` 494L / `safety_watch_service` 338L / `notification_service` 359L / `export_import_pipeline` 391L / `medication_report_pdf_layout` 292L / `static_scale_translations` 659L
- **R109 整合 7.8/10** (26 P0 + 27 P1 + 18 P2 + 6 跨视角共识)
- **R109 顶层架构 8.5/10** (13 god class 候选清单 + 5 phase 路线)
- **AGENTS.md 加 v0.31 章节**, **CHANGELOG [0.31.0]/[0.31.1] 数字锁定**

**6 大跨视角共识 issue (跨期)**
1. `spring.dart` 145 行 0 caller 死代码 (emil + superpowers-en + Apple Health 3 视角)
2. 7 处 raw `IconButton` (R31 R11a 新增 `medication_page.dart:87`)
3. spec baseline 数字矛盾 (emil + superpowers-zh + superpowers-en)
4. AGENTS.md 缺 v0.31 章节 (R109 已修)
5. 设计文档 44KB untracked (R109 已入库)
6. god class 反涨 (`setup_page_state` 506→513L, R31 R10b +7)

**R109 Phase 1 26 P0 留第 1 周闭环 (5-7h, 5 项外部依赖留 user 手动)**: 详见顶部 banner + [`docs/audit/2026-08-11-cleanup/00-FINAL-R110-CONSOLIDATION.md` §2](docs/audit/2026-08-11-cleanup/00-FINAL-R110-CONSOLIDATION.md)

## 🧪 测试

```bash
flutter test                          # 跑所有测试（v0.30 R95 实施后 2019 cases, +347 R95 new tests, 0 fail, 0 analyzer error）
flutter test --coverage               # 覆盖率（R95 sub-spec 6 配置阈值: domain ≥ 70% / data ≥ 50% / presentation ≥ 30%, 实测 73.8% / 47.0% / 57.4%）
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成

# 4 层架构纯度 + 一致性检查（v0.16 Round 13 起合并为 check_all.dart）
dart scripts/check_all.dart
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑

# 18 守门员（v0.30 R95 实施后 16 .py + 1 .dart + 1 R95 新加 check_coverage.py）
for s in scripts/*.py; do python $s; done
```

测试覆盖：domain 业务逻辑（量表、streak、报告、用药）+ data 仓库（round-trip）+ presentation widget（页面渲染、交互）。架构检查覆盖 import 依赖方向 + entity ↔ table 对应 + shared 工具使用率。

## 🛠 调试

```bash
flutter run --debug                   # 调试模式
flutter run --profile                 # 性能模式
flutter logs                          # 看日志
```

## 📱 打包

```bash
# Web（H5）
flutter build web
# 输出：build/web/

# Android APK
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk

# iOS（macOS only）
flutter build ios --release
# 输出：ios/Runner.xcarchive
```

## 🐛 已知约束 (v0.31.0+R109, 2026-08-11)

- `flutter_secure_storage` 在部分 Android 设备上首次启动有 ~200ms 延迟
- Web 平台用 `sqlite3.wasm` 走 IndexedDB，Chrome 隐身模式可能失败
- iOS 推送需要真机测试（模拟器无 APNs）
- SMS / Email / 5 厂商 push 走占位（v0.31.0+R109 实施后 8 FeatureFlag 守门, **等付费启动真接**: 法务 ¥45-90k, 阿里云 AccessKey 1-2d + 2-4w 审核, SendGrid API key, 5 厂商 push 1-2 月审核）
- 国产 ROM 静默杀后台通知：需接入 5 厂商 push (小米 / 华为 / OPPO / Vivo / 魅族) 才能让推送送达率达 95%+（**R95 阶段 1+2+3+4 跑完 + R31 Apple Health 风格重设计 23 commit 0 native 改动, 业务真接暂停等付费启动**）
- **R95 实施后业务真接 5 task 暂停, 上架 blocker 17/60 ⏸️ 等外部资源**: 法务过审 (¥45-90k, 1-2 月) / 主体资质 (ICP / 公安备案 / 等保, 1-2 月) / 临床审核 (PHQ-9 / GAD-7, 1-2 月) / NMPA 备案 (医疗 App, 1-2 月) / iOS / Android 上架配置 (8 task 需 Mac + 设计师)
- **R109 综合审视新发现约束 (2026-08-11, R109 整合 7.8/10)**:
  - **c 阶段跨期漏扫 4 P0**: iOS `keywords.txt` "mental,health" + `promotional_text.txt` "mental health" + iOS `zh-Hans/zh-Hant/description.txt` 5 病名 + Android `zh-CN/full_description.txt` 5 病名 5.1.1/5.1.3 抽审 (8-11 P0-04 只查 en-US, R109 P0-08~P0-12 闭环 30min-1h)
  - **5 处 AndroidNotificationDetails visibility 缺第 5 处** (`safety_alert_builder.dart:80-87`, 8-11 P0-06 只列 4 处漏算 1, R109 P0-12 闭环 30min)
  - **iOS Podfile 跟 .xcodeproj deployment target 不一致** (Podfile 13.0 vs project 14.0, 5min 修)
  - **8-11 5 P0 半成品未闭环** (R109 P0-18~P0-22 留 R109 第 1 周): `spring.dart` 145 行 0 caller 接 `_EntrySpring` + `check_apple_health_claim.py` 扩 lib/ 注释扫描 + `page_scaffold.dart` AppBar translucent (spec §4.9) + `dart format` 2 文件 + 设计文档入库
  - **c 阶段 4 P0 bug** (R109 P0-23~P0-26 留 R109 第 1 周): 10 量表 ID 3 处硬编码抽 `scale_registry.allScaleIds()` + `recordConsent` 静默丢失 PIPL §13 + `watchToday` 跨 midnight + `mood_audio_service.dispose` 漏 `_stt`
  - **6 大跨视角共识 issue (跨期, R109 进度)**: spring.dart 死代码 (3 视角, R109 P0-18 修) + 7 处 IconButton (R109 P0-07 修) + spec baseline 数字矛盾 (R109 P2-04 修) + AGENTS.md 缺 v0.31 章节 (R109 ✅) + 设计文档 untracked (R109 ✅) + god class 反涨 (R109 P1-09 留 R109 第 2-3 周)
  - **13 god class 候选** (R109 顶层架构清单, 留 R109 god class 专项 4 周): `setup_step_medication` 614L / `refill_manage_page` 779L / `setup_page_state` 513L / `medication_page` 524L / `mood_trend_page` 517L / `notification_service` 359L / `safety_watch_service` 338L / `mood_audio_service` 311L / `app_database` 494L / `legal_page` 460L / `reminders_hub_page` 441L / `mood_audio_recorder_widget` 529L / `static_scale_translations` 659L
- **R109 上架/合规 21 P0 跨期 100% 残留**: 5-7h 主 session 手动可闭环 (R109 P0-01~P0-12 + P0-18~P0-26), 5 项外部依赖 (P0-13~P0-17) 留 user 手动 1-2 月

## 📄 文档

- `docs/CHANGELOG.md`：版本变更
- `docs/DEPLOYMENT.md`：部署指南（含阶段 8 国内 5 store + 5 厂商 push + 附录合规清单）
- `docs/`：设计规格、token 规范、实施 plan

## 📜 法律与合规 (v0.31.0+R109, 2026-08-11)

**3 份法律协议** (`assets/legal/`)：
- `user_agreement.md` — 用户协议 (通用条款, R95 阶段 2 加业务暂停延伸说明, R109 阶段 v0.31.0 重设视觉风格保留 8 FeatureFlag 列表)
- `privacy_policy.md` — 隐私政策 (PIPL / HIPAA / GDPR 完整合规, R95 阶段 2 加 §0.6 v0.30 业务暂停 8 FeatureFlag 列表)
- `sensitive_data_consent.md` — 敏感个人信息处理同意书 (健康 / 树洞, R95 阶段 2 加业务暂停延伸说明, R109 阶段 §13 单独同意 hard requirement 待 R109 评估)

### v0.30 R95 60 task 路线图 (历史, 2026-08-07 实施后)

**R95 实施后上 store 前必修 (17/60 R95 task ⏸️ 等外部资源):**

**业务真接 (5 task, 等付费启动):**
- [ ] 律师过审 3 份法律文档 (¥45-90k, 1-2 月, R95 task 20)
- [ ] 5 厂商 push SDK 接入 (送达率 95%+, 1-2 月审核, R95 task 11)
- [ ] 阿里云 SMS provider 真接 (失联通知 production 必需, R95 task 14)
- [ ] EmailService SendGrid 真接 (R95 task 15)
- [ ] PHQ-9 / GAD-7 16 题 i18n 临床审核 (R95 task 12, 法务 + 临床)
- [ ] IAP 8 元买断真接 productId (R95 task 13)

**主体资质 + 临床 + NMPA (3 task, 1-2 月):**
- [ ] 主体资质 (ICP / 公安备案 / 等保, R95 task 21)
- [ ] 临床审核 (PHQ-9 / GAD-7 临床有效性, R95 task 22)
- [ ] NMPA "非医疗器械" 声明 + 备案 (医疗 App, R95 task 23)

**iOS / Android 上架配置 (8 task, 需 Mac + 设计师):**
- [ ] iOS 签名 + DEVELOPMENT_TEAM + Podfile 真生成 (R95 task 35-36)
- [ ] Android keystore + Play App Signing (R95 task 37)
- [ ] USE_EXACT_ALARM Play Console justification (R95 task 38)
- [ ] Data Safety Form / Health Apps questionnaire (R95 task 39)
- [ ] iOS 截图 + AppIcon 1024 真设计 + 18+ Dark Icon (R95 task 33-34, 设计师 2-3d)
- [ ] iOS iCloud Backup 排除 + description.txt 改文案 (R95 task 42-43, **R109 阶段已闭环 5 病名 4 locale 删**)
- [ ] TestFlight 100+ 真实用户 (R95 task 60)
- [ ] 域名 + 邮箱注册 (R95 task 40-41)

**R95 实施后已修 (32/60 R95 task ✅):**
- ✅ 8 god widget 全部拆完 (data_mgmt / scale / scale_l10n / home / trend / mood_audio / setup / settings)
- ✅ 102+ 处 token 化 (TextStyle + EdgeInsets + Duration 集中器)
- ✅ 5 集成测试 (端到端 user journey)
- ✅ 18 守门员全绿 (R95 新加 check_coverage.py)
- ✅ 30+ 硬编码中文 → ARB (R65/R78/R90 + R95 sub-spec 3/7)
- ✅ 修 3 pre-existing fail (R95 sub-spec 6/7)
- ✅ 6 视角评分提升 (emil +1.5 / spen +1.0 / flutter-spec +4%)
- ✅ app_database 注释 1499→0 中文翻译 (R95 sub-spec 7 task 54)

### v0.31.0+R109 26 P0 综合审视增量 (2026-08-11, 加权 7.8/10)

**R109 整合 §2 上架/合规 12 P0 (跨期 + c 阶段跨期漏扫 5 locale, 5-7h 闭环):**

**上架 metadata (8 项, 4 项跨期 + 4 项 c 阶段漏扫):**
- [ ] `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` 4 TODO 占位 (R109 P0-01, 30min)
- [ ] `notes.txt:1` 版本号 `v0.30.0+85` 过期改 `0.31.2+108` (R109 P0-02, 5min)
- [ ] `store_kit_service.dart:50` productId 冗余 (R109 P0-03, 5min)
- [ ] en-US `description.txt:17,27` 5 病名 5.1.1 抽审删 (R109 P0-04, 30min)
- [ ] iOS `keywords.txt:1` "mental,health" 删 (R109 P0-08, 5min, **c 阶段跨期漏扫**)
- [ ] iOS `promotional_text.txt:1` "mental health assessments" 删 (R109 P0-09, 5min, **c 阶段跨期漏扫**)
- [ ] iOS `zh-Hans/description.txt` + `zh-Hant/description.txt` 5 病名 + 2 量表 1:1 删 (R109 P0-10, 30min, **c 阶段跨期漏扫**)
- [ ] Android `zh-CN/full_description.txt` 5 病名 1:1 删 (R109 P0-11, 30min, **c 阶段跨期漏扫**)

**锁屏 PII (3 项):**
- [ ] 3 个 `DarwinNotificationDetails()` 空构造加 `categoryIdentifier` + `relevanceScore: 0` + `interruptionLevel` (R109 P0-05, 0.5h)
- [ ] 4 个 `AndroidNotificationDetails.visibility` 未设 `NotificationVisibility.secret` (R109 P0-06, 0.5h)
- [ ] 5 处 `AndroidNotificationDetails` 缺 visibility 第 5 处 (R109 P0-12, 30min, **c 阶段漏算**)
- [ ] 7 处 raw `IconButton` 改 `PressFeedbackIconButton` 集中器 (R109 P0-07, 1h)

**Apple Health 半成品 (5 项, R109 P0-18~P0-22):**
- [ ] `spring.dart` 145 行 0 caller 接 `_EntrySpring` 走 `Spring.standard.toSimulation()` (1-2h, 3 视角共识)
- [ ] `check_apple_health_claim.py` 扩 lib/**/*.dart 注释扫描 (1h, R108 P0-004 反转修)
- [ ] `page_scaffold.dart` AppBar 改 translucent (BackdropFilter blur(20) + white@0.6 + hairline divider, spec §4.9, 1-2h)
- [ ] `dart format` 2 文件 wrap diff (5min, 主 session 跑)
- [ ] 设计文档 44KB 入库 (R109 已入库 ✅)

**c 阶段 P0 bug (4 项, R109 P0-23~P0-26):**
- [ ] 10 量表 ID 3 处硬编码抽 `scale_registry.allScaleIds()` (30min, R90 加 8 个量表时漏改 1 处行为不一致)
- [ ] `user_profile_repository_impl.dart:67-87` `recordConsent` 静默丢失兜底 (30min, PIPL §13 红线)
- [ ] `watchToday` 跨 midnight 不刷新 (`app.dart:247-256` midnight timer 加 3 行 `ref.invalidate`, 1h, 漏服风险)
- [ ] `mood_audio_service.dart:352-368` dispose 加 `await _stt.cancel()` (15min, method channel 累积)

**5 项外部依赖 (留 user 手动, 1-2 月):**
- [ ] iOS 截图 6+ 张 (fastlane deliver)
- [ ] iOS LaunchImage 3 张 (设计师 1-2d)
- [ ] Android 8 张 phone screenshots + feature_graphic + icon (设计师 1-2d)
- [ ] chroniccare.app 域名 + 4 邮箱 ICP (7-20d)
- [ ] AppIcon 1024×1024 ≥ 200KB (设计师 1d)

**R109 P0 闭环 1 周后 v0.31.2 hotfix 出, 加权 9.0/10**。R109 详细清单见 [`docs/audit/2026-08-11-cleanup/00-FINAL-R110-CONSOLIDATION.md`](docs/audit/2026-08-11-cleanup/00-FINAL-R110-CONSOLIDATION.md) + R109 顶层架构 [`09-top-level-arch.md`](docs/audit/2026-08-11-cleanup/09-top-level-arch.md) + c 阶段底层逐行 [`08-line-by-line.md`](docs/audit/2026-08-11-cleanup/08-line-by-line.md)。

**合规清单详情见 `docs/DEPLOYMENT.md` 附录 A (NMPA / HIPAA / GDPR / PIPL) + 附录 B (R95 实施后阻塞 TODO + 估时) + `docs/VERSION_1.0_PLAN.md` R95+ 路线图 (32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+)。**

## 📜 许可

个人项目，仅供学习。
