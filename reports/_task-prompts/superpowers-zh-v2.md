工作目录: D:\Batch\chroniccare
视角: superpowers-zh（中文代码审查 / 提交规范 / l10n / 隐私边界）

【BUDGET 硬上限 250 调用，超过立即收工】
【已预读】AGENTS.md、CHANGELOG、pubspec.yaml（主对话已载入）
【策略】grep-first

# 步骤

## 1. 一次拿全量问题清单（80 调用内）

并行跑：

```
# hard-code 字符串（没用 l10n）
ripgrep "'[\u4e00-\u9fff]" lib/presentation/ -t dart  # 中文直接写死在代码
ripgrep "Text\('[^']*[\u4e00-\u9fff]" lib/ -t dart
ripgrep "'[A-Z][a-z]+ [a-z]+" lib/presentation/ -t dart  # 英文硬写

# dartdoc 缺失（public API 缺 /// 注释）
# 用 ast scan 跑：所有 public class/method 上方 5 行内是否有 ///

# commit 风格违规
git log --format="%s" -200 | grep -v "^[0-9]\.[0-9]\+ round [0-9]\+:"

# 时区问题
ripgrep "toIso8601String" lib/ -t dart
ripgrep "toUtc\(\)" lib/ -t dart

# 命名违规（AGENTS.md 命名表）
ripgrep "@DataClassName\('[A-Z][a-z]*'\)" lib/core/data/database/tables/ -t dart
ripgrep "class [A-Z][a-zA-Z]*Entity" lib/domain/entities/ -t dart

# 隐私边界
ripgrep "vent_entries|VentEntry" lib/ -t dart | grep -v "vent/\|VentEntryEntity"
ripgrep "mood_entries|MoodEntry" lib/ -t dart | grep -v "mood/\|MoodEntryEntity"

# 文档 drift
ripgrep "schemaVersion: [0-9]" lib/core/data/database/app_database.dart -t dart
ripgrep "schemaVersion" AGENTS.md docs/CHANGELOG.md

# 跨 feature
python scripts/check_cross_feature.py
```

## 2. 抽样 read（30 调用内）

- lib/l10n/app_zh.arb vs app_en.arb（对比覆盖率）
- lib/core/l10n/strings.dart（domain 层 fallback）
- 5 个最关键 feature 的入口 page（每个只 read 30 行）

## 3. git 历史分析（10 调用内）

```
git log --format="%h %s %ad" --date=short -50
git log --format="%an" | sort | uniq -c | sort -rn  # 协作模式
git log --format="%ad" --date=format:"%H" -100 | sort | uniq -c  # 深夜/周末比例
```

## 4. 输出报告

写到 `D:\Batch\chroniccare\reports\audit-superpowers-zh.md`

格式同前。

【绝对禁止】
- 不要 read 整个 .arb 文件（用 grep 数 key 数量即可）
- 不要列举 AGENTS.md 已知坑清单里已经修过的（除非确认又出现）
- 不要写"规范很好"这种废话
