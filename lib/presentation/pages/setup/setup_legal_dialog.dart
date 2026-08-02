// setup_legal_dialog.dart — 法律文档查看对话框
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// ✅ v0.27 round 58 (P0 #3 软实施): 紧急联系人单独同意文档化
// ✅ v0.27 round 62 (P0-2 修复): 升级到 ConsentDialog 强制流程
//    - 修复前: setup 流程只勾选"我已告知上述联系人", 联系人本人**没**法律地位。
//      add(contact) 0 consent 流程 → PIPL §13 违规。
//    - 修复后: 主页 contacts_list_widget 的 _showAddContactDialog 在 add()
//      前**必须**先弹 ConsentDialog (`lib/presentation/widgets/consent_dialog.dart`)
//      用户确认"已告知并取得同意"才能 add。ConsentArtifact 走 piiSafeLog
//      留痕 (grantedAt / version)。
//    - 简化版: 用户**担保**已告知联系人 (本人确认), 不强制联系人独立确认。
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
// v1.0 严格 PIPL §13 + §23 升级 (待 A-01 AliyunSmsProvider 真接 + 模板过审):
//   1. setup 添加联系人时, 给每个联系人发"同意接收失联通知"短信 (模板话术)
//   2. 联系人回复 "Y" → 标记为 confirmed=true
//   3. SafetyWatchService 只在所有联系人都 confirmed 时才发失联通知
//   4. UI 加 "待确认 / 已确认" 状态显示
//   5. 30 天未回复 → 提醒用户再次发送确认
//
// 当前依赖 (R58 未达):
//   - 真实短信 provider (AliyunSmsProvider.send() 未实现, 走 AliyunSmsProvider
//     真实接入后做) — 卡 A-01 xlarge
//   - 联系人状态字段 (UserProfile 或 ContactEntity 加 consentConfirmedAt)
//
// 当前状态: ✅ R58 文档化 (软实施: 用户主动告知, 联系人主动确认留 A-01)
// 优先级: 卡 A-01 (80-120h), 当前 P3 保留。
// 守门员: scripts/check_legal_consent.py 走 EXEMPT_LINE_RE (✅) 豁免。
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
      l10n.crisisHotlineTwLabel,
      '${l10n.crisisHotlineTwNumber} (${l10n.crisisHotlineTwDesc})',
      l10n.crisisHotlineHkLabel,
      '${l10n.crisisHotlineHkNumber} (${l10n.crisisHotlineHkDesc})',
      l10n.crisisHotlineMoLabel,
      '${l10n.crisisHotlineMoNumber} (${l10n.crisisHotlineMoDesc})',
    ];
    return Container(
      margin: const EdgeInsets.only(top: AppTokens.spacingLg),
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      decoration: BoxDecoration(
        color: AppTokens.surfaceColor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.dividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🆘 心理危机干预热线 (24h)',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.primaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
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
