# 底层逐行审计 B — presentation + theme + routing (2026-08-13)

范围: lib/presentation/** (199 文件) + lib/core/theme (8) + lib/core/routing (11) + lib/app.dart + lib/l10n (ARB 1230 zh=en parity)。工作树 mid-R109 (ElevatedButton→FilledButton / Card→TrackingItemCard ~50%), 部分 findings 会在 round 7 消失。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| B2-01 | 路由 | **死 push → 404**: 日历空态 "无在用药物" navigate `/medication/new` (未注册) | medication_calendar_grid.dart:66 | 0.2h | **P1** |
| B2-02 | 路由 | **死 push → 404**: 日历空态 "无已排程药物" navigate `/medication/list` (未注册) | medication_calendar_grid.dart:80 | 0.2h | **P1** |
| B2-03 | 路由 | 死 push: contacts 加号 → `/contacts/new`, 无 GoRoute 无表单页 (latent 因 emergencyContactEnabled=false) | contacts_list_widget.dart:43 | 0.5h | P2 |
| B2-04 | 导航 | **/medication 是 ShellRoute 的 sibling**: 底部 NavigationBar/NavigationRail 在用药主页不渲染, 回首页只能系统返回/FAB (R101 P0 只修 2/3 tab) | app_route_main.dart:48-69 vs app_shell.dart:41-46 vs app_route_medication.dart:60-67 | 1-2h | **P1** |
| B2-05 | 导航 | app_shell `_currentIndex` /settings/* 与 /medication/* 分支不可达 (shell 只精确匹配 / 与 /settings) | app_shell.dart:57-73 | 0.2h | P3 |
| B2-06 | i18n | 15 处硬编码中文标题 "走 ARB Phase 5 再补" (与 SP-zh-15 重叠): add_medication 4 / medication_detail 3 / medication_calendar 3 / refill_manage 2 | 见 SP-zh-15 | 1h | **P1** |
| B2-07 | 逻辑 | trend_calendar `_selected` 在 initState 钉死, didUpdateWidget 只跟年/月 → 跨午夜同月后选中停留昨天 (dayChangeTick 重建不修 _selected; v0.22 r28 只覆盖 today 高亮) | trend_calendar.dart:61-80,89 | 1h | P3 |
| B2-08 | ui | medication_page raw `Text('$e')` error + raw CircularProgressIndicator, 而同文件后段已有 ErrorState/LoadingSkeleton 变体 — 双轨渲染路径 | medication_page.dart:193-194 vs :203+ | 0.5h | P3 |
| B2-09 | 功能 | DayDetail "补打卡" 是 SnackBar-only stub (`_onAddLogStub`, ref.invalidate 不 insert) — 点了无持久效果 | medication_calendar_page.dart:240-254 | 2h | P2 |
| B2-10 | ui | consent_dialog raw TextButton + FilledButton 绕过 token 按钮对 | consent_dialog.dart:87,91 | 0.5h | P3 |
| B2-11 | 测试 | vent compose 只有静态 source-grep sanity test, record→play→encrypt→save 全链路无 widget test | vent_compose_page_r93_hide_test.dart | 4h | P2 |
| B2-12 | 测试 | 0 widget test: crisis_hotline / vent_detail / add_medication wizard / medication_detail / refill_manage / calendar_grid 热力图; 无 route-level test (会抓到 B2-01/02/03) | test/presentation/ 盘点 | — | P3 |
| B2-13 | transient | app_list_tile.dart:166 仍 raw Card (R91 未完成); reminders_hub_page 注释有 mojibake `�?` (1/3/6/10/36/120 行) | 上述 | — | round 7 复验 |

## 验证干净项 (⭕ 无问题)

- 路由盘点: 32 push 目标 vs 38 注册路径, 仅 3 死 (上); redirects 正确 (/check-in/medication/:id→/?medId&autofire / safety passthrough / assessment→phq9); /assessment/history 在 /assessment/:id 前 (声明序注释); vent detail int.tryParse 兜底
- transition 频率框架 (emil): fade=3 主 tab / slide-right=子页 / slide-up=rare 全屏 — 7 路由文件一致
- 通知深链: 静态 bind/setLaunchPayload/pendingLaunchLink + ValueNotifier 单例, AppRoot.build bind
- routerProvider: ref.read + _RouterProfileCache + ref.listen invalidate, pageBuilder/redirect 0 watch
- audio 生命周期: vent_detail 3 StreamSubscription cancel + player.dispose 先于 super.dispose; AudioLifecycleMixin 顺序 cancel→stop→dispose recorder→dispose player→delete temp; 0 orphan .listen
- mounted/async: 218 mounted match; weight_widgets:181,184 / notification_status_card:125 / legal_page:77-104 守卫在; timers/controllers 全 dispose
- DateTime.now(): 热门页无双 now race; day 边界 dayChangeTickProvider + AppRoot midnight timer
- Provider 卫生: reminders_hub 只在 handler 读; daily_tracking 8 卡各自 self-watch (R100 模式)
- l10n: zh=en 1230 parity; 1102 l10n.* 引用 0 missing; static_scale 硬编码 = documented v1.0 决策
- IconButton 规则: raw 只在 PressFeedbackIconButton 内部; 页面全走 wrapper
- token: 5 文件 + facade; spring standard (mass1/stiffness200/damping20); theme_provider useStorage=false 测试 override

## 总结

1) 2 个 P1 死路由 404 (0.4h) — route-level test 全部缺失才让它们活到现在; 2) P1: /medication 不在 shell (1-2h) + 15 处硬编码中文 (1h, 与 SP-zh-15 同修); 3) P2: 补打卡 stub / vent 全链路测试 / contacts 死 push; 4) 预定 clean 项: 生命周期 / 深链 / provider 卫生 / token; 5) 层面整体健康, 建议 B2-01/02/04/06 在 R109 round 7 前并入。