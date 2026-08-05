# Task 9 Brief — ARB key 同步 zh / en / zh_Hant

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: 51c9a0e (task 1-8 + fixes 完成)
- Task 1-8 已完成: schema + state + widget + 3 栏 + 5/7 wizard + settings + trend_calendar 集成
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture
- 守门员: `flutter analyze` 0 error
- 现有 16 守护脚本 (新增 `check_orphan_arb_keys.py` 在 R56e 加, `check_strings_hardcoded.py` / `check_zh_hant_consistency.py` 在 R57 加)
- i18n ARB 走 `flutter gen-l10n` 自动生成
- 已硬编码中文 string 全部要替换为 ARB key (Task 5/6/7/8 implementer 留了 TODO)

## 已有文件 / 上下文

- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (要加 28 个 key)
- `lib/l10n/app_localizations_*.dart` (auto-generated, 跑 `flutter gen-l10n`)
- 现有 CBT 硬编码中文 string 在以下文件 (Task 5/6/7/8 加):
  - `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart`
  - `lib/presentation/pages/mood/widgets/cbt_wizard.dart`
  - `lib/presentation/pages/mood/widgets/cbt_section_field.dart` (button label '?')
  - `lib/presentation/pages/mood/widgets/cbt_explainer_card.dart`
  - `lib/presentation/pages/mood/widgets/cbt_prompt_sheet.dart`
  - `lib/presentation/pages/mood/mood_recorder_page.dart` (SegmentedButton labels '3 栏' / '5 栏' / '7 栏')
  - `lib/presentation/pages/settings/widgets/cbt_section.dart`
  - `lib/presentation/pages/trend/trend_calendar.dart` (DayDetailCard CBT block)
  - `lib/l10n/app_localizations_zh.dart` (这个 implementer 之前发现被改过, 检查现状)

## TDD 流程

每个 step: 1) 加 ARB 28 keys (zh + en + zh_Hant) 2) `flutter gen-l10n` 3) 替换硬编码 4) `flutter analyze` 0 + `flutter test` 通过 5) 守门员脚本全绿 6) commit。

## Report 文件

详细报告写到: `.superpowers/sdd/task-9-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 9: ARB key 鍚屾? zh / en / zh_Hant

**Files:**
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh_Hant.arb`

**Interfaces:**
- 28 涓?柊 ARB key锛坰pec 鏂囨。宸插垪锛?
- [ ] **Step 1: 鍐?zh ARB 鍐呭?**

`lib/l10n/app_zh.arb` 鍦ㄦ枃浠舵湯灏惧姞锛?
```json
,
  "moodCbtLevelLabel3": "3 鏍?,
  "moodCbtLevelLabel5": "5 鏍?,
  "moodCbtLevelLabel7": "7 鏍?,
  "moodCbtBanner": "CBT 鎬濈淮璁板綍",
  "moodCbtExpandExplain": "浠€涔堟槸 CBT 鎬濈淮璁板綍锛?,
  "moodCbtSectionSituation": "鎯呭?",
  "moodCbtSectionAutomaticThought": "鑷?姩鎬濈淮",
  "moodCbtSectionEvidenceFor": "鏀?寔璇佹嵁",
  "moodCbtSectionEvidenceAgainst": "鍙嶅?璇佹嵁",
  "moodCbtSectionAlternative": "鏇夸唬鎬濈淮",
  "moodCbtSectionRerated": "閲嶆柊璇勫垎",
  "moodCbtSectionCoreBelief": "鏍稿績淇″康",
  "moodCbtSectionBehavior": "琛屼负搴斿?",
  "moodCbtExplainerBody": "CBT锛堣?鐭ヨ?涓虹枟娉曪級鎬濈淮璁板綍甯?綘璇嗗埆骞堕噸鏋勮礋闈㈣嚜鍔ㄦ€濈淮銆俓n鎸?5 鏍忔爣鍑嗭細鍏堣?褰曟儏澧冧笌鎯虫硶锛屽啀鎵捐瘉鎹?敮鎸?鍙嶅?锛屾渶鍚庡啓涓嬫洿骞宠　鐨勬浛浠ｆ兂娉曘€?,
  "moodCbtFieldHintSituation": "瑙﹀彂杩欎釜鎯虫硶鐨勪簨浠舵槸浠€涔堬紵鍙戠敓鍦ㄥ摢銆佷粈涔堟椂鍊欍€佹湁璋侊紵",
  "moodCbtFieldHintAutomaticThought": "閭ｄ竴鍒昏剳娴蜂腑闂?繃鐨勬兂娉曘€佸嵃璞℃垨淇″康鏄?粈涔堬紵",
  "moodCbtFieldHintEvidenceFor": "浠€涔堜簨鏀?寔杩欎釜鎯虫硶锛?,
  "moodCbtFieldHintEvidenceAgainst": "浠€涔堜簨涓嶆敮鎸佽繖涓?兂娉曪紵",
  "moodCbtFieldHintAlternative": "濡傛灉浣犵殑濂芥湅鍙嬮亣鍒拌繖浜嬶紝浣犱細鎬庝箞鍔漈A锛?,
  "moodCbtFieldHintCoreBelief": "杩欎釜鎯虫硶鑳屽悗鏇存繁灞傜殑淇″康鏄?粈涔堬紵锛堝? \"鎴戜笉澶熷ソ\"锛?,
  "moodCbtFieldHintBehavior": "鎺ヤ笅鏉ヤ綘鎵撶畻鎬庝箞鍋氾紵",
  "moodCbtPromptTitle": "寮曞?闂??",
  "moodCbtStepOf": "绗?{current} 姝?/ 鍏?{total} 姝?,
  "moodCbtTranscriptApply": "灏嗗綍闊宠浆鍐欏～鍏ユ?鏍?,
  "moodCbtReratedComparison": "閲嶆柊璇勫垎锛歿new}锛堝師 {old}锛?,
  "settingsCbtLevel": "鎬濈淮璁板綍妗ｄ綅",
  "settingsCbtLevelDescription": "閫夋嫨姣忔?璁板綍鎯呯华鏃朵娇鐢ㄧ殑鎬濈淮璁板綍妯℃澘",
  "settingsCbtLevel3Desc": "鍏ラ棬鐗堬紝1-2 鍒嗛挓鍙?～瀹?,
  "settingsCbtLevel5Desc": "鏍囧噯 Beck 鎬濈淮璁板綍锛屽惈璁ょ煡閲嶆瀯鍏抽敭姝ラ?",
  "settingsCbtLevel7Desc": "娣卞害鐗堬紝鍚?牳蹇冧俊蹇佃瘑鍒?拰琛屼负搴斿?",
  "moodCbtScoreReratedLabel": "閲嶆柊璇勫垎",
  "moodCbtChipBadge5": "CBT 5 鏍?,
  "moodCbtChipBadge7": "CBT 7 鏍?
```

- [ ] **Step 2: 鍐?en ARB 鍐呭?**

`lib/l10n/app_en.arb` 鍚屾牱 28 keys 缈昏瘧锛?
```json
,
  "moodCbtLevelLabel3": "3-column",
  "moodCbtLevelLabel5": "5-column",
  "moodCbtLevelLabel7": "7-column",
  "moodCbtBanner": "CBT Thought Record",
  "moodCbtExpandExplain": "What is a CBT thought record?",
  "moodCbtSectionSituation": "Situation",
  "moodCbtSectionAutomaticThought": "Automatic Thought",
  "moodCbtSectionEvidenceFor": "Evidence For",
  "moodCbtSectionEvidenceAgainst": "Evidence Against",
  "moodCbtSectionAlternative": "Alternative Thought",
  "moodCbtSectionRerated": "Re-rated",
  "moodCbtSectionCoreBelief": "Core Belief",
  "moodCbtSectionBehavior": "Behavioral Response",
  "moodCbtExplainerBody": "CBT (Cognitive Behavioral Therapy) thought records help you identify and reframe negative automatic thoughts.\nThe standard 5-column format: first record the situation and thoughts, then weigh evidence for/against, and write a more balanced alternative.",
  "moodCbtFieldHintSituation": "What event triggered this thought? Where, when, with whom?",
  "moodCbtFieldHintAutomaticThought": "What thought, image, or belief flashed through your mind?",
  "moodCbtFieldHintEvidenceFor": "What supports this thought?",
  "moodCbtFieldHintEvidenceAgainst": "What doesn't support this thought?",
  "moodCbtFieldHintAlternative": "If your best friend were in this situation, what would you tell them?",
  "moodCbtFieldHintCoreBelief": "What deeper belief lies behind this thought? (e.g. \"I'm not good enough\")",
  "moodCbtFieldHintBehavior": "What will you do next?",
  "moodCbtPromptTitle": "Guiding questions",
  "moodCbtStepOf": "Step {current} of {total}",
  "moodCbtTranscriptApply": "Apply transcript to this field",
  "moodCbtReratedComparison": "Re-rated: {new} (was {old})",
  "settingsCbtLevel": "Thought record level",
  "settingsCbtLevelDescription": "Choose the thought record template for each mood log",
  "settingsCbtLevel3Desc": "Beginner, 1-2 minutes to complete",
  "settingsCbtLevel5Desc": "Standard Beck thought record with cognitive reframing",
  "settingsCbtLevel7Desc": "Deep version with core belief and behavioral response",
  "moodCbtScoreReratedLabel": "Re-rated score",
  "moodCbtChipBadge5": "CBT 5-column",
  "moodCbtChipBadge7": "CBT 7-column"
```

- [ ] **Step 3: 鍐?zh_Hant ARB 鍐呭?**

`lib/l10n/app_zh_Hant.arb` 鍚屾牱 28 keys 绻佷綋锛堢敤 OpenCC s2tw 杞?崲 zh 鈫?zh_Hant锛夛細

```json
,
  "moodCbtLevelLabel3": "3 娆?,
  "moodCbtLevelLabel5": "5 娆?,
  "moodCbtLevelLabel7": "7 娆?,
  "moodCbtBanner": "CBT 鎬濈董瑷橀寗",
  "moodCbtExpandExplain": "浠€楹兼槸 CBT 鎬濈董瑷橀寗锛?,
  "moodCbtSectionSituation": "鎯呭?",
  "moodCbtSectionAutomaticThought": "鑷?嫊鎬濈董",
  "moodCbtSectionEvidenceFor": "鏀?寔璀夋摎",
  "moodCbtSectionEvidenceAgainst": "鍙嶅皪璀夋摎",
  "moodCbtSectionAlternative": "鏇夸唬鎬濈董",
  "moodCbtSectionRerated": "閲嶆柊瑭曞垎",
  "moodCbtSectionCoreBelief": "鏍稿績淇″康",
  "moodCbtSectionBehavior": "琛岀偤鎳夊皪",
  "moodCbtExplainerBody": "CBT锛堣獚鐭ヨ?鐐虹檪娉曪級鎬濈董瑷橀寗骞?綘璀樺垾涓﹂噸妲嬭矤闈㈣嚜鍕曟€濈董銆俓n鎸?5 娆勬?婧栵細鍏堣?閷勬儏澧冭垏鎯虫硶锛屽啀鎵捐瓑鎿氭敮鎸?鍙嶅皪锛屾渶寰屽?涓嬫洿骞宠　鐨勬浛浠ｆ兂娉曘€?,
  "moodCbtFieldHintSituation": "瑙哥櫦閫欏€嬫兂娉曠殑浜嬩欢鏄?粈楹硷紵鐧肩敓鍦ㄥ摢銆佷粈楹兼檪鍊欍€佹湁瑾帮紵",
  "moodCbtFieldHintAutomaticThought": "閭ｄ竴鍒昏叇娴蜂腑闁冮亷鐨勬兂娉曘€佸嵃璞℃垨淇″康鏄?粈楹硷紵",
  "moodCbtFieldHintEvidenceFor": "浠€楹间簨鏀?寔閫欏€嬫兂娉曪紵",
  "moodCbtFieldHintEvidenceAgainst": "浠€楹间簨涓嶆敮鎸侀€欏€嬫兂娉曪紵",
  "moodCbtFieldHintAlternative": "濡傛灉浣犵殑濂芥湅鍙嬮亣鍒伴€欎簨锛屼綘鏈冩€庨杭鍕窽A锛?,
  "moodCbtFieldHintCoreBelief": "閫欏€嬫兂娉曡儗寰屾洿娣卞堡鐨勪俊蹇垫槸浠€楹硷紵锛堝? \"鎴戜笉澶犲ソ\"锛?,
  "moodCbtFieldHintBehavior": "鎺ヤ笅渚嗕綘鎵撶畻鎬庨杭鍋氾紵",
  "moodCbtPromptTitle": "寮曞皫鍟忛?",
  "moodCbtStepOf": "绗?{current} 姝?/ 鍏?{total} 姝?,
  "moodCbtTranscriptApply": "灏囬寗闊宠綁瀵?～鍏ユ?娆?,
  "moodCbtReratedComparison": "閲嶆柊瑭曞垎锛歿new}锛堝師 {old}锛?,
  "settingsCbtLevel": "鎬濈董瑷橀寗妾斾綅",
  "settingsCbtLevelDescription": "閬告搰姣忔?瑷橀寗鎯呯窉鏅備娇鐢ㄧ殑鎬濈董瑷橀寗妯℃澘",
  "settingsCbtLevel3Desc": "鍏ラ杸鐗堬紝1-2 鍒嗛悩鍙?～瀹?,
  "settingsCbtLevel5Desc": "妯欐簴 Beck 鎬濈董瑷橀寗锛屽惈瑾嶇煡閲嶆?闂滈嵉姝ラ?",
  "settingsCbtLevel7Desc": "娣卞害鐗堬紝鍚?牳蹇冧俊蹇佃瓨鍒ュ拰琛岀偤鎳夊皪",
  "moodCbtScoreReratedLabel": "閲嶆柊瑭曞垎",
  "moodCbtChipBadge5": "CBT 5 娆?,
  "moodCbtChipBadge7": "CBT 7 娆?
```

- [ ] **Step 4: 閲嶆柊鐢熸垚 l10n 浠ｇ爜**

```bash
flutter gen-l10n
```

Expected: 0 error, 鐢熸垚鐨?`app_localizations_*.dart` 鍖呭惈 28 鏂?key銆?
- [ ] **Step 5: 璺戝畧闂ㄥ憳楠岃瘉 i18n 鍚屾?**

```bash
python scripts/check_arb_keys.py
python scripts/check_orphan_arb_keys.py
python scripts/check_zh_hant_consistency.py
```

Expected: 3 涓?剼鏈?叏缁裤€?
- [ ] **Step 6: 鎶?hardcoded 涓?枃 string 鏇挎崲涓?ARB key**

`grep -n "鎯呭?\|鑷?姩鎬濈淮\|鏇夸唬鎬濈淮" lib/presentation/pages/mood/widgets/cbt_*.dart` 鎵惧埌鎵€鏈夌敤纭?紪鐮佷腑鏂囩殑鍦版柟锛屾浛鎹?负 `AppLocalizations.of(context).moodCbtSection*`銆?
```bash
flutter analyze
```

Expected: 0 error锛堝惈 `check_strings_hardcoded.py`锛夈€?
- [ ] **Step 7: 璺戝叏閲忔祴璇?*

```bash
flutter test
```

Expected: 1187 + 28 = 1215 cases pass锛坙10n 鐢熸垚鐨勯?澶栨祴璇曪級銆?
- [ ] **Step 8: Commit**

```bash
git add lib/l10n/app_zh.arb \
        lib/l10n/app_en.arb \
        lib/l10n/app_zh_Hant.arb \
        lib/l10n/app_localizations*.dart \
        lib/presentation/pages/mood/widgets/cbt_*.dart
git commit -m 'v0.29 round 84 (i18n): 28 涓?CBT ARB key zh/en/zh_Hant 鍚屾?'
```

---


