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
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

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
            // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
            PressFeedbackIconButton(
              icon: Icons.close,
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
                        // v0.26 round 57 (emil EMIL-INC-03): 走 textStyleMono 集中器
                        // 替代内联 TextStyle('monospace', fontSizeBodySm, lineHeight, color)
                        // textStyleMono 自带 lineHeightNormal + textPrimaryColor
                        style: AppTokens.textStyleMono(
                          context,
                          size: AppTokens.fontSizeBodySm,
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
                          color: AppTokens.dividerColor(context),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // v0.27 R70 (emil B-3 重构): 3 按钮统一走 LoadingTextButton 集中器
                        // 替代 3 模式不一致: PressFeedback+OutlinedButton.onPressed=null /
                        // PressFeedback+LoadingTextButton(filled) / PressFeedback+OutlinedButton.onPressed=直接
                        // emil "DRY for taste" + 集中器复用原则
                        Expanded(
                          child: LoadingTextButton(
                            label: AppLocalizations.of(context).settingsCopy,
                            icon: Icons.copy,
                            isLoading: false,
                            onPressed: _copy,
                            variant: LoadingTextButtonVariant.outlined,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: LoadingTextButton(
                            label:
                                AppLocalizations.of(context).medReportPdfLabel,
                            icon: Icons.picture_as_pdf,
                            isLoading: _pdfLoading,
                            onPressed:
                                (widget.reportData == null || _pdfLoading)
                                    ? null
                                    : _exportPdf,
                            variant: LoadingTextButtonVariant.filled,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: LoadingTextButton(
                            label: AppLocalizations.of(context)
                                .medReportShareLabel,
                            icon: Icons.share,
                            isLoading: false,
                            onPressed: _share,
                            variant: LoadingTextButtonVariant.outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // PDF 生成时的全屏遮罩
            // v0.27 R70 (emil B-2): 走 LoadingScrim 集中器
            // 替代 30 行 inline scrim + Card + spinner + AbsorbPointer
            // 集中器自动包 AbsorbPointer (R69 P0-2 修复) + scrim 0.54 (long task modal 标准)
            LoadingScrim(
              isLoading: _pdfLoading,
              message: AppLocalizations.of(context).medReportPdfLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.report));
    if (mounted) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).snackbarCopied,
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
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionShare,
          error: e,
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
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionGeneratePdf,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }
}
