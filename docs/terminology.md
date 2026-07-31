# 中文术语集中表 (chroniccare v0.27 round 59)

> **作者**: Mavis (root orchestrator)
> **来源**: superpowers-zh §3.1-3.2 审视发现
> **目的**: 集中"App/应用/客户端"、"i18n/国际化/本地化"等混用术语,统一团队 + 翻译规范
> **状态**: R59 修正 spec 文档化; R60+ 修正 ARB 集中器 (新加 `lib/core/l10n/terms.dart` + `appTerms` ARB section)

---

## 1. 核心原则

1. **技术词保留英文**: API / i18n / SDK / schema / endpoint / payload / token / provider / notifier
2. **业务词用中文**: 打卡 / 续方 / 失联 / 紧急联系人 / 评估 / 情绪日记 / 树洞
3. **App 名称用专名**: "慢病管家" (项目名) / "App" (英文 ARB) / "本应用" (中文 ARB) — **不混用**
4. **首次出现规范**: 技术词首次出现加英文 (例如"PHQ-9（9 项患者健康问卷）")

---

## 2. App 自身名称

| 场景 | 用法 | 例子 | 禁用 |
|---|---|---|---|
| 中文 ARB 文案 | "本应用" | "本应用不提供医疗建议" | ❌ "本 App"、"本软件"、"本客户端" |
| 中文 ARB 引导文字 | "慢病管家" | "请在设置中打开慢病管家的通知权限" | ❌ "本应用"、"本 App" |
| 中文 ARB 引用第三方 | 第三方原名 | "通过小米/华为/OPPO 的系统设置" | — |
| 英文 ARB 文案 | "the app" 或 "Chronic Care" | "This app does not provide medical advice" | ❌ "this application" |
| 英文 ARB 引用系统 | "system" | "In the system settings" | — |
| 代码注释 | 项目名 "慢病管家" + "app" | "// 慢病管家 app 通知 channel" | — |
| commit message | "App" 或 "app" | "v0.25 round 56: app_tokens 集中器化" | — |
| README / CHANGELOG | "App" (与代码风格一致) | "App v0.27 released" | — |

**修正 R59 状态**:
- ✅ spec 文档化 (本文件)
- ⏳ R60 修正: 改 14 处中文 ARB 中"App" → "本应用"或"慢病管家"
  - `app_zh.arb:50` "App 会在我失联时给他们发通知" → "慢病管家会在我失联时给他们发通知"
  - `app_zh.arb:96, 120, 256, 286, 290, 300, 808, 813, 818, 1130, 1135, 1138, 1152, 1163` 同款

---

## 3. i18n / 国际化 / 本地化 / 多语言

| 场景 | 用法 | 例子 | 禁用 |
|---|---|---|---|
| 技术上下文 (代码 / 文档 / commit) | "i18n" | "// i18n keys 同步检查" | ❌ "国际化"、"本地化" |
| 用户面向 (中文 ARB) | "多语言" 或 "翻译" | "本应用支持 3 种语言: 简体中文 / 繁体中文 / English" | ❌ "i18n"、"国际化" |
| 英文 ARB | "translation" 或 "language" | "Translation support" | ❌ "i18n" (用户不理解) |
| ARB key 名 | `xxxI18n` 后缀 | `emailBodyI18n` / `emailFooterI18n` | ✅ 现状正确 |

**现状 (R59 修正前)**:
- ARB key 名用 "I18n" 后缀 — 正确 (代码风格)
- 中文 ARB 内容未出现"i18n/国际化/本地化" — 0 命中
- 英文 ARB 内容未出现 "i18n" — 0 命中
- 修正优先级: **低** (现状已合理, 仅需 spec 文档化)

---

## 4. 评估量表 (PHQ-9 / GAD-7)

| 场景 | 用法 | 例子 | 禁用 |
|---|---|---|---|
| 首次出现 | "PHQ-9（9 项患者健康问卷）" | "请完成 PHQ-9（9 项患者健康问卷）评估" | ❌ 仅 "PHQ-9" |
| 后续出现 | "PHQ-9" | "PHQ-9 分数为 12" | ❌ "9 项患者健康问卷" |
| 代码 / 文档 | "PHQ-9" / "GAD-7" | "// PHQ-9 评估 widget" | — |
| ARB key | `phq9Xxx` / `gad7Xxx` | `phq9Item1Text` | ✅ 现状正确 |
| 严重度等级 | "无 / 轻度 / 中度 / 重度" | "您的 PHQ-9 评估结果为中度抑郁" | ❌ "normal / mild / moderate / severe" (除非英文) |

**修正优先级**: **P2 (低)** — 量表 i18n 化是 spzh v0.25 R56h P0 必修, 已修 domain/logic/assessment_scale.dart (R48) 加 `detectCrisis` 6 region 路由, 但量表题目/严重度仍硬编中文 (R51b 修正 TODO, v0.27 仍未修正)。**R60+ 修正**: `domain/logic/assessment_scale.dart` 加 `List<AssessmentItem> items` 字段, 数据从 ARB 拿。

---

## 5. 隐私 / 合规术语

| 场景 | 用法 | 例子 | 禁用 |
|---|---|---|---|
| 中文 ARB | "敏感个人信息" | "本应用处理您的健康医疗等敏感个人信息" | ❌ "敏感数据"、"私密信息" |
| 法律文档 (PIPL) | "敏感个人信息" | 见 `assets/legal/privacy_policy.md` | ✅ 现状正确 |
| 代码 / 文档 | "PII" (Personally Identifiable Information) | "pii_safe_log.dart: 屏蔽 PII" | — |
| 用户面向 | "隐私" | "隐私政策" | ❌ "机密" |

---

## 6. 医疗 / 用药术语

| 术语 | 用法 | 例子 | 备注 |
|---|---|---|---|
| 用药 | "吃药" / "服药" / "用药" | "今天吃药了吗" | 口语用"吃药", 文档用"服药" |
| 续方 | "续方" / "开药" | "续方提醒" | "续方" 是精神科标准术语 |
| 失联 | "失联" / "未打卡" / "联系不上" | "失联通知" | "失联" 是核心 feature 名 (失联通知) |
| 紧急联系人 | "紧急联系人" | "添加紧急联系人" | ❌ "联系人" / "家人" (太泛) |
| 树洞 | "树洞" / "倾诉" / "私密倾诉" | "树洞（私密倾诉）" | spzh 报告统一为"树洞" |
| 评估 | "评估" / "心理评估" / "测评" | "完成评估" | ❌ "考试" (用户产生压力) |
| 情绪日记 | "情绪日记" / "情绪" | "记录情绪" | "情绪日记" = 完整 feature 名 |
| 打卡 | "打卡" / "签到" | "今天打卡了吗" | "打卡" 是核心 feature 名 |

---

## 7. 罗马化规则 (中英混排空格)

| 规则 | 例子 | 禁用 |
|---|---|---|
| 中文 + 英文之间加半角空格 | "请完成 PHQ-9 评估" | ❌ "请完成PHQ-9评估" |
| 中文 + 数字之间加半角空格 | "已坚持 5 天" | ❌ "已坚持5天" |
| 中文 + 标点之间无空格 | "你好,世界" (逗号是中文) | ❌ "你好, 世界" |
| 数字 + 单位之间无空格 | "5 天" / "10 ms" | ❌ "5  天" |
| 全角括号包英文 | "（App）" | ❌ "(App)" |
| 全角冒号 + 英文 | "PHQ-9：分数" | ❌ "PHQ-9: 分数" |

**修正 R59 状态**:
- 修正了 3 处真实半角斜杠 (`preset_medication_templates.dart:74/119/154` 的 `SSRI / SNRI` → `SSRI ／ SNRI`)
- 修正了 fullwidth 误报 (47→45 violations, 部分有效)
- 修正 R60+ 修正剩余 35+ 处真实 violations

---

## 8. 关键决策记录 (ADR)

### ADR-059-1: 术语集中化

**决策**: 中文术语统一用"本应用" / "慢病管家" / "多语言" / "敏感个人信息" 等专名, 不混用"App / 应用 / 客户端"等。

**原因**:
- 团队 1-3 人 + 翻译合作方, 术语混乱导致 i18n 翻译不一致 (spzh §3.1-3.2 发现 4 处混用)
- App Store 审核 / 4 store 隐私 URL / PIPL 合规需要统一术语

**后果**:
- ✅ R59 修正 3 处真实半角斜杠
- ⏳ R60 修正 14 处"App" → "本应用" / "慢病管家"
- ⏳ R60 新增 `lib/core/l10n/terms.dart` 技术词集中器
- ⏳ R60 新增 ARB `appTerms` section 业务词集中器

**拒绝的备选**:
- ❌ 全部用 "App" (英文) — 中文用户不友好
- ❌ 全部用 "本应用" (中文) — 失去"专名"感
- ❌ 新加 ARB key `appTermApp / appTermApplication` — 过度工程

---

## 9. 关联文档

- `AGENTS.md` — 项目指引
- `docs/CHANGELOG.md` — 版本变更
- `docs/CHINESE_COMMIT_GUIDE.md` — 中文 commit 规范
- `docs/anti_patterns.md` (R60+ 新建) — 中国开发者 anti-pattern
- `scripts/check_fullwidth_punctuation.py` — 全角标点守护 (R59 修正误报)

---

**v0.27 round 59 修正路径**:
- ✅ spec 文档化 (本文件)
- ⏳ R60 修正: 14 处 "App" → "本应用" / "慢病管家" + 新增 `lib/core/l10n/terms.dart`
- ⏳ R60 修正: `check_zh_terms_consistency.py` 守护脚本 (spzh §5#7)
- ⏳ R60 修正: `check_chinese_anti_pattern.py` 守护脚本 (拼音 / 全角空格 / 错别字)
