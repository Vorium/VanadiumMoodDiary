// v0.30 round 95 (sub-spec 1 task 2a): 抽 export_tile
// v0.30 round 95 (sub-spec 1 task 6.5): 拆 JSON 弹窗 → export_dialog
//
// 数据导出入口 tile — 走 ConsentDialog + audit log + JSON 弹窗 + PIPL §17 告知
//
// 业务逻辑 (主壳保留):
// - PIPL §13 单独同意 (ConsentDialog kind: dataExport)
// - audit log 写 legalConsentStoreProvider (PIPL §17 可追溯), 失败走 swallowError
// - ref.read(dataExportServiceProvider).exportToJson() 生成 JSON
// - ExportDialog.show(...) 弹 JSON 弹窗 (Q4b 明文风险 + 责任划界 + 强制勾选)
// - PIPL §28 vent 录音不导出 (ExportDialog 内 Container 提示)
//
// 业务封装 (R95 sub-spec 1 task 6.5 抽出):
// - ExportDialog widget: JSON 弹窗全部 UI + 强制勾选 state + Clipboard.setData
// - export_tile 主壳不再含 100+ 行 JSON 弹窗 UI, 只调 ExportDialog.show(...)
//
// props callback 模式 (R93 task 1 模式):
// - 主壳持 ref + context
// - sub-tile 接受 onExport 回调 (默认调内部 _exportData; 测试可注入自定义回调跳过完整流)
// - sub-tile 不读全局 (除 ref 自带的 provider)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/export_dialog.dart';

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
  /// 3. exportToJson → ExportDialog.show(...) JSON 弹窗 (Q4b 明文风险 + 责任划界 + 强制勾选)
  ///
  /// v0.30 round 95 (sub-spec 1 task 6.5): JSON 弹窗 UI 抽到 ExportDialog,
  /// 本函数从 200+ 行 → 60 行, 业务逻辑保留。
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    // v0.27 R82: PIPL §13 单独同意 — 数据导出走 ConsentDialog (kind: dataExport)
    // 替代之前的"敏感文字警告" 通用 dialog。修复前只警告, 没生成 ConsentArtifact,
    // 法务复查时缺 §13 同意证据。修复后: 弹 ConsentDialog 走 dataExportConsent
    // 模板 (purpose / dataCategories / retention 3 placeholder) → 用户同意 →
    // 写 audit log (LegalConsentStore.recordDataExportConsent) → 继续 export。
    final l10n = AppLocalizations.of(context);
    final consent = await ConsentDialog.show(
      context,
      kind: ConsentKind.dataExport,
      // R100 (P1#9): 3 placeholder 走 ARB, 替代 hardcoded 中文
      placeholders: {
        'purpose': l10n.dataExportPurposeBackup,
        'dataCategories': l10n.dataExportDataCategories,
        'retention': l10n.dataExportRetentionClipboard,
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
      // v0.30 round 95 (sub-spec 1 task 6.5): JSON 弹窗 UI 抽到 ExportDialog
      await ExportDialog.show(context, json: json);
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
