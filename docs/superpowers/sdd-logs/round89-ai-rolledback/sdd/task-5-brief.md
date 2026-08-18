# Task 5 Brief — i18n 25 ARB keys + CHANGELOG R89

> Source of truth.

## Context
- Worktree: D:\Batch\chroniccare\.worktrees\feat-cbt-ai
- Task 1-4 done: AiService + DeepSeekProvider + AiSettings + CbtWizard 3 按钮 (commit 1a27c9e, 1507 pass)
- baseline 1507 pass / 0 fail (R89 Task 4 fix 后)
- Goal: 25 个 hardcoded 中文 placeholder 全换 ARB key + 3 文件 (zh/en/zh_Hant) + CHANGELOG R89 entry
- 复用 R56e 守门员 `python scripts/check_orphan_arb_keys.py` (定义但未引用 = fail) + `check_arb_keys.py` (3 语言同步)
- 复用 R85 wizard + R88 cbt_section 命名风格 (`moodCbt*` / `cbtExportPdf*`)

## Global Constraints
- Flutter 3.41.9 / Dart 3.12.2 / 4-layer architecture
- 守门员: `flutter analyze` 0, `flutter test` 全过, 16+ 守门全绿
- 跑 `flutter pub get` 触发 `flutter gen-l10n` (l10n.yaml 已配)
- 3 ARB 文件同步 (zh / en / zh_Hant),不能漏语言
- 复用 R56e `check_orphan_arb_keys.py` 验证 0 orphan
- 命名约定:
  - `ai*` 前缀 (settings + dialog + button 共用)
  - `moodCbtAi*` 前缀 (wizard 范围)
  - 跟 `moodCbtSectionAlternative` / `cbtExportPdfButton` 一致 PascalCase
- 占位符: ARB 用 `{name}` + `@key: { placeholders: { name: { type: "String" } } }` 双声明
- description 字段必填 (gen-l10n 文档生成用)

## TDD
不需要写新 test (i18n 是替换 hardcoded string + 跑守门员验证 0 orphan + 0 missing translation)。1 commit。

## Report
Write to: `.superpowers/sdd/task-5-report.md`
Reply: Status + commit SHA + 1-line summary + concerns.

---

## Task 5: i18n 25 ARB keys + CHANGELOG R89

**Files:**
- Modify: `lib/l10n/app_zh.arb` (+25 keys)
- Modify: `lib/l10n/app_en.arb` (+25 keys)
- Modify: `lib/l10n/app_zh_Hant.arb` (+25 keys)
- Modify: `lib/presentation/pages/settings/widgets/ai_section.dart` (Text 替换)
- Modify: `lib/presentation/pages/settings/widgets/ai_consent_dialog.dart` (Text 替换)
- Modify: `lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart` (Text 替换)
- Modify: `lib/presentation/pages/mood/widgets/cbt_wizard.dart` (3 button label 替换)
- Modify: `docs/CHANGELOG.md` (R89 entry)
- Test: (无新 test — i18n 由守门员 check_orphan_arb_keys + check_arb_keys 验证)

### Step 1: 加 25 ARB keys (3 文件)

**Settings / Dialog / Section (16 keys)**:

| Key | zh | en | zh_Hant |
|---|---|---|---|
| `aiSectionTitle` | AI 辅助 (CBT 思维记录) | AI Assist (CBT Thought Record) | AI 輔助 (CBT 思維記錄) |
| `aiSectionHint` | 启用后, 可在思维记录向导生成 AI 建议 (国内 DeepSeek, 数据脱敏后传输). | Once enabled, the CBT wizard can generate AI suggestions (domestic DeepSeek, data redacted before transfer). | 啟用後, 可在思維記錄向導生成 AI 建議 (國內 DeepSeek, 資料脫敏後傳輸). |
| `aiEnableToggle` | 启用 AI 辅助 | Enable AI Assist | 啟用 AI 輔助 |
| `aiApiKeyLabel` | API Key | API Key | API Key |
| `aiApiKeyHint` | 请输入 API Key | Enter API Key | 請輸入 API Key |
| `aiModelLabel` | 模型 | Model | 模型 |
| `aiModelDeepseekChat` | deepseek-chat | deepseek-chat | deepseek-chat |
| `aiTestConnection` | 测试连接 | Test Connection | 測試連接 |
| `aiTestConnectionPending` | 测试连接功能待 v0.31 接入 | Test connection feature pending v0.31 | 測試連接功能待 v0.31 接入 |
| `aiApiKeySaved` | API Key 已保存 | API Key saved | API Key 已儲存 |
| `aiSaveFailed` | 保存失败: {error} | Save failed: {error} | 儲存失敗: {error} |
| `aiEmptyApiKeyHint` | 请输入 API Key | Please enter API Key | 請輸入 API Key |
| `aiLoadSettingsFailed` | 加载 AI 设置失败: {error} | Failed to load AI settings: {error} | 載入 AI 設定失敗: {error} |
| `aiConsentTitle` | 启用 AI 辅助 (CBT) | Enable AI Assist (CBT) | 啟用 AI 輔助 (CBT) |
| `aiConsentBody` | 请阅读以下条款, 同意后方可启用: | Please review the following terms before enabling: | 請閱讀以下條款, 同意後方可啟用: |
| `aiConsentAccept` | 同意并启用 | Accept & Enable | 同意並啟用 |
| `aiConsentDecline` | 拒绝 | Decline | 拒絕 |
| `aiConsentPoint1` | 1. 数据脱敏: AI 收到的仅含情绪分数 / 标签 / CBT 档位, 不含你的笔记或自动思维原文。 | 1. Data redaction: AI receives only your mood score / tags / CBT level, not your notes or automatic thoughts. | 1. 資料脫敏: AI 收到的僅含情緒分數 / 標籤 / CBT 檔位, 不含你的筆記或自動思維原文。 |
| `aiConsentPoint2` | 2. 国内传输: 数据通过 DeepSeek API 传输 (api.deepseek.com), 不出境。 | 2. Domestic transfer: Data is sent via DeepSeek API (api.deepseek.com); it does not leave China. | 2. 國內傳輸: 資料通過 DeepSeek API 傳輸 (api.deepseek.com), 不出境。 |
| `aiConsentPoint3` | 3. 第三方处理: DeepSeek 按其隐私政策处理 (链接可在 设置 → 法律与隐私 查看)。 | 3. Third-party processing: DeepSeek processes per its privacy policy (see Settings → Legal & Privacy). | 3. 第三方處理: DeepSeek 按其隱私政策處理 (連結可在 設定 → 法律與隱私 查看)。 |
| `aiConsentPoint4` | 4. 可随时撤回: 在本节关闭开关即可, 历史 AI 建议保留在本地。 | 4. Withdraw anytime: toggle off here; past AI suggestions stay local. | 4. 可隨時撤回: 在本節關閉開關即可, 歷史 AI 建議保留在本機。 |
| `aiConsentVersion` | 同意版本: 1.0 | Consent version: 1.0 | 同意版本: 1.0 |

**Wizard / Generate button (3 keys)**:

| Key | zh | en | zh_Hant |
|---|---|---|---|
| `moodCbtAiAltThoughtButton` | AI 建议替代思维 | AI Suggest Alternative Thought | AI 建議替代思維 |
| `moodCbtAiCoreBeliefButton` | AI 提取核心信念 | AI Extract Core Belief | AI 提取核心信念 |
| `moodCbtAiBehaviorResponseButton` | AI 建议行动 | AI Suggest Action | AI 建議行動 |
| `moodCbtAiGenerating` | AI 生成中... | AI generating... | AI 生成中... |
| `moodCbtAiGenerated` | {label} 已生成 | {label} generated | {label} 已生成 |
| `moodCbtAiUnavailable` | {label} 暂不可用, 请稍后再试 | {label} unavailable, please retry | {label} 暫時無法使用, 請稍後再試 |
| `moodCbtAiFailed` | AI 生成失败: {error} | AI generation failed: {error} | AI 生成失敗: {error} |
| `moodCbtAiHelperEnable` | 请先在设置启用 AI 辅助 | Please enable AI Assist in Settings first | 請先在設定啟用 AI 輔助 |
| `moodCbtAiHelperApiKey` | 请先在设置填写 API Key | Please set API Key in Settings first | 請先在設定填寫 API Key |

合计: 22 (settings/dialog) + 9 (wizard) = 31 keys — 略多于 plan 估计 16,但覆盖所有 hardcoded strings。**实现者要确认 keys 数**,如 25 keys 全 3 文件共 75 项,工作量中等。

### Step 2: 替换 4 个文件的 hardcoded Text 引用

**`lib/presentation/pages/settings/widgets/ai_section.dart`** — 把所有 `Text('中文 placeholder')` 改成 `Text(l10n.aiXxx)`, 加 `final l10n = AppLocalizations.of(context);` 在 build() 入口。

**`lib/presentation/pages/settings/widgets/ai_consent_dialog.dart`** — 同上。

**`lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart`** — 同上 + `_errorLabel` 3 个 string 走 l10n。

**`lib/presentation/pages/mood/widgets/cbt_wizard.dart`** — 3 个 `CbtAiGenerateButton(...)` 的 `label:` 字段改 `l10n.moodCbtAiAltThoughtButton` 等。

**注意**: 任何用了 `l10n.xxx` 都需要 `final l10n = AppLocalizations.of(context);` 在 build 入口取 (widget 跟 cbt_section 同模式)。

### Step 3: 跑 pub get + 守门员

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
flutter pub get
# 触发 flutter gen-l10n 自动生成 lib/l10n/app_localizations*.dart
python scripts/check_arb_keys.py       # 3 语言同步
python scripts/check_orphan_arb_keys.py  # 0 orphan
python scripts/check_strings_hardcoded.py  # 0 hardcoded Chinese string in 4 个 widget
python scripts/check_legal_consent.py  # PIPL §13 守门
python scripts/check_no_pua.py
python scripts/check_fullwidth_punctuation.py
flutter analyze
flutter test
```

Expected: 1507+ pass (0 new test, 数字不变), 0 fail, 0 analyzer error, 16+ 守门全绿, 0 orphan key, 0 hardcoded AI string in 4 widget, 3 语言同步。

### Step 4: 写 CHANGELOG R89 entry

`docs/CHANGELOG.md` 在最新 R88 之后加:

```markdown
## [0.30.0] - 2026-08-XX

### Added (R89)

- **AI 辅助 (CBT 思维记录)**: 5 个 AI 能力 — 替代思维 / 情绪识别 / 认知扭曲 / 核心信念 / 行动建议
- **国内 LLM provider**: DeepSeek (https://api.deepseek.com/v1/chat/completions) — 数据不出境
- **隐私优先**: 全本地脱敏 (只发 score / tags / cbtLevel), apiKey 走 EncryptedSharedPreferences
- **PIPL §13 单独同意**: 首次启用弹 4 项条款 dialog (脱敏 / 国内传输 / 第三方处理 / 可撤回)
- **Fail-safe**: 1 个 prompt 失败不影响其他 4 个字段 (Future.wait + _safeCall 双层保护)
- **Wizard 集成**: 3 个 AI 按钮 (替代思维 / 核心信念 / 行动建议) — settings 启用后 wizard 显示
- **30 ARB keys (zh/en/zh_Hant)**: 覆盖 settings section / consent dialog / wizard button

### Privacy

- 客户端**完全脱敏** — 用户的 note / automaticThought / situation / 任何自由文本**永不发送**到 LLM
- 仅 metadata (score 1-5 + tags 数组 + CBT 档位 3/5/7) 发给 DeepSeek
- API key 走 Android EncryptedSharedPreferences / iOS Keychain / Windows DPAPI
- 用户可随时 toggle off, 历史 AI 建议保留在本地

### Notes

- 单 provider MVP (DeepSeek), OpenAI/Claude 留 v0.31+
- 真实"测试连接"按钮功能 v0.31 接入 (本版仅占位)
- 同意版本: 1.0 (法务审核时如需 bump, AI 重新弹 dialog)
```

### Step 5: Commit

```bash
cd D:\Batch\chroniccare\.worktrees\feat-cbt-ai
git add lib/l10n/app_zh.arb \
        lib/l10n/app_en.arb \
        lib/l10n/app_zh_Hant.arb \
        lib/l10n/app_localizations.dart \
        lib/l10n/app_localizations_zh.dart \
        lib/l10n/app_localizations_en.dart \
        lib/l10n/app_localizations_zh_Hant.dart \
        lib/presentation/pages/settings/widgets/ai_section.dart \
        lib/presentation/pages/settings/widgets/ai_consent_dialog.dart \
        lib/presentation/pages/mood/widgets/cbt_ai_generate_button.dart \
        lib/presentation/pages/mood/widgets/cbt_wizard.dart \
        docs/CHANGELOG.md
git commit -m "v0.30 round 89 (i18n): 30 ARB keys (settings/dialog/wizard) + CHANGELOG R89 + 3 lang sync"
```

---

## 已知坑 (R89 Task 5)

1. **30 keys vs plan 16 keys**: 实测 hardcoded string 数 30 个 (含 helper text / snackbar / dialog 4 条 bullet),超过 plan 估计的 16。**这是必要的覆盖**,plan 16 估计偏低。
2. **`check_strings_hardcoded.py` 守门**: R57 加的,会扫 `lib/` 找硬编码中文。本 task 必须让 4 个 AI widget 0 hardcoded。
3. **`check_orphan_arb_keys.py` 守门**: R56e 加的,定义但未引用 = fail。确认所有 30 keys 都被引用。
4. **`flutter pub get` 触发 `gen-l10n`**: l10n.yaml 已配,`flutter pub get` 自动跑,生成 app_localizations_zh.dart 等 3 个文件。**不要手动改 generated 文件**。
5. **zh_Hant 跟 zh 差异**: 简体 → 繁体的转换不能机械 (e.g. "设置" → "設定" 而非 "设訂")。**R57 守门员 `check_zh_hant_consistency.py` (OpenCC s2tw)** 自动校验。
6. **placeholder syntax**: 已有 `cbtExportPdfSuccess` 模式 (`{count}` + `@key: { placeholders: { count: { type: "int" } } }`),照搬。
7. **CHANGELOG R89 entry**: 跟 R88 entry 同格式,R88 是 "R88 (i18n): 5 ARB keys..." 本 task 是 "R89 (i18n): 30 ARB keys..."。
8. **Text widget 替换时保留 widget 树结构**: 不要换 widget 类型 (e.g. `Text(l10n.x)` 不能换成 `TextButton`)。只换 string。

## 跟其他 task 的契约

- Task 1-4 已 commit, 文字是中文 placeholder — 本 task 一次性全换
- Task 6 (final review) — 期待看到 0 hardcoded, 30 ARB keys 干净, 16 守门全绿

## 不在 scope

- ❌ 任何新 test (i18n 由守门员验证)
- ❌ 重构 widget (只换 string)
- ❌ 新增功能
- ❌ 守门员 script 改动 (R57 已有 `check_strings_hardcoded.py` + `check_orphan_arb_keys.py`)
- ❌ 修 minor ledger 里的 5 项 (M1-M5 Task 4 + 4 Task 3 + 6 Task 1) — 累 ledger,sub-spec 5 完后单独 batch
