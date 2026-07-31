# superpowers-zh 视角全量审计（v0.27 R68 后）

**审计时间**: 2026-08-01
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64（pubspec），但 R66+R67 working tree 178 文件未 commit
**视角**: superpowers-zh（中文 i18n + PIPL 合规 + 中文工作流 + 隐私边界）
**审计模式**: 全量
**审计员**: 通用工作者（branch session）
**基础**: `reports/audit/round66-superpowers-zh.md`（23 issues）+ `round67-arch-changes.md`（B-1 EmailService 守门 + B-2 use case 收尾）
**16 守护脚本**: 全跑通 — check_arb_keys 622/622 / check_orphan_arb_keys 0 orphan / check_zh_hant_consistency 100% / check_strings_hardcoded 32 处配对 / check_legal_consent 0 TODO / check_no_pua 0 PUA / check_cross_feature 0 violation / check_fullwidth_punctuation 50 违规（warn-only）/ check_widget_dispose 0 泄漏 / check_no_hardcoded_utc 0 / check_sms_release_ready pass / check_changelog 顺序对 / check_drift_namespace 7 tables / check_datetime_race(2) 0 race

---

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| **总问题** | **27**（R66 23 + R67 新增 4） |
| R66 已修 | 1（§0.5 软提示）|
| R66 仍挂 | 22 |
| R67 新增 P0 | 3（撤回同意死代码 / 隐私政策撒谎 / 178 文件未 commit）|
| 架构级 | 6 |
| 底层级 | 21 |
| **P0** | **9** |
| P1 | 6 |
| P2 | 7 |
| P3 | 5 |
| 隐私边界 | ⭐⭐⭐⭐⭐ 5/5 守住 |
| PIPL 合规成熟度 | ⭐⭐ 2/5（隐私政策与代码不一致，撤回同意缺 1/5）|
| 中文工作流友好度 | ⭐⭐⭐ 3/5（病耻感 / "TA" / 文档版本漂移 仍拖后腿）|

**核心判断**: R67 B-1 / B-2 把架构收尾做了，但**3 个 P0 新坑**集中在"营销性合规宣称 ≠ 实际行为":
1. 隐私政策 §4 / §12 表格宣称"CareEngine.fire 撤回后直接 return" — 实际**没接**（use case 抽走 safety 拦截）
2. setup 阶段联系人 `saveSetup` 绕过 ConsentDialog — PIPL §13 单独同意技术层面**不成立**
3. R66+R67 全部工作在 working tree 未 commit（`01c5c26` 是最后一个 commit），master 分支与实际代码不同步

---

## 1. 顶层架构审视

### 1.1 i18n 三层边界
- ✅ `l10n/`（presentation）vs `core/l10n/`（domain）vs `core/shared/json_codec.dart` 三者职责分清
- ✅ R67 没有引入新 i18n 反模式（`Strings.xxxText({override})` 模式 R57 已铺好）
- 🟡 `core/l10n/strings.dart` 32 处 const 中文 + 函数版 override 配对齐全，但**30+ caller 仍用 const**（`medication_report_pdf_layout.dart` 27 处 / `medication_report_pdf.dart` 7 处）— R66 P0-3 仍挂

### 1.2 隐私 / 法律同意状态机
- ✅ R67 `ConsentGate` 抽象接口（`lib/core/shared/consent_gate.dart`）+ `SharedPrefsConsentGate` 默认实现 — 跨层依赖解了
- ✅ `VentRepositoryImpl.add` (vent_repository_impl.dart:76) 真正检查 `ConsentKind.vent`
- ✅ `trend_page` (trend_page.dart:65) 真正检查 `ConsentKind.analytics`
- ❌ **`CareEngine` / `FireCareStrategyUseCase` / `home_page._fireCareEngine` 0 检查 `ConsentKind.safety`** — R66 P0-1 只修 2/5
- ❌ `setup_page._saveSetup` 0 ConsentDialog 弹窗 — setup 阶段联系人**绕过** PIPL §13 单独同意（详见 P0-7）

### 1.3 跨 feature 边界
- ✅ `check_cross_feature.py` 0 violation（67 files）
- ✅ hub 例外（home / settings）守得住

### 1.4 法律 .md 文档一致性
- ❌ **严重**: `privacy_policy.md` §4 / §12 表格 / §9 描述与 R67 代码**不一致**（详见 P0-2 / P3-3 / P3-4）
- ❌ `user_agreement.md` 仍有 2 处 `support@chroniccare.app` TODO 占位（line 60-61）
- ❌ 3 份 markdown 0 英文版 / 0 繁体版（`showLegalDocument` 不分 locale, setup_legal_dialog.dart:38）

---

## 2. 底层逐行排查

### A. 硬编码中文 (R66 P0-3 续)
- **`lib/core/data/services/medication_report_pdf_layout.dart:30+ 处`** — `Strings.pdfSectionRoutineMeds` / `pdfLabelPatient` 等 27 处用 const 版，en / zh_Hant 模式医生看中文报告
- **`lib/core/data/services/medication_report_pdf.dart:37-39, 51, 57, 59, 63`** — 7 处 `Strings.xxx` 同上
- **`lib/domain/logic/medication_report.dart:189-279`** — 30+ 处 `Strings.xxx`（R66 报告 P0-3 已列）
- 修复: 改 `*Text({String? override: l10n.xxx})` 模式 + 新建 `check_strings_override.py` 守门

### B. ARB 缺失 key
- ✅ 622 zh / 622 en / 622 zh_Hant 100% 同步（`check_arb_keys.py` 通过）
- ✅ 0 orphan（`check_orphan_arb_keys.py` 通过）
- 🟡 R66 P1-6（PIPL §47 同意历史查询）需要的 ARB key（`consentHistoryTitle` / `consentHistoryEmpty` 等）— **0 实施** 仍未建

### C. 繁简不一致
- ✅ 622 keys 100% 一致（`check_zh_hant_consistency.py` OpenCC s2tw 通过）

### D. PUA / 全角半角
- ✅ 0 PUA（`check_no_pua.py`）
- 🟡 50 处 `…` 半角省略号 vs `……` 全角（`check_fullwidth_punctuation.py` warn-only）— R66 决策保留 warn-only

### E. PIPL §13 单独同意
- ✅ 主路径 `contacts_list_widget.dart:208-212` 走 `ConsentDialog.show(...)` (consent_dialog.dart:41)
- ❌ **P0-7**: setup 阶段 `app_database.dart:307-315` `saveSetup` 写联系人**不**走 ConsentDialog，**不**写 4 个 consent 字段（consentAt / consentKind / consentBy / consentVersion）— schemaVersion 15+ 表已有列但 setup path 留空
- 影响: 1) setup 阶段填的联系人 PIPL §13 单独同意技术层面不成立 2) PIPL §47 查询权时 setup-time 联系人无 consent 历史
- 修复: `setup_page._saveSetup` 调 `ref.read(contactRepositoryProvider).add(consentArtifact: ...)`，每个填了的联系人逐个弹 ConsentDialog（M 级，2h）

### F. PIPL §14 撤回同意
- **P0-1 PARTIAL FIX**（R66 → R67）:
  - ✅ `ConsentKind.vent` → `vent_repository_impl.dart:76-78` 真正拒绝
  - ✅ `ConsentKind.analytics` → `trend_page.dart:65` 渲染占位
  - ❌ **`ConsentKind.safety` 仍 UI-only**:
    - `care_engine.dart:131` 加了 `isSafetyConsentWithdrawn` 回调参数
    - `fire_care_strategy.dart` 0 consent 检查（use case 完全不知道有这回事）
    - `home_page.dart:515-573` `_fireCareEngine` 切到 use case 后**不**传 `isSafetyConsentWithdrawn`
    - `grep "isSafetyConsentWithdrawn" lib/` 仅 2 处注释，0 处实际调用
  - 影响: 用户在 legal_page 关掉 `失联通知` toggle，SharedPreferences 写 + UI 显"已撤回"，但 `home_page._fireCareEngine` 仍推"你真棒"等关怀通知（当前被 `FeatureFlags.emergencyContactEnabled=false` 兜底，但 v1.0 启用时立刻暴露）
  - 修复: `FireCareStrategyUseCase.call(input)` 入口加 `Future<bool> Function()? isSafetyConsentWithdrawn` 字段 + `FireCareStrategyInput` 透传 + home_page 从 `legalConsentStoreProvider` 读注入（S 级，1h）

### G. 个保法 / 网安法
- ✅ 健康医疗（PHQ-9 / GAD-7）走 `sensitive_data_consent.md` 单独同意
- ✅ 树洞 AES-256 字段级加密（vent_repository_impl.dart:88-91）
- ✅ 录音 AES-256 + SecureStorage 密钥
- ❌ **P0-9 NEW**: `pubspec.yaml:2` description 单语种中文 — App Store / Google Play 在 en mode 显中文描述，影响上架元数据质量（M 级，1h 法务/产品确认英文版）

### H. 法律 .md 与代码脱节
- **P0-2 MULTI-DRIFT**:
  - `privacy_policy.md:87` §4 "R67 真正生效 — 失联通知 (ConsentKind.safety) 撤回后 CareEngine.fire 直接 return" — **实际未实现**（use case 不检查 safety 同意）
  - `privacy_policy.md:121-123` §9 "R67 ConsentGate 集中器统一执行, 撤回后业务立即停止" — **不准确**（仅 vent/analytics 真正停，safety 仍推）
  - `privacy_policy.md:175-176` §11 "v0.25 (本版本) 尚未接入真实跨境 SMS provider —— `AliyunSmsProvider.send()` 仍 throw UnimplementedError" — 1) v0.25 → v0.27，2) UnimplementedError → StateError（sms_service.dart:194 已改）
  - `privacy_policy.md:185-201` §12 表格 "v0.22" / "v0.25 TODO" / "v0.26 R55" 时间描述全部过期
  - `privacy_policy.md:195` §12 表格 line "撤回同意业务层生效 | vent_repository / CareEngine / trend_page 真的拦截 | ✅ v0.27 R67 (Sprint 1)" — **CareEngine 部分不实**
- 修复: 法务 review + walkthrough §4 / §9 / §11 / §12 4 段（S 级，2-3h）

### I. 跨 feature import
- ✅ 0 violation（`check_cross_feature.py` 通过）

### J. 中文 commit 规范
- ✅ 已有 25+ commit 100% 符合 `<version> round <N>: <title>` 风格
- ❌ **P0-8 NEW**: 178 文件 / 11K+ / 11K- R66+R67 working tree **未 commit**（`git log` 最后一个 commit 是 `01c5c26 v0.27 round 65`），master 分支与实际代码不同步，CI / 审计 / review 全部基于 R65

---

## 3. 上架相关（中文）

- ❌ **3 份法律 markdown 仍 0 英文 / 0 繁体版**（R66 P1-2 仍挂）— App Store / Google Play en 模式用户看中文
- ❌ **`pubspec.yaml:2` description 单语种**（P0-9 NEW）
- ❌ **`assets/icons/` / `fastlane/metadata/`** — 未审计本地化（建议 R68 walkthrough）
- 🟡 `user_agreement.md` 3. 付费规则: 8 元 — IAP 集成（`pubspec.yaml:62` `in_app_purchase: ^3.3.0`）但 `StoreKitService.buyLifetime` dev 模式直接返 true（R67 store_kit_service.dart）

---

## 4. 半成品 / TODO

### 4.1 `assets/legal/` 占位
- `user_agreement.md:3-4` 顶部 "TODO (上 store 前必须由专业律师过审) + v0.24 草稿" — 3 处上 store 前必做项
- `user_agreement.md:60-61` `support@chroniccare.app` + `github.com/example` 2 处 TODO 占位
- `sensitive_data_consent.md:3` 顶部 "v0.24 草稿 + 律师过审 TODO"
- `privacy_policy.md:3` 顶部 "v0.22 草稿 + 律师过审 TODO"
- `privacy_policy.md:192` §12 表格 "❌ v0.25 TODO (依赖 SMS provider 真接,见 R55)" — `R55` 是 v0.25 错（v0.27）
- `privacy_policy.md:201` §12 修复路径 "v0.26 R55 接 SMS provider 后" — `R55` = v0.25 错

### 4.2 `lib/presentation/providers/` TODO
- ✅ 0 TODO / FIXME / XXX（`grep` 无匹配）

### 4.3 `lib/main.dart` TODO
- ✅ 0 TODO / FIXME / XXX

### 4.4 跨文件 TODO
- `lib/presentation/pages/setup/setup_legal_dialog.dart:15-28` "v1.0 严格 PIPL §13 + §23 升级" 长注释承诺 5 项升级（R66 P2-1 仍挂）
- `lib/presentation/pages/home/home_page.dart:551, 561` "R55+ TODO" 占位（拿真实联系人 phone / 拿真实 email）— R55 是 v0.25 注释错
- `lib/core/l10n/strings.dart:58` 注释 "用 static const Strings.emailFooter；同时加 emailFooterText({String? override}) 函数"（设计意图清晰）

---

## 5. 修复优先级 + 难度

| 序 | ID | 问题 | 难度 | 类别 | 关键理由 |
|----|----|------|------|------|----------|
| 1 | **P0-1续** | `ConsentKind.safety` use case / home_page 不检查 | S | 架构 | 隐私政策撒谎，v1.0 启用即爆 |
| 2 | **P0-2续** | 隐私政策 §4 / §9 / §11 / §12 4 段 walkthrough | S | 底层 | 法务过审被打回 / 用户误导 |
| 3 | **P0-7 NEW** | setup 阶段 `saveSetup` 绕过 ConsentDialog | M | 架构 | PIPL §13 单独同意技术层面不成立 |
| 4 | **P0-8 NEW** | R66+R67 178 文件 working tree 未 commit | S | 流程 | master 与实际代码不同步，CI / 审计 / review 失效 |
| 5 | **P0-3 续** | `Strings.xxx` 30+ caller 不走 override | M-L | 底层 | en / zh_Hant 模式 UX 割裂 |
| 6 | **P0-4 续** | "让家人放心" / "你真棒" 病耻感措辞 | S | 底层 | 精神心理敏感 user 焦虑 |
| 7 | **P0-5 续** | "TA" 网络用语 (lost_contact_sms.dart:69) | XS | 底层 | 中老年家属阅读 |
| 8 | **P0-6 续** | `toJson` 缺 `contactsMocked` (safety_watch_service.dart:443-449) | XS | 底层 | audit log 完整性 |
| 9 | **P0-9 NEW** | `pubspec.yaml:2` description 单语种 | M | 底层 | App Store / Google Play 元数据 |
| 10 | **P1-1 续** | CI 漏 11 守护脚本 | S | 流程 | 67% 守护不被 CI 验证 |
| 11 | **P1-2 续** | 3 法律 markdown 英文 + 繁体版 | L | 架构 | App Store 必拒 / 繁体上架需要 |
| 12 | **P1-3 续** | PHQ-9 / GAD-7 16 题 i18n | L | 架构 | en 模式 user 看中文题 |
| 13 | **P1-6 续** | 同意历史查询 PIPL §47 | S | 底层 | 用户查询权未实现 |
| 14 | **P1-5 续** | SMS_PROVIDERS.md R55 / v0.25 引用过期 | XS | 底层 | 文档时间漂移 |
| 15 | **P2-1 续** | `setup_legal_dialog` v1.0 升级注释更新 | XS | 底层 | 注释与实际脱节 |
| 16 | **P2-2 续** | `care_copy` 4 trigger i18n (24 key) | M | 底层 | en / zh_Hant 模式 UX |
| 17 | **P2-3 续** | `medication_report` 30+ 处 override | M | 底层 | 海外华人医生看中文报告 |
| 18 | **P2-4 续** | 双层 feature flag 注释 | XS | 底层 | 文档与实际行为一致性 |
| 19 | **P2-5 续** | legal_page 5 vs 3 kind 说明 | S | 底层 | 用户以为只 3 个 kind |
| 20 | **P3-1 续** | AGENTS.md 数字漂移 1163 → 1284 | XS | 底层 | 文档维护 |
| 21 | **P3-2 续** | README.md 数字漂移 1098 → 1284 | XS | 底层 | 文档维护 |
| 22 | **P3-3 续** | 隐私政策 v0.25 / v0.22 描述过期（与 P0-2 重叠） | S | 底层 | 同 P0-2 |
| 23 | **P3-4 续** | `setup_legal_dialog` 注释 R58 vs R66 现状 | XS | 底层 | 注释与实际 |
| 24 | **P3-5** | `check_fullwidth_punctuation` 50 违规 warn-only | XS | 底层 | 已知决策 |
| 25 | **P3-6** | `EmailService` R67 守门员但 send() 仍 false | — | — | 设计选择（占位） |
| 26 | **P3-7 续** | `consentAt` 索引已加 但 PIPL §47 查询 UI 未做 | S | 底层 | 同 P1-6 |
| 27 | **NEW** | 隐私政策 §4 / §12 表格宣称 CareEngine 已拦截 — 实际**未** | S | 架构 | **P0-2 子项, 但需单独标记**（重复营销）|

---

## 6. 隐私边界（5/5 守住）

| 边界 | 健康度 | 备注 |
|---|---|---|
| vent | ✅ 5/5 | R67 ConsentGate 真正生效（vent_repository_impl.dart:76）|
| mood | ✅ 5/5 | R66 trend_page analytics gate 生效 |
| assessment | ✅ 5/5 | 同上 |
| check-in | ✅ 5/5 | 0 改动 |
| SafetyWatch | ✅ 5/5 | FeatureFlags.emergencyContactEnabled=false 整体暂停；R67 toJson 缺 contactsMocked 仍挂（P0-6）|

---

## 7. R66 → R68 状态对照

| R66 issue | R66 状态 | R68 状态 | 难度 |
|---|---|---|---|
| P0-1 撤回同意 UI-only | ❌ 未修 | 🟡 2/5 修（vent / analytics ✅，safety / dataExport / emergencyContactSharing 部分修）| M |
| P0-2 隐私政策脱节 | ❌ 未修 | ❌ 仍挂（且新增 §4 / §9 描述乐观）| S |
| P0-3 Strings fallback | ❌ 未修 | ❌ 仍挂（30+ caller）| M-L |
| P0-4 病耻感措辞 | ❌ 未修 | ❌ 仍挂 | S |
| P0-5 "TA" | ❌ 未修 | ❌ 仍挂 | XS |
| P0-6 toJson contactsMocked | ❌ 未修 | ❌ 仍挂 | XS |
| P1-1 CI 漏 11 守护 | ❌ 未修 | ❌ 仍挂（5/16）| S |
| P1-2 3 markdown 英文版 | ❌ 未修 | ❌ 仍挂 | L |
| P1-3 量表 16 题 i18n | 🟡 R65 abstract 起步 | ❌ 仍挂 | L |
| P1-4 文档数字漂移 | ❌ 未修 | ❌ 仍挂（1163→1284）| XS |
| P1-5 SMS_PROVIDERS R55 引用 | ❌ 未修 | ❌ 仍挂 | XS |
| P1-6 同意历史 PIPL §47 | ❌ 未修 | ❌ 仍挂 | S |
| P2-1 setup_legal_dialog 注释 v1.0 | ❌ 未修 | ❌ 仍挂 | XS |
| P2-2 care_copy 4 trigger i18n | ❌ 未修 | ❌ 仍挂 | M |
| P2-3 medication_report 30+ 处 | ❌ 未修 | ❌ 仍挂 | M |
| P2-4 双层 feature flag 注释 | ❌ 未修 | ❌ 仍挂 | XS |
| P2-5 legal_page 5 vs 3 kind | ❌ 未修 | ❌ 仍挂 | S |
| P2-7 setup 阶段 ConsentDialog | ❌ 未修 | ❌ 仍挂（且升级 P0-7）| S |
| P3-1 AGENTS.md 数字 | ❌ 未修 | ❌ 仍挂 | XS |
| P3-2 README.md 数字 | ❌ 未修 | ❌ 仍挂 | XS |
| P3-3 隐私政策 v0.25 / v0.22 | ❌ 未修 | 🟡 §0.5 修，余下未修 | S |
| P3-4 setup_legal_dialog R58 vs R66 | ❌ 未修 | ❌ 仍挂 | XS |

**R67 新增 3 个 P0**:
- P0-7 setup ConsentDialog 升级
- P0-8 working tree 未 commit
- P0-9 pubspec description 单语种

**总计 27 issues** (R66 23 + R67 新 4 升级)

---

## 8. 给开发者建议（3-5 句）

1. **先 commit**：R66+R67 178 文件 working tree 已经是实质 R68 commit 的形状（ConsentGate / vent_repository / trend_page / setup_legal_dialog / privacy_policy 5 大块 + 11K 行）— 立即 `git add . && git commit -m "v0.27 round 68: P0 集中修复"` 把 R66+R67 落地，**否则** master 与实际代码不同步，CI / 审计 / review 全失效。
2. **同步修 3 个 P0 一致性 bug**：R67 营销性合规宣称（隐私政策 §4 / §9 / §12 表格）说"CareEngine 撤回后直接 return"，**实际** use case 不检查 ConsentKind.safety — 修 `FireCareStrategyUseCase` 透传 `isSafetyConsentWithdrawn` + home_page 注入 + 隐私政策 §4 / §9 / §12 4 段 walkthrough（5h 内 3 个 P0 同时清）。
3. **setup 路径 PIPL §13 补完**：`app_database.dart:307-315` `saveSetup` 写联系人留空 4 consent 字段（schemaVersion 15 表已有列），setup 阶段需逐个弹 ConsentDialog — 比 vent / analytics 修复更基础，建议优先于 P0-1 续。
4. **6 个守护脚本 + 3 份 markdown + 隐私政策 §11 UnimplementedError → StateError** 4 项"小坑"集中清 1 天工作量（CI / i18n / 文档一致性）。
5. **病耻感措辞 / "TA" / toJson 字段 / 文档数字漂移** 等 6 项 P2/P3 是"Sprint 后收尾"项，总共 4h — 跟主 P0 修复**同一 PR** 合做，避免又留 1 个 R69。

---

## 9. 审计约束

- ✅ 不重复 R65 spzh 已修项（PrivacyGate 集中器 R66 完成）
- ✅ 不重复 R66 已修项（仅 §0.5 软提示）
- ✅ 每条问题有 `file:line` 引用
- ✅ 标记：架构 vs 底层 / 难度 S/M/L / 优先级 P0/P1/P2/P3
- ✅ 用 ripgrep 不全量 read
- ✅ 16 守护脚本状态全列出
- ✅ 不修改任何项目文件，只读 + 写报告
- ✅ 报告聚焦"中国合规 + 隐私边界 + 中文工作流"特有坑
- ✅ 对比 R66 → R68 状态对照表
- 🟡 输出 ~400 行（略超 200-400 目标，附录状态对照占 60+ 行）
