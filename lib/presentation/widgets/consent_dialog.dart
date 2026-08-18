import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// v0.27 round 62 (P0-2 修复): 共享 ConsentDialog 组件
///
/// PIPL §13 单独同意要求处理敏感个人信息时**显式**告知用户 + 取得同意。
///
/// v0.27 round 82: 抽象化支持多个 [ConsentKind]
/// 修复前 `show()` 写死单一 kind + `thresholdDays: int` 必传参数, 只能支持
/// 加联系人场景。修复后用 `placeholders: Map<String, Object>?` 替代
/// `thresholdDays`, 内部按 `kind` 选不同渲染模板:
/// - [ConsentKind.dataExport] → 用新 `dataExportConsent*` 模板
///   (placeholders 需要 `purpose` / `dataCategories` / `retention`)
/// - [ConsentKind.vent] / [ConsentKind.analytics] →
///   fallback 模板 (PIPL §14 撤回 toggle 目前不弹 dialog, 留接口给 v1.0),
///   round 6d 起走中性 `consentDialogGeneric*` 文案 (不再复用 §13 联系人措辞)
///
/// 1.1.0 round 4 (emotion-first refactor): emergencyContactSharing / safety
/// 2 分支整摘 (失联通信业务暂停定版, 无 caller)。
///
/// 用法 (dataExport 场景, R82 加):
/// ```dart
/// final consent = await ConsentDialog.show(
///   context,
///   kind: ConsentKind.dataExport,
///   placeholders: const {
///     'purpose': '本地备份',
///     'dataCategories': '用药 / 打卡 / 情绪',
///     'retention': '剪贴板 + 用户自行保存',
///   },
/// );
/// if (consent == null) return; // 用户拒绝
/// await ref.read(legalConsentStoreProvider).recordDataExportConsent(consent);
/// ```
///
/// 设计: 复用 showDialog + StatefulBuilder 模式, 不引入新的 dialog 框架。
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
    Map<String, Object>? placeholders,
  }) async {
    final l10n = AppLocalizations.of(context);
    // v0.27 round 77 (R76-N6 修): await 之前先读 provider, 避免
    // `use_build_context_synchronously` 警告 (R56 memory: 同一 context
    // 在 await 前后用 analyzer 不认)。
    final container = ProviderScope.containerOf(context);

    // R82: 按 kind 选模板
    final template = _resolveTemplate(l10n, kind, placeholders);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 必须显式选择, 防止误点背景关闭
      builder: (ctx) => AlertDialog(
        title: Text(template.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              template.body,
              const SizedBox(height: AppTokens.spacingMd),
              // 版本号留痕 (PIPL §13 + §17)
              Text(
                template.version,
                // P3-CLEAN-13: 用 builder ctx 而非外层 context — caller
                // dispose 而 dialog 仍挂时 rebuild 用 defunct element 会崩
                style: AppTokens.textStyleCaptionHint(ctx),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(template.rejectLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(template.agreeLabel),
          ),
        ],
      ),
    );

    if (result != true) return null;
    // v0.27 round 77 (R76-N6 修): 跟 setup_page 同步从 legalVersionProvider 读
    // (启动时算的 legal version), 替代 hardcode 'v0.27-2026-08-01'。
    final version = container.read(legalVersionProvider);
    return ConsentArtifact(
      kind: kind,
      grantedAt: DateTime.now(),
      grantedBy: 'user', // 未来支持代理人代同意时扩展
      version: version,
    );
  }

  /// R82: 按 kind + placeholders 选模板
  static _ConsentTemplate _resolveTemplate(
    AppLocalizations l10n,
    ConsentKind kind,
    Map<String, Object>? p,
  ) {
    switch (kind) {
      case ConsentKind.dataExport:
        // R82: 3 个 placeholder (purpose / dataCategories / retention)
        final purpose = (p?['purpose'] as String?) ?? '';
        final dataCategories = (p?['dataCategories'] as String?) ?? '';
        final retention = (p?['retention'] as String?) ?? '';
        return _ConsentTemplate(
          title: l10n.dataExportConsentTitle,
          body: Text(
            l10n.dataExportConsentBody(
              purpose,
              dataCategories,
              retention,
            ),
          ),
          agreeLabel: l10n.dataExportConsentConfirm,
          // 复用 contactConsentReject (中英繁 "暂不同意" / "Decline for now"
          // / "暫不同意" 跨场景通用)
          rejectLabel: l10n.contactConsentReject,
          version: l10n.dataExportConsentVersion,
        );
      case ConsentKind.vent:
      case ConsentKind.analytics:
        // Fallback: §14 撤回 toggle 在 legal_page 走 LegalConsentStore.withdraw,
        // 目前不弹 ConsentDialog。1.1.0 round 4b 后仅 vent / analytics
        // 可能走此路径 (safety / emergencyContactSharing 已随外联整摘)。
        // round 6d: 标题/按钮改中性 consentDialogGeneric* 文案, 不再复用
        // §13 联系人措辞 (contactConsentTitle/Agree/Version 已删)。
        return _ConsentTemplate(
          title: l10n.consentDialogGenericTitle,
          body: Text(_fallbackBodyFor(kind, l10n)),
          agreeLabel: l10n.consentDialogGenericAgree,
          rejectLabel: l10n.consentDialogGenericReject,
          version: l10n.consentDialogGenericVersion,
        );
    }
  }

  /// §14 撤回场景 fallback body (R82: 现阶段不弹, 留接口)
  ///
  /// R100 (P1#9): 3 段法律文案走 ARB (consentWithdraw*Body)
  static String _fallbackBodyFor(ConsentKind kind, AppLocalizations l10n) {
    switch (kind) {
      case ConsentKind.vent:
        return l10n.consentWithdrawVentBody;
      case ConsentKind.analytics:
        return l10n.consentWithdrawAnalyticsBody;
      default:
        return '';
    }
  }
}

/// R82: 内部模板小类, 让 _resolveTemplate 全 switch 时不重复
/// build AlertDialog 代码。
class _ConsentTemplate {
  final String title;
  final Widget body;
  final String agreeLabel;
  final String rejectLabel;
  final String version;
  const _ConsentTemplate({
    required this.title,
    required this.body,
    required this.agreeLabel,
    required this.rejectLabel,
    required this.version,
  });
}
