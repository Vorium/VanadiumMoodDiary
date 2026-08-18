// setup_legal_dialog.dart — 法律文档查看对话框
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// ✅ v0.27 round 83 (R83) 律师审核 ⚠️ Q10b 修复:
//    在 md 文档展示区域底部加"本地区心理危机干预热线"section (5 条:
//    大陆 2 + 港澳台 3), 引用 12 个 crisisHotlineCn/Tw/Hk/Mo
//    {Label,Number,Desc} 3-tuple key。走 i18n 渲染让 zh / en / zh_Hant
//    都显示对应地区文案,与 user_agreement.md §5 + sensitive_data_consent.md §8
//    表格完全同步。R83 之前 12 个 crisisHotline* key 是 orphan (R56e 后
//    守护严格),所以加这个 section 一举两得:补全律师要求的危机热线 +
//    消除 orphan ARB key。
//
// 1.1.0 round 4 (emotion-first refactor): 紧急联系人 SMS 同意升级注释整摘
// (失联通信业务暂停定版), 热线 section 保留。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:chroniccare_theme/chroniccare_theme.dart';
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
      case 'medical_disclaimer':
        return l10n.settingsDisclaimer;
      default:
        return name;
    }
  }

  /// v0.27 R83 (Q10b): 在 md 文档展示区域底部追加 5 条本地区心理危机干预热线
  /// (大陆 2 + 港澳台 3),与 user_agreement.md §5 / sensitive_data_consent.md §8
  /// 表格完全同步。走 i18n 让 zh / en / zh_Hant 各自显示。
  Widget _crisisHotlineSection(
    BuildContext context,
    AppLocalizations l10n,
    Color textColor,
  ) {
    final lines = <String>[
      l10n.crisisHotlineCnLabel,
      '${l10n.crisisHotlineCnNumber} (${l10n.crisisHotlineCnDesc})',
      // R97-P1-7 (2026-08-07): 补北京心理危机研究与干预中心热线。
      //
      // 修前 bug (spzh 审计): 顶部注释写"5 条 (大陆 2 + 港澳台 3)", 实际
      // 只渲染 4 条 (大陆 1 + 港澳台 3), 漏 crisisHotlineCnBeijing。
      // 与 user_agreement.md §5 表格 (5 条) 不同步, 同时让
      // crisisHotlineCnBeijing* 3 个 ARB key 成为 orphan (触发
      // check_orphan_arb_keys.py 守门员告警)。
      l10n.crisisHotlineCnBeijingLabel,
      '${l10n.crisisHotlineCnBeijingNumber} (${l10n.crisisHotlineCnBeijingDesc})',
      l10n.crisisHotlineTwLabel,
      '${l10n.crisisHotlineTwNumber} (${l10n.crisisHotlineTwDesc})',
      l10n.crisisHotlineHkLabel,
      '${l10n.crisisHotlineHkNumber} (${l10n.crisisHotlineHkDesc})',
      l10n.crisisHotlineMoLabel,
      '${l10n.crisisHotlineMoNumber} (${l10n.crisisHotlineMoDesc})',
    ];
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spacingLg),
      padding: AppTokens.edgeInsetsMd,
      decoration: BoxDecoration(
        color: AppTokens.surfaceColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.dividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.setupCrisisHotlineTitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.primaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          for (final line in lines)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTokens.spacingXxxs),
              child: Text(
                '• $line',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: textColor,
                  height: AppTokens.lineHeightNormal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = AppTokens.textPrimaryColor(context);
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snap.data!,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      height: AppTokens.lineHeightNormal,
                      color: textColor,
                    ),
                  ),
                  _crisisHotlineSection(context, l10n, textColor),
                ],
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
