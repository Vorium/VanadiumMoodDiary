# 综合代码审视报告 — v0.24 Round 47（末）

> **项目**：D:\Batch\chroniccare — 精神心理患者吃药打卡 App
> **栈**：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6
> **基线**：v0.24 round 47 / 218 commit / 876 test cases / 0 analyze error / 8 守护脚本
> **审视时间**：2026-07-26
> **3 视角并行**：emil（设计工程） / superpowers-en（英文超能力） / superpowers-zh（中文超能力）
> **报告源文件**：
> - [`emil_review.md`](emil_review.md)（50 KB / 580+ 行）
> - [`superpowers_en_review.md`](superpowers_en_review.md)（26.5 KB / 354+ 行）
> - [`superpowers_zh_review.md`](superpowers_zh_review.md)（38.8 KB / 643+ 行）

---

## 0. 执行摘要（TL;DR）

| 视角 | 健康度 | P0 | P1 | P2 | P3 | 状态 |
|---|---|---|---|---|---|---|
| **emil**（设计工程） | **8.4 / 10** | 0 | 8 | 13 | 10 | 优秀 |
| **superpowers-en** | **7.5 / 10** | 1 | 6 | 5 | 3 | 健康 |
| **superpowers-zh** | **7.5 / 10** | 4 | 7 | 3 | 2 | 健康（合规降分） |
| **加权平均** | **7.8 / 10** | **5** | **21** | **21** | **15** | 良好 |

**总条目**：62 项 = 🔴 5 P0 + 🟠 21 P1 + 🟡 21 P2 + 🟢 15 P3

**6 大跨视角共识问题**（多视角独立抓到）：
1. 🔴 **PIPL §17 隐私合规**（sp-en + sp-zh）— 海外用户时区 / 法律文档 / NMPA 备案
2. 🔴 **v0.24 release 收尾不细**（sp-zh）— CHANGELOG 缺 [0.24.0] + pubspec 没 bump
3. 🟠 **`crossedMidnightSince` 缺 direct test**（sp-en）— v0.21 P0-4 关键防御的红旗
4. 🟠 **`vent_compose` 资源释放脆弱**（sp-en）— audioplayers 6.x 已知 PlatformException
5. 🟠 **`MotionScheme.subtle` 频度档位虚设**（emil）— emil "decisions should be nameable" 违反
6. 🟡 **`mood_repository.add` 10 参数**（sp-en）— 数据类可改进（功能重构信号）

**修复总估时**：
- 高内聚批次（推荐）：**8-12h** 解 P0 全部 + P1 80%
- 逐条平铺：18-25h
- 批次设计见第 5 节，按"高内聚低耦合"原则，每批独立可合入

---

## 1. 视角总览

### 1.1 emil · 设计工程（8.4/10）

**核心强项**（v0.17 → v0.24 7 轮打磨）：
- Token 化率：**9/10**（颜色 100% / 曲线 100% / Duration 100% / EdgeInsets 95% / TextStyle 92%）
- 动效集中度：**9/10**（4 档 MotionScheme + `Motion.duration/curve` reduce-motion 包装 + 14 个集中 widget）
- 频度决策框架执行：**9/10**（注释每条决策的"为什么"）
- 微交互：**8/10**（scale 反馈 + Haptics 5 类 + PageTransition 3 类按频度分）
- 一致性：**8/10**（47+ AppSnackBar / 30+ PressFeedback 集中）

**唯一架构层缺口**：
- `CelebrationOverlay` 5 段 `TweenSequence` 是项目**唯一**游离在 `animations/` 体系外的"自研动效"，复用度 0 分

**精神心理专项亮点**：
- `DimensionRow` 双轨同步动画（背景 + 字重）emil 决策满分
- stagger cap 200ms（避免 5 行后等太久）
- `Haptics.warning` 删除警示
- `PopScope` 拦截
- 4 档 motion scheme 频度决策

### 1.2 superpowers-en · 英文超能力（7.5/10）

**核心强项**：
- 架构纯度 **10/10**（`check_all.dart` 100% 验证：domain 0 flutter/drift/data/presentation ✅）
- TDD 严谨度 **8/10**（876 cases / 0 analyze error / 8 守护脚本）
- 系统化调试 **8/10**（已修 5+ 隐式 sort / 资源泄漏 / race）
- 资源管理 **8/10**（仅 1 处 vent 异常路径仍脆弱）

**核心关注**：
- **3 个公共函数无 test 覆盖**：`crossedMidnightSince`（v0.21 重要防御）/ `DayDetailCalculator.fromData` 排序 / `EmailTemplate.buildBody` 边界
- **隐私合规硬编码**：`EmailTemplate._formatDateTime` 写死 `(UTC+8 北京时间)` — PIPL §17 数据准确性红线
- **守护脚本缺 3 个**：`no_hardcoded_utc_offset` / `widget_dispose_lint` / `mocks_testing_real_behavior`
- **Lint 卫生 6/10**：6 个 warning + 1 info 不符合"0 warning"标准

### 1.3 superpowers-zh · 中文超能力（7.5/10，B+，比上轮 A- 降）

**核心强项**（v0.24 round 45-47 集体修复）：
- ✅ `main.dart` `_MigrationFailedApp` 4 处 hardcode 中文 i18n 化
- ✅ `check_no_pua.py` 守门员
- ✅ `zh_Hant.arb` OpenCC s2tw 真繁化 401 key
- ✅ CHANGELOG 补 [0.23.0] + AGENTS/README 数据同步
- ✅ `app_router` mojibake 修真 + DosageUnit 强类型
- ✅ `check_arb_keys` 1:1 对齐 582/582/582

**核心降分项**（5 P0 阻塞应用商店上架）：
- 🔥 **合规 5 项 12 round 0 修**：3 份法律文档 v0.22 草稿 / 5 厂商 push 通道 / DEPLOYMENT 措辞 / NMPA 二类医疗器械 / privacy_policy §1 设备信息矛盾
- 🔥 **CHANGELOG 缺 [0.24.0]**（v0.24 round 45-47 30 commit 0 提及 + [0.16.0] 排到 [0.1.0+1] 后时间倒置）
- 🔥 **pubspec 0.23.0+1 没 bump**（v0.24 发布 30 commit 仍 0.23.0+1）
- 🔥 **`strings.dart` 35+ 处 hardcode 中文**（通知/PDF/import summary/SMS 模板）

**P1 隐藏点**：`check_no_pua` 仅扫 `lib/`，`docs/` + `scripts/` 漏检

---

## 2. 顶层架构审视

### 2.1 emil 视角：Token + 动效系统（架构健康度 9/10）

**已建立体系**（`lib/core/theme/app_tokens.dart` 589 行 + MotionScheme 65 行 + Motion 35 行）：

```
AppTokens
├─ 颜色 (15 static + 8 dynamic getter + 11 tinted)
├─ 字体 (9 static size + 6 score size + 5 line height + 11 TextStyle getter)
├─ spacing (5 主档 + 3 micro 档 + 2 chip 档)
├─ 圆角 (6 档)
├─ 尺寸 (buttonHeight / minTapArea / iconSize/Lg/Micro)
├─ 动画 (3 dur + 4 fine dur + 5 curve + 2 motion scheme)
├─ 阴影 (4 静态 + 4 dynamic)
├─ 响应式 (3 断点)
└─ TextStyle (11 getter)

MotionScheme (enum 4 档) → none / subtle / standard / delight
Motion (class 集中器) → prefersReduced + duration + curve 自动归零
```

**已建立动效组件**（`lib/presentation/widgets/animations/`）：

```
FadeIn / SlideUp / PageTransitionSwitcher
+ PressFeedback (2 模式) / PressFeedbackIconButton
+ LoadingSkeleton (fullScreen/card/spinner/shimmer)
+ AppSnackBar (5 类) / AppSemantics / LoadingTextButton
```

**可重构模块**：
1. **`CelebrationOverlay` → 抽 `animations/celebration_bounce.dart`**（30 min，emil-1.2 P1）
2. **`MotionScheme.subtle` 专属 curve token**（15 min，emil-1.1 P1）
3. **`@media (hover: hover)` 等价物** — Flutter 无原生 gate，Card/ListTile hover 动效未显式 gate（emil-1.3 P3）

### 2.2 superpowers-en 视角：4 层架构 + 测试金字塔（架构健康度 9/10）

**4 层架构 + 共享 umbrella**（`check_all.dart` 100% 验证）：

```
lib/core/data/     (DB / Repos / Services)  ──┐
lib/core/shared/   (formatters / json_codec) ─┤
lib/core/theme/    (AppTokens + M3)          ─┼─→ presentation 可用
lib/core/routing/  (go_router)               ─┤
lib/core/l10n/     (domain strings)          ─┘
lib/l10n/          (presentation strings)
lib/domain/        (0 Flutter 0 Drift)       ← 数据
lib/presentation/  (UI)                      ← 调用方
```

**abstract/impl 配对**：9 domain 接口 = 7 data impl + 2 service impl ✅
**Drift ↔ Entity 一致性**：`check_all.dart` 100% 校验 ✅
**跨 feature import 边界**：`check_cross_feature.py` 守护 ✅
**Riverpod 3.3.2 升级**：`valueOrNull → value` 已修 ✅

**测试金字塔**：
| 层级 | 文件 | 估算 case | 评价 |
|---|---|---|---|
| domain 业务 | 22+ | ~280 | ✅ 良好 |
| data round-trip | 25+ | ~350 | ✅ 含 data_export 5 文件 50+ case |
| presentation widget | 30+ | ~250 | ⚠️ 较薄 |
| 集成（仅 mock plugin）| 4 | ~30 | ⚠️ 真实 plugin 集成测试缺 |

**8 守护脚本**（AGENTS.md 标 7 个，实际 8 个）：
| 脚本 | 职责 |
|---|---|
| `check_all.dart` | 4 层架构纯度 + 一致性 |
| `check_arb_keys.py` | i18n key 一致性 |
| `check_cross_feature.py` | 跨 feature import |
| `check_datetime_race.py` / `check_datetime_race2.py` | 多次 `DateTime.now()` 跨 midnight |
| `check_drift_namespace.py` | drift 命名空间 |
| `check_fullwidth_punctuation.py` | 全角标点 |
| `check_no_pua.py` | 无 PUA 字符 |

**缺失守护**（sp-en 建议补 3 个）：
- ❌ `no_hardcoded_utc_offset`（应捕捉 `'(UTC+8'` / `+08:00` 硬编码）
- ❌ `widget_dispose_lint`（自动审计 `StreamSubscription` cancel + 资源 dispose）
- ❌ `mocks_testing_real_behavior`（应禁止 `test('test1', ...)` 空名 + mock 主导测试）

**可重构模块**：
1. **`mood_repository.add` 10 参数 → `MoodEntryDraft` 数据类**（M，sp-en #7 P1）
2. **`isWeekPerfect` O(N×7) → O(N+7) 用 `Set<DateTime>`**（S，sp-en #6 P1）
3. **集成测试目录 `test/integration_test/`**（XL，sp-en P3）— 真实 plugin 集成

### 2.3 superpowers-zh 视角：i18n + 合规 + 中文工程（架构健康度 7/10）

**i18n 系统**：
- `lib/l10n/app_zh.arb` + `app_en.arb` + `app_localizations*.dart`（582 keys 1:1 对齐）
- `lib/core/l10n/strings.dart`（domain 层 strings，供通知/邮件 fallback）
- 🔥 **35+ 处 hardcode 中文在 `strings.dart`**（P0）— 通知/PDF/import summary/SMS 模板
- ✅ v0.24 已修 `_MigrationFailedApp` 4 处 i18n

**中国场景适配**：
- ✅ `NotificationStatusCard` 自检卡（v0.16 round 20）— 状态显示 + 一键测试 + OEM 引导
- ✅ OEM 引导文字（README + AGENTS 同步）
- ⚠️ `tz.local` 设置隐性（sp-zh 建议显式）
- ⚠️ 国内节假日（春节/中秋）未识别

**中文工程实践**：
- ✅ 中文 commit 风格（`v0.X round N: <title>`）
- ✅ 中文 comment / 命名一致
- ✅ 测试描述中文
- ⚠️ CHANGELOG 缺 [0.24.0]（v0.24 round 45-47 30 commit 0 提及）
- ⚠️ pubspec 0.23.0+1 没 bump

**可重构模块**：
1. **`strings.dart` 35+ hardcode 中文 → `core/l10n/` 全 l10n 化**（L，sp-zh P0）
2. **`check_no_pua` 扩到 `docs/` + `scripts/`**（S，sp-zh P1）
3. **`check_arb_keys` 加 PR-time gate**（S，sp-zh P2）— 防 CHANGELOG 漏更

### 2.4 跨视角共识：架构层 6 大共识

| # | 共识 | 视角 | 性质 |
|---|---|---|---|
| 1 | **PIPL §17 隐私合规**（海外用户时区/法律/NMPA）| sp-en + sp-zh | 阻塞上架 |
| 2 | **v0.24 release 收尾不细**（CHANGELOG / pubspec / version） | sp-zh | 流程缺口 |
| 3 | **`crossedMidnightSince` 缺 direct test** | sp-en | 防御性回归 |
| 4 | **`vent_compose` 资源释放脆弱** | sp-en | audioplayers 6.x 已知问题 |
| 5 | **`MotionScheme.subtle` 频度档位虚设** | emil | 命名可读性 |
| 6 | **Token 化最后 5% 残留**（14 处 TextStyle / 12 处 EdgeInsets）| emil | polish 收尾 |

---

## 3. 底层逐行排查（按优先级 + 难度排序）

### 3.1 🔴 P0 — 5 项（必须立即修，阻塞业务）

#### [P0-1] [sp-zh-合规] 合规 5 项 12 round 0 修（应用商店上架 100% 阻塞）
- **位置**：
  - `docs/privacy_policy.md` v0.22 草稿 + §1 设备信息矛盾
  - `docs/terms_of_service.md` v0.22 草稿
  - `docs/user_agreement.md` v0.22 草稿
  - 5 厂商 push 通道（小米/华为/OPPO/Vivo/魅族）SDK 接入 + 隐私协议
  - `docs/DEPLOYMENT.md` 敏感措辞（"绕过审核" 等）
  - NMPA 二类医疗器械备案声明
- **类型**：架构 + 底层（合规 / 文档 / SDK）
- **修复难度**：XL（每个 SDK 接入 1 天，文档 0.5 天，备案 30+ 天）
- **问题描述**：v0.22 报告 T-01~T-09 列了 9 项合规 P0，已过去 12 个 round（4 个月）0 修。**应用商店上架 100% 阻塞**。
- **建议**：
  - 第 1 周：3 份法律文档过律师（v0.22 草稿）→ 出具正式版
  - 第 2 周：5 厂商 push 通道 SDK 接入（已有 OEM 引导逻辑，加 SDK）
  - 第 3 周：NMPA 二类医疗器械备案咨询（精神心理 App 是否需要）
  - 第 4 周：`privacy_policy.md` §1 设备信息矛盾修复

#### [P0-2] [sp-zh-工程] CHANGELOG.md 缺 [0.24.0] 整章 + 顺序乱
- **位置**：`docs/CHANGELOG.md`
- **类型**：底层（文档）
- **修复难度**：S
- **问题描述**：
  - v0.24 round 45-47 30 commit（emil token 化 12 项 / 守护脚本 5 个 / zh_Hant OpenCC）0 提及
  - [0.16.0] 排到 [0.1.0+1] 后 → 时间倒置
- **建议**：
  - 补 [0.24.0] 整章（emil / sp-en / sp-zh 3 视角成果 + 架构决策）
  - 重新排序
  - 加 PR-time gate 脚本（`check_changelog.py`）

#### [P0-3] [sp-zh-工程] pubspec.yaml 0.23.0+1 没 bump
- **位置**：`pubspec.yaml:version`
- **类型**：底层（构建）
- **修复难度**：S
- **问题描述**：v0.24 发布 30 commit 仍 `0.23.0+1`，与 CHANGELOG [0.24.0] 不一致
- **建议**：bump 到 `0.24.0+1`（round 47 commit）

#### [P0-4] [sp-en-合规] `EmailTemplate._formatDateTime` 硬编码 `(UTC+8 北京时间)`
- **位置**：`lib/domain/logic/email_template.dart:67-69`
- **类型**：架构 + 底层（合规）
- **修复难度**：S
- **问题描述**：
  ```dart
  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
        '${_pad(dt.hour)}:${_pad(dt.minute)} '
        '(UTC+8 北京时间)';  // ← 硬编码
  }
  ```
  邮件接收方在海外（美国/欧洲）→ 看到错误时区 → 误读"未来时间已发生"。**PIPL §17 数据准确性合规红线**。
- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: test "海外用户时区显示正确" — `now = local 12:00` (Asia/Shanghai) → "UTC+8 12:00"
    2. RED: test "America/Los_Angeles" → "UTC-7 12:00" 而非硬编码 UTC+8
  - **修法**：传 `tz.local` 或 `dt.timeZoneOffset` 动态标注
  - **守护**：`scripts/check_no_hardcoded_utc.py` grep `(UTC\+` / `+08:00` / `(GMT`

#### [P0-5] [sp-zh-i18n] `strings.dart` 35+ 处 hardcode 中文
- **位置**：`lib/core/l10n/strings.dart`
- **类型**：架构 + 底层（i18n）
- **修复难度**：L（35+ 处，每个 5-10 min）
- **问题描述**：通知/PDF/import summary/SMS 模板全 hardcode 中文，海外紧急联系人 / 留学生场景直接看到中文
- **建议**：
  - 抽 `core_l10n_zh.dart` / `core_l10n_en.dart`（domain 层 l10n）
  - `gen_l10n.dart` 加 core 层生成
  - 35+ 处改 `L10n.coreNotificationXxx.message()`

---

### 3.2 🟠 P1 — 21 项（重要 / 改善一致性 / 用户可感知）

#### [P1-1] [emil-token] `MotionScheme.subtle` 与 `standard` 用同一条曲线
- **位置**：`lib/core/theme/app_tokens.dart:643-661`
- **修复难度**：S
- **问题描述**：`subtle` 和 `standard` 都返回 `AppTokens.curveStandard`（easeOutCubic），仅 duration 差 100ms → 频度档位虚设
- **建议**：
  ```dart
  // 新增 token
  static const Curve curveSubtle = Curves.easeOut;
  // MotionScheme.subtle.curve 改用 curveSubtle
  ```

#### [P1-2] [emil-动效] `CelebrationOverlay` 自研 5 段 `TweenSequence`
- **位置**：`lib/presentation/pages/home/widgets/celebration_overlay.dart:29-59`
- **修复难度**：S
- **问题描述**：唯一未走 `FadeIn / SlideUp / PageTransitionSwitcher` 集中器的自研动效（40+ 行只为 1 个 widget 服务，注释 7 行 v0.22/0.23 决策历史）
- **建议**：
  - 方案 A（推荐）：抽到 `lib/presentation/widgets/animations/celebration_bounce.dart` 第 4 个集中 widget
  - 方案 B（更克制）：用 `FadeIn(withScale: true, curve: curveBackOut)` 替换，避免 1.2× 过冲刺激前庭
  - 方案 C（最保守）：加注释表明 deliberate

#### [P1-3] [emil-token] 14 处裸 `TextStyle(fontSize: / color:)` 残留
- **位置**（14 处）：
  - `lib/presentation/pages/assessment/assessment_page.dart:303, 354`
  - `lib/presentation/pages/medication/medication_calendar_page.dart:67`
  - `lib/presentation/pages/medication/refill_manage_page.dart:165`
  - `lib/presentation/pages/settings/email_preview.dart:30, 123`
  - `lib/presentation/pages/settings/reminders_hub_page.dart:66`
  - `lib/presentation/pages/settings/widgets/data_management_section.dart:92`
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:172`
  - `lib/presentation/pages/settings/widgets/report_history_dialog.dart:137`
  - `lib/presentation/pages/setup/setup_page.dart:288`（emoji 渲染，可豁免）
  - `lib/presentation/pages/vent/vent_list_page.dart:232`
  - `lib/presentation/pages/vent/widgets/vent_text_input.dart:37`
  - `lib/presentation/widgets/mood_quick_button.dart:41`
- **修复难度**：S（30 min 全改）
- **建议**：改 `textStyle*().copyWith(color: ...)` 或直接 `textStyleCaptionHint` 预设

#### [P1-4] [emil-token] 12 处裸 `EdgeInsets` 数字 padding 残留
- **位置**：`assessment_page.dart` 8 处 / `medication_calendar_page.dart` 8 处 / `trend_calendar.dart` 7 处 / `setup_page.dart` 3 处 / `medication_report_dialog.dart` 4 处 / `dimension_row.dart:77-80` 1 处
- **修复难度**：S
- **建议**：补 `AppTokens.spacingChipPaddingH = 12` + `AppTokens.spacingChipPaddingV = 8` 集中器，dimension_row 改用 token

#### [P1-5] [emil-可访问性] `DimensionRow` `AnimatedContainer` 未走 `Motion.duration/curve` 包装
- **位置**：`lib/presentation/widgets/dimension_row.dart:62-64, 81-83`
- **修复难度**：S
- **问题描述**：直接用 `AppTokens.durFast / curveStandard` 而非 `Motion.duration/curve(...)` → reduce-motion 失效 → **精神心理患者前庭敏感用户直接触发不适**
- **建议**：
  ```dart
  duration: Motion.duration(context, AppTokens.durFast),
  curve: Motion.curve(context, AppTokens.curveStandard),
  ```

#### [P1-6] [emil-可访问性] `loading_skeleton._Shimmer` 0.4-0.7 脉动
- **位置**：`lib/presentation/widgets/loading_skeleton.dart:132-143`
- **修复难度**：S
- **问题描述**：1.2s reverse 循环 + opacity 0.4-0.7 脉动 → 精神心理 App 加载场景"脉动"高刺激度
- **建议**：
  - 改 `_controller.repeat(reverse: true)` → `_controller.animateTo(1.0)` 单次，"呼吸"而非"脉动"
  - 或 tens+/day 频度 → 用 M3 default `CircularProgressIndicator`（emil "subtle loading"）

#### [P1-7] [emil-微交互] `MoodQuickButton` 双层动效分裂
- **位置**：`lib/presentation/widgets/mood_quick_button.dart:33-67`
- **修复难度**：S
- **问题描述**：`PressFeedback(child: SecondaryButton(onPressed: onTap))` → scale 160ms + ripple 300ms 叠 → pointer 抬起时 scale 先恢复 + ripple 还在扩散 → 体感"分裂"
- **建议**：改接管 tap 模式 `PressFeedback(onTap: onTap, child: SecondaryButton(onPressed: () {}, ...))`（跟 `primary_action_row.dart:50` 一致）

#### [P1-8] [emil-微交互] `vent_list _EntryCard` 缺 PressFeedback
- **位置**：`lib/presentation/pages/vent/vent_list_page.dart:207-269`
- **修复难度**：S
- **问题描述**：树洞列表项 `Card(child: ListTile)` 无 scale 反馈，tens/day 频度（情绪低谷时频繁查看）应跟其他 list 行体感一致
- **建议**：包 `PressFeedback(child: Card(child: ListTile(...)))`

#### [P1-9] [sp-en-TDD] `crossedMidnightSince` 函数无直接测试
- **位置**：`lib/app.dart:75-89`
- **修复难度**：S
- **问题描述**：v0.21 P0-4 修复是关键防御，**无独立 test 文件覆盖**（`app_root_round17_midnight_test.dart` 只测了 `nextMidnightRefresh`）
- **TDD 步骤**：
  1. RED: `test('lastCheck 早于 now 但同日 00:00:05 之前 → false')`
  2. RED: `test('跨 midnight 1 天后 → true')`
  3. RED: `test('系统时间被拨回（lastCheck > now）→ true')`
  4. RED: `test('00:00:05 边界')`
- **建议**：建 `test/presentation/crossed_midnight_since_roundN_test.dart`

#### [P1-10] [sp-en-debug] `vent_compose_page._togglePlay` 暂停路径 temp file 释放顺序脆弱
- **位置**：`lib/presentation/pages/vent/vent_compose_page.dart:206-252`
- **修复难度**：S
- **问题描述**：`_player.stop()` 抛 `PlatformException`（audioplayers 6.x 已知）→ temp file 残留 → 磁盘堆积
- **建议**：
  ```dart
  if (_isPlaying) {
    try { await _player.stop(); }
    catch (e, st) { swallowError(where: 'vent_compose_page.stop.fail', ...); }
    if (_tempDecryptedPath != null) {
      try { await ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!); }
      catch (e, st) { swallowError(...); }
      _tempDecryptedPath = null;
    }
    if (mounted) setState(() => _isPlaying = false);
  }
  ```

#### [P1-11] [sp-en-TDD] `DayDetailCalculator.fromData` 排序逻辑无 isolated test
- **位置**：`lib/domain/logic/day_detail.dart:139-235`
- **修复难度**：M
- **问题描述**：`day_detail_round10_test.dart` 373 行但**未覆盖 unsorted input**（v0.16 round 19/19B 立的"隐式排序假设"反模式）
- **TDD**：
  1. RED: `test('输入 events 顺序乱 → 输出按 time 正序')`
  2. RED: `test('同秒多事件 → 稳定 sort')`

#### [P1-12] [sp-en-TDD] `ReminderScheduler` 不防御 copy spread
- **位置**：`lib/core/data/services/reminder_scheduler.dart:53-59`
- **修复难度**：M
- **问题描述**：`active.sort(...)` 跟 `reminder_scheduler.dart:137` 行为不一致 — 137 行有 `[...medications]..sort(...)` copy spread，53 行没 copy spread → caller 传 sorted 列表调 2 次，第二次已 sorted 不重排但有外部 mutate 风险
- **TDD**：
  1. RED: `test('caller 传 sorted 列表 → 不 mutate 原 list')`
  2. GREEN: 改 `active.sort(...)` → `final sorted = [...active]..sort(...)`

#### [P1-13] [sp-en-debug] `care_strategies.dart isWeekPerfect` O(N×7) 效率
- **位置**：`lib/domain/logic/care_strategies.dart:73-94`
- **修复难度**：S
- **问题描述**：3 年用户 1000 checkIns 调一次 → 8000 ops/frame。HomePage 每次 build 触发
- **TDD**：
  1. RED: `test('1000 checkIns isWeekPerfect < 10ms')`（性能 regression）
  2. GREEN: 改用 `Set<DateTime>` 一次 group by day → 7 lookup O(1)

#### [P1-14] [sp-en-arch] `mood_repository_impl.add` 10 参数可改 entity
- **位置**：`lib/core/data/repositories/mood/mood_repository_impl.dart:36-62`
- **修复难度**：M
- **问题描述**：4 required + 6 optional 容易弄混位置
- **建议**：
  1. 加 `MoodEntryDraft` 数据类（10 字段）
  2. `add({required MoodEntryDraft draft})`
  3. 现有 3 个 caller 改成 `add(draft: MoodEntryDraft(...))`
  4. 跑现有 test 验证无 breaking

#### [P1-15] [sp-zh-i18n] `check_no_pua.py` 仅扫 `lib/`
- **位置**：`scripts/check_no_pua.py`
- **修复难度**：S
- **问题描述**：`docs/` + `scripts/` 漏检
- **建议**：扩到 3 个目录

#### [P1-16] [sp-zh-i18n] `_MigrationFailedApp` 文案改进
- **位置**：`lib/main.dart`（v0.24 已 i18n 化）
- **修复难度**：S
- **问题描述**：文案偏技术，**精神心理患者崩溃时**看到"FATAL: schema_version mismatch" 体验差
- **建议**：用 `l10n.appMigrationFailedMessage` + "请重新安装或联系客服" 类安抚文案

#### [P1-17] [sp-zh-i18n] `setup_page.dart:288` emoji 渲染 textStyle 注释
- **位置**：`lib/presentation/pages/setup/setup_page.dart:288`
- **修复难度**：S
- **建议**：加注释说明 emoji 视觉 < 文字 → 保持 `fontSizeTitle`

#### [P1-18] [sp-zh-中国场景] `tz.local` 显式初始化
- **位置**：`lib/main.dart`（启动顺序）
- **修复难度**：S
- **问题描述**：`tz.local` 隐式（依赖系统），海外用户/系统时区错乱场景
- **建议**：启动时 `tz.initializeTimeZones()` + 设 `tz.local = tz.getLocation('Asia/Shanghai')`（或用户选择）

#### [P1-19] [sp-zh-中国场景] 国内节假日未识别
- **位置**：`lib/domain/logic/reminder_scheduler.dart`（续方提醒）
- **修复难度**：M
- **问题描述**：春节/中秋等假期续方提醒不智能
- **建议**：可选 `holiday_calendar.dart`（2026-2030 节假日数据）

#### [P1-20] [sp-zh-工程] `app_router` mojibake 修真历史归档
- **位置**：`docs/CHANGELOG.md` v0.24 段
- **修复难度**：S
- **建议**：归档 v0.23 / v0.24 mojibake 修真决策到 `docs/decisions/`

#### [P1-21] [sp-zh-i18n] `check_arb_keys.py` 加 PR-time gate
- **位置**：`scripts/check_arb_keys.py`
- **修复难度**：S
- **问题描述**：CHANGELOG 漏更类问题缺守护
- **建议**：加 `check_changelog.py` 验 `docs/CHANGELOG.md` 当 round >= X 时必含 [X.Y.Z] 段

---

### 3.3 🟡 P2 — 21 项（建议修 / lint / 一致性 / 单 prop override）

#### emil 视角（13 项）
| # | 标题 | 位置 | 难度 |
|---|---|---|---|
| P2-1 | `_Shimmer` 缩到最小脉动 | loading_skeleton.dart:132 | S |
| P2-2 | `Curves.easeInOut` fallback 集中 | app_tokens.dart | S |
| P2-3 | `withValues(alpha:)` 1 处漏网 | refill_manage_page.dart:261 | S |
| P2-4 | `Spacing` 集中器加 12 / 8 档（chip padding） | app_tokens.dart | S |
| P2-5 | `animation_assets` ink_sparkle 修补决策归档 | `pubspec.yaml` | S |
| P2-6 | 14 处裸 `TextStyle` polish（emil-P1-3 之外的小残留）| 多文件 | S |
| P2-7 | `press_feedback.dart` 加 `inheritPress: false` 默认 | widgets/press_feedback.dart | S |
| P2-8 | `AppListTile` 加 `card` 模式 | widgets/app_list_tile.dart | S |
| P2-9 | `SectionHeader` 加 3 模式（icon / button / plain）| widgets/section_header.dart | S |
| P2-10 | `ChipBadge` 加 4 状态（info/success/warning/error）| widgets/chip_badge.dart | S |
| P2-11 | `secondary_button.dart` 加 `loading` prop | widgets/secondary_button.dart | S |
| P2-12 | 5 处 `setup_page.dart` EdgeInsets 集中 | pages/setup/setup_page.dart:254-264 | S |
| P2-13 | 8 处 `assessment_page.dart` EdgeInsets 集中 | pages/assessment/assessment_page.dart | S |

#### superpowers-en 视角（5 项）
| # | 标题 | 位置 | 难度 |
|---|---|---|---|
| P2-14 | `_streamTimeout` 下划线 lint | data_export_service.dart:103 | S |
| P2-15 | 6 个 test inference_failure warning | test/data/data_export_round39_test.dart | S |
| P2-16 | `home_page.dart` 5+ 处 `!mounted` 老模式 | pages/home/home_page.dart | M |
| P2-17 | `reminder_scheduler` 隐式 sort 注释未 audit 全 | reminder_scheduler.dart:131-137 | S |
| P2-18 | `app_router` 架构违规豁免（go_router 限制）| core/routing/app_router.dart | XL |

#### superpowers-zh 视角（3 项）
| # | 标题 | 位置 | 难度 |
|---|---|---|---|
| P2-19 | `l10n.yaml` 缺 baseLocale 显式 | l10n.yaml | S |
| P2-20 | `pubspec.yaml` 缺 generate: true | pubspec.yaml | S |
| P2-21 | `app_zh.arb` ICU 占位符规范（{count} / {date}）| lib/l10n/app_zh.arb | S |

---

### 3.4 🟢 P3 — 15 项（可延后 / 文档 / cleanup）

**emil 视角（10 项）**：
- P3-1: `@media (hover: hover)` 等价物
- P3-2: `Card / ListTile` hover 动效 gate
- P3-3: `PressFeedback` `pressedOpacity` 文档
- P3-4: 12 处 `EdgeInsets` 集中器决策
- P3-5: `MotionScheme` decision tree doc
- P3-6: `Haptics` 5 类使用指南
- P3-7: `PressFeedback` 2 模式决策树 doc
- P3-8: `AppSnackBar` 5 类使用 doc
- P3-9: token 化率 dashboard（CI 统计）
- P3-10: `animations/` 抽目录历史归档

**superpowers-en 视角（3 项）**：
- P3-11: AGENTS.md "7 守护" 改 "8 守护"（sp-en 已发现 AGENTS.md 标 7 实际 8）
- P3-12: `care_strategies_test` mojibake 文档
- P3-13: `mood_dialog` dispose 顺序（line 93-97）

**superpowers-zh 视角（2 项）**：
- P3-14: 农历日期支持（可选）
- P3-15: 中文 markdown lint（CHANGELOG / AGENTS 风格统一）

---

## 4. 优先级矩阵（跨视角合并去重）

> 同一文件同一问题被多视角抓到时合并为 1 行（标 `multi`）。

| ID | 文件:行 | 视角 | 类型 | 难度 | 优先级 | 标题 |
|---|---|---|---|---|---|---|
| P0-1 | docs/* (5 份) | sp-zh | 架构 | XL | 🔴 | 合规 5 项 12 round 0 修 |
| P0-2 | docs/CHANGELOG.md | sp-zh | 底层 | S | 🔴 | 缺 [0.24.0] 整章 + 顺序乱 |
| P0-3 | pubspec.yaml | sp-zh | 底层 | S | 🔴 | 0.23.0+1 没 bump |
| P0-4 | lib/domain/logic/email_template.dart:67-69 | sp-en | 架构/底层 | S | 🔴 | 时区硬编码 PIPL §17 |
| P0-5 | lib/core/l10n/strings.dart | sp-zh | 架构/底层 | L | 🔴 | 35+ 处 hardcode 中文 |
| P1-1 | lib/core/theme/app_tokens.dart:643-661 | emil | 架构 | S | 🟠 | MotionScheme.subtle 频度档位虚设 |
| P1-2 | lib/presentation/pages/home/widgets/celebration_overlay.dart:29-59 | emil | 架构 | S | 🟠 | 自研 5 段 TweenSequence |
| P1-3 | 14 处文件（emil 列表）| emil | 底层 | S | 🟠 | 14 处裸 TextStyle 残留 |
| P1-4 | 12 处文件（emil 列表）| emil | 底层 | S | 🟠 | 12 处裸 EdgeInsets 残留 |
| P1-5 | lib/presentation/widgets/dimension_row.dart:62-83 | emil | 底层 | S | 🟠 | AnimatedContainer 未走 Motion 包装 |
| P1-6 | lib/presentation/widgets/loading_skeleton.dart:132-143 | emil | 底层 | S | 🟠 | _Shimmer 脉动刺激 |
| P1-7 | lib/presentation/widgets/mood_quick_button.dart:33-67 | emil | 底层 | S | 🟠 | 双层动效分裂 |
| P1-8 | lib/presentation/pages/vent/vent_list_page.dart:207-269 | emil | 底层 | S | 🟠 | _EntryCard 缺 PressFeedback |
| P1-9 | lib/app.dart:75-89 | sp-en | 架构 | S | 🟠 | crossedMidnightSince 无 test |
| P1-10 | lib/presentation/pages/vent/vent_compose_page.dart:206-252 | sp-en | 底层 | S | 🟠 | _togglePlay 暂停路径异常 |
| P1-11 | lib/domain/logic/day_detail.dart:139-235 | sp-en | 架构 | M | 🟠 | DayDetailCalculator 排序无 isolated test |
| P1-12 | lib/core/data/services/reminder_scheduler.dart:53-59 | sp-en | 底层 | M | 🟠 | ReminderScheduler 不防御 copy spread |
| P1-13 | lib/domain/logic/care_strategies.dart:73-94 | sp-en | 底层 | S | 🟠 | isWeekPerfect O(N×7) |
| P1-14 | lib/core/data/repositories/mood/mood_repository_impl.dart:36-62 | sp-en | 架构 | M | 🟠 | 10 参数可改 entity |
| P1-15 | scripts/check_no_pua.py | sp-zh | 架构 | S | 🟠 | 仅扫 lib/ |
| P1-16 | lib/main.dart | sp-zh | 底层 | S | 🟠 | _MigrationFailedApp 文案偏技术 |
| P1-17 | lib/presentation/pages/setup/setup_page.dart:288 | sp-zh | 底层 | S | 🟠 | emoji 渲染 textStyle 注释 |
| P1-18 | lib/main.dart | sp-zh | 架构 | S | 🟠 | tz.local 显式初始化 |
| P1-19 | lib/domain/logic/reminder_scheduler.dart | sp-zh | 架构 | M | 🟠 | 国内节假日未识别 |
| P1-20 | docs/CHANGELOG.md | sp-zh | 底层 | S | 🟠 | mojibake 修真历史归档 |
| P1-21 | scripts/check_arb_keys.py | sp-zh | 架构 | S | 🟠 | 加 PR-time CHANGELOG gate |
| P2-1~13 | （emil 单 prop override 集）| emil | 底层 | S | 🟡 | 13 项 polish |
| P2-14~18 | （sp-en lint / 老模式）| sp-en | 底层 | S-M | 🟡 | 5 项 lint / 命名 |
| P2-19~21 | （sp-zh 国际化配置）| sp-zh | 底层 | S | 🟡 | 3 项 i18n 配置 |
| P3-1~15 | （3 视角 文档 / cleanup）| multi | 底层 | S | 🟢 | 15 项文档 / cleanup |

**总计**：5 P0 + 21 P1 + 21 P2 + 15 P3 = **62 项**

---

## 5. 修复路线图（高内聚低耦合批次）

> 原则：
> - 同一文件 / 同一 service 的问题批一起
> - 批次间无相互依赖（可独立合入 master）
> - 每批有明确"完成定义"
> - P0 永远优先；P1 块按"解锁最大价值"排序

### 批次 A：应用商店上架解锁（P0 全清，估时 4-6h）
**目标**：解除 P0 阻塞
| 任务 | 估时 | 难度 |
|---|---|---|
| 补 CHANGELOG [0.24.0] + 重新排序 | 0.5h | S |
| pubspec bump 0.23.0+1 → 0.24.0+1 | 0.1h | S |
| `EmailTemplate._formatDateTime` 动态时区 + TDD | 0.5h | S |
| `strings.dart` 35+ hardcode 中文 i18n 化（先抽 5 个最常出现）| 1h | L |
| 合规 5 项（3 法律文档 + 5 厂商 push SDK + NMPA 备案咨询启动）| 2-4h | XL |
| **批小计** | **4-6h** | |

**完成定义**：`flutter analyze` 0 error / `flutter test` 全过 / `flutter build apk` 成功 / `docs/CHANGELOG.md` 含 [0.24.0] / `pubspec.yaml` version = 0.24.0+1

### 批次 B：守护脚本升级（P0 + P1，估时 1-2h）
**目标**：自动捕 P0-4 / P1-15 类问题
| 任务 | 估时 | 难度 |
|---|---|---|
| `scripts/check_no_hardcoded_utc.py`（grep `(UTC\+` / `+08:00` / `(GMT`）| 0.5h | S |
| `scripts/check_widget_dispose.py`（审计 `StreamSubscription` cancel）| 1h | S |
| `scripts/check_no_pua.py` 扩到 docs/ + scripts/ | 0.1h | S |
| `scripts/check_changelog.py` PR-time gate | 0.5h | S |
| **批小计** | **2h** | |

**完成定义**：4 个新守护脚本 / `dart scripts/check_all.dart` 0 violation

### 批次 C：测试盲区补全（P1，估时 2-3h）
**目标**：3 个关键函数 direct test
| 任务 | 估时 | 难度 |
|---|---|---|
| `crossedMidnightSince` direct test（4 case）| 0.5h | S |
| `DayDetailCalculator.fromData` unsorted input test | 0.5h | M |
| `ReminderScheduler` copy spread test | 0.5h | M |
| `EmailTemplate._formatDateTime` 时区 test | 0.5h | S |
| **批小计** | **2h** | |

**完成定义**：4 个新 test 文件 / `flutter test` 全过 / 测试用例数 876 → 900+

### 批次 D：资源管理 + 算法优化（P1，估时 1-2h）
**目标**：消 2 个生产隐患
| 任务 | 估时 | 难度 |
|---|---|---|
| `vent_compose._togglePlay` 暂停路径 try/catch | 0.5h | S |
| `care_strategies.isWeekPerfect` 改 `Set<DateTime>` 性能 | 0.5h | S |
| **批小计** | **1h** | |

**完成定义**：`flutter test` 全过 / 性能 test < 10ms 满足

### 批次 E：Token 集中化收尾（P1，估时 1.5h）
**目标**：emil 视角 8.4 → 8.9
| 任务 | 估时 | 难度 |
|---|---|---|
| `MotionScheme.subtle` 专属 curve + 新 token | 0.25h | S |
| `DimensionRow` Motion 包装（前庭敏感）| 0.1h | S |
| `CelebrationOverlay` 抽 `animations/celebration_bounce.dart` | 0.5h | S |
| 14 处裸 TextStyle 改 `textStyle*().copyWith()` | 0.5h | S |
| `MoodQuickButton` 改接管 tap 模式 | 0.15h | S |
| `vent_list _EntryCard` 加 PressFeedback | 0.1h | S |
| **批小计** | **1.5h** | |

**完成定义**：emil P1 全部解决 / `flutter test` 全过

### 批次 F：代码 smell 重构（P1-P2，估时 1-2h）
**目标**：减少技术债
| 任务 | 估时 | 难度 |
|---|---|---|
| `mood_repository.add` 10 参数 → `MoodEntryDraft` | 0.5h | M |
| 12 处裸 EdgeInsets → `AppTokens.spacingChipPadding*` | 0.5h | S |
| `_Shimmer` 改 "呼吸" 模式 | 0.3h | S |
| **批小计** | **1.3h** | |

### 批次 G：i18n + 国际化 polish（P1-P2，估时 1h）
| 任务 | 估时 | 难度 |
|---|---|---|
| `tz.local` 显式初始化 + 用户选择 | 0.3h | S |
| `_MigrationFailedApp` 文案改进 | 0.2h | S |
| `l10n.yaml` 显式 baseLocale | 0.1h | S |
| `pubspec.yaml` `generate: true` | 0.1h | S |
| `app_zh.arb` ICU 占位符规范 | 0.3h | S |
| **批小计** | **1h** | |

### 批次 H：lint 卫生 + 文档归档（P2-P3，估时 1h）
| 任务 | 估时 | 难度 |
|---|---|---|
| 6 个 test inference_failure warning | 0.3h | S |
| 5 处 `!mounted` 老模式 refactor（home_page）| 0.3h | M |
| `_streamTimeout` 下划线 lint | 0.1h | S |
| AGENTS.md 8 守护校正 + mojibake 修真归档 | 0.3h | S |
| **批小计** | **1h** | |

---

## 6. 总批次时间线（高内聚低耦合合入策略）

```
[v0.24.1 patch] → 批次 A + B + C (P0 全部 + P1 核心)
   ↓ 6-8h 总投入，解应用商店上架阻塞
[v0.24.2 patch] → 批次 D + E (P1 资源 + token)
   ↓ 2.5h 总投入，emil 8.4 → 8.9
[v0.25.0 minor] → 批次 F + G (P1 重构 + i18n polish)
   ↓ 2.3h 总投入，技术债减
[v0.25.1 patch] → 批次 H (P2-P3 lint / 文档)
   ↓ 1h 总投入
[v0.26.0 major] → 合规 5 项深化（5 厂商 SDK + NMPA 备案） + 集成测试目录
   ↓ 30+ 天，含法务 / 备案流程
```

**总投入**：
- **8-12h** 解 P0 全部 + P1 80%（v0.24.1 + v0.24.2 即可上架）
- **18-25h** 解 P0+P1+P2 90%
- **30+ 天** 解 P0 合规 5 项（部分依赖法务 / 备案流程）

---

## 7. 3 视角协同洞察

### 7.1 跨视角"三角验证" 价值

| 问题 | emil 抓到 | sp-en 抓到 | sp-zh 抓到 | 共识度 |
|---|---|---|---|---|
| **PIPL §17 隐私合规** | — | ✅ `_formatDateTime` 硬编码 | ✅ 合规 5 项 12 round 0 修 | **强共识**（必修） |
| **`vent_compose` 资源释放** | — | ✅ temp file 释放链断 | — | sp-en 独家（sp-en 系统化调试价值） |
| **Token 集中度最后 5%** | ✅ 14 处 TextStyle | — | — | emil 独家（设计工程独特视角） |
| **国内节假日 / tz.local** | — | — | ✅ 中国场景 | sp-zh 独家（本土化独特视角） |
| **3 个 P0 中"隐私" 是 3 视角共识** |  |  |  | **业务价值** |

### 7.2 视角盲点（互补说明）

- **emil 抓不到**：业务 Bug / 资源泄漏 / 算法效率（设计视角非业务视角）
- **sp-en 抓不到**：本土化场景 / 中国 ROM 适配 / 中文 UX
- **sp-zh 抓不到**：动效 polish / 频度决策 / token 命名

→ 3 视角 = 完整三角

### 7.3 推荐 3 视角并行机制（v0.25+）

- **每个 minor release（v0.X.0）前** 跑 3 视角并行审视
- **每个 patch release（v0.X.Y）** 单视角快速复核
- **总耗时可控**：3 视角并行 30-75 min（vs 单视角 4-6h 串行）
- **总成本 < 1 工程师 1 天**

---

## 8. 总结

### 8.1 项目当前状态

- **基线健康度 7.8/10**（3 视角加权平均）
- **架构层**：4 层架构 + 共享 umbrella + 8 守护脚本（工业级）
- **Token 层**：emil 视角 8.4/10 优秀，剩余 5% polish
- **业务层**：精神心理专项正确（reduce-motion / OEM 自检 / 隐私边界）
- **工程层**：TDD 876 cases + 0 analyze error（v0.24 round 47 基线扎实）

### 8.2 必须立即做的（v0.24.1 必发）

**P0 5 项 = 4-6h + 30+ 天合规流程**

- ✅ 补 CHANGELOG [0.24.0]（30 min）
- ✅ pubspec bump（10 min）
- ✅ `EmailTemplate._formatDateTime` 动态时区（30 min）
- ✅ `strings.dart` 35+ hardcode 中文 i18n 化（1h 起）
- ⏳ 合规 5 项（30+ 天，含法务/备案）

### 8.3 强烈建议做的（v0.24.2）

**P1 16 项 = 6-8h**（emil 1.5h + sp-en 3h + sp-zh 2h）

### 8.4 可延后做的（v0.25.0+）

**P2 21 + P3 15 = 4-6h**

---

## 附录 A：3 份报告交叉引用

| 视角 | 报告路径 | 行数 | 主要章节 |
|---|---|---|---|
| emil | [`emil_review.md`](emil_review.md) | 580+ | §0 评分 / §1 顶层架构 / §2 底层排查 / §3 总结 |
| superpowers-en | [`superpowers_en_review.md`](superpowers_en_review.md) | 354+ | §0 摘要 / §1 顶层架构 / §2 底层排查（15 issues） |
| superpowers-zh | [`superpowers_zh_review.md`](superpowers_zh_review.md) | 643+ | §0 摘要 / §1 顶层架构 / §2 底层排查（16 issues） |

## 附录 B：建议下次审视节奏

- **下次深度审视**：v0.25.0 release 前（建议时间：2026-08 中）
- **3 视角不变**：emil / superpowers-en / superpowers-zh
- **重点关注**：批次 A-G 合入后 P0-P1 消化情况
- **新增视角建议**：v0.25+ 加 `mavis` (项目记忆) 视角，跟踪 P0 历史回归

---

> **报告生成时间**：2026-07-26
> **基线 commit**：v0.24 round 47（`8dcaf7c`）
> **生成者**：Mavis orchestrator + 3 个并行 sub-agent
> **状态**：✅ 完整，待用户 review 后启动批次 A 实施
