# chroniccare.app 域名 + 邮箱注册详细步骤 (R108)

> **范围**: v0.30 R108 P0 #13 — Android + iOS 上架 P0 阻塞之五
> **基线**: v0.30.0+85 / 2026-08-10 cleanup
> **读者**: 上架负责人 / DevOps
> **关联**: `scripts/register_domain.sh` (R108) + `scripts/templates/*.html.tmpl` (R108)

---

## 一、为什么是 P0 阻塞 (4 视角共识)

`fastlane/metadata/{ios,android}/*/privacy_url.txt` + `support_url.txt` 共 12 个 URL 全部指向 **`https://chroniccare.app/...`** — **但域名未注册**, 上架时被 Google Play / Apple 拒因 "Privacy URL unreachable"。

| 平台 | 文件 | URL |
|---|---|---|
| iOS en-US | `privacy_url.txt` | `https://chroniccare.app/privacy` |
| iOS en-US | `support_url.txt` | `https://chroniccare.app/support` |
| iOS zh-Hans | `privacy_url.txt` | `https://chroniccare.app/privacy` |
| iOS zh-Hans | `support_url.txt` | `https://chroniccare.app/support` |
| iOS zh-Hant | `privacy_url.txt` | `https://chroniccare.app/privacy` |
| iOS zh-Hant | `support_url.txt` | `https://chroniccare.app/support` |
| Android en-US | **缺** (R100 已删) | `https://chroniccare.app/privacy` |
| Android zh-CN | **缺** (R100 已删) | `https://chroniccare.app/privacy` |

> **R100 修过**: Android 2 隐私 URL 删了, 改用 `https://chroniccare.app/privacy` 统一 (但仍不可达)。

---

## 二、6 步注册 + 部署

### Step 1: 注册 Cloudflare 账号

1. 打开 https://dash.cloudflare.com/sign-up
2. 填邮箱 + 密码 (建议用 `privacy@<你的个人域名>` 注册, 保持品牌一致)
3. 验证邮箱
4. 选 Free plan ($0/月, Pages + Email Routing 永久免费)

### Step 2: 注册 chroniccare.app 域名 (Cloudflare Registrar, $15/年)

1. Cloudflare Dashboard → **Domain Registration** → 搜索 `chroniccare.app`
2. 价格: **$15/年** (Cloudflare cost price, 不收中间商差价)
3. 加购物车 → Checkout:
   - 联系人信息 (Name / Address / Email / Phone) — **必须真实**, WHOIS 公开
   - 信用卡 (Visa / Mastercard / Amex)
4. 提交后 1-5 分钟激活, 收到 email "Domain registered"

> **⚠️ $.app TLD 强制 HTTPS**: Google 自有 TLD, 所有 `*.app` 域名必须 SSL 证书 (Cloudflare Pages 自动配, 免费)

### Step 3: 启用 Cloudflare Pages + 部署 4 HTML

1. Cloudflare Dashboard → **Workers & Pages** → **Create** → **Pages** → **Upload assets**
2. 项目名: `chroniccare-legal` (会生成 `chroniccare-legal.pages.dev`, 可绑自定义域)
3. 上传 4 HTML 文件 (用 `scripts/register_domain.sh` 自动生成, 或手动):
   - `privacy.html` → 访问 `https://chroniccare.app/privacy`
   - `support.html` → 访问 `https://chroniccare.app/support`
   - `user-agreement.html` → 访问 `https://chroniccare.app/user-agreement`
   - `sensitive-data-consent.html` → 访问 `https://chroniccare.app/sensitive-data-consent`
4. **Custom domains** → 绑 `chroniccare.app` (主域 + 4 子路径):
   - 点 "Set up a custom domain" → 输入 `chroniccare.app` → 选 "Add CNAME"
   - 重复 4 次, 加 4 子路径 (Pages 自动处理子路径)
5. SSL 证书自动配 (Cloudflare Universal SSL, 1-15 分钟)

### Step 4: 启用 Email Routing + 4 邮箱 (免费)

1. Cloudflare Dashboard → **Email** → **Email Routing** → **Get started**
2. 启用 Email Routing (改 MX 记录, 1-5 分钟)
3. **Destinations** → 添加你的个人邮箱 (例 `yourname@gmail.com`), 验证 (发邮件确认链接)
4. **Custom addresses** → 添加 4 邮箱:
   - `support@chroniccare.app` → 转发到 `yourname@gmail.com`
   - `privacy@chroniccare.app` → 转发到 `yourname@gmail.com`
   - `noreply@chroniccare.app` → 转发到 `yourname@gmail.com` (用得少)
   - `abuse@chroniccare.app` → 转发到 `yourname@gmail.com` (RFC 2142 强制要求)
5. 验证: 从你的个人邮箱发邮件到 `support@chroniccare.app`, 1 分钟内收到

> **优点**: 0 邮件服务器, 0 月费, Cloudflare Email Routing 永久免费
> **限制**: 仅转发, 不能直接发邮件 (发邮件用 Gmail / SendGrid / Amazon SES)

### Step 5: ICP 备案 (中国大陆上架强制, 7-20d)

> **⚠️ 必做, 不做 App Store 中国 / 小米 / 华为 / OPPO / vivo / 魅族 / 应用宝 都上架不了**

1. **准备**:
   - 营业执照 (企业 ICP, 1-2d 阿里云认证) 或 身份证 (个人 ICP, 部分省份不开放)
   - 法人身份证 (正面 + 反面)
   - 网站负责人身份证 (如果跟法人不同)
   - 幕布 (阿里云寄, 腾讯云无, 自拍白墙也行)
2. **注册备案系统账号**:
   - 阿里云: https://beian.aliyun.com (推荐, UI 友好)
   - 腾讯云: https://console.cloud.tencent.com/beian (备选)
3. **填主体信息**:
   - 公司名 (跟营业执照一致)
   - 营业执照号 (统一社会信用代码)
   - 法人姓名 / 身份证
4. **填网站信息**:
   - 主域: `chroniccare.app`
   - 4 子页面 (实际 ICP 备案只填主域, 子页面自动覆盖)
5. **提交初审** (阿里云 1-2d, 腾讯云 1d)
6. **寄送幕布拍照** (阿里云, 腾讯云无):
   - 阿里云寄幕布到家 (1-3d)
   - 法人站在幕布前拍 1 张照片
   - 上传备案系统
7. **管局审核** (7-20d, 看省份):
   - 北京/上海/广州: 5-7d
   - 浙江/江苏/广东: 7-10d
   - 偏远: 15-20d
8. **获得 ICP 备案号**: 形如 `京ICP备12345678号-1`
9. **展示**:
   - App 底部 footer: `京ICP备12345678号-1`
   - 4 HTML 页面 footer 加备案号
   - 工信部链接: `https://beian.miit.gov.cn/`
10. **公安备案** (30d 内, 简):
    - 打开 https://beian.mps.gov.cn
    - 用 ICP 备案账号登录
    - 填公安备案信息 (5 分钟)
    - 获得公安备案号 (形如 `京公网安备 11010102000000号`)
    - 同样展示在 App footer + 4 HTML footer

### Step 6: 修改 `fastlane/metadata/*/privacy_url.txt` + `support_url.txt`

> **R100 + R108 已统一占位**: 6 URL 文件内容已是 `https://chroniccare.app/privacy` / `https://chroniccare.app/support`, **域名注册后即自动生效**, 无需再改。

**但需新增 Android 2 URL 文件** (R100 删了, R108 恢复):

```bash
mkdir -p fastlane/metadata/android/en-US
echo "https://chroniccare.app/privacy" > fastlane/metadata/android/en-US/privacy_url.txt
echo "https://chroniccare.app/support" > fastlane/metadata/android/en-US/support_url.txt
mkdir -p fastlane/metadata/android/zh-CN
echo "https://chroniccare.app/privacy" > fastlane/metadata/android/zh-CN/privacy_url.txt
echo "https://chroniccare.app/support" > fastlane/metadata/android/zh-CN/support_url.txt
```

---

## 三、HTML 模板 (4 页面)

`scripts/templates/` 目录提供 4 HTML 模板 (用 `{{占位}}` 替换):

| 模板 | 输出 | 源 Markdown |
|---|---|---|
| `privacy.html.tmpl` | `privacy.html` | `assets/legal/privacy_policy.md` |
| `support.html.tmpl` | `support.html` | (无 md, 模板自带内容) |
| `user-agreement.html.tmpl` | `user-agreement.html` | `assets/legal/user_agreement.md` |
| `sensitive-data-consent.html.tmpl` | `sensitive-data-consent.html` | `assets/legal/sensitive_data_consent.md` |

**用法** (用 `register_domain.sh` 自动替换):

```bash
export CF_API_TOKEN="xxx"
export CF_ACCOUNT_ID="yyy"
./scripts/register_domain.sh
# 自动调用 sed 替换 {{VERSION}} / {{YEAR}} / {{EMAIL}} 占位
```

**手动替换** (Mac/Linux):

```bash
for tmpl in scripts/templates/*.html.tmpl; do
  out=$(basename "$tmpl" .tmpl)
  sed -e "s/{{VERSION}}/v0.30.0+85/g" \
      -e "s/{{YEAR}}/2026/g" \
      -e "s/{{EFFECTIVE_DATE}}/2026-08-10/g" \
      -e "s/{{SUPPORT_EMAIL}}/support@chroniccare.app/g" \
      -e "s/{{PRIVACY_EMAIL}}/privacy@chroniccare.app/g" \
      "$tmpl" > "build/$out"
done
# 嵌入 Markdown 内容到 {{CONTENT}} (需 pandoc)
pandoc -f markdown -t html assets/legal/privacy_policy.md | \
  sed -e 's/<h1>.*<\/h1>//' \
      -e 's/<\/body>//' \
  > /tmp/md_content.html
sed -i -e '/{{CONTENT}}/{
  r /tmp/md_content.html
  d
}' build/privacy.html
```

---

## 四、URL 验证 (域名注册后跑)

```bash
# 用 curl 验证 4 HTML 可达
for url in privacy support user-agreement sensitive-data-consent; do
  echo -n "$url: "
  curl -s -o /dev/null -w "%{http_code} (%{size_download} bytes)\n" \
    "https://chroniccare.app/$url"
done

# 期望输出:
# privacy: 200 (16XXX bytes)
# support: 200 (5XXX bytes)
# user-agreement: 200 (5XXX bytes)
# sensitive-data-consent: 200 (6XXX bytes)

# 邮箱验证
for email in support privacy noreply abuse; do
  echo -n "$email@chroniccare.app: "
  nslookup -type=MX chroniccare.app | grep "mail exchanger"
done
```

---

## 五、CI 集成 (Cloudflare API 自动化)

`scripts/register_domain.sh` 已用 Cloudflare API 写:
- Step 3: 添加 zone (DNS)
- Step 4: Email Routing 配 4 邮箱
- Step 5: Pages 部署 (需 wrangler CLI)

**GitHub Actions 例**:

```yaml
# .github/workflows/deploy-legal-pages.yml
- name: Deploy to Cloudflare Pages
  env:
    CF_API_TOKEN: ${{ secrets.CF_API_TOKEN }}
    CF_ACCOUNT_ID: ${{ secrets.CF_ACCOUNT_ID }}
  run: ./scripts/register_domain.sh
```

**GitLab CI 例**:

```yaml
deploy:legal:
  stage: deploy
  script:
    - export CF_API_TOKEN=$CF_API_TOKEN
    - export CF_ACCOUNT_ID=$CF_ACCOUNT_ID
    - ./scripts/register_domain.sh
  only:
    - main
```

---

## 六、ICP 备案脚本化? 暂不可能

ICP 备案 **必须人工在阿里云 / 腾讯云备案系统操作**:
- 涉及营业执照拍照 + 法人身份证 + 幕布照片
- 管局人工审核 (真人看资料)
- 任何"脚本自动化 ICP 备案"都是骗子

**预计人工时间**:
- 准备材料: 1-2h
- 填系统 + 初审: 2-4h
- 寄幕布 + 拍照: 3-5d
- 管局审核: 7-20d
- **总计**: 2-3 周 (含等待时间)

---

## 七、隐私 / 安全考虑

1. **WHOIS 公开**: Cloudflare Registrar 默认开启 WHOIS privacy (免费, 隐藏真实邮箱/电话), 建议保持
2. **DNSSEC**: 强烈建议启用 (Cloudflare 免费 1-click), 防止 DNS 劫持
3. **CAA 记录**: 限制证书签发 (只允许 Let's Encrypt / Google Trust Services)
4. **HSTS**: Pages 自动启用, 强制 HTTPS ($.app TLD 强制)
5. **CSP**: 4 HTML 模板应加 Content-Security-Policy (后续 R109)

---

## 八、未做 / 风险 / 下一步

### 已知限制

- **ICP 备案必须人工** — 至少 2-3 周审核时间, 上架时间线被卡
- **域名 $15/年** — 续费需每年 1 次 (信用卡自动扣)
- **Cloudflare Email Routing 仅转发** — 不能直接发邮件 (发邮件用 SendGrid / Gmail API)
- **4 HTML 静态页面** — 不能后台动态生成 (如需评论/订阅, 需 Cloudflare Workers + D1)

### 后续优化 (R109+)

- R109: 加 `check_domain_reachable.py` 守门员, 每次 PR 自动 curl 4 URL 验 200
- R109: 集成 Fathom / Plausible 隐私友好统计 (知道多少人访问隐私页, 不收集 PII)
- R110: Cloudflare Workers + D1 做评论/订阅 (用户可订阅隐私政策更新通知)
- R110: 集成 Google Search Console + Bing Webmaster (SEO 优化, 用户搜 "ChronicCare 隐私" 找到这页)

---

## 九、Checklist (域名注册 + 上架前逐项过)

### 域名 + 邮箱

- [ ] Cloudflare 账号已注册
- [ ] chroniccare.app 域名已注册 ($15/年, 信用卡已扣)
- [ ] WHOIS privacy 启用 (隐藏真实邮箱/电话)
- [ ] DNSSEC 启用
- [ ] Email Routing 启用
- [ ] 4 邮箱 `support / privacy / noreply / abuse@chroniccare.app` 已配转发
- [ ] 测试: 个人邮箱发邮件到 `support@chroniccare.app`, 1 分钟内收到
- [ ] 测试: 4 邮箱各发 1 封测试邮件, 全收到

### Pages 部署

- [ ] `chroniccare-legal` Pages 项目已创建
- [ ] 4 HTML 已上传 (privacy / support / user-agreement / sensitive-data-consent)
- [ ] Custom domain `chroniccare.app` 已绑, 4 子路径路由 OK
- [ ] SSL 证书自动签发 (Cloudflare Universal SSL, 1-15 分钟)
- [ ] 4 URL 全部 200, 字节数 > 1KB

### ICP 备案 (中国大陆上架)

- [ ] 营业执照已上传阿里云/腾讯云备案系统
- [ ] 主体信息填完
- [ ] 网站信息填完 (主域 chroniccare.app)
- [ ] 初审通过 (1-2d)
- [ ] 幕布拍照上传 (阿里云)
- [ ] 管局审核通过 (7-20d)
- [ ] 获得 ICP 备案号
- [ ] App footer + 4 HTML footer 加 ICP 备案号
- [ ] 公安备案 (30d 内, https://beian.mps.gov.cn)

### URL 文件

- [ ] `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` 已是 `https://chroniccare.app/privacy`
- [ ] `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` 已是 `https://chroniccare.app/support`
- [ ] `fastlane/metadata/android/{en-US,zh-CN}/privacy_url.txt` 已新建
- [ ] `fastlane/metadata/android/{en-US,zh-CN}/support_url.txt` 已新建
- [ ] curl 验证 12 URL 全 200

### 验证

- [ ] App Store Connect → App 隐私 → Privacy Policy URL 可达
- [ ] App Store Connect → App 通用 → Support URL 可达
- [ ] Google Play Console → Store listing → Privacy policy URL 可达
- [ ] Google Play Console → App content → Data safety → Data deletion endpoint URL 可达
- [ ] Google Play Console → App content → Health apps → Disclosure 引用的 URL 可达

---

## 十、相关文件清单

| 文件 | 类型 | 作用 |
|---|---|---|
| `scripts/register_domain.sh` | Bash 脚本 (R108) | Cloudflare API 注册 + Pages 部署占位 |
| `scripts/templates/privacy.html.tmpl` | HTML 模板 (R108) | 隐私页 (来自 privacy_policy.md) |
| `scripts/templates/support.html.tmpl` | HTML 模板 (R108) | 支持页 (含 FAQ) |
| `scripts/templates/user-agreement.html.tmpl` | HTML 模板 (R108) | 用户协议页 |
| `scripts/templates/sensitive-data-consent.html.tmpl` | HTML 模板 (R108) | 敏感数据同意页 (PIPL §14) |
| `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` | Markdown 源 (R67) | HTML 转换源 |
| `fastlane/metadata/{ios,android}/*/privacy_url.txt` | URL 文件 (R100 + R108) | 12 URL 指向 chroniccare.app |
| `fastlane/metadata/{ios,android}/*/support_url.txt` | URL 文件 (R100 + R108) | 12 URL 指向 chroniccare.app |
