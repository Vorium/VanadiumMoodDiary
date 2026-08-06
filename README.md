# 慢病管家（ChronicCare）

> 我今天吃了药 · 精神心理患者吃药打卡 + 停药通知

> **🚧 v0.30 阶段 2 集中修复 (R93, 2026-08-06)**: 7 项未真接业务已用 `FeatureFlag` 守护 + UI 完全 hidden (`SizeBox.shrink`):
> 1. IAP 8 元买断 (Apple 2.1 拒 — `iapEnabled=false`)
> 2. 失联通知 / 紧急联系人 SMS (阿里云未真接 — `emergencyContactEnabled=false`)
> 3. 5 厂商 push (米/华/OPPO/vivo/魅族 — `fiveVendorPushEnabled=false`)
> 4. EmailService 邮件导出 (SendGrid 未真接 — `emailServiceEnabled=false`)
> 5. vent + mood audio 录音 (业务闭环不全 — `ventAudioEnabled=false`)
> 6. PHQ-9 / GAD-7 量表 (en/zh_Hant 翻译不全 — `phqGad7I18nEnabled=false`)
> 7. Android BootReceiver (WorkManager 完善前 — `bootReceiverEnabled=false`)
>
> 业务真接后翻 flag = 立即恢复, 数据模型 / Repository / 业务代码全部保留。详见 `lib/core/data/feature_flags.dart` + `assets/legal/privacy_policy.md` §0.6。

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

## 🧪 测试

```bash
flutter test                          # 跑所有测试（v0.25 round 56e 后 1098 cases）
flutter test --coverage               # 覆盖率
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成

# 4 层架构纯度 + 一致性检查（v0.16 Round 13 起合并为 check_all.dart）
dart scripts/check_all.dart
# 注：dart run 在本项目会触发 objective_c build hook 失败，用 dart 直接跑
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

## 🐛 已知约束 (v0.25 round 48)

- `flutter_secure_storage` 在部分 Android 设备上首次启动有 ~200ms 延迟
- Web 平台用 `sqlite3.wasm` 走 IndexedDB，Chrome 隐身模式可能失败
- iOS 推送需要真机测试（模拟器无 APNs）
- SMS 走阿里云占位（v0.25 R55 上正式接入）
- 国产 ROM 静默杀后台通知：需接入 5 厂商 push (小米 / 华为 / OPPO / Vivo / 魅族)
  才能让推送送达率达 95%+ (R55 计划)

## 📄 文档

- `docs/CHANGELOG.md`：版本变更
- `docs/DEPLOYMENT.md`：部署指南（含阶段 8 国内 5 store + 5 厂商 push + 附录合规清单）
- `docs/`：设计规格、token 规范、实施 plan

## 📜 法律与合规 (v0.25 R54 增补)

**3 份法律协议** (`assets/legal/`)：
- `user_agreement.md` — 用户协议 (通用条款)
- `privacy_policy.md` — 隐私政策 (PIPL / HIPAA / GDPR 完整合规)
- `sensitive_data_consent.md` — 敏感个人信息处理同意书 (健康 / 树洞)

**上 store 前必修:**
- [ ] 律师过审 3 份法律文档 (法务负责)
- [ ] NMPA "非医疗器械" 声明 (见 `docs/DEPLOYMENT.md` 附录 A)
- [ ] 软件著作权登记证书 (CPDA 受理 1-2 月)
- [ ] ICP 备案 (域名 7-15 天)
- [ ] 5 厂商 push SDK 接入 (送达率 95%+, R55 计划)
- [ ] 阿里云 SMS provider 真接 (失联通知 production 必需, R55 计划)
- [ ] PIPL §13 单独同意实现 (联系人回复 Y, R55 计划)

**合规清单详情见 `docs/DEPLOYMENT.md` 附录 A (NMPA / HIPAA / GDPR /
PIPL) + 附录 B (v0.25 阻塞 TODO + 估时)。**

## 📜 许可

个人项目，仅供学习。
