工作目录: D:\Batch\chroniccare
视角: superpowers-en（工程方法论：TDD / code review / systematic debug）

【BUDGET 硬上限 250 调用，超过立即收工】
【已预读】AGENTS.md、CHANGELOG、pubspec.yaml（主对话已载入）
【策略】grep-first，对命中文件只 read 上下文 30 行

# 步骤

## 1. 一次拿全量问题清单（80 调用内）

并行跑：

```
# 8 种已知坑 pattern 全量 grep
ripgrep "\.first\.timestamp|\.last\.timestamp|\.first\.id|\.last\.id" lib/ -t dart
ripgrep "DateTime\.now\(\)" lib/ -t dart
ripgrep "int\.parse\(" lib/ -t dart
ripgrep "DateTime\.parse\(" lib/ -t dart
ripgrep "millisecondsSinceEpoch" lib/ -t dart
ripgrep "addListener" lib/ -t dart
ripgrep "setState\(" lib/ -t dart -B 2 -A 2
ripgrep "try \{" lib/ -t dart -A 8 | grep -B 2 "dispose"

# 复杂度指标
ripgrep -c "if \(|else if|switch |case " lib/**/*.dart | sort -t: -k2 -rn | head -20
ripgrep -c "" lib/**/*.dart | sort -t: -k2 -rn | head -30  # 文件行数 top 30

# 测试覆盖
Get-ChildItem lib/ -Recurse -Filter "*.dart" | ForEach-Object { ... }  # 没测试覆盖的

# 错误吞错
ripgrep "catch \(_" lib/ -t dart
ripgrep "on Exception catch" lib/ -t dart -A 3

# 跨层 import
ripgrep "import 'package:flutter" lib/domain/ -t dart
ripgrep "import.*drift" lib/domain/ -t dart
ripgrep "import.*presentation" lib/data/ -t dart

# 跨 feature import
ripgrep "import.*pages/.*/" lib/presentation/pages/ -t dart | grep -v "pages/.*/" 
```

## 2. 跑 flutter analyze + flutter test（30 调用内 + 600s timeout）

```
flutter analyze 2>&1 | tail -50
flutter test 2>&1 | tail -30
```

## 3. 抽样 read（40 调用内）

只对 grep 命中的 Top 5 复杂文件 read 上下文（不是全文件）：
- care_engine.dart
- app_database.dart
- notification_service.dart（如果存在）
- reminder_scheduler.dart
- safety_watch_service.dart（如果存在）

每文件 read 用 offset/limit 选最复杂段落。

## 4. 输出报告

写到 `D:\Batch\chroniccare\reports\audit-superpowers-en.md`

格式同 emilkowalski：架构审视 5 条 + 底层 P0-P3 排序

【绝对禁止】
- 不要 read 整个文件
- 不要重复跑 grep
- 不要列举非问题（"代码风格很好" 这种废话）
