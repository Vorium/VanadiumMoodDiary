import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/last_med_info.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';

/// 主页底部信息:last med + 底部"你还在线"文案
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
/// 复用 LastMedInfo widget 显示打卡时间 + 下次提醒。
class HomeFooter extends StatelessWidget {
  final CheckInEntity? lastCheckIn;
  final DateTime? nextReminder;
  final bool showStreakBroken;

  const HomeFooter({
    super.key,
    required this.lastCheckIn,
    required this.nextReminder,
    required this.showStreakBroken,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // v0.23 round 40 (emil F11 fix): stagger fade-in
        // 主页内容"逐项落入"的细微高级感,emil "30-80ms stagger = 累积成高级感"
        // HomeFooter 2 项 (LastMedInfo + homeStillOnline), 各 delay staggerStepMs
        FadeIn(
          // 0 * / 1 * staggerStepMs 是 stagger delay 视觉模式, 故意保留 0 * 显式
          // 表达"第 0 项 delay 0"的对称性 (下一行 1 * staggerStepMs 跟它对仗)
          // ignore: use_named_constants
          delay: const Duration(milliseconds: 0 * AppTokens.staggerStepMs),
          child: LastMedInfo(
            lastCheckIn: lastCheckIn?.timestamp,
            nextReminder: nextReminder,
            showStreakBroken: showStreakBroken,
          ),
        ),
        const SizedBox(height: AppTokens.spacingXl),
        FadeIn(
          delay: const Duration(milliseconds: 1 * AppTokens.staggerStepMs),
          child: Center(
            child: Text(
              AppLocalizations.of(context).homeStillOnline,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.fgHintInput(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
