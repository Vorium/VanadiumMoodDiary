import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/logic/email_template.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 邮件预览页
class EmailPreviewPage extends ConsumerWidget {
  const EmailPreviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final contactsAsync = ref.watch(contactsProvider);
    final medsAsync = ref.watch(medicationsProvider);

    return PageScaffold(
      title: AppLocalizations.of(context).emailPreviewTitle,
      child: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                  AppLocalizations.of(context).emailPreviewSetupRequired,
                  style: AppTokens.textStyleBody(context)
                      .copyWith(color: AppTokens.textHintColor(context)),),
            );
          }
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  AppLocalizations.of(context).emailPreviewDescription,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    color: AppTokens.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingMd),
                contactsAsync.when(
                  data: (contacts) {
                    final firstContact =
                        contacts.isEmpty ? null : contacts.first;
                    // v0.16 (Round 12): email 模板改用 domain entity, 直接传 MedicationEntity 不再 toDriftRow()
                    final medication = medsAsync.maybeWhen(
                      data: (m) => m.isEmpty ? null : m.first,
                      orElse: () => null,
                    );

                    // v0.24 round 48 (spzh P0-5): 传 i18n 字符串,海外用户看英文
                    final l10n = AppLocalizations.of(context);
                    final safeName = (profile.userName ?? '').trim().isEmpty
                        ? '您的家人'
                        : profile.userName!.trim();
                    final subject = EmailTemplate.buildSubject(
                      userName: profile.userName,
                      daysWithoutCheckIn: 2,
                      subjectOverride:
                          '[Medication Reminder] $safeName missed check-in for 2 days',
                    );

                    final body = EmailTemplate.buildBody(
                      userName: profile.userName,
                      daysWithoutCheckIn: 2,
                      lastCheckIn:
                          DateTime.now().subtract(const Duration(days: 2)),
                      medication: medication,
                      cycleHours: profile.checkInCycleHours,
                      bodyOverride: l10n.emailBodyI18n(safeName, 2),
                      footerOverride: l10n.emailFooterI18n,
                    );

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTokens.spacingMd),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To: ${firstContact?.phone ?? AppLocalizations.of(context).emailPreviewNoContact}',
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeLabel,
                                color: AppTokens.textSecondaryColor(context),
                              ),
                            ),
                            const SizedBox(height: AppTokens.spacingXxs),
                            Text(
                              'Subject: $subject',
                              style: const TextStyle(
                                fontSize: AppTokens.fontSizeBody,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Divider(height: AppTokens.spacingLg),
                            SelectableText(
                              body,
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeBody,
                                height: AppTokens.lineHeightRelaxed,
                                color: AppTokens.textPrimaryColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const LoadingSkeleton.fullScreen(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppTokens.spacingMd),
                    child: ErrorState(
                      title: AppLocalizations.of(context).commonLoadFailed(''),
                      detail: e.toString(),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingMd),
                Container(
                  padding: const EdgeInsets.all(AppTokens.spacingSm),
                  decoration: BoxDecoration(
                    color: AppTokens.primaryLightColor(context),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Text(
                    AppLocalizations.of(context).emailPreviewDisclaimer,
                    style: AppTokens.textStyleLabel(context),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(''),
          detail: e.toString(),
        ),
      ),
    );
  }
}
