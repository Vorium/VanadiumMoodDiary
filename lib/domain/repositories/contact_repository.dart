// v0.14 (Round 12A) ContactRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
library;

import '../entities/contact_entity.dart';

/// 紧急联系人仓库（domain 接口）
abstract class ContactRepository {
  /// 监听所有启用的联系人（按 sortOrder 升序）
  Stream<List<ContactEntity>> watchAll();

  /// 添加联系人
  Future<int> add({
    required String name,
    required String phone,
    int sortOrder = 0,
  });

  /// 更新（保留以备 API 稳定，UI 暂未调用）
  Future<bool> update(ContactEntity contact);

  /// 删除（物理删除）
  Future<int> delete(int id);
}
