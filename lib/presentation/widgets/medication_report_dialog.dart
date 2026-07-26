import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chroniccare/core/data/services/medication_report_pdf.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 用药报告全屏预览
///
/// 两种用途：
/// - 刚生成：[reportData] 非空，PDF 按钮可用
/// - 历史详情：[reportData] 为 null，PDF 按钮置灰（用户可基于当前数据重新生成）
class MedicationReportDialog extends StatefulWidget {
  final String report;
  final MedicationReportData? reportData;
  final int windowDays;
  const MedicationReportDialog({
    super.key,
    required this.report,
    required this.reportData,
    required this.windowDays,
  });

  @override
  State<MedicationReportDialog> createState() => _MedicationReportDialogState();
}

class _MedicationReportDialogState extends State<MedicationReportDialog> {
  bool _pdfLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${AppLocalizations.of(context).settingsMedReport}（近 ${widget.windowDays} 天）',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: AppLocalizations.of(context).commonClose,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // 顶部说明条
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTokens.spacingMd),
                  // v0.22 round 29 (emil-01~12): 改用 tintedPrimaryLight 集中器
                  color: AppTokens.tintedPrimaryLight(context),
                  child: Text(
                    AppLocalizations.of(context).medReportCopyHint,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                  ),
                ),
                // 报告内容
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    color: AppTokens.surfaceColor(context),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.report,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: AppTokens.fontSizeBodySm,
                          height: AppTokens.lineHeightNormal,
                          color: AppTokens.textPrimaryColor(context),
                        ),
                      ),
                    ),
                  ),
                ),
                // 底部操作条：3 个按钮等分（复制 / PDF / 分享）
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: AppTokens.dividerColor(context),),),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          // v0.22 round 30 (emil P1-1): 复制按钮包 PressFeedback 接管 tap
                          child: PressFeedback(
                            onTap: _copy,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy, size: 18),
                              label: Text(
                                  AppLocalizations.of(context).settingsCopy,),
                              onPressed: null, // 委托给 PressFeedback
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: PressFeedback(
                            // v0.22 round 30 (emil P1-1): 不接管 onTap,
                            // 让 button.onPressed 自己处理 disabled 状态
                            // (reportData == null || _pdfLoading)
                            // v0.24 round 43 (emil P1-01 H-03): 改用
                            // LoadingTextButton + icon 参数,
                            // 替代内联 FilledButton.icon + Spinner
                            child: LoadingTextButton(
                              label: AppLocalizations.of(context)
                                  .medReportPdfLabel,
                              icon: Icons.picture_as_pdf,
                              isLoading: _pdfLoading,
                              onPressed:
                                  (widget.reportData == null || _pdfLoading)
                                      ? null
                                      : _exportPdf,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: PressFeedback(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share, size: 18),
                              label: Text(AppLocalizations.of(context)
                                  .medReportShareLabel,),
                              onPressed: _share,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // PDF 生成时的全屏遮罩
            // scrim 0.54 — M3 Modal barrier 0.32 太浅, PDF 生成 5s+ 需更深遮罩
            // 让用户清楚"正在后台生成", emil 0.54 是'long task modal'标准 alpha
            if (_pdfLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacingMd),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: AppTokens.spacingSm),
                            Text(AppLocalizations.of(context)
                                .medReportPdfLoading,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(context, AppLocalizations.of(context).snackbarCopied),
      );
    }
  }

  Future<void> _share() async {
    try {
      await Share.share(
        widget.report,
        subject: AppLocalizations.of(context).medReportShareSubject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).snackbarActionShare,
              error: e,),
        );
      }
    }
  }

  /// 生成 PDF → 弹系统打印/分享面板
  Future<void> _exportPdf() async {
    final data = widget.reportData;
    if (data == null) return;
    setState(() => _pdfLoading = true);
    try {
      final bytes = await MedicationReportPdf.build(data);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: AppLocalizations.of(context)
            .medReportFileName(Formatters.dateCompact(data.periodEnd)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).snackbarActionGeneratePdf,
              error: e,),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }
}
