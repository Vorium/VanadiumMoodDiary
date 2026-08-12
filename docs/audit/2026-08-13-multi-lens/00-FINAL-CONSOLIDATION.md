# R110 综合审视最终整合报告 (2026-08-13, 10 视角并行)

> 基线: master `b22b284` 0.32.0+129 (R109 round 6 part 2) + 工作树 99 文件脏 (R109 round 6 未收尾)。
> 10 个 subagent 并行审计: 7 产品视角 (emilkowalski / superpowers-en / superpowers-zh / flutter-specification / AppStore / GooglePlay / Apple Health) + 顶层架构 + 2 路底层逐行 (domain+data / presentation+theme+routing)。
> 全部只读, 未跑 flutter analyze/test (工作树 mid-R109 transient)。

## 状态快照

- 项目: v0.32.0+129, schemaVersion 22 (迁移链 1→22 完整), 421 dart 文件 ~90K 行, 3 语 ARB 1230 key 100% parity
- R32 跨期残留验证: 11/11 代码级 P0 已闭环 (锁屏 PII / Spring 接线 / translucent AppBar / productId / 描述病名等)
- 新增硬问题: 通知 ID 碰撞 (P0 bug), domain purity 3 处违规 (CI 红), 12 处硬编码中文 (守门员盲区), 上架资产 100% 占位 (双平台)

## 加权综合评分 (非官方, 供参考)

- 架构层: 8.4/10 (usecase 层薄 -0.4, purity 违规 -0.5, scale_translations 三源 -0.3, AppDatabase 编排 -0.2, 其余健康)
- 底层: 7.2/10 (生命周期纪律优秀 +0.8, 通知 ID 碰撞 -0.4, i18n 12 处 -0.3, 睡眠圆统计 -0.1)
- 视觉层: 8.0/10 (token 集中器 100% 采纳, 8 feature 未 AppleListSection 化 -0.8, mood 双色板 -0.3, reduce-transparency 死代码 -0.2)
- 上架层: 2.5/10 (双平台资产/URL/keystore 全占位, 代码面已基本干净)
- **预估 R110 round 1 修完 P0 后: 7.5→8.3/10**

## P0 清单 (按优先级, 跨视角排序)

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| B1-1 | 底层·bug | ≤1h | **通知 ID 碰撞**: safety 5000 / assessment 7000 / mood 8000 / badge 9999 全部落在 medication [2000,202000) 与 refill [6000,206000) cancel 区间内 → 每次启动/改药/续方重排静默删除这些通知 |
| AR-1 | 架构·CI 红 | ≤2h | check_all.dart 3 处 domain purity 违规: phone_validator / feature_flags / flutter/foundation |
| SP-zh-15 | 底层·i18n | ≤2h | 12 处 "Phase 5 再补" 硬编码中文 (medication 4 文件), 11/12 ARB key 不存在 |
| SP-zh-16 | 底层·守门员 | ≤1h | check_strings_hardcoded.py 只查 static const, inline `title:'中文'` 全漏 |
| AS-07/08/14 | 上架·合规 | ≤4h | 紧急联系人部分可见 + "Mock/开发模式" 用户文案 + release 启动 validateForRelease 抛错横幅 |
| AS-01/02 | 上架·元数据 | 10min | review_information 4 占位符 + notes.txt 版本过时含虚假声明 |
| AS-03/E5 | 上架·外部 | 7-20d | privacy/support URL → chroniccare.app 未注册域名 (双平台硬阻塞) |
| AS-04~06 + GP-1~5 | 上架·资产 | 外部 | 双平台截图/图标 100% 占位 (iOS 0 张 / 68B / 10.9KB; Android 8×67B / feature_graphic 空白 / 1443B icon / tablet 0 / short_description 86字符) |
| GP-7 | 上架·构建 | 1h | keystore 未生成 → release AAB 无法构建 |
| SP-en-1/AR-3 | 架构·测试 | 2-3d | static_scale_translations 三源 1591L 重复, 全项目最大 0 测试块 |
| AR-2 | 架构·循环 | 1wk | 4 个 data service import 生成的 ARB → data→ui 循环, pub workspace 阻塞 |
| AR-4/AR-5 | 架构·编排 | 1-2wk | usecase 层薄 (6 文件 731L), saveSetup/clearAllUserData 在 AppDatabase |
| SP-en-10 | 测试·transient | — | R32 126 fail 需 R109 收尾后重验证 |

## P1 清单

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| EM-01 | 视觉 | 0.5h | mood 双色板漂移 (详情页旧灰蓝 vs 趋势页 iOS 板) |
| EM-02/AH-04 | 半成品 | 1-2d/页 | 8 feature 仍 0 AppleListSection (mood/vent/assessment/contact/settings/daily_tracking/crisis_hotline/mood_list) |
| EM-03/AH-07 | 半成品 | 2h | Spring.of(context) stub, bouncy/gentle 0 caller |
| EM-04/FS-10/AH-08 | a11y | 0.5h | page_scaffold `&& false` 死代码, reduce-transparency 承诺未兑现 |
| SP-en-2~5 | 测试 | ≤1w | 15+ 个 ≥400L god class 0 测试 |
| SP-en-6/7 | 测试 | ≤1.5h | schemaVersion 22 无迁移测试; aliyun_sms test 被 .disabled |
| B2-01/02 | 路由 | 0.4h | 日历空态 2 个死 push → 404 |
| B2-04 | 导航 | 1-2h | /medication 主 tab 在 ShellRoute 外, 底部导航不渲染 |
| AR-10 | 架构 | 3-5d | core/shared 非中性 (consent_gate→care_engine, swallow_error 全局 sink) |
| SP-zh-01~08 | docs | ≤2h | AGENTS/README/CHANGELOG 滞后 10+ 版本, R32 报告 untracked 死链 |
| GP-6/8/11/12/14 | 上架 | ≤4h | screening 措辞 / label 硬编码 / Data Safety 表单 / 16KB 仅配置级 / badge 第 5 处缺 visibility |
| AS-09/10/11/13 | 上架 | ≤1h | 5.1.3 screening / SOP productId / pubspec+119 vs HEAD+129 / setup PIPL 同意 |
| FS-2 | 性能 | ≤1d | daily_tracking_page 单 build watch 8 stream |

## P2 代表项

B1-3 sleep 圆统计 (1d) · B1-4 MedicationTimes 无边界校验 (0.5h) · B1-7 评估提醒 past-fireAt (2h) · FS-3/4/7/9/11 · B2-03/07/09/10/11 · SP-en-12/13/16/18 · AH-09 SF Symbol 0 / AH-10 palette 窄 · AR-9 DRY / AR-13 providers 散 / AR-14 pub workspace 前置 · GP-16/18

## P3 / 卫生

B1-5/6 · SP-zh-09~14 (.bak / worktree / tmp / 行尾 / 归档 / 命名漂移) · B2-05/08/12 · EM-05~13

## 已闭环验证 (R32 跨期)

锁屏 PII (Darwin 5 处 + Android 4 处 secret + 静态 title) · 描述病名 4 locale 清除 · productId · 8 raw IconButton → PressFeedback · Spring.standard 接线 · translucent AppBar blur(20) · check_pii_in_title 扩 safetyAlertTitle · zh_Hant {name} 清除 · spec baseline 2019→2103 · curveAppleSheet/Drawer 删除 · ARB 3 语 parity · fullwidth 0 · 迁移链 1→22 · 生命周期审计全绿 · check_cross_feature 0 violation

## 外部链接隐藏确认 (用户 item 1)

- ✅ 已隐藏: IAP (iapEnabled=false) / 5 厂商 push / 邮件导出 / 设置页联系人 / webview/mailto/http 0 存在 (仅 tel: 危机热线)
- ❌ 部分可见: setup 联系人表单 (setup_step_welcome.dart:130-183, 无 gate) + reminders_hub 安全卡 (带 "当前使用 Mock" 红色横幅) + safetyAlertBodyMocked "开发模式" 文案
- ⚠️ 占位: 全部 privacy/support URL 指向未注册 chroniccare.app (双平台硬阻塞, 需 ICP 7-20d)

## 架构结论 (用户 item 3)

4 层纯度 3 违规 (先修) · data→presentation l10n 循环 = pub workspace 最大阻塞 · 仓库层 17:1 healthy · 跨 feature 隔离干净 (树洞 0 泄露) · usecase 层最薄 · AppDatabase 编排 2 处 · 重构路线: ①修违规(小时) → ②SetupService/DataWipeService(1-2wk) → ③scale_translations 合一(2-3d) → ④l10n 循环(1wk) → ⑤god class 拆+测试(1mo) → ⑥feature-first+workspace(最后)

## 底层结论 (用户 item 4)

全树 ~90K 行已遍历: 生命周期纪律优秀 (9 订阅全 cancel / 8 timer 全 dispose / audio 顺序 / 61 mounted 守卫) · DateTime.now() 入口单次化 · 真 bug: B1-1 通知 ID 碰撞 + B1-3 睡眠圆统计 + B1-7 评估提醒 → 修复计划见 `10-line-by-line-presentation.md` / `09-line-by-line-domain-data.md`

## R110 修复路径

- **R110 round 1 (本批 commit 1)**: 审计报告入库 + 仓库卫生
- **R110 round 2 (本批 commit 2)**: docs 对齐 (README/AGENTS/spec/CHANGELOG/pubspec/notes.txt)
- **R110 round 3 (本批 commit 3)**: P0 代码闭环 (通知 ID 带 / purity / 联系人 gate / Mock 文案 / validateForRelease / 12 处 i18n / 2 死路由 + shell / badge visibility / 守门员扩规)
- **R109 收尾 (transient)**: 99 文件脏 working tree 归类 3 commit; 126 i18n fail 重验证
- **外部依赖**: 域名 ICP + 4 邮箱 + 截图/图标 (设计师) + keystore → 上架
- **R111 及以后**: god class 专项 + scale_translations 合一 + usecase 厚化 + feature-first (R110 路线图)