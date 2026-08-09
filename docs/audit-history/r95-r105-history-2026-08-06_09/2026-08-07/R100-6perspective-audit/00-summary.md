# R100 六视角整合审计总报告（v0.30.0+85）

**审计时间**: 2026-08-07 | **基线**: HEAD `f0dcaa6` + 工作区未提交改动（R92-R99 修复堆积）
**6 视角**: /emilkowalski（01）/ /superpowers-en（02）/ /superpowers-zh（03）/ AppStore（04）/ GooglePlay（05）/ /flutter-specification（06）
**方法**: 全部实测，非引用旧报告 —— 17 守护脚本 + `dart scripts/check_all.dart` + `flutter analyze` + `scripts/_audit_v2.py` + 关键发现逐条源码复核
**日志留档**: `reports/r100/*.log`

---

## 一、实测结果速览

| 检查 | 结果 |
|---|---|
| `check_all.dart` 4 层纯度 + 一致性 | ✅ |
| `flutter analyze` | ✅ No issues found |
| ARB 三语 1068 key 同步 / orphan 0 / OpenCC s2tw 100% | ✅ |
| `check_cross_feature` 118 files / datetime race / widget dispose / legal consent / sms release | ✅ 全绿 |
| `check_16kb_alignment` | ✅（WARN: ndkVersion 未显式声明） |
| `check_fullwidth_punctuation` | ⚠️ 132 warn（warn-only，多为生成文件） |
| `_audit_v2.py` | 🔴 硬编码中文 336 处（UI 必修 ~30）；法务文件缺口；metadata 占位 |
| R99 报的 BUG-1~5 | ✅ 全部复核闭环（见 02 报告） |

---

## 二、五项要求逐项答复

### 1️⃣ 需要外部链接的内容是否已全部隐藏？—— **代码层 ✅ 全部隐藏；上架物料层 ❌ 未就绪**

| 层 | 状态 | 证据 |
|---|---|---|
| lib/ 代码 | ✅ 0 真实外链跳转 | 全库扫描：唯一 url_launcher 调用 = `tel:` 危机热线（crisis_hotline_page.dart:238）；其余 https 命中全在注释 |
| 邮箱 / GitHub 联系方式 | ✅ 软隐藏 | 无 mailto、不可点击；但法务文档残留 9 处"软隐藏 `xxx@chroniccare.app`"**说明文字**（见 Z-10） |
| 半成品功能入口 | ✅ 8 个 FeatureFlags 全 false，编译期锁定，UI 不可见 | feature_flags.dart:48-69 |
| fastlane 上架物料 | ❌ | privacy_url / support_url 指向**未注册域名** chroniccare.app（iOS 3 语 6 文件）；video.txt = YouTube PLACEHOLDER（Android 2 文件） |

### 2️⃣ 上架 / 架构 / 重构建议 / 半成品问题 —— 见 §三 总表

- **上架**：双平台截图占位（必拒）、iOS 后台模式声明风险、域名未注册、keystore 未生成。
- **架构**：4+1 层架构保留（9/10），8 项内聚/耦合优化点（F-1~F-8）。
- **半成品**：8 项 FeatureFlags 骨架（SMS 90% / Email 90% / IAP 70% / push 50% / BootReceiver 30% / ventAudio 80% / PHQ-GAD i18n 低 / 联系人隐藏）全部隐藏到位，metadata 文案仍承诺"失联通知规划中"需删。

### 3️⃣ 顶层架构审视 —— **不建议换架构**（详见 06 报告 §二）

当前规模（2019 tests / 13+ 表 / 9 repo）下 4+1 层 + Riverpod 3 + go_router + Drift 是最优解；迁移 BLoC/CA 收益为负。重构重点放在 **home_page_state 拆分（F-1）**、**SafetyCheckResult API 收敛（F-2）**、services/ 分组（F-5）、usecase 补全（F-6）。

### 4️⃣ 底层逐行排查 —— R99 的 5 个 BUG 全部闭环，本轮无新增功能级 bug（详见 06 报告 §三）

残留为优化项而非 bug：a11y 覆盖、golden test、trailing comma、半角标点、工程垃圾文件。

### 5️⃣ 需求文档 —— 已同步更新 `docs/VERSION_1.0_PLAN.md`（R100 章节）+ 本目录 7 份报告落盘

---

## 三、总问题清单（按修复优先级排序，标注 架构/底层 × 难度）

### P0 — 不做必被拒 / 有真实损失（8 项）

| # | 问题 | 视角 | 层级 | 难度 |
|---|---|---|---|---|
| 1 | [N-9] ~280 文件未提交改动分批 commit（防丢失，一切修复的前提） | sp-en | 底层 | 简单 |
| 2 | [A-2/S-1] 注册 chroniccare.app 域名 + 隐私/支持/数据删除静态页（iOS 6 文件 + Play Data Safety 依赖） | AppStore/GPlay | 底层 | 中 |
| 3 | [G-1/A-1] 双平台真实截图 + feature graphic（Android 67B 占位 PNG ×10；iOS screenshots/ 缺失） | GPlay/AppStore | 底层 | 中 |
| 4 | [G-2] 删 video.txt PLACEHOLDER（Android 2 文件） | GPlay | 底层 | 简单 |
| 5 | [G-3] 生成 release keystore + key.properties | GPlay | 底层 | 简单 |
| 6 | [A-3] 删 UIBackgroundModes audio+processing + BGTaskScheduler 声明（业务未启用，Apple 2.5.4 拒因） | AppStore | 底层 | 简单 |
| 7 | [A-5] user_agreement "8 元买断" 段改"未来版本"表述或真接 IAP（二选一） | AppStore | 底层 | 简单 |
| 8 | [G-4/A-6] metadata title/subtitle 删 "(失联通知规划中)"（Android title + iOS zh-Hans/Hant subtitle） | GPlay/AppStore | 底层 | 简单 |

### P1 — 高概率被打回 / 用户可见缺陷（7 项）

| # | 问题 | 视角 | 层级 | 难度 |
|---|---|---|---|---|
| 9 | [Z-1~Z-7] UI 硬编码中文 ~30 处走 ARB（en locale 可见，约 +40 key × 3 语） | sp-zh | 底层 | 中 |
| 10 | [A-4] InfoPlist.strings 补 5 项 usage description 英文基线 + zh 覆盖（现为纯中文） | AppStore | 底层 | 简单 |
| 11 | [F-2] 删 `SafetyCheckResult.displayMessage` 旧 getter，编译期强制走 l10n 版 | flutter-spec | 架构 | 简单 |
| 12 | [F-3/N-3] 3 个 StreamProvider 加 autoDispose（ventSealed/ventSealedAt/allAssessmentEntries） | flutter-spec | 架构 | 简单 |
| 13 | [F-4/N-2] 删 CareEngine.evaluate/fire legacy 死代码 | flutter-spec | 架构 | 简单 |
| 14 | [Z-10] 法务文档 9 处软隐藏说明文字去掉占位域名残留 | sp-zh | 底层 | 简单 |
| 15 | [N-1] 清理 repo 根 80+ 临时垃圾文件（_*.py / test_*.txt / _trash_*） | sp-en | 底层 | 简单 |

### P2 — 质量提升，上架后跟进（12 项）

| # | 问题 | 视角 | 层级 | 难度 |
|---|---|---|---|---|
| 16 | [F-1] home_page_state 656 行拆 HomeSafetyCoordinator（3 职责分离） | flutter-spec | 架构 | 复杂 |
| 17 | [法务] user_agreement 补 7 项 / sensitive_data_consent 补 3 项 PIPL 条款（仅中国区需要） | sp-zh | 底层 | 中 |
| 18 | [E-1] a11y Semantics 补齐核心交互件（CheckInButton / MoodQuickButton / vent swipe 等） | emil | 底层 | 中 |
| 19 | [N-4] 其余大文件拆分（setup_page_state 535 / vent_compose 512 / main 500 / legal_page 494 / notification_service 480） | sp-en | 架构 | 复杂 |
| 20 | [F-5] services/ 31 平铺文件按 notify/safety/pdf/audio 分子目录 | flutter-spec | 架构 | 中 |
| 21 | [F-6] 跨 repo 编排补 usecase（home / medication 优先） | flutter-spec | 架构 | 中 |
| 22 | [E-3/F-7] app_colors 迁 ThemeExtension + ThemeModeNotifier 迁 AsyncNotifier | emil/flutter-spec | 架构 | 复杂 |
| 23 | [Z-8] ARB 半角标点 58 key × 2 语批量全角化 | sp-zh | 底层 | 简单 |
| 24 | [E-2] golden test 基建（核心 widget 视觉回归） | emil | 底层 | 中 |
| 25 | [F-8] routerProvider cache 迁 NotifierProvider | flutter-spec | 架构 | 中 |
| 26 | [N-8] import 顺序 4 文件 + test trailing comma 104 处 + fullwidth 脚本豁免 generated | sp-en/flutter-spec | 底层 | 简单 |
| 27 | [G-8] build.gradle.kts 显式 pin ndkVersion | GPlay | 底层 | 简单 |

**统计**：P0=8 / P1=7 / P2=12；架构级=8 项（F-1~F-8 映射的 #11~13,16,19~22,25）/ 底层实现级=19 项；简单=15 / 中等=9 / 复杂=3。

---

## 四、执行顺序建议

1. **今天**：#1 commit 落地 → #4 删 video.txt → #8 删"规划中"文案 → #6 删后台声明（纯删减，零风险）。
2. **本周**：#2 域名注册（阻塞 #5 表单、#14 文案终稿）；#3 真机截图；#9~#13 代码修复一批 commit。
3. **提审前**：#5 keystore；#7 IAP 表述；#10 InfoPlist.strings。
4. **上架后**：P2 按 round 排期（参考 VERSION_1.0_PLAN R100 章节）。
