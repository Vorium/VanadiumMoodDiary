# 慢病管家 ChronicCare · 白皮书

> 写给团队（PM / Dev / Designer / QA / 后续接手者）的一站式项目档案。
> 最后更新：2026-07-17（v0.17 round 7 后）

---

## 📌 0. 文档地图（按角色查）

| 角色 | 重点章节 |
|---|---|
| **项目经理（PM）** | §1 愿景 · §3 商业模式 · §13 路线图 · §14 团队分工 · §15 风险 |
| **前端/客户端开发（Dev）** | §5 技术栈 · §6 架构 · §7 数据模型 · §8 业务流程 · §10 通知系统 · §11 树洞 · §12 设计系统 · §17 已知坑 |
| **设计师（Designer）** | §1 愿景 · §2 用户 · §12 设计系统 · §11 树洞（独立风格） |
| **QA / 测试** | §9 测试策略 · §10 通知系统（重点 OEM 引导） · §17 已知坑 |
| **新接手者** | 先读 §0 文档地图，再按需跳读 |

---

## 1. 愿景与定位

**一句话**：让精神心理疾病患者 **少一次"今天吃没吃药"的焦虑**。

**为什么做**：
- 慢性病（抑郁、焦虑、双相、精神分裂）患者需 **多年甚至终身** 规律服药
- 漏服 1-2 次即可导致病情波动（抑郁复发、双相转相、停药综合征）
- 现有工具：医院公众号、闹钟、健康 App — 都不针对"长期规律吃药 + 失联兜底" 这个具体场景
- 参考"死了么"（极简 + 失联兜底）模式，做精神心理患者专版

**差异化**：
- **零云端**：所有数据本地 SQLCipher 加密，连不上网也能用
- **失联兜底**：48h 未打卡自动通知紧急联系人（不是"快不行了"措辞，是"请你方便时提醒我"）
- **私密倾诉（树洞）**：完全独立模块，不进任何分析 / 通知 / 报告

---

## 2. 目标用户

| 维度 | 描述 |
|---|---|
| **人群** | 精神心理疾病患者（抑郁、焦虑、双相、精神分裂、PTSD） |
| **年龄** | 18-45 岁为主，能用智能手机 |
| **服药状态** | 已确诊 6+ 个月、稳定服药方案 1 种以上 |
| **痛点** | 健忘 / 状态差时漏服 / 没人提醒 / 怕副作用擅自停 |
| **付费意愿** | 8 元一次性买断，不订阅（参考"死了么"） |
| **数量级** | 中国 2.3 亿精神心理疾病患者（卫健委 2023），但目标人群要 "确诊 + 稳定 + 智能手机"，实际 TAM 估 200-500 万 |

**不服务的人**（明确边界）：
- 急性发作期（需要医生干预，不是工具的事）
- 不愿用 App 的（不强求）

---

## 3. 商业模式

**当前（v0.17）**：
- **8 元付费下载**（Google Play + App Store）
- 一次性买断，无内购，无订阅

**未来（v1.0+）**：
- 医生版（订阅制）：医生看患者依从性
- 加密备份（订阅制）：跨设备同步
- 暂不接广告 — 数据敏感 + 用户脆弱

---

## 4. 核心机制（3 个）

### 4.1 每日打卡
- 主页 1 个大按钮：「我今天吃了药」
- 点完：haptic 反馈 + 庆祝动画 + streak +1
- 状态记忆：当天已打卡 → 按钮变 "✓ 已完成"

### 4.2 多药物管理
- 首次引导 step 2：设置药物（名称 / 剂量 / 每天时间点）
- 多个 time 点 → 每天 N 次精准推送
- 临时吃药（"今晚加了 1 次"）→ 关联到现有药物，自由输入

### 4.3 失联兜底
- 漏 2 天（48h）未打卡 → 自动 SMS 通知紧急联系人
- **措辞刻意温和**：「请你方便的时候提醒我按时吃药」而非「快不行了」
- 多联系人按 sortOrder 顺序发送，全部失败才放弃

---

## 5. 技术栈

| 组件 | 版本 | 选型理由 |
|---|---|---|
| **Flutter** | 3.44.5 stable | 跨 iOS/Android/未来 watch，UI 性能优 |
| **Dart** | 3.12.2 | Flutter 内置 |
| **状态管理** | flutter_riverpod 3.3.2 | compile-time 安全 + autoDispose + Provider 测试覆盖好 |
| **本地数据库** | drift 2.20.3 | 类型安全 + SQL 表达力 + SQLCipher 加密好接入 |
| **数据库加密** | sqlcipher_flutter_libs 0.6.4 | 行业标准加密 SQLite |
| **路由** | go_router 14.6.1 | 声明式 + 深链 + ShellRoute 适配底部导航 |
| **图表** | fl_chart 0.69 | 纯 Dart，性能好 |
| **本地通知** | flutter_local_notifications 17.2.3 | 跨平台时区感知 |
| **PDF 报告** | pdf 3.11 + printing 5.13 | 离线生成 PDF |
| **加密** | flutter_secure_storage + encrypt (AES-256) | iOS Keychain / Android Keystore + 自定义加密 |
| **录音** | record 5.2.0 + audioplayers 6.1.0 | 树洞语音用 |
| **国产 ROM 兼容** | permission_handler 11.3.1 | 通知 / 电池优化权限 |

---

## 6. 架构

### 6.1 4 层架构 + 共享层（**当前**）

```
lib/
├── main.dart              # 入口（含通知 init / DB key 解锁）
├── app.dart               # App 根 + ProviderScope + 跨 midnight refresh
├── routing/               # go_router 配置（ShellRoute 底部导航）
├── theme/                 # 设计 Token (AppTokens) + Material 3 主题
├── l10n/                  # 静态 Strings（暂未上 flutter_localizations）
├── data/                  # 基础设施层
│   ├── database/         # Drift 表 + 数据库 + mapper
│   ├── repositories/     # 仓库实现（*_repository_impl.dart）
│   └── services/         # 通知/邮件/SMS/PDF/录音/导出
├── domain/                # 领域层（**0 Flutter / 0 Drift / 0 data 依赖**）
│   ├── entities/         # 业务实体（*Entity 后缀）
│   ├── logic/            # 业务规则（量表/streak/care engine/报告）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例（业务编排）
├── shared/                # 共享层：3 层都能用的横切层
│   ├── formatters.dart   # 日期/时间格式化
│   ├── json_codec.dart   # JSON 编解码
│   ├── domain_value.dart # DomainValue<T>（替代 drift Value<T>）
│   └── mood_visual.dart  # 情绪分数 → emoji/label/ARGB int
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers
    ├── pages/             # 1 个目录 = 1 个页面（home/setup/settings/...）
    └── widgets/           # 通用组件（*_button.dart / page_scaffold.dart）
```

**依赖方向（强制）**：
- `presentation → domain ← data`（domain 是接口所有者）
- `shared` 被 3 层都能用（但被 check_all 监测：只被 1 层用 = 移走）

### 6.2 架构检查（CI 友好）

```bash
dart scripts/check_all.dart   # 一次出 2 份报告
```

输出：
- **[1/2] 4 层架构纯度**：domain 0 flutter / 0 drift / 0 data / 0 presentation
- **[2/2] 架构语义一致性**：domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应 + shared 工具使用度

违规时 exit 1，CI 会 fail。

**注**：`dart run` 在本项目会触发 `objective_c` build hook 失败，用 `dart` 直接跑。

### 6.3 feature-first 重构（**v0.17 round 8 进行中**）

**目标**：把 layer-first 改成 feature-first，让每个 feature 自洽。

**新结构**：
```
lib/
├── main.dart
├── app.dart
├── core/                  # 跨 feature 共享（v0.17 round 8 已建）
│   ├── database/         # ← lib/data/database/
│   ├── theme/            # ← lib/theme/
│   ├── l10n/             # ← lib/l10n/
│   ├── shared/           # ← lib/shared/
│   ├── routing/          # ← lib/routing/
│   └── services/         # 跨 feature service（notification/email/crypto）
└── features/             # 8 个 feature（待切）
    ├── home/
    │   ├── data/         # 仓库实现 + drift table + mapper
    │   ├── domain/       # entity + repository abstract + usecase
    │   └── presentation/ # page + widget + provider
    ├── setup/
    ├── settings/
    ├── trend/
    ├── assessment/
    ├── medication/
    ├── vent/
    └── check_in/
```

**跨 feature 共享规则**：
- 跨 feature 的 entity（如 `MedicationEntity` 被 check_in / medication / trend 复用）→ 放 owner feature，其他 feature 调 owner 的 public API
- 跨 feature 的 service → 放 `core/services/`
- 4 层纯度检查**仍然生效**（feature 内仍 3 层 + 跨 feature 不允许 cyclic）

**当前状态**：
- 8a ✅ 共享层（database / theme / l10n / shared / routing）移到 `lib/core/`
- 8b ⏳ 8 个 feature 切分（home / setup / settings / trend / assessment / medication / vent / check_in）— 进程到一半重置回 4 层架构（**见 §13 路线图**）
- 8c ⏳ check_all 脚本重写（监测 `core/` + `features/`）

---

## 7. 数据模型

### 7.1 Drift 7 表

| 表 | 用途 | 关键字段 |
|---|---|---|
| `user_profiles` | 用户档案 | name, created_at, language |
| `medications` | 药物 | name, dosage, times (JSON 数组), start_date, end_date, refill_date, refill_remind_days |
| `check_ins` | 每日打卡 | timestamp, mood_score (1-10), note, sleep_hours, exercise_minutes |
| `mood_entries` | 情绪日记 | timestamp, score (1-10), note, factors (JSON) |
| `contacts` | 紧急联系人 | name, phone, email, sort_order, is_archived |
| `vent_entries` | 树洞 | timestamp, text, audio_path, audio_duration_ms, content_type |
| `report_histories` | 报告历史 | generated_at, type, file_path, parameters (JSON) |
| `assessments` (在 check_ins) | 心理评估（PHQ-9 / GAD-7）| type, answers (JSON), total_score, severity |

**schema 当前 version 6**（v0.15 树洞新增 vent_entries = 6，v5→6 迁移已实现）

### 7.2 Domain Entity 命名

- `UserProfileEntity`、`MedicationEntity`、`CheckInEntity`、`MoodEntryEntity`、`ContactEntity`、`VentEntryEntity`
- **`Entity` 后缀强制**：避免跟 drift `@DataClassName('X')` 冲突

### 7.3 数据流

```
[Presentation] ── ref.read(provider) ──> [Repository] ── watch / insert / delete ──> [Drift]
        ▲                                                                       │
        │                                                                       │
        └────────────── Stream<*> ◀── watchAll / getById ◀─────────────────────┘
```

---

## 8. 业务流程

### 8.1 首次引导（setup）
1. 欢迎页 + 隐私说明
2. 个人信息（姓名 + 紧急联系人）
3. 药物设置（名称 + 剂量 + 时间点，可多选预设模板）
4. 评估建议（PHQ-9 baseline，可跳过）
5. 通知权限申请 + 引导到系统设置

### 8.2 每日打卡（check_in）
1. 用户点「我今天吃了药」按钮
2. 写 `CheckInEntity(useCase: RecordCheckInUseCase)`
3. 写 DB → 触发 `streakSummaryProvider` 自动重算
4. UI 显示庆祝动画 + 鼓励文案（按 streak 天数切换）

### 8.3 CareEngine 规则引擎
**4 种触发规则**（每天 0:00 跑一次）：

| 规则 | 触发条件 | 动作 |
|---|---|---|
| `secondDayMissed` | 昨天 + 今天都没打卡 | 邮件给联系人 |
| `lateCheckInHabit` | 最近 7 天有 3 天 18:00 后才打卡 | 调整推送时间更早 |
| `weekPerfect` | 连续 7 天按时打卡 | 周日庆祝推送 |
| `none` | 规则不匹配 | 静默 |

`shouldFire()` 3 态：false 不调 / true 调 `showNow` / 抛异常被 try/catch 包。

### 8.4 失联通知
- 每天 check 时：计算自上次打卡距今小时数
- 超过 48h → 走多联系人循环（按 sortOrder），每个发 SMS
- **措辞固定模板**（"请你方便的时候提醒我按时吃药"），不暴露病情 / 不渲染病情

### 8.5 跨 midnight streak 刷新
- 主页 `streakSummaryProvider` 跨 23:59:59 后不自动失效
- AppRoot 挂 midnight timer，**00:00:05 自动 `ref.invalidate(streakSummaryProvider)`**
- `nextMidnightRefresh(now)` 抽 top-level 纯函数（跨月/跨年/buffer 5s 防 race）

---

## 9. 测试策略

### 9.1 三层测试

| 层 | 类型 | 工具 | 速度 | 覆盖目标 |
|---|---|---|---|---|
| **domain** | 纯 Dart 单测 | `test/domain/*` | ⚡⚡⚡ < 1s | 90%+ |
| **data** | Drift round-trip | `test/data/*` | ⚡⚡ ~5s | 80%+ |
| **presentation** | widget test | `test/presentation/*` | ⚡ ~20s | 70%+ |

**当前**：528 cases pass（v0.17 round 7）

### 9.2 测试覆盖分布

| 模块 | 覆盖 | 备注 |
|---|---|---|
| domain entities | 100% | 业务方法 + 边界 |
| domain logic | 90%+ | streak_calculator / care_engine / scale / medication_report |
| data repositories | 80%+ | round-trip + 边界 |
| presentation widget | 70%+ | 主要页面 + 交互 |
| **safety_watch / care_engine / schedule service 单独** | 偏低 ⚠️ | 后续 round 9 补 |

### 9.3 TDD 纪律

- v0.16 几轮 bug 修都是"先发现 → 再写 test"，**不是红灯先行**
- v0.17 round 7 B4 demo：先写 `calendar_window_provider_test.dart` 引导 `CalendarWindowNotifier` 实现
- **下次新功能试试先写 test**（C1/C3/B2 候选场景）

---

## 10. 通知与提醒系统

### 10.1 通知 id 分段

| 段 | 用途 | 公式 | cancel 范围 |
|---|---|---|---|
| 1001 | 每天 20:00 通用打卡提醒 | 固定 | 单 id |
| 2000+ | 药物时间点 | `2000 + medId * 10 + timeIdx` | `[2000, 202000)` |
| 3000 | 10am 软提醒 | 固定 | 单 id |
| 4000+ | CareEngine 关怀 | `4000 + ruleIdx` | `[4000, 202000)` |
| 5000+ | 续方 | `5000 + medId` | `[5000, 202000)` |
| 6000+ | 续方提醒（v0.19B） | `6000 + medId` | `[6000, 202000)` |
| 99001 | 测试通知 | 固定 | 单 id |

**统一 cancel range 200000**：covers medId 几万个，远超实际用户量。

### 10.2 国产 ROM 静默杀后台通知

**问题**：小米 / 华为 / OPPO / Vivo / 魅族 默认禁止 App 后台运行 + 自启动 + 精确闹钟。

**用户报"到点没收到提醒"99% 是这个原因。**

**修法**（v0.16 round 20）：
- 设置页加 `NotificationStatusCard` 自检卡
  - 状态显示：当前已排队的待发通知数（0 / N / 不支持三态）
  - **测试通知按钮**：点一下立即推一条
  - **查看已排队通知**：弹 dialog 列出所有 `pendingNotificationRequests` 标题
  - **国产手机后台引导**：折叠面板展开 5 大品牌每家 2-3 步
  - `kIsWeb` fallback：web 端显示"通知功能仅在 Android/iOS 可用"

**debug 误区**：不要靠 `developer.log` 排查（用户看不到），先检查自检卡 pendingCount。

---

## 11. 树洞（Vent / 私密倾诉空间）

**v0.15 round 18 上线**。**完全独立模块**。

### 11.1 隐私边界（**强制**）

| 模块 | 允许 | 禁止 |
|---|---|---|
| 树洞 | 无 | 趋势 / 评估 / CareEngine / SafetyWatch / 通知 / 关怀 |

**如果发现树洞内容进了趋势页 = bug，立即修。**

### 11.2 设计原则

- 文字 / 语音 / 混排三种记录形式
- 录音用 `record` 5.2.0，播放用 `audioplayers` 6.8.1
- audio 文件存 `app docs/vent_audio/`（DB 路径引用，DB 整体 SQLCipher 加密）
- 主页加"倾诉 🌲"入口按钮
- 列表 + 长按删除；详情 + 进度条

**为什么独立**：保护"私密空间"信任 → 即使内容含"想死"也不通知家人。

### 11.3 命名

- domain entity: `VentEntryEntity`
- drift table: `@DataClassName('VentEntry')` (避免冲突)

---

## 12. 设计系统

### 12.1 设计 Token（`lib/theme/app_tokens.dart`）

| 类别 | token | 例子 |
|---|---|---|
| spacing | `spaceXs` / `spaceSm` / `spaceMd` / `spaceLg` / `spaceXl` | 4 / 8 / 12 / 16 / 24 |
| radius | `radiusSm` / `radiusMd` / `radiusLg` | 4 / 8 / 12 |
| fontSize | `fontSizeCaption` / `body` / `title` / `display` | 12 / 14 / 18 / 24 |
| color | `warning` / `warningStrong` / `success` / `error` | ARGB int |
| duration | `durFast` / `durNormal` / `durSlow` | 100 / 200 / 300 ms |
| **curve**（v0.17 round 1）| `curveStandard` / `curveDecelerate` / `curveAccelerate` / `curveDelight` | easeOutCubic / easeOutQuart / easeInCubic / elasticOut |
| breakpoint | `wideScreenMinWidth` | 720 |

### 12.2 emil 动效频度决策框架

| 频度 | 例子 | 动效 |
|---|---|---|
| **100+/day** | 键盘快捷键、命令面板、核心导航 | **无动画**（Raycast 没 open/close） |
| **Tens/day** | hover 状态、列表导航、频繁 toggle | 微弱（fast + subtle） |
| **Occasional** | modal、drawer、toast、settings | 标准（标准 duration + curveStandard） |
| **Rare / 首次** | onboarding、空状态、success、celebration | 可加 delight（curveDelight） |

**哲学**：高频交互 → 无动画；低频 + 高情绪 → 可以加 delight。

### 12.3 路由转场（v0.17 round 2）

| 类型 | 用法 | 时长 |
|---|---|---|
| `_fadePage` | 主导航（/, /settings） | durNormal |
| `_slideRightPage` | 子页（/settings/reminders） | durNormal |
| `_slideUpPage` | 全屏深页（/setup） | durSlow |

### 12.4 设计原则

- **Material 3** + `InkSparkle.splashFactory`（v0.17 round 7 A5）
- **温柔色调**：避免高饱和 / 红绿对比，适配抑郁/焦虑用户敏感
- **大字体**：body 14-16 sp（默认 Material 太小）
- **haptic 反馈**：打卡完成、删除等关键操作
- **庆祝克制**：streak 数字用 `TweenAnimationBuilder` 0→N 慢慢增长，不用粒子效果

---

## 13. 路线图（Roadmap）

### 13.1 当前进度

| 版本 | round | 内容 | 状态 |
|---|---|---|---|
| v0.5 | 1-2 | 极简 MVP（主页打卡 + 设置 + 引导） | ✅ |
| v0.6 | - | 多联系人邮件 + 失联检测 v0 | ✅ |
| v0.7 | - | SMS 抽象 + CareEngine + 10 规则 | ✅ |
| v0.8 | - | PHQ-9 + 量表历史 + Web 加载 | ✅ |
| v0.12 | - | 邮件/SMS 通知 + 趋势页 + 临时吃药 | ✅ |
| v0.13 | - | 多档案 + 续方提前 + 评估历史 sparkline | ✅ |
| v0.14 | - | 续方管理 + 评估历史独立页 + 用药日历 + 提醒中心 | ✅ |
| v0.15 | round 18 | 树洞（完全独立） | ✅ |
| v0.16 | round 1-20 | 4 层架构 + 5 轮 code review + 9 个 gotcha fix + 通知自检 | ✅ |
| v0.17 | round 1-7 | emil 动效 + Riverpod 3.0 升级 + 跨 midnight + 7 项 process 改进 | ✅ |

**当前**：v0.17 round 7 已 commit，528 test pass，4 个 info-level `prefer_const_constructors` 待清。

### 13.2 下一步（v0.17 round 8+）

| 优先级 | 项 | 描述 | 工作量 |
|---|---|---|---|
| 🔴 P0 | **Feature-first 重构（8b）** | 把 layer-first 切到 feature-first（8 个 feature） | 大（3-5 commit） |
| 🔴 P0 | **check_all 脚本重写（8c）** | 监测 `core/` + `features/` 新结构 | 中（1 commit） |
| 🟡 P1 | **C1 自动 retry + 指数退避** | DB / notification 失败自动重试 | 中（1 commit） |
| 🟡 P1 | **C3 Stream `==` 过滤** | 之前是 `identical`，减少重复 rebuild | 小（1 commit） |
| 🟢 P2 | **B2 拆 Notifier** | setup 22 处 setState + medication_calendar / vent 拆 Notifier | 中（1-2 commit） |
| 🟢 P2 | **B3 ConsumerStatefulWidget → ConsumerWidget** | 9 个 widget 状态提到 provider | 中（1-2 commit） |
| 🟢 P2 | **升 Drift 2.20.3 → 2.34.2** | drift 实际没 3.x，最新 2.34.2。**注**：drift_dev 2.34.0 跟 sqlparser 0.44.6 撤回冲突，需 pin `sqlparser: 0.44.5` 在 `pubspec_overrides.yaml` | 小（1 commit） |
| 🟢 P2 | **docs sync** | CHANGELOG + AGENTS.md + Memory 同步 v0.17 round 8 | 小（1 commit） |
| ⚪ P3 | B5 测试覆盖补 | safety_watch / care_engine / schedule service 单独补 | 中 |
| ⚪ P3 | C4 统一 Notifier API | 项目 0 个用到，skip | - |

### 13.3 远期（v1.0+）

- 加密云端备份（订阅制）
- 医生版（订阅制）
- Apple Watch 伴侣 App
- i18n 英文版（出海）
- 接入国家心理援助热线（替代 mock）

---

## 14. 团队分工建议

### 14.1 角色 + 职责

| 角色 | 主要职责 | 不应做 |
|---|---|---|
| **PM** | 路线图优先级、用户访谈、A/B test 决策、版本发布节奏 | 不写代码、不直接改 AGENTS.md |
| **产品设计（Designer）** | 视觉稿、动效、design token、文案、A/B test 变体 | 不写业务逻辑代码 |
| **iOS / Android Dev** | feature 实现、bug 修、单元测试、性能 | 不改 SQL schema（要 PR review） |
| **架构师** | 4 层架构纯度、check_all 脚本、Riverpod 模式、Drift 升级 | 不写 UI |
| **QA** | 黑盒测试、国产 ROM 兼容性、用户场景复现 | 不写 production 代码（可写 test） |
| **DevOps** | CI/CD、构建、发布、监控、Sentry 等价物 | 不改业务代码 |

### 14.2 当前最小团队配置

- **1 PM**（兼产品 / 用户访谈）
- **1 Designer**（兼动效 / 文案）
- **1 全栈 Dev**（Flutter 全栈 + 简单 DevOps）
- **1 QA**（兼职 / 后续轮次扩）

### 14.3 沟通规范

- **commit message 用纯英文**（PowerShell 路径解析限制，中文标点会被吞）
- AGENTS.md 给 AI Agent 看（不是人看，但人是 source of truth）
- CHANGELOG 跟代码同步更新（每个 commit 前 / 后）

---

## 15. 风险与缓解

| 风险 | 影响 | 缓解 |
|---|---|---|
| 国产 ROM 静默杀通知 | 用户收不到提醒 | NotificationStatusCard 自检 + OEM 引导 |
| 隐私泄露 | 患者敏感数据 | SQLCipher + 零云端 + 树洞独立 |
| 自伤内容被 CareEngine 误触发 | 通知家人造成二次伤害 | CareEngine 不知道树洞（隐私边界） |
| 漏服失联 | 病情波动 | 48h 兜底 + 措辞温和 |
| 患者擅自停药 | 停药综合征 | 用药教育 + 续方提醒（不强制） |
| Drift 升级断路 | 不能跟上游 | 锁 `pubspec_overrides.yaml` 临时绕道（v0.17 round 8 已 pin sqlparser 0.44.5） |
| 单 Dev 单点 | 关键人风险 | 文档化（AGENTS.md / WHITEPAPER.md）+ TDD（v0.17 round 7 B4） |

---

## 16. CI/CD

### 16.1 本地验证

```bash
flutter analyze    # 必须 0 error / 0 warning（info-level 可）
flutter test       # 必须 528 cases 全过
dart scripts/check_all.dart  # 4 层架构纯度 + 一致性
```

### 16.2 打包

```bash
# Web
flutter build web
python -m http.server 8358   # dev server（drift worker 404 → production 模式）

# Android APK
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk

# iOS
flutter build ios --release
# 输出：ios/Runner.xcarchive
```

### 16.3 部署目标

- **Web**：PWA + 静态托管
- **Android**：Google Play + 国产应用市场（华为 / 小米 / OPPO / Vivo / 魅族）
- **iOS**：App Store

---

## 17. 已知坑（Gotchas — 必读）

> 这些是 v0.16 - v0.17 期间踩过的坑，新人先看这一节。

| # | 坑 | 原因 | 修法 |
|---|---|---|---|
| 1 | `flutter_secure_storage` Android 首次启动 ~200ms 延迟 | 设备 Keystore 启动慢 | 提前 init + Loading state |
| 2 | Drift schema 升级漏 migration | `app_database.dart` schemaVersion++ 但忘加 `onUpgrade` | PR review + 必看 migration 段 |
| 3 | `VentEntryEntity` vs `VentEntry` 命名冲突 | domain entity vs drift @DataClassName | domain 强制 `*Entity` 后缀 |
| 4 | `audioplayers + record` 一起用文件锁冲突 | 同进程两个 handle | recorder 先 dispose 再 player |
| 5 | `Stream subscription leak` | `_player.onXxx.listen()` 没存 subscription | 存字段 + dispose 时 cancel |
| 6 | `BuildContext` 跨 async gap 警告 | analyzer `use_build_context_synchronously` | mounted check 或 `this.context` |
| 7 | `DateTime.now()` 多次 race | 跨 midnight 边界日期不一致 | 函数入口 `final now = DateTime.now();` 一次 |
| 8 | **Notification id cancel range 公式不匹配** | 之前 1000/100000 范围太窄 | 统一 200000 + id 公式要对应 |
| 9 | **Filename collision** | 同毫秒内 2 个文件覆盖 | timestamp + 4 位 random suffix |
| 10 | `setState` after defunct | listener 内调 setState + State dispose 后触发 | listener 内 `if (!mounted) return;` guard |
| 11 | **Resource acquire/release** 必须 try/finally | try 块内 acquire 资源 + dispose 一气呵成，异常时 dispose 不跑 | `final x = ...; try { use } finally { x.dispose(); }` |
| 12 | **`.first` / `.last` 隐式排序假设** | 依赖 drift orderBy 隐式顺序，future caller 传 unsorted 数据会算错 | 函数内部显式 sort + unsorted input regression test |
| 13 | **GoRouter path param unsafe parse** | `int.parse` 抛 FormatException → app 崩 | `int.tryParse(...) ?? 0` |
| 14 | **国产 ROM 静默杀后台通知** | 小米/华为/OPPO/Vivo/魅族默认禁止后台 + 自启动 | NotificationStatusCard 自检 + OEM 引导 |
| 15 | **Riverpod 3.x `valueOrNull` → `value`** | 2.6 的 `AsyncValue.valueOrNull` 在 3.x 改名 | 全局搜索 `valueOrNull` 替换 |
| 16 | **Riverpod 3.x `ref.mounted` 仅限 Notifier** | Provider/StreamProvider/ConsumerStatefulWidget 不能用 | 保持 `!mounted` check（项目 27 处） |
| 17 | **Drift sqlparser 0.44.6 撤回** | 0.44.6 被作者撤回，build_runner AOT kernel 编译失败 | `pubspec_overrides.yaml` pin `sqlparser: 0.44.5` |
| 18 | **跨 midnight streak 不刷新** | streakSummaryProvider 自身没监听时间变化 | AppRoot 挂 midnight timer + `nextMidnightRefresh` 纯函数 |
| 19 | **emil 动效 token 缺 curve** | 之前 app_tokens.dart 只有 dur* 缺 curve | 4 个 curve token + emil 决策框架 doc 注释 |
| 20 | **go_router 默认无 page transition** | GoRoute.builder 默认切换无动画 | `pageBuilder` + `CustomTransitionPage`（3 类 transition） |
| 21 | **Flutter widget test ink_sparkle shader 缺失** | Material 3 InkWell 需要 `shaders/ink_sparkle.frag` | 从 SDK 复制到 `assets/shaders/` + `pubspec.yaml: shaders:` 字段 |

完整 gotcha 索引见 `AGENTS.md` "已知坑"段。

---

## 18. 决策记录（Decision Log）

| 决策 | 原因 |
|---|---|
| 4 层架构 | domain 易测试 + 易复用 + 0 Flutter 依赖 |
| SQLCipher + 零云端 | 精神心理患者数据敏感 |
| 树洞独立表 | 隐私边界：绝对不进任何分析 / 通知 / 关怀 |
| Audio 存本地文件 | DB 体积不能爆炸，文件用路径引用 |
| `ProviderScope` overrides 测试 | 真实 DB 测试太慢，in-memory + override 足够覆盖 |
| 主页底部按钮加"倾诉" | 用户主要路径 = 打卡 / 设置 / 倾诉 3 个核心动作 |
| `RadioListTile` → `RadioGroup`（Flutter 3.32+） | 弃用警告 |
| `try/finally` 资源释放 | 异常路径也要 release |
| `int.tryParse` 替代 `int.parse` | GoRouter 路径参数 fallback |
| `reduce(isAfter)` 替代 `.last` | 不依赖 list 顺序 |
| commit message 用纯英文 | PowerShell 路径解析限制 |
| 8 元一次性买断，无订阅 | 用户人群 + 商业模式 |
| emil 动效频度决策 | 100+/day 无，tens 微，occasional 标准，rare 可 delight |
| **feature-first 重构（v0.17 round 8）** | 拆 lib/ 按 feature，让每个 feature 自洽 |

---

## 19. 附录

### 19.1 关键文档

- `README.md` — 项目简介（公开版）
- `AGENTS.md` — AI Agent 视角的项目指引（私有）
- `docs/CHANGELOG.md` — 版本变更（Keep a Changelog 格式）
- `docs/DEPLOYMENT.md` — 部署相关
- `docs/SENDGRID_SETUP.md` — 邮件服务配置
- `docs/WHITEPAPER.md` — **本文档**（团队一站式档案）

### 19.2 关键脚本

- `scripts/check_all.dart` — 4 层架构纯度 + 一致性
- `scripts/test_delivery_rate.dart` — 通知送达率测试
- `scripts/8a2_rewrite_to_absolute.py` — 把所有相对 import 转 package: 绝对路径（v0.17 round 8）
- `scripts/8a_rewrite_imports.py` — 旧版本（v0.17 round 8 初期，已被 8a2 替代）

### 19.3 关键命令

```bash
# 跑
flutter run -d <device>

# 监听代码生成
dart run build_runner watch --delete-conflicting-outputs

# 单文件测试
flutter test test/domain/streak_calculator_test.dart

# 4 层架构检查
dart scripts/check_all.dart

# 解决 Drift sqlparser 撤回
# 已在 pubspec_overrides.yaml pin sqlparser: 0.44.5，dart pub get 自动应用
```

### 19.4 关键文件路径

| 文件 | 用途 |
|---|---|
| `lib/main.dart` | 启动顺序、SQLCipher 初始化、通知 init |
| `lib/data/database/app_database.dart` | schemaVersion 6，所有表 + migration |
| `lib/domain/logic/care_engine.dart` | 失联检测 / 续方 / 通知触发核心规则 |
| `lib/presentation/providers/core_providers.dart` | 全局 provider 注册表 |
| `lib/routing/app_router.dart` | 所有页面路由 + shell (NavigationRail) |
| `lib/data/services/notification_service.dart` | 通知 id 公式 + cancel range + 自检卡依赖 |
| `lib/theme/app_tokens.dart` | 设计 Token（spacing/radius/fontSize/color/duration/curve/breakpoint） |

### 19.5 紧急联系方式（产品设计）

- **北京心理危机研究与干预中心**：010-82951332
- **全国心理援助热线**：400-161-9995
- **生命热线**：400-821-1215

---

## 文档维护

- **owner**：当前主开发者（详细见 git log 活跃 commit 作者）
- **更新时机**：每个 round commit 后 / 每个版本发布前
- **下次 review**：v0.17 round 8 完成时（feature-first 重构 + check_all 重写）
