import 'package:drift/drift.dart';

/// 情绪日记表
///
/// 用户每天可记 1~N 次心情，存 4 维度分数（情绪/精力/睡眠/焦虑，各 1-5）+ 标签 JSON + 备注
/// 设计：1=很差 / 2=差 / 3=一般 / 4=好 / 5=很好
///
/// v0.18 round 18 (P1-15): 升级 4 维度
/// - score 仍是必填(情绪，老 schema 兼容)
/// - energy / sleep / anxiety 3 个新列 nullable(老数据没值，新数据 4 维全填)
/// - 焦虑反向计分: 1=严重 / 5=平静(UI 提示 "1=焦虑严重 5=完全平静")
///
/// v0.23 round 31 (P0 新功能): 语音录入 3 字段
/// - audioPath: 加密文件路径 (.m4a.enc), 独立 mood_audio/ 目录
/// - audioTranscript: 本地 STT 识别文字 (mobile 平台 speech_to_text 7.x
///   + web 平台 Chrome Web Speech API, 单次识别 60s 上限)
/// - audioDurationMs: 录音时长(毫秒), UI 显示用
/// - 3 列都 nullable, 老数据 / 纯文字模式自动为 null
@DataClassName('MoodEntry')
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 记录时间
  DateTimeColumn get timestamp => dateTime()();

  /// 情绪分数 1-5（必填,1=很差 5=很好）
  IntColumn get score => integer()();

  /// 精力分数 1-5（v0.18 P1-15 新增,1=很低 5=充沛）
  IntColumn get energy => integer().nullable()();

  /// 睡眠分数 1-5（v0.18 P1-15 新增,1=很差 5=很好）
  IntColumn get sleep => integer().nullable()();

  /// 焦虑分数 1-5（v0.18 P1-15 新增，反向:1=严重 5=平静）
  IntColumn get anxiety => integer().nullable()();

  /// 情绪标签 JSON 数组：'["焦虑","失眠"]'
  /// 选填，单选多个
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  /// 自由备注
  TextColumn get note => text().nullable()();

  // ===== v0.23 (Round 31) 语音录入字段 =====

  /// 加密 audio 文件路径（.m4a.enc）
  ///
  /// 独立于 vent audio，存储在 app docs/mood_audio/ 目录。
  /// 老数据 / 纯文字模式 = null。
  TextColumn get audioPath => text().nullable()();

  /// 本地 STT 识别文字
  ///
  /// 限制:
  /// - mobile: speech_to_text 7.x 平台内置 STT (on-device 优先)
  /// - web: Chrome Web Speech API (单次识别 60s 上限)
  /// - 3min 录音时只能识别前 60s
  /// 设备不支持 / 失败 = null(graceful degrade)。
  TextColumn get audioTranscript => text().nullable()();

  /// 录音时长(毫秒)
  ///
  /// 存储精度 = ms,UI 按秒/分秒显示。
  IntColumn get audioDurationMs => integer().nullable()();

  // ===== v0.29 round 84 (CBT 思维记录) 字段 =====

  /// 5/7 栏第 1 栏"情境"
  TextColumn get situation => text().nullable()();

  /// 5/7 栏第 2 栏"自动思维"
  TextColumn get automaticThought => text().nullable()();

  /// 5/7 栏第 3 栏"支持自动思维的证据"
  TextColumn get evidenceFor => text().nullable()();

  /// 5/7 栏第 3 栏"反对自动思维的证据"
  TextColumn get evidenceAgainst => text().nullable()();

  /// 5/7 栏第 4 栏"替代思维"
  TextColumn get alternativeThought => text().nullable()();

  /// 5/7 栏第 4 栏"重新评分" (1-5)
  IntColumn get reratedScore => integer().nullable()();

  /// 7 栏"核心信念"
  TextColumn get coreBelief => text().nullable()();

  /// 7 栏"行为应对"
  TextColumn get behaviorResponse => text().nullable()();

  // ===== v0.30 round 91 (sub-spec 7 日常追踪) period 列 =====

  /// 心境时段标记 (morning / noon / evening / night / unspecified)
  ///
  /// 老 entry 兼容: nullable, 默认 'unspecified' (在 repository / UI 层
  /// 处理 'unspecified' 当 null)。4 段聚合 (心境图表按 4 段叠柱状/折线)。
  /// 简化 vs 4 张 mood_period 表 — 0 新表, 0 跨表 join。
  TextColumn get period => text().nullable()();

  /// v0.30 R101: 影响因素 JSON 数组
  ///
  /// 参照 Apple Health State of Mind 的影响因素标签系统。
  /// 6 大类 (关系/健康/活动/正念/天气/其他) 30+ 预设标签。
  /// 老数据 = '[]' (空列表)。
  TextColumn get influenceFactorsJson =>
      text().withDefault(const Constant('[]'))();

  /// v0.30 R101: 记录模式 ('momentary' / 'daily')
  ///
  /// 老数据 = null (仅新录音 dialog 有选择)。nullable 兼容老 entry。
  TextColumn get recordingMode => text().nullable()();
}
