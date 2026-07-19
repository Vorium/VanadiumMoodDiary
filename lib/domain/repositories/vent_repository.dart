// v0.15 (Round 18) VentRepository — 树洞仓库 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
// 树洞数据完全独立于情绪日记，本仓库也不参与任何分析/通知/关怀。
library;

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';

/// 树洞仓库（domain 接口）
///
/// 业务方法清单：
/// - [watchAll] - 监听所有树洞条目（按时间倒序）
/// - [add] - 新增树洞（text / audio / mixed）
/// - [delete] - 删除单条（同时删除关联的 audio 文件）
/// - [getById] - 单条查询
abstract class VentRepository {
  /// 监听所有树洞条目（按时间倒序）
  Stream<List<VentEntryEntity>> watchAll();

  /// 新增树洞条目
  ///
  /// [text] 文字内容（可空）
  /// [audioPath] 录音文件绝对路径（可空）
  /// [audioDurationSec] 录音时长（可空）
  /// [audioSizeBytes] 录音文件大小（可空）
  /// [at] 注入时间（测试用），默认 DateTime.now()
  ///
  /// text 和 audio 至少要有一个；都为空时抛 ArgumentError。
  /// 返回新插入的 id。
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    DateTime? at,
  });

  /// 删除单条
  ///
  /// 如果 [VentEntryEntity.audioPath] 不为空，**会同时删除 audio 文件**。
  /// 返回是否成功删除（false = 条目不存在）。
  Future<bool> delete(int id);

  /// 单条查询（按 id）
  Future<VentEntryEntity?> getById(int id);
}
