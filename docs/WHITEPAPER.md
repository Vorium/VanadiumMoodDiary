# 慢病管家 ChronicCare · 白皮书

> **⚠️ Legacy 标注 (v1.1.0)**: 历史存档文档 — CHANGELOG 1.0.0+147 已声明
> WHITEPAPER 不动, 内容停留在 v0.22 时代, 失联兜底/紧急联系人/邮件 等
> 描述已于 v1.1.0 删除的业务不再反映当前产品状态。

> 写给团队（PM / Dev / Designer / QA / 后续接手者）的一站式项目档案。
> 最后更新：2026-07-20（v0.22 round 28 后 — spzh 报告 §4.3 同步重写）

---

## 📌 0. 文档地图（按角色查）

| 角色 | 重点章节 |
|---|---|
| **项目经理（PM）** | §1 愿景 · §3 商业模式 · §13 路线图 · §14 团队分工 · §15 风险 |
| **前端/客户端开发（Dev）** | §5 技术栈 · §6 架构 · §7 数据模型 · §8 业务流程 · §10 通知系统 · §11 树洞 · §12 设计系统 · §17 已知坑 |
| **设计师（Designer）** | §1 愿景 · §2 用户 · §12 设计系统 · §11 树洞（独立风格） |
| **QA / 测试** | §9 测试策略 · §10 通知系统（重点 OEM 引导） · §17 已知坑 |
| **新接手者** | 先读 §0 文档地图，再按需跳读；**关键路径在 §19.4**（已按 v0.18 后 5 层 umbrella 修正） |

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

> 当前快照（`pubspec.yaml` 实际版本，v0.22 round 28 后对齐）。

| 组件 | 版本 | 选型理由 |
|---|---|---|
| **Flutter** | 3.41.9 stable | 跨 iOS/Android/Web，UI 性能优；pubspec 约束 `>=3.41.0` |
| **Dart** | 3.12.2 | Flutter 内置 |
| **状态管理** | flutter_riverpod 3.3.2 | compile-time 安全 + `valueOrNull` → `value`（v0.17 升 3.x）；`ref.mounted` 仅 Notifier 限制（项目 27 处 `!mounted` 保持） |
| **本地数据库** | drift 2.20.3 | 类型安全 + SQL 表达力 + SQLCipher 加密好接入；**schemaVersion 当前 11**（v0.18→v0.21 三步迁移） |
| **数据库加密** | sqlcipher_flutter_libs 0.6.4 | 行业标准加密 SQLite |
| **路由** | go_router 14.6.1 | 声明式 + 深链 + `pageBuilder` + `CustomTransitionPage`（v0.17 round 2 加 3 类 transition） |
| **图表** | fl_chart 0.69 | 纯 Dart，性能好 |
| **本地通知** | flutter_local_notifications 17.2.3 + flutter_timezone 3.0.1 | 跨平台时区感知 + `zonedSchedule` |
| **PDF 报告** | pdf 3.11 + printing 5.13 | 离线生成 PDF |
| **加密** | flutter_secure_storage 9.2.2 + **pointycastle 3.9.1**（AES-256） | iOS Keychain / Android Keystore + 自定义加密；**v0.20 已从 `encrypt` 迁 `pointycastle`**（`97476d5`，加密 blob 格式不变，老数据可正常解密） |
| **录音 / 播放** | record 5.2.0 + audioplayers 6.1.0 | 树洞 audio 用；树洞录音额外 AES-256 加密存盘（v0.18 P0-2 `4f2f196`） |
| **国产 ROM 兼容** | permission_handler 11.3.1 | 通知 / 电池优化权限 |
| **国际化** | intl 0.20.2 + flutter_localizations（arb） | 中英 ARB 各 108+ keys；~125 个硬编码中文抽到 ARB（v0.21 round 21） |
| **工具** | uuid 4.5.1 / flutter_dotenv 6.0.1 / share_plus 10.1.4 / shared_preferences 2.3.3 | id 生成 / env 加载 / 分享 / 偏好 |
| **代码生成** | build_runner 2.4.13 + drift_dev 2.20.3 | drift 注解处理 |

**依赖健康度（v0.18-v0.22 治理）**：
- ✅ 删 `freezed` / `json_serializable`（实测 0 引用，v0.19 round 19 净）
- ✅ `encrypt` → `pointycastle`（encrypt 2022 停维 4 年，pointycastle 持续维护，v0.20 round 20 净）
- ✅ 删 `dio`（v0.16 round 19 净，EmailService 0 引用）

---

## 6. 架构

### 6.1 5 层 umbrella + 4 层依赖（**当前 — v0.18 落地**）

> **v0.18 (round 12 起)**：`data/shared/theme/routing/l10n` 5 个子层并入 `lib/core/`
> 作为 umbrella。所以实际是 **5 层 + 共享 umbrella**:
> - `lib/core/data/` — 基础设施(Database / Repositories / Services / Utils)
> - `lib/core/shared/` — 跨层共享(formatters / json_codec / mood_visual)
> - `lib/core/theme/` — AppTokens + M3 主题 + dark mode
> - `lib/core/routing/` — go_router
> - `lib/core/l10n/` — domain 层 strings(供通知/邮件用)
> - `lib/l10n/` — presentation 层 flutter_localizations(供 UI 用)
> - `lib/domain/` — 0 Flutter 0 Drift 业务层
> - `lib/presentation/` — UI 层

```
lib/
├── main.dart              # 入口（启动顺序 + SQLCipher + 通知 init）
├── app.dart               # App 根 + ProviderScope
├── core/                  # 基础设施 umbrella
│   ├── data/              # data 层（DB / Repositories / Services / Utils）
│   │   ├── database/     # Drift 表 / 数据库 / 迁移
│   │   │   ├── tables/   # 1 个表 = 1 子目录（check_in/, contact/, ...）
│   │   │   ├── mappers/  # row ↔ entity 翻译（1 文件 1 mapper）
│   │   │   ├── connection/  # conditional import (web / native)
│   │   │   └── app_database.dart  # schemaVersion 11
│   │   ├── repositories/  # *RepositoryImpl（按 feature 子目录, v0.18 round 18 拆）
│   │   ├── services/     # 通知/邮件/SMS/录音/导出/加密
│   │   └── utils/         # phone_validator 等
│   ├── shared/            # 跨层共享（domain + data + presentation 都可用）
│   │   ├── formatters.dart
│   │   ├── json_codec.dart
│   │   ├── domain_value.dart  # DomainValue<T>（替代 drift Value<T>）
│   │   └── mood_visual.dart   # 情绪分数 → emoji/label
│   ├── theme/             # AppTokens + M3 主题 + dark mode（v0.18 round 18）
│   │   ├── app_tokens.dart   # 颜色/字体/间距/圆角/动画/阴影/breakpoint
│   │   ├── app_theme.dart    # light + dark ThemeData
│   │   ├── theme_provider.dart   # Riverpod ThemeMode
│   │   └── theme_toggle_button.dart
│   ├── routing/           # go_router 配置
│   │   └── app_router.dart  # 所有路由 + fade/slide-right/slide-up 3 类 transition
│   └── l10n/              # domain 层 strings（通知/邮件 fallback）
│       └── strings.dart
├── l10n/                  # presentation 层 flutter_localizations
│   ├── app_zh.arb         # 中文文案源（108+ keys）
│   ├── app_en.arb         # 英文文案源
│   ├── app_localizations.dart
│   ├── app_localizations_zh.dart
│   └── app_localizations_en.dart
├── domain/                # 0 Flutter 0 Drift 业务层
│   ├── entities/         # *Entity 后缀（避免跟 drift @DataClassName 冲突）
│   ├── logic/            # 业务规则（量表/streak/care engine/报告/email 模板）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例（业务编排）
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers（v0.18 round 18 拆 3 文件）
    │   ├── core_providers.dart   # DB + 基础服务 + 7 个 repo
    │   ├── service_providers.dart  # reminder / safety / assessment / data export
    │   └── vent_providers.dart   # vent audio + entries
    ├── pages/             # 1 个目录 = 1 个页面（按 feature 拆 8 个）
    │   ├── home/         # 主页（打卡 / 庆祝 / mood / vent 入口）
    │   ├── setup/        # 首次设置（4 步：consent / welcome / medication / done）
    │   ├── settings/     # 设置（含 settings/widgets/ 子组件 + reminders_hub）
    │   ├── trend/        # 趋势（list + calendar 视图）
    │   ├── assessment/   # 心理评估（答题 + 历史 + 提醒 section）
    │   ├── check_in/     # 打卡按钮
    │   ├── contact/      # 紧急联系人列表
    │   ├── medication/   # 用药（calendar / refill / today / report / dialogs）
    │   ├── mood/         # 情绪（dialog + quick button）
    │   └── vent/         # 树洞（list / compose / detail）
    └── widgets/           # 通用组件
        ├── page_scaffold.dart
        ├── app_snack_bar.dart
        ├── loading_skeleton.dart  # 统一 loading（fullScreen / card / Spinner, v0.18）
        ├── secondary_button.dart
        ├── press_feedback.dart    # v0.18: 按钮 :active scale 反馈
        └── animations/    # 通用动效（FadeIn / SlideUp）
```

**依赖方向（强制）**：
- `presentation → domain ← data`（domain 是接口所有者）
- `core/shared` 被 3 层都能用（但被 check_all 监测：只被 1 层用 = 移走）
- `l10n/`（presentation） vs `core/l10n/`（domain） 分层：**presentation 走 flutter_localizations（UI 用），domain 走 core/l10n/ 静态 strings（通知/邮件 fallback）**

### 6.2 架构检查（CI 友好 — 4 件套）

```bash
dart scripts/check_all.dart            # [1] 4 层纯度 + [2] 语义一致性
python scripts/check_cross_feature.py  # [3] 跨 feature import 边界（presentation/pages/{A}/ 禁 import pages/{B}/）
python scripts/check_drift_namespace.py  # [4] drift 命名空间一致性（v0.22 round 28 新增）
python scripts/check_fullwidth_punctuation.py  # [5] 全角标点检测（v0.21 round 21 P1-16）
```

**check_all.dart 输出**：
- **[1/2] 4 层架构纯度**：domain 0 flutter / 0 drift / 0 data / 0 presentation；data 不依赖 presentation。同时检测 `package:` 绝对路径 + `../../` 相对路径
- **[2/2] 架构语义一致性**：domain `*Entity` ↔ drift `@DataClassName('X')` 一一对应 + shared 工具使用度

违规时 exit code 1，CI 会 fail。

**注**：`dart run` 在本项目会触发 `objective_c` build hook 失败，用 `dart` 直接跑。

### 6.3 5 层 umbrella 落地（v0.18 round 12 完成）

**目标**：把 v0.16 之前的 layer-first 切到 5 层 umbrella，让跨层依赖一目了然。

**演进时间线**：
| Round | 主题 | 关键 commit | 影响范围 |
|---|---|---|---|
| v0.17 round 9 | `lib/{data,theme,l10n,shared,routing}/` → `lib/core/{...}/` | `60a26c7` | 137 files / 593 +/- 421 LOC |
| v0.17 round 10 | `presentation/pages/` 按 feature 拆 (14 dirs) | `df556f8` | 14 files moved, 19 imports updated |
| v0.17 round 11 | drift tables + mappers 按 feature 拆 (13 files) | `e8c7a12` | 13 files moved, 24 imports updated |
| v0.17 round 12 | `home_secondary_button.dart` → `presentation/widgets/secondary_button.dart` + `scripts/check_cross_feature.py` | `c6edf7d` | 1 file moved + 1 lint script added |
| v0.17 round 13 | CI workflow + 修 `ink_sparkle` 矛盾 + `print`→`debugPrint` + LoadingSkeleton | `ecd3e25` | 3 files / 192 +/- 38 LOC |
| v0.17 round 14 | 拆 `core_providers` (3 files) + animations/ subdir + l10n + swallowError + AppSnackBar + MotionScheme | `5610394` ... `ecc6865` | 50+ files / 1500+ LOC |
| v0.18 round 18 | 5 层 umbrella 目录树物理重写 | `7b95d41` | docs only |

**当前结论**（v0.18 治理后）：
- 8a ✅ 共享层（database / theme / l10n / shared / routing）并入 `lib/core/`
- 8b ⏸️ 8 个 feature 完全切分（home / setup / settings / trend / assessment / medication / vent / check_in）— **评估后放弃纯 feature-first**，因为 entity 跨 feature 大量互引用，硬拆会循环依赖
- 8c ✅ check_all 脚本重写（监测 `core/` + `domain/` + `data/` + `presentation/` 4 层）

**最终采用**：3 层 hybrid — `lib/{core,domain,presentation}/` + presentation/pages 按 feature 拆。
- entity 留在 `lib/domain/entities/`（跨 feature 共享，owner feature 不切割）
- presentation/page 按 feature 拆（v0.18 round 12 cross-feature 规则：✅ 允许跨 feature import `core/` / `domain/` / `data/` / `presentation/providers/` / `presentation/widgets/`；❌ 禁止 `pages/{A}/` import `pages/{B}/`，除 hub：`home` 和 `settings`）

---

## 7. 数据模型

### 7.1 Drift 8 表（**当前 schemaVersion 11**）

| 表 | 用途 | 关键字段 | schemaVersion 增量 |
|---|---|---|---|
| `user_profiles` | 用户档案 | name, created_at, language, last_check_in_at, 4 个 consent 字段, **userName nullable (v0.21 round 23)** | 1 → 11 全程，9→10 加 4 consent；10→11 userName nullable |
| `medications` | 药物 | name, dosage, times (JSON 数组), start_date, end_date, refill_date, refill_remind_days | 1 起；7→8 加 `(user_id, timestamp)` 复合索引 |
| `check_ins` | 每日打卡 | timestamp, mood_score (1-10), note, sleep_hours, exercise_minutes | 1 起；7→8 加索引 |
| `mood_entries` | 情绪日记 | timestamp, score (1-10), note, factors (JSON), **energy / sleep / anxiety (v0.18 round 18 4 维度)** | 1 起；6→7 加 3 列；7→8 加索引 |
| `contacts` | 紧急联系人 | name, phone, email, sort_order, is_archived | 1 起；7→8 加 `(user_id, timestamp)` 复合索引 |
| `vent_entries` | 树洞 | timestamp, text, **contentTextEnc (BLOB, AES-256 加密, v0.21 round 22 P0-1 修)**, audio_path, audio_duration_ms, content_type | 5→6 v0.15 新增；7→8 加索引；8→9 加 contentTextEnc |
| `report_histories` | 报告历史 | generated_at, type, file_path, parameters (JSON) | 1 起 |
| `assessments` (在 check_ins) | 心理评估（PHQ-9 / GAD-7）| type, answers (JSON), total_score, severity | 1 起；7→8 加索引 |

**schemaVersion 演进**（`lib/core/data/database/app_database.dart:43-58`）：

| Version | Round | 变更 |
|---|---|---|
| 1→5 | v0.5 - v0.7 | 初版 4 表 + vent_entries / assessments |
| 5→6 | v0.15 round 18 | 新增 `vent_entries`（树洞独立） |
| 6→7 | v0.18 round 18 (P1-15) | `mood_entries` 加 energy / sleep / anxiety 3 nullable column |
| 7→8 | v0.18 round 18 (P0-8) | 4 表查询索引：`(user_id, timestamp)` 复合索引，N+1 显著减少 |
| 8→9 | v0.21 round 22 (P0-1 修) | `vent_entries` 加 `contentTextEnc`（BLOB, AES-256 加密） |
| 9→10 | v0.21 round 22 (P1-22 修) | `user_profiles` 加 4 个 consent 字段 |
| 10→11 | v0.21 round 23 (P1-24 修) | `user_profiles.userName` 改 nullable，无 userName 不阻塞 setup |

### 7.2 Domain Entity 命名

- `UserProfileEntity` / `MedicationEntity` / `CheckInEntity` / `MoodEntryEntity` / `ContactEntity` / `VentEntryEntity`
- **`Entity` 后缀强制**：避免跟 drift `@DataClassName('X')` 冲突
- v0.21 round 21 修过 `vent_entry.dart` → `vent_entry_entity.dart` 命名一致性（`eec9d9a`）

### 7.3 数据流

```
[Presentation] ── ref.read(provider) ──> [Repository] ── watch / insert / delete ──> [Drift]
        ▲                                                                       │
        │                                                                       │
        └────────────── Stream<*> ◀── watchAll / getById ◀─────────────────────┘
```

**v0.21 round 21 优化**（`eec9d9a`）：
- DB 层加 `watchNormalCheckIns` / `getLatestNormalCheckIn` / `getLatestAssessmentTimestamp`（避免 N+1）
- Services 用 DB query 替代全表 scan + Dart filter
- Providers 复用缓存数据，不再每次 re-fetch
- 删 `main.dart` 重复 `AppDatabase()` connection
- 独立 async 用 `Future.wait` 并行化

---

## 8. 业务流程

### 8.1 首次引导（setup — 4 步）
> v0.18 round 18 后改为 4 步（之前 5 步，"评估建议"砍了），setup_page.dart 1000+ 行拆 7 文件（`4cd0bf0`）

1. **Step 0 法律同意**（v0.18 P0-13，`ddb9009`）：PopScope 拦截物理返回键，强制勾选同意 + 法律文档内嵌
2. **Step 1 欢迎** + 隐私说明
3. **Step 2 用药设置**（名称 + 剂量 + 时间点 + 续方）
4. **Step 3 完成**（通知权限申请 + 引导到系统设置）

### 8.2 每日打卡（check_in）
1. 用户点「我今天吃了药」按钮
2. 写 `CheckInEntity(useCase: RecordCheckInUseCase)`
3. 写 DB → 触发 `streakSummaryProvider` 自动重算
4. UI 显示庆祝动画 + 鼓励文案（按 streak 天数切换）
5. v0.18 round 18：`user_profiles.lastCheckInAt` live write（`0412692`），失联检测不再用旧值

### 8.3 CareEngine 规则引擎
**4 种触发规则**（每天 0:00 跑一次）：

| 规则 | 触发条件 | 动作 |
|---|---|---|
| `secondDayMissed` | 昨天 + 今天都没打卡 | 邮件给联系人 |
| `lateCheckInHabit` | 最近 7 天有 3 天 18:00 后才打卡 | 调整推送时间更早 |
| `weekPerfect` | 连续 7 天按时打卡 | 周日庆祝推送 |
| `none` | 规则不匹配 | 静默 |

`shouldFire()` 3 态：false 不调 / true 调 `showNow` / 抛异常被 try/catch 包。

**v0.18 round 18 增强**（`ee6cd3b`）：
- `CareCopy` 抽离（文案集中 1 处）
- 删 setup 软提醒双推（之前 setup 完成后会推 2 条软提醒）
- CareEngine 12 个 edge case test（v0.17 round 5，fire 3 态 + 4 规则边界：22:00 整点 / 周末 18:00 边界 / 36h + hour<10）

### 8.4 失联通知
- 每天 check 时：计算自上次打卡距今小时数
- 超过 48h → 走多联系人循环（按 sortOrder），每个发 SMS
- **措辞固定模板**（"请你方便的时候提醒我按时吃药"），不暴露病情 / 不渲染病情
- v0.18 round 18 P1-15：`MockSmsProvider` / `AliyunSmsProvider` 显式 throw + UI banner（`d62fa2f`），失败不再静默
- v0.21 round 22 P1-23：添加联系人前弹同意 dialog（`2e24e7f`）

### 8.5 跨 midnight streak 刷新（v0.17 round 4）
- 主页 `streakSummaryProvider` 跨 23:59:59 后不自动失效
- AppRoot 挂 midnight timer，**00:00:05 自动 `ref.invalidate(streakSummaryProvider)`**
- `nextMidnightRefresh(now)` 抽 top-level 纯函数（跨月/跨年/buffer 5s 防 race）
- **v0.22 round 28 P0 bug 修**（`df3f015`）：trend_calendar `CalendarView` 同款 — `_today = DateTime.now()` 在 field init 取一次永远不变；改 `ConsumerStatefulWidget` + `ref.watch(dayChangeTickProvider)` 触发跨日 rebuild

### 8.6 N+1 query 优化（v0.21 round 21 — `eec9d9a`）
- DB 层加 `watchNormalCheckIns` / `getLatestNormalCheckIn` / `getLatestAssessmentTimestamp`
- Services 用 DB query 替代全表 scan + Dart filter
- Providers 复用缓存数据，不再每次 re-fetch
- 独立 async 用 `Future.wait` 并行化

---

## 9. 测试策略

### 9.1 三层测试

| 层 | 类型 | 工具 | 速度 | 覆盖目标 |
|---|---|---|---|---|
| **domain** | 纯 Dart 单测 | `test/domain/*` | ⚡⚡⚡ < 1s | 90%+ |
| **data** | Drift round-trip | `test/data/*` | ⚡⚡ ~5s | 80%+ |
| **presentation** | widget test | `test/presentation/*` | ⚡ ~20s | 70%+ |

**当前**：**703 cases pass**（v0.22 round 28，**0 failures**）

测试数演进：

| Version | Test Cases | 增量 | 主要内容 |
|---|---|---|---|
| v0.16 | 471 | - | 4 层架构迁移完 |
| v0.17 | 528 | +57 | emil 动效 + 跨 midnight + CareEngine 12 edge case + Riverpod 3.x |
| v0.18 | 565 | +37 | pii_safe_log / SnoozeManager / dark token / CareCopy / WCAG / vent encryption round-trip |
| v0.19 | **702** | +137 | 29 文件补 roundN 命名 + database_migration 全 schemaVersion 路径 + reminder_scheduler 回归 + 6 处 mounted bug |
| v0.20 | 702 | 0 | 无新增（依赖迁移靠现有 encryption round-trip 覆盖） |
| v0.21 | **703** | +1 | N+1 query 修回归 + Dismissible / RefreshIndicator / 主题切换淡入 |
| v0.22 | **703** | 0 | 修 P0 + P1 14 项 bug 没引入新测试（v0.23 加 regression） |

### 9.2 测试覆盖分布

| 模块 | 覆盖 | 备注 |
|---|---|---|
| domain entities | 100% | 业务方法 + 边界 |
| domain logic | 90%+ | streak_calculator / care_engine / scale / medication_report |
| data repositories | 80%+ | round-trip + 边界 + database_migration 全 schemaVersion 路径（v0.19 round 19） |
| presentation widget | 70%+ | 主要页面 + 交互；v0.22 round 28 修 4 个 P0 bug 待加 regression |
| **safety_watch / care_engine / schedule service 单独** | 补 | v0.19 round 19B 修过 unsorted input（`a435903` `dbeeaff` `0758894`） |

### 9.3 命名规范（v0.19 round 19 统一）

- 1 个测试文件对应 1 个 round
- 命名 `{module}_roundNN_test.dart`（`roundNN` = 版本号中的 round 数字，如 v0.15 round 18 → `vent_list_round18_test.dart`）
- v0.19 round 19 一次性把 29 个测试文件补全 roundN 后缀（`20bd10e`）

### 9.4 TDD 纪律

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

### 10.3 v0.18-v0.22 通知增强

- **v0.18 round 18** SnoozeManager 拆子 service（`85d0253`）：从 `notification_service` 独立
- **v0.18 round 18 P0-2**：notification_service 接受 entity（`4c69e91`），消除 domain → data 反向依赖
- **v0.18 round 18 P0-7**（`ee72529`）：web 端抛明确 PlatformException，**阻断静默失败**
- **v0.22 round 28 P1 修**（`f17e0d4`）：`DatabaseMigration.needsMigration()` 内部加 `MissingPluginException` + `UnsupportedError` catch，web 端不崩

### 10.4 通知 id 演进（v0.19B 修过 cancel range）

| Bug | 修前 | 修后 | commit |
|---|---|---|---|
| `cancelAllSnoozes` 范围过窄（`[4000, 104000)`） | medId ≥ 72 漏 cancel | `[4000, 202000)` | v0.16 round 19B |
| `rescheduleMedicationReminders` 范围过窄（`[2000, 3000)`） | medId ≥ 100 漏 cancel | `[2000, 202000)` | v0.16 round 19B |
| `rescheduleRefillReminders` 范围过窄（`_refillBaseId + 1000`） | medId ≥ 1000 漏 cancel | `[6000, 202000)` | v0.16 round 19B |

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
- 录音用 `record` 5.2.0，播放用 `audioplayers` 6.1.0
- audio 文件存 `app docs/vent_audio/`，**v0.18 P0-2 起额外 AES-256 加密存盘**（`4f2f196`），SQLCipher 之外的第二层保护
- 主页加"倾诉 🌲"入口按钮
- 列表 + 长按删除；详情 + 进度条
- **v0.21 round 22 P0-1 修**（`eec9d9a`）：`vent_entries.contentTextEnc` (BLOB, AES-256 加密) — 树洞文字在 DB 层也加密，防 DB dump 泄漏
- **v0.22 round 28 P1 修**（`f17e0d4`）：`_togglePlay` 失败时 temp file 堆积泄漏；catch 内 try/finally 调 `deleteTempFile` 清 temp

**为什么独立**：保护"私密空间"信任 → 即使内容含"想死"也不通知家人。

### 11.3 命名

- domain entity: `VentEntryEntity`（v0.21 round 21 命名一致性 `vent_entry_entity.dart`，`eec9d9a`）
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

### 13.1 已完成（v0.5 - v0.22）

| 版本 | round | 内容 | 状态 | 关键 commit |
|---|---|---|---|---|
| v0.5 | 1-2 | 极简 MVP（主页打卡 + 设置 + 引导） | ✅ | - |
| v0.6 | - | 多联系人邮件 + 失联检测 v0 | ✅ | - |
| v0.7 | - | SMS 抽象 + CareEngine + 10 规则 + PHQ-9 | ✅ | - |
| v0.8 | - | 量表多选（PHQ-9 + GAD-7）+ 评估历史折线 + Web 加载 | ✅ | - |
| v0.12 | - | 邮件/SMS 通知 + 趋势页 + 临时吃药 | ✅ | - |
| v0.13 | - | 多档案 + 续方提前 + 评估历史 sparkline | ✅ | - |
| v0.14 | - | 续方管理 + 评估历史独立页 + 用药日历 + 提醒中心 | ✅ | - |
| v0.15 | round 18 | 树洞（完全独立） | ✅ | - |
| v0.16 | round 1-20 | 4 层架构 + 5 轮 code review + 9 个 gotcha fix + 通知自检 | ✅ | - |
| v0.17 | round 1-7 | emil 动效 + Riverpod 3.0 升级 + 跨 midnight + 7 项 process 改进 | ✅ | - |
| v0.17 | round 8-14 | 5 层 umbrella 落地（6 commits, 200+ files / 2500+ LOC） | ✅ | `60a26c7` `df556f8` `e8c7a12` `c6edf7d` `ecd3e25` `5610394` `ecc6865` |
| **v0.18** | round 18-20 | P0 安全（13 项）+ P1 UI/UX（19 项）+ i18n batch（4 项）+ 9 测试 | ✅ | `b046f13` `4f2f196` `00fcfaa` `4c69e91` `a1aa700` `ee72529` `ddb9009` `d9bae94` |
| **v0.19** | round 19-20 | 大文件拆分（god-file 治理）+ 137 测试 + setup 1000 行 → 7 文件 | ✅ | `31c86f3` `4cd0bf0` `d5693e8` `a435903` `0971139` `7b7d516` `2449a63` `20bd10e` `0758894` `dbeeaff` |
| **v0.20** | - | **加密依赖迁移**：`encrypt` → `pointycastle`（停维 4 年 → 持续维护） | ✅ | `97476d5` |
| **v0.21** | round 21-26 | N+1 query 修 + 125 string 抽 ARB + Dismissible + RefreshIndicator + 主题淡入 + analyzer 全清 | ✅ | `9c305ed` `eec9d9a` `94e0803` `2e24e7f` `295d4b3` `b0b9757` `419df9c` |
| **v0.22** | round 28 | **三视角审视 P0 + P1 14 项 bug 修**（trend_calendar dark mode + 跨日 + listener leak + a11y Semantics + CryptoService 合并 + 文档同步） | ✅ | `df3f015` `f17e0d4` `93449a2` `09a01ac` `6da9bdc` `00717d9` |

**当前**（v0.22 round 28）：
- **703 / 703 test pass**
- **`flutter analyze` 0 issues**
- `dart scripts/check_all.dart` 全过
- `python scripts/check_cross_feature.py` 0 violation
- `python scripts/check_fullwidth_punctuation.py` 0 issue
- `pubspec.yaml` version `0.21.0+1`（v0.23 升 `0.22.0+1`）

### 13.2 关键指标对比

| 指标 | v0.17 round 7 | v0.22 round 28 | 增量 |
|---|---|---|---|
| 测试数 | 528 | 703 | +175 |
| schemaVersion | 6 | 11 | +5 |
| 依赖项（核心） | 12 | 13 | pointycastle 替 encrypt |
| dead code（依赖） | - | 0 | 删 freezed/json_serializable/dio |
| 5 层 umbrella | ⏳ 进行中 | ✅ | 完成 |
| dark mode token | ❌ | ✅ | v0.18 round 18 |
| L10N keys（ARB） | - | 108+ | v0.21 round 21 抽 125 string |
| 树洞录音加密 | ❌ | ✅ | v0.18 P0-2 AES-256 |
| vent contentTextEnc | ❌ | ✅ | v0.21 round 22 P0-1 |
| PII 安全日志 | ❌ | ✅ | v0.18 P0-1 release swallow |
| a11y Semantics | 部分 | ✅ 4 P0 bug 修 | v0.22 round 28 emil-bug-04/05 |
| 4 件套 CI 检查 | 1 | 4 | check_all + cross_feature + drift_namespace + fullwidth_punctuation |

### 13.3 下一步（v0.23+ 候选 — spzh 报告 §4.6 排序）

| 优先级 | 项 | 描述 | 工作量 | 来源 |
|---|---|---|---|---|
| 🔴 P0 | **修 30+ 半角标点** | `check_fullwidth_punctuation.py` 扩 ASCII_PUNCT 8+ 种 + `--strict` 模式 CI 强制 | 小（1 commit） | spzh-doc-08 + spzh-flow-05/07 |
| 🔴 P0 | **法律文档 CI 同步** | `check_legal_sync.py` 检查法律文档最后更新日期 vs 涉及法律变更的 commit 日期 | 中（1-2 commit） | spzh-flow-06 + spzh-doc-19 |
| 🔴 P0 | **P2 review P0 残留** | 3-4 项占位邮箱 / 文档"治愈"措辞 / "撤回同意"入口 / `setupContactConsent` 半角 | 小（1 commit） | spzh 报告 §3 残留 |
| 🔴 P0 | **CI 强制流程 5 件套** | `flutter analyze` + `flutter test` + `check_all.dart` + `check_cross_feature.py` + `check_fullwidth_punctuation.py --strict` | 中（1 commit） | spzh 报告 §4.3 |
| 🟡 P1 | **release notes 自动生成** | commit 用 conventional commit 风格 → `standard-version` / `release-please` 自动 CHANGELOG，根治 CHANGELOG 滞后 | 中（1-2 commit） | spzh-flow-04 + spzh-doc-04 |
| 🟡 P1 | **commitlint + husky/lefthook** | 挡掉不符合规范的 commit，统一风格 | 小（1 commit） | spzh-flow-08 |
| 🟡 P1 | **Drift 升级 2.20.3 → 2.34.2** | drift 实际没 3.x，最新 2.34.2。**注**：drift_dev 2.34.0 跟 sqlparser 0.44.6 撤回冲突，需 pin `sqlparser: 0.44.5` 在 `pubspec_overrides.yaml` | 中（1-2 commit） | v0.17 round 8 计划 |
| 🟡 P1 | **v0.22 P0 bug regression test** | 4 个 P0 bug（trend_calendar dark mode / 跨日 / listener leak / a11y Semantics）加 widget test 卡住 | 中（1 commit） | v0.22 round 28 待办 |
| 🟡 P1 | **flutter 版本 CI 检查** | `check_flutter_version.py` 比对 `flutter --version` vs `pubspec.yaml` 约束 vs AGENTS.md / README.md | 小（1 commit） | spzh 报告 §4.3 |
| 🟡 P1 | **P2_COMPLIANCE_REVIEW 跟踪表** | 加"已修 / 遗留 / 不修"3 列，方便 review 进度可视化 | 小（1 commit） | spzh-doc-20 |
| 🟢 P2 | **ADR 流程** | 缺 `docs/architecture-decisions.md` 正式 ADR 流程 | 中 | spzh-doc-17 |
| 🟢 P2 | **tag 流程恢复** | v0.18-0.21 全无 tag，`GIT_WORKFLOW.md` 失效 | 小 | spzh-flow-02 |
| 🟢 P2 | **C1 自动 retry + 指数退避** | DB / notification 失败自动重试（Riverpod 3.x 内置） | 中（1 commit） | v0.17 round 8 计划 |
| 🟢 P2 | **C3 Stream `==` 过滤** | 之前是 `identical`，减少重复 rebuild | 小（1 commit） | v0.17 round 8 计划 |
| 🟢 P2 | **B2 拆 Notifier** | setup 22 处 setState + medication_calendar / vent 拆 Notifier | 中（1-2 commit） | v0.17 round 8 计划 |
| 🟢 P2 | **B3 ConsumerStatefulWidget → ConsumerWidget** | 9 个 widget 状态提到 provider | 中（1-2 commit） | v0.17 round 8 计划 |
| ⚪ P3 | **reports/ 索引文件** | round 1-26 报告归档目录 | 小 | spzh-doc-14 |
| ⚪ P3 | **P2 review 报告同步** | `P2_COMPLIANCE_REVIEW.md` 标"已修"项 | 小 | spzh-doc-20 |

### 13.4 远期（v1.0+）

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

#### commit 规范（v0.22 round 28 双轨统一 — `6da9bdc`）

> **历史冲突解决**：v0.17 round 14 之前要求**纯中文**（`docs/CHINESE_COMMIT_GUIDE.md` L17），但 v0.21 round 22-26 实际 commit 80% 是英文。两份规范自相矛盾，v0.22 round 28 统一为 **conventional commit 双轨**。

**当前规范**（`6da9bdc` 落地）：

- **接受 conventional commit 双轨**：
  - **格式 A（英文）**：`type(scope): subject` — 例如 `refactor(architecture): v0.19 大文件拆分 + 架构违规修复 + bug 修复`（`31c86f3`）
  - **格式 B（混合）**：`<version> round <N>: <type>(<scope>) <中文/英文 subject>` — 例如 `v0.22 round 28: fix(P0) 4 bug - trend_calendar dark mode + dayChangeTick + listener leak + a11y Semantics`（`df3f015`）
- **`type`**：`fix` / `refactor` / `feat` / `docs` / `test` / `chore` / `perf` / `build`
- **`<scope>` 建议**：`P0` / `P1` / `P2` / `P3` / `architecture` / `data` / `domain` / `presentation` / `i18n` / `a11y` / `l10n` 等
- **subject 必含** `<version> round <N>:` 头部（除非纯 hotfix）

**PowerShell 解析坑**（推荐规避）：

- `git commit -m "中文 $variable ..."` 在 PowerShell 下 `中文` 部分被吞，**只能用 `git commit -F commit_msg.txt` 文件方式**
- 文件方式：写 `commit_msg.txt`（UTF-8 无 BOM）→ `git commit -F commit_msg.txt`
- 详见 AGENTS.md "PowerShell Set-Content 破坏 UTF-8 中文" 段

**v0.23 计划**：commitlint + husky/lefthook 强制挡掉不符合规范的 commit（spzh-flow-08）

#### 其他规范

- **AGENTS.md** 给 AI Agent 看（不是人看，但人是 source of truth）
- **CHANGELOG** 跟代码同步更新（每个 commit 前 / 后 — v0.22 round 28 `00717d9` 补 v0.18-0.21 整段 50+ commit，根治过去 4 个 minor version 滞后）
- **法律文档**（`assets/legal/*.md`）涉及隐私 / 同意 / 加密 变更时同步更新；PIPL 告知不实是合规风险
- **报告归档**：`reports/round{NN}/` 一次 review 落 1 个目录（spen / spzh / emil 三视角）

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

### 16.1 本地验证（v0.22 round 28 — 4 件套全过）

```bash
flutter analyze                                          # 必须 0 error / 0 warning / 0 info（v0.21 round 21 `9c305ed` 全清）
flutter test                                             # 必须 703 / 703 cases 全过（v0.22 round 28）
dart scripts/check_all.dart                              # 4 层架构纯度 + 一致性
python scripts/check_cross_feature.py                    # 跨 feature import 边界
python scripts/check_drift_namespace.py                  # drift 命名空间一致性（v0.22 round 28 新增）
python scripts/check_fullwidth_punctuation.py            # 全角标点检测（v0.21 round 21 P1-16）
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

| # | 坑 | 原因 | 修法 | 引入版本 |
|---|---|---|---|---|
| 1 | `flutter_secure_storage` Android 首次启动 ~200ms 延迟 | 设备 Keystore 启动慢 | 提前 init + Loading state | v0.5 |
| 2 | Drift schema 升级漏 migration | `app_database.dart` schemaVersion++ 但忘加 `onUpgrade` | PR review + 必看 migration 段（当前 schemaVersion 11） | v0.5 |
| 3 | `VentEntryEntity` vs `VentEntry` 命名冲突 | domain entity vs drift @DataClassName | domain 强制 `*Entity` 后缀 | v0.15 |
| 4 | `audioplayers + record` 一起用文件锁冲突 | 同进程两个 handle | recorder 先 dispose 再 player | v0.15 |
| 5 | `Stream subscription leak` | `_player.onXxx.listen()` 没存 subscription | 存字段 + dispose 时 cancel | v0.15 |
| 6 | `BuildContext` 跨 async gap 警告 | analyzer `use_build_context_synchronously` | mounted check 或 `this.context` | v0.16 |
| 7 | `DateTime.now()` 多次 race | 跨 midnight 边界日期不一致 | 函数入口 `final now = DateTime.now();` 一次 | v0.16 |
| 8 | **Notification id cancel range 公式不匹配** | 之前 1000/100000 范围太窄 | 统一 200000 + id 公式要对应 | v0.16 |
| 9 | **Filename collision** | 同毫秒内 2 个文件覆盖 | timestamp + 4 位 random suffix | v0.16 |
| 10 | `setState` after defunct | listener 内调 setState + State dispose 后触发 | listener 内 `if (!mounted) return;` guard | v0.16 |
| 11 | **Resource acquire/release** 必须 try/finally | try 块内 acquire 资源 + dispose 一气呵成，异常时 dispose 不跑 | `final x = ...; try { use } finally { x.dispose(); }` | v0.16 |
| 12 | **`.first` / `.last` 隐式排序假设** | 依赖 drift orderBy 隐式顺序，future caller 传 unsorted 数据会算错 | 函数内部显式 sort + unsorted input regression test | v0.16 |
| 13 | **GoRouter path param unsafe parse** | `int.parse` 抛 FormatException → app 崩 | `int.tryParse(...) ?? 0` | v0.16 |
| 14 | **国产 ROM 静默杀后台通知** | 小米/华为/OPPO/Vivo/魅族默认禁止后台 + 自启动 | NotificationStatusCard 自检 + OEM 引导 | v0.16 |
| 15 | **Riverpod 3.x `valueOrNull` → `value`** | 2.6 的 `AsyncValue.valueOrNull` 在 3.x 改名 | 全局搜索 `valueOrNull` 替换 | v0.17 |
| 16 | **Riverpod 3.x `ref.mounted` 仅限 Notifier** | Provider/StreamProvider/ConsumerStatefulWidget 不能用 | 保持 `!mounted` check（项目 27 处） | v0.17 |
| 17 | **Drift sqlparser 0.44.6 撤回** | 0.44.6 被作者撤回，build_runner AOT kernel 编译失败 | `pubspec_overrides.yaml` pin `sqlparser: 0.44.5` | v0.16 |
| 18 | **跨 midnight streak 不刷新** | streakSummaryProvider 自身没监听时间变化 | AppRoot 挂 midnight timer + `nextMidnightRefresh` 纯函数 | v0.17 |
| 19 | **emil 动效 token 缺 curve** | 之前 app_tokens.dart 只有 dur* 缺 curve | 4 个 curve token + emil 决策框架 doc 注释 | v0.17 |
| 20 | **go_router 默认无 page transition** | GoRoute.builder 默认切换无动画 | `pageBuilder` + `CustomTransitionPage`（3 类 transition） | v0.17 |
| 21 | **Flutter widget test ink_sparkle shader 缺失** | Material 3 InkWell 需要 `shaders/ink_sparkle.frag` | 从 SDK 复制到 `assets/shaders/` + `pubspec.yaml: shaders:` 字段 | v0.17 |
| 22 | **trend_calendar dark mode silent bug**（v0.22 P0 修） | v0.18 加 8 个 dynamic color getter 时 `_DayDetailCard` + `_EventRow` 漏 6 处静态 `AppTokens.divider` / `textHint` / `textSecondary` | 全部换 `AppTokens.dividerColor(context)` + 去掉外层 `const` | v0.22 |
| 23 | **trend_calendar 跨日不刷新**（v0.22 P0 修） | `CalendarView` 是 `StatefulWidget`，`_today = DateTime.now()` 在 field init 取一次永远不变 | 改 `ConsumerStatefulWidget` + `ref.watch(dayChangeTickProvider)` | v0.22 |
| 24 | **AnimationController listener leak**（v0.22 P0 修） | `didUpdateWidget` 每次 value 变化都 `_controller.addListener(() { setState... })` 匿名闭包但**没移除旧 listener** → 指数级 rebuild | 抽 `_tickListener` 字段稳定引用 + `initState` 注册 1 次 + `dispose` 移除 | v0.22 |
| 25 | **a11y ChoiceChip/评分 无 Semantics**（v0.22 P0 修） | 9 题 × 4 选项 = 36 个孤立读屏项 / 5 个评分无 wrapper | `Semantics(container: true, label: '...', inMutuallyExclusiveGroup: true, selected: ...)` 包装 | v0.22 |
| 26 | **vent `_togglePlay` 失败时 temp file 堆积**（v0.22 P1 修） | catch 内不删 `_tempDecryptedPath`，连续失败会堆积 temp 文件 | catch 内 try/finally 调 `deleteTempFile` 清 temp | v0.22 |
| 27 | **web 端 database_migration 启动崩溃**（v0.22 P1 修） | `DatabaseMigration.needsMigration()` 内部用 `File.existsSync()` 抛 `UnsupportedError`，main.dart 无 try/catch | 内部加 `on MissingPluginException` + `on UnsupportedError` catch 返回 false | v0.22 |
| 28 | **CryptoService 与 EncryptionService 重复**（v0.22 P1 修） | v0.7 旧 CryptoService 用 `String.codeUnits`（UTF-16）不标准 + 实际 lib/ 0 业务引用 | 删 `crypto_service.dart`；`EncryptionService` 加 `encryptString` + `decryptString` | v0.22 |
| 29 | **mood_quick_button 漏 PressFeedback**（v0.22 P1 修） | `SecondaryButton` 无 PressFeedback 包，注释撒谎说"内部已处理" | 外包 PressFeedback + 修注释 | v0.22 |
| 30 | **app_zh.arb 半角标点**（v0.22 P1 修） | `setupContactConsent` 半角 `,` → 全角 `，`（**关键法律文案** v0.21 P1-16 漏修）；3 处 `...` → `……` | `python scripts/check_fullwidth_punctuation.py --strict` 强制 CI | v0.22 |
| 31 | **PowerShell `git commit -m` 中文被吞**（spzh-doc-16 修） | PowerShell `git commit -m "中文 $variable ..."` `$variable` 解析坑，中文被吞 | 改 `git commit -F commit_msg.txt` 文件方式（UTF-8 无 BOM） | v0.17 |
| 32 | **commit 规范 2 份自相矛盾**（v0.22 P1 修） | `CHINESE_COMMIT_GUIDE.md` 写"全部中文" vs `WHITEPAPER.md` 写"纯英文" | 2 份都改为"接受 conventional commit 双轨" | v0.22 |

完整 gotcha 索引见 `AGENTS.md` "已知坑"段。

---

## 18. 决策记录（Decision Log）

### 18.1 核心架构决策

| 决策 | 原因 | 引入版本 |
|---|---|---|
| 4 层架构 | domain 易测试 + 易复用 + 0 Flutter 依赖 | v0.14 |
| 5 层 umbrella（`lib/core/{data,shared,theme,routing,l10n}/`） | v0.17 round 9 物理分层，跨层依赖一目了然 | v0.17 |
| SQLCipher + 零云端 | 精神心理患者数据敏感 | v0.5 |
| 树洞独立表 | 隐私边界：绝对不进任何分析 / 通知 / 关怀 | v0.15 |
| 树洞录音 AES-256 加密（`4f2f196`） | SQLCipher 之外的第二层保护 | v0.18 |
| vent contentTextEnc 列（`BLOB` AES-256, `eec9d9a`） | 树洞文字在 DB 层也加密，防 DB dump 泄漏 | v0.21 |
| Audio 存本地文件 | DB 体积不能爆炸，文件用路径引用 | v0.15 |
| `ProviderScope` overrides 测试 | 真实 DB 测试太慢，in-memory + override 足够覆盖 | v0.5 |
| 3 层 hybrid (layer-first in `lib/{core,domain,presentation}/` + feature-first in `lib/presentation/pages/`) | entity 跨 feature 大量互引用，硬拆会循环依赖；只有 presentation 是 feature-driven (v0.17 P3-6 经验) | v0.18 |
| 拆 `core_providers` → 3 文件 (core / service / vent) | 单文件 25+ provider 跨 feature 修改容易冲突 | v0.17 |
| repositories 按 feature 拆子目录（`1a501ce`） | v0.18 round 18 跟 presentation/pages 保持一致 | v0.18 |

### 18.2 加密 / 安全

| 决策 | 原因 | 引入版本 |
|---|---|---|
| `encrypt` → `pointycastle`（`97476d5`） | encrypt 2022 停维 4 年；pointycastle 持续维护 + 加密 blob 格式不变 | v0.20 |
| PII 安全日志（`b046f13`） | release 模式 swallow 错误日志，dev 模式完整堆栈 | v0.18 |
| PIPL 3 份法律文档（`d9bae94`） | 隐私政策 / 用户协议 / 数据收集说明 | v0.18 |
| `user_profiles` 4 个 consent 字段（schemaVersion 9→10） | 显式记录用户授权 | v0.21 |
| `setupContactConsent` 半角 → 全角标点（`f17e0d4`） | 关键法律文案 v0.21 P1-16 漏修 | v0.22 |
| `sensitive_data_consent.md` L49 改为 AES-256 已启用（`6da9bdc`） | v0.18 P0-2 已加密，原文"当前未加密"告知不实 | v0.22 |

### 18.3 测试 / 流程

| 决策 | 原因 | 引入版本 |
|---|---|---|
| 测试文件命名 `{module}_roundNN_test.dart` | 1 个测试文件 = 1 个 round | v0.19 |
| 数据库 migration 全 schemaVersion 路径覆盖 | schemaVersion 升级漏 migration 是 silent bug | v0.19 |
| 隐式排序必须显式 sort + unsorted input regression test | 依赖 drift orderBy 隐式顺序是 silent bug | v0.16 |
| commit message 接受 conventional commit 双轨（`6da9bdc`） | PowerShell `$variable` 解析坑 + 长 message 用 `-F file` | v0.22 |
| `check_fullwidth_punctuation.py` 强制 CI（v0.23 计划） | v0.21 P1-16 漏修 30+ 标点 | - |

### 18.4 UI / 设计

| 决策 | 原因 | 引入版本 |
|---|---|---|
| 主页底部按钮加"倾诉" | 用户主要路径 = 打卡 / 设置 / 倾诉 3 个核心动作 | v0.15 |
| `RadioListTile` → `RadioGroup`（Flutter 3.32+） | 弃用警告 | v0.16 |
| `try/finally` 资源释放 | 异常路径也要 release | v0.16 |
| `int.tryParse` 替代 `int.parse` | GoRouter 路径参数 fallback | v0.16 |
| `reduce(isAfter)` 替代 `.last` | 不依赖 list 顺序 | v0.16 |
| 8 元一次性买断，无订阅 | 用户人群 + 商业模式 | v0.5 |
| emil 动效频度决策 | 100+/day 无，tens 微，occasional 标准，rare 可 delight | v0.17 |
| dark mode token API（`6366d3c`） | 8 处 widget 切 dark variant | v0.18 |
| 全角标点统一（`731f975`） | P1-16 修 173 处中文文案 | v0.18 |
| prefers-reduced-motion 尊重（`0ad8e79`） | 系统级动效偏好自动禁用 | v0.18 |
| 港澳台/国际区号扩展（`388ce92`） | phone_validator 支持 +852/+853/+886/+1/+44 | v0.18 |

### 18.5 文档 / 流程同步

| 决策 | 原因 | 引入版本 |
|---|---|---|
| AGENTS.md 给 AI Agent 看（不是人看） | 人是 source of truth | v0.14 |
| CHANGELOG 跟代码同步更新（每个 commit 前/后） | v0.22 round 28 `00717d9` 补 v0.18-0.21 整段 50+ commit | v0.22 |
| 法律文档跟代码 diff CI 同步（v0.23 计划） | `sensitive_data_consent.md` L49 PIPL 告知不实 = 合规风险 | - |
| release notes 自动生成（v0.23 计划） | 根治 CHANGELOG 滞后 | - |

### 18.6 重构历史（v0.17 round 9–14 — P3-6 归档）

| Round | 主题 | 关键 commit | 影响范围 |
|---|---|---|---|
| 9 | `lib/{data,theme,l10n,shared,routing}/` → `lib/core/{...}/` | `60a26c7` | 137 files / 593 +/- 421 LOC |
| 10 | `presentation/pages/` 按 feature 拆 (14 dirs) | `df556f8` | 14 files moved, 19 imports updated |
| 11 | drift tables + mappers 按 feature 拆 (13 files) | `e8c7a12` | 13 files moved, 24 imports updated |
| 12 | `home_secondary_button.dart` → `presentation/widgets/secondary_button.dart` + `scripts/check_cross_feature.py` | `c6edf7d` | 1 file moved + 1 lint script added |
| 13 | CI workflow + 修 `ink_sparkle` 矛盾 + `print`→`debugPrint` + LoadingSkeleton | `ecd3e25` | 3 files / 192 +/- 38 LOC |
| 14 | 拆 `core_providers` (3 files) + animations/ subdir + l10n + swallowError + AppSnackBar + MotionScheme | `5610394` ... `ecc6865` | 50+ files / 1500+ LOC |

每轮的完整 commit message 见 `git log --oneline`。代码侧决策细节在 `AGENTS.md` "决策记录" 段。

---

## 19. 附录

### 19.1 关键文档

- `README.md` — 项目简介（公开版）
- `AGENTS.md` — AI Agent 视角的项目指引（私有）
- `docs/CHANGELOG.md` — 版本变更（Keep a Changelog 格式，**v0.22 round 28 `00717d9` 补 v0.18-0.21 整段**）
- `docs/DEPLOYMENT.md` — 部署相关
- `docs/SENDGRID_SETUP.md` — 邮件服务配置
- `docs/CHINESE_COMMIT_GUIDE.md` — 中文 commit 指南（**v0.22 round 28 已与 WHITEPAPER §14.3 统一为 conventional commit 双轨**）
- `docs/GIT_WORKFLOW.md` — Git 工作流（**v0.22 round 28 起 tag 流程失效待修**）
- `docs/P2_COMPLIANCE_REVIEW.md` — P2 合规审查（59 项，部分已修未标）
- `docs/WHITEPAPER.md` — **本文档**（团队一站式档案）
- `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` — PIPL 法律文档
- `reports/round{NN}/{spen,spzh,emil}_review.md` — 三视角 review 报告

### 19.2 关键脚本（**v0.22 round 28 实际清单**）

| 脚本 | 类型 | 用途 | 引入版本 |
|---|---|---|---|
| `scripts/check_all.dart` | dart | 4 层架构纯度 + 一致性 | v0.16 |
| `scripts/test_delivery_rate.dart` | dart | 通知送达率测试（占位，跑不了） | v0.16 |
| `scripts/check_cross_feature.py` | python | 跨 feature import 边界检查 | v0.17 |
| `scripts/check_drift_namespace.py` | python | drift 命名空间一致性 | v0.22 |
| `scripts/check_fullwidth_punctuation.py` | python | 全角标点检测 | v0.21 |

> ❌ **已删**（v0.18 后）：
> - `scripts/8a2_rewrite_to_absolute.py` — 把所有相对 import 转 package: 绝对路径（v0.17 round 8 一次性脚本）
> - `scripts/8a_rewrite_imports.py` — 旧版本（v0.17 round 8 初期）
> - 14 个一次性 migration scripts（v0.21 round 21 `eec9d9a` 物理删除）

### 19.3 关键命令

```bash
# 跑
flutter run -d <device>

# 监听代码生成
dart run build_runner watch --delete-conflicting-outputs

# 单文件测试
flutter test test/domain/streak_calculator_test.dart

# 4 件套 CI 检查（v0.22 round 28）
flutter analyze                                                            # 0 issues
flutter test                                                               # 703 / 703
dart scripts/check_all.dart                                                # 4 层 + 一致性
python scripts/check_cross_feature.py                                      # 跨 feature
python scripts/check_drift_namespace.py                                    # drift 命名空间
python scripts/check_fullwidth_punctuation.py                              # 全角标点

# 解决 Drift sqlparser 撤回
# 已在 pubspec_overrides.yaml pin sqlparser: 0.44.5，dart pub get 自动应用
```

### 19.4 关键文件路径（**v0.18 后 5 层 umbrella 修正**）

> ❌ **已过时路径**（v0.18 round 9 后改 `lib/core/` umbrella）：
> - `lib/data/database/app_database.dart` → 实际 `lib/core/data/database/app_database.dart`
> - `lib/data/services/notification_service.dart` → 实际 `lib/core/data/services/notification_service.dart`
> - `lib/routing/app_router.dart` → 实际 `lib/core/routing/app_router.dart`
> - `lib/theme/app_tokens.dart` → 实际 `lib/core/theme/app_tokens.dart`

| 文件 | 用途 |
|---|---|
| `lib/main.dart` | 启动顺序、SQLCipher 初始化、通知 init |
| `lib/app.dart` | App 根 + ProviderScope |
| `lib/core/data/database/app_database.dart` | **schemaVersion 11**，所有表 + migration |
| `lib/core/data/services/notification_service.dart` | 通知 id 公式 + cancel range + 自检卡依赖 |
| `lib/core/routing/app_router.dart` | 所有页面路由 + shell (NavigationRail) + 3 类 transition |
| `lib/core/theme/app_tokens.dart` | 设计 Token（spacing/radius/fontSize/color/duration/curve/breakpoint + dark variant） |
| `lib/core/theme/app_theme.dart` | Material 3 light + dark ThemeData |
| `lib/core/shared/{formatters,json_codec,domain_value,mood_visual}.dart` | 跨层共享工具 |
| `lib/core/l10n/strings.dart` | domain 层 strings（通知/邮件 fallback） |
| `lib/l10n/app_zh.arb` + `app_en.arb` | presentation 层 flutter_localizations（108+ keys） |
| `lib/domain/logic/care_engine.dart` | 失联检测 / 续方 / 通知触发核心规则 |
| `lib/presentation/providers/core_providers.dart` | 全局 provider 注册表（DB + 7 个 repo） |
| `lib/presentation/providers/service_providers.dart` | reminder / safety / assessment / data export |
| `lib/presentation/providers/vent_providers.dart` | vent audio + entries |
| `lib/presentation/widgets/{page_scaffold,app_snack_bar,loading_skeleton,secondary_button,press_feedback}.dart` | 通用组件 |
| `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` | PIPL 法律文档 |

### 19.5 紧急联系方式（产品设计）

- **北京心理危机研究与干预中心**：010-82951332
- **全国心理援助热线**：400-161-9995
- **生命热线**：400-821-1215

---

## 文档维护

- **owner**：当前主开发者（详细见 git log 活跃 commit 作者）
- **更新时机**：每个 round commit 后 / 每个版本发布前
- **下次 review**：v0.22 round 28 后（v0.23+ 计划已落地在 §13.3 候选表，含 P0 4 项 + P1 6 项 + P2 5 项 + P3 2 项 = 17 项）
- **同步来源**：`reports/round27/{spen,spzh,emil}_review.md` 三视角报告 → `AGENTS.md` / `CHANGELOG.md` / `WHITEPAPER.md` / `DEPLOYMENT.md` / `SENDGRID_SETUP.md` / `assets/legal/*.md` 6 份文档
