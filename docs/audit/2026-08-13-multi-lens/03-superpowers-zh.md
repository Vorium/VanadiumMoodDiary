# superpowers-zh 视角审计 (docs / i18n / 一致性) (2026-08-13)

核心结论: 文档体系整体滞后 HEAD 10 个版本; i18n 主战场干净但漏 4 个 sibling 文件 12 处; 守门员存在盲区使违规全绿。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| SP-zh-01 | docs | AGENTS.md schemaVersion 声称 12, 实际 22 | AGENTS.md:104 vs app_database.dart:143 | ≤0.5h | P1 |
| SP-zh-02 | docs | AGENTS.md 测试数 2019 过时 (实测 ~2246 pass/9 fail@+129) | AGENTS.md:136,443 | ≤0.5h | P1 |
| SP-zh-03 | docs | AGENTS.md 必读文件死路径 `lib/routing/` → 实际 `lib/core/routing/` | AGENTS.md:107 (同段自相矛盾) | ≤0.5h | P1 |
| SP-zh-04 | docs | 守门员数量声称 18, 实际 21 (3 个新 script 未计入) | AGENTS.md:258,431-436 | ≤0.5h | P2 |
| SP-zh-05 | docs | README 头声称 v0.31.1+108 / 7.8/10, HEAD 已 +129 且 R32 报告未链接 | README.md:5 | ≤0.5h | P1 |
| SP-zh-06 | docs | AGENTS.md 缺 R109 章节 (transient, round 6 收尾时补) | AGENTS.md 尾部 | ≤0.5h | P2 |
| SP-zh-07 | docs+hygiene | pubspec +119 / CHANGELOG +119 vs HEAD +129: **缺 [0.32.0+120..129] 10 段**, check_changelog 自我闭环假绿 | pubspec.yaml:5 / CHANGELOG.md:3 | ≤1h | P1 |
| SP-zh-08 | hygiene | **R32 审计 7 文件 untracked 且已被 VERSION_1_0_PLAN.md 引用 → 死链** | git status `?? docs/audit/2026-08-11-r32-multi-lens/` / VERSION_1_0_PLAN.md:9-10 | ≤0.5h | P1 |
| SP-zh-09 | hygiene | .bak ×2 + .worktrees/ 含 prunable Windows 路径残留, 未 ignore | docs/design/*.md.bak / git worktree list | ≤0.5h | P2 |
| SP-zh-10 | hygiene | 旧审计 2 报告未归档 docs/audit_round84/85 (违反 R108 归档政策) | docs/ 根 | ≤0.5h | P3 |
| SP-zh-11 | hygiene | 3 doc 纯行尾归一化未提交 (920/183/137 行全部 diff) | WHITEPAPER / SENDGRID_SETUP / v0.22_mojibake | ≤0.5h | P3 |
| SP-zh-12 | docs | 2026-08-11-cleanup 文件命名 R110 / 内容 R109 漂移 | 00-FINAL-R110-CONSOLIDATION.md 标题 | ≤0.5h | P3 |
| SP-zh-13 | hygiene | 99 项 working tree 脏 (R109 未收尾), 需归类 3 commit | git status | ≤2h | P2(transient) |
| SP-zh-14 | hygiene | scripts/_archive 99 文件被跟踪, sprint2-zh-hant-tmp 41 文件反复改 | .gitignore:32-33 | ≤0.5h | P3 |
| SP-zh-15 | i18n | **12 处硬编码中文 UI 标题 (带"走 ARB Phase 5 再补"注释), 11/12 key 不存在** | add_medication_page:237,316,459,506 / medication_detail_page:73,132,187 / medication_calendar_page:95,151,204 / refill_manage_page:146,210 | ≤2h | **P1** |
| SP-zh-16 | 守门员 | check_strings_hardcoded.py 只扫 static const, **inline 字面量全漏** (12 处违规仍 [OK]) | scripts/check_strings_hardcoded.py | ≤1h | **P1** |
| SP-zh-17 | i18n | home_header 日期 `年/月/日` 硬编码, 无 en 分支 | home_header.dart:109 | ≤0.5h | P2 |
| SP-zh-18 | i18n | app_routes 中文兜底 '返回首页' | app_routes.dart:170 | ≤0.5h | P3 |
| SP-zh-19 | i18n | presentation 20 处中文 error/note (dev 面为主, 需人工确认无 snackbar 路径) | legal_consent_provider 等 | ≤1h | P3 |
| SP-zh-20 | i18n | domain 量表中文 (~40 label + 6 hotline) = 已知债, v1.0 PHQ-9 i18n | level2_*.dart / whodas / pss / asrm / isi | >1w | P3 |

## 核实闭环 (R32 跨期)

ARB 3 语 1230 key 100% parity · en 无 UI 中文 · zh_Hant OpenCC 100% · fullwidth 0 · R32 B-10 21 处硬编码已清 · C-01 Spring 已接 · C-02 translucent AppBar 已实现 · B-27 check_pii_in_title 已扩 · spec baseline 已闭环

## 总结

1) 文档滞后是最大系统性债 (AGENTS 3 处硬数据全旧 + README 21 commit 前 + CHANGELOG 缺 10 段); 2) i18n 漏 4 sibling 文件 12 处 + 11 幻影 key; 3) 守门员盲区复现 (inline 字面量不查); 4) 仓库卫生未收尾 (untracked 报告死链 / worktree 残留 / tmp 文件); 5) 正面: R109 round 6 收敛 126→9 fail, 提交纪律是剩余风险主因。