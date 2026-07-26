# Push Provider 接入指南 (v0.25 R55 增补)

> **背景:** spzh 视角 P0 #5: 之前 release 模式仅依赖 `flutter_local_
> notifications 17.x`,在国产 Android ROM (MIUI / EMUI / ColorOS /
> OriginOS / Flyme) 上推送送达率 < 70%(ROM 静默杀后台通知 + 限制
> 自启 + 禁用精确闹钟)。**5 厂商 push 通道 0 接** = 精神心理患者
> 失联通知失效 = 法律责任。
>
> **本文档提供:** 5 厂商 push SDK 接入详细 plan + 估时 + 步骤 +
> 上线 checklist。R55 范围**仅**列 plan,真实 SDK 接入需 1-2 月
> 厂商审核。

---

## 总览

| # | 厂商 | SDK 名称 | 适用 ROM | 审核周期 | 送达率提升 |
|---|------|----------|----------|----------|-----------|
| 1 | **小米推送 (Mi Push)** | `mipush: ^5.0.0` | MIUI / HyperOS | 1 周 | MIUI 90% → 99% |
| 2 | **华为 PUSH (HMS Core)** | `huawei_push: ^6.11.0` | EMUI / HarmonyOS | 2 周 | EMUI 80% → 99% |
| 3 | **OPPO PUSH (Pusher 2.0)** | `oppo_push: ^3.0.0` | ColorOS | 2 周 | OPPO 75% → 99% |
| 4 | **vivo PUSH** | `vivo_push: ^2.0.0` | OriginOS | 1 周 | vivo 75% → 99% |
| 5 | **魅族 PUSH (Flyme Push)** | `mzpush: ^4.0.0` | Flyme | 1 周 | Flyme 70% → 99% |
| + | **FCM (Firebase)** | `firebase_messaging: ^14.0.0` | 原生 Android (海外) | 即时 | 海外 95%+ |

**总估时:** 1-2 月 (5 厂商审核并行 + FCM 即时)。
**总 Android 覆盖:** 95%+ (除极小众定制 ROM)。

---

## 架构 (类比 SmsProvider)

`NotificationService` 当前直接用 `flutter_local_notifications`。改造
为抽象 `PushProvider` 接口,按设备厂商路由:

```dart
// lib/core/data/services/push_provider.dart (R55 计划新增)
abstract class PushProvider {
  String get name;                       // "mi" / "huawei" / "oppo" / ...
  String get sdkVersion;                 // SDK 版本
  bool get isAvailable;                  // 当前设备是否支持 (e.g. 不是 MIUI 返 false)
  bool get isProductionReady;            // release 必须用真实 SDK
  
  /// 初始化 (绑定 AppID/AppKey)
  Future<void> init();
  
  /// 注册设备 token (用户唯一标识)
  Future<String> registerDeviceToken();
  
  /// 订阅 tag (e.g. medication_id=42, 让 vendor 推送给特定用户)
  Future<void> subscribeTag(String tag);
  
  /// 发送透传消息 (数据消息, 不显示通知)
  Future<bool> sendTransparentMessage({
    required String payload,
    Map<String, String>? extra,
  });
}
```

**路由逻辑** (`NotificationService.routeToProvider`):
1. iOS → APNs (`flutter_local_notifications`)
2. Android 海外 / 原生 → FCM + 兜底 `flutter_local_notifications`
3. Android 国产 ROM → 检测厂商 SDK 路由:
   - MIUI 设备 → MiPushProvider
   - EMUI 设备 → HuaweiPushProvider
   - ColorOS 设备 → OppoPushProvider
   - OriginOS 设备 → VivoPushProvider
   - Flyme 设备 → MzPushProvider
   - 其他 → 兜底 `flutter_local_notifications`

**改造点:**
- `NotificationService.init()` 加 `PushRouter.detect()` 调用
- 5 厂商 `PushProvider` 实现类 (R55 后) + `PushRouter` 工厂
- 通知 payload 格式不变, 5 厂商 SDK 收 payload 后用 `flutter_local_notifications` 显示 UI

---

## 1. 小米推送 (Mi Push) - 优先级最高 (MIUI 国内份额最大)

### 1.1 注册
- 网址: https://dev.mi.com/console/appservice/push.html
- 步骤: 注册小米开发者账号 (实名认证 1-3 天) → 创建应用 → 获得
  - `AppID` (32 位字符串)
  - `AppKey` (32 位字符串)
  - `AppSecret` (16 位字符串)

### 1.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    mipush: ^5.0.0  # 或 flutter_mi_push
  ```
- `android/app/build.gradle`:
  ```gradle
  android {
    defaultConfig {
      manifestPlaceholders = [
        MI_PUSH_APPID: "YOUR_APPID",
        MI_PUSH_APPKEY: "YOUR_APPKEY",
      ]
    }
  }
  ```
- `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <service
      android:name="com.xiaomi.push.service.XMPushService"
      android:enabled="true"
      android:process=":pushservice" />
  <receiver
      android:name="com.xiaomi.push.service.XMPushService$MessageHandleService"
      android:enabled="true" />
  <service
      android:name="com.xiaomi.push.service.XMJobService"
      android:enabled="true"
      android:exported="false"
      android:permission="android.permission.BIND_JOB_SERVICE"
      android:process=":pushservice" />
  ```
- `MiPushProvider` 实现 `PushProvider` 接口, `init()` 调
  `MiPushClient.registerPush(context, appId, appKey)` 拿 regId。

### 1.3 审核
- 1 周 (开发者认证 + 应用审核)

### 1.4 测试
- 杀掉 app, 触发失联通知 → MIUI 设备能收到 push
- 推送送达率验证: 100 次推送, 95+ 到达

---

## 2. 华为 PUSH (HMS Core Push)

### 2.1 注册
- 网址: https://developer.huawei.com/consumer/cn/hms/huawei-pushkit
- 实名认证 (1-3 天) → 创建应用 → 获得:
  - `App ID` (HMS Core)
  - `App Secret`

### 2.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    huawei_push: ^6.11.0
  ```
- `android/app/build.gradle`:
  ```gradle
  apply plugin: 'com.huawei.agconnect'
  dependencies {
    implementation 'com.huawei.hms:push:6.11.0+300'
  }
  ```
- 配 `agconnect-services.json` (从华为开发者中心下载)
- `HuaweiPushProvider` 实现 `PushProvider` 接口

### 2.3 审核
- 2 周 (华为应用市场强制要求接入 HMS Core)

### 2.4 HarmonyOS 兼容
- 同一 SDK 自动兼容 HarmonyOS 2.0+, 无需额外集成

---

## 3. OPPO PUSH (Pusher 2.0)

### 3.1 注册
- 网址: https://push.oppo.com/
- 步骤: 实名 + 创建应用 → 获得:
  - `AppKey`
  - `AppSecret`
  - `MasterSecret`

### 3.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    oppo_push: ^3.0.0
  ```
- `OppoPushProvider` 实现 `PushProvider` 接口

### 3.3 审核
- 2 周

---

## 4. vivo PUSH

### 4.1 注册
- 网址: https://dev.vivo.com.cn/push
- 实名 + 创建应用 → 获得 `AppKey` / `AppSecret`

### 4.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    vivo_push: ^2.0.0
  ```
- `VivoPushProvider` 实现

### 4.3 审核
- 1 周

---

## 5. 魅族 PUSH (Flyme Push)

### 5.1 注册
- 网址: https://open.flyme.cn/
- 实名 + 创建应用 → 获得 `AppId` / `AppKey` / `AppSecret`

### 5.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    mzpush: ^4.0.0
  ```
- `MzPushProvider` 实现

### 5.3 审核
- 1 周

---

## 6. 兜底: FCM (Firebase Cloud Messaging)

### 6.1 注册
- 网址: https://console.firebase.google.com/
- 创建项目 → 添加 Android app → 下载 `google-services.json`

### 6.2 集成
- `pubspec.yaml`:
  ```yaml
  dependencies:
    firebase_core: ^2.27.0
    firebase_messaging: ^14.7.19
  ```
- `android/app/build.gradle`:
  ```gradle
  apply plugin: 'com.google.gms.google-services'
  ```
- 配 `google-services.json` 到 `android/app/`
- `FcmPushProvider` 实现

### 6.3 适用
- 海外用户 (Google Play 必装)
- 国内 Android 设备 (非国产 ROM) 也走 FCM

---

## 上线 checklist (R55 实施时)

- [ ] 注册 5 厂商开发者账号 (法务 + 实名认证 1-2 周)
- [ ] pubspec 加 5 厂商依赖 (R55 PR)
- [ ] AndroidManifest 加 5 厂商 service 配置 (R55 PR)
- [ ] 5 个 `PushProvider` 实现类 (R55 PR, 每类 ~50-100 行)
- [ ] `PushRouter` 工厂类按设备型号路由 (R55 PR)
- [ ] `NotificationService.init()` 集成 `PushRouter` (R55 PR)
- [ ] `PushProvider` 单元测试 + widget test (R55 PR)
- [ ] release 模式启动检测 (类似 `SmsService.validateForRelease`)
- [ ] 5 厂商审核 1-2 月
- [ ] 集成测试: 5 厂商各 100 次推送送达率 ≥ 95%

**估总:** R55 实施 4-6h + 审核 1-2 月 = 完整 push 通道 1-2 月后上线。

---

## 已知风险

- 5 厂商 push SDK 各自独立, bug fix 周期不同
- 用户跨厂商 (e.g. 换手机) 需重新 registerDeviceToken
- 推送 payload 跨厂商格式差异 (需在 `NotificationService` 统一)
- 厂商 SDK 升级可能 break compat (R55+ 需持续跟进)
