// v0.29 round 84 (CBT 思维记录): 顶部 ℹ️ 折叠说明卡
//
// 首次使用默认展开, 用户可手动折叠
//
// 设计:
// - StatefulWidget: 内部 _expanded 兜底, 让裸用 (test / 简单 caller) 可工作
// - 父组件提供 expanded+onToggle 时切外部控制 (CbtDraftState.showExplainer)
// - 任一为 null (expanded==null || onToggle==null) → 走内部 _expanded
// - 两者都给 → 走外部 (parent 控制 state, widget 只是 view)
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

class CbtExplainerCard extends StatefulWidget {
  final String title;
  final String body;
  final bool? expanded;
  final VoidCallback? onToggle;

  const CbtExplainerCard({
    super.key,
    required this.title,
    required this.body,
    this.expanded,
    this.onToggle,
  });

  @override
  State<CbtExplainerCard> createState() => _CbtExplainerCardState();
}

class _CbtExplainerCardState extends State<CbtExplainerCard> {
  bool _internalExpanded = true;

  bool get _isExternallyControlled =>
      widget.expanded != null && widget.onToggle != null;

  bool get _effectiveExpanded =>
      _isExternallyControlled ? widget.expanded! : _internalExpanded;

  void _handleToggle() {
    if (_isExternallyControlled) {
      widget.onToggle!();
    } else {
      setState(() => _internalExpanded = !_internalExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expanded = _effectiveExpanded;
    return Card(
      color: AppTokens.tintedPrimarySoft(context),
      child: InkWell(
        onTap: _handleToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: AppTokens.spacingXxs),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTokens.textStyleLabel(context),
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: AppTokens.spacingXs),
                Text(widget.body, style: AppTokens.textStyleBody(context)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
