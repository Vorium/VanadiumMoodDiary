import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';

/// 一个药物草稿（用于预置方案 + 手动录入之间的桥梁）
///
/// v0.10 (Round 4)：用户首次设置时点一下就能载入一整套方案，
/// 不用从零开始手填。参考 Mood Tracker (3h3.com) 的"预置习惯库"思路。
///
/// v0.16 (Round 19): `times` 从 `List<HourMinute>` 改为 `List<HourMinute>`，消除 flutter 依赖
///
/// v0.28 round 65 (spzh P2-G): `name` / `hint` 从硬编中文字符串 → i18n key
/// 字符串。template 的 name/description 同理 (`nameKey` / `descriptionKey`)。
///
/// v0.32 R112 (AR-16): `nameL10n` / `hintL10n` / `descriptionL10n` (原
/// 接受 AppLocalizations, data→l10n 循环) 移到 presentation extension
/// `lib/presentation/services/preset_med_l10n.dart` — 本文件 0 l10n 依赖,
/// 只保留 key 数据。
class MedicationDraft {
  /// i18n key for 药名 (e.g. "SSRI 类抗抑郁药")，caller 走
  /// presentation extension `nameL10n` 解析
  final String nameKey;

  /// 每次剂量
  final double dosage;

  /// 单位：mg / 片
  final String dosageUnit;

  /// 服药时间点（一天可以多次）
  final List<HourMinute> times;

  /// i18n key for 备注（标常见用途），caller 走
  /// presentation extension `hintL10n` 解析
  final String? hintKey;

  const MedicationDraft({
    required this.nameKey,
    required this.dosage,
    required this.dosageUnit,
    required this.times,
    this.hintKey,
  });
}

/// 预置方案
///
/// v0.28 round 65 (spzh P2-G): `name` / `description` 从硬编中文字符串
/// → i18n key 字符串。`id` / `emoji` 是数据
/// 不变 (id 是 wire 协议, emoji 是 visual 标识)。
///
/// v0.32 R112 (AR-16): `nameL10n` / `descriptionL10n` 移到 presentation
/// extension `lib/presentation/services/preset_med_l10n.dart`。
class MedicationTemplate {
  final String id;
  final String emoji;
  final String nameKey;
  final String descriptionKey;
  final List<MedicationDraft> meds;

  const MedicationTemplate({
    required this.id,
    required this.emoji,
    required this.nameKey,
    required this.descriptionKey,
    required this.meds,
  });
}

/// 全部预置方案
///
/// 设计原则：
/// - 时间点取**国内精神心理患者常见服药节奏**（早 8 / 午 13 / 晚 20）
/// - 药名 + 剂量留 hint，**用户必须自己核对/修改**，app 不替代医嘱
/// - "自定义"是隐式选项：用户点"添加药物"按钮就是自定义路径
/// v0.23 (P0-11): 去顶层 const, 内部 MedicationDraft 用 DosageUnit.tablet.id
/// (Dart const 表达式不支持 enum instance property access, 顶层 const 强制内部 const)
/// v0.28 round 65 (spzh P2-G): 内部 MedicationDraft 的 `name` / `hint` 改成
/// i18n key (String)，渲染时由 caller 走 presentation extension 解析。
final kMedicationTemplates = <MedicationTemplate>[
  MedicationTemplate(
    id: 'mood_ssri_morning',
    emoji: '🌅',
    nameKey: 'presetMedSsriMorningTitle',
    descriptionKey: 'presetMedSsriMorningDesc',
    meds: [
      MedicationDraft(
        nameKey: 'presetMedSsriName',
        dosage: 1,
        dosageUnit: DosageUnit.tablet.id,
        times: [const HourMinute(hour: 8, minute: 0)],
        // P0-5 fix: 改分类描述，避免《广告法》第 16 条 +
        // 《医疗广告管理办法》风险(原列 4 个真实处方药通用名)。
        hintKey: 'presetMedSsriHint',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'mood_mood_stabilizer_twice',
    emoji: '🌗',
    nameKey: 'presetMedMoodStabilizerTwiceTitle',
    descriptionKey: 'presetMedMoodStabilizerTwiceDesc',
    meds: [
      MedicationDraft(
        nameKey: 'presetMedMoodStabilizerName',
        dosage: 1,
        dosageUnit: DosageUnit.tablet.id,
        times: [
          const HourMinute(hour: 8, minute: 0),
          const HourMinute(hour: 20, minute: 0),
        ],
        // v0.21 Round 22 (P0-3 修复): 改分类描述。
        // 原 hint 列真实处方药通用名（碳酸锂 / 丙戊酸钠 / 拉莫三嗪），
        // 违反《广告法》§15（处方药不得在大众媒体做广告）。
        hintKey: 'presetMedMoodStabilizerHint',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'combo_ssri_bedtime',
    emoji: '🌓',
    nameKey: 'presetMedComboSsriBedtimeTitle',
    descriptionKey: 'presetMedComboSsriBedtimeDesc',
    meds: [
      MedicationDraft(
        nameKey: 'presetMedSsriName',
        dosage: 1,
        dosageUnit: DosageUnit.tablet.id,
        times: [const HourMinute(hour: 8, minute: 0)],
      ),
      MedicationDraft(
        nameKey: 'presetMedSleepAidName',
        dosage: 1,
        dosageUnit: DosageUnit.tablet.id,
        times: [const HourMinute(hour: 21, minute: 0)],
        // v0.21 Round 22 (P0-3 修复): 阿普唑仑 / 艾司唑仑是国家管制的
        // 二类精神药品（《精神药品品种目录》收录），褪黑素是保健品。
        // 改分类描述，避免《广告法》§15 处方药广告违规。
        // v0.27 round 59 (spzh §2.2 修正): 半角 / → 全角 ／ (medical abbreviation 风格)
        hintKey: 'presetMedSleepAidHint',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'combo_antipsychotic_full',
    emoji: '🔁',
    nameKey: 'presetMedComboAntipsychoticFullTitle',
    descriptionKey: 'presetMedComboAntipsychoticFullDesc',
    meds: [
      MedicationDraft(
        nameKey: 'presetMedAntipsychoticName',
        dosage: 1,
        dosageUnit: DosageUnit.tablet.id,
        times: [
          const HourMinute(hour: 8, minute: 0),
          const HourMinute(hour: 13, minute: 0),
          const HourMinute(hour: 20, minute: 0),
        ],
        // P0-5 fix: 改分类描述，避免广告法风险。
        hintKey: 'presetMedAntipsychoticHint',
      ),
      MedicationTemplateHelper.bedtimeAntipsychotic,
    ],
  ),
];

/// 模板助手：避免在多个模板里重复定义"晚间辅助药"
class MedicationTemplateHelper {
  static const bedtimeAntipsychotic = MedicationDraft(
    nameKey: 'presetMedSedativeAnxiolyticName',
    dosage: 1,
    dosageUnit: '片',
    times: [HourMinute(hour: 21, minute: 30)],
    // P0-5 fix: 改分类描述。
    // v0.27 round 59 (spzh §2.2 修正): 半角 / → 全角 ／
    hintKey: 'presetMedSedativeAnxiolyticHint',
  );
}
