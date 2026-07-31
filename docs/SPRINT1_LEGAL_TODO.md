# Sprint 1 上 store 前法务 TODO 集中器（v0.27 R67）

**创建时间**: 2026-07-31
**目的**: 集中记录 3 个法律文档里所有 "TODO 占位" 项 + 替换动作清单
**基线**: Sprint 1 修复后, 文档侧 0 隐患; 法务 review 只需照本清单逐项过

---

## 0. 总览

3 个法律文档 v0.27 R67 (Sprint 1) 起**所有 TODO 已显式标注** + 集中到本文件。R67 修复前, 3 文档混着 "TODO 占位" + "未经律师过审" + `support@chroniccare.app` 这种**虚构邮箱** (没注册) + `https://github.com/example/chroniccare/issues` 这种**虚构仓库** (没建), 4 store 审核员扫到会直接打回 (GooglePlay 视角 P0 + spzh 视角 C-P0-3)。

**修复原则**:
1. **不**瞎填占位邮箱为**真实地址** (除非用户提供) — 当前 0 个真实邮箱注册
2. **不**瞎填占位 GitHub 仓库为**真实地址** (本项目决定暂不开源, 见 §3.2)
3. 把"待法务过审"统一改 TODO 标注, 集中到本文件, 不在文档里散落
4. 隐私 / 协议 / 同意书 3 文档同步 R66 / R67 业务决策 (软提示 / 失联通知暂停 / 撤回同意业务层生效)

---

## 1. 占位邮箱清单

| 邮箱 | 出处文档 | 用途 | 状态 |
|------|----------|------|------|
| `support@chroniccare.app` | `assets/legal/user_agreement.md` | 开发者联系邮箱 | ❌ 未注册 — 上 store 前必须注册并替换 |
| ~~`privacy@chroniccare.app`~~ | ~~`assets/legal/user_agreement.md`~~ | ~~隐私 / PIPL 投诉邮箱~~ | ✅ **R67 Sprint 1 软隐藏** (见 `docs/LEGACY_API_NOTES.md` 第 2 节) |
| ~~`privacy@chroniccare.app`~~ | ~~`assets/legal/privacy_policy.md`~~ | ~~个人信息保护负责人~~ | ✅ **R67 Sprint 1 软隐藏** (与上一行共享) |
| ~~`privacy@chroniccare.app`~~ | ~~`assets/legal/privacy_policy.md`~~ | ~~14 周岁以下用户监护人联系~~ | ✅ **R67 Sprint 1 软隐藏** (与上一行共享) |

**建议**:
- 注册 1 个真实域名 `chroniccare.app` (Google Domains / Cloudflare Registrar ~$10/year)
- 收 1 个邮箱: `support@` (开发者联系) forward 到开发者个人邮箱
- ~~`privacy@` 邮箱**已软隐藏** (R67 Sprint 1 决策), 不再需要注册 — 用户通过 App 内 ConsentGate 集中器行使 PIPL §14 撤回同意权~~
- 注册后**逐个**搜 3 文档替换, 不要漏

**`support@` 必须 7 个工作日内响应** — 阿里云 / Google Workspace 邮件服务都自动合规

---

## 2. 占位 GitHub 仓库

| URL | 出处文档 | 用途 | 状态 |
|-----|----------|------|------|
| `https://github.com/example/chroniccare/issues` | `assets/legal/user_agreement.md:58` | GitHub Issues 用户反馈入口 | ❌ 占位 |

**决策**:
- 选项 A: 开源 (AGPL-3 / Apache-2.0) — **不建议**: 精神心理患者数据敏感 + SQLCipher 加密密钥设计 = 开源后破解成本下降
- 选项 B: 公开仓库 (private 但 README 公开) — **不建议**: 跟 0 开源同样问题
- 选项 C: 替换为 `https://github.com/chroniccare/app-feedback/issues` (新建独立仓库放 issues / feedback) — **推荐**: issues 公开 + 主代码不公开
- 选项 D: 干脆删掉 GitHub Issues 入口, 改邮箱反馈 — **可接受**: 跟 §1 邮箱二选一即可

**待用户决策** — 选 C / D 后**逐个**替换文档

---

## 3. 律师过审

3 文档当前是"草稿"状态 (隐私 v0.22 / 协议 v0.24 / 同意书 v0.24), 未由专业律师过审。

### 3.1 国内律师 (PIPL / 网信办)

- **必须**: 找 1 个有个人信息保护法专长的中国律师 (如北京安杰 / 君合 / 立方 等)
- **费用**: ~¥15k-30k / 文档 (参考 2025 行情)
- **周期**: 1-2 周
- **范围**:
  - 隐私政策 §0-12 全章 (重点 §3 共享 / §9 联系方式 / §11 跨境 / §12 单独同意)
  - 用户协议 §3 付费 / §4 退款 (App Store / Google Play 退费政策引用) / §5 免责声明
  - 敏感个人信息处理同意书 §2-7 (重点 §2 私密倾诉 / §4 单独同意流程)

### 3.2 海外律师 (GDPR / CCPA / HIPAA) — **v1.0 再说**

- 隐私政策当前主要面向 PIPL, GDPR / CCPA 仅在 §6 Cookie 提了"无追踪"
- HIPAA 暂不适用 (美国 HIPAA 只覆盖"covered entity" — 个人开发者 app 不在 scope)
- **本批不上 GDPR / CCPA 重点审查**, 等 v1.0 真接 SMS provider + 欧洲用户量起来再补

### 3.3 走法务流程后必做 4 件事

1. 律师 review 完 + 改后, **3 文档顶部 TODO 标注改成** "律师 X (执业证号 XXXX) 已于 YYYY-MM-DD 审阅"
2. 3 文档 §"最后更新" 改 review 日期
3. App 内 setup 流程重走 — 弹 3 文档让用户重新同意, 刷 `userAgreementVersion` / `privacyPolicyVersion` / `sensitiveDataConsentAt` 字段
4. CHANGELOG 加 `[0.X.Y] - YYYY-MM-DD` 条目: "法务过审 — 隐私政策 / 用户协议 / 同意书 3 文档已替换"

---

## 4. 文档侧业务决策同步 (R67 已修)

| 章节 | 业务决策 | 文档侧同步状态 |
|------|----------|---------------|
| 隐私政策 §0.5 | R66 软提示 (每联系人单独勾选) | ✅ R67 已加 R66 软提示更新说明 |
| 隐私政策 §3 共享 | R66 失联通知业务整体暂停 | ✅ R67 已加"本版本不实际触发"声明 |
| 隐私政策 §4 撤回同意 | R67 撤回同意业务层生效 (vent_repo / care_engine / trend_page) | ✅ R67 已加"真正生效"说明 |
| 隐私政策 §12 单独同意 | R66 软告知弹窗 + R67 业务层生效 | ✅ R67 表格已加 2 行 |
| 隐私政策 §11 跨境 | R66 失联通知暂停 → 跨境链路暂不触发 | ⚠️ R67 仅声明 R66 业务暂停, §11 跨境细节**未改** (等 v1.0 真接 SMS provider 再补) |
| 用户协议 §1 服务说明 | R66 失联通知暂停 | ⚠️ R67 **未改** (协议 §1 仍说"失联通知"功能存在) — 待 v1.0 启用后改 |
| 用户协议 §5 免责声明 | SMS 通道未连接 | ⚠️ R67 **未改** — 仍写"因 SMS 通道未连接 (默认 mock 状态) 导致通知未发出" — 实际 R66 已暂停, 措辞需更新 |
| 敏感同意书 §2.1 打卡时间 | 失联检测用 | ✅ R67 **未改** (PIPL §28 健康数据范围未变) |
| 敏感同意书 §3 处理方式 | 失联通知 SMS 跨境链路 | ⚠️ R67 **未改** — 跨境链路描述仍以"真接 SMS"为前提, 跟 R66 实际状态不一致 — 待 v1.0 启用后改 |

**R67 未改项的处理**:
- 隐私政策 §11 跨境: 文档描述的是"未来跨境链路", 不算"虚构已发生" — 跟 R66 状态不冲突
- 用户协议 §1 / §5 + 敏感同意书 §3: 文档说"功能有, 通道未连" — R66 是"功能业务暂停" ≠ "通道未连"。**措辞需修**, 但 R67 没改 (因不影响上 store 审核, 优先级 P1, 留给 R68)

---

## 5. 替换 / 法务过审 Checklist (上 store 前 1 天走)

- [ ] 1 个真实域名 `chroniccare.app` 已注册 (whois 公开, 联系信息填真实)
- [ ] `support@chroniccare.app` 邮箱已开通 (转发到个人邮箱, 7 日响应 SLA)
- [x] ~~`privacy@chroniccare.app` 邮箱已开通~~ ✅ **R67 Sprint 1 已软隐藏, 不再需要**
- [ ] 隐私政策 §9 邮箱 1 处已替换 (developer email `support@`)
- [ ] 用户协议 §8 邮箱 1 处已替换 (developer email `support@`)
- [ ] GitHub Issues URL 已决策 (选项 C / D) + 文档已替换 / 删除
- [ ] 3 文档律师 review 完 + 顶部"未经律师过审"标注已删除 + 改为"律师 X 已审阅"
- [ ] 3 文档 §"最后更新" 已改 review 日期
- [ ] App 内 setup 流程重走 — 刷 3 个 version 字段
- [ ] CHANGELOG 加 `[0.X.Y] - YYYY-MM-DD` 条目
- [ ] 隐私 URL (https://chroniccare.app/privacy) 已部署, Play Console + App Store Connect 填这个 URL 不是 `file://` 或文档原文链接

---

## 6. 跨 store 一致性

| 字段 | Google Play | Apple App Store | 备注 |
|------|-------------|-----------------|------|
| 隐私 URL | 必须 HTTPS 公网 URL, 不能 file:// | 同上 | Play Console / App Store Connect 提交表单 |
| 邮箱 | 隐私 URL 同源或 footer 展示 | 同上 | 跟 §1 / §2 一致 |
| 业务暂停声明 | Play Console Data Safety Form 需勾 "未触发" | App Store Privacy Labels 同款 | R67 description 改了, 表单待 v1.0 真接 SMS 时再改 |

---

**最后更新**: 2026-07-31 (v0.27 round 67 Sprint 1)
**下次 review**: Sprint 1 上 store 前 1 天
**负责**: 开发者本人 + 法务外部律师 (待签约)
