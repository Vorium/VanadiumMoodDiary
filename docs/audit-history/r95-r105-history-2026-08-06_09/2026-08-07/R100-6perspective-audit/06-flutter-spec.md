# R100 flutter-specification 视角报告（Flutter 规范 / 架构纯度 / 顶层架构审视）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动
**方法**: `dart scripts/check_all.dart` 实测 + 依赖方向/命名/Provider 规范逐层抽查 + 大文件行数统计

## 一、规范合规实测

| 检查 | 结果 |
|---|---|
| 4 层纯度（domain/shared 0 flutter 0 drift 0 data 0 presentation；data 不依赖 presentation） | ✅ 通过 |
| 架构一致性（`*Entity` ↔ drift `@DataClassName` 一一对应；shared ≥2 层使用） | ✅ 通过 |
| 跨 feature import 边界（118 files） | ✅ 0 violation |
| `flutter analyze` | ✅ 0 issue |
| 命名约定（Entity 后缀 / mapper / repository_impl / provider 暴露接口） | ✅ 抽查合规 |
| drift 生成物与 schema（schemaVersion + migration 链） | ✅ R95 收尾已验证 |

## 二、顶层架构评估（高内聚低耦合重点）

**结论：当前 4+1 层架构（presentation → domain ← data + core umbrella）对本项目规模（2019 tests / 13+ 表 / 9 repo / ~580 dart 文件）是合适的，不建议迁移 BLoC / Clean Architecture 全家桶。** Riverpod 3 + go_router + Drift 组合稳定，守护脚本已形成闭环，换架构收益为负。

需要提升内聚/降低耦合的点：

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| F-1 | `home_page_state.dart` 656 行：`_fireCareEngine` / `_runAfterCheckIn` / `_runSafetyCheck` 三职责混居（打卡 UI + 安全检测编排 + CareEngine 分发），是 presentation 层最大 god state | `lib/presentation/pages/home/home_page_state.dart` | 架构 | 复杂 | 中 |
| F-2 | `SafetyCheckResult` 双 API 未收敛：`displayMessage`（返 i18n key）仍保留，正确入口是 `displayMessageL10n(l10n)`；BUG-1 虽已修调用方，但旧 getter 仍可被新代码误用 | `safety_watch_service.dart` | 架构 | 简单（删 getter，编译期强制） | 中 |
| F-3 | 3 个 StreamProvider 缺 autoDispose（见 N-3） | providers | 架构 | 简单 | 中 |
| F-4 | `CareEngine.evaluate/fire` 死代码（见 N-2） | domain/logic | 架构 | 简单 | 中 |
| F-5 | `core/data/services/` 根目录仍平铺 31 文件（export/ 子目录已拆出是正面先例），建议按 notify/ safety/ pdf/ audio/ 续拆 | services/ | 架构 | 中 | 低 |
| F-6 | UseCase 覆盖不足：9 repo 仅 4 usecase（check_in / check_safety / fire_care_strategy / schedule_refill_reminder），跨 repo 编排部分泄漏到 presentation state（如 home / medication 页面） | domain/usecases/ | 架构 | 中 | 低 |
| F-7 | ThemeExtension 缺位（见 E-3）；`ThemeModeNotifier` 异步改 state 应迁 AsyncNotifier | core/theme | 架构 | 复杂 / 简单 | 低 |
| F-8 | `routerProvider` 手写 `_RouterProfileCache` mutable cache（R57 性能修复产物），可迁 NotifierProvider 更 Riverpod-idiomatic；当前实现有完整注释 + GC 说明，风险低 | app_router.dart | 架构 | 中 | 低 |

## 三、底层逐行排查结论（全 lib/ 遍历 + 脚本扫描）

- **Bug**：R99 的 BUG-1~5 全部复核闭环；本轮无新增功能级 bug。`check_datetime_race` 0、`check_widget_dispose` 0、`.first`/`.last` 隐式排序问题历史轮次已修（mood_dao 显式 ORDER BY、assessment_summary_strip 显式 sort）。
- **残留优化点**：test/ 约 104 处 trailing comma info；4 文件 import 顺序（dart: 先于 package:）；`check_fullwidth_punctuation` 132 warn（多为生成文件，建议脚本豁免 generated 而非逐条修）。
- **半成品清单**（FeatureFlags 8 项全 false，骨架完成度见 VERSION_1.0_PLAN §半成品表）：SMS 失联通知 / SendGrid 邮件 / IAP / 5 厂商 push / BootReceiver / vent 语音 / PHQ-GAD 全量 i18n / 紧急联系人——全部编译期锁定关闭，UI 不可见，符合"先隐藏后真接"策略，无泄漏点。

## 四、结论

架构健康度 9/10。唯一建议排期的架构动作是 F-1（home_page_state 拆分，可借鉴 R95 settings_page 4-group 拆法）与 F-2（API 收敛），其余为低紧急整理项。
