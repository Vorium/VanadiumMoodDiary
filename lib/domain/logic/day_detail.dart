// v0.14 (Round 12A) trend_page 日历视图：当天事件详情
//
// 把某天的所有 checkIns / moodEntries 转换为统一事件列表，
// 方便日历视图的"选中日详情"展示。
//
// 设计原则：
// - 纯函数：不依赖 Flutter
// - 跨日截断：用日期（年月日）匹配，不用 timestamp
// - 按时间正序：方便用户看"今天发生了什么"
// - 汇总统计：总打卡数 / 情绪数 / 评估数 / 最高最低分
//
// v0.14 升级：4 层架构 — 接受 CheckInEntity / MoodEntryEntity
library;

import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';

/// 当天事件类型
enum DayEventKind {
  /// 每日打卡（normal type）
  checkInNormal,

  /// 临时吃药（temp type）
  checkInTemp,

  /// 心理评估（phq9 / gad7 type）
  assessment,

  /// 情绪记录
  mood,
}

/// 当天一条事件
class DayEvent {
  /// 事件时间
  final DateTime time;

  /// 类型
  final DayEventKind kind;

  /// 主标题
  final String title;

  /// 副标题（可选）
  final String? subtitle;

  /// 情绪分（仅 mood）
  final int? moodScore;

  /// 情绪标签（仅 mood）
  final List<String> moodTags;

  /// 评估总分（仅 assessment）
  final int? assessmentTotal;

  /// 量表 id（仅 assessment）
  final String? assessmentScaleId;

  /// 关联 medication id（仅 check_in_normal / temp）
  final int? medicationId;

  /// 关联 medication 名（仅 check_in_normal / temp）
  final String? medicationName;

  const DayEvent({
    required this.time,
    required this.kind,
    required this.title,
    this.subtitle,
    this.moodScore,
    this.moodTags = const [],
    this.assessmentTotal,
    this.assessmentScaleId,
    this.medicationId,
    this.medicationName,
  });
}

/// 当天详情
class DayDetail {
  final DateTime date;
  final List<DayEvent> events; // 按时间正序

  /// 是否完全空（无任何事件）
  bool get isEmpty => events.isEmpty;

  /// normal 打卡数
  int get totalCheckIns =>
      events.where((e) => e.kind == DayEventKind.checkInNormal).length;

  /// 临时吃药数
  int get totalTempMeds =>
      events.where((e) => e.kind == DayEventKind.checkInTemp).length;

  /// 情绪记录数
  int get totalMoodEntries =>
      events.where((e) => e.kind == DayEventKind.mood).length;

  /// 评估数
  int get totalAssessments =>
      events.where((e) => e.kind == DayEventKind.assessment).length;

  /// 最高情绪分
  int? get bestMoodScore {
    final scores =
        events.where((e) => e.moodScore != null).map((e) => e.moodScore!);
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a > b ? a : b);
  }

  /// 最低情绪分
  int? get worstMoodScore {
    final scores =
        events.where((e) => e.moodScore != null).map((e) => e.moodScore!);
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a < b ? a : b);
  }

  /// 是否有完成每日打卡
  bool get hasNormalCheckIn => totalCheckIns > 0;

  const DayDetail({required this.date, required this.events});
}

/// DayDetail 纯函数计算
class DayDetailCalculator {
  DayDetailCalculator._();

  /// 构造某天的 DayDetail
  ///
  /// [date] 任意时间点，函数取其"当天 0 点"作为边界
  /// [checkIns] / [moodEntries] 全集
  /// [medications] 全集（仅用来反查 medicationId → name）
  /// [now] 可注入测试
  static DayDetail fromData({
    required DateTime date,
    required List<CheckInEntity> checkIns,
    required List<MoodEntryEntity> moodEntries,
    required List<MedicationEntity> medications,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final nextDay = day.add(const Duration(days: 1));

    // medication id → name 索引
    final medById = <int, MedicationEntity>{
      for (final m in medications) m.id: m,
    };

    final events = <DayEvent>[];

    // 1. check_ins
    for (final c in checkIns) {
      if (c.timestamp.isBefore(day) || !c.timestamp.isBefore(nextDay)) {
        continue;
      }
      final med = c.medicationId == null ? null : medById[c.medicationId!];
      if (c.isNormal) {
        events.add(
          DayEvent(
            time: c.timestamp,
            kind: DayEventKind.checkInNormal,
            title: med != null ? '打卡 · ${med.name}' : '每日打卡',
            subtitle: _timeLabel(c.timestamp),
            medicationId: c.medicationId,
            medicationName: med?.name,
          ),
        );
      } else if (c.isTemp) {
        final parsed = JsonCodec.parseTempMedNote(c.note);
        events.add(
          DayEvent(
            time: c.timestamp,
            kind: DayEventKind.checkInTemp,
            title: parsed.name.isNotEmpty ? '临时 · ${parsed.name}' : '临时吃药',
            subtitle: parsed.description.isNotEmpty
                ? '${_timeLabel(c.timestamp)} · ${parsed.description}'
                : _timeLabel(c.timestamp),
          ),
        );
      } else if (c.isAssessment) {
        // 评估总分：复用 AssessmentRecord.tryFromEntity 的正规 JSON 解析
        final record = AssessmentRecord.tryFromEntity(c);
        final total = record?.total;
        events.add(
          DayEvent(
            time: c.timestamp,
            kind: DayEventKind.assessment,
            title: _scaleName(c.type.wire),
            subtitle: total != null
                ? '${_timeLabel(c.timestamp)} · 总分 $total'
                : _timeLabel(c.timestamp),
            assessmentTotal: total,
            assessmentScaleId: c.type.wire,
          ),
        );
      }
      // 其他 type 忽略
    }

    // 2. mood_entries
    for (final m in moodEntries) {
      if (m.timestamp.isBefore(day) || !m.timestamp.isBefore(nextDay)) {
        continue;
      }
      final tags = m.tags;
      final parts = <String>[
        '${MoodVisual.emojiFor(m.score)} ${MoodVisual.labelFor(m.score)}',
      ];
      if (tags.isNotEmpty) parts.add(tags.join(' / '));
      if (m.note != null && m.note!.isNotEmpty) parts.add(m.note!);
      events.add(
        DayEvent(
          time: m.timestamp,
          kind: DayEventKind.mood,
          title: parts.first,
          subtitle: [
            _timeLabel(m.timestamp),
            if (tags.isNotEmpty) tags.join(' / '),
            if (m.note != null && m.note!.isNotEmpty) m.note!,
          ].where((s) => s.isNotEmpty).join(' · '),
          moodScore: m.score,
          moodTags: tags,
        ),
      );
    }

    // 按时间正序
    events.sort((a, b) => a.time.compareTo(b.time));

    return DayDetail(date: day, events: List.unmodifiable(events));
  }

  static String _timeLabel(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  static String _scaleName(String scaleId) {
    switch (scaleId) {
      case 'phq9':
        return 'PHQ-9 抑郁筛查';
      case 'gad7':
        return 'GAD-7 焦虑筛查';
      default:
        return scaleId;
    }
  }
}
