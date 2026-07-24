// setup_legal_dialog.dart — 法律文档查看对话框
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// v0.23 round 41 (spzh P3-31 TODO): 架构债务 — 紧急联系人单独同意 (PIPL §13/§23)
//
// 当前 setup 流程只勾选"我已告知上述联系人", 联系人本人**没**法律地位。
// 严格 PIPL 合规需让联系人通过短信回复 "Y" 才算单独同意 (PIPL §13 单独同意 +
// §23 第三方 PII 告知)。
//
// 完整实施步骤 (后续 round):
//   1. setup 添加联系人时, 给每个联系人发"同意接收失联通知"短信 (模板话术)
//   2. 联系人回复 "Y" → 标记为 confirmed=true
//   3. SafetyWatchService 只在所有联系人都 confirmed 时才发失联通知
//   4. UI 加 "待确认 / 已确认" 状态显示
//   5. 30 天未回复 → 提醒用户再次发送确认
//
// 当前依赖:
//   - 真实短信 provider (AliyunSmsProvider.send() 未实现, 走 AliyunSmsProvider
//     真实接入后做)
//   - 联系人状态字段 (UserProfile 或 ContactEntity 加 consentConfirmedAt)
//
// 当前状态: TODO 留注释, 真实合规需待 SMS 接入 (P0-1 fix 长期挂)
// 优先级 P3 M 项 (4-8h)。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 显示法律 markdown 文档的对话框
Future<void> showLegalDocument(BuildContext context, String name) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => LegalDocumentDialog(name: name),
  );
}

class LegalDocumentDialog extends StatelessWidget {
  final String name;
  const LegalDocumentDialog({super.key, required this.name});

  String _title(AppLocalizations l10n) {
    switch (name) {
      case 'user_agreement':
        return l10n.setupLegalUserAgreement;
      case 'privacy_policy':
        return l10n.setupLegalPrivacyPolicy;
      case 'sensitive_data_consent':
        return l10n.setupLegalSensitiveData;
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_title(l10n)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder<String>(
          future: rootBundle.loadString('assets/legal/$name.md'),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingSkeleton.fullScreen();
            }
            if (snap.hasError || !snap.hasData) {
              return Center(
                child: Text(l10n.setupLegalLoadFailed),
              );
            }
            return SingleChildScrollView(
              child: Text(
                snap.data!,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  height: AppTokens.lineHeightNormal,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonClose),
        ),
      ],
    );
  }
}
