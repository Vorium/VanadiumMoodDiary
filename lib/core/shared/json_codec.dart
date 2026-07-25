import 'dart:convert';

import 'package:chroniccare/core/shared/swallow_error.dart';

/// 统一 JSON 编解码工具（共享层：domain + data + presentation 均可使用）
///
/// 重要：所有存在 SQLite 中的 JSON 字段（mood tags、medication times、临时用药 note）
/// 都应该通过本工具读写，避免格式漂移。
class JsonCodec {
  JsonCodec._();

  // ====== `List<String>`（mood tags 等） ======

  /// 编码 `List<String>` → JSON 字符串
  ///
  /// 空列表统一返回 `'[]'`，便于数据库默认值与空值比较。
  static String encodeStringList(List<String> values) {
    if (values.isEmpty) return '[]';
    return jsonEncode(values);
  }

  /// 解码 JSON 字符串 → `List<String>`
  ///
  /// 容错：
  /// - 空字符串 / `'[]'` → `[]`
  /// - 解析失败 → `[]`（不抛异常，因为显示层宁愿空也不能崩）
  /// - 解析失败时通过 [swallowError] 记录,release 不打,debug 模式
  ///   走 `developer.log` 给排查留线索
  static List<String> decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (e, st) {
      // v0.23 round 39 (P1-10 fix): 不再 `catch (_)` 完全静默,
      // 走 swallowError 集中器,release 模式不打印,debug 模式打 developer.log
      swallowError(
        where: 'JsonCodec.decodeStringList',
        error: e,
        stack: st,
        note: '解析失败: 返回空列表',
      );
    }
    return const [];
  }

  // ====== Map（结构化 note 等） ======

  static String encodeMap(Map<String, dynamic> value) => jsonEncode(value);

  static Map<String, dynamic> decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e, st) {
      // 解析失败 → 返回空 map,这是 fallback 路径(损坏的 JSON 字段)。
      swallowError(
        where: 'JsonCodec.decodeMap',
        error: e,
        stack: st,
        note: '解析失败: 返回空 map',
      );
    }
    return const {};
  }

  // ====== 临时用药 note 解析 ======

  /// 解析 `{name, desc}` 结构化 note，容错老格式 "name:desc"
  static ({String name, String description}) parseTempMedNote(String? raw) {
    if (raw == null || raw.isEmpty) {
      return (name: '', description: '');
    }
    final asMap = decodeMap(raw);
    if (asMap.isNotEmpty) {
      final name = (asMap['name'] as String?)?.trim() ?? '';
      final desc = (asMap['desc'] as String?)?.trim() ?? '';
      return (name: name, description: desc);
    }
    final sepIdx = raw.indexOf(':');
    if (sepIdx > 0) {
      return (
        name: raw.substring(0, sepIdx).trim(),
        description: raw.substring(sepIdx + 1).trim(),
      );
    }
    return (name: raw.trim(), description: '');
  }

  /// 构造结构化 note
  static String buildTempMedNote({
    required String name,
    String description = '',
  }) {
    return encodeMap({'name': name, 'desc': description});
  }
}
