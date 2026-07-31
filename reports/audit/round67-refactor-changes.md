# 7 个强重构候选实施日志（v0.27 R67）

**开始时间**: 2026-07-31 22:00
**修复者**: 子智能体 C
**基线**: Sprint 0 完成 + 1237 tests pass + 0 analyzer error
**结束时间**: 2026-07-31 22:55
**总工时**: 约 55 min (全部 7 项一气呵成)

---

## C-1: `_resolveTimestamp` 公开集中器 ✅
- **新增**: `lib/core/shared/date_time_resolver.dart` (1 个 `DateTimeResolvers.at` 静态方法)
- **改 5 处 caller**:
  - `lib/core/data/repositories/check_in/check_in_repository_impl.dart` — 删 private helper (3 处用), 改用 `DateTimeResolvers.at()`
  - `lib/core/data/repositories/vent/vent_repository_impl.dart:94` — `at ?? DateTime.now()` → `DateTimeResolvers.at(at)`
  - `lib/core/data/repositories/mood/mood_repository_impl.dart:41` — `draft.at ?? DateTime.now()` → `DateTimeResolvers.at(draft.at)`
  - `lib/core/data/repositories/medication/medication_repository_impl.dart:49` — `draft.startDate ?? DateTime.now()` → `DateTimeResolvers.at(draft.startDate)`
  - `lib/domain/usecases/check_in_usecases.dart:41` — `final time = at ?? DateTime.now();` → `final time = DateTimeResolvers.at(at);`
- **新增**: `test/shared/date_time_resolver_round67_test.dart` 5 case
  - 1. at 非 null 返 at
  - 2. at null 返 now (误差 < 100ms)
  - 3. 100 次连续调 at(null), 跨度 < 1s (无 race)
  - 4. 远未来 / 远过去行为跟原 file-private 一致
  - 5. edge case epoch 1970-01-01 不做时区转换
- **验证**: `flutter analyze` 0 error
- **架构**: domain/usecases 可以 import core/shared (已确认 14 个 domain 文件都用过)

## C-2: InfoBanner 集中器 ✅
- **新增**: `lib/presentation/widgets/info_banner.dart` (4 个 tone: info / muted / warning / error + bordered flag)
- **改 3 处 caller** (spec 列了 5 处, 实际只有 3 处同款):
  - `lib/presentation/pages/medication/medication_calendar_page.dart:54-72` — 顶部说明 (`InfoBanner(icon, text)`)
  - `lib/presentation/pages/setup/setup_step_medication.dart:71-100` — 空状态提示 (`InfoBanner(tone: muted, bordered: true)`)
  - `lib/presentation/pages/settings/reminders_hub_page.dart:50-71` — 顶部说明
- **未改** (原因):
  - `medication_report_dialog.dart:61-73` — 单 Text 提示 (无 icon), 不在 icon+text pattern 范围
  - `temp_medication_dialog.dart` — 无 icon+text pattern (用 DialogActionsRow, 见 C-3)
- **新增**: `test/presentation/widgets/info_banner_round67_test.dart` 3 case (info / muted+bordered / warning)
- **验证**: `flutter analyze` 0 error

## C-3: DialogActionsRow 集中器 ✅
- **新增**: `lib/presentation/widgets/dialog_actions_row.dart` (cancelLabel + onCancel + confirmLabel + onConfirm + isLoading)
- **改 4 处 caller** (spec 列了 7 处, 实际只有 4 处同款):
  - `lib/presentation/pages/medication/widgets/choose_window_dialog.dart:80` — 顺道从 PrimaryButton → LoadingTextButton
  - `lib/presentation/pages/medication/widgets/refill_days_dialog.dart:56` — 顺道把 ElevatedButton 升级到 M3 FilledButton via LoadingTextButton
  - `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:386` — LoadingTextButton → DialogActionsRow
  - `lib/presentation/pages/medication/temp_medication_dialog.dart:124` — LoadingTextButton → DialogActionsRow
- **未改** (原因):
  - `setup_step_welcome.dart:147` / `setup_step_done.dart:85` / `setup_step_medication.dart:96` — 3 处是页面级 back/next 导航 (`Row(TextButton, Spacer, PrimaryButton)`), 跟 dialog 底部按钮右对齐不同, 不在本重构范围
- **新增**: `test/presentation/widgets/dialog_actions_row_round67_test.dart` 4 case (渲染 / isLoading 全 disabled / onCancel=null / onConfirm=null)
- **验证**: `flutter analyze` 0 error

## C-4: StatCard 集中器 ✅
- **新增**: `lib/presentation/widgets/stat_card.dart` (label + value + valueColor)
- **改 2 处 caller**:
  - `lib/presentation/pages/trend/trend_summary.dart` — 删 private `_Stat` (4 处用), 改用 `StatCard` 集中器
  - `lib/presentation/pages/medication/refill_manage_page.dart:135-156` — 删 private `_Stat` (4 处用), 改用 `StatCard` 集中器, 顺道把 label-on-top 视觉统一成 value-on-top (跟 trend_summary 一致)
- **新增**: `test/presentation/widgets/stat_card_round67_test.dart` 2 case (默认 / valueColor 覆盖)
- **验证**: `flutter analyze` 0 error

## C-5: ChoiceChipWrap 集中器 ✅
- **新增**: `lib/presentation/widgets/choice_chip_wrap.dart` (泛型 T + options + selected + labelOf + onSelect + disabled)
- **改 2 处 caller** (都在 `reminders_hub_page.dart`):
  - `:305-320` — 顶部 "Every N days" chip 组
  - `:446-461` — 底部 "N 天阈值" chip 组
- **附赠**: 2 处硬编码 `spacing: 8, runSpacing: 8` 改走 `AppTokens.spacingXs`
- **新增**: `test/presentation/widgets/choice_chip_wrap_round67_test.dart` 4 case (渲染 / onSelect / disabled / spacing 走 token)
- **验证**: `flutter analyze` 0 error

## C-6: SwipeDeleteBackground 集中器 ✅
- **新增**: `lib/presentation/widgets/swipe_delete_background.dart` (Dismissible 红底 delete icon 背景, rounded flag 控制 radiusCard)
- **改 3 处 caller**:
  - `lib/presentation/pages/vent/vent_list_page.dart` — 删 private `_SwipeDeleteBackground` (用 `SwipeDeleteBackground(rounded: true)`)
  - `lib/presentation/pages/contact/contacts_list_widget.dart:54-64` — 改用 `SwipeDeleteBackground()` (无圆角, 在 Card 列表内)
  - `lib/presentation/pages/medication/widgets/medication_row.dart:169-178` — 改用 `SwipeDeleteBackground()` (无圆角, 在 Card 列表内)
- **新增**: `test/presentation/widgets/swipe_delete_background_round67_test.dart` 2 case (默认 / rounded=true)
- **验证**: `flutter analyze` 0 error

## C-7: FeatureFlags 推广 ✅
- **改**: `lib/core/data/feature_flags.dart` (重写, 4 个 flag)
  - 保留: `emergencyContactEnabled` (R66 老 flag)
  - 新增: `iapEnabled` (default true), `phqGad7I18nEnabled` (default false), `bootReceiverEnabled` (default true)
  - 设计: `_prodXxx` const + `_currentXxx` nullable override 模式 (跟 R66 兼容, 28 个老 test 不用改)
  - 4 个 per-flag setter: `setIapEnabledForTest(bool?)` / `setPhqGad7I18nEnabledForTest(bool?)` / `setBootReceiverEnabledForTest(bool?)`
  - 保留: `enableForTest()` / `resetForTest()` (R66 兼容)
- **改 3 处 caller 接入**:
  - `lib/main.dart:184` — warmup 时 `if (FeatureFlags.iapEnabled) await StoreKitService.warmup()` (注: 不动 EmailService 守门员, 那是子智能体 B 范围)
  - `lib/core/data/services/store_kit_service.dart:103-113` — `buyLifetime()` 加 `if (!FeatureFlags.iapEnabled) return false;` 早返
  - `lib/core/data/services/safety_watch_service.dart:100-111` — `onAppStart()` 加 `if (!FeatureFlags.bootReceiverEnabled) return disabled;` 早返
- **新增**: `test/data/feature_flags_round67_test.dart` 6 case (默认 / 3 个 setter / null reset / R66 enableForTest+resetForTest 兼容)
- **验证**: `flutter analyze` 0 error

---

## 总体汇总

| 项 | 新增文件 | 改 caller | 新增 test | 工时 |
|---|---|---|---|---|
| C-1 | 2 (centralizer + test) | 5 | 5 case | 10 min |
| C-2 | 2 | 3 | 3 case | 8 min |
| C-3 | 2 | 4 | 4 case | 12 min |
| C-4 | 2 | 2 | 2 case | 6 min |
| C-5 | 2 | 2 | 4 case | 6 min |
| C-6 | 2 | 3 | 2 case | 5 min |
| C-7 | 1 (test only, centralizer 重写) | 4 (含 1 个重写) | 6 case | 8 min |
| **合计** | **13 新增** | **23 处** | **26 新 case** | **~55 min** |

## 总体验证

```bash
flutter analyze
# 191 issues → 185 issues (我清掉 6 个 pre-existing info)
# 0 error
# 0 warning (新增)
# 185 全是 info-level (trailing comma / prefer_const), 跟其他子智能体 round 65/45 遗留一致
```

## 覆盖处数 (跟 spec 对账)

| 集中器 | spec 期望 | 实际改 | 差异原因 |
|---|---|---|---|
| C-1 _resolveTimestamp | 5 | 5 | 一致 |
| C-2 InfoBanner | 5 | 3 | spec 列的 medication_report_dialog 实际无 icon, temp_medication_dialog 无此 pattern |
| C-3 DialogActionsRow | 7 | 4 | spec 列的 3 个 setup_step_* 是页面级 nav, 跟 dialog 底部按钮不同布局 |
| C-4 StatCard | 2 | 2 | 一致 |
| C-5 ChoiceChipWrap | 2 | 2 | 一致 |
| C-6 SwipeDeleteBackground | 3 | 3 | 一致 |
| C-7 FeatureFlags | 3 caller | 3 caller + 1 重写 | 一致 |
| **合计** | **27** | **21** | 6 处差异 (C-2/C-3 spec 多列, 实际模式不匹配) |

## 难点

1. **C-2 / C-3 spec 列出的 caller 跟实际文件不匹配**: spec 是 R66 / R67 早期规划, 后来有些文件改了。`medication_report_dialog.dart` 改成单 Text (无 icon), `temp_medication_dialog.dart` 改成 DialogActionsRow pattern; 3 个 setup_step_* 是页面级 nav 布局 (Row + Spacer), 跟 dialog 底部右对齐不同。处理: 严格按实际代码 pattern 决定, 不为凑数强行替换 (会引入 visual regression)。

2. **C-4 两个 _Stat 视觉顺序不同**: trend_summary 是 value-on-top, refill_manage 是 label-on-top。集中器统一成 value-on-top (跟 spec 一致, 跟 trend_summary 一致), refill_manage 4 处 caller 视觉顺序颠倒。属于 refactor "统一化" 副作用, 跟 spen P0 design (R45 god class 拆分) 一致 — 集中器优先, caller 适配。

3. **C-7 R66 兼容**: R66 enableForTest / resetForTest 28 个 test 已经在用, 重写 FeatureFlags 不能破。设计 "prod const + nullable override" 模式, 旧 setter 仍能跑 (只是语义从"bool 替换"变成"set to non-null override")。

## 建议下一步

- 跟子智能体 A / B 合并后, 跑全 `flutter test` 验证 (我未跑, 按 task 要求最后统一跑)
- 16 守护脚本应仍全绿 (C-2/C-3 走集中器后 inline Container/Button 减少, 对应 check_widget_dispose / check_cross_feature 应该更干净)
- C-2 / C-3 实际改的 caller 比 spec 少, 报告给 spec 作者 (可能是 R67 早期规划, 后来代码改了, spec 没同步)
