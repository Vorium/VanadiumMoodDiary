// v0.32 R109 (god class 拆 round 4): 抽 AddMedicationFormValidator 纯函数
//
// 改前: `add_medication_page.dart` 598L god class, 内嵌 2 个 form 验证逻辑:
//   - `_nextStep` (line 66-77) name 字段非空检查 (硬编码 if)
//   - `_save` (line 87-128) dosage 数字解析 (line 92 `double.tryParse` 兜底为 0)
// 改后: 抽纯函数 validator 到 domain/logic, page 只负责 widget 渲染 +
// controller state. 跟 R108 抽 `medication_slot_calculator.dart` + R109 round 3
// 抽 `medication_page_stats_calculator.dart` 同款 (纯函数集中器).
//
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调
//   的纯函数, AGENTS.md 必读.

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';

/// 新增用药表单验证器 (R109 抽纯函数集中器)
///
/// 改前 2 个散落验证逻辑集中到 1 个纯函数类:
/// - `validateName` 名称非空检查
/// - `parseDosage` 数字解析 (兜底为 0, 跟原 `_save` line 92 行为 1:1)
/// - `canAdvance` 步骤 1 名称验证
/// - `toDraft` 完整 form state → MedicationDraft (跟原 `_save` 行为 1:1)
///
/// 0 副作用 0 Flutter: 不调 repo, 不读 prefs, 不调 plugin.
/// 字段验证跟 UI 渲染分离, 易单测 + 易复用 (未来 edit_medication_dialog
/// 也能用 `toDraft` 跟 `parseDosage`).
class AddMedicationFormValidator {
  // 不可实例化 — 纯函数类
  const AddMedicationFormValidator._();

  /// 名称非空验证
  ///
  /// 跟原 `_nextStep` (line 68) `text.trim().isEmpty` 行为 1:1
  /// 返回 null = 合法, 返回非空 String = 错误码
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'medication_name_required';
    }
    return null;
  }

  /// 数字解析
  ///
  /// 跟原 `_save` (line 92) `double.tryParse(...) ?? 0` 行为 1:1
  static double parseDosage(String? dosageText) {
    return double.tryParse(dosageText ?? '') ?? 0;
  }

  /// 步骤 1 (name) 能否前进
  ///
  /// 跟原 `_nextStep` (line 68-77) `if (_currentStep == 0 && name 空) return` 1:1
  static bool canAdvanceFromStep1(String? name) => validateName(name) == null;

  /// 完整 form state → MedicationDraft
  ///
  /// 跟原 `_save` (line 92-106) MedicationDraft 构造 1:1, 集中器方便
  /// unit test + edit_medication_dialog 复用.
  static MedicationDraft toDraft({
    required String name,
    required String dosageText,
    required DosageUnit dosageUnit,
    required List<HourMinute> times,
    required MedicationForm form,
    required int colorIndex,
  }) =>
      MedicationDraft(
        name: name.trim(),
        dosage: parseDosage(dosageText),
        dosageUnit: dosageUnit,
        times: times,
        form: form,
        colorIndex: colorIndex,
      );
}
