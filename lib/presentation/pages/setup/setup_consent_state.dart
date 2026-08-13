// setup_consent_state.dart — setup Step 0 法律同意 5 勾选状态 (AR-20 批2a)
//
// 拆自 setup_page_state.dart (503L god class, 职责 3: 4 步导航 + consent
// 编排 + 提交): 5 个 consent bool 字段 + R104 一键全部同意内联逻辑抽成
// 纯状态类, 0 Flutter 0 Riverpod 依赖, 直接单测。
//
// 5 勾选 (v0.31.1 R103 加医学免责声明后):
// - userAgreement / privacyPolicy / sensitiveData (PIPL 基础同意)
// - ageAttestation (v0.27 R83, 年龄严正声明)
// - medicalDisclaimer (R103, 医学免责声明)
//
// 用法 (SetupPageState):
// ```dart
// final _consent = SetupConsentState();
// onConsentUserAgreementChanged: (v) =>
//     setState(() => _consent.userAgreement = v),
// onAgreeAll: () => setState(_consent.agreeAll),
// ```
class SetupConsentState {
  bool userAgreement = false;
  bool privacyPolicy = false;
  bool sensitiveData = false;
  // v0.27 R83: 第 4 个勾选 — 年龄严正声明
  bool ageAttestation = false;
  // R103 (P0-9): 第 5 个勾选 — 医学免责声明
  bool medicalDisclaimer = false;

  /// R104: 一键全部同意 (5 个全置 true)
  void agreeAll() {
    userAgreement = true;
    privacyPolicy = true;
    sensitiveData = true;
    ageAttestation = true;
    medicalDisclaimer = true;
  }

  /// 5 勾选全 true 才允许进入下一步 (跟 SetupStepConsent allChecked 1:1)
  bool get allAgreed =>
      userAgreement &&
      privacyPolicy &&
      sensitiveData &&
      ageAttestation &&
      medicalDisclaimer;
}
