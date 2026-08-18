# superpowers-zh 增量审视报告 (R93 后 → R95+)

> **视角**: 国内合规 + 中文规范 (PIPL / GB / NMPA / 简繁一致性 / Git 中文规范)
> **审视人**: Mavis (orchestrator, spzh 视角)
> **基线**: [R92 spzh 报告](../03-superpowers-zh-report.md) (73.9KB)
> **当前版本**: v0.30.0+85 (R93 已完成)
> **R93 后新增关键变化**: 3 法律 md 加 R93 阶段 2 业务暂停说明 + README 红 banner + DEPLOYMENT 阶段 5/6/7 补全 + 36 张 iOS 67B 占位 png 删

---

## 0. 摘要 (TL;DR)

R92 spzh 评分工程 8.0 / **合规 3.5 / 资质 1.0 / 中文 7.5 / Git 6.0**。R93 已用 FeatureFlag 守门 8 业务 (技术暂停), 但**法务过审 + 5 厂商 push + 8 量表 i18n + 域名邮箱仍是硬门槛**。**R93 后新发现**: `core/l10n/strings.dart` 479 字符硬编码中文 (跨层共享, 应走 ARB), `scale_translations.dart` 1528 字符 (P0 必修)。

---

## 1. R92 基线复盘

**R92 spzh 36 P0 上架 blocker**:
- **PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54** 全部法律条文合规
- 3 份法律 md 律师过审 (¥45-90k, 4 周)
- 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署
- 邮箱注册 (`support@` / `privacy@chroniccare.app`)
- 5 厂商 push SDK 接入 (1-2 月, 米/华/OPP/vivo/魅族)
- 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配
- IAP 8 元买断真接 productId
- 阿里云 SMS 真接 (法务 1-2 月模板审核 + AccessKey 申请)
- EmailService 真接 SendGrid
- 8 量表 PHQ-9 / GAD-7 16 题 i18n (法律责任)
- BootReceiver 完善
- 4 store 4 套独立 metadata + 截图
- 失联通知告知不准确 (PIPL §17 业务暂停 vs 文档矛盾)

**R93 已修**:
- ✅ 3 法律 md (privacy_policy §0.6 / user_agreement / sensitive_data_consent 修订历史) 加 R93 阶段 2 业务暂停说明
- ✅ README 红 banner 列出 7 项 FeatureFlag
- ✅ DEPLOYMENT 阶段 5/6/7 补全 (Apple metadata 模板 + 上架前 checklist + 部署监控)
- ✅ 8 业务 FeatureFlag 守门 (技术暂停, 但法务过审仍是硬门槛)
- ✅ 36 张 iOS 67B 占位 png 删 (Apple 拒审点)

**R93 未修 (仍是 P0 上架 blocker)**:
- ❌ 3 份法律 md 律师过审 (¥45-90k, 4 周)
- ❌ 5 厂商 push SDK 接入 (1-2 月)
- ❌ 8 量表 PHQ-9 / GAD-7 16 题 i18n (法律责任)
- ❌ 域名 + 邮箱注册
- ❌ IAP / AliyunSms / EmailService 真接 (业务真接)

---

## 2. R93 后新发现

### 2.1 架构层 (1 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| Z-1 | 8 业务 FeatureFlag 守门**只是技术暂停, 法务过审**才是业务上线硬门槛 | `lib/core/data/feature_flags.dart` | XL | P0 |

### 2.2 底层 (3 项)

| 编号 | 描述 | 文件:行 | 难度 | 优先级 |
|------|------|---------|------|--------|
| Z-2 | `core/l10n/strings.dart` 479 字符硬编码中文 (跨层共享, 应走 ARB) | `lib/core/l10n/strings.dart:155` | L | **P0 必修** |
| Z-3 | `scale_translations.dart` 1528 字符硬编码中文 (8 量表 16 题) | `lib/domain/entities/scale_translations.dart:326` | L | **P0 必修** |
| Z-4 | `home_page.dart` 580 字符硬编码中文 (8 widget 内部 fallback) | `lib/presentation/pages/home/home_page.dart:204` | M | P1 |
| Z-5 | 业务暂停 vs 文档矛盾**部分修** (剩 bootReceiver 已实现但 0 实现 / vent 撤回已实现但 PIPL §47 物理删) | `feature_flags.dart` + 法律 md | L | P1 |

---

## 3. R92 未修的 P0/P1 (现状)

| 编号 | 描述 | R92 难度 | R93 后现状 | 优先级 |
|------|------|----------|-----------|--------|
| Z-6 | 3 份法律 md 律师过审 (¥45-90k) | XL | **未修** (R93 加 R93 阶段 2 说明, 但仍标"草稿") | **P0** |
| Z-7 | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | M | **未修** | **P0** |
| Z-8 | 邮箱注册 (`support@` / `privacy@chroniccare.app`) | S | **未修** | **P0** |
| Z-9 | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族, 1-2 月) | XL | **未修** (R93 hidden UI 但 0 接) | **P0** |
| Z-10 | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | XL | **未修** | P1 |
| Z-11 | IAP 8 元买断真接 productId | M | **未修** (R93 hidden 入口) | **P0** |
| Z-12 | 阿里云 SMS 真接 (法务 1-2 月模板审核 + AccessKey) | XL | **未修** (R93 hidden 入口) | **P0** |
| Z-13 | EmailService 真接 SendGrid (法务 + API key) | L | **未修** (R93 hidden 入口) | **P0** |
| Z-14 | 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核) | L | **未修** (R93 flag false) | **P0** |
| Z-15 | 4 store 4 套独立 metadata + 截图 | L | **未修** (R93 删占位但真截图未补) | P1 |
| Z-16 | 失联通知告知不准确 (PIPL §17 业务暂停 vs 文档矛盾) | L | **R93 部分修** (README 红 banner) | P1 |
| Z-17 | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | XL | **未修** | P1 |
| Z-18 | PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54 全部法律条文合规 | XL | **未修** (R93 加 R93 阶段 2 说明) | P1 |
| Z-19 | `app_colors.dart` 538 字符 / `app_database.dart` 502 字符 注释中文 | XS | **未修** (注释, 翻译文档即可) | P3 |
| Z-20 | `sms_service.dart` 432 字符 / `email_service.dart` 350 字符 注释中文 | XS | **未修** (注释) | P3 |
| Z-21 | 繁简一致性 (OpenCC s2tw) | S | **未修** (R57 守门员已加) | P3 |
| Z-22 | 主体资质 (ICP / 公安备案 / 等保) | XL | **未修** (1.0 上线前必做) | **P0** |
| Z-23 | 临床审核 (PHQ-9 / GAD-7 临床有效性) | XL | **未修** (8 量表上线前) | **P0** |

---

## 4. R95+ 建议 (按优先级)

### 4.1 P0 必做 (1-3 月, ¥45-90k + 1-2 月)

1. **R95 task 9**: 30+ 硬编码中文业务 hotspot → 走 ARB (L, 1-2 周, +30 ARB keys)
2. **R95 task 11**: 5 厂商 push SDK 接入 (XL, 4-8 周, 1-2 月审核)
3. **R95 task 12**: 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (XL, 4-6 周, 法务 + 临床审核)
4. **R95 task 13**: IAP 8 元买断真接 productId (M, 1-2 周, 苹果审核)
5. **R95 task 14**: 阿里云 SMS 真接 (XL, 1-2d + 2-4w 审核, 法务模板 + AccessKey)
6. **R95 task 15**: EmailService 真接 SendGrid (L, 1-2 周, 法务 + API key)
7. **R95 task 20**: 法务过审 ¥45-90k, 1-2 月, 3 份 md 律师签字 (XL, 4-8 周)
8. **R95 task 22**: 主体资质 (ICP / 公安备案 / 等保) (XL, 4-8 周)
9. **R95 task 23**: 临床审核 (PHQ-9 / GAD-7 临床有效性) (XL, 4-8 周)
10. **R95 task 40**: 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 (M, 1-2d + 3-5d 部署)
11. **R95 task 41**: 邮箱注册 (`support@` / `privacy@chroniccare.app`) (S, 1-2h)

### 4.2 P1 重要 (3+ 月)

12. **R95 task 18**: PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54 全部法律条文合规 (XL, 1-2 月)
13. **R95 task 19**: 4 store 4 套独立 metadata + 截图 (L, 1-2 周)
14. **R95 task 31**: audit log 明文 (PIPL §47 删除权) (M, 1 周)

### 4.3 P2 建议 (3+ 月)

15. **R95 task 59**: 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 (XL, 4-8 周)

### 4.4 P3 nice-to-have (3+ 月)

16. **R95 task 21**: 繁简一致性 (OpenCC s2tw) 守门员加严 (S, 1-2d)
17. **R95 task 19**: `app_colors.dart` / `app_database.dart` / `sms_service.dart` / `email_service.dart` 注释中文 → 翻译文档 (XS, 1-2h)

---

**spzh 视角报告完成时间**: 2026-08-06
**spzh 视角报告体量**: 4.8KB
**R95+ spzh 建议总计**: 17 项 (11 P0 + 3 P1 + 1 P2 + 2 P3)
**参考**: [00-r95-summary.md §3.3](./00-r95-summary.md#33-superpowers-zh-视角-国内合规--中文--r93-后增量)
