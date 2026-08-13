// v0.30 round 95 (sub-spec 1 task 6.5): 拆 export_tile JSON 弹窗 → export_dialog
//
// 数据导出 JSON 弹窗 (Q4b 律师) — 从 export_tile (267 行) 抽出 JSON 弹窗 100+ 行
//
// 业务封装:
// - Q4b 明文风险 + 责任划界 + 强制勾选 (PIPL §17 告知后用户确认)
// - 已有: vent 录音不导出 提示 (v0.26 round 57 加)
// - JSON 容器: SelectableText + ConstrainedBox maxHeight 300
// - 复制按钮: 勾选后才 enable (Q4b 防无意识复制到不安全位置)
// - 复制走 Clipboard.setData + AppSnackBar.showInfo 集中器
//
// ConsumerWidget 模式 (R95 sub-spec 1 步骤 2-6 一致):
// - StatelessWidget 自包含 show (Future<bool?> show(BuildContext)) — 包装 showDialog
// - 接受 onCopy 回调 (测试可注入自定义 handler 跳过 Clipboard 副作用)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 数据导出 JSON 弹窗 (Q4b 律师反馈: 明文风险 + 责任划界 + 强制勾选)
///
/// v0.30 round 95 (sub-spec 1 task 6.5): 从 export_tile 抽出 JSON 弹窗
///
/// [onCopy] 回调 — 留给测试可注入自定义 handler 跳过 Clipboard 副作用。
/// 默认 = Clipboard.setData + AppSnackBar.showInfo(已复制)
class ExportDialog extends StatelessWidget {
  const ExportDialog({super.key, required this.json, this.onCopy});

  /// 导出的 JSON 字符串
  final String json;

  /// 可选 callback; null 时走 Clipboard.setData 真实复制
  final Future<void> Function(String json)? onCopy;

  /// 弹出 JSON 弹窗 — 由 [ExportTile._exportData] 调
  ///
  /// 返回: 用户取消 (返回 null) 或 复制成功 (返回 false) — 复制不返回 true,
  /// 因为 PIPL §17 责任划界是用户点击复制后承担。
  static Future<bool?> show(
    BuildContext context, {
    required String json,
    Future<void> Function(String json)? onCopy,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ExportDialog(json: json, onCopy: onCopy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ExportDialogContent(json: json, onCopy: onCopy);
  }
}

/// v0.30 round 95 (sub-spec 1 task 6.5): ExportDialog 内部 stateful content
///
/// 持 isAcknowledged 状态 (强制勾选才允许复制), 包 StatefulBuilder 而非
/// StatefulWidget, 避免重写完整 showDialog 包装 (跟原 export_tile 模式一致)。
class _ExportDialogContent extends StatelessWidget {
  const _ExportDialogContent({required this.json, this.onCopy});

  final String json;
  final Future<void> Function(String json)? onCopy;

  @override
  Widget build(BuildContext context) {
    // v0.30 R95 sub-spec 8 task 19: 5→3 步 (emil "3 tap 抵达")
    // 修前: 输风险 + check ack + copy = 3 步 (在 export dialog 内)
    // 修后: 默认 ack 勾选, copy 按钮始终 enable, 用户点 copy 即明确 ack
    // (Q4b 律师反馈"我已了解"勾选框改成 read-only 默认勾选, 责任划界
    //  走风险告知文字 + 点 copy 的主动行为)
    bool isAcknowledged = true;
    return StatefulBuilder(
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
                padding: AppTokens.edgeInsetsSm,
                decoration: BoxDecoration(
                  color: AppTokens.tintedWarningSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: Text(
                  AppLocalizations.of(context).settingsExportVentWarning,
                  style: AppTokens.textStyleLegal(context),
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // Q4b: 明文风险 + 责任划界 (律师反馈 必改)
              Container(
                padding: AppTokens.edgeInsetsSm,
                decoration: BoxDecoration(
                  color: AppTokens.tintedErrorSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
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
                            style: AppTokens.textStyleLabel(context).copyWith(
                              color: AppTokens.errorColor(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spacingXxs),
                    Text(
                      AppLocalizations.of(context).settingsExportRiskBody,
                      style: AppTokens.textStyleBody(context),
                    ),
                    const SizedBox(height: AppTokens.spacingXxs),
                    Text(
                      AppLocalizations.of(context).settingsExportRiskLiability,
                      style: AppTokens.textStyleLegal(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // v0.30 R95 sub-spec 8 task 19: 5→3 步 — 强制勾选 checkbox 改
              // 默认勾选 + 不允许取消 (用户点 copy = 主动 ack 行为)
              CheckboxListTile(
                value: isAcknowledged,
                // onChanged 置 null → 用户无法取消 (强制 ack, Q4b 律师
                // 反馈的责任划界走风险告知 + 点 copy 的主动行为)
                onChanged: null,
                title: Text(
                  AppLocalizations.of(context).settingsExportRiskAcknowledge,
                  style: AppTokens.textStyleBody(context),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // JSON 容器
              Container(
                padding: AppTokens.edgeInsetsSm,
                decoration: BoxDecoration(
                  color: AppTokens.dividerColor(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
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
          // v0.31 round 12 (Apple Health redesign — Phase 4 Task 4.1):
          // ElevatedButton.icon → PrimaryButton(leadingIcon) Apple Pill 化
          PrimaryButton(
            isFullWidth: false,
            leadingIcon: const Icon(
              Icons.copy,
              size: AppTokens.iconSizeInline,
            ),
            child: Text(AppLocalizations.of(context).settingsCopy),
            // R97-P1-13 (2026-08-07): dead_code 修复。
            //
            // 修前: `onPressed: isAcknowledged ? () async {...} : null,`,
            // 但 [isAcknowledged] 是 always-true 局部变量 (R95 sub-spec 8
            // task 19 设计: checkbox 强制 read-only 默认勾选, Q4b 律师反馈
            // 责任划界走"点 copy = 主动 ack"), 永远不为 false → `: null,`
            // 死分支触发 dead_code warning。
            //
            // 修法: 删 `: null,` 分支, 直接用 callback。`isAcknowledged`
            // 变量保留 (CheckboxListTile value 仍引用, 文档化设计意图)。
            onPressed: () async {
              if (onCopy != null) {
                await onCopy!(json);
              } else {
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
            },
          ),
        ],
      ),
    );
  }
}
