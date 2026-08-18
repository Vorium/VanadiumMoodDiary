import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/last_med_info.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';

/// 主页底部信息:last med + 底部"你还在线"文案
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出。
/// 复用 LastMedInfo widget 显示打卡时间 + 下次提醒。
///
/// R114 Wave B2 (B2-8, emil F2): 加 [entryDuration] / [entryDelay] 门控 —
/// 修前 footer 2 项用 FadeIn 默认 400ms + 30ms stagger 且不接
/// homeEntryPlayedProvider, 每次 tab 切回主页重播 (Wave 7 门控了
/// header/checkin/summary 漏掉 footer)。
class HomeFooter extends StatelessWidget {
  final CheckInEntity? lastCheckIn;
  final DateTime? nextReminder;
  final bool showStreakBroken;

  /// 入场动画时长 (Wave 7 同款门控: entryPlayed → Duration.zero)
  final Duration entryDuration;

  /// 第 2 项 stagger delay (entryPlayed → Duration.zero)
  final Duration entryDelay;

  const HomeFooter({
    super.key,
    required this.lastCheckIn,
    required this.nextReminder,
    required this.showStreakBroken,
    this.entryDuration = AppTokens.durSlow,
    this.entryDelay = const Duration(milliseconds: AppTokens.staggerStepMs),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // v0.23 round 40 (emil F11 fix): stagger fade-in
        // 主页内容"逐项落入"的细微高级感,emil "30-80ms stagger = 累积成高级感"
        // HomeFooter 2 项 (LastMedInfo + homeStillOnline), 各 delay staggerStepMs
        FadeIn(
          duration: entryDuration,
          // 0 * staggerStepMs 是 stagger delay 视觉模式, 故意保留 0 * 显式
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
          duration: entryDuration,
          delay: entryDelay,
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
