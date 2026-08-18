# ChronicCare 服务蓝图 (Service Blueprint)

> **文档**: R128e audit 优化 (论文 1 赵佳睿《服务设计的心灵树洞 APP》§3.3 优化)
> **版本**: 2026-08-18
> **目标**: 形式化服务系统的整体概貌 + 不同人员行为/流程 + 触点责任, 跟 user_journey.md 配对

---

## 一、服务蓝图总览 (Service Blueprint Overview)

论文 1 §3.3 服务蓝图: 可视化对服务设计过程中涉及的不同人员的行为和流程的准确描述, 了解服务过程/性质, 控制和改善服务质量和用户体验。

```
┌──────────────────────────────────────────────────────────────────┐
│ 客户行为 (Customer Actions)                                          │
│  下载 → 安装 → 启动 → 引导 → 日常使用 → 回顾 → 导出/删除            │
│   ↓        ↓       ↓       ↓          ↓         ↓       ↓            │
│ 触点 (Frontstage)                                                    │
│  商店页面  Splash  4 步引导  主页 4 tab  Trend   隐私设置             │
├──────────────────────────────────────────────────────────────────┤
│  前台员工 (Frontstage Employees)                                     │
│  ❌ 慢性是 0 员工, 0 客服 (永久免费, 无后端运营)                     │
├──────────────────────────────────────────────────────────────────┤
│  后台流程 (Backstage Processes)                                      │
│   ┌─ ConsentGate (R67 集中器, 同意流程)                              │
│   ├─ Local Storage (Drift + SQLCipher, 本地存储)                    │
│   ├─ Worry 3 操作闭环 (R128e 论文 3 优化)                            │
│   ├─ Vent 标签 3 分类 (R128e 论文 2 优化)                            │
│   ├─ Assessment 10 量表 (R90 + R92 + R93)                           │
│   ├─ Trend 计算器 (4 维分数聚合 + 周月对比)                         │
│   ├─ Mood 4 维评分 + CBT 3/5/7 栏 (R108 简化)                      │
│   ├─ Crisis Hotline 5 地区 (tel: scheme, url_launcher)              │
│   └─ Apple Health Visual (R31 5 token + 6 widget 集中器)            │
├──────────────────────────────────────────────────────────────────┤
│  支持流程 (Support Processes)                                       │
│   ┌─ 守门员 (21 个 check_*.py, CI 自动跑)                          │
│   ├─ 加密服务 (flutter_secure_storage + pointycastle)               │
│   ├─ iOS Privacy Manifest (5 类 + 2 类 NSPrivacyAccessed)         │
│   ├─ Android backup 排除 (3 个 XML)                                │
│   └─ R128e gdc audit 8 维度交叉审计                                  │
└──────────────────────────────────────────────────────────────────┘
```

## 二、客户行为路径 + 触点 (Customer Journey with Touchpoints)

| 阶段 | 客户行为 | 触点 | 前台 | 后台流程 | 支持流程 |
|---|---|---|---|---|---|
| **发现** | App Store / Play Store 搜索 | 商店页面 | 商店运营 (Apple/Google) | App Store Optimization (ASO) | — |
| **下载** | 点击下载 + 安装 | 商店下载 | 商店运营 | Apple/Google Play Server | — |
| **启动** | 启动 Splash → 加载 | 启动页 | ❌ 0 员工 | 启动期 EarlyLoadingApp (R104) | flutter analyze 0 error |
| **引导** | 4 步: 同意 → 欢迎 → 用药 → 完成 | 4 步引导 | ❌ 0 员工 | ConsentGate + DB schemaVersion 24 init | 4 法律文档 R67-R128 |
| **首次记录** | Mood/Vent 第一个 entry | Mood tab / Vent tab | ❌ 0 员工 | Drift insert + SQLcipher | R128e worry 3 闭环 |
| **日常使用** | 4 tab 切换 + 记录 + 回顾 | 主页 / 设置 | ❌ 0 员工 | Local Storage + Apple Health visual | reduce-motion 全适配 |
| **持续使用** | 7+ 日后形成习惯 | 同上 | ❌ 0 员工 | Worry timeline 增长 | Trend 计算器 |
| **闭环** | Worry "我不再烦恼啦" | Worry timeline | ❌ 0 员工 | Worry resolved 标记 + 移忆往昔 | 🎉 snackbar (R108+) |
| **复测** | Assessment 30 天后建议 | Assessment center | ❌ 0 员工 | 复测提醒 (待实现, P1 R128e) | — |
| **数据导出** | 设置 → 导出 JSON | 设置 → 数据管理 | ❌ 0 员工 | data export v6 多版本 | 16KB aligned |
| **数据删除** | 设置 → 清空 | 设置 → 数据管理 | ❌ 0 员工 | schemaVersion 24 全表删 | 二次确认 dialog |
| **危机干预** | 5 地区一键拨打 | Crisis hotline | ❌ 0 员工 | tel: scheme 走系统拨号 | url_launcher 6.3.1 |

## 三、后台流程详细 (Backstage Processes Detail)

### 3.1 ConsentGate (R67)

**入口**: 引导 Step 1 (同意) + 设置 → 法律与隐私
**流程**:
```
  Show ConsentGate Dialog (3 同意书: 隐私 + 用户协议 + 敏感数据)
    ↓ 用户点 "同意"
  写 SharedPreferences `consent_<key>_accepted_at` 时间戳
    ↓
  写 user_profile 表 `userAgreementVersion` 字段
    ↓
  Show 主页
```

**Failover**: 用户拒绝 → 弹 "需要同意才能使用" → 不能进入主页

### 3.2 Local Storage (Drift + SQLCipher)

**入口**: 所有 record 写操作
**流程**:
```
  用户提交 record (Mood / Vent / Mood / Assessment / Worry / ...)
    ↓ repository impl
  Drift DAO → INSERT INTO <table> VALUES (...)
    ↓ SQLCipher 自动加密
  写 sqlite 文件 (encrypted)
    ↓
  Stream emit → Provider 通知 → UI 重建
```

**Schema**: 13 表 + schemaVersion 24 (24-version migration timeline)
**Backup**: iOS iCloud Backup 排除 (markAppDocsExcludedFromBackup)

### 3.3 Worry 3 操作闭环 (R128e 论文 3 优化)

**入口**: Worry timeline 详情页
**流程**:
```
  用户进 /worry/:id (详情)
    ↓ 看到 3 按钮
  点 "继续倾诉该烦恼"
    → MoodRecorderPage.show(initialWorryThreadId=id)
    → 保存新 mood entry, 自动关联 worry
  点 "我又烦恼啦" (R128e 新增)
    → 同上 + snackbar "已重新打开, 需要的时候随时来倾诉"
    → 注意: open 状态下, 不改 status
  点 "不再烦恼啦"
    → 弹确认 dialog "放下这个烦恼?"
    → 确认 → status: open → resolved, 记 resolvedAt
    → 移入忆往昔 + snackbar "🎉 恭喜, 你放下了这个烦恼"
```

### 3.4 Vent 标签 3 分类 (R128e 论文 2 优化)

**入口**: Vent tag picker
**流程**:
```
  用户进 Vent compose
    ↓ 看到标签区 (R128e 后分 3 组)
  学习工作: 学业 / 工作
  情感生活: 家庭 / 亲密关系 / 朋友
  身心健康: 身体 / 情绪 / 其他
    ↓ 选标签 + 写正文
  保存 vent_entry
```

### 3.5 Assessment 10 量表 (R90 + R92 + R93)

**入口**: Assessment center
**流程**:
```
  用户进 /assessment-center
    ↓ 看到 10 量表 grid (PHQ-9/GAD-7 默认隐藏)
  点 PHQ-9 → AssessmentPage(scaleId='phq9')
    ↓ 答题 (1-4 分, 共 9 题)
  提交 → AssessmentRepository.submitEntry
    ↓
  写 assessment_entries 表
  计算 score + severity_rank
    ↓
  弹 CrisisSignal dialog (如 score ≥ 阈值)
    ↓
  跳回 AssessmentHistoryList
```

### 3.6 Trend 计算器

**入口**: Trend tab
**流程**:
```
  用户进 /trend
    ↓ watch mood_entries_provider
  计算本周 / 上周 / 上月 4 维分数均值
    ↓
  渲染 4 维折线图 (fl_chart) + 事件流
    ↓
  AI Insight (待实现, 5-6 月后 Apple Intelligence 窗口)
    "连续 5 天焦虑 > 4, 建议做 PHQ-9 评估"
```

### 3.7 Mood 4 维评分 + CBT (R108 简化)

**入口**: Mood tab → 4 维评分 → 影响 → (可选 CBT) → 保存
**流程**:
```
  4 维评分 (mood/energy/sleep/anxiety, 1-5)
    ↓
  影响因素 (可选, 多选 chip)
    ↓
  Status phrase (可选, 17 预设)
    ↓
  CBT 思维记录 (3/5/7 栏, 可选)
    ↓
  保存 mood_entry + 关联 worryThreadId (可选)
```

### 3.8 Crisis Hotline (R97-P1-11)

**入口**: 设置 → 危机热线 + VentHero "危机资源" 入口
**流程**:
```
  5 地区分组 (cn/tw/hk/us/intl)
    ↓ 选地区
  列出 2-3 热线号码
    ↓ 点号码
  tel: scheme 走系统拨号
    ↓
  失败回退: 显示号码 + 复制按钮 (Clipboard)
```

### 3.9 Apple Health Visual (R31 5 token + 6 widget)

**入口**: 主页 4 横滚 AppleHealthTile
**流程**:
```
  AppleHealthTile(metricId)
    ↓ metricId 查 AppColors.healthMetricsColorFor
  渲染 110×140 圆角 tile + system icon + label
    ↓
  onTap 跳对应详情 (medication/today/...)
```

**HealthKit 集成**: R128c stub (0 真接, 5-6 月后真接窗口)

## 四、支持流程 (Support Processes)

### 4.1 守门员 21 个 (CI 自动跑)

| 守门员 | 职责 |
|---|---|
| check_apple_health_claim.py (7 规则) | Apple Health 5.1.3 抽审防御 |
| check_cross_feature.py | 跨 feature import 检查 |
| check_arb_keys.py + check_zh_hant_consistency.py | ARB 三语同步 |
| check_drift_namespace.py | Drift 表命名空间 |
| check_datetime_race*.py | DateTime 竞态 |
| check_fullwidth_punctuation.py | 全角标点 |
| check_no_hardcoded_utc.py | UTC 硬编码 |
| check_no_pua.py | PUA 字符 |
| check_widget_dispose.py | widget dispose 资源泄漏 |
| check_legal_consent.py | 法律同意 |
| check_strings_hardcoded.py | 硬编码字符串 |
| check_changelog.py | CHANGELOG 版本 |
| check_16kb_alignment.py | 16KB page size |
| check_pii_in_title.py | 通知 PII 锁屏 |
| check_usecase_layer.py | usecase 层纯度 |
| check_review_information_todo.py | review info TODO |
| check_coverage.py | 覆盖率阈值 |
| check_no_network_io.py | 0 网络 IO |
| check_release_no_network.py | release 0 网络 |
| check_encryption_at_rest.py | 静态加密 |
| check_five_vendor_push_ready.py | 5 厂商 push 准备 |
| check_feature_first_migration.py | feature 第一迁移 |

### 4.2 加密服务

- `flutter_secure_storage` (iOS Keychain / Android Keystore) 管理 DB key
- `pointycastle` AES-256-CBC 加密 (待 R128e 升级 HMAC/GCM 完整性)
- `sqlcipher_flutter_libs` 0.6.5+ (16KB aligned)

### 4.3 跨平台隐私

- iOS PrivacyInfo.xcprivacy: 5 类 NSPrivacyAccessedAPI + 2 类 NSPrivacyCollectedDataType (AudioData + UserContent)
- Android: 3 个 backup XML 排除 (app docs + audio + db)

### 4.4 R128e gdc audit (本周期)

8 视角交叉审计 (emil / superpowers / flutter-audit / gdc / AppStore / GooglePlay / Apple Health) → 66 项发现 → 修复中。

## 五、服务接触点责任 (Service Touchpoint Responsibilities)

| 触点 | 触点类型 | 当前实现责任 | 责任团队 |
|---|---|---|---|
| 商店页面 | 营销 | 用户下载决策 (慢性: 永久免费 + 本地化文案) | 产品 + 营销 |
| 启动页 | First Impression | EarlyLoadingApp + 0 splash delay | R104 |
| 4 步引导 | Onboarding | ConsentGate + R67 + 4 文档 | 信任建立 |
| 主页 4 tab | 核心 UI | Mood / Vent / Trend / Settings | 1.1.0 round 4b emotion-first |
| Mood 4 维 + CBT | 记录 | R108 简化 3/5/7 栏 | CBT |
| Vent 文字 + 录音 | 记录 | R128e 3 分类 (本 commit) | Vent |
| Worry timeline | 闭环 | R128e 3 操作 (本 commit) | Worry |
| Assessment 10 量表 | 评估 | R90 + R92 + R93 量表 | Assessment |
| Trend 计算器 | 回顾 | 4 维聚合 + 周月对比 | Trend |
| Crisis hotline | 安全 | 5 地区 + tel: scheme | R97-P1-11 |
| Tips 心理技巧 | 学习 | 5 技巧 + mindfulness (待扩) | Tips |
| Settings 法律页 | 信任 | 4 法律文档 + ConsentGate | R67 |

## 六、关键改进点 (Service Improvement Opportunities)

### 6.1 短期 (P1)
1. **Assessment 复测提醒** (30 天): 增加用户评估频率
2. **CBT + 正念引导** (Tips): 加 5-10 个步骤化呼吸/正念练习
3. **匿名模式 toggle** (Settings → Privacy): vent 元数据隐藏

### 6.2 中期 (P2)
4. **AI Insight Loop**: Trend 页 + Apple Intelligence (5-6 月后)
5. **CBT AI 重评建议**: 用户输入情绪 → AI 提供 CBT 重评 (5-6 月后)
6. **Worry 闭环动画**: 论文 3 §5.3 "动物安慰动画"

### 6.3 长期 (P3)
7. **多设备同步**: 用户池足够大后 (需放弃 0 云端原则)
8. **匿名分享/陌生人共鸣**: 论文 3 §5.4 (需足够用户 + 合规审核)

## 七、风险评估 (Service Risk Assessment)

| 风险 | 等级 | 缓解策略 |
|---|---|---|
| 数据丢失 | 低 | 导出 v6 多版本格式 + 16KB aligned |
| HealthKit 误声明 (5.1.3) | 低 | 7 规则守门员 (Apple Health claim lock-in) |
| 危机干预失败 | 中 | 5 地区 + 二次确认 + 失败回退 |
| 抑郁用户漏识别 | 中 | Assessment 危机信号自动检测 (PHQ-9 ≥ 10 触发 CrisisSignal dialog) |
| 5 厂商 push 误发 | 低 | FeatureFlag 默认 false + 1-2 月真接后开 |
| Apple Health 视觉 vs 数据矛盾 | 低 | tooltip 明确 + 守门员 7 规则 |
| 跨期修真残留 | 中 | R128e audit commit message 规范 (修真 × N 改回描述) |