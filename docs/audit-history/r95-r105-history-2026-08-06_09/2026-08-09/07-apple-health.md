# Apple Health 视角报告 (2026-08-09)

**评分**: N/A (新视角)

## HealthKit 集成审查

### 现状
App 本地追踪 10 类健康数据:
- mood (情绪日记)
- sleep (睡眠)
- weight (体重)
- anxiety (焦虑)
- social_rhythm (社会节律)
- stress (压力事件)
- treatment (治疗记录)
- check-in (打卡)
- assessment (心理评估)
- medication (用药)

**HealthKit 零集成**: 无任何 HealthKit 代码、entitlements、或 Info.plist 声明。

### 建议

| # | 问题 | 难度 | 优先级 | 说明 |
|---|------|------|--------|------|
| H1 | 未接入 HealthKit | 大 | P3 | sleep/weight 可双向同步 |
| H2 | 未声明 HealthKit entitlements | 简单 | P3 | 需 Xcode 配置 |
| H3 | 未实现 HKObserverQuery | 大 | P3 | 后台数据同步 |
| H4 | 无 Health 数据导出格式 | 中 | P3 | CDA/FHIR |

### 结论
Apple Health 集成为 P3 nice-to-have, **不阻塞上架**。当前本地追踪已完整, HealthKit 是增值功能。建议 v1.0 后作为 v1.1 功能规划。
