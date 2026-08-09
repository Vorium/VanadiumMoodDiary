# R108 Revisit 审视指令

> 给 7 视角 + 顶层架构 + 底层逐行 subagent 共用。
> 输出位置: `docs/audit/2026-08-10-r108-revisit/`

## 任务

从 0 开始,基于项目当前状态(working tree 含 R108 进行中工作)做独立审视。
**不要看 `docs/audit-history/` 下任何旧报告**(那是 R107 cleanup 等历史基线,参考用,但不能照抄结论)。
**不要修改任何代码 / commit / 推送**。只输出报告。

## 项目背景

- 路径: `D:\Batch\chroniccare`
- 栈: Flutter 3.44.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
- 产品: 精神心理患者吃药打卡 App(本地加密、零云端、4 层架构)
- 必读: `AGENTS.md` + `README.md`
- 旧基线: `docs/audit-history/r107-cleanup-2026-08-10/00-summary.md`(仅供理解历史,不要照抄)

## 当前 baseline 状态(重要)

- HEAD: `ac2be71 v0.30 round 100: R100 六视角审计修复 — P0 5 项 + P1 7 项全部闭环`
- working tree: **30+ modified, 26 deleted(已 staged)**
- `flutter analyze`: 118 issue(全是 warning,0 error)
- `flutter test`: 124 fail + 1 skip + 1405 pass(**working tree 是 R108 进行中状态,124 fail 是 R108 在做的工作**)
- 已知 R108 进行中:
  - `lib/core/data/services/notification_delegate.dart`(新增,完成)
  - `lib/core/data/services/mood_reminder_notifier.dart`(新增)
  - `lib/core/data/utils/skip_backup.dart`(新增)
  - `lib/core/shared/date_utils.dart`(新增)
  - `lib/domain/logic/medication_slot_calculator.dart`(新增)
  - `lib/presentation/pages/home/controllers/`(新增,主页 controller 重构)
  - `lib/presentation/pages/medication/{medication_page,add_medication_page,medication_detail_page}.dart`(可能 god class 拆分中)
  - `lib/presentation/pages/mood_list/{mood_detail_page,mood_trend_page}.dart`(新增)
  - `lib/main/`(可能 main.dart 拆分中)
  - `test/core/data/services/notification_delegate_round108_test.dart` 等 14+ 个 round108 lock-in test
  - `TODO_R108.md`(R108 P0 #11-#13 任务清单)
  - 域名占位 + 邮箱占位 + 截图脚本 + keystore 脚本等

**subagent 必须认识到**:
1. working tree 是真实状态,不是干净状态
2. R108 进行中的代码可能未完成,不要因为 test fail 给 P0(那是工作进度)
3. 但**底层 bug** + **架构问题** + **上架问题** + **文档问题**等,都是审视目标

## 输出文件格式

每个 subagent 输出一个 markdown 文件,文件名:
- 7 视角: `lens/01-emil.md` ~ `lens/07-apple-health.md`
- 顶层: `08-architecture.md`
- 底层: `09-bottom-up-bugs.md`

每个文件结构(必须遵守):

```markdown
# <视角名> 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: <emil|superpowers-en|superpowers-zh|appstore|googleplay|flutter-spec|apple-health|architecture|bottom-up>
- 审视者: <subagent name>
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D
- 范围: <1 段说明 subagent 看了哪些文件/目录>

## 1. 整体评分(0-10)
<分数> — <1 句话理由>

## 2. 关键发现(按 P0/P1/P2/P3 排序,每项含架构/底层标签 + 修复难度)

### P0(必修,阻塞上架/严重 bug)
- [架构|底层] **[P0-001] 标题** — 修复难度:<S|M|L|XL> — 工作量:<Xh|Xd>
  - 位置: <file:line>
  - 现状: <1-2 句>
  - 建议: <1-2 句>
  - 外部链接检查: <是否涉及外链/域名/邮箱/URL,需隐藏>

### P1(应修,影响品质)
...

### P2(可修,优化)
...

### P3(建议,长期)
...

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查
- 列出所有扫描到的 <a href> / URL / 邮箱 / 域名(包含哪些已经隐藏,哪些未隐藏)
- 表格: 位置 | 内容 | 状态(已隐藏/未隐藏/占位符)

## 4. 上架 / 架构 / 重构 / 半成品问题
按用户要求的 4 类分别列:
- 4.1 上架相关(必填,影响 iOS/Android/Privacy)
- 4.2 架构相关(可选,顶层架构 subagent 必须深写)
- 4.3 重构建议(可选,顶层架构 subagent 必须深写)
- 4.4 半成品 / TODO / 残缺功能(必填,跨 subagent 重点)

## 5. 总结 + 给整合者的建议
<1 段,关键 takeaway>

## 附录: 详细证据
<subagent 自己组织,grep 输出、文件引用等>
```

## 关键约束

1. **不要修改代码 / commit / 推送**
2. **不要参考 R107 cleanup 旧报告做结论**,只能参考 AGENTS.md / README.md / 实际代码
3. **必须遍历代码**(用 read / grep / glob)
4. **架构 vs 底层标签**:
   - 架构 = 跨模块设计(分层、依赖、god class、抽象层)
   - 底层 = 单文件 bug / 错误处理 / 资源泄漏 / 类型错误
5. **修复难度**:
   - S = 1-2 小时
   - M = 半天
   - L = 1-2 天
   - XL = 3-5 天或更长
6. **P0/P1/P2/P3 标准**:
   - P0 = 阻塞上架 / 严重功能 bug / 数据丢失 / 合规
   - P1 = 显著影响体验 / 重要功能缺失
   - P2 = 优化 / 一致性
   - P3 = 锦上添花 / 长期

## 完成后

1. 写完报告后,在文件末尾加一行:
   ```
   <!-- subagent: <name> 完成时间: <ISO timestamp> -->
   ```
2. 用文字回复主 agent: "报告已写到 docs/audit/2026-08-10-r108-revisit/<file>.md,共 N 个 P0, M 个 P1"

## 主 agent 整合

主 agent 拿到所有 subagent 报告后,会:
1. 写 `00-FINAL-CONSOLIDATION.md` 整合(标架构 vs 底层 + 难度 + 优先级 + 整合修复路线)
2. 更新 README.md / docs/VERSION_1.0_PLAN.md / AGENTS.md
3. 最终 commit

subagent 不用做整合,只做自己视角的审视。
