// v0.30 round 95 (sub-spec 1 task 2a): 抽 export_tile
//
// 数据导出入口 tile — 走 ConsentDialog + audit log + JSON 弹窗 + PIPL §17 告知
//
// 业务逻辑从主壳 (200+ 行) 抽到本 sub-tile:
// - PIPL §13 单独同意 (ConsentDialog kind: dataExport)
// - audit log 写 legalConsentStoreProvider (PIPL §17 可追溯), 失败走 swallowError
// - JSON 弹窗: Q4b 明文风险 + 责任划界 + 强制勾选 + 复制按钮
// - PIPL §28 vent 录音不导出 (settingsExportVentWarning Container 提示)
//
// props callback 模式 (R93 task 1 模式):
// - 主壳持 ref + context
// - sub-tile 接受 onExport 回调 (默认调内部 _exportData; 测试可注入自定义回调跳过完整流)
// - sub-tile 不读全局 (除 ref 自带的 provider)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';

/// 导出全部数据 tile (PIPL §13 + §17 + §28 风险告知)
///
/// v0.30 round 95: ConsumerWidget, 内部 _exportData 走完整 export 流程
///
/// [onExport] 回调 — 留给测试可注入自定义 handler 跳过完整流。
/// 默认 = 内部 _exportData 完整流程 (ConsentDialog + audit log + JSON 弹窗)
class ExportTile extends ConsumerWidget {
  const ExportTile({super.key, this.onExport});

  /// 可选 callback; null 时走内部 _exportData 完整流程
  final Future<void> Function()? onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppListTile(
      leading: Icon(
        Icons.upload_outlined,
        color: AppTokens.primaryColor(context),
      ),
      title: Text(AppLocalizations.of(context).settingsExportData),
      subtitle: Text(
        AppLocalizations.of(context).settingsExportSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (onExport != null) {
          onExport!();
        } else {
          _exportData(context, ref);
        }
      },
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 2a): 完整 export 流程
  ///
  /// 1. ConsentDialog kind=dataExport (PIPL §13 单独同意)
  /// 2. 写 audit log (PIPL §17 可追溯), 失败走 swallowError 不阻塞主流程
  /// 3. exportToJson → JSON 弹窗 (Q4b 明文风险 + 责任划界 + 强制勾选)
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    // v0.27 R82: PIPL §13 单独同意 — 数据导出走 ConsentDialog (kind: dataExport)
    // 替代之前的"敏感文字警告" 通用 dialog。修复前只警告, 没生成 ConsentArtifact,
    // 法务复查时缺 §13 同意证据。修复后: 弹 ConsentDialog 走 dataExportConsent
    // 模板 (purpose / dataCategories / retention 3 placeholder) → 用户同意 →
    // 写 audit log (LegalConsentStore.recordDataExportConsent) → 继续 export。
    final consent = await ConsentDialog.show(
      context,
      kind: ConsentKind.dataExport,
      placeholders: const {
        'purpose': '本地备份 / 跨设备迁移',
        'dataCategories':
            '用药记录、打卡记录、紧急联系人、情绪日记、树洞文字 (录音不导出)',
        'retention': '剪贴板 + 用户自行保存到加密存储',
      },
    );
    if (consent == null) {
      // 用户点了"暂不同意" — 静默退出, 不弹额外提示
      return;
    }
    // R82: 写 audit log (PIPL §17 同意记录可追溯)
    try {
      await ref
          .read(legalConsentStoreProvider)
          .recordDataExportConsent(consent);
    } catch (e, st) {
      // 写 audit log 失败不应该阻塞主流程 (consent 已拿到, 用户已明确同意)
      // 走 swallowError 跟 _showMedicationReport 写 history 失败的模式一致
      swallowError(
        where: 'ExportTile._exportData.recordAudit',
        error: e,
        stack: st,
        note: '写 audit log 失败, 主流程继续 (consent 已拿到)',
      );
    }
    if (!context.mounted) return;

    final service = ref.read(dataExportServiceProvider);
    try {
      final json = await service.exportToJson();
      if (!context.mounted) return;
      // v0.28 R83 (Q4b 律师): 导出 JSON dialog 加明文风险 + 责任划界
      // + 强制勾选"我已了解风险"才允许复制 (PIPL §17 告知后用户确认,
      // 责任划界由用户承担 — 跟"明文 = 用户自负"是法律标配)
      bool isAcknowledged = false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(
              AppLocalizations.of(context).settingsExportDialogTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).settingsExportInstruction,
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  // 已有: vent 录音不导出 提示 (v0.26 round 57 加)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.tintedWarningSoft(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      AppLocalizations.of(context).settingsExportVentWarning,
                      style: AppTokens.textStyleLegal(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // Q4b: 明文风险 + 责任划界 (律师反馈 必改)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.tintedErrorSoft(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                      border: Border.all(
                        color: AppTokens.errorColor(context),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTokens.errorColor(context),
                              size: AppTokens.iconSizeInline,
                            ),
                            const SizedBox(
                              width: AppTokens.spacingXxs,
                            ),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)
                                    .settingsExportRiskTitle,
                                style: AppTokens.textStyleLabel(context)
                                    .copyWith(
                                  color: AppTokens.errorColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spacingXxs),
                        Text(
                          AppLocalizations.of(context)
                              .settingsExportRiskBody,
                          style: AppTokens.textStyleBody(context),
                        ),
                        const SizedBox(height: AppTokens.spacingXxs),
                        Text(
                          AppLocalizations.of(context)
                              .settingsExportRiskLiability,
                          style: AppTokens.textStyleLegal(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // 强制勾选 checkbox 才允许复制
                  CheckboxListTile(
                    value: isAcknowledged,
                    onChanged: (v) =>
                        setLocal(() => isAcknowledged = v ?? false),
                    title: Text(
                      AppLocalizations.of(context)
                          .settingsExportRiskAcknowledge,
                      style: AppTokens.textStyleBody(context),
                    ),
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // JSON 容器
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.dividerColor(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          json,
                          // v0.26 round 57 (emil EMIL-INC-03): 走 textStyleMono 集中器
                          // 替代内联 TextStyle('monospace', fontSizeCaptionSm)
                          style: AppTokens.textStyleMono(
                            context,
                            size: AppTokens.fontSizeCaptionSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).commonClose),
              ),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.copy,
                  size: AppTokens.iconSizeInline,
                ),
                label: Text(AppLocalizations.of(context).settingsCopy),
                onPressed: isAcknowledged
                    ? () async {
                        await Clipboard.setData(
                          ClipboardData(text: json),
                        );
                        if (ctx.mounted) {
                          // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
                          AppSnackBar.showInfo(
                            ctx,
                            AppLocalizations.of(ctx).snackbarCopied,
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).settingsActionExport,
          error: e,
        );
      }
    }
  }
}
