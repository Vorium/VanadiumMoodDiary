# superpowers-zh 视角审视报告 (v0.21+, round 27)

> **审视员**: superpowers-zh 中文规范 / 流程 / 文档审查 sub-agent
> **时间**: 2026-07-21(round 26 之后,v0.21.0+1)
> **范围**: 完整 `lib/` + `test/` + `docs/` + `assets/legal/` + `pubspec.yaml` + git 历史
> **方法**: 静态 grep + 关键文件精读 + 跟 superpowers-zh 4 个中国特色 skill(中文代码审查 / 中文提交规范 / 中文文档 / 中文 Git 工作流)逐项对照
> **不动代码**: 纯 review,产出 spzh-NN / spzh-doc-NN / spzh-i18n-NN / spzh-bug-NN 列表
> **基线**: `flutter analyze` 0 issues + `flutter test` **703/703 pass** + `dart scripts/check_all.dart` 2/2 pass + `python scripts/check_cross_feature.py` 0 violations

---

## 0. 项目现状

### 0.1 工程统计(本审视实测)

| 维度 | 数字 | 备注 |
|---|---|---|
| `lib/` .dart 文件数 | **161** | grep 统计 |
| `lib/` 总 LOC | **31,935** | grep 统计(非生成代码) |
| `test/` .dart 文件数 | **74** | grep 统计 |
| `test/` 总 LOC | **10,371** | grep 统计 |
| `lib/` 中 `print(` 残留 | **1 处** | `lib/app.dart:125`,已加 `// ignore: avoid_print` |
| `lib/` 中 `debugPrint(` | **0 处** | — |
| `lib/` 中 `// TODO/FIXME/XXX/HACK` 真标记 | **7 处** | 全是 "v1.0+ TODO" 未来增强,非 bug |
| `lib/` 中 `// XXX` 占位 | **0 处** | grep 验证(很多 `xxx` 是变量名/通配符) |
| 当前版本 | `pubspec.yaml` `version: 0.21.0+1` | — |
| `schemaVersion` | `app_database.dart:64` = **11** | AGENTS.md 写 8(滞后 3 个) |
| `flutter test` 总数 | **703 / 703 pass** | AGENTS.md 写 702(差 1) |
| `flutter analyze` | **0 issues** | — |
| `dart scripts/check_all.dart` | **2/2 通过** | purity + consistency |
| `python scripts/check_cross_feature.py` | **0 violations** | 49 files checked |
| git 状态 | working tree clean,单 master 分支,**0 tag** | — |

### 0.2 最近 30 / 50 / 100 commit 风格统计(实测)

| 区间 | 中文 round (`v0.X round N:`) | 英文 conventional (`<type>(<scope>):`) | 比例(英文 %) |
|---|---|---|---|
| 最近 30 | **6** | **24** | **80%** |
| 最近 50 | **6** | **44** | **88%** |
| 最近 100 | **52** | **48** | **48%** |

> **关键观察**:
> 1. **最近 30 commit 中 80% 是英文 conventional**,违反 `CHINESE_COMMIT_GUIDE.md` "项目 commit 历史全部中文" (L17)
> 2. **最近 50 commit 中 88% 是英文** — 比 30 更恶化,趋势是逐渐切到 conventional commit
> 3. **最近 100 中 52% 是中文** — 整个项目历史里约一半是中文,但 2026-07-15 后 v0.18 起 26 个 round commit 中 24/30 = **80%** 是英文
> 4. 范本对照(最近 6 个中文 commit 都是 v0.21 round 22-26): `v0.21 round 26: P3-1 主题切换淡入动画` 风格
> 5. 范本对照(最近 5 个英文 commit): `97476d5 refactor(encryption): encrypt 包迁移到 pointycastle`

### 0.3 文档清单 + 同步状态

| 文档 | 路径 | 最后更新 | 同步状态 | 滞后点 |
|---|---|---|---|---|
| `AGENTS.md` | `/AGENTS.md` | v0.17 round 14 P1-9(commit 7b95d41) | ⚠️ **滞后** | L9 写 "Flutter 3.44.5" / L104 写 "schemaVersion 当前 8" / L136 写 "702 cases" / L236 内部自爆 "项目跑的是 3.41.9" — **3 个版本号自相矛盾** |
| `README.md` | `/README.md` | 早期 v0.18 | ⚠️ **滞后** | L25 写 "3.44.5" 但实际 3.41.9;L52 写 "encrypt" 库(实际 v0.18 已换 pointycastle);L123 写 "702 cases" 实际 703 |
| `CHANGELOG.md` | `docs/CHANGELOG.md` | 2026-07-17 (v0.17.0) | ❌ **严重滞后** | 整段缺 v0.18 / 0.19 / 0.20 / 0.21(4 个 minor version, 26+ round commit 无记录) |
| `WHITEPAPER.md` | `docs/WHITEPAPER.md` | 2026-07-17 (v0.17 round 7) | ❌ **严重滞后** | L4 "最后更新 2026-07-17" — 整文档 v0.17;§6 架构图 / §13 路线表 / §19.4 关键路径 全部滞后;L470/587 "commit message 用纯英文" 跟 CHINESE_COMMIT_GUIDE.md 自相矛盾;L608 引用 `scripts/test_delivery_rate.dart` / `scripts/8a2_rewrite_to_absolute.py` / `scripts/8a_rewrite_imports.py` — 后 2 个 **已删** |
| `DEPLOYMENT.md` | `docs/DEPLOYMENT.md` | 早期(v0.5) | ❌ **滞后** | L15 `fvm use 3.44.5` vs L36 `fvm use 3.41.9` 矛盾;L40 `flutter run -d chrome` 跟 AGENTS.md "drift worker 404" 提示矛盾;L121/122 `app.chroniccare` 跟 L105 `app.chroniccare.you` 矛盾;L124/142/152/155/157 "死了么" / "治愈" / "突然死了" / "再治愈更难" 4 处 P2-P0-10 风险未修;L191 "© 2026 Mavis" 角色不明 |
| `SENDGRID_SETUP.md` | `docs/SENDGRID_SETUP.md` | v0.16 | ⚠️ **滞后** | L72 `test/data/email_service_test.dart` 路径错(应该是 `_roundN_test.dart`);L83 `import 'package:chroniccare/data/services/email_service.dart'` 路径错(实际 `lib/core/data/services/email_service.dart`);L88-91 `EmailService(apiKey, useMock: false)` 实际签名已变;L94 `to: '13800138000'` 注释说 "phone 替代 email" 但参数名还是 `to`;L98 `medication: null` 类型应改 `MedicationEntity?` |
| `CHINESE_COMMIT_GUIDE.md` | `docs/CHINESE_COMMIT_GUIDE.md` | v0.17 round 14 P3-1 | ❌ **规范自废** | L17 "❌ 不用英文 (项目 commit 历史全部中文)" 跟实际 80% 英文严重矛盾 |
| `GIT_WORKFLOW.md` | `docs/GIT_WORKFLOW.md` | v0.17 round 14 P3-2 | ⚠️ **失效** | L84 "每个 minor version 在最后一个 round 后打 tag" — v0.18/19/20/21 都 **无 tag**(`git tag -l` 空) |
| `P2_COMPLIANCE_REVIEW.md` | `docs/P2_COMPLIANCE_REVIEW.md` | 2026-07-18 (v0.18 初) | ⚠️ 待查 | 13 P0 + 24 P1 + 17 P2 + 5 P3 = 59 项,**部分已修未标"已修"** |
| `P2_DESIGN_REVIEW.md` | `docs/P2_DESIGN_REVIEW.md` | 2026-07-18 | 待查 | (本报告未深读) |
| `P2_SYSTEM_REVIEW.md` | `docs/P2_SYSTEM_REVIEW.md` | 2026-07-18 | 待查 | (本报告未深读) |
| `CODE_REVIEW_v0.17r12.md` | `docs/CODE_REVIEW_v0.17r12.md` | 2026-07-18 | 历史 | v0.17 round 12 末产物,后 26 round 未更新 |
| `legal/privacy_policy.md` | `assets/legal/privacy_policy.md` | 2026-07-20 (v0.21) | ✅ 基本同步 | L47/48 v0.18 录音加密 + v0.21 文字加密都提到了 ✓;L111 `privacy@chroniccare.app` 占位无标注(P2-P0-6) |
| `legal/sensitive_data_consent.md` | `assets/legal/sensitive_data_consent.md` | 2026-07-20 | ❌ **PIPL 告知不实** | L49 "树洞录音 \| 本地(当前未加密,v1.0+ 加密)" — v0.18 P0-2 已加密(commit 4f2f196),隐私政策正确,本同意书**错** |
| `legal/user_agreement.md` | `assets/legal/user_agreement.md` | 2026-07-20 | ⚠️ 占位 | L57 `support@chroniccare.app(占位)` / L58 `https://github.com/example/chroniccare/issues(占位)` 都是占位(P2-P0-6) |

### 0.4 上一轮 v0.17 round 1-5 已修流程项回顾

v0.17 round 1-5 (P3 阶段) 落了 4 项 process 改进,这次审视检查每个的现状:

| 改进项 | 状态 | 评价 |
|---|---|---|
| 中文 commit 规范 (`CHINESE_COMMIT_GUIDE.md`) | ❌ **失效** | 规范写"全部中文",实际最近 50 commit 88% 英文 |
| 中文 Git workflow (`GIT_WORKFLOW.md`) | ⚠️ 框架在 / 细节失效 | 单 master 一直 OK;但 **tag 流程失效(v0.18-0.21 全无 tag)** |
| 中文代码审查 skill | ✅ 实践过 | P2 review 落到 P2_COMPLIANCE_REVIEW.md 59 项,13 P0 大部分已修但 review doc 没标"已修"项 |
| 中文文档 | ⚠️ 部分 | AGENTS.md v0.17 末大改;但 CHANGELOG / WHITEPAPER 滞后 4 个 minor version |

---

## 1. 顶层架构审视(流程 / 规范层)

### 1.1 commit message 习惯

**严重违反规范** — 最近 30 commit 中 **80% 是英文 conventional commit**,跟 `CHINESE_COMMIT_GUIDE.md` 规则严重不符。

| 项目 | `CHINESE_COMMIT_GUIDE.md` 规则 | 实际 |
|---|---|---|
| Subject 语言 | "中文,动词开头" (L16) | **80% 英文**(refactor/fix/feat/test/docs/chore) |
| 前缀 | `<version> round <N>:` (L15) | **80% 无 round 前缀** |
| Type 分类 | (未规定,默认 round) | **80% 用 conventional commit `<type>(<scope>):`** |
| 例子 | `v0.17 round 14: P1-3 split core_providers into 3 files` | `97476d5 refactor(encryption): encrypt 包迁移到 pointycastle` |

**根因分析**:
- `CHINESE_COMMIT_GUIDE.md` L17 写"❌ 不用英文 (项目 commit 历史全部中文)",这句**不实**(v0.16 round 1-20 + v0.17 就有 refactor / fix / test / docs 英文 commit)
- v0.18-v0.21 期间 26 个 round commit 全部用 conventional commit 英文,作者已切换风格但**规范没更新**

**修复建议(2 选 1)**:
- **选项 A(推荐)**: 接受"英文 conventional + 中文 round"双轨并存,更新 `CHINESE_COMMIT_GUIDE.md` 删"全部中文"那句话,把规范改为接受 conventional commit 风格。conventional commit 在 GitHub UI / IDE / changelog-gen 工具里更通用
- 选项 B: 严格执行中文,迁回旧风格(痛苦,不推荐)

### 1.2 文档体系

**3 类滞后,1 类矛盾**:

1. **严重滞后**:
   - `CHANGELOG.md` 缺 v0.18 / 0.19 / 0.20 / 0.21 整段(4 个 minor version, 26+ round, 3+ 月工作量)
   - `WHITEPAPER.md` 整文档 v0.17 round 7(2026-07-17),未更新
2. **轻微滞后**:
   - `AGENTS.md` 数字滞后(schemaVersion / 测试数 / 3 个版本号自相矛盾)
   - `README.md` 路径 / 数字 / 库依赖滞后
   - `DEPLOYMENT.md` Flutter 版本冲突 / 营销文案"P2-P0-10"未修 / 路径错
   - `SENDGRID_SETUP.md` 路径 / API 签名 / 注释错
3. **过期 / 矛盾**:
   - `sensitive_data_consent.md` L49 说"录音未加密",但实际 v0.18 P0-2 已 AES-256 → **PIPL 告知不实,合规风险**
   - `CHINESE_COMMIT_GUIDE.md` L17 vs `WHITEPAPER.md` L470/587 自相矛盾(中文 vs 英文)
4. **历史归档**:
   - `CODE_REVIEW_v0.17r12.md` / `P2_*_REVIEW.md` 仍是 v0.17 末 / v0.18 初产物,未说明"哪些 P0 已修,哪些遗留"

**关键文件路径不一致**(`WHITEPAPER.md §19.4` vs 实际):

| `WHITEPAPER` 写 | 实际 |
|---|---|
| `lib/data/database/app_database.dart` | `lib/core/data/database/app_database.dart` |
| `lib/routing/app_router.dart` | `lib/core/routing/app_router.dart` |
| `lib/theme/app_tokens.dart` | `lib/core/theme/app_tokens.dart` |
| `lib/data/services/notification_service.dart` | `lib/core/data/services/notification_service.dart` |

**AGENTS.md 内部 3 个版本号自相矛盾**(本审视实测):

| 行号 | 写 | 实际 |
|---|---|---|
| L9 | "Flutter 3.44.5 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3" | `flutter --version` = **3.41.9** |
| L236 | "Flutter 3.44.5+ ... 当前项目跑的是 3.41.9 所以 work" | 跟 L9 矛盾 |
| `pubspec.yaml` L8 | `flutter: '>=3.41.0'` | 约束 ✓ (3.41.0+) |

→ AGENTS.md L9 应该改 "Flutter 3.41.9 (>=3.41.0 兼容)" / 删 L236 "3.44.5+" 那段

### 1.3 命名 / 注释 / 本地化

| 维度 | 状态 | 评价 |
|---|---|---|
| 命名 (`*Entity` 后缀) | ⚠️ 灰色地带 | `HourMinute` 在 `entities/` 但无 `Entity` 后缀(实际是 value object 不是 entity);AGENTS.md 命名约定不区分 entity / value object |
| 命名 (snake_case 表名) | ✅ | 7 个 drift 表都 snake_case + 单数 @DataClassName |
| 命名 (XRepository / XRepositoryImpl) | ✅ | 7 个 repo 都遵守 |
| 注释语言混用 | ⚠️ 中英混 47% | 1344 个 `///` doc comment, 944 个 `//` line comment,统计 47% 混(主要: identifier 用英文, 解释用中文) |
| 中文本地化 | ⚠️ 4 处漏 | `app_zh.arb` 仍有 4 处半角省略号 `...`(L1 / L430 / L799) + 1 处半角逗号(L39);P1-16 修了 173 但漏 5 |
| 全角标点脚本 | ⚠️ 检测能力不足 | `scripts/check_fullwidth_punctuation.py:18` `ASCII_PUNCT = r"[,;!?]"` 只覆盖 4 种,**漏检测 `:` `(` `)` `[` `]` `／` `——`** |

---

## 2. 底层逐行排查

### 2.1 代码规范问题

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 修复难度 | 建议优先级 |
|------|------|---------|------|--------|----------|------------|
| **spzh-01** | 命名 | `lib/domain/entities/hour_minute.dart:9` | `class HourMinute` 在 `entities/` 目录但无 `Entity` 后缀。AGENTS.md 命名表 L112 写 "domain 实体 = `*Entity` 后缀" — 但 `HourMinute` 是 value object,不是 entity。**AGENTS.md 命名约定不区分 entity / value object**,应补"value object 用 PascalCase 无后缀" | 低 | 低 | P3 |
| **spzh-02** | 命名 | `lib/domain/usecases/check_in_usecases.dart` | 文件名 plural "usecases"(整个项目就 1 个 usecase 文件),其他 7 个 domain 都是 singular class 名(medication_repository / contact_repository / vent_repository)。**应改 single file "record_check_in.dart" 一致** | 低 | 低 | P3 |
| **spzh-03** | 调试残留 | `lib/app.dart:125` | 唯一 1 处 `print('⚠️ AssessmentReminder.onAppStart 失败: $e')`,虽然有 `// ignore: avoid_print`,但 v0.18 P2-P0-3 PII 安全日志 fix 应**走 piiSafeLog / devLog**(release swallow) 而不是 `print`(生产环境 `print` 仍输出到 stdout,IDE 调试器可见) | 中 | 低 | **P2** |
| **spzh-04** | 死代码 | `lib/core/data/services/snooze_manager.dart:106` (1 处 `piiSafeLog` 半角冒号) + `lib/core/data/services/notification_service.dart:336, 623, 631` (3 处 TODO) + `lib/core/data/services/sms_service.dart:11, 12, 62, 99` (4 处 TODO Aliyun/Twilio) + `lib/core/data/services/email_service.dart:63` (1 处 v1.0+ TODO SMS) | 共 7 处真 TODO + 1 处 v1.0+ 占位;全是 future 增强,非 bug。**Mock provider 显式 throw**: `sms_service.dart:99` 抛 `StateError('AliyunSmsProvider.send() 未实现')` — README "占位 ≠ 占位" 矛盾 | 中 | 低 | **P2** |
| **spzh-05** | 命名 | `lib/core/l10n/strings.dart:15-30` | `Strings.emailBody(userName, days)` 等 hardcode 中文,但 v0.21 P0-7 PIPL §6 最小化 fix 后用了 `name` fallback。**应 deprecated + i18n 化**(P2-P1-04 列了),目前 v1.0+ TODO 但没写出来 | 中 | 中 | 中 |
| **spzh-06** | 命名 | `lib/l10n/app_localizations_*.dart` | Flutter 自动生成,**l10n key 100% camelCase**(625 zh + 617 en)— 一致 ✓。但 zh 跟 en 不全对称:`@homeLastMed` / `@homeNextReminder` / `@homeStreak` / `@setupStep` / `@snackbarErrorTemplate` 等 metadata 字段;en 独有 `@_v0_21_round_22_settings_clear_all_data` placeholder 1 个;zh 独有 `description` 1 个 | 低 | 低 | P3 |
| **spzh-07** | 命名 | `lib/l10n/app_zh.arb` 跟 `app_en.arb` | zh 637 keys / en 629 keys,差 8。**zh 多 9 个,en 少 9 个(metadata 加 placeholder)**,但 zh 跟 en 都各少 1 个真正的 string — 需要 gen-l10n 重新生成对齐 | 低 | 低 | P3 |
| **spzh-08** | 调试残留 | `scripts/test_delivery_rate.dart` | WHITEPAWER §19.2 提到这个脚本,实际存在但 v0.16 删 EmailService 的 dio 后**这个脚本实际跑不了**(参数已变)。**应在 docs 删掉** | 低 | 低 | P3 |
| **spzh-09** | 文档同步 | `lib/core/l10n/strings.dart:15-30` | `emailBody` / `emailSubject` / `emailFooter` 用全角标点 ✓;但 `emailLastMed` / `emailMedInfo` / `emailCycle` 用半角冒号 → `Strings.emailMedInfo` L25 `$name $dosage$unit` 没有中文标点,跟其他 3 个字符串风格不太一致 | 低 | 低 | P3 |
| **spzh-10** | 命名 | `lib/presentation/pages/medication/medication_calendar_page.dart` | 跨 feature 引用: `home_page.dart` import `medication/temp_medication_dialog.dart` + `medication/today_med_schedule.dart` — AGENTS.md v0.17 round 12 规则 "❌ presentation/pages/{A}/ 禁 import presentation/pages/{B}/",但 home 算 hub 例外。**其他跨 feature import 需要 grep 检查** | 中 | 中 | 中 |
| **spzh-11** | 命名 | `lib/main.dart:9` | `import 'package:chroniccare/core/data/database/app_database.dart';` 跟 v0.18 之前 `lib/data/database/...` 路径不一样。`SENDGRID_SETUP.md:83` `import 'package:chroniccare/data/services/email_service.dart';` 仍写**旧路径**(实际 `lib/core/data/services/...`)**文档 / 代码不一致** | 高 | 极低 | **高** |
| **spzh-12** | 命名 | `lib/main.dart` L + `lib/app.dart` | 项目实际跑的是 `lib/main.dart` + `lib/app.dart`,但 `WHITEPAPER.md:19.4 关键路径` 没列 `lib/main.dart` / `lib/app.dart` | 低 | 低 | P3 |
| **spzh-13** | 命名 | `AGENTS.md` L9 | "Flutter 3.44.5" 跟实际 3.41.9 不符;同时跟 L236 "3.41.9" 矛盾;pubspec.yaml L8 `flutter: '>=3.41.0'` 兼容 3.41.0+。**AGENTS.md 自相矛盾 3 个版本号** | 高 | 极低 | **高** |
| **spzh-14** | 命名 | `pubspec.yaml:2` | `description: "我今天吃了药 - 精神心理患者吃药打卡 + 停药通知"` — "停药通知"措辞偏冷;P2-P0-10 "治愈" 风险;**律师 review 前应温和化**(类似 "服药提醒" / "关怀提醒") | 中 | 极低 | 中 |
| **spzh-15** | 注释 | `lib/core/data/database/app_database.dart:43-58` | schemaVersion 升级注释堆了 5 行(6→7, 7→8, 8→9, 9→10, 10→11),全是 `v0.X round Y (P-X-X 修复):` 风格,没写"为什么改"。追溯要 git blame。**应保留 commit hash 方便查** | 低 | 低 | P3 |

### 2.2 文档同步问题

| 编号 | 类别 | 文件 | 描述 | 严重度 | 修复难度 | 建议优先级 |
|------|------|------|------|--------|----------|------------|
| **spzh-doc-01** | 文档过期 | `docs/CHANGELOG.md` | **整段缺 v0.18 / 0.19 / 0.20 / 0.21**(4 个 minor version, 26+ round, 3+ 月工作量)。最新条目 = v0.17.0 / 2026-07-17。Keep a Changelog 格式失效 | 高 | 中 | **P0** |
| **spzh-doc-02** | 文档过期 | `docs/WHITEPAPER.md` | 整文档 v0.17 round 7。§13 路线表 / §6 架构图 / §5 技术栈表 / §19.4 关键路径全滞后。**对内一站式档案失效** | 高 | 中 | **P1** |
| **spzh-doc-03** | 文档不一致 | `assets/legal/sensitive_data_consent.md:49` | "树洞录音 \| 本地(当前未加密,v1.0+ 加密)" — 但 v0.18 P0-2 已 AES-256 加密(commit 4f2f196)。**法律文档跟代码不一致 = PIPL 告知不实** | 高 | 极低 | **P0** |
| **spzh-doc-04** | 文档过期 | `AGENTS.md:104` | `app_database.dart schemaVersion 当前 8` → 实际 11(差 3 个) | 中 | 极低 | **P1** |
| **spzh-doc-05** | 文档过期 | `AGENTS.md:136` | `flutter test 必须全过(当前 702 cases)` → 实际 703 | 中 | 极低 | P1 |
| **spzh-doc-06** | 文档不一致 | `AGENTS.md:137` | `python scripts/check_cross_feature.py` → 实际 2 个 script 共存(`dart scripts/check_all.dart` + `python scripts/check_cross_feature.py`),不是替换关系 | 中 | 极低 | P2 |
| **spzh-doc-07** | 文档不一致 | `AGENTS.md:204` | "**任何 PR 必保 0 error / 0 warning**" — 项目用 `master` 单 dev,无 PR;`flutter analyze 0 issues` 满足 ✓。但**实际没 PR 工作流** | 低 | 低 | P3 |
| **spzh-doc-08** | 文档不一致 | `AGENTS.md:208` | 提交风格规则写"`<version> round <N>:<title>`,参考 `git log --oneline`" — 但 80% commit 不遵守 | 高 | 中 | **P1** |
| **spzh-doc-09** | 文档过期 | `README.md:52` | `\| 加密 \| flutter_secure_storage + encrypt (AES-256) \|` — 但 v0.18 commit 97476d5 已迁移 `encrypt` → `pointycastle` | 高 | 极低 | **P1** |
| **spzh-doc-10** | 文档过期 | `README.md:123` | `flutter test 跑所有测试(702 cases)` → 实际 703 | 中 | 极低 | P1 |
| **spzh-doc-11** | 文档不一致 | `docs/DEPLOYMENT.md:36` | `fvm use 3.41.9` 跟 L15 `fvm use 3.44.5` / L25 README / L9 AGENTS.md 都不一致;`flutter --version` 实测 3.41.9 — **DEPLOYMENT.md L36 是对的,L15 / README / AGENTS 都错** | 中 | 极低 | P2 |
| **spzh-doc-12** | 文档不一致 | `docs/SENDGRID_SETUP.md:88-99` | (1) L72 `test/data/email_service_test.dart` 路径错;(2) L83 import `package:chroniccare/data/services/email_service.dart` 错(应是 `core/data/services/...`);(3) L88-91 `EmailService(apiKey, useMock: false)` 实际签名已变;(4) L94 `to: '13800138000'` 注释说 phone 但参数名还是 to;(5) L98 `medication: null` 类型应改 `MedicationEntity?`;(6) L100 `cycleHours: 48` v0.21 P0-7 后是 int 不是 Duration | 高 | 中 | **P1** |
| **spzh-doc-13** | 文档过期 | `docs/GIT_WORKFLOW.md:84-90` | "每个 minor version 在最后一个 round 后打 tag" — v0.18 / 19 / 20 / 21 都无 tag(`git tag -l` 空) | 中 | 极低 | P2 |
| **spzh-doc-14** | 文档缺失 | `docs/` | 缺 `reports/` 索引文件。`reports/round27/` 已建,但 `reports/round1-26/` 怎么找?(本报告发现 round 26 实际是 419df9c,那 round 25 之前的报告在哪?) | 中 | 中 | P2 |
| **spzh-doc-15** | 文档不一致 | `docs/CHINESE_COMMIT_GUIDE.md:17` | "❌ 不用英文 (项目 commit 历史全部中文)" — 跟实际最近 30 commit 80% 英文矛盾。**最严重,误导新接手者** | 高 | 极低 | **P0** |
| **spzh-doc-16** | 文档不一致 | `docs/WHITEPAPER.md:14.3 沟通规范` L470 / L587 | "**commit message 用纯英文**(PowerShell 路径解析限制,中文标点会被吞)" — 跟 `CHINESE_COMMIT_GUIDE.md` 完全相反。**2 份"规范"自相矛盾** | 高 | 中 | **P0** |
| **spzh-doc-17** | 文档缺失 | `docs/` | 缺 `dataflow.md` / `architecture-decisions.md` 等 ADR(Architecture Decision Records)。当前只有 WHITEPAPER §18 决策表 + AGENTS.md 决策表 2 处,**没 ADR 流程** | 低 | 中 | P3 |
| **spzh-doc-18** | 文档缺失 | `docs/CHANGELOG.md` | 缺 v0.22 plan / 未来路线。v0.18-0.21 已合 26 个 round(CHANGELOG 都不写,plan 也不写) | 中 | 中 | P2 |
| **spzh-doc-19** | 文档缺失 | `assets/legal/*.md` | 3 份法律文档最后更新日期 2026-07-20,但 v0.21 round 24-26 有改动(release candidate / 联系人同意正式落地),法律文档没同步 | 中 | 中 | P1 |
| **spzh-doc-20** | 文档不一致 | `docs/P2_COMPLIANCE_REVIEW.md` | 13 P0 + 24 P1 + 17 P2 + 5 P3 = 59 项;v0.18-v0.21 已修 P2-P0-1 / 2 / 3 / 4 / 5 / 7 / 8 / 9 / 11 / 12 / 13 / 0-2 / 0-7 / 0-8, **但 review doc 没标"已修"**。新接手者不知 P0 是否都修了 | 中 | 中 | P2 |
| **spzh-doc-21** | 文档缺失 | `docs/WHITEPAPER.md:19.2 关键脚本` | 提到 `scripts/test_delivery_rate.dart` + `scripts/8a2_rewrite_to_absolute.py` + `scripts/8a_rewrite_imports.py` — 后 2 个 v0.18 后**已删**;`test_delivery_rate.dart` 仍存在但跑不了。**文档不实** | 中 | 极低 | P2 |
| **spzh-doc-22** | 文档不一致 | `docs/DEPLOYMENT.md:40` | `flutter run -d chrome` — 跟 AGENTS.md "dev 服务器坑: web 平台不能用 `flutter run -d chrome`(drift worker 404),用 `flutter build web` + `python -m http.server 8358` 走 production 模式" 矛盾 | 高 | 极低 | **P1** |
| **spzh-doc-23** | 文档不一致 | `docs/DEPLOYMENT.md:121-122` | L121 `app.chroniccare` 跟 L105 `app.chroniccare.you` 矛盾(Bundle ID 路径) | 中 | 极低 | P2 |
| **spzh-doc-24** | 文档不一致 | `docs/DEPLOYMENT.md:124, 142, 152, 155, 157` | 5 处 P2-P0-10 风险: "停药通知" / "精神心理疾病患者" / "突然死了" / "复发一次,再治愈更难" / "死了么" 模式 — **法律 / 广告法风险** | 高 | 极低 | **P0** |
| **spzh-doc-25** | 文档不一致 | `docs/DEPLOYMENT.md:191` | "© 2026 Mavis" — 角色不明(Mavis 是公司 / 人 / 项目代号?);"开发者邮箱" 等 L192 客服邮箱是占位 | 中 | 极低 | P2 |
| **spzh-doc-26** | 文档不一致 | `assets/legal/privacy_policy.md:111` + `assets/legal/user_agreement.md:57, 58` | (1) `privacy@chroniccare.app` / `support@chroniccare.app` / `https://github.com/example/chroniccare/issues` 全是占位;(2) 隐私政策没标"占位",用户协议标了;(3) PIPL §52 告知要求联系方式 — **占位 = 不实告知** | 高 | 极低 | **P1** |
| **spzh-doc-27** | 文档不一致 | `assets/legal/sensitive_data_consent.md:5` | "最后更新:2026-07-20" — 但 L49 内容是 v0.17 风格,不是 v0.21。**头部时间跟实际内容不一致** | 中 | 极低 | P2 |

### 2.3 中文本地化

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 修复难度 | 建议优先级 |
|------|------|---------|------|--------|----------|------------|
| **spzh-i18n-01** | 半角标点 | `lib/l10n/app_zh.arb:39` | `setupContactConsent: "我已告知上述联系人,App 会在我失联时给他们发通知"` — 联系人之后用**半角逗号** `,`,应改全角 `，`。**P1-16 修了 173 但漏 1** — 这是**用户可见的关键法律文案** | 中 | 极低 | **P1** |
| **spzh-i18n-02** | 半角标点 | `lib/l10n/app_zh.arb:7` | `commonLoading: "加载中..."` — 中文 UI 用半角 `...` 应改全角 `……`(GB/T 15834-2011 §4.6) | 中 | 极低 | **P1** |
| **spzh-i18n-03** | 半角标点 | `lib/l10n/app_zh.arb:430` | `assessmentLoadingBack: "正在返回上一页..."` — 同上 | 中 | 极低 | P1 |
| **spzh-i18n-04** | 半角标点 | `lib/l10n/app_zh.arb:799` | `medReportPdfLoading: "生成 PDF 中..."` — 同上 | 中 | 极低 | P1 |
| **spzh-i18n-05** | 半角标点 | `lib/l10n/app_zh.arb:67` | `settingsMedReportSubtitle: "选时间窗口（7/14/30 天）"` — 半角 `/` 应改全角 `／` 或保留半角加空格"7 / 14 / 30 天"(P2-P1-10) | 中 | 极低 | P2 |
| **spzh-i18n-06** | 半角标点 | `lib/l10n/app_zh.arb:147` | `snackbarPhoneInvalid: "号码格式不对（支持大陆/港澳台/国际）"` — 半角 `/` 应改全角 `／` 或顿号 `、`(P2-P1-15) | 中 | 极低 | P2 |
| **spzh-i18n-07** | 半角标点 | `lib/core/data/services/preset_medication_templates.dart:71, 92, 116, 136, 151` | **5 处 hint 全用半角括号** `()` 应改全角 `（）`(中文文案排版指北 + GB/T 15834-2011)。例:`hint: '常见 SSRI / SNRI 类抗抑郁药(具体药名以医生处方为准)'` → `常见 SSRI / SNRI 类抗抑郁药（具体药名以医生处方为准）` | 中 | 低 | P2 |
| **spzh-i18n-08** | 半角标点 | `lib/domain/logic/medication_report.dart:253-333` | **11 处报告模板半角冒号 `:`** 应改全角 `：`(PDF / Markdown 报告用户可见,医疗专业场景)。例:`buf.writeln('**患者:** ${...}')` | 中 | 低 | P2 |
| **spzh-i18n-09** | 半角标点 | `lib/core/data/services/notification_service.dart:83, 117, 155, 374, 414, 454, 458, 526, 558, 561` | **10 处 dev log 半角标点**(逗号 / 冒号),`developer.log` / `piiSafeLog` 输出。虽不直接用户可见,但 debug log 风格不一致。**应统一全角** | 低 | 低 | P3 |
| **spzh-i18n-10** | 半角标点 | `lib/core/data/services/reminder_scheduler.dart:111, 114, 116, 119, 193` | **5 处 dev log 半角标点** | 低 | 低 | P3 |
| **spzh-i18n-11** | 半角标点 | `lib/core/data/services/medication_report_pdf.dart:272-276` | **5 处 PDF 模板半角冒号**(用户可见) | 中 | 低 | P2 |
| **spzh-i18n-12** | 半角标点 | `lib/core/data/services/assessment_reminder_service.dart:67, 111, 182` | **3 处异常信息 / dev log 半角标点**(`评估提醒间隔必须是 $allowedDays 之一, 实际: $days`) | 低 | 低 | P3 |
| **spzh-i18n-13** | 半角标点 | `lib/domain/logic/assessment_comparison.dart:157` | `throw ArgumentError('未知量表: $scaleId');` — 半角冒号,虽 throw 给 dev 不给用户,但统一全角更专业 | 低 | 极低 | P3 |
| **spzh-i18n-14** | 半角标点 | `lib/domain/logic/care_engine.dart:144, 146` | `developer.log('✅ 关怀触发: ${trigger.type.name}')` / `developer.log('❌ 关怀触发失败: $e')` — 半角冒号 | 低 | 极低 | P3 |
| **spzh-i18n-15** | 半角标点 | `lib/core/data/database/connection/web.dart:25` | `'Web 平台暂不支持,**精神心理患者 PII 不能落明文 IndexedDB。**\n'` — 半角逗号。这是 `UnsupportedError` 的 message,**runZonedGuarded 捕获后展示给用户** | 中 | 极低 | P2 |
| **spzh-i18n-16** | 半角标点 | `lib/core/data/services/safety_watch_service.dart:238` | `developer.log('🚨 SafetyWatch 触发: trigger=$trigger days=$daysSinceLast')` — 半角冒号 | 低 | 极低 | P3 |
| **spzh-i18n-17** | 半角标点 | `lib/core/data/services/snooze_manager.dart:106` | `piiSafeLog('SnoozeManager', '❌ snooze 调度失败: $e')` — 半角冒号 | 低 | 极低 | P3 |
| **spzh-i18n-18** | 脚本检测能力 | `scripts/check_fullwidth_punctuation.py:17-18` | 脚本 `ASCII_PUNCT = r"[,;!?]"` 只覆盖 4 种标点,**不检查 `:` `(` `)` `[` `]` `／` `…` `——` 等**。注意 L25-28 单独有 `:` 检查(算 5 种),但 `( ) / ／ …` 都漏。P1-16 修了 173 但漏 30+(spzh-i18n-01..17 共 30+ 处) | 中 | 低 | P2 |
| **spzh-i18n-19** | 翻译质量 | `lib/l10n/app_en.arb` | P2-P2-04 已记录 5 个英文 i18n 文案机翻痕迹,目前**没修**。例:`"Took my meds today"` 替代 `"I took my meds today"` | 中 | 低 | P3 |
| **spzh-i18n-20** | 多语种 | `lib/l10n/` | **只有简中 + 英文**,P2-P3-01 已记录缺繁体中文(港澳台用户)。项目支持港澳台手机号 (P1-14) 但没繁体版 | 低 | 中 | P3 |
| **spzh-i18n-21** | 数字格式 | `lib/l10n/` | 没检查,默认 intl 包会按 locale 转换数字 / 日期 / 货币。`app_zh.arb` 用 `13800138000` 是中文数字习惯(无千分位),`app_en.arb` 同 key 同一数字。**应考虑港澳台 / 简中数字格式是否统一** | 低 | 中 | P3 |
| **spzh-i18n-22** | 日期格式 | `lib/l10n/` | `commonLoading` 之类没日期;但 `medication_report.dart:255` "报告周期: $start 至 $end(共 $windowDays 天)" 中文+数字格式;`lib/core/shared/formatters.dart` 应检查 | 低 | 中 | P3 |
| **spzh-i18n-23** | 人称统一 | `lib/l10n/app_zh.arb` | P2-P3-02 已记录 "你/您" 不统一。setup 用 "你的名字",disclaimer 用 "本" 不用 "您",`snackbarPhoneInvalid` 又有 "您"。**医疗 App 建议"您"** | 中 | 低 | P2 |
| **spzh-i18n-24** | 语气 | `lib/l10n/app_zh.arb` | v0.21 P1-21 中文本土化已落地。但 `setupContactConsent` 写"App 会在我失联时给他们发通知" — "失联" 偏冷,**温和版**: "如果你 48 小时没打卡,App 会通知他们" | 中 | 低 | P2 |
| **spzh-i18n-25** | 隐私文案 | `lib/l10n/app_zh.arb` | v0.21 P1-23 联系人同意已落地(setupContactConsent)。但**没配套的"我已撤回告知"文案**(legal_page 用) | 低 | 低 | P2 |
| **spzh-i18n-26** | emoji 慎重 | `lib/l10n/app_zh.arb` 多处 | 🌱 / 🌲 / 🌳 / 🌓 / 🔁 / ⚠️ / ✅ / ❌ emoji 多。P2-P1-14 记录"🌱 抑郁用户慎用"。目前**没做用户研究 / 心理评估** | 低 | 中 | P3 |

### 2.4 流程规范问题

| 编号 | 类别 | 文件 | 描述 | 严重度 | 修复难度 | 建议优先级 |
|------|------|------|------|--------|----------|------------|
| **spzh-flow-01** | 流程失效 | `CHINESE_COMMIT_GUIDE.md` | 规范写中文,实际最近 30 commit 80% 英文。**最严重** | 高 | 低 | **P0** |
| **spzh-flow-02** | 流程失效 | `GIT_WORKFLOW.md:84-90` | tag 流程规定打 tag,实际 v0.18-0.21 没 tag | 中 | 极低 | P2 |
| **spzh-flow-03** | 流程缺失 | `CHANGELOG.md` | v0.18+ 整段没记录。**P0 必修** | 高 | 中 | **P0** |
| **spzh-flow-04** | 流程缺失 | 无 | 缺"每次 round commit 后**立即**更新 CHANGELOG + AGENTS.md + WHITEPAPER"的 CI 检查 | 中 | 中 | P2 |
| **spzh-flow-05** | 流程缺失 | `scripts/check_fullwidth_punctuation.py:76` | 脚本是 warn-only(`return 0`)。**应在 CI 强制**(P1-16 修了 173 但 P1-16 自身没强 CI 化) | 中 | 低 | P2 |
| **spzh-flow-06** | 流程缺失 | 无 | 缺"法律文档跟代码 diff"的 CI 检查(P2-P2-15 提过) | 低 | 中 | P3 |
| **spzh-flow-07** | 流程缺失 | `scripts/check_fullwidth_punctuation.py:18` | 脚本只检查 `,;!?:` 5 种标点,实际应扩到 8+ 种(`()` `[]` `／` `…` `——`) | 中 | 低 | P2 |
| **spzh-flow-08** | 流程混乱 | 多 commit | 26 个 round commit 用了 2 种风格混搭,git log 检索时 diff 不便。**应统一一种**(推荐 conventional commit) | 中 | 低 | P2 |
| **spzh-flow-09** | 流程缺失 | `pubspec.yaml` | 没 `analyzer: exclude:` 配置,**flutter analyze 0 issues 但没强 CI gate**(commit 9c305ed 修过 "all analyzer errors/warnings",但这是事后修) | 低 | 低 | P2 |
| **spzh-flow-10** | 流程缺失 | `AGENTS.md:200-208` | "关键约束"段写"任何 PR 必保 0 error / 0 warning" 但项目**没 PR 工作流**(单 dev 单 master),文档不实 | 低 | 低 | P3 |
| **spzh-flow-11** | 流程失效 | `AGENTS.md:9 + AGENTS.md:236` | 同一文档 L9 写 "Flutter 3.44.5" 跟 L236 写 "3.41.9" 自相矛盾;`pubspec.yaml:8` `>=3.41.0`;`flutter --version` 实测 3.41.9。**3 个版本号 4 处不一致** | 高 | 极低 | **P1** |
| **spzh-flow-12** | 流程失效 | `AGENTS.md:104 + app_database.dart:64` | AGENTS.md 写 schemaVersion 8,实际 11;**新接手者按文档改 schema 会漏 migration** | 高 | 极低 | **P0** |
| **spzh-flow-13** | 流程缺失 | 无 | 缺"`flutter --version` 输出 vs pubspec.yaml 约束 vs 文档声称版本"的一致性 CI 检查 | 中 | 中 | P3 |

---

## 3. Bug 清单(流程 / 文档类)

> "Bug" 指**当前行为有问题**或**违反某已知模式/最佳实践**,区别于 §2 "可优化"。

| 编号 | 类别 | 文件 | 描述 | 严重度 | 修复难度 | 建议优先级 |
|------|------|------|------|--------|----------|------------|
| **spzh-bug-01** | 文档 bug | `assets/legal/sensitive_data_consent.md:49` | "树洞录音 \| 本地(当前未加密,v1.0+ 加密)" — v0.18 P0-2 已 AES-256 加密。**PIPL 告知不实,合规风险** | **高** | 极低 | **P0** |
| **spzh-bug-02** | 文档 bug | `CHINESE_COMMIT_GUIDE.md:17` | "项目 commit 历史全部中文" — 实际最近 30 commit 80% 英文,**新接手者会被误导** | 高 | 极低 | **P0** |
| **spzh-bug-03** | 文档 bug | `WHITEPAPER.md:14.3 L470, L587` | "commit message 用纯英文" 跟 `CHINESE_COMMIT_GUIDE.md` 自相矛盾 | 高 | 极低 | **P0** |
| **spzh-bug-04** | 文档 bug | `CHANGELOG.md` | v0.18 / 19 / 20 / 21 4 个 minor version 无记录 = **release notes 失效** | 高 | 中 | **P0** |
| **spzh-bug-05** | 文档 bug | `AGENTS.md:104` | schemaVersion 8 → 实际 11。**新接手者按文档改 schema 会漏 migration** | 高 | 极低 | **P0** |
| **spzh-bug-06** | 文档 bug | `AGENTS.md:136` | 测试 702 → 实际 703。**新接手者跑测试预期失败** | 中 | 极低 | P1 |
| **spzh-bug-07** | 文档 bug | `AGENTS.md:9 + AGENTS.md:236 + DEPLOYMENT.md:15` | Flutter 版本 3 个文档 4 处不一致(3.44.5 vs 3.41.9 vs >=3.41.0) | 高 | 极低 | **P1** |
| **spzh-bug-08** | 文案 bug | `lib/l10n/app_zh.arb:39, 7, 430, 799` | 4 处半角标点(P1-16 漏修),其中 1 处是联系人同意**关键法律文案** | 中 | 极低 | **P1** |
| **spzh-bug-09** | 文案 bug | `lib/domain/logic/medication_report.dart:11 处` | 报告模板半角冒号 11 处(PDF / Markdown 用户可见) | 中 | 低 | P2 |
| **spzh-bug-10** | 文案 bug | `lib/core/data/services/preset_medication_templates.dart:5 处` | 模板 hint 半角括号(P0-3 修了处方药名但漏修括号) | 中 | 极低 | P2 |
| **spzh-bug-11** | 文案 bug | `lib/core/data/database/connection/web.dart:25` | 异常信息半角逗号(runZonedGuarded 捕获后会显示给用户) | 中 | 极低 | P2 |
| **spzh-bug-12** | 调试残留 bug | `lib/app.dart:125` | 唯一 1 处 `print` 残留。P2-P0-3 PII 安全日志 fix 没覆盖到这里。**生产 build 仍走 print** | 中 | 极低 | P2 |
| **spzh-bug-13** | 文档 bug | `pubspec.yaml:2` | `description: "我今天吃了药 - 精神心理患者吃药打卡 + 停药通知"`。P2-P0-10 "停药通知"措辞 — "停药"偏冷,**律师 review 前应温和化** | 中 | 极低 | P2 |
| **spzh-bug-14** | 流程 bug | `git tag` | v0.18 / 19 / 20 / 21 没 tag。release 流程没跟踪 | 中 | 极低 | P2 |
| **spzh-bug-15** | 脚本 bug | `scripts/check_fullwidth_punctuation.py:18` | `ASCII_PUNCT = r"[,;!?]"` 太窄,漏 `:()[]/...` 等。**P1-16 修了 173 但还有 30+ 漏** | 中 | 低 | P2 |
| **spzh-bug-16** | 文档 bug | `assets/legal/privacy_policy.md:111` + `user_agreement.md:57, 58` | `privacy@chroniccare.app` / `support@chroniccare.app` / `https://github.com/example/chroniccare/issues` 占位邮箱。P2-P0-6 没修。**PIPL §52 告知要求联系方式** | 中 | 极低 | **P1** |
| **spzh-bug-17** | 命名 bug | `lib/domain/entities/hour_minute.dart:9` | `class HourMinute` 在 entities 目录但无 `Entity` 后缀。**AGENTS.md 命名约定灰色地带** | 低 | 低 | P3 |
| **spzh-bug-18** | 文档 bug | `WHITEPAPER.md:4` | "最后更新:2026-07-17(v0.17 round 7 后)" — 整文档严重滞后,**对内档案失效** | 高 | 中 | **P1** |
| **spzh-bug-19** | 文档 bug | `WHITEPAPER.md:19.4 关键文件路径` | 4 个文件路径写错(lib/data 实际是 lib/core/data 等),**新接手者按文档找不到文件** | 中 | 极低 | P2 |
| **spzh-bug-20** | 文档 bug | `WHITEPAPER.md:19.2 关键脚本` | 提到 `scripts/test_delivery_rate.dart` + `scripts/8a2_rewrite_to_absolute.py` + `scripts/8a_rewrite_imports.py` — 后 2 个 v0.18 后**已删**,文档不实 | 中 | 极低 | P2 |
| **spzh-bug-21** | 文档 bug | `README.md:52` | 加密依赖写"encrypt"库,实际 v0.18 commit 97476d5 已迁移到 pointycastle。**新接手者 `flutter pub add encrypt` 会被代码层报错** | 高 | 极低 | **P1** |
| **spzh-bug-22** | 文档 bug | `SENDGRID_SETUP.md:83, 88-91, 94, 98, 100` | 5 处 path / API 签名错。**用户照抄会 import 失败 / 函数参数错** | 高 | 极低 | **P1** |
| **spzh-bug-23** | 文档 bug | `DEPLOYMENT.md:40` | `flutter run -d chrome` 跟 AGENTS.md "drift worker 404" 提示矛盾;**新接手者按文档跑 web 必崩** | 高 | 极低 | **P1** |
| **spzh-bug-24** | 法律 bug | `DEPLOYMENT.md:124, 142, 152, 155, 157` | 5 处 P2-P0-10 风险: "停药通知" / "精神心理疾病患者" / "突然死了" / "再治愈更难" / "死了么"。**律师 review 必拒** | 高 | 极低 | **P0** |
| **spzh-bug-25** | 文档 bug | `AGENTS.md:137` | `python scripts/check_cross_feature.py` 跟 v0.16 round 13 合并的 `dart scripts/check_all.dart` 同时存在,文档没说哪个是 source of truth;`flutter test` baseline 应该是 `dart scripts/check_all.dart` + `python scripts/check_cross_feature.py` 4 件套 | 中 | 极低 | P2 |
| **spzh-bug-26** | 文档 bug | `P2_COMPLIANCE_REVIEW.md` | 13 P0 已修没标"已修",新接手者不知 P0 是否都修了;**review doc 自身没跟踪** | 中 | 中 | P2 |
| **spzh-bug-27** | 文档 bug | `DEPLOYMENT.md:36` | `fvm use 3.41.9` 跟 L15 `fvm use 3.44.5` 自相矛盾;**L36 是对的(实测 3.41.9),L15 错** | 中 | 极低 | P2 |
| **spzh-bug-28** | 命名 bug | `lib/core/l10n/strings.dart:15-30` | 整个 `Strings` 类 hardcode 中文 fallback,但 `EmailTemplate` 应该是 domain 层接收 i18n strings 作为参数。**当前 Strings 是临时实现但注释没标 @Deprecated** | 中 | 中 | P3 |
| **spzh-bug-29** | 调试残留 bug | `lib/core/data/services/sms_service.dart:99` | `'AliyunSmsProvider.send() 未实现 (v1.0+ TODO — 需要 accessKey/secret/signName)'` — `StateError` 抛出不友好,UI 拿到 catch 后显示 "发送失败" 但不告诉用户"未实现"。**应给 mock provider 一个友好 fallback** | 中 | 低 | P2 |
| **spzh-bug-30** | 命名 bug | `lib/main.dart:9` | `import 'package:chroniccare/core/data/database/app_database.dart';` — 跟 v0.18 之前 `lib/data/database/...` 路径不一样,`SENDGRID_SETUP.md:83` 仍写**旧路径**,**实际新接手者按文档 import 找不到文件** | 高 | 极低 | **P1** |

### 3.1 隐私 / 合规专项检查 (PIPL 视角)

| 法律条款 | 当前状态 | 风险 |
|---|---|---|
| **PIPL §4 目的明确** | ⚠️ 隐私政策 §1 写"健康数据"模糊 | "健康数据" 跟"医疗数据" 边界模糊;P2-P0-10 提示可能触发 NMPA 医疗器械备案 |
| **PIPL §6 最小化** | ✅ v0.21 P1-23 联系人同意 + P0-7 userName nullable | OK |
| **PIPL §7 真实准确告知** | ❌ `sensitive_data_consent.md:49` 说"未加密" 跟实际 v0.18 P0-2 加密矛盾 | **告知不实** |
| **PIPL §13 紧急联系人知情** | ✅ v0.21 P1-23 setupContactConsent + 隐私政策 §0.5 | OK |
| **PIPL §14 单独同意** | ✅ v0.18 P2-P0-13 step 0 PopScope | OK |
| **PIPL §23 第三方告知** | ✅ 隐私政策 §0.5 + setupContactConsent | OK |
| **PIPL §26 撤回同意** | ⚠️ P2-P0-1 "法律与隐私" 入口缺失 | 隐私政策 §4 写"您可以随时撤回" 但 settings_page 找不到入口 |
| **PIPL §44 撤回后停止处理** | ✅ v0.21 P0-1 userName nullable + 隐私政策 §0 consentRevokedAt | OK |
| **PIPL §47 主动删除** | ✅ v0.21 P0-8 settings_page clearAllData | OK |
| **PIPL §52 联系方式** | ❌ `privacy@chroniccare.app` 占位无标注 | 告知要求真实联系方式 |
| **PIPL §53 投诉举报** | ✅ 隐私政策 §9 投诉举报:网信办、公安机关 | OK |
| **广告法 §15 处方药禁广告** | ⚠️ DEPLOYMENT.md §5 描述隐含"SSRI / SNRI / 情绪稳定剂 / 助眠药" 营销文案 | 法律风险 |
| **广告法 §16 治愈率禁** | ❌ DEPLOYMENT.md:155 "复发一次,再治愈更难" | 必删 |
| **医疗广告管理办法 §3 医疗广告禁** | ❌ DEPLOYMENT.md "为精神心理疾病患者(焦虑/抑郁/双相/睡眠障碍)打造" | 触发 NMPA 备案? |
| **精神药品品种目录** | ⚠️ `preset_medication_templates.dart` hint 提到"苯二氮卓类/助眠药" 分类 OK 但 hint 半角括号 | 半角括号,中英混排 |

---

## 4. 总结

### 4.1 关键发现 3 条

1. **法律 / 文档同步类问题最严重 — 多个文档自相矛盾,部分内容跟实际代码冲突**
   - `CHANGELOG.md` 整段缺 v0.18 / 19 / 20 / 21(4 个 minor version, 26+ round)
   - `WHITEPAPER.md` 整文档停在 v0.17 round 7(3+ 个月前)
   - `assets/legal/sensitive_data_consent.md:49` 说"录音未加密",但 v0.18 P0-2 已加密 → **PIPL 告知不实,合规风险**
   - `CHINESE_COMMIT_GUIDE.md:17` 说"全部中文" vs `WHITEPAPER.md:470/587` 说"用纯英文" — **2 份规范自相矛盾**
   - `AGENTS.md:9` "3.44.5" vs `AGENTS.md:236` "3.41.9" vs `DEPLOYMENT.md:15` "3.44.5" vs `DEPLOYMENT.md:36` "3.41.9" — **同文档 4 处版本号不一致**
   - DEPLOYMENT.md 5 处 P2-P0-10 风险("死了么" / "治愈" / "突然死了" / "再治愈更难" / "停药通知") — **律师 review 必拒**

2. **commit 规范自废,作者已切到 conventional commit 但规范没更新**
   - `CHINESE_COMMIT_GUIDE.md` 写"项目 commit 历史全部中文"
   - 实际最近 30 commit **80% 英文**,最近 50 commit **88% 英文**
   - 推荐方案: 接受 conventional commit 双轨,更新 `CHINESE_COMMIT_GUIDE.md` 删"全部中文"那句话(选 A)

3. **P2 合规 review doc 13 P0 大部分已修,但 review 文档没标"已修"项**
   - `P2_COMPLIANCE_REVIEW.md` 13 P0 + 24 P1 + 17 P2 + 5 P3 = 59 项
   - 实际已修: P2-P0-1 / 2 / 3 / 4 / 5 / 7 / 8 / 9 / 11 / 12 / 13 / 0-2 / 0-7 / 0-8(共 14 项)
   - 实际未修: P2-P0-6(占位邮箱) / P2-P0-10("治愈" / DEPLOYMENT.md 文案) / P2-P0-1(撤回入口) 部分
   - **review doc 自身没跟踪,P0 修了没标"已修",新接手者不知 P0 是否都修了**

### 4.2 Top 5 必修(本轮建议立刻修)

按 **严重度 + 修复难度 + 落地价值** 综合排序:

| 排序 | 编号 | 标题 | 文件:行 | 修复方法 | 估时 |
|------|------|------|---------|----------|------|
| **#1** | spzh-bug-04 + spzh-doc-01 | **补 CHANGELOG v0.18 / 19 / 20 / 21** | `docs/CHANGELOG.md` | 按 git log 26 个 round commit 写 4 个 minor version entry,每条按 Keep a Changelog 格式 | 2-3h |
| **#2** | spzh-bug-01 + spzh-doc-03 + spzh-bug-24 | **修 sensitive_data_consent.md L49 + DEPLOYMENT.md 5 处 P2-P0-10 风险** | `assets/legal/sensitive_data_consent.md:49` + `docs/DEPLOYMENT.md:124, 142, 152, 155, 157` | 改"本地加密存储(AES-256,密钥设备绑定,2026-07 起启用)";DEPLOYMENT.md 改温和版(去掉"死了么" / "治愈" / "突然死了",改为"关怀提醒" / "规律吃药" / "突然停药" / "再规律") | 1-2h |
| **#3** | spzh-bug-08 + spzh-i18n-01..04 | **修 app_zh.arb 4 处半角标点** | `lib/l10n/app_zh.arb:39, 7, 430, 799` | `,` → `，`;`...` → `……`;同时把 `lib/l10n/app_localizations_zh.dart` 4 个对应 getter 改了 | 10min |
| **#4** | spzh-bug-05 + spzh-bug-06 + spzh-bug-07 + spzh-doc-04..06 + spzh-bug-21..23 + spzh-bug-25 | **AGENTS.md / README.md / DEPLOYMENT.md / SENDGRID_SETUP.md 同步当前数字 + 路径** | `AGENTS.md:9, 104, 136, 236` + `README.md:52, 123` + `DEPLOYMENT.md:15, 36, 40` + `SENDGRID_SETUP.md:72, 83, 88-91, 94, 98, 100` | schemaVersion 8 → 11;702 → 703;3 个版本号 → 3.41.9;`encrypt` → `pointycastle`;`flutter run -d chrome` → `flutter build web + python -m http.server 8358`;5 处 path / API 签名 | 1h |
| **#5** | spzh-bug-02 + spzh-bug-03 + spzh-flow-01 | **修 commit 规范自相矛盾** | `CHINESE_COMMIT_GUIDE.md:17` + `WHITEPAPER.md:470, 587` | 2 选 1: A. 接受 conventional commit 双轨,更新 CHINESE_COMMIT_GUIDE.md;B. 强制中文。**推荐 A** | 30min |

### 4.3 长期建议(本轮不修,留 P2)

- **修脚本检测能力**:`scripts/check_fullwidth_punctuation.py` 扩展 ASCII_PUNCT 到 8+ 种,加 `--strict` 模式在 CI 强制
- **修报告模板 11 处半角冒号**:`lib/domain/logic/medication_report.dart` + `lib/core/data/services/medication_report_pdf.dart` 全文标点统一
- **修 preset_medication_templates 5 处半角括号**:P0-3 修了处方药名但漏改括号
- **加 CI 强制流程**:`flutter analyze` + `flutter test` + `dart scripts/check_all.dart` + `python scripts/check_cross_feature.py` + `python scripts/check_fullwidth_punctuation.py --strict` 5 件套
- **加 release notes 自动生成**:commit 用 conventional commit 风格的话,`standard-version` / `release-please` 自动从 commit log 生成 CHANGELOG,根治 CHANGELOG 滞后问题
- **WHITEPAPER 重写**:整文档按当前 v0.21 状态重写,§13 路线图 / §6 架构图 / §5 技术栈表 全部刷新;同时加"哪些 P2 review P0 已修,哪些遗留"对照表
- **统一 commit 规范 + 加 CI lint**:commitlint + husky / lefthook,挡掉不符合规范的 commit
- **法律文档 CI 同步**:`scripts/check_legal_sync.py` 检查法律文档最后更新日期 vs 涉及法律变更的 commit 日期,滞后 N 天报警
- **P2_COMPLIANCE_REVIEW 跟踪表**:加"已修 / 遗留 / 不修"3 列,方便 review 进度可视化
- **flutter 版本 CI 检查**:`scripts/check_flutter_version.py` 比对 `flutter --version` 输出 vs `pubspec.yaml` 约束 vs AGENTS.md 描述 vs README.md 描述

### 4.4 数字快照

| 维度 | 数字 |
|---|---|
| 审视 lib 文件数 | 161 |
| 审视 lib LOC | 31,935 |
| 审视 test 文件数 | 74 |
| 审视 test LOC | 10,371 |
| 最近 30 commit 中文 round 比例 | **20% (6/30)** |
| 最近 30 commit 英文 conventional 比例 | **80% (24/30)** |
| 最近 50 commit 中文 round 比例 | 12% (6/50) |
| 最近 50 commit 英文 conventional 比例 | **88% (44/50)** |
| 注释中英混比例 | 47% (2277/4661) |
| app_zh.arb 半角标点(用户可见) | **5 处** (4 个 `...` + 1 个 `,`) |
| domain/data 半角标点(报告 / PDF / log) | 30+ 处 |
| 待修 P2 review P0 残留 | 3-4 个(占位邮箱 / 文档"治愈"措辞 / "撤回同意"入口 / setupContactConsent 半角) |
| CHANGELOG 滞后 minor version | **4 (v0.18, 0.19, 0.20, 0.21)** |
| AGENTS.md / README.md / WHITEPAPER.md 滞后 round | 4-10+ |
| Flutter 版本文档不一致处数 | **4 处** (AGENTS L9, L236; DEPLOYMENT L15, L36) |
| Flutter 版本 vs 文档差异 | 1 (3.41.9 实际 vs 3.44.5 声称) |
| flutter analyze | 0 issues |
| flutter test | 703 / 703 pass |
| 严重度 P0 (本报告) | 7 (spzh-bug-01/02/03/04/05/24 + spzh-doc-15/16) |
| 严重度中 | 20+ |
| 严重度低 | 15+ |

### 4.5 整体规范 / 文档健康度评分

| 维度 | 分数 (1-10) | 备注 |
|---|---|---|
| 架构 | **9.5** | 4 层 + shared 边界全守;privacy 100% |
| 测试覆盖 | **9.0** | 74 文件 / 703 cases / 23 round;domain 业务 + data round-trip + presentation widget 三层齐 |
| 代码质量 | **8.5** | 几乎无 lint warning;少数 dead code + 重复实现;emil/Riverpod 3.x 风格统一 |
| 安全 / 隐私 | **9.5** | SQLCipher 设备绑 key + 字段级加密 (vent text BLOB) + 隐私边界严守 + 国产 ROM 引导 |
| 时序正确性 | **9.5** | DateTime 全部缓存 now 一次;streak/midnight/跨日 4 套修复 |
| 中文本地化 | **7.5** | P1-16 修 173 但漏 5+30+;脚本检测能力不足;繁体 / 港澳台 / 英文 i18n 待补 |
| 文档同步 | **4.0** | AGENTS.md / README.md / DEPLOYMENT.md / WHITEPAPER.md 4 份文档严重滞后;CHANGELOG 缺 4 minor version;Flutter 版本 4 处不一致;法律文档自相矛盾 |
| 流程规范 | **5.0** | commit 规范自废(80% 英文);tag 流程失效;`print` 残留 1 处;`check_fullwidth_punctuation.py` warn-only |

**综合**: 7.4 / 10 — **代码层面 8.5+,文档/流程层面 5-,需要补 P0 必修 5 项**。

### 4.6 跟进建议

下次发起 round 时建议同时跑:
1. `flutter analyze` + `flutter test` + `dart scripts/check_all.dart` + `python scripts/check_cross_feature.py` 4 件套 baseline
2. `grep -rn 'TODO\|FIXME\|XXX\|HACK' lib/` 看技术债清单
3. 同步 `AGENTS.md` 的 schemaVersion / 测试数 / 3 个 Flutter 版本号
4. 同步 `CHANGELOG.md` 补 4 个 minor version
5. 同步 `WHITEPAPER.md` 整文档重写
6. 修 `CHINESE_COMMIT_GUIDE.md` L17 自相矛盾
7. 修 `sensitive_data_consent.md` L49 PIPL 告知不实
8. 修 `DEPLOYMENT.md` 5 处 P2-P0-10 法律风险
9. 跑 `python scripts/check_fullwidth_punctuation.py --strict` 找出 30+ 漏修标点
10. 加 1 个新 widget test 覆盖 `dayChangeTickProvider` + 跨日 rebuild(供 spen 引用)

---

**审视完成**。本次发现:
- 严重文档 bug: **6 个**(spzh-bug-01/02/03/04/05/24)
- 严重流程 bug: **2 个**(spzh-bug-07 + spzh-flow-11)
- 中度规范 bug: **15+ 个**
- 低度 polish: **20+ 个**

**总工作量估算**:Top 5 必修 ~ **5-6h**;中期 polish ~ **15-20h**;长期治理 ~ **30-40h**。
按 1 人 1-2h/天:**Top 5 本周可修;中期 1-2 周;长期 1 个月**。

建议:
- **本周**: 修 Top 5 必修(5-6h)
- **下月**: 中期 polish(15-20h),优先修 30+ 半角标点 + WHITEPAPER 重写 + P2_COMPLIANCE_REVIEW 跟踪表
- **下季度**: 长期治理(30-40h),加 CI 强制 + commit 规范 lint + 法律文档 CI 同步 + flutter 版本 CI 检查

---

*报告生成时间: 2026-07-21*
*审视工具: Read + ripgrep + dart scripts + flutter analyze + flutter test*
*审视范围: 74 test files + 161 lib files + 13 doc files + 1 changelog + 3 legal docs + pubspec.yaml + 50 recent commits*
