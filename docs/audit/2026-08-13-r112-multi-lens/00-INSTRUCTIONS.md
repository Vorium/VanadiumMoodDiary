# R112 多视角综合审视指令 (2026-08-13)

> 给 9 个 subagent 共用: 6 视角 + 顶层架构 + 2 路底层逐行。
> 输出位置: `docs/audit/2026-08-13-r112-multi-lens/`

## 任务

从 0 开始, 基于项目当前状态 (working tree 含 R112 进行中工作) 做独立审视。
**不要照抄 `docs/audit/2026-08-13-r111-multi-lens/` 及任何历史审计报告的结论** — 只可从旧报告了解"哪些已宣称闭环"然后**自己去代码里验证**是否属实。结论必须来自本次实读代码。
**绝对不要修改任何代码 / commit / 推送**。只输出报告。

## 项目背景

- 路径: `/Volumes/macssd/Batch/chroniccare`
- 栈: Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 产品: 精神心理患者吃药打卡 App (本地加密、零云端、4 层架构)
- 必读: `AGENTS.md` + `README.md` (进项目先扫这两个)
- 规模: 421 dart 文件 ~90K+ 行, schemaVersion 22, 3 语 ARB

## 当前 baseline 状态 (重要)

- HEAD: `6bbb308` 0.32.0 round 7b-6 (R110 round 3 + round 7a/7b 测试批已 commit)
- working tree: **127 modified + 13 untracked** (R112 = R111 hotfix 计划执行中)
- `flutter analyze`: **0 error / 3 warning / 133 info** (主 agent 实测)
- `flutter test`: **2377 pass / 4 fail (全为 iOS 资产占位, 外部依赖) / 1 skip** (主 agent 实测)
- R112 进行中的未提交工作 (审视时当作"进行中代码", 但其中新代码同样要审质量):
  - export/import JSON schema **v5 升级** (E1/E2 修复): `lib/core/data/services/export/{export_import_pipeline,export_orchestrator,export_schema_service}.dart` + 新测试 `test/data/data_export_v5_round8_test.dart`
  - `user_name_helper.dart` 从 `lib/core/shared/` 移到 `lib/domain/logic/` (D + ??)
  - 新增 `lib/presentation/services/scale_name_l10n.dart` + `lib/presentation/widgets/mood_label.dart` (EM-21 修复?)
  - 新增 `scripts/check_review_information_todo.py` (AS-16 守门员)
  - `lib/core/data/services/{notification_service,safety_alert_builder,safety_alert_sender_impl,safety_watch_service}.dart` 修改
  - `lib/domain/logic/{asrm,isi,email_template,lost_contact_sms,level2_*}.dart` 等量表修改
  - `lib/domain/entities/tracking_item_config.dart` 修改
  - fastlane metadata (notes.txt / description / short_description / changelogs) 修改
  - 新测试: `test/domain/static_scale_translations_round8_test.dart` (SP-111-04) / `test/presentation/reminders_hub_safety_gate_round8_test.dart` / `test/presentation/notification_status_card_permission_round8_test.dart` / `test/presentation/pages/medication/medication_backfill_round8_test.dart` 等
  - 未入库: `docs/audit/2026-08-13-r111-multi-lens/` (R111 报告, untracked)

**subagent 必须认识到**:
1. working tree 是真实状态; R112 进行中的代码可能未完成, 不要因为"进行中"给 P0 (那是工作进度)
2. 但新写的代码质量 (bug / i18n / 架构 / 测试) 同样是审视目标
3. 旧报告宣称已闭环的项目 (如 R110 12 P0、R111 E1/E2), 必须实读代码验证

## 输出文件

每个 subagent 输出 1 个 markdown 文件:

| subagent | 输出文件 |
|---|---|
| 01 emil (设计/UX) | `01-emil.md` |
| 02 superpowers (工程实践) | `02-superpowers.md` |
| 03 flutter-spec | `03-flutter-spec.md` |
| 04 appstore | `04-appstore.md` |
| 05 googleplay | `05-googleplay.md` |
| 06 apple-health | `06-apple-health.md` |
| 07 顶层架构 | `07-top-level-arch.md` |
| 08 底层逐行 domain+data | `08-line-by-line-domain-data.md` |
| 09 底层逐行 presentation+core | `09-line-by-line-presentation.md` |

## 文件结构 (必须遵守)

```markdown
# <视角名> 审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: <...>
- 审视者: <subagent name>
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M 13??
- 范围: <1 段说明看了哪些文件/目录, 列出关键文件清单>

## 1. 整体评分 (0-10)
<分数> — <1 句话理由>

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0 (必修, 阻塞上架/严重 bug)
- [架构|底层] **[P0-001] 标题** — 修复难度:<S|M|L|XL> — 工作量:<Xh|Xd>
  - 位置: <file:line>
  - 现状: <1-2 句>
  - 建议: <1-2 句>

### P1 (应修, 影响品质)
... (格式同上)

### P2 (可修, 优化)
### P3 (建议, 长期)

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (只扫描 lib/ + fastlane/ + docs/)
- 表格: 位置 | 内容 | 状态(已隐藏/未隐藏/占位符)

## 4. 四类问题 (用户点名)
- 4.1 上架相关
- 4.2 架构相关 (07 顶层架构必须深写)
- 4.3 重构建议 (07 顶层架构必须深写)
- 4.4 半成品 / TODO / 残缺功能

## 5. 总结 + 给整合者的建议

## 附录: 详细证据 (grep 输出、文件引用)
```

## 关键约束

1. **只读, 绝不改代码/commit/push**
2. **结论必须来自本次实读代码** (read/grep/glob); 旧报告只能当"待验证清单"
3. **必须遍历范围内的代码**; 底层逐行两个 subagent 尤其要遍历范围内每个 dart 文件
4. **标签**: 架构 = 跨模块设计 (分层/依赖/god class/抽象); 底层 = 单文件 bug/错误处理/资源泄漏/类型错误
5. **难度**: S=1-2h, M=半天, L=1-2d, XL=3-5d+
6. **P0/P1/P2/P3**: P0=阻塞上架/数据丢失/合规/严重 bug; P1=显著影响体验/重要缺失; P2=优化/一致性; P3=长期
7. 每项发现标上唯一 ID (如 EM-xx / SP-xx / FS-xx / AS-xx / GP-xx / AH-xx / AR-xx / E-xx / R112-xx, 避免与旧报告 ID 混淆可用 R112-xx)
8. 完成后文件末尾加 `<!-- subagent: <name> 完成时间: <ISO> -->`, 并回复主 agent 摘要 (N 个 P0 / M 个 P1)

## 主 agent 整合 (subagent 不用做)

主 agent 拿到 9 份报告后: 写 `00-FINAL-CONSOLIDATION.md` (标架构 vs 底层 + 难度 + 按优先级排序 + 修复路线) → 更新 spec/README/AGENTS。
