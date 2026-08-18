// v0.21 Round 22 (P0-2 修复): 法律与隐私页
//
// PIPL §26 撤回同意 UI 实现。
// - 顶部 3 份法律文档入口(复用 showLegalDocument)
// - 底部 2 个 toggle:树洞 / 评估分析
//   (1.1.0 round 4b: 失联通知 toggle 随外联服务整摘)
// - 每个 toggle 旁边显示"撤回时间"或"从未撤回"
// - toggle 持久化到 SharedPreferences
//
// v1.1.0+167 R122 P2-2: 555L → 120L 主壳, 拆 4 widget + 1 enum 到
// widgets/legal_*.dart (跟 R121 vent_list_page 模式对齐)。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_consent_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_doc_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_section_title.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_withdraw_choice.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_withdraw_option.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

class LegalPage extends ConsumerStatefulWidget {
  const LegalPage({super.key});

  @override
  ConsumerState<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends ConsumerState<LegalPage> {
  // v0.27 round 63 (P0-3 修复续): legal_page UI 只显示 2 个 toggle
  // (vent / analytics), 不显示 dataExport (PIPL §13 强场景, 走
  // ConsentDialog 单独同意流程)。
  // 1.1.0 round 4b: safety toggle 随外联服务整摘 (3 → 2)。
  // 用 _visibleKinds 显式列 UI 可见 kind, 避免跟全 3 值 ConsentKind.values
  // 混用, snackbar (current/total) 计数走 _visibleKinds.indexOf 跟长度,
  // 不会因 enum 顺序变化而错位。
  static const _visibleKinds = [
    ConsentKind.vent,
    ConsentKind.analytics,
  ];

  // 三个 kind 的当前撤回状态 — 启动时读,变更时写
  late Map<ConsentKind, bool> _withdrawn;
  late Map<ConsentKind, DateTime?> _withdrawnAt;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _withdrawn = {for (final k in ConsentKind.values) k: false};
    _withdrawnAt = {for (final k in ConsentKind.values) k: null};
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(legalConsentStoreProvider);
    for (final kind in ConsentKind.values) {
      _withdrawn[kind] = await store.isWithdrawn(kind);
      _withdrawnAt[kind] = await store.withdrawnAt(kind);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(ConsentKind kind, bool withdraw) async {
    final store = ref.read(legalConsentStoreProvider);
    // v0.28 R82.5 (法务 Q7b 必改, PIPL §47): vent 撤回弹 3 选 1 dialog
    // 立即删除 / 加密封存 / 取消。analytics 走原直接 toggle 路径
    // (1.1.0 round 4b: safety 分支随外联服务整摘)
    if (withdraw && kind == ConsentKind.vent) {
      final choice = await _showVentWithdrawDialog();
      if (choice == null) return; // 用户取消, 状态不变
      if (choice == LegalWithdrawChoice.delete) {
        // 立即删除: 物理删所有 vent 行 + audio 文件
        try {
          final repo = ref.read(ventRepositoryProvider);
          final deletedCount = await repo.deleteAll();
          if (mounted) {
            AppSnackBar.showInfo(
              context,
              AppLocalizations.of(context)
                  .legalVentWithdrawnDeleted(deletedCount),
            );
          }
        } catch (e, st) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              action: AppLocalizations.of(context).legalVentDeleteRetry,
              error: e,
            );
          }
          // 不抛 — 错误已显示, 让用户重试 toggle
          // v0.32 R112 (E-02): 之前裸 developer.log 无 kReleaseMode 守卫,
          // release 模式把含文件路径/PII 的 stack 写进 console (R108 P0#12
          // 锁定的漏洞类别)。换 swallowError (内部 _isProduct 守卫)。
          swallowError(
            where: 'legal_page.ventDeleteAll',
            error: e,
            stack: st,
            note: 'deleteAll failed — snackbar 已提示用户重试',
          );
          return;
        }
      } else {
        // 加密封存: 数据物理上还在, UI 隐藏
        await store.seal(kind);
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            AppLocalizations.of(context).legalVentWithdrawnSealed,
          );
        }
      }
      // 2 个选择都标 withdrawn=true (功能停用)
      // v1.1.0 R113 (BUG 8): 修前 `await store.withdraw(kind)` 在 try 外 —
      // SP 写失败 = unhandled async error。修: try/catch + swallowError +
      // 错误 snackbar, 失败不置 withdrawn (用户可重试)。
      // P3 同批: 修前页面再调一次 DateTime.now() 记 _withdrawnAt, 跟 store
      // 内部 epoch 差几 ms (跨 midnight 显示差 1 天)。修: 回读持久化值。
      try {
        await store.withdraw(kind);
        _withdrawnAt[kind] = await store.withdrawnAt(kind);
      } catch (e, st) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            action: AppLocalizations.of(context).legalVentDeleteRetry,
            error: e,
          );
        }
        swallowError(
          where: 'legal_page.ventWithdraw',
          error: e,
          stack: st,
          note: 'withdraw failed — snackbar 已提示用户重试',
        );
        return;
      }
      if (mounted) {
        setState(() => _withdrawn[kind] = true);
        // 重新触发 ventSealedProvider 让 vent_list_page 重建
        ref.invalidate(ventSealedProvider);
        ref.invalidate(ventSealedAtProvider);
      }
      return;
    }

    // analytics 走原路径 (无数据清理)
    // v1.1.0 R113 (BUG 8 同批): 同款 try/catch 收口 (跟 vent 路径一致)
    try {
      if (withdraw) {
        await store.withdraw(kind);
      } else {
        await store.reset(kind);
      }
    } catch (e, st) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).legalVentDeleteRetry,
          error: e,
        );
      }
      swallowError(
        where: 'legal_page.analyticsToggle',
        error: e,
        stack: st,
        note: 'consent store write failed — snackbar 已提示用户重试',
      );
      return;
    }
    _withdrawnAt[kind] = await store.withdrawnAt(kind);
    if (mounted) {
      setState(() => _withdrawn[kind] = withdraw);
      // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
      // v0.27 round 63 (P0-3 修复续): snackbar 计数走 _visibleKinds 长度 + index,
      // 不用 ConsentKind.values (含 §13 强场景 dataExport, 用户从未在 UI 看到,
      // 计数会从 1/3 跳到 3/3 再到 5/3, 语义错乱)。
      final current = _visibleKinds.indexOf(kind) + 1;
      final total = _visibleKinds.length;
      AppSnackBar.showInfo(
        context,
        withdraw
            ? AppLocalizations.of(context).legalConsentWithdrawn(current, total)
            : AppLocalizations.of(context).legalConsentReAgreed(current, total),
      );
    }
  }

  /// v0.28 R82.5 (法务 Q7b 必改): vent 撤回 3 选 1 dialog
  ///
  /// 返回用户选择, null = 取消。dialog 不可 barrierDismissible (防误关)。
  Future<LegalWithdrawChoice?> _showVentWithdrawDialog() async {
    final l10n = AppLocalizations.of(context);
    return showDialog<LegalWithdrawChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.forest_outlined, size: 32),
        title: Text(l10n.legalVentWithdrawTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.legalVentWithdrawBody),
            const SizedBox(height: AppTokens.spacingMd),
            // 立即删除 (红色, 强调不可恢复)
            LegalWithdrawOption(
              choice: LegalWithdrawChoice.delete,
              icon: Icons.delete_forever_outlined,
              iconColor: AppTokens.errorColor(context),
              title: l10n.legalVentWithdrawDelete,
              description: l10n.legalVentWithdrawDeleteDesc,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 加密封存 (info 蓝, 中性)
            LegalWithdrawOption(
              choice: LegalWithdrawChoice.sealed,
              icon: Icons.lock_outline,
              iconColor: AppTokens.primaryColor(context),
              title: l10n.legalVentWithdrawSeal,
              description: l10n.legalVentWithdrawSealDesc,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.legalPageTitle,
      child: !_loaded
          ? const Center(child: LoadingSpinner())
          : ListView(
              padding: AppTokens.edgeInsetsMd,
              children: [
                // ===== 法律文档 =====
                LegalSectionTitle(text: l10n.legalPageDocuments),
                Card(
                  child: Column(
                    children: [
                      LegalDocTile(
                        icon: Icons.description_outlined,
                        title: l10n.setupLegalUserAgreement,
                        onTap: () => showLegalDocument(
                          context,
                          'user_agreement',
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      LegalDocTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.setupLegalPrivacyPolicy,
                        onTap: () => showLegalDocument(
                          context,
                          'privacy_policy',
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      LegalDocTile(
                        icon: Icons.medical_services_outlined,
                        title: l10n.setupLegalSensitiveData,
                        onTap: () => showLegalDocument(
                          context,
                          'sensitive_data_consent',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.spacingLg),

                // ===== 撤回同意 =====
                LegalSectionTitle(text: l10n.legalPageWithdrawTitle),
                Container(
                  padding: AppTokens.edgeInsetsSm,
                  decoration: BoxDecoration(
                    color: AppTokens.tintedWarningSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Text(
                    l10n.legalPageWithdrawDescription,
                    style: AppTokens.textStyleLegal(context),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Card(
                  child: Column(
                    children: [
                      LegalConsentTile(
                        kind: ConsentKind.vent,
                        title: l10n.legalPageWithdrawVent,
                        subtitle: l10n.legalPageWithdrawVentSubtitle,
                        withdrawn: _withdrawn[ConsentKind.vent]!,
                        withdrawnAt: _withdrawnAt[ConsentKind.vent],
                        onToggle: (v) => _toggle(ConsentKind.vent, v),
                      ),
                      const Divider(height: 1, thickness: 0.5),
                      LegalConsentTile(
                        kind: ConsentKind.analytics,
                        title: l10n.legalPageWithdrawAnalytics,
                        subtitle: l10n.legalPageWithdrawAnalyticsSubtitle,
                        withdrawn: _withdrawn[ConsentKind.analytics]!,
                        withdrawnAt: _withdrawnAt[ConsentKind.analytics],
                        onToggle: (v) => _toggle(ConsentKind.analytics, v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// 提供给 legal_page 内部用的清理方法(测试 / 调试)
Future<void> clearLegalConsentCache() async {
  final prefs = await SharedPreferences.getInstance();
  for (final k in ConsentKind.values) {
    await prefs.remove('legal_consent_withdrawn_${k.name}');
    await prefs.remove('legal_consent_withdrawn_${k.name}_at');
  }
  // v0.28 R82.5: 同步清封存标志
  await prefs.remove('legal_consent_vent_sealed_at');
}
