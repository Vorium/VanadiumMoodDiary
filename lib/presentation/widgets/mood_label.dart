// v0.32 round 8 (R111 EM-21 fix): 情绪分数 → 本地化标签
//
// 背景: presentation 3 处用 core Strings.moodLabel / MoodVisual.labelFor 硬编码
// 中文, en locale 下显示中文。v5 ARB 新增 moodLabel1-5 键后统一走 l10n。
// domain/shared 层仍用 MoodVisual.labelFor (通知/邮件 fallback, 0 flutter)。
import 'package:chroniccare/l10n/app_localizations.dart';

/// 分数 (1-5) → 本地化情绪标签
String moodLabel(AppLocalizations l10n, int score) => switch (score) {
      1 => l10n.moodLabel1,
      2 => l10n.moodLabel2,
      3 => l10n.moodLabel3,
      4 => l10n.moodLabel4,
      5 => l10n.moodLabel5,
      _ => l10n.moodLabel3,
    };
