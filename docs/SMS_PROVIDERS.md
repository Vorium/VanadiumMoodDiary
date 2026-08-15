# SMS Provider 接入指南 (v0.25 R55 增补)

> **⚠️ Legacy 存档 (v1.1.0)**: SMS 业务已于 v1.1.0 删除, 本文档为历史存档, 不再维护。

> **背景:** spzh 视角 P0 #6: `AliyunSmsProvider.send()` 当前 throw
> `UnimplementedError` 占位,release 模式下失联通知永远抛错 = production
> **不可用**。**本文档提供:** 阿里云 SMS SDK 真接详细 plan + 接入步骤
> + 上线 checklist。

---

## 总览

| # | Provider | 适用场景 | 接入周期 | 成本 |
|---|----------|----------|----------|------|
| 1 | **阿里云短信 (Aliyun SMS)** | 中国大陆 +86 | 2+ 月 (备案 + 签名 + 模板审核) | 0.045 元/条 |
| 2 | **腾讯云短信 (Tencent SMS)** | 中国大陆 +86 备选 | 1+ 月 | 0.04-0.06 元/条 |
| 3 | **Twilio** | 海外号码 (+1 / +44 / +852 等) | 1 周 (注册即用) | $0.0079/条 |
| 4 | **MockSmsProvider** (已有) | dev / test | 0 | 0 |

**PIPL 跨境合规:** 海外号码优先 Twilio (主体在美, 通过境内
Twilio 子公司签标准合同 + 备案)。

---

## 1. 阿里云短信 (Aliyun SMS) - 国内主选

### 1.1 注册 + 备案 (法务 + 业务)

- 网址: https://dysms.console.aliyun.com/
- 步骤:
  1. 阿里云账号实名认证 (企业 + 法人身份证 + 营业执照, 1-3 工作日)
  2. 申请短信签名 "慢病管家" (审核 1-2 工作日, 需业务证明)
  3. 申请短信模板 (审核 1-2 工作日, **内容需法务过审**)
     - 模板示例: "我是${userName}，已${days}天没在App里打卡吃药。
       请你方便的时候提醒我按时吃药，避免复发。"
     - 模板审核驳回率高, 需明确说明用途 (用户主动设置的关怀通知)
  4. 申请 AccessKey (`AccessKeyId` + `AccessKeySecret`)
- **总周期:** 2 周 - 2 月 (模板审核 1-2 周 + 签名 1-2 周 + 实名 1-3 天)

### 1.2 集成

- `pubspec.yaml`:
  ```yaml
  dependencies:
    # 不直接用 aliyun_sms (无官方 Flutter SDK),用 dio 直连 API
    dio: ^5.0.0  # 项目可能已有
    crypto: ^3.0.0  # HMAC-SHA1 签名
  ```
- 现有 `AliyunSmsProvider` (lib/core/data/services/sms_service.dart)
  已接受 `accessKeyId/secret/signName/templateCode`, 改 `send()` 真实
  实现:
  
  ```dart
  @override
  Future<bool> send({required String to, required String body, String? templateId}) async {
    // R55 计划: 真实接入阿里云 SMS API
    // 1. 构造请求参数 (PhoneNumbers / TemplateCode / TemplateParam / SignName)
    // 2. 按阿里云 API v3 签名规范 (HMAC-SHA1) 计算签名
    // 3. POST https://dysmsapi.aliyuncs.com/
    // 4. 解析响应 (Code='OK' 返 true, 其他返 false)
    // 5. 错误处理 (限流/余额不足/模板错误 走 swallowError)
    // 6. timeout 5s, 重试 3 次 (指数退避)
    throw UnimplementedError(
      'AliyunSmsProvider 真接 R55+ TODO — 需要 accessKey/secret/signName'
      '/templateCode + 法务过审模板。详见 docs/SMS_PROVIDERS.md §1',
    );
  }
  ```

### 1.3 阿里云 API v3 签名伪代码

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String _signRequest(Map<String, String> params, String accessKeySecret) {
  // 1. 排序参数 (key 字典序)
  final sortedKeys = params.keys.toList()..sort();
  // 2. 构造待签名字符串
  final queryString = sortedKeys
      .map((k) => '$k=${Uri.encodeComponent(params[k]!)}')
      .join('&');
  // 3. 构造规范化请求
  final stringToSign = 'GET&${Uri.encodeComponent('/')}'
      '&${Uri.encodeComponent(queryString)}';
  // 4. HMAC-SHA1 签名
  final key = utf8.encode(accessKeySecret + '&');
  final hmac = Hmac(sha1, key);
  final digest = hmac.convert(utf8.encode(stringToSign));
  return base64Encode(digest.bytes);
}
```

### 1.4 模板审核技巧

- 模板**明确用途** (用户主动设置的关怀通知, 非营销)
- 模板**避免敏感词** ("药" "病" "自杀" 等可能被 AI 审核驳回)
- 备选措辞:
  - "我是 ${userName}，已 ${days} 天没打卡 App, 请方便时提醒我" (避用"药")
  - "您好, ${userName} 设置您为紧急联系人, 已 ${days} 天没打卡, 烦请提醒" (客服话术)
- 模板驳回后**重新提交不同措辞**, 平均需 2-3 次

### 1.5 上线 checklist

- [ ] 阿里云账号实名认证 (法人 + 营业执照)
- [ ] 申请短信签名 "慢病管家" 通过
- [ ] 申请短信模板通过 (至少 1 条关怀 + 1 条失联)
- [ ] AccessKey 申请 + 保存到 `.env` (`ALIYUN_ACCESS_KEY_ID` /
      `ALIYUN_ACCESS_KEY_SECRET` / `ALIYUN_SIGN_NAME` /
      `ALIYUN_TEMPLATE_CODE_CARE` / `ALIYUN_TEMPLATE_CODE_LOST`)
- [ ] `AliyunSmsProvider.send()` 真实实现
- [ ] 安全: AccessKey 存 `flutter_secure_storage`, 不进 git
- [ ] 单元测试: mock dio 响应 OK + fail
- [ ] 集成测试: 真实发送 1 条 SMS 到自己手机验证
- [ ] release 模式启动检测 (现有 `validateForRelease` 已 OK)
- [ ] 错误处理: 限流 / 余额不足 / 模板错误 走 `swallowError`
- [ ] 监控: 每日发送成功率 / 平均延迟 / 失败原因分布

**估总:** R55 实施 1-2 天 + 阿里云审核 2-4 周 = 完整 SMS 通道 1 月后上线。

---

## 2. 腾讯云短信 (Tencent SMS) - 备选

### 2.1 接入

- 网址: https://cloud.tencent.com/product/sms
- 流程同阿里云, 但审核周期可能更短 (1-2 周)
- 优势: 微信生态集成 (公众号 / 小程序推送)

### 2.2 集成

- 同样用 dio + HMAC-SHA256 (腾讯云 API v3 用 SHA256, 不是 SHA1)
- 单独 `TencentSmsProvider` 实现 `SmsProvider` 接口
- `SmsService` 加腾讯云 provider 路由

### 2.3 适用

- 阿里云模板审核失败时备选
- 微信用户量大时优势 (公众号触达)

---

## 3. Twilio - 海外主选

### 3.1 注册

- 网址: https://www.twilio.com/
- 步骤: 注册账号 (1 天, 信用卡验证) → 创建 Messaging Service
  → 申请海外号码 +1 / +44 / +852 等
- 优势: 即时开通, 无签名/模板审核
- 劣势: 贵 ($0.0079/条), 国内号码不支持 (PIPL 跨境问题)

### 3.2 集成

- `pubspec.yaml`:
  ```yaml
  dependencies:
    twilio_flutter: ^0.3.0
  ```
- `TwilioSmsProvider` 实现 `SmsProvider` 接口
- 路由: 中国大陆号码 → AliyunSms, 海外号码 → Twilio

### 3.3 跨境合规 (PIPL §38)

- Twilio 在境内无主体, 需通过境内子公司或代理签标准合同
- 实际: 找一家国内 Twilio 代理 (如 容联·云通讯) 签合同 + 备案
- 估时: 1-2 月

---

## 4. MockSmsProvider (现有, dev 用)

不改动, 保留作为 dev / test provider。
`SmsService.validateForRelease` 已保证 release 模式不会用 mock。

---

## 5. 上线 checklist 总览

- [ ] 阿里云账号 + 短信签名 + 模板审核 (R55 法务 + 业务负责)
- [ ] AliyunSmsProvider.send() 真实实现 (R55 PR, 1-2 天)
- [ ] 单元 + 集成测试 (R55 PR)
- [ ] Twilio 代理签标准合同 + 备案 (PIPL §38)
- [ ] TwilioSmsProvider 真接 (R55+ PR)
- [ ] SmsService 增加号码路由 (+86 → 阿里云, 海外 → Twilio)
- [ ] release 模式启动检测 (现有 `validateForRelease` 已 OK)
- [ ] 监控 + 告警 (每日发送成功率)
- [ ] 文档更新 (CHANGELOG + README + DEPLOYMENT 阶段 8)

**估总:** 阿里云 + Twilio 全接通 = 1-3 月 (法务 + 审核是瓶颈)。

---

## 已知风险

- 阿里云模板审核**驳回率高** (内容涉及"病"/"药"等敏感词)
- Twilio 国内号码不支持, 必须接国内 provider
- 跨境 SMS 需 PIPL §38 标准合同备案 (1-2 月)
- AccessKey 泄露 = 短信费用被盗刷 (安全: 存 SecureStorage)
- SMS 限流 (阿里云默认 100/秒) = 100 个联系人同时失联通知
  会触发限流, 需申请提额或重试机制
