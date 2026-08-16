// 规则 3 标记: 量表中文 fallback — v1.0+ i18n (R51b backlog, 显示层走 l10n)
// DSM-5 Level 2 精神病性症状量表 (成人)
//
// 数据来源: APA 公开 PROMIS / DSM-5 Level 2 精神病症状简化版
// (代表 5-9 题原 PROMIS bank, 8 题覆盖核心症状: 现实检验异常 / 幻觉 / 妄想 / 思维紊乱)
//
// 题数: 8
// 选项: 0-3 (从来没有 / 很少 / 有时 / 经常, 共 4 档)
// 总分: 0-24
//
// 严重度切分 (4 档):
// 0-5  → 无精神病性症状
// 6-10 → 轻度
// 11-15 → 中度 (建议就医)
// 16-24 → 重度 (强烈建议就医)
//
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// R60 AssessmentScale interface 复用, 题目硬编中文 (Task 6 走 ARB 翻译)
//
// 危机信号: 不触发 (公开量表, 走 PHQ-9 第 9 题)

import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';

/// DSM-5 Level 2 精神病性症状量表 (成人) 实现
class Level2PsychosisScale implements AssessmentScale {
  @override
  final ScaleTranslations translations;
  const Level2PsychosisScale({
    this.translations = const StaticScaleTranslations(),
  });

  @override
  String get id => 'level2_psychosis';

  // v0.32 round 8 (R111 E4/R111-02 fix): 走 translations (跟 phq9 一致)
  @override
  String get displayName => translations.level2PsychosisName();

  @override
  String get shortDescription => translations.level2PsychosisShortDescription();

  @override
  String get instruction => translations.level2PsychosisInstruction();

  @override
  List<AssessmentItem> get items => const [
        AssessmentItem(0, '听到别人听不到的声音'),
        AssessmentItem(1, '觉得有人想伤害您'),
        AssessmentItem(2, '觉得有人在监视您'),
        AssessmentItem(3, '觉得自己的思维被控制或被广播'),
        AssessmentItem(4, '看到别人看不到的东西'),
        AssessmentItem(5, '觉得自己的思维被打断或被插入'),
        AssessmentItem(6, '觉得周围的事情与自己有关'),
        AssessmentItem(7, '感到现实不太真实'),
      ];

  @override
  Map<int, String> get options => const {
        0: '从来没有',
        1: '很少',
        2: '有时',
        3: '经常',
      };

  @override
  int get totalRange => 24;

  @override
  List<SeverityCutoff> get severityCutoffs => const [
        SeverityCutoff(
          threshold: 5,
          rank: 0,
          label: '无症状', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '无精神病性症状',
        ),
        SeverityCutoff(
          threshold: 10,
          rank: 1,
          label: '轻度', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '轻度精神病性症状',
        ),
        SeverityCutoff(
          threshold: 15,
          rank: 2,
          label: '中度', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '中度精神病性症状, 建议就医',
        ),
        SeverityCutoff(
          threshold: 24,
          rank: 3,
          label: '重度', // v1.0+ i18n (R51b: 量表严重度/危机电话走 ARB backlog)
          summary: '重度精神病性症状, 强烈建议就医',
        ),
      ];

  @override
  AssessmentResult computeResult(List<int> scores) {
    final total = scores.fold<int>(0, (a, b) => a + b);
    final cutoff = severityCutoffs.firstWhere(
      (c) => total <= c.threshold,
      orElse: () => severityCutoffs.last,
    );
    return AssessmentResult(
      total: total,
      summary: cutoff.summary,
      recommendDoctorVisit: cutoff.rank >= 2,
      urgentDoctorVisit: cutoff.rank >= 3,
    );
  }

  @override
  CrisisSignal? detectCrisis(
    List<int> scores,
    AssessmentResult result, {
    HotlineRegion region = HotlineRegion.cn,
  }) =>
      null;
}

/// Level 2 精神病单例 (Task 2 注册表用)
const level2PsychosisScale = Level2PsychosisScale();
// rule3-whitelist: 48-55, 60-63
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
