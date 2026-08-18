# Medical Disclaimer — 慢病管家 (ChronicCare)

> **Draft for legal & medical advisor review — 草稿待法务 + 医学顾问审**
> **Date**: 2026-08-02
> **Round**: v0.28 R85 P0-8
> **Trigger**: Apple App Store Guideline 1.4.1 (Safety - Physical Harm) / Google Play Health App Policy
> **Locale**: en / zh-Hans / zh-Hant
> **Source of truth**: `docs/MEDICAL_DISCLAIMER.md` (本文档)
> **Distribution**:
> 1. 隐私政策 URL `https://chroniccare.app/medical-disclaimer` (R85 P0-3 注册域名后上线)
> 2. App 内设置页 "法律与隐私 → 医学免责声明" 入口
> 3. Apple App Store / Google Play Console 上架材料 (作为 review note 引用)
> 4. App 启动 onboarding 末步 "我已阅读并同意医学免责声明" 勾选项

---

## 0. 概述 (Overview)

**慢病管家 (ChronicCare)** 是一款**个人健康追踪工具**, **不提供医疗建议、诊断、治疗或临床决策支持**。

- 名称: 慢病管家 (ChronicCare)
- 类别: Health & Fitness / Medical (自我评估, 非医疗器械)
- 目标用户: 慢性病 (抑郁 / 焦虑 / 双相 / PTSD / ADHD / 高血压 / 糖尿病等) 患者及家属
- 监管状态: **非医疗器械** (Not a medical device) — **未经 FDA / NMPA / 任何国家医疗器械监管机构审批**
- 临床证据: 无独立临床研究 / 无同行评议证据 / 无医疗器械注册证

---

## 1. 核心免责声明 (zh-Hans)

### 1.1 不是医疗工具

**慢病管家是一款个人记录工具, 不提供医疗建议、诊断或治疗。**

所有用药提醒、情绪评估、PHQ-9 / GAD-7 量表、危机资源链接, **仅供参考**。这些功能不能替代专业医疗人员的面对面诊断、治疗方案、用药调整或心理危机干预。

### 1.2 不替代医生

**所有医疗决策 (包括但不限于用药调整、停药、加药、剂量调整、就诊时机、住院决策) 必须由您的主治医生、心理治疗师或其他持证医疗专业人员做出。**

App 内显示的:
- 用药提醒时间表 — **不构成医嘱**
- 服药趋势 / 依从性统计 — **仅供参考, 不是疗效评估**
- PHQ-9 / GAD-7 量表分数 — **是自评筛查工具, 不是临床诊断**
- 失联通知触发 — **是辅助功能, 不是紧急救援服务**

均不应作为您做出任何医疗决策的唯一依据。

### 1.3 危机情况处理

**如果您或您认识的人正在经历心理危机、自杀想法、严重药物不良反应或医疗紧急情况:**

**请立即拨打当地急救电话 (中国大陆 120, 香港 999, 台湾 119, 美国 911) 或前往最近医院急诊。**

慢病管家不是紧急救援服务。**失联通知功能** (v1.0 计划) 通知您的紧急联系人是辅助性的, 不能替代专业危机干预。

**心理危机热线 (24h):**

| 地区 | 热线名称 | 电话 |
|------|---------|------|
| 中国大陆 | 北京心理危机研究与干预中心 | 010-82951332 |
| 中国大陆 | 全国 24 小时心理援助热线 | 400-161-9995 |
| 中国香港 | 生命热线 (24 小时) | 2382 0000 |
| 中国台湾 | 安宁专线 (24 小时) | 1925 |
| 中国澳门 | 明爱生命热线 (24 小时) | 2826 1122 |
| 美国 | 988 Suicide & Crisis Lifeline | 988 |
| 英国 | Samaritans | 116 123 |
| 国际 | https://findahelpline.com | — |

### 1.4 数据准确性

App 内显示的所有数据 (服药记录、情绪分数、评估结果、趋势图表) 来自**用户主动输入**, 我们无法保证输入的准确性、完整性或真实性。

由于以下原因, 数据可能不准确:
- 用户忘记打卡或漏打卡
- 用户输入错误 (例如选错药物剂量)
- 系统时间错误
- 多设备时间不同步
- App 升级 / 数据迁移过程中数据丢失

App 不对基于不准确数据做出的任何医疗决策承担责任。

### 1.5 算法局限性

App 内 PHQ-9 / GAD-7 量表是**国际通用自评筛查工具**, 但:
- **不是临床诊断工具** — 仅用于自评情绪倾向
- **有文化 / 语言适用性差异** — 不同语言版本可能存在翻译偏差
- **不能识别所有心理疾病** — 例如躁狂发作、人格障碍、物质滥用等
- **不能替代专业精神科评估** — 高分建议联系精神科医生

App 内"评估历史趋势"功能基于量表分数时序比较, 是简单的数学趋势 (上升 / 下降 / 持平), 不构成临床评估。

### 1.6 儿童 / 青少年使用

**本 App 不专为 14 周岁以下儿童设计。**

- 14-18 周岁使用本 App 须取得监护人代为同意 (R83 PIPL §14 单独同意书已要求)
- 监护人应监督未成年人使用, 定期查看其情绪日记 / 评估记录
- 监护人发现未成年人有自伤 / 自杀想法时, 应**立即联系专业心理咨询师或精神科医生**, 而非仅依赖 App 内功能

### 1.7 隐私与数据安全

本 App 数据**全部存储在用户设备本地**, 加密保存 (SQLCipher AES-256 + flutter_secure_storage), 不上传任何服务器。

但请注意:
- 设备遗失 / 损坏可能导致数据丢失, **请定期导出 JSON 备份**
- App 不承诺数据永久可访问性
- 树洞等高敏感数据, 加密密钥绑定设备, 设备 root / 越狱后理论上存在风险

详细见隐私政策 https://chroniccare.app/privacy

### 1.8 责任限制 (Liability Limitation)

在适用法律允许的最大范围内:
- App 开发者**不对因使用本 App 导致的任何直接或间接医疗后果承担责任**
- 包括但不限于: 漏服药物、错误剂量、延误就诊、未识别心理危机、数据丢失等
- 用户使用本 App 视为**已阅读、理解并同意**本免责声明

---

## 2. Medical Disclaimer (en)

### 2.1 Not a Medical Device

**ChronicCare is a personal health tracking tool. It does NOT provide medical advice, diagnosis, treatment, or clinical decision support.**

All medication reminders, mood assessments, PHQ-9 / GAD-7 scales, and crisis resource links are for **reference only**. These features do not replace face-to-face diagnosis, treatment plans, medication adjustments, or psychological crisis intervention by qualified healthcare professionals.

### 2.2 Not a Substitute for Your Doctor

**All medical decisions (including but not limited to medication changes, dosing adjustments, hospital visits, treatment plans) must be made by your primary care physician, psychiatrist, psychologist, or other licensed healthcare professional.**

The following displayed in the App:
- Medication reminder schedules — **NOT medical advice**
- Medication adherence statistics — **reference only, NOT efficacy assessment**
- PHQ-9 / GAD-7 scale scores — **self-report screening tool, NOT clinical diagnosis**
- Lost-contact safety net triggers — **auxiliary function, NOT emergency response**

None of these should be used as the sole basis for any medical decision.

### 2.3 Crisis Situations

**If you or someone you know is experiencing a mental health crisis, suicidal thoughts, severe medication side effects, or a medical emergency:**

**Call your local emergency number immediately (US 911, UK 999, EU 112, China 120) or go to the nearest hospital emergency room.**

ChronicCare is NOT an emergency response service. The **lost-contact safety net feature** (planned for v1.0) that notifies your emergency contacts is auxiliary and cannot replace professional crisis intervention.

**Crisis Hotlines (24h):**

| Region | Hotline | Phone |
|--------|---------|-------|
| United States | 988 Suicide & Crisis Lifeline | 988 |
| United Kingdom | Samaritans | 116 123 |
| International | https://findahelpline.com | — |

### 2.4 Data Accuracy

All data displayed in the App (medication logs, mood scores, assessment results, trend charts) is **entered by the user**. We cannot guarantee the accuracy, completeness, or truthfulness of user input.

Data may be inaccurate due to:
- Forgotten or missed check-ins
- User input errors (e.g., wrong dosage)
- System time errors
- Multi-device time sync issues
- Data loss during app updates / migrations

We are not responsible for medical decisions based on inaccurate data.

### 2.5 Algorithmic Limitations

The PHQ-9 / GAD-7 scales in the App are **internationally validated self-report screening tools**, but:
- **NOT clinical diagnostic tools** — used for self-assessment of emotional tendencies only
- **Have cultural / language validity differences** — different language versions may have translation biases
- **Cannot identify all mental health conditions** — e.g., manic episodes, personality disorders, substance use disorders
- **Cannot replace professional psychiatric evaluation** — high scores warrant contacting a psychiatrist

The "assessment history trends" feature compares scale scores over time using simple mathematical trends (rising / falling / stable) and does NOT constitute clinical assessment.

### 2.6 Children / Adolescent Use

**This App is not designed for children under 14 years of age.**

- Users aged 14-18 must obtain guardian consent before using the App (R83 PIPL §14 separate consent)
- Guardians should monitor minors' use, regularly review their mood journals / assessment records
- If a minor expresses self-harm / suicidal thoughts, **immediately contact a professional psychologist or psychiatrist**, not solely rely on App features

### 2.7 Privacy and Data Security

App data is **stored entirely on the user's device**, encrypted with SQLCipher AES-256 + flutter_secure_storage, and NOT uploaded to any server.

However, please note:
- Device loss / damage may cause data loss — **export JSON backups regularly**
- The App does not guarantee permanent data accessibility
- For highly sensitive data (vent), encryption keys are device-bound; theoretically vulnerable if device is rooted / jailbroken

See full Privacy Policy at https://chroniccare.app/privacy

### 2.8 Limitation of Liability

To the maximum extent permitted by applicable law:
- App developers are **NOT liable for any direct or indirect medical consequences** resulting from use of the App
- Including but not limited to: missed medications, incorrect dosing, delayed medical attention, unrecognized mental health crisis, data loss, etc.
- By using the App, the user is deemed to have **read, understood, and agreed** to this disclaimer

---

## 3. Apple App Store Guideline 1.4.1 自检

App Store Guideline 1.4.1 (Safety - Physical Harm) 要求:
> "If your medical app may provide inaccurate data or information, or be used in diagnosing or treating patients, it may be subject to more rigorous review. Apps must clearly disclose data and methods used to support claimed health measurements, and if accuracy or methodology cannot be verified, we will reject the app. Apps should remind users to consult with their doctor in addition to using the app before making medical decisions."

### 3.1 自检表

| Guideline 要求 | 当前实现 | 状态 |
|---|---|---|
| 1.4.1 披露测量准确度 | 本 disclaimer §1.2 / §2.2 明确说明 "App 提醒用户咨询医生" | ✅ |
| 1.4.1 提醒用户咨询医生 | 启动时 + setup_step_consent 4 步同意 + 本 disclaimer | ✅ |
| 1.4.1 准确度方法可验证 | PHQ-9 / GAD-7 引用国际通用量表 (原始论文公开) | ✅ |
| 1.4.1 不声称诊断 / 治疗 | 用户协议 §2 / 本 disclaimer §1.1 | ✅ |
| 1.4.1 监管批准 | **无 FDA / NMPA 监管** — 本 disclaimer §0 明确 "非医疗器械" | ✅ |
| 1.4.3 处方药 | App **不涉及任何处方药名** | ✅ |

### 3.2 准备的 Apple Review Note 模板

> **App Name**: 慢病管家 (ChronicCare)
>
> **Guideline 1.4.1 Compliance Statement**:
>
> ChronicCare is a personal health tracking tool. It does NOT claim to diagnose, treat, or cure any medical condition. All PHQ-9 / GAD-7 assessments are internationally validated self-report screening tools used for self-monitoring of emotional tendencies, not clinical diagnosis. The App includes explicit medical disclaimers (https://chroniccare.app/medical-disclaimer) and crisis hotlines (5 regions, 24h).
>
> The App does not connect to any medical hardware, does not claim to measure vital signs (heart rate / blood pressure / blood glucose / blood oxygen), and does not recommend specific medications or dosages.
>
> Per the Disclaimer (https://chroniccare.app/medical-disclaimer), users are reminded to:
> 1. Consult their doctor before making any medical decision
> 2. Use the App only as a personal tracking tool
> 3. Contact local emergency services in case of crisis

### 3.3 上架前需准备的额外材料

- [ ] 注册 `chroniccare.app` 域名 (P0-3 外部)
- [ ] 上线本 disclaimer HTML 渲染版
- [ ] App 内 onboarding 末步加 "我已阅读并同意医学免责声明" 勾选
- [ ] App Store Connect 上架材料引用本 disclaimer URL
- [ ] Google Play Console Data Safety Form 引用本 disclaimer (声明 "本 App 非医疗器械, 不提供医疗建议")
- [ ] **医学顾问协议** (如可能) — 临床医生 / 精神科医生签字证明 "App 内容无医疗错误"
- [ ] **peer-reviewed study** (如可能) — PHQ-9 / GAD-7 原始论文公开引用

---

## 4. 上架前 Checklist

| # | 项 | 状态 | 负责人 |
|---|---|---|---|
| 1 | 本 disclaimer 草稿 | ✅ v0.28 R85 P0-8 | 工程 |
| 2 | 医学顾问审 | ❌ 待外聘 (1-2 周) | 用户决议 |
| 3 | 法务审 (PIPL §28 健康医疗) | ❌ P0-2 律师审 | 用户决议 |
| 4 | 注册 chroniccare.app + 上线 HTML | ❌ P0-3 外部 | 用户决议 |
| 5 | App 内 onboarding 末步勾选 | ❌ R85+ | 工程 |
| 6 | App Store Connect Review Note | ❌ R85+ (待 P0-3 URL) | 工程 |
| 7 | Google Play Data Safety Form | ❌ P0-3 跟 P0-3 同步 | 工程 |
| 8 | zh-Hant 翻译 | ❌ 律师审后 | 用户决议 |

---

## 5. 修订历史

| 版本 | 日期 | 状态 | 关键事项 |
|------|------|------|---------|
| v0.28 R85 | 2026-08-02 | 草稿 (R85 P0-8 写) | 初次草稿, 待医学顾问 + 法务审 |
| v0.28+ | 待定 | TODO (上 store 前必须由医学顾问 + 律师过审) | (1) 医学顾问签字 (2) 律师签字 (3) 注册域名 + 上线 HTML (4) 翻译成 zh-Hant |

---

**集中器**: 本 disclaimer 在 `docs/MEDICAL_DISCLAIMER.md`, 同步到:
- `assets/legal/medical_disclaimer.md` (P0-3 注册域名后转 HTML 上线)
- App 内 onboarding 末步
- App Store / Google Play 上架材料
- 隐私政策 §10 未成年人保护 + §1 健康数据 引用
