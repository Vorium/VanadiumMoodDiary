# 七视角审视 — 共享上下文

> **项目**：chroniccare v0.27.0+62（精神心理患者吃药打卡 App，本地加密零云端）
> **栈**：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 (SQLCipher) / go_router 14.6
> **日期**：2026-07-31
> **基础报告**：
> - `reports/CONSOLIDATED-AUDIT-v0.27.md`（700+ 行综合审计）
> - `docs/reviews/2026-07-26-three-lens/{emil,spen,spzh}/report.md`（上次 3 视角）
> - `docs/reviews/2026-07-31-three-lens/consolidated.md`（3 视角整合 R60+）
> - `docs/reviews/2026-07-31-three-lens/{emil-v0.27+,spen-v0.27+}.md`（R60+ 增量）
> - `docs/CHANGELOG.md` 顶部 Unreleased（R62 修正起点）
> - `AGENTS.md`（项目代码视角导览）
> **关键约束**：
> - 域 0 Flutter / 0 Drift（domain 层）
> - 树洞（vent）数据隐私边界绝对不能进通知/趋势/关怀
> - 已有 16+1 守护脚本（`scripts/` 下）

---

## 文件规模（必须知道）

| 类别 | 数量 |
|---|---|
| lib/ .dart | **239** |
| test/ | 121 |
| scripts/ (Python + Dart) | 135 |
| docs/ | 55 |
| pubspec | 65 行 |
| AGENTS.md | 254 行 |

---

## 项目 4 层 + 5 共享 umbrella 架构

```
lib/
├── main.dart
├── app.dart
├── core/                  # 基础设施 umbrella
│   ├── data/              # Database / Repositories / Services / Utils
│   ├── shared/            # formatters / json_codec / mood_visual
│   ├── theme/             # AppTokens + M3 主题
│   ├── routing/           # go_router
│   └── l10n/              # domain 层 strings(通知/邮件 fallback)
├── l10n/                  # presentation 层 flutter_localizations
├── domain/                # 0 Flutter 0 Drift 业务层
│   ├── entities/         # *Entity 后缀
│   ├── logic/            # 业务规则
│   ├── repositories/     # 抽象接口
│   └── usecases/         # 用例
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers
    ├── pages/             # 8 个 feature 子目录
    └── widgets/
```

---

## 关键已知项（避免重复发现）

1. **schemaVersion = 14**（R60 D1 修正过 12→14 漂移）
2. **pubspec.version = 0.27.0+62**（R62 修正过 0.25.0+1 漂移）
3. **已 16+1 守护脚本全绿**（含 check_no_pua / check_orphan_arb_keys / check_legal_consent / check_sms_release_ready / check_strings_hardcoded / check_zh_hant_consistency）
4. **P0-1 SmsGateway** 仍 ⏳（等法务 + 阿里云 AccessKey 审核）
5. **P0-2 PIPL §13/§14 真正实现** 仍 ⏳（文档有 + 假实现）
6. **R62 修正起点**：P0-3 通知 3 态分流（SafetyAlert sent/mocked/failed）+ assessment_record 修正 + SmsService 单例 + 11 处 P1 修正

---

## sub-agent 工作守则

**必须遵循**：
- 用 ripgrep (`Select-String` / `Get-ChildItem -Recurse`) 模式扫描，**不要全量读 239 个文件**
- grep 关键 pattern 列举：`int.parse` / `DateTime.now()` / `Future.delayed` / `setState` / `dispose` / `print(` / `TODO` / `hardcode` / 硬编码中文字符串 / `Magic` 数字 / `try {` + 异常吞 / `dark mode` 等
- 重点 read 关键文件：`lib/main.dart` / `lib/app.dart` / `lib/core/data/database/app_database.dart` / `lib/core/routing/app_router.dart` / `lib/presentation/providers/core_providers.dart` / `lib/domain/logic/care_engine.dart`
- 输出**精炼**（控制在 30KB 以内），每条问题带"行号"或"文件路径"定位
- 顶层架构审视 = 2-5 条建议（高内聚低耦合）
- 底层逐行排查 = 5-15 条具体问题（按视角重要性排序）
- 标记：架构 vs 底层 / 修复难度 S/M/L / 优先级 P0/P1/P2/P3

**禁止**：
- 全量 `Get-Content lib/**/*.dart`（会爆 context）
- 重复发现已修问题（看 `CHANGELOG.md` Unreleased 段）
- 输出无定位的泛泛建议

---

## 视角清单 + 输出文件名

| 视角 | 报告路径 | sub-agent 重点 |
|---|---|---|
| emil (UI/动效/设计) | `emil/report.md` | AppTokens / 暗色 mode / 动效 / 文字 token / spacing |
| superpowers-en (TDD/调试/规范) | `spen/report.md` | TDD 覆盖 / 隐式排序 / DateTime race / null safety / BuildContext |
| superpowers-zh (中文/合规/PIPL) | `spzh/report.md` | 中文命名 / 隐私政策 / PIPL §13 §14 / 单独同意 / ARB 同步 |
| AppStore | `appstore/report.md` | iOS 上架 / 隐私 / IAP / 元数据 / iPad / 截图 |
| GooglePlay | `googleplay/report.md` | Android 上架 / 64-bit / 权限 / 隐私 / 目标 SDK / 数据安全 |
| 阿里巴巴开发规范 | `alibaba/report.md` | 命名 / 异常 / 日志 / 性能 / 注释 / 魔法值 |
| Flutter 开发规范 | `flutter/report.md` | Effective Dart / Widget 树 / 性能 / 平台适配 |

---

## 输出格式（每视角统一）

```markdown
# {视角} 审视报告 — chroniccare v0.27.0+62

> **视角**: ...
> **扫描范围**: (例如 "lib/ 239 dart + pubspec + ios/ + android/")
> **扫描方法**: ripgrep pattern + 关键文件 read
> **基础**: (引用已有报告)

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| 总问题 | X |
| 架构级 | X |
| 底层级 | X |
| P0 | X |
| P1 | X |
| P2 | X |
| P3 | X |

## 1. 顶层架构审视（2-5 条）

### 1.1 架构评级
| 维度 | 评分 | 理由 |

### 1.2 顶层重构建议（高内聚低耦合）

| # | 模块 | 现状 | 建议 | 难度 | 优先级 |

## 2. 底层逐行排查（5-15 条）

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 | 原因 |

## 3. 视角特定清单（按视角习惯）

(例如 spen 必有:隐式排序 / DateTime race / BuildContext 跨 async gap / dispose 完整性 / null safety)

## 4. 与历史报告对比

(引用 v0.27 R60+ / 7.26 三视角 已发现项，标注: 重复 / 增量 / 已修)

## 5. 修复路线（top 5，按优先级）

1. P0-X (S/M/L): 一句话 + 文件:行
2. ...
```

---

**关键警告**：

- 上次 3 视角 sub-agent 全 stack overflow 失败。本次 7 视角 sub-agent 严格走 grep + 精炼输出。
- 若 1 个 sub-agent 输出 > 30KB，主线程整合时会再次截断。
- 写文件用 `Set-Content -Path ... -Encoding UTF8`，不要 `>>` 追加。
