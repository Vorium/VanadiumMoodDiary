// v0.30 R101: 药物剂型枚举
//
// 参照 Apple Health Medications 的剂型分类。
// 存储用英文 id (跟 DosageUnit 模式一致)。

enum MedicationForm {
  tablet('tablet'),
  capsule('capsule'),
  liquid('liquid'),
  patch('patch'),
  injection('injection'),
  other('other');

  const MedicationForm(this.id);

  /// 存储到 DB 的字符串值
  final String id;

  /// 从 DB 字符串反序列化
  ///
  /// 容错: 未知 id 走 tablet (兜底)
  static MedicationForm fromId(String? id) {
    if (id == null) return tablet;
    for (final form in MedicationForm.values) {
      if (form.id == id) return form;
    }
    return tablet;
  }
}
