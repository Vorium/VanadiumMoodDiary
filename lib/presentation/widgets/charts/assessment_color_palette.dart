// v0.30 round 90 (sub-spec 6 量表中心): 量表色 + 线型 集中管理
//
// 12 量表多色多线型 (10 开放 + 2 unavailable 灰)。
// 色相分散, 色盲友好, 跟 R85 rerated chart 风格一致。
// 3 线型 (实线/虚线/点线) 按 scale index % 3 循环。
//
// 4 层架构: presentation 层, 返回 int (ARGB) 而非 Color (跟 MoodVisual 同款
// pattern)。presentation widget 把 ARGB int wrap 成 Color
// (e.g. `Color(AssessmentColorPalette.colorArgbFor(id))`)。
//
// 用法:
//   - 多线 chart 拿色: `Color(AssessmentColorPalette.colorArgbFor(scaleId))`
//   - chip avatar 拿色: `Color(AssessmentColorPalette.colorArgbFor(scaleId))`
//   - 拿线型 (fl_chart LineChartBarData.dashArray): `AssessmentColorPalette.dashFor(scaleId)`
//   - 遍历所有量表: `AssessmentColorPalette.allScaleIds`
//
// 顺序固定: 跟 lib/domain/logic/scale_registry.dart:allScales() 一一对应
// (PHQ-9 / GAD-7 / ISI / PSS / WHODAS / Level 2 Dep/Anx/Mania/Psy / ASRM)。
// NSESSS / CRDPSS 是 unavailable, 不在 10 个开放列表里, 不画线。

class AssessmentColorPalette {
  AssessmentColorPalette._();

  /// 顺序跟 scale_registry.allScales() 一一对应 (10 开放量表)
  static const List<String> _scaleIds = [
    'phq9', // 1. PHQ-9 抑郁筛查
    'gad7', // 2. GAD-7 广泛焦虑
    'isi', // 3. ISI 失眠严重指数
    'pss', // 4. PSS 压力量表
    'whodas', // 5. WHODAS 2.0 残疾评定
    'level2_depression', // 6. DSM-5 Level 2 抑郁严重度
    'level2_anxiety', // 7. DSM-5 Level 2 焦虑严重度
    'level2_mania', // 8. DSM-5 Level 2 躁狂严重度
    'asrm', // 9. ASRM 自评躁狂量表
    'level2_psychosis', // 10. DSM-5 Level 2 精神病性症状
  ];

  /// 所有 10 个开放量表 id (顺序固定, 跟 _scaleIds 一致)
  static const List<String> allScaleIds = _scaleIds;

  /// 10 开放量表 ARGB int 色 — 跟 _scaleIds index 一一对应
  /// 色相分散, 色盲友好:
  /// 蓝 / 红 / 绿 / 橙 / 紫 / 青 / 粉 / 棕 / 蓝紫 / 浅绿
  static const List<int> _colorArgbs = [
    0xFF1E88E5, // 1. PHQ-9 蓝
    0xFFE53935, // 2. GAD-7 红
    0xFF43A047, // 3. ISI 绿
    0xFFFB8C00, // 4. PSS 橙
    0xFF8E24AA, // 5. WHODAS 紫
    0xFF00ACC1, // 6. Level 2 Dep 青
    0xFFD81B60, // 7. Level 2 Anx 粉
    0xFF6D4C41, // 8. Level 2 Mania 棕
    0xFF3949AB, // 9. ASRM 蓝紫
    0xFF7CB342, // 10. Level 2 Psy 浅绿
  ];

  /// 3 线型 (实线/虚线/点线) — 按 scale index % 3 循环
  /// (fl_chart LineChartBarData.dashArray 接受 `List&lt;int&gt;` 表示 dash on/off 像素)
  static const List<List<int>> _dashArrays = [
    <int>[], // 实线 (index 0, 3, 6, 9)
    <int>[5, 5], // 虚线 (index 1, 4, 7)
    <int>[2, 3], // 点线 (index 2, 5, 8)
  ];

  /// 按 scaleId 拿色 (ARGB int, 找不到返 0xFF9E9E9E 深灰 兜底)
  ///
  /// UI 层 wrap: `Color(AssessmentColorPalette.colorArgbFor(scaleId))`
  static int colorArgbFor(String scaleId) {
    final idx = _scaleIds.indexOf(scaleId);
    if (idx < 0) return 0xFF9E9E9E;
    return _colorArgbs[idx % _colorArgbs.length];
  }

  /// 按 scaleId 拿线型 (找不到返 const [] 实线 兜底)
  ///
  /// UI 层直接传给 LineChartBarData.dashArray
  static List<int> dashFor(String scaleId) {
    final idx = _scaleIds.indexOf(scaleId);
    if (idx < 0) return const <int>[];
    return _dashArrays[idx % _dashArrays.length];
  }
}
