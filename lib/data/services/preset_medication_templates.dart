import 'package:flutter/material.dart';

/// 一个药物草稿（用于预置方案 + 手动录入之间的桥梁）
///
/// v0.10 (Round 4)：用户首次设置时点一下就能载入一整套方案，
/// 不用从零开始手填。参考 Mood Tracker (3h3.com) 的"预置习惯库"思路。
class MedicationDraft {
  /// 药名（中文常见抗抑郁/抗焦虑/抗精神病药名）
  final String name;
  /// 每次剂量
  final double dosage;
  /// 单位：mg / 片
  final String dosageUnit;
  /// 服药时间点（一天可以多次）
  final List<TimeOfDay> times;

  /// 可选：备注，标常见用途
  final String? hint;

  const MedicationDraft({
    required this.name,
    required this.dosage,
    required this.dosageUnit,
    required this.times,
    this.hint,
  });
}

/// 预置方案
class MedicationTemplate {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<MedicationDraft> meds;

  const MedicationTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.meds,
  });
}

/// 全部预置方案
///
/// 设计原则：
/// - 时间点取**国内精神心理患者常见服药节奏**（早 8 / 午 13 / 晚 20）
/// - 药名 + 剂量留 hint，**用户必须自己核对/修改**，app 不替代医嘱
/// - "自定义"是隐式选项：用户点"添加药物"按钮就是自定义路径
const kMedicationTemplates = <MedicationTemplate>[
  MedicationTemplate(
    id: 'mood_ssri_morning',
    name: '单药 · SSRI 早一次',
    emoji: '🌅',
    description: '1 种药，每天早 8 点服用（适用 SSRI / SNRI 类）',
    meds: [
      MedicationDraft(
        name: 'SSRI 类抗抑郁药',
        dosage: 1,
        dosageUnit: '片',
        times: [TimeOfDay(hour: 8, minute: 0)],
        hint: '常见：氟西汀 / 舍曲林 / 帕罗西汀 / 艾司西酞普兰',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'mood_mood_stabilizer_twice',
    name: '情绪稳定剂 · 早晚两次',
    emoji: '🌗',
    description: '1 种药，每天早 8 点 + 晚 20 点',
    meds: [
      MedicationDraft(
        name: '情绪稳定剂',
        dosage: 1,
        dosageUnit: '片',
        times: [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
        hint: '常见：碳酸锂 / 丙戊酸钠 / 拉莫三嗪',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'combo_ssri_bedtime',
    name: '联合 · 早抗抑郁 + 晚助眠',
    emoji: '🌓',
    description: '2 种药：早 8 点 SSRI + 晚 21 点助眠',
    meds: [
      MedicationDraft(
        name: 'SSRI 类抗抑郁药',
        dosage: 1,
        dosageUnit: '片',
        times: [TimeOfDay(hour: 8, minute: 0)],
      ),
      MedicationDraft(
        name: '助眠药',
        dosage: 1,
        dosageUnit: '片',
        times: [TimeOfDay(hour: 21, minute: 0)],
        hint: '常见：阿普唑仑 / 艾司唑仑 / 佐匹克隆 / 褪黑素',
      ),
    ],
  ),
  MedicationTemplate(
    id: 'combo_antipsychotic_full',
    name: '重性 · 早中晚三次',
    emoji: '🔁',
    description: '2 种药：早 8 / 午 13 / 晚 20，覆盖全天',
    meds: [
      MedicationDraft(
        name: '抗精神病药',
        dosage: 1,
        dosageUnit: '片',
        times: [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 13, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
        hint: '常见：奥氮平 / 利培酮 / 阿立哌唑 / 喹硫平',
      ),
      MedicationTemplateHelper.bedtimeAntipsychotic,
    ],
  ),
];

/// 模板助手：避免在多个模板里重复定义"晚间辅助药"
class MedicationTemplateHelper {
  static const bedtimeAntipsychotic = MedicationDraft(
    name: '镇静/抗焦虑辅助',
    dosage: 1,
    dosageUnit: '片',
    times: [TimeOfDay(hour: 21, minute: 30)],
    hint: '常见：喹硫平（小剂量）/ 苯二氮卓类',
  );
}
