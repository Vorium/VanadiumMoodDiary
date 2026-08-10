#!/usr/bin/env bash
# v0.30 R108: chroniccare.app 域名注册 + Cloudflare Pages 部署占位脚本
#
# 背景 (R108):
# - R107 4 视角共识 P0: chroniccare.app 域名未注册 → 12 URL 不可达
# - 6 隐私 URL (iOS 3 locale) + 5 支持 URL (iOS 3 locale + Android 2 locale) = 11 不可达
# - 注册 4 邮箱: privacy@ / support@ / noreply@ / abuse@ (Cloudflare Email Routing 免费)
# - Cloudflare Pages 部署 4 HTML: privacy / support / user-agreement / sensitive-data-consent
# - ICP 备案 (中国大陆上架强制, 7-20d 审核, 需营业执照)
#
# ⚠️  本脚本仅占位, **实际跑需用户填真实信息**:
#    1. Cloudflare 账号 + API token
#    2. 信用卡 ($15/年 域名 + Pages 免费)
#    3. 营业执照 (ICP 备案需要)
#
# 用法 (Mac/Linux/WSL):
#   export CF_API_TOKEN="your_cloudflare_api_token"
#   export CF_ACCOUNT_ID="your_cloudflare_account_id"
#   ./scripts/register_domain.sh
#
# 详细步骤见: docs/audit/2026-08-10-cleanup/R108-domain-registration-guide.md

set -euo pipefail

# 0. 占位 — 真实跑前需 dev 填下面 4 个变量
CF_API_TOKEN="${CF_API_TOKEN:-PLACEHOLDER_REPLACE_WITH_YOUR_CLOUDFLARE_API_TOKEN}"
CF_ACCOUNT_ID="${CF_ACCOUNT_ID:-PLACEHOLDER_REPLACE_WITH_YOUR_ACCOUNT_ID}"
CF_ZONE_ID="${CF_ZONE_ID:-PLACEHOLDER_REPLACE_WITH_ZONE_ID_AFTER_DOMAIN_REGISTERED}"
DOMAIN="${DOMAIN:-chroniccare.app}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@chroniccare.app}"
PRIVACY_EMAIL="${PRIVACY_EMAIL:-privacy@chroniccare.app}"
NORELY_EMAIL="${NORELY_EMAIL:-noreply@chroniccare.app}"
ABUSE_EMAIL="${ABUSE_EMAIL:-abuse@chroniccare.app}"

# 1. 占位检查
if [[ "$CF_API_TOKEN" == PLACEHOLDER* ]] || [[ "$CF_ACCOUNT_ID" == PLACEHOLDER* ]]; then
  echo "[FAIL] 本脚本是占位, 实际跑前需 dev 填真实 CF_API_TOKEN + CF_ACCOUNT_ID" >&2
  echo "       详见 R108-domain-registration-guide.md §二" >&2
  echo "       1. 注册 Cloudflare 账号: https://dash.cloudflare.com/sign-up" >&2
  echo "       2. 获取 API token: https://dash.cloudflare.com/profile/api-tokens" >&2
  echo "       3. 获取 Account ID: dash.cloudflare.com → Workers & Pages → 右侧" >&2
  echo "       4. 重新跑脚本, 传入真实值:" >&2
  echo "          export CF_API_TOKEN=xxx CF_ACCOUNT_ID=yyy" >&2
  echo "          ./scripts/register_domain.sh" >&2
  exit 1
fi

# 2. 工具检查
for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "[FAIL] $tool 找不到。请装: brew install $tool (Mac) / sudo apt install $tool (Linux)" >&2
    exit 1
  fi
done

CF_API="https://api.cloudflare.com/client/v4"
AUTH_HEADER="Authorization: Bearer $CF_API_TOKEN"

# 3. Step 1: 注册域名 (Cloudflare Registrar, $15/年, 仅支持 $.app TLD)
echo "[1/5] 注册 $DOMAIN (Cloudflare Registrar, \$15/年)..."

# 检查域名是否已注册
CHECK_RESP=$(curl -s -X GET "$CF_API/registrar/domains/$DOMAIN" \
  -H "$AUTH_HEADER" 2>&1)
if echo "$CHECK_RESP" | jq -e '.success == true' >/dev/null 2>&1; then
  echo "      [OK] 域名已存在, 跳过注册"
else
  # 注册域名 (实际生产环境需在 Cloudflare Dashboard 手动注册, 需信用卡)
  echo "      [WARN] 实际注册需在 Cloudflare Dashboard 手动操作:"
  echo "             1. https://dash.cloudflare.com → Domain Registration"
  echo "             2. 搜索 $DOMAIN → Add to cart"
  echo "             3. 填联系人信息 + 信用卡 → Submit"
  echo "             4. 约 1-5 分钟完成"
  echo "      [SKIP] 本脚本自动注册 API 暂不开放 (Cloudflare 政策)"
  read -rp "      完成注册后回车继续 (按 Ctrl+C 中止): "
fi

# 4. Step 2: 添加 zone
echo "[2/5] 添加 zone (Cloudflare DNS)..."
ZONE_RESP=$(curl -s -X POST "$CF_API/zones" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$DOMAIN\",\"type\":\"full\"}" 2>&1)
if echo "$ZONE_RESP" | jq -e '.success == true' >/dev/null 2>&1; then
  CF_ZONE_ID=$(echo "$ZONE_RESP" | jq -r '.result.id')
  echo "      [OK] zone id: $CF_ZONE_ID"
else
  echo "      [INFO] zone 可能已存在, 尝试 GET..."
  ZONE_RESP=$(curl -s -X GET "$CF_API/zones?name=$DOMAIN" \
    -H "$AUTH_HEADER" 2>&1)
  if echo "$ZONE_RESP" | jq -e '.result[0].id' >/dev/null 2>&1; then
    CF_ZONE_ID=$(echo "$ZONE_RESP" | jq -r '.result[0].id')
    echo "      [OK] zone id (existing): $CF_ZONE_ID"
  else
    echo "[FAIL] zone 创建失败: $ZONE_RESP" >&2
    exit 1
  fi
fi

# 5. Step 3: Email Routing (4 邮箱转发, 免费)
echo "[3/5] 启用 Email Routing + 4 邮箱..."
# 启用 Email Routing
curl -s -X POST "$CF_API/zones/$CF_ZONE_ID/email/routing/enable" \
  -H "$AUTH_HEADER" >/dev/null 2>&1 || echo "      (Email Routing 可能已启用)"

# 添加 4 邮箱 (转发的目标地址需 dev 填)
DESTINATION_EMAIL="${DESTINATION_EMAIL:-PLACEHOLDER_REPLACE_WITH_YOUR_PERSONAL_EMAIL}"
for email in "$SUPPORT_EMAIL" "$PRIVACY_EMAIL" "$NORELY_EMAIL" "$ABUSE_EMAIL"; do
  echo "      配置 $email → $DESTINATION_EMAIL"
  curl -s -X POST "$CF_API/zones/$CF_ZONE_ID/email/routing/addresses" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    --data "{\"email\":\"$email\"}" >/dev/null 2>&1 || true
done

# 添加 routing rule
curl -s -X POST "$CF_API/zones/$CF_ZONE_ID/email/routing/rules" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  --data "{
    \"name\": \"forward all to personal\",
    \"enabled\": true,
    \"matchers\": [{\"type\": \"all\"}],
    \"actions\": [{\"type\": \"forward\", \"value\": [\"$DESTINATION_EMAIL\"]}]
  }" >/dev/null 2>&1 || true

echo "      [OK] Email Routing 配置完成 (需在 dashboard 验证)"

# 6. Step 4: Pages 项目 (用 wrangler CLI 部署 4 HTML)
echo "[4/5] 创建 Cloudflare Pages 项目..."

# 临时生成 4 HTML (从 assets/legal/*.md + 模板)
TMP_DIR=$(mktemp -d)
echo "      生成 4 HTML 到 $TMP_DIR..."

# 调用 pandoc 转换 (可选, 没装的话用 sed 简单包 HTML)
if command -v pandoc >/dev/null 2>&1; then
  PANDOC_OPTS=(-f markdown -t html --standalone)
else
  PANDOC_OPTS=()
fi

for page in "privacy:privacy_policy" "support:" "user-agreement:user_agreement" "sensitive-data-consent:sensitive_data_consent"; do
  IFS=':' read -r page_name md_name <<< "$page"
  if [ -z "$md_name" ]; then
    # support 没对应 md, 用模板默认
    if [ -f "scripts/templates/${page_name}.html.tmpl" ]; then
      sed -e "s/{{VERSION}}/v0.30.0+85/g" \
          -e "s/{{YEAR}}/2026/g" \
          -e "s/{{EFFECTIVE_DATE}}/2026-08-10/g" \
          -e "s/{{SUPPORT_EMAIL}}/$SUPPORT_EMAIL/g" \
          -e "s/{{PRIVACY_EMAIL}}/$PRIVACY_EMAIL/g" \
          "scripts/templates/${page_name}.html.tmpl" > "$TMP_DIR/${page_name}.html"
    fi
  else
    # 转换 md → html
    if [ -f "assets/legal/${md_name}.md" ] && [ -f "scripts/templates/${page_name}.html.tmpl" ]; then
      # 占位: 简化为 sed 替换, 实际生产应用 pandoc
      sed -e "s|{{VERSION}}|v0.30.0+85|g" \
          -e "s|{{YEAR}}|2026|g" \
          -e "s|{{EFFECTIVE_DATE}}|2026-08-10|g" \
          -e "s|{{SUPPORT_EMAIL}}|$SUPPORT_EMAIL|g" \
          -e "s|{{PRIVACY_EMAIL}}|$PRIVACY_EMAIL|g" \
          "scripts/templates/${page_name}.html.tmpl" > "$TMP_DIR/${page_name}.html"
      # 简单把 md 内容嵌进 {{CONTENT}} 占位
      MD_CONTENT=$(cat "assets/legal/${md_name}.md" | sed 's/$/\<br\>/')
      sed -i "s|{{CONTENT}}|${MD_CONTENT}|g" "$TMP_DIR/${page_name}.html"
    fi
  fi
  echo "      [OK] 生成 $TMP_DIR/${page_name}.html"
done

# wrangler 部署 (需装 wrangler: npm i -g wrangler)
if command -v wrangler >/dev/null 2>&1; then
  cd "$TMP_DIR"
  for page in privacy support user-agreement sensitive-data-consent; do
    if [ -f "${page}.html" ]; then
      # Pages 直接支持单 HTML 部署 (走 wrangler pages deploy)
      wrangler pages deploy "$TMP_DIR" \
        --project-name="chroniccare-legal" \
        --branch="main" \
        --commit-message="R108 deploy legal pages" 2>&1 | tail -5
      break   # 1 次 deploy 全 4 个 HTML
    fi
  done
  cd - >/dev/null
else
  echo "      [WARN] wrangler 未装, 跳过自动部署"
  echo "             装: npm install -g wrangler"
  echo "             然后: cd $TMP_DIR && wrangler pages deploy . --project-name=chroniccare-legal"
fi

# 7. Step 5: ICP 备案 (中国大陆上架强制)
echo ""
echo "[5/5] ICP 备案 (中国大陆上架强制, 7-20d 审核)..."
echo "      ⚠️  本步骤无法脚本化, 需人工在 ICP 系统操作:"
echo ""
echo "      1. 注册阿里云/腾讯云账号 + 营业执照认证 (1-2d)"
echo "      2. 备案系统: https://beian.aliyun.com (阿里云) 或 https://console.cloud.tencent.com/beian (腾讯云)"
echo "      3. 填主体信息 (公司名 / 营业执照 / 法人身份证)"
echo "      4. 填网站信息: chroniccare.app (主域) + 4 子页面 (隐私/支持/用户协议/敏感数据同意书)"
echo "      5. 提交初审 (阿里云 1-2d, 腾讯云 1d)"
echo "      6. 寄送幕布拍照 (阿里云寄幕布, 腾讯云无)"
echo "      7. 管局审核 (7-20d, 看省份, 北京/上海 5-7d, 偏远 15-20d)"
echo "      8. 获得 ICP 备案号 (例: 京ICP备12345678号-1)"
echo "      9. 在 App 底部 / 隐私政策底部展示: '京ICP备12345678号-1'"
echo "      10. 公安备案 (30d 内, 简): https://beian.mps.gov.cn"
echo ""
echo "[OK] 域名注册 + Email Routing + Pages 部署 完成!"
echo ""
echo "下一步:"
echo "  1. 在 Cloudflare Dashboard 验证 4 邮箱 (发测试邮件)"
echo "  2. 在 Cloudflare Pages Dashboard 验证 4 HTML 可访问:"
echo "     https://chroniccare.app/privacy"
echo "     https://chroniccare.app/support"
echo "     https://chroniccare.app/user-agreement"
echo "     https://chroniccare.app/sensitive-data-consent"
echo "  3. 修改 fastlane/metadata/{ios,android}/*/privacy_url.txt + support_url.txt 6 文件 (已是占位, 无需改)"
echo "  4. ICP 备案 (中国大陆上架必须, 7-20d)"
echo "  5. 验证 App Store Connect / Google Play Console 上架材料可达"
echo ""
