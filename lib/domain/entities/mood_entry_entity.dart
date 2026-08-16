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

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';

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

  // ===== v0.29 round 84 (CBT 思维记录) 字段 =====

  /// 5/7 栏第 1 栏"情境"
  final String? situation;

  /// 5/7 栏第 2 栏"自动思维"
  final String? automaticThought;

  /// 5/7 栏第 3 栏"支持自动思维的证据"
  final String? evidenceFor;

  /// 5/7 栏第 3 栏"反对自动思维的证据"
  final String? evidenceAgainst;

  /// 5/7 栏第 4 栏"替代思维"
  final String? alternativeThought;

  /// 5/7 栏第 4 栏"重新评分" (1-5)
  final int? reratedScore;

  /// 7 栏"核心信念"
  final String? coreBelief;

  /// 7 栏"行为应对"
  final String? behaviorResponse;

  // ===== v0.30 round 91 (sub-spec 7 日常追踪) 字段 =====

  /// 心境时段标记 (morning / noon / evening / night / unspecified)
  ///
  /// 老 entry 兼容: 老数据列值为 null — 业务层 (MoodPeriodAggregator /
  /// filteredMoodEntriesProvider) 把 null 当 'unspecified' 桶。
  /// 4 段聚合 (心境图表按 morning/noon/evening/night 叠柱状/折线)。
  final String? period;

  /// v0.30 R101: 影响因素 JSON 数组
  ///
  /// 参照 Apple Health State of Mind 的影响因素标签系统。
  /// 6 大类 (关系/健康/活动/正念/天气/其他) 30+ 预设标签。
  /// 老数据 = '[]' (空列表)。
  final String influenceFactorsJson;

  /// v0.30 R101: 记录模式 ('momentary' / 'daily')
  ///
  /// 老数据 = null (仅新录音 dialog 有选择)。
  final String? recordingMode;

  /// 状态短语（预设或自定义, 可空）
  final String? statusPhrase;

  /// v1.1.0 round 9 (F1 烦恼闭环): 关联的烦恼主题 id (可空)
  ///
  /// 记录时绑定到 [WorryThreadEntity]; 未绑定 = null。同一烦恼的多条
  /// 记录通过这个字段组成时间线。
  final int? worryThreadId;

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
    this.situation,
    this.automaticThought,
    this.evidenceFor,
    this.evidenceAgainst,
    this.alternativeThought,
    this.reratedScore,
    this.coreBelief,
    this.behaviorResponse,
    this.period,
    this.influenceFactorsJson = '[]',
    this.recordingMode,
    this.statusPhrase,
    this.worryThreadId,
  });

  // ===== 业务方法 =====

  /// 解析后的标签列表
  List<String> get tags => JsonCodec.decodeStringList(tagsJson);

  /// v0.30 R101: 解析后的影响因素列表
  List<String> get influenceFactors =>
      InfluenceCodec.decode(influenceFactorsJson);

  /// v0.30 R101: 是否有影响因素
  bool get hasInfluenceFactors => influenceFactors.isNotEmpty;

  /// 分数是否在 1-5 范围内
  bool get isValidScore => score >= 1 && score <= 5;

  /// 是否 4 维度全填（v0.18 P1-15 新增）
  bool get isFull4D => energy != null && sleep != null && anxiety != null;

  MoodEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    int? score,
    DomainValue<int?>? energy,
    DomainValue<int?>? sleep,
    DomainValue<int?>? anxiety,
    String? tagsJson,
    DomainValue<String?>? note,
    DomainValue<String?>? audioPath,
    DomainValue<String?>? audioTranscript,
    DomainValue<int?>? audioDurationMs,
    DomainValue<String?>? situation,
    DomainValue<String?>? automaticThought,
    DomainValue<String?>? evidenceFor,
    DomainValue<String?>? evidenceAgainst,
    DomainValue<String?>? alternativeThought,
    DomainValue<int?>? reratedScore,
    DomainValue<String?>? coreBelief,
    DomainValue<String?>? behaviorResponse,
    DomainValue<String?>? period,
    String? influenceFactorsJson,
    DomainValue<String?>? recordingMode,
    DomainValue<String?>? statusPhrase,
    DomainValue<int?>? worryThreadId,
  }) {
    return MoodEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      energy: energy == null ? this.energy : energy.value,
      sleep: sleep == null ? this.sleep : sleep.value,
      anxiety: anxiety == null ? this.anxiety : anxiety.value,
      tagsJson: tagsJson ?? this.tagsJson,
      note: note == null ? this.note : note.value,
      audioPath: audioPath == null ? this.audioPath : audioPath.value,
      audioTranscript: audioTranscript == null
          ? this.audioTranscript
          : audioTranscript.value,
      audioDurationMs: audioDurationMs == null
          ? this.audioDurationMs
          : audioDurationMs.value,
      situation: situation == null ? this.situation : situation.value,
      automaticThought: automaticThought == null
          ? this.automaticThought
          : automaticThought.value,
      evidenceFor: evidenceFor == null ? this.evidenceFor : evidenceFor.value,
      evidenceAgainst: evidenceAgainst == null
          ? this.evidenceAgainst
          : evidenceAgainst.value,
      alternativeThought: alternativeThought == null
          ? this.alternativeThought
          : alternativeThought.value,
      reratedScore:
          reratedScore == null ? this.reratedScore : reratedScore.value,
      coreBelief: coreBelief == null ? this.coreBelief : coreBelief.value,
      behaviorResponse: behaviorResponse == null
          ? this.behaviorResponse
          : behaviorResponse.value,
      period: period == null ? this.period : period.value,
      influenceFactorsJson: influenceFactorsJson ?? this.influenceFactorsJson,
      recordingMode:
          recordingMode == null ? this.recordingMode : recordingMode.value,
      statusPhrase:
          statusPhrase == null ? this.statusPhrase : statusPhrase.value,
      worryThreadId:
          worryThreadId == null ? this.worryThreadId : worryThreadId.value,
    );
  }

  /// v0.23 (Round 31): 是否有录音附件
  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  // ===== v0.29 round 84 CBT 业务方法 =====

  /// 是否 5/7 栏思维记录（任一 CBT 字段非空）
  bool get isCbtRecord =>
      situation != null ||
      automaticThought != null ||
      evidenceFor != null ||
      evidenceAgainst != null ||
      alternativeThought != null ||
      reratedScore != null ||
      coreBelief != null ||
      behaviorResponse != null;

  /// 推断档位: 7=coreBelief/behaviorResponse 非空, 5=任一 5/7 栏共享字段 (situation /
  ///   automaticThought / evidenceFor / evidenceAgainst / alternativeThought /
  ///   reratedScore) 非空, 3=其它
  int? get cbtLevel {
    if (coreBelief != null || behaviorResponse != null) return 7;
    if (alternativeThought != null ||
        reratedScore != null ||
        situation != null ||
        automaticThought != null ||
        evidenceFor != null ||
        evidenceAgainst != null) {
      return 5;
    }
    return null;
  }

  /// 重新评分差值 (rerated - score),仅 5/7 栏有 reratedScore 时返回
  double? get scoreShift {
    if (reratedScore == null) return null;
    return (reratedScore! - score).toDouble();
  }

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
        other.audioDurationMs == audioDurationMs &&
        other.situation == situation &&
        other.automaticThought == automaticThought &&
        other.evidenceFor == evidenceFor &&
        other.evidenceAgainst == evidenceAgainst &&
        other.alternativeThought == alternativeThought &&
        other.reratedScore == reratedScore &&
        other.coreBelief == coreBelief &&
        other.behaviorResponse == behaviorResponse &&
        other.period == period &&
        other.influenceFactorsJson == influenceFactorsJson &&
        other.recordingMode == recordingMode &&
        other.statusPhrase == statusPhrase &&
        other.worryThreadId == worryThreadId;
  }

  @override
  int get hashCode => Object.hashAll([
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
        situation,
        automaticThought,
        evidenceFor,
        evidenceAgainst,
        alternativeThought,
        reratedScore,
        coreBelief,
        behaviorResponse,
        period,
        influenceFactorsJson,
        recordingMode,
        statusPhrase,
        worryThreadId,
      ]);

  @override
  String toString() => 'MoodEntryEntity('
      'id=$id, score=$score, energy=$energy, sleep=$sleep, anxiety=$anxiety, '
      'tagsJson=$tagsJson, hasAudio=$hasAudio, '
      'audioDurationMs=$audioDurationMs, '
      'cbtLevel=$cbtLevel, '
      'situation=$situation, automaticThought=$automaticThought, '
      'evidenceFor=$evidenceFor, evidenceAgainst=$evidenceAgainst, '
      'alternativeThought=$alternativeThought, reratedScore=$reratedScore, '
      'coreBelief=$coreBelief, behaviorResponse=$behaviorResponse, '
      'period=$period, '
      'influenceFactors=$influenceFactorsJson, '
      'worryThreadId=$worryThreadId, '
      'at=$timestamp)';
}
