// v0.15 (Round 18) VentEntry — 树洞领域实体
//
// 4 层架构示范：domain 层 0 Flutter 0 dart:io 依赖。
// `audioPath` 存绝对路径，audio 文件本身在 app docs 目录（encrypted DB 之外）。
// 录音文件存在性检查 / 删除是 data 层职责（`VentAudioStorage`），不在 domain。
//
// 设计要点：
// - 不可变 + copyWith
// - hasText / hasAudio / isEmpty 业务方法
// - durationLabel 业务方法（"1分23秒"）
library;

import 'package:chroniccare/core/shared/domain_value.dart';

/// 树洞条目（领域实体）
///
/// 一条记录可同时有 text 和 audio（用户先录后补文字，或反过来）。
/// 两个都为空 = 不应保存。
class VentEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 文字内容（可空）
  final String? contentText;

  /// 录音文件绝对路径（可空）
  final String? audioPath;

  /// 录音时长（秒，可空）
  final int? audioDurationSec;

  /// 录音文件大小（字节，可空）
  final int? audioSizeBytes;

  const VentEntryEntity({
    required this.id,
    required this.timestamp,
    this.contentText,
    this.audioPath,
    this.audioDurationSec,
    this.audioSizeBytes,
  });

  // ===== 业务方法 =====

  /// 是否有文字内容
  bool get hasText => contentText != null && contentText!.trim().isNotEmpty;

  /// 是否有录音
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  /// 是否同时有 text + audio
  bool get isMixed => hasText && hasAudio;

  /// 是否为空条目（text 和 audio 都没有）
  bool get isEmpty => !hasText && !hasAudio;

  /// 录音时长的人类可读格式（"1分23秒" / "23秒" / "1分05秒"）
  String durationLabel() {
    final sec = audioDurationSec;
    if (sec == null) return '';
    if (sec < 60) return '$sec秒';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s == 0 ? '$m分' : '$m分${s.toString().padLeft(2, '0')}秒';
  }

  VentEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    DomainValue<String?>? contentText,
    DomainValue<String?>? audioPath,
    DomainValue<int?>? audioDurationSec,
    DomainValue<int?>? audioSizeBytes,
  }) {
    return VentEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      contentText: contentText == null ? this.contentText : contentText.value,
      audioPath: audioPath == null ? this.audioPath : audioPath.value,
      audioDurationSec:
          audioDurationSec == null ? this.audioDurationSec : audioDurationSec.value,
      audioSizeBytes:
          audioSizeBytes == null ? this.audioSizeBytes : audioSizeBytes.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VentEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.contentText == contentText &&
        other.audioPath == audioPath &&
        other.audioDurationSec == audioDurationSec &&
        other.audioSizeBytes == audioSizeBytes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        contentText,
        audioPath,
        audioDurationSec,
        audioSizeBytes,
      );

  @override
  String toString() =>
      'VentEntryEntity(id=$id, ts=$timestamp, text=${contentText?.length ?? 0}字, audio=${audioPath != null})';
}
