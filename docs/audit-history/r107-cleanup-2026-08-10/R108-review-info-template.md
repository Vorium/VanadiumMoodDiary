# R108 fastlane review_information 占位模板

> **作者**: P0 必修 subagent B (v0.30 R108)
> **基线**: v0.30.0+85
> **状态**: ✅ 占位已创建 (TODO 待业务上线前替换)

---

## 背景

R107 报告 §2.2 + §5 appstore P0 阻断项 6 之一: `fastlane/metadata/ios/review_information/` 目录不存在 → Apple App Store Connect 上传时 fastlane deliver 报 "Missing required review information fields" 硬阻塞。

## Apple fastlane review_information 6 个标准字段

| 字段 | 用途 | 当前状态 | 替换时间 |
|------|------|---------|---------|
| `first_name.txt` | Apple Review 联系人 first name | TODO 占位 | 域名 + 邮箱注册后 |
| `last_name.txt` | Apple Review 联系人 last name | TODO 占位 | 域名 + 邮箱注册后 |
| `email_address.txt` | Apple Review 联系邮箱 | TODO 占位 | 域名 + 邮箱注册后 |
| `phone_number.txt` | Apple Review 联系电话 | TODO 占位 | 域名 + 邮箱注册后 |
| `demo_user.txt` | Demo 账号 (本项目无 login) | ✅ 真实内容 | 已完成 |
| `notes.txt` | 审核员补充说明 | ✅ 真实内容 (8 项指南) | 已完成 |

## 各项内容解释

### demo_user.txt (✅ 真实内容)

> This app does not require login — all data is stored locally on the device (SQLCipher + AES-256).

**为什么必须明确"无 login"**: Apple fastlane deliver 必读 demo_user 字段。如果审核员看不到 "no login" 声明, 会问 "怎么给我 demo 账号?" 拖延审核。

### notes.txt (✅ 真实内容)

8 项审核员指南:

1. **No login required** — 全本地, 无账号 / 无云端 / 无统计
2. **First-time setup** — 4 步 onboarding (consent → welcome → medication → done)
3. **Daily use** — 主页 "I took my medication today" 按钮
4. **Privacy** — SQLCipher AES-256 加密, 无第三方 SDK
5. **Languages** — en-US / zh-Hans / zh-Hant (繁简中文), Settings 切换
6. **Crisis resources** — 设置 → 危机热线 (6 个 region), 一键拨号
7. **Voice notes (vent/mood)** — 可选功能, 需麦克风权限, 全加密
8. **Feature flags** — 7 项后台依赖功能 (IAP, SMS, Email, 5 厂商 push) 业务暂停阶段, UI 不显示

### first_name / last_name / email_address / phone_number (TODO 占位)

**为什么是 TODO**: 域名 `chroniccare.app` 未注册 (R107 §2.1), 邮箱 `privacy@chroniccare.app` / `support@chroniccare.app` 未注册 (R95 task 41), 业务上线前必填。

**业务上线前替换步骤**:

1. 注册 `chroniccare.app` 域名 (Cloudflare 域名注册, 7-20 天 ICP 备案, R107 §2.1)
2. 注册 `privacy@chroniccare.app` 邮箱 (Cloudflare Email Routing, free tier)
3. 注册 `support@chroniccare.app` 邮箱
4. 替换 4 个 .txt 文件内容:
   - `first_name.txt` = "TODO: 真实名字" → "实际 first name"
   - `last_name.txt` = "TODO: 真实姓" → "实际 last name"
   - `email_address.txt` = "TODO: 真实邮箱..." → "support@chroniccare.app"
   - `phone_number.txt` = "TODO: +86 真实手机号..." → "+86 138 0013 8000 (开发团队手机)"
5. 跑 lock-in test `test/fastlane/review_info_exists_round108_test.dart` 验证:
   - 文件存在 + 非空
   - 联系信息 4 文件含 TODO 标记或真实信息 (替换后含真实值)
   - demo_user.txt 含 "no login" 声明
   - notes.txt 含审核员指南关键词

## 改动清单

### 1. 新建 `fastlane/metadata/ios/review_information/` 目录

```
review_information/
├── first_name.txt      (19 B, TODO 占位)
├── last_name.txt       (16 B, TODO 占位)
├── email_address.txt   (57 B, TODO 占位)
├── phone_number.txt    (41 B, TODO 占位)
├── demo_user.txt       (100 B, 真实内容)
└── notes.txt           (954 B, 真实内容, 8 项指南)
```

### 2. 新建 `test/fastlane/review_info_exists_round108_test.dart` (lock-in test)

- 锁住目录存在
- 锁住 6 个 .txt 文件存在 + 非空
- 锁住 demo_user.txt 含 "no login" 声明
- 锁住 notes.txt 含审核员指南关键词
- 锁住联系信息 4 文件含 TODO 或真实信息 (防御漏替换)

## 验证

```bash
# lock-in test (R108 上架前必跑)
flutter test test/fastlane/review_info_exists_round108_test.dart
# → 12 case 应全过
```

## 业务上线前 TODO 清单

- [ ] 注册 `chroniccare.app` 域名 (Cloudflare 域名注册 + ICP 备案)
- [ ] 注册 `privacy@chroniccare.app` 邮箱
- [ ] 注册 `support@chroniccare.app` 邮箱
- [ ] 替换 4 个 TODO .txt 为真实信息
- [ ] 跑 lock-in test 验证 (12 case 全过)
- [ ] 跑 `bundle exec fastlane deliver --submit_for_review` 上传测试

## 防御未来再误删

- lock-in test 强制 6 个文件存在 + 非空
- 业务上线前 4 个 TODO 替换后, lock-in test 应仍通过 (含 TODO 或真实信息)
- R108 注释 + 文档, R110+ refactor 必读
