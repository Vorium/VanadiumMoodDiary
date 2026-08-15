// v0.32 R109 (god class 拆 round 5): 抽 SetupWelcomeFormValidator 纯函数
//
// 改前: `setup_page_state.dart` 560L 内嵌 `_validateWelcomeForm` (line ~252-282,
//   30L) form 验证逻辑:
//   - 名字非空检查
//   - 紧急联系人手机号格式校验 (PhoneValidator.isValid)
//   - 手机号重复校验 (set length vs list length)
// 改后: 抽纯函数 validator 到 domain/logic, state 只负责 widget 渲染 +
// controller 状态. 跟 R108 抽 `medication_slot_calculator.dart` + R109 round 3
// 抽 `medication_page_stats_calculator.dart` + R109 round 4 抽
// `add_medication_form_validator.dart` 同款 (纯函数集中器).
//
// 1.1.0 round 4 (emotion-first refactor): 联系人表单整摘后 phone 校验
// (validatePhones / setup_validation_phone_invalid / phone_duplicate)
// 无 caller, 删除。validator 只剩名字非空 1 项。
//
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调
//   的纯函数, AGENTS.md 必读.

/// Setup Step 1 (welcome) form 验证器 (R109 抽纯函数集中器)
///
/// 改前 1 个散落验证方法集中到 1 个纯函数类:
/// - `validateName` 名字非空检查
/// - `validateWelcomeForm` 整合 (返回 null 合法, 错误码字符串不合法)
///
/// 0 副作用 0 Flutter: 不调 repo, 不读 prefs, 不调 plugin.
/// 字段验证跟 UI 渲染分离, 易单测 + 易复用.
class SetupWelcomeFormValidator {
  // 不可实例化 — 纯函数类
  const SetupWelcomeFormValidator._();

  /// 名字非空验证
  ///
  /// 跟原 `_validateWelcomeForm` (line 256) `nameController.text.trim().isEmpty` 1:1
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'setup_validation_name_required';
    }
    return null;
  }

  /// Step 1 (welcome) 完整 form 验证
  ///
  /// 1.1.0 round 4: 联系人表单整摘后只验名字。
  /// 返回 null = 合法, 错误码 = 名字为空.
  static String? validateWelcomeForm({
    required String? name,
  }) {
    return validateName(name);
  }
}
