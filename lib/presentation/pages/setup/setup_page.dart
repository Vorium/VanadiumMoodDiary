import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/strings.dart';
import '../../../theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../widgets/page_scaffold.dart';

/// 首次设置引导页（3 步）
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  int _step = 0;

  // Step 1
  final _nameController = TextEditingController();
  final List<TextEditingController> _contactControllers = [
    TextEditingController(),
  ];

  // Step 2
  final _medNameController = TextEditingController();
  int _frequency = 1;

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _contactControllers) {
      c.dispose();
    }
    _medNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: Strings.setupStep(_step + 1, 3),
      child: AnimatedSwitcher(
        duration: AppTokens.durNormal,
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStepWelcome();
      case 1:
        return _buildStepMedication();
      case 2:
        return _buildStepDone();
      default:
        return _buildStepWelcome();
    }
  }

  Widget _buildStepWelcome() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Text(
            Strings.setupHello,
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(
            Strings.setupIntro,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: Strings.setupName,
              hintText: Strings.setupNameHint,
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            Strings.setupContacts,
            style: TextStyle(
              fontSize: AppTokens.fontSizeLabel,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          for (int i = 0; i < _contactControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
              child: TextField(
                controller: _contactControllers[i],
                decoration: InputDecoration(
                  labelText: '紧急联系人邮箱 ${i + 1}',
                  hintText: Strings.setupContactHint,
                ),
              ),
            ),
          if (_contactControllers.length < 3)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _contactControllers.add(TextEditingController());
                });
              },
              child: const Text(Strings.setupAddContact),
            ),
          const SizedBox(height: AppTokens.spacingXl),
          ElevatedButton(
            onPressed: _canGoNextFromWelcome() ? () => setState(() => _step = 1) : null,
            child: const Text(Strings.setupNext),
          ),
        ],
      ),
    );
  }

  bool _canGoNextFromWelcome() {
    if (_nameController.text.trim().isEmpty) return false;
    return _contactControllers.any((c) => c.text.trim().isNotEmpty);
  }

  Widget _buildStepMedication() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Text(
            '你常吃什么药？',
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(
            '（不用精确，没填不影响打卡）',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          TextField(
            controller: _medNameController,
            decoration: const InputDecoration(
              labelText: Strings.setupMedName,
              hintText: Strings.setupMedNameHint,
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            Strings.setupMedFrequency,
            style: TextStyle(
              fontSize: AppTokens.fontSizeLabel,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text(Strings.setupMedTimes1)),
              ButtonSegment(value: 2, label: Text(Strings.setupMedTimes2)),
              ButtonSegment(value: 3, label: Text(Strings.setupMedTimes3)),
            ],
            selected: {_frequency},
            onSelectionChanged: (s) => setState(() => _frequency = s.first),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _step = 0),
                child: const Text('← 上一步'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _finishSetup,
                child: const Text(Strings.setupNext),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDone() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Center(child: Text('🌱', style: TextStyle(fontSize: 64))),
          const SizedBox(height: AppTokens.spacingLg),
          const Center(
            child: Text(
              Strings.setupDoneTitle,
              style: TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Center(
            child: Text(
              Strings.setupDoneSubtitle,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          const Text(Strings.setupDailyRoutine, style: TextStyle(fontSize: AppTokens.fontSizeBody, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(Strings.setupReminder1),
          const Text(Strings.setupReminder2),
          const Text(Strings.setupReminder3),
          const SizedBox(height: AppTokens.spacingXl),
          const Text(Strings.setupPrivacy, style: TextStyle(fontSize: AppTokens.fontSizeBody, fontWeight: FontWeight.w500)),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(Strings.setupPrivacy1),
          const Text(Strings.setupPrivacy2),
          const Text(Strings.setupPrivacy3),
          const SizedBox(height: AppTokens.spacingXl),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text(Strings.setupStart),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSetup() async {
    await ref.read(userProfileRepositoryProvider).save(
          userName: _nameController.text.trim(),
        );

    for (int i = 0; i < _contactControllers.length; i++) {
      final email = _contactControllers[i].text.trim();
      if (email.isEmpty) continue;
      await ref.read(contactRepositoryProvider).add(
            name: 'Contact ${i + 1}',
            email: email,
            sortOrder: i,
          );
    }

    if (_medNameController.text.trim().isNotEmpty) {
      await ref.read(medicationRepositoryProvider).add(
            name: _medNameController.text.trim(),
            frequencyPerDay: _frequency,
          );
    }

    await ref.read(notificationServiceProvider).scheduleDailyReminder(
          hour: 20,
          minute: 0,
        );

    if (mounted) {
      setState(() => _step = 2);
    }
  }
}
