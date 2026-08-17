// v1.1.0 R116 (god class 拆 round 3): 时间段内单条药物 Row
//
// 历史:
// - v0.30 R101: medication_page 内联 _SlotEntryRow 92L, 1 文件 380L god class
// - v0.32 R109: 抽 calculator + empty state cards, medication_page 瘦身
// - v1.1.0 R113 (BUG 6): checkIn 异步 + AsyncValue.guard 错误处理
// - v1.1.0 R116: _SlotEntryRow → MedicationSlotEntryRow public,
//   拆到独立文件 (本文件)
//
// 公开 API:
// - MedicationSlotEntryRow: 单条时段药物 row, 32pt pill icon + 药名 +
//   时:分 + 剂量 + 直接打卡 checkbox (R113 PressFeedback 包装 + 错误
//   snackbar, 跟 home CheckInButton 同款)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/medication_page_stats_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 时间段内的单条药物 — 支持直接打卡
class MedicationSlotEntryRow extends ConsumerWidget {
  const MedicationSlotEntryRow({super.key, required this.entry});

  final MedicationSlotEntry entry;

  /// R113 (BUG 6): 从原 inline async closure 抽出, 供 PressFeedback
  /// (mode 1, 同步 VoidCallback) 调用, unawaited 显式标记 fire-and-forget。
  ///
  /// v1.1.0 R113 (BUG 6 续): checkIn 走 AsyncValue.guard — 异常吞进
  /// state 不 throw (home ref.listen 同款模式)。修前失败时无任何反馈
  /// (Haptics.success 照跑, 用户以为成功了)。修: 完成后查 hasError →
  /// 错误 snackbar + 跳过 haptic 成功反馈。
  void _checkIn(WidgetRef ref, BuildContext context, MedicationSlotEntry e) {
    unawaited(() async {
      await ref
          .read(checkInNotifierProvider.notifier)
          .checkIn(medicationId: e.med.id);
      if (!context.mounted) return;
      final failed = ref.read(checkInNotifierProvider).hasError;
      if (failed) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionCheckin,
          error: ref.read(checkInNotifierProvider).error,
        );
        return;
      }
      await Haptics.success();
    }());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MedicationPillIcon(
            colorIndex: e.med.colorIndex,
            size: 32,
            initial: e.med.name,
          ),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.med.name,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
                Text(
                  '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')} · '
                  '${e.med.dosage}${e.med.dosageUnit.id}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
          ),
          // 直接打卡按钮 (参照 Apple Health Medications checkbox)
          // R113 (BUG 6): PressFeedback 包装 (按下 scale 0.97 + haptic,
          // mode 1 接管 tap — 修前裸 GestureDetector 无任何按压反馈),
          // AnimatedSwitcher 时长走 Motion.duration (修前裸 AppTokens.durFast
          // 是全 lib 唯一绕过 Motion wrapper 的动画)。
          PressFeedback(
            onTap: e.done ? null : () => _checkIn(ref, context, e),
            child: AnimatedSwitcher(
              duration: Motion.duration(context, AppTokens.durFast),
              child: Icon(
                e.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                key: ValueKey(e.done),
                size: 28,
                color: e.done
                    ? AppTokens.primaryColor(context)
                    : AppTokens.textHintColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
