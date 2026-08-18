# ChronicCare 用户旅程图 (User Journey Map)

> **文档**: R128e audit 优化 (论文 1 赵佳睿《服务设计的心灵树洞 APP》§3.2 优化)
> **版本**: 2026-08-18
> **目标**: 形式化 3 阶段用户旅程 (服务前 / 服务中 / 服务后) + 触点 + 情感曲线, 跨团队对齐设计语言

---

## 一、目标用户 (Persona)

| 维度 | Persona A: 职场青年 | Persona B: 学生党 | Persona C: 待业/复健期 |
|---|---|---|---|
| 年龄 | 22-34 | 16-22 | 25-45 |
| 痛点 | 工作压力 + 焦虑失眠 | 学业 + 恋爱 + 社交 | 失业 + 抑郁 + 孤独 |
| 频度 | 每日 1-3 次倾诉 | 每日 2-5 次 | 每周 3-7 次 |
| 风险 | 中度焦虑 (PHQ-9 5-9) | 中度焦虑 + 失眠 (ISI 8-14) | 重度抑郁 (PHQ-9 ≥10) |
| 渠道 | 通勤 + 午休 + 睡前 | 课间 + 宿舍 + 晚自习 | 全天不定时 |

论文 1 §1.1 用户画像对齐: 18-34 岁, 抑郁 + 焦虑占比高, 需倾诉出口。

## 二、3 阶段用户旅程

### 阶段 1: 服务前 (Service Before) — 首次下载到首次记录

```
触点序列:
  App Store / Play Store 搜索
    ↓ 看到截图 + 描述
  下载 + 安装
    ↓ 首次启动
  启动页 (translucent AppBar + 海洋主题)
    ↓ 4 步引导
  引导 Step 1: 同意 (隐私 + 医疗免责 + 敏感数据 3 同意书)
    ↓ 同意
  引导 Step 2: 欢迎 (情绪日记 + 树洞 + 趋势 3 主功能介绍)
    ↓ 选 "开始"
  引导 Step 3: 用药 (可选, 可跳过)
    ↓
  引导 Step 4: 完成
    ↓ 进入主页
  主页 4 tab: Mood / Vent / Trend / Settings
```

| 触点 | 用户行为 | 情感 | 痛点机会 | 慢性应对 |
|---|---|---|---|---|
| 应用商店搜索 | 看截图 + 描述 | 好奇 | "真的免费吗?" "会上 Apple Health 吗?" | 描述明确 "永久免费 + 本地化" + tooltip "应用内数据, 不上 Apple Health" |
| 启动页 | 1s 看到 ocean blue + 治愈系 | 期待 | 启动慢 | 启动期放 EarlyLoadingApp (R104) 立即显示 loading |
| 引导 Step 1 (同意) | 3 同意书弹窗 | 信任 | "数据安全吗?" | ConsentGate 集中器 + SQLCipher 加密声明 |
| 引导 Step 2 (欢迎) | 3 主功能卡片 | 期待 | "哪个先试?" | 突出 Mood (P0 主线) + Vent (P0 主线) |
| 引导 Step 3 (用药) | 可跳过 | 焦虑 | "必须填吗?" | "可选, 可跳过" + 路由回主页 |
| 进入主页 | 看到 4 tab + AppleHealthTile 横滚 | 安全感 | "首页空怎么办?" | 双主卡 (MoodHero + VentHero) R115+ polish, 不显示空态 |

### 阶段 2: 服务中 (Service During) — 日常使用 (核心)

```
典型一天 (Persona A 职场青年):
  早上通勤 (8:00):
    Mood tab → 记录情绪 4 维 (心情 3 / 精力 2 / 睡眠 3 / 焦虑 4)
    + 影响因素 (睡眠不足 / 工作压力) + status phrase "有点难过"
    → 保存到 mood_entries 表
    
  午休 (12:30):
    Vent tab → 写一段 50 字烦恼
    + 选标签 [工作, 焦虑]
    + 选 "私密" 模式
    → 保存到 vent_entries 表 (录音可选项, 用户可关闭)
    
  晚上睡前 (22:30):
    Trend tab → 看到本周情绪曲线 (Apple Health 风格)
    + 3 周对比 (跟上周/上月比)
    → 趋势页提供 Insight ("连续 5 天焦虑 > 4, 建议做 PHQ-9 评估")
```

| 触点 | 用户行为 | 情感 | 痛点机会 | 慢性应对 |
|---|---|---|---|---|
| Mood 记录 | 4 维评分 + 影响因素 | 释放 | "CBT 表单太复杂" | R108 后简化: 3/5/7 栏可选, 5 栏默认 |
| Vent 写烦恼 | 文字 + 录音 + 标签 | 共鸣 | "记录会丢吗?" | SQLCipher 加密 + 0 云端声明 |
| Trend 回顾 | 看曲线 | 安心 | "没有 insight 反馈" | R108 Trend 计算器 + 智能洞察 (待实现) |
| Worry 闭环 | 3 操作 (继续倾诉/我又烦恼/不再烦恼) | 释然 | "看不到之前的烦恼" | worry_archive + timeline (R128e 论文 3 优化) |
| Assessment | 10 量表自评 | 反思 | "题目太多" | 渐进开放 (PHQ-9/GAD-7 admin-only) |
| Crisis hotline | 一键拨打 (tel: scheme) | 安全 | "找不到号码" | 5 地区 + 国际 + iOS healthcare-fitness category |
| Tips 心理技巧 | 阅读 + 实践 | 启发 | "看不到与心情的关联" | mood 关联 tip 推荐 (待实现) |

### 阶段 3: 服务后 (Service After) — 回顾 + 复测 + 治愈

```
触发场景:
  ① 用户主动进 /trend 回顾 (每周 1-2 次)
  ② 系统推送提醒 (如 30 天未填 mood, /assessment 30 天复测)
  ③ 用户进 /worry/archive 看忆往昔 (焦虑时)
  ④ 用户进 /settings 导出 / 删除全部数据 (隐私敏感时)
```

| 触点 | 用户行为 | 情感 | 痛点机会 | 慢性应对 |
|---|---|---|---|---|
| Trend 回顾 | 周报 / 月报 | 安心 | "看不到长期趋势" | R128 跨 30 天 chart 渲染 |
| Worry 忆往昔 | 浏览已闭环 | 释然 | "没有成就感" | "🎉 恭喜, 你放下了 N 个烦恼" snackbar (R108+) |
| Assessment 复测 | 30 天后建议复测 | 反思 | "忘记周期" | 复测提醒 (待实现, P1 R128e 优化) |
| 数据导出 | JSON v6 多版本 | 安全感 | "云端数据被偷了" | 0 云端 + 本地加密 + 可导出 |
| 数据删除 | 一键清空 | 控制感 | "删除不彻底" | 二次确认 + DB schemaVersion 24 全表删 |
| 法律与隐私 | 设置 → 法律页 | 信任 | "不知道数据怎么用" | 4 法律文档 + ConsentGate |

## 三、情感曲线 (Emotional Curve)

```
服务前:    好奇 (40) ──→ 信任建立 (60) ──→ 启动 (70) ──→ 完成引导 (75)
                  ↑                                       ↑
                  商店描述不明确              3 同意书弹窗阻力
                  
服务中:    日常 (70) ──→ 倾诉 (85) ──→ 记录完 (80) ──→ 回顾 (75)
                       ↑                  ↑                ↑
                  隐私顾虑          影响因素复杂        缺洞察反馈
                  
服务后:    复测 (75) ──→ 闭环 (90) ──→ 导出 (85) ──→ 删除 (95)
                    ↑          ↑         ↑              ↑
                  遗忘周期      成就感     数据安全感       控制感

注: 数字 0-100 主观情感值 (0 = 焦虑/失望, 100 = 完全信任/满意)
```

## 四、跨阶段触点 (Cross-Stage Touchpoints)

| 触点 | 跨阶段 | 当前实现 |
|---|---|---|
| `AppleHealthTile` 横滚 | 服务前 / 服务中 | ✅ R31 实现 (8 metric palette) |
| `MoodHeroCard` + `VentHeroCard` | 服务前 / 服务中 | ✅ R115+ 实现 (双主卡) |
| `PressFeedback` (按钮 scale 0.97) | 全阶段 | ✅ R0 起统一 |
| `PageScaffold` (translucent AppBar) | 全阶段 | ✅ R32 + R112 优化 |
| `LoadingSkeleton` (full-screen) | 服务前 / 服务中 | ✅ R0 起 |
| `ConsentGate` (集中器) | 服务前 | ✅ R67 实现 |
| 4 法律文档 | 服务后 | ✅ R67 + R83 + R128 |
| `Worry 3 操作闭环` | 服务中 | ✅ R128e 论文 3 优化 (本 commit) |
| Vent 标签 3 分类 | 服务中 | ✅ R128e 论文 2 优化 (本 commit) |

## 五、关键指标 (Key Metrics)

| 指标 | 定义 | 目标 |
|---|---|---|
| 引导完成率 | 进入 Step 1 → 完成 Step 4 | ≥ 85% |
| 7 日留存 | 注册后 7 日回访 | ≥ 40% |
| mood 日活 | 每日 mood entry 数 | Persona A 0.7 / Persona B 1.5 |
| vent 日活 | 每日 vent entry 数 | Persona A 0.5 / Persona B 1.0 |
| worry 闭环率 | 创建 worry → resolved | ≥ 60% |
| assessment 完成率 | 进入量表 → 提交 | ≥ 75% |
| 数据导出率 | 设置 → 导出 | (合规事件, 不强求) |

## 六、设计哲学对齐

- **Emil Kowalski**: "invisible details compound" — 不可见细节 (按钮 scale, reduce-motion 适配, tooltip)
- **Apple Health**: 8 metric 横滚 tile + iOS insetGrouped + ALL CAPS section
- **隐私优先**: 0 云端 / 0 追踪 / 0 广告 / SQLCipher + flutter_secure_storage

## 七、未来优化方向

1. **Service Blueprint** (姐妹文档): 细化前后端交互 + 触点责任
2. **Insight Loop**: Trend 页 + AI 提供建议 (5-6 月后 Apple Intelligence 窗口)
3. **CBT + 正念引导** (P1): tips 加 5-10 个步骤化呼吸/正念练习
4. **测评复测循环** (P1): Assessment 30 天建议复测
5. **AI 智能重评** (5-6 月后): 走 HealthKitFactory 同模式 (abstract + NoOp + 真接)