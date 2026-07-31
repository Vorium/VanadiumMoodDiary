# v1.0.0 版本 bump 决策文档（v0.27 R67）

**创建时间**: 2026-07-31
**目的**: 记录 v0.27.0+64 → v1.0.0+1 bump 的 5 个前置条件 + 决策路径
**当前**: pubspec.yaml `version: 0.27.0+64` (App Store 4.3 Spam 风险 — R66 标记)

---

## 0. 背景

R66 audit (appstore 视角) 标记 pubspec.yaml `version: 0.27.0+64` 是 App Store 4.3 Spam 风险 —
Apple 看到 0.x 版本可能认为是"未完成产品"或"重复提交"。

行业惯例: 0.x 留给"开发期", 1.0.0 是"首次公开 / 商业发布"。本项目决定:
- **M1 上 store** 用 0.27.0+64 (R67 修复后)
- **M2** Sprint 2 + 3 修完 P1 / P2 后, **决策** bump 到 1.0.0+1

**为什么不直接 bump 到 1.0.0**:
1. v0.27 仍在迭代, 失联通知 SMS / 邮件真接 (R55+) 还没落地
2. 14+ 守护脚本里有些 R57 才加的, 1.0 应该带"完整守护"标签发布
3. 3 个法务文档 (R67 修) 等法务过审才算"商业就绪"

---

## 1. bump 5 个前置条件

### ✅ P0-A: Sprint 1 上架前 P0 全修 (R67 进行中)

- A-1 ~ A-9 共 9 项 (本子智能体 A 负责)
- 子智能体 B 负责 email_service / use case 接入
- 子智能体 C 负责 `_resolveTimestamp` 公开 / widget 集中器
- **状态**: R67 进行中, 完成 = 16 守护脚本全绿 + 0 analyzer error

### ⏳ P0-B: Sprint 2 iOS / Android 守护补齐 (R68 计划)

- iOS 16KB page size 验证 (R66 标记, Flutter 3.41.9 编译参数可能未对齐)
- Android 16KB alignment (Android 15+ 强制)
- USE_EXACT_ALARM Play Console justification 100+ 字符
- Data Safety Form / Health Apps questionnaire 实际填写

### ⏳ P0-C: 法务过审 (R67 §1 / §2 / §3 法律文档)

- 隐私政策 / 用户协议 / 敏感同意书 3 文档律师 review
- 邮箱 (support / privacy) + GitHub 仓库 决策 (见 `docs/SPRINT1_LEGAL_TODO.md`)
- 见 `docs/SPRINT1_LEGAL_TODO.md` 9 项 checklist

### ⏳ P1: Sprint 3 P1 警告全清 (R66 标 12+12 项)

- A-4 IAP 8 元买断 (store_kit_service 第 103-113 行) + user_agreement §3 文字
- A-7 / A-8 BGTaskScheduler + UNUserNotificationCenter delegate (R67 已修)
- A-10 / A-11 App Privacy 4 类数据 (R67 已修 PrivacyInfo.xcprivacy)
- GooglePlay G-5 ~ G-10 6 项 P0 警告 (R67 修了 G-9 short description / G-10 description)

### ⏳ P2: 重构机会 (R66 §4 重构机会清单)

- 7 个强推荐重构 (InfoBanner / DialogActionsRow / StatCard / ChoiceChipWrap /
  SwipeDeleteBackground / _resolveTimestamp / FeatureFlags 推广)
- 5 个半推荐重构 (TrailingSpinner / LegendDot / atomic size token 补全)
- **评估**: 不是 1.0 blocker, 但能提"代码质量"维度的评分

---

## 2. 决策路径

| 阶段 | 时间 | 动作 |
|------|------|------|
| M1 提交 | 2026-08-15 (估) | 0.27.0+64 + 全部 R67 修复 + Play App Signing |
| M2 审核期 | 2-4 周 | Apple / Google 审核 (Apple 24-48h, Google 1-7 天) |
| M3 上线 | 2026-09 (估) | 0.27.0+64 在 store 上, 用户开始下载 |
| M4 Sprint 2 修 | 2026-10 | R68 P0 守护补齐 (16KB / Data Safety / USE_EXACT_ALARM) |
| M5 Sprint 3 修 | 2026-11 | R69 P1 警告全清 + P2 重构 |
| M6 v1.0 决策 | 2026-12 | **决策点**: 评估是否 bump 到 1.0.0+1 |
| M7 v1.0 发布 | 2027-01 (估) | 1.0.0+1 提交 + 大版本号上线 |

**v1.0.0 决策的硬门槛** (任何一项没满足 = 不 bump):
- [ ] 5 个前置条件 (P0-A / P0-B / P0-C / P1 / P2) 全部 ✅
- [ ] 真接阿里云 SMS (R55) — 至少真接 1 个 SMS provider
- [ ] 真接 SendGrid 邮件 (R55)
- [ ] 法务过审完
- [ ] 至少 100 个真实用户跑过 0.27.x (用 Fastlane 跑 + TestFlight 拉人)
- [ ] 14 守护脚本 0 violation (含 R66 新增的 4 个)

---

## 3. 不 bump 的风险

如果直接用 0.27.0+64 提交但后续发现 v1.0.0 才适合:
- Apple / Google 看到 0.x 版本会怀疑是"未完成产品"
- 影响上架审核 (4.3 Spam 规则)
- 用户也会觉得是"测试版", 转化率低

如果过早 bump (Sprint 1 直接 1.0.0+1):
- 等于"宣告产品就绪", 但实际还在迭代
- 用户买了发现问题 → 退款 / 1 星 → 后期难洗
- 行业影响: 项目"早期口碑"差, 后续版本难翻身

**结论**: 1.0.0 是营销事件, 不是技术事件。R67 建议"先用 0.27.0+64 提交, M6 决策点决定是否 bump"。

---

## 4. 引用

- Apple 4.3 Spam: https://developer.apple.com/app-store/review/rejections/#common-rejections
- Play Store 重复提交政策: https://support.google.com/googleplay/android-developer/answer/9888077
- 行业惯例 (0.x → 1.0): Semantic Versioning https://semver.org/
- 本项目历史: `git log --oneline --grep="version"` 看每次 bump 决策
