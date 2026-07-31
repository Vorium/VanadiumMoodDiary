// 树洞 audio metadata 序列化 + 校验 — v0.24 Sprint #5c (emil god class 拆解)
//
// **职责**: vent audio 字段 (duration / sizeBytes / hadAudio 标志) 序列化 + 边界校验
//
// **关键约束** (P0 隐私边界): vent audio 文件**不导出** (跨设备路径失效, app docs
// 目录路径在新设备无效)。只导出 metadata 引用 + `hadAudio` 标志。
// 重装 → 导入后, 文字会恢复, 录音会标 `hasAudio=false`。
//
// **来源**: v0.7 起 data_export_service 就只导 metadata, 不导文件本体;
// 校验逻辑原本散在 facade import 段 (line 441-451 max 86400s / 1GB hardcode),
// Sprint #5c 抽到 `ExportAudioService` + 复用 `ExportSchemaService.validateIntOr`。
//
// **emil 设计决策**:
// - "translucent decisions should be nameable" — audio 段 3 字段 + 2 max 边界独立命名
// - 复用 `ExportSchemaService.validateIntOr` 静态 helper, 不重复定义
// - 0 外部依赖 (pure map 操作 + 校验), 易测
// - `const` constructor (跟 `ExportSchemaService` 风格一致, 0 runtime cost)

import 'package:chroniccare/core/data/services/export/export_schema_service.dart';

/// 树洞 audio metadata 序列化 + 校验
///
/// 单一职责: vent audio 段 map 拼装 + duration / sizeBytes 边界校验
///
/// 边界常量:
/// - 86400 秒 = 24 小时 (单条录音上限, 跟 `MoodRecorder` maxReached 180s 无关,
///   这里是导入校验用的兜底上限, 防止坏数据写库)
/// - 1073741824 字节 = 1GB (单条录音大小上限, 跟 mood 录音实际 ~MB 级无关,
///   同样是导入校验兜底)
class ExportAudioService {
  const ExportAudioService();

  /// 序列化 vent 段 audio 字段
  ///
  /// 跨设备不可用 → `audioPath` 永不导出, 仅作 `hadAudio` 标志用
  /// (用户看到导出 JSON 里有 `hadAudio: true` 知道这条曾经有录音, 但点播放无效)
  ///
  /// **emil 决策**: `hadAudio` 是 1 个明确决策 (跨设备不可用的降级), 命名清晰
  Map<String, dynamic> buildAudioMetadata({
    required int? audioDurationSec,
    required int? audioSizeBytes,
    required String? audioPath, // 仅作 `hadAudio` 标志用
  }) {
    return {
      'audioDurationSec': audioDurationSec,
      'audioSizeBytes': audioSizeBytes,
      if (audioPath != null) 'hadAudio': true,
    };
  }

  /// 校验 + 解析 audio duration (秒) 字段 (import 时用)
  ///
  /// 边界: 0 ≤ x ≤ 86400 (24h), 失败用 `defaultValue` 兜底
  int parseAudioDurationSec(dynamic v, {int defaultValue = 0}) {
    return ExportSchemaService.validateIntOr(
      v,
      defaultValue,
      min: 0,
      max: 86400,
    );
  }

  /// 校验 + 解析 audio size (字节) 字段 (import 时用)
  ///
  /// 边界: 0 ≤ x ≤ 1073741824 (1GB), 失败用 `defaultValue` 兜底
  int parseAudioSizeBytes(dynamic v, {int defaultValue = 0}) {
    return ExportSchemaService.validateIntOr(
      v,
      defaultValue,
      min: 0,
      max: 1073741824,
    );
  }
}
