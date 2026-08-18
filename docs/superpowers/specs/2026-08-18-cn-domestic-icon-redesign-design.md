# CN Domestic Icon Redesign + Multi-Platform Store Metadata — Design Spec

> **日期**: 2026-08-18
> **作者**: AI (brainstorming → writing-plans)
> **状态**: 待用户 review
> **关联**: R128e audit (gdc R128e §8 上架准备度 0/10) + emotion-first refactor (1.1.0+185) + 5 P0 跨期残留 (PS-1~PS-5)

---

## 1. 背景

### 1.1 当前矛盾

R128e (2026-08-18) 把项目定位从「慢病管理 / chronic disease management」改为 **「MoodDiary 心情日记 — 情绪日记 + 树洞倾诉优先 (mood journal & vent-first)」**, 删 HealthKit / ResearchKit / 治疗功能。但项目现存上架资产**未同步更新**:

| 资产 | 现状 | 跟 emotion-first 矛盾点 |
|---|---|---|
| iOS AppIcon 1024×1024 | 16KB 医疗风 (胶囊+心+十字 on 绿色) | 强矛盾: 「医疗符号」与「情绪优先」互斥 |
| Android mipmap | 1-4KB Flutter 默认占位 | 跟新定位完全无品牌 |
| Play feature_graphic | 67B 占位 | 无品牌 |
| iOS en-US/zh-Hans/zh-Hant description.txt | R111 中性化后, 仍有「树洞」作为差异化但不是首位 | 「树洞」未放首位 + 危机热线冗长 |
| 8 国内平台 metadata | **不存在** | 完全空白 |
| 项目名 platform 端 | iOS 已 `MoodDiary 心情日记` Android 已 `MoodDiary` (待确认) | OK 但缺国内平台同步 |

### 1.2 上架准备度 (R128e §8)

| 平台 | 代码合规 | 元数据 / 视觉资产 | 总分 |
|---|---|---|---|
| Apple App Store | 9/10 | **0/10** (iOS 截图/Privacy URL/Support URL/review_information 4 字段/Podfile) | 3.5/10 |
| Google Play | 9/10 | **0/10** (域名 + ICP) | 6.4/10 |
| Apple Health 集成 | 9/10 (视觉) | 0/10 (集成) | 7.5/10 |

### 1.3 设计意图

R128e emotion-first 后,**图标** + **品牌色** + **元数据文案** 3 件资产必须同步重做,否则上架时:
1. App Store 5.1.3 抽审触发 (Medical category 风险)
2. Google Play Health Apps Questionnaire 与自定位矛盾
3. 国内 8 商店上架无任何准备
4. 用户看到「医疗符号」会预期是医疗 App,与实际「情绪日记」不符 = 安装后流失

---

## 2. 目标

1. **品牌图标 emotion-first 重设计**: 完全去掉医疗符号(胶囊/十字),改用「情绪波 + 半圆(月亮/日)」柔和隐喻
2. **5 平台元数据自动可生成**: Apple App Store + Google Play + 8 国内平台 (华为/小米/OPPO/vivo/魅族/应用宝/360/百度) 的 metadata + 图标变体 全部由脚本确定性产出
3. **文案 emotion-first 全面刷新**: 6 文件 (iOS en-US + zh-Hans + zh-Hant, Android en-US + zh-CN short+full) 突出「树洞」差异化
4. **守门员完整**: 新增 2 个守门员, 现有 4 个守门员阈值/规则更新, 0 医疗词回归

---

## 3. 图标设计语言

### 3.1 Combo 1 — "Sunset Breath" 日落呼吸

**色彩 (组合 A 暖橙 + B 冷紫)**:
- 背景水平渐变: `#FFB088` (暖橙粉) → `#B5A0D4` (浅紫) (温度像日落天空)
- 主形白色填充 (透明度 92%): 月亮/太阳半圆
- 曲线白色描边 (透明度 75%): 1.5px 情绪波穿过下沿

**几何参数** (1024×1024 viewport):
- 主半圆: 中心 `(512, 460)`, 半径 `320`, 顶部圆弧 = 月/日
- 内部留白: 半圆中心下凹 `(512, 600)` 半径 `80` (B 的负空间哲学)
- 情绪波: 三次贝塞尔曲线, 起点 `(180, 700)`, 中点 `(512, 760)`, 终点 `(844, 700)`, 振幅 `30`
- 安全区: 中心 80% 圆内,各平台变体按 70%/75%/80% 调整

**与现有 5 token 兼容**:
- `chroniccare_theme` 的 `accentAppleHealth` (`#34C759`) 改用 `accentSunsetPeach` (`#FFB088`) 作为新主品牌色 (commit 一并改 theme)
- 主页 header / 主页 tab / 设置页 等使用 `accentAppleHealth` 的地方批量替换为 `accentSunsetPeach`

### 3.2 各平台图标变体

| 平台 | 主要求 | 生成变体 |
|---|---|---|
| iOS AppIcon | 1024×1024 满幅方形,无 alpha | 标准 Combo 1 |
| iOS LaunchImage | iPhone XS 1242×2688 / iPhone 8 Plus 1242×2208 / iPhone 8 750×1334 | 白底 + Combo 1 居中圆角图标 (320×320 / 220×220 / 130×130) |
| Android mipmap | mdpi 48 / hdpi 72 / xhdpi 96 / xxhdpi 144 / xxxhdpi 192 | Combo 1 |
| Android adaptive icon | 108×108 viewport, 安全区 72×72 | foreground = Combo 1 + background = 暖橙渐变 `#FFB088` 满幅 |
| Play icon | 512×512 | Combo 1 (不加 adaptive 安全区) |
| Play feature_graphic | 1024×500 | 渐变背景 + Combo 1 圆角图标 (居左) + 「MoodDiary 心情日记」(居右, 110pt) |
| 华为应用市场 | 216×216 圆角 + 5% 安全区 | Combo 1 + 5px 透明边框 |
| 小米应用商店 | 512×512 + 8% 安全区 | Combo 1 + 41px 透明边框 |
| OPPO 软件商店 | 512×512 + 80% 中心安全区 | Combo 1 + 51px 透明边框 |
| vivo 应用商店 | 512×512 + 圆形裁切 | Combo 1 圆形 mask |
| 魅族应用商店 | 512×512 方形 | Combo 1 标准 |
| 应用宝 | 512×512 方形 | Combo 1 标准 |
| 360 手机助手 | 512×512 + 圆角 25px | Combo 1 圆角 mask |
| 百度手机助手 | 512×512 方形 | Combo 1 标准 |

### 3.3 文件结构

```
assets/brand/
├── app_icon_master.png           # 🆕 Combo 1 主图 1024×1024 (脚本生成后保留)
├── icon_showcase.html            # 🆕 HTML 预览所有变体 (iOS / Android / Play / 8 国内平台)
├── cn_domestic_preview.html      # 🆕 HTML 预览 8 平台元数据 + 图标
├── icon-1024.png                 # 🆕 iOS AppIcon 1024×1024 (脚本生成)
├── icon-512.png                  # 🆕 Play 商店 512×512 (脚本生成)
├── huawei-icon-216.png           # 🆕
├── xiaomi-icon-512.png
├── oppo-icon-512.png
├── vivo-icon-512.png
├── meizu-icon-512.png
├── tencent-icon-512.png
├── qihoo-icon-512.png
├── baidu-icon-512.png
└── _archive/                     # 现有, 保留旧医疗风图标作历史
```

---

## 4. 8 国内平台元数据结构

### 4.1 目录结构

```
fastlane/metadata/
├── ios/                    # 现有,不动
├── android/                # 现有,en-US + zh-CN
└── cn_domestic/            # 🆕 8 国内平台
    ├── huawei/
    │   ├── app_intro.txt          # 80-120 字
    │   ├── app_tags.txt           # 5-8 关键词
    │   ├── app_category.txt       # 健康 / 医疗 (健康优先, emotion-first)
    │   ├── app_subcategory.txt    # 心理健康 / 健康工具
    │   ├── screenshots_spec.txt   # 1080×1920 × 5 张占位说明
    │   ├── icon_spec.txt          # 216×216 + 5px 安全区
    │   ├── privacy_url.txt        # 占位 [PENDING_DOMAIN: https://chroniccare.app/privacy]
    │   ├── developer_verified.txt # 开发者实名标记 (待用户填)
    │   ├── content_rating.txt     # 应用分级 (12+ 或 17+)
    │   └── soft_copyright.txt     # 软著证书占位 [PENDING_SOFT_COPYRIGHT]
    ├── xiaomi/                    # 同结构
    ├── oppo/                      # 同结构
    ├── vivo/                      # 同结构
    ├── meizu/                     # 同结构
    ├── tencent/                   # 应用宝 (腾讯)
    ├── qihoo/                     # 360 手机助手
    └── baidu/                     # 百度手机助手
```

### 4.2 各平台差异

| 平台 | 关键差异点 |
|---|---|
| 华为应用市场 | 必填「应用分级」(12+ 或 17+), 「应用来源」(自主开发), 「ICP 备案号」 |
| 小米应用商店 | 必填「隐私声明」 + 「开发者实名」 |
| OPPO 软件商店 | 必填「隐私合规自检」(《APP 违法违规收集使用个人信息行为认定方法》), 必填「应用分类」(健康/医疗 二选一) |
| vivo 应用商店 | 必填「内容审核」(情绪/医疗合规), 必填「隐私 URL」 |
| 魅族应用商店 | 较宽松,基础 + 软著 |
| 应用宝 | 必填「官网 URL」(可同 privacy URL) + 「开发者实名」 |
| 360 手机助手 | 必填「360 实名」+ 「应用标签」 |
| 百度手机助手 | 必填「百度账号实名」+ 「应用标签」 |

### 4.3 软著证书占位

8 国内平台全部需要「软件著作权证书」(PDF)。当前阶段无证书,生成脚本写 `[PENDING_SOFT_COPYRIGHT: 软件著作权证书 PDF, 用户上架前需提交]`。

---

## 5. 文案 emotion-first 全面刷新

### 5.1 现有文案审计

| 文件 | 现状 | 问题 |
|---|---|---|
| iOS en-US description.txt | 40 行 | 「Vent space」埋没在 KEY FEATURES 第 2 项 |
| iOS zh-Hans description.txt | 39 行 | 「树洞」提了但没放首位 |
| iOS zh-Hant description.txt | 41 行 | 港台分流 OK |
| iOS en-US subtitle.txt | `Mood + Vent Journal` | OK |
| iOS en-US keywords.txt | 5 个词 | 加 `self-care, private, encrypted, free` 4 个 |
| Android 4 文件 | 跟 iOS 平行 | 同 iOS 问题 |

### 5.2 刷新策略

**iOS en-US description.txt** (改):
```
MoodDiary is more than a mood journal — it's a private vent space where your words stay yours.

Every day has unspoken moments. MoodDiary gives you a quiet corner to:
• Rate today across 4 dimensions (mood, energy, sleep, stress)
• Vent freely with voice or text — fully encrypted, on your phone
• Watch patterns over time and see yourself getting better, one day at a time

This is not a medical tool. It doesn't diagnose or treat. But it can help you notice how you feel.

VENT FIRST
A completely private space to write or record what's on your mind. No judgment, no cloud, no one watching. Voice notes supported.

MOOD JOURNAL
Rate today across mood, energy, sleep, and stress. Attach voice notes, influence factors, and optional CBT thought records.

WORRY CLOSURE
Start a worry thread, and record every time it comes back. The day you say "I'm no longer worried", it moves to your memory archive.

TRENDS
Cross-mood, cross-vent trend charts — see yourself getting better, day by day.

CRISIS RESOURCES
Local crisis hotlines (5 regions) — one tap to dial.

OUR PROMISE
• 100% local: all data and recordings stay on your phone, encrypted with SQLCipher
• Zero cloud: no servers, no accounts, no tracking
• Zero ads: no ad SDKs, no third-party analytics
• Permanently free: no in-app purchases, ever
• Exportable: JSON backups anytime, or delete everything with one tap

IMPORTANT DISCLAIMER
This app does not provide medical advice, diagnosis, or treatment. It is a personal journaling tool. If you are in an emergency, contact local emergency services:
• US: 988 (Suicide & Crisis Lifeline)
• UK: 116 123 (Samaritans)
• International: https://findahelpline.com

For everyone who needs a little support.
```

**iOS zh-Hans description.txt** (改):
```
每个人都有说不出口的时刻。

MoodDiary 心情日记,一个只属于你的情绪日记和树洞。

它不是医疗工具,不能替代医生的诊断与治疗。但它能帮你:
• 在树洞里放心倾诉
• 记下每天的情绪和状态
• 看到自己一点一点变好的轨迹

核心功能

【树洞倾诉】完全私密的角落,把想说的写下来、说出来。加密存储在你的手机里。语音记录支持。

【情绪日记】用 4 个维度给今天打分,记录情绪变化轨迹。可附语音、影响因素,还有 CBT 思维记录帮你整理思路。

【烦恼闭环】记下一个烦恼,时间线记录每次心情。有一天你会发现"我不再烦恼啦",它会收藏进"忆往昔"。

【趋势回顾】跨情绪、树洞的趋势图,看到自己一点一点变好的轨迹。

【自我测评】可选的自助反思问卷,帮助观察情绪变化规律。结果仅供参考,答案只保存在你的手机上。

【危机资源】设置页内置各地心理援助热线,一键拨打。

我们的承诺
• 100% 本地:所有数据、录音都存在你手机里,用 SQLCipher 加密
• 零云端:没有服务器、没有账号、没有埋点
• 零广告:不接任何广告 SDK、不接任何第三方统计
• 永久免费:永远不收费,永远没有内购
• 数据可导出:随时导出 JSON 备份,也可以一键全部删除

重要声明
本 App 不提供医疗建议、诊断或治疗。MoodDiary 心情日记是一个个人记录工具,不能替代专业医疗服务。如出现紧急情况,请立即联系当地急救或心理危机热线:
• 全国 24 小时免费心理热线:800-810-1117
• 全国心理援助热线:400-161-9995
• 国际:https://findahelpline.com

献给每一个需要一点支持的人。
```

**iOS zh-Hant description.txt** (改): 跟 zh-Hans 平行, 港台分流保留 (`台灣安心專線 1925` + `香港撒瑪利亞 2389 2222`)

**iOS en-US subtitle.txt** (改):
- 旧: `Mood + Vent Journal`
- 新: `Mood Journal + Vent Space`

**iOS en-US keywords.txt** (改):
- 旧: `mood,journal,vent,diary,wellbeing`
- 新: `mood,journal,vent,diary,wellbeing,self-care,mind,private,encrypted,free`

**Android 4 文件**:
- full_description.txt: 跟 iOS en-US/zh-Hans 平行
- short_description.txt (en-US): `Mood journal + vent space. Private.` (32 字符)
- short_description.txt (zh-CN): `情绪日记·树洞倾诉·本地加密零云端` (24 字符)

**8 国内平台独立文案**:
- app_intro.txt: 80-200 字中文 (按平台字数限制)
- app_tags.txt: 5-10 关键词中文
- app_category.txt: `健康 / 心理健康 / 健康工具` (按平台分类树)

---

## 6. 实施计划

### 6.1 新增脚本

| 脚本 | 行数估 | 职责 |
|---|---|---|
| `scripts/generate_app_icon.py` 🆕重写 | 350L | 从 Combo 1 设计生成所有图标变体 |
| `scripts/generate_feature_graphic.py` 🆕 | 80L | 2 张 feature_graphic (en-US/zh-CN) |
| `scripts/generate_cn_metadata.py` 🆕 | 500L | 8 平台 × 8-10 字段 = ~70 metadata 文件 |
| `scripts/refresh_emotion_first_copy.py` 🆕 | 200L | 重写 6 个文案 |
| `scripts/check_icon_quality.py` 🆕 | 80L | 守门员: 校验图标尺寸/格式/品牌色 |
| `scripts/check_cn_metadata.py` 🆕 | 120L | 守门员: 校验 8 平台 metadata 完整 |

### 6.2 修改现有脚本

- `scripts/generate_data_safety_form.py`: emotion-first 后 Health Apps 部分删「Health Apps」标签
- `scripts/generate_health_apps_questionnaire.py`: 改名为 `generate_app_review_questionnaire.py`, 适配非医疗问卷
- `scripts/check_appicon_size.py`: 阈值改 250KB (适配新设计)
- `scripts/check_appstore_metadata.py`: 加 emotion-first 关键词 (mood, vent, journal) 必现检查
- `packages/chroniccare_theme/lib/src/app_colors.dart`: `accentAppleHealth` 改 `accentSunsetPeach` (#FFB088)

### 6.3 CI 集成

`.github/workflows/ci.yml` 加 2 个 step:
- `python scripts/check_icon_quality.py`
- `python scripts/check_cn_metadata.py`

### 6.4 交付物清单 (~110 文件)

| 类别 | 数量 |
|---|---|
| iOS AppIcon (含 16 尺寸) | 16 |
| iOS LaunchImage | 3 |
| Android mipmap | 5 |
| Android adaptive icon XML | 1 |
| Play icon | 2 |
| Play feature_graphic | 2 |
| 8 国内平台图标变体 | 8 |
| 8 国内平台 metadata | ~70 |
| 文案刷新 | 6 |
| HTML 预览 | 2 |
| 新/改脚本 | 6 |
| **合计** | **~121** |

---

## 7. 验证 & 守门员

### 7.1 新增守门员

- `check_icon_quality.py`: 检查所有 PNG 字节大小/尺寸/品牌色 hex 在 `#FFB088`/`#B5A0D4`/`#FFFFFF` 范围内
- `check_cn_metadata.py`: 检查 8 平台 metadata 关键字段非空、字数在限制内、隐私 URL 占位标记存在

### 7.2 现有守门员回归

- `check_apple_health_claim.py`: emotion-first 后应 0 命中 (无医疗词)
- `check_appicon_size.py`: 阈值 250KB
- `check_appstore_metadata.py`: 验证文案 emotion-first 关键词必现
- `check_appstore_screenshots.py`: 占位验证
- `check_no_pua.py`: 不应影响
- `check_strings_hardcoded.py`: 不应影响

### 7.3 手动验证

- `flutter run` 看新图标 in-app (主页 tab / 设置页 header)
- 浏览器打开 `assets/brand/icon_showcase.html` 看所有平台变体
- 浏览器打开 `assets/brand/cn_domestic_preview.html` 看 8 平台元数据

### 7.4 视觉回归

- 主页 tab icon / header icon / 设置页 icon 切到 `accentSunsetPeach` 后应保持 5 token 设计语言一致

---

## 8. 关键文件 (实现后状态)

| 路径 | 状态 | 行数估 |
|---|---|---|
| `scripts/generate_app_icon.py` | 🆕 重写 | 350L |
| `scripts/generate_feature_graphic.py` | 🆕 | 80L |
| `scripts/generate_cn_metadata.py` | 🆕 | 500L |
| `scripts/refresh_emotion_first_copy.py` | 🆕 | 200L |
| `scripts/check_icon_quality.py` | 🆕 | 80L |
| `scripts/check_cn_metadata.py` | 🆕 | 120L |
| `scripts/generate_data_safety_form.py` | 改 | +20L |
| `scripts/generate_health_apps_questionnaire.py` | 改名 + 改 | +30L |
| `scripts/check_appicon_size.py` | 改阈值 | -5L |
| `scripts/check_appstore_metadata.py` | 加规则 | +30L |
| `packages/chroniccare_theme/lib/src/app_colors.dart` | 改色 | +5L |
| `assets/brand/app_icon_master.png` | 🆕 | 1024×1024 PNG |
| `assets/brand/icon-1024.png` | 🆕 | 1024×1024 PNG |
| `assets/brand/icon-512.png` | 🆕 | 512×512 PNG |
| `assets/brand/icon_showcase.html` | 🆕 | HTML |
| `assets/brand/cn_domestic_preview.html` | 🆕 | HTML |
| `fastlane/metadata/cn_domestic/{huawei,xiaomi,oppo,vivo,meizu,tencent,qihoo,baidu}/*.txt` | 🆕 70 文件 | ~10L/file |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/description.txt` | 改 | +5L/file |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/subtitle.txt` | 改 | 1L/file |
| `fastlane/metadata/ios/en-US/keywords.txt` | 改 | 1L |
| `fastlane/metadata/android/{en-US,zh-CN}/full_description.txt` | 改 | +5L/file |
| `fastlane/metadata/android/{en-US,zh-CN}/short_description.txt` | 改 | 1L/file |
| `.github/workflows/ci.yml` | 加 step | +10L |

---

## 9. 风险 & 缓解

| 风险 | 缓解 |
|---|---|
| Combo 1 图标在 small icon (48px) 不可读 | 双层 fallback: 大圆(高对比) + 情绪波(细线条) — 缩到 48px 时只剩大圆,仍品牌可识别 |
| 国内 8 平台签名证书不同,出 APK 多次 | 当前阶段不出 APK,只生成 metadata + 图标。签名走现有 release keystore,各商店分别上传 |
| 软著证书缺失,部分平台无法上架 | 脚本生成 `[PENDING_SOFT_COPYRIGHT]` 占位, 用户上架前提交 |
| 域名 + ICP 未注册,隐私 URL 占位无法填 | 脚本生成 `[PENDING_DOMAIN: https://chroniccare.app/privacy]` 占位,用户填真实 URL |
| 现有 `accentAppleHealth` 主题色被改后,旧截图/UI 不一致 | 一次性 commit 替换 + `icon_showcase.html` 预览视觉确认 |
| check_apple_health_claim.py 0 命中后,脚本实际可能漏报 | emotion-first 重写文案过 R111 中性化已验证,新文案加 emotion-first 关键词必现规则 |

---

## 10. 不在范围内

- 真实截图 (5 主流程 × 多分辨率) — 设计师外部出图
- 法务签字 (3 法律文档) — 律师外部过审
- 域名注册 + ICP 备案 — 用户外部流程
- Apple/Google/各平台开发者账号注册 — 用户外部流程
- keystore 生成 + 各平台签名证书 — 用户外部流程
- 5 厂商 push 真 SDK 接入 (米/华/OPP/vivo/魅族) — R124 阶段 2, 1-2 月外部
- Apple HealthKit 真接 — R128c 阶段 2, 5-6 月后外部

---

## 11. 实施状态

⏳ 待用户 review → 待 writing-plans → 待实现

---

## 12. 参考

- `docs/STOREFRONT_RELEASE_SOP.md` — 上架前必做清单 (v0.27 round 82)
- `docs/SUBMISSION_INFO.md` — 上架前必填信息 (R108 BUG-1 修复)
- `docs/audit/2026-08-18-r128e-multi-lens/00-FINAL-CONSOLIDATION.md` §8 上架准备度
- `docs/audit/2026-08-18-r128e-multi-lens/06-pull-on-shelf.md` PS-1~PS-7 P0 残留
- `docs/superpowers/specs/2026-08-15-emotion-first-refactor-design.md` — 定位改 emotion-first 的设计 spec
- `AGENTS.md` §6 God Class + §7 FeatureFlag + §8 上架准备度