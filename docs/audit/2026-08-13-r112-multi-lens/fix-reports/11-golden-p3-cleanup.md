# Wave 3 收尾批 (H2) Fix Report — golden 测试 + P3 卫生杂项 + 防御复查

实现 subagent · 2026-08-14 · working tree 基于 master `6bbb308` (R112 进行中, 未 commit)

## 每任务状态

### 1. Golden ×3 (FS P2-003) — **done**
- 新文件 `test/presentation/widgets/widgets_golden_round8_test.dart` (3 testWidgets)
- 基线 PNG 入库 `test/presentation/widgets/golden/` (3 文件: primary_button_primary.png 4.5KB / stat_card_default.png 3.5KB / apple_list_section_with_chip.png 6.8KB)
- 约定 (项目首批 golden): 固定 view 800×600 + DPR 1.0 + `AppTheme.light()` 真实主题 + zh locale + `pumpAndSettle` (TweenNumber 初始动画收尾)。3 个 widget 均不按压 → 不触发 ink_sparkle shader (已知坑规避: 不依赖 assets/shaders 渲染)
- 生成: `flutter test --update-goldens` 后无 flag 重跑验证稳定 (2 次全过)
- 注: 首次生成在 `test/presentation/widgets/golden/` 下产生 `golden/golden` 嵌套, 已重构为 test 文件在 `widgets/` + PNG 在 `widgets/golden/`

### 2. EM-19 app_list_tile 假 API — **done**
- grep 0 caller (`AppListTile.destructive` 仅自引用) → 删 destructive 命名构造 + `_isDestructive` 字段 + build assert, 更新头注释 (3 构造 → 2 构造)

### 3. 注释漂移 — **done** (5min×4)
- `apple_health_tile.dart:13` "~88pt" → "~110pt" (tileHeight 实值, R109 round 6 升)
- `apple_list_section.dart` 2 处 "SectionHeader 是 11pt" → 注明 EM-02b 后同为 13pt, 不用它的真实原因是 chip 参数 + 布局语义
- `notification_status_card.dart` 测试 id 99001 → **50000100** (5M+ 带外; 旧 99001 在 refill band [6000, 206000) 内 = 6000+medId 93001 理论碰撞)。同步 `notification_status_card_round20_test.dart:138` 断言 99001 → 50000100
- EM-08 6 处硬编码 fontSize 加"装饰性保留"注释: mood_detail_page:106 (emoji 48) / cbt_three_column_mode:44,56 (emoji 20 ×2) / mood_trend_page:398 (emoji 20) / add_medication_page:393 (chip 16) / medication_detail_page:304 (日历格 10)。注: 审计报告行号已随 working tree 漂移, 按"硬编码 fontSize grep"实值定位

### 4. moodTodayLabel 参数化 (R112-06/07/08) — **done**
- 3 语 ARB 加 `moodTodayLabelWithValue(value)` + @metadata placeholder (String) + moodLabel1-5 补 @metadata description
- `flutter gen-l10n` 全局再生成
- `mood_quick_button.dart:51` 拼接 → `moodTodayLabelWithValue(moodLabel(l10n, score))`
- 新测试 `test/presentation/widgets/mood_label_round8_test.dart` (6 case): moodLabel 5 档 zh/en 断言 + 越界 fallback + MoodQuickButton 已记录/未记录/en locale 无尾随空格漂移
- 连带: `scale_strings_arb_lock_in_round95_test.dart` total 1278 → 1279 (净 +1 key, @metadata 不占 key)

### 5. R112-09 press_feedback_icon_button — **done**
- 模式 2 分支传 `enabled: onPressed != null` (release build assert 被 strip 后双 null 理论可达的假反馈防御), 模式 1 显式 `enabled: true`

### 6. theme_provider 竞态 — **done**
- `_generation` 计数: `set()` ++, `_load()` 启动时快照, 晚到 (generation 变) 即丢弃
- 新测试 `test/core/theme/theme_provider_round8_test.dart` (2 case, MethodChannel mock 慢读 + Completer 控制): 手动 set 后晚到丢弃 / 无 set 时正常应用

### 7. vent_list_page — **done**
- `_confirmDelete` 长按路径对齐 swipe: 入口 `Haptics.warning()` + 删除后 `AppSnackBar.undo` 撤销
- `_EntryCell` StatelessWidget → ConsumerWidget, `ProviderScope.containerOf(context).read` → `ref.read`; repo 在 async gap (dialog await) 前捕获, ref 不跨 unmount 使用 (Riverpod 3 防御)

### 8. FS-3 + FS-11 — **done**
- FS-11 (home_fab_toolbar mixin) 已在 working tree 删除 (R111 先做), 复查确认 0 ticker 0 AnimationController
- FS-3: `TempMedicationDialog.show()` 改 await `medicationsProvider.future` 后再开 dialog (修前 loading 分支弹 LoadingSkeleton 死加载), 失败降级照常开; dialog 内部保留 ref.watch (R111 已修)。删 2 个 dead import
- 注: 该 widget 当前 0 runtime caller (grep 实锤), 属死代码维护, 未删 (超出本批任务范围)

### 9. 按钮集中器迁移 — **done**
- `cbt_section_field.dart` TextButton.icon('?') → PrimaryButton tertiary + leadingIcon (help_outline 16) + isFullWidth: false, 保留 '?' 文案 (cbt_widgets_round84_test `find.text('?')` 继续过)
- `treatment_page.dart:54` FilledButton.icon → PrimaryButton primary + leadingIcon + isFullWidth: false (treatment_page_round92_test `find.text('添加')` 继续过)

### 10. FS P2-005 audioplayers_platform_interface — **done**
- 选"更稳的后者": pubspec dev_dependencies 显式声明 `audioplayers_platform_interface: ^7.1.0` (仅测试 mock 用, runtime 依赖面不变), `flutter pub get` 已跑

### 11. E-01 同源防御 — **done** (P1 防御, 1h)
- 全 lib grep `unawaited(` 32 处逐一排查 (dispose 链 6 文件):
  - vent_compose_page / mood_audio_recorder_widget / vent_detail_page 三处 dispose 链已在 R112/B1-11 用字段缓存修过 (复查确认)
  - **新修**: `vent_compose_page._getAudioDuration` finally 块 (录音后立刻 pop → unmount 后仍执行) 走 `_storage` 字段 (local 缓存 + null 分支兜底, 字段不参与类型提升), 修前 ref.read 抛 StateError 被吞 → temp 明文泄漏
  - preset_templates_sheet (任务点名) 是 StatelessWidget 0 dispose 链, 干净
  - 其余 unawaited 站点 (quick_mood_carousel Haptics / vent_list SP setBool / notification_status_card postFrame 带 mounted guard / audio_lifecycle cancel / app.dart 启动) 均无 ref.read 或不在 unmount 后链上 — **无新发现**

### 12. R111-08 vent compose 全链路 — **done**
- 新测试 `test/presentation/pages/vent/vent_compose_full_chain_round8_test.dart`: GoRouter '/vent'+'/vent/compose', 全内存 fake (broadcast stream repo onListen emit 初始空 / fake storage), 平台通道 mock 跟 dispose leak 测试一致 → 空列表 → 写第一句 → 输入 → 放进树洞 (按 LoadingTextButton 定位, title 同文案) → 列表出现新条目 + repo.add 断言

## 测试数
- 新增 12 test: golden 3 + mood_label/MoodQuickButton 6 + theme race 2 + vent 全链路 1
- 修改 2 个既有测试: notification_status_card_round20 (id 断言), scale_strings_arb_lock_in (1279)

## 全量验证结果
- `flutter test`: **2483 pass / 4 fail / 1 skip** (基线 2471 pass / 4 fail / 1 skip — 4 fail 为 iOS 资产占位同款, 0 新增 fail, 0 回归)
- `flutter analyze`: **0 error / 0 warning** / 108 info (基线 3 warning 已在 working tree 清零; 我新文件自清 const infos)
- `python scripts/check_arb_keys.py` ✅ 1279 × 3 语同步
- `python scripts/check_orphan_arb_keys.py` ✅ 0 orphan
- `python scripts/check_strings_hardcoded.py` ✅ 规则 1 = 34 处 (R57 配对), 规则 2 inline = 0
- `python scripts/check_cross_feature.py` ✅ 0 violation
- `python scripts/check_zh_hant_consistency.py` ✅ 100%
- `python scripts/check_coverage.py` ✅ 18 gatekeeper 全过
- `dart scripts/check_all.dart` ✅ 纯度 + 一致性双过

## Concerns
1. **golden 字体稳定性**: 3 张 PNG 用 flutter_test 默认字体 (中文渲染为框), 跨 Flutter 版本升级可能 diff — 项目锁 3.41.9 内稳定; 若后续引入真实字体加载, 需重新生成基线
2. **TempMedicationDialog 0 caller**: FS-3 修复对象实为死代码 (grep 无调用点)。已修但建议后续 round 决定"删或接 caller", 避免假维护
3. **notification_status_card 测试 id 5M+ 带外**: 50000100 与固定带 (safety 5000000 / assessment 5000001 / mood 5000002 / carePush 5000010+ / badge 5000100) 间距 90+, 未来新增固定 id 需绕开此值 (注释已标)
4. **PrimaryButton 迁移视觉变化**: cbt_section_field 的 '?' 按钮 + treatment_page 添加按钮从 40pt 默认高升到 50pt Pill 高 — 语义测试继续过, 但视觉验收未跑真机
5. **vent 长按删除 undo**: restore 用 `repo.restore(entry)` 恢复原 id (swipe 路径同款), 但 fake repo restore 自增 id — 生产 repo 语义以 swipe 路径为准, 长按路径现在与其一致
6. **check_strings_hardcoded 规则 1 数字 34**: 与本批无关 (R57 override 配对), 确认无新增
7. 未 commit (按指示), 新文件 + 修改均留 working tree, 与 R112 同批其他 agent 变更混在一起 — 建议按文件分组 commit
