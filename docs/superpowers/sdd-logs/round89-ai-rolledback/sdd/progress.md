# SDD Progress Ledger (v0.30 round 89 — CBT AI 辅助 sub-spec 5)

## Tasks
- [ ] Task 1: AiService + abstract AiProvider + 5 prompt files + mock test (TDD red→green)
- [ ] Task 2: DeepSeekProvider HTTP impl (https://api.deepseek.com/v1/chat/completions)
- [ ] Task 3: AiSettings + 同意 dialog (PIPL §13) + settings AI section
- [ ] Task 4: CbtWizard 集成 3 个 AI 按钮 (替代思维 / 核心信念 / 行动建议)
- [ ] Task 5: i18n 16 ARB keys (zh/en/zh_Hant) + CHANGELOG R89 entry
- [ ] Task 6: Final whole-branch review + fix Critical/Important + merge master

## Plan
- Spec: docs/superpowers/specs/2026-08-05-cbt-ai-design.md
- Plan: docs/superpowers/plans/2026-08-05-cbt-ai.md
- baseline 1487 pass / 0 fail (R88)
- master commit 6dd8127, worktree head e42efcf (spec/plan)
- 5 个 sub-spec 已完成 (eebb8fd / f92bb0e / dc69d70 / 6dd8127)

## Progress
- [x] Task 0: spec + plan committed (e42efcf)
- [x] Task 1: complete (commit 3aa357b, review Approved — AiService + abstract + 5 prompt + 3 mock test, 1490 pass, 0 Critical/Important, 6 Minor: lastUserPrompt 覆盖 / eagerError 双重 / PromptLoader async 预留 / 无 logging / systemPrompt 区分 / 17 守门员 typo)
- [x] Task 2: complete (commit 757c70a, review Approved — DeepSeekProvider HTTP impl + 4 mock test, 1494 pass, 0 Critical/Important, 4 Minor: test Latin1 encoding fix / http.Client dispose / pubspec 顺序 / 无 timeout)
- [x] Task 3: complete (commit a6cdd33, review 1 Critical + 2 Important + 4 Minor → fix round 1 → DONE — AiSettings + 同意 dialog + settings AI section + deadlock 修复 + 重命名 `AiSettings` (revert check_all 豁免) + TextField controller + 错误反馈, 1502 pass, 16+ 守门全绿, 4 Minor 累 ledger)
- [x] Task 4: complete (commit 1a27c9e, review 0 Critical + 2 Important + 4 Minor → fix round 1 → DONE — CbtWizard 3 个 AI 按钮 + aiServiceProvider + hasError helper text + 修正 generateAll 注释, 1507 pass, 16 守门全绿, 5 Minor 累 ledger: cbtLevel=7 hardcoded / test 区分 / error path test / $e 暴露 / 无 wizard 集成)
- [x] Task 5: complete (commit 4b5162a — 32 ARB keys × 3 lang + 4 widget l10n + CHANGELOG R89, 16/16 守门绿 (含 check_orphan_arb_keys + check_strings_hardcoded), 1507/1507 tests pass, 2 Minor: +1 extra key 必要 / CHANGELOG 双 entry 跟 R88 pattern 一致)
