# Task 4 (C2) 修复报告 — theme/widgets/setup/assessment/routing

> 实现 subagent 报告 · 2026-08-13 · 不 commit (R1 裁决), 改动留 working tree
> 所有权: app_colors / spring / app_list_tile / section_header / apple_list_section /
> quick_mood_carousel / setup_* / assessment_widgets / app_route_medication /
> crisis_hotline + medication_calendar (仅删 import) / home controllers /
> cbt_three_column_mode + mood_factor_analysis (EM-16b) / check_in_button (仅 format)
> + 对应测试文件

## 任务状态

| # | 任务 | 状态 | 说明 |
|---|---|---|---|
| 1 | 3 analyzer warning 清零 | ✅ done | crisis_hotline_page:30 + medication_calendar_page:27 删 unused app_motion import; medication_backfill_round8_test:12 删 unused check_in_entity import (该文件按指示加入所有权) |
| 2 | EM-16b 对比度 token | ✅ done | 见下 |
| 3 | EM-14b AppListTile enabled | ✅ done | 见下 |
| 4 | EM-07 mood_trend Colors.white | ⏭️ 跳过 | mood_trend_page.dart 归 C1 agent (任务指示明确跳过) |
| 5 | EM-09b _ChipBadge 合一 | ✅ done (带 ⚠️) | 见下 + concerns |
| 6 | R112-02 tune icon 44pt | ✅ done | PressFeedback 包 SizedBox(44×44) + Center, icon 视觉仍 18pt; 顺带删 quick_mood_carousel.dart:31 unnecessary app_motion import (1 info 消) |
| 7 | R112-03 Spring.of 死代码 | ✅ done | 删 SpringType enum + Spring.of (`final _ = context` hack), 保留 3 static const + toDescription/toSimulation; spring_round10_test 同步删 Spring.of case (5→4 case), physics import 去 hide |
| 8 | R112-04 setState 反模式 | ✅ done | setup_page_state.dart:373 `if (!mounted) { setState(...); return; }` → `if (!mounted) return;` (_saving 复位由 finally 块承担) |
| 9 | R112-09 MedDraft.times 通知 | ✅ done | MedDraft 加 `_onTimesChanged` 回调 + `addTime`(自动排序+通知)/`removeTimeAt`, attachListener 注册; setup_step_medication InputChip onDeleted / ActionChip 改走新方法 |
| 10 | R112-06 sparkline maxTotal | ✅ done | 新增 `AssessmentSparkline.sparklineMaxTotalFor(scaleId)` 静态 helper 走 domain scale_registry.scaleById(id)?.totalRange, null/≤0 防御 21; WHODAS 48 / PSS 40 / ISI 28 / ASRM 20 不再画出界 |
| 11 | R112-07 /medication/detail 深链 | ✅ done | `int.tryParse(pathParameters['id'] ?? '') ?? 0` (跟 app_route_vent.dart:38 同款), 脏 URL → medNotFound 分支 |
| 12a | use_build_context 4 处 info | ✅ done | home_deep_link_handler 198/207/208 + home_care_engine_dispatcher:74 guard 改 `!isMounted() \|\| !context.mounted` — 4 info 全消 |
| 12b | setup_redesign 死 override | ✅ done | `_NoopNotificationService.scheduleDailyReminder` 死 fake override 删 (R108 后迁 delegate, 无 @override 的 0 用途方法) |
| 12c | check_in_button 缩进 | ✅ done | `dart format` (86 行 child: 缩进 + 4 处行折叠, 纯 whitespace) |
| 13 | CHANGELOG 验证行 | ✅ 只读确认 | [0.32.0+142] "flutter analyze 0 error / 0 warning" 在本批清完 3 warning 后**为真**, 不动 |

## 验证结果 (实测)

- **flutter analyze: 0 error / 0 warning / 113 info** (baseline 0e/3w/133i; 本批净 -3w -20i)
- **flutter test 全量: 2447 pass / 1 skip / 4 fail** (4 fail 全为 iOS 资产占位, 设计师依赖, 与 baseline 相同; baseline 2377 pass → +70 含并发 agent 的 test)
- **我的文件 analyze 问题数: 0** (含新增测试文件, dart format + dart fix trailing_commas 清干净)
- 守门员: check_cross_feature 0 violation; check_all 一致性 ✅ / 纯度 ❌ 1 处 (`lib/domain/usecases/dispatch_safety_alert.dart:15` import flutter/foundation — **并发 agent D 的 in-flight 文件, 非本批**, baseline 无此违规)

## 各任务细节

### EM-16b (P1) — 对比度 token
- `app_colors.dart`: `fgOnSuccess` 浅绿别名 → **深绿 #2E7D32** (白底 ≈5.1:1); 新增 `fgError` 深红 **#C62828** (≈5.6:1) + `fgWarningStrong` 深橙 **#BF360C** (≈5.6:1)
- ⚠️ **命名偏差**: 任务要求 "新增 fgOnError", 但 `fgOnError(BuildContext)` 是既有 "on error 表面" 语义 dynamic getter (chip_badge error tone / last_startup_error_banner / swipe_delete_background / legal_page 4 个 caller 依赖, 不在本 agent 所有权) — Dart 静态字段与静态方法不能同名, 故深红文字 token 命名 **`fgError`** (代码注释已说明), 主 agent 复核时注意
- `mood_factor_analysis.dart:114-116`: textColor 按档走 fgOnSuccess/fgOnWarning/fgError (指示条仍走浅色装饰色)
- `cbt_three_column_mode.dart:116-117`: `_scoreTextColor` switch 全档走深色 token (1→fgError, 2→fgWarningStrong, 3→fgOnWarning, 4→fgOnSuccess, 5→primary)
- 副作用 (正向): chip_badge success tone + profile_group 3 处读 `fgOnSuccess` 同步受益
- 测试: `test/core/theme/app_colors_contrast_round8_test.dart` 5 case (色值 lock-in + computeLuminance 对比度: 新 3 token ≥4.5:1; fgOnWarning 保持 #E65100 只断 ≥3:1 大字档 — R111 既有选择白底 ≈3.8:1, 任务明确"不倒退")

### EM-14b (P1) — AppListTile 假反馈
- `PressFeedback(enabled: onTap != null, onTap: onTap, child: listTile)` — 无 onTap 行 0 scale 0 haptic; mode 2 "child.onTap 接管" 错误注释 (header/field/build 3 处) 改正确描述 (ListTile.onTap 恒 null, 行不可点)
- 只读验证: assessment_section.dart:93 (关于) / :106 (免责声明) 均无 onTap = 实锤调用点, 修后无假反馈
- 测试: `app_list_tile_enabled_round8_test.dart` 3 case (无 onTap→enabled=false / 有 onTap→true+tap / carded 同)

### EM-09b (P2) — _ChipBadge 合一 ⚠️
- section_header + apple_list_section 两处私有 `_ChipBadge` (136-160 / 232-256) 删除, 改 import 公共 `widgets/ChipBadge` (同层无循环依赖)
- 测试: section_header_round8b_test 新 case 4 (chip → find.byType(ChipBadge)); home_emil_round81 3 case + apple_list_section_round8a 全绿
- **⚠️ 新发现 (建议主 agent 立 P1)**: 公共 `ChipBadge` neutral tone fg = `fgOnPrimary(context)` = colorScheme.onPrimary = **white (light mode)** on tintedPrimarySoft — 换上去后 medication_page 数量 chip ("5" / "2/3") + trend_page "近 30 天" + profile_group "当前" 在 light mode 文字**白底白 ≈1.1:1 不可读** (EM-16b 同族)。私有副本原是 primary 绿字。**chip_badge.dart 不在本 agent 所有权**。5 分钟修法: ChipBadge.neutral fg 改 `fgOnPrimary → colorScheme.primary` (或加 primary tone)。若主 agent 认为不该换回, 请把该修法补进任务清单。

### R112-09 (P2) — MedDraft.times 通知
- `setup_widgets.dart` MedDraft: `attachListener` 现在同时注册 times 变更回调; 新增 `addTime` (add+sort+notify) / `removeTimeAt` (remove+notify); dispose 清回调
- `setup_step_medication.dart`:281/297 改走 `med.removeTimeAt(tIdx)` / `med.addTime(picked)` → SetupPageState._onTextChanged → setState 重建
- 测试: `setup_step_medication_times_round8_test.dart` 4 case (addTime 通知+排序 / removeTimeAt 通知 / 无 listener 兜底 / MedCard 删 chip 接线)

### R112-06 (P2) — sparkline
- 测试: `assessment_sparkline_max_total_round8_test.dart` 3 case (10 个已知量表 totalRange / 未知 id / 空串)

### R112-07 (P2) — 路由
- 测试: `routing/medication_detail_route_round8_test.dart` 2 case (走 AppRouteMedication.shellRoutes() 真实 pageBuilder, /medication/detail/abc → "药物未找到" 不崩; /42 正常)

## 新增/修改测试清单 (本 agent 部分)

| 文件 | 变更 |
|---|---|
| test/core/theme/app_colors_contrast_round8_test.dart | 新, 5 case |
| test/presentation/widgets/app_list_tile_enabled_round8_test.dart | 新, 3 case |
| test/presentation/pages/setup/setup_step_medication_times_round8_test.dart | 新, 4 case |
| test/presentation/pages/assessment/assessment_sparkline_max_total_round8_test.dart | 新, 3 case |
| test/routing/medication_detail_route_round8_test.dart | 新, 2 case |
| test/presentation/pages/home/quick_mood_carousel_tap_target_round8_test.dart | 新, 2 case |
| test/presentation/widgets/section_header_round8b_test.dart | +1 case (ChipBadge lock-in) + format |
| test/core/theme/spring_round10_test.dart | -1 case (Spring.of 随死代码删), 头注释+import 同步 |
| test/presentation/pages/setup/setup_redesign_round10_test.dart | 删死 override + format |
| test/presentation/pages/medication/medication_backfill_round8_test.dart | 删 unused import |
| test/presentation/pages/assessment/assessment_widgets_round7b_test.dart | 仅 dart format + fix trailing commas (0 逻辑改) |

合计本批 +20 新 case / -1 case。

## Concerns / 并发冲突记录

1. **⚠️ EM-09b 视觉回归风险 (见上)** — 最需要主 agent 裁决的一项。
2. **并发 agent D 编辑了我两个文件**: (a) home_care_engine_dispatcher.dart — D 把 `onCheckIn(l10n:)` 改 `l10nResolver:` (AR-16 refactor), 我的 context.mounted guard 被保留, 最终编译干净; (b) setup_page_state.dart — D 加了 preset_med_l10n.dart extension import (nameL10n 移 presentation), 我的 R112-04 修复未受干扰。两份改动均已验证共存。
3. **cbt_three_column_mode score 5 仍 `AppColors.primary` (#34C759) 作文字色** (白底 ≈2.1:1) — 任务范围只列 success/error/warningStrong 三档, 未动; 品牌绿 15pt w600 属同族残留, 建议后续 `fgOnPrimaryDeep` 或专门 deep-green token (0.1h)。
4. 检查时发现 `lib/domain/usecases/dispatch_safety_alert.dart:15` import flutter/foundation → check_all 纯度 ❌ — **agent D in-flight**, baseline 无, 本批未碰。
5. 全量测试的 4 fail = iOS 资产占位 (app_icon/launch_image, 设计师依赖), 与 baseline 一致; 会话期间 D 的 l10nResolver refactor 一度把 test/data 打红 8-12 error, 现已被 D 修到 0 error。

## TDD 说明

- 6 个新测试文件全部先写后跑红 (一次批量红 phase: +0 -8), 实现后全绿
- 纯 lint/删死代码类 (任务 1 / 7 / 8 / 12) 无行为可测, 以 analyze 0 问题 + 既有测试不倒退为验证 (无"失败测试先行"意义, 已注明)

<!-- subagent: C2-theme-widgets-setup 完成时间: 2026-08-13T12:00:00Z -->
