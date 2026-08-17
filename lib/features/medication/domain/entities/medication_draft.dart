// v0.25 round 60: MedicationDraft value object
//
// 之前 MedicationRepository.add() 9 个参数 (spen 报告 P1 #12 #4),
// spen 建议抽 MedicationDraft value object 减少参数 list.
// R60 抽 MedicationDraft + add() 改用.
//
// R60 范围 (渐进 facade 模式):
//   1. MedicationDraft value object (本文件, 9 字段)
//   2. MedicationRepository.add() 改接受 MedicationDraft (不保留旧 API,
//      一次性替换, 编译失败强制 caller 更新 — 测试驱动迁移)
//   3. MedicationRepositoryImpl.add() 改接受 MedicationDraft
//   4. caller 更新 (setup_step_medication / edit_medication_dialog 等)
import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_form.dart';

/// v0.25 round 60 (spen P1 #12 #4): 药物草稿 value object
///
/// MedicationRepository.add() 之前 9 个参数 (spen 报告"11 个"是估算偏差,
/// 实际 9 个), 调用方写起来难维护, 也容易传错.
///
/// R60 抽 MedicationDraft 装 9 字段, 配合 copyWith 让 UI 编辑场景清晰.
class MedicationDraft {
  /// 药物名 (例: "舍曲林")
  final String name;

  /// 剂量数值 (例: 50.0)
  final double dosage;

  /// 剂量单位 (例: mg / ml / pill)
  final DosageUnit dosageUnit;

  /// 每日服药时间列表 (例: [HourMinute(8, 0), HourMinute(20, 0)])
  final List<HourMinute> times;

  /// 起始服药日期 (默认 = DateTime.now())
  final DateTime? startDate;

  /// 下次续方日期 (null = 不提醒续方)
  final DateTime? refillAt;

  /// 续方提醒提前天数 (例: 7 = 提前 7 天提醒)
  final int refillReminderDays;

  /// 是否启用 (false = 软停药, 保留打卡历史)
  final bool isActive;

  /// 停药日期 (isActive=false 时填, 默认 null)
  final DateTime? endDate;

  /// v0.30 R101: 剂型 (片剂/胶囊/口服液/贴剂/注射/其他)
  final MedicationForm form;

  /// v0.30 R101: 颜色索引 (0-5, 对应 6 种药丸颜色)
  final int colorIndex;

  /// v0.30 R101: 备注
  final String? notes;

  const MedicationDraft({
    required this.name,
    required this.dosage,
    required this.dosageUnit,
    required this.times,
    this.startDate,
    this.refillAt,
    this.refillReminderDays = 7,
    this.isActive = true,
    this.endDate,
    this.form = MedicationForm.tablet,
    this.colorIndex = 0,
    this.notes,
  });

  /// copyWith 模式 — UI 编辑场景 (e.g. 改 dosage 不动 name)
  ///
  /// v0.30 round 95 (sub-spec 7 R96c fix): nullable 字段 (startDate /
  /// refillAt / endDate) 走 [DomainValue] 包装, 区分"保持原值"(`null`) 跟
  /// "显式清空"(`DomainValue(null)`)。修前 [DateTime?] 无法区分二者, UI
  /// 编辑场景 (e.g. 取消续方) 没办法把字段显式清回 null。
  ///
  /// 模式跟 [DomainValue] 集中器 (lib/core/shared/domain_value.dart) 一致
  /// — 替代 drift 的 `Value<T>`, 保持 domain 层 0 drift 依赖。
  ///
  /// 不传 DomainValue (即传统 null) 走"保持原值"兼容老 caller;
  /// 传 `DomainValue(null)` 显式清空;
  /// 传 `DomainValue(dateTime)` 设新值。
  MedicationDraft copyWith({
    String? name,
    double? dosage,
    DosageUnit? dosageUnit,
    List<HourMinute>? times,
    DomainValue<DateTime?>? startDate,
    DomainValue<DateTime?>? refillAt,
    int? refillReminderDays,
    bool? isActive,
    DomainValue<DateTime?>? endDate,
    MedicationForm? form,
    int? colorIndex,
    DomainValue<String?>? notes,
  }) {
    return MedicationDraft(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      times: times ?? this.times,
      startDate: startDate != null ? startDate.value : this.startDate,
      refillAt: refillAt != null ? refillAt.value : this.refillAt,
      refillReminderDays: refillReminderDays ?? this.refillReminderDays,
      isActive: isActive ?? this.isActive,
      endDate: endDate != null ? endDate.value : this.endDate,
      form: form ?? this.form,
      colorIndex: colorIndex ?? this.colorIndex,
      notes: notes != null ? notes.value : this.notes,
    );
  }
}
