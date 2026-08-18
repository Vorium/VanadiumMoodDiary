# Lens 8: flutter-audit (Flutter spec compliance)

**Date**: 2026-08-17
**Scope**: Flutter 3.47 stable spec 落地 + Material 3 + Widget 最佳实践 + Riverpod 3 + Drift 2.20
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**97%/100** (R31 97% 持平, R115+0 新增, Flutter 3.47 toolchain 已适配)

## 核心 Findings

### ✅ Flutter 3.47 适配 (3 项, R117 round 5 落地)
1. **Gradle 8.13 → 8.14**: `gradle-wrapper.properties` 升 8.14
2. **NDK 27 → 28.2.13676358**: jni + speech_to_text 插件要求
3. **`android.newDsl=true`**: AGP 9+ 强制要求

### ✅ Material 3 / iOS 风格 (5 项, R31 落地)
1. **5 token 集中器**: colors/typography/spacing/motion/spring
2. **6 widget 集中器**: PrimaryButton/CheckInButton/StatCard/AppleHealthTile/AppleListSection/SectionHeader
3. **ink_sparkle shader**: `assets/shaders/ink_sparkle.frag` 3978B 已复制
4. **Curve token**: 4 个 curve (FastEaseInOut/AppleEase/Emphasized/Bouncy) 集中
5. **Spring 物理模型**: `spring.dart` 145L 已写, 但 0 caller (R31 P0-08 待 R109 接)

### ✅ Riverpod 3.3.2 (3 项)
1. **Provider 模式**: `Provider<X>(...)` 暴露 domain 接口, 不暴露 impl
2. **`value` not `valueOrNull`**: R17 round 3 升级
3. **`ref.mounted` 仅 Notifier**: 27 处 `!mounted` 保持 (无 Notifier)

### ✅ Drift 2.20.3 SQLCipher (4 项)
1. **schemaVersion 23**: 守门员监控, 改表必加 onUpgrade migration
2. **1 表 1 子目录**: `database/tables/{check_in,medication,mood,vent,...}/`
3. **mapper 1 文件 1 mapper**: row ↔ entity 翻译在 data/database/*_mapper.dart
4. **`@DataClassName` 单数**: domain 实体 `*Entity` 后缀避免冲突

### ✅ go_router 14.6 (3 项)
1. **3 类 transition**: fade / slide-right / slide-up (R17 round 2)
2. **`context.push(...)` / `context.pop()`**: go_router 习惯
3. **ShellRoute**: 主页 NavigationRail

### ⚠️ Flutter spec gap (4 项)

| # | 位置 | 问题 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---|
| F-1 | `lib/core/theme/spring.dart` | 145L 0 caller, R31 P0 半成品 | 接 `_EntrySpring` 走 `Spring.standard.toSimulation()` | Small | P1 |
| F-2 | `lib/presentation/widgets/loading_skeleton.dart` | 3 variant (fullScreen/card/Spinner) 用法不一致 | 收 1 个 enum, 统一 3 mode | Trivial | P3 |
| F-3 | `lib/presentation/pages/medication/widgets/medication_slot_entry_row.dart` | R116 round 3 新增 121L, test 0 | 加 1-2 widget test | Trivial | P2 |
| F-4 | `lib/core/data/services/notification_service.dart` | 417L god class 候选, 跨 8 表 notif id 公式 | 拆 4 facade 子 (R23 P3 已抽 3) | Medium | P1 |

### 🚫 已闭环红线 (8 项, R31 累计)
- ❌ raw IconButton (7 处) → PressFeedbackIconButton 集中器
- ❌ hardcoded 中文 string → ARB key
- ❌ 隐式排序 → 显式 `[...records]..sort()`
- ❌ 跨 midnight race → AppRoot midnight timer
- ❌ DateTime.now() 多次调用 → 函数入口固化
- ❌ Stream subscription leak → dispose() 取消
- ❌ BuildContext 跨 async gap → this.context
- ❌ schemaVersion 漏 migration → 守门员

## 跨 Lens 共识

- **跟 emil**: F-1 spring.dart = E-2 spring.dart 同一半成品
- **跟 frame-thinking**: F-4 notification_service 417L = FT-2 / FT-3 god class
- **跟 superpowers-en**: F-3 medication_slot_entry_row test gap = S-EN-5/6/7 unit test gap

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| Flutter 3.47 适配 | Gradle/NDK/newDsl | ✓ (R117 round 5 落地) |
| Material 3 token 集中 | 5 集中器 | ✓ |
| Riverpod 3.x 升级 | value / !mounted | ✓ |
| Drift 2.20 守门员 | 1 | ✓ |
| ink_sparkle shader | 1 | ✓ |
| 0 raw IconButton | 0 | ✓ |
| 跨 11 feature 不互 import | 0 violation | ✓ |

## 下轮建议 (R117 flutter focus)

1. **P1**: F-1 spring.dart 接 _EntrySpring (1.5h)
2. **P1**: F-4 notification_service 拆 4 facade (4h)
3. **P2**: F-3 medication_slot_entry_row 加 widget test (1h)
4. **P3**: F-2 loading_skeleton enum 统一 (0.5h)
