import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../l10n/strings.dart';
import '../../../theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/page_scaffold.dart';

/// 设置页
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final medsAsync = ref.watch(medicationsProvider);

    return PageScaffold(
      title: '设置',
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          const _SectionHeader(title: Strings.settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => _ContactsList(contacts: contacts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          const _SectionHeader(title: Strings.settingsMedication),
          const SizedBox(height: AppTokens.spacingSm),
          medsAsync.when(
            data: (meds) => _MedicationsList(meds: meds),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined, color: AppTokens.primary),
              title: const Text(Strings.settingsEmailPreview),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/email-preview'),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppTokens.primary),
              title: Text(Strings.settingsAbout),
              subtitle: Text('v0.1.0 · 我今天吃了药'),
            ),
          ),

          const Card(
            child: ListTile(
              leading: Icon(Icons.shield_outlined, color: AppTokens.textSecondary),
              title: Text(Strings.settingsDisclaimer),
              subtitle: Text('本应用不提供医疗建议，所有功能仅供参考。'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTokens.fontSizeLabel,
        color: AppTokens.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ContactsList extends ConsumerWidget {
  final List<Contact> contacts;

  const _ContactsList({required this.contacts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (contacts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: Text('还没有联系人，请先添加', style: TextStyle(color: AppTokens.textHint)),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < contacts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTokens.primary),
              title: Text(contacts[i].name),
              subtitle: Text(contacts[i].email),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTokens.error),
                onPressed: () async {
                  await ref
                      .read(contactRepositoryProvider)
                      .delete(contacts[i].id);
                },
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

  void _showAddContactDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              controller: emailController,
              decoration: const InputDecoration(labelText: '邮箱'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(Strings.commonCancel)),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              await ref.read(contactRepositoryProvider).add(
                    name: nameController.text.trim().isEmpty
                        ? 'Contact'
                        : nameController.text.trim(),
                    email: emailController.text.trim(),
                    sortOrder: 99,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(Strings.commonSave),
          ),
        ],
      ),
    );
  }
}

class _MedicationsList extends ConsumerWidget {
  final List<Medication> meds;

  const _MedicationsList({required this.meds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (meds.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.spacingMd),
          child: Text('还没添加常吃药', style: TextStyle(color: AppTokens.textHint)),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < meds.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.medication_outlined, color: AppTokens.primary),
              title: Text(meds[i].name),
              subtitle: Text('每日 ${meds[i].frequencyPerDay} 次'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTokens.error),
                onPressed: () async {
                  await ref.read(medicationRepositoryProvider).delete(meds[i].id);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
