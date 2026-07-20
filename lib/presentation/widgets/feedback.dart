// v0.21 Round 22 (P1-14 修复): 集中触感反馈 helper
//
// 之前 home_page 3 处直接 HapticFeedback.mediumImpact / lightImpact /
// selectionClick — 分散 + 命名不统一 (没"success"/"warning" 等语义)。
// 抽 Haptics helper 统一 5 类操作触感:
//
// - tap()         选项切换 (评分 / 评估题 / mood) → selectionClick (轻)
// - success()     保存 / 完成 (打卡成功 / 报告生成) → mediumImpact (中)
// - warning()     删除 / 销毁 (联系人删 / 树洞删) → heavyImpact (重)
// - light()       取消 / 关闭 → lightImpact (微)
//
// 命名 `Haptics` 而非 `Feedback` — Flutter `package:flutter/src/widgets/feedback.dart`
// 有同名类会冲突。
//
// 频度: tens/day (按按钮) — emil 不需要动画,只 haptic 即可
import 'package:flutter/services.dart';

class Haptics {
  Haptics._();

  /// 选项切换(轻触感,告诉用户"选项被选中")
  ///
  /// 适用:情绪日记 4 维评分切换 / 评估题选项 / mood 评分
  static Future<void> tap() => HapticFeedback.selectionClick();

  /// 操作成功(中触感,告诉用户"操作生效")
  ///
  /// 适用:打卡成功 / snooze 5min 成功 / 报告生成
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// 危险操作(重触感,警示"删了不可恢复")
  ///
  /// 适用:删除联系人 / 树洞条目 / 报告历史
  static Future<void> warning() => HapticFeedback.heavyImpact();

  /// 轻量反馈(微触感,无负担)
  ///
  /// 适用:取消按钮 / dialog 关闭 / 切换 theme
  static Future<void> light() => HapticFeedback.lightImpact();
}
