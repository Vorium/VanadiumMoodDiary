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

## 4 项 Sprint 1 上架必做 (R67 决策保留)

### 1. 律师 review 3 份 md
- `assets/legal/privacy_policy.md` (14.2 KB) — 14 章
- `assets/legal/user_agreement.md` (4.5 KB)
- `assets/legal/sensitive_data_consent.md` (4.5 KB)
- **估时**: 1-2 周 + ¥15-30k/文档 (3 文档)
- **R69 状态**: 修订历史段化 + 5 段 walkthrough 落地 (CC-3/4/8)
- **未做**: 律师 review 1-2 周 + 签字

### 2. 邮箱 `support@chroniccare.app` 注册
- **R67 状态**: TODO 占位, 当前文件 3 处引用 (privacy_policy / user_agreement / Play Console Developer email)
- **估时**: 1-2h (注册邮箱 + 替换 3 处)
- **未做**: 邮箱注册 + 替换 3 处 md

### 3. GitHub 仓库
- `https://github.com/example/chroniccare/issues` 当前是 TODO 占位
- **R67 状态**: TODO 占位, `user_agreement.md:60-61` 引用
- **估时**: 半天 (确认仓库 / 创建 issues section)
- **未做**: 创建 / 确认仓库

### 4. 域名 `chroniccare.app` 注册 + HTTPS 部署
- **R67 状态**: TODO 占位, 6 URL 文件 + Play Console Privacy Policy URL
- **估时**: 1-2 天 (注册 + 备案 + Cloudflare 部署 3 份 md 转 HTML)
- **未做**: 域名注册 + DNS + 备案 + HTTPS 部署

## 4 项 Sprint 1 上架前必做 (R67-R72 累计)

详见 `docs/DEPLOYMENT.md` 阶段 7.5 上架前 must-check 清单。
