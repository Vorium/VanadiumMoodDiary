# Flutter 代码规范 (flutter-code.md)

> 来源: Effective Dart + flutter_lints 5.0 + 国内大厂公开规范 (字节/美团/闲鱼) + 项目 AGENTS.md 既定规范 (2026-08-16)

## 风格与语法
- 命名: 类/枚举 PascalCase; 方法/变量 camelCase; 常量 lowerCamelCase 或 SCREAMING_SNAKE_CASE; 私有 `_` 前缀; 文件/目录 snake_case
- import 组织: dart: → package: → 相对导入 (本项目: 全 package: 绝对导入, 0 相对导入)
- 优先 const / final; 避免 dynamic (JSON 校验层可用 Object? + type check); 集合字面量
- 禁止 print (用 dart:developer log 或项目 swallowError/piiSafeLog)
- build 方法 ≤80 行 (超标拆私有 widget); 函数 ≤50 行
- 魔法数字抽常量或 token

## 架构 (项目既定 4 层 + umbrella)
- 依赖方向: `presentation → domain ← data`; domain 0 Flutter 0 Drift
- core/ umbrella: data / shared / theme / routing / l10n
- 验证: `dart scripts/check_all.dart` (纯度 + 一致性); `python scripts/check_cross_feature.py --ci`
- 跨 feature import 禁止 (presentation/pages/{A} → {B}, 除 home/settings hub)
- god class 阈值 ≥400L 需评估拆解; 数据表/页面规模大文件不强制拆
- 状态管理: Riverpod 统一; 无 GetX/Bloc 混用
- 路由: go_router 集中注册; 禁止散落 MaterialPageRoute

## 性能
- 大列表 ListView.builder; 列表项 const; RepaintBoundary 高频子树
- build 无重计算/IO; 高频重建用 AnimatedBuilder/局部 provider
- dispose 全覆盖 (Stream/Controller/Timer/AudioPlayer); 审计期 33/33 dispose 达标为基准
- 动画只动 transform/opacity; 走 Motion.duration/curve 集中器 + reduce-motion

## UI / 无障碍 / i18n
- 颜色/字号/间距全走 AppTokens (5 token 集中器); 0 硬编码色值
- 用户可见文案 100% ARB (zh/en/zh_Hant 3 语); domain 预设内容允许中文 canonical + 显示层 localized* override
- 可点击区域 ≥48dp; IconButton 全带 tooltip; 对比度 ≥4.5:1 (状态色作文本色用 fgOn* 系)
- textScaler 适配; 深色模式全 token

## 测试与守门员
- 1 测试文件对应 1 功能 round: `{module}_{roundN}_test.dart`
- 21 守门员全绿为 commit 门槛: `python scripts/check_*.py` + `dart scripts/check_all.dart`
- flutter analyze 0 error / 0 warning (info 可接受)
- dart format --set-exit-if-changed 全绿
- coverage 阈值: domain ≥70% / data ≥45% / presentation ≥30% (check_coverage.py)
