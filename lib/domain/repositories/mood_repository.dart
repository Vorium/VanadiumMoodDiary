// v0.14 (Round 12A) MoodRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
//
// v0.23 (Round 31) 语音录入: add() 加 3 个 audio 参数 (audioPath / audioTranscript
// / audioDurationMs),纯文字模式老调用方不传 = 行为不变。
//
// v0.24 round 48 (sp-en P1-14) add() 10 参 → MoodEntryDraft 参数对象:
// 之前 add() 10 个 named 参数, caller 调一行很挤, 加新字段必须改 signature
// + 所有 caller。抽 [MoodEntryDraft] 后 signature 简化为
// `add({required MoodEntryDraft draft})`, 加字段只改 draft + 内部映射。

import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 情绪日记仓库（domain 接口）
abstract class MoodRepository {
  /// 监听所有情绪记录
  Stream<List<MoodEntryEntity>> watchAll();

  /// 监听今日情绪
  Stream<List<MoodEntryEntity>> watchToday();

  /// 监听最新一条情绪（首页概览卡用，避免全表扫描）
  Stream<MoodEntryEntity?> watchLatest();

  /// 添加一条
  ///
  /// v0.24 round 48 (sp-en P1-14) 重构: 接收 [MoodEntryDraft] 参数对象,
  /// 替代之前 10 个 named 参数。draft 内字段语义跟旧 add() 一一对应:
  /// - score / tags 必填
  /// - note / at / energy / sleep / anxiety / audioPath / audioTranscript
  ///   / audioDurationMs 都 optional, 老数据 / 纯文字模式 = null
  /// - at null = repository 用 DateTime.now()
  ///
  /// v0.18 (P1-15) 4 维: energy / sleep / anxiety 3 个 optional,
  /// 不传 = 单 score 模式(向后兼容老调用方)。
  ///
  /// v0.23 (Round 31) 语音录入: audioPath / audioTranscript / audioDurationMs
  /// 3 个 optional 字段。audioPath 必填另两个(录音必须有文件,识别文字可空,
  /// 时长可空但建议填)。删除条目时 audioPath 对应的文件由 caller (page / service)
  /// 负责清理,repository 自身只管 DB 行。
  Future<int> add({required MoodEntryDraft draft});

  /// 删除一条
  ///
  /// v0.23 (Round 31): 注意 — audio 文件**不**在这里删,caller (page/service)
  /// 拿到 id 后单独调 audio storage 删。repository 只管 DB 行,保持职责清晰。
  Future<int> delete(int id);

  /// v1.1.0 round 9 (F1 烦恼闭环): 监听某个烦恼主题下的记录 (时间正序)
  Stream<List<MoodEntryEntity>> watchByThread(int threadId);
}
