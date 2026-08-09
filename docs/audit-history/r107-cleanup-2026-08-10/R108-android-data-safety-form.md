# Play Console Data Safety Form 设置指南 (R108)

> **范围**: v0.30 R108 P0 #11b — Android 上架 P0 阻塞之二
> **基线**: v0.30.0+85 / 2026-08-10 cleanup
> **读者**: 需要上架 Google Play 的 dev / 产品
> **关联**: `scripts/generate_data_safety_form.py` (R72 + R108 增量) + `docs/audit/2026-08-10-cleanup/06-googleplay.md`

---

## 一、为什么是 P0 阻塞

Google Play 2022-04 起强制 7 大类手填, 缺则上架被拒。
**当前项目状态**:
- `scripts/generate_data_safety_form.py` (R72 已加, 覆盖 5 大类) — 自动从 `assets/legal/privacy_policy.md` + `ios/Runner/PrivacyInfo.xcprivacy` 解析
- R108 增量: 更新到 v0.30 状态, 加 health_info 子类 (PHQ-9/GAD-7/medication/mood/audio), 加 `deletion_endpoint`
- **生成 2 个文件**: `build/data_safety_form.json` (Play Console 提交用) + `build/data_safety_form.md` (人类可读 checklist)
- **未提交原因**: R72 写完脚本后没真跑 Play Console, 缺最后 4h 人工提交

---

## 二、7 大类 × 4 子项 = 28 子项 (Play Console 强制)

| 类别 | 实际收集 | 子项 (collected/shared/control/handling) | 应填声明 |
|------|----------|---------------------------|----------|
| **Location** | ❌ 不收 | 0/0/N/A | "App doesn't collect this data" |
| **Personal info** | 🟡 昵称 (v0.21 nullable) | collected=✓, shared=✗, control=delete/edit | "Collected, not shared, deletable" |
| **Financial info** | ❌ 不收 (IAP 走 Google 平台) | 0/0/N/A | 注明 "Google Play 平台 IAP 自处理" |
| **Health & fitness** | 🟡 **强制披露**: 药名/剂量/打卡/PHQ-9/GAD-7/mood | collected=✓, shared=✗, encrypted=✓ | "Collected, encrypted on device, deletable" |
| **Messages** | ❌ 不收 | 0/0/N/A | "App doesn't collect this data" |
| **Photos & videos** | ❌ 不收 (vent audio 是 Audio 类) | 0/0/N/A | "App doesn't collect this data" |
| **Audio** | 🟡 vent audio (R104 启用) + mood audio | collected=✓, shared=✗, encrypted=✓ | 同上 |
| **Files & docs** | ❌ 不收 (除本地加密 audio) | 0/0/N/A | "App doesn't collect this data" |
| **Calendar** | ❌ 不收 | 0/0/N/A | 同上 |
| **Contacts** | 🟡 **紧急联系人 (PIPL §23)** | collected=✓, shared=✗ | 注明 **未实际触发 SMS** (FeatureFlag.emergencyContactEnabled=false) |
| **App activity** | 🟡 打卡/用药/情绪/评估 (本地) | collected=✓, shared=✗ | 同上 |
| **Web browsing** | ❌ 不收 (0 网络) | 0/0/N/A | "App doesn't collect this data" |
| **App info & performance** | 🟡 crash log (runZonedGuarded 本地) + 设备型号判断通知兼容性 | collected=✓, shared=✗ | "Collected locally for crash diagnostics, not shared" |

> **注**: 上表是 R108 视角对 v0.30 业务的实际声明。R72 `generate_data_safety_form.py` 自动生成的 `build/data_safety_form.md` 含完整 28 子项 (含 personal info + health info + audio + contacts + app activity 5 个有内容, 8 个 N/A)。

---

## 三、安全实践披露 (必填)

| 字段 | 应填 | 备注 |
|---|---|---|
| **Data is encrypted in transit** | ✗ No / N/A | App 0 网络, 适用 "No data collected" 类 |
| **Data is encrypted at rest** | ✅ Yes | "AES-256 (SQLCipher) + Keychain (iOS) / EncryptedSharedPreferences (Android)" |
| **Users can request that data be deleted** | ✅ Yes | "App 内删除 + 卸载清空 + privacy@chroniccare.app 邮件请求" |
| **Independent security review** | ✗ No | 诚实填 (私人项目无 SOC2 / ISO 27001) |

---

## 四、4 步生成 + 提交

### Step 1: 跑脚本生成 JSON + Markdown

```bash
python scripts/generate_data_safety_form.py

# 输出:
#   build/data_safety_form.json   (Play Console 提交参考, 结构化)
#   build/data_safety_form.md     (人类可读, 含 28 子项 checklist)
```

### Step 2: Play Console → App content → Data safety

1. 打开 https://play.google.com/console → 选 ChronicCare
2. 左栏 **Policy → App content** → **Data safety** 卡片
3. 点 **Start** (首次) 或 **Manage** (已填过)

### Step 3: 7 大类逐项填 (按 `build/data_safety_form.md`)

打开 `build/data_safety_form.md`, 复制每个类别的应填声明到 Play Console:

1. **Data collection and security** → 各子类勾 "Yes/No" + 选类型 (collected/shared/encrypted)
2. **Data sharing with third parties** → "No, I don't share user data with third parties" (App 0 第三方 SDK)
3. **Data security practices**:
   - Data is encrypted in transit: **No** (App 0 网络, 填 N/A)
   - Data is encrypted at rest: **Yes** + "AES-256 (SQLCipher)"
   - Users can request data deletion: **Yes** + 描述
4. **Data deletion options**:
   - URL: `https://chroniccare.app/delete-data-instructions` (待域名注册后可达)
   - In-app deletion: "设置 → 数据管理 → 导出 / 清空"
   - Uninstall: "Android 12+: 卸载自动清; Android < 12: 系统设置清"
5. **Independent security review**: **No** (诚实填)

### Step 4: Save + Submit

1. **Save** (草稿状态, 可改)
2. 确认所有 7 大类都填完 (Play Console 会标红)
3. **Submit app for review** (跟其他上架材料一起 review)

---

## 五、Health & fitness 详细披露 (重点)

Google 对 Health 类 App 强制加密披露 + 注明收集目的。本项目对应:

| 子类 | 收集 | 加密 | 共享 | 删除 |
|------|------|------|------|------|
| **Health conditions** (PHQ-9 抑郁筛查 / GAD-7 焦虑筛查答案) | ✅ | ✅ AES-256 at rest | ❌ | ✅ |
| **Medications** (药名 / 剂量 / 用药时间) | ✅ | ✅ | ❌ | ✅ |
| **Mood and emotional state** (1-5 颗星 + 60 秒语音 + 标签) | ✅ | ✅ | ❌ | ✅ |

> **必填声明**: "These health data are **NOT** shared with any third party and are stored **locally on the user's device only** using AES-256 encryption (SQLCipher). The app does **NOT** transmit, upload, or back up any health data to the cloud. The user can delete all data at any time via the in-app 'Settings → Data Management → Clear All Data' option, or by uninstalling the app on Android 12+."

---

## 六、Audio 类详细披露 (R104 vent audio 启用后必填)

| 子类 | 收集 | 加密 | 共享 | 删除 |
|------|------|------|------|------|
| **Voice or sound recordings** (vent audio 60 秒 + mood audio) | ✅ | ✅ | ❌ | ✅ |

> **必填声明**: "These audio recordings are **NOT** shared with any third party and are stored **locally on the user's device only** using AES-256 encryption (SQLCipher). The app does **NOT** transmit, upload, or back up any audio recordings to the cloud. The user can delete individual recordings at any time via the in-app vent/mood journal UI, or all recordings via the 'Settings → Data Management → Clear All Data' option. Audio recordings are **EXCLUDED from iCloud Backup** (iOS) and **EXCLUDED from Auto Backup** (Android 12+) to prevent PII leakage to cloud backup services (per PIPL §28)."

---

## 七、Contacts 类披露 (PIPL §23 必填)

| 子类 | 收集 | 加密 | 共享 | 删除 |
|------|------|------|------|------|
| **Address book** (紧急联系人姓名 + 手机号) | ✅ (选填) | ✅ | ❌ | ✅ |

> **必填声明**: "The user can optionally add emergency contacts (name + phone number) in Settings. **This feature is currently disabled at runtime** (FeatureFlags.emergencyContactEnabled=false) — no emergency SMS or notification is actually sent. The contact data is stored **locally on the user's device only** using AES-256 encryption (SQLCipher) and is **NEVER** shared with any third party. When this feature is enabled in a future release, the data will remain local-only and the user will be re-prompted for explicit consent per PIPL §23."

---

## 八、App activity 类披露

| 子类 | 收集 | 加密 | 共享 | 删除 |
|------|------|------|------|------|
| **App interactions** (打卡 / 趋势 / 评估 / 用药) | ✅ | ✅ | ❌ | ✅ |
| **In-app search history** (无搜索, 仅 data filter) | ❌ | N/A | N/A | N/A |

---

## 九、未做 / 风险 / 下一步

### 已知限制

- **生成脚本不直接填 Play Console** — 需 dev 人工复制粘贴 (Google 不开放 100% API 填表单)
- **本指南依赖 chroniccare.app 域名** — 没注册前 deletion URL `https://chroniccare.app/delete-data-instructions` 不可达 (R108 P0 #13 配套)
- **脚本输出不含 Health & fitness / Audio / Contacts 的详细披露文本** — 上面 6-8 节给的是人工填 Play Console 时的标准声明, 后续可加进脚本

### 后续优化 (R109+)

- R109: 把上面 6-8 节的标准声明进 `build/data_safety_form.md` (R108 当前只生成结构化 28 子项)
- R110: 写 Play Console API 自动化 (Google Play Developer Reporting API 还在 beta, 多数字段可 API 写)
- R110: 集成 `check_privacy_consistency.py` 守门员, 自动 diff `assets/legal/privacy_policy.md` vs `build/data_safety_form.json` 防漂移

---

## 十、Checklist (上架前逐项过)

- [ ] 跑 `python scripts/generate_data_safety_form.py` 无错
- [ ] `build/data_safety_form.md` 生成 (含 28 子项)
- [ ] `build/data_safety_form.json` 生成 (结构化)
- [ ] Play Console → Data safety → 7 大类逐项填完
- [ ] Health & fitness 3 子类填 ✅ + 加密披露
- [ ] Audio 1 子类填 ✅ + 加密披露 + iCloud/Auto Backup 排除说明
- [ ] Contacts 1 子类填 ✅ + 注明 FeatureFlag=false 未实际触发
- [ ] Data security practices 4 字段填 (encrypted in transit=No, at rest=Yes, deletion=Yes, review=No)
- [ ] Data deletion options: URL `https://chroniccare.app/delete-data-instructions` + in-app + uninstall
- [ ] Save + Submit app for review

---

## 十一、相关文件清单

| 文件 | 类型 | 作用 |
|---|---|---|
| `scripts/generate_data_safety_form.py` | Python 脚本 (R72 + R108 增量) | 生成 JSON + Markdown 模板 |
| `build/data_safety_form.json` | 输出 (运行时生成) | Play Console 提交参考 |
| `build/data_safety_form.md` | 输出 (运行时生成) | 人类可读 28 子项 checklist |
| `assets/legal/privacy_policy.md` | 输入 | 隐私政策 (R72 自动解析) |
| `ios/Runner/PrivacyInfo.xcprivacy` | 输入 | iOS Privacy Manifest (R72 自动解析) |
| `lib/core/data/services/notification_service.dart:142-186` | 代码 | 通知请求权限 (Data safety 关联) |
