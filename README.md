# 慢病管家（ChronicCare）

> 情绪日记 + 树洞倾诉优先 · 用药记录辅助的精神心理自我关怀 App

**v1.1.0+148**（情绪优先重构, 2026-08-15）· Flutter 3.41.9 · 本地加密零云端

## 🎯 产品

为精神心理患者设计的情绪优先自我关怀 App：每天记录心情、随时向树洞倾诉，吃药打卡作为辅助支持。

**核心机制**：
- 每天记录 1 次心情（5 档情绪 + 状态短语 + 影响因素 + 语音）
- 树洞私密倾诉（文字 / 语音 / 标签，完全独立，不参与任何分析）
- 用药打卡记录辅助（streak / 多药物提醒 / 续方）
- 数据本地加密（SQLCipher + 敏感字段 AES-256），不上传云端

**目标用户**：精神心理疾病患者（抑郁、焦虑、双相等），需长期规律服药的人群。

**商业模式**：永久完全免费，无任何购买入口、收费项目或订阅。

## ✨ 功能

### 核心
- 情绪日记（5 档情绪 + 状态短语 + 影响因素 + 语音）
- 树洞（私密倾诉空间）：文字 / 语音 / 标签，完全独立不参与任何分析
- 情绪回顾页（周 / 月统计摘要）
- 每日打卡 + streak 跟踪
- 多药物管理（剂量、服用时间、停药/恢复、续方）
- 心理评估（PHQ-9 抑郁 + GAD-7 焦虑 + 历史趋势）
- 每日跟踪（睡眠 / 体重 / 社交节律 / 压力等 6 项）
- 危机热线（5 区域一键拨打）

### 通知与提醒
- 每天 20:00 通用打卡提醒 + 10am 软提醒（漏 1 天安慰）
- 多药物时间点精准推送、续方提前 N 天提醒、周期评估提醒
- 国产 ROM 适配：设置页通知自检卡 + 小米/华为/OPPO/vivo 等 7 品牌引导

### 报告与分析
- 趋势页（30 天热力图 + 柱状图 + 评估折线）
- 依从性日历（医生视角）+ 评估严重度分级
- PDF 报告导出 + JSON 数据导出/导入（换机不丢数据）

### 隐私
- SQLCipher 全库加密 + 敏感字段额外 AES-256
- 密钥存 flutter_secure_storage（iOS Keychain / Android Keystore）
- 零云端上传、零 analytics/ad/tracking SDK
- 敏感数据处理单独同意（PIPL §13）+ audit log 加密留痕

## 🚀 快速开始

```bash
# 1. 装 Flutter（如果没装）
brew install fvm
fvm install 3.41.9
fvm use 3.41.9

# 2. 装依赖 + 代码生成（Drift）
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# 3. 跑
flutter run

# 4. 跑测试
flutter test
```

> Web 平台不能用 `flutter run -d chrome`（drift worker 404），用 `flutter build web` + `python -m http.server 8358` 走 production 模式。

## 📦 技术栈

| 组件 | 版本 |
|---|---|
| Flutter / Dart | 3.41.9 / 3.12.2 |
| 状态管理 | Riverpod 3.3.2 |
| 本地数据库 | Drift 2.20.3 + SQLCipher 加密 |
| 路由 | go_router 14.6 |
| 图表 | fl_chart |
| 推送 | flutter_local_notifications 17 |
| 加密 | flutter_secure_storage + pointycastle (AES-256) |
| 录音 / 播放 | record 5.2.0 / audioplayers 6.1.0 |
| 文件分享 | share_plus |

## 📁 目录结构（4 层架构 + 共享层）

```
lib/
├── main.dart / app.dart    # 入口 + Riverpod ProviderScope
├── core/                   # 基础设施 umbrella
│   ├── data/               # data 层（DB / Repositories / Services）
│   ├── shared/             # 跨层共享（formatters / json_codec / mood_visual）
│   ├── theme/              # AppTokens + Apple Health 风格主题
│   ├── routing/            # go_router
│   └── l10n/               # domain 层 strings
├── l10n/                   # presentation 层 flutter_localizations（zh/en/zh_Hant）
├── domain/                 # 领域层（纯 Dart，0 Flutter 0 Drift）
│   ├── entities/  logic/  repositories/  usecases/
└── presentation/           # UI 层（providers / pages / widgets）
```

**依赖方向**：`presentation → domain ← data`。架构纯度 + 一致性检查：`dart scripts/check_all.dart`（注：用 `dart` 直接跑，`dart run` 会触发 objective_c build hook 失败）。

## 🧪 测试

```bash
flutter test            # 全部（实测 2280 pass / 1 skip [main_migration_i18n 范围外声明]）
flutter test --coverage # 阈值: domain ≥ 70% / data ≥ 45% / presentation ≥ 30%

# 21 个守门员（架构纯度 / i18n / 锁屏 PII / 合规 / 覆盖率等）
for s in scripts/*.py; do python $s; done
```

## 🛠 调试

```bash
flutter run --debug      # 调试
flutter run --profile    # 性能
flutter logs             # 看日志
flutter test --plain-name "测试描述"   # 跑单个 test
```

## 📱 打包

```bash
flutter build apk --release    # Android → build/app/outputs/flutter-apk/app-release.apk
flutter build ios --release    # iOS (macOS only)
flutter build web              # Web (H5)
```

发布冒烟一键脚本：`scripts/release_smoke_build.sh "<标题>"`（版本自增 + CHANGELOG 同步 + assembleRelease + apksigner + 16KB objdump 实测 + 桌面输出）。

## 🐛 已知约束

- 4 FeatureFlag 守门：`ventAudioEnabled=true`；`fiveVendorPushEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` 均 `false`（等外部依赖：5 厂商 push / 法务+临床审核 / WorkManager 完善）
- 5 厂商 push 走占位（1-2 月审核）
- 国产 ROM 静默杀后台：需用户手动开启自启动 + 精确闹钟白名单（设置页有品牌引导）
- iOS 推送需真机测试（模拟器无 APNs）；Web 走 IndexedDB，Chrome 隐身模式可能失败

## 📜 法律与合规

`assets/legal/` 3 份协议（中英双语）：
- `user_agreement.md` — 用户协议
- `privacy_policy.md` — 隐私政策（PIPL / HIPAA / GDPR）
- `sensitive_data_consent.md` — 敏感个人信息处理同意书（健康 / 树洞，PIPL §13 单独同意）

上架合规清单见 `docs/DEPLOYMENT.md` 附录 A/B + `docs/SUBMISSION_INFO.md`（console 表单文案 + 外部依赖登记）。

## 📄 文档

- `docs/CHANGELOG.md` — 版本变更（Keep a Changelog 格式）
- `docs/DEPLOYMENT.md` — 部署指南
- `docs/VERSION_1.0_PLAN.md` — 路线图
- `docs/audit/` — 历次综合审视报告（R95~R112 开发过程存档）

## 📜 许可

个人项目，仅供学习。
