# ChronicCare 项目 spec (2026-08-16 审计生成)

> 反映真实架构 / 模块划分 / 已知问题。基于 2026-08-16 十视角审计 (见 .opencode/audit/00-FINAL-CONSOLIDATION.md)。

## 1. 产品

情绪日记 + 树洞倾诉优先、用药记录辅助的精神心理自我关怀 App。零云端, 本地 SQLCipher 加密。永久免费 (无 IAP)。

**4 FeatureFlag**: `ventAudioEnabled=true` / `fiveVendorPushEnabled=false` / `phqGad7I18nEnabled=false` / `bootReceiverEnabled=false`。

## 2. 技术栈

Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6 / flutter_local_notifications 17.2 / fl_chart / pdf。版本 1.1.0+149, schemaVersion 24, export schema v7, ARB 1326 key ×3 语。

## 3. 架构 (4 层 + core umbrella)

```
presentation (UI)  →  domain (业务, 0 Flutter 0 Drift)  ←  data (基础设施)
                        ↑
              core/ umbrella (data/shared/theme/routing/l10n)
```

- `lib/domain/`: entities (`*Entity`) / logic (业务规则 34 文件) / repositories (15 抽象接口) / usecases (3 文件 4 用例, 全活)
- `lib/core/data/`: database (24 schema + migration) / repositories (impl) / services (通知/录音/导出/加密/consent store)
- `lib/core/theme/`: 5 token 集中器 (colors/typography/spacing/motion/spring)
- `lib/core/routing/`: go_router 按 feature 10+ 文件拆
- `lib/presentation/`: providers (按职责拆) / pages (13 feature 目录) / widgets (集中器: AppleListSection/StatCard/PrimaryButton/PressFeedback)
- 验证: `dart scripts/check_all.dart` + 21 守门员 (scripts/check_*.py) + CI (21 守门员全接)

## 4. 模块划分 (按 feature)

| 模块 | 位置 | 隐私边界 |
|---|---|---|
| 情绪日记 (mood) | pages/mood + mood_list + domain/logic/mood_* | 主流程 (记录/列表/回顾/CBT) |
| 树洞 (vent) | pages/vent + vent 表独立 | **绝对隔离** — 不进趋势/通知/评估 |
| 烦恼闭环 (worry) | pages/worry + worry_threads 表 (schema 24) | 属 mood 范畴 |
| 用药 (medication) | pages/medication + 通知/续方 | — |
| 心理评估 (assessment) | pages/assessment + 10 量表 (phq9/gad7 flag 隐藏) | 不进外部通知 |
| 打卡 (check-in) | home + streak | — |
| 每日跟踪 (daily_tracking) | 6 项 (睡眠/体重/社交/压力/治疗/焦虑) | — |
| 心理技巧 (tips) | pages/tips + psychology_tips_library (F3) | — |
| 危机热线 | crisis_hotline_page (5 区域 tel:) | — |

## 5. 数据完整性

- schemaVersion 24, migration dry-run 测试 guard v∈[1,23]
- export v7: 12 表 round-trip + old→new id 重映射; import 3 实体簇 (import_profile/entities/vent)
- SQLCipher + 敏感字段 AES-256 (audit log); 明文音频 temp 文件生命周期 (PIPL §28 关注点)

## 6. 已知问题 (2026-08-16 R114 修复战役后, 详见 .opencode/audit/)

**P0 (上架阻塞, 100% 外部依赖, 代码不可修)**: privacy/support URL 占位 (域名 ICP) / review_information 4 占位 / 双平台截图 (设计师) / ICP 备案 + 软著 (国内商店) / console 4 表单 / **工程闭环 vs 用户闭环脱节** (gdc 主矛盾: 建议注册域名 + sideload 10 真实用户)

**已闭环 (R114 5 wave, 51 项)**: P1×11 (通知死链/录音明文 temp PIPL §28/评估总分 0/裸 scaleId/树洞封存泄漏 PIPL §47/Dismissible 炸树/setup 幂等等) + P2×17 (懒加载 LazyAppleListSection/snooze 降级/cancel 互杀 refill 带 2500000/watchToday 跨日/DST/打卡率分母/DB key 失配恢复/图表 Semantics/inset 统一/swipe-back/import_entities 拆分等) + P3×14 (死代码 6 项/lib lint 清零等) + mood 主流程 ALS 化 (72pt MoodScoreButtons + spring)

**R115 剩余 (代码级, 低优先)**: StatefulShellRoute 分支保活 / mood sheet 化 (v1.0) / AES-CBC→GCM (v1.0, 需数据迁移) / import_entities _importDailyTracking 再拆 (可选)

**法务 (外部, 需律师)**: 3 份 assets/legal 文档律师过审 + 隐私政策邮箱占位替换 + LEGAL_REVIEW_BRIEF 更新

## 7. 路线图

R115: 法务文档律师过审 → 上架外部闸门 (域名 ICP → 设计师资产 → console 表单 → review 真实值) → sideload 10 真实用户验证定位 → v1.0 (2027-Q1: HealthKit / 量表 i18n R51b / AES-GCM / 5 厂商 push)

## 8. 质量门禁 (commit 前)

flutter analyze 0e/0w + lib 0 info · flutter test 2509 pass / 0 fail / 1 skip · 21 守门员全绿 · check_all 双绿 · dart format 0 changed · coverage 阈值 (domain 70% / data 45% / presentation 30%)
