// setup_widgets.dart — 首次设置引导页拆分出的辅助类和组件
//
// 从 setup_page.dart 拆分，v0.19 (P1-15)
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 新增 [SetupProgressBar] + [SetupStepHeader] 两个 helper widget。
// - SetupProgressBar: 顶部 4 段 hairline 进度条 (currentStep 控制高亮)
// - SetupStepHeader: 大标题 28pt + 副标题 15pt, Apple 引导流程
//   章节头 (跟 SectionHeader ALL CAPS 11pt 不同 — 这两个是 Hero 级别)。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/preset_med_l10n.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 内存态的药物草稿
///
/// v0.32 round 8 (R112-09 fix): 加 times 变更通知回调 —
/// 修前 `times` 是裸 List，MedCard 的 InputChip onDeleted / ActionChip 添加
/// 直接改 list 不触发任何通知 → 用户"删除、添加没反应"假 bug。修后
/// [addTime] / [removeTimeAt] 触发 [attachListener] 注册的回调（跟
/// nameController/dosageController listener 同款模式），接
/// SetupPageState._onTextChanged → setState 重建。
class MedDraft {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  String dosageUnit = 'mg';
  final List<TimeOfDay> times = [];

  VoidCallback? _onTimesChanged;

  void attachListener(VoidCallback cb) {
    nameController.addListener(cb);
    dosageController.addListener(cb);
    // v0.32 round 8 (R112-09): times 变更也走同一回调
    _onTimesChanged = cb;
  }

  /// v0.32 round 8 (R112-09): 添加服药时间 — 自动按 hour*60+minute 升序
  /// 排序 + 触发变更通知 (替代裸 `times.add` + 手动 sort)
  void addTime(TimeOfDay t) {
    times.add(t);
    times.sort(
      (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
    );
    _onTimesChanged?.call();
  }

  /// v0.32 round 8 (R112-09): 删除服药时间 — 触发变更通知
  /// (替代裸 `times.removeAt`)
  void removeTimeAt(int index) {
    times.removeAt(index);
    _onTimesChanged?.call();
  }

  /// v0.32 R112 (AR-20 批2a): 预置方案草稿 → 内存态草稿工厂
  ///
  /// 拆自 setup_page_state._showPresetTemplatesSheet 的 20L 构造逻辑
  /// (1:1): 药名走 i18n (spzh P2-G, 用户可编辑覆盖), 整数剂量去 .0,
  /// times 转 TimeOfDay。
  static MedDraft fromTemplate(MedicationDraft d, AppLocalizations l10n) {
    return MedDraft()
      ..nameController.text = d.nameL10n(l10n)
      ..dosageController.text = d.dosage == d.dosage.toInt()
          ? d.dosage.toInt().toString()
          : d.dosage.toString()
      ..dosageUnit = d.dosageUnit
      ..times.addAll(
        d.times.map((hm) => TimeOfDay(hour: hm.hour, minute: hm.minute)),
      );
  }

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    _onTimesChanged = null;
  }
}

/// 预置方案应用结果（bottom sheet 返回）
class TemplateApplyResult<T> {
  final T template;
  final bool append;
  const TemplateApplyResult({required this.template, required this.append});
}

/// 法律同意勾选行（checklist + 查看按钮）
class ConsentCheckRow extends StatelessWidget {
  final bool checked;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onView;

  const ConsentCheckRow({
    super.key,
    required this.checked,
    required this.label,
    required this.onTap,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: checked
            ? AppTokens.primaryLightColor(context)
            : AppTokens.surfaceColor(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: checked
              ? AppTokens.primaryColor(context)
              : AppTokens.borderColor(context),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // v0.22 round 29 (emil-50): activeColor 已 deprecated (Flutter 3.32+),
          // 改用 side + fillColor 控制 (M3 标准用法)
          Checkbox(
            value: checked,
            onChanged: (_) => onTap(),
            side: BorderSide(
              color: AppTokens.borderColor(context),
              width: 1.5,
            ),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTokens.primaryColor(context);
              }
              return null;
            }),
          ),
          Expanded(
            child: Text(
              label,
              // v0.31 round 10: 大字条款 — fontSizeBody (17pt) 替代 fontSizeLabel (15pt)
              // spec §5.2 "consent 项改 ALL CAPS section header + 大字条款"
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody, // 17 (iOS body)
                color: checked
                    ? AppTokens.textPrimaryColor(context)
                    : AppTokens.textSecondaryColor(context),
                fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          // v0.22 round 28 (emil-30): "查看" TextButton 外包 PressFeedback 给 scale 反馈
          // (10+/day 频度, emil 决策框架要求 :active 反馈)
          PressFeedback(
            child: TextButton(
              onPressed: onView,
              child: Text(AppLocalizations.of(context).setupConsentView),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),
        ],
      ),
    );
  }
}

// =====================================================================
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 顶部 4 段 hairline 进度条 (currentStep 控制高亮)
// =====================================================================

/// v0.31 round 10: setup 流程顶部 4 段 hairline 进度条
///
/// 设计 (spec §5.2):
/// - 4 段等宽小 hairline (每段 2pt 高, 圆角 1pt)
/// - currentStep (0-based) 之前段: 走 `primaryColor` (iOS systemGreen)
/// - currentStep 当前段: 走 `primaryColor` (同色, 视觉上 "已到这一段")
/// - currentStep 之后段: 走 `borderColor` 浅灰
/// - 段间 4pt 间距 (spacingXs), 整体 padding 走 pageMarginH (20)
/// - dark mode 自动走 `dividerDark` / `primaryColor` (Token 已处理)
///
/// 用法: 放在 `PageScaffold.appBarBottom`:
/// ```dart
/// PageScaffold(
///   appBarBottom: SetupProgressBar(currentStep: _step, totalSteps: 4),
///   child: ...,
/// )
/// ```
class SetupProgressBar extends StatelessWidget {
  /// 当前步骤 (0-based): 0 / 1 / 2 / 3
  final int currentStep;

  /// 总步骤数 (固定 4 — 0 consent / 1 welcome / 2 medication / 3 done)
  final int totalSteps;

  const SetupProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 4,
  });

  /// hairline 厚度 (iOS 极细线 — 跟 AppleListSection 的 0.5 风格统一)
  static const double _height = 3.0;

  /// hairline 圆角
  static const double _radius = 1.5;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTokens.primaryColor(context);
    final inactiveColor = AppTokens.borderColor(context);
    return Padding(
      // 横向 pageMarginH 跟主内容对齐, 纵向 0 (贴 AppBar 底)
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageMarginH,
        vertical: AppTokens.spacingXxs, // 4
      ),
      child: Row(
        children: [
          for (int i = 0; i < totalSteps; i++) ...[
            Expanded(
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: i <= currentStep ? activeColor : inactiveColor,
                  borderRadius: BorderRadius.circular(_radius),
                ),
              ),
            ),
            if (i < totalSteps - 1)
              const SizedBox(width: AppTokens.spacingXs), // 4
          ],
        ],
      ),
    );
  }
}

/// v0.31 round 10: setup 步骤大标题 + 副标题 (28pt + 15pt)
///
/// Apple 引导流程章节头 (跟 [SectionHeader] ALL CAPS 11pt 不同,
/// 这两个是 Hero 级别 — 大数字 + 大色块对比, 走 Apple style "Hello" 卡片):
/// - title 28pt w600 (AppTokens.fontSizeTitle, iOS Large Title 风格)
/// - subtitle 15pt secondary (AppTokens.fontSizeLabel, iOS subheadline)
/// - 间距 8pt (spacingXs) — Apple spec "标题下 8pt 副标题"
/// - 整体 padding 走 pageMarginH (20) 横向, 跟下方 form 块对齐
///
/// 用法:
/// ```dart
/// SetupStepHeader(
///   title: l10n.setupHello,
///   subtitle: l10n.setupIntro,
/// )
/// ```
class SetupStepHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SetupStepHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 横向 pageMarginH 跟主内容对齐, 顶部 spacingMd (16) 跟进度条分隔
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageMarginH,
        vertical: AppTokens.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            // 28pt w600 (Apple Large Title 风格) — fontSizeTitle token
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle, // 28
              fontWeight: FontWeight.w600,
              height: AppTokens.lineHeightTight,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTokens.spacingXs), // 8
            Text(
              subtitle!,
              // 15pt secondary (iOS subheadline) — fontSizeLabel token
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel, // 15
                color: AppTokens.textSecondaryColor(context),
                height: AppTokens.lineHeightNormal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
