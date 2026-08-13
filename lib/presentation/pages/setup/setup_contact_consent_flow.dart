// setup_contact_consent_flow.dart — 联系人同意弹窗循环 (AR-20 批2a)
//
// 拆自 setup_page_state.dart _finishSetup 内的 PIPL §13 单独同意循环
// (v0.27 round 68 CC-1): 对每个填了手机号的联系人弹 ConsentDialog,
// 只有同意的才入 contactList (跟 contactConsents 等长)。用户拒绝 →
// 弹提示 + 返回 null (终止 setup, PIPL §13 严同意, 部分填也不行)。
//
// 跟主路径 contacts_list_widget 走同一 ConsentDialog 集中器
// (v0.27 round 82: placeholders map 抽象)。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/phone_validator.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';

/// 联系人同意收集结果 (contactList 与 contactConsents 等长, R68 CC-1)
class SetupContactConsentResult {
  final List<({String name, String phone, int sortOrder})> contactList;
  final List<ConsentArtifact> contactConsents;

  const SetupContactConsentResult({
    required this.contactList,
    required this.contactConsents,
  });
}

/// 联系人同意弹窗循环 (PIPL §13)
class SetupContactConsentFlow {
  SetupContactConsentFlow._();

  /// 循环弹同意 dialog 收集联系人 + 同意留痕
  ///
  /// 返回 null = 用户拒绝某联系人 (终止 setup) 或 context 中途 unmount,
  /// caller 应终止提交。手机号留空 → 跳过 (联系人可选, 2026-07-31)。
  static Future<SetupContactConsentResult?> collect({
    required BuildContext context,
    required List<TextEditingController> nameControllers,
    required List<TextEditingController> phoneControllers,
  }) async {
    final contactList = <({String name, String phone, int sortOrder})>[];
    final contactConsents = <ConsentArtifact>[];
    for (int i = 0; i < phoneControllers.length; i++) {
      final phone = phoneControllers[i].text.trim();
      if (phone.isEmpty) continue;
      // PIPL §13: 弹同意 dialog, 用户拒绝 → 不写该联系人, 终止 setup
      // v0.27 round 82: 改用 placeholders map (R82 抽象化 ConsentDialog)
      final consent = await ConsentDialog.show(
        context,
        kind: ConsentKind.emergencyContactSharing,
        placeholders: const {
          'thresholdDays': 2, // 跟 care_strategies.secondDayMissed 一致
        },
      );
      if (consent == null) {
        // 用户拒绝: 终止整个 setup (PIPL §13 严同意, 部分填也不行)
        if (context.mounted) {
          AppSnackBar.showInfo(
            context,
            AppLocalizations.of(context).setupConsentRejected,
          );
        }
        return null;
      }
      // v0.27 R73 (重构-1): analyzer 期望 await 后用 context 之前有 mounted
      // guard (R17+R56b 已知模式)。
      if (!context.mounted) return null;
      final normalized = PhoneValidator.normalize(phone) ?? phone;
      final name = nameControllers[i].text.trim().isEmpty
          ? AppLocalizations.of(context).setupContactFallbackName(i + 1)
          : nameControllers[i].text.trim();
      contactList.add((name: name, phone: normalized, sortOrder: i));
      contactConsents.add(consent);
    }
    return SetupContactConsentResult(
      contactList: contactList,
      contactConsents: contactConsents,
    );
  }
}
