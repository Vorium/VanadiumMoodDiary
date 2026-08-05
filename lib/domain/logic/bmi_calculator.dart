// v0.30 round 91 (sub-spec 7 日常追踪): BmiCalculator 纯函数
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R60 R90 calculator 模式一致。
//
// R91 brief: "BMI 读 profile.height — R91 没存 profile, calculator 接受
// heightCm 参数 (上层 dialog 读 profile)"。
// calculator 0 依赖 profile, 只接受数值, 应用层负责传 heightCm。

/// BMI 计算器
class BmiCalculator {
  BmiCalculator._();

  /// BMI = weightKg / (heightM * heightM)
  ///
  /// [heightCm] = null / 0 / 负数 → null (profile.height 缺失 / 边界保护)
  ///
  /// 中国成人 BMI 标准 (跟世界卫生组织 WHO 略有不同, 用 WHO 亚洲标准):
  /// - < 18.5 = 偏瘦
  /// - 18.5 - 24 = 正常
  /// - 24 - 28 = 超重
  /// - >= 28 = 肥胖
  static double? compute({required double weightKg, double? heightCm}) {
    if (heightCm == null || heightCm <= 0) return null;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// BMI → 分类 (4 档)
  ///
  /// [bmi] 0 / 负数 → 'underweight' (兜底, 不应发生)
  static String category(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 24) return 'normal';
    if (bmi < 28) return 'overweight';
    return 'obese';
  }
}
