import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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
  static List<String> decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty || raw == '[]') return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList(growable: false);
      }
    } catch (_) {
      // 解析失败：返回空列表
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
      // v0.17 round 14 (P1-5): 之前完全静默，现在 dev 模式 devtools 能看见。
      if (kDebugMode) {
        developer.log(
          'json_codec.decodeMap: parse failed, returning const {}',
          name: 'swallow',
          error: e,
          stackTrace: st,
        );
      }
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
