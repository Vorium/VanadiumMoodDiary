import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:go_router/go_router.dart';

/// 紧急联系人列表 + 添加按钮
class ContactsListWidget extends ConsumerStatefulWidget {
  final List<ContactEntity> contacts;
  const ContactsListWidget({super.key, required this.contacts});

  @override
  ConsumerState<ContactsListWidget> createState() => _ContactsListWidgetState();
}

class _ContactsListWidgetState extends ConsumerState<ContactsListWidget> {
  final Set<int> _deleting = {};

  @override
  Widget build(BuildContext context) {
    final contacts = widget.contacts;
    if (contacts.isEmpty) {
      // v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState
      return EmptyState(
        icon: Icons.contacts_outlined,
        title: AppLocalizations.of(context).contactEmptyList,
        actionLabel: AppLocalizations.of(context).contactAddAction,
        onAction: () => GoRouter.of(context).push('/contacts/new'),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < contacts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            // v0.21 Round 23 (P1-26): swipe-to-dismiss 左滑删除
            Dismissible(
              key: ValueKey('contact-${contacts[i].id}'),
              direction: DismissDirection.endToStart,
              background: const SwipeDeleteBackground(),
              onDismissed: (_) => _swipeDeleteContact(contacts[i]),
              // v0.26 round 57 (emil C-12): 走 AppListTile.standard 集中器
              // 替代 inline ListTile (Dismissible 包裹, 不影响 ListTile 本身)
              child: AppListTile.standard(
                leading: Icon(
                  Icons.person_outline,
                  color: AppTokens.primaryColor(context),
                ),
                title: Text(contacts[i].name),
                subtitle: Text(contacts[i].phone),
                trailing: _deleting.contains(contacts[i].id)
                    ? const SizedBox(
                        width: AppTokens.spacingMd,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: LoadingSpinner(size: 16),
                        ),
                      )
                    : // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
                    PressFeedbackIconButton(
                        icon: Icons.delete_outline,
                        tooltip: AppLocalizations.of(context).commonDelete,
                        onPressed: () => _deleteContact(contacts[i].id),
                        color: AppTokens.errorColor(context),
                      ),
              ),
            ),
          ],
          const Divider(height: 1),
          // v0.24 round 43 (emil D-05 P2): 添加联系人入口包 AppListTile
          // → 隐式获得 PressFeedback scale 反馈 (tens/day 频度)
          AppListTile(
            leading: Icon(Icons.add, color: AppTokens.primaryColor(context)),
            title: Text(AppLocalizations.of(context).setupAddContact),
            onTap: () => _showAddContactDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(int id) async {
    if (_deleting.contains(id)) return;
    setState(() => _deleting.add(id));
    try {
      // v0.21 Round 22 (P1-14 修复): 删除前重触感警示
      await Haptics.warning();
      await ref.read(contactRepositoryProvider).delete(id);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonActionDelete,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  /// v0.21 Round 23 (P1-26): swipe-to-dismiss 触发
  ///
  /// 跟 IconButton 删除共享底层逻辑,但加 Undo snackbar 给反悔窗口。
  Future<void> _swipeDeleteContact(ContactEntity contact) async {
    if (_deleting.contains(contact.id)) return;
    setState(() => _deleting.add(contact.id));
    try {
      await ref.read(contactRepositoryProvider).delete(contact.id);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      AppSnackBar.undo(
        context,
        message: l10n.contactDeleted,
        onUndo: () async {
          await ref.read(contactRepositoryProvider).restore(contact);
        },
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonActionDelete,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(contact.id));
    }
  }

  /// v0.27 R71 (P5.4 修复): 改 Future<void> + try/finally 包 showDialog,
  /// 替代 .then() 残存模式。
  /// 之前用 .then((_) { dispose }) 是为了 dialog 关闭后清理 controllers,
  /// 但 .then() 模式已被 R17+R56b 标为 deprecated (emil 'async + await 优先')。
  /// try/finally 等价 + 异常路径更安全 (dialog 抛异常也会 dispose)。
  Future<void> _showAddContactDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context).contactAddTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context).contactNameLabel,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context).contactPhoneLabel,
                      hintText: '13800138000',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(ctx),
                  child: Text(AppLocalizations.of(context).commonCancel),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty) return;
                          if (!PhoneValidator.isValid(phone)) {
                            // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
                            AppSnackBar.showInfo(
                              context,
                              AppLocalizations.of(context).snackbarPhoneInvalid,
                            );
                            return;
                          }
                          setLocal(() => saving = true);
                          try {
                            // v0.27 round 62 (P0-2 修复): 先弹 ConsentDialog
                            // (PIPL §13 单独同意) → 用户同意才进 add()。
                            // 拒绝 → 弹 snackbar 提示, 不保存。
                            if (!ctx.mounted) return;
                            // v0.27 round 62 (P0-2 修复): 拿当前用户配置的失联阈值,
                            // 让 consent dialog 文案里的"连续 N 天"是用户自己的值。
                            final thresholdDays =
                                await SafetyConfigService().getThresholdDays();
                            final consent = await ConsentDialog.show(
                              context,
                              kind: ConsentKind.emergencyContactSharing,
                              thresholdDays: thresholdDays,
                            );
                            if (consent == null) {
                              // 用户拒绝, 退出 add 流程
                              if (ctx.mounted) {
                                setLocal(() => saving = false);
                                AppSnackBar.showInfo(
                                  context,
                                  AppLocalizations.of(context)
                                      .contactConsentReject,
                                );
                              }
                              return;
                            }
                            await ref.read(contactRepositoryProvider).add(
                                  // v0.27 round 62 (P1-10 修复): 改用 l10n key 而非
                                  // hardcode 英文 'Contact'。 en/zh/zh_Hant 三种语言
                                  // 都用 i18n key, 没填姓名时给合理的本地化默认值。
                                  name: nameController.text.trim().isEmpty
                                      ? AppLocalizations.of(context)
                                          .contactDefaultName
                                      : nameController.text.trim(),
                                  phone:
                                      PhoneValidator.normalize(phone) ?? phone,
                                  consentArtifact: consent,
                                  sortOrder: 99,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) {
                              // v0.27 round 59 (emil EMIL-T13): 用 showError 集中器
                              AppSnackBar.showError(
                                context,
                                action: AppLocalizations.of(context)
                                    .commonActionSave,
                                error: e,
                              );
                              setLocal(() => saving = false);
                            }
                          }
                        },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(AppLocalizations.of(context).commonSave),
                      if (saving)
                        IgnorePointer(
                          child: LoadingSpinner(
                            size: AppTokens.iconSizeInline,
                            color: AppTokens.fgOnPrimary(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      // v0.27 R71 (P5.4): try/finally 替代 .then(),
      // 异常路径也保证 dispose (race condition 防御)
      nameController.dispose();
      phoneController.dispose();
    }
  }
}
