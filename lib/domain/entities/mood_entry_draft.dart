// v0.24 round 48 (sp-en P1-14): MoodEntryDraft — add() 10 参 → draft 对象的参数对象
//
// 现状: MoodRepository.add() 有 10 个 named 参数 (score / tags / note /
// at / energy / sleep / anxiety / audioPath / audioTranscript / audioDurationMs),
// caller (mood_dialog) 调用时所有字段都挤一行, 视觉噪音大, 加新字段必
// 须改 signature + 所有 caller。round 31 加 audio 3 字段时已经经历一次
// breaking refactor, 再加字段会更痛。
//
// 改法: 引入 [MoodEntryDraft] 不可变参数对象, 封装"准备入库"的 mood entry。
// - add() signature 简化为 `add({required MoodEntryDraft draft})`
// - 新增字段时只改 MoodEntryDraft + repository.add() 内部, caller 不动
// - draft 是 named-only (除 score/tags 必填), 误传风险低
//
// MoodEntryDraft 是 domain 层概念 (0 flutter 0 drift), UI 层构造,
// repository 接收 + 翻译成 drift companion。

/// 准备入库的情绪记录草稿（参数对象）
///
/// v0.24 round 48 (sp-en P1-14) 抽 10 字段为 immutable data class。
///
/// `score` 1-5 必填, `tags` 可空列表 (允许 [])。
/// 4 维字段 (energy / sleep / anxiety) 老数据为 null (单 score 模式),
/// 新数据全填 = 4 维模式。
/// 语音录入 3 字段 (audioPath / audioTranscript / audioDurationMs) 老数据
/// / 纯文字模式 = null。
///
/// `at` 不传 = repository 用 DateTime.now() (跟之前 add() 默认行为一致)。
class MoodEntryDraft {
  /// 情绪分数 1-5（必填,1=很差 5=很好）
  final int score;

  /// 情绪标签（必填,允许空列表 = 无标签）
  final List<String> tags;

  /// 自由备注
  final String? note;

  /// 记录时间
  ///
  /// null = repository 用 DateTime.now() (caller 不必传, 跟旧 add() 行为一致)
  final DateTime? at;

  /// 精力分数 1-5
  final int? energy;

  /// 睡眠分数 1-5
  final int? sleep;

  /// 焦虑分数 1-5（反向,1=严重 5=平静）
  final int? anxiety;

  /// 加密 audio 文件路径 (.m4a.enc)
  final String? audioPath;

  /// STT 识别文字
  final String? audioTranscript;

  /// 录音时长（毫秒）
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
  /// 老 entry 兼容: null = repository 层当 'unspecified' 写 (跟老数据
  /// 不显式标 period 一致, 不破坏既有查询)。
  /// 4 段聚合 (mood_period_aggregator 跟 chart 读这一列分桶)。
  final String? period;

  /// v0.30 R101: 影响因素 JSON 数组
  ///
  /// 参照 Apple Health State of Mind 的影响因素标签系统。
  final String? influenceFactorsJson;

  /// v0.30 R101: 记录模式 ('momentary' / 'daily')
  final String? recordingMode;

  const MoodEntryDraft({
    required this.score,
    required this.tags,
    this.note,
    this.at,
    this.energy,
    this.sleep,
    this.anxiety,
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
    this.influenceFactorsJson,
    this.recordingMode,
  });
}
