// v0.15 (Round 18) VentAudioStorage — 树洞 audio 文件本地存储
//
// 文件存 app docs 目录（v0.7 data_export_service 已有类似模式），
// 路径通过 `path_provider` 拿。
//
// 隐私：文件本身**不加密**（v0.15 MVP），但 DB 整体在 SQLCipher 里，
// 路径 = 实际内容的"钥匙"。v1.0+ 可考虑用 AES 加密文件本体。
//
// 设计：
// - 生成新文件路径（不创建文件，由调用方写）
// - 单文件删除（best-effort）
// - 清空全部（隐私清除 / 卸载时）
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 树洞 audio 文件管理
class VentAudioStorage {
  static const _dirName = 'vent_audio';

  /// 取 audio 目录（不存在则创建）
  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 生成新的 audio 文件路径（不创建文件）
  ///
  /// 路径格式：{app_docs}/vent_audio/vent_{timestamp_ms}.m4a
  /// 用 m4a 是 Android/iOS 都支持 + 体积小的格式。
  Future<String> newAudioPath() async {
    final dir = await _dir();
    final name = 'vent_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(dir.path, name);
  }

  /// 删除单个 audio 文件
  ///
  /// 文件不存在视为成功（idempotent）。
  Future<bool> deleteAudio(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 清空所有 audio 文件（用于"清空树洞"功能 / 隐私清除）
  Future<int> deleteAll() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
          count++;
        } catch (_) {
          // 跳过无法删除的
        }
      }
    }
    return count;
  }

  /// audio 文件总大小（字节），用于统计 / 警告用户
  Future<int> totalSizeBytes() async {
    final dir = await _dir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }
}
