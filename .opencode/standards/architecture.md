# 架构规范 (architecture.md)

> 来源: 项目 4 层架构决策 (AGENTS.md) + 高内聚低耦合通用原则 (2026-08-16)

## 分层
```
presentation (UI)  →  domain (业务, 0 Flutter)  ←  data (基础设施)
                        ↑
              core/ umbrella (data/shared/theme/routing/l10n)
```
- domain 实体 `*Entity` 后缀; drift @DataClassName 单数
- mapper 放 data 层 (不放 domain)
- 接口放 domain/repositories (abstract); 实现在 data/repositories (`*RepositoryImpl`)
- presentation 通过 Provider<X>(...) 暴露接口, 不暴露 impl

## 内聚与耦合标准
- 高内聚: 一个 feature 的实体/逻辑/页面/路由在一个目录; 1 页面 = 1 目录
- 低耦合: 跨 feature 只有 hub (home/settings) 可 import 子 feature 入口
- 共享 widget 放 presentation/widgets/ (跨 feature 复用)
- provider 小且专 (≤150L 为佳); services 单一职责
- god class ≥400L 且多职责 → 拆; 数据表 (scale_translations) / 纯 token 文件豁免

## 编排层 (usecase)
- domain/usecases 负责跨依赖编排 (切断 data↔presentation 依赖)
- 允许服务直连 logic (编排核心在 Riverpod notifier + service), usecase 不强制厚化

## 数据完整性
- schemaVersion 变更必须 migration + dry-run 测试 (v∈[1,24] guard)
- export/import round-trip 测试覆盖每张表 (v7: 全部 12 表)
- 隐私边界: vent (树洞) 绝对隔离 — 不进 trend/assessment/notification
- 通知 ID 区间不重叠; cancel 范围公式匹配

## 重构准则
- 优先修 bug 与数据完整性, 再谈结构
- feature-first 重构 (lib/features/): 当前判定不值得 (纯 move 2-3 周 0 行为收益)
- pub workspace: 零云端无消费者, 不做
- 拆 god class 按"真 god class"判定 (931L pipeline 已拆; 页面规模文件维持)
