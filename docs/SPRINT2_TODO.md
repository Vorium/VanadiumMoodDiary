# Sprint 2 待办集中索引（v0.27 R77 引入）

> **背景 (R76 报告 P3-7)**: 5+ 个真接大工程已分散在 3 doc
> (`SMS_PROVIDERS.md` / `LEGACY_API_NOTES.md` / `SPRINT1_LEGAL_TODO.md` /
> `VERSION_1.0_PLAN.md`), R77 集中索引让 reviewer 一次找到。
>
> **R77 决策**: 不重复内容, 只做集中索引 + 进度摘要 + 链接。
> 详细 TODO 仍保留在各自 doc 维护, 本文件作为 "总览 + 优先级 + 估时"。

## 0. Sprint 1 (R67) 待办 (用户侧)

详见 [`docs/SPRINT1_LEGAL_TODO.md`](SPRINT1_LEGAL_TODO.md)。

| 序号 | 任务 | 估时 | 状态 | 阻塞 |
|---|---|---|---|---|
| 1.1 | 律师 review 3 份 md (privacy / user_agreement / sensitive_data_consent) | 1-2 周 + ¥45-90k | **未做** | R77-S2-1 |
| 1.2 | 邮箱 `support@chroniccare.app` 注册 | 1-2h | **未做** | — |
| 1.3 | GitHub 仓库 `github.com/example/chroniccare` 替换 | 半天 | **未做** | — |
| 1.4 | 域名 `chroniccare.app` 注册 + HTTPS 部署 3 份 md | 1-2 天 | **未做** | — |

**Sprint 1 上架必须** 4 项, R77 后 0 改善 (用户侧操作)。

## 1. Sprint 2 (R77) 我侧 半成品 + 跨 round 大工程

### 1.1 PHQ-9 / GAD-7 16 题全文 i18n 化 (R76 P0, 跨 round XL)

- **当前状态**: R65 起步, scale_translations.dart abstract class 抽离,
  Phq9Scale.translations 字段注入, 21 case crisis test 通过。
- **未做**: 16 题题目 + 5 档严重度 + 4 档选项 (0-3) + 2 instruction 全文
  i18n 化, 70+ ARB key × 3 语 = 210 key。
- **估时**: 1-2 round (8-16h)
- **影响**: en / zh_Hant 用户做 PHQ-9 / GAD-7 看到中文题目, **医疗法律责任**。
- **优先级**: P0 (上架 blocker, 但 v1.0 前非 blocker)
- **详情**: R74 P0-1 (P1-A 起步) → R65 抽 abstract → R77 P0-17 收尾 hotline
  i18n (tw/sg/uk) 但 16 题未做。

### 1.2 package_info_plus 引入 + _kLegalVersion 自动读 pubspec (R76 P1-6)

- **当前状态**: R77-13 抽 `core/shared/legal_version.dart` + provider,
  const `kPubspecVersion` 跟 pubspec.yaml 同步 (手动)。
- **未做**: 加 `package_info_plus` 依赖, 启动时 `PackageInfo.fromPlatform()` 读
  pubspec.yaml.version, 删除 const + 手动同步。
- **估时**: 4-6h (加 plugin + 改 main.dart 启动顺序 + iOS pod install + Android gradle sync)
- **风险**: iOS Podfile / Android gradle 改, 需用户 macOS 跑 `pod install`。
- **优先级**: P1 (R77 已落 const 折中, R78 升级)
- **详情**: 见 `lib/core/shared/legal_version.dart` 顶部 TODO。

### 1.3 SMS 真接阿里云 (R55 起步, 法务 + AccessKey 依赖)

- **当前状态**: SmsService fail-fast 守门员 + placeholder 占位 (R75 改 throw StateError)。
- **未做**: 法务 1-2 月模板审核 + 阿里云 AccessKey 申请 + SMS API 集成。
- **估时**: 1-2 月 (法务阻塞)
- **优先级**: P0 (上架 blocker, 但 v1.0 前非 blocker)
- **详情**: `docs/SMS_PROVIDERS.md` 完整 TODO + 阿里云 API 文档链接。

### 1.4 Email 真接 SendGrid (R55 起步, AccessKey 依赖)

- **当前状态**: EmailService 类似 SmsService, R75 改 throw StateError。
- **未做**: SendGrid API key 申请 + 模板审核 + 集成。
- **估时**: 1-2 周 (法务模板完成后)
- **优先级**: P0 (上架 blocker, 跟 SMS 平行)
- **详情**: `docs/SENDGRID_SETUP.md` 完整 TODO。

### 1.5 iOS Podfile + Podfile.lock 真实生成 (R77 占位)

- **当前状态**: R77-8 占位 Podfile 写好, .gitignore 加 exception 跟踪 Podfile。
- **未做**: macOS 跑 `cd ios && pod install` 生成 Podfile.lock, 删 .gitignore
  exception 让 Podfile.lock 正常被 .gitignore 忽略。
- **估时**: 0.5h (用户 macOS 操作)
- **优先级**: P1 (iOS 真 build 必须, R77-8 占位注释说明)

## 2. R77 修复循环后剩余 (P1 架构 / 重构)

### 2.1 home_page god class 抽 3 helper (R76 P3-1)

- **当前**: home_page.dart 678 行 (R76 增 47), R74 报告 P3-1 评估至今 0 改善。
- **目标**: 抽 `HomeDeepLinkHandler` / `HomeCareEngineDispatcher` / `HomeCelebrationController`
  3 helper, 减到 ~450 行。
- **估时**: 1-2h
- **风险**: home_page 含 deep link + CareEngine + safety watch + 庆祝 overlay,
  拆完需要 10+ integration test 保护 (R76 P3-5)。
- **优先级**: P3 (NIT, 跟 R78 home_page 集成测一起做更稳)

### 2.2 mood_audio_section 591 行 god class 评估 (R76 新发现)

- **当前**: mood_audio_section.dart 591 行 (R76 新最大 god class 候选,
  R74 报 mood_dialog 1204 行有误, 实际 R64 已拆)。
- **目标**: 拆 3 sub-widget (AudioRecorderSection + AudioPlayerSection +
  RecordControlsSection), 减到 ~300 行。
- **估时**: 2-3h
- **优先级**: P3 (NIT)

### 2.3 vent_compose dispose 异步未 await (R74 P2-1 → R75 → R76 → R77 仍未修)

- **当前**: vent_compose_page dispose 时 `await _recorder.stop()` / `_player.dispose()`
  不 await, 可能资源泄漏。
- **目标**: 用 `unawaited` 标注 + 加资源释放顺序的 regression test。
- **估时**: 0.5-1h
- **优先级**: P2 (R74 报告 3 轮未修, R77 紧急)

### 2.4 notification_service const 改 final 风险大 (R77-10 partial 1/5)

- **当前**: R77-10 partial 改了 4 处 const 通知 channel, snooze_manager 1/5 处改 l10n 化。
- **未做**: 4 处 const (notification_service.dart) 改 final + 构造函数接受 l10n 函数。
- **估时**: 4-6h
- **风险**: 4 处 const 改 final + 6 caller + init 顺序大改, 需要 10+ test。
- **优先级**: P2 (跟 R78 一起)

### 2.5 setup_page wizard 4 step 内部 state 化 (R76 P3-2 完整版)

- **当前**: R77-18 写 7 case 集成测, 但 setup_page 仍 501 行 4 step facade。
- **未做**: 4 step 改 ConsumerStatefulWidget 内部管 state, setup_page 退化为
  stepper orchestrator ~250 行。
- **估时**: 4-6h (controller lift + state 共享设计)
- **优先级**: P3 (R77 集成测已保, 留给 R78)

### 2.6 badge_sync_service catch (e) 加 swallowError 包装 (R76 P3-3)

- **当前**: 唯一用 `catch (e)` 但 0 `swallowError(where, error, stack)` 包装。
- **目标**: 改 `catch (e, st) { swallowError(...); }`。
- **估时**: 10min
- **优先级**: P3 (NIT)

## 3. 集成测 18 case (R76 P3-5) — 部分完成

- ✅ R77-18 完成 setup_page 7 case (4 step 状态机 + 跳过 + 返回 + 重置)
- ❌ home_page 集成测 10 case (deep link + CareEngine + 庆祝 overlay)
- ❌ vent_compose dispose 异步未 await regression test
- ❌ export_orchestrator export + import 集成测 5 case (R77 拆完 2 file
  后更适合写, R78+ 一起)

## 4. R78+ Sprint 1+2 路线图

```
Sprint 1 (R67-R77): P0/P1 清零 25 项 (上架/架构/重构/半成品)
  - 病耻感 5 + i18n 3 + 错字 1 + PIPL 4 + 临床精度 1 + iOS 3 + 架构 6 + 重构 4
  - 全部走 commit 落地, 16 守护脚本全绿

Sprint 2 (R78+): 半成品收尾 + 上架资源
  - 1.1 PHQ-9 16 题 i18n (XL, 8-16h)
  - 1.2 package_info_plus (4-6h, 需 macOS)
  - 2.1 home_page 抽 3 helper (1-2h)
  - 2.3 vent_compose dispose 修 (0.5-1h)
  - 2.4 notification_service const 改 final (4-6h)
  - 2.6 badge_sync swallowError (10min)
  - 3.1 home_page 集成测 10 case (2-3h)
  - 3.3 export_orchestrator 集成测 5 case (2-3h)

Sprint 3 (v1.0 上架):
  - 用户侧: 4 项 Sprint 1 (律师 + 邮箱 + 仓库 + 域名) + 1.3 SMS 真接 + 1.4 Email 真接
  - 我侧: 1.5 iOS Podfile 真生成 (0.5h)
```

## 5. 维护

- **R77 引入**: 本文件作为 "我侧 + 用户侧 集中索引"
- **更新触发**: 每 round audit 后更新进度 + 估时
- **不重复**: 详细 TODO 仍维护在各自 doc (SPRINT1_LEGAL / SMS_PROVIDERS /
  LEGACY_API_NOTES / VERSION_1.0_PLAN), 本文件只做"找得到 + 优先级清楚"
