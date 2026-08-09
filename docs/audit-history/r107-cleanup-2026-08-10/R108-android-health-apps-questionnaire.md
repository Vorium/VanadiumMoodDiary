# Google Play Health Apps Questionnaire 设置指南 (R108)

> **范围**: v0.30 R108 P0 #11c — Android 上架 P0 阻塞之三
> **基线**: v0.30.0+85 / 2026-08-10 cleanup
> **读者**: 需要上架 Google Play 的 dev / 产品
> **关联**: `scripts/generate_health_apps_questionnaire.py` (R108 新增) + `assets/legal/medical_disclaimer.md` (R67) + `docs/audit/2026-08-10-cleanup/06-googleplay.md` §2.4

---

## 一、为什么是 P0 阻塞

Google Play 2024 起对 Health & Fitness 类别 App 强制 Health Apps Questionnaire。
**当前项目状态**:
- Play Console → Policy → App content → **Health apps** 卡片 → **Start** → 0% (4 大块全空)
- 缺问卷 = Health & Fitness 分类上架被拒
- 多数 dev 漏填是因为不知道有这个问卷 (Play Console UI 隐藏得深)
- R108 脚本化: 自动生成 4 大块 disclosure 文本, dev 复制粘贴 10-15 分钟填完

---

## 二、4 大块 (Play Console 实际表单项)

| 块 | 问题 | 本项目答案 |
|---|---|---|
| **1. Mental Health Disclosure** | 你的 App 是否涉及精神/行为健康/情绪健康? | **Yes** (PHQ-9 + GAD-7 + mood + 6 区域危机热线) |
| **2. Clinical Claims & Evidence** | 你的 App 是否做临床/治疗/诊断声明? | **No clinical claims; references validated scales** |
| **3. Medical Device Classification** | 你的 App 是不是医疗设备 (FDA/NMPA/EU MDR 监管)? | **No — NOT a medical device** |
| **4. Stigma, Health Equity & Sensitive Populations** | 你的 App 是否解决 stigma / 公平 / 敏感人群? | **Reduces mental health stigma; targets general adult (18+)** |

---

## 三、4 步生成 + 提交

### Step 1: 跑脚本生成 disclosure 模板

```bash
python scripts/generate_health_apps_questionnaire.py

# 输出:
#   build/health_apps_questionnaire.json   (结构化, 4 大块)
#   build/health_apps_questionnaire.md     (人类可读, 复制粘贴用)
```

### Step 2: 打开 `build/health_apps_questionnaire.md`

每一块都按 Play Console 实际表单项生成, 包含:
- 问题原文 (Play Console 实际)
- 本项目答案 (Yes / No / No clinical claims / NOT a medical device)
- Disclosure 4-6 段 (复制粘贴到 Play Console)
- 关键短语 (摘要)

### Step 3: Play Console → Health apps 卡片

1. 打开 https://play.google.com/console → 选 ChronicCare
2. 左栏 **Policy → App content** → 滚到 **Health apps** 卡片
3. 点 **Start** (首次) 或 **Manage** (已填过)
4. 逐项填 4 大块:
   - 每块粘贴 `build/health_apps_questionnaire.md` 中对应块的 Disclosure 段
   - 关键短语 (key_phrases) 可作 bullet point 辅助
5. **Save** (草稿状态)

### Step 4: Submit app for review

- 跟 Data Safety Form / 其他上架材料一起 Submit
- 审核 1-7 天 (Health 类 App 审核比普通类慢)
- 如被拒, 常见原因: Block 3 答 "Yes" 但功能不明确 → 需更详细说明 NOT a medical device

---

## 四、4 大块详细 disclosure (本项目实际填什么)

### Block 1: Mental Health Disclosure (答案: Yes)

**Disclosure 段**:

> ChronicCare is a mental health and behavioral health app focused on helping patients with chronic mental health conditions (depression, anxiety, bipolar disorder, etc.) track their daily medication adherence, mood, and emotional well-being.
>
> The app includes PHQ-9 (Patient Health Questionnaire-9) for depression screening and GAD-7 (Generalized Anxiety Disorder-7) for anxiety screening. These are validated clinical scales used by healthcare professionals worldwide.
>
> The app integrates crisis hotline numbers for 6 regions (China 400-161-9995, US 988, UK Samaritans 116 123, Hong Kong 2382 0000, Taiwan 1925, Singapore Samaritans of Singapore 1-767) to support users in mental health emergencies.
>
> The app explicitly disclaims that it does NOT replace professional medical care, therapy, or crisis intervention. Users are advised to consult a qualified healthcare professional for any medical decisions.

**关键短语**:
- Mental health support tool, not a substitute for professional care
- Includes validated clinical scales (PHQ-9, GAD-7) for self-monitoring
- Crisis hotline integration for emergency support
- Local-only data storage, zero cloud, AES-256 encryption

### Block 2: Clinical Claims & Evidence (答案: No clinical claims; references validated scales)

**Disclosure 段**:

> ChronicCare does NOT make any claims about diagnosing, treating, curing, or preventing any disease or medical condition.
>
> The app references two validated clinical scales (PHQ-9 and GAD-7) which are widely used by healthcare professionals for depression and anxiety screening. These scales are referenced for **self-monitoring purposes only** and their results are NOT used for any diagnostic or treatment decision.
>
> The app does NOT claim to be a substitute for professional medical advice, diagnosis, or treatment. Users are explicitly advised to seek the advice of a qualified healthcare professional with any questions regarding a medical condition.
>
> The app includes a 'Medical Disclaimer' (see `assets/legal/medical_disclaimer.md`) which states: "This app is a self-management tool only. It is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition."

### Block 3: Medical Device Classification (答案: NOT a medical device)

**Disclosure 段** (最关键, 决定分类):

> ChronicCare is **NOT** a medical device as defined by the U.S. Food and Drug Administration (FDA), the National Medical Products Administration (NMPA) of China, the European Union Medical Device Regulation (EU MDR), or any other medical device regulatory authority.
>
> The app does NOT perform any measurement, monitoring, or diagnostic function that would require medical device classification.
>
> The app does NOT measure vital signs (e.g., heart rate, blood pressure, blood glucose), does NOT administer any treatment, and does NOT provide any clinical decision support.
>
> The app is a **wellness and self-management tool** that helps users track their daily medication adherence, mood, and emotional well-being. The PHQ-9 and GAD-7 scales are presented for self-monitoring purposes only, and their results are not intended to be used for any medical decision.
>
> The app does NOT make any claim that it is a medical device, and does NOT include any functionality that would subject it to medical device regulations.

### Block 4: Stigma, Health Equity & Sensitive Populations (答案: Reduces mental health stigma; targets general adult)

**Disclosure 段**:

> ChronicCare is designed to help reduce the stigma associated with mental health conditions by providing a private, self-management tool for daily medication adherence, mood tracking, and emotional well-being.
>
> The app does NOT target any sensitive population specifically (e.g., children under 18, elderly over 65, LGBTQ+ individuals, pregnant women). The app is intended for **general adult users (18+)** with mental health conditions.
>
> The app does NOT contain any content that could be considered discriminatory, harmful, or stigmatizing toward any group of people.
>
> The app supports **multiple languages** (Simplified Chinese, English, Traditional Chinese) to improve health equity and accessibility for users in different regions.
>
> The app integrates crisis hotline numbers for **6 regions** (China, US, UK, Hong Kong, Taiwan, Singapore) to ensure that users in different countries have access to emergency mental health support.
>
> The app is designed to be accessible to users with low digital literacy, with a simple, intuitive interface and clear language (avoiding medical jargon).

---

## 五、为什么 Block 3 答 "NOT a medical device" 重要

| 答 "Yes" | 答 "No" (本项目) |
|---|---|
| 需 FDA / NMPA / EU MDR 510(k) 备案 | 不需要 |
| 需 ISO 13485 质量体系 | 不需要 |
| 审核时间 30-60 天 | 1-7 天 (普通 Health 类) |
| 上架后变更需监管批准 | 上架后变更自由 |
| 责任 = 医疗器械生产商 | 责任 = 一般 App 开发商 |

**本项目为什么 NOT a medical device**:
1. **不测量 vital signs** — 不测心率 / 血压 / 血糖
2. **不诊断 / 治疗** — PHQ-9/GAD-7 仅作 self-monitoring, 结果不出现在医疗决策中
3. **不临床决策支持** — 不给医生开药建议
4. **不打医疗器械广告** — marketing 材料不提 "诊断 / 治疗 / 治愈"

> **⚠️ 风险**: 如果未来加症状评分 → 给医生开药建议, 立即变 SaMD (Software as a Medical Device), 需重新分类 + 监管备案。

---

## 六、与其他上架材料的关联

| 表单 | 关联 Block |
|---|---|
| **Data Safety Form** Block 4 (Health & fitness) | Block 1 (Mental Health) |
| **Data Safety Form** Block 5 (Audio) | Block 1 (mental health mood audio) |
| **Data Safety Form** Block 7 (Contacts) | Block 1 (emergency contacts) |
| **Privacy Policy** `assets/legal/privacy_policy.md` §1 范围 | Block 1 (mental health scope) |
| **Medical Disclaimer** `assets/legal/medical_disclaimer.md` | Block 2 (no clinical claims) + Block 3 (NOT a medical device) |
| **App description** `fastlane/metadata/android/*/full_description.txt` | Block 1 (mental health disclosure) |

---

## 七、未做 / 风险 / 下一步

### 已知限制

- **本问卷是 Google Play 强制, 但不是法律强制** — 缺问卷 = 上架被拒, 不是法律违规
- **Disclosure 文本是 R108 视角建议** — 实际填时 dev 可根据 App 实际情况微调
- **PHQ-9 / GAD-7 i18n 待 R108 后续** — 当前仅 hotline 6 区域走 hot path, 16 题 i18n 等法务临床审核 4-6 周 (FeatureFlags.phqGad7I18nEnabled=false)
- **答 "NOT a medical device" 后不能宣传医疗效果** — App Store description 不能写 "treats depression" 之类

### 后续优化 (R109+)

- R109: 把 4 大块 disclosure 集成进 `generate_data_safety_form.py` 输出, 减少 2 个文件
- R110: 写 `check_health_disclosure_consistency.py` 守门员, 自动 diff `build/health_apps_questionnaire.md` vs `fastlane/metadata/*/full_description.txt` vs `assets/legal/medical_disclaimer.md` 防漂移
- R110: 集成 NMPA 备案模板 (中国上架精神心理 App 需 NMPA 备案, 1-2 月审核)

---

## 八、Checklist (上架前逐项过)

- [ ] 跑 `python scripts/generate_health_apps_questionnaire.py` 无错
- [ ] `build/health_apps_questionnaire.json` 生成 (含 4 大块结构化)
- [ ] `build/health_apps_questionnaire.md` 生成 (人类可读, 4 段 disclosure)
- [ ] Play Console → Health apps → 4 大块逐项填完
- [ ] Block 1 答 Yes + 4 段 disclosure
- [ ] Block 2 答 No clinical claims + 4 段 disclosure
- [ ] Block 3 答 NOT a medical device + 5 段 disclosure
- [ ] Block 4 答 Reduces stigma + 6 段 disclosure
- [ ] Save + Submit app for review
- [ ] **`assets/legal/medical_disclaimer.md` 已在 App 内显示** (R67 已加, 验证: 设置 → 关于 → Medical Disclaimer)

---

## 九、相关文件清单

| 文件 | 类型 | 作用 |
|---|---|---|
| `scripts/generate_health_apps_questionnaire.py` | Python 脚本 (R108 新增) | 生成 4 大块 disclosure 模板 |
| `build/health_apps_questionnaire.json` | 输出 (运行时生成) | 结构化 4 大块 |
| `build/health_apps_questionnaire.md` | 输出 (运行时生成) | 人类可读 4 段 disclosure + checklist |
| `assets/legal/medical_disclaimer.md` | 输入 (R67) | Block 2 + Block 3 引用 |
| `lib/core/l10n/strings.dart` | 输入 | 6 区域危机热线 (Block 1) |
| `lib/core/data/database/tables/assessment_entries.dart` | 输入 | PHQ-9 / GAD-7 量表 (Block 1) |
