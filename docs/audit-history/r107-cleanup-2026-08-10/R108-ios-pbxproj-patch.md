# R108 iOS PrivacyInfo.xcprivacy pbxproj 修复步骤

> **背景**: R107 报告 P0-4 (`docs/audit/2026-08-10-cleanup/00-summary.md` §2.4)
> 精神心理患者敏感数据 (SQLCipher DB / vent audio / audit log) 默认随 iCloud Backup
> 上传 = PIPL §6 + §28 跨境数据风险 + App Store 5.1.1(4) 隐私清单 2024-05 起强制
> 上架拒。

---

## ⚠️ 前置条件 (Mac dev 必备)

本修复需在 **macOS 环境下** 跑, 原因:
- iOS 端注册 MethodChannel (P0-1) + pbxproj 修改 (P0-4) + xcodebuild 验证
- `python3` (macOS 自带) + Xcode 15+

**当前 Windows 环境无法跑 xcodebuild / pod install**, 本文档是 dev 在 Mac 上跑的 step-by-step。

---

## Step 1: 拉取 R108 修复

```bash
cd ~/work/chroniccare
git fetch origin
git checkout feature/r108-p0-1to5    # R108 修复 branch
git pull
```

**预期文件改动** (4 类):
- `lib/core/data/utils/skip_backup.dart` (新增)
- `lib/core/data/database/connection/native.dart` (改 1 行 + 注释)
- `lib/core/data/privacy/encrypted_audio_storage.dart` (改 1 行 + 注释)
- `lib/core/data/services/swallow_log_sink.dart` (改 1 行 + 注释)
- `lib/main.dart` (新增 1 helper + 1 call)
- `lib/core/data/services/notification_service.dart` (新增 _canScheduleExact)
- `lib/core/data/services/reminder_dispatcher.dart` (新增 useExactAllowWhileIdle field)
- `lib/core/l10n/strings.dart` (notifMedicationBody 签名改)
- `lib/core/data/services/medication_notifier.dart` (改 caller)
- `lib/presentation/pages/home/home_page_state.dart` (8 层 → 3 层 stagger)
- `ios/Runner/AppDelegate.swift` (新增 MethodChannel)
- `scripts/register_ios_privacy_info.py` (新增)
- `test/core/data/utils/skip_backup_round108_test.dart` (新增)
- `test/core/data/services/notification_service_can_exact_round108_test.dart` (新增)
- `test/core/l10n/strings_notif_body_round108_test.dart` (新增)
- `test/presentation/pages/home/stagger_clamp_round108_test.dart` (新增)
- `test/scripts/register_ios_privacy_info_round108_test.dart` (新增)
- `docs/CHANGELOG.md` (新增 R108 entry)

---

## Step 2: 跑 P0-4 修复脚本 (idempotent)

```bash
cd chroniccare  # 项目根目录

# 1. 验证: 当前是否已注册 (CI mode)
python3 scripts/register_ios_privacy_info.py --check-only
# 预期: ❌ PrivacyInfo.xcprivacy 未注册 ... exit 1
# (首次跑会失败, 修法继续 ↓)

# 2. 修复: 注入 pbxproj
python3 scripts/register_ios_privacy_info.py
# 预期: ✅ 已写回 ios/Runner.xcodeproj/project.pbxproj
#       ✅ Xcode → Runner target → Build Phases → Copy Bundle Resources
#       ✅ 应该看到 PrivacyInfo.xcprivacy 已加入
# exit 0

# 3. 验证: 再跑 --check-only 确认已注册
python3 scripts/register_ios_privacy_info.py --check-only
# 预期: ✅ PrivacyInfo.xcprivacy 已注册 ... exit 0

# 4. 兜底: 跑全部守门员
flutter analyze
flutter test
python3 scripts/check_*.py  # 18 个, 应该全绿
```

**关键警告**:
- ⚠️ 不要**手工**编辑 pbxproj (容易破坏 ID 唯一性 / 缩进 / 引号)
- ⚠️ 跑完脚本必须 `git diff ios/Runner.xcodeproj/project.pbxproj` 人工 review 4 处注入
  - PBXBuildFile section 增 1 行
  - PBXFileReference section 增 1 行
  - PBXResourcesBuildPhase (Runner target) `files` 列表增 1 行
  - PBXGroup (Runner group) `children` 列表增 1 行
- ⚠️ Xcode 重新打开 project 应**不**弹 "Convert to New Build System" 对话框
  (弹了 = pbxproj 已被破坏, 撤销改 `git checkout` + 找原因)

---

## Step 3: pod install (CocoaPods 项目)

```bash
cd ios
pod install --repo-update
cd ..
# 预期: Pod 安装完成, Podfile.lock 更新
```

**目的**: pod install 触发 .xcworkspace 重新生成, 把 R108 P0-4 注入的
PrivacyInfo.xcprivacy 链接到 Pods 项目。

如果 CocoaPods 报 "The sandbox is not in sync with the Podfile.lock":
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

---

## Step 4: Xcode 重新打开 + 验证

```bash
open ios/Runner.xcworkspace  # 必须 .xcworkspace, 不是 .xcodeproj
```

Xcode UI 验证 (5 步):
1. 左侧 navigator 选 Runner project
2. 选 Runner target → **Build Phases** tab
3. 展开 **Copy Bundle Resources** section
4. 应该看到 `PrivacyInfo.xcprivacy` (新增项)
5. 勾选确认 + 不勾选 = build 时会警告, 勾选 = 正常打包

如果看不到 PrivacyInfo.xcprivacy:
- 检查 `git diff ios/Runner.xcodeproj/project.pbxproj | head -100`
- 检查 `python3 scripts/register_ios_privacy_info.py --check-only` 返 0
- 检查 ios/Runner/PrivacyInfo.xcprivacy 文件存在 + 4.8KB+ 大小

---

## Step 5: xcodebuild 验证 (CI-style 验证)

```bash
# Debug 模式构建 (避免 codesign 失败)
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Debug \
           -sdk iphonesimulator \
           -destination 'platform=iOS Simulator,name=iPhone 15' \
           clean build 2>&1 | tee /tmp/xcodebuild.log

# 验证 PrivacyInfo.xcprivacy 在产物里
find ~/Library/Developer/Xcode/DerivedData -name "PrivacyInfo.xcprivacy" -type f
# 预期: 找到 1 个文件 (在 Runner.app/ 路径下)

# Release 模式构建 (codesign 需 Apple developer cert)
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -sdk iphoneos \
           -destination 'generic/platform=iOS' \
           CODE_SIGNING_ALLOWED=NO \
           build
# ⚠️ 跳 codesign = 只能在 simulator 跑, 真机需 Apple cert
```

**预期 log 关键词**:
- "Copying PrivacyInfo.xcprivacy" → ✅ 成功打包
- "Build target Runner" → ✅ 整体 build 成功
- 任何 "warning: PrivacyInfo not found" → ❌ pbxproj 注册失败, 回 Step 2

---

## Step 6: 上架前 checklist (P0-1 旁路)

P0-1 (iCloud Backup 排除) 跟 P0-4 (PrivacyInfo 注册) 是**独立**修复,
但都依赖 iOS build 链路, 一起验证:

### P0-1 (iCloud Backup)
- [ ] 跑 xcodebuild + 部署到真机
- [ ] 打开 iOS 设置 → Apple ID → iCloud → Manage Storage → Backups
- [ ] 找本 App → 看 "Backup Size" = 0 KB
      (实际 PII 文件被 `isExcludedFromBackup = true` 排除, 不计入 backup 大小)
- [ ] 或用 Xcode Device Console 跑 app, 在 iCloud backup 完成后
      restore 到新设备, 应该**没有** chroniccare.sqlite / vent_audio / swallow.log

### P0-2 (SCHEDULE_EXACT_ALARM)
- [ ] 部署到 Android 13+ 真机 (或 API 33+ 模拟器)
- [ ] 设置 → Apps → ChronicCare → Special access → Alarms & reminders
- [ ] toggle 关闭 "Allow exact alarms" (撤回 SCHEDULE_EXACT_ALARM 权限)
- [ ] 回 app, 设一个 1 分钟后的 medication reminder
- [ ] 1 分钟后, 通知可能延迟到 15 分钟内 (inexact 兜底) → 验证
- [ ] 重启 app, 看 logcat 有 `SCHEDULE_EXACT_ALARM 不可用, 降级 inexactAllowWhileIdle`

### P0-3 (锁屏 body 脱敏)
- [ ] 部署到 iOS 真机 + Android 真机
- [ ] 配 1 个 medication (e.g. 20:00 提醒)
- [ ] 锁屏, 等 20:00 通知 banner
- [ ] banner body 应是 "该吃药了 · 点一下 = 打卡", **不含** dosage / unit
      (修前: "2.5mg · 点一下 = 打卡")

### P0-5 (主页 stagger clamp)
- [ ] 打开 app 主页, 切换 → 重进 → 反复 10 次
- [ ] 主页入场 3 层 (header / summary / hero) 微 stagger 0/40/80ms
- [ ] 后 5 层 (encouragement / carousel / primary / today schedule / secondary) 无动画
- [ ] 总累加 ≤ 80ms, 前庭敏感用户应**不再**报告不适

---

## Step 7: 提交 + push

```bash
git add -A
git status
# 预期: 15+ 文件改动 (5 fix + 5 test + CHANGELOG + main.dart + ...)
# 关键: ios/Runner.xcodeproj/project.pbxproj 必须有 diff (4 处注入)

git commit -m "0.30 R108 round 108: P0 #1-5 + P0 #12 旁路修复 (iCloud Backup + 锁屏 PII + 主页 stagger + PrivacyInfo + main.dart developer.log)"

git push origin feature/r108-p0-1to5
```

---

## 排错

### Symptom 1: pbxproj 注入后 Xcode 报 "Parse Error"
- **原因**: ID 冲突 (24 hex char 不唯一)
- **修法**: `git checkout ios/Runner.xcodeproj/project.pbxproj`,
  检查 `register_ios_privacy_info.py` 里的 ID prefix (当前 `A1B2C3D4E5F6A7B8C9D0E1F1/F2`),
  改成项目未占用的 prefix (e.g. `A1B2C3D4E5F6A7B8C9D0E1R8`)

### Symptom 2: pbxproj 注入后 xcodebuild 报 "Multiple commands produce"
- **原因**: PrivacyInfo.xcprivacy 被同时注册到 PBXResourcesBuildPhase 2 次 (e.g. 之前手动加过)
- **修法**: `grep PrivacyInfo ios/Runner.xcodeproj/project.pbxproj | wc -l` 应 = 3
  (PBXBuildFile + PBXFileReference + Resources build phase 内引用 = 3)
  如果 = 4+ = 之前手动加过, 删除多余行

### Symptom 3: MethodChannel 调用时 iOS 报 "MissingPluginException"
- **原因**: AppDelegate.swift 没注册 `chroniccare/backup` channel
- **修法**: 检查 `grep "慢性护理/backup" ios/Runner/AppDelegate.swift` 应有 2 处
  (channel name + handler case)
- **额外**: 检查 `SkipBackup.channelName` (Dart 侧) == `"chroniccare/backup"`
  (Swift 侧) — 任何 1 char 不匹配都失败

### Symptom 4: SCHEDULE_EXACT_ALARM 仍 inexact
- **原因**: 通知 service 初始化前没调 rescheduleAll
- **修法**: 检查 main.dart runApp 后有 `addPostFrameCallback((_) => notifService.rescheduleAll(...))`
- **额外**: 部署后第一次启动可能走 inexact (权限未授予), 第二次启动才走 exact

---

## 后续 (R108b+)

- R108b (P0 #6 chroniccare.app 域名注册 + 2 邮箱) — 4h + 7-20d ICP
- R108c (P0 #5 iOS LaunchImage + AppIcon 真图) — 1.5h (designer 接力)
- R108d (P0 #7-11 上架物料补齐) — ~5-7d
- R109 (1-2 月) — 拆 6 大 god class (main.dart 459L / home_page_state 597L 等)
- R110 (1-2 月) — feature-first 重构

**总 R108 预估**: 12-14 工作日 / 2-3 sprint (P0 13 项)
**R108 (本批) 已完成**: 5 项 (#1 #2 #3 #4 #5) + 1 旁路 (#12) ≈ 7h
**R108 (本批) 剩余**: 0 代码项, 全部待 Mac dev 真机验证

---

## 文档版本

- 创建: 2026-08-10 (R108 P0 必修 subagent)
- 最后更新: 2026-08-10
- 关联审计: `docs/audit/2026-08-10-cleanup/00-summary.md` §2.4
- 关联 PR: feature/r108-p0-1to5 (待 push)
