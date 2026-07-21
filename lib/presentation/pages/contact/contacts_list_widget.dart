import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
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
              background: Container(
                alignment: Alignment.centerRight,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.spacingLg),
                color: AppTokens.error,
                child: Icon(
                  Icons.delete_outline,
                  // v0.22 round 30 (emil P2-6): 走 fgOnError
                  color: AppTokens.fgOnError(context),
                ),
              ),
              onDismissed: (_) => _swipeDeleteContact(contacts[i]),
              child: ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: AppTokens.primary,
                ),
                title: Text(contacts[i].name),
                subtitle: Text(contacts[i].phone),
                trailing: _deleting.contains(contacts[i].id)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: LoadingSpinner(size: 16),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTokens.error,
                        ),
                        onPressed: () => _deleteContact(contacts[i].id),
                      ),
              ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add, color: AppTokens.primary),
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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).commonActionDelete,
              error: e,),
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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).commonActionDelete,
              error: e,),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(contact.id));
    }
  }

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    bool saving = false;

    showDialog<void>(
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
                      labelText: AppLocalizations.of(context).contactNameLabel,),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).contactPhoneLabel,
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
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            AppSnackBar.info(
                              context,
                              AppLocalizations.of(context).snackbarPhoneInvalid,
                            ),
                          );
                          return;
                        }
                        setLocal(() => saving = true);
                        try {
                          await ref.read(contactRepositoryProvider).add(
                                name: nameController.text.trim().isEmpty
                                    ? 'Contact'
                                    : nameController.text.trim(),
                                phone: PhoneValidator.normalize(phone) ?? phone,
                                sortOrder: 99,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              AppSnackBar.error(
                                context,
                                action: AppLocalizations.of(context)
                                    .commonActionSave,
                                error: e,
                              ),
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
                      const IgnorePointer(
                        child: LoadingSpinner(
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
    });
  }
}
