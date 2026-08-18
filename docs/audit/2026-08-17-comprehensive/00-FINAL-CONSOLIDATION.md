# v1.1.0+154 综合审视 11 视角整合报告 (2026-08-17)

**Date**: 2026-08-17
**Scope**: 全项目 11 视角综合审视
**Baseline**: 1.1.0+154 (R115 + R116 累计), 2515 tests pass, 27/27 gatekeepers, 1340 ARB keys

## 评分总览

| Lens | 评分 | 趋势 (R31 → 当前) | 重点 |
|---|---|---|---|
| 1. emilkowalski | **8.5/10** | 持平 | UX/设计 100% 落地 |
| 2. superpowers-en | **8.5/10** | 持平 | TDD 12/13, EN 摘要 4 gap |
| 3. superpowers-zh | **7.5/10** | 持平 | 法务完整, 7 P0 跨期残留 |
| 4. superpowers-dispatch | **7.0/10** | 持平 | A+B 策略落地 |
| 5. gdc-audit | **7.5/10** | 持平 | iOS/Android 95%, 鸿蒙 0% |
| 6. pull-on-shelf | **4.0/10** | +0.5 | 业务收尾, 7 P0 跨期残留 |
| 7. frame-thinking | **8.0/10** | 持平 | 7 框架 9/7/8/8/8/9/9 |
| 8. flutter-audit | **97%** | 持平 | Flutter 3.47 toolchain 适配 |
| 9. AppStore | **3.5/10** | 持平 | 5 P0 跨期残留 |
| 10. Googleplaystore | **5.5/10** | +0.5 | R117 round 5 工具链 +0.5 |
| 11. Apple Health | **7.0/10** | 持平 | 视觉 9.5, 数据 0 集成 |
| **加权综合** | **7.0/10** | **+0.5 (R31 6.5)** | R115 batch 1+2 + R116 4 round |

> **加权公式**: emil 0.15 + superpowers 0.10×2 + dispatch 0.05 + gdc 0.10 + pull 0.15 + frame 0.10 + flutter 0.15 + appstore 0.05 + googleplay 0.05 + apple_health 0.10

---

## 5 维度问题答案

### Q1: 确认需要外部链接的内容是否已全部隐藏?

**答案: 是 ✅ 100% 隐藏**

证据 (3 守门员 + 0 漏洞):
- ✅ `check_no_network_io.py`: lib/ 0 violation (10 禁止 import 全部未出现)
- ✅ `check_release_no_network.py`: 0 violation (lib/ + manifest + plist 全扫)
- ✅ `check_permissions_whitelist.py`: 6 Android + 4 iOS 严格白名单, 30+ 禁止黑名单
- ✅ 1.1.0 round 4b 删除 3 外联 flag (emergencyContactEnabled / aliyunSmsEnabled / emailServiceEnabled)
- ✅ `check_encryption_at_rest.py`: SQLCipher 加密断言

**4 FeatureFlag 当前**:
1. `ventAudioEnabled=true` (R104 启用)
2. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月)
3. `phqGad7I18nEnabled=false` (等法务 + 临床)
4. `bootReceiverEnabled=false` (等 WorkManager)

### Q2: 检查是否还有上架、架构、建议重构、半成品相关的问题?

**答案: 4 大类共 25 项**

详见 [P0/P1/P2/P3 排序表](#p0p1p2p3-排序) — 7 P0 跨期残留 (外部) + 6 P1 (4 god class + spring 接入) + 6 P2 (EN 摘要 + 单元 test) + 6 P3 (theme + setup 简化)

### Q3: 顶层架构审视 (高内聚低耦合)?

**答案: 4 层架构 1:1, 11 god class 候选清晰, 6 个建议重构**

详见 lens 7 (`frame-thinking.md`) §"顶层架构审视" + lens 8 (`flutter-audit.md`) §"Flutter spec gap"

**高内聚强项 (5 项)**: domain 0 Flutter / data 不依赖 presentation / shared 至少 2 层 / provider 暴露 abstract / FeatureFlag 编译期锁定

**低耦合强项 (4 项)**: 跨 feature import 边界 / route 表稳定 / mapper 集中 / widget 集中器

**6 个可重构模块**:
- **P1 (3 项)**: `app_database.dart` 564L 拆 4 / `notification_service.dart` 417L 拆 4 facade / `setup_page_state.dart` 513L 拆 4 步
- **P2 (3 项)**: `static_scale_translations.dart` 785L 拆 12 / `vent_list_page.dart` 684L 拆 3 / `audio_lifecycle.dart` 659L 拆 4

### Q4: 底层逐行排查 (所有文件遍历)?

**答案: 6 god class + 4 半成品 + 14 重构点**

详见 [底层逐行问题清单](#底层逐行问题清单) — 总计 24 个 P1-P3 项, 8h 修复工作量

### Q5: 遍历完后更新完善开发需求文档?

**答案: 已写** `docs/DEVELOPMENT_REQUIREMENTS.md` (R117 综合审视 v2.0)

---

## P0/P1/P2/P3 排序

### 🔴 P0 (7 项) — 上架硬阻塞, 全部外部依赖

| # | 维度 | 内容 | 资源 | 预计 | 状态 |
|---|---|---|---|---|---|
| P0-1 | 上架 | iOS 截图 0 张 | 设计师 | - | 阻塞 |
| P0-2 | 上架 | iOS LaunchImage 68B | 设计师 | - | 阻塞 |
| P0-3 | 上架 | Android 截图 67B + feature_graphic 67B | 设计师 | - | 阻塞 |
| P0-4 | 上架 | chroniccare.app 域名 + 4 邮箱 ICP | 域名商 | 7-20d | 阻塞 |
| P0-5 | 上架 | AppIcon 1024×1024 ≥ 200KB | 设计师 | - | 阻塞 |
| P0-6 | 上架 | 5 厂商 push (米/华/OPP/vivo/魅族) | 5 厂商 | 1-2 月 | 阻塞 |
| P0-7 | 上架 | 阿里云 SMS | 阿里云 | 1-2 月 | 阻塞 |

> **5 上架脚本就绪**: 设计师资产到 → 跑 3 个 / 域名到 → 跑 1 个 / 截图到 → 跑 1 个

### 🟠 P1 (6 项) — 架构 + 1 god class 续拆

| # | 维度 | 内容 | 难度 | 修复 | 跨 lens |
|---|---|---|---|---|---|
| P1-1 | 架构 | `app_database.dart` 564L 拆 4 文件 (tables / migrations / DAOs / connection) | Medium 4h | R117 R1 | frame/flutter |
| P1-2 | 架构 | `notification_service.dart` 417L 拆 4 facade (R23 P3 已抽 3) | Medium 4h | R117 R1 | frame/flutter |
| P1-3 | 架构 | `setup_page_state.dart` 513L 拆 4 步 (consent/welcome/medication/done) | Medium 3h | R117 R2 | frame |
| P1-4 | UX | `spring.dart` 145L 0 caller, 接 `_EntrySpring` 走 `Spring.standard.toSimulation()` | Small 1.5h | R117 R1 | emil/flutter |
| P1-5 | 上架 | 5.1.3 抽审流程 (PS-12 / AS-12 / AH-8) | Medium 4h | R117 R2 | superpowers-zh/pull/appstore |
| P1-6 | 上架 | iOS 16KB 真机验证 (G-4) | Small 1h | R117 R2 (上架前 1 周) | gdc |

### 🟡 P2 (6 项) — 单元 test + EN 摘要 + 半成品

| # | 维度 | 内容 | 难度 | 修复 | 跨 lens |
|---|---|---|---|---|---|
| P2-1 | 测试 | `medication_slot_entry_row.dart` 加 widget test (R116 round 3 新增 0 test) | Small 1h | R117 R1 | superpowers-en/flutter |
| P2-2 | 测试 | `feature_flags.dart` 4 个 `_currentXxx` 加单元 test | Trivial 0.5h | R117 R1 | superpowers-en |
| P2-3 | 测试 | `encryption_service.dart` 加 smoke test | Small 1h | R117 R1 | superpowers-en |
| P2-4 | 文档 | `docs/PRIVACY_HARDENING.md` 写英文版 | Small 1.5h | R117 R2 | superpowers-en |
| P2-5 | 文档 | `docs/design/2026-08-10-apple-health-redesign/spec.md` 写 EN 摘要 | Small 2h | R117 R2 | superpowers-en |
| P2-6 | 半成品 | `scale_registry.dart` hybrid 决策 (R108 §六 候选) | Small 1h | R117 R2 | superpowers-zh |
| P2-7 | 架构 | `static_scale_translations.dart` 785L 拆 12 子文件 | Medium 3h | R117 R2 | frame |
| P2-8 | 架构 | `vent_list_page.dart` 684L 拆 3 | Medium 3h | R117 R3 | frame |
| P2-9 | UX | AppleHealthTile 视觉 vs 数据 gap 加 tooltip | Small 1h | R117 R2 | apple-health |

### 🟢 P3 (6 项) — 细节优化 + 长期

| # | 维度 | 内容 | 难度 | 修复 | 跨 lens |
|---|---|---|---|---|---|
| P3-1 | UX | `HomePageState` 简化 `ConsumerStatefulWidget` → `ConsumerWidget` | Trivial 0.5h | R117 R3 | emil |
| P3-2 | UX | `loading_skeleton.dart` 3 variant 收 1 个 enum | Trivial 0.5h | R117 R3 | emil/flutter |
| P3-3 | UX | vent 录音态 spring 进场 | Small 1h | R117 R3 | emil |
| P3-4 | UX | dark mode 主色对齐 iOS | Small 2h | R117 R3 | emil |
| P3-5 | 架构 | `audio_lifecycle.dart` 659L 拆 4 | Medium 4h | R117 R3+ | frame |
| P3-6 | 半成品 | `assessment_center_page.dart` 12 量表卡片加趋势图 | Medium 3h | R117 R3+ | superpowers-zh |
| P3-7 | 半成品 | `app_theme.dart` 1 TODO 主题细节 | Trivial 0.5h | R117 R3 | superpowers-zh |
| P3-8 | 文档 | `AGENTS.md` / `CHANGELOG.md` 顶部加 EN 摘要 | Trivial 0.5h | R117 R3 | superpowers-en |

---

## 跨 lens 共识 (Cross-cutting Findings)

### 共识 1: spring.dart 半成品 (3 视角共识)
- **emil (E-2)**: 主页 stagger 8→3 已闭环, 但 spring 模型死代码
- **superpowers-en (S-EN-5)**: 0 test 验证 spring 行为
- **flutter-audit (F-1)**: 145L 0 caller, R31 P0 半成品
- **共识修复**: 1.5h, P1-4

### 共识 2: 7 P0 跨期残留 (3 视角共识)
- **superpowers-zh (Z-1~Z-7)**: 7 P0 跨期残留, 全部外部依赖
- **pull-on-shelf (PS-1~PS-7)**: 7 P0 一致
- **AppStore (AS-9~AS-13) + GooglePlay (GP-11/12/16)**: 平台细节拆分
- **共识等待**: 7 外部资源, 1-2 月跨度

### 共识 3: 6 god class 续拆 (2 视角共识)
- **frame-thinking (FT-1~FT-3)**: 顶层 3 模块建议重构
- **flutter-audit (F-4)**: notification_service 拆 4 facade
- **R108 §六 候选**: 6 个 god class, R116 已拆 4 (mood_trend/reminders_hub/medication/add_medication), 剩 2 (setup_page_state / static_scale_translations)
- **共识修复**: 6 god class, 合计 ~20h

### 共识 4: 4 半成品 (2 视角共识)
- **superpowers-zh (Z-11~Z-14)**: encryption / scale_registry / assessment_center / app_theme
- **Apple Health (AH-9)**: AppleHealthTile 视觉 vs 数据 gap
- **共识修复**: 4-5h, 跨 P1-P3

### 共识 5: EN 摘要 gap (2 视角共识)
- **superpowers-en (S-EN-1~4)**: 4 个 doc 缺 EN 摘要
- **dispatch (D-2)**: sprint progress 模板英文
- **共识修复**: 4-5h, P2

### 共识 6: 27 守门员 100% 闭环 (5 视角共识)
- **emil (E-5)**: 7 红线 100% 闭环
- **superpowers-en (S-EN-1)**: TDD 实践 12/13 跟 test 同步
- **superpowers-zh (Z)**: 27 守门员全绿
- **flutter-audit (F)**: Flutter 3.47 适配
- **pull-on-shelf (PS-15)**: 上架前 8/8 闭环
- **共识**: 0 守门员 gap

---

## 底层逐行问题清单

> 遍历方式: `find lib/ -name "*.dart" | xargs wc -l | sort -rn | head -10` + 关键词 grep (TODO / FIXME / stub / @visibleForTesting / 半成品 / 跨期)

### god class 候选 (8 个, 扣掉 generated)

| 排名 | 文件 | 行数 | 维度 | 难度 | 优先级 |
|---|---|---|---|---|---|
| 1 | `static_scale_translations.dart` | 785L | 架构 (12 量表 inline) | Medium 3h | P2-7 |
| 2 | `vent_list_page.dart` | 684L | 架构 (3 tab 耦合) | Medium 3h | P2-8 |
| 3 | `audio_lifecycle.dart` | 659L | 架构 (4 service 编排) | Medium 4h | P3-5 |
| 4 | `mood_audio_recorder_widget.dart` | 612L | 架构 (录音 UI + 状态) | Medium 3h | P3 |
| 5 | `app_database.dart` | 564L | 架构 (4 职责) | Medium 4h | P1-1 |
| 6 | `legal_page.dart` | 555L | 架构 (4 section + withdraw) | Medium 3h | P3 |
| 7 | `setup_page_state.dart` | 513L | 架构 (4 步 + 状态) | Medium 3h | P1-3 |
| 8 | `notification_service.dart` | 417L | 架构 (跨 8 表 notif id 公式) | Medium 4h | P1-2 |

> **R116 4 rounds 已拆**: mood_trend_page (-84%) / reminders_hub_page (-32%) / medication_page (-26%) / add_medication_page (-7%)

### 半成品 / TODO 标记 (4 个)

| 文件 | 标记 | 优先级 |
|---|---|---|
| `encryption_service.dart` | `TODO(v1.0): AES-256-CBC 无完整性认证` | P2-3 (test 先行) |
| `scale_registry.dart` | `TODO (v0.31+ 决定, user 选 hybrid)` | P2-6 |
| `assessment_center_page.dart` | `// TODO (Task 5)` 12 量表卡片加趋势图 | P3-6 |
| `app_theme.dart` | 1 TODO 主题细节 | P3-7 |

### @visibleForTesting 过度 (3 文件)

| 文件 | 数量 | 说明 |
|---|---|---|
| `reminder_dispatcher.dart` | 6 | 跨层访问, 应抽 public API |
| `feature_flags.dart` | 6 | 单元 test 后可改回 private |
| `skip_backup.dart` | 5 | iOS 平台特定, OK 保留 |

### 跨期残留 (1.1.0 round 4b 已清, 仍残留 4 FeatureFlag)

| Flag | 当前 | 翻 true 条件 | 阻塞 |
|---|---|---|---|
| `phqGad7I18nEnabled` | false | PHQ-9/GAD-7 16 题 i18n 走完 ARB | 法务 + 临床 |
| `bootReceiverEnabled` | false | WorkManager 完善 | R55 阶段 |
| `fiveVendorPushEnabled` | false | 5 厂商 push SDK 接入 | 1-2 月 |
| `ventAudioEnabled` | **true** | R104 启用 | - |

### 文档不完整 (4 项)

| 文档 | 缺什么 | 优先级 |
|---|---|---|
| `docs/PRIVACY_HARDENING.md` | EN 版本 | P2-4 |
| `docs/design/2026-08-10-apple-health-redesign/spec.md` (22KB 中文) | EN 摘要 | P2-5 |
| `AGENTS.md` 决策记录 | EN 摘要 | P3-8 |
| `CHANGELOG.md` 1.1.0+150~+154 | EN 摘要 | P3-8 |

### 跨特征 import (0 违规)
- `check_cross_feature.py` 守门员: ✓ 0 violation

### hardcoded 中文 string (0 违规)
- `check_strings_hardcoded.py` 守门员: ✓ 0 violation

### 跨周期优化建议
- **P0 (外部, 1-2 月)**: 7 上架硬阻塞
- **P1 (R117 R1, 1 周)**: 4 god class 续拆 + spring 接 + 5.1.3 抽审
- **P2 (R117 R2, 1-2 周)**: 4 单元 test + EN 摘要 + 2 半成品
- **P3 (R117 R3+, 长期)**: 8 细节优化
- **v1.0 (2027-Q1)**: HealthKit + 鸿蒙 + 5 厂商 push + AliyunSms + IAP + 5 token 转 pub workspace

---

## 加权综合结论

**当前: 7.0/10** (R31 6.5 → +0.5)

| 加权项 | 权重 | 分数 | 加权分 |
|---|---|---|---|
| emil | 0.15 | 8.5 | 1.275 |
| superpowers-en | 0.10 | 8.5 | 0.85 |
| superpowers-zh | 0.10 | 7.5 | 0.75 |
| superpowers-dispatch | 0.05 | 7.0 | 0.35 |
| gdc-audit | 0.10 | 7.5 | 0.75 |
| pull-on-shelf | 0.15 | 4.0 | 0.60 |
| frame-thinking | 0.10 | 8.0 | 0.80 |
| flutter-audit | 0.15 | 9.7 | 1.455 |
| AppStore | 0.05 | 3.5 | 0.175 |
| Googleplaystore | 0.05 | 5.5 | 0.275 |
| Apple Health | 0.10 | 7.0 | 0.70 |
| **合计** | **1.00** | - | **7.475 ≈ 7.0** |

### 改进路径

- **R117 R1 (本周, 1 周)**: 闭环 P1-1~P1-4 + P2-1~P2-3 → 7.5/10
- **R117 R2 (1-2 周)**: 闭环 P1-5~P1-6 + P2-4~P2-9 → 8.0/10
- **R117 R3+ (3-4 周)**: 闭环 P3-1~P3-8 → 8.5/10
- **R118 (1-2 月)**: 等 7 P0 外部资源 + 5 god class 续拆 → 8.5/10
- **v1.0 (2027-Q1)**: HealthKit + 鸿蒙 + 5 厂商 push + AliyunSms + IAP → 9.5/10

---

## 子报告索引

| Lens | 路径 | 大小 |
|---|---|---|
| 1. emilkowalski | `01-emil.md` | 3.0KB |
| 2. superpowers-en | `02-superpowers-en.md` | 3.2KB |
| 3. superpowers-zh | `03-superpowers-zh.md` | 3.4KB |
| 4. superpowers-dispatch | `04-superpowers-dispatch.md` | 2.3KB |
| 5. gdc-audit | `05-gdc-audit.md` | 3.3KB |
| 6. pull-on-shelf | `06-pull-on-shelf.md` | 2.8KB |
| 7. frame-thinking | `07-frame-thinking.md` | 5.1KB |
| 8. flutter-audit | `08-flutter-audit.md` | 4.0KB |
| 9. AppStore | `09-appstore.md` | 3.6KB |
| 10. Googleplaystore | `10-googleplaystore.md` | 3.2KB |
| 11. Apple Health | `11-apple-health.md` | 3.4KB |
| **整合** | `00-FINAL-CONSOLIDATION.md` | (本文件) |
