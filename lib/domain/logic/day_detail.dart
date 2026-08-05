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
//
// v0.28 round 65 (spzh P2-H 修复): `fromData` 加 `AppLocalizations l10n` 参数
// (可选, 不传 = 中文 fallback)，渲染事件 title 走 6 个 i18n key:
//   `dayDetailCheckInWith` / `dayDetailDailyCheckIn` /
//   `dayDetailTempWith` / `dayDetailTempMed` /
//   `dayDetailPhq9` / `dayDetailGad7`
// 老 caller (10 case test) 改传 mock l10n 走 i18n 路径。
//
// v0.27 round 75 (R74 报告 P1-1 部分修): 之前 `import 'package:chroniccare/l10n/app_localizations.dart'`
// 让 domain 间接 import Flutter, 违反 4 层架构纯度。R75 partial fix:
// 1/3 file (scale_translations.dart) 已迁出 AppLocalizationsScaleTranslations 到
// presentation/services/scale_translations_l10n.dart。
// 2/3 file (day_detail.dart + vent_entry_entity.dart) 留 R76 全修 — 改用
// closure 参数化注入 i18n 查找, 涉及 fromData / _renderCheckInLabel / _scaleName
// 6+ method 重构 + 10 case test 改, R75 时间紧 1 round 装不下, R76 单独 1 round
// 完成。

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

/// v0.27 round 77 (R76-N11 修): i18n closure 注入 typedef
///
/// 4 个 i18n key 走 closure 注入 (`dayDetailCheckInWith` /
/// `dayDetailDailyCheckIn` / `dayDetailTempWith` / `dayDetailTempMed`),
/// caller 传 `checkInLabel: (medName) => l10n.dayDetailCheckInWith(medName)` 等
/// 闭包即可, domain 0 flutter import 完全。
typedef CheckInLabelFn = String Function(String? medName);

/// v0.27 round 77 (R76-N11 修): 2 个 scale i18n closure 注入
/// (`dayDetailPhq9` / `dayDetailGad7`)。
typedef ScaleNameFn = String Function();

/// DayDetail 纯函数计算
class DayDetailCalculator {
  DayDetailCalculator._();

  /// 构造某天的 DayDetail
  ///
  /// [date] 任意时间点，函数取其"当天 0 点"作为边界
  /// [checkIns] / [moodEntries] 全集
  /// [medications] 全集（仅用来反查 medicationId → name）
  /// [checkInLabel] 可选 i18n — 不传 = 中文 fallback (单测用)
  /// [dailyLabel] 可选 i18n — 不传 = '每日打卡'
  /// [tempLabel] 可选 i18n — 不传 = '临时吃药'
  /// [phq9Name] / [gad7Name] 可选 i18n — 不传 = 'PHQ-9 抑郁筛查' / 'GAD-7 焦虑筛查'
  ///
  /// v0.27 round 77 (R76-N11 修): 之前 `AppLocalizations? l10n` 让 domain
  /// 间接 import Flutter。改用 6 个 closure 注入, domain 0 flutter 完全。
  static DayDetail fromData({
    required DateTime date,
    required List<CheckInEntity> checkIns,
    required List<MoodEntryEntity> moodEntries,
    required List<MedicationEntity> medications,
    CheckInLabelFn? checkInLabel,
    String Function()? dailyLabel,
    CheckInLabelFn? tempLabel,
    String Function()? tempDefaultLabel,
    ScaleNameFn? phq9Name,
    ScaleNameFn? gad7Name,
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
            title: _renderCheckInLabel(
              CheckInType.normal,
              medName: med?.name,
              checkInLabel: checkInLabel,
              dailyLabel: dailyLabel,
            ),
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
            title: parsed.name.isNotEmpty
                ? _renderCheckInLabel(
                    CheckInType.temp,
                    medName: parsed.name,
                    checkInLabel: tempLabel,
                    dailyLabel: tempDefaultLabel,
                  )
                : _renderCheckInLabel(
                    CheckInType.temp,
                    checkInLabel: tempLabel,
                    dailyLabel: tempDefaultLabel,
                  ),
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
            title: _scaleName(
              c.type.wire,
              phq9Name: phq9Name,
              gad7Name: gad7Name,
            ),
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

  /// 渲染打卡事件 title (i18n 化, closure=null 走中文 fallback)
  ///
  /// v0.28 round 65 (spzh P2-H 修复): 抽 helper 统一 5+ 处 '打卡 · ${name}' /
  /// '每日打卡' / '临时 · ${name}' / '临时吃药' / 'PHQ-9 抑郁筛查' /
  /// 'GAD-7 焦虑筛查' 硬编中文。传 closure 走 4 个 i18n key。
  /// v0.27 round 77 (R76-N11 修): 从 `AppLocalizations? l10n` 改 closure 注入
  /// (`checkInLabel` / `dailyLabel`)。
  static String _renderCheckInLabel(
    CheckInType type, {
    String? medName,
    CheckInLabelFn? checkInLabel,
    String Function()? dailyLabel,
  }) {
    if (checkInLabel != null) {
      switch (type) {
        case CheckInType.normal:
          if (medName != null) return checkInLabel(medName);
          return dailyLabel?.call() ?? '每日打卡';
        case CheckInType.temp:
          if (medName != null && medName.isNotEmpty) {
            return checkInLabel(medName);
          }
          return dailyLabel?.call() ?? '临时吃药';
        case CheckInType.phq9:
        case CheckInType.gad7:
        case CheckInType.isi:
        case CheckInType.pss:
        case CheckInType.whodas:
        case CheckInType.level2Depression:
        case CheckInType.level2Anxiety:
        case CheckInType.level2Mania:
        case CheckInType.asrm:
        case CheckInType.level2Psychosis:
          // 评估走 _scaleName 不用 _renderCheckInLabel
          break;
      }
    }
    // 中文 fallback (单测 / 老 caller 兼容)
    switch (type) {
      case CheckInType.normal:
        return medName != null ? '打卡 · $medName' : '每日打卡';
      case CheckInType.temp:
        return medName != null && medName.isNotEmpty ? '临时 · $medName' : '临时吃药';
      case CheckInType.phq9:
        return 'PHQ-9 抑郁筛查';
      case CheckInType.gad7:
        return 'GAD-7 焦虑筛查';
      case CheckInType.isi:
      case CheckInType.pss:
      case CheckInType.whodas:
      case CheckInType.level2Depression:
      case CheckInType.level2Anxiety:
      case CheckInType.level2Mania:
      case CheckInType.asrm:
      case CheckInType.level2Psychosis:
        // v0.30 round 91 (fix): R90 8 个新量表兜底, caller 走
        // _scaleName 拿量表 displayName (scale_registry) — 这里
        // 留中文兜底给单测, 实际 UI 渲染走 _scaleName 路径。
        return '心理量表评估';
    }
  }

  /// v0.27 round 77 (R76-N11 修): 改 closure 注入 (`phq9Name` / `gad7Name`),
  /// domain 0 flutter。
  static String _scaleName(
    String scaleId, {
    ScaleNameFn? phq9Name,
    ScaleNameFn? gad7Name,
  }) {
    if (phq9Name != null || gad7Name != null) {
      switch (scaleId) {
        case 'phq9':
          return phq9Name?.call() ?? 'PHQ-9 抑郁筛查';
        case 'gad7':
          return gad7Name?.call() ?? 'GAD-7 焦虑筛查';
        default:
          return scaleId;
      }
    }
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
