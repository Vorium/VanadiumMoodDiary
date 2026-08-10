# 情绪日记模块调整设计方案 — 参照 Apple Health 心理状态

**创建时间**: 2026-08-07
**状态**: 设计方案（全部实施）
**参照**: Apple Health State of Mind (iOS 17+)

---

## 一、Apple Health 心理状态核心设计

### 1.1 记录界面
- **1-5 分滑块**: 红(非常不愉快) → 黄(一般) → 绿(非常愉快)，连续渐变
- **影响因素标签**: 6 大类 30+ 预设标签
  - 关系: 家人、朋友、伴侣、孩子、同事
  - 健康: 运动、生病、睡眠、饮食
  - 活动: 工作、爱好、旅行、通勤、购物、打扫、游戏、阅读、娱乐
  - 正念: 冥想、呼吸、日记、瑜伽
  - 天气: 晴天、多云、雨天、雪天、刮风
  - 其他: 自定义
- **两种模式**: 日常心情 (Overall Today) + 瞬时情绪 (Right Now)

### 1.2 趋势分析
- 周/月/年折线图
- 分数分布直方图
- 影响因素关联分析 (哪些因素与高/低分相关)

### 1.3 提醒机制
- 定时提醒记录情绪
- 可自定义提醒时间

---

## 二、当前项目现状

### 2.1 已有优势
- 4 维度评分 (mood/energy/sleep/anxiety) — 比 Apple Health 更全面
- CBT 思维记录 (3/5/7 栏 Beck 标准) — Apple Health 无此功能
- 语音录入 + STT — Apple Health 无此功能
- 时段标记 (morning/noon/evening/night)
- SQLCipher 加密存储

### 2.2 需要调整
1. 影响因素标签: 6 个固定"情绪状态"标签 → 6 大类 30+ "影响因素"标签
2. 趋势图: 简单 4 段聚合 → 周/月折线图 + 分布直方图
3. 提醒通知: 无 → 每天定时提醒
4. 详情页: 列表预览 → 完整详情页
5. 编辑/删除: 只能新增 → 支持编辑删除
6. 因素关联分析: 无 → 标签与分数相关性

---

## 三、实施计划

### Phase 1: P0 — 影响因素标签 + 提醒通知 (1周)

#### 1.1 影响因素标签系统

**数据模型扩展** (schemaVersion 21):

```dart
// Drift 表新增列
TextColumn get influenceFactorsJson => text().withDefault(const Constant('[]'))();

// 影响因素分类常量 (domain 层)
enum InfluenceCategory {
  relationships('relationships'),  // 关系
  health('health'),                // 健康
  activities('activities'),        // 活动
  mindfulness('mindfulness'),      // 正念
  weather('weather'),              // 天气
  other('other');                  // 其他
}

// 预设影响因素 (domain 层)
const Map<InfluenceCategory, List<String>> kInfluenceFactors = {
  InfluenceCategory.relationships: ['家人', '朋友', '伴侣', '孩子', '同事'],
  InfluenceCategory.health: ['运动', '生病', '睡眠好', '饮食健康'],
  InfluenceCategory.activities: ['工作', '爱好', '旅行', '通勤', '购物', '游戏', '阅读', '娱乐'],
  InfluenceCategory.mindfulness: ['冥想', '呼吸练习', '写日记', '瑜伽'],
  InfluenceCategory.weather: ['晴天', '多云', '雨天', '雪天', '刮风'],
};
```

**UI 变更**:
- MoodRecorderPage 加 "影响因素" section (可折叠)
- 按类别分组展示 chip，多选
- 底部 "+ 自定义" 按钮

**ARB key**: ~20 个 (类别名 + 因素名) × 3 语

#### 1.2 情绪记录提醒通知

**实现路径**:
- data: 新建 `MoodReminderNotifier` (参照 MedicationNotifier 模式)
  - 每天固定时间 (默认 20:00) 发通知
  - 通知 payload: `chroniccare://mood-diary`
  - 通知 id: `moodReminderBaseId = 8000`
- presentation: 设置页加 "情绪记录提醒" 开关 + 时间选择
- ARB key: ~5 个 × 3 语

### Phase 2: P1 — 趋势图 + 详情页 + 编辑删除 (1-2周)

#### 2.1 趋势图增强

**新建页面**: `mood_trend_page.dart`
**路由**: `/mood-trend` (从 mood-list 页进入)

**图表**:
1. 周趋势折线图: 近 7 天每天平均分
2. 月趋势折线图: 近 30 天每天平均分
3. 分布直方图: 1-5 分各占多少天
4. 4 维度雷达图: mood/energy/sleep/anxiety 各维度均值

**实现**: 复用 `fl_chart` (已有依赖) 或自绘 CustomPainter

#### 2.2 因素关联分析

**逻辑**:
```
遍历所有有 influenceFactors 的 entry
→ 按因素分组
→ 计算每组 avgScore + count
→ 按 avgScore 排序
→ 输出: [{factor: "家人", avg: 4.2, count: 15}, ...]
```

**UI**: 柱状图或卡片列表

#### 2.3 情绪详情页

**新建**: `mood_detail_page.dart`
**路由**: `/mood-detail/:id`

**布局**:
```
┌─────────────────────────────────┐
│  ← 情绪详情        [编辑] [删除] │
├─────────────────────────────────┤
│  😄 4/5  2026-08-07 20:30       │
│  时段: 晚上                      │
├─────────────────────────────────┤
│  4 维度:                         │
│  情绪 ████░ 4  精力 ███░░ 3     │
│  睡眠 █████ 5  焦虑 ██░░░ 2     │
├─────────────────────────────────┤
│  情绪状态: [焦虑] [失眠]         │
│  影响因素: [家人] [运动] [晴天]  │
├─────────────────────────────────┤
│  CBT 思维记录 (5栏)             │
│  情境: 今天工作压力大...         │
│  自动思维: 我做不好...           │
│  支持证据: ...                   │
│  反对证据: ...                   │
│  替代思维: ...                   │
│  重新评分: 3/5                   │
├─────────────────────────────────┤
│  [🎤 播放录音] 01:23            │
│  文字备注: 今天感觉...           │
└─────────────────────────────────┘
```

#### 2.4 编辑/删除已有记录

**编辑**: 复用 MoodRecorderPage，传入已有 entry 预填
**删除**: 确认 dialog → `moodRepositoryProvider.delete(id)`
**入口**: 详情页底部 + 列表页左滑 Dismissible

### Phase 3: P2 — 瞬时/日常模式 + 滑块渐变 + 导出 (1周)

#### 3.1 瞬时/日常记录模式

**Drift 表新增**: `recordingMode` 列 ('momentary' / 'daily')
**UI**: MoodRecorderPage 顶部加 SegmentedButton 切换
**默认**: 瞬时模式 (减少认知负担)

#### 3.2 评分滑块颜色渐变

**替换**: ChoiceChip → Slider + 颜色渐变
**颜色**: 1=红(#FF3B30) → 3=黄(#FFCC00) → 5=绿(#34C759)

#### 3.3 情绪日记导出

**接入**: data_export_service 加 mood 导出
**格式**: JSON (已有) + PDF (新建) + CSV (新建)

### Phase 4: P3 — CBT 重评趋势 (3天)

#### 4.1 CBT 重评趋势可视化

**数据**: scoreShift = reratedScore - score
**UI**: 在趋势页加 "CBT 效果" section
**图表**: 折线图展示 scoreShift 随时间变化

---

## 四、数据层变更汇总

### 4.1 Drift 表迁移 (schemaVersion 21)

```dart
// 新增列
TextColumn get influenceFactorsJson => text().withDefault(const Constant('[]'))();
TextColumn get recordingMode => text().withDefault(const Constant('momentary'))();
```

### 4.2 MoodEntryEntity 扩展

```dart
// 新增字段
final List<String> influenceFactors;  // 影响因素列表
final String recordingMode;           // 'momentary' / 'daily'
```

### 4.3 新增 domain 文件

| 文件 | 说明 |
|------|------|
| `domain/entities/influence_category.dart` | 影响因素分类枚举 + 预设常量 |
| `domain/logic/mood_factor_analyzer.dart` | 因素关联分析纯函数 |

### 4.4 新增 data 文件

| 文件 | 说明 |
|------|------|
| `core/data/services/mood_reminder_notifier.dart` | 情绪记录提醒通知编排 |

### 4.5 新增 presentation 文件

| 文件 | 说明 |
|------|------|
| `pages/mood/widgets/mood_influence_chips.dart` | 影响因素标签选择器 |
| `pages/mood_list/mood_detail_page.dart` | 情绪详情页 |
| `pages/mood_list/mood_trend_page.dart` | 趋势图页 |
| `pages/mood_list/widgets/mood_trend_chart.dart` | 趋势图 widget |
| `pages/mood_list/widgets/mood_distribution_chart.dart` | 分布直方图 |
| `pages/mood_list/widgets/mood_factor_card.dart` | 因素关联卡片 |

### 4.6 新增 ARB key 估算

| 类别 | key 数 | 说明 |
|------|--------|------|
| 影响因素类别名 | 6 | 关系/健康/活动/正念/天气/其他 |
| 影响因素标签名 | 30 | 5×6 类 |
| 提醒设置 | 5 | 开关/时间/标题/描述 |
| 趋势图 | 10 | 标题/轴标签/空态 |
| 详情页 | 8 | 标题/操作/维度标签 |
| **合计** | **~60** | × 3 语 = 180 条 ARB |

---

## 五、兼容性

| 现有功能 | 影响 |
|----------|------|
| QuickMoodCarousel (主页快速打卡) | 不变，仍只填 score |
| MoodRecorderPage Dialog | 扩展，加影响因素 section |
| CBT 思维记录 | 不变 |
| 录音功能 | 不变 |
| MoodListPage 列表 | 不变，加点击进详情页 |
| MoodPeriodAggregator | 不变，趋势图是新增页面 |
| 数据导出 | 扩展，加 mood 数据 |

---

## 六、决策点

| # | 问题 | 决策 |
|---|------|------|
| 1 | 影响因素 vs 情绪状态标签 | **两者共存**: 情绪状态标签 (焦虑/抑郁/平静...) 保留，影响因素标签 (家人/工作/运动...) 新增 |
| 2 | 自定义标签 | **P2 做**: 先用预设覆盖 90%，后续加自定义 |
| 3 | 瞬时/日常模式 | **P2 做**: 默认瞬时，减少认知负担 |
| 4 | 趋势图库 | **自绘 CustomPainter**: 项目已有 app_tokens 体系，fl_chart 风格不匹配 |
| 5 | 提醒时间 | **默认 20:00**: 精神心理患者晚间反思最合适 |
