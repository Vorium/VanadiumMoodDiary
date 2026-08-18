# R92 Audit Fixes — Design Spec

> **重建日期**: 2026-08-18 (从代码注释 + audit 目录推断)
> **原始 spec 已删**, 基于代码内 R92 注释推断

## 1. 背景

R92 是 2026-07-26 启动的多视角审计 (emil / superpowers / flutter-spec / AppStore / GooglePlay), 发现 P0 若干, 本 spec 记录 P0 修复集合。

## 2. 范围 (基于可推断修复痕迹)

R92 多视角审计发现 P0 集中于:
- **P0#14**: assessment center 顶部 mini 趋势图原是 R90 Task 5 placeholder `SizedBox.shrink()` + TODO, R92 替换为真实 `assessment_multi_line_chart.dart`
- **Apple Health 5.1.3 claim lock-in**: 加 `scripts/check_apple_health_claim.py` 守门员 (154 行), 5 规则严格锁
- **16KB page size**: drift 0.6.5+ 是 Google Play 2025-11 强制的 16KB 对齐最低版本, sqlcipher_flutter_libs 锁 0.6.5+

## 3. 关键修复

### 3.1 Assessment Center P0#14

**位置**: `lib/features/assessment/presentation/pages/assessment_center_page.dart:81-94`

**修复前**:
```dart
// TODO: R90 Task 5 placeholder
SizedBox.shrink(),
```

**修复后**:
```dart
AssessmentMultiLineChart(
  scales: ref.watch(assessmentScalesProvider),
  height: 80,
),
```

**守门员**: 测试覆盖 R92 P0#14 (test/documentation/r93_doc_consistency_test.dart)

### 3.2 Apple Health Claim Lock-in

**新增**: `scripts/check_apple_health_claim.py` (154 行)
- 5 规则严格锁:
  1. `Apple Health` 字面只能在特定 widget 出现
  2. 不允许 claim `Apple Health integration` 当未集成 SDK
  3. `healthKitEnabled` FeatureFlag 默认 false
  4. tooltip 必须明确"应用内数据, 不上 Apple Health"
  5. lib/ 主体禁止 healthKit import
- 测试: `test/lock_in/apple_health_mention_lock_in_round9_test.dart`

### 3.3 16KB page size

`pubspec.yaml:38-42`:
```yaml
# v0.27 round 82: 0.6.5+ 是 16KB page size 对齐最低版本
sqlcipher_flutter_libs: ^0.6.5
```

**守门员**: `scripts/check_16kb_alignment.py` (10KB) + 18 .so objdump 正则验证

## 4. 实施状态

✅ 全部实施。

## 5. 关键文件

| 路径 | 行数 | 角色 |
|---|---|---|
| `scripts/check_apple_health_claim.py` | 154 | Apple Health 5.1.3 锁 |
| `lib/core/platform/health_kit/health_kit_service.dart` | 204 | HealthKit SDK stub (R128c 占位) |
| `lib/core/data/feature_flags.dart` | — | healthKitEnabled FeatureFlag |
| `scripts/check_16kb_alignment.py` | 10KB | 16KB 对齐验证 |
| `lib/features/assessment/presentation/pages/assessment_center_page.dart` | 125 | Assessment Center (含 R92 P0#14 修复) |

## 6. 关联

- R93 阶段 2 audit-fixes (PHQ-9/GAD-7 隐藏)
- R108 revisit: 8 P0 引入 + 17 in-progress 残留
- Apple Health 视觉风格: `docs/design/2026-08-10-apple-health-redesign/spec.md`

## 7. 局限

- ❌ R92 完整 P0 清单 (代码注释只见部分)
- ❌ 多视角审计具体结论
- ❌ 修复 commit 对应