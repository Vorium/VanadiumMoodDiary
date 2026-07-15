import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/utils/phone_validator.dart';
import '../../../../domain/entities/contact_entity.dart';
import '../../../../l10n/strings.dart';
import '../../../../theme/app_tokens.dart';
import '../../../providers/core_providers.dart';

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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: Text('还没有联系人，请先添加',
              style: TextStyle(color: AppTokens.textHint)),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < contacts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.person_outline, color: AppTokens.primary),
              title: Text(contacts[i].name),
              subtitle: Text(contacts[i].phone),
              trailing: _deleting.contains(contacts[i].id)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTokens.error),
                      onPressed: () => _deleteContact(contacts[i].id),
                    ),
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add, color: AppTokens.primary),
            title: const Text(Strings.setupAddContact),
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
      await ref.read(contactRepositoryProvider).delete(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
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
            title: const Text('添加紧急联系人'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '姓名'),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手机号',
                    hintText: '13800138000',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text(Strings.commonCancel),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  final phone = phoneController.text.trim();
                  if (phone.isEmpty) return;
                  if (!PhoneValidator.isValid(phone)) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('手机号格式不对（11 位数字）')),
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
                        SnackBar(content: Text('保存失败：$e')),
                      );
                      setLocal(() => saving = false);
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(Strings.commonSave),
                    if (saving)
                      const IgnorePointer(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
