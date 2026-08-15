// setup_submit_flow.dart — 提交序列编排 (AR-20 批2a)
//
// 拆自 setup_page_state.dart _finishSetup: completeSetup 之后的 4 段编排
// (PIPL §14 同意留痕 / watchAll 5s 超时 / 请求通知权限 / 重排用药提醒 +
// 每日提醒) + medicationList 收集。错误不吞, 原样上抛 — caller
// (SetupPageState) 管 error snackbar + swallowError + saving 复位。
//
// v0.27 round 59 (spen §5#18 latent P0 fix): watchAll 5s timeout 是
// fail-loud — TimeoutException 抛出落入 caller catch → setup 失败 + UI
// 提示 (修前 fail-soft 吞数据 → 失通知)。
//
// 1.1.0 round 4: contactList / contactConsents 参数整摘 (联系人同意弹窗
// 循环已删, 失联通信业务暂停定版)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// 提交序列 + 提交数据收集 (AR-20 批2a)
class SetupSubmitFlow {
  SetupSubmitFlow._();

  /// MedDraft 列表 → medicationList 提交数据 (空药名跳过, dosage 兜底 0)
  ///
  /// 跟原 _finishSetup 1:1: name 走 trim, 空 name 跳过,
  /// double.tryParse 失败 → 0, times 转 HourMinute。
  static List<
          ({
            String name,
            double dosage,
            String dosageUnit,
            List<HourMinute> times,
          })>
      collectMedications(List<MedDraft> meds) {
    final medicationList = <
        ({
          String name,
          double dosage,
          String dosageUnit,
          List<HourMinute> times,
        })>[];
    for (final m in meds) {
      final name = m.nameController.text.trim();
      if (name.isEmpty) continue;
      final dosage = double.tryParse(m.dosageController.text.trim()) ?? 0;
      medicationList.add(
        (
          name: name,
          dosage: dosage,
          dosageUnit: m.dosageUnit,
          times: m.times
              .map((t) => HourMinute(hour: t.hour, minute: t.minute))
              .toList(),
        ),
      );
    }
    return medicationList;
  }

  /// 提交序列: completeSetup → recordConsent (PIPL §14) → 通知重排
  ///
  /// 错误原样上抛, 由 caller 管 error snackbar / swallowError。
  /// context 中途 unmount → 静默 return (后续步骤无意义, caller 的
  /// finally 块负责 _saving 复位)。
  static Future<void> run({
    required WidgetRef ref,
    required BuildContext context,
    required String userName,
    required List<
            ({
              String name,
              double dosage,
              String dosageUnit,
              List<HourMinute> times,
            })>
        medicationList,
  }) async {
    // v0.32 架构批 2 (AR-19): saveSetup 迁到 SetupCommitter (data 层编排,
    // transaction 语义不变)。
    await ref.read(setupCommitterProvider).completeSetup(
          userName: userName,
          medicationList: medicationList,
        );
    if (!context.mounted) return;
    // v0.21 Round 22 (P1-22 修复): PIPL §14 同意记录
    // setup 步骤 0 勾选完成时, 记录同意时刻 + 协议版本号,
    // 后续可证明"用户当时同意了哪一版协议"
    // v0.27 round 77 (R76-N6 修): 跟 consent_dialog 同步从 provider 读
    // 启动时算的 legal version, 不再有 hardcode const
    final legalVersion = ref.read(legalVersionProvider);
    await ref.read(userProfileRepositoryProvider).recordConsent(
          userAgreementVersion: legalVersion,
          privacyPolicyVersion: legalVersion,
        );
    if (!context.mounted) return;

    // v0.27 round 59 (spen §5#18 latent P0 fix): 修正 fail-soft timeout
    // 丢数据。R52 加 5s timeout 防御 drift stream hang (DB lock 时罕见)
    // 但 fail-soft onTimeout: () => const [] 让"用户若有 N 个药"被吞成 0
    // 个 → 失通知。修正成 fail-loud: TimeoutException 抛出 → caller catch
    // → setup 失败 + UI 提示
    final medications = await ref
        .read(medicationRepositoryProvider)
        .watchAll()
        .first
        .timeout(const Duration(seconds: 5));

    // R97-P1-6 (2026-08-07): 在 context 内请求通知权限。
    //
    // 修前: notification_service.init() 在 main.dart 启动时立即弹权限请求,
    // 用户没看到任何 UI 不知为何授权 → 拒绝率高 + 违反 App Store 5.1.1
    // "权限应在 context 内请求"指南。
    //
    // 修后: 改在 setup 流程配完药、即将调度提醒的时机请求 — 用户已明确
    // 配置了药物 + 看到"提醒"相关 UI, 此刻请求权限符合用户预期。
    // 用户拒绝时仍继续 setup (提醒调度失败不阻塞核心功能), 后续在
    // settings/reminders_hub 还可重新触发。
    try {
      await ref.read(notificationServiceProvider).requestPermission();
    } catch (e, st) {
      // 平台异常 (e.g. web 不支持) 不阻塞 setup, 走 swallowError 集中器
      swallowError(
        where: 'setup_page_state._goToStep3.requestPermission',
        error: e,
        stack: st,
        note: '通知权限请求失败不阻塞 setup',
      );
    }

    await ref
        .read(notificationServiceProvider)
        .delegate
        .rescheduleMedicationReminders(medications);
    await ref
        .read(notificationServiceProvider)
        .delegate
        .scheduleDailyReminder(hour: 20, minute: 0);
  }
}
