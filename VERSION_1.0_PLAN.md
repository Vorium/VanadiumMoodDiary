# VERSION 1.0.0 计划与现状

> **本文件重建日期**: 2026-08-18 (gdc R128e audit)
> **原始 VERSION_1.0_PLAN.md (1879L) 已随 322 份含'修'字文档 commit 删除 (b2d9744f)**
> **当前状态**: 已发 v1.0.0+147 (永久免费定版) + 1.1.0+185 (emotion-first refactor 闭环)
> **本计划记录**: v1.0.0 ~ v1.1.0 跨期关键决策 + 现状盘点

---

## 一、v1.0.0 计划 (历史)

### 1.1 R108 revisit 综合审视
**P0 跨期残留 (R32 → R108)**: 13 项必修 + 4 god class 拆 + 24 error 清
- 8 P0 引入 + 17 in-progress 残留全清
- 紧急修 4 round (b9f14bc+108 / 312d171+109 / 3ac02e7+110 / 40de204+111) 全 merge to master
- 闭环: R32 新增 33 P0 中可闭环 19 项 + R32 跨期 P1 中 5 项 (P1-3/7/8/10/13)
- 修后预估综合 8.5/10 (R32 起点 6.2 → +2.3)

### 1.2 R70-R95 god page 拆分 + 子 spec 收尾
- MoodTrendPage 653L → 4 文件 (mood_trend_calculator + _line_chart + _distribution + _cbt_chart)
- assessment / medication / daily_tracking / vent 7 sub-spec 闭环
- R101: Apple Health 视觉 audit, R128 AH-16 tintedMetricSoft 0 caller 删

### 1.3 R110 feature-first 重构
- 5 阶段路线 (FEATURE_FIRST_PLAN.md:1-268)
- 阶段 1: daily_tracking 子树隔离
- 阶段 2: 6 feature 完整迁移 (assessment / mood / vent / medication / daily_tracking / crisis)
- 阶段 3: pub workspace 骨架
- 阶段 4: notification / crisis / HealthKit 抽象
- 阶段 5: theme workspace 转公共 package

### 1.4 16KB page size 合规 (Google Play 2025-11 强制)
- drift 0.6.5+ / sqlcipher_flutter_libs 0.6.5+ (16KB aligned)
- iOS native Pods 未自动验证 (待 macOS build 实测)

### 1.5 隐私合规
- PrivacyInfo.xcprivacy 5 NSPrivacyAccessedAPITypes + 2 NSPrivacyCollectedDataTypes
- 4 法律文档 (privacy_policy / user_agreement / sensitive_data_consent / medical_disclaimer)
- PIPL §14 撤回同意通道 + §38 跨境通道

---

## 二、v1.0.0 状态 (已发 v1.0.0+147)

### 永久免费定版 (1.0.0+147, 2026-08-14)
- 删除所有 IAP 代码 / 依赖 / 文案 (Fastfile precheck_include_in_app_purchases: false)
- privacy_policy.md "永久免费定版" 段
- 客服话术 / marketing 描述 同步

### Apple Health 视觉重设 (R31, v0.31.0+107)
- 5 阶段 13 task 完成
- 11+ feature 视觉对齐 iOS 17/18 风格
- 5 token + 6 widget 集中器

### Apple Health 集成 (R128c stub)
- 0 集成, 5-6 月后真接窗口
- HealthKit stub (204L) — abstract + NoOp + factory + facade 4 段式
- 7 守门员规则 (Apple 5.1.3 used-but-not-declared + declared-but-not-used 防御)

### 11+ Feature 完整实施
- 用药管理 (medication) — Apple Health 风格 + 3 步向导 + 4 时段
- 情绪日记 (mood) — 4 维分数 + CBT 3/5/7 栏 + 影响因素 + 语音
- 树洞 (vent) — 文字 + 录音 + 标签
- 趋势 (trend) — 跨 mood/vent/daily_tracking
- 日常追踪 (daily_tracking) — 6 子模块
- 心理评估 (assessment) — 10 量表 + 2 unavailable
- 危机热线 (crisis) — 5 地区 + tel: scheme 一键拨打
- 提醒 (notification) — medication refill + 用药 + 评估
- 续方 (refill) — 续方管理
- 设置 (settings) — iOS settings grouped 风格
- 主页 (home) — 4 tab (Mood / Vent / Trend / Settings)
- 启动 (AppRoot) — translucent AppBar

---

## 三、v1.1.0 emotion-first refactor (1.1.0+115 ~ +147)

### 项目定位调整
- 慢病管理 → 情绪日记 + 树洞倾诉优先
- 删除失联通知 / 紧急联系人 / SMS / Email Service 4 外联业务
- 主页 4 tab 简化 (Mood / Vent / Trend / Settings)

### 数据库迁移
- emotion-first refactor 1.1.0 round 4b: deleteTable('contacts')
- schemaVersion 24 (当前)

### FeatureFlags 简化
- 7 → 4 flag (删 3 外联: emergencyContactEnabled / aliyunSmsEnabled / emailServiceEnabled)
- 加 1: healthKitEnabled (v1.1.0+183 R128c)

---

## 四、当前状态 (gdc R128e audit 2026-08-18)

### 上架准备度
| 维度 | 评分 | 关键阻塞 |
|---|---|---|
| 代码合规 | 9/10 | — |
| 隐私合规 | 9/10 | — |
| 元数据 / 视觉资产 | 0/10 | 5 P0 硬阻断 (iOS Screenshots / 域名 / 联系信息 / Podfile / 域名 ICP) |
| 法律文档 | 7/10 | user_agreement.md 律师过审 PENDING_LAWYER_REVIEW |
| Apple Health 集成 | 2/10 | 视觉 9/10 + 集成 0/10 (5-6 月后真接) |
| Android HealthConnect | 0/10 | 完全 0 抽象 |
| 5 厂商 push | 1/10 | 抽象 + NoOp 占位, SDK 未真接 (1-2 月后) |

### 限制
- ❌ 5 P0 上架硬阻断全部依赖外部: 域名注册 + 域名 ICP + 设计师出图 + 真人填 review_information + 律师过审
- ❌ 5-6 月后才能真接 HealthKit + 1-2 月后才能真接 5 厂商 push
- ❌ 2 个空 package (chroniccare_core/ + chroniccare_features_mood/) 待用户决断

---

## 五、决策路径

### R110 → R128 跨期
- R110 (2026-08-05): feature-first 重构启动, FEATURE_FIRST_PLAN.md 路线
- R126 (2026-08-13): 6 feature 完整迁移
- R127 stage3 (2026-08-15): pub workspace 骨架, 3 package 声明
- R128a-c (2026-08-15): notification / crisis / HealthKit 抽象
- R128d (2026-08-15): 5 token 集中器转 package
- R129 (2026-08-17): hotfix P0 修真 8 项
- R128e (2026-08-18): 7 视角 gdc audit, 66 项发现

### 当前 (1.1.0+185)
- R128e audit 修复 Wave 1 完成 (14 文件: R93 spec 矛盾 + 3 flag 触发条件 + Apple Health 7 规则 + 14 处 token + Android changelog 1.0.0 → 1.1.0)
- 待续: A4 (6 module 迁移) / A5 (mood_detail_page 265L 拆) / A6 (boot_apps 466L 续拆) / A10 (home_page_state 430L 拆)

---

## 六、局限

- ❌ 原始 1879L VERSION_1.0_PLAN (含 R0-R110 每 round 详细 plan) 已随 322 文档删除不可恢复
- ❌ R32 → R128e 共 100+ round 的逐次 plan 缺失
- ✅ 本计划是从 git log + pubspec.yaml + AGENTS.md + R-number 注释重建的关键里程碑
- ✅ 后续 commit 增量修改直接 commit (本文件不需要再重写)