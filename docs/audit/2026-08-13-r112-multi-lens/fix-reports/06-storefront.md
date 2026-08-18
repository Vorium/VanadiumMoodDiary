# Fix Report 06 — Storefront 文案 / 构建链 / console 表单生成器 (R112)

- 实现 subagent: storefront
- 完成时间: 2026-08-13
- 任务出处: `docs/audit/2026-08-13-r112-multi-lens/04-appstore.md` + `05-googleplay.md` (R112 新发现 P1/P2/P3)
- 文件所有权: fastlane/metadata/**, fastlane/Fastfile, android wrapper 三件套配置, scripts/ 3+1 个, PrivacyInfo.xcprivacy, docs/SUBMISSION_INFO.md

## 任务状态总览

| # | 任务 | 状态 | 说明 |
|---|---|---|---|
| 1 | AS-22 description 已关闭功能措辞 | **done** | en-US description.txt:1 + WHO IS THIS FOR 第 2 条改中性 |
| 2 | GP-R112-01 full_description 点名隐藏量表 | **done** | en-US:17 + zh-CN:18 改"不点名通用措辞", 中英同步 |
| 3 | AS-21 promotional_text "mental health assessments" | **done** | → "guided self-reflection check-ins" |
| 4 | AS-20 keywords 删 mental/心理 | **done** | 3 locale 各删 1 词, 保留 health/健康 |
| 5 | AS-23 Fastfile release fail-fast guard | **done** | 0 截图 → `UI.user_error!` abort; `ruby -c` Syntax OK |
| 6 | GP-R112-02 gradle wrapper 机器路径 + .gitignore | **done** | https URL 替换; 三件套放行; 磁盘三件套齐全 (jar 53KB/gradlew 5KB/bat 2.4KB, 无需报告 blocked) |
| 7 | GP-R112-07 ndkVersion pin + 脚本防假阳性 | **done** | build.gradle.kts pin 27.0.12077973; 脚本区分 pin 值 vs flutter.ndkVersion 引用 (后者 WARN) |
| 8 | GP-R112-03 Data Safety 生成器 4 处 | **done** | Audio files 数据型 + 量表通用措辞 + personal_info collected=false + 版本读 pubspec |
| 9 | GP-R112-04 Health Apps 生成器 3 处 | **done** | 版本读 pubspec + PHQ-9/GAD-7 全清 (grep 0) + 1 条 audio disclosure |
| 10 | GP-R112-05/06 + AS-17 console 表单文案 | **done** | SUBMISSION_INFO.md 新 §2.5: Exact Alarm 理由 + 麦克风声明 (中英) + 5.1.3 问卷草稿表 |
| 11 | AS-24 check_review_information_todo 加固 | **done** | docstring 对齐实现 (删 111/000-0000) + 4 文件存在性断言 + notes/demo_user 非空断言; 实测 exit 0 |
| 12 | AS-25 PrivacyInfo 删 ContactInfo | **done** | 删 dict + 注释记 "v1.0 SMS 真接时加回" (含回填模板); plutil + XML parse 双绿 |
| 13 | P3-02 notes.txt 6 regions | **done** | → "5 regions + international" |
| 14 | P2-04 release_notes.txt ×3 locale | **done** | 从 CHANGELOG 0.32.0+142 摘 1-2 句, 三语同步 |

**blocked: 0 项。**

## 具体改动明细

### 1. 商店文案 (fastlane/metadata/**)

- `ios/en-US/description.txt`:
  - 首行 "…track your mood, and **stay connected with loved ones** — all while…" → "…track your mood, and **build steady daily routines** — all while…" (与 Android full_description 首行措辞对齐)
  - WHO IS THIS FOR 第 2 条 "**Caregivers who want to gently check in on loved ones**" → "**People who prefer an offline-first, private tracking tool**" (与 Android 第 3 条对齐)
  - zh-Hans/zh-Hant description 本无此句, 未动 (任务范围外)
- `android/en-US/full_description.txt:17`: "using two widely-recognized standardized questionnaires" → "**Optional guided self-reflection scales** to help you notice patterns…"
- `android/zh-CN/full_description.txt:18`: "内置两种广泛使用的标准化心理量表" → "内置**多种**标准化**自我评估**量表"
- `ios/en-US/promotional_text.txt`: "mental health assessments" → "guided self-reflection check-ins"
- `ios/{en-US,zh-Hans,zh-Hant}/keywords.txt`: 删 "mental"/"心理", 保留 "health"/"健康" (en: 7→6 词; zh 7→6 词)
- `ios/{en-US,zh-Hans,zh-Hant}/release_notes.txt`: 新建 (0.32.0+142 要点摘录, 三语)
- `ios/review_information/notes.txt:6`: "Crisis Hotlines (6 regions)" → "(5 regions + international)"

### 2. Fastfile (AS-23)

`lane :release` 顶部加 fail-fast guard (build 之前):

```ruby
screenshots = Dir.glob(File.join('fastlane', 'metadata', 'ios', '*', 'screenshots', '*'))
if screenshots.empty?
  UI.user_error!('Release aborted: no screenshots found under fastlane/metadata/ios/*/screenshots/. …')
end
```

出图后 (任一 locale screenshots 目录非空) 自动放行; `metadata` lane 不受影响。`ruby -c fastlane/Fastfile` → Syntax OK。

### 3. Android 构建链 (GP-R112-02 / GP-R112-07)

- `android/gradle/wrapper/gradle-wrapper.properties:4`: `file:///C:/Users/18449/...` → `https\://services.gradle.org/distributions/gradle-8.13-bin.zip`
- `android/.gitignore`: 删除 `gradle-wrapper.jar` / `/gradlew` / `/gradlew.bat` 3 行 (Flutter 官方模板默认入库)。`git check-ignore` 实测三件套已放行 (`??` 状态, 下次 commit 即可入库)
- `android/app/build.gradle.kts:13`: `ndkVersion = flutter.ndkVersion` → `ndkVersion = "27.0.12077973"` + 注释
- `scripts/check_16kb_alignment.py` check_gradle(): 三分支 — pin 值 (`"x.y.z"`) → OK; `flutter.ndkVersion` 引用 → WARN 提示 pin; 未声明 → WARN。消 GP-R112-07 假阳性
- 磁盘验证: `android/gradlew` (4971B) / `gradlew.bat` (2404B) / `gradle-wrapper.jar` (53636B) 均在, 无需手工生成

### 4. console 表单生成器 (GP-R112-03/04)

`scripts/generate_data_safety_form.py`:
- 新增 `parse_pubspec_version()` 读 pubspec.yaml (原 `v0\.27\.0\+\d+` 恒 unknown)
- health 段去 PHQ-9/GAD-7 点名 → "Self-assessment scale answers (guided self-reflection scales, on-device only)"; mood 子类去掉 "60 秒语音"
- 新增独立 `audio_files` 段: category "Photos and videos or audio" (Play 数据型大类), 子类 "Voice notes (树洞/情绪语音笔记, 仅本地 AES-256 加密存储)"
- `personal_info.collected` → **false**, types 空 + 注释 "emergencyContactEnabled=false 全 gate, v1.0 SMS 真接时改回"
- Markdown 渲染同步 (个人信息 ❌ + 音频段)

`scripts/generate_health_apps_questionnaire.py`:
- `app_version` 硬编码 "0.30.0+85" → `parse_pubspec_version()`
- 4 处 PHQ-9/GAD-7 点名 (block 1 disclosure/key_phrases + block 2 disclosure/key_phrases + block 3 disclosure) → 通用 "standardized self-assessment scales" 措辞; 生成物 grep PHQ-9/GAD-7 = 0
- 新增 1 条 audio disclosure (block 1 disclosure + key_phrases): "Voice notes … stored locally with AES-256 encryption … never uploaded, never shared, not used for diagnosis, advertising, or any other purpose"

实测: 两生成器跑通, JSON `app_version` = 0.32.0+142, Audio 段在位, personal_info collected=False。

### 5. 守门员加固 (AS-24)

`scripts/check_review_information_todo.py`:
- docstring 规则 1 对齐实现 (删 `111` / `000-0000` 两 pattern — 实现本无, 且 `\b111\b` 会误伤热线号)
- 新增规则 3: `first_name.txt` / `last_name.txt` / `email_address.txt` / `phone_number.txt` 4 文件存在性断言 (缺任一 = FAIL) + `notes.txt` / `demo_user.txt` 非空断言
- 实测: exit 0, 4 个有标记占位 warn-only 正常

### 6. PrivacyInfo.xcprivacy (AS-25)

- 删除 NSPrivacyCollectedDataTypeContactInfo dict (66-76 行原位置)
- 注释追加 AS-25 段: 与 R108 删 HealthAndFitness 同逻辑 (declared-but-not-used; emergencyContactEnabled=false → 无入口采集), 并附 v1.0 SMS 真接时回填的完整 dict 模板
- `plutil -lint` OK + `xml.dom.minidom` parse OK

### 7. SUBMISSION_INFO.md (§2.5 新增 "Play Console 表单文案 (R112)")

- **§2.5.1 Exact Alarm 申报**: "Core functionality: 定时服药依从性提醒" + 英文申报理由全文 (clinician 定时剂量 + 误时 = 漏服药 + `canScheduleExactAlarms()` 检查 + inexact 兜底已就绪, 被驳回可零改动降级)
- **§2.5.2 麦克风 Permissions Declaration**: 英文 statement + 中文备份 (用户主动录制 / 本地 AES-256 / 不共享不用于广告或诊断)
- **§2.5.3 App Store 5.1.3 Health Disclosure 问卷草稿**: 8 行表格 (self-assessment / not diagnosis / 非医疗器械 / 数据 100% 本地), 口径与 description 中性化 + Health Apps 生成器一致

## 验证结果

| 检查 | 结果 |
|---|---|
| `python scripts/check_review_information_todo.py` | ✅ exit 0 (4 warn = 有标记占位, 外部依赖预期) |
| `python scripts/check_16kb_alignment.py` | ✅ exit 0 (pin ndkVersion 27.0.12077973 OK; pubspec WARN 为原有噪声, 非本轮问题) |
| `python scripts/check_pii_in_title.py` | ✅ exit 0 |
| `python scripts/check_apple_health_claim.py` | ✅ exit 0 |
| `python scripts/generate_data_safety_form.py` | ✅ 跑通, 版本/Audio/量表/手机号 4 处全修 |
| `python scripts/generate_health_apps_questionnaire.py` | ✅ 跑通, PHQ-9/GAD-7 grep 0, audio disclosure 在 |
| `ruby -c fastlane/Fastfile` | ✅ Syntax OK |
| `plutil -lint ios/Runner/PrivacyInfo.xcprivacy` | ✅ OK |

## Concerns / 给整合者

1. **wrapper 三件套入库时机**: `android/gradlew` / `gradlew.bat` / `gradle-wrapper.jar` 现为 untracked (`??`), 下次 commit 请务必带上 (否则 GP-R112-02 只修了一半)。文件是 2026-07-31 磁盘原物, 非本次生成。
2. **zh-Hans/zh-Hant promotional_text** 仍含 "心理评估"/"心理評估" 词 — 审计只点名 en-US 的 "mental health assessments", 中文 "心理评估" 是功能名词 (与 App 内文案一致), 判断风险低于英文, 故未动。若整合者想更保守可下一轮改。
3. **check_16kb_alignment.py 残留 WARN**: check_pubspec 仍在 pubspec.yaml 找 ndkVersion (Flutter 惯例放 build.gradle.kts), 输出 "[WARN] ndkVersion 未显式声明" 属原有噪声; exit 0 不受影响。彻底清理需把 pubspec 段的 ndkVersion 检查删掉 (本轮未动, 保持最小 diff)。
4. **Android changelogs 目录** (`fastlane/metadata/android/*/changelogs/`) 是 R112 其他子任务的 untracked 产物, 本轮未触碰。
5. **release_notes.txt 会被 fastlane deliver 覆盖为空白** (若 App Store Connect 手填过) — 提交前请确认 ASC 侧 release notes 与本地一致。
6. **遗留 P0 不变 (外部依赖)**: 域名 ICP / 设计师资产 (iOS 截图+LaunchImage+Icon / Android 截图+feature_graphic+icon) / keystore / review_information 4 真实值。Fastfile guard 会在出图后自动放行。
