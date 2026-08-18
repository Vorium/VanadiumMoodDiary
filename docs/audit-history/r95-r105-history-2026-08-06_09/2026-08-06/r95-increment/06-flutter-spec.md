# flutter-spec v3.1 增量审视报告 (R93 后 → R95+)

> **视角**: Flutter v3.1 规范合规 (14 章 + 6 附录, effective_dart / flutter_lints / Riverpod 3.x / Drift / go_router)
> **审视人**: Mavis (orchestrator, flutter-spec 视角)
> **基线**: [R92 flutter-spec 报告](../06-flutter-spec-report.md) (72.8KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: vent contentText DROP (schemaVersion 18→19) + 3 处 catch (_) → swallowError 集中器 + 36 R93 tests 加固

---

## 0. 摘要 (TL;DR)

R92 flutter-spec 评分 **84% 合规** (120/143 项无违规), 6 P0 阻断 (签名 / Podfile / SMS 守卫 / PIPL / PHQ i18n / web 端) + 19 P1 警告 + 25 P2/P3 建议。R93 已修部分 (vent contentText DROP + 3 catch 集中器 + 36 tests)。**R93 后新发现**: 224 TextStyle 集中器化 (R92 提 158, R93 后 224 增 42%), 208 EdgeInsets 集中器化, 96 Duration 集中器化 (79 magic 残留), 10 处 catch (_) 静默吞错。

---

## 1. R92 基线复盘

**R92 flutter-spec 84% 合规 6 P0 阻断**:
- B.1 Android release 签名 (P0 阻断)
- B.2 iOS Podfile 真生成 (P0 阻断, 需 Mac)
- B.3 SMS release 守卫 (P0 阻断, R92 已加 `_isFullyImplemented` 守门员)
- B.4 PIPL §13 同意留痕 (P0 阻断, R82 已修)
- B.5 PHQ-9 / GAD-7 16 题 i18n (P0 阻断, 法务 + 临床审核)
- B.6 web 端 fail-fast (P0 阻断)

**R92 flutter-spec 19 P1 警告**:
- 跨 feature import 守门员覆盖
- `const Strings` 集中器泄露
- 若干 PUA 字符风险
- widget dispose 边界 4 处
- AppDelegate 多余 entry
- TODO/FIXME 注释过密
- 跨年/跨月 DateTime race 守门员
- CI build job
- `dart format --set-exit-if-changed`
- 集成测试少
- setup_page 4 字段 wizard 缺总览
- 6+ 处 `catch (_) { ... }` 静默吞错
- god router facade 拆分 (R57 已修)
- `_RouterProfileCache` 内部 mutable + 手动 sync state
- 其它

**R92 flutter-spec 25 P2/P3 建议**:
- 跨 round 文档化 (1.0 折中方案)
- schemaVersion 注释缺 16→17 placeholder
- PHQ-9 / GAD-7 16 题 i18n 留 v1.0
- 少量 hardcoded string 跟 ARB 重复
- Cursor/.vscode 推荐
- CODEOWNERS 简单
- TextStyle / EdgeInsets 集中器化 (R92 提 158 + 162, R93 后 224 + 208 增 30-40%)
- Duration / Curves 集中器化
- 其它

**R93 已修**:
- ✅ vent contentText DROP (schemaVersion 18→19, PIPL §28 字段级明文清理)
- ✅ 3 处 catch (_) → swallowError 集中器 (assessment_dao / weight_widgets / mood_recorder_page)
- ✅ 36 R93 tests 加固
- ✅ 17 守门员全绿 (16 .py + 1 .dart, 含 R60 漏列的 check_16kb_alignment.py)
- ✅ medication_calendar god page 642→209 行

---

## 2. R93 后新发现

### 2.1 架构层 (2 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| F-1 | 8 个 god page 拆剩 5 个 (R93 task 1 拆 1 个) | 多文件 | XL | P0 |
| F-2 | `notification_service.dart` 450 行 facade + 6 sub — sub 数量已 6, 超 facade 边界, 评估是否再拆 1 层 | `lib/core/data/services/notification_service.dart` | L | P1 |

### 2.2 底层 (4 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| F-3 | 224 TextStyle 中 32 个在主题层 (已算 token), 真正 magic 192 个 | 多文件 | L | P0 |
| F-4 | 208 EdgeInsets 全部 magic 残留 | 多文件 | L | P0 |
| F-5 | 96 Duration 中 17 个已 token, 79 个 magic 残留 | 多文件 | L | P0 |
| F-6 | 10 处 catch (_) 静默吞错 (R92 报 11+ → R93 修 3 处剩 10 处) | 多文件 | M | P0 |
| F-7 | 30+ 硬编码中文业务 hotspot (scale_translations 1528 / home_page 580 / strings.dart 479 / app_colors 538 / main 532 / app_database 502) | 多文件 | L | P0 |

---

## 3. R92 未修的 P0/P1 (现状)

### 3.1 P0 阻断 (R92 报 6, R93 后仍 6)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| F-8 | B.1 Android release 签名 | S | **未修** (仍 debug fallback) | **P0** |
| F-9 | B.2 iOS Podfile 真生成 (需 Mac) | S | **未修** (0.5d, 需 Mac) | **P0** |
| F-10 | B.3 SMS release 守卫 (R92 已加 `_isFullyImplemented`, R93 flag false 强化) | S | **R93 强化** (FeatureFlag 守门) | **P0** |
| F-11 | B.4 PIPL §13 同意留痕 (R82 已修) | — | **✅ 完成** | — |
| F-12 | B.5 PHQ-9 / GAD-7 16 题 i18n (法务 + 临床审核) | L | **未修** (R93 flag false) | **P0** |
| F-13 | B.6 web 端 fail-fast (P0 #7 flutter-spec) | M | **未修** (1-2d) | **P0** |

### 3.2 P1 警告 (R92 报 19, R93 后仍 15+)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| F-14 | 6+ 处 `catch (_) { ... }` 静默吞错 (R92 报, R93 修 3 处剩 10 处) | M | **R93 改善 -1 仍 10 处** | P0 |
| F-15 | god router facade 拆分 (R57 已修) | L | **R57 ✅** | — |
| F-16 | `_RouterProfileCache` 内部 mutable + 手动 sync state (P1 3.6) | M | **未修** | P1 |
| F-17 | 跨 feature import 守门员覆盖 | S | **R57 ✅** | — |
| F-18 | `const Strings` 集中器泄露 | S | **未修** (R57 折中方案) | P3 |
| F-19 | 若干 PUA 字符风险 | S | **R56 守门员 ✅** | — |
| F-20 | widget dispose 边界 4 处 | M | **未修** (1 处 R92 已知 false positive) | P1 |
| F-21 | AppDelegate 多余 entry | S | **未修** (1-2h) | P2 |
| F-22 | TODO/FIXME 注释过密 | XS | **未修** (P3) | P3 |
| F-23 | 跨年/跨月 DateTime race 守门员 | S | **R19B ✅** | — |
| F-24 | CI build job | M | **未修** (.github/workflows/ci.yml 缺) | P1 |
| F-25 | `dart format --set-exit-if-changed` | XS | **未修** (P3) | P3 |
| F-26 | 集成测试少 (1 个) | L | **未修** (仍 1 个) | P1 |
| F-27 | setup_page 4 字段 wizard 缺总览 | M | **未修** (R76 P3-2 完整版) | P1 |
| F-28 | 4 层架构纯度 (`check_all.dart` 跑过) | — | **R19B ✅** | — |
| F-29 | `main.dart:41,54` 顶层 mutable static (P3 1.1) | S | **未修** (3 行) | P3 |
| F-30 | `FeatureFlags` 全局静态可变状态 (P3 1.8) | S | **未修** (R67 注释解释 trade-off) | P3 |
| F-31 | `app_database.dart` 502 字符硬编码中文注释 | S | **未修** (P3, 翻译文档即可) | P3 |
| F-32 | `main.dart` 532 字符硬编码中文错误信息 | M | **未修** (P2, 走 ARB) | P2 |

### 3.3 P2/P3 建议 (R92 报 25, R93 后 20+)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| F-33 | 跨 round 文档化 (1.0 折中方案) | XS | **R19B ✅** | — |
| F-34 | schemaVersion 注释缺 16→17 placeholder | XS | **未修** (P3) | P3 |
| F-35 | PHQ-9 / GAD-7 16 题 i18n 留 v1.0 | L | **未修** (R93 flag false) | P0 |
| F-36 | 少量 hardcoded string 跟 ARB 重复 | S | **未修** | P2 |
| F-37 | Cursor/.vscode 推荐 | XS | **未修** | P3 |
| F-38 | CODEOWNERS 简单 | XS | **未修** | P3 |
| F-39 | TextStyle / EdgeInsets 集中器化 (R92 提 158 + 162, R93 后 224 + 208 增 30-40%) | L | **未修** (反而增加) | P0 |
| F-40 | Duration / Curves 集中器化 (R92 提 50+ + 50+, R93 后 96 + 9) | L | **未修** | P0 |
| F-41 | `lib/core/data/services/export/export_schema_service.dart` 3 处 catch (_) | S | **未修** | P0 |
| F-42 | `data_export_service.dart` vent audio 不导出文件 (跨设备路径失效) | M | **未修** | P1 |
| F-43 | `consolidated/consent_gate.dart:168-174` ConsentKind.safety/vent/analytics 撤回 fallback 硬编中文 | S | **未修** (需 i18n 化) | P1 |
| F-44 | `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted(success: true)` 占位 | S | **未修** (业务真接 SMS 时需调 Flutter MethodChannel) | P1 |
| F-45 | `legal_version.dart` `kPubspecVersion` 手动同步 (P3 1.9) | XS | **未修** (R78+ 考虑 `package_info_plus` 自动) | P3 |
| F-46 | `app_router.dart:50-60` redirect 嵌套路径 startsWith 守卫 (P1 4.3) | M | **未修** | P1 |
| F-47 | `app_router.dart:50-60` redirect 嵌套路径 startsWith 守卫 (P2 4.6) | M | **未修** | P2 |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-3 周)

1. **R95 task 1-7**: 拆 5 个 600+ 行 god page (data_mgmt / scale / home / trend / mood_audio) (L-XL, 6-9 周)
2. **R95 task 3**: 224 TextStyle 集中器化 (保留 PDF 字体 12 个) (L, 1-2 周)
3. **R95 task 4**: 208 EdgeInsets + 96 Duration 中 79 个 magic 集中器化 (L, 1-2 周)
4. **R95 task 8**: 10 处 catch (_) 静默吞错 → `swallowError` 集中器 (M, 1 周)
5. **R95 task 9**: 30+ 硬编码中文业务 hotspot → 走 ARB (L, 1-2 周, +30 ARB keys)
6. **R95 task 12**: PHQ-9 / GAD-7 16 题 i18n 真接 (L, 4-6 周, 法务 + 临床审核)
7. **R95 task 25**: `vent_compose dispose 异步未 await` (S, 2-3d)
8. **R95 task 30**: `assessment_dao._rowToEntry` 解析失败 PII 泄露 (S, 2-3d)

### 4.2 P1 重要 (1-3 月)

9. **R95 task 16**: `notification_service.dart` 450 行再拆 1 层 facade (L, 1-2 周)
10. **R95 task 21**: 集成测试 1 → 3-5 个 (L, 1-2 周)
11. **R95 task 24**: `_RouterProfileCache` 内部 mutable + 手动 sync state 修 (M, 1-2 周)
12. **R95 task 27**: widget dispose 边界 4 处 (M, 1-2 周)
13. **R95 task 28**: CI build job (.github/workflows/ci.yml) (M, 1-2 周)
14. **R95 task 32**: `app_router.dart` redirect 嵌套路径 startsWith 守卫 (M, 3-5d)
15. **R95 task 42**: `data_export_service.dart` vent audio 文件导出 (M, 1-2 周)
16. **R95 task 43**: `consent_gate.dart:168-174` ConsentKind.safety/vent/analytics 撤回 fallback i18n 化 (S, 1-2d)
17. **R95 task 44**: `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted` (S, 0.5d, Mac)

### 4.3 P2 建议 (3+ 月)

18. **R95 task 53**: `main.dart` 532 字符硬编码中文错误信息 → 走 ARB (M, 1-2d)
19. **R95 task 54**: `app_database.dart` 502 字符硬编码中文注释 → 翻译文档 (XS, 1-2h)
20. **R95 task 55**: 少量 hardcoded string 跟 ARB 重复清理 (S, 1-2d)

### 4.4 P3 nice-to-have (3+ 月)

21. **R95 task 56**: `main.dart:41,54` 顶层 mutable static (S, 3 行)
22. **R95 task 57**: `FeatureFlags` 全局静态可变状态 (S, 1-2d, R67 trade-off 重评)
23. **R95 task 58**: `const Strings` 集中器泄露 (S, 1-2d, R57 折中方案重评)
24. **R95 task 59**: schemaVersion 注释缺 16→17 placeholder (XS, 1-2h)
25. **R95 task 60**: TODO/FIXME 注释过密 (XS, 1-2h)
26. **R95 task 61**: `legal_version.dart` `kPubspecVersion` 手动同步 → `package_info_plus` 自动 (XS, 1-2h)
27. **R95 task 62**: Cursor/.vscode 推荐 (XS, 1-2h)
28. **R95 task 63**: CODEOWNERS 简单 (XS, 1-2h)
29. **R95 task 64**: `dart format --set-exit-if-changed` CI 加严 (XS, 1-2h)
30. **R95 task 65**: AppDelegate 多余 entry (S, 1-2h, Mac)
31. **R95 task 66**: 跨 round 文档化 v1.0 折中方案 (XS, 1-2h)
32. **R95 task 67**: PHQ-9 / GAD-7 16 题 i18n 留 v1.0 决策文档 (XS, 1-2h)

---

**flutter-spec 视角报告完成时间**: 2026-08-06
**flutter-spec 视角报告体量**: 7.2KB
**R95+ flutter-spec 建议总计**: 32 项 (8 P0 + 9 P1 + 3 P2 + 12 P3)
**参考**: [00-r95-summary.md §3.6](./00-r95-summary.md#36-flutter-spec-v31-视角--r93-后增量)
