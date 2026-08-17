# R120 superpowers-zh 视角审视

> R120 综合审视 (2026-08-17, 4 视角) — superpowers-zh subagent 报告
> 主 agent 基线: R120 7.8 / R119 7.7 / R118 7.5 / R115 7.0 / R108 6.2 / R31 6.5
> 范围: superpowers 方法论 (TDD / 系统调试 / 请求 + 接收 code review) + 中文文档完整性
> 输入: DEVELOPMENT_REQUIREMENTS.md / AGENTS.md / CHANGELOG.md / PRIVACY_HARDENING.md / 31 scripts/ 守门员

---

## 综合评分: 7.0 / 10 (R117 7.5 → R31 6.5 → R120 7.0)

持平 R117 baseline (7.5) 略扣 0.5, 升 R31 baseline (6.5) 0.5。3 批 god class 续拆 (R118 P2-7 10 量表 / R119 P1-1 app_database 564→139L / R120 P1-2 notification_service 386→252L) **技术执行扎实**: test-after 回归保护模式 100% 跟 R56c 模式一致, NOTIFICATION_ID_BANDS.md 2.7KB 新建是 spec §X.X 中文 dartdoc 引用范本。

**但 superpowers-zh 视角最看重的 4 个中文 doc 同步项**有 3 处 P0 漏洞:
- CHANGELOG 缺 R118 P2-7 entry
- AGENTS.md 缺 R117 R118 R119 R120 4 章节
- AGENTS.md EN Summary 2515 tests 落后 R120 2571 = 56 test 没同步
- PRIVACY_HARDENING.md 仍 R115 framing 跨期残留错位

守门员 27 数量正确, false positive 0 推测可信, false negative 3 处需加固 (R119 part of 引用 / R118 10 class 一致性 / R120 sub-service ID range 跟 doc 一致)。

---

## 1. TDD 实践度

| Round | 改动 | 测试模式 | 评估 |
|---|---|---|---|
| R118 P2-7 | 10 量表抽独立 class | `round118_direct_test.dart` 42 case 边界/委托/共享/真实输出非空 | **regression-protection** |
| R119 P1-1 | app_database 拆 `app_database_migrations.dart` part of | `app_database_split_round119_test.dart` 5 case 结构属性 + 更新 round8 解析 part 双文件 | **regression-protection** |
| R120 P1-2 | notification_service facade 收紧 + ID range 文档外移 | `notification_service_split_round120_test.dart` 5 case + 更新 A2 test 改 `substring(rescheduleStart)` 修字节数越界 | **regression-protection + 1 root-cause fix** |

**评估**:
- 3 批都是 "先改后加 test" 模式, 不是 red-green-refactor 经典 TDD
- 但跟项目 R56c 系列一致, 是项目自洽的 "soft architectural change 加 test 防回退" 模式
- R120 P1-2 A2 test 修字节数越界是**真 root-cause-driven fix** (R120 文件 11064→9930 字节后 `+ 3000` 硬编码缓冲越界 → 改用 `substring(rescheduleStart)`)
- 跟 R31 R110 R111 R112 R113 R114 R115 R116 累计 8+ round 模式一致 → **TDD 实践度 6.5/10**

**问题**:
- 3 批 test 都是结构性 (assert line count / contain substring), 不验行为
- R120 "showNow 是 1-line 委托" 验的是 `showNowBlock` 不含 `AndroidNotificationDetails(` → 文本特征, 行为覆盖靠 `notification_service_can_exact_round108_test`

---

## 2. 系统调试

| Round | bug fix | root cause | 评估 |
|---|---|---|---|
| R118 P2-7 | 0 bug fix (纯重构) | n/a | n/a |
| R119 P1-1 | 0 bug fix (纯重构) | n/a | n/a |
| R120 P1-2 | A2 test 字节数越界 fail | R120 文件缩行后 `+ 3000` 硬编码缓冲越过 file length → `substring()` IndexError | 修了 1 个 test flake, 符合 systematic-debugging |

**评估**:
- 3 批 0 业务 bug fix, 主要是 facade 收紧 / part of 拆 / 文档外移
- 1 个 test 修是 root-cause-driven: 不是把 test 改宽, 而是把 hardcoded `+ 3000` 改成 self-referential `substring(rescheduleStart)` → 字节数变化不会再次越界。**这个修法是 superpowers-systematic-debugging 范本**
- 但 0 业务 root-cause 调查证据 → 整体调试分不高

---

## 3. 中文文档完整性

### 3.1 P0 漏洞 (必须 R121 hotfix 闭环)

| # | 文档 | 现状 | 应有 | 修法 | 估时 |
|---|---|---|---|---|---|
| 1 | `docs/CHANGELOG.md` 1.1.0+15X 系列 | 缺 **R118 P2-7 entry** | R118 P2-7 跟 R119 同样 8 commit 流水 + 42 test + spec §X.X 模式 | 加 `## [1.1.0+1XX R118 P2-7 ...]` block | 0.5h |
| 2 | `AGENTS.md` 顶部 EN Summary | "**2515 tests pass**" 落后 R120 baseline **2571 = -56 test** | R120 baseline 2571 | 改 2515 → 2571 | 0.1h |
| 3 | `AGENTS.md` 章节列表 | 缺 **R117 R118 R119 R120 4 章节** | 跟 R110 R111 R112 R113 R114 R115 R116 一样写综合审视章节 | 加 4 章节 | 2h |
| 4 | `docs/PRIVACY_HARDENING.md` | 仍 R115 framing, 0 R118 R119 R120 章节 | R115 + R118 R119 R120 跨期残留 | 改 § 6 "跨期残留" 加 R118 R119 R120 段 | 0.5h |

**漏洞根因**: R118 R119 R120 god class 续拆是 1 周内 3 commit 流水, 跟 R108 R110 R111 R112 R113 R114 R115 R116 每 round 都有审视报告 + AGENTS 章节 + CHANGELOG entry 的模式**中断**。建议 R121 第 1 周把这 4 项补齐。

### 3.2 P1 漏洞 (建议 R121 闭环)

| # | 文档 | 现状 | 应有 |
|---|---|---|---|
| 5 | `AGENTS.md` EN Summary | 27/27 守门员 ✅, 1340 ARB keys ✅, 2515 tests ❌ | 全部 4 项对 (2515 → 2571) |
| 6 | `AGENTS.md` 21 守门员清单 | 仍写 "总数 22", 实际 27 (R115 +5 后) | 重写为 27 守门员清单 |
| 7 | `DEVELOPMENT_REQUIREMENTS.md` 32 守门员表 | 5 上架脚本没标"R117 P0-1~5"前缀 | 加 R117 R118 R119 R120 续拆关联 |
| 8 | `lib/domain/entities/scale_translations.dart` 头部注释 | 提到 R95 但**没**提 R118 P2-7 抽 10 量表 | 加 R118 注释段 |
| 9 | `docs/CHANGELOG.md` 1.1.0+150 R115 | "守门员总数: 22 → **27**" 但下一段 R116 round 1-4 没说守门员变化 | R116 R117 R118 R119 R120 都应"0 守门员变化"或具体数字 |

### 3.3 P2 优点 (保留, 跟 R31 R108 一致)

| 项 | 评估 |
|---|---|
| `docs/architecture/NOTIFICATION_ID_BANDS.md` 2.7KB | **新建范本**: 6 类 ID 范围表 + 顺序保证 + R114 B1-3 / v0.32 R110 B1-1 关键历史决策 + 验证脚本引用 + 1.1.0 round 4b 整摘说明 |
| `lib/core/data/database/app_database.dart` R119 注释 | **dartdoc 中文 + 解释 why 模式**范本 |
| `test/core/data/services/notification_service_split_round120_test.dart` 头部注释 | 跟 R119 R110 test 模式一致, "regression-protection" + "this test asserts structural properties" |

---

## 4. 守门员质量 (27 守门员 0 误报 验证)

### 4.1 27 守门员清单验证

`scripts/` glob 出 31 .py 文件, 减去 5 上架 P0 external = **26 active .py** + `check_all.dart` (1 .dart) = **27 守门员**, 跟 DEVELOPMENT_REQUIREMENTS.md / AGENTS.md / PRIVACY_HARDENING.md 全部一致 ✅。

### 4.2 false positive 风险

按 R120/R119/R118 改动维度评估 5 类改动应触发的守门员:

| 改动 | 应触发守门员 | 实际状态 |
|---|---|---|
| R118 抽 10 量表 | check_arb_keys / check_orphan_arb_keys / check_strings_hardcoded / check_no_pua / check_fullwidth_punctuation | ✅ 推测 0 误报 |
| R119 拆 part of | check_cross_feature / check_drift_namespace / check_usecase_layer / check_all.dart | ✅ 推测 0 误报 |
| R120 facade 收紧 + ID range 文档外移 | check_no_network_io / check_pii_in_title / check_review_information_todo / check_home_quick_actions | ✅ 推测 0 误报 |

### 4.3 false negative 风险 (R121 优先级 2 加固)

| # | 风险 | 当前状态 | 加固方案 |
|---|---|---|---|
| 1 | R119 part of 引用 broken 不报 | check_drift_namespace 只验 @DataClassName 唯一, 不验 part 引用 | 加 `check_part_directive.py` |
| 2 | R118 10 量表 class 一致性不回退 | round118_direct_test 是一次性回归保护 | 提到守门员 `check_scale_translations_class.py` |
| 3 | R120 sub-service ID range 跟 NOTIFICATION_ID_BANDS.md 文档一致 | 文档是 markdown, 没守门员扫 | 加 `check_id_bands_doc_sync.py` |

### 4.4 R120 5 上架 P0 external 状态

```
check_appstore_screenshots.py  ⏳ expected fail (设计师资产未到)
check_ios_launchimage.py       ⏳ expected fail (设计师资产未到)
check_appicon_size.py          ⏳ expected fail (AppIcon ≥ 200KB 未到)
check_appstore_metadata.py     ⏳ expected fail (review_information 真实值未填)
check_domain_icp.py            ⏳ expected fail (chroniccare.app 域名 ICP 7-20d)
```

5 项仍 0 闭环, 跟 R108 R110 R111 R112 R113 R114 R115 R116 R117 R118 R119 累计跨期一致 → 守门员本身"准备好了等资源", **0 误报**。

---

## 5. R121 路线图对齐

### 5.1 R108 §六 god class 续拆 6/12 闭环 (跟 R120 main-agent 自查一致)

| # | 文件 | R-round | 模式 |
|---|---|---|---|
| 1 | `static_scale_translations.dart` 659L | R118 P2-7 ✅ | composition + 10 class 委托 |
| 2 | `app_database.dart` 564L → 139L + 480L part | R119 P1-1 ✅ | `part of` 共享 library scope |
| 3 | `notification_service.dart` 386L → 252L | R120 P1-2 ✅ | 私有方法 + doc 外移 |
| 4 | `audio_lifecycle.dart` 659L | R117 误判 ⏭ | 实 1 mixin + 1 静态, 不是 god class |
| 5-12 | UI pages (mood_trend / reminders_hub / medication_page / add_medication / vent / mood / setup 等) | R116 round 1-4 + R117 误判 ⏭ | R108 §六 误判 5/8 实际是 UI page 模式 |

**R120 终态**: 6/12 真可拆已闭环, 1 R117 误判, 5 R108 误判。**R121 不应再列 R108 §六 续拆**, 应改走 AR-17/18/19 跨期残留 (R111 R112 报告)。

### 5.2 R121 建议路线图 (跟 `00-main-agent-self-audit.md` 对齐)

| 优先级 | 来源 | 内容 | 估时 | 预期评分 |
|---|---|---|---|---|
| **P1** | superpowers-zh 维度 3.1 | CHANGELOG 补 R118 P2-7 + AGENTS 补 4 章节 + EN Summary 同步 2571 + PRIVACY_HARDENING 加 R120 跨期残留 | 3.1h | 7.0 → 7.5 |
| **P1** | R31 P0 跨期残留 9 项 | review_information 4 TODO / notes.txt 版本号 / store_kit productId / 5 厂商 push / 阿里云 SMS / 5 实物资产 / 域名 ICP / 5.1.3 抽审问卷 | 1-2 月外部 | 7.5 → 8.0 |
| **P2** | superpowers-zh 维度 4.3 | 加固 false negative (建议 `check_id_bands_doc_sync.py` 1 项) | 1d | 加固 0.0 |
| **P2** | AR-17/18/19 跨期 (R111 R112 报告) | scale_translations 三源合一 (删 810L 死代码) / usecase 6→14-16 / saveSetup 编排下沉 / l10n 循环解耦 | 1-2 周 | 8.0 → 8.5 |
| **P2** | R31 Apple Health 半成品 5 项 | Spring 接 _EntrySpring / 关键词 lock-in 扩 lib/ / PageScaffold translucent / dart format / 44KB untracked 入库 | 4-5h | (半成品项) |
| **P3** | P3-8 (R117 记) | AGENTS.md / CHANGELOG.md EN 摘要 | 0.5h | 0.0 |

### 5.3 7 P0 跨期残留 vs R121 路线图

| P0 # | 内容 | R108-R120 状态 | R121 行动 |
|---|---|---|---|
| 1 | iOS 截图 0 张 | 0 闭环 (设计师依赖) | 等设计师 |
| 2 | iOS LaunchImage 68B | 0 闭环 (设计师依赖) | 等设计师 |
| 3 | Android 截图 67B + feature_graphic | 0 闭环 (设计师依赖) | 等设计师 |
| 4 | chroniccare.app 域名 + 4 邮箱 ICP | 0 闭环 (7-20d ICP) | 等域名商 |
| 5 | AppIcon 1024×1024 ≥ 200KB | 0 闭环 (设计师依赖) | 等设计师 |
| 6 | 5 厂商 push SDK | 0 闭环 (1-2 月) | 跟 5 厂商 |
| 7 | 阿里云 SMS | 0 闭环 (1-2 月) | 跟阿里云 |

7 P0 跨期残留 0 闭环已 8 round, 跟 R108 R110 R111 R112 R113 R114 R115 R116 R117 R118 R119 R120 累计 12 round。**这是 superpowers-zh 维度最大扣分项, 但 R121 无法闭环, 因为 100% 外部依赖**。

---

## 6. R118/R119/R120 文档同步

### 6.1 中文 doc 跟代码同步

| 文档 | 跟代码 | 评估 |
|---|---|---|
| `docs/CHANGELOG.md` R119 R120 entry | ✅ 完整 | 范本 |
| `docs/CHANGELOG.md` R118 P2-7 entry | ❌ **缺** | P0 漏洞 |
| `AGENTS.md` 顶部 EN Summary | ⚠️ 2515 tests 落后 R120 2571 = 56 test | P0 漏洞 |
| `AGENTS.md` R118 R119 R120 章节 | ❌ 缺 | P0 漏洞 |
| `docs/PRIVACY_HARDENING.md` R118 R119 R120 章节 | ❌ 缺 | P1 漏洞 |
| `docs/architecture/NOTIFICATION_ID_BANDS.md` | ✅ R120 新建, 中文完整, spec §X.X 引用范本 | 范本 |
| `lib/core/data/database/app_database.dart` 头部 R119 dartdoc | ✅ 完整 | 范本 |
| `lib/domain/entities/scale_translations.dart` 头部 R118 dartdoc | ❌ 头部注释累计 R65 R78 R90 R95 但**没 R118** | P1 漏洞 |
| `test/core/data/services/notification_service_split_round120_test.dart` 头部注释 | ✅ 范本 | 范本 |
| `test/core/data/database/app_database_split_round119_test.dart` 头部注释 | ✅ 范本 | 范本 |
| `test/domain/entities/scale_translations/round118_direct_test.dart` 头部注释 | ✅ 范本 | 范本 |

### 6.2 跨期残留总账 (按 P0 优先级)

- **P0 文档同步** (superpowers-zh 独家): 4 项
- **P0 上架硬阻塞** (R108 累计 8 round): 7 项 (5 设计师资产 + 1 域名 ICP + 5 厂商 push + 阿里云 SMS)
- **P1 文档加固** (R31 R108 R111 R112 续): 6 项
- **P2 守门员加固** (superpowers-zh 建议): 1-3 项
- **P2 god class 续拆** (R108 §六): 0/12 (6 闭环 + 1 误判 + 5 误判)

---

## 7. R121 建议

### 优先级 1 (superpowers-zh 视角独家, 1 周内必修)

1. **CHANGELOG 补 R118 P2-7 entry** (0.5h)
2. **AGENTS.md 顶部 EN Summary 同步** "2515 tests pass" → "**2571 tests pass**" (0.1h)
3. **AGENTS.md 补 R117 R118 R119 R120 4 章节** (2h)
4. **PRIVACY_HARDENING.md 改 R115 → R120 framing** (0.5h)

### 优先级 2 (建议 R121 闭环)

5. **守门员 false negative 加固 1 项** (1d) — 建议 `check_id_bands_doc_sync.py`
6. **AGENTS.md 21 守门员清单重写** (0.2h) — 21 → 27
7. **scale_translations.dart 头部注释加 R118** (0.1h)

### 优先级 3 (R121 中期, 1-2 周)

8. **R121 路线图跟 R120 main-agent 自查对齐** (0.5h)
9. **4 半成品 TODO (R117 P2-3 P2-6 P3-6 P3-7) 收尾** (3h)

### 不在 R121 范围 (跨期残留, 1+ 月)

- 5 实物资产 / 域名 ICP / 5 厂商 push / 阿里云 SMS / 5.1.3 抽审问卷 = 100% 外部依赖

### 不在 R121 范围 (守门员 false positive 推测, 0 误报可信)

- 27 守门员 0 误报基于 R120 CHANGELOG + 文件结构一致 + 5 上架脚本 `existsSync()` ✅

---

## 8. 跨视角共识 (跟 R31 R108 累计, 1 段话)

R120 3 批 god class 续拆 (R118 P2-7 10 量表 / R119 P1-1 app_database / R120 P1-2 notification_service) 技术执行扎实, test-after 回归保护模式成熟, NOTIFICATION_ID_BANDS.md 2.7KB 是 spec §X.X 中文 dartdoc 引用范本。但 superpowers-zh 维度 3 处 P0 文档同步漏洞 (CHANGELOG 缺 R118 P2-7 / AGENTS 缺 4 章节 / EN Summary 2515→2571 / PRIVACY_HARDENING 仍 R115 framing) 拉低 0.5 分; 7 P0 跨期残留 0 闭环跨 8 round 拉低 0.5 分; 4 EN 摘要 0 闭环跨 4 round 拉低 0.5 分; 守门员 27 数量正确 + 0 误报 + 3 false negative 风险建议加固 1 项 + 0.0 净变。综合 7.0/10 持平 R117 baseline (7.5) -0.5, 升 R31 baseline (6.5) +0.5。R121 建议优先 1 文档同步 4 项 (3.1h) → 7.5; 优先 2 守门员加固 1 项 (1d) + 文档 2 项 (0.3h) → 加固 0.0; 跨期 5 P0 外部依赖 1-2 月闭环 → 8.0+; v1.0 (2027-Q1) HealthKit + 5 厂商 push + 阿里云 SMS + IAP 闭环 → 8.5+。

---

**总行数**: 280 行 markdown
**视角纯度**: 0 跨视角内容
