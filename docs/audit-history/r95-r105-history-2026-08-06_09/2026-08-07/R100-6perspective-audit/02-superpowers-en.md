# R100 superpowers-en 视角报告（工程实践 / 测试 / 错误处理 / 工程卫生）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动（R99 修复后）
**方法**: 实测 17 守护脚本 + `flutter analyze`（0 issue）+ `_audit_v2.py` + git status 全量复核

## 一、实测绿灯（本轮新跑）

| 检查 | 结果 |
|---|---|
| `dart scripts/check_all.dart` 4 层纯度 + 一致性 | ✅ |
| `flutter analyze` | ✅ No issues found |
| ARB 3 语同步（1068 key） | ✅ |
| `check_cross_feature.py`（118 files） | ✅ 0 violation |
| `check_orphan_arb_keys.py` | ✅ 0 orphan |
| `check_datetime_race.py` + race2 | ✅ 0 |
| `check_widget_dispose.py` | ✅ 0 leak |
| 测试基线 | 2019 cases（R95 sub-spec 8 收尾实测） |

**R99 报的 5 个 BUG 复核全部闭环**：BUG-1 displayMessageL10n（home_page_state.dart:258,470 ✅）、BUG-2 版本参数化（kPubspecVersion='0.30.0+85' ✅）、BUG-3 orphan key（0 ✅）、BUG-4 datetime race（mood_period_aggregator 已单捕获 refNow ✅）、BUG-5 unused import（analyze 0 ✅）。

## 二、问题清单

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| N-1 | **工程卫生：repo 根 80+ 临时垃圾文件未清理**（`_c1.py`/`_trash_*.txt`/`test_all_v*.txt`/`_o*.tmp`/`CRLF'''`/`LF'''` 等），全部 untracked 但污染工作区 + 干扰搜索 | repo 根目录 | 底层 | 简单 | 中 |
| N-2 | **死代码：`CareEngine.evaluate` / `fire` legacy API**（LEGACY_API_NOTES 承诺 v0.28 删，已拖 2 个版本，0 调用方仅注释引用） | `lib/domain/logic/care_engine.dart` | 架构 | 简单 | 中 |
| N-3 | **3 个 StreamProvider 缺 autoDispose**（subscription 永不释放）：ventSealedProvider / ventSealedAtProvider / allAssessmentEntriesProvider | `legal_consent_provider.dart:273,279`；`assessment_providers.dart:34` | 架构 | 简单 | 中 |
| N-4 | 大文件：home_page_state 656 行（3 职责混居）/ setup_page_state 535 / vent_compose 512 / main.dart 500 / legal_page 494 / notification_service 480 / reminders_hub_page 477 / safety_watch_service 457 | 见 `reports/r100/_sizes.py` 输出 | 架构 | 复杂 | 低 |
| N-5 | `core/data/services/` 28 文件平铺无分组（notify / export / sms-email 应分子目录） | `lib/core/data/services/` | 架构 | 中 | 低 |
| N-6 | UseCase 覆盖不足：9 repo 仅 4 usecase，部分编排逻辑仍在 presentation state | `lib/domain/usecases/` | 架构 | 中 | 低 |
| N-7 | commit 规范：近 100 commit 3 个不符合 `<version> round <N>:` 格式（R95 fixup 系列） | `_audit_v2.py` §E | 底层 | 简单 | 低 |
| N-8 | `ThemeModeNotifier.build` 异步改 state，应迁 AsyncNotifier；4 文件 import 顺序；test/ ~104 trailing comma info | theme_provider 等 | 底层 | 简单 | 低 |
| N-9 | 未提交改动 ~280 文件（R92-R99 修复堆积），需尽快分批 commit 降低丢失风险 | `git status` | 底层 | 简单 | **高** |

## 三、结论

工程质量处于高位：0 analyzer issue、17 守护脚本基本全绿、2019 tests。最高优先事项不是代码而是 **流程卫生**：N-9（commit 落地）+ N-1（垃圾清理）。架构债（N-2~N-6）全部低紧急，可上架后分批还。
