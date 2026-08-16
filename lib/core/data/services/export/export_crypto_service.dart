// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// 树洞文字 encrypt/decrypt 包装 — v0.24 Sprint #5c (emil god class 拆解)
//
// **职责**: AES-256 encrypt/decrypt blob ↔ utf8 string, 失败返回 null 不抛异常
//
// **来源**: v0.21 Round 22 (P0-3) 树洞文字字段级加密 (PIPL §28 敏感个人信息),
// 原本所有 encrypt/decrypt 调用都堆在 `data_export_service.dart` 内 (line 177-207
// `_buildVentEntryExport` decrypt 段 + line 431-435 `importFromJson` encrypt 段)。
//
// **隐私边界**: vent 二次确认 (presentation 层) 不动 — 仅数据层副作用封装下沉
// (P0-3 修复保留: decrypt 失败 → null 不抛, v0.23 round 39 P1-5 容错保留)
//
// **依赖**: `EncryptionService` (单例, DI 可注入 mock 测 decrypt 容错)
//
// **emil 设计决策**:
// - "decisions should be nameable" — vent text 加密决策独立命名, 不混在 facade
// - decrypt 失败 → null (跟 `int? _validateInt` 风格一致, 决策可命名)
// - 不持有状态 — 副作用通过 `EncryptionService` 单例 key cache, 自身 0 field
// - constructor 兼容 facade 旧签名 `DataExportService(db, [reportRepo, ventTextEncryption])`
//   把 `ventTextEncryption` 转发到 `ExportCryptoService(ventTextEncryption)`, 50+ 现有 test 不改

import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// 树洞文字 encrypt/decrypt 包装
///
/// 单一职责: vent text ↔ BLOB 加密, 失败返回 null (PKCS7 pad / data corruption 不抛)
class ExportCryptoService {
  /// 构造注入 EncryptionService, 默认走单例 (跟 `EncryptionService()` 一致)
  ///
  /// 测试场景可注入 mock 或用 `setKeyForTest` 注入固定 key (避免 platform channel)
  ExportCryptoService([EncryptionService? encryption])
      : _encryption = encryption ?? EncryptionService();

  final EncryptionService _encryption;

  /// 解密 vent 文字 BLOB → utf8 字符串
  ///
  /// **失败处理**: decrypt 失败 (PKCS7 pad 错误 / data corruption) → 返回 `null`,
  /// 不抛异常。`swallowError` 集中器记录 developer.log 便于排查。
  ///
  /// **来源**: v0.23 round 39 (P1-5 fix) 修过 — 之前 `on Exception` 漏 catch
  /// `InvalidArgument` (PKCS7 pad 错误) → 整条 vent 导出炸 → 整个 export 失败。
  /// 改成 catch all, text = null。
  ///
  /// 返回 null 场景:
  /// - `blob == null` (老数据无加密字段, v8 schema 之前)
  /// - decrypt 抛任意异常 (PKCS7 pad / data corruption / FormatException)
  Future<String?> decryptVentText(Uint8List? blob) async {
    if (blob == null) return null;
    try {
      final plain = await _encryption.decrypt(Uint8List.fromList(blob));
      return utf8.decode(plain);
    } catch (e, st) {
      exportErrorSink(
        where: 'ExportCryptoService.decryptVentText',
        error: e,
        stack: st,
        note: 'vent 文字 decrypt 失败 (PKCS7 pad / data corruption), 视为无文字',
      );
      return null;
    }
  }

  /// 加密 vent 文字 utf8 string → BLOB (供 `insertVentEntry.contentTextEnc`)
  ///
  /// **空字符串 → null** (跟 `decryptVentText` 对称 — null 表示"无文字")
  ///
  /// 不抛异常 (encrypt 在 EncryptionService 内理论不会抛, key cache 命中情况下)
  Future<Uint8List?> encryptVentText(String? text) async {
    if (text == null || text.isEmpty) return null;
    return _encryption.encrypt(Uint8List.fromList(utf8.encode(text)));
  }
}
// rule3-whitelist: 62
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
