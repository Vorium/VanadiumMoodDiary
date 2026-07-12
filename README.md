# 慢病管家（ChronicCare）

> 我今天吃了药 · 精神心理患者吃药打卡 + 停药通知

## 🎯 产品

参考"死了么"模式做的精神心理患者专版吃药打卡 App。

**核心机制**：
- 每天点 1 次"我今天吃了药"
- 漏 2 天（48 小时）未打卡 → 自动发邮件给紧急联系人
- 邮件措辞："请你方便的时候提醒我按时吃药"（不是"快不行了"）
- 数据本地加密，不上传云端

**商业模式**：8 元付费下载（Google Play + App Store）

## 🚀 快速开始

```bash
# 1. 装 Flutter（如果没装）
# macOS:
brew install fvm
fvm install 3.41.9
fvm use 3.41.9

# 2. 装依赖
flutter pub get

# 3. 跑代码生成（Drift / freezed / Riverpod）
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
| Dart | 3.11.5 |
| 状态管理 | Riverpod 2.6 + freezed 2.5 |
| 本地数据库 | Drift 2.20（SQLite）|
| 路由 | go_router 14 |
| 邮件 | SendGrid |
| 加密 | flutter_secure_storage + encrypt (AES-256) |

## 📁 目录结构

```
lib/
├── main.dart              # 入口
├── app.dart               # App 根 + 路由
├── theme/                 # 设计 Token + Material 3 主题
├── l10n/                  # 国际化字符串
├── data/
│   ├── database/          # Drift 表 + 数据库
│   ├── repositories/      # 仓库层
│   └── services/          # 服务层（邮件/加密/通知/失联检测）
├── domain/
│   ├── models/            # 数据模型
│   └── logic/             # 业务逻辑（StreakCalculator / ReminderScheduler）
└── presentation/
    ├── providers/         # Riverpod Providers
    ├── pages/             # 页面（home/setup/settings）
    └── widgets/           # 通用组件
```

## 🧪 测试

```bash
flutter test                          # 跑所有测试
flutter test --coverage               # 覆盖率
dart run build_runner watch --delete-conflicting-outputs  # 监听代码生成
```

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

## 📄 文档

- PRD：`/workspace/prd-chronic-disease-app/PRD-v0.1-draft.md`
- 设计规格：`/workspace/prd-chronic-disease-app/design-spec.md`
- 设计 Token：`/workspace/prd-chronic-disease-app/design-tokens.md`
- 实施 Plan：`/workspace/prd-chronic-disease-app/IMPLEMENTATION-PLAN.md`

## 📜 许可

个人项目，仅供学习。
