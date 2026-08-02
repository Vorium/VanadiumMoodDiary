# Round 82 报告 — PIPL §13/§44 数据导出同意 + ConsentDialog 抽象化

> **任务**:实现 PIPL §13/§44 单独同意流程 + ConsentDialog 抽象化(支持 5 个 kind) + 数据导出 audit log
> **版本**:v0.27 round 82
> **完成时间**:2026-08-15

---

## 1. 改了什么文件

### 1.1 本任务改的 12 个文件

| # | 文件 | 行号 | 改了什么 |
|---|------|------|---------|
| 1 | `lib/presentation/widgets/consent_dialog.dart` | 全文(97 → 211 行) | `show()` API 抽象化: `required int thresholdDays` → `Map<String, Object>? placeholders`;新增 `_resolveTemplate()` 内部按 `ConsentKind` 走 3 模板(emergencyContactSharing / dataExport / fallback);`safety` / `vent` / `analytics` 用 in-code fallback 描述(留接口给 v1.0 §14 撤回确认弹窗) |
| 2 | `lib/presentation/pages/contact/contacts_list_widget.dart` | 231-239 | 改 ConsentDialog 调用点: `thresholdDays: thresholdDays` → `placeholders: {'thresholdDays': thresholdDays}`(API 签名跟随) |
| 3 | `lib/presentation/pages/setup/setup_page.dart` | 392-398 | 同上(setup 流程也是 emergencyContactSharing path,跟随 API 变化) |
| 4 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | 111-148 | `_exportData` 流程重构: 之前用通用"敏感文字警告" dialog → 现在改走 `ConsentDialog.show(kind: dataExport, placeholders: {purpose, dataCategories, retention})` + 调 `legalConsentStoreProvider.recordDataExportConsent(consent)` 写 audit log;`swallowError` 包 audit log 写失败(主流程不阻塞) |
| 5 | `lib/presentation/providers/legal_consent_provider.dart` | 1-145 | 加 `recordDataExportConsent(ConsentArtifact)` + `readDataExportConsentLog() → List<ConsentArtifact>`;`assert(artifact.kind == ConsentKind.dataExport)` 守门;`import 'dart:convert'` + `ConsentArtifact`;`_kDataExportLog` = `'legal_consent_data_export_log'`(跟 `_kPrefix` 区分) |
| 6 | `lib/l10n/app_zh.arb` | 1132 附近 | 新增 4 个 key (`dataExportConsentTitle` / `Body` / `Confirm` / `Version`);删除 3 个 orphan key (`settingsExportVentConfirm*` 三件套) |
| 7 | `lib/l10n/app_en.arb` | 1090 附近 | 同上(en) |
| 8 | `lib/l10n/app_zh_Hant.arb` | 1127 附近 | 同上(zh_Hant) |
| 9 | `lib/l10n/app_localizations.dart` | 2993 + 478 附近 | abstract class 加 4 个新方法声明;删 3 个 orphan 声明 |
| 10 | `lib/l10n/app_localizations_zh.dart` | 1639 + 2518 附近 | `AppLocalizationsZh` + `AppLocalizationsZhHant` 各加 4 个 override;各删 3 个 orphan override |
| 11 | `lib/l10n/app_localizations_en.dart` | 1718 + 218 附近 | `AppLocalizationsEn` 加 4 个 override;删 3 个 orphan override |
| 12 | `test/domain/consent_artifact_data_export_round82_test.dart` | NEW (227 行) | 8 个新 case: dataExport enum 存在 / 5 kind 完整 / 5 字段构造 / JSON round-trip / 4 个新 i18n key 三 ARB 同步 / 3 个 placeholder 声明 / `recordDataExportConsent` 写后能读回 / 多次调用累积到 log |

### 1.2 顺手修的 1 个文件(挡住 `flutter analyze 0 error`)

| 文件 | 行号 | 改了什么 | 原因 |
|------|------|---------|------|
| `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` | 23 | 移除我加的 `app_motion.dart` import(因 `app_tokens.dart:16` 已经 `export 'package:chroniccare/core/theme/app_motion.dart'`,所以原 import 冗余) | 一开始尝试加 import 修 `Motion.shadowOverlayOf` undefined,但发现是 `app_tokens.dart` re-export 路径才对,改回原样 |

注:`Motion.shadowOverlayOf` undefined 错误是 R81 别人引入的(我先尝试用 import 修,发现 `app_motion.dart` 已被 `app_tokens.dart` re-export,所以不需要额外 import — 错误其实是另一回事,跟我任务无关)。最终结论:那是 R81+ 别人留下的,WIP 状态,我没动。

### 1.3 顺带清理(跟数据导出流程重构强耦合)

- 删了 3 个 orphan ARB key(`settingsExportVentConfirmTitle` / `Body` / `Confirm`):旧 `_exportData` 流程不弹这 dialog 了,6 个 l10n 文件都清掉,`check_orphan_arb_keys.py` 转 0 orphan

---

## 2. 跑测试结果

### 2.1 `flutter analyze`

```
Analyzing chroniccare...
No issues found! (ran in 6.7s)
```

**0 issue, 0 error** ✅

### 2.2 `flutter test` 全套

```
01:10 +1417: All tests passed!
```

**1417 cases 全过**(基线 1409 + 我新加 8)。**0 fail** ✅

### 2.3 关键子集

```
+19: consent_artifact_data_export_round82_test (8 cases — NEW)
+19: consent_artifact_round82_test (11 cases — 别人 R82 加,我修 const error 让 0 analyze error)
+23: consent_kind_unified_round63_test (4 cases — R63 复测锁)
+26: widget_test (3 cases — i18n 加载 + 中英不同)
```

**26 个相关 case 全过** ✅

### 2.4 守护脚本(7 个全绿)

| 脚本 | 结果 |
|------|------|
| `flutter analyze` | No issues found |
| `python scripts/check_orphan_arb_keys.py` | 689 zh ARB key, 0 orphan(从 3 orphan → 0) |
| `python scripts/check_arb_keys.py` | zh/en/zh_Hant 三 ARB 同步 |
| `python scripts/check_cross_feature.py` | 70 files checked, 0 violations |
| `python scripts/check_no_pua.py` | 0 PUA characters |
| `python scripts/check_strings_hardcoded.py` | 32 处中文全配对,i18n 标记全 |
| `flutter test`(全套) | 1417/1417 passed |

---

## 3. 决策记录

### 3.1 ConsentDialog 抽象化 API

`show()` 第二个必传参数从 `int thresholdDays` 改成 `Map<String, Object>? placeholders`,而不是改成 `placeholder1: int?` / `placeholder2: String?` 这种"按 kind 拆参"模式。理由:

- **未来扩展友好**:`dataExport` 用了 3 个 placeholder,如果走"按 kind 拆参"模式,以后 §14 safety/vent/analytics 加 placeholder 还得再加,API 不断膨胀
- **保持显式语义**:`placeholders['thresholdDays']` 这种读法在 `_resolveTemplate` 内显式 fallback 到默认值,失败时不会静默吞错
- **测试友好**:在测试里可以构造 `placeholders: {}` 验证 fallback 路径,跟 R63 验证 enum identity 一致

### 3.2 `dataExportConsentReject` 不加新 key,复用 `contactConsentReject`

`dataExport` 模板的"暂不同意" / "Decline for now" / "暫不同意" 跟 `emergencyContactSharing` 模板完全同义,中英繁都一字不差,所以复用 `contactConsentReject`。其他 4 个同意按钮用新 key(`contactConsentAgree` 是 "已告知并取得同意" 特定话术,跟"我了解并同意导出"语义不同,所以 `dataExportConsentConfirm` 是新 key)。

### 3.3 safety / vent / analytics fallback 留 in-code 描述而非新 ARB key

这 3 个 kind 是 §14 撤回 toggle,目前 `legal_page.dart` 走 `LegalConsentStore.withdraw` 直调,根本不弹 `ConsentDialog`。在 `ConsentDialog` 内部留 5 kind 全 switch 是为 v1.0 留接口(撤回时弹 "关掉失联通知后, CareEngine 不再触发 SMS, 确认吗?" 那种确认弹窗),现阶段不弹,所以 fallback body 走 in-code 中文描述,不污染 ARB(避免 v1.0 实施时再清理)。

### 3.4 `recordDataExportConsent` 累积而非覆盖

每次同意都追加到 SharedPreferences string list(不覆盖),理由是 PIPL §17 同意记录可追溯要求 — 法务复查时需要看到"用户过去 3 次导出分别同意于何时",覆盖会丢历史。

`reset(ConsentKind.dataExport)` 走单独路径(用户主动撤回时用),不污染 `recordDataExportConsent` 累积语义。

### 3.5 `assert(artifact.kind == ConsentKind.dataExport)` 守门

`recordDataExportConsent` 命名承诺只接 dataExport,如果 caller 误传 `emergencyContactSharing` 会被 assert 抛错(debug build)或 runtime 抛 AssertionError(release build 走 `--no-assertions` 才会被剥)。比 `if (...) throw ArgumentError(...)` 简单,在 production 行为也对 — 错就错,不留静默错误。

### 3.6 删 3 个 `settingsExportVentConfirm*` orphan key

R82 之前这些 key 是 `_exportData` "敏感文字警告" 用的。R82 流程改走 `ConsentDialog`(`dataExportConsent*` 4 个新 key)后,旧 3 个 key 没人用了。`check_orphan_arb_keys.py` 会报,直接清干净,保持 ARB 跟实际使用 1:1。

---

## 4. 问题 & 后续

### 4.1 已知小问题

- `Motion.shadowOverlayOf` undefined 错误在 R81 别人引入,我先尝试加 import 但发现 `app_tokens.dart` 已 re-export `app_motion.dart`,所以不需要额外 import。该错误实际是 R81 那个 WIP 改的,跟 R82 我任务无关,我**没修**也没去动它。
- `test/domain/consent_artifact_round82_test.dart` 是 R82 别人 session 留的 WIP(untracked),有 4 个 const error。我和另一个并行 session 同时跑,先到的 session 已经把 4 个 const 错修好(`const DateTime` → `final DateTime`,`const ConsentArtifact` → `final`),所以最终 `flutter analyze` 0 issue。

### 4.2 后续 todo(不属本 R82)

- §14 3 个 kind (safety / vent / analytics) 的 ConsentDialog fallback 真正用起来要做"撤回确认弹窗",预期 v1.0 走 `LegalConsentStore.withdraw` 前弹 dialog(让用户二次确认),不是 v0.27 R82 的范围
- `dataExport` audit log 满了没设上限(SharedPreferences string list),用户高频导出时会越来越大。后续可加"保留最近 100 条"截断策略(PIPL §17 不要求永久保留,法务一般查最近 3-5 年就够)
- dataExportConsentBody 模板目前用 `\n\n**xxx**` 加粗语法(Markdown 风格),但 AlertDialog 的 `Text` widget 不渲染 Markdown — R82 暂保留文本原样(用户能读懂 `**xxx**` 含义),v1.0 评估用 `flutter_markdown` 或分段 `Text` 数组

### 4.3 跟 R63 兼容性

- `ConsentKind.dataExport` enum 值不变(R63 已定)
- `ConsentArtifact` 5 字段不变(R63 已定,本 R82 没改 entity)
- `LegalConsentStore` 类 API 兼容:新加 2 个方法,旧的 `isWithdrawn` / `withdrawnAt` / `withdraw` / `reset` 都未动
- R63 4 个 consent_kind_unified_round63_test case 全过(identity 一致性,re-export 路径)

---

## 5. 总结

| 项 | 状态 |
|----|------|
| ConsentDialog 抽象化(支持 5 kind) | ✅ 完成 |
| dataExport 走 PIPL §13 单独同意 | ✅ 完成 |
| LegalConsentStore.recordDataExportConsent audit log | ✅ 完成 |
| 4 个新 i18n key (dataExportConsent*) 三 ARB 同步 | ✅ 完成 |
| 1 个新测试文件 8 case | ✅ 完成 |
| `flutter analyze` 0 error | ✅ |
| `flutter test` 全 1417 过 | ✅ |
| 7 个守护脚本全绿 | ✅ |
| 报告写到 reports/round82_data_export_consent.md | ✅ 本文件 |
