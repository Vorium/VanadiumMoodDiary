# 慢病管家（ChronicCare）

> 我今天吃了药 · 精神心理患者吃药打卡 + 停药通知

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
fvm install 3.44.5
fvm use 3.44.5

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
| Flutter | 3.44.5 stable |
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
flutter test                          # 跑所有测试（702 cases）
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

## 🐛 已知约束

- `flutter_secure_storage` 在部分 Android 设备上首次启动有 ~200ms 延迟
- Web 平台用 `sqlite3.wasm` 走 IndexedDB，Chrome 隐身模式可能失败
- iOS 推送需要真机测试（模拟器无 APNs）
- SMS 走阿里云占位（v1.0 上正式接入）

## 📄 文档

- `PRD-v0.1-draft.md`：产品需求
- `docs/CHANGELOG.md`：版本变更
- `docs/`：设计规格、token 规范、实施 plan

## 📜 许可

个人项目，仅供学习。
