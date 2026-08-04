# CBT 思维记录改造 — Sub-spec 1（核心三档可切换 UI）

| 项目 | 内容 |
|---|---|
| 状态 | design (待 review) |
| 日期 | 2026-08-04 |
| 范围 | sub-spec 1 / 5（核心 CBT 思维记录） |
| 后续 sub-spec | 重评效果图 / mood 列表页 / PDF 导出 / AI 辅助 |

## 背景

当前 mood 模块是单页 dialog 结构：`score(1-5) + tags + 4 维(精力/睡眠/焦虑) + 自由 note + 录音`。自由 `note` 缺乏结构化引导，对认知重构（cognitive restructuring）这一 CBT 核心技巧支持不足。

CBT 实践中 Beck 的标准做法是 5 栏思维记录（情境/自动思维/情绪+强度/支持-反对证据/替代思维+重新评分），3 栏是入门版，7 栏是深度版（含核心信念 + 行为应对）。本 spec 引入「三档可切换思维记录」，默认 3 栏（低门槛）但允许用户升级到 5/7 栏（认知重构关键步骤齐全），并记忆档位偏好。

## Goals

- 在 mood dialog 内提供 3/5/7 档思维记录可切换 UI（默认 3 档）
- 8 个新字段持久化（`situation` / `automaticThought` / `evidenceFor` / `evidenceAgainst` / `alternativeThought` / `reratedScore` / `coreBelief` / `behaviorResponse`）
- 档位偏好记忆：设置页设默认档位（持久化），dialog 顶部 SegmentedButton 可临时切档（不持久化）
- 老数据完全兼容（schema 升级，nullable 新字段）
- trend_calendar 在 5/7 栏 mood entry 上展示 CBT 摘要

## Non-Goals（明确剔除）

- ❌ CBT 重评效果图（`reratedScore` 对比）— sub-spec 2
- ❌ mood 列表页 — sub-spec 3
- ❌ CBT 字段导出 PDF — sub-spec 4
- ❌ AI 辅助生成思维记录 — sub-spec 5
- ❌ 现有 `note` 字段迁移 / 废弃 — 保留
- ❌ CBT 字段的 share / 邮件 — 不在 scope

## 范围（sub-spec 1）

包含以下 5 块：

1. **数据模型**：drift schema 升级（v12 → v13），entity 新增 8 字段，迁移兼容老数据
2. **档位状态机**：SharedPreferences 持久化 + 设置页入口 + dialog 顶部 SegmentedButton
3. **3 栏 UI**（单屏长表单）
4. **5/7 栏 UI**（wizard 步骤式 + 进度条 + 引导）
5. **趋势集成**：trend_calendar 单元格 + `_DayDetailCard` 展示 CBT 摘要

## 数据模型

### Drift 表 schema 升级

**`mood_entries` 表新增 8 列**（全 nullable）：

```sql
ALTER TABLE mood_entries ADD COLUMN situation TEXT;
ALTER TABLE mood_entries ADD COLUMN automatic_thought TEXT;
ALTER TABLE mood_entries ADD COLUMN evidence_for TEXT;
ALTER TABLE mood_entries ADD COLUMN evidence_against TEXT;
ALTER TABLE mood_entries ADD COLUMN alternative_thought TEXT;
ALTER TABLE mood_entries ADD COLUMN rerated_score INTEGER;
ALTER TABLE mood_entries ADD COLUMN core_belief TEXT;
ALTER TABLE mood_entries ADD COLUMN behavior_response TEXT;
```

**schemaVersion 升级**：12 → 13

**迁移策略**：`onUpgrade` 块内对所有现有用户执行上述 ALTER TABLE；新用户走 `createAll`。

### Domain Entity

`MoodEntryEntity` 新增 8 个 nullable 字段（类型见上表），保持不可变。`copyWith` 用 `DomainValue<T?>` 包装（现有模式）以支持显式 `null` 写入（清空字段）。

**`MoodEntryDraft` 同步新增 8 字段**（与 entity 同名同类型）。`MoodRepository.add()` 和 `update()` signature 保持 `{required MoodEntryDraft draft}`，新字段全部在 draft 内。

**业务方法新增**：
- `bool get isCbtRecord` — 是否 5/7 栏（任意一个 CBT 字段非空）
- `int? get cbtLevel` — 推断档位：3=note 模式 / 5=alternativeThought 非空 / 7=coreBelief 非空
- `double? get scoreShift` — `reratedScore - score`（5/7 栏专用，3 栏为 null）

### 数据库迁移兼容性

- 老数据：所有新字段为 null → UI 自动按 3 栏 mode 渲染
- 反向兼容：导出 / 备份时 8 字段 null 不报错
- 字段名漂移检查：使用 `check_drift_namespace.py` 守门员确认 `@DataClassName('MoodEntry')` 唯一

## 档位状态机

### 持久化层

- SharedPreferences key：`mood.thought_record_level` (int, 3 / 5 / 7)
- 默认值：3（首次安装 / 升级时写入）
- provider 暴露：`final thoughtRecordLevelProvider = NotifierProvider<...>(...)` 包装 SharedPreferences

### 两处入口

**A. 设置页**（持久化默认档位）
- 位置：`lib/presentation/pages/settings/page.dart` 新增 section "思维记录"
- 控件：`RadioListTile<ThoughtRecordLevel>` 三选一（3 栏 / 5 栏 / 7 栏）
- 文案（ARB key：`settingsCbtLevel*`）：
  - 标题：「思维记录档位」
  - 3 栏说明：「入门版，1-2 分钟可填完」
  - 5 栏说明：「标准 Beck 思维记录，含认知重构关键步骤」
  - 7 栏说明：「深度版，含核心信念识别和行为应对」
- 改后立即写入 SP。**不影响已经在编辑的 dialog**（dialog 打开时已读快照值）

**B. Dialog 顶部 SegmentedButton**（临时切换）
- 控件：`SegmentedButton<ThoughtRecordLevel>` (3 栏 / 5 栏 / 7 栏)
- 行为：仅影响**当前 dialog 这次**填写，关闭 dialog 后失效（不写 SP）
- 状态提升：`_MoodDialogContent` 持有 `ThoughtRecordLevel _currentLevel` 局部 state

### 档位切换时的数据保留

schema 全 8 字段都在 mood entry 上，**任何档位切换都不丢数据**。UI 渲染逻辑：
- 3 → 5：已填的 `situation` / `automaticThought` 保留，新增 evidenceFor/Against/Alternative/reratedScore 4 字段空白
- 5 → 3：5 栏字段保留在 schema，UI 隐藏；下次再切 5 栏可见
- 5 → 7：在 step 5 后插入 step 6 (coreBelief) / step 7 (behaviorResponse)
- 7 → 5：core/behavior 字段保留但不显示

### wizard step 重置

5/7 栏 wizard 中用户临时切档时，step index 跳到**第一个完全为空的栏**：
- 计算函数：`int _firstEmptyStep(MoodEntryDraft draft, int level)`
- 全空 → step 1
- 5 栏：situation 空 → 1；automaticThought 空 → 2；evidenceFor/Against 全空 → 3；alternativeThought 空 → 4；都填了 → 5（确认页）

## UI 设计

### 3 栏 mode（单屏长表单）

```
┌──────────────────────────────────────┐
│ 情绪记录                  [3|5|7栏] │  ← 顶部 SegmentedButton
├──────────────────────────────────────┤
│ ① 你现在的感受？                      │  ← score 1-5（复用）
│   ○ ● ○ ○ ○                          │
├──────────────────────────────────────┤
│ ② 发生了什么？                        │  ← situation
│   [多行文本框, placeholder]            │
├──────────────────────────────────────┤
│ ③ 那一刻脑海里闪过什么想法？          │  ← automaticThought
│   [多行文本框 + ? prompt 库]           │
├──────────────────────────────────────┤
│ [🎙 录音] [标签选择] [保存]            │
└──────────────────────────────────────┘
```

### 5/7 栏 mode（wizard 步骤式）

```
┌──────────────────────────────────────┐
│ 情绪记录              [3|5|7栏]      │  ← 顶部 SegmentedButton
│ Step 2 / 5  ●●○○○                    │  ← 进度条
├──────────────────────────────────────┤
│ ℹ️ 什么是 CBT 思维记录？  [展开 ▾]   │  ← 折叠说明卡
├──────────────────────────────────────┤
│ ② 自动思维  ⓘ                        │
│ 那一刻脑海中闪过的想法、印象或信念     │  ← 引导文案
│ [多行文本框, placeholder]             │
│  [?] 引导问题:                        │  ← prompt 库
│    • 如果你的好朋友遇到这事,          │
│      你会怎么劝TA?                    │
│    • 最坏/最好/最现实的结果是什么?     │
│    • 一年后你还会这么想吗?            │
│ [录音转写 → 填入此栏]                │  ← 录音后激活
├──────────────────────────────────────┤
│              [上一步] [下一步 →]      │
└──────────────────────────────────────┘
```

**5 栏 5 步映射**：
- Step 1: situation
- Step 2: automaticThought
- Step 3: score(1-5) + evidenceFor + evidenceAgainst
- Step 4: alternativeThought + reratedScore(1-5)
- Step 5: 确认 + 提交

**7 栏 加 2 步**：
- Step 6: coreBelief
- Step 7: behaviorResponse

### 引导系统

- **顶部 ℹ️ 折叠卡**：静态说明 CBT 思维记录是什么，1 段话。**新用户首次默认展开**（用 `showOnFirstUse` 标志，存 SP），老用户可折叠
- **每栏 ⓘ 图标**：popup 弹窗显示该栏 CBT 含义（学术化说明）
- **每栏 placeholder**：1 句启发式引导
- **每栏 [?] prompt 库**：弹 bottom sheet，3-5 个引导问题，点击追加到文本框
- **实时引导**：step 1 → step 2 切换时 step 顶部小提示「接下来想想为什么这个事件让你产生这个想法」

### 录音转写与 CBT 字段关联

- 录音后 STT transcript 先入 `note` 字段（保持现有行为）
- 「自动思维」栏上方加按钮「将录音转写填入此栏」（仅当 `audioTranscript` 非空时显示）
- 用户**主动**点击才填，不默认填（避免误填误导认知重构）

## 状态管理

### 新增 Provider

- `thoughtRecordLevelProvider` (NotifierProvider\<ThoughtRecordLevel\>) — SP 持久化
- `cbtDraftProvider` (NotifierProvider\<CbtDraftState\>) — 当前 dialog 内的 CBT 字段临时状态

### CbtDraftState

不可变 state：
- `ThoughtRecordLevel level` — 当前 dialog 档位
- `int stepIndex` — wizard 步进（3 栏 mode 固定 0）
- `MoodEntryDraft draft` — 完整 draft（含 score/tags/note/4 维/audio/CBT 8 字段）
- `bool showCbtExplainer` — 顶部 ℹ️ 折叠卡是否展开（首次默认 true）

方法：
- `setLevel(ThoughtRecordLevel)` — 切档 + 跳到第一个未填 step
- `setStep(int)` — 跳到指定 step（带范围 check）
- `updateField(String key, dynamic value)` — 更新单个 CBT 字段
- `reset()` — 清空（dialog 关闭时调）

## 错误处理

- SP 读档位失败（罕见）→ fallback 3 栏，UI 显示「无法读取偏好，使用默认档位」toast（warn 级别，不阻断）
- schema 升级失败（罕见）→ 走 drift 默认错误处理，App 启动崩溃对话框
- 用户填了一半关 dialog → 不自动保存（保持现有 dialog 行为）；如未来需要草稿持久化，留 v2.x

## 测试

- **domain 业务**：`MoodEntryEntity` 新字段 `cbtLevel` / `scoreShift` / `isCbtRecord` 边界条件 + `CbtDraftState` setLevel / setStep / 切档保留数据
- **data round-trip**：drift insert → entity → CBT 字段全保留
- **presentation widget**：
  - 3 栏 mode 渲染：3 栏输入框可见
  - 5 栏 mode 渲染：wizard step 1 显示 situation
  - 7 栏 mode 渲染：wizard 多 2 步
  - SegmentedButton 切档：3 → 5 保留 situation
  - 录音转写填入按钮：仅当 audioTranscript 非空时显示
  - 设置页 radio 改后 SP 写入
- **集成**：trend_calendar 单元格 5/7 栏 mood entry 显示 📝 角标 + `_DayDetailCard` 展开 CBT 字段
- **回归**：老 mood entry 升级后 3 栏 mode 渲染无异常

## 风险与回滚

- **schema 迁移失败**：测试覆盖 + 灰度 5% 用户（v0.28+ 已支持）；失败回滚到 v12
- **CBT 字段填一半误保存**：保存前检查 score 必填 + situation 必填（5/7 栏），其他可选
- **wizard step 跳来跳去 UX 差**：用户反馈 → v2.x 改"全部步骤可滚动"

## ARB key 列表（待加）

```
moodCbtLevelLabel3       "3 栏"
moodCbtLevelLabel5       "5 栏"
moodCbtLevelLabel7       "7 栏"
moodCbtBanner            "CBT 思维记录"
moodCbtExpandExplain     "什么是 CBT 思维记录？"
moodCbtSectionSituation  "情境"
moodCbtSectionAutomaticThought "自动思维"
moodCbtSectionEvidenceFor    "支持证据"
moodCbtSectionEvidenceAgainst "反对证据"
moodCbtSectionAlternative    "替代思维"
moodCbtSectionRerated        "重新评分"
moodCbtSectionCoreBelief     "核心信念"
moodCbtSectionBehavior       "行为应对"
moodCbtExplainerBody   "CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准：先记录情境与想法，再找证据支持/反对，最后写下更平衡的替代想法。"
moodCbtFieldHintSituation  "触发这个想法的事件是什么？发生在哪、什么时候、有谁？"
moodCbtFieldHintAutomaticThought "那一刻脑海中闪过的想法、印象或信念是什么？"
moodCbtFieldHintEvidenceFor  "什么事支持这个想法？"
moodCbtFieldHintEvidenceAgainst "什么事不支持这个想法？"
moodCbtFieldHintAlternative  "如果你的好朋友遇到这事，你会怎么劝TA？"
moodCbtFieldHintCoreBelief   "这个想法背后更深层的信念是什么？（如 \"我不够好\"）"
moodCbtFieldHintBehavior     "接下来你打算怎么做？"
moodCbtPromptTitle          "引导问题"
moodCbtStepOf               "第 {current} 步 / 共 {total} 步"
moodCbtTranscriptApply      "将录音转写填入此栏"
moodCbtReratedComparison    "重新评分：{new}（原 {old}）"
settingsCbtLevel            "思维记录档位"
settingsCbtLevelDescription "选择每次记录情绪时使用的思维记录模板"
settingsCbtLevel3Desc       "入门版，1-2 分钟可填完"
settingsCbtLevel5Desc       "标准 Beck 思维记录，含认知重构关键步骤"
settingsCbtLevel7Desc       "深度版，含核心信念识别和行为应对"
moodCbtScoreReratedLabel    "重新评分"
moodCbtChipBadge5           "CBT 5 栏"
moodCbtChipBadge7           "CBT 7 栏"
```

## 实施步骤（high level）

1. schema 升级（drift v12→v13 + 8 字段 + entity + draft）
2. provider 层（`thoughtRecordLevelProvider` + `CbtDraftState`）
3. ARB key 添加（zh / en / zh_Hant 同步）
4. 公共 widget：`CbtSectionField` + `CbtPromptSheet` + `CbtExplainerCard`
5. 3 栏 mode UI（改造 `mood_recorder_page.dart`）
6. 5/7 栏 wizard UI（新建 `cbt_wizard.dart`）
7. 设置页 radio 入口
8. trend_calendar 集成（单元格 + DayDetailCard）
9. 测试（domain 8 cases + data 4 cases + widget 12 cases + 集成 2 cases = 26 cases）
10. 守门员：`flutter analyze` 0 / `flutter test` 全过 / 16 脚本全绿

## 后续 sub-spec 计划（不在本 spec 范围）

- **sub-spec 2**：CBT 重评效果图（score vs reratedScore 对比曲线）
- **sub-spec 3**：mood 列表页（独立 list + detail page + filter + search）
- **sub-spec 4**：CBT 字段导出 PDF（data_export service 扩展）
- **sub-spec 5**：AI 辅助生成思维记录（provider 选型 + 同意流程 + 脱敏 + 失败降级）
