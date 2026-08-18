# R108 UIBackgroundModes audio 恢复 — 来龙去脉

> **作者**: P0 必修 subagent B (v0.30 R108)
> **基线**: v0.30.0+85
> **状态**: ✅ 已修 (commit 待提)

---

## 背景

R107 报告 §2.2 + §5 appstore P0 阻断项 7 之一: vent audio 已启用但 `UIBackgroundModes audio` 缺 = vent 录音时 App 进后台被 iOS 系统秒杀 = 录音丢失 + 用户体验崩。

## 时间线

| 日期 | Round | 动作 | 原因 |
|------|-------|------|------|
| 2026-08-08 | R100 (P0#6, appstore A-3) | 删 `UIBackgroundModes audio+processing` + `BGTaskSchedulerPermittedIdentifiers` | ventAudio / 失联通知业务 FeatureFlags 全关, 声明的后台能力无实际使用 = Apple 2.5.4 拒因 |
| 2026-08-09 | R104 | `FeatureFlags.ventAudioEnabled` 翻 `true` | vent+mood 语音录音真接 (录音功能上线) |
| 2026-08-10 | R107 | 9 视角综合审计: 发现 R100 删 + R104 启用矛盾 | vent 录音功能启用却没声明 audio 后台 = Apple 2.5.4 仍会拒 + iOS 录音时进后台被杀 |
| 2026-08-10 | **R108 (本次)** | **恢复 `UIBackgroundModes = [audio]`** | **声明跟实际能力匹配** |

## 为什么只恢复 audio, 不恢复 processing

- **audio**: vent+mood 语音录音需要 (R104 已真接)
- **processing**: BGProcessingTask 失联检测, 依赖阿里云 SMS, 当前 `FeatureFlags.aliyunSmsEnabled=false`, 业务未真接
  - 声明 processing 但实际不跑 = Apple 2.5.4 used-but-not-declared 拒因
  - 阿里云 SMS 真接 (法务 1-2 月模板审核 + AccessKey 申请) 后再恢复 processing

## 改动清单

### 1. `ios/Runner/Info.plist`

```diff
 <!--
-    v0.30 R100 (P0#6, appstore A-3): 删 UIBackgroundModes audio+processing +
-    BGTaskSchedulerPermittedIdentifiers 声明。原因: ventAudio / 失联通知业务
-    均 FeatureFlags 关闭, 声明的后台能力无实际使用 = Apple 2.5.4 拒因。
-    业务真接时 (vent 语音录音 / BGProcessingTask 失联检测) 再加回:
-    UIBackgroundModes=[audio, processing] + BGTaskSchedulerPermittedIdentifiers
-    =[com.chroniccare.safety-check] + AppDelegate.swift BGTaskScheduler.register。
+    v0.30 R108 (P0#2, appstore A-3): 恢复 UIBackgroundModes audio
+    原因: R100 (2026-08-08) 因 ventAudio 业务 FeatureFlags 关闭删 audio,
+    但 R104 (2026-08-09) 已将 FeatureFlags.ventAudioEnabled 翻 true
+    (vent+mood 语音录音真接)。声明跟实际能力不匹配, Apple 2.5.4 拒因,
+    且录音时 App 进后台被系统秒杀 = 录音丢失 + 用户体验崩。
+    R108 决策: 只恢复 audio (vent 录音后台继续录制), 不恢复 processing
+    (BGProcessingTask 失联检测等阿里云 SMS 真接后再加)。
+    加 R108 注释标记 + R100 删/恢复的来龙去脉, 防御未来再误删。
 -->
+<key>UIBackgroundModes</key>
+<array>
+    <string>audio</string>
+</array>
```

### 2. `ios/Runner/AppDelegate.swift`

- 加注释: R108 恢复 + audio mode 由 Info.plist 接管 + 不需要 register 代码
- 业务代码 0 改动 (audio mode 是系统级声明, AVAudioSession 录音启动时自动接管)

### 3. `test/ios/info_plist_background_modes_round108_test.dart` (新)

- 锁住 Info.plist 含 UIBackgroundModes + audio
- 锁住不应含 processing (业务未真接)
- 锁住 AppDelegate.swift 含 R108 注释
- 锁住 project.pbxproj 引用 Info.plist 路径不变

## 验证

```bash
# lock-in test (R108 上架前必跑)
flutter test test/ios/info_plist_background_modes_round108_test.dart
# → 5 case 应全过
```

## 防御未来再误删

- lock-in test `info_plist_background_modes_round108_test.dart` 强制 audio 存在
- 锁住 Info.plist 不应含 processing (防止有人"善意"加全部模式)
- R108 注释标记 + R100 删/恢复时间线, R110+ refactor 必读
- processing 恢复条件: `FeatureFlags.aliyunSmsEnabled=true` + AppDelegate.swift BGTaskScheduler.register 加回
  - 预期时间: 阿里云 SMS 真接后 (法务 1-2 月 + AccessKey 申请)
  - 届时同步: Info.plist 加 processing + AppDelegate register + 加新 lock-in test 锁住 processing

## Apple Guideline 引用

- **Apple App Store Review Guideline §2.5.4**: Apps may only use background modes for the intended purposes described below.
  - audio: Apps that play or record audio (including voice over IP) may use this background mode.
- 5 视角共识: R100 删 + R104 启用矛盾 = 2.5.4 拒因
- Lock-in test 锁住"声明跟实际能力一致"原则
