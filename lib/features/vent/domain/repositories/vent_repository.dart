// v0.15 (Round 18) VentRepository — 树洞仓库 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
// 树洞数据完全独立于情绪日记，本仓库也不参与任何分析/通知/关怀。

import 'package:chroniccare/features/vent/domain/entities/vent_entry_entity.dart';

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
  /// [tagsJson] 标签 JSON 数组（1.1.0 round 5c 新增, 默认 '[]'）
  /// [at] 注入时间（测试用），默认 DateTime.now()
  ///
  /// text 和 audio 至少要有一个；都为空时抛 ArgumentError。
  /// 返回新插入的 id。
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    String? tagsJson,
    DateTime? at,
  });

  /// 删除单条
  ///
  /// 如果 [VentEntryEntity.audioPath] 不为空，**会同时删除 audio 文件**。
  /// 返回是否成功删除（false = 条目不存在）。
  Future<bool> delete(int id);

  /// 单条查询（按 id）
  Future<VentEntryEntity?> getById(int id);

  /// 恢复单条（用于 Dismissible 误删 Undo）
  ///
  /// 重新插入原 entry（id 会变 — drift auto-increment），
  /// 保留原 text / audio / 时长 / 大小。
  /// [originalTimestamp] 保留原 timestamp（用 add 的 at 参数注入）。
  /// 返回新 id。
  Future<int> restore(VentEntryEntity entry);

  /// v0.28 R82.5 (法务 Q7b 必改): 物理删除所有 vent 条目 + 全部 audio 文件
  ///
  /// PIPL §47 删除权: 撤回 vent 同意时, 用户选"立即删除"走此路径。
  /// 跟 [delete] 区别: 删单条 vs 删所有。返回删了几条 (供 UI 提示)。
  ///
  /// 事务保护: 删 DB 行 + 删 audio 文件包一个事务 (read audioPath 列表 →
  /// 事务删 DB → 循环删文件)。事务失败回滚, 但已删的文件不还原
  /// (FS 不可逆, 走 [VentAudioStorage.deleteAllWithRetry] 兜底重试 3 次)。
  Future<int> deleteAll();
}
