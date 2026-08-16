# v1.1.0 round 11 (R115) 零外联隐私加固证据清单

> **状态**: 5/5 新守门员绿, 总守门员数 22→27 (+5)
> **目标**: 锁住"零云端 + 零推送 + 零外联"产品定位, 防止未来 commit 偷偷引入网络/权限
> **日期**: 2026-08-17

## 1. 设计原则 (why)

**精神心理 / 慢性病数据合规要求**:
- **PIPL §28** (中国个人信息保护法): 敏感个人信息 (健康 / 医疗) 需加密存储 + 最小化收集
- **HIPAA field-level encryption**: 静态加密 (at rest) + 传输加密 (in transit) — 零外联架构天然满足
- **Apple 5.1.3 Sensitive Apps policy**: 紧急功能 (一键拨打) 不能上传任何数据
- **Google Play Health/Sensitive Apps policy**: 通知 / 提醒功能需本地化, 不外联

**产品定位翻转 (1.1.0 round 4b emotion-first refactor)**: 精神心理自我关怀 App, 永久免费 + 零云端 + 零推送, 走 SQLCipher 本地加密。这份文档是 R115 视觉重构 (Batch 2) 加固零外联架构的硬约束证据。

## 2. 5 个新守门员 (R115 落地)

### 2.1 `check_permissions_whitelist.py` (B1)

**作用**: 扫描 `android/app/src/main/AndroidManifest.xml` + `ios/Runner/Info.plist`, 验证权限**严格白名单** (不允许多 1 项)。

**白名单**:
- Android 6 项: `INTERNET` / `POST_NOTIFICATIONS` / `SCHEDULE_EXACT_ALARM` / `WAKE_LOCK` / `VIBRATE` / `RECORD_AUDIO`
- iOS 4 项: `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` / `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription`

**黑名单 (显式禁止, 复活即 fail)**: 通讯录 / 位置 / 短信 / 摄像头 / 蓝牙 / 账户 / 系统弹窗 / 通知后台 Activity / 通知等 30+ 项

**实测**:
```bash
$ python3 scripts/check_permissions_whitelist.py
✅ 0 violation — 权限严格白名单保持
```

### 2.2 `check_no_network_io.py` (B2)

**作用**: 扫描 `lib/**/*.dart`, 验证零网络外联。

**禁止 import** (10 项): `package:http` / `package:dio` / `package:web_socket_channel` / `package:firebase_*` / `package:sentry_*` / `package:cloud_firestore` / `package:googleapis` / `package:aws_*` / `package:azure_*` / `package:crypto_`

**禁止 `dart:io` 调用**: `HttpClient()` / `WebSocket.connect()` / `HttpServer.bind()` / `Socket.connect(<远程>)` — 远程指非 localhost / 127.0.0.1

**`url_launcher` 白名单 scheme**: 仅 `tel:` / `mailto:` / `sms:` (走系统调用, 无需 INTERNET)

**实测**:
```bash
$ python3 scripts/check_no_network_io.py
✅ 0 violation — lib/ 零网络外联
```

### 2.3 `check_encryption_at_rest.py` (B3)

**作用**: 扫描 `lib/**/*.dart` 在 app docs 写文件的逻辑, 验证**必须走加密** (PIPL §28)。

**加密白名单**:
- SQLCipher database (`AppDatabase()`)
- `.m4a.enc` 加密音频 (`EncryptedFileStorage`)
- `swallow.log` 加密 audit log
- `flutter_secure_storage` (Keychain/Keystore)

**禁止明文写**: `.writeAsString*` / `.writeAsBytes*` 在 app docs 上下文 (未走加密)

**禁止明文后缀**: `.json` / `.txt` / `.csv` / `.log` / `.pref` / `.xml` / `.yaml` / `.yml` 写 app docs

**实测**:
```bash
$ python3 scripts/check_encryption_at_rest.py
✅ 0 violation — app docs 落盘全部加密
```

### 2.4 `check_pii_in_assets.py` (B4)

**作用**: 扫描 `assets/`, 验证无真实 PII (手机号 / 身份证 / 邮箱 / IPv4) 意外混进 release 包。

**注**: 不扫 `test/` — test 里的 PII 100% 是 fake fixture (测 PII 脱敏用), 已有多种 placeholder 模式豁免。

**行级豁免**: `// @pii-ok` 标记该行 (用于 demo fixture)

**实测**:
```bash
$ python3 scripts/check_pii_in_assets.py
✅ 0 PII found — assets/ 合规
```

### 2.5 `check_release_no_network.py` (B5)

**作用**: 验证 `lib/` + 平台 manifest 不引用任何外联域名 (除系统白名单)。

**白名单 URL** (走系统调用, 非外联):
- `schemas.android.com` (Android schema)
- `www.apple.com` (iOS privacy)
- `play.google.com` / `apps.apple.com` (商店链接)
- `example.com` / `docs.flutter.dev` / `pub.dev` / `github.com` (文档 + 包管理)

**扫描内容**:
- `lib/**/*.dart` 中 `http://` / `https://` 字符串字面量 + `Uri.https()` 调用
- `android/app/src/main/res/xml/network_security_config.xml` 的 `cleartextTrafficPermitted="true"` 标记
- `ios/Runner/Info.plist` 中的外联 URL

**实测**:
```bash
$ python3 scripts/check_release_no_network.py
✅ 0 violation — 零外联架构保持
```

## 3. 守门员矩阵 (R115 后总 27 个)

| # | 脚本 | 范围 | R115 状态 |
|---|---|---|---|
| 1-21 | 既有 21 个 (.py + check_all.dart) | 杂 | 维持 |
| **22** | `check_home_quick_actions.py` | Home 入口 | **R115 新** |
| **23** | `check_permissions_whitelist.py` | Manifest | **R115 新** |
| **24** | `check_no_network_io.py` | lib/ 网络 | **R115 新** |
| **25** | `check_encryption_at_rest.py` | lib/ 落盘 | **R115 新** |
| **26** | `check_pii_in_assets.py` | assets/ | **R115 新** |
| **27** | `check_release_no_network.py` | 跨平台域名 | **R115 新** |

## 4. CI 接入指引

```bash
# 27 守门员一气跑完
for s in scripts/check_*.py; do
    python3 "$s" || exit 1
done
dart scripts/check_all.dart || exit 1

# R115 终态
flutter analyze  # 0 error
flutter test    # 2512+ pass / 0 fail / 1 skip
```

## 5. 已知豁免 (有合理理由)

| 豁免项 | 文件 | 原因 |
|---|---|---|
| `INTERNET` 权限保留 | `android/app/src/main/AndroidManifest.xml` | R114 注释: 0 实际网络出口, 未来合规页面预留 |
| `RECORD_AUDIO` 权限 | 同上 | vent / mood 语音录音业务 (R104 启用) |
| `NSMicrophoneUsageDescription` | `ios/Runner/Info.plist` | vent / mood 录音 + 转写 |
| test 目录 PII | `test/**` | fake fixture 测 PII 脱敏功能, placeholder 模式自动豁免 |

## 6. 跨期残留 (R115+ 待办)

- **上架 P0 5 项**: 截图 / 域名 ICP / 4 邮箱 / AppIcon ≥200KB (外部依赖, 不在守门员范围)
- **CI workflow 接入**: 27 守门员串联到 .github/workflows (R115 Phase 4 后续)

## 7. R115 视觉重构相关

- Home / Settings 入口 emotion-first (用药/量表 → 二级入口)
- 详情见 `docs/design/2026-08-17-redesign-mockup/index.html`
- CHANGELOG `1.1.0+150` 章节

---

**维护者**: Mavis (R115)
**更新策略**: 新增外联功能前**先**讨论 + 更新本守门员 + 同步 AGENTS.md
