// v1.1.0 round 9 (F4 树洞使用公约): 公约弹窗 helper (首次进入 vent compose)
//
// 抽独立文件: 让 vent_compose_page 保持 < 520 行守门 (A5 lock-in), 弹窗
// 逻辑 + 已读检查不进 orchestrator。
import 'package:flutter/material.dart';

import 'package:chroniccare/features/vent/data/services/vent_agreement_store.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 首次进入撰写页且未确认过公约 → 等首帧渲染完弹 dialog
///
/// [store] 由调用方 (initState 内 ref.read) 捕获传入, 避免异步间隙碰 ref
/// (E-01 同款约束); 点"我知道了"后标记已读, 之后不再弹。
Future<void> showVentAgreementIfNeeded(
  BuildContext context,
  VentAgreementStore store,
) async {
  if (await store.isAcknowledged()) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.ventAgreementTitle),
        content: SingleChildScrollView(
          child: Text(l10n.ventAgreementBody),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              store.acknowledge();
            },
            child: Text(l10n.ventAgreementConfirm),
          ),
        ],
      ),
    );
  });
}
