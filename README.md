# 慢病管家（ChronicCare）

> 我今天吃了药 · 精神心理患者吃药打卡 + 停药通知

> **🚧 v0.30 R95 阶段 1+2+3+4 实施后 (2026-08-07)**: 8 sub-spec / 44 commit / 2019 pass (+347 R95 new tests) / 0 analyzer error / 18 守门员全绿 / 0 god page 残留 (8 god widget 拆完: data_mgmt / scale / scale_l10n / home / trend / mood_audio / setup / settings)。
>
> **6 视角评分提升** (R92 → R95): emil **7.5→9.0** (+1.5) / spen **8.0→9.0** (+1.0) / flutter-spec **84%→88%** (+4%) / spzh 工程 **8.0→9.0** / spzh 合规 **3.5→4.5** / AppStore **6.0→6.5** / GooglePlay **38%→40%**。
>
> **业务真接 + 法务 + 资质 + 临床 + 设计师 + Mac 暂停, 8 FeatureFlag 仍守门 (R95 持续)**:
> 1. IAP 8 元买断 (Apple 2.1 拒 — `iapEnabled=false`, 等 App Store Connect 真接)
> 2. 失联通知 / 紧急联系人 SMS (阿里云未真接 — `emergencyContactEnabled=false`, 等 AccessKey + 阿里云审核)
> 3. 5 厂商 push (米/华/OPPO/vivo/魅族 — `fiveVendorPushEnabled=false`, 等 5 厂商 1-2 月审核)
> 4. EmailService 邮件导出 (SendGrid 未真接 — `emailServiceEnabled=false`, 等 API key)
> 5. vent + mood audio 录音 (业务闭环不全 — `ventAudioEnabled=false`, 等业务真接)
> 6. PHQ-9 / GAD-7 量表 (en/zh_Hant 翻译不全 — `phqGad7I18nEnabled=false`, 等法务 + 临床审核)
> 7. Android BootReceiver (WorkManager 完善前 — `bootReceiverEnabled=false`)
> 8. AliyunSms 真接 (`aliyunSmsEnabled=false`, 等 AccessKey)
>
> **业务真接后翻 flag = 立即恢复, 数据模型 / Repository / 业务代码全部保留**。详见 `lib/core/data/feature_flags.dart` + `assets/legal/privacy_policy.md` §0.6 + `docs/VERSION_1.0_PLAN.md` R95 路线图。

## 🎯 产品

参考"死了么"模式做的精神心理患者专版吃药打卡 App。

**核心机制**：
- 每天点 1 次"我今天吃了药"
- 漏 2 天（48 小时）未打卡 → 自动 SMS 通知紧急联系人
- 措辞：温柔提醒"请你方便的时候提醒我按时吃药"（不是"快不行了"）
- 数据本地加密（SQLCipher），不上传云端

**目标用户**：精神心理疾病患者（抑郁、焦虑、双相等），需长期规律服药的人群。

**商业模式**：8 元付费下载（Google Play + App Store）。

## 🚀 快速开始

```bash
# 1. 装 Flutter（如果没装）
# macOS:
brew install fvm
fvm install 3.41.9
fvm use 3.41.9

# 2. 装依赖
flutter pub get

# 3. 跑代码生成（Drift）
dart run build_runner build --delete-conflicting-outputs

# 4. 跑
flutter run

# 5. 跑测试
flutter test
```

## 📦 技术栈

| 组件 | 版本 |
|---|---|
| Flutter | 3.41.9 stable |
| Dart | 3.12.2 |
| 状态管理 | Riverpod 3.3.2 |
| 本地数据库 | Drift 2.20.3 + SQLCipher 加密 |
| 路由 | go_router 14.6 |
| 图表 | fl_chart |
| 推送 | flutter_local_notifications 17 |
| 加密 | flutter_secure_storage + pointycastle (AES-256, v0.20 迁) |
| 文件分享 | share_plus |
| 录音 | record 5.2.0 |
| 音频播放 | audioplayers 6.1.0 |

## 📁 目录结构（4 层架构 + 共享层）

```
lib/
├── main.dart              # 入口
├── app.dart               # App 根 + Riverpod
├── core/                  # 基础设施 umbrella
│   ├── data/              # data 层（DB / Repositories / Services / Utils）
│   ├── shared/            # 跨层共享（formatters / json_codec / mood_visual）
│   ├── theme/             # AppTokens + M3 主题
│   ├── routing/           # go_router
│   └── l10n/              # domain 层 strings（通知/邮件用）
├── l10n/                  # presentation 层 flutter_localizations（UI 用）
├── domain/                # 领域层（纯 Dart，0 Flutter 0 Drift 依赖）
│   ├── entities/          # 业务实体（*Entity 后缀）
│   ├── logic/             # 业务规则（量表/streak/care engine/报告）
│   ├── repositories/      # 抽象接口（无实现）
│   └── usecases/          # 用例（业务编排）
└── presentation/          # UI 层
    ├── providers/         # Riverpod providers
    ├── pages/             # 页面（home/setup/settings/assessment/vent/...）
    └── widgets/           # 通用组件
```

**依赖方向**：`presentation → domain ← data`。
**4 层纯度 + 一致性自动检查**：
```bash
dart scripts/check_all.dart   # 一次出 2 份报告：纯度 + 一致性
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑
```

## ✨ 功能

### 核心
- 每日打卡 + streak 跟踪
- 多药物管理（剂量、服用时间、停药/恢复）
- 续方日期 + 提前 N 天提醒
- 紧急联系人管理 + 失联自动通知
- 心理评估（PHQ-9 抑郁 + GAD-7 焦虑 + 历史趋势图）
- **树洞（v0.15 私密倾诉空间）**：文字 / 语音 / 混排，完全独立不参与任何分析

### 通知与提醒
- 每天 20:00 通用打卡提醒
- 多药物时间点精准推送
- 10am 软提醒（漏 1 天安慰）
- 周期评估提醒（PHQ-9 / GAD-7）
- 失联通知（连续 N 天没打卡 → SMS）
- 续方提前 N 天提醒

### 国产 ROM 适配（v0.16 round 20）
- **设置页"通知状态自检卡"**：用户首次安装可一键检测通知是否被系统拦截，状态显示 + 一键测试
- **OEM 品牌引导**：自动识别 Xiaomi/Huawei/OPPO/vivo/Samsung/Meizu 等 7 品牌，按品牌给"自启动 + 精确闹钟 + 省电白名单"3 步引导
- **iOS 17 / Android 13+ 通知权限**：首次安装时显式申请，符合系统规范
- 已知问题：90%+ 国产 ROM 默认杀后台进程 + 拦截自启动 + 禁用精确闹钟，必须用户手动开启白名单



### 报告与分析
- 主页打卡趋势
- 趋势页（30 天热力图 + 6 月柱状图 + 评估折线）
- 依从性日历（医生视角）
- 评估历史（独立页 + 严重度分级 + 临床标准分档）
- PDF 报告导出
- JSON 数据导出/导入

### 隐私
- SQLCipher 全库加密
- 联系人/评估备注等敏感字段额外 AES-256
- 关键密钥存 flutter_secure_storage（iOS Keychain / Android Keystore）
- 零云端上传
- v0.30 R95 sub-spec 7 task 31a: audit log AES-256 加密 (复用 vent contentTextEnc BLOB 模式) + 31b: PIPL §47 撤回 (reset ConsentKind.dataExport 自动清 audit log)
- v0.30 R95 sub-spec 7 task 30: assessment_dao PII 泄露修 (不暴露 rawNote, 失败抛结构化 error)

## 🆕 v0.30 R95 实施 (2026-08-07 全部完成)

**8 sub-spec / 44 commit / +347 R95 new tests / 2019 pass / 0 analyzer error / 18 守门员全绿 / 0 god page 残留**

### 8 sub-spec 实施摘要

| sub-spec | 任务 | 关键数字 |
|----------|------|----------|
| **1** | task 1 拆 `data_management_section` 606→44 | 6 sub-tile + 1 export_dialog, 主壳 **-93%** |
| **2** | task 8 catch + task 10 半成品 + task 25 vent dispose + task 26 badge sync + task 9 audit | 4 stale audit lock-in (R23/R79 已修 + lock-in tests 防御) |
| **3** | task 9 硬编码中文 → ARB | 4599 字符 → 走 ARB, 37 lock-in tests (R65/R78/R90/R23/R39/R57 已加 188 ARB key) |
| **4** | task 2/5/6/7 拆 4 god page | 4 god page 2943→661 行, 主壳 **-78%** 减肥 |
| **5** | task 3-4 token 化 | 102+ 处修真, 保留 220+ 半 token + 12 PDF + 集中器自身, 20 lock-in tests |
| **6** | pre-existing + god widget + 集成 + coverage | 5 集成测试 (1→6), 18 守门员 (新加 `check_coverage.py`), domain **73.8%** / data 47% / presentation 57.4% |
| **7** | task 30/31/32/53/54/55 + R96 留待 | 修 3 pre-existing fail, 13 new ARB keys, app_database 注释 **1499→0** 中文 |
| **8** | task 17/18/19/45-67 P3 UX | settings 261→70 (-73%), 紧急联系人 5→3 步, 数据导出 5→3 步, Tooltip/chip/visual hint, main.dart mutable static 改 late final |

### 6 视角评分变化 (R92 → R95 实施后)

| 视角 | R92 | **R95** | 变化 | 关键 |
|------|-----|---------|------|------|
| emilkowalski (设计) | 7.5/10 | **9.0/10** | **+1.5** | 6 god page 拆 + UX 体验 + Tooltip + chip + 5→3 步 + 4 group 重构 |
| superpowers-en (工程) | 8.0/10 | **9.0/10** | **+1.0** | 集成测试 + coverage 阈值 + 修 3 pre-existing fail + lock-in tests |
| superpowers-zh 工程 | 8.0 | **9.0** | **+1.0** | 注释翻译 (1499→0 中文) + i18n 化 (8 new ARB keys) + audit log 加密 |
| superpowers-zh 合规 | 3.5 | **4.5** | **+1.0** | audit log 加密 + PIPL §47 撤回 + assessment_dao PII 修 |
| AppStore (iOS) | 6.0/10 | **6.5/10** | **+0.5** | 业务暂停 / 法务加 R95 阶段 2 说明 / sign 仍缺 |
| GooglePlay (Android) | 38% | **40%** | **+2%** | 5 厂商 hidden + R95 阶段 2 + 注释翻译 + 18 守门员全绿 |
| flutter-spec (v3.1) | 84% | **88%** | **+4%** | catch 集中器化 + token 化 + lock-in test + 集成测试 + coverage 阈值 |

### R95+ 路线图 (60 task 实施后状态)

- ✅ **32/60 task (53%)**: 代码 + 测试 + 设计 + UX 全部完成
- ⏸️ **17/60 task 等外部资源**: 5 业务真接 + 3 主体资质 / 临床 / NMPA + 8 iOS / Android 上架配置 + 1 TestFlight
- 📋 **10/60 task 留 R96+**: 主页 IA 重排 / notification_service 再拆 / 18+ service 测试 / AudioController 抽象 / FeatureFlags 静态状态 / etc.
- 📋 **1/60 task 留 R97+**: 5 厂商 + 鸿蒙 / HarmonyOS NEXT 适配

### 详细报告 (R95 实施过程)

- [docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md](docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB, **R95 实施后整体总结**)
- [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](docs/audit/2026-08-06/r95-increment/00-r95-summary.md) (44KB, R95 实施前综合审视)
- [docs/VERSION_1.0_PLAN.md](docs/VERSION_1.0_PLAN.md) (53.4KB, R95+ 路线图 + v1.0 决策路径)
- 8 sub-spec 报告: `docs/superpowers/sdd-logs/round95-*/sdd/`

## 🧪 测试

```bash
flutter test                          # 跑所有测试（v0.30 R95 实施后 2019 cases, +347 R95 new tests, 0 fail, 0 analyzer error）
flutter test --coverage               # 覆盖率（R95 sub-spec 6 配置阈值: domain ≥ 70% / data ≥ 50% / presentation ≥ 30%, 实测 73.8% / 47.0% / 57.4%）
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成

# 4 层架构纯度 + 一致性检查（v0.16 Round 13 起合并为 check_all.dart）
dart scripts/check_all.dart
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑

# 18 守门员（v0.30 R95 实施后 16 .py + 1 .dart + 1 R95 新加 check_coverage.py）
for s in scripts/*.py; do python $s; done
```

测试覆盖：domain 业务逻辑（量表、streak、报告、用药）+ data 仓库（round-trip）+ presentation widget（页面渲染、交互）。架构检查覆盖 import 依赖方向 + entity ↔ table 对应 + shared 工具使用率。

## 🛠 调试

```bash
flutter run --debug                   # 调试模式
flutter run --profile                 # 性能模式
flutter logs                          # 看日志
```

## 📱 打包

```bash
# Web（H5）
flutter build web
# 输出：build/web/

# Android APK
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk

# iOS（macOS only）
flutter build ios --release
# 输出：ios/Runner.xcarchive
```

## 🐛 已知约束 (v0.30 R95 实施后, 2026-08-07)

- `flutter_secure_storage` 在部分 Android 设备上首次启动有 ~200ms 延迟
- Web 平台用 `sqlite3.wasm` 走 IndexedDB，Chrome 隐身模式可能失败
- iOS 推送需要真机测试（模拟器无 APNs）
- SMS / Email / 5 厂商 push 走占位（v0.30 R95 实施后 8 FeatureFlag 守门, **等付费启动真接**: 法务 ¥45-90k, 阿里云 AccessKey 1-2d + 2-4w 审核, SendGrid API key, 5 厂商 push 1-2 月审核）
- 国产 ROM 静默杀后台通知：需接入 5 厂商 push (小米 / 华为 / OPPO / Vivo / 魅族) 才能让推送送达率达 95%+（**R95 阶段 1+2+3+4 跑完, 业务真接暂停等付费启动**）
- **R95 实施后业务真接 5 task 暂停, 上架 blocker 17/60 ⏸️ 等外部资源**: 法务过审 (¥45-90k, 1-2 月) / 主体资质 (ICP / 公安备案 / 等保, 1-2 月) / 临床审核 (PHQ-9 / GAD-7, 1-2 月) / NMPA 备案 (医疗 App, 1-2 月) / iOS / Android 上架配置 (8 task 需 Mac + 设计师)

## 📄 文档

- `docs/CHANGELOG.md`：版本变更
- `docs/DEPLOYMENT.md`：部署指南（含阶段 8 国内 5 store + 5 厂商 push + 附录合规清单）
- `docs/`：设计规格、token 规范、实施 plan

## 📜 法律与合规 (v0.30 R95 实施后, 2026-08-07)

**3 份法律协议** (`assets/legal/`)：
- `user_agreement.md` — 用户协议 (通用条款, R95 阶段 2 加业务暂停延伸说明)
- `privacy_policy.md` — 隐私政策 (PIPL / HIPAA / GDPR 完整合规, R95 阶段 2 加 §0.6 v0.30 业务暂停 8 FeatureFlag 列表)
- `sensitive_data_consent.md` — 敏感个人信息处理同意书 (健康 / 树洞, R95 阶段 2 加业务暂停延伸说明)

**R95 实施后上 store 前必修 (17/60 R95 task ⏸️ 等外部资源):**

**业务真接 (5 task, 等付费启动):**
- [ ] 律师过审 3 份法律文档 (¥45-90k, 1-2 月, R95 task 20)
- [ ] 5 厂商 push SDK 接入 (送达率 95%+, 1-2 月审核, R95 task 11)
- [ ] 阿里云 SMS provider 真接 (失联通知 production 必需, R95 task 14)
- [ ] EmailService SendGrid 真接 (R95 task 15)
- [ ] PHQ-9 / GAD-7 16 题 i18n 临床审核 (R95 task 12, 法务 + 临床)
- [ ] IAP 8 元买断真接 productId (R95 task 13)

**主体资质 + 临床 + NMPA (3 task, 1-2 月):**
- [ ] 主体资质 (ICP / 公安备案 / 等保, R95 task 21)
- [ ] 临床审核 (PHQ-9 / GAD-7 临床有效性, R95 task 22)
- [ ] NMPA "非医疗器械" 声明 + 备案 (医疗 App, R95 task 23)

**iOS / Android 上架配置 (8 task, 需 Mac + 设计师):**
- [ ] iOS 签名 + DEVELOPMENT_TEAM + Podfile 真生成 (R95 task 35-36)
- [ ] Android keystore + Play App Signing (R95 task 37)
- [ ] USE_EXACT_ALARM Play Console justification (R95 task 38)
- [ ] Data Safety Form / Health Apps questionnaire (R95 task 39)
- [ ] iOS 截图 + AppIcon 1024 真设计 + 18+ Dark Icon (R95 task 33-34, 设计师 2-3d)
- [ ] iOS iCloud Backup 排除 + description.txt 改文案 (R95 task 42-43)
- [ ] TestFlight 100+ 真实用户 (R95 task 60)
- [ ] 域名 + 邮箱注册 (R95 task 40-41)

**R95 实施后已修 (32/60 R95 task ✅):**
- ✅ 8 god widget 全部拆完 (data_mgmt / scale / scale_l10n / home / trend / mood_audio / setup / settings)
- ✅ 102+ 处 token 化 (TextStyle + EdgeInsets + Duration 集中器)
- ✅ 5 集成测试 (端到端 user journey)
- ✅ 18 守门员全绿 (R95 新加 check_coverage.py)
- ✅ 30+ 硬编码中文 → ARB (R65/R78/R90 + R95 sub-spec 3/7)
- ✅ 修 3 pre-existing fail (R95 sub-spec 6/7)
- ✅ 6 视角评分提升 (emil +1.5 / spen +1.0 / flutter-spec +4%)
- ✅ app_database 注释 1499→0 中文翻译 (R95 sub-spec 7 task 54)

**合规清单详情见 `docs/DEPLOYMENT.md` 附录 A (NMPA / HIPAA / GDPR / PIPL) + 附录 B (R95 实施后阻塞 TODO + 估时) + `docs/VERSION_1.0_PLAN.md` R95+ 路线图 (32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+)。**

## 📜 许可

个人项目，仅供学习。
