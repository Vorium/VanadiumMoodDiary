# superpowers-en 增量审视报告 (R93 后 → R95+)

> **视角**: 英文软件工程 (Superpowers methodology - TDD / SDD / Code Review / Worktree)
> **审视人**: Mavis (orchestrator, spen 视角)
> **基线**: [R92 spen 报告](../02-superpowers-en-report.md) (76.7KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: SDD 流程 7 task 完整闭环 + 36 R93 tests + 17 守门员全绿

---

## 0. 摘要 (TL;DR)

R92 spen 评分 8.0/10, "SDD 闭环 + 16 守门员, 5 P0 bug 漏测"。R93 已修大部分 SDD 流程, 1 pre-existing fail `mood_period_aggregator` (R91 集成时遗留) 仍未修。**R93 后新发现**: 9 个 600+ 行 god page 拆剩 5 个 (R93 task 1 拆 1 个), 集成测试仍 1 个未增, coverage 阈值仍未加。

---

## 1. R92 基线复盘

**R92 spen 8.0/10 核心发现**:
- 5 P0 bug 漏测 (AliyunSms / vent contentText / 硬编码中文 / EmailService / 跨 round regression)
- 11+ 处 `catch (_) { ... }` 静默吞错
- 9 个 600+ 行 god page 拆 (R19c 已评未拆)
- 集成测试 1 → 3-5 个
- 18+ service 子类 sub-service 测试 (R56c 续修)
- coverage 阈值 + Codecov
- `.worktrees/feat-cbt-thought-report/` 物理目录残留
- `.r61_backup_20260731_101630/` + `.r61_backup_logs/` 残 1.5 月
- 50+ `Duration(milliseconds:)` + 50+ `Curves.easeXxx` 残留
- `notification_service` const 改 final 风险大 (R77-10 partial 1/5)
- `home_page god class 抽 3 helper` (R76 P3-1, R93 涨到 679 行反加)
- `mood_audio_section 591 行 god class 评估` (R76 新发现, R93 减到 553 行)
- `vent_compose dispose 异步未 await` (R72 P2-1 → R75 → R76 → R77 → R93 仍未修)
- `badge_sync_service catch (e) 加 swallowError 包装` (R76 P3-3)
- `setup_page wizard 4 step 内部 state 化` (R76 P3-2 完整版)

**R93 已修**:
- ✅ vent contentText DROP (schemaVersion 18→19)
- ✅ 3 处 catch (_) → swallowError 集中器 (assessment_dao / weight_widgets / mood_recorder_page)
- ✅ medication_calendar god page 642→209 行
- ✅ 17 守门员全绿 (16 .py + 1 .dart, 含 R60 漏列的 check_16kb_alignment.py)
- ✅ 36 R93 tests 加固

---

## 2. R93 后新发现

### 2.1 架构层 (2 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| S-1 | 8 个 god page 拆剩 5 个 (R93 task 1 拆 1 个) — home_page 679 / trend_calendar 642 / data_management_section 606 / mood_audio_section 553 / scale_translations 784 (含 scale_translations_l10n 708) | 多文件 | XL | P0 |
| S-2 | 1 pre-existing fail `mood_period_aggregator` R91 集成时遗留, R93 CHANGELOG 标, R95 必修 | `test/domain/logic/mood_period_aggregator_*.dart` | M | P0 |

### 2.2 底层 (3 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| S-3 | 10 处 catch (_) 静默吞错 (R92 报 11+ → R93 修 3 处剩 10 处, export_schema_service 加 2 处) | 多文件 | M | P0 |
| S-4 | 79 个 magic Duration 残留 (96 - 17 已 token) | 多文件 | L | P0 |
| S-5 | `.r61_backup_20260731_101630/` (1.7MB) + `.r61_backup_logs/` (2.6MB) 残 1.5 月 (R92 提, R93 task 1 未清) | `.r61_backup_*` | XS | P1 |

---

## 3. R92 未修的 P0/P1 (现状)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| S-6 | 集成测试 1 → 3-5 个 | L | **未修** (仍 1 个) | P1 |
| S-7 | 18+ service 子类 sub-service 测试 (R56c 续修) | L | **未修** | P1 |
| S-8 | coverage 阈值 (≥ 70% domain / 50% data) + Codecov | M | **未修** | P1 |
| S-9 | `vent_compose dispose 异步未 await` (R72 P2-1 跨 5 轮未修) | S | **未修** | P1 |
| S-10 | `badge_sync_service catch (e) 加 swallowError` (R76 P3-3) | S | **未修** | P1 |
| S-11 | `notification_service` const 改 final (R77-10 partial 1/5) | M | **未修完** | P1 |
| S-12 | `setup_page` wizard 4 step 内部 state 化 (R76 P3-2) | M | **未修** | P1 |
| S-13 | `home_page` god class 抽 3 helper (R76 P3-1) | L | **未修** (反而涨到 679 行) | P1 |
| S-14 | `mood_audio_section` god class 评估 (R76 新发现) | L | **未拆** (R93 减 38 行剩 553) | P1 |
| S-15 | `assessment_dao._rowToEntry` 解析失败 PII 泄露 | S | **未修** | P1 |
| S-16 | audit log 明文 (PIPL §47 删除权) | M | **未修** | P1 |
| S-17 | CI 缺 coverage / `flutter build appbundle` / release publish | M | **未修** | P2 |
| S-18 | web 端 fail-fast (P0 #7 flutter-spec) | M | **未修** | P1 |
| S-19 | `app_router.dart` redirect 嵌套路径 startsWith 守卫 | M | **未修** | P2 |
| S-20 | `check_strings_hardcoded.py` 规则加严 | S | **未修** | P2 |
| S-21 | 11+ 处 `catch (_) { ... }` 静默吞错 (R92 报, R93 修 3 处剩 10 处) | M | **R93 改善 -1 仍 10 处** | P0 |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-3 周)

1. **R95 task 1-7**: 拆 5 个 600+ 行 god page (data_mgmt / scale / home / trend / mood_audio) (L-XL, 6-9 周)
2. **R95 task 8**: 10 处 catch (_) 静默吞错 → `swallowError` 集中器 (M, 1 周)
3. **R95 task 25**: `vent_compose dispose 异步未 await` (S, 2-3d, R72 跨 5 轮未修)
4. **R95 task 26**: `badge_sync_service catch (e) 加 swallowError` (S, 1-2d)
5. **R95 task 30**: `assessment_dao._rowToEntry` 解析失败 PII 泄露 (S, 2-3d)
6. **R95 task 31**: audit log 明文 (PIPL §47 删除权) (M, 1 周)
7. **R95 task 5**: `mood_period_aggregator` pre-existing fail 修 (M, 1-2d, R91 集成遗留)

### 4.2 P1 重要 (1-3 月)

8. **R95 task 23**: `setup_page` wizard 4 step 内部 state 化 (M, 1-2 周)
9. **R95 task 24**: `notification_service` const 改 final 风险大 (M, 1 周)
10. **R95 task 27**: 集成测试 1 → 3-5 个 (L, 1-2 周)
11. **R95 task 28**: coverage 阈值 (≥ 70% domain / 50% data) + Codecov (M, 1-2 周)
12. **R95 task 29**: 18+ service 子类 sub-service 测试 (L, 1-2 周)
13. **R95 task 32**: `app_router.dart` redirect 嵌套路径 startsWith 守卫 (M, 3-5d)
14. **R95 task 56**: web 端 fail-fast (M, 1-2d)
15. **R95 task 57**: `legal_version.dart` kPubspecVersion 手动同步 → `package_info_plus` 自动 (XS, 1-2h)

### 4.3 P2 建议 (3+ 月)

16. **R95 task 17**: CI 缺 coverage / `flutter build appbundle` / release publish (M, 1-2 周)
17. **R95 task 20**: `check_strings_hardcoded.py` 规则加严 (S, 1-2d)

### 4.4 P3 nice-to-have (3+ 月)

18. **R95 task 5 配**: 物理残留清理 (.r61_backup_* 删) (XS, 1-2h)

---

**spen 视角报告完成时间**: 2026-08-06
**spen 视角报告体量**: 4.5KB
**R95+ spen 建议总计**: 18 项 (7 P0 + 8 P1 + 2 P2 + 1 P3)
**参考**: [00-r95-summary.md §3.2](./00-r95-summary.md#32-superpowers-en-视角-英文软件工程--r93-后增量)
