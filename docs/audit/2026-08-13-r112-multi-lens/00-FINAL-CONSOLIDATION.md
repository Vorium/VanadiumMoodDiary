# R112 多视角综合审视最终整合报告 (2026-08-13, 9 视角并行)

> 基线: master `6bbb308` 0.32.0+140 + working tree R112 进行中 (127 modified + 13 untracked, pubspec 0.32.0+142)。
> 9 个 subagent 并行只读审计: 6 产品视角 (emil / superpowers / flutter-spec / AppStore / GooglePlay / Apple Health) + 顶层架构 + 2 路底层逐行 (domain+data / presentation+core)。
> 全部只读 0 代码改动; superpowers + flutter-spec + apple-health agent 实测门禁与测试。

## 状态快照

- 项目: v0.32.0+142 (working tree), schemaVersion 22, ~421 dart 文件 ~81K 行, 3 语 ARB 1250 key 100% parity
- `flutter test` = **2377 pass / 4 fail (iOS 资产占位) / 1 skip**; `flutter analyze` = **0 error / 3 warning / 133 info** (warning 非零, CHANGELOG 已提前宣称 "0 warning" 不实)
- 守门员: check_all 纯度+一致性 PASS; 13 个 python 守门员全绿 (review_information_todo warn-only 3 外部占位; check_16kb 仍指令模式无判定)
- R111 待验证清单 **8/8 项全实读闭环属实**: E1/E2/E3 export v5 (真 round-trip 7 test) / FS-14 死路由 / EM-14/16/21 / R111-02/03 / SP-111-02 warning 27→3 / mojibake 清零 / EM-05/02b/06b/15/17/18 / spring.dart 接入真 caller

## 加权综合评分 (非官方, 供参考)

| 视角 | 评分 | 一句话 |
|---|---|---|
| emil (设计) | 7.5 | token 层 9/10, 落地层 Card 方言 0 进展 + 新 helper 引入 1 回归 |
| superpowers (工程) | 8.5 | TDD 历史最佳档, 但 3 warning + AR-17 恶化到 4 源 |
| flutter-spec | 8.5 | R111 遗留闭环率最高 (8/12), spec §5.5-5.7 视觉债 0 进度 |
| AppStore | 4.0 | 代码面 9.5/10, 5 P0 全外部; 新发现 AS-22 拒因级文案 |
| GooglePlay | 6.0 | 元数据 3/4 收口; 6 P0 全外部; 4 个新 P1 (wrapper/生成器) |
| Apple Health | 7.0 | HealthKit 合规 10/10, spec 数字膨胀不可复现, 8 feature 0 ALS |
| 顶层架构 | 6.0 | 边界层满血; AR-16/17/18/19 四大债跨期; 2 个守门盲区新实锤 |
| 底层 domain+data | 8.0 | 1 新 P0 (E6 整 6 表丢数据) + 3 P1; 纪律全绿 |
| 底层 presentation | 8.0 | 2 P1 (ref-after-dispose 泄漏链 + 裸 log 泄 PII) + 9 P2 |
| **加权** | **≈7.1/10** | R111 7.3 微降: R112 修掉大量旧债, 但引入 E6/泄漏链/裸 id 回归 |

> 修完代码级 P0/P1 后预估 **8.3/10**; 上架外部闸门 (域名/资产/keystore) 不动则天花板 ~8.5。

## P0 清单 (按修复优先级; ★=本轮新发现)

### A 组 — 代码级 P0 (本周可闭环)

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| **★E6** | 底层·数据完整性 | M ~1d | **export v5 仍完全缺 6 张 daily tracking 表** (sleep/weight/socialRhythm/stress/treatment/anxietyAgitation, R91 功能) — 换机整块静默丢失; import 也不 clear 这 6 表 (主 agent 已实锤: export/ 目录 0 引用这 6 个 Dao, 唯一 3 处 sleep/anxiety 命中是 mood 4D 子字段)。R111 E1 只对 medications/mood/contacts 逐字段对照, 漏了整表。**v5 尚未 commit, 同批补完避免二次 schema bump** |
| AR-17 | 架构·内聚 | L 2-3d | scale 翻译 **R112 从 3 源恶化到 4 源**: scale_name_l10n (新) + assessment_center_card 私有 switch 未迁 + domain static 781L + l10n impl 810L 死代码 (**0 运行时 caller 实锤**, 186 method 全空 stub)。删 ~1,600L 的最高 ROI 项 |
| AR-18 | 架构·编排 | M 0.5d+ | usecase 6 文件 739L 中 **2 个死代码**: CheckSafetyUseCase / ScheduleRefillReminderUseCase 0 运行时 caller (service 直接调 logic 绕过)。先接线 (半天) 或删 |
| AR-16 | 架构·循环 | L 1wk | data→生成 ARB 仍 4 文件 (safety_watch_service/preset_medication_templates/cbt_pdf×2) + **新实锤 check_all 守门盲区**: data 规则只禁 presentation/ 不禁 l10n/, 3 轮审计没人管得住 → 先让 gate 红再修 |

### B 组 — 上架外部 P0 (100% 外部依赖, 与 R110/R111 一致 0 进展)

| ID | 标签 | 难度 | 描述 |
|---|---|---|---|
| AS-01/03/04/05/06 | 上架·外部 | 设计师+ICP | iOS: review 4 标记占位 / privacy-support URL→未注册 chroniccare.app (7-20d ICP) / 截图 0 / LaunchImage 3×68B / AppIcon 10.9KB |
| GP-1/2/3/7/URL/11 | 上架·外部 | 设计师+1h+ICP+console | Android: 8 截图 67B / feature_graphic 67B / icon 192 (需 512) / keystore 未生成 / 域名 / Data Safety+Health Apps+Exact Alarm+Permissions 4 表单 0 提交 |

## P1 清单 (代码级, 按修复优先级排序)

| # | ID | 标签 | 难度 | 描述 |
|---|---|---|---|---|
| 1 | E-02 | 底层·安全 | S 0.2h | legal_page.dart:94 裸 `developer.log` 无 kReleaseMode 守卫 — vent 删除失败 stack 泄 PII 到 release console (违反 R108 P0#12) |
| 2 | E-01 | 底层·泄漏 | M 0.5d | mood_audio_recorder_widget + vent_compose dispose 链在 unmount 后 `ref.read` → Riverpod 3.4.2 无条件 StateError 被吞 → **MoodAudioService native 句柄每次开弹窗泄漏 (100+/day) + 播放后明文 temp 文件永不删除 (PIPL §28)**。B1-11 已修 vent_detail, 这 2 处漏修, 复用"字段缓存"模式 |
| 3 | ★E7 | 底层·合规 | S 2h | profile PIPL §14 同意留痕 4 字段 (agreement/privacy/consentAt/revokedAt) 不导出 — E2 只修 contact 侧, 撤回状态跨设备断裂 |
| 4 | ★E8 | 底层·数据 | M 4h | medications 导出走 `watchActive()` — 软停药药名换机后从历史/报告消失 (报告生成用 watchAllIncludingInactive, 导出却用 active, 自相矛盾) |
| 5 | ★E9 | 底层·i18n | S 1h | 趋势日历选中日 8 新量表显示 raw scaleId ("level2_depression"), 只注入了 phq9/gad7 2 个 closure |
| 6 | ★R112-01 (emil) | 底层·i18n | S 10min | settings 量表列表 PHQ-9/GAD-7 subtitle 裸 id "phq9"/"gad7" 3 语回归 — scale_name_l10n switch 漏 2 case, 测试 `ids.sublist(2)` 恰好盲区 |
| 7 | EM-16b | 视觉·a11y | S ≤1h | 对比度只修 warning 档: success 2.4:1 / error 3.0:1 / warningStrong 2.3:1 仍作文字色; `fgOnSuccess=success` 是假 token |
| 8 | GP-R112-01 | 上架·文案 | S 30min | Android full_description 点名 PHQ-9/GAD-7 但 prod 被 gate 隐藏 (实际露 8 量表) — iOS 已中性化 Android 漏改, 误导描述拒审风险 |
| 9 | AS-22 | 上架·文案 | S 10min | en description "stay connected with loved ones" 描述已 gate 关闭的 SMS 功能 — 唯一新拒因级 (Apple 2.1) |
| 10 | AS-21 | 上架·文案 | S 5min | promotional_text "mental health assessments" — R109 宣称删从未落地, R110/R111 双双漏提 |
| 11 | AS-23 | 上架·流程 | S 15min | Fastfile `submit_for_review:true` + 0 截图 = 一键提交脚本枪 |
| 12 | GP-R112-02 | 上架·构建 | S 15min | gradle-wrapper.properties 提交 `file:///C:/Users/18449/...` 机器路径 + wrapper 三件套被 .gitignore 排除 — 干净机器 release build 必断 |
| 13 | GP-R112-03/04 | 上架·表单 | S 1h | Data Safety / Health Apps 2 个生成器过期: 缺 Audio 数据型 (R111-1 未闭环) / 量表名失真 / 电话号过度申报 / 版本硬编码 0.30.0+85 |
| 14 | GP-R112-05/06 | 上架·表单 | S 2h | Exact Alarm 申报文案 + 麦克风 Permissions Declaration 文案未备 |
| 15 | AS-17 残留 | 上架·问卷 | M 0.5d | 5.1.3 Health Disclosure 问卷未起草 (提交周前 1 周做) |
| 16 | SP-R112-01 | 底层·门禁 | S 0.5h | 3 warning 违反 0-warning 门禁 + CHANGELOG 提前宣称 "0 warning" — 删 3 个 unused import 即绿 |
| 17 | EM-02/AH-04 | 半成品·视觉 | L 1-2d/页 | 8 feature 仍 0 AppleListSection (settings 41 Card 最重) — 4 轮审计唯一 0 进展项, 截图前必修 |
| 18 | FS P1-001 | 半成品·视觉 | M 3-6d | spec §5.5-5.7 mood/vent/assessment 3 feature ALS 化 0 进度 |
| 19 | R112-ARCH-01 | 架构·分层 | M 1-2d | legal_consent_provider 291L (presentation) 直接 SharedPreferences 持久化 PIPL 证据链 |
| 20 | R112-ARCH-02 | 架构·依赖 | S ≤1d | data→core/routing 传递 Flutter 依赖 (notification_service/initializer→notification_navigation), 第二处守门盲区 |
| 21 | R112-ARCH-03 | 架构·尺寸 | M 1d | export_import_pipeline 530L 新 god class, 4 子任务注释计划 5 轮未执行 |
| 22 | AR-19 | 架构·内聚 | XL 3-5d | saveSetup/clearAllUserData 仍在 app_database:420-519 (setup 原子性依赖 transaction) |
| 23 | AR-20 | 架构·尺寸 | XL 1-2mo | god class 21 个 ≥400L, 拆解仅 1/21 (medication_page), 多数反涨 |
| 24 | AR-23 | 架构·耦合 | L 3-5d | swallowError 77 处调用点跨 40 文件, 建议 3 簇 (audio/notification-safety/export) scoped sink |

## P2 代表项 (合并去重)

- **底层**: R112-01 mood_trend 日均算法错 (加权衰减均值, [5,1,1]→2.0 而非 2.33) · R112-02 MoodDetailPage 332L 死代码 (列表条目无详情入口) · R112-03 影响因素 chips en 用户看中文 (kInfluenceFactorsL10n 0 caller) · R112-04 setup `if (!mounted) setState` 反模式 · R112-05 onReorder deprecated + drag index 用 sortOrder · R112-06 sparkline maxTotal 写死 phq9 27/其他 21 → WHODAS 48 画出界 · R112-07 `/medication/detail/abc` int.parse 崩深链 · R112-09 setup MedCard 时间 chip 增删不重建 · R112-05 import isActive 裸 `as bool?` cast 脏数据崩全导入 · R112-06 lastCheckInAt 导出不读 · SP-R112-04 E5 StateError 新抛路径 0 测试 · E-02 同源 grep 复查 (unawaited+ref.read)
- **视觉**: EM-14b AppListTile 无 onTap 仍 scale+haptic · EM-07 fl_chart 3 处 Colors.white · EM-09b _ChipBadge 三副本 · R112-02 (emil) 18pt more icon tap target <44pt · EM-11 72pt quick mood spec 未落地 · AH-16 medication 4 tile 全同色同 icon + tintedMetricSoft 死 token · AH-08 reduce-transparency 假代理 · AH-15 vent FAB 未落地 · AH-09 SF Symbol 0
- **spec 漂移** (一次修): AH-13 spec:318 完成度数字膨胀不可复现 (home 17 vs 实测 4) · AH-17 spec:401 test baseline "2103" 过期 (实测 2312 声明/2377 pass) · R112-AH-101 headline 24/1.6 未改 22/1.5 · R112-AH-102 hairlineDivider 从未落地 · R112-AH-103 tile 88pt→110 注释矛盾 · R112-AH-105 SectionHeader 11→13pt 未写回 spec · R112-05 apple_list_section 注释仍称 11pt
- **上架**: AS-20 keywords "mental,health" (R109 宣称删未落地) · AS-24 新守门员 docstring 漂移 + 不校验 4 文件存在性 · AS-25 xcprivacy ContactInfo 声明但功能全 gate · GP-R112-07 check_16kb 假阳性 "显式 ndkVersion" (实际 flutter.ndkVersion 引用) · R111-2 0 release 产物 R8/shrink 全链未验证 · R111-3 safety_alert visibility:public 待法务 · FS golden test 0 落地 (spec §8.2)
- **测试/卫生**: FS P2-005 test 直 import audioplayers_platform_interface · SP-R112-05 data 覆盖率余量仅 +1.5pp · SP-R112-06 check_16kb 无 exit-code 语义 · SP-R112-03 (同 AR-18) · setup_redesign 1 处死 fake override 漏网 · check_in_button.dart:86 缩进 format 未跑

## 四类问题 (用户任务 1)

### 1. 上架
- **代码面 9.5/10 达提交水准且 R112 更干净**: 锁屏 PII 收敛到历史最佳 (userName 从 title+body 双删) / PrivacyInfo 五处一致 0 假声明 / IAP 隐藏链路完整 / AS-16/02/15/17 四项闭环 / short_description 86→71 / changelogs 已写 / GP-10 重授权 UI
- **硬阻塞 100% 外部依赖**: 域名 ICP (7-20d) → 设计师资产 (截图/Icon/LaunchImage/feature_graphic, 2-3d) → keystore (1h) → release build 冒烟+16KB objdump (1d) → console 4 表单 (含 RECORD_AUDIO Audio 申报, 2-3h) → review_information 真实值 + 5.1.3 问卷
- **新拒因风险 2 项 (本批新发现, 10min 可修)**: AS-22 description 描述已关闭功能 / GP-R112-01 Android 文案点名被隐藏的量表
- **构建链地雷**: GP-R112-02 gradle wrapper 机器路径 + 三件套未入库 — keystore 修好后第一脚就会踩

### 2. 架构 (结论: 4 层 + core umbrella 对 81K 行够用, feature-first/pub workspace 现在不推荐)
- 边界层满血: purity 0 violation / 一致性 1:1 / 跨 feature 0 / repo 17:17 / 覆盖率 18 项 PASS
- **2 个守门盲区新实锤**: check_all data 规则不禁 l10n/ 不禁 core/routing/ → AR-16 + R112-ARCH-02 三年没人管得住。修复 = 先让 gate 红
- 结构层四大债 (AR-16/17/18/19) 全部跨期残留, AR-17 反恶化到 4 源
- 重构路线 (风险调整价值排序): ① AR-17 删 1,600L 死代码 (2-3d) → ② AR-18 接线 2 个死 usecase (0.5d) + E6 export 补 6 表 (1d, 跟 R112 同批!) → ③ AR-16 守门先红后修 (1wk) → ④ AR-20 god class 接力 (4 批, 先测后拆) → ⑤ AR-23 swallowError 分簇 → ⑥ feature-first (仅前 5 步完成后)

### 3. 重构建议
- R112 收尾: E6+E7+E8 一个 PR (export v6 或同 v5 补全, 避免二次 bump) + AR-17 合一 + E-01/E-02
- 务实修正 usecase 目标: "6→14-16" 改为 "先接线 2 个死 usecase, 6→8"
- legal_consent_provider 抽 ConsentPreferenceStore (data service, 加密) — 与 AR-19 同批
- Fastfile release lane 加 fail-fast guard (0 截图即 abort)
- 2 个 console 表单生成器改为从 feature_flags.dart + scale_registry.dart 读真实状态生成

### 4. 半成品 / 死代码 (删除优先级排序)
1. AppLocalizationsScaleTranslations 810L (0 runtime caller, 186 method 全空 stub) — 删
2. CheckSafetyUseCase / ScheduleRefillReminderUseCase 174L (有 test 无接线) — 接或删
3. MoodDetailPage 332L (无路由无入口) — 挂 onTap 或删
4. Spring.of/SpringType/gentle/bouncy + tintedMetricSoft (0 caller) — 删或接第 2 caller
5. _ChipBadge ×2 私有副本 / AppListTile._isDestructive 假 API / kInfluenceFactorsL10n (0 caller)
6. showSafetyAlert userName 死参数 / BootReceiver.kt 死文件 / lastCheckInAt 导出不读

## 顶层架构结论 (用户任务 2)

- **是否可用更优架构**: 4 层 + core umbrella 当前规模够用 (证据: 3 轮守门全绿、边界 0 违规、覆盖率达标)。最大痛感不在"分层错了"而在"层内职责没落位" (编排散在 services/providers、死代码没删、god class 没拆)。feature-first (2-3wk) 是纯 move, 边际收益 < 成本, 不推荐现在做; pub workspace (1mo) 对零云端本地 App 无实际买家, 且 AR-16 不修必死锁, 排 v1.0+ 平台拆分时再评估
- **高内聚低耦合分项**: usecase 3/10 (2/6 死代码) / god class 4/10 (21 个, 1/21 拆成) / l10n 循环 2/10 / scale 内聚 2/10 (4 源) / 路由 8/10 (35 route 7 feature 文件, 1 个重复路由 /mood-diary+/mood-list) / 仓库层 10/10
- R112 正向动作: safety_watch_service 依赖收窄 / usecase 守门 warning 闭环 / user_name_helper 移到 domain 正确层

## 底层逐行结论 (用户任务 3)

- 全树 ~81K 行已遍历 (domain+data 170 文件 + presentation+core ~200/237 文件): **1 新 P0 (E6) / 7 新 P1 (E7/E8/E9 + E-01/E-02 + R112-01 emil + EM-16b)**
- 纪律全绿复验: 43 处 DateTime.now() 单次化 / 0 空 catch / 显式 sort / 通知 ID 5M+ 带 / 迁移链 v1→v22 / 锁屏 PII 0 泄露 / Timer+StreamSubscription dispose / check_pii_in_title PASS
- R111 宣称闭环 8/8 项实锤属实 (含 export v5 7 case round-trip、v19→v22 真实 dry-run、36 量表一致性 test)
- 唯一不实: CHANGELOG "0 warning" (实测 3) — 文档提前宣称

## R112 修复路径 (建议)

- **R112 hotfix 收尾 (本周, 代码级 ~3.5-4d)**: ① E6+E7+E8+E9 export 补全 (1d, 最高优先真 bug, 与 v5 同批) → ② E-01/E-02 (0.7d) → ③ R112-01 (emil) 补 2 case + EM-16b 对比度 (0.2d) → ④ SP-R112-01 3 warning 清零 + CHANGELOG 改实测数 (0.1h) → ⑤ AS-21/22/23 + GP-R112-01/02 上架文案/wrapper (1h) → ⑥ AR-17 删死代码 + 接线 2 usecase (3d) → ⑦ GP-R112-03/04 生成器刷新 (1h) → ⑧ 上架外链/asset 部分 (Fastfile guard 15min, 其余外部) → 预期 8.3/10
- **R113 视觉专项**: EM-02/AH-04 8 feature ALS 化 (先 settings 4 组 + vent + assessment) → 集中器自清 (ChipBadge 合一/Spring 死代码/注释同步) → golden test 3 核心 widget
- **R112/113 架构专项**: AR-16 守门先红 (0.5d) → AR-19+R112-ARCH-01 数据编排下沉 (5d) → AR-20 god class 批1 export_import_pipeline 拆 4 子函数 (1d)
- **外部闸门 (并行)**: 域名 ICP → keystore (1h) → 首次 release build 冒烟 + 16KB objdump (1d) → console 4 表单 → 设计师资产 → review 真实值 + 5.1.3 问卷
- **v1.0 (2027-Q1)**: HealthKit / 鸿蒙 / 5 厂商 push / 阿里云 SMS / IAP 真接

## spec / README 更新 (用户任务 4, 主 agent 已执行)

- `docs/design/2026-08-10-apple-health-redesign/spec.md`: 完成度数字重算写回 (ALS 实测 27 处调用, 非 17/20/55) + §5.5-5.7 进度标记 + SectionHeader 13pt / headline 22 / lineHeight 1.5 / test baseline 数字同步
- `README.md`: 测试数字 (2377/4/1)、R112 段落、守门员 22 状态、god class 21 最新表
- `AGENTS.md`: 本轮 R112 审视章节 + 数字同步
