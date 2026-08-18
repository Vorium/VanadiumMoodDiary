// v0.30 round 95 (sub-spec 1 task 5): 抽 import_tile
//
// 数据导入入口 tile — 走 JSON 导入 + 风险告知 + 用户确认
//
// 业务逻辑从主壳 (~75 行) 抽到本 sub-tile:
// - StatefulBuilder 弹 dialog: title + 风险告知 + TextField (mono 字体) +
//   取消 / 导入覆盖按钮
// - 加载中按钮 (LoadingTextButton) 防止重复提交
// - dataExportServiceProvider.importFromJson(input) 导入 JSON
// - 成功: dialog 关闭 + AppSnackBar.showInfo
// - 失败: setLocal 解除 loading + AppSnackBar.showError
// - try/finally controller.dispose() 防止 leak (v0.27 R71 P5.4)
//
// props callback 模式 (R95 sub-spec 1 步骤 2-4b 一致):
// - ConsumerWidget 自包含 _showImportDialog 完整流程
// - 接受 onImport 回调 (默认调内部 _showImportDialog; 测试可注入自定义 handler 跳过完整流)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

/// 1.1.0 round 7b (P1 i18n): 本地构建导入摘要
///
/// service 层 (ImportResult.summary) 保持 canonical 中文 fallback 不动
/// (数据导出 JSON 里不带摘要, 只有 UI 显示; 但仍留 canonical 兼容老 caller),
/// 显示层用计数字段 + ARB (importSummary* 带 {n}) 按 locale 拼接。
/// Strings.importSummaryXxx({override}) 走 R57 先例: override 非 null 时
/// 优先 ARB 值。
String _localizedImportSummary(AppLocalizations l10n, ImportResult r) {
  final parts = <String>[
    Strings.importSummaryMedication(
      r.medicationCount,
      override: l10n.importSummaryMedication(r.medicationCount),
    ),
    Strings.importSummaryCheckIn(
      r.checkInCount,
      override: l10n.importSummaryCheckIn(r.checkInCount),
    ),
  ];
  if (r.reportHistoryCount > 0) {
    parts.add(
      Strings.importSummaryReport(
        r.reportHistoryCount,
        override: l10n.importSummaryReport(r.reportHistoryCount),
      ),
    );
  }
  if (r.moodEntryCount > 0) {
    parts.add(
      Strings.importSummaryMood(
        r.moodEntryCount,
        override: l10n.importSummaryMood(r.moodEntryCount),
      ),
    );
  }
  if (r.ventEntryCount > 0) {
    parts.add(
      Strings.importSummaryVent(
        r.ventEntryCount,
        override: l10n.importSummaryVent(r.ventEntryCount),
      ),
    );
  }
  return parts.join(' / ');
}

/// 数据导入 tile (JSON 导入 + 风险告知)
///
/// v0.30 round 95: ConsumerWidget, 内部 _showImportDialog 走完整 import 流程
///
/// [onImport] 回调 — 留给测试可注入自定义 handler 跳过完整流。
/// 默认 = 内部 _showImportDialog 完整流程 (JSON 解析 + DB 导入 + 错误处理)
class ImportTile extends ConsumerWidget {
  const ImportTile({super.key, this.onImport});

  /// 可选 callback; null 时走内部 _showImportDialog 完整流程
  final Future<void> Function()? onImport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v0.32 round 13 (R112 EM-02/AH-04): 透明 Material 包 ListTile,
    // 防 Flutter debug assert (ListTile 在 AppleListSection 白色
    // DecoratedBox 容器内 ink 不可见)
    return Material(
      type: MaterialType.transparency,
      child: AppListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.download_outlined,
          color: AppTokens.primaryColor(context),
        ),
        title: Text(AppLocalizations.of(context).settingsImportData),
        subtitle: Text(
          AppLocalizations.of(context).settingsImportSubtitle,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (onImport != null) {
            onImport!();
          } else {
            _showImportDialog(context, ref);
          }
        },
      ),
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 5): 完整 import 流程
  ///
  /// 1. 弹 AlertDialog: title + 风险告知 TextField (mono 字体, 8 行高) + 取消 / 导入按钮
  /// 2. 加载中按钮 (LoadingTextButton) 防止重复提交
  /// 3. ref.read(dataExportServiceProvider).importFromJson(input) 导入
  /// 4. 成功: dialog 关闭 + AppSnackBar.showInfo(summary)
  /// 5. 失败: setLocal 解除 loading + AppSnackBar.showError
  ///
  /// 业务封装在 [ImportDialog] (私有 StatefulWidget) 内部, 它的 State 在
  /// dispose() 时释放 TextEditingController, 防止 controller 在 dialog 退出动画
  /// 期间被 dispose (R95 sub-spec 1 task 5 widget test 4 暴露的 pre-existing bug:
  /// showDialog() finally dispose 早于 dialog 退出动画完成, TextField 报
  /// "controller was used after being disposed")。
  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          ImportDialog(service: ref.read(dataExportServiceProvider)),
    );
  }
}

/// v0.30 round 95 (sub-spec 1 task 5): Import dialog 私有 widget
///
/// 业务封装 — 由 [ImportTile._showImportDialog] 弹, 内部:
/// - 持 TextEditingController (在 dispose() 释放, 避开 dialog 退出动画 race)
/// - 持 loading 状态 (LoadingTextButton isLoading)
/// - 走 ref.read(dataExportServiceProvider) 完整 import 流程
class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key, required this.service});

  /// v0.30 round 95 (sub-spec 1 task 5): 数据导入服务 — 由父 widget 读 provider 注入
  final DataExportService service;

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _importing = false;

  @override
  void dispose() {
    // v0.27 R71 (P5.4): try/finally 替代 .then(), 异常路径也保证 dispose
    // 注: 用 StatefulWidget 的 dispose() 替代 showDialog 外面的 finally,
    // 避开 controller 早于 dialog 退出动画被 dispose (R95 sub-spec 1 task 5
    // widget test 4 暴露的 pre-existing bug)。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).settingsImportDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppLocalizations.of(context).settingsImportWarning),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: _controller,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).settingsImportHint,
              border: const OutlineInputBorder(),
            ),
            // v0.26 round 57 (emil EMIL-INC-03): 走 textStyleMono 集中器
            // 替代内联 TextStyle('monospace', fontSize: 12)
            // 注: 12.0 = fontSizeCaptionSm, 等价
            style: AppTokens.textStyleMono(
              context,
              size: AppTokens.fontSizeCaptionSm,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _importing ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).commonCancel),
        ),
        LoadingTextButton(
          label: AppLocalizations.of(context).settingsImportAndOverwrite,
          isLoading: _importing,
          onPressed: () async {
            final input = _controller.text.trim();
            if (input.isEmpty) return;
            setState(() => _importing = true);
            final result = await widget.service.importFromJson(input);
            if (!context.mounted) return;
            if (result.success) {
              Navigator.pop(context);
              // 1.1.0 round 7b (P1 i18n): 不再直接显示 service 层的
              // canonical 中文 summary (result.summary), 改用计数字段 +
              // AppLocalizations 本地构建 (en 用户不再看到 "N 药" 中文)
              final l10n = AppLocalizations.of(context);
              final summary = _localizedImportSummary(l10n, result);
              AppSnackBar.showInfo(
                context,
                l10n.settingsImportSuccess(summary),
              );
            } else {
              setState(() => _importing = false);
              // v0.27 round 59 (emil EMIL-T13): 用 showError 集中器
              AppSnackBar.showError(
                context,
                action: AppLocalizations.of(context).settingsActionImport,
                error: result.error,
              );
            }
          },
        ),
      ],
    );
  }
}
