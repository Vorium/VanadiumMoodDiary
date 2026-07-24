// v0.14 (Round 12A) MoodRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
//
// v0.23 (Round 31) 语音录入: add() 加 3 个 audio 参数 (audioPath / audioTranscript
// / audioDurationMs),纯文字模式老调用方不传 = 行为不变。
library;

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 情绪日记仓库（domain 接口）
abstract class MoodRepository {
  /// 监听所有情绪记录
  Stream<List<MoodEntryEntity>> watchAll();

  /// 监听今日情绪
  Stream<List<MoodEntryEntity>> watchToday();

  /// 添加一条
  ///
  /// v0.18 (P1-15) 4 维: energy / sleep / anxiety 3 个 optional,
  /// 不传 = 单 score 模式(向后兼容老调用方)。
  ///
  /// v0.23 (Round 31) 语音录入: audioPath / audioTranscript / audioDurationMs
  /// 3 个 optional 字段。audioPath 必填另两个(录音必须有文件,识别文字可空,
  /// 时长可空但建议填)。删除条目时 audioPath 对应的文件由 caller (page / service)
  /// 负责清理,repository 自身只管 DB 行。
  Future<int> add({
    required int score,
    required List<String> tags,
    String? note,
    DateTime? at,
    int? energy,
    int? sleep,
    int? anxiety,
    String? audioPath,
    String? audioTranscript,
    int? audioDurationMs,
  });

  /// 删除一条
  ///
  /// v0.23 (Round 31): 注意 — audio 文件**不**在这里删,caller (page/service)
  /// 拿到 id 后单独调 audio storage 删。repository 只管 DB 行,保持职责清晰。
  Future<int> delete(int id);
}
