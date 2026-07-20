import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/secondary_button.dart';
import 'package:chroniccare/presentation/pages/mood/mood_quick_button.dart';

/// 主页次要操作行：情绪日记快速按钮 + 树洞入口
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
///
/// 隐私边界（AGENTS.md）: 情绪日记不进 vent / care engine。
/// 树洞 (vent) 独立表，绝对不进任何分析、纯私密空间。
///
/// v0.21 Round 22 (P0-9): 树洞入口外包 PressFeedback 提供 scale 反馈。
/// MoodQuickButton 内部已自己处理 scale,不再外包。
class SecondaryActionRow extends StatelessWidget {
  final VoidCallback onMoodTap;

  const SecondaryActionRow({super.key, required this.onMoodTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MoodQuickButton(onTap: onMoodTap),
        const SizedBox(height: AppTokens.spacingSm),
        // v0.15 (Round 18) 树洞入口
        // 与情绪日记完全独立：树洞不进任何分析、纯私密空间
        PressFeedback(
          onTap: () => context.push('/vent'),
          child: SecondaryButton(
            onPressed: () {}, // PressFeedback 处理 tap
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.forest_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).homeVentButton,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeButton,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
