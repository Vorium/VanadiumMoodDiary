// v0.14 (Round 13A) 续方管理页面
//
// 集中查看所有药物的续方状态：
// - 每种药一行：药名 / 剂量 / 续方日期 / 距今天 X 天 / 状态徽章
// - 状态：未设 / 已设（远）/ 提醒中 / 已过期
// - 行点击 → 跳到该药的编辑对话框
//
// 数据源：MedicationEntity（domain）+ MedicationRepository（abstract）
// 业务方法直接用 entity.isInRefillWindow / .isRefillOverdue
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';

/// 续方状态
enum RefillStatus {
  /// 没设续方日期
  notConfigured,

  /// 续方日还在远处（> 提醒窗口）
  farFuture,

  /// 进入提醒窗口
  inWindow,

  /// 已过期
  overdue,
}

extension RefillStatusX on RefillStatus {
  String get label {
    switch (this) {
      case RefillStatus.notConfigured:
        return '未设置';
      case RefillStatus.farFuture:
        return '已设';
      case RefillStatus.inWindow:
        return '提醒中';
      case RefillStatus.overdue:
        return '已过期';
    }
  }

  Color get color => switch (this) {
        RefillStatus.notConfigured => AppTokens.textHint,
        RefillStatus.farFuture => AppTokens.primary,
        RefillStatus.inWindow => AppTokens.warning,
        RefillStatus.overdue => AppTokens.error,
      };
}

/// 续方管理
class RefillManagePage extends ConsumerWidget {
  const RefillManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    return PageScaffold(
      title: '续方管理',
      child: medsAsync.when(
        data: (meds) => _buildBody(context, ref, meds),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<MedicationEntity> meds,) {
    final now = DateTime.now();

    // 给每种药计算状态
    final rows = meds
        .map((m) => _Row(
              med: m,
              status: _statusFor(m, now),
              daysUntil: _daysUntilRefill(m, now),
            ),)
        .toList()
      ..sort((a, b) {
        // 状态优先级：已过期 > 提醒中 > 已设 > 未设置
        int rank(RefillStatus s) => switch (s) {
              RefillStatus.overdue => 0,
              RefillStatus.inWindow => 1,
              RefillStatus.farFuture => 2,
              RefillStatus.notConfigured => 3,
            };
        final r = rank(a.status).compareTo(rank(b.status));
        if (r != 0) return r;
        // 续方日近的排前面
        if (a.daysUntil != null && b.daysUntil != null) {
          return a.daysUntil!.compareTo(b.daysUntil!);
        }
        return a.med.name.compareTo(b.med.name);
      });

    // 顶部汇总
    final overdue = rows.where((r) => r.status == RefillStatus.overdue).length;
    final inWindow =
        rows.where((r) => r.status == RefillStatus.inWindow).length;
    final configured = rows.where((r) => r.med.hasRefill).length;

    return ListView(
      children: [
        const SizedBox(height: AppTokens.spacingMd),

        // 顶部汇总卡
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Row(
              children: [
                _Stat(label: '总药数', value: '${meds.length}'),
                const SizedBox(width: AppTokens.spacingMd),
                _Stat(label: '已设续方', value: '$configured'),
                const SizedBox(width: AppTokens.spacingMd),
                _Stat(
                  label: '提醒中',
                  value: '$inWindow',
                  valueColor: inWindow > 0 ? AppTokens.warning : null,
                ),
                const SizedBox(width: AppTokens.spacingMd),
                _Stat(
                  label: '已过期',
                  value: '$overdue',
                  valueColor: overdue > 0 ? AppTokens.error : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTokens.spacingMd),

        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppTokens.spacingXl),
            child: Center(
              child:
                  Text('还没有添加药物', style: TextStyle(color: AppTokens.textHint)),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  _RefillRow(
                    row: rows[i],
                    onTap: () => _editMedication(context, rows[i].med),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: AppTokens.spacingMd),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            '点击任一行可编辑续方日期。提醒窗口：续方前 N 天（N=reminderDays）。',
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHint,
            ),
          ),
        ),
      ],
    );
  }

  RefillStatus _statusFor(MedicationEntity m, DateTime now) {
    if (!m.hasRefill) return RefillStatus.notConfigured;
    if (m.isRefillOverdue(now)) return RefillStatus.overdue;
    if (m.isInRefillWindow(now)) return RefillStatus.inWindow;
    return RefillStatus.farFuture;
  }

  /// 按"天"计算 refill 距今多少天（负数=已过期 N 天；0=今天；正数=还有 N 天）
  ///
  /// 用 `m.refillAt.difference(today)` 而不是 `m.refillAt.difference(now)`，
  /// 避免时分秒导致的边界误差。
  static int _daysUntilRefill(MedicationEntity m, DateTime now) {
    if (m.refillAt == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(
      m.refillAt!.year,
      m.refillAt!.month,
      m.refillAt!.day,
    );
    return refillDay.difference(today).inDays;
  }

  Future<void> _editMedication(
    BuildContext context,
    MedicationEntity med,
  ) async {
    await showEditMedicationDialog(context, med);
  }
}

class _Row {
  final MedicationEntity med;
  final RefillStatus status;
  final int? daysUntil; // 负数 = 已过期
  const _Row({required this.med, required this.status, this.daysUntil});
}

class _RefillRow extends StatelessWidget {
  final _Row row;
  final VoidCallback onTap;
  const _RefillRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = row.med;
    final statusColor = row.status.color;
    return ListTile(
      onTap: onTap,
      leading: _StatusDot(status: row.status),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${m.name} ${_formatDose(m.dosage, m.dosageUnit)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: Text(
              row.status.label,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          _subtitleFor(row),
          style: const TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            color: AppTokens.textHint,
          ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTokens.textHint),
    );
  }

  String _subtitleFor(_Row r) {
    final m = r.med;
    if (!m.hasRefill) {
      return '未设续方日期 · 提醒窗口 ${m.refillReminderDays} 天';
    }
    final dateStr =
        '${m.refillAt!.year}-${m.refillAt!.month.toString().padLeft(2, '0')}-${m.refillAt!.day.toString().padLeft(2, '0')}';
    final days = r.daysUntil!;
    String suffix;
    if (days < 0) {
      suffix = '（已过 ${-days} 天）';
    } else if (days == 0) {
      suffix = '（今天）';
    } else {
      suffix = '（还有 $days 天）';
    }
    return '$dateStr $suffix · 提前 ${m.refillReminderDays} 天提醒';
  }

  String _formatDose(double d, String u) {
    final isInt = d == d.truncateToDouble();
    return '${isInt ? d.toInt() : d}$u';
  }
}

class _StatusDot extends StatelessWidget {
  final RefillStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        switch (status) {
          RefillStatus.notConfigured => Icons.help_outline,
          RefillStatus.farFuture => Icons.check,
          RefillStatus.inWindow => Icons.notifications_active,
          RefillStatus.overdue => Icons.warning_amber,
        },
        color: status.color,
        size: 18,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor; // null = 默认 textPrimary
  const _Stat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHint,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
