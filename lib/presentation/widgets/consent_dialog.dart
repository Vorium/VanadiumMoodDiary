import 'package:flutter/material.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// v0.27 round 62 (P0-2 修复): 共享 ConsentDialog 组件
///
/// PIPL §13 单独同意要求处理敏感个人信息时**显式**告知用户 + 取得同意。
/// 精神心理患者 App 加紧急联系人场景下, 必须确认用户已告知联系人 "App
/// 会在我失联时给你发短信" 后才能保存。
///
/// 用法:
/// ```dart
/// final consent = await ConsentDialog.show(
///   context,
///   kind: ConsentKind.emergencyContactSharing,
///   thresholdDays: 2,
/// );
/// if (consent == null) {
///   // 用户点了"暂不同意"
///   return;
/// }
/// await ref.read(contactRepositoryProvider).add(
///   name: ...,
///   phone: ...,
///   consentArtifact: consent,
/// );
/// ```
///
/// 设计: 复用 showDialog + StatefulBuilder 模式 (跟 contacts_list_widget 的
/// _showAddContactDialog 一致), 不引入新的 dialog 框架。
class ConsentDialog {
  ConsentDialog._();

  /// 显示知情同意 dialog
  ///
  /// 返回:
  /// - `ConsentArtifact` — 用户同意, 携带同意时间 / 主体 / 版本
  /// - `null` — 用户拒绝 (点了"暂不同意"或返回键)
  static Future<ConsentArtifact?> show(
    BuildContext context, {
    required ConsentKind kind,
    required int thresholdDays,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 必须显式选择, 防止误点背景关闭
      builder: (ctx) => AlertDialog(
        title: Text(l10n.contactConsentTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.contactConsentBody(thresholdDays)),
              const SizedBox(height: AppTokens.spacingMd),
              // 版本号留痕 (PIPL §13 + §17)
              Text(
                l10n.contactConsentVersion,
                style: AppTokens.textStyleCaptionHint(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.contactConsentReject),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.contactConsentAgree),
          ),
        ],
      ),
    );

    if (result != true) return null;
    return ConsentArtifact(
      kind: kind,
      grantedAt: DateTime.now(),
      grantedBy: 'user', // 未来支持代理人代同意时扩展
      version: 'v1',
    );
  }
}
