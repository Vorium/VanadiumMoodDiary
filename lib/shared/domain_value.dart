/// 领域层 Value 包装器，替代 `package:drift/drift.dart` 的 `Value<T>`
///
/// 用于 copyWith 方法中区分"保持当前值"（传 null）和"清空为 null"（传 DomainValue(null)）。
///
/// domain 层不依赖 drift，所以 entity 的 copyWith 签名要用 `DomainValue<T>?` 而非 `Value<T>?`。
class DomainValue<T> {
  final T value;
  const DomainValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainValue<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DomainValue($value)';
}
