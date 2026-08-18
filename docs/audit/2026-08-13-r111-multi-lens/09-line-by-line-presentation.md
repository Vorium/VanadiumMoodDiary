# 底层逐行审计 B — presentation + theme + routing (2026-08-13, R111 复跑)

范围: `lib/presentation/**` (199 文件 — pages 全 feature + providers 18 + widgets 40) + `lib/core/theme/` (8) + `lib/core/routing/` + `lib/main.dart` + `lib/app.dart` + `test/presentation/` (31 + 子目录) 抽查。基线 = 上一轮 `docs/audit/2026-08-13-multi-lens/10-line-by-line-presentation.md` (B2-01~13)。工作树 master 6bbb308 (v0.32.0+140, R110 round 3 之后)。

## Findings (R111 复跑, 含基线 B2 闭环验证)

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| R111-01 | 路由 | **B2-03 跨期残留**: `/contacts/new` 死 push — 全 routing 目录 0 个 `contacts` 匹配, 无 GoRoute 无表单页 (latent 因 emergencyContactEnabled=false, 但 settings 嵌入空态按钮可达) | contacts_list_widget.dart:43; lib/core/routing/ 全 grep 0 命中 | 0.5h | **P2** |
| R111-02 | i18n | **B2-06 家族延伸 (domain 层, 守门员盲区)**: 8/10 量表 displayName/shortDescription 硬编码中文 — settings assessment_section / assessment_center / chart tooltip 直接展示, en 用户看到中文量表名 | isi.dart:36,39 / asrm.dart:37,40 / pss.dart:38,41 / whodas.dart:37,40 / level2_depression:36,39 / level2_anxiety:36,39 / level2_mania:36,39 / level2_psychosis:36,39; phq9/gad7 走 ARB 翻译 | 4h | **P2** |
| R111-03 | 功能 | **B2-09 跨期残留**: 补打卡仍是 SnackBar-only stub (ref.invalidate 不 insert, 无持久效果); R110 round 3 只把文案走 ARB, 未实现 | medication_calendar_page.dart:240-254 (v0.30 R93 task 1.5) | 2h | **P2** |
| R111-04 | ui | **B2-08 跨期残留**: 3 文件 loading/error 双轨 raw 路径 (裸 Text('$e') + raw CircularProgressIndicator), 同文件已有 ErrorState/LoadingSkeleton 变体 | medication_page.dart:193-194 / medication_detail_page.dart:223,226 / mood_trend_page.dart:101-102; today_summary_header.dart:47 | 0.5h | P3 |
| R111-05 | ui | **B2-10 跨期残留**: consent_dialog raw TextButton + FilledButton 绕过 token 按钮对 | consent_dialog.dart:87,91 | 0.5h | P3 |
| R111-06 | ui | 3 处日期格式化绕过 Formatters 集中器 (formatters.dart 已 intl 化, 这 3 处手写 pad 拼串 — en locale 格式仍对, 但跟集中器脱钩) | legal_page.dart:352-356 / last_med_info.dart:70-78 / trend_heatmap_grid.dart:58 | 0.5h | P3 |
| R111-07 | ui | error_state raw ElevatedButton.icon 未迁 PrimaryButton (R65 "9 处迁移" 漏网) | error_state.dart:86-87 | 0.5h | P3 |
| R111-08 | 测试 | **B2-11 跨期残留**: vent compose record→play→encrypt→save 全链路仍无 widget test (r93_hide 仍静态 source-grep) | test/presentation/vent_compose_page_r93_hide_test.dart | 4h | **P2** |
| R111-09 | 测试 | B2-12 部分闭环: R110 round 7b 已补 vent_detail / add_medication / edit_medication_dialog / refill 2x2 + crisis-hotline route-level (home_fab_toolbar_round92); 仍缺 calendar_grid 热力图 + 全局 route 表回归 | 新增 4 测试文件 + home_fab_toolbar_round92_test.dart | — | P3 |
| R111-10 | 杂项 | **B2-13 跨期残留**: reminders_hub_page 22 行注释 mojibake `�?` (GBK 截断) — 纯注释, 0 功能影响; app_list_tile.dart:166 仍 raw Card | reminders_hub_page.dart:1,3,6-10,39-41,53,131,151,187,202,208,210,316,387,452 | 0.2h | P3 |

## B2 基线闭环验证 (R110 round 3 之后)

| ID | 状态 | 证据 |
|---|---|---|
| B2-01 | ✅ 闭环 | medication_calendar_grid.dart:67 → `/medication/add` (原 /medication/new) |
| B2-02 | ✅ 闭环 | medication_calendar_grid.dart:79 → `/medication` (原 /medication/list) |
| B2-03 | ⚠️ 未闭环 | 见 R111-01 |
| B2-04 | ✅ 闭环 | app_route_medication.dart:6 "v0.32 R110 round 3 (B2-04 fix): 4 个 /medication* 路由移进 shell"; app_shell.dart:66-68 `/medication/*` 归 tab |
| B2-05 | ✅ 闭环 | app_shell.dart:66-68 补 /medication 分支; NavigationRail 全 tab 可达 |
| B2-06 | ✅ 主 15 处闭环 / ⚠️ 延伸 | R110 round 3 12 处 ARB + R32 P0-15 21 处; 延伸见 R111-02 |
| B2-07 | ✅ 闭环 (复验健康) | trend_calendar.dart:57,62-70 initState 初始化, :75-80 didUpdateWidget 同年月比较, :90 watch dayChangeTickProvider 跨日重建 — 无钉死 |
| B2-08 | ⚠️ 未闭环 | 见 R111-04 |
| B2-09 | ⚠️ 未闭环 | 见 R111-03 |
| B2-10 | ⚠️ 未闭环 | 见 R111-05 |
| B2-11 | ⚠️ 未闭环 | 见 R111-08 |
| B2-12 | 🔶 部分闭环 | 见 R111-09 |
| B2-13 | ⚠️ 未闭环 (注释级) | 见 R111-10 |

## 验证干净项 (本轮全量复跑 ⭕)

- **死路由全量 grep**: 51 个 push/go 目标, 仅 1 个未注册 (/contacts/new, R111-01); crisis-hotline 真页面 (R92 P0#12), home_fab_toolbar ScrollController 滚顶 (R92 P0#13), /medication 入 shell (R110 round 3)
- **providers 18/18**: iap (StoreKitService.isProSync 内存缓存 + markAsPro 同步), care_strategy (FireCareStrategyUseCase 注册, 0 dead code), assessment (allAssessmentEntriesProvider 带 autoDispose); legal_consent re-export ConsentKind 单 source; mood_list_filter reset 用 identical 去重
- **theme 8/8**: 5 token 集中器 + facade 转发 1:1 (app_tokens 380L 纯转发无重复定义); R32 P1-7 死代码已删 (curveAppleSheet/Drawer); spring.dart 已接 _EntrySpring (check_in_button:241-243 Spring.standard.toSimulation, unbounded controller + dispose); shadow 全 0/极轻 (Apple §3.4.4); Motion 4 档 + reduce-motion 全覆盖
- **shared widgets 40/40 dispose 卫生**: TweenNumber removeListener+dispose; SlideUp/FadeIn _delayTimer cancel; _Shimmer _pauseTimer cancel; AudioLifecycleMixin 4 步链 (cancel sub → stop recorder → dispose recorder → dispose player → delete temp) + playerCompleteSub 显式 cancel; CelebrationBounce/RepaintBoundary
- **隐式排序 0 残留**: AssessmentMultiLineChart:174 + DailyTrackingMultiChart:197,227,261,303 全显式 sort (v0.16 r19 坑)
- **fl_chart 空 dashArray 守护**: _resolveDashArray null 分支 (R90-A/R91 fl_chart 0.69 crash 已知坑, 两 chart 都处理)
- **PageScaffold test 优雅降级**: _canRouterPop try/catch → widget test 无 GoRouter 不崩
- **reduce-motion 覆盖**: FadeIn/SlideUp/CelebrationBounce/_Shimmer/Motion.duration/curve + dimension_row AnimatedContainer (R56 修) + PressFeedback 全走 Motion
- **i18n**: check_strings_hardcoded.py PASS (34 override 对 + inline 0); 12 处硬编码中文 → ARB 已闭环 (R110 round 3); reminder_cards/vent_list/trend_summary 等全 l10n
- **a11y**: AppSemantics container/button/exclude 3 工厂 + liveRegion streak + dimension_row 互斥组
- **零 P0 / 零 P1 残留**: R108 8 个回归 error、R31 17 P0、R110 12 P0 全数闭环 (本文档无 P0/P1 新增)

## 总结

1) **0 P0 / 0 P1 / 3 P2 / 7 P3**, 层面整体健康度显著高于基线轮 (B2 从 2×P1+5×P2 降到 0×P1)
2) P2 三件值得做: R111-01 死路由 (0.5h, 顺手把紧急联系人表单页挂了) / R111-03 补打卡真实现 (2h) / R111-08 vent 全链路 widget test (4h)
3) R111-02 是守门员盲区样板: check_strings_hardcoded.py 只扫 presentation inline, domain 静态 getter 硬编码中文全漏 — 建议给 check_strings_hardcoded.py 加 domain 层规则或升级 R110 决策 "PHQ-9 i18n" 到全 10 量表
4) 其余 P3 均 ≤0.5h 的集中器迁移 (日期格式化 3 处 / raw button 3 处 / mojibake 注释), 可并进 R109 god class 批次顺手清
