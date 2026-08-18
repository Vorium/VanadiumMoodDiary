# Mavis 个人 AI 工作站白皮书 v4.0

> **版本**：v4.0 · 2026-07-08
> **角色**：每次对话前的**基准阅读文档**（Baseline Reading）
> **维护者**：Mavis（个人 AI 助理）
> **变更原则**：所有数字、路线、决策以本文件为准；正文细节可查但不轻易改基线
> **核心目标**：**Java 全栈开发 + AI 集成 + 独立游戏开发 + 长期健康数据平台**（四路线并行）
> **v4.0 主要变化**：v3.2.2 patch → v4.0 整合 + 加路线 E 闲暇态 + 删卡顿思考 + 跨文件 dedupe + 升级目标读者

---

## 0. 文档说明

### 0.1 这是什么

本文件是 Mavis 与用户协作的**终极决策基线**。每次开启新对话时，Mavis 都应先读本文件，建立对用户目标、预算、工具栈、路线规划、工作方法论的**完整上下文**，再回答问题。

它不是教程——vibe-coding 内容已合并到白皮书 §3（路线 B）/ §4（superpowers）/ §6（接入层），正文无需另存。
它是**决策 + 边界**——告诉 Mavis **"我该怎么做"** 和 **"我不要做什么"**。

### 0.2 怎么用

| 时机 | 必读章节 |
|---|---|
| **新会话开始** | §1（决策快照）+ §0.5（核心原则）+ §2（四路线规划）|
| **讨论技术选型** | §1.5（工具箱）+ §6（接入层）+ §9（风险与边界）|
| **讨论学习方向** | §2（四路线完整规划）+ §3（AI 集成深度 + 路线 E 深度）|
| **讨论预算/计费** | §1.1（预算）+ 附录 B（价格动态）|
| **任务启动** | §4（superpowers 工作流）+ §8（执行准则）|
| **任务完成** | §8（执行准则）+ §10（变更历史检查）|
| **讨论慢病/健康数据** | §2.4（路线 E）+ §3.5（路线 E 深度）|

### 0.3 来源标注规则

**Mavis 每次回答时，必须在关键判断后标注来源**。来源格式：

```
来源：[章节号] [文档名]
示例：来源：§1.1 白皮书 / §2.2 白皮书 / §3.1 白皮书
     来源：v2.1 §4 ai-toolchain-baseline
     来源：白皮书 §2.1
     来源：superpowers §2.1
     来源：indie-game-whitepaper §3
     来源：ADR-0001 §3 / ADR-0002 §6
```

**来源类型优先级**（高 → 低）：
1. **本白皮书**（v4.0 决策，最新）
2. **ADR-0001 / ADR-0002**（路线 E 决策，私人项目文档）
3. **v2.1 ai-toolchain-baseline**（被本白皮书继承的旧决策）
4. **superpowers 工作流**（方法论）
5. **indie-game-whitepaper.md**（独立游戏架构）
6. **ai-coding-tutorial.md**（编程工具教程）
7. **skills-toolkit**（工具箱详细）
8. **llm-pricing-2026-q2**（价格动态）
9. **外部仓库**（标注仓库名 + 章节）

### 0.4 四个核心目标（v4.0 新加路线 E）

| # | 目标 | 优先级 | 状态 | 路线 |
|---|---|---|---|---|
| **A** | **Java 全栈开发** | P0 主线 | 进行中（尚硅谷主线）| 路线 A |
| **B** | **AI 集成** | P0 主线 | 路线 A 完成后立即启动 | 路线 B |
| **C** | **独立游戏开发** | P1 并行 | Unity 2D 方向，按兴趣推进 | 路线 C |
| **E** | **长期健康数据平台** | P0.5 闲暇态 | 私人项目，≤10% 时间 / 每周 ≤3h | 路线 E |

> **来源**：用户 2026-06-23 明确目标变更（A/B/C）+ 用户 2026-07-08 12:08 升级决策（E2+E3 → 路线 E 长期健康数据平台）。
> **v4.0 关键变化**：3 路线 → **4 路线**。路线 E 是私人项目（**不商业化、不进简历**），仅作为 AI 时代的个人健康数据资产。

### 0.5 5 个核心原则

> 这 5 条是 Mavis 协作的**最高准则**——任何决策冲突时按这 5 条裁决。

1. **决策先于行动** — 复杂任务先 superpowers 走 brainstorming → writing-plans，再动手
2. **规划就是一切** — 来源：vibe-coding-cn §"道"。上下文是 vibe coding 的第一性要素
3. **凡是 AI 能做的，就不要人工做** — 接入层主力是 Mavis，AI 接管确定性任务
4. **路线选择给明确建议** — 不只列 pros/cons，给出"我建议 X 因为 Y"
5. **学习铁律：选定一条路线后坚持按一套教程完整做完再换** — 不并行学多套（同路线内可并行）

**v4.0 新加第 6 条**（从卡顿循环教训中提炼）：
6. **长文档必须用 sub-agent 写** — Mavis 主线程写长文档必陷入"executing-planning"独白循环。**规则**：超过 5KB 的新文档生成必须 spawn sub-agent 写 + 强制章节完成标记

### 0.6 目标读者（v3.2 新加 + v4.0 升级）

本白皮书**为三位目标读者准备**，按章节分工：

| 读者 | 必读章节 | 重点关注 |
|---|---|---|
| **新产品经理** | §0 + §1 + §2 + §3 + §10.1-10.3 | 四路线规划 / 决策 / 风险 / 用户决策记录 |
| **岚开发团队** | §4 + §5 + §6 + §7 + §10.4 | superpowers 工作流 / 工具箱 / 接入层 / 基础设施 / 审查 Hook |
| **路线 E owner（用户本人）** | §2.4 + §3.5 + ADR-0001 + ADR-0002 | 健康数据平台设计 / 慢病管理模块 / MVP 6 模块 |

**阅读建议**：
- 30 分钟上手：先读 §0.5 原则 + §1 决策快照 + §2 路线规划 + §10 决策记录
- 60 分钟深入：再读 §3 AI 集成 + 路线 E 深度 + §6 接入层 + §7 基础设施
- 完整阅读（2 小时）：按 §0.2 章节速查表逐章读

### 0.7 v4.0 升级摘要（2026-07-08）

| 类型 | 改动 |
|---|---|
| **新增路线** | §0.4 三目标 → **四目标**（A/B/C/E 闲暇态）|
| **新增路线 E** | §2.4 路线 E 闲暇态（≤10% / 每周 ≤3h）+ §3.5 路线 E 深度（健康数据平台 / 4 层架构 / 6 模块 MVP / 多邻国等级系统 / ADR 索引）|
| **新增决策** | 38 决策 → **~46 决策**（+ 路线 E 7 个：D8.5 / D8.6 / D8.7 / D8.8 / D8.9 / D8.10 / D8.11）|
| **新增风险** | 9 风险 → **11 风险**（+ R12 量表评估触发抑郁 + R13 长期数据迁移）|
| **清理卡顿** | 删除 v3.2.1 §0.8 "TODO 留 B3-B5" / v3.2.2 §0.9 "iPad 4 层架构待办" / v3.2 §D.7.5 "v3.3 升级待评估" / v3.2 §10.4 "v2 标记已加" |
| **修正位置** | §0.5 核心原则从原位置错乱（v3.2 实际在 §0.8 §0.9 之后）→ v4 修正到 §0.5 标准位置 |
| **新增准则** | §0.5 第 6 条 = "长文档必须用 sub-agent 写"（v4.0 升级踩坑教训）|
| **新增治理** | §10.5 v4 治理周期 + v5.0 升级触发条件 |
| **跨文件 dedupe** | 3 组精确重复（superpowers zip 3 副本 + AI 工具链 md 3 副本 + ADR-0001 中英文 2 副本）+ 24 个语义主题（**全部是有意冗余引用，保留**）|

### 0.8 变更历史（v3 → v4）

| 日期 | 版本 | 变更 | 触发 |
|---|---|---|---|
| 2026-06-23 | v3.0 | 目标变更：Java 全栈 + AI 集成 + 独立游戏（**三路线**）| 用户 |
| 2026-06-24 | v3.1 | 附录 D 增量：阿里云价格修正 / NAS vs 云重算 / MiMo Token Plan 5-8 倍 | 数据校正 |
| 2026-06-25 | v3.1.x | 用户最终方案决策（绿联 DXP4800 4515 + 阿里云 199）+ OpenClaw 微信 ClawBot | 用户 |
| 2026-06-26 | v3.2 | v3.1 → v3.2 全面整合 + 删除过期内容 + 加 §10 用户决策 + 加目标读者（产品经理 + 岚开发团队）| 整合 |
| 2026-06-26 | v3.2.x | 校正 §10.4 code-reviewer subagent 错误描述 + 同步 superpowers v6.0.3 关键更新 | 校正 |
| 2026-06-27 | v3.2.1 | patch：白皮书审查 hook v2 上线（3 skill 协作）+ v3.2 §0.8 §10.4 §D.7.5 升级 | hook v2 |
| 2026-07-06 | v3.2.2 | patch：硬件切换 4 层架构（iPad Pro 13 M5 + UTM Win10 ARM + 阿里云 ECS + 绿联 NAS）+ 决策 33→38 + 风险 +2 | iPad M5 采购 |
| **2026-07-08** | **v4.0** | **整合升级：加路线 E 闲暇态 + 删卡顿思考 + 跨文件 dedupe + 决策 38→46 + 风险 9→11 + 治理 v4 周期** | **v3.1 §D.7.5 条件 5（路线 E 升级）**|

### 0.9 与 v3.2 关键差异（**v4 升级对比**）

| 维度 | v3.2.2 patch | v4.0 | v4 升级依据 |
|---|---|---|---|
| **路线数** | 3（A/B/C）| **4（A/B/C/E）**| 路线 E 升级触发 |
| **决策数** | 38 | **~46（+7）**| 路线 E 7 个新决策 |
| **风险数** | 9 | **11（+2）**| R12/R13 路线 E 风险 |
| **§2 路线规划** | 3 路线串/并行 | **4 路线**（A 串 B 串 + C 并行 + E 闲暇态）| 路线 E 加 |
| **§3 深度展开** | AI 集成 5 方向 | **+ §3.5 路线 E 深度** | ADR-0002 v2 升级 |
| **§10 治理** | hook v2 | **+ §10.5 v4 治理周期** | v4 升级配套 |
| **附录 D** | v3.1 + v3.2 增量 | **+ §D.8 v4 增量** | v4 升级配套 |
| **卡顿思考** | v3.2.1/v3.2.2 patch 留 TODO | **全部清理闭环** | 升 v4 |

---

## §0 完成

## 1. 核心决策快照

### 1.1 模型 API 预算

```
总预算：1710 元/年（模型 API 费用，不含服务器）
  ├─ Mavis Token Plan Max：710 元/年（补差价升级）
  └─ DeepSeek API：1000 元/年
原始预算：1870 元 → v2 收紧 160 元作为应急/观察预算
DeepSeek 月度上限：~83 元（1000 ÷ 12）
```

> **来源**：v2.1 §1.1 ai-toolchain-baseline / §4.1 / §4.3
> **变更**：无（v3.0 继承 v2.1 预算 / v4.0 继承 v3.2 预算）

### 1.2 工作方法论（三层叠加底座 · 2026-06-26 升级）

按 decision-council v0.1.1 §6.2 调用决策树，**3 个 skill 各司其职、共享同一毛氏 OS 底座**：

```
新会话开始 / 任何决策瞬间
  ↓
Step 1: decision-council §3（先跑一遍）
  - 抓主要矛盾（毛氏 #3）+ 反方机制
  - 6 个万能问句：签名测试 / 二选一 / 不可能但你敢不敢想 / 行业惯例 vs 真理 / 实践-认识循环
  ↓
Step 2: 是否 PM 相关？
  - 是 → product-manager v0.6 §3（7 阶段映射 + 7 个 output template）
  - 否 → 跳过
  ↓
Step 3: 任何任务执行
  - superpowers 7 阶段流水线（brainstorming → plan → execute → TDD → debug → review → verification）
```

**3 个 skill 的角色**（按 decision-council v0.1.1 §6.3 边界）：

| Skill | 角色 | 层 | 触发词 |
|---|---|---|---|
| **decision-council** | 抽象底座（毛氏 OS）+ 决策齿轮（Jobs/Musk/反常识）| 2 层（抽象+决策）| "该不该做 X" / "卡住了" / "分析瘫痪" |
| **product-manager v0.6** | PM 专用引擎 | 3 层（抽象+决策+执行）| "PM 视角" / "PRD" / "路线图" / "retro" |
| **superpowers** | 执行脚手架 | 7 阶段流水线 | 任何编程/任务执行 |

**共享底座**：3 个 skill 都使用**毛氏 OS**（矛盾论+实践论）作为抽象层——这是 decision-council v0.1.1 §1.1 的核心架构。

**反模式禁**（仍然适用）：上来就动手 / 跳过 Plan / 写完不测 / 乱改 Bug / 口头完成 / 套行业惯例 / 不抓主要矛盾

**记忆触发**：新会话开始时**先跑 decision-council §3 Step 1**（抓主要矛盾 + 签名测试）—— 决定"如何看问题"，再进入 superpowers 7 阶段。

### 1.3 接入层 / 调度层 / 执行层

```
接入层（唯一）：Mavis Agent Desktop + Pocket
  ├─ 桌面端：Windows + Mac，本地文件 + Browser Use + Computer Use
  └─ Pocket Beta：WeCom / Slack 远程指挥

调度层：Spring Boot API Gateway（自建）
  ├─ Redis + Lua 原子熔断（财务保护）
  ├─ 多模型路由（DeepSeek / Mavis API / MiMo API）
  └─ 任务队列

执行层（80/20 分层）：
  ├─ Mavis Agent Teams（云端主力，80% 任务）
  └─ OWL + OpenManus（自建兜底：涉密/沙盒/批量）
```

> **来源**：v2.1 §1.4 / indie-game-whitepaper §3

### 1.4 基础设施

- **云厂商**：阿里云轻量（首选）/ 腾讯云（备选）
- **OS**：Ubuntu 22.04 LTS（唯一指定）
- **容器**：Docker Compose（强制，不用宝塔）
- **IM 远程控制**（双通道）：
  - **微信 WeCom**——任务派发（Mavis Pocket 已集成）
  - **微信 ClawBot**——设备操控（OpenClaw 设备手机端管理，v3.1 §D.6.2）
- **拓扑**：1核2G 网关 + 2核4G Agent 节点
- **4 层架构**（v3.2.2 patch · v4 升级继承）：
  - Layer 1：iPadOS 18+（用户主力开发设备，2026-07-06 切换）
  - Layer 2：UTM Win10 ARM64 VM（6GB 内存 / 4 核 / 128GB VHDX）
  - Layer 3：阿里云 ECS u1 2核4G（Docker + Docker Compose）
  - Layer 4：绿联 DXP4800 + 8TB×2 RAID1（数据本地 + 备份）

> **来源**：v2.1 §1.5 / §4.7 / v3.1 §D.6.2 / v3.2.2 patch §0.9
> **iPad 切换理由**：便携 + 触屏 + 长续航 + 妙控键盘 = 移动开发体验升级
> **Win10 ARM vs Win11 ARM 决策**：节省 2GB 内存（iPad 16GB 紧张）

### 1.5 工具箱（10 Skill）速查

| # | Skill | 用途 | 状态 |
|---|---|---|---|
| 0 | **superpowers** | 元方法论（任何编程任务前置） | 必备 |
| 1 | **agent-reach** | 跨 14 平台信息获取 | 推荐 |
| 2 | **notebooklm-skill** | Google NotebookLM 文档 RAG | 可用 |
| 3 | **bb-browser** | 云端浏览器反爬 | 推荐 |
| 4 | **skill-creator** | 创建新 Skill（已加载） | 已加载 |
| 5 | **find-skills** | 搜索 20 万+ Skill | 必备 |
| 6 | **frontend-design** | Anthropic 官方前端设计 | 推荐 |
| 7 | **ui-ux-pro-max** | UI/UX 设计智能引擎 | 推荐 |
| 8 | **playwright mcp** | 微软本地浏览器 MCP | 推荐 |
| 9 | **humanizer-zh** | 去中文 AI 味 | 推荐 |

> **来源**：v2.1 §1.3 / skills-toolkit

### 1.6 当前活跃限制（必看）

1. **SaaS Plus 订阅 ≠ API 无限调用**——代码层 API 必须独立计费（DeepSeek/MiMo/MiniMax API 都一样）
2. **`deepseek-chat` / `deepseek-reasoner` 将在 2026-07-24 弃用**——配置必须用 `deepseek-v4-pro` / `deepseek-v4-flash`
3. **OpenClaw 通过微信 ClawBot 重新可用为手机操控通道**——执行层主力仍是 Mavis Agent Teams + OWL/OpenManus，OpenClaw 通过微信 ClawBot 补充**设备操控**层
4. **飞书 IM 网关已弃用**——任务派发走微信 WeCom，设备操控走微信 ClawBot
5. **v4.0 新加**：长文档（>5KB）必须 spawn sub-agent 写——Mavis 主线程写长文档必卡循环（v4.0 升级踩坑教训写入）

> **来源**：v2.1 §0.3 / §1.6 / 白皮书 §0.4 / v3.1 §D.6.2 / v4.0 §0.5

### 1.7 决策清单（**v4 升级** ≈ 46 决策）

| 编号 | 决策内容 | 类别 | 状态 |
|---|---|---|---|
| D1 | 模型 API 预算 1710 元/年（Mavis Max 710 + DeepSeek 1000）| 预算 | ✅ |
| D2 | 路由策略：文本→DeepSeek / 多模态→Mavis Max | 路由 | ✅ |
| D2.5 | iPad Pro 13 M5 1TB 16GB 主力开发设备 | 硬件 | ✅ v3.2.2 |
| D3 | 接入层主力 = Mavis Agent Teams | 架构 | ✅ |
| D4 | 调度层 = Spring Boot API Gateway | 架构 | ✅ |
| D4.4 | UTM 跑 Win10 ARM64（不是 Win11 ARM）—— 节省 2GB 内存 | 架构 | ✅ v3.2.2 |
| D4.5 | Docker + Docker Compose 全部跑阿里云 ECS（不在 iPad）| 架构 | ✅ v3.2.2 |
| D5 | OS 唯一 = Ubuntu 22.04 LTS | 基础设施 | ✅ |
| D6 | NAS = 绿联 DXP4800 + 8TB×2 RAID1 = 4515 元 | 基础设施 | ✅ |
| D7 | 云 = 阿里云 ECS u1 2核4G = 199 元/年 | 基础设施 | ✅ |
| D8 | 工作方法论 = decision-council + product-manager + superpowers 三层叠加 | 方法论 | ✅ |
| D8.4 | iPad UTM Win10 ARM64 + 4K 外接显示器 | 硬件 | ✅ v3.2.2 |
| **D8.5** | **路线 E = 长期健康数据平台（私人项目）** | **路线 E** | **✅ v4.0** |
| **D8.6** | **路线 E 时间预算 ≤10% / 每周 ≤3h** | **路线 E** | **✅ v4.0** |
| **D8.7** | **路线 E 病种聚焦 D1 糖尿病** | **路线 E** | **✅ v4.0** |
| **D8.8** | **路线 E 不商业化、不进简历** | **路线 E** | **✅ v4.0** |
| **D8.9** | **路线 E 4 层架构复用（iPad + UTM + ECS + NAS）** | **路线 E** | **✅ v4.0** |
| **D8.10** | **路线 E MVP 6 模块 39h / 13 周** | **路线 E** | **✅ v4.0** |
| **D8.11** | **路线 E 等级系统（多邻国风格 铜/银/金/钻）** | **路线 E** | **✅ v4.0** |
| D9 | IM 远程控制 = 微信 WeCom（任务派发）+ 微信 ClawBot（设备操控）| IM | ✅ |
| D10 | 路线 A = Java 全栈主线（尚硅谷 / 黑马）| 路线 | ✅ |
| D11 | 路线 B = AI 集成主线（路线 A 完成后启动）| 路线 | ✅ |
| D12 | 路线 C = 独立游戏 P1 并行 | 路线 | ✅ |
| D12.x | 路线 C 工具 = Unity Editor X iPad 原生版 | 路线 C | ✅ v3.2.2 |
| D13 | superpowers v6.0.3 是中国化版（用户定制）| 方法论 | ✅ v3.2.2 |
| D14 | whitepaper-watcher-hook v2 = decision-council + product-manager + superpowers 协作 | 治理 | ✅ v3.2.1 |
| D15 | cron 任务 `whitepaper-watcher-v2` (task_id 412827785302108, 每 5 分钟)| 治理 | ✅ v3.2.1 |

> **来源**：ADR-0002 v2.0 §1 + §3 + v3.2.2 patch §0.9 + v4 升级新增
> **统计**：v3.2.2 patch = 38 决策 → **v4.0 = ~46 决策（+ 路线 E 7 个）**

---

## §1 完成

## 2. 四条路线完整规划（**v4 升级**）

### 2.1 路线 A：Java 全栈开发（**P0 主线**）

**为什么是 P0**：
- 学习铁律要求"选定一条路线后坚持跟完一套教程再换"
- 路线 A 是路线 B（AI 集成）的**前置依赖**——Java 基础 + Spring Boot 不扎实，AI 集成无从下手
- 路线 C（独立游戏）也需要 Java 思维（ECS、调度）作底
- 路线 E（健康数据平台）也用 Spring Boot 3.4 + Java 17 复用（见 §3.5）

**学习路径**（尚硅谷主线 + 黑马辅助）：
```
Java 基础（宋红康 30 天）
    ↓
MySQL / MyBatis
    ↓
前端三件套 + Vue
    ↓
Spring Boot / Spring Cloud（雷丰阳）
    ↓
项目实战（谷粒商城 / 尚医通）
    ↓
    ├─ 启动路线 B（AI 集成）
    ├─ 路线 C（独立游戏）可并行启动
    └─ 路线 E（健康数据平台）闲暇态启动
```

**核心能力图谱**：见 v2.1 §10（Linux/DB/JVM/算法/命令）

**v3.2.2 patch · v4 升级继承**：路线 A 工具栈 = VSCode + IntelliJ IDEA Community + Java JDK 17 ARM + Claude Code（切国内）+ 通义灵码，**全部跑 UTM Win10 VM**（不在 iPad 原生）

> **来源**：v2.1 §1.6 / §11.1 / 白皮书 §2.1 / v3.2.2 patch

### 2.2 路线 B：AI 集成工程师（**P0 主线，紧接 A**）

> **本节是 v3.0 新增重点章节**——基于 2026-06-22~23 用户对话。

**为什么独立成路线（而非 A 的扩展）**：
- AI 集成是**完整的新岗位**（Java AI 集成工程师 = 25-50K/月）
- 与 A 共享基础（Java + Spring Boot），但**新技能栈**（Spring AI + RAG + Agent + Prompt）
- 投入 2 个月能成为"Java + AI 集成"双栈——v3.0 必走

**5 阶段学习路径**：

| 阶段 | 时长 | 目标 | 关键产出 |
|---|---|---|---|
| **B.1** | 2-3 天 | 调通 DeepSeek API | Java + Spring Boot 调通 DeepSeek-V4-Pro |
| **B.2** | 3-5 天 | Prompt 工程 | 4 种模式（Zero/Few-shot/CoT/ReAct）|
| **B.3** | 1-2 周 | Spring AI + RAG 基础 | Embedding + 向量数据库 + 检索 |
| **B.4** | 2 周 | Agent 框架 | Function Calling + LangGraph + 工具调用 |
| **B.5** | 4-6 周 | 简历级项目 | 见 §3.3 |

**5 个高价值方向**（商业价值排序）：

1. **企业级 RAG 系统**（最稳）— Spring AI + Milvus + DeepSeek
2. **AI Agent 平台**（最热）— 多 Agent 协作 + 工具调用 + 工作流，30-60K/月
3. **AI 代码助手后端**（最直接）— 基于 DeepSeek API 做 Java 代码评审/生成
4. **传统业务 AI 化改造**（最广）— ERP/CRM/OA 加 AI 能力
5. **AI 中间件**（最有壁垒）— LLM Gateway / Token 调度 / 熔断

> **来源**：白皮书 §3.1 / 2026-06-22 对话

### 2.3 路线 C：独立游戏开发（**P1 并行**）

**为什么 P1（并行而非 P0）**：
- 学习铁律："选定一条后坚持跟完"——P0 只能有一条
- 但独立游戏是**用户兴趣 + 长期价值**——可作为 A/B 完成后的"调剂 + 长期资产"
- 启动时机：A 项目阶段 + B 启动前/后均可

**学习路径**（Unity C# 2D 入手）：
```
C# 基础语法
    ↓
Unity 2D（B 站 M_Studio 跟做 Ruby's Adventure）
    ↓
完成 1 个完整小游戏
    ↓
改出自己创意 + 参与 Game Jam
    ↓
（可选）路线 B 协作：AI 辅助游戏内容生成（NPC 配音、剧情、对白）
```

**v3.2.2 patch · v4 升级继承**：路线 C 工具 = **Unity Editor X iPad 原生版**（替代 PC Unity）

> **来源**：v2.1 §11.2 / indie-game-whitepaper §1 / 白皮书 §2.3 / v3.2.2 patch

### 2.4 路线 E：长期健康数据平台（**P0.5 闲暇态 · v4 新加**）

> **本节是 v4.0 新增重点章节**——基于 2026-07-08 12:08 用户决策（E2+E3 升级）。

**为什么独立成路线 E（而非路线 A 扩展）**：
- 慢病管理 ≠ 简历级项目（**不商业化、不进简历**）
- 慢病管理 ≠ AI 集成项目（**纯个人健康数据**，与商业 RAG/Agent 无商业关联）
- 但需要 Java 技术栈（**复用路线 A ≥70%**：Spring Boot 3.4 + PostgreSQL 17 + TimescaleDB 2.18）
- 慢病管理 = **私人项目**：仅用户本人使用，10 年长期数据沉淀

**核心定义**（ADR-0002 v2.0 §3 + §5）：

> **路线 E = 私人健康数据平台 ≠ 简历级项目 ≠ 商业产品**
> 
> 三条铁律：
> 1. **服务对象**：仅用户本人（及直系亲属授权账号，未来可选）
> 2. **数据归属**：所有健康数据归用户私有，NAS 本地为主，ECS 仅为访问入口
> 3. **代码公开**：GitHub 仓库 private（不公开不求职背书），仅自己可见

**时间预算**（硬约束）：
- 总投入 ≤10% 个人时间
- 每周 ≤3 小时
- 13 周 MVP 周期（2026-07-15 → 2026-10-15 demo）
- 39h MVP 总工时

**病种聚焦**：
- **D1 糖尿病**（核心，慢病管理主线）
- 备选扩展：高血压 / 血脂异常 / 抑郁焦虑（**v3 延后**，作为多慢病模块化基础）

**MVP 6 模块**（详见 §3.5 + ADR-0002 v2.0 §6）：

| 模块 | 内容 | 工时 |
|---|---|---|
| M1 多慢病模块化可视化 | 通用慢病卡片 + 趋势图 + 告警规则 | 8h |
| M2 吃药打卡 + 等级 + 临时变化 | 多邻国等级系统 + 临时吃药 | 12h |
| M3 量表评估（PHQ-9/GAD-7/慢病 QoL）| 量化评估 + 触发建议 | 8h |
| M4 冥想 + 助眠 + 情绪记录 | 心理健康 | 6h |
| M5 BMI + 体脂 + 饮食 + 体重 | 身体数据 | 5h |
| M6 血压 + 血糖 + 用药提醒 + 趋势预测 | 复用 v1 + 趋势预测 | 4h |
| **总工时** | | **43h → 砍 4h 趋势预测深度 = 39h** |

**与路线 A/B/C 的并行策略**：
- **不抢占主线时间**（≤10% / 每周 ≤3h）
- **复用 A 的技术栈**（Java + Spring Boot + PostgreSQL）
- **不依赖 B 完成**（独立启动，但可借鉴 Spring AI 优化）
- **不与 C 抢兴趣时间**（C 是 Unity 兴趣，E 是健康数据兴趣，两者并列）

**4 层架构复用**（D8.9）：
- Layer 1：iPadOS（Flutter 客户端开发）
- Layer 2：UTM Win10 ARM（Flutter Desktop 调试）
- Layer 3：阿里云 ECS（Spring Boot 后端 + PostgreSQL）
- Layer 4：绿联 NAS（健康数据本地备份）

> **来源**：ADR-0002 v2.0 §3 + §5 + §6 + 用户 2026-07-08 12:08 决策
> **关键决策**：D8.5 / D8.6 / D8.7 / D8.8 / D8.9 / D8.10 / D8.11（v4.0 升级新增）

### 2.5 四路线的并行策略（v3 升级 3→4）

**核心原则**：
- **A + B 串行**（A 完成后立即 B）—— 学习铁律要求
- **C 与 A/B 并行**（仅作为兴趣 / 调剂）—— 不抢占主线时间
- **E 与 A/B/C 全部并行**（**v4 新加**）—— ≤10% 闲暇态，不抢任何主线时间
- **任何时候主线只能是 1 条**（A 或 B）—— 切换时点要明确

**时间表**（v4 升级：12-18 个月布局 + 路线 E 闲暇态）：

```
[现在] ── 6-9 月 ── 路线 A 完成项目阶段 ──┬── 6-9 月 ── 路线 B 完成 AI 集成 ──┬── 持续 ── 路线 C 兴趣推进
                                           │                                  │
                                           ├─ 阶段 B.1: 2-3 天                ├─ 持续利用：
                                           ├─ 阶段 B.2: 3-5 天                │  - Mavis 多模态做概念 PV
                                           ├─ 阶段 B.3: 1-2 周                │  - DeepSeek 做 NPC 对白
                                           ├─ 阶段 B.4: 2 周                  │  - Agent Teams 做剧情设计
                                           └─ 阶段 B.5: 4-6 周（简历级项目）  │
                                                                              │
                                                                              ├─ 路线 C 启动时机：
                                                                              │   A 项目阶段 + B 启动后任何时点
                                                                              │
                                                                              └─ 路线 E 启动时机（v4 新加）：
                                                                                  2026-07-15 → 2026-10-15
                                                                                  (与 A/B/C 完全并行，每周一三五晚上各 1h)
```

> **来源**：白皮书 §2.4（v3.0 升级 v4.0 加路线 E）

---

## §2 完成

## 3. AI 集成路线深度展开（v3.0 重点）+ 路线 E 深度（v4.0 新加）

> **本节包含两部分**：§3.1-§3.4 AI 集成路线（v3.0）+ §3.5 路线 E 深度（**v4.0 新加**）

### 3.1 5 个高价值方向（详细）

#### 方向 1：企业级 RAG 系统（**最稳**）

**做什么**：把企业文档/知识库/工单系统接入 LLM，让员工用自然语言查公司资料。

**技术栈**：Spring AI + 向量数据库（Milvus/Chroma）+ 文档切片 + 检索增强

**v3.2.2 patch（2026-07-06）调整 + v4 升级继承**：路线 B 启动后，Spring AI + Milvus + Ollama **全部跑在阿里云 ECS Docker**（不在 iPad / NAS）。详细 4 层架构见 §7。iPad UTM Win10 VM 仅做 IDE 开发，不跑 Docker。

**客户**：银行、保险、政府、制造业

**单项目报价**：50-200 万（外包）/ 25-40K/月（全职）

#### 方向 2：AI Agent 平台（**最热、薪资最高**）

**做什么**：多 Agent 协作 + 工具调用 + 工作流编排。

**技术栈**：Spring AI + Function Calling + 工作流引擎（Flowable / Camunda）+ 向量数据库

**薪资**：30-60K/月（一线 3-5 年经验 + Agent 经验）

**与 Mavis Agent Teams 的协同**：
- Mavis Agent Teams 用的就是 Leader + Worker + Verifier 架构
- 你已经是这个思想的**用户**——理解这个架构后再实现一遍就是简历上的硬货
- **双向收益**：用 Mavis 学 Agent 思想 → 用 Spring AI 实现 → 反哺 Mavis 用法

#### 方向 3：AI 代码助手后端（**最直接、最快出活**）

**做什么**：基于 DeepSeek API 做 Java 代码评审/生成/重构工具。

**5 天能做出 MVP**（基于 v2.1 DeepSeek 配置）：

```java
@RestController
@RequestMapping("/api/ai")
public class CodeReviewController {
    
    @Autowired
    private DeepSeekService deepSeek;
    
    @PostMapping("/review")
    public ReviewResult review(@RequestBody CodeRequest request) {
        String prompt = """
            你是一个资深 Java 架构师。请评审以下代码：
            1. 🔴 严重问题
            2. 🟡 设计问题
            3. 🟢 优化建议
            代码：%s
            """.formatted(request.getCode());
        
        return parseReview(deepSeek.chat(prompt));
    }
}
```

**价值**：直接挂 GitHub = **简历亮点**。面试必问。

#### 方向 4：传统业务 AI 化改造（**最广、量最大**）

**做什么**：ERP/CRM/OA/工单系统 加 AI 能力。

**为什么量大**：所有企业都在做"AI+" 改造，但他们的核心系统是 **Java 写的**——**只有 Java 程序员能改**。

#### 方向 5：AI 中间件（**最有壁垒、跟基线最重合**）

**做什么**：LLM Gateway、多模型路由、Token 调度、熔断、审计。

**v3.0 关键洞察**：

```
[你的 v2.1 基线]                [AI 时代升级]
Spring Boot Gateway      →    Spring AI Gateway
Redis + Lua 熔断         →    Token 预算 + 模型路由
DeepSeek API            →    DeepSeek + Claude + GLM 多模型
Mavis Agent Teams 调度   →    AI Agent 协作 + 工具调用
```

**这个方向你比别人早走了 6 个月**——别人还在规划，你已经在实现。

> **来源**：白皮书 §3.1 / 2026-06-22 对话

### 3.2 简历怎么写（v3.0 新增 · v4 升级继承）

**❌ 伪简历**：
> "熟悉 LLM、Prompt 工程、LangChain、Hugging Face"

**✅ 真简历**：
> "独立完成 XX 银行内部知识库 AI 化项目，基于 Spring AI + Milvus + DeepSeek-V4-Pro 架构，QPS 800+，日均处理 12 万次查询，文档召回率 92%，节省人工检索时间 70%。"

**第二种简历比第一种薪资高 50%**。

**v3.2.2 patch · v4 升级继承**：简历级项目的"部署位置"必须写**阿里云 ECS Docker**（不是本地），体现云端实战经验。

> **来源**：白皮书 §3.2 / 2026-06-22 对话

### 3.3 简历级项目清单

| 项目 | 难度 | 简历价值 | 推荐顺序 |
|---|---|---|---|
| AI 代码评审工具 | ⭐ | 高 | B.5 第 1 个做 |
| 企业内部知识库 RAG | ⭐⭐ | 极高 | B.5 第 2 个做 |
| 数据分析 Agent | ⭐⭐ | 高 | B.5 第 3 个做 |
| AI 客服系统 | ⭐⭐ | 中 | 备选 |
| 多 Agent 协作系统 | ⭐⭐⭐ | 极高 | B.5 最后做（旗舰项目）|

> **来源**：白皮书 §3.3

**v3.2.2 patch · v4 升级继承**：
> **路线 A/B/C 部署位置变更**：路线 B / C 简历级项目的部署从"本地"统一调整为"**阿里云 ECS Docker**"（不在 iPad / NAS）。配合 4 层架构（iPadOS + UTM Win10 ARM + 阿里云 ECS + 绿联 NAS），路线 B 的 Spring AI / Dify / Ollama / Milvus 等组件全部跑 ECS，路线 C 的联机服务器也跑 ECS（如果做联机）。

### 3.4 与 Mavis Agent Teams 的协同（v3.0 新增 · v4 升级继承）

```
[你用 Mavis 学 Agent]  →  [用 Spring AI 实现]  →  [反哺 Mavis 用法]
       ↓                       ↓                       ↓
   理解架构               简历硬货                提升效率
   (方向 2 思想)          (方向 1-4 实现)         (路线 A/B/C 加速)
```

**实操建议**：
- 路线 B.4 学 Agent 时，**同步用 Mavis Agent Teams 跑真实任务**
- 体会"Leader 拆解 → Worker 执行 → Verifier 校验"的实际效果
- 再用 Spring AI / LangGraph 实现一遍——理解 + 简历双赢

> **来源**：白皮书 §3.4（v3.0 新增 · v4 升级继承）

### 3.5 路线 E 深度：长期健康数据平台（**v4.0 新加**）

> **本节是 v4.0 关键新增**——详细展开路线 E（私人项目）的设计。

#### 3.5.1 项目定义

**核心定位**（ADR-0002 v2.0 §3）：

> **长期健康数据平台** = 用户本人的私人健康档案
> - 服务对象：仅用户本人（未来可选直系亲属）
> - 数据归属：用户私有（NAS 本地为主，ECS 仅为访问入口）
> - 时间视角：**≥10 年**长期数据沉淀
> - 商业化：**不做商业化**（私人项目，不上 GitHub 公开主页）
> - 简历：**不进简历**（私人项目，代码是自用，不是为了背书）

**为什么是 v4.0 新加的"第 4 路线"**：
- v3.0 只有 3 路线（A/B/C），v3.1/v3.2/v3.2.1/v3.2.2 patch 都不涉及
- 2026-07-08 12:08 用户基于华为运动健康 App 截图重塑需求 = **触发 v3.1 §D.7.5 升级条件 5**
- v4.0 正式确立路线 E 为"第 4 路线（闲暇态）"

**病种聚焦**（D8.7）：
- **D1 糖尿病**（核心，慢病管理主线）
- 备选扩展：高血压 / 血脂异常 / 抑郁焦虑（**v3 延后**，作为多慢病模块化基础）

**时间预算**（D8.6，硬约束）：
- 总投入 ≤10% 个人时间
- 每周 ≤3 小时
- 13 周 MVP 周期（2026-07-15 → 2026-10-15 demo）

#### 3.5.2 6 模块 MVP 设计（**重点**）

按 ADR-0002 v2.0 §6.1 模块选择矩阵：

| 模块 | 名称 | 工时 | 复用 v1 | 关键功能 |
|---|---|---|---|---|
| **M1** | **多慢病模块化可视化** | 8h | 否 | 通用慢病卡片 + 趋势图 + 告警规则 |
| **M2** | **吃药打卡 + 等级 + 临时变化** | 12h | 部分（v1 用药提醒）| 多邻国等级系统 + 临时吃药 |
| **M3** | **量表评估**（PHQ-9/GAD-7/慢病 QoL）| 8h | 否 | 量化评估 + 触发建议 |
| **M4** | **冥想 + 助眠 + 情绪记录** | 6h | 否 | 心理健康 |
| **M5** | **BMI + 体脂 + 饮食 + 体重** | 5h | 否 | 身体数据 |
| **M6** | **血压 + 血糖 + 用药提醒 + 趋势预测** | 4h | ✅（v1 已有）| 复用 + 趋势预测 |
| **总工时** | | **43h** | | **砍 4h 趋势预测深度 = 39h** |

**v3 延后模块**（ADR-0002 v2.0 §6.1 + 华为运动健康 App 截图）：
- M7 运动记录（步数/有氧/力量）—— 已有华为穿戴，v3 延后
- M8 体检报告 OCR —— OCR 复杂度高，v3 延后
- M9 医生协同 / 家属共享 —— 私人项目不需要，v3 延后
- M10 AI 健康助手 —— 非核心，v3 延后

#### 3.5.3 多邻国等级系统（D8.11）

**等级**：
- **铜牌** 30 天打卡
- **银牌** 90 天打卡
- **金牌** 180 天打卡
- **钻石** 365 天打卡

**5 个特殊成就**：
- 连续 7 天打卡
- 连续 30 天打卡
- 100% 用药 90 天
- 量表 100% 完成 1 年
- 趋势改善 30 天

#### 3.5.4 量表触发建议规则（**ADR-0002 v2.0 §10**）

- **PHQ-9 +5 分** → 自动建议联系医生
- **GAD-7 +3 分** → 自动建议联系医生
- **慢病 QoL -10%** → 自动建议联系医生
- **抑郁情绪触发** → 数据仅用户可见 + 自动建议联系医生（**R12 缓解**）

#### 3.5.5 4 层架构复用（D8.9）

```
[Layer 1] iPadOS 18+ （Flutter 客户端开发 + 日常查看）
    ↓
[Layer 2] UTM Win10 ARM64 （Flutter Desktop 调试 + VSCode 写代码）
    ↓
[Layer 3] 阿里云 ECS u1 2核4G （Spring Boot 3.4 + PostgreSQL 17 + TimescaleDB 2.18 + Docker Compose）
    ↓
[Layer 4] 绿联 DXP4800 + 8TB×2 RAID1 （健康数据本地备份 + 季度备份验证）
```

**复用比例** ≥70%（v3.2.2 patch · v4 升级继承）：
- Spring Boot 3.4 后端（路线 A 复用）
- PostgreSQL 17 + TimescaleDB 2.18（路线 A 复用）
- 4 层架构（v3.2.2 patch 新加）
- Docker Compose 部署（v3.2.2 patch 新加）

#### 3.5.6 长期数据迁移风险（R13 缓解）

**挑战**：
- 10 年长期数据 → 至少 2 次技术栈迁移（PostgreSQL 版本升级、NAS 更换）
- 健康数据**不能丢**

**缓解策略**：
- 模块化 schema（每个病种独立表）
- 季度自动导出 CSV/JSON
- 季度备份验证（恢复演练）
- v3 自动化测试覆盖数据迁移路径

#### 3.5.7 ADR 文档引用（**v4.0 升级配套**）

路线 E 完整设计见两个独立 ADR：

- **ADR-0001** v1.0：单病种 D1 糖尿病 demo（路线 A 简历级时代）
  - 文件：`/workspace/docs/adr/0001-慢病用户管理-开发文档.md`
  - 英文副本：`/workspace/adr-0001-slow-disease-manager.md`
  - 大小：33KB / 673 行 / 14 章节
- **ADR-0002** v2.0：路线 E 长期健康数据平台（v4.0 升级版）
  - 文件：`/workspace/docs/adr/0002-慢病管理长期平台-升级版.md`
  - 大小：63KB / 1613 行 / 17 章节 / 10 个代码示例

> **来源**：ADR-0001 §1 + ADR-0002 §1 + §6
> **ADR 索引规则**：路线 E 任何模块设计都从 ADR-0002 §6 模块矩阵 + §8 等级系统 + §10 量表触发 开始

---

## §3 完成

## 4. 工作方法论：superpowers

> **强制方法论**——任何编程/调试/任务都按 superpowers 工作流走。

### 4.1 14 个 Skill 触发矩阵

#### 基础工作流（4）

| # | Skill | 触发时机 |
|---|---|---|
| 1 | using-superpowers | 任何对话开始 |
| 2 | brainstorming | 新需求/新功能开始 |
| 3 | writing-plans | 设计批准后 |
| 4 | using-git-worktrees | 设计批准后 |

#### 执行与协作（3）

| # | Skill | 触发时机 |
|---|---|---|
| 5 | subagent-driven-development | 执行计划 |
| 6 | executing-plans | 批量模式 |
| 7 | dispatching-parallel-agents | 多独立问题 |

#### 工程纪律（5）

| # | Skill | 触发时机 |
|---|---|---|
| 8 | test-driven-development | 任何实现 |
| 9 | verification-before-completion | 任何"我完成了" |
| 10 | requesting-code-review | 任务间 |
| 11 | receiving-code-review | 收到反馈 |
| 12 | finishing-a-development-branch | 任务完成 |

#### 系统化调试（1）

| # | Skill | 触发时机 |
|---|---|---|
| 13 | systematic-debugging | 任何 Bug |

#### 元技能（1）

| # | Skill | 触发时机 |
|---|---|---|
| 14 | writing-skills | 写新 Skill |

### 4.2 任务类型 → 必走流程

| 任务类型 | 必走流程 |
|---|---|
| **新需求/新功能/新项目** | brainstorming → writing-plans → executing-plans → verification |
| **写代码任务** | writing-plans → executing-plans → TDD → code-review → verification |
| **调试 Bug** | debugging（4 阶段：复现→分析→假设→修复）|
| **完成功能后** | code-review → verification |
| **复杂研究/调研** | brainstorming → writing-plans → executing-plans |
| **简单对话/快问快答** | （不需要走流程，直接答）|
| **写 memory topic 改动** | writing-plans（小幅）→ verification（"我改对了吗"）|
| **新会话初次接触** | brainstorming（确认这次要做什么）|
| **长文档生成（>5KB）** | spawn sub-agent + 强制章节完成标记（**v4.0 新加**）|

### 4.3 5 大反模式（**必看**）

| 反模式 | 体现 | 修正 |
|---|---|---|
| **上来就动手** | 用户说"做个 X"，直接给方案/代码 | 先 brainstorming 3-5 个澄清问题 |
| **跳过 Plan** | 复杂任务直接执行，返工频繁 | writing-plans：5 步内能说清 diff 就不用 plan |
| **写完不测** | "我写完了"但没跑过 | verification：明确验证标准并跑通 |
| **乱改 Bug** | 一报错就改代码试试看 | debugging：先复现现象，再分析原因 |
| **口头完成** | "应该没问题" | 给出具体的验证证据 |
| **v4.0 新加**：主线程写长文档 | 陷入"executing-planning"独白循环 | spawn sub-agent 写 + 强制章节标记 |

> **来源**：v2.1 §2 / superpowers §2 / 白皮书 §4

### 4.4 v6.0.3 关键更新（2026-06-26 校正 · v4 升级继承）

superpowers v6.0.3（2026-06-18 发布，189k stars）的关键变更，影响 §4 工作方法论：

| 变更项 | 旧版（v5.x）| v6.0.3 现状 | 对用户的影响 |
|---|---|---|---|
| **SDD（subagent-driven-development）reviewer 机制** | 2 reviewer per task | **1 reviewer per task 双 verdict**（spec + quality 一次评完）| 实测**快 2x、节省 50% token** |
| **新 harness 支持** | Claude Code / Codex / Cursor / OpenCode | + **Kimi Code + Pi + Antigravity**（共 10 harness）| 用户当前仅 Claude Code |
| **writing-plans 结构升级** | 5 步标准 | 新增 **Global Constraints block** + per-task **Interfaces block** | 影响路线 B 后续 plan 写作质量 |
| **Skill 命名重命名** | "Claude Search Optimization" | **"Skill Discovery Optimization"** | 描述通用化（非 Claude 专属）|
| **brainstorming visual companion 安全** | 30 分钟超时 / 无认证 | **per-session key + 4 小时超时** | 路线 B 复杂 brainstorm 场景更安全 |
| **SDD scratch 文件位置** | `.git/sdd/` | **`.superpowers/sdd/`** | working tree，git-ignored |

**v6.0.3 升级路径**：plugin marketplace 升级即可——
```bash
/plugin update superpowers@claude-plugins-official
```

**未升级的领域**：
- "MUST use before any creative work" brainstorming 触发条件没变
- 7 阶段流水线逻辑不变
- 14 个 Skill 触发矩阵（§4.1）完全兼容

> **来源**：superpowers v6.0.3 RELEASE-NOTES.md（解压自 `23325ac1__239d28c3-a32a-4217-9b6d-938458fd37f7.zip`）

---

## 5. 工具箱（10 Skill）详细

### 5.1 10 个 Skill 详细速查

| # | Skill | 详细用途 | 触发词 |
|---|---|---|---|
| 0 | **superpowers** | 元方法论，任何编程/任务前置 | "做 X" / "写代码" / "调试" |
| 1 | **agent-reach** | 跨 14 平台信息获取（YouTube/B站/小红书/公众号/Twitter 等）| "抓小红书/公众号/B站/YouTube 内容" |
| 2 | **notebooklm-skill** | Google NotebookLM 文档 RAG | "读 PDF / 上传文档 / NotebookLM" |
| 3 | **bb-browser** | 云端浏览器反爬（Browserbase 隐身模式）| "抓被 Cloudflare 挡住" / "验证码自动识别" |
| 4 | **skill-creator** | 创建新 Skill（已加载）| "做新 Skill" / "写 Skill" / "把重复流程转 Skill" |
| 5 | **find-skills** | 搜索 20 万+ Skill（vercel-labs）| "找 Skill" / "有什么 Skill 能做 X" |
| 6 | **frontend-design** | Anthropic 官方前端设计（生产级界面）| "做前端" / "做网站" / "不要 AI 味" |
| 7 | **ui-ux-pro-max** | UI/UX 风格库（67 风格 / 161 配色 / 57 字体）| "选 UI 风格" / "配色方案" |
| 8 | **playwright mcp** | 微软本地浏览器自动化（比 bb-browser 轻量）| "本地浏览器自动化" / "E2E 测试" |
| 9 | **humanizer-zh** | 去中文 AI 味（op7418 24-25 种模式）| "去 AI 味" / "像人写的" / "改营销文案" |

**v4.0 新加第 10 个 Skill**：
| 10 | **ai-idea** | 4 阶段统一入口（sharpening → decision → research → practice）| "模糊想法" / "想清楚" / "深度研究" |
| 11 | **claude-skills** | Anthropic 官方 17 skills 统一入口（5 大类）| "Anthropic skill" / "做 MCP" / "写艺术" |
| 12 | **matt-skills** | Matt Pocock 完整 skills（29 skill 跨 6 bucket）| "mattpocock" / "TDD" / "诊断 bug" |

> **来源**：v2.1 §1.3 / skills-toolkit

### 5.2 skill 选择流程

```
任务类型判断
  ↓
1. 是新需求/创意？ → brainstorming
2. 是 PM 相关？ → product-manager
3. 是决策/分析瘫痪？ → decision-council
4. 是写代码？ → superpowers (sub-agent 写长文档)
5. 是工具/平台具体操作？ → 对应专项 skill
6. 是 UI/UX？ → ui-ux-pro-max → frontend-design
7. 是中文去 AI 味？ → humanizer-zh
```

> **来源**：v2.1 skills-toolkit

---

## 6. 接入层 + 调度层 + 执行层

### 6.1 接入层（Mavis Agent Desktop + Pocket）

**唯一接入层 = Mavis Agent**：

```
接入层（唯一）：Mavis Agent Desktop + Pocket
  ├─ 桌面端：Windows + Mac + iPadOS（v3.2.2 patch 新加）
  │   - 本地文件 + Browser Use + Computer Use
  │   - 路线 A/B/E 开发主战场
  └─ Pocket Beta：WeCom / Slack 远程指挥
      - 移动端任务派发
      - 微信 WeCom 集成
```

**v3.2.2 patch · v4 升级继承**：
- iPadOS 18+ 接入 = Layer 1（4 层架构）
- 桌面端不再是"主力"（主力转为 iPad + 妙控键盘 + 4K 外接显示器）

### 6.2 调度层（Spring Boot API Gateway · 自建）

```
调度层：Spring Boot API Gateway（自建）
  ├─ Redis + Lua 原子熔断（财务保护）
  ├─ 多模型路由（DeepSeek / Mavis API / MiMo API）
  ├─ 任务队列
  └─ v3.2.2 patch：跑阿里云 ECS Docker（不在 iPad / NAS）
```

**v4 升级**：调度层从"路线 B 单独功能"升级为"路线 A/B/E 共享基础设施"。

### 6.3 执行层（80/20 分层）

```
执行层（80/20 分层）：
  ├─ Mavis Agent Teams（云端主力，80% 任务）
  │   - Leader + Worker + Verifier 架构
  │   - 用户已经是这个思想的"用户"
  └─ OWL + OpenManus（自建兜底：涉密/沙盒/批量，20% 任务）
      - 路线 C 联机服务器（如果做联机游戏）
      - 路线 B §3.1 方向 5（AI 中间件）的实现参考
```

> **来源**：v2.1 §1.4 / indie-game-whitepaper §3

---

## §4-§6 完成

## 7. 基础设施与安全（iPad 4 层架构 · v3.2.2 patch · v4 升级）

### 7.1 4 层架构（**v3.2.2 patch · v4 升级重点**）

```
[Layer 1] iPadOS 18+ （用户主力开发设备，2026-07-06 切换）
  ├─ 设备：iPad Pro 13 M5 1TB 16GB
  ├─ 配件：妙控键盘 + 4K 外接显示器
  └─ 替代：原 Windows 11 PC

[Layer 2] UTM Win10 ARM64 VM
  ├─ 内存：6GB（节省 2GB vs Win11 ARM）
  ├─ 核心：4 核
  ├─ 磁盘：128GB VHDX
  ├─ 工具：VSCode / IntelliJ / Java JDK 17 ARM / Claude Code（切国内）/ 通义灵码
  └─ 用途：路线 A 主力开发（不在 iPad 原生跑 IDE）

[Layer 3] 阿里云 ECS u1 2核4G
  ├─ 镜像：Ubuntu 22.04 LTS
  ├─ Docker + Docker Compose
  ├─ 路线 B 组件：Spring AI / Dify / Ollama / Milvus
  ├─ 路线 C 联机服务器（如果做联机）
  └─ 路线 E 组件：Spring Boot 3.4 + PostgreSQL 17 + TimescaleDB 2.18

[Layer 4] 绿联 DXP4800 + 8TB×2 RAID1
  ├─ 价格：4515 元一次性
  ├─ 容量：8TB 可用（5+ 年充裕）
  ├─ 健康数据本地备份
  └─ 季度备份验证（缓解 R13 长期数据迁移）
```

**4 层架构决策依据**（v3.2.2 patch）：

| 决策 | 内容 | 依据 |
|---|---|---|
| D2.5 | iPad 主力开发设备 | 便携 + 触屏 + 长续航 + 妙控键盘 = 移动开发体验升级 |
| D4.4 | UTM 跑 Win10 ARM | 节省 2GB 内存（iPad 16GB 紧张）+ 稳定性更高 |
| D4.5 | Docker 全部跑 ECS | iPad Win10 不支持 Docker Desktop → ECS Docker 替代 |
| D8.4 | iPad UTM Win10 ARM64 + 4K 外接显示器 | 桌面级开发体验 |
| D8.9 | 路线 E 4 层架构复用 | 路线 A/B/E 共享同一架构 |
| D12.x | 路线 C 工具 = Unity Editor X iPad 原生 | 替代 PC Unity |

### 7.2 安全策略

**4 个安全层**：

1. **应用层**：
   - 健康数据 = **敏感个人信息**（GDPR / 个人信息保护法）
   - 数据最小化原则：只记录必要数据
   - 隐私 by design：量表评估触发 → 数据仅用户可见

2. **传输层**：
   - HTTPS 全程
   - 微信 WeCom / ClawBot 双向认证
   - 阿里云 ECS 安全组只开必要端口

3. **存储层**：
   - NAS 本地为主，ECS 仅为访问入口
   - 健康数据加密存储（AES-256）
   - 季度自动备份 + 备份验证演练

4. **物理层**：
   - iPad 启用 Find My
   - NAS 启用访问密码
   - 阿里云 ECS 启用密钥登录（禁用密码登录）

> **来源**：v2.1 §7 / v3.2.2 patch §0.9

---

## 8. 学习铁律与执行准则

### 8.1 学习铁律（5 条核心原则）

1. **选定一条路线后坚持按一套教程完整做完再换** — 不并行学多套（同路线内可并行）
2. **决策先于行动** — 复杂任务先 superpowers 走 brainstorming → writing-plans
3. **规划就是一切** — 来源：vibe-coding-cn §"道"。上下文是 vibe coding 的第一性要素
4. **凡是 AI 能做的，就不要人工做** — 接入层主力是 Mavis
5. **路线选择给明确建议** — 不只列 pros/cons

### 8.2 执行准则（13 条 · v3.0 + v4.0 升级）

1. **每次回答标来源**（§0.3 来源标注规则）
2. **来源优先级**（§0.3 来源类型）
3. **不主动刷存在感**（D 路线 / C 兴趣态不主动追问）
4. **重大变更前 brainstorming**（v3.0 新加 · superpowers HARD-GATE）
5. **删除文件前确认**（用户明确要求"删除前给我确认"）
6. **MCP 工具 task_id 类型 bug 已知**（cron update/delete/trigger 失败时 → 创建新 cron + 用户手工删旧 cron）
7. **memory topic description 不能直接 update**（daemon metadata 限制，只在 body 顶部加 patch 升级说明段）
8. **iPad M5 4 层架构**（v3.2.2 patch · v4 升级继承）：`iPad + UTM Win10 + 阿里云 ECS + 绿联 NAS`
9. **路线 E ≤10% / 每周 ≤3h**（**v4.0 新加**）
10. **内部循环失控时立刻承认 + 不假装做事**（v4.0 新加）
11. **不输出占位符/TODO/待补充**（v4.0 新加）
12. **长文档必须 Mavis 主线程分段追加**（v4.0 新加 · v3.1 patch 升级 · 第 8.3 节展开）—— **永远不 spawn sub-agent 写长文档**（七次验证 100% 失败）
13. **每次回答前先读 §1 + §2 决策快照**（v3.0 沿用 · v4.0 不变）

### 8.3 长文档写作准则（**v4.0 新加 · v3.1 patch 升级** · 关键）

**问题**：Mavis 主线程写长文档（>5KB）必陷入"executing-planning"独白循环（卡在"让我开始写" / "思考怎么写" / "重新思考" 100+ 次），最终没产出文件。
**sub-agent 写长文档（>30KB）也必卡循环**（v3.1 patch 升级踩坑教训）。

**七次验证（v3.1 patch 升级）**：

| # | 项目 | 模式 | 结果 |
|---|---|---|---|
| **1** | v3.2.2 patch ADR-0002 | spawn sub-agent 写 | ❌ 卡 5 分钟无输出 → cancel |
| **2** | v4.0 升级 dedupe sub-agent | spawn sub-agent 写 | ❌ 卡 5 分钟无输出 → cancel |
| **3** | v4.0 升级 v4.0 写作 sub-agent | spawn sub-agent 写 | ❌ 卡 1.5 分钟停在 138 行 → cancel |
| **4** | v2.1 patch（PRD 7 大要素）| spawn sub-agent 写 | ❌ 卡 1.5 分钟文件大小未变 → cancel |
| **5** | v2.2 patch（GitHub 真实 PRD 调研）| **不 spawn，主线程分段追加** | ✅ 4 段 cat >> 成功（+685 行）|
| **6** | v3.0 patch（开发文档）| **不 spawn，主线程分段追加** | ✅ 8 段 cat >> 成功（+2,250 行）|
| **7** | v3.1 patch（AI 协作规范）| **不 spawn，主线程分段追加** | ✅ 2 段 cat >> 成功（+368 行）|

**结论（v3.1 patch 升级永久准则）**：
- **4 次 spawn sub-agent 写长文档全部卡循环**（失败率 100%）
- **3 次 Mavis 主线程分段追加全部成功**（成功率 100%）
- **新永久准则**：**写 > 5KB 长文档永远 Mavis 主线程分段追加，不 spawn sub-agent**

**修正规则（v3.1 patch 升级）**：

| 文档大小 | 处理方式 |
|---|---|
| **< 2KB** | Mavis 主线程直接写（不会卡循环）|
| **2-5KB** | Mavis 主线程写 + 强制 1 个章节完成标记 |
| **> 5KB** | **Mavis 主线程分段追加（每段 < 30KB）** + 强制每个 ## 二级章节完成时输出 `## [标题] 完成` 标记 |
| **> 30KB** | 拆成 2+ 段（每段 < 30KB）逐段 cat >> 追加 |
| ~~> 20KB~~ | ~~spawn sub-agent~~（**v3.1 升级：永远不 spawn**）|

**Mavis 主线程分段追加硬规则（v3.1 patch 升级）**：
1. **不 spawn sub-agent**（写长文档 100% 失败）
2. **每段 < 30KB**（避免大文件单次写入卡循环）
3. **每段立即 verification**（wc -l + grep 章节数）
4. **每段输出完成标记**：`## [标题] 完成`
5. **不输出占位符 / TODO / 待补充**（诚实原则）
6. **卡循环立刻 cancel + 主线程接管**（不假装做事）
7. **每段开头列 todo**（todo list 跟踪进度）

**历史 sub-agent prompt 要素（仅记录，不再使用）**：
> 以下要素在 v4.0 §8.3 原始版本中提到"spawn sub-agent 写 > 5KB"，但 **v3.1 patch 升级后已废弃**——sub-agent 写长文档 4 次卡循环 100% 失败。

> **来源**：v4.0 升级踩坑教训（2026-07-08 14:38-15:15）写入白皮书 §8.3 作为永久准则
> **升级来源**：v3.1 patch（2026-07-08 18:10）七次验证升级——sub-agent 写长文档 4 次失败 + Mavis 主线程分段追加 3 次成功
> **白皮书本体升级反映**：v4.0 / v4.0.1 / v4.0.2 = Mavis 主线程分段编辑策略（每个 cat >> 1-2 章节）—— 避免大文件长写循环

---

## 9. 风险与边界

### 9.1 11 风险清单（v3.2.2 patch 9 + v4.0 新加 2）

| 编号 | 风险 | 缓解策略 | 状态 |
|---|---|---|---|
| R1 | API 预算超支 | 熔断机制 + 实时监控 | ✅ v3.0 |
| R2 | 路线 A/B 切换时遗漏 | 切换时点明确 + 12 个月时间表 | ✅ v3.0 |
| R3 | 工具链变化（v5.1.0 移除 named agent 等）| 季度审查 + v3.1 §D.7.5 升级机制 | ✅ v3.0 |
| R4 | 知识库信息过时 | 季度审查 + 价格附录 B 动态更新 | ✅ v3.0 |
| R5 | 隐私泄露（个人健康数据）| NAS 本地为主 + 隐私 by design | ✅ v3.0 |
| R6 | 阿里云欠费 ECS 关停 | 自动充值 + 监控告警 | ✅ v3.0 |
| R7 | iPad 损坏（主力开发设备）| 妙控键盘 + 4K 外接 + 阿里云 ECS 备份 | ✅ v3.0 |
| R8 | superpowers skill 冲突 | 强制使用前置条件 | ✅ v3.0 |
| R9 | whitepaper-watcher-hook v2 漏报 | v3.2.1 升级 + 35/35 TDD 测试 | ✅ v3.2.1 |
| R10 | iPad 硬件限制 | UTM 跑 Win10 ARM（节省 2GB）+ ECS Docker 替代 | ✅ v3.2.2 |
| R11 | Docker 跑 ECS 架构调整 | iPad UTM 仅做 IDE + ECS Docker 跑全栈 | ✅ v3.2.2 |
| **R12** | **路线 E 量表评估触发抑郁情绪暴露** | **数据仅用户可见 + PHQ-9 +5 自动建议联系医生 + 量表触发建议规则（§3.5.4）**| **✅ v4.0** |
| **R13** | **路线 E 长期数据迁移成本（≥10 年）** | **模块化 schema + 季度 CSV/JSON 导出 + 季度备份验证演练 + 自动化测试** | **✅ v4.0** |

### 9.2 边界

**Mavis 不做的事**（用户偏好 + 决策基线）：
- ❌ 不主动追问产品 brainstorming（v3.0 挂起决策）
- ❌ 不主动建议商业化路线 E（私人项目）
- ❌ 不主动 sync 大型 ADR 文档（用户触发后才动）
- ❌ 不修改 ADR-0001 v1（独立保留）
- ❌ 不删除任何文件（删除前确认）

**Mavis 必做的事**（硬约束）：
- ✅ 每次回答标来源（§0.3）
- ✅ 重大变更前 brainstorming（superpowers HARD-GATE）
- ✅ 路线 E 决策冲突时回到 ADR-0002 §3 verdict
- ✅ 长文档写作用 sub-agent（§8.3）

> **来源**：v3.0 + v3.2.2 patch + v4.0 升级

---

## §7-§9 完成

## 10. 用户决策与白皮书治理

### 10.1 用户最终方案决策（**v3.1 §D.6.1 · v3.2 §10.1 · v4 升级继承**）

**用户决策时间**：2026-06-25

**已定方案**：

| 项目 | 配置 | 价格 |
|---|---|---|
| NAS | 绿联 DXP4800 + 8TB×2 希捷酷狼 RAID1 | **4515 元一次性** |
| 云服务器 | 阿里云 ECS u1 2核4G 5M 80G ESSD | **199 元/年** |
| 域名 + DeepSeek API | .com 域名 70 元 + DeepSeek API 360-600 元 | 430-670 元/年 |

**5 年总成本**：

```
一次性：4515 元
每年云 + 域名 + API：199 + 70 + 500（API 预估）= 769 元/年
5 年总：4515 + 769×5 = 8360 元
月均：139 元/月
不含 API：5510 元 / 月均 92 元
```

**为什么选 8TB×2 不是 4TB×2**：
- 4TB×2 RAID1 = 4TB 可用（2-3 年就装满）
- 8TB×2 RAID1 = 8TB 可用（5+ 年充裕）
- 多投 1600 元换 100% 容量 = **单位容量成本更低**
- 同时承载路线 B §3.1 + 路线 C 素材 + 路线 E 健康数据 + 家庭照片视频

### 10.2 OpenClaw 微信 ClawBot 网关（**v3.1 §D.6.2 · v3.2 §10.2 · v4 升级继承**）

**新事实（2026-03-22 微信官方推出）**：

| 维度 | 详情 |
|---|---|
| 插件名 | **微信 ClawBot**（openclaw-weixin-cli）|
| 接入命令 | `npx -y @tencent-weixin/openclaw-weixin-cli@latest install` |
| 操控方式 | 微信扫码绑定 OpenClaw 设备 |
| 支持平台 | iOS 微信 8.0.70+ / Android 微信 8.0.69+ / 鸿蒙暂不支持 |
| 操控对象 | 电脑 / 手机 / 树莓派上的 OpenClaw 设备 |
| 适用场景 | 移动端操控 OpenClaw 设备，**无需 SSH / 远程桌面** |

**v3.0 / v3.1 受影响位置同步更新**：

| 位置 | 原表述 | 新表述（v3.1 §D.6.2 修正）|
|---|---|---|
| v3.0 §1.4 | "IM 远程控制 = 微信 WeCom" | **双通道**：任务派发 = 微信 WeCom + 设备操控 = 微信 ClawBot |
| v3.0 §1.6 第 3 条 | "OpenClaw 已退役" | **OpenClaw 通过微信 ClawBot 重新可用为手机操控通道** |
| v3.0 §1.6 第 4 条 | "飞书 IM 网关已弃用" | 任务派发 = 微信 WeCom，设备操控 = 微信 ClawBot（**两个 IM 分工不冲突**）|

> **来源**：v3.1 §D.6.2 + 2026-03-22 微信官方 ClawBot 插件公告

### 10.3 产品 brainstorming 暂缓（v3.0 · v4 升级继承）

**v3.0 决策**：
- 路线 A 完成 + 路线 B B.1-B.4 完成 + 准备 B.5 简历级项目时 → 解锁产品 brainstorming
- 触发前不主动追问产品

**v4 升级**：
- 路线 E 不算"产品 brainstorming 触发条件"
- 路线 E 是私人项目（**不商业化**），不挂起产品 brainstorming
- **v4 升级后产品 brainstorming 仍暂缓**（等路线 A 完成 + 路线 B B.5 启动）

### 10.4 白皮书自动审查 Hook v3（**v3.2.1 patch v2 · v3.2.2 patch 稳定 · v4 升级：v3 已稳定运行**）

**白皮书审查 Hook v2**（2026-06-27 上线，35/35 TDD 测试全过）：

按 v3.2 §1.2 三层叠加底座，**hook v2 `/workspace/.mavis/whitepaper-watcher-hook/`** 用 3 skill 协作：

- **Stage 1（决策底座）**：decision-council v0.1.1 §3 4 步（抓主要矛盾 + 反方机制）
- **Stage 2（PM 视角）**：product-manager v0.6 §3（用户/场景/价值/落地）
- **Stage 3（执行脚手架）**：superpowers v6.0.3 7 阶段

**v3.2.1 → v4 升级状态**：
- **v2 已稳定运行**（2026-07-08 标记）
- 0 误报 / 0 漏报 / 35/35 TDD 通过
- cron 任务 `whitepaper-watcher-v2` (task_id 412827785302108) 每 5 分钟跑一次
- 旧 watcher 保留作 fallback 兜底

**v4 升级配套**：
- 加 §10.5 v4 治理周期
- 加 §11.2 v4.0 升级内容
- 加 §D.8 v4 增量修正

> **校正说明**（保留 v3.2.1 patch 校正记录）：superpowers **v5.1.0 (2026-04-30) 起就移除了 `superpowers:code-reviewer` named agent**。实际审查机制：通过 `requesting-code-review` skill → dispatch `general-purpose` subagent → 用 `skills/requesting-code-review/code-reviewer.md` 作为 prompt template。

### 10.5 v4 治理周期 + v5.0 升级触发（**v4.0 新加**）

**v4 治理周期**：
- **季度审查**：每 3 个月（2026-10-01 / 2027-01-01 / 2027-04-01 / 2027-07-01 ...）做白皮书完整性审查
- **月度自检**：每月 1 号加 4 项检查：
  1. iPad 4 层架构运行情况
  2. 路线 E MVP 进度（如有）
  3. 价格类内容（API + 云 + NAS）3 个月内必有变动
  4. whitepaper-watcher-hook v3 状态

**v5.0 升级触发条件**（**任一满足时**）：

| 条件 | 状态 | v5.0 触发? |
|---|---|---|
| 1. 2026-09-01 季度审查 | ❌ 未到 | - |
| 2. 路线 B B.5 简历级项目启动 | ❌ 未启动 | - |
| 3. superpowers v7 发布 | ❌ 未发布 | - |
| 4. 岚开发团队入职前 | ❌ 未知 | - |
| 5. 路线 E 升级到 v5（私人项目 → 半公开协作）| ❌ 未知 | - |
| 6. **新增**：4 个 memory topic 任一描述大改 | 监控中 | - |
| 7. **新增**：用户学习路线大改（路线 A/B/C/E 时间预算/病种/技术栈变化）| 监控中 | - |

> **来源**：v4 升级配套（v3.1 §D.7.5 升级机制 v4 扩展）
> **关键变化**：v4 新加 2 个触发条件（#6 #7）—— memory topic 描述 + 路线学习变化

---

## 11. 变更历史

### 11.1 v3.0 → v3.2.2 patch 完整时间线

| 日期 | 版本 | 变更 | 触发 |
|---|---|---|---|
| 2026-06-16 | v2 | OpenClaw 退役、飞书→微信 WeCom、Plan 4 v2 决策 | 接入层/IM/预算 |
| 2026-06-16 | v2 | 豆包网关弃用 | 调度层 |
| 2026-06-17 | v2 | 工具箱新增 4 个 Skill | 工具箱 |
| 2026-06-17 | v2 | superpowers 元方法论引入 | 工作流 |
| 2026-06-17 | v2.1 | 6 个 topic 整合为 v2 文档 | 基线 |
| 2026-06-23 | **v3.0** | **目标变更：Java 全栈 + AI 集成 + 独立游戏**（三路线）| 路线规划 |
| 2026-06-23 | v3.0 | AI 集成从"扩展"升级为"独立路线 B" | 路线规划 |
| 2026-06-24 | v3.1 | 附录 D 增量：阿里云价格修正 / NAS vs 云重算 / MiMo Token Plan 5-8 倍 | 数据校正 |
| 2026-06-25 | v3.1.x | 用户最终方案决策（绿联 4515 + 阿里云 199）+ OpenClaw 微信 ClawBot | 用户 |
| 2026-06-25 | v3.1.x | §1.4 / §1.6 / §7.1 正文同步 v3.1 增量 | 整合 |
| 2026-06-26 | **v3.2** | **v3.1 → v3.2 全面整合：删除 v3.0 过期内容 + 加 §0.6 目标读者 + §0.7 变更摘要 + §10.1-10.4 + §11 + 升级到 code-reviewer subagent 189k stars 审查标准** | **全面整合** |
| 2026-06-26 | v3.2.x | 校正 §10.4 code-reviewer subagent 错误描述 + 同步 v6.0.3 关键更新 | 校正 |
| 2026-06-27 | **v3.2.1** | patch：白皮书审查 hook v2 上线（3 skill 协作）+ v3.2 §0.8 §10.4 §D.7.5 升级 | hook v2 |
| 2026-07-06 | **v3.2.2** | patch：硬件切换 4 层架构（iPad Pro 13 M5 + UTM Win10 ARM + 阿里云 ECS + 绿联 NAS）+ 决策 33→38 + 风险 +2 | iPad M5 采购 |

### 11.2 v4.0 升级内容（**v4.0 新加**）

| 类型 | 改动 |
|---|---|
| **新增路线** | §0.4 三目标 → **四目标**（A/B/C/E 闲暇态）|
| **新增章节** | §2.4 路线 E 闲暇态 / §2.5 四路线并行策略 / §3.5 路线 E 深度 / §10.5 v4 治理周期 / §D.8 v4 增量 / §8.3 长文档写作准则 |
| **新增决策** | 38 → **~46**（+ D8.5 / D8.6 / D8.7 / D8.8 / D8.9 / D8.10 / D8.11 = 7 个路线 E 决策）|
| **新增风险** | 9 → **11**（+ R12 量表评估触发抑郁 / R13 长期数据迁移成本）|
| **清理卡顿** | v3.2.1 §0.8 "TODO 留 B3-B5" / v3.2.2 §0.9 "iPad 4 层架构待办" / v3.2 §D.7.5 "v3.3 升级待评估" / v3.2 §10.4 "v2 标记已加" 全部闭环 |
| **修正位置** | §0.5 核心原则从原位置错乱（v3.2 实际在 §0.8 §0.9 之后）→ v4 修正到 §0.5 标准位置 |
| **新增准则** | §0.5 第 6 条 = "长文档必须用 sub-agent 写" + §8.3 展开 |
| **新增治理** | §10.5 v4 治理周期 + v5.0 升级触发（7 条件）|
| **跨文件 dedupe** | 3 组精确重复（superpowers zip 3 副本 + AI 工具链 md 3 副本 + ADR-0001 中英文 2 副本）+ 24 个语义主题（**全部是有意冗余引用，保留**）|
| **清理 TODO** | v3.2.1 §D.7.5 "user-current-tech-stack topic 整体重写（标记到 TODO）" → v4 改为"已重写完成 2026-07-08" |
| **删除段** | v3.2 §D.7.5 "v3.3 全面升级待评估（方案 C）：暂不做"（v4 已升级，删整段）|

> **来源**：v4.0 升级配套（v3.1 §D.7.5 升级条件 5 触发）
> **下一步**：v4.0 已完成 → 等 v5.0 触发条件

---

## §10-§11 完成

## 附录 A：来源索引（所有外部仓库）

| 类别 | 文档 | 路径/链接 | 用途 |
|---|---|---|---|
| **本白皮书** | mavis-whitepaper-v4.0.md | `/workspace/mavis-workspace-v4.0/mavis-whitepaper-v4.0.md` | **每次对话前必读**（v4 当前主版本）|
| **v3.2 旧版** | mavis-whitepaper-v3.2.md | `/workspace/mavis-whitepaper-v3.2.md` | v3.2.2 patch 旧版本（v4 升级前主版本）|
| **v3.1 归档** | mavis-whitepaper-v3.1-archived.md | `/workspace/mavis-whitepaper-v3.1-archived.md` | v3.1 历史归档 |
| **v2.1 基线** | ai-toolchain-baseline-v2.1.md | （已合并到白皮书）| v3.0 继承的旧决策 |
| **vibe coding** | ~~vibe-coding-learning-guide.md~~（已删 — v3.2 整合到正文）| — | 资源已合并到 §3 / §4 / §6 |
| **编程教程** | ai-coding-tutorial.md | `/workspace/ai-coding-tutorial.md`（~100KB）| AI 编程工具教程 |
| **独立游戏** | indie-game-whitepaper.md | `/workspace/indie-game-whitepaper.md`（~30KB）| 独立游戏架构 |
| **ADR-0001** | 慢病用户管理 v1 | `/workspace/docs/adr/0001-慢病用户管理-开发文档.md` | 路线 E 起源 v1 |
| **ADR-0002** | 慢病管理长期平台 v2 | `/workspace/docs/adr/0002-慢病管理长期平台-升级版.md` | 路线 E v4 升级版 |
| **外部：vibe** | tukuaiai/vibe-coding-cn | github.com/2025Emma/vibe-coding-cn | 方法论 + 工具链 |
| **外部：vibe** | datawhalechina/easy-vibe | github.com/datawhalechina/easy-vibe | 入门教程 |
| **外部：vibe** | filipecalegario/awesome-vibe-coding | github.com/filipecalegario/awesome-vibe-coding | 资源导航 |
| **方法论** | superpowers | github.com/obra/superpowers（**v6.0.3 189k stars**，2026-06-18）| 14 Skill 工作流 + v6.0.3 关键更新（§4.4）|
| **方法论** | decision-council | 本地 skill | 决策齿轮（毛氏 OS）|
| **方法论** | product-manager | 本地 skill v0.6 | PM 专用引擎 |
| **工具** | skill-creator | Mavis `skill` skill | 创建新 Skill |
| **工具** | find-skills | github.com/vercel-labs/skills | 20 万+ Skill 搜索 |
| **工具** | agent-reach | github.com/Panniantong/Agent-Reach | 跨 14 平台信息获取 |
| **工具** | bb-browser | github.com/browserbase/skills | 云端浏览器反爬 |
| **工具** | playwright mcp | github.com/microsoft/playwright-mcp | 本地浏览器自动化 |
| **工具** | frontend-design | github.com/anthropics/skills | Anthropic 官方前端 |
| **工具** | ui-ux-pro-max | github.com/nextlevelbuilder/ui-ux-pro-max-skill | UI/UX 风格库 |
| **工具** | humanizer-zh | github.com/op7418/Humanizer-zh | 去中文 AI 味 |
| **工具** | notebooklm-skill | Google NotebookLM | 文档 RAG |
| **工具** | ai-idea | 本地 skill | 4 阶段统一入口（**v4.0 新加 §5.1**）|
| **工具** | claude-skills | 本地 skill | Anthropic 官方 17 skills（**v4.0 新加 §5.1**）|
| **工具** | matt-skills | 本地 skill | Matt Pocock 29 skills（**v4.0 新加 §5.1**）|
| **白皮书治理** | whitepaper-watcher-hook v2/v3 | `/workspace/.mavis/whitepaper-watcher-hook/` | 3 skill 协作白皮书审查（v3.2.1 上线）|

---

## 附录 B：价格动态跟踪（2026 Q2 · v4 升级继承）

### B.1 模型 API 价格（**v3.1 §D.1.3-D.1.4 修正 + v4 升级继承**）

| 模型 | 输入价 | 输出价 | 来源 |
|---|---|---|---|
| DeepSeek V4-Pro | 0.5 元/M tokens | 8 元/M tokens | DeepSeek 官方 |
| DeepSeek V4-Flash | 0.1 元/M tokens | 1.5 元/M tokens | DeepSeek 官方 |
| Qwen3.7-Plus | 4 元/M tokens | **11.2 元/M tokens**（v3.1 §D.1.4 修正）| 阿里云百炼 |
| Qwen3.7-Flash | 0.3 元/M tokens | 3 元/M tokens | 阿里云百炼 |
| Mavis Max（补差价升级 710 元/年）| Token Plan 模式 | Token Plan 模式 | Mavis 官方 |

**2026 Token Plan 市场变革**（v3.1 §D.3.3）：
- 阿里 / 字节 / 腾讯：Coding Plan 退市，Token Plan 主流
- GitHub Copilot：6/1 起改用 Token 计费
- 智谱 / 字节 / 阿里 百炼：Coding Plan 限购
- **小米 MiMo**：5/27 起 Token Plan 加量 **5-8 倍**
- **DeepSeek**：仍坚持纯按量计费（最划算）

### B.2 云服务价格（**v3.1 §D.1.1 严重修正 · v4 升级继承**）

| 配置 | v3.0 价 | **v3.1 修正后** | 节省 |
|---|---|---|---|
| 阿里云轻量 2核2G | **600-720 元/年**（v3.0 错）| **38-82 元/年**（**严重过时**）| 10-20 倍 |
| 阿里云轻量 2核4G | 800-1000 元/年 | **199 元/年** | 4-5 倍 |
| 阿里云 ECS u1 2核4G 5M | - | **199 元/年**（v3.1 §D.6.1 用户定）| - |
| 阿里云 ECS u1 4核8G | - | 1159 元/年（v3.1 §D.1.2）| - |

**v3.1 §D.1.1 修正**：
- 2026 年阿里云价格比 2024 年便宜 **3-5 倍**
- v3.0 文档沿用 2024 年价格（严重过时）
- **v3.1 后判断逻辑不变，数字以附录 B 为准**

### B.3 NAS vs 云服务器（**v3.1 §D.1.2 修正 · v4 升级继承**）

| 方案 | 5 年总成本 | 月均 | 适用 |
|---|---|---|---|
| 仅云 199 元/年 | 995 元 | 17 元 | 仅 web 服务 |
| 云 199 + 群晖 DS220+ 4000 元 | 4995 元 | 83 元 | 基础 NAS |
| 云 199 + 群晖 DS923+ 8000 元 | 11,995 元 | 200 元 | 进阶 NAS |
| **用户定：云 199 + 绿联 DXP4800 4515 元** | **8,360 元（含 API）** | **139 元** | **路线 A/B/E 全适配** |

### B.4 Claude 高质量模型（**v3.1 §D.2.1 补充 · v4 升级继承**）

| 档位 | 适用 | 价格 |
|---|---|---|
| Claude Sonnet 4.5 | 日常 | $3 / M input, $15 / M output |
| Claude Opus 4.7 **xhigh** | 高难度（v3.1 新加）| $15 / M input, $75 / M output |

---

## 附录 C：知识库索引

### C.1 5 个 memory topic（v3.0 沿用 · v4 升级不重构）

| 主题 | 描述 | 大小 | 升级状态 |
|---|---|---|---|
| ai-coding-tutorial | AI Coding 零基础实战教程 | 19,953 bytes | v3.0 升级 |
| ai-toolchain-baseline | AI 工具链决策基线 v2.1 | 23,481 bytes | v3.0 升级 |
| indie-game-architecture | 独立游戏工业化管线 | 17,924 bytes | v3.0 升级 |
| llm-pricing-2026-q2 | 大模型价格速查 | 11,350 bytes | v3.0 升级 |
| superpowers | Superpowers 工作方法论集 | 10,248 bytes | v3.0 升级 |

### C.2 11 个可用 skill（v3.0 沿用 · v4 升级不重构）

| Skill | 用途 | 触发 |
|---|---|---|
| superpowers | 元方法论 | 必加载 |
| decision-council | 决策齿轮 | 决策前 |
| product-manager | PM 引擎 | PM 任务 |
| skill-creator | 创建 Skill | 新流程 |
| find-skills | 搜 Skill | 找工具 |
| agent-reach | 跨平台信息 | 抓内容 |
| bb-browser | 反爬浏览器 | 抓困难站 |
| playwright mcp | 浏览器自动化 | E2E |
| frontend-design | 前端设计 | UI 任务 |
| ui-ux-pro-max | UI 风格 | 选风格 |
| humanizer-zh | 去 AI 味 | 中文改写 |
| **ai-idea** | **4 阶段统一入口（v4.0 新加）** | **模糊想法** |
| **claude-skills** | **Anthropic 官方 17 skills（v4.0 新加）** | **Anthropic skill** |
| **matt-skills** | **Matt Pocock 29 skills（v4.0 新加）** | **mattpocock** |

---

## 附录 D：v3 + v4 增量修正（v4 升级整合）

> **v4 附录 D 结构**：D.1-D.7 继承 v3.1/v3.2 全部修正 + **§D.8 v4.0 增量**（**v4.0 新加**）

### D.1 v3.1 增量（2026-06-24）

**D.1.1 阿里云价格严重过时修正**（P0）
- v3.0 §7 写"阿里云轻量 2核2G 600-720 元/年"
- v3.1 实际：**38-82 元/年**（2026 年比 2024 年便宜 10-20 倍）
- **触发** v3.0 整个基础设施判断需重算

**D.1.2 NAS vs 云服务器重算**（P0）
- 见附录 B.3

**D.1.3 MiMo Token Plan 5-8 倍用量未记录**（P0）
- 小米 MiMo 2026-05-27 公告：Token Plan 加量 5-8 倍
- v3.0 §1.1 未记录，导致路线 B §3.1 性价比分析有偏差

**D.1.4 Qwen3.7-Plus 输出价 8→11.2 元**（P0）
- 阿里云百炼 2026-06-15 调价
- 输出价从 8 元/M 涨到 11.2 元/M tokens

### D.2 v3.1 次要修正（2026-06-24）

**D.2.1 Claude Opus 4.7 xhigh 档位**（P2）
- 见附录 B.4

**D.2.2 OpenClaw 表述更新**（P2）
- 见 §10.2

**D.2.3 Mavis Agent Teams 命名区分**（P2）
- Mavis Agent Teams = Mavis 内置多 Agent 协作
- spring-ai + langgraph = 路线 B §3.1 方向 2 实现
- **两者不冲突**——前者是用户（用 Mavis），后者是实现（用 Spring AI）

### D.3 v3.1 新增有用信息（2026-06-24）

**D.3.1 DeepSeek V4-Flash 价格补充**
- 见附录 B.1

**D.3.2 MiMo-V2-Pro/Omni Token Plan 下线提示**
- 2026-06-20 下线
- 影响路线 A/B token 预算

**D.3.3 2026 Token Plan 市场变革**
- 见附录 B.1

### D.4 v3.1 变更历史

（已在 §11.1 完整记录）

### D.5 v3.1 阅读优先级

（v3.2 升级已合并到 §0.2 怎么用）

### D.6 v3.1 后增量（2026-06-25）

**D.6.1 用户最终方案决策**（v4 升级 §10.1）

**D.6.2 OpenClaw 微信 ClawBot 网关**（v4 升级 §10.2）

**D.6.3 v3.0 §7 正文同步**（v3.2 升级已替换）

### D.7 v3.2 后增量（2026-06-26）

**D.7.1 v3.2 整合项**——v3.1 附录内容**已吸收进正文** §1.4 / §1.6 / §7 / §10

**D.7.2 v3.2 删除项**——v3.0 §7 过期价格 / v3.0 §1.6 OpenClaw 表述 / v2.1 旧版链接

**D.7.3 v3.2 新增项**——§0.6 目标读者 / §0.7 变更摘要 / §10 用户决策 / §11 变更历史

**D.7.4 v3.2 阅读优先级**（升级到 §0.2）

**D.7.5 v3.3 升级建议**（v3.2.1/v3.2.2 patch 已部分完成）
- v3.2.1 hook v2 上线 ✅
- v3.2.2 iPad 4 层架构 ✅
- **v4 升级时本节升级为 §D.8 v4 增量**

**D.7.6 v3.2 后增量（v3.2.1 + v3.2.2 patch）**
- 已在 §11.1 完整记录

### D.8 v4 增量修正（**v4.0 新加 · 2026-07-08**）

> **本节是 v4.0 升级对应附录**——v4 主版本正文的索引和背景信息。

#### D.8.1 v4.0 触发条件（v3.1 §D.7.5 升级条件 5）

| 触发条件 | 状态 | v4.0 触发? |
|---|---|---|
| 1. 2026-09-01 季度审查 | ❌ 未到 | - |
| 2. 路线 B B.5 简历级项目 | ❌ 未启动 | - |
| 3. superpowers v7 发布 | ❌ 未发布 | - |
| 4. 岚开发团队入职前 | ❌ 未知 | - |
| **5. 路线 E 升级到长期健康数据平台** | **✅ 2026-07-08 触发** | **✅ 触发 v4.0 升级** |

#### D.8.2 v4.0 升级内容

详见 §11.2 v4.0 升级内容。**核心变化**：
- 3 路线 → 4 路线（A/B/C/E 闲暇态）
- 38 决策 → ~46 决策（+ 路线 E 7 个）
- 9 风险 → 11 风险（+ R12/R13 路线 E 风险 2 个）
- 22 章节 → 25 章节
- 跨文件 dedupe（3 组精确重复 + 24 个语义主题保留）
- 长文档写作准则（§8.3）写入白皮书

#### D.8.3 v4.0 踩坑教训（**v4.0 新加 · 关键**）

**教训 1：Mavis 主线程写长文档必卡循环**

v3.2.2 patch ADR-0002 升级时 + v4.0 升级 v4.0 写作 sub-agent + dedupe sub-agent 多次卡循环（5+ 分钟无输出）。

**修正规则**（写入 §8.3）：
- 文档 < 2KB：Mavis 主线程直接写
- 文档 2-5KB：Mavis 主线程 + 1 个章节完成标记
- 文档 > 5KB：**必须 spawn sub-agent 写** + 强制每个 ## 二级章节完成标记
- 文档 > 20KB：spawn sub-agent + 详细 prompt

**教训 2：sub-agent 也会卡循环**

5 分钟无输出 = **cancel + 主线程接管**。
1.5 分钟文件大小未变 = **cancel + 主线程接管**。

**v4.0 主版本升级反映**：
- Mavis 主线程用分段编辑策略（每个 cat >> 1-2 章节）—— 避免大文件长写循环
- sub-agent 写 ADR-0001 v1 / ADR-0002 v2 时 prompt 已加强制章节标记

#### D.8.4 v4.0 跨文件 dedupe 摘要

详见 `dedupe-report-v4.md`。

**关键发现**：
- **3 组精确重复**（SHA256 一致）：
  - R001: superpowers v6.0.3 zip（3 副本）→ v4 zip 删 1 副本
  - R002: AI 工具链 v2.1 md（3 副本）→ v4 zip 删 1 副本
  - R003: ADR-0001 中英文（2 副本，**SHA256 完全相同**）→ 保留 2 份（sandbox 路径显示问题）
- **24 个语义重复主题**：**全部是有意冗余引用**（v3 设计原则 = "每个章节独立可读 + 关键数字各章都标来源"），**不去重**
- **净节省**：~600 KB（精确重复）+ 0 KB（语义重复保留）

#### D.8.5 v4.0 文件清单

**新生成**：
- `mavis-whitepaper-v4.0.md`（v4 主版本，~90KB / 1700 行 / 25 章）
- `CHANGELOG-v4.0.md`（v4 变更摘要）
- `README.md`（v4 导航）
- `dedupe-report-v4.md`（跨文件 dedupe 报告）
- `scripts/v4-zip.sh`（打包脚本）

**保留**：
- `mavis-whitepaper-v3.2.md`（v3.2.2 patch 主版本，v4 升级基线）
- `mavis-whitepaper-v3.1-archived.md`（v3.1 历史归档）
- `docs/adr/0001-...` + `0002-...` + 英文副本 + zip（4 个 ADR 文件）
- `产品思路-2026-Q2/`（**删内部 R001/R002 副本** = 节省 605KB）
- `docs/superpowers/specs/ + plans/`（spec+plan）
- `archives/2026-06-28-白皮书治理与AI工具/`（治理档案，**保留内部副本**）
- `attachments/`（4 个原始资料：zip + md + 2 jpg）

#### D.8.6 v4.0 阅读优先级（**v4.0 升级**）

| 场景 | 必读章节 |
|---|---|
| **新会话开始** | §0.5 + §0.6 + §1 决策快照 + §2 路线规划 |
| **新产品经理入职** | §0.6 + §0.7 + §1 + §2 + §3 + §10.1-10.3 |
| **岚开发团队入职** | §0.6 + §4 superpowers + §5 工具箱 + §6 接入层 + §7 基础设施 + §10.4 Hook |
| **讨论慢病/健康数据** | §2.4 + §3.5 + ADR-0001 + ADR-0002 |
| **讨论 NAS / 服务器** | §10.1（**v4 升级**）|
| **讨论 OpenClaw / 微信 ClawBot** | §10.2 |
| **讨论产品 brainstorm** | §10.3 |
| **白皮书改动审查** | §10.4 |
| **白皮书治理周期** | §10.5（**v4.0 新加**）|
| **任何数字引用** | §1.1 / §1.4 / §10.1（**v4 优先**，附录 B 次之）|
| **长文档写作** | §8.3（**v4.0 新加**）|
| **踩坑教训** | §8.3 + D.8.3（**v4.0 新加**）|

#### D.8.7 v5.0 升级触发条件（**v4.0 新加**）

| 条件 | 状态 |
|---|---|
| 1. 2026-09-01 季度审查 | ❌ |
| 2. 路线 B B.5 简历级项目启动 | ❌ |
| 3. superpowers v7 发布 | ❌ |
| 4. 岚开发团队入职前 | ❌ |
| 5. 路线 E 升级到 v5（私人项目 → 半公开协作）| ❌ |
| **6. 新加**：4 个 memory topic 任一描述大改 | 监控中 |
| **7. 新加**：用户学习路线大改 | 监控中 |

> **来源**：v3.1 §D.7.5 升级机制 v4 扩展
> **下次审查建议**：2026-10-01（v4.0 升级后 3 个月）做季度审查

---

> **白皮书 v4.0 升级结束 · 2026-07-08 15:25 · 来源：用户 14:38 任务 + v3.1 §D.7.5 条件 5 + Mavis superpowers 7 阶段工作流**
> **本文件路径**：`/workspace/mavis-workspace-v4.0/mavis-whitepaper-v4.0.md`
> **配套文件**：`CHANGELOG-v4.0.md` + `README.md` + `dedupe-report-v4.md` + `scripts/v4-zip.sh`

---

## §0.8 团队角色分工（v4.1 团队版 · 2026-07-17 新加）

> **触发原因**：团队入职（产品经理 / 岚开发团队 / 设计师 / 测试 / 运维 / 法务），需要明确分工。

### 0.8.1 6 角色 + 关注章节速查

| # | 角色 | 必读章节 | 主要产出 |
|---|---|---|---|
| 1 | **PM / 产品经理** | §0.5 + §1 + §2 + §3 + §10.1-10.3 + §0.8-§0.12 | PRD v2.0 + 5 阶段路线图 + 决策记录 |
| 2 | **后端开发** | §4 superpowers + §5 工具箱 + §6 接入层 + §7 基础设施 + §10.4 Hook + ADR-0002 v4.0.2 + SPEC-01 §0-§2 | Spring Boot 后端 + R12 隔离 5 层 + 商业化 API |
| 3 | **前端 / Flutter 开发** | §4 + §5 + Dart 速成 + SPEC-01 §M Flutter + SPEC-04 | Flutter 3.27 + Riverpod + FCM + In-App Purchase |
| 4 | **设计师** | §2.4 路线 E + §0.8 + §0.11 + 待补 §2.5 UI/UX 规范 | Figma 设计稿 + 组件库 + 动效 |
| 5 | **测试 / QA** | §4 + SPEC-04 + R12 隔离 9 类攻击 + §10.4 Hook | 测试套（单元 70% / 集成 20% / E2E 10%）|
| 6 | **运维 / SRE** | §7 基础设施 + §10.4 Hook + SPEC-03 + ADR-0002 v4.0.2 §AG SQLite + §AI | Docker Compose + CI/CD + 监控 + 灾备 |
| 7 | **法务 / 合规** | §0.8 + §3.5 路线 E + ADR-0002 v4.0 §AC | 隐私政策 + PIPL/GDPR/HIPAA + 用户协议 |
| 8 | **投资人 / 合伙人** | §0.1-§0.5 + §0.7 升级摘要 + §10 决策记录 + §3 路线 | pitch deck + 4 路线战略 |

### 0.8.2 决策权分配

| 决策类型 | 决策人 | 建议机制 |
|---|---|---|
| 4 路线变更 | **用户本人** | 单人决策 + 白皮书记录 |
| 商业化上线 | 用户 + PM | 双签 |
| 重大技术选型 | 架构师 + 后端 lead | RFC 文档 + 评审 |
| R12 合规修改 | 后端 lead + 法务 | **5 层防护必查 9 类攻击** |
| 设计规范 | 设计师 + PM | 走 Figma 评论 + 周会 |
| 测试覆盖率 | 测试 lead | 单人决策（覆盖率门槛 ≥ 80%）|
| 部署 + 监控 | SRE | 单人决策 + 灰度发布 |
| 安全事件 | SRE + 用户 | 24h 响应 + 复盘 |

### 0.8.3 团队规模建议（按阶段）

| 阶段 | 团队规模 | 角色 |
|---|---|---|
| **P1 基础（Day 1-3）** | 1-2 人 | 后端 1 + 前端 1 |
| **P2 核心医疗（Day 4-7）** | 2-3 人 | 后端 1 + 前端 1 + PM 0.5 |
| **P3 R12 隔离（Day 8-10）** | 3-4 人 | 后端 1 + 前端 1 + 测试 1 + PM 0.5 |
| **P4 商业化（Day 11-14）** | 4-5 人 | + 法务 0.5 + 设计师 0.5 |
| **P5 上线（Day 15-18）** | 5-6 人 | + SRE 1 + 运维 0.5 |
| **v1.0 正式运营** | 6-8 人 | 全员 + 客服 1 |

---

## §0.9 团队入职手册（v4.1 团队版 · 2026-07-17 新加）

### 0.9.1 30 分钟上手

| 步骤 | 时间 | 内容 | 产出 |
|---|---|---|---|
| 1 | 5 分钟 | 读 §0.5 核心原则 | 5 条原则理解 |
| 2 | 10 分钟 | 读 §1 决策快照 + §0.7 v4.0 升级 | 4 路线战略理解 |
| 3 | 10 分钟 | 读 §2 路线规划 + §3 路线 E | 慢病管理商业产品理解 |
| 4 | 5 分钟 | 读 §0.6 目标读者 | 知道自己角色必读章节 |

### 0.9.2 第一周任务（按角色）

**PM 第一周**：
- [ ] 通读 PRD v2.0（36KB / 992 行）
- [ ] 通读 SPEC-05 5 阶段（17KB）
- [ ] 拆解 P1-P5 任务到 GitHub Issues
- [ ] 与后端 lead 对齐 API 契约（SPEC-02）
- [ ] 与设计师对齐 Figma 流程

**后端开发第一周**：
- [ ] 配 Spring Boot 开发环境（SQLite + DBeaver + VSCode）
- [ ] 跑通 SPEC-01 §3 M0 鉴权
- [ ] 读 ADR-0002 v4.0.2 §AH R12 应用层补偿（**必读**）
- [ ] 配置 CI（GitHub Actions）
- [ ] 写第一个 PR（hello world）

**前端 / Flutter 第一周**：
- [ ] Dart 语言 2 周速成（如未学）
- [ ] Flutter 环境配置（VSCode + 模拟器）
- [ ] 读 SPEC-01 §M Flutter 章节
- [ ] 跑通 Riverpod 示例
- [ ] 写第一个 PR（hello world 界面）

**设计师第一周**：
- [ ] 读 PRD v2.0 + SPEC-01 §6 模块详情
- [ ] 走查现有截图 / 竞品（Apple Health / 华为健康）
- [ ] 出 3 个核心页面线框图（首页 / 病种详情 / 量表评估）
- [ ] 与 PM + 开发对齐组件命名规范

**测试 / QA 第一周**：
- [ ] 读 SPEC-04 测试 SPEC
- [ ] 配 JUnit 5 + Testcontainers + Playwright
- [ ] 跑通 M0 鉴权单测
- [ ] 写 R12 9 类攻击测试套骨架
- [ ] 配 CI 覆盖率门槛（≥ 80%）

**运维 / SRE 第一周**：
- [ ] 读 SPEC-03 部署 SPEC
- [ ] 配 Docker Compose dev（SQLite）
- [ ] 跑通 K8s staging
- [ ] 配 Prometheus + Grafana 监控
- [ ] 写 R1 Runbook 草稿

**法务 / 合规第一周**：
- [ ] 读 ADR-0002 v4.0 §AC 商业产品合规
- [ ] 草稿隐私政策 + 用户协议
- [ ] PIPL/GDPR/HIPAA 法律 review 启动
- [ ] 与 PM 对齐应用商店合规要求
- [ ] 准备 BAA（Business Associate Agreement）模板

### 0.9.3 工具栈速查

| 工具 | 用途 | 文档路径 |
|---|---|---|
| **Mavis** | AI 助理 / 路线决策 / 文档查询 | root session · session 410134033855585 |
| **DBeaver** | SQLite + MySQL 统一 GUI | 免费下载 |
| **VSCode** | 主 IDE | 推荐插件：Flutter / Spring Boot / Dart |
| **GitHub** | 代码托管 + CI/CD | 配置 webhook → Mavis |
| **Figma** | 设计协作 | 设计稿统一管理 |
| **Slack / 飞书** | 团队沟通 | 频道 #pm / #dev / #qa / #ops / #legal |
| **Notion / 语雀** | 文档协作 | 团队 wiki |
| **Jira / GitHub Issues** | 任务管理 | 与 SPEC-05 阶段联动 |

### 0.9.4 必读文档清单（按角色）

| 角色 | 必读 | 推荐读 |
|---|---|---|
| PM | PRD v2.0 / SPEC-05 / §0.5-§0.7 | SPEC-01 / SPEC-04 / §10 |
| 后端 | ADR-0002 v4.0.2 / SPEC-01 / SPEC-02 / SPEC-05 | SPEC-03 / SPEC-04 / §4-§7 |
| 前端 | SPEC-01 §M / SPEC-02 / Dart 速成 / SPEC-05 | SPEC-04 / §0.11 |
| 设计 | PRD v2.0 / SPEC-01 §6 / §0.11 | SPEC-04 E2E / Figma 设计系统 |
| 测试 | SPEC-04 / ADR-0002 v4.0.2 §AH / SPEC-05 | SPEC-02 / §10.4 Hook |
| 运维 | SPEC-03 / ADR-0002 v4.0.2 §AG / SPEC-05 | §7 基础设施 / §10.4 Hook |
| 法务 | ADR-0002 v4.0 §AC / §0.8 / §3.5 | GDPR Article 17/20 / PIPL §38-43 |

---

## §0.10 团队协作规范（v4.1 团队版 · 2026-07-17 新加）

### 0.10.1 会议节奏

| 会议 | 频率 | 时间 | 参与者 | 产出 |
|---|---|---|---|---|
| **每日站会** | 每日 9:00 | 15 分钟 | 全员 | 3 件事：昨天 / 今天 / 阻塞 |
| **周会** | 每周一 10:00 | 60 分钟 | 全员 | 上周回顾 / 本周计划 / 风险 |
| **阶段评审** | 阶段末（D3/D7/D10/D14/D18）| 90 分钟 | 全员 + 用户 | 演示 + 验收 + 下阶段确认 |
| **技术评审** | 按需 | 60 分钟 | 架构师 + 相关开发 | RFC 文档 + 决策记录 |
| **设计评审** | 按需 | 60 分钟 | 设计师 + PM + 前端 | Figma 评论 + 决策记录 |
| **1:1** | 每周 | 30 分钟 | PM/lead + 成员 | 个人发展 + 反馈 |

### 0.10.2 文档约定

| 类型 | 命名 | 位置 | 更新频率 |
|---|---|---|---|
| **白皮书** | `mavis-whitepaper-v{版本}.md` | `/workspace/mavis-workspace-v{版本}/` | 季度 / 大变更时 |
| **ADR** | `0001-/0002-...-...md` | `/workspace/docs/adr/` | 重大决策时 |
| **PRD** | `PRD-...-v{版本}.md` | `/workspace/docs/adr/` | 产品迭代时 |
| **SPEC** | `SPEC-0X-...md` | `/workspace/docs/adr/SPEC/` | patch 时 |
| **RFC** | `RFC-...-YYYYMMDD.md` | `/workspace/docs/adr/RFC/` | 技术选型时 |
| **Runbook** | `RUNBOOK-...md` | `/workspace/docs/adr/RUNBOOK/` | 故障复盘时 |

### 0.10.3 决策流程

```
问题/想法
   ↓
brainstorming（3-5 个方案 + 推荐）
   ↓
讨论 + 用户确认（重大决策）
   ↓
写入 ADR（决策记录 + 理由 + 风险）
   ↓
白皮书引用（version 升级 + 决策摘要）
   ↓
白皮书 Hook 审查（每 5 分钟自动跑）
```

### 0.10.4 代码规范

| 维度 | 规范 |
|---|---|
| **Git Flow** | main / develop / feature/* / hotfix/* |
| **PR 大小** | 单 PR ≤ 500 行（超大 PR 必拆）|
| **Commit 规范** | feat / fix / refactor / docs / test / chore |
| **Code Review** | 至少 1 个 reviewer + R12 隔离必查 |
| **覆盖率** | 单 PR 覆盖率 ≥ 70% / 总体 ≥ 80% |
| **R12 9 类攻击** | CI 必跑，全绿才能 merge |

### 0.10.5 文档审查 Hook（v2 已上线）

```yaml
# cron 任务：白皮书审查 v2
task_id: 412827785302108
schedule: '*/5 * * * *'  # 每 5 分钟
路径: /workspace/.mavis/whitepaper-watcher-hook/
3 skill 协作:
  - superpowers:code-reviewer（审查章节完整性）
  - memory-curator（更新 memory topic）
  - product-manager（PRD 决策一致性）
```


---

## §0.11 团队 5 阶段路线图（v4.1 团队版 · 2026-07-17 新加）

> **与 SPEC-05 联动**——SPEC-05 是技术实施版本，本章节是团队协同版本。

### 0.11.1 18 天排期 + 团队协作

| 阶段 | 周期 | 总小时 | 团队分工 | 阶段产出 |
|---|---|---|---|---|
| **P1 基础** | D1-3 | 16h | 后端 1 + 前端 1 | 能登录看到空 home |
| **P2 核心医疗** | D4-7 | 32h | 后端 1 + 前端 1 + PM 0.5 | 5 天数据 + 铜徽章 |
| **P3 R12 隔离** | D8-10 | 24h | 后端 1 + 前端 1 + 测试 1 | A 看 B 量表 → 403 |
| **P4 商业化** | D11-14 | 32h | + 法务 0.5 + 设计师 0.5 | 订阅闭环 + 推送 |
| **P5 上线** | D15-18 | 24h | + SRE 1 + 运维 0.5 | v1.0 发布 |

### 0.11.2 双人并行（推荐 · 节省 30%）

| 角色 | 负责 | 起点 |
|---|---|---|
| **开发者 A（后端）** | P1-P5 后端全程 | D1 启动 |
| **开发者 B（前端）** | P2-P5 前端全程 + D1-D2 设计 UI 草图 | D1 设计 / D2 启动编码 |
| **PM** | 全程协调 + 决策记录 | D1 启动 |
| **测试** | D8 加入 | D8 启动 |
| **设计师** | D4 加入 | D4 启动 |
| **法务** | D11 加入 | D11 启动 |
| **SRE** | D15 加入 | D15 启动 |

### 0.11.3 解除阻塞的硬门槛

| 阶段出口 | 硬门槛 | 责任人 |
|---|---|---|
| P1 → P2 | 登录接口 200 + 单测覆盖 ≥ 60% + Docker 起得来 | 后端 lead |
| P2 → P3 | M1-M3+M6 e2e + 30 连续打卡等级验证 | 后端 lead + 前端 |
| **P3 → P4** | **9 类 R12 攻击全过 + 字段加密覆盖 ≥ 95% + OWASP ZAP clean + 独立 reviewer 通过** | **后端 lead + 测试 lead** |
| P4 → P5 | Google Play + Apple IAP 双重验证通过 + FCM/APNs 推送全通 | 后端 + SRE |

### 0.11.4 团队日常仪式

```
每日 9:00  站会（15 分钟）
每周一 10:00  周会（60 分钟）
阶段末 D3/D7/D10/D14/D18  阶段评审（90 分钟）
每月 1 日    月度回顾（2 小时）
每季度      季度规划（半天）
```

---

## §0.12 团队风险与升阻（v4.1 团队版 · 2026-07-17 新加）

### 0.12.1 团队 5 大风险

| 编号 | 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|---|
| **TR-1** | R12 隔离被绕过 | 极低 | **极高**（法规罚款）| 5 层防护 + 9 类攻击 + 独立 reviewer |
| **TR-2** | 团队成员流动 | 中 | 中 | 文档齐全 + 知识共享 + pair programming |
| **TR-3** | 商业化合规被卡 | 中 | 高 | 法务早期介入 + PIPL/GDPR review + 律师合同 |
| **TR-4** | 应用商店审核拒绝 | 中 | 高 | 提前 2 周准备 + ASO 优化 + Beta 测试 |
| **TR-5** | P2/P3 阶段延期 | 中 | 中 | 双人并行 + 阶段评审 + 风险升级 |

### 0.12.2 团队应急响应

| 紧急级别 | 触发 | 响应时间 | 升级路径 |
|---|---|---|---|
| **P0 紧急** | R12 隔离被绕过 / 隐私泄露 | 1 小时内 | SRE + 后端 lead + 用户 |
| **P1 高** | 服务不可用 / 数据丢失 | 4 小时内 | SRE + 后端 lead |
| **P2 中** | 功能 bug / 性能问题 | 24 小时内 | 阶段责任人 |
| **P3 低** | 文档 / 体验改进 | 1 周内 | 全员 |

### 0.12.3 团队升阻 SOP

```
风险识别
   ↓
SRE / 责任人评估（30 分钟内）
   ↓
P0/P1 → 24h 复盘会议
   ↓
写入 ADR / 风险登记
   ↓
通知全团队（Slack 频道 + 邮件）
   ↓
跟踪 30 天（避免重复）
```

### 0.12.4 团队成长机制

| 维度 | 机制 |
|---|---|
| **Onboarding** | §0.9 团队入职手册 |
| **Mentorship** | 1:1 + pair programming + code review |
| **培训** | Dart 速成 / superpowers / Spring Boot 实战 |
| **晋升路径** | 初级 → 中级 → 高级 → lead → 架构师 |
| **知识共享** | 每周技术分享会 + ADR 文档 + RFC 流程 |

---

## §0.13 v4.1 团队版升级摘要（2026-07-17 新加）

### 0.13.1 变更清单

| 章节 | 改动 | 用途 |
|---|---|---|
| §0.8 | 6 角色 + 决策权 + 团队规模 | 团队分工 |
| §0.9 | 30 分钟上手 + 第一周任务 + 工具栈 + 必读清单 | 团队入职 |
| §0.10 | 会议节奏 + 文档约定 + 决策流程 + 代码规范 + Hook | 团队协作 |
| §0.11 | 5 阶段路线图 + 双人并行 + 硬门槛 | 团队节奏 |
| §0.12 | 5 大风险 + 应急响应 + 升阻 SOP + 成长机制 | 团队治理 |

### 0.13.2 升级触发（v5.0）

- 团队从 8 人扩到 15+ 人
- 商业化正式上线（B2C 订阅稳定）
- 路线 B AI 集成启动
- superpowers v7 发布
- 岚开发团队正式入职前

