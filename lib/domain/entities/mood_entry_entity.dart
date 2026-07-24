// v0.14 (Round 12A) MoodEntryEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift。
// `tags` 暴露解析后的 `List<String>`（不再让 UI 调 `MoodRepository.decodeTags`）。
//
// v0.23 (Round 31) 语音录入新增 3 字段（mobile + web 一致行为）：
// - `audioPath` 加密文件路径(.m4a.enc)，独立于 vent audio
// - `audioTranscript` 本地 STT 识别文字
// - `audioDurationMs` 录音时长（毫秒，回放 UI 用）
//
// 设计要点：
// - 不可变（所有 final 字段 + copyWith）
// - `tagsJson` 仍保留（与数据库 schema 对齐），但 UI 用 `tags` getter
// - `score` 用 int 1-5，含 `scoreEmoji` / `scoreLabel` 便捷方法（通过 MoodVisual）
library;

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// 情绪记录（领域实体）
///
/// 字段含义见 `lib/data/database/tables/mood_entries.dart`。
class MoodEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 情绪分数 1-5（必填,1=很差 5=很好）
  final int score;

  /// 精力分数 1-5（v0.18 P1-15 新增,1=很低 5=充沛）
  /// 老数据为 null(单 score 模式)
  final int? energy;

  /// 睡眠分数 1-5（v0.18 P1-15 新增,1=很差 5=很好）
  final int? sleep;

  /// 焦虑分数 1-5（v0.18 P1-15 新增，反向:1=严重 5=平静）
  final int? anxiety;

  /// 标签 JSON 数组（数据库原值）
  ///
  /// UI / 业务代码应当使用 [tags] getter 拿解析后的 `List<String>`。
  final String tagsJson;

  /// 自由备注
  final String? note;

  /// v0.23 (Round 31) 语音录入：加密 audio 文件路径(.m4a.enc)
  ///
  /// 独立于 vent audio（隐私边界 + 各自 lifecycle）。
  /// 老数据 / 纯文字模式 = null。
  final String? audioPath;

  /// v0.23 (Round 31) 语音录入：本地 STT 识别文字
  ///
  /// **STT 限制说明**: speech_to_text 7.x + Chrome Web Speech API 单次识别 60s
  /// 上限,3min 录音只能识别前 60s,剩余部分不识别(UI 需提示用户)。
  /// 设备不支持 STT / 识别失败 = null(graceful degrade, 录音仍正常保存)。
  final String? audioTranscript;

  /// v0.23 (Round 31) 语音录入：录音时长(毫秒)
  ///
  /// 存储精度 = ms,UI 显示按秒 / 分秒。
  final int? audioDurationMs;

  const MoodEntryEntity({
    required this.id,
    required this.timestamp,
    required this.score,
    this.energy,
    this.sleep,
    this.anxiety,
    this.tagsJson = '[]',
    this.note,
    this.audioPath,
    this.audioTranscript,
    this.audioDurationMs,
  });

  // ===== 业务方法 =====

  /// 解析后的标签列表
  List<String> get tags => JsonCodec.decodeStringList(tagsJson);

  /// 分数是否在 1-5 范围内
  bool get isValidScore => score >= 1 && score <= 5;

  /// 是否 4 维度全填（v0.18 P1-15 新增）
  bool get isFull4D => energy != null && sleep != null && anxiety != null;

  MoodEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    int? score,
    int? energy,
    int? sleep,
    int? anxiety,
    String? tagsJson,
    DomainValue<String?>? note,
    DomainValue<String?>? audioPath,
    DomainValue<String?>? audioTranscript,
    DomainValue<int?>? audioDurationMs,
  }) {
    return MoodEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      energy: energy ?? this.energy,
      sleep: sleep ?? this.sleep,
      anxiety: anxiety ?? this.anxiety,
      tagsJson: tagsJson ?? this.tagsJson,
      note: note == null ? this.note : note.value,
      audioPath: audioPath == null ? this.audioPath : audioPath.value,
      audioTranscript: audioTranscript == null
          ? this.audioTranscript
          : audioTranscript.value,
      audioDurationMs: audioDurationMs == null
          ? this.audioDurationMs
          : audioDurationMs.value,
    );
  }

  /// v0.23 (Round 31): 是否有录音附件
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.score == score &&
        other.energy == energy &&
        other.sleep == sleep &&
        other.anxiety == anxiety &&
        other.tagsJson == tagsJson &&
        other.note == note &&
        other.audioPath == audioPath &&
        other.audioTranscript == audioTranscript &&
        other.audioDurationMs == audioDurationMs;
  }

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        score,
        energy,
        sleep,
        anxiety,
        tagsJson,
        note,
        audioPath,
        audioTranscript,
        audioDurationMs,
      );

  @override
  String toString() => 'MoodEntryEntity('
      'id=$id, score=$score, energy=$energy, sleep=$sleep, anxiety=$anxiety, '
      'tagsJson=$tagsJson, hasAudio=$hasAudio, '
      'audioDurationMs=$audioDurationMs, at=$timestamp)';
}
