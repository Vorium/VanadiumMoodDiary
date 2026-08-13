// v0.32 R112 (AR-16): SafetyCheckResult l10n 显示 (presentation extension)
//
// 背景: `SafetyCheckResult.displayMessageL10n(AppLocalizations)` 原在 data 层
// `safety_watch_service.dart` — data 直接 import `package:chroniccare/l10n/`
// (生成 ARB, 传递 import flutter/widgets), 4 层架构 data→l10n 循环 (AR-16)。
// 移到 presentation extension, caller 语法不变:
// `result.displayMessageL10n(l10n)` (需 import 本文件)。
//
// 旧方法语义 (v0.27 R61 引入, R100 删掉返 key 的旧 getter) 保持不变:
// - caller (UI widget) 传 l10n 拿 i18n 字符串; 编译期强制走本方法
//   (旧 `displayMessage` 返 key 字符串的 getter 已删, 防未来 caller
//   误用显示裸 key)。
// - 8 个 kind 全部覆盖:
//   disabled / ok / noData / alertedToday / dndSuppressed / noContacts
//   alerted (3 态: ok / mocked / failed) / error
import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// [SafetyCheckResult] 的 UI 可读文案 (presentation 层 l10n 解析)
extension SafetyCheckResultL10n on SafetyCheckResult {
  String displayMessageL10n(AppLocalizations l10n) {
    switch (kind) {
      case SafetyCheckKind.disabled:
        return l10n.safetyCheckResultDisabled;
      case SafetyCheckKind.ok:
        return l10n.safetyCheckResultOk(daysSinceLast ?? 0);
      case SafetyCheckKind.noData:
        return l10n.safetyCheckResultNoData;
      case SafetyCheckKind.alertedToday:
        return l10n.safetyCheckResultAlertedToday(daysSinceLast ?? 0);
      case SafetyCheckKind.dndSuppressed:
        return l10n.safetyCheckResultDndSuppressed;
      case SafetyCheckKind.noContacts:
        return l10n.safetyCheckResultNoContacts;
      case SafetyCheckKind.alerted:
        // 3 态: ok > mock > fail (跟 NotificationService._resolveSafetyAlertBody 一致)
        if (contactsMocked > 0 && contactsNotified == 0) {
          return l10n.safetyCheckResultAlertedMocked(contactsMocked);
        }
        return l10n.safetyCheckResultAlerted(
          daysSinceLast ?? 0,
          contactsNotified,
          contactsFailed,
        );
      case SafetyCheckKind.error:
        return l10n.safetyCheckResultError(errorMessage ?? '');
    }
  }
}
