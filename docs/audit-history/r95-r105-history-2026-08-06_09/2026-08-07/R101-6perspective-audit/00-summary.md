# R101 六视角整合审计总报告（v0.30.0+85）

**审计时间**: 2026-08-07 | **基线**: R100 后最新工作区
**6 视角**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification
**方法**: 6 个 agent 并行深度扫描全部 lib/ + test/ + docs/ + android/ + ios/ 文件，非引用旧报告

---

## 一、外部链接隐藏确认

| 检查项 | 状态 | 证据 |
|--------|------|------|
| lib/ 代码中真实外链跳转 | ✅ 全部隐藏 | 唯一 url_launcher = `tel:` 危机热线；其余 https 全在注释/sms_service 空壳 |
| 邮箱/GitHub 联系方式 | ✅ 软隐藏 | 无 mailto，不可点击；法务文档残留 9 处占位域名说明文字 |
| 半成品功能入口 | ✅ 8 个 FeatureFlags 全 false | feature_flags.dart:48-69，编译期锁定 |
| fastlane 上架物料 URL | ❌ 未就绪 | privacy_url / support_url 指向未注册 chroniccare.app；video.txt = PLACEHOLDER |
| **结论** | **代码层 ✅ 全隐藏；上架物料层 ❌ 未就绪** | — |

---

## 二、六视角评分总览

| 视角 | 评分 | 关键发现数 | 最高优先 |
|------|------|-----------|----------|
| emilkowalski (UI/UX) | 8.5/10 | 38 (P0=3, P1=12, P2=15, P3=8) | hero shadow dark mode 不可见 |
| superpowers-en (工程) | 9.0/10 | 26 (P0=3, P1=5, P2=12, P3=6) | check_all.dart 守护脚本 bug |
| superpowers-zh (中文/合规) | 8.0/10 | 14 (P0=1, P1=4, P2=5, P3=4) | SMS 未接入 = 核心安全空壳 |
| AppStore (iOS) | 6.5/10 | 26 (REJECT=5, LIKELY=5, WARN=8) | 隐私政策 URL 404 |
| GooglePlay (Android) | 4.0/10 | 18 (REJECT=5, LIKELY=5, WARN=8) | RECORD_AUDIO 权限残留 |
| flutter-spec (规范) | 88% | 22 (P0=3, P1=7, P2=7, P3=5) | dart format 149 文件不一致 |

---

## 三、统一问题清单（按修复优先级排序，去重合并）

### P0 — 阻塞发布 / 必修（12 项）

| # | 问题 | 视角 | 层级 | 难度 | 估时 |
|---|------|------|------|------|------|
| 1 | **~280 文件未提交改动分批 commit** | sp-en | 底层 | 简单 | 1-2h |
| 2 | **注册 chroniccare.app 域名 + 部署隐私/支持/数据删除页** (iOS 6 URL + Play Data Safety) | App/GPlay | 底层 | 中 | 1-2d + 部署 |
| 3 | **双平台真实截图 + feature graphic** (Android 占位 PNG ×10, iOS 0 张) | App/GPlay | 底层 | 中 | 1-2d |
| 4 | **删 video.txt PLACEHOLDER ×2** (Android) | GPlay | 底层 | 简单 | 10min |
| 5 | **生成 release keystore + key.properties** | GPlay | 底层 | 简单 | 30min |
| 6 | **删 iOS UIBackgroundModes audio+processing + BGTaskScheduler** (Apple 2.5.4 拒因) | AppStore | 底层 | 简单 | 10min |
| 7 | **user_agreement "8 元买断" → "未来版本" 或真接 IAP** (Apple 3.1.1) | AppStore | 底层 | 简单 | 30min |
| 8 | **metadata 删 "(失联通知规划中)"** (Android title + iOS subtitle) | App/GPlay | 底层 | 简单 | 10min |
| 9 | **`record`/`speech_to_text` 插件合并 RECORD_AUDIO 权限** → 加 `tools:node="remove"` | GPlay | 底层 | 简单 | 15min |
| 10 | **法律文件"草稿"标注删除** (privacy/user_agreement/sensitive 三份 md 修订历史) | GPlay | 底层 | 简单 | 30min |
| 11 | **隐私政策联系方式补充** (§9 + §8 "本服务不提供邮件" → 真实邮箱) | App/GPlay | 底层 | 简单 | 1h |
| 12 | **SCHEDULE_EXACT_ALARM 运行时权限检查** (Android 12+ 用户可关闭 → SecurityException → crash) | GPlay | 底层 | 中 | 2-3d |

### P1 — 高概率打回 / 用户可见缺陷（15 项）

| # | 问题 | 视角 | 层级 | 难度 | 估时 |
|---|------|------|------|------|------|
| 13 | **8 个新量表硬编码中文** (ASRM/ISI/PSS/WHODAS/Level2 ×4, en/zh_Hant 用户看到中文) | sp-zh | 底层 | 高 | 1-2 周 |
| 14 | **care_copy.dart 关怀文案硬编码中文** (4 种关怀触发 title+body 未走 i18n) | sp-zh | 底层 | 中 | 2-3d |
| 15 | **安全警报通知锁屏暴露敏感健康信息** (importance:max + "已 X 天未打卡吃药") | sp-zh | 底层 | 中 | 2-3d |
| 16 | **邮件通知向紧急联系人暴露药名+剂量** (SMS 已修 R74, 邮件未同步) | sp-zh | 底层 | 简单 | 1h |
| 17 | **Dynamic Type 完全不支持** (所有字号硬编码 const, Apple 2.5.1 拒因) | AppStore | 架构 | 高 | 1-2 周 |
| 18 | **医疗免责声明不够显著** (仅设置页底部, Apple 1.4.1 要求首次启动展示) | AppStore | 底层 | 中 | 2-3d |
| 19 | **App Store 描述宣传 "coming soon" 功能** (Apple 2.3.3 禁止宣传不可用功能) | AppStore | 底层 | 简单 | 30min |
| 20 | **PHQ-9/GAD-7 i18n 未完成但描述宣传** (feature_flag=false, 英文用户看中文题) | App/GPlay | 底层 | 高 | 1-2 周 |
| 21 | **开发者联系方式缺失** (App 内无邮箱, Apple/Google 强制要求) | App/GPlay | 底层 | 简单 | 1h |
| 22 | **check_all.dart 守护脚本 bug** (domain→core/data/ 违规被静默忽略) | sp-en | 架构 | 简单 | 30min |
| 23 | **domain vent_repository.dart 导入 data 层 VentAudioStorage** (架构违规) | sp-en | 架构 | 简单 | 15min |
| 24 | **domain safety_detector.dart 导入 data 层 SafetyCheckKind** (架构违规) | sp-en | 架构 | 简单 | 1h |
| 25 | **cbt_thought_record_pdf.dart 导入 flutter/material.dart** (data 层零 flutter) | sp-en | 架构 | 简单 | 30min |
| 26 | **UI 硬编码中文 ~30 处走 ARB** (en locale 可见, ~+40 key × 3 语) | sp-zh | 底层 | 中 | 1 周 |
| 27 | **dart format 149 文件不一致** (CI 阻断级) | flutter-spec | 底层 | 简单 | 30min |

### P2 — 质量提升 / 上架后跟进（20 项）

| # | 问题 | 视角 | 层级 | 难度 | 估时 |
|---|------|------|------|------|------|
| 28 | home_page_state 656 行 → HomeSafetyCoordinator 拆分 | sp-en/flutter | 架构 | 复杂 | 1-2 周 |
| 29 | hero_illustration.dart:52 Colors.black 硬编码 dark mode 阴影不可见 | emil | 底层 | 简单 | 15min |
| 30 | 4 处 emoji fontSize 硬编码 magic number (hero_illustration.dart) | emil | 底层 | 简单 | 30min |
| 31 | quick_mood_carousel.dart 注释说走 Haptics.success 但实际未调用 | emil | 底层 | 简单 | 10min |
| 32 | vent_detail_page.dart Slider 缺语义标签 (a11y) | emil | 底层 | 简单 | 15min |
| 33 | TextTheme 缺 headlineSmall/titleMedium/bodySmall/labelSmall | emil | 底层 | 中 | 1h |
| 34 | 7 个 data 层文件导入 l10n/app_localizations.dart (架构软耦合) | sp-en | 架构 | 中 | 2-3d |
| 35 | catch(e) 无类型区分 — 9 处裸 catch | sp-en | 底层 | 中 | 1-2d |
| 36 | swallowError release 模式完全静默 (无 log/无 crash reporter) | sp-en | 架构 | 中 | 1-2d |
| 37 | SQLCipher PRAGMA key 字符串拼接 (虽 base64 无特殊字符) | sp-zh | 底层 | 简单 | 1h |
| 38 | 数据导出明文暴露树洞加密内容 | sp-zh | 底层 | 中 | 1-2d |
| 39 | SQLite ALTER TABLE DROP COLUMN 兼容性 (老 Android 设备) | sp-zh | 底层 | 中 | 1-2d |
| 40 | 通知 Channel 名称硬编码中文 (Android 设置页) | sp-zh | 底层 | 中 | 2-3d |
| 41 | Podfile.lock 缺失 (iOS 构建 reproducibility) | AppStore | 底层 | 简单 | 30min (需 Mac) |
| 42 | Podfile platform :ios 13.0 vs pbxproj 14.0 不一致 | AppStore | 底层 | 简单 | 5min |
| 43 | NSUserTrackingUsageDescription 声明但无 ATT 弹窗 | AppStore | 底层 | 简单 | 30min |
| 44 | shared_providers.dart 反向 import (providers → pages) | flutter-spec | 架构 | 简单 | 30min |
| 45 | check_in_entity.dart labelL10n 硬编码中文 fallback | flutter-spec | 底层 | 简单 | 1h |
| 46 | streakSummaryProvider 内 DateTime.now() 未 watch dayChangeTickProvider | flutter-spec | 底层 | 简单 | 30min |
| 47 | todayProvider 返回 DateTime.now() 非 tz.TZDateTime | flutter-spec | 底层 | 中 | 1-2d |

### P3 — Nice-to-have / 技术债（18 项）

| # | 问题 | 视角 | 层级 | 难度 |
|---|------|------|------|------|
| 48 | setup_step_done.dart 6 处 Text(l10n.xxx) 缺 TextStyle | emil | 底层 | 简单 |
| 49 | medication_calendar_page.dart 构造 SnackBar 绕过 AppSnackBar 集中器 | emil | 底层 | 简单 |
| 50 | setup_step_medication.dart hintText '40' 硬编码 | emil | 底层 | 简单 |
| 51 | contacts_list_widget.dart hintText '13800138000' 硬编码 | emil | 底层 | 简单 |
| 52 | check_in_button 打卡成功无庆祝微弹效果 | emil | 底层 | 简单 |
| 53 | home_fab_toolbar FAB width/height: 56 硬编码 | emil | 底层 | 简单 |
| 54 | vent_compose_page 无 maxLength 视觉指示 | emil | 底层 | 简单 |
| 55 | setup_page 4 步 wizard 无进度指示器 | emil | 底层 | 简单 |
| 56 | 多处缺失 Haptic 反馈 (calendar cell / view toggle / assessment 选项) | emil | 底层 | 简单 |
| 57 | AppTokens facade 306 行纯转发过重 | sp-en | 架构 | 中 |
| 58 | check_in_dao.dart:62 DAO 层调 DateTime.now() | sp-en | 底层 | 简单 |
| 59 | VentEntryEntity.durationLabel() 硬编码中文 fallback (旧方法未删) | sp-en | 底层 | 简单 |
| 60 | AliyunSmsProvider.send() 抛 StateError 而非 UnimplementedError | sp-en | 底层 | 简单 |
| 61 | 中国节假日模块硬编码中文 (不直接展示, 影响有限) | sp-zh | 底层 | 低 |
| 62 | LoadingScrim 返回 Positioned.fill 但非 Stack 子级时行为未定义 | flutter | 底层 | 简单 |
| 63 | var 使用不一致 24 处 (应改 final) | flutter | 底层 | 简单 |
| 64 | .g.dart 8557 行已 commit (确认 CI 有 build_runner 步骤) | flutter | 底层 | 简单 |
| 65 | AppTokens 中 4 个 size 常量未放 AppSpacing 子模块 | flutter | 底层 | 简单 |

---

## 四、架构审视结论

### 4.1 是否需要换架构？

**结论: 不需要。** 当前 4+1 层 (data/shared/theme/routing/l10n → domain → presentation) + Riverpod 3 + go_router + Drift(SQLCipher) 在 2019 tests / 13+ 表 / 9 repo 规模下是最优解。迁移 BLoC/GetX 收益为负。

### 4.2 架构违规 (需修复)

| # | 违规 | 文件 | 修复方案 |
|---|------|------|----------|
| 1 | check_all.dart 守护脚本 bug | scripts/check_all.dart:231 | 加 `core/data/` case |
| 2 | domain→data (VentAudioStorage) | domain/repositories/vent_repository.dart:6 | 删 import |
| 3 | domain→data (SafetyCheckKind) | domain/logic/safety_detector.dart:49 | 枚举移到 domain |
| 4 | data→flutter (material.dart) | data/services/cbt_thought_record_pdf.dart:15 | DateTimeRange 改自定义类 |
| 5 | providers→pages (反向 import) | presentation/providers/shared_providers.dart:1 | TodayMedSchedule 移 widgets/ |
| 6 | data 层 7 文件导入 l10n | 多个 service 文件 | 改用 domain 层 Strings |

### 4.3 建议重构模块

| 模块 | 当前状态 | 建议 | 难度 |
|------|----------|------|------|
| home_page_state | 656 行 god class | 拆 HomeSafetyCoordinator + DeepLinkHandler + CelebrationManager | 复杂 |
| services/ | 31 文件平铺 | 按 notify/safety/pdf/audio 分子目录 | 中 |
| SafetyCheckKind/Result | 放 data 层 | 移到 domain/entities/ | 简单 |
| ThemeExtension | 未使用 | app_colors 迁 ThemeExtension | 复杂 |
| routerProvider | Provider cache | 迁 NotifierProvider | 中 |

---

## 五、半成品 / TODO 清单

| 文件 | 内容 | 阻塞项 | 当前状态 |
|------|------|--------|----------|
| sms_service.dart:91-201 | AliyunSmsProvider.send() 空壳 | 法务模板审核 + AccessKey | UI 不可见 (FeatureFlag=false) |
| email_service.dart:162 | 真实邮件发送未实现 | API key | UI 不可见 |
| scale_registry.dart:40-42 | NSESSS/CRDPSS 量表接入 | 法务审核 | UI 不可见 |
| store_kit_service.dart:117 | buyLifetime() return false | IAP 配置 | UI 不可见 |
| BootReceiver.kt | 43 行半成品 | WorkManager 参考 | 未注册, 不触发 |
| user_agreement.md:22 | "计划定价 8 元" | IAP 真接 | **用户可见** ⚠️ |

---

## 六、修复执行顺序建议

### 今天 (1-2h, 纯删减零风险)
1. #1 commit 落地 (280 文件)
2. #4 删 video.txt
3. #8 删"规划中"文案
4. #6 删 iOS 后台声明
5. #9 加 RECORD_AUDIO tools:node="remove"
6. #27 dart format

### 本周 (需决策)
7. #2 域名注册 (阻塞多项)
8. #3 真机截图
9. #7 IAP 表述修改
10. #10 法律文件删"草稿"
11. #11 邮箱注册
12. #22-25 架构违规修复

### 提审前
13. #5 keystore
14. #12 SCHEDULE_EXACT_ALARM 权限检查
15. #18 医疗免责声明 (setup 流程加)
16. #19 删 coming soon
17. #26 UI 硬编码中文 → ARB
18. #15-16 通知隐私 + 邮件隐私

### 上架后
19. #13-14 量表 i18n + care_copy i18n
20. #17 Dynamic Type
21. #20 PHQ-9/GAD-7 i18n
22. #28+ 架构重构

---

## 七、统计汇总

| 优先级 | 数量 | 架构级 | 底层级 | 简单 | 中等 | 复杂 |
|--------|------|--------|--------|------|------|------|
| **P0** | 12 | 0 | 12 | 9 | 3 | 0 |
| **P1** | 15 | 4 | 11 | 8 | 4 | 3 |
| **P2** | 20 | 4 | 16 | 10 | 8 | 2 |
| **P3** | 18 | 3 | 15 | 15 | 3 | 0 |
| **总计** | **65** | **11** | **54** | **42** | **18** | **5** |

**核心结论**: 
- 代码质量/架构/测试在国内中型项目中处于天花板水平 (2019 tests, 18 守门员, 0 analyzer error)
- 上架真正阻塞是**外部资源**: 域名/截图/keystore/IAP 决策/法务/5 厂商审核
- 本轮新发现 65 项 (vs R100 的 27 项), 主要增量来自 emilkowalski 视角 (38 项 UI polish) 和 AppStore/GooglePlay 合规细节
- **可代码化修复: 54/65 (83%)**, 其中简单难度 42/65 (65%) 可 1-2 天内批量修完
