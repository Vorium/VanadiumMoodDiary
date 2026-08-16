# Lens 5: gdc-audit (全平台合规 audit)

**Date**: 2026-08-17
**Scope**: iOS / Android / Web / 鸿蒙 / 多 form factor 跨平台合规
**Baseline**: 1.1.0+154, 2515 tests pass, 27/27 gatekeepers

## 总体评分

**7.5/10** (R31 持平, 鸿蒙 + Web form factor 长期未实现)

## 平台覆盖现状

| 平台 | 状态 | 主要文件 | 备注 |
|---|---|---|---|
| **iOS** | 95% | `ios/Runner/Info.plist` + `ios/Runner.xcodeproj` | 上架前 5 P0 跨期残留 (Z-1~Z-5) |
| **Android** | 95% | `android/app/src/main/AndroidManifest.xml` + `android/app/build.gradle.kts` | 升 NDK 28.2 + Gradle 8.14 适配 3.47 |
| **Web** | 70% | `web/index.html` + `web/manifest.json` | Drift worker 404 → 走 `flutter build web` + `python -m http.server 8358` production 模式 |
| **Linux** | 0% | - | 未启用 |
| **macOS** | 0% | - | 未启用 |
| **Windows** | 0% | - | 未启用 |
| **鸿蒙** | 0% | - | v1.0 长期 (AGENTS.md 路线图) |

## 核心 Findings

### ✅ 已闭环 (5 项, R31 R108 R115 累计)
1. **iOS 16KB alignment**: `check_16kb_alignment.py` 守门员 + NDK 28.2 已配齐
2. **Android 权限白名单**: 6 个白名单 + 30+ 禁止 (SMS/位置/相机/Contacts/存储写 等)
3. **iOS plist 严格白名单**: 4 个 usage description
4. **网络零外联**: 27 守门员覆盖 lib/ + manifest + plist
5. **隐私政策 3 法务文档**: assets/legal/ 完整, PIPL §13 单同意

### ⚠️ 跨平台 gap (4 项)

| # | 平台 | 状态 | 影响 | 优先级 |
|---|---|---|---|---|
| G-1 | 鸿蒙 | 0% (无 platform 目录) | 鸿蒙 0 上架 | P3 (v1.0 长期) |
| G-2 | macOS / Linux / Windows desktop | 0% | desktop form factor 缺 | P3 (R110+ 长期) |
| G-3 | Web PWA service worker | 弱 | 离线能力差 | P3 (R110+ 长期) |
| G-4 | iOS 16KB 实测 (非编译期) | 0 设备验证 | 等真机 | P2 (上架前 1 周) |

### ⚠️ 平台特定 (5 项)

| # | 平台 | 问题 | 修复 | 优先级 |
|---|---|---|---|---|
| G-5 | iOS | `NSPhotoLibraryUsageDescription` 4 occurrence (含 R70 删除重加 R102 恢复 R108 re-add 历史) | 文档已完整, 0 行为问题 | - |
| G-6 | iOS | `UIBackgroundModes` 含 `audio` (R108 P0#2 恢复), 但 vent audio 仅录音不后台播放 | 加注释"录音期间保活,非后台播放" | P3 |
| G-7 | Android | `INTERNET` 权限保留 (R114 注释"无实际网络出口,未来预留") | 改 AndroidManifest 注释 (无 0 行为变化) | P3 |
| G-8 | Android | `RECORD_AUDIO` 1 个, vent + mood 录音共用 | 拆 2 个 service 加 manifest-service 绑定 | P3 |
| G-9 | Web | `flutter build web` 走 production 模式 OK, dev 模式 drift worker 404 | 已加 AGENTS.md 已知坑, 0 行为变化 | - |

## 跨 Lens 共识

- **跟 pull-on-shelf**: G-4 iOS 16KB 实测 + Z-1~Z-5 截图都是上架前同步
- **跟 Apple Health**: G-1 鸿蒙 = HealthKit 0 集成跨期残留
- **跟 superpowers-zh**: G-5~G-9 5 个 platform 特定问题都是 P3 (无阻塞)

## R115+ 改动验证

| 指标 | 期望 | 实际 |
|---|---|---|
| iOS + Android 95% | 4+5 = 9 项闭环 | ✓ |
| 鸿蒙 / Desktop 0% | 0 启动 | ✗ (v1.0 长期) |
| 16KB alignment 守门员 | 1 | ✓ |
| 0 网络外联 | 0 | ✓ |

## 下轮建议 (R117 gdc focus)

1. **P2**: G-4 iOS 16KB 真机验证 (上架前 1 周)
2. **P3**: G-1~G-3 长期平台 (鸿蒙/desktop/web PWA)
3. **P3**: G-6~G-8 平台细节注释
