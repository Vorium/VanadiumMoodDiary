# R120 main-agent 自查

> 1.1.0 round 12l (R120 综合审视): 主 agent 自查报告, 等 4 subagent
> (emil / flutter-spec / superpowers-zh / frame-thinking) 报告完成后整合
> 到 `00-FINAL-CONSOLIDATION.md`。

## 综合评分基线

| 审视轮次 | 综合 | 主壳 god class 拆分 | 守门员绿数 | test pass |
|---|---|---|---|---|
| R107 (2026-08-10) | 6.2 | 0/12 | 21/21 | 2416 |
| R108 (2026-08-10) | 6.2 | 0/12 (R108 拆解 in progress) | 21/21 | 2377 |
| R31 Apple Health 重设 (2026-08-11) | 7.5 | 0/12 | 21/21 | 2416 |
| R115 emotion-first 重构 (2026-08-17) | 7.0 | 0/12 | 22/27 | 2509 |
| R116 god class 4 round (2026-08-17) | 7.0 | 0/12 | 22/27 | 2515 |
| R117 11 视角综合 (2026-08-17) | 7.0 | 0/12 | 27/27 (5 上架 P0) | 2515 |
| R118 P2-7 (10 量表) (2026-08-17) | 7.5 | 1/12 | 27/27 | 2561 |
| R119 P1-1 (app_database) (2026-08-17) | 7.7 | 2/12 | 27/27 | 2566 |
| **R120 P1-2 (notification_service) (2026-08-17)** | **7.8** | **3/12** | **27/27** | **2571** |

**预期 R120 整合后**: 7.8/10 (R119 7.7 → R120 7.8, +0.1), 4 视角综合验证后 7.5~8.0 区间。

## R108 §六 候选进度 3/12

| # | 文件 | 状态 | 拆分模式 | R-round |
|---|---|---|---|---|
| 1 | `static_scale_translations.dart` 659L | ✅ R118 拆 10 量表 | composition + 委托 | R118 P2-7 |
| 2 | `app_database.dart` 564L → 139L + 480L part | ✅ R119 | `part of` 共享 library scope | R119 P1-1 |
| 3 | `notification_service.dart` 386L → 257L | ✅ R120 | 私有方法 + doc 外移 | R120 P1-2 |
| 4 | `audio_lifecycle.dart` 659L | ⏭ 跳过 (R117 误判: 1 mixin + 1 静态) | n/a | n/a |
| 5 | `mood_trend_page.dart` 653L | ✅ 早 R116 round 1 拆 | chart 抽 4 文件 | R116 |
| 6 | `reminders_hub_page.dart` 441L | ✅ 早 R116 round 2 拆 | sheet 抽 1 文件 | R116 |
| 7 | `medication_page.dart` 380L | ✅ 早 R116 round 3 拆 | row 抽 1 文件 | R116 |
| 8 | `add_medication_page.dart` 247L | ✅ 早 R116 round 4 拆 | indicator + footer 抽 2 widget | R116 |
| 9-12 | UI pages (vent / mood / setup) | ⏭ R108 §六 误判, 实际是 UI 页面, 不是 service 类 | n/a | n/a |

**R108 §六 12 候选** 中**真可拆**的 7 个, R115/R116/R118/R119/R120 已闭环 **6 个** (4 UI page + 2 service)。
剩 1 个 `audio_lifecycle.dart` 是 R117 误判, 不是 god class (1 mixin + 1 静态)。

## R120 验收数据

### R118 P2-7 (10 量表独立 class)

| 量表 | 文件 | 行数 | 状态 |
|---|---|---|---|
| PHQ-9 | phq9_translations.dart | 94L | ✅ |
| GAD-7 | gad7_translations.dart | 84L | ✅ |
| ISI | isi_translations.dart | 83L | ✅ |
| PSS | pss_translations.dart | 84L | ✅ |
| WHODAS | whodas_translations.dart | 90L | ✅ |
| ASRM | asrm_translations.dart | 83L | ✅ |
| Level2 D | level2_depression_translations.dart | 84L | ✅ |
| Level2 A | level2_anxiety_translations.dart | 83L | ✅ |
| Level2 M | level2_mania_translations.dart | 81L | ✅ |
| Level2 P | level2_psychosis_translations.dart | 88L | ✅ |
| 主壳 (10 const + 70 委托) | static_scale_translations.dart | 394L | ✅ (R118 前 659L, -40%) |
| **合计** | **11 文件** | **948L** | **8 commit 闭环** |

**R118 测试**: `test/domain/entities/scale_translations/round118_direct_test.dart` 42 test case (边界 20 / 主壳委托 10 / 跨 class 共享 2 / 真实输出非空 10)

### R119 P1-1 (app_database 拆 part 文件)

| 文件 | R119 前 | R119 后 | Δ |
|---|---|---|---|
| `app_database.dart` 主壳 | 564L | 139L | **-75.4%** |
| `app_database_migrations.dart` (新 part) | 0L | 480L | new |
| **合计** | 564L | 619L | +9.7% (R119 doc + 1-line 委托 overhead) |

**R119 测试**: `app_database_split_round119_test.dart` 5 case (双存在 / part 指令 / 1-line 委托 / 24 version guard / 主壳 < 200L)
**修正**: `database_migration_dryrun_round8_test.dart` 改读 main + part 双文件

### R120 P1-2 (notification_service facade 收紧)

| 文件 | R120 前 | R120 后 | Δ |
|---|---|---|---|
| `notification_service.dart` 主壳 | 386L | 257L | **-33.4%** |
| `docs/architecture/NOTIFICATION_ID_BANDS.md` (新) | 0L | 54L | new |
| **合计** | 386L | 311L | -19.4% |

**R120 测试**: `notification_service_split_round120_test.dart` 5 case (双存在 / 私有方法 / showNow 1-line 委托 / ID doc 外移 / 主壳 < 350L)
**修正**: `notification_service_can_exact_round108_test.dart` A2 改用 `substring` 而非 `+ 3000` 硬编码缓冲

### R120 全量验证

| 指标 | R118 baseline | R119 | R120 |
|---|---|---|---|
| `flutter analyze` | 0 error / 0 warn | 0/0 | **0/0** |
| `flutter test` | 2561 pass / 0 fail / 1 skip | 2566 | **2571** |
| `dart check_all.dart` | 0 violation | 0 | **0** |
| 27 守门员 | 20 ✅ + 5 上架 P0 + 2 warn | 20+5+2 | **20+5+2** |
| R108 §六 候选 | 1/12 | 2/12 | **3/12** |

## R120 拆解模式跨 round 一致性

| 模式 | R118 | R119 | R120 | 一致性 |
|---|---|---|---|---|
| 拆解单位 | 量表 class (高内聚) | 1 个 part 文件 (24-version) | 私有方法 + doc 外移 | ✅ 不同模式适配不同文件, 不强求一致 |
| 公开 API 变化 | 0 (委托模式) | 0 (drift schema 不变) | 0 (NotificationDetails 1:1 保留) | ✅ 全 0 公共 API 变化 |
| drift / schema 风险 | 0 (domain 层) | 0 (schemaVersion 24 不变) | 0 (sub-service 接口不变) | ✅ 0 schema/data 迁移风险 |
| 回归 test 模式 | 42 case 直接单测 | 5 case (god class size guard) | 5 case (god class size guard) | ✅ 模式一致: 主壳 < N + 关键 invariant |
| rule3-whitelist | 0 (R57 已配对) | 0 (snake_case only) | 4 行号重生 (R120 缩行后) | ✅ 行号需重生, R120 已补 |

## 跨期 7 P0 external 残留 (跟 R108/R117 baseline 一致)

| P0 | 阻塞 | 预计解决 |
|---|---|---|
| iOS 截图 0 张 | 设计师资产 | 1-2 周 |
| iOS LaunchImage 68B | 设计师资产 | 1-2 周 |
| Android 截图 + feature_graphic 67B | 设计师资产 | 1-2 周 |
| AppIcon 1024×1024 ≥200KB | 设计师资产 | 1-2 周 |
| chroniccare.app 域名 + 4 邮箱 ICP | 阿里云备案 7-20d | 1-2 月 |
| 5 厂商 push SDK | 5 厂商审核 1-2 月 | 1-2 月 |
| 阿里云 SMS | 失联通知 100% 失效, 1-2 月 | 1-2 月 |

**零外联架构保持**: 1.1.0 round 4b 删除 SMS/Email/Contacts/IAP/SafetyWatch 后, 27 守门员 (`check_no_network_io`, `check_release_no_network`, `check_permissions_whitelist`) 全绿, 4 FeatureFlag (`ventAudio=true`, `fiveVendorPush=false`, `phqGad7I18n=false`, `bootReceiver=false`) 状态不变。

## R121 路线图建议

| 优先级 | 候选 | 风险 | 投入 |
|---|---|---|---|
| 1 | 跑 R120 综合审视 4 subagent 整合 (本轮) | 低 | 1h |
| 2 | 修 R120 subagent 发现的 P0/P1 问题 | 视发现 | 1-3h |
| 3 | 跨期 P0 跟进: chroniccare.app 域名 ICP 备案 | 外部 | 1-2 月 |
| 4 | 跑综合审视升级版: 加 7 subagent (apple-health / gdc-audit / frame / superpowers-en / superpowers-dispatch / googleplay / appstore) | 低 | 6-8h |
| 5 | R108 §六 第 4 round (UI page 拆解, R117 误判候选重审) | 中 | 2-3 周 |

## 已知问题 (R120 自查发现, 需 subagent 交叉验证)

1. **notification_service `👆 通知被点击` emoji + 1 处 `Android 13+` piiSafeLog CJK 字面量** (rule3-whitelist 已配对, R120 缩行后行号 137, 193, 207, 215-216)
2. **7 P0 external 跨期** — 等设计师资产 / 域名 ICP / 5 厂商 push
3. **`vent_list_page.dart` 684L** 仍超 350L, 但属 UI page 不是 service 类, 不在 R108 §六 候选
4. **`mood_audio_service.dart` 496L** 仍超 350L, 跨 audio recording 风险, R121 候选
5. **27 守门员 `check_strings_hardcoded` 规则 1 (28 处 static const/String R57 override)** — R120 后维持 28 处, 0 新增
