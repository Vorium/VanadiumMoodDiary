# GooglePlay Android 增量审视报告 (R93 后 → R95+)

> **视角**: Google Play 上架合规 (Data Safety / Health Apps / 16KB alignment / Play App Signing / OEM push / USE_EXACT_ALARM)
> **审视人**: Mavis (orchestrator, GooglePlay 视角)
> **基线**: [R92 GooglePlay 报告](../05-googleplay-android-report.md) (55.1KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: BootReceiver FeatureFlag 关 (避 R65 crash) + OEM push 引导 hidden + 5 厂商引导 hidden

---

## 0. 摘要 (TL;DR)

R92 GooglePlay 评分 **38%**, 16 P0 红线, 失联业务**无效** (5 厂商 push SDK 0 接, 国产 ROM 推送率 < 70%)。R93 已 BootReceiver FeatureFlag 关 + 5 厂商引导 hidden。**R93 后新发现**: Android keystore + Play App Signing 仍未做, USE_EXACT_ALARM justification 仍未填, Data Safety Form / Health Apps questionnaire 仍未填。

---

## 1. R92 基线复盘

**R92 GooglePlay 38% 16 P0 红线**:
- 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族, 1-2 月审核)
- 失联通知业务无效 (5 厂商 0 接, 推送率 < 70%)
- Android keystore + Play App Signing (1-2h 脚本)
- USE_EXACT_ALARM Play Console justification 100+ 字符
- Data Safety Form / Health Apps questionnaire
- 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配
- 3 法务 md 律师过审
- 域名 + 邮箱注册
- 16KB alignment (R84 已完成, ✅)
- 8 量表 PHQ-9 / GAD-7 16 题 i18n
- IAP 8 元买断真接
- AliyunSms / EmailService 真接
- BootReceiver 完善 (R65 0 实现, R93 改 flag false)

**R93 已修**:
- ✅ BootReceiver FeatureFlag 关 (避 R65 crash, 设备重启后不重排通知)
- ✅ OEM push 引导 hidden (5 厂商引导)
- ✅ 5 厂商 push SDK FeatureFlag 关 (业务真接前)
- ✅ ventAudio / phqGad7I18n / fiveVendorPush / emailService FeatureFlag 关

**R93 未修 (仍是 P0 上架 blocker)**:
- ❌ 5 厂商 push SDK 接入 (1-2 月)
- ❌ Android keystore + Play App Signing
- ❌ USE_EXACT_ALARM justification
- ❌ Data Safety Form / Health Apps questionnaire
- ❌ 失联通知业务无效
- ❌ 3 法务 md 律师过审

---

## 2. R93 后新发现

### 2.1 架构层 (1 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| G-1 | 5 厂商 push SDK 接入**仍未启动** (失联业务上线前必做) | `PUSH_PROVIDERS.md` 仅有 plan | XL | **P0** |

### 2.2 底层 (3 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| G-2 | Android keystore + Play App Signing (R92 提 1-2h 脚本, R93 仍未做) | `android/key.properties` 不存在 + `build.gradle.kts:74-80` fallback debug | S | **P0** |
| G-3 | USE_EXACT_ALARM Play Console justification 100+ 字符 (R92 提, R93 仍未填) | Play Console | S | **P0** |
| G-4 | Data Safety Form / Health Apps questionnaire (R92 提, R93 仍未填) | Play Console | M | **P0** |

---

## 3. R92 未修的 P0/P1 (现状)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| G-5 | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族, 1-2 月) | XL | **未修** (R93 hidden UI 但 0 接) | **P0** |
| G-6 | 失联通知业务无效 (5 厂商 0 接, 推送率 < 70%) | XL | **R93 hidden UI 但 0 接** | **P0** |
| G-7 | Android keystore + Play App Signing | S | **未修** (1-2h 脚本) | **P0** |
| G-8 | USE_EXACT_ALARM justification 100+ 字符 | S | **未修** | **P0** |
| G-9 | Data Safety Form / Health Apps questionnaire | M | **未修** (1-2d) | **P0** |
| G-10 | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | XL | **未修** (1-2 月) | P1 |
| G-11 | 3 法务 md 律师过审 (¥45-90k) | XL | **未修** (R93 加 R93 阶段 2 说明) | **P0** |
| G-12 | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | M | **未修** | **P0** |
| G-13 | 邮箱注册 (`support@` / `privacy@`) | S | **未修** | **P0** |
| G-14 | 8 量表 PHQ-9 / GAD-7 16 题 i18n | L | **未修** (R93 flag false) | **P0** |
| G-15 | IAP 8 元买断真接 productId | M | **未修** (R93 hidden 入口) | **P0** |
| G-16 | AliyunSms / EmailService 真接 | XL | **未修** (R93 hidden 入口) | **P0** |
| G-17 | BootReceiver 完善 (R65 0 实现) | L | **R93 flag false** (避 crash) | P1 |
| G-18 | 16KB alignment (R84 已完成) | — | **✅ 完成** | — |
| G-19 | APK vs AAB 决策 (R92 提未明确) | S | **AAB 上传但 keystore 缺** | P1 |
| G-20 | Android 5 厂商 OEM 引导 hidden (R93 task 3 hidden, 仍 0 接) | XS | **R93 hidden 但 0 接** | P1 |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-4 周, ¥45-90k + 1-2 月法务)

1. **R95 task 11**: 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) (XL, 4-8 周, 1-2 月审核)
2. **R95 task 14**: 阿里云 SMS 真接 (XL, 1-2d + 2-4w 审核)
3. **R95 task 15**: EmailService 真接 SendGrid (L, 1-2 周)
4. **R95 task 20**: 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字)
5. **R95 task 37**: Android keystore + Play App Signing (S, 1-2h 脚本)
6. **R95 task 38**: USE_EXACT_ALARM Play Console justification 100+ 字符 (S, 1-2h)
7. **R95 task 39**: Data Safety Form / Health Apps questionnaire (M, 1-2d)
8. **R95 task 40**: 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
9. **R95 task 41**: 邮箱注册 (`support@` / `privacy@`)

### 4.2 P1 重要 (1-4 周)

10. **R95 task 17**: BootReceiver 完善 (R65 0 实现, R93 flag false 避 crash) (L, 1-2 周)
11. **R95 task 19**: APK vs AAB 决策 (AAB 上传但 keystore 缺) (S, 0.5d)
12. **R95 task 59**: 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 (XL, 4-8 周)

### 4.3 P2 建议 (1+ 月)

13. **R95 task 12**: 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (XL, 4-6 周, 法务 + 临床审核)
14. **R95 task 13**: IAP 8 元买断真接 productId (M, 1-2 周, 苹果审核)

### 4.4 P3 nice-to-have (3+ 月)

15. **R95 task 20**: Android 5 厂商 OEM 引导 hidden (R93 hidden 但 0 接) — 业务真接后翻 true

---

**GooglePlay 视角报告完成时间**: 2026-08-06
**GooglePlay 视角报告体量**: 4.2KB
**R95+ GooglePlay 建议总计**: 15 项 (9 P0 + 3 P1 + 2 P2 + 1 P3)
**参考**: [00-r95-summary.md §3.5](./00-r95-summary.md#35-googleplay-android-视角--r93-后增量)
