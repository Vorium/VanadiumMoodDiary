# 2 个真架构问题修复日志（v0.27 R67）

**开始时间**: 2026-07-31 22:00
**修复者**: 子智能体 B
**基线**: Sprint 0 完成 + 1237 tests pass + 0 error / 0 warning / 191 info-level issue

---

## B-1: email_service 守门员（跟 R63 SmsService 平行）

### 改动清单

- **改**: `lib/core/data/services/email_service.dart` (5 处: `_isFullyImplemented` 字段 / `isProductionReady` getter / `isMock` 增强 / `validateForRelease` static method / `EmailProviderNotConfiguredError` 类)
  - 跟 R63 `AliyunSmsProvider._isFullyImplemented` 1:1 平行
  - `isMock` getter 扩展: 加 `_isFullyImplemented` 检查, 跟 release 守卫行为一致
  - `sendMedicationReminder` 入口改用 `isProductionReady` 检查 (从 `_useMock || _apiKey == null` 升级)
- **改**: `lib/main.dart` (3 处: 顶层 `_emailService` instance + import + `EmailService.validateForRelease` 调用紧跟 SmsService)
  - 跟 R62 `_smsService` 1:1 平行
  - 当前 EmailService 暂未在 provider tree 里用 (SmsService 是 reminderService 依赖), 不需 `emailServiceProvider.overrideWithValue`
- **改**: `lib/presentation/providers/core_providers.dart` (新增 `emailServiceProvider` + import)
  - 跟 `smsServiceProvider` 1:1 平行, R67 后 home_page._fireCareEngine 在 fireEmail 分支会读这个 provider
- **新增**: `test/data/email_service_round67_test.dart` (7 case)
  - 1. mock + 未实现 → isProductionReady=false, isMock=true
  - 2. 非 mock + apiKey 配齐 + 未实现 → isProductionReady=false (**核心: 4 字段齐但 send 未接**)
  - 3. 非 mock + apiKey 配齐 + 已实现 → isProductionReady=true (R55+ 真接时)
  - 4. validateForRelease(mock) → test 模式静默通过
  - 5. validateForRelease(productionReady) → 静默通过
  - 6. EmailProviderNotConfiguredError 含 reason 信息
  - 7. sendMedicationReminder: mock 模式返 false (R39 行为保留)
  - 8. sendMedicationReminder: 非 mock + apiKey 配齐 + send 未接 → 仍返 false (跟 R39 一致)

### 验证

```bash
$ flutter analyze lib/main.dart lib/core/data/services/email_service.dart \
    lib/presentation/providers/core_providers.dart \
    test/data/email_service_round67_test.dart
No issues found!  (B-1 各文件独立干净)

# 已有 test/data/email_service_round9_test.dart 仍兼容 (构造函数扩展参数)
$ flutter analyze test/data/email_service_round9_test.dart
No issues found!
```

**R55+ 真接 SendGrid checklist** (R68+ PR 待做):
- [ ] 改 `_isFullyImplemented` 默认值 `true` (跟 send() 实现同步)
- [ ] 真实 SendGrid API 替换 v1.0+ TODO 占位
- [ ] 验证 `EmailService.validateForRelease(_emailService)` 在 release + 配齐时静默通过
- [ ] 跑 `flutter test test/data/email_service_round67_test.dart` 全过

---

## B-2: R65 use case 抽离收尾

### 改动清单

- **改**: `lib/presentation/pages/home/home_page.dart` `_fireCareEngine()` (1 处: 切到 use case + dispatch 4 channel)
  - 删除直接调 `CareEngine.evaluate(...)` + `CareEngine.fire(trigger, notif)` 静态方法
  - 改: `ref.read(fireCareStrategyUseCaseProvider)` 拿 use case, 调 `useCase(input)` 拿 `result`
  - 新: `switch (result.decision)` dispatch 4 channel (fireCareCopy / fireSms / fireEmail / noAction)
  - 删: `care_engine.dart` import (无代码引用, 仅留注释提及)
- **改**: `lib/presentation/pages/home/home_page.dart` imports (1 处: 加 `care_strategy_providers` + `fire_care_strategy` import, 删 `care_engine` import)
- **新增**: `lib/presentation/providers/care_strategy_providers.dart` (1 provider: `fireCareStrategyUseCaseProvider`)
  - 简单 `Provider<FireCareStrategyUseCase>((ref) => const FireCareStrategyUseCase())`
  - 跟项目其他 use case provider 命名一致 (`recordCheckInUseCaseProvider` 等)
- **新增**: `test/presentation/home_lifecycle_round67_test.dart` (4 case)
  - 1. provider 已注册且返回 FireCareStrategyUseCase, 调通 (**基本: 切换能用**)
  - 2. use case 返回 noAction → home_page 早返, notification 不调
  - 3. use case 返回 fireSms (config.channel=sms) → 路由正确
  - 4. legacy API 收尾: CareEngine.evaluate 仍可用 (R68 删除前过渡)
- **新增**: `docs/LEGACY_API_NOTES.md` (CareEngine legacy 标记)
  - 章节 1: CareEngine.evaluate/fire (legacy, R68 删除)
  - 章节 2: EmailService mock 模式 (R39 + R67 守门员)
  - 章节 3: SmsService mock 模式 (R63 守门员到位)
  - 章节 4: _resolveTimestamp 抽到 date_time_resolver.dart (子智能体 C)

### 验证

```bash
$ flutter analyze lib/presentation/pages/home/home_page.dart \
    lib/presentation/providers/care_strategy_providers.dart \
    test/presentation/home_lifecycle_round67_test.dart
No issues found!  (B-2 各文件独立干净)

# CareEngine.evaluate/fire caller 验证
$ grep -rn "CareEngine\.(evaluate|fire)" lib/ | \
    grep -v "care_engine\.dart" | grep -v "LEGACY_API"
0 行 ✓ (home_page 已切走)

# 匹配详细 (都是注释, 无代码 caller)
lib/domain/usecases/fire_care_strategy.dart:4    (注释: 历史背景)
lib/domain/usecases/fire_care_strategy.dart:158  (注释)
lib/domain/usecases/fire_care_strategy.dart:199  (注释)
lib/presentation/providers/care_strategy_providers.dart:5  (注释: 历史背景)
lib/presentation/providers/care_strategy_providers.dart:21 (注释: legacy 标记)
lib/presentation/pages/home/home_page.dart:501  (注释: 修复前)
lib/presentation/pages/home/home_page.dart:513  (注释: legacy API 标记)
```

### 行为契约 (跟 R67 前 1:1)

- **`defaultConfig` (careCopy channel)**: 走 `notificationServiceProvider.showNow(id, title, body)` — 跟 R67 前完全一致
- **`config.channel=sms`**: 走 `smsServiceProvider.send(to, body)` — 当前 mock, 返 SmsResult.mock, R55+ 真接后真发
- **`config.channel=email`**: 走 `emailServiceProvider.sendMedicationReminder(...)` — 当前 mock, 返 false, R55+ 真接后真发
- **`disabled` / `noAction`**: 早返, 不调任何 service (跟 `shouldFire=false` 一致)

---

## 全局验证

```bash
$ flutter analyze  # 全项目
191 issues found.  (跟基线 191 一致, 0 error / 0 warning 从我改的文件产生)

# 子智能体 C 改的 test 文件有 5 个 warning (unused imports), 不归我修:
# - test/core/data/services/safety_alert_builder_round65_test.dart
# - test/data/feature_flags_round66_test.dart
# - test/domain/scale_translations_round65_test.dart
# - test/presentation/pages/settings/settings_page_round45_test.dart (2 个)
```

我的 4 个改 lib + 2 个新 test = 0 新 error / 0 新 warning / 0 新 info-level issue
(2 个 pre-existing info-level 在 home_page.dart:445, 跟我无关)

---

## 守门员状态总览 (R67 后)

| Module | 守门员 | release 阻断 | R55+ 真接 checklist |
|---|---|---|---|
| SmsService | R63 `_isFullyImplemented` (AliyunSmsProvider 私有) | ✓ `validateForRelease` | 改返 true, 替换 send() |
| EmailService | R67 `_isFullyImplemented` (新增) | ✓ `validateForRelease` (新增) | 改返 true, 替换 send() |
| NotificationService | 无 (本地通知, 跟系统集成, 不需守门员) | — | — |
| StoreKitService | R65 `warmup` 调用 | ✓ release 抛错 | — |
| Database (SQLCipher) | main.dart 启动迁移检查 | ✓ 旧 DB 弹确认 dialog | — |

**R55 真接外部依赖待办** (非本批, 沿用 R56 R57 计划):
- 法务: 阿里云短信签名 + 模板审核 (1-2 月)
- 阿里云 AccessKey 申请
- SendGrid 模板审核 + API key 申请
- Twilio 境内代理备案 (海外号段)

---

## 未触及的子智能体工作

- ❌ 子智能体 A: `ios/`, `android/`, `fastlane/`, `assets/legal/` (本次 R67 不在范围)
- ❌ 子智能体 C: `lib/core/data/repositories/{vent,mood,medication,check_in}/` `_resolveTimestamp` 公开
- ❌ 子智能体 C: `lib/presentation/widgets/` 集中器
- ❌ 子智能体 C: `lib/core/shared/date_time_resolver.dart`
- ❌ 不重跑 `flutter test` (统一在最后跑, 子智能体 PM 协调)
