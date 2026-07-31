# tooling 审计报告

> 范围：`D:\Batch\chroniccare\scripts\` + `D:\Batch\chroniccare\docs\`
> 性质：READ-ONLY 审计，无任何文件被修改
> 当前项目版本：`0.25.0+1`（pubspec.yaml）/ `## [0.25.0]`（CHANGELOG.md 顶部）— **一致 ✓**

---

## 1. scripts/ 分类

> 总览：根目录 17 个 `.py`（17 个活跃守门员 + 工具）+ 9 个 `_rXX_` / `_tmp_` 前缀的一次性脚本
> 加 `check_all.dart`（AGENTS #12 守门员）共 18 个「活跃」+ 9 个「归档候选」

### 1.1 Keep — 活跃守门员（12 个在 AGENTS.md 登记 + 4 个 v0.26 R57 新增但 AGENTS 漏更）

| 脚本 | 状态 | 备注 |
|---|---|---|
| `check_arb_keys.py` | Keep | AGENTS #1 + CHANGELOG 多处 |
| `check_changelog.py` | Keep | AGENTS #2 + v0.24 R45 修正加的 |
| `check_cross_feature.py` | Keep | AGENTS #3 + AGENTS 写流程必跑 |
| `check_datetime_race.py` | Keep | AGENTS #4 |
| `check_datetime_race2.py` | Keep | AGENTS #5 |
| `check_drift_namespace.py` | Keep | AGENTS #6 |
| `check_fullwidth_punctuation.py` | Keep | AGENTS #7（v0.27 R59 修正 45 violations） |
| `check_no_hardcoded_utc.py` | Keep | AGENTS #8 |
| `check_no_pua.py` | Keep | AGENTS #9 |
| `check_widget_dispose.py` | Keep | AGENTS #10 |
| `check_orphan_arb_keys.py` | Keep | AGENTS #11（R56e 新增） |
| `check_legal_consent.py` | Keep | **AGENTS 漏更** — v0.26 R57 加，未进 12 守门员清单 |
| `check_sms_release_ready.py` | Keep | **AGENTS 漏更** — v0.26 R57 加，v0.27 R58 降为 warn-only |
| `check_strings_hardcoded.py` | Keep | **AGENTS 漏更** — v0.26 R57 加 |
| `check_zh_hant_consistency.py` | Keep | **AGENTS 漏更** — v0.26 R57 加 |
| `_clean_orphan_arb_keys.py` | Keep（保留） | 一次性工具但 docstring 明确说「保留方便未来又有 orphan 时手工清理」+ commit `5f12111` 记录保留意图 |
| `make_icon_preview_v5.py` | **Archive 候选** | 不在任何文档/CHANGELOG 引用，v1-v4 已在 `_archive/`，v5 同样无引用 → 见 §1.4 |

> ⚠️ **AGENTS.md 漏更 4 项**：AGENTS.md 写「12 守护脚本清单 (v0.25 round 56e 后)」但 v0.26 R57 (commit `4ce7bf9`) 实际新增 4 个守门员，**当前真实数 = 16**。需 R60 修正 AGENTS。

### 1.2 Archive — 9 个一次性脚本（全部 `_rXX_` 前缀，可放心归档）

| 脚本 | 用途（docstring） | 为何可归档 |
|---|---|---|
| `_r49_dark_mode_color_replace.py` | v0.25 R49 (emil P0 #1) 60+ 处 dark mode color → dynamic getter | 替换已完成 + 后续由 `check_no_pua.py`/`check_no_hardcoded_utc.py` 守门 |
| `_r49_remove_const_for_dynamic_color.py` | v0.25 R49 sub-task 删 const 关键字 | 同上 |
| `_r49_remove_const_v2.py` | v0.25 R49 v2（行内 const 模式） | 同上；v1/v2 两版都归档（v2 替代 v1） |
| `_r53a_dedup_imports.py` | v0.25 R53a 7 DAO 重复 import 去重 | 一次性去重 + 后续 `dart fix --apply` 会自动处理 |
| `_r53a_fix_dao_imports.py` | v0.25 R53a 修 7 DAO `app_database.g.dart` import 错 | 一次性修正 |
| `_r53a_remove_g_imports.py` | v0.25 R53a 删 7 DAO `.g.dart` import | 一次性修正（与上一条互补） |
| `_r56b_spacing_tokenize.py` | v0.25 R56b 46 处 SizedBox → spacing token | 替换已完成（emil P1 batch） |
| `_r56_icon_size_replace.py` | v0.25 R56 32 处 icon size → token | 替换已完成 |
| `_r59_fix_underscore.py` | v0.25 R59 单文件 (`app_routes.dart`) 4 行 `_` → `__` 修正 | 单文件、单行替换、再无残留 |

> 全部带 `_rXX_` 前缀，按现行 AGENTS.md §命名约定（`v0.16 round 9-11` 起 1-shot 脚本归档 `_archive/`）应统一进 `_archive/`。已存在的 `_archive/`（`audit_zh_hant.py` / `batch_replace_snackbar.py` / `_tmp_fix_pua.py` / `_tmp_replace_snackbar.py` 等）即是同类先例。

### 1.3 Verify — 需要 grep 二次确认

- 无（已逐文件 docstring + git log + 全项目 grep 验证完）

### 1.4 用户可能误以为「重要」但实为 one-off 的脚本

| 脚本 | 容易被误以为 | 实际 |
|---|---|---|
| `make_icon_preview_v5.py` | 「v5」名字看起来像当前活跃工具 | 营销预览图生成器，v1-v4 都在 `_archive/`，**v5 也应归档**。全项目 grep 仅它自身引用 |
| `_clean_orphan_arb_keys.py` | 名字带 `clean` 像日常工具 | docstring 自述「一次性工具，保留方便未来手工清理」+ 39 个 orphan key 写死硬编码列表（`ORPHANS = [...]`），不通用 |

---

## 2. test/ 健康度

- **110 个测试文件**（6 个子目录 + scripts/ test）
- **全部匹配 `*_round\d+\w*_test.dart` 模式**（含 sub-iteration 后缀如 `_round45d_` / `_round61c3_` / `_round19b_`）
- **无 0-test 文件**：所有文件 `expect(...)` 调用 ≥ 2（最小是 `app_snack_bar_round14_test.dart` = 7 个 expect；`vent_compose_stop_and_cleanup_round48_test.dart` = 3 个 expect；`streak_calculator_round3_test.dart` = 3 个 expect）
- **无 `expect(true, true)` 占位文件**：grep 0 命中
- 文件名不严格匹配但仍合规的（如 `app_root_round17_midnight_test.dart` / `medications_list_split_round45d_test.dart`）都是 `module_roundN_sub_test.dart` 变体，跟现行 R56c-R56c''' 引入的 sub-iteration 命名一致

> ✅ test/ 无任何 actionable 问题

---

## 3. docs/CHANGELOG.md vs pubspec.yaml

| 检查项 | 结果 |
|---|---|
| CHANGELOG 顶部 `## [0.25.0]` vs pubspec `0.25.0+1` | **一致 ✓** |
| 版本段顺序（倒序） | **正确 ✓**（v0.25.0 → v0.1.0+1 倒序） |
| 时间倒置 bug | 已修正（v0.24 R45 spzh P0-of-P0 修正过） |
| 版本号跳号 | v0.12.0 → v0.8.0（缺 0.9/0.10/0.11）— 这是因为这些 round 直接 bump 到 0.12 而非 0.9，**非 bug**，项目里没 0.9/0.10/0.11 |
| 旧版本条目是否应清 | v0.1.0+1 / v0.5.0 / v0.6.0 / v0.7.0 / v0.8.0 是 7/11-7/12 起点记录，Keep a Changelog 格式推荐保留 |
| CHANGELOG 中 `1098 tests pass` vs 实际 110 个测试文件 | 一致 ✓（AGENTS.md 注明 1098 cases） |

> ✅ CHANGELOG 无 actionable 问题

---

## 4. docs/ 陈旧文件

| 文件 | 末次修改 | 距今 | 状态 | 备注 |
|---|---|---|---|---|
| `PRD-v0.1-draft.md` | 7/15 | 12d | **stale** | 标题写「v0.15 草稿」但项目已 v0.25（10 minor 落后），文件名还叫 `v0.1-draft` 而内容是 v0.15（命名漂移） |
| `CODE_REVIEW_v0.17r12.md` | 7/17 | 10d | **stale** | 标题硬编码 v0.17 round 12，8 minor 落后；v0.27 R58 已重审 (`review-superpowers-en-v027.md`)，本文件应归档 |
| `P2_COMPLIANCE_REVIEW.md` | 7/18 | 9d | **stale** | 「P1 全部 28 项 done」基线（v0.18 初），9d 落后；后续 v0.27 已做完整三视角审视（`docs/reviews/`） |
| `P2_DESIGN_REVIEW.md` | 7/18 | 9d | **stale** | 同上，emil 视角已被 `audit-emilkowalski-topdown.md` 取代 |
| `P2_SYSTEM_REVIEW.md` | 7/18 | 9d | **stale** | 同上，被 v0.27 审视取代 |
| `GIT_WORKFLOW.md` | 7/17 | 10d | **可保留** | 标注「v0.17 round 14 / P3-2」但内容是日常 git 流程（master 单 branch / 不走 PR），跟当前 v0.27 实操一致；标记版本号属历史 tag 而非 stale |
| `CHINESE_COMMIT_GUIDE.md` | 7/20 | 7d | **可保留** | 中文 commit message 规范，git log 确认项目至今仍用此格式（如 `v0.27 round 59: 三视角 P0/P1 修正批次 1`） |
| `SENDGRID_SETUP.md` | 7/20 | 7d | **可保留** | mock-only 状态说明（v0.22 R29 spzh 修正过 6 处文档错误） |
| `WHITEPAPER.md` | 7/20 | 7d | **可保留** | 当前最新一份产品白皮书，CHANGELOG v0.22.0 提过 §5/§6/§13/§14.3 同步完成 |
| `DEPLOYMENT.md` / `PUSH_PROVIDERS.md` / `SMS_PROVIDERS.md` | 7/26 | 1d | **活跃** | v0.25 R54-R55 新增/修正 |
| `terminology.md` | 7/27 | 0d | **活跃** | v0.27 R59 新增 |

> **建议**：把 `PRD-v0.1-draft.md` / `CODE_REVIEW_v0.17r12.md` / `P2_*.md` 3 个文件（6 个文件含 P2 三个）移到 `docs/archive/reviews/v0.18/` 下，与 `docs/archive/reviews/v0.22/` 风格一致。

---

## 5. Actionable 清单（按优先级）

1. **AGENTS.md 修正**（P1，文档同步）
   - 「12 守护脚本清单」段补 4 项 v0.26 R57 新增守门员：`check_legal_consent.py` / `check_sms_release_ready.py` / `check_strings_hardcoded.py` / `check_zh_hant_consistency.py`
   - 真实数 = 16（不是 12）
2. **scripts 归档**（P2，9 个 one-off 脚本 → `_archive/`）
   - `_r49_*.py` × 3（dark mode color + const 修正 v1/v2）
   - `_r53a_*.py` × 3（DAO import 修正 3 步）
   - `_r56b_spacing_tokenize.py` / `_r56_icon_size_replace.py`
   - `_r59_fix_underscore.py`
   - `make_icon_preview_v5.py`（v5 跟 v1-v4 一起进 `_archive/`，统一营销预览图工具归位）
3. **docs 归档**（P2，6 个 stale review 文件 → `docs/archive/reviews/v0.18/`）
   - `PRD-v0.1-draft.md`（重命名建议 `prd-v015-draft.md` 或直接归档）
   - `CODE_REVIEW_v0.17r12.md`
   - `P2_COMPLIANCE_REVIEW.md` / `P2_DESIGN_REVIEW.md` / `P2_SYSTEM_REVIEW.md`
4. **reports/ 清理**（P3，27 个 `_check_callers*.ps1` + `_callers6.log` + 5 个 `_thumb_v4_*.png` + 2 个临时 `.py` 是未追踪临时工件，可考虑加 `.gitignore` 模式 `_*`）

---

## 6. Summary

- ✅ **CHANGELOG vs pubspec 一致**（0.25.0+1）
- ✅ **test/ 全健康**（110 文件 / 0 个空测 / 全匹配命名）
- ⚠️ **AGENTS.md 漏更 4 个守门员**（v0.26 R57 增的 4 个，应从 12 → 16）
- 📦 **9 个 `_rXX_` 一次性脚本可归档**（含 v1-v4 已归档的同类 `_r56_`/`_r59_` 等）
- 📦 **`make_icon_preview_v5.py` 误判风险高**（名字像活跃工具，实质是营销预览图生成器）
- 📦 **6 个 docs/ 文件陈旧**（v0.17/v0.18 era 的 1-shot review 报告，落后 8-10 minor）
