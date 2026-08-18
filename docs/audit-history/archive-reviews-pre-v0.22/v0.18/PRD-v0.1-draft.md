# 慢病管家（ChronicCare）产品需求文档 · v0.15

| 项 | 值 |
|---|---|
| 文档版本 | **v0.15**（树洞 + 4 层架构 + 提醒中心 + 用药日历 + 评估历史）|
| 编写日期 | 2026-07-15 |
| 文档状态 | 🟢 v0.15 已完成；下一阶段 v1.0 真实平台对接 + 加密备份 |
| 配套文档 | `README.md`（产品视角）· `AGENTS.md`（代码视角）· `docs/CHANGELOG.md`（版本变更） |

---

## 0. 版本速览

> 详细修订记录见 `docs/CHANGELOG.md`（Keep a Changelog 格式）。本节只列**关键里程碑**。

| 阶段 | 版本 | 日期 | 关键事件 |
|---|---|---|---|
| 草稿 | v0.1-v0.3 | 2026-07-11 | 4 个用户洞察迭代：精神心理 → 死了么模式 → 大砍刀 |
| **产品洞察** | **v0.4** | 2026-07-11 | **死了么模式 × 吃药 = 「停药通知」差异化核心** |
| 极简 MVP | v0.5 | 2026-07-12 | 主页打卡 + 设置 + drift + go_router |
| 关怀体系 | v0.6-v0.13 | 2026-07-12~14 | 邮件/SMS/SafetyWatch/情绪日记/评估/续方/多联系人 |
| **架构升级** | **v0.14** | 2026-07-15 | **4 层架构**（domain 0 Flutter 依赖）+ 提醒中心 + 用药日历 |
| **私密空间** | **v0.15** | 2026-07-15 | **树洞（Vent）—— 完全独立不参与任何分析** |

---

## 1. 产品概述

### 1.1 一句话定位
> **"我今天吃了药"**——为精神心理疾病患者打造的"吃药打卡 + 停药通知"极简 App。
> **不死，但可能停药**——把死了么的"死了通知"升级为"停药通知"，从"善后"变成"主动干预"。

### 1.2 核心洞察
- 精神心理患者**最大的健康风险不是"突然死了"**，是**"突然停药"**（撤药反应 / 复发率 50-70% / 停药 2 周是复发高峰）
- "死了么"模式的核心 = **失联自动通知**——普适机制
- 把失联定义从"死亡"换成"停药"= 升级为可操作的生命守护
- 紧急联系人角色 = "善后发现" → "主动提醒吃药" = 真正能救

### 1.3 项目方向

| 维度 | 值 |
|---|---|
| 病种 | 精神心理（焦虑/抑郁/双相/睡眠）|
| 核心动作 | 1 个按钮：「今天吃了药」 |
| 失联定义 | 48 小时未打卡 |
| 通知内容 | 邮件"请提醒我吃药"（不是"请检查我状态"）|
| 商业模式 | 8 元付费下载 |
| 工作量 | ≤5% / 周 ≤2h |

---

## 2. 需求分析

### 2.1 用户痛点
| 痛点 | 现有方案不足 | **本产品解法** |
|---|---|---|
| 漏吃药 1 次就自责 / 复发风险 | 传统提醒 App 太冰冷 | 极简打卡 + 失联通知（双重保障）|
| 突发撤药反应没人知道 | 死了么只覆盖"死亡" | 升级为"停药通知"——更早介入 |
| 紧急联系人在外地不能实时看 | 邮件能异步到达 | 邮件 + 累积历史（让家人/医生看到趋势）|
| 病耻感强 | 精神科 App 标签刺眼 | 叫"慢病管家"类中性名字 + 树洞完全独立 |
| 一个人住怕"悄无声息停药" | 死了么没专攻精神心理 | 精神心理用户群垂直 |
| 想发泄又怕被记录 / 分析 | 情绪 App 全都进分析 | 树洞（v0.15）—— 纯私密空间，零分析 |

### 2.2 竞品分析
| 竞品 | 模式 | 我们的差异化 |
|---|---|---|
| 死了么/在么在么 | 通用签到 + 死了通知 | **专攻"停药"——更可操作** |
| 善言 | 通用签到 | 我们精神心理垂直 |
| medTimer | 通用吃药提醒 | 我们是"打卡"不是"提醒"——更轻 |
| 活法/糖友 | 单病种 App | 精神心理专版 + 树洞私密空间 |

---

## 3. 功能详细

### 3.1 业务规则（spec）

**打卡**：
- 每日 1 次 = 1 次"今日完成"（多次吃药只算 1 次）
- 临时吃药（关联到现有药物）= 不影响 streak，但计入健康档案

**宽容机制**：
- 漏 1 天（24h）：连续天数不断，显示"少 1 次没关系"
- 漏 2 天（48h+）：触发 CareEngine 规则 + SafetyWatch 失联检测
- 漏 3 天：连续天数归 0

**隐私边界**（**关键**）：
- 0 注册 0 账号 0 手机号
- 不收位置、通讯录、IP
- **树洞（v0.15）完全独立**：不进入趋势 / 评估 / CareEngine / SafetyWatch / 任何通知
- 即便树洞内容含"想死"也不通知家人（保护"私密空间"信任）

**游戏化**：**不做**（精神心理用户不适合"段位感"）

### 3.2 视觉设计
- **大字体**（适老化 + 精神心理用户友好）
- **大按钮**（≥72dp）
- **单色主题**：嫩绿色（萌芽意象，呼应"还在坚持"）
- **文案温柔**：用"少 1 次没关系""还在坚持"代替"漏服警告"

### 3.3 技术栈
| 组件 | 版本 |
|---|---|
| Flutter | 3.44.5 stable |
| Dart | 3.12.2 |
| 状态管理 | Riverpod 2.6 |
| 本地数据库 | Drift 2.28 + **SQLCipher 加密**（v0.14 修） |
| 路由 | go_router 14.6 |
| 推送 | flutter_local_notifications 17 |
| 加密 | flutter_secure_storage（iOS Keychain / Android Keystore）|
| 录音 | record 5.2.0（v0.15 树洞） |
| 音频播放 | audioplayers 6.8.1（v0.15 树洞） |

**架构**：4 层（`presentation → domain ← data`），domain 0 Flutter 依赖。详见附 C.0。

---

## 4. 非功能需求

| 维度 | 指标 |
|---|---|
| 性能 | 打开主页 ≤1s；打卡响应 ≤100ms |
| 兼容性 | Web：iOS Safari / Android Chrome 最新两版；APK：Android 9+；iOS：14+ |
| 安全 | 本地数据 SQLCipher；密钥 flutter_secure_storage |
| 隐私 | GDPR / 个保法；最小数据原则（不收位置/IP/云端）|
| 离线 | 100% 离线打卡（失联检测客户端 SafetyWatch）|
| 数据量 | 单用户 1 年 ≤ 1MB（含 vent audio） |

---

## 5. 验收标准

| 模块 | 验收 |
|---|---|
| 主页加载 | ≤1s 显示大按钮 |
| 打卡 | 点击 ≤100ms 响应，本地记录成功 |
| 连续天数 | 漏 1 天不归 0；漏 3 天归 0 |
| 失联通知 | 模拟连续 48h 未打卡，48h 后 SMS 通知紧急联系人 |
| 多联系人 | 支持 1-3 个，按顺序发送 |
| 临时吃药 | 任意时间能添加，关联到现有药物，不影响 streak |
| 树洞 | 文字 / 录音 / 混排；删除时 audio 文件 best-effort 同步删 |
| 树洞隔离 | grep 全代码确认 vent 数据**无任何** trend / assessment / CareEngine 引用 |
| 隐私 | 飞行模式可打卡；本地数据 SQLCipher 加密 |
| 跨端 | iOS Safari + Android Chrome + 微信内置浏览器均可 |
| 测试 | `flutter test` 全过（**462 cases**） |

---

## 6. 商业模式

| 维度 | 值 |
|---|---|
| 定价 | 8 元付费下载（与死了么对齐）|
| 平台 | Google Play + App Store |
| 内购 | v1.x 可加"高级提醒""多联系人"等 |
| 服务器成本 | SendGrid 免费 100 封/天，超出 $0.0006/封 |
| 收支平衡 | 1000 用户 × 8 元 = 8000 元，足够覆盖 1-2 年运营 |

---

# 附录

> 附录 A-F 描述 v0.15 实际形态。代码实现细节见 `AGENTS.md`。

## 附 A. 产品结构（v0.15 实际模块树）

```
慢病管家 v0.15
├── 主页（Home）
│   ├── 大按钮 1：「我今天吃了药」（每日 1 次 / normal）
│   ├── 大按钮 2：「临时吃药 +」（关联到现有药物 / temp）
│   ├── 连续天数 / 总打卡 / 总天数 + 鼓励文案
│   ├── 今日服药计划（v0.14）
│   ├── 情绪日记快捷按钮（v0.9）
│   ├── 倾诉入口 🌲（v0.15 → /vent 树洞）
│   ├── 5 分钟 Snooze 推迟（v0.10）
│   └── 最后吃药时间 + 下次提醒
├── 首次引导（Setup，两步 30s）
├── 设置（Settings）
│   ├── 联系人（v0.13 多档案 + soft delete + 排序）
│   ├── 吃药管理（增删改 / 时间点 / 续方 N 天）
│   ├── 提醒中心（v0.14：5 张卡集中管理）
│   ├── 续方管理（v0.14：状态优先级 + 4 状态徽章）
│   ├── 安全开关（v0.12：用户主动关闭失联通知）
│   ├── 数据管理（JSON 导出 / 导入）
│   └── 关于 / 免责声明 / 主题切换
├── 趋势页（Trend）
│   ├── 30 天打卡热力图 + 6 月柱状图
│   ├── 心理评估历史折线图（PHQ-9 + GAD-7）
│   └── 情绪日记趋势（v0.9）
├── 心理评估（Assessment）
│   ├── 评估页（PHQ-9 / GAD-7，第 9 题危机弹窗）
│   ├── 评估结果页（sparkline + PDF / Markdown 报告）
│   └── 评估历史独立页（v0.14：diff 徽章 + 严重度色）
├── 用药日历（v0.14，医生视角 7/30/90 天热力图）
├── 树洞（v0.15，**完全私密**）
│   ├── /vent 列表（按时间倒序 + 长 80 字预览 + 时长）
│   ├── /vent/compose 撰写（文字 2000 字 / 录音 m4a / 混排）
│   └── /vent/detail/:id 详情（完整内容 + 播放进度条）
│   └── ⚠️ 树洞不进入任何分析 / 通知 / 关怀 / 趋势
└── 通知系统
    ├── 本地通知（每日 20:00 + 药物时间点 + 10:00 软提醒 + 续方）
    ├── Deep Linking 路由（v0.11）
    └── 失联通知（SafetyWatch：启动 + 持续 1h + SMS 兜底）
```

## 附 B. 功能详细（v0.15 现状 vs v0.4 计划）

> 完整版见 `docs/CHANGELOG.md`。本表只列**关键差异**。

| 模块 | v0.4 计划 | v0.15 实际 | 差异 |
|---|---|---|---|
| 打卡 | normal + temp | ✅ + 关联到现有药物 | v0.7 加 |
| 失联通知 | 48h 邮件 | ✅ 4 种 CareEngine + SafetyWatch 启动 + 持续监测 | 比 v0.4 复杂 |
| 趋势图 | v1.5 | ✅ v0.6 提前 + v0.8 量表 + v0.14 评估历史 | 提前 1+ 版本 |
| 量表 | MVP 不做 | ✅ PHQ-9 + GAD-7 + 严重度分级 | **超出原计划**（用户刚需）|
| 本地加密 | AES-256 | ✅ **v0.14 SQLCipher**（v0.8 前裸存）| v0.14 修 |
| 续方 / 评估历史 / 用药日历 / 提醒中心 | v1.0 | ✅ v0.13-v0.14 提前 | 提前 1+ 版本 |
| 情绪日记 | 未计划 | ✅ v0.9（5 级 emoji）| 新需求 |
| 树洞 | 未计划 | ✅ v0.15（完全私密）| 新需求（Munger 反方）|
| 跨平台 | Web → APK → iOS | ✅ Web 跑通；APK/iOS v1.0 | 一致 |

## 附 C. 关键架构决策

### C.0 4 层架构（v0.14 落地，v0.15 vent 验证）

```
lib/
├── presentation/         # UI 层（Riverpod providers + pages + widgets）
├── domain/               # 领域层（0 Flutter 依赖）
│   ├── entities/         # 业务实体（*Entity 后缀）
│   ├── logic/            # 业务规则（量表 / streak / care engine / 报告）
│   ├── repositories/     # 抽象接口（无实现）
│   └── usecases/         # 用例
└── data/                 # 基础设施层
    ├── database/         # Drift 表 + mapper + 数据库
    ├── repositories/     # *RepositoryImpl
    ├── services/         # 通知 / 邮件 / SMS / 录音 / 导出
    └── utils/            # JSON / 格式化
```

**依赖方向**：`presentation → domain ← data`。**domain 层不能 import `package:flutter/...`**。

**核心约束**：
- 命名：drift 表 `@DataClassName('X')` 单数 + domain 实体 `XEntity`（避免 import 冲突）
- mapper 放 `data/database/*_mapper.dart`，**不放** domain 层
- presentation provider 暴露 `XRepository`（domain 接口），不暴露 impl
- UI 路由用 `context.push(...)` / `context.pop()`（go_router 习惯）

**带来的好处**：domain 纯 Dart 可独立测；业务可移植；repo swap 容易。

### C.1 CareEngine 规则引擎（v0.7 + v0.10 SafetyWatch）

4 种规则 + 失联检测：
- `none`：不触发
- `secondDayMissed`：漏 1 天 + 14 点前未打卡 → 主动 push 安慰
- `lateCheckInHabit`：连续 3 天 22 点后打卡 → 建议早睡
- `weekPerfect`：最近 7 天每天 22 点前打卡 → 庆祝
- **SafetyWatch**（v0.10）：启动跑一次 + 持续 1h 心跳监测 + 48h 未打卡 → SMS 兜底

未来扩展：接 LocalAiHook（MedGemma 1.5）用 LLM 替代规则。

### C.2 量表抽象（v0.8）

```dart
abstract class AssessmentScale { ... }
class Phq9Scale implements AssessmentScale { ... }
class Gad7Scale implements AssessmentScale { ... }
```

加新量表 2 步：新建 `xxx_scale.dart` + `scale_registry.dart` 加一行。

数据复用 `check_ins` 表（type='phq9'/'gad7' + note='{"scale":"phq9","scores":[1,2,...],"total":10}'），**不引入新表**。

### C.3 SMS / Email Provider 抽象（v0.7）

```dart
abstract class SmsProvider { Future<bool> send({...}); }
class MockSmsProvider implements SmsProvider { ... }     // 本地日志
class AliyunSmsProvider implements SmsProvider { ... }   // v1.0 真实 key
```

### C.4 树洞完全隔离（v0.15，**关键隐私边界**）

**Munger 反方**：如果树洞内容进趋势 / CareEngine / SafetyWatch，会破坏"私密空间"信任 → 用户根本不用。

**5 条不可违反**：
1. 树洞**完全独立**的表（`vent_entries`），不进任何分析
2. 树洞**不触发**任何通知（即便内容含"想死"也不通知家人）
3. 树洞**不进** CareEngine / SafetyWatch / 续方 / 评估 / 任何 trend
4. 主页入口独立（"倾诉 🌲"按钮，不混入情绪日记）
5. 命名 `VentEntryEntity`（domain）vs `VentEntry`（drift）—— 避免 import 混淆

**audio 文件管理**：存 `app docs/vent_audio/`（独立目录）+ DB 存绝对路径 + 删条目时 best-effort 删文件。

**4 层落地参考**：v0.15 树洞是 4 层架构的"模板案例"——`VentEntryEntity` + `VentRepository`（abstract）+ `VentRepositoryImpl`（Drift）+ 3 个 presentation 页面。

## 附 D. 测试与质量

| 指标 | 状态 |
|---|---|
| 代码质量门 | ✅ **0 errors / 0 warnings** |
| 测试覆盖 | **462 tests pass**（v0.8 86 → v0.15 +376）|
| 跑测 | `flutter test` ≈ 14 秒 |
| v0.15 新增 | 树洞 entity 20 个 + widget 6 个 |
| 覆盖率（domain）| 量表 + CareEngine + 评估 + mood + vent 全覆盖 |

**3 层测试结构**：
- **domain 业务**：纯 Dart，0 Flutter 依赖（最快 ≈1s）
- **data round-trip**：DB insert → entity → 校验
- **presentation widget**：`ProviderScope` overrides + `MaterialApp` + `tester.pumpAndSettle`

## 附 E. 已知遗留（v0.15 → v1.0）

| 项 | 状态 | 优先级 |
|---|---|---|
| Web 平台 CanvasKit 走 CDN（国内污染）| ✅ v0.8 修 | P0 ✅ |
| Web dev 模式 drift worker 404 | ✅ v0.8 修 | P0 ✅ |
| 本地数据加密 | ✅ v0.14 SQLCipher | P0 ✅ |
| 4 层架构 | ✅ v0.14 落地 + v0.15 vent 验证 | P0 ✅ |
| 多档案联系人 | ✅ v0.13 修 | P0 ✅ |
| 续方提前提醒 | ✅ v0.13 + v0.14 续方管理页 | P0 ✅ |
| 提醒中心 | ✅ v0.14 | P0 ✅ |
| 树洞（私密倾诉）| ✅ v0.15 | P0 ✅ |
| MedGemma 1.5 本地 AI 接入 | ❌ 接口就位（LocalAiHook），未接真实模型 | P2 |
| 真实 SendGrid key | ❌ v1.0+ 平台对接 | P2 |
| 拍照识别药盒 | ❌ v1.x | P3 |
| 家属/医生联动 | ❌ v1.x | P3 |
| APK / iOS 打包上架 | ❌ **v1.0** | P1 |
| 加密备份（DB 导出 + AES 压缩）| ❌ **v1.0** | P1 |
| 树洞全文搜索 / 时间轴可视化 | ❌ v1.x 体验增强 | P3 |

## 附 F. 下一步问题（v1.0）

之前 v0.4 提的 Q4（平台选择）✅ Web 先行。v0.14 提的 Q5（本地加密）✅ SQLCipher。v0.15 提的 Q6（私密倾诉）✅ vent。

**Q7**：v1.0 优先做什么？
- **A**：APK 打包 + Android 9+ 灰度 —— 真实用户验证
- **B**：加密备份（DB 导出 + AES 压缩 + 跨设备导入）—— 数据资产保护
- **C**：MedGemma 1.5 真实接入（设备 ≥6GB RAM）—— 差异化
- **D**：拍照识别药盒（CameraX + TFLite）—— 降低录入摩擦

建议 **A + B 并行**（真实用户 + 数据资产），C/D 推后到 v1.x。
