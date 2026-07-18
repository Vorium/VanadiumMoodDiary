import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/database/mappers/medication/medication_mapper.dart';
import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 首次设置引导页（3 步）
///
/// v0.6：
/// - 联系人：email 改 phone（中国大陆手机号 + 正则校验）
/// - 药物：从单一 SegmentedButton（1/2/3 次）改多药物列表
///   每个药物：name + dosage + dosageUnit(mg/片) + 多个 TimeOfDay
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  /// P0-6 fix: 加 1 步 consent (法律同意),变 4 步流程 (0=consent, 1=welcome,
  /// 2=medication, 3=done)。所有 3 勾选必勾才能继续。
  int _step = 0;

  // P0-6: 3 个法律勾选状态
  bool _consentUserAgreement = false;
  bool _consentPrivacyPolicy = false;
  bool _consentSensitiveData = false;

  // Step 1
  final _nameController = TextEditingController();
  final List<TextEditingController> _contactNameControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _contactPhoneControllers = [
    TextEditingController(),
  ];

  // Step 2：多药物列表
  final List<_MedDraft> _meds = [];

  // 防止完成按钮被重复点击导致重复 insert
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    for (final c in _contactNameControllers) {
      c.addListener(_onTextChanged);
    }
    for (final c in _contactPhoneControllers) {
      c.addListener(_onTextChanged);
    }
    for (final m in _meds) {
      m.attachListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    // v0.16 round 19 fix: 之前直接 setState，在 dispose 时 _MedDraft.controller.dispose()
    // 触发 listener，State 已 defunct，setState assert 失败。
    // 加 mounted check，dispose 阶段直接吞掉
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    for (final c in _contactNameControllers) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final c in _contactPhoneControllers) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final m in _meds) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppLocalizations.of(context).setupStep(_step + 1, 4),
      // v0.17 round 14 (P2-4): setup wizard step transition
      // 之前只设了 duration,没设 transitionBuilder / layoutBuilder.
      // 现在用 fade + slide-up (occasional 频度,user 1-3 次).
      // layoutBuilder 让新旧 child 在切换瞬间叠加,避免 height 跳变.
      child: AnimatedSwitcher(
        duration: AppTokens.durNormal,
        switchInCurve: AppTokens.curveDecelerate,
        switchOutCurve: AppTokens.curveAccelerate,
        transitionBuilder: (child, anim) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_step),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStepConsent();
      case 1:
        return _buildStepWelcome();
      case 2:
        return _buildStepMedication();
      case 3:
        return _buildStepDone();
      default:
        return _buildStepWelcome();
    }
  }

  // ============== Step 0: 法律同意 (P0-6 PIPL) ==============
  Widget _buildStepConsent() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingLg),
          const Icon(
            Icons.gavel_outlined,
            size: 56,
            color: AppTokens.primary,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            '使用前请阅读',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(
            '为遵守《个人信息保护法》(PIPL),本 App 处理您的健康医疗等'
            '敏感个人信息前,需要您明确、单独同意以下 3 份文件。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          _ConsentCheckRow(
            checked: _consentUserAgreement,
            label: '我已阅读并同意《用户协议》',
            onTap: () =>
                setState(() => _consentUserAgreement = !_consentUserAgreement),
            onView: () => _showLegalDocument(context, 'user_agreement'),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _ConsentCheckRow(
            checked: _consentPrivacyPolicy,
            label: '我已阅读并同意《隐私政策》',
            onTap: () =>
                setState(() => _consentPrivacyPolicy = !_consentPrivacyPolicy),
            onView: () => _showLegalDocument(context, 'privacy_policy'),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          _ConsentCheckRow(
            checked: _consentSensitiveData,
            label: '我已阅读并同意《敏感个人信息处理同意书》',
            onTap: () =>
                setState(() => _consentSensitiveData = !_consentSensitiveData),
            onView: () => _showLegalDocument(context, 'sensitive_data_consent'),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Builder(
            builder: (_) {
              final allChecked = _consentUserAgreement &&
                  _consentPrivacyPolicy &&
                  _consentSensitiveData;
              return ElevatedButton(
                onPressed: allChecked ? () => setState(() => _step = 1) : null,
                child: const Text('开始设置'),
              );
            },
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            '提示:您可以随时在「设置 → 法律与隐私」撤回同意。'
            '拒绝或撤回后,App 的相关功能将无法使用。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHint,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }

  // ============== Step 1：欢迎 + 联系人 ==============
  Widget _buildStepWelcome() {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            AppLocalizations.of(context).setupHello,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            AppLocalizations.of(context).setupIntro,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).setupName,
              hintText: AppLocalizations.of(context).setupNameHint,
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text(
            AppLocalizations.of(context).setupContacts,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeLabel,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          for (int i = 0; i < _contactPhoneControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _contactNameControllers[i],
                    decoration: InputDecoration(
                      labelText: '联系人 ${i + 1} 姓名',
                      hintText: '妈妈',
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  TextField(
                    controller: _contactPhoneControllers[i],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: '紧急联系人手机号 ${i + 1}',
                      hintText: '13800138000',
                    ),
                  ),
                ],
              ),
            ),
          if (_contactPhoneControllers.length < 3)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  final nameC = TextEditingController();
                  nameC.addListener(_onTextChanged);
                  _contactNameControllers.add(nameC);
                  final phoneC = TextEditingController();
                  phoneC.addListener(_onTextChanged);
                  _contactPhoneControllers.add(phoneC);
                });
              },
              child: Text(AppLocalizations.of(context).setupAddContact),
            ),
          const SizedBox(height: AppTokens.spacingXl),
          Builder(
            builder: (_) {
              final err = _validateWelcomeForm();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (err != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppTokens.spacingSm),
                      child: Text(
                        err,
                        style: const TextStyle(
                          color: AppTokens.error,
                          fontSize: AppTokens.fontSizeLabel,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed:
                        err == null ? () => setState(() => _step = 2) : null,
                    child: Text(AppLocalizations.of(context).setupNext),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 校验第一步表单。返回 null 表示通过，返回 String 是第一个错误信息。
  String? _validateWelcomeForm() {
    if (_nameController.text.trim().isEmpty) {
      return '请填写你的名字';
    }
    final phones = <String>[];
    for (int i = 0; i < _contactPhoneControllers.length; i++) {
      final phone = _contactPhoneControllers[i].text.trim();
      if (phone.isEmpty) continue;
      if (!PhoneValidator.isValid(phone)) {
        return '第 ${i + 1} 个联系人手机号格式不对（11 位数字）';
      }
      if (phones.contains(phone)) {
        return '第 ${i + 1} 个联系人手机号重复了';
      }
      phones.add(phone);
    }
    if (phones.isEmpty) {
      return '至少填 1 个紧急联系人手机号';
    }
    return null;
  }

  // ============== Step 2：药物列表 ==============
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
            '（可加多个药，每个药配自己的时间和剂量；跳过不影响打卡）',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          for (int i = 0; i < _meds.length; i++) ...[
            _buildMedCard(i),
            const SizedBox(height: AppTokens.spacingMd),
          ],
          if (_meds.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              decoration: BoxDecoration(
                color: AppTokens.primaryLight,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTokens.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      '还没添加药物。可以跳过——打卡不需要药物信息。',
                      style: TextStyle(
                        color: AppTokens.textSecondary,
                        fontSize: AppTokens.fontSizeLabel,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: AppTokens.spacingMd),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                final m = _MedDraft();
                m.attachListener(_onTextChanged);
                _meds.add(m);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('+ 添加药物'),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.10 (Round 4): 一键载入预置方案
          TextButton.icon(
            onPressed: () => _showPresetTemplatesSheet(),
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('📋 载入预置方案（4 种常见模式）'),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: _saving ? null : () => setState(() => _step = 1),
                child: const Text('← 上一步'),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _finishSetup,
                      child: Text(AppLocalizations.of(context).setupNext),
                    ),
                    if (_saving)
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
          ),
        ],
      ),
    );
  }

  Widget _buildMedCard(int index) {
    final m = _meds[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '药物 ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTokens.fontSizeBody,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTokens.error,
                  ),
                  tooltip: '删除这个药',
                  onPressed: () {
                    setState(() {
                      m.dispose();
                      _meds.removeAt(index);
                    });
                  },
                ),
              ],
            ),
            TextField(
              controller: m.nameController,
              decoration: const InputDecoration(
                labelText: '药名',
                // P0-5 fix: 改中性文案,避免《广告法》第 16 条 +《医疗广告
                // 管理办法》风险(原预填真实处方药通用名)。
                hintText: '请输入药盒上的名称（选填）',
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: m.dosageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: '剂量',
                      hintText: '40',
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: m.dosageUnit,
                    decoration: const InputDecoration(labelText: '单位'),
                    items: const [
                      DropdownMenuItem(value: 'mg', child: Text('mg')),
                      DropdownMenuItem(value: '片', child: Text('片')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => m.dosageUnit = v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
            const Text(
              '吃药时间（点 + 加）',
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.textSecondary,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int tIdx = 0; tIdx < m.times.length; tIdx++)
                  InputChip(
                    label: Text(_formatTime(m.times[tIdx])),
                    onDeleted: () {
                      setState(() => m.times.removeAt(tIdx));
                    },
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('加时间'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: m.times.isNotEmpty
                          ? m.times.last
                          : const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        // 同时间不去重，让用户自己决定
                        m.times.add(picked);
                        m.times.sort(
                          (a, b) => (a.hour * 60 + a.minute)
                              .compareTo(b.hour * 60 + b.minute),
                        );
                      });
                    }
                  },
                ),
              ],
            ),
            if (m.times.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '（不设置时间 = 不调度提醒，仅记录）',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 弹底部 sheet 让用户选预置方案
  ///
  /// v0.10 (Round 4) — 参考 Mood Tracker 预置习惯库。
  /// 选完方案后，_meds 列表被预填（替换或追加，二选一由用户决定）。
  Future<void> _showPresetTemplatesSheet() async {
    final result = await showModalBottomSheet<_TemplateApplyResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
                child: Text(
                  '📋 选择预置方案',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: AppTokens.spacingSm),
                child: Text(
                  '预置方案会填好药名 + 时间，你可以接着改。'
                  '最终服药请按医嘱核对。',
                  style: TextStyle(
                    color: AppTokens.textSecondary,
                    fontSize: AppTokens.fontSizeLabel,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              for (final t in kMedicationTemplates)
                Card(
                  child: ListTile(
                    leading:
                        Text(t.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(t.description),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => Navigator.of(ctx).pop(
                      _TemplateApplyResult(
                        template: t,
                        append: _meds.isNotEmpty,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppTokens.spacingMd),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      // 释放旧 _meds 的 controller
      for (final m in _meds) {
        m.dispose();
      }
      _meds.clear();

      for (final d in result.template.meds) {
        final m = _MedDraft()
          ..nameController.text = d.name
          ..dosageController.text = d.dosage == d.dosage.toInt()
              ? d.dosage.toInt().toString()
              : d.dosage.toString()
          ..dosageUnit = d.dosageUnit
          ..times.addAll(
            d.times.map((hm) => TimeOfDay(hour: hm.hour, minute: hm.minute)),
          );
        m.attachListener(_onTextChanged);
        _meds.add(m);
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '已载入：${result.template.name}（${result.template.meds.length} 个药）'
            '请核对药名和剂量'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============== Step 3：完成 ==============
  Widget _buildStepDone() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          const Center(child: Text('🌱', style: TextStyle(fontSize: 64))),
          const SizedBox(height: AppTokens.spacingLg),
          Center(
            child: Text(
              AppLocalizations.of(context).setupDoneTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Center(
            child: Text(
              AppLocalizations.of(context).setupDoneSubtitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            AppLocalizations.of(context).setupDailyRoutine,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(AppLocalizations.of(context).setupReminder1),
          Text(AppLocalizations.of(context).setupReminder2),
          Text(AppLocalizations.of(context).setupReminder3),
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            AppLocalizations.of(context).setupPrivacy,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(AppLocalizations.of(context).setupPrivacy1),
          Text(AppLocalizations.of(context).setupPrivacy2),
          Text(AppLocalizations.of(context).setupPrivacy3),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _step = 2),
                child: const Text('← 上一步'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: Text(AppLocalizations.of(context).setupStart),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============== 保存 ==============
  Future<void> _finishSetup() async {
    if (_saving) return;
    setState(() => _saving = true);

    final validationError = _validateWelcomeForm();
    if (validationError != null) {
      setState(() => _saving = false);
      return;
    }

    final userName = _nameController.text.trim();
    final contactList = <({String name, String phone, int sortOrder})>[];
    for (int i = 0; i < _contactPhoneControllers.length; i++) {
      final phone = _contactPhoneControllers[i].text.trim();
      if (phone.isEmpty) continue;
      final normalized = PhoneValidator.normalize(phone) ?? phone;
      final name = _contactNameControllers[i].text.trim().isEmpty
          ? 'Contact ${i + 1}'
          : _contactNameControllers[i].text.trim();
      contactList.add((name: name, phone: normalized, sortOrder: i));
    }

    final medicationList = <({
      String name,
      double dosage,
      String dosageUnit,
      List<HourMinute> times,
    })>[];
    for (final m in _meds) {
      final name = m.nameController.text.trim();
      if (name.isEmpty) continue; // 跳过空药物
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

    try {
      await ref.read(databaseProvider).saveSetup(
            userName: userName,
            contactList: contactList,
            medicationList: medicationList,
          );
      if (!mounted) return;

      // v0.7：重排所有 medication 的本地推送（每个 time 一个 zonedSchedule）
      final medications =
          await ref.read(medicationRepositoryProvider).watchAll().first;
      // v0.13 (Round 11): 4 层架构 — entity → Drift row 转换
      await ref.read(notificationServiceProvider).rescheduleMedicationReminders(
            medications.map((e) => e.toDriftRow()).toList(),
          );
      // 漏 1 天主动 push 安慰（上午 10 点检查）
      await ref
          .read(notificationServiceProvider)
          .scheduleSoftReminder(hour: 10, minute: 0);
      // fallback 通用打卡提醒
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(hour: 20, minute: 0);
      if (!mounted) return;

      if (mounted) {
        setState(() => _step = 3);
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${e.toString().split('\n').first}'),
            backgroundColor: AppTokens.error,
          ),
        );
      }
      developer.log(
        'setup _finishSetup error',
        name: 'SetupPage',
        error: e,
        stackTrace: st,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }
  }
}

/// 内存态的药物草稿
class _MedDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  String dosageUnit = 'mg';
  final List<TimeOfDay> times = [];

  void attachListener(VoidCallback cb) {
    nameController.addListener(cb);
    dosageController.addListener(cb);
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
  }
}

/// 预置方案应用结果（bottom sheet 返回）
class _TemplateApplyResult {
  final MedicationTemplate template;
  final bool append;
  const _TemplateApplyResult({required this.template, required this.append});
}

/// P0-6: 法律同意勾选行(checklist + 查看按钮)
class _ConsentCheckRow extends StatelessWidget {
  final bool checked;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onView;

  const _ConsentCheckRow({
    required this.checked,
    required this.label,
    required this.onTap,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: checked ? AppTokens.primaryLight : AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: checked ? AppTokens.primary : AppTokens.border,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            activeColor: AppTokens.primary,
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color:
                    checked ? AppTokens.textPrimary : AppTokens.textSecondary,
                fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: onView,
            child: const Text('查看'),
          ),
          const SizedBox(width: AppTokens.spacingXs),
        ],
      ),
    );
  }
}

/// P0-6: 显示法律 markdown 文档
Future<void> _showLegalDocument(
  BuildContext context,
  String name,
) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _LegalDocumentDialog(name: name),
  );
}

class _LegalDocumentDialog extends StatelessWidget {
  final String name;
  const _LegalDocumentDialog({required this.name});

  String get _title {
    switch (name) {
      case 'user_agreement':
        return '用户协议';
      case 'privacy_policy':
        return '隐私政策';
      case 'sensitive_data_consent':
        return '敏感个人信息处理同意书';
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_title),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder<String>(
          future: _loadAsset('assets/legal/$name.md'),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return LoadingSkeleton.fullScreen();
            }
            if (snap.hasError || !snap.hasData) {
              return const Center(
                child: Text('加载失败,请检查网络或重新打开 App'),
              );
            }
            return SingleChildScrollView(
              child: Text(
                snap.data!,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  height: 1.5,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Future<String> _loadAsset(String path) async {
    // 用 rootBundle 异步加载(避免 BuildContext 跨 async gap 警告)
    return rootBundle.loadString(path);
  }
}
