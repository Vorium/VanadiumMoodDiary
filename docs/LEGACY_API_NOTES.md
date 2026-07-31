# Legacy API Notes (v0.27 R67 收尾)

**建立时间**: 2026-07-31
**目的**: 集中记录 `domain/logic/` 老 API 状态, 标记"还能用但不再推荐" / "v0.28 删除" 计划。
**维护**: 每次 domain/logic 抽 use case 或 refactor 时, 在本文档加 / 删条目。

---

## 1. `CareEngine.evaluate` / `CareEngine.fire` (legacy, v0.28 删除)

**文件**: `lib/domain/logic/care_engine.dart:68-200`

**状态**: R65 抽了 `FireCareStrategyUseCase` (`lib/domain/usecases/fire_care_strategy.dart`),
R67 收尾把唯一 caller (`home_page._fireCareEngine`) 切到 use case, R67 后
**0 caller** (除 `care_engine.dart` 自身注释外)。

**为什么 v0.28 删除**:
- 业务编排下沉到 use case 后, 4 strategy 评分 / priority-best 选择 / delivery
  channel 决策都集中在 use case 1 个文件, `CareEngine` 自身只剩 legacy
  静态方法 + 内部 helper, 没业务价值
- 留作 legacy 1 个 round (R67) 观察, 防止有未发现的 caller

**v0.28 删除 checklist** (R68 PR 待做):
- [ ] `grep -rn "CareEngine\.(evaluate|fire)" lib/ test/`
- [ ] 若 0 匹配, 删 `care_engine.dart` 整个文件
- [ ] 检查 `care_strategies.dart` 4 个 strategy function 是否还有 caller
  (应在 use case 内被调, 不在 `CareEngine.evaluate` 内)
- [ ] 更新 `lib/domain/usecases/fire_care_strategy.dart` 注释里的"care_engine.dart
      :68-109" 老路径引用
- [ ] 更新本文件, 移除本条目

**当前 caller 列表 (R67 验证)**:
```
$ grep -rn "CareEngine\.(evaluate|fire)" lib/
lib/domain/logic/care_engine.dart:51       (注释: usage example)
lib/domain/logic/care_engine.dart:150,156  (内部 log 'CareEngine.fire' where 字段)
lib/domain/usecases/fire_care_strategy.dart:4,158,199  (注释: 历史背景)
lib/presentation/providers/care_strategy_providers.dart:5,21  (注释: 历史背景)
lib/presentation/pages/home/home_page.dart:501,513  (注释: 修复前/legacy 标记)
```

0 实际代码 caller ✓

---

## 2. `EmailService` mock 模式 (R39 P1-8 留作 mock, R67 加守门员)

**文件**: `lib/core/data/services/email_service.dart`

**状态**: R67 加 `isProductionReady` 守门员 + `validateForRelease` 静态方法
(跟 R63 SmsService 守门员 1:1 平行)。

**R55+ 真接 SendGrid 时**:
- 改 `_isFullyImplemented` 默认值 `true` (跟 send() 同步)
- 真实 API 调用替换 v1.0+ TODO 占位
- release 模式启动不再被 `validateForRelease` 阻断

**为什么 v0.28 暂留**:
- 当前 SendGrid 仍未真接, `sendMedicationReminder` 返 `false` (mock 透明)
- 留作"等真接"的占位
- 真接后 `isMock` getter 保留 (UI 仍可检测), 但 `validateForRelease` 不再阻断

---

## 3. `SmsService` mock 模式 (R63 已修, 守门员到位)

**文件**: `lib/core/data/services/sms_service.dart:42-49, 60-87, 270-298`

**状态**: R63 加 `_isFullyImplemented` 守门员 + `isProductionReady` getter +
`validateForRelease` 静态方法。R67 B-1 修复让 `EmailService` 跟这套 1:1 平行。

**R55+ 真接 AliyunSms 时**:
- 改 `AliyunSmsProvider._isFullyImplemented` 返 `true` (跟 send() 同步)
- 真实 SDK 调用替换当前 `StateError` 占位
- release 模式启动不再被 `validateForRelease` 阻断

---

## 4. `_resolveTimestamp` 私有 helper (R67 子智能体 C 公开)

**文件**: `lib/core/data/repositories/{vent,mood,medication,check_in}/` 各
repository impl 内的私有方法 (v0.16 起一直私有, 反复 copy-paste)

**状态**: R67 子智能体 C 抽到 `lib/core/shared/date_time_resolver.dart` 公开,
各 repo 改用共享 helper。本文档仅记录"曾经私有, 现公开"。

---

## 5. `privacy@chroniccare.app` 隐私投诉邮箱 (R67 用户决策, **软隐藏**, 暂不实现)

**业务范围**: PIPL §14 撤回同意 + §54 投诉渠道

**状态**: **隐藏** (R67 Sprint 1 用户决策)。**不提供邮件渠道**, 用户通过 App 内
ConsentGate 集中器 (`lib/core/shared/consent_gate.dart`) 行使 PIPL §14 撤回同意权,
撤回后 vent_repository / care_engine / trend_page 业务立即停止。

**R67 Sprint 1 决策** (用户提出, 即时执行):
- 决策原因: 用户决定不投入精力维护真实邮箱基础设施 (PIPL §54 投诉 7 工作日响应 SLA
  需要专人值守, 当前 0 客服团队)。
- 软隐藏 ≠ 永久删除: 撤回同意 + PIPL 投诉功能**仍由 ConsentGate 集中器实现**,
  业务层完整。重新启用只需 4 步 (见下)。

**改动的文档** (R67):
- `assets/legal/privacy_policy.md` 3 处 (顶部 TODO + §9 联系方式 + §10 未成年人保护)
- `assets/legal/user_agreement.md` 2 处 (顶部 TODO + §8 联系方式)
- `docs/SPRINT1_LEGAL_TODO.md` 4 处 (清单表 3 行 + checklist 1 项)
- 全部 5 处 `privacy@chroniccare.app` 改为引用 `App 内 设置 → 法律与隐私 页面` + R67 ConsentGate
- `support@chroniccare.app` (开发者联系) **保留**, 仍为上 store 前必注册项

**重新启用条件** (未来真接邮件 + 客服团队到位时):
- [ ] 招 / 分配至少 1 人值守 `privacy@` 邮箱, 7 工作日响应 SLA
- [ ] 注册 `chroniccare.app` 域名 + `privacy@` 邮箱 (Google Workspace / 阿里云邮箱)
- [ ] 改 `assets/legal/privacy_policy.md` 5 处 + `user_agreement.md` 2 处:
  - §9 / §8 联系方式: 改回 `隐私 / PIPL 投诉邮箱:privacy@chroniccare.app`
  - §10 未成年人保护: 改回 `监护人可联系 privacy@chroniccare.app`
  - 顶部 TODO 段: 加 "注册 `privacy@chroniccare.app` 邮箱" 项
- [ ] 改 `docs/SPRINT1_LEGAL_TODO.md` 4 处: 取消 ✅ 软隐藏, 改回 ❌ 待注册
- [ ] 改 `lib/core/data/services/email_service.dart`: 增加 `privacyContactMode = 'real'`
      分支, 调真实 `privacy@` 邮箱 (跟 SmsProvider.isProductionReady 同模式)
- [ ] 更新本文档, 移除本条目
- [ ] `flutter analyze` + `flutter test` + 16 守护脚本全绿
- [ ] CHANGELOG 加 `[0.X.Y] - YYYY-MM-DD` 条目: "重新启用隐私投诉邮箱"

**为什么用软隐藏不是删除**:
- 业务价值仍存在 (用户行使 PIPL §14 必须有渠道)
- ConsentGate 已在 R67 业务层生效, 撤回功能完整
- 未来真接邮件时, 改 5 处文档 + 1 处 service 分支即可, **无代码逻辑改动**
- 删除的复杂度 (决策文档 + 跨 store 沟通) > 软隐藏的成本 (留 1 个 LEGACY_NOTES 条目)

**参考**:
- 同 R66 `FeatureFlags.emergencyContactEnabled = false` 软隐藏失联通知业务的模式
- 软隐藏决策文档化 (R67 LEGACY_NOTES) + 业务层完整 (ConsentGate) = 可逆架构

---

## 维护流程

**新增条目** (refactor / 抽 use case / 软隐藏 feature 时):
1. 在本文档加新章节, 标 **状态** + **决策原因** + **重新启用条件 / 删除条件** + **caller 列表**
2. 在对应源文件注释里 `@see docs/LEGACY_API_NOTES.md` 互引

**删除条目** (legacy 真删时):
1. 从本文档移除对应章节
2. 删源文件 + 跑 `flutter analyze` 验证 0 error
3. 跑 `flutter test` 全过验证

**收尾**: R67 子智能体 B 第一次建本文档 (4 节), 后续 R67 Sprint 1 增补第 5 节 (privacy@ 软隐藏), R68+ 由各 PR 维护者更新。
