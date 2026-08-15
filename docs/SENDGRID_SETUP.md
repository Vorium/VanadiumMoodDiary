# SendGrid 集成指南

> **⚠️ Legacy 存档 (v1.1.0)**: Email 业务已于 v1.1.0 删除, 本文档为历史存档, 不再维护。

> 慢病管家用 SendGrid 发"停药通知"邮件。本文档告诉你**15 分钟内**完成配置。

> **⚠️ v0.22 round 29 状态说明**：当前 `EmailService` 是 **mock-only**（v0.16 删 dio 依赖，
> v0.7 后改 mock 短信），实际不发邮件。本文档描述的是 v1.0+ 接入 SendGrid 的路径，
> 当前 .env `EMAIL_USE_MOCK=true` 时所有邮件走 mock 日志。要做真实发送需先接入
> dio + SendGrid SDK（参考 §6 v1.0+ 章节）。**6 处文档错误已修**（path / import / 构造签名 / type）。

---

## 1. 注册 SendGrid（5 分钟）

1. 访问 https://app.sendgrid.com/
2. 点 **Start for Free**（免费版 100 封/天，足够 MVP）
3. 填邮箱 + 密码 + 手机验证
4. 登录后进 Dashboard

---

## 2. 创建 API Key（2 分钟）

1. 左菜单 **Settings → API Keys**
2. 点 **Create API Key**
3. Name: `chroniccare-prod`
4. API Key Permissions: **Restricted Access** → 勾选 **Mail Send**（其他不要勾）
   - 或者直接选 **Full Access**（最简单，但权限过大）
5. 点 **Create & View**
6. **复制 API Key**（只显示一次！）
   - 格式：`SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

## 3. 验证发件人邮箱（5 分钟）

SendGrid 要求先验证发件人：

1. 左菜单 **Settings → Sender Authentication**
2. **Single Sender Verification** → **Create New Sender**
3. 填：
   - From Name: `慢病管家`
   - From Email: `noreply@chroniccare.app`（或你自己的域名邮箱）
   - Reply To: 同上
   - Company Address: 填你的（可以写测试地址）
4. 点 **Create**
5. **去你邮箱**（填写的 From Email）点验证链接

> ⚠️ 这一步必须做！否则发件被 SendGrid 拦截。

---

## 4. 配置 .env（1 分钟）

```bash
# 复制模板
cp .env.example .env

# 编辑 .env
nano .env
```

填入：
```bash
SENDGRID_API_KEY=SG.你的真实key
SENDGRID_FROM_EMAIL=noreply@chroniccare.app
SENDGRID_FROM_NAME=慢病管家
EMAIL_USE_MOCK=false
```

---

## 5. 测试发送（2 分钟）

### 5.1 单元测试（mock 模式）

```bash
flutter test test/data/email_service_round9_test.dart
```

应该看到 2 个 mock 模式测试通过（v0.22 round 9 后缀命名）。

### 5.2 真实发送测试（用真实 API Key）

写个一次性脚本：

```bash
cat > /tmp/test_sendgrid.dart <<'EOF'
import 'package:chroniccare/core/data/services/email_service.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

void main() async {
  // v0.22 round 29 修正:
  // - import path: data/services → core/data/services (v0.18 改 umbrella)
  // - 构造: apiKey 可选, useMock 默认 true
  // - 实际当前 EmailService mock-only, useMock:false 仍走 mock (dio 依赖已删)
  // - to 仍是 String, phone 替代 email (v0.6 设计) — 注释保持
  // - medication 类型: MedicationEntity? (v0.16 domain entity 化)
  // - cycleHours: int 48 不是 Duration (v0.21 P0-7 改)
  final service = EmailService(
    apiKey: 'SG.你的真实key',
    useMock: true, // v0.22 当前必须 true, 真实发送 v1.0+
  );

  final ok = await service.sendMedicationReminder(
    to: '13800138000', // v0.6: phone 替代 email
    userName: '测试小明',
    daysWithoutCheckIn: 2,
    lastCheckIn: DateTime.now().subtract(const Duration(days: 2)),
    medication: null, // MedicationEntity? v0.16
    cycleHours: 48, // int (v0.21 P0-7)
  );

  print(ok ? '✅ 发送成功(mock)' : '❌ 发送失败');
}
EOF

dart run /tmp/test_sendgrid.dart
```

### 5.3 送达率测试（10 个邮箱）

```bash
# 准备 10 个测试邮箱（用自己的 + 朋友的）
EMAILS="your@gmail.com friend1@qq.com friend2@163.com ..."

for email in $EMAILS; do
  echo "Testing: $email"
  # 调上面脚本
done
```

记录每个邮箱的送达情况：
- 立即收到：✅
- 进垃圾箱：⚠️（需调 SPF/DKIM）
- 收不到：❌（查 SendGrid Activity 看原因）

---

## 6. 生产化配置（v1.0+）

### 6.1 域名认证（避免进垃圾箱）

如果要发到企业邮箱，强烈建议做 **Domain Authentication**：

1. **Settings → Sender Authentication → Authenticating Your Domain**
2. 选你的 DNS 提供商（Cloudflare / 阿里云 / 腾讯云 / GoDaddy）
3. 按提示加 SPF / DKIM / DMARC 记录
4. 验证后，发件人用你的域名（如 `noreply@yourdomain.com`）

### 6.2 提升免费额度

- 免费版：100 封/天 = 3000 封/月
- Essentials 版（$20/月）：50,000 封/月
- v1.0+ 1000 用户 * 平均每月 0.5 封 = 500 封 → 免费版足够

### 6.3 监控

1. **SendGrid Dashboard → Activity**：看送达/打开/点击
2. **Settings → Webhook**：接 SendGrid Event 实时回调（v1.0+）
3. **告警**：连续 1 小时送达率 < 95% 报警

---

## 7. 故障排查

| 问题 | 原因 | 解法 |
|---|---|---|
| 401 Unauthorized | API Key 错 | 重新生成 |
| 403 Forbidden | 没勾 Mail Send 权限 | 重新创建时勾上 |
| 邮件进垃圾箱 | 没做 Domain Auth | 加 SPF/DKIM |
| 完全收不到 | 发件人邮箱未验证 | 完成步骤 3 |
| 报错"sender identity" | 发件人不在 verified list | 加新 sender |

---

## 8. 安全 checklist

- [ ] `.env` 在 `.gitignore`（已加）
- [ ] API Key 用 Restricted Access（不是 Full Access）
- [ ] .env 不会上传到 GitHub
- [ ] 生产环境用 Environment Variable，不写死在代码
- [ ] 定期 rotate API Key（每 3-6 个月）
- [ ] 监控 SendGrid 异常登录
