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
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调
//   的纯函数, AGENTS.md 必读. 接受 phone validator 注入 (0 副作用).

import 'package:chroniccare/core/shared/phone_validator.dart';

/// Setup Step 1 (welcome) form 验证器 (R109 抽纯函数集中器)
///
/// 改前 1 个散落验证方法集中到 1 个纯函数类:
/// - `validateName` 名字非空检查
/// - `validatePhones` 手机号格式 + 重复校验 (接受 phone 列表, 返 null = 合法)
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

  /// 手机号列表验证 (格式 + 重复)
  ///
  /// 跟原 `_validateWelcomeForm` (line 263-279) 1:1:
  /// 1. 跳过空 phone (紧急联系人可选, 2026-07-31 病耻感 + 失联通信业务暂停)
  /// 2. 已填 phone 走 PhoneValidator.isValid
  /// 3. 已填 phone 之间不能重复
  ///
  /// 返回 null = 合法, 返回非空 String = 错误码
  static String? validatePhones(List<String> phones) {
    final filled = phones
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (filled.isEmpty) return null;
    for (final phone in filled) {
      if (!PhoneValidator.isValid(phone)) {
        return 'setup_validation_phone_invalid';
      }
    }
    final unique = filled.toSet();
    if (unique.length != filled.length) {
      return 'setup_validation_phone_duplicate';
    }
    return null;
  }

  /// Step 1 (welcome) 完整 form 验证
  ///
  /// 跟原 `_validateWelcomeForm` 1:1 整合, 接受 name + phones.
  /// 返回 null = 合法, 错误码 = 第一个不合法字段.
  static String? validateWelcomeForm({
    required String? name,
    required List<String> phones,
  }) {
    final nameError = validateName(name);
    if (nameError != null) return nameError;
    return validatePhones(phones);
  }
}
