// v0.21 Round 22 (P0-2 修复): 法律与隐私页
//
// PIPL §26 撤回同意 UI 实现。
// - 顶部 3 份法律文档入口(复用 showLegalDocument)
// - 底部 3 个 toggle:失联通知 / 树洞 / 评估分析
// - 每个 toggle 旁边显示"撤回时间"或"从未撤回"
// - toggle 持久化到 SharedPreferences
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

class LegalPage extends ConsumerStatefulWidget {
  const LegalPage({super.key});

  @override
  ConsumerState<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends ConsumerState<LegalPage> {
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
    if (withdraw) {
      await store.withdraw(kind);
      _withdrawnAt[kind] = DateTime.now();
    } else {
      await store.reset(kind);
      _withdrawnAt[kind] = null;
    }
    if (mounted) {
      setState(() => _withdrawn[kind] = withdraw);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            withdraw
                ? '已撤回 (${ConsentKind.values.indexOf(kind) + 1}/3)'
                : '已重新同意 (${ConsentKind.values.indexOf(kind) + 1}/3)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PageScaffold(
      title: l10n.legalPageTitle,
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              children: [
                // ===== 法律文档 =====
                _SectionTitle(text: l10n.legalPageDocuments),
                Card(
                  child: Column(
                    children: [
                      _DocTile(
                        icon: Icons.description_outlined,
                        title: l10n.setupLegalUserAgreement,
                        onTap: () => showLegalDocument(
                          context,
                          'user_agreement',
                        ),
                      ),
                      const Divider(height: 1),
                      _DocTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l10n.setupLegalPrivacyPolicy,
                        onTap: () => showLegalDocument(
                          context,
                          'privacy_policy',
                        ),
                      ),
                      const Divider(height: 1),
                      _DocTile(
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
                _SectionTitle(text: l10n.legalPageWithdrawTitle),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: AppTokens.tintedWarningSoft(context),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Text(
                    l10n.legalPageWithdrawDescription,
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Card(
                  child: Column(
                    children: [
                      _ConsentTile(
                        kind: ConsentKind.safety,
                        title: l10n.legalPageWithdrawSafety,
                        subtitle: l10n.legalPageWithdrawSafetySubtitle,
                        withdrawn: _withdrawn[ConsentKind.safety]!,
                        withdrawnAt: _withdrawnAt[ConsentKind.safety],
                        onToggle: (v) => _toggle(ConsentKind.safety, v),
                      ),
                      const Divider(height: 1),
                      _ConsentTile(
                        kind: ConsentKind.vent,
                        title: l10n.legalPageWithdrawVent,
                        subtitle: l10n.legalPageWithdrawVentSubtitle,
                        withdrawn: _withdrawn[ConsentKind.vent]!,
                        withdrawnAt: _withdrawnAt[ConsentKind.vent],
                        onToggle: (v) => _toggle(ConsentKind.vent, v),
                      ),
                      const Divider(height: 1),
                      _ConsentTile(
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(
          left: AppTokens.spacingXs,
          bottom: AppTokens.spacingSm,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: AppTokens.fontSizeHeadline,
            fontWeight: FontWeight.w600,
            color: AppTokens.textPrimaryColor(context),
          ),
        ),
      );
}

class _DocTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _DocTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTokens.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final ConsentKind kind;
  final String title;
  final String subtitle;
  final bool withdrawn;
  final DateTime? withdrawnAt;
  final ValueChanged<bool> onToggle;

  const _ConsentTile({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.withdrawn,
    required this.withdrawnAt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timeText = withdrawnAt == null
        ? l10n.legalPageConsentNever
        : l10n.legalPageConsentRecorded(
            '${withdrawnAt!.year.toString().padLeft(4, '0')}-'
            '${withdrawnAt!.month.toString().padLeft(2, '0')}-'
            '${withdrawnAt!.day.toString().padLeft(2, '0')} '
            '${withdrawnAt!.hour.toString().padLeft(2, '0')}:'
            '${withdrawnAt!.minute.toString().padLeft(2, '0')}',
          );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppTokens.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTokens.textHintColor(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: withdrawn,
                onChanged: onToggle,
                activeThumbColor: AppTokens.error,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 11,
                color: withdrawn
                    ? AppTokens.error
                    : AppTokens.textHintColor(context),
              ),
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
}
