// AppSemantics — a11y 集中器
//
// v0.24 round 45 (emil P1-18): 替代散落 6 处裸 `Semantics(...)` 调用 + 1 处
// `ExcludeSemantics(...)`。emil "decisions should be nameable" — 3 种 a11y
// 模式抽 3 个工厂。
//
// 设计:
// - `container` 工厂: 描述整个区域 (TalkBack 读出 label, 整个区域为单一焦点)
// - `button` 工厂: 单选/复选按钮 (button: true + selected + inMutuallyExclusiveGroup)
// - `exclude` 工厂: 从 a11y 树排除 (用于内部 text 跟外面 label 重复时)
//
// 强制传 `label` 防止漏 a11y 描述 (TalkBack / VoiceOver 体验)。

import 'package:flutter/widgets.dart';

class AppSemantics {
  const AppSemantics._();

  /// 容器型 a11y 包装 — TalkBack/VoiceOver 把整个 child 读为单一焦点，朗读 label
  ///
  /// 适用:
  /// - 评分组件整体 (mood_rating container)
  /// - 评估题 (assessment question)
  /// - 时间窗口选择 (medication calendar segmented)
  /// - streak liveRegion 公告 (liveRegion: true)
  static Widget container({
    required String label,
    required Widget child,
    bool liveRegion = false,
  }) {
    return Semantics(
      container: true,
      label: label,
      liveRegion: liveRegion,
      child: child,
    );
  }

  /// 按钮型 a11y 包装 — 标记为可交互 button，支持 selected / 互斥分组
  ///
  /// 适用:
  /// - 评分按钮 1-5 分 (mood rating)
  /// - 单选/复选按钮 (inMutuallyExclusiveGroup: true)
  static Widget button({
    required String label,
    required Widget child,
    bool selected = false,
    bool inMutuallyExclusiveGroup = false,
  }) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
      child: child,
    );
  }

  /// 从 a11y 树排除 child — 用于内部 text 跟外层 container label 重复时
  ///
  /// 例: streak 数字外层 Semantics container 朗读 "已坚持 5 天"，
  /// 内部 Text 重复显示 "已坚持 5 天" — ExcludeSemantics 避免双重朗读
  static Widget exclude({required Widget child}) {
    return ExcludeSemantics(child: child);
  }
}
