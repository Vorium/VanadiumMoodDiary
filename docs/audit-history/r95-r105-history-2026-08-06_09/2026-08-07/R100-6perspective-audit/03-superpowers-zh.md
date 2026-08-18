# R100 superpowers-zh 视角报告（中文本地化 / i18n / PIPL 合规）

**审计时间**: 2026-08-07 | **基线**: v0.30.0+85 + 工作区未提交改动
**方法**: `_audit_v2.py` 实测（§A/§B/§C/§G）+ ARB 3 语逐 key 校验脚本 + OpenCC s2tw 繁简一致性

## 一、实测绿灯

| 检查 | 结果 |
|---|---|
| ARB zh/en/zh_Hant 1068 key 三语同步 | ✅ 0 missing |
| OpenCC s2tw 繁简一致性 | ✅ 100% |
| orphan ARB key | ✅ 0 |
| 关键文案抽样（setup / home / safety / vent / legal 撤回 / 导出风险 / 18 岁声明） | ✅ 三语全齐且质量合格 |
| `settingsAboutVersion` | ✅ 已参数化 `v{version}`，走 kPubspecVersion 注入 |
| `check_strings_hardcoded.py` / `check_legal_consent.py` | ✅ 通过 |

## 二、i18n 债务（硬编码中文 336 处 / 68 文件）

分类处置建议：
- **合理豁免（~300 处）**：`domain/logic/` 量表题目（8 量表）+ `static_scale_translations.dart`（override fallback 设计）+ `core/l10n/strings.dart`（domain 层通知/PDF fallback）+ `piiSafeLog` 日志文案。维持现状。
- **必须修的 UI 硬编码（~30 处，en locale 可见）**：

| # | 位置 | 文案样例 |
|---|---|---|
| Z-1 | `daily_tracking/widgets/weight_widgets.dart`（5 处） | "体重 (kg)" / "如 60.5" / "暂无 BMI" |
| Z-2 | `daily_tracking/widgets/social_rhythm_widgets.dart`（4 处） | 3 个 labelText + 摘要行 |
| Z-3 | `anxiety_agitation_widgets.dart:177,205` / `sleep_widgets.dart:309` / `stress_event_widgets.dart:119` | "1=严重 5=平静" 等 |
| Z-4 | `mood_list_item.dart:66`（"CBT 7 栏"）/ `mood_list_filter_bar.dart:216`（"全部"）/ `cbt_section.dart:78`（"{n} 栏"） | CBT 栏数文案 |
| Z-5 | `consent_dialog.dart:169-173`（3 段撤回后果） | 法律相关文案必须走 ARB |
| Z-6 | `medication_report_dialog.dart:45`（"（近 N 天）"拼接）/ `medication_calendar_page.dart:213`（"补打卡功能接入中"半成品提示） | — |
| Z-7 | `setup_legal_dialog.dart:110`（"🆘 心理危机干预热线 (24h)"）/ `export_tile.dart:87-90`（consent purpose/retention 4 处） | — |

修复成本：约 +40 ARB key × 3 语，有 check_arb_keys / zh_hant_consistency 守门。**层级：底层；难度：中；紧急度：中**（en 模式上架可见）。

## 三、标点与文风

| # | 问题 | 定位 | 层级 | 难度 | 紧急度 |
|---|---|---|---|---|---|
| Z-8 | 半角标点：zh / zh_Hant ARB 各 58 key 中文后接半角 `,.;:` | `lib/l10n/app_zh*.arb` | 底层 | 简单 | 低 |
| Z-9 | 代码注释半角标点 132 warn（warn-only，多为 app_localizations 生成文件） | `check_fullwidth_punctuation` | 底层 | — | 低（豁免 generated） |

## 四、法务文件覆盖缺口（PIPL，仅目标中国区时需要）

`_audit_v2.py` §C 实测：

| 文件 | 缺失项 |
|---|---|
| `privacy_policy.md` | ✅ 13 项全覆盖，无缺口 |
| `user_agreement.md`（3376 chars，过短） | ✗ 情绪日记条款 / PIPL §13 单独同意 / §17 责任 / §29 跨境 / 第三方 SDK 表格 / 网络数据安全 / 年龄 18 条款（7 项） |
| `sensitive_data_consent.md` | ✗ PIPL §17 / §29 / 第三方 SDK 表格（3 项） |

**层级：底层（文档）；难度：中；紧急度：高（仅当上架中国区）；海外区可降级**。

## 五、联系方式软隐藏复核（外链主题相关）

- 代码层 0 真实邮箱/外链（唯一 url_launcher 调用 = `tel:` 危机热线，`crisis_hotline_page.dart:238`）。
- 法务文档 9 处 `privacy@` / `support@chroniccare.app` / `github.com/example/chroniccare` **软隐藏说明文字残留**（privacy_policy.md:150,164,214,218,220；user_agreement.md:68,71,88,93）。功能上已隐藏（无 mailto、不可点击），但审核员阅读法务文档时可见占位域名。
- **建议**：域名注册前把"软隐藏 `xxx@chroniccare.app`"字样改为"联系方式见 App 内设置页"，避免给审核员留下"信息不完整"印象。**层级：底层；难度：简单；紧急度：中**。

## 六、结论

三语 i18n 基建扎实（守门脚本全绿）。上架前建议修 Z-1~Z-7（UI 硬编码）+ 法务软隐藏残留文字；中国区上架则必须补 user_agreement / sensitive_data_consent 缺口。
