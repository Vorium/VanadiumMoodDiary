# Apple Health 风格 UI Redesign · Design Spec

> **Status**: Draft v0.1 · 2026-08-10
> **Scope**: 全 11 个 feature 页面重设计 · 改动深度 = Token + 关键 widget
> **Style**: Apple Health app (iOS 17/18) · 极简 / 大量留白 / 0 阴影靠 color 表达层次
> **Owner**: Mavis (orchestrator) + subagent-driven implementation

---

## 1. 现状诊断

### 1.1 设计 token 现状（v0.27 R65 拆分后已结构化）
- **文件组织**：`app_tokens.dart` (facade) + `app_colors.dart` + `app_typography.dart` + `app_spacing.dart` + `app_motion.dart` 5 个
- **色**：主色嫩绿 `#6BCF7F` · 背景 `#FAFAFA` · 卡片 `#FFFFFF` · textPrimary `#1A1A1A` · border `#E0E0E0`
- **间距**：`8/16/24/40/80` 5 主档 + `2/4/6/12` 细颗粒
- **圆角**：`button 24 / card 16 / input 12 / chip 8 / cell 2-4`
- **字号**：`title 28 / headline 24 / button 20 / body 18 / label 16 / caption 14 / micro 10-8`
- **动效**：`fast 200 / normal 300 / slow 500 ms` + 6 curve + 4 档 MotionScheme

### 1.2 关键 widget 现状
- `CheckInButton`: 88px 高、24px 圆角、嫩绿大块按钮（接近 M3 elevated button 风格）
- `PrimaryButton`: 直接 wrap FilledButton（依赖 M3 默认样式）
- `StatCard`: 数字 headline 24 + label caption 14，w600（标准 M3 风格）
- `SectionHeader`: label 16 / w500 / textSecondary（标准小标题）
- `HomePage`: 6 区域（Header / HeroIllustration / QuickMoodCarousel / PrimaryActionRow / TodaySummaryCard / SecondaryActionRow），3-3 + 居中布局
- `SetupStep*`: 4 步（consent/welcome/medication/done），单一 Column + 多 TextField
- `MedicationPage`: 5 个子页（calendar/today/refill/manage/detail）

### 1.3 核心问题（用户视角）
1. **按钮太高（88px）** — Apple 标准 50-56px，过大像 M2 默认 + 圆形 24px 圆角像 Android 老风格
2. **配色太单调** — 全 app 只有 1 个主色（嫩绿），没有 Apple Health 那种红/粉/橙/绿/蓝/紫模块化彩色 tile
3. **大数字不够 Apple** — w600 headline 不如 Apple Health 标志性 ultralight w200 数字有高级感
4. **卡片层次靠阴影** — 实际 iOS 不用 shadow，靠 hairline divider + container color 表达层次
5. **间距偏大** — `spacingMd=24 / spacingLg=40` 频繁使用，信息密度低
6. **页面背景白** — iOS 是 `#F2F2F7` systemGroupedBackground，不是纯白
7. **缺 ALL CAPS section header** — iOS section header 是 ALL CAPS 12pt 灰色，跟正文强对比
8. **缺 translucent AppBar** — iOS 顶部 nav bar 走 translucency + blur，不是固定不透明
9. **缺 spring 动效** — 当前全用 duration-based，Apple 用 spring 表达物理
10. **缺 0.5px hairline divider** — 当前 1px 实色 divider 太硬

---

## 2. Apple Health 风格核心原则（emil + apple-design skill 综合）

### 2.1 8 大原则（来自 apple-design SKILL §16）

| # | 原则 | 在本项目落地 |
|---|------|----------|
| 1 | **Purpose** | 精神心理患者向，去除一切"通用 SaaS"装饰，只保留核心动作（打卡/记录） |
| 2 | **Agency** | 撤销/返工随手可达，不滥用 dialog 拦截 |
| 3 | **Responsibility** | 隐私默认开启，病耻感文案收敛 |
| 4 | **Familiarity** | 沿用 iOS 用户已有的"卡片 + 章节 + 数字"心智模型 |
| 5 | **Flexibility** | 暗色模式 + 大字模式 + 减少动效模式全支持 |
| 6 | **Simplicity** | 每屏只一个核心动作，其他进二级页 |
| 7 | **Craft** | 0.5px hairline / ultralight 数字 / spring 反馈 / 200ms transition |
| 8 | **Delight** | 偶尔的庆祝弹跳 / 数字递增 tween / Mood emoji 弹性 |

### 2.2 emil 决策框架（应用版）
- 按钮按下 → `scale(0.97)` + 100ms ease-out（已通过 `PressFeedback` 实现）
- 卡片/容器不用 `scale(0)` 入场 → `scale(0.95) + opacity 0`
- Spring > duration-based（任何手势/状态切换）
- 入场用 `easeOut`，出场用 `easeIn`，手势/拖动用 `easeInOut`
- 持续动效（loading shimmer）必须 < 1.2s 周期 + 600ms pause
- UI 动画 < 300ms（庆祝可 < 500ms）

### 2.3 Reduced-motion + Reduced-transparency + 高对比
- 系统开 reduce-motion → 所有 spring/duration 降为 0 / linear（已通过 `Motion.duration` 实现）
- 系统开 reduce-transparency → translucent AppBar 变 solid
  - **实现状态 (R110 2026-08-13 审计记录)**: Flutter 未暴露 reduce-transparency 媒体查询, `page_scaffold.dart:61-65` 目前恒 translucent (`&& false` 死分支, 错用 disableAnimations 代理)。R111 用 AccessibilityInfo/原生 bridge 做真代理, 或本行降级为 spec 文档化取舍。
- 系统开高对比 → 所有容器加 1px 边框 + 强对比色

---

## 3. Token 重定义（具体值）

### 3.1 `app_colors.dart` — 完整改写

#### 3.1.1 基础色（亮色）
| Token | 当前 | 新值 | 备注 |
|---|---|---|---|
| `background` | `#FAFAFA` | `#F2F2F7` | iOS systemGroupedBackground |
| `surface` | `#FFFFFF` | `#FFFFFF` | 不变 |
| `surfaceVariant` | (无) | `#FFFFFF` M3 standard | 新增 |
| `surfaceContainer` | (无) | `#F2F2F7` | 新增（iOS 风格 secondary surface） |
| `textPrimary` | `#1A1A1A` | `#000000` | iOS label 默认纯黑（暗色下反白） |
| `textSecondary` | `#666666` | `#3C3C43` 60% | iOS secondaryLabel |
| `textHint` | `#595959` | `#3C3C43` 30% | iOS tertiaryLabel |
| `border` | `#E0E0E0` | `#3C3C43` 10% / `#C6C6C8` | 视情况选 iOS separator 风格 |
| `divider` | `#F0F0F0` | hairline `#C6C6C8` @ alpha 0.4 | 0.5px 视觉等效 |
| `disabled` | `#BDBDBD` | M3 disabled 12% alpha | 不变 |

#### 3.1.2 主色（嫩绿）— 保留但微调
- `primary`: `#34C759`（**改为 iOS systemGreen**，原 6BCF7F 偏冷，iOS 绿更鲜）
- `primaryDark`: `#248A3D`（按下态）

#### 3.1.3 6 色 metric tile 调色板（Apple Health 标志性）
新增常量 `healthMetricsColors`，映射到 8 个项目功能：
| Metric ID | 颜色 | iOS 同名 | 用途 |
|---|---|---|---|
| `medication` | `#FF3B30` systemRed | 红 | 用药 / 续方 / 提醒 |
| `mood` | `#FF2D55` systemPink | 粉 | 心情 / 应激 |
| `vent` | `#AF52DE` systemPurple | 紫 | 树洞 / 录音 |
| `assessment` | `#5856D6` systemIndigo | 靛 | 心理评估 |
| `checkIn` | `#34C759` systemGreen | 绿 | 打卡 / streak |
| `trend` | `#007AFF` systemBlue | 蓝 | 趋势 / 图表 |
| `contact` | `#FF9500` systemOrange | 橙 | 紧急联系人 |
| `sleep` | `#5AC8FA` systemTeal | 青 | 睡眠 / 日常 |

（实际项目里 `sleep` 还没接入，先保留 7 个 metric + 1 灰兜底）

#### 3.1.4 Tinted color 体系重做
- `tintedPrimarySoft` (0.1) → `tintedPrimarySoft` (0.08，更柔)
- `tintedMetricSoft(metricId, ctx)` 新增 → 按 metricId 拿对应 metric 色 @ alpha 0.12
- `tintedErrorSoft` / `tintedWarningSoft` 保留，alpha 降到 0.08

#### 3.1.5 dark mode
- `backgroundDark` `#121212` → `#000000` (iOS 暗色纯黑)
- `surfaceDark` `#1E1E1E` → `#1C1C1E` (iOS secondarySystemGroupedBackground)
- `textPrimaryDark` `#E6E6E6` → `#FFFFFF`
- 其他 dark 系列同步 iOS 暗色规范

### 3.2 `app_typography.dart` — 大调

#### 3.2.1 字号阶梯（Apple 14 档）
| 旧 | 新 | 用途 |
|---|---|---|
| `fontSizeTitle 28` | `fontSizeTitle 28` | 不变（页面大标题） |
| `fontSizeHeadline 24` | `fontSizeHeadline 22` | 略小，更 Apple |
| `fontSizeButton 20` | `fontSizeButton 17` | **关键改：iOS button 标准 17pt** |
| `fontSizeBody 18` | `fontSizeBody 17` | **关键改：iOS body 标准 17pt** |
| `fontSizeLabel 16` | `fontSizeLabel 15` | iOS subheadline |
| `fontSizeCaption 14` | `fontSizeCaption 13` | iOS footnote |
| `fontSizeMicro 10` | `fontSizeMicro 11` | 微调 |
| `fontSizeXxxSmall 8` | `fontSizeXxxSmall 9` | 微调 |
| `fontSizeBodySm 13` | `fontSizeBodySm 12` | iOS caption2 |
| `fontSizeCaptionSm 12` | `fontSizeCaptionSm 11` | |
| `fontSizeLabelSm 11` | `fontSizeLabelSm 11` | |
| (新增) | `fontSizeMetricXl 34` | **Apple Health 大数字** ultralight |
| (新增) | `fontSizeMetricLg 28` | 次大数字 |
| (新增) | `fontSizeMetricMd 22` | 中等数字 |

#### 3.2.2 字重（核心改：增加 ultralight）
- 现有 w400/w500/w600/w700 保留
- **新增 w200 ultralight** → `fontWeightUltralight`（Apple Health 大数字）
- **新增 w300 light** → `fontWeightLight`（Apple secondary 大数字）
- `textStyleMetricXl(c)` 新增 → 34 / w200 / tight / `textPrimaryColor`
- `textStyleMetricLg(c)` 新增 → 28 / w300 / tight / `textPrimaryColor`

#### 3.2.3 行高
- `lineHeightTight 1.2` → `1.1`（Apple 大字紧凑）
- `lineHeightNormal 1.5` → `1.4`（Apple body 紧凑）
- `lineHeightLoose 1.8` → `1.6`（Apple long-form 紧凑）
- `lineHeightSnug 1.4` 不变
- `lineHeightRelaxed 1.6` → `1.5`

#### 3.2.4 字符间距
- 大字（≥ 22pt）`letterSpacing: -0.5`（Apple SF Pro Display 收紧）
- 中字（17-20pt）`letterSpacing: -0.2`
- 小字（≤ 14pt）`letterSpacing: 0`

### 3.3 `app_spacing.dart` — 小调

#### 3.3.1 圆角（**关键改**）
- `radiusButton 24` → `radiusButton 14`（Apple standard button）
- `radiusCard 16` → `radiusCard 16` 不变
- `radiusInput 12` → `radiusInput 10`（Apple input）
- `radiusChip 8` → `radiusChip 8` 不变
- `radiusCell 2` → `radiusCell 4`（heatmap cell 略大）
- `radiusCellLg 4` → `radiusCellLg 6`
- **新增** `radiusTile 12` (Apple Health tile)
- **新增** `radiusLargeButton 22` (Pill button, 类似 FAB)

#### 3.3.2 尺寸
- `buttonHeight 88` → `buttonHeight 50`（**关键改：iOS standard 50pt**）
- `buttonHeightSmall 56` → `buttonHeightSmall 44`（iOS small button 44pt）
- `inputHeight 56` → `inputHeight 44`（iOS text field 44pt）
- `iconSize 24` → `iconSize 22`（略小，更 Apple）
- `iconSizeLg 32` → `iconSizeLg 28`
- `iconSizeInline 18` → `iconSizeInline 17`
- `iconSizeSmall 14` → `iconSizeSmall 13`
- `iconSizeEmpty 64` → `iconSizeEmpty 56`
- `iconSizeError 56` → `iconSizeError 48`

#### 3.3.3 间距
- `spacingXs 8` → `spacingXs 8` 不变
- `spacingSm 16` → `spacingSm 12`（略小）
- `spacingMd 24` → `spacingMd 16`（**关键改：iOS 列表 cell 标准 16**）
- `spacingLg 40` → `spacingLg 24`
- `spacingXl 80` → `spacingXl 48`（**关键改：减少空旷**）
- **新增** `spacingXxxl 32`（Apple 章节间距）
- `pageMarginH 16` → `pageMarginH 20`（iOS standard 20pt）
- `pageMarginV 24` → `pageMarginV 16`

#### 3.3.4 Stagger（emil 动效）
- `staggerStepMs 40` → `staggerStepMs 30`（略快，Apple 感觉更紧凑）
- `staggerCapMs 200` → `staggerCapMs 150`（5 行后立即出现，emil 感知性能）

### 3.4 `app_motion.dart` — 大调（核心改：Spring > Duration）

#### 3.4.1 Duration（保留但调档）
- `durFast 200` → `durFast 200` 不变
- `durNormal 300` → `durNormal 250`（略快，Apple 紧凑）
- `durSlow 500` → `durSlow 400`
- `durPress 160` → `durPress 100`（**关键改：iOS 即时反馈 100ms**）

#### 3.4.2 Curve（保留 + 增强）
- 保留 `curveStandard (easeOutCubic) / curveSubtle (easeOut) / curveDecelerate (easeOutQuart) / curveAccelerate (easeInCubic) / curveDelight (elasticOut) / curveBackOut (easeOutBack)`
- **新增** `curveSpring` → 自定义 spring curve（cubic-bezier(0.23, 1, 0.32, 1)）→ Apple springOut 近似
- **新增** `curveAppleSheet` → iOS 抽屉曲线 `cubic-bezier(0.32, 0.72, 0, 1)` (apple-design §4)
- **新增** `curveAppleDrawer` → `cubic-bezier(0.77, 0, 0.175, 1)`

#### 3.4.3 Spring（核心新功能）
- 新增 `class Spring` → 模仿 iOS spring 行为
  - `static Spring standard = Spring(mass: 1, stiffness: 200, damping: 20)` → critical damped 0.4s
  - `static Spring gentle = Spring(mass: 1, stiffness: 150, damping: 18)` → 0.5s
  - `static Spring bouncy = Spring(mass: 1, stiffness: 200, damping: 12)` → 0.5s 轻弹
  - 提供 `SpringSimulation` wrapper（用 flutter 内置 physics）

#### 3.4.4 Shadow — 大改（Apple 0 阴影）
- `shadowCardOf` 改为空（**删 shadow**）→ Apple Health 0 阴影
- `shadowCardDarkOf` 同上
- `shadowDialogOf` 改为 1 层极轻（iOS modal shadow 极轻）
- `shadowOverlayOf` 同上
- **新增** `hairlineDivider` helper（0.5px 等效 hairline，用 `Divider(thickness: 0.5)`）

#### 3.4.5 MotionScheme 不变（4 档 none/subtle/standard/delight）

#### 3.4.6 Motion 类（已实现）保留 + 加 spring wrapper
- 新增 `Spring.of(context, SpringType.standard)` 返回 `Spring` 实例

---

## 4. 关键 widget 改写清单（5-8 个）

### 4.1 `PrimaryButton` — Apple Pill 风格
- 改前：依赖 M3 FilledButton，full width
- 改后：
  - 高度 50（用 `buttonHeight`）
  - 圆角 14（用 `radiusButton`）
  - 字号 17（用 `fontSizeButton`）
  - 字重 w600
  - 文字 + 可选 leading icon
  - 3 种 variant: `primary` (filled) / `secondary` (tonal) / `tertiary` (text)
  - 内部包 `PressFeedback` 提供 scale(0.97) 反馈

### 4.2 `CheckInButton` — Apple Health 巨型 CTA
- 改前：88px 高 + 24 圆角 + 嫩绿块
- 改后：
  - 高度 64（`buttonHeight + 14`，Apple Health 巨型 pill）
  - 圆角 32（**全圆角**，pill 形状）
  - 字号 20（更大）
  - 居中：emoji/icon + 文字 + 副标题（连续天数）
  - 背景：systemGreen + 1px 1px 投影（极轻）
  - 打卡完成态：变灰 + 显示对勾动画（spring + scale 0.95→1）

### 4.3 `StatCard` — Apple Health 大数字
- 改前：headline 24 + caption 14
- 改后：
  - 大数字 34 / w200 ultralight / tight 1.1
  - 单位小字 13 / w400 / textSecondary
  - label 在下 13 / w400 / textHint
  - 4 个变体：`default` / `large` (34) / `xl` (44) / `inline`
  - 数字递增 tween（已有 `_StreakCounter` 模式）

### 4.4 新增 `AppleHealthTile` — 彩色 metric 模块
- 用法：8 个 metric（medication/mood/vent/assessment/checkIn/trend/contact/sleep）
- 结构：
  - 圆角 12 容器
  - 背景：metric 色 @ alpha 0.12
  - 左上：metric icon（28pt，metric 色）
  - 中：metric 名（caption）+ 当前值（metricLg ultralight）
  - 右：箭头 (chevron)
- 点击 → 跳到对应 feature
- 仿 Apple Health "favorites" 卡片

### 4.5 新增 `AppleListSection` — iOS ListSection 风格
- 用法：模拟 iOS 群组列表（背景 F2F2F7 之上放白色圆角块）
- 结构：
  - 标题 ALL CAPS 13pt w400 textHint（iOS section header 标准）
  - 内容白色圆角块
  - 内部 cell 用 hairline divider（0.5px）
  - cell 高度 44pt
- 替代现有的 `Card + Padding` 模式

### 4.6 `SectionHeader` — iOS section header
- 改前：label 16 / w500 / textSecondary
- 改后：fontSizeCaptionSm (11) / w500 / textHint / **letterSpacing 0.6 ALL CAPS**
- 新增 `AppleListSection` 集成

### 4.7 `HomeHeader` — Apple Health greeting
- 改前：greeting + date + theme toggle
- 改后：
  - 大字 greeting "早安，李雷" 28pt w600
  - 副字日期 15pt w400 textSecondary
  - 右上：theme toggle（小 icon button 32x32）
  - 下边距 16 → 8（更紧凑）
  - 背景：透明（页面背景 F2F2F7 自带）

### 4.8 `TodaySummaryCard` + `QuickMoodCarousel`
- 改前：复合卡片 + 横向 mood emoji 滚动
- 改后：
  - `TodaySummaryCard` → 4 个 `StatCard` 网格，2x2，间距 12
  - `QuickMoodCarousel` → 5 个圆形 mood button（48x48）横向 + 选中 spring 放大 1.1

### 4.9 PageScaffold + AppBar — Translucent 风格
- 改前：固定不透明 AppBar
- 改后：
  - AppBar 背景：white @ alpha 0.6 + BackdropFilter blur(20)
  - elevation: 0
  - 暗色下：black @ alpha 0.4 + blur(20)
  - 顶部 hairline divider（仅滚动时显示）
  - 适配 reduce-transparency 媒体查询（变 solid）

---

## 5. 页面级应用（11 feature）

> **完成度 (R110 2026-08-13 审计实测): 4.5/11** — home (12 ALS + 4 AHT) / setup (5 ALS) / medication (17 ALS + 4 AHT) / trend (1 ALS) 已改; mood / mood_list / vent / assessment / contact / settings / daily_tracking / crisis_hotline **仍 0 AppleListSection 化** (Card+ListTile 旧方言), 见 docs/audit/2026-08-13-multi-lens/ EM-02/AH-04。

### 5.1 Home（重点改）— Apple Health 仪表盘
- 改前：6 区域堆叠
- 改后：
  - 顶部：HomeHeader（greeting + theme toggle）
  - 第 1 块：CheckInButton（巨型 pill）
  - 第 2 块：AppleListSection "今日指标" → 4 个 StatCard 网格
  - 第 3 块：AppleListSection "心情" → QuickMoodCarousel
  - 第 4 块：AppleListSection "快捷操作" → 2x2 AppleHealthTile 网格
  - 第 5 块：SecondaryActionRow（设置 / 树洞）
  - 整体 spacing 改为 spacingMd (16)

### 5.2 Setup（重点改）— 引导流程
- 改前：4 步单一 Column + 大量 TextField
- 改后：
  - 顶部：进度条 1/4（小 hairline）
  - 大标题 28pt + 副标题 15pt
  - 表单：AppleListSection 风格（圆角白块 + hairline）
  - 底部：PrimaryButton (full width)
  - 章节：间距 24

### 5.3 Medication（重点改）— 功能页
- 改前：5 子页混合
- 改后：
  - 顶部 8 个 AppleHealthTile 横滚（medication / refill / history / ...）
  - 主区：today schedule 用 AppleListSection 风格
  - 浮动：+ Add medication (FAB)
  - 颜色：medication = systemRed

### 5.4 Trend（中等改）— 图表
- 改前：多图 + 卡片
- 改后：
  - 章节用 AppleListSection
  - 图表保留（颜色改 metric palette）
  - 间距紧凑到 16

### 5.5 Mood / MoodList（中等改）— 情绪页
- 改前：5 档 emoji + 记录表
- 改后：
  - 5 档大圆形 mood button（72x72）横向 spring 选中
  - 记录列表 AppleListSection 风格
  - 颜色：mood = systemPink

### 5.6 Vent（中等改）— 树洞
- 改前：列表 + 录音
- 改后：
  - 列表 AppleListSection 风格
  - FAB 添加（systemPurple）
  - 录音 button 改 Apple Pill 风格

### 5.7 Assessment（中等改）— 评估
- 改前：题目 + 历史
- 改后：
  - 历史列表 AppleListSection
  - 题目页保留但 spacing 16
  - 颜色：assessment = systemIndigo

### 5.8 CheckIn / Contact / Settings / DailyTracking（自动适配）
- 不手动改结构，靠 token 变化自动升级
- 验证截图通过

---

## 6. 关键决策点（**用户已确认** · 2026-08-10）

| # | 决策 | 用户选择 | 实施含义 |
|---|---|---|---|
| 1 | 主色 | ✅ **改 iOS green #34C759** | `AppColors.primary` 从 `#6BCF7F` → `#34C759` |
| 2 | 大数字 ultralight (w200) | ✅ **全部 StatCard 用 w200** | `textStyleMetricXl/Lg/Md` 3 个全部 ultralight |
| 3 | buttonHeight 88 → 50 | ✅ **完全 iOS 50+14** | `buttonHeight 88 → 50` + `radiusButton 24 → 14` 同步改 |
| 4 | 圆角 button 24 → 14 | ✅ **完全 iOS 50+14**（同 #3 一起） | 同上 |
| 5 | 彩色 metric tile 8 个 | ✅ **8 个全面板** | `healthMetricsColors` 8 个全上（medication/mood/vent/assessment/checkIn/trend/contact/sleep） |
| 6 | Spring 动效 | ✅ **引入 Spring + 保留 MotionScheme 双轨** | 新增 `class Spring` + 3 静态实例，兼容现有 `MotionScheme` 4 档 |
| 7 | translucent AppBar | ✅ **引入**（BackdropFilter blur） | `page_scaffold.dart` 改造，dark mode 同步 |
| 8 | dark mode 同步 | ✅ **一次到位** | 所有 token + widget 同步改 dark mode |

---

## 7. 验收标准

### 7.1 客观
- `flutter analyze` 0 error
- `flutter test` 全过（baseline 2103 cases + 5+ 新 widget test；R110 实测 ~2246 pass / 9 fail, R109 收尾后清零）
- 21 守门员全绿
- Token 覆盖率 ≥ 95%（grep 0 硬编码 `Color(0xFF...)` / `fontSize: X` / `borderRadius: BorderRadius.circular(X)` in `lib/presentation/`）

### 7.2 主观（截图对比）
- Home 页：Apple Health 风格一眼可辨
- 3 个 metric tile 彩色（medication 红 / mood 粉 / vent 紫）
- 按钮按下有 scale(0.97) 反馈
- 文字密度比 v0.30 R107 提升 30%（spacings 从 24 → 16）

---

## 8. 实施策略

### 8.1 5 phase · 13 task
详见 `plan.md`

### 8.2 TDD 原则
- 每个新 widget 必须有 1 个 golden test（检查关键视觉属性：圆角/字号/颜色）
- 每个改写 widget 保留原 test 兼容 + 加 1 个新 visual assertion

### 8.3 Subagent 策略
- Phase 1（token）: 1 个 subagent 自己跑（一致性高）
- Phase 2（widget）: 4 个 subagent 并行（每个独立 widget）
- Phase 3（页面）: 3 个 subagent 并行（home/setup/medication）
- Phase 4（清理）: 1 个 subagent
- 每个 subagent 完跑后：1 个 reviewer subagent 跑 `flutter analyze + test + 守门员`

### 8.4 风险
- **R1**: token 大改可能破坏 100+ 处现有 widget → Phase 1 后必须跑 baseline test
- **R2**: dark mode 同步改可能引入新 contrast bug → 跑 contrast 守门员
- **R3**: Spring 引入可能跟 MotionScheme 冲突 → 双轨制（保留 duration，新增 spring，按场景选）
- **R4**: 11 feature 改完 regression 风险高 → 分 phase 跑，phase 之间留 baseline buffer

---

## 9. 范围外（明确不做）

- ❌ 不动业务逻辑（domain / data 层 0 改动）
- ❌ 不拆 god class（home_page_state 506L 不动，留 R109 处理）
- ❌ 不改路由结构
- ❌ 不加新 feature
- ❌ 不改 ARB 文案（除非有 i18n 长度问题）
- ❌ 不改 backend / push / SMS / IAP 集成

---

## 10. 文件变更清单（预估）

**改（5 个）**：
- `lib/core/theme/app_colors.dart`（~370 → ~450 行）
- `lib/core/theme/app_typography.dart`（~205 → ~260 行）
- `lib/core/theme/app_spacing.dart`（~155 → ~190 行）
- `lib/core/theme/app_motion.dart`（~220 → ~290 行）
- `lib/core/theme/app_tokens.dart`（~315 → ~330 行，facade 转发更新）

**新增（3 个 widget）**：
- `lib/presentation/widgets/apple_health_tile.dart`（~150 行）
- `lib/presentation/widgets/apple_list_section.dart`（~120 行）
- `lib/core/theme/spring.dart`（~80 行）

**重写（5 个 widget）**：
- `lib/presentation/widgets/primary_button.dart`（~80 → ~180 行）
- `lib/presentation/widgets/check_in_button.dart`（~180 → ~220 行）
- `lib/presentation/widgets/stat_card.dart`（~70 → ~120 行）
- `lib/presentation/widgets/section_header.dart`（~135 → ~110 行）
- `lib/presentation/widgets/page_scaffold.dart`（看现状，~50 → ~80 行）

**页面级改（5 个 feature）**：
- `lib/presentation/pages/home/*`（改 widget 集成）
- `lib/presentation/pages/setup/*`（改 4 步视觉）
- `lib/presentation/pages/medication/*`（改 tile + section）
- `lib/presentation/pages/trend/*`（改 section 集成）
- `lib/presentation/pages/mood/*` + `mood_list/*`（改 mood button）

**Token 应用层（5 个 feature 自动化）**：
- `lib/presentation/pages/vent/*`（走 token 自动升级）
- `lib/presentation/pages/assessment/*`（走 token）
- `lib/presentation/pages/check_in/*`（走 token）
- `lib/presentation/pages/contact/*`（走 token）
- `lib/presentation/pages/settings/*`（走 token）
- `lib/presentation/pages/daily_tracking/*`（走 token）

**测试**：
- 新增 5+ widget golden test
- 新增 1+ spring motion test
- 新增 1+ 彩色 tile test
- 修复 token 改后 fail 的现有 test（预计 5-10 个）

---

## 11. 时间估算

| Phase | 内容 | 估时 | 并行度 |
|---|---|---|---|
| Phase 1 | Token 重定义 | 4-6h | 1 subagent |
| Phase 2 | 5 widget 重写 + 3 widget 新增 | 6-8h | 4 subagent 并行 |
| Phase 3 | 3 核心页重设 | 6-8h | 3 subagent 并行 |
| Phase 4 | 5 中等页 follow + 清理 | 4-5h | 1 subagent |
| Phase 5 | 验证 + 守门员 + 截图 | 2-3h | 1 reviewer |
| **总计** | | **22-30h** | 5 phase 流水 |

按 subagent-driven 模式，实际时间 ≈ 1-2 周（跨多 session）。
