// setup_legal_dialog.dart — 法律文档查看对话框
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
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
                  height: 1.5,
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
