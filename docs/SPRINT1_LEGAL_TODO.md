# Sprint 1 法律上架待办（v0.27 R67 集中跟踪）

> v0.27 R67 引入 (P0 集中清零): 3 份法律 md (`privacy_policy.md` /
> `user_agreement.md` / `sensitive_data_consent.md`) 顶部 TODO 律师过审 banner
> 删完, 改成修订历史段化 (R67 audit 改)。**Sprint 1 上架前 4 项必须**:
>
> 1. 律师 review 3 份 md
> 2. 邮箱 `support@chroniccare.app` 注册 + 替换 TODO
> 3. GitHub 仓库 `https://github.com/example/chroniccare/issues` 替换 TODO
> 4. 域名 `chroniccare.app` 注册 + HTTPS 部署 3 份 md
>
> R67-R72 持续: banner 已删, 但 4 项待办 (邮箱 / 仓库 / 域名 / 律师) 仍在
> 进展待用户侧操作。
>
> v0.27 R77 (P0-15 紧急, R74 报告 AS-P0-11 修): 此占位 md 创建, 让
> `privacy_policy.md:0.5` + `user_agreement.md:60-61` 引用死链
> `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` 暂时不报
> 404。律师 review 启动后, 此占位 md 由律师 / 法务替换为正式版本。
>
> **v0.30 R96 (2026-08-07) 更新**: P0-2/3/5 已软隐藏 (跟 `privacy@chroniccare.app`
> 同一策略), 不再阻塞当前版本审核。`user_agreement.md` §8 联系方式改"本服务暂不提供
> 邮件 / GitHub 渠道", `fastlane/Appfile` 改 ENV 模式。域名 + 邮箱 + 仓库注册后
> 取消软隐藏恢复联系方式 (非上架 blocker, 但 PIPL §52 建议长期保留可达渠道)。

## 4 项 Sprint 1 上架必做 (R67 决策保留, R96 部分软隐藏)

### 1. 律师 review 3 份 md
- `assets/legal/privacy_policy.md` (14.2 KB) — 14 章
- `assets/legal/user_agreement.md` (4.5 KB)
- `assets/legal/sensitive_data_consent.md` (4.5 KB)
- **估时**: 1-2 周 + ¥15-30k/文档 (3 文档)
- **R69 状态**: 修订历史段化 + 5 段 walkthrough 落地 (CC-3/4/8)
- **未做**: 律师 review 1-2 周 + 签字

### 2. 邮箱 `support@chroniccare.app` 注册 — ✅ R96 已软隐藏
- **R96 状态**: TODO 占位已软隐藏, `user_agreement.md` §8 改"本服务暂不提供邮件渠道"
- **估时**: 1-2h (注册邮箱 + 取消软隐藏恢复联系方式)
- **未做**: 邮箱注册 (依赖域名注册, 见 §4)

### 3. GitHub 仓库 — ✅ R96 已软隐藏
- **R96 状态**: TODO 占位已软隐藏, `user_agreement.md` §8 改"本服务暂不提供 GitHub 渠道"
- **估时**: 半天 (确认仓库 / 创建 issues section + 取消软隐藏)
- **未做**: 创建 / 确认仓库

### 4. 域名 `chroniccare.app` 注册 + HTTPS 部署
- **R67 状态**: TODO 占位, 6 URL 文件 + Play Console Privacy Policy URL
- **估时**: 1-2 天 (注册 + 备案 + Cloudflare 部署 3 份 md 转 HTML)
- **未做**: 域名注册 + DNS + 备案 + HTTPS 部署

## 4 项 Sprint 1 上架前必做 (R67-R72 累计)

详见 `docs/DEPLOYMENT.md` 阶段 7.5 上架前 must-check 清单。
