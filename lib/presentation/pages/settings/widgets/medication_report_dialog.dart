import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/services/medication_report_pdf.dart';
import '../../../../shared/formatters.dart';
import '../../../../domain/logic/medication_report.dart';
import '../../../../l10n/strings.dart';
import '../../../../theme/app_tokens.dart';

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
          title: Text('${Strings.settingsMedReport}（近 ${widget.windowDays} 天）'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
              tooltip: '关闭',
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
                  color: AppTokens.primary.withValues(alpha: 0.08),
                  child: const Text(
                    '可全选复制、生成 PDF 或分享给医生',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ),
                // 报告内容
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    color: AppTokens.surface,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.report,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                          color: AppTokens.textPrimary,
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
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppTokens.divider)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制'),
                            onPressed: _copy,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: FilledButton.icon(
                            icon: _pdfLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf, size: 18),
                            label: const Text('PDF'),
                            onPressed:
                                (widget.reportData == null || _pdfLoading)
                                    ? null
                                    : _exportPdf,
                          ),
                        ),
                        const SizedBox(width: AppTokens.spacingSm),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('分享'),
                            onPressed: _share,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // PDF 生成时的全屏遮罩
            if (_pdfLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppTokens.spacingMd),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: AppTokens.spacingSm),
                            Text('生成 PDF 中...'),
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
        const SnackBar(content: Text('已复制到剪贴板')),
      );
    }
  }

  Future<void> _share() async {
    try {
      await Share.share(
        widget.report,
        subject: '慢病管家 · 用药报告',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败：$e')),
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
        name: '用药报告_${Formatters.dateCompact(data.periodEnd)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成 PDF 失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }
}
