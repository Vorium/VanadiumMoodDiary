// v0.28 round 83 (spzh P1-3 修复): swallowError release 模式本地 log sink
//
// 背景 (P2-1 修复 from spen): swallowError release 模式**完全静默**,
// 出 bug 用户报反馈, 后端没任何线索。release 模式 dev log 被 PIPL 合规
// 限制 (走 piiSafeLog 自动 swallow) 也不能开。
//
// 修法: release 模式把 swallow 调用 append 到 app docs 下的 swallow.log
// 文件, 同时做 PII 脱敏 (mask phone / email / 长数字串)。下次启动可以
// 让用户"分享诊断包"或在 settings 加"导出"按钮。
//
// 设计要点:
// - 文件位置: app docs / swallow.log (跟其他本地数据同位置, app 删除时一起清)
// - 文件大小: 1MB 上限, 超过从头 truncate (FIFO rotate)
// - 写入: append-only, fire-and-forget, 失败不阻塞主流程
// - 脱敏: mask phone (用 pii_safe_log.maskPhone) + mask email (regex) +
//   mask 长数字串 (10+ digit, 避免身份证 / 银行卡泄漏)
// - 不依赖 Flutter (只用 dart:io + dart:async)
// - 不依赖 package:flutter (data 层允许 dart:io)
//
// 接入: main.dart release 模式调 setSwallowLogSink(SwallowLogSink(...))
// swallow_error.dart 调 sink 写入。dev 模式 sink 不注册, swallowError
// 走原本 developer.log 路径。

import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';

/// 写入本地 swallow.log 的 sink (release 模式用)
///
/// 文件格式: 每行 1 条记录, 字段以 ` | ` 分隔:
/// `<UTC ISO timestamp> | <where> | <note> | <error type> | <error message>`
///
/// PII 脱敏: 写之前对 note / error message 跑 [sanitizeForLog], 替换:
/// - 手机号 → `138****8000` 形式
/// - 邮箱 → `j***@example.com`
/// - 10+ 位长数字串 → `****` (避免身份证/银行卡泄漏)
class SwallowLogSink {
  final File _file;
  final int _maxBytes;
  final _writeQueue = <String>[];
  Future<void>? _pendingFlush;

  /// 上次实际写入时间 (debug 用: 检测 sink 是否被调用)
  DateTime? lastWriteAt;

  SwallowLogSink(this._file, {int maxBytes = 1024 * 1024})
      : _maxBytes = maxBytes;

  /// 工厂: 默认路径 (app docs / swallow.log) + 1MB 上限
  static Future<SwallowLogSink> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/swallow.log');
    return SwallowLogSink(file);
  }

  /// 写 1 条 (fire-and-forget, 失败不抛)
  void write({
    required String where,
    required String? note,
    required Object error,
  }) {
    try {
      final ts = DateTime.now().toUtc().toIso8601String();
      final safeWhere = sanitizeForLog(where);
      final safeNote = note == null ? '' : sanitizeForLog(note);
      final errType = error.runtimeType.toString();
      final errMsg = sanitizeForLog(error.toString());
      final line = '$ts | $safeWhere | $safeNote | $errType | $errMsg\n';
      _writeQueue.add(line);
      // 异步 flush, 不等结果
      unawaited(_flush());
    } catch (_) {
      // 写 log 失败 = 静默 (双层 swallow 没意义抛出去)
    }
  }

  Future<void> _flush() async {
    // 序列化所有 _flush 调用: 同时多次 write() 不会 race
    if (_pendingFlush != null) {
      await _pendingFlush;
      return;
    }
    final completer = _PendingFlush();
    _pendingFlush = completer.future;
    try {
      // loop 处理 write-during-flush: 写完一个 batch 后, 如果新内容
      // 被加进来 (后续 _flush await 本次), 继续写
      while (true) {
        if (_writeQueue.isEmpty) break;
        final batch = List<String>.from(_writeQueue);
        _writeQueue.clear();
        await _doFlush(batch);
      }
    } finally {
      _pendingFlush = null;
      completer.complete();
    }
  }

  Future<void> _doFlush(List<String> batch) async {
    try {
      if (!await _file.parent.exists()) {
        await _file.parent.create(recursive: true);
      }
      // 追加写 batch
      final raf = await _file.open(mode: FileMode.append);
      try {
        for (final line in batch) {
          await raf.writeString(line);
        }
      } finally {
        await raf.close();
      }
      lastWriteAt = DateTime.now();
      // 写完检查大小, 超过上限从头截断 (FIFO rotate)
      if (await _file.exists()) {
        final size = await _file.length();
        if (size > _maxBytes) {
          await _truncate();
        }
      }
    } catch (_) {
      // 写失败静默 (跟 swallowError 一样: 不影响主流程)
    }
  }

  /// truncate: 保留后 80% 大小内容, 砍掉最旧 (FIFO rotate)
  Future<void> _truncate() async {
    if (!await _file.exists()) return;
    final content = await _file.readAsString();
    final keepBytes = (_maxBytes * 0.8).toInt();
    if (content.length <= keepBytes) return;
    final truncated = content.substring(content.length - keepBytes);
    // 找到下一个换行符位置对齐 (避免半行)
    final firstNewline = truncated.indexOf('\n');
    final aligned = firstNewline >= 0
        ? truncated.substring(firstNewline + 1)
        : truncated;
    await _file.writeAsString(aligned);
  }

  /// 读全部 (测试 / 调试用, UI 不暴露)
  Future<String> readAll() async {
    if (!await _file.exists()) return '';
    return _file.readAsString();
  }

  /// 删文件 (clearAllUserData 配套)
  Future<void> delete() async {
    if (await _file.exists()) {
      await _file.delete();
    }
    lastWriteAt = null;
  }

  /// PII 脱敏: 替换手机号 / 邮箱 / 长数字串
  ///
  /// **不是完美脱敏** — 是 best-effort, 防止最常见的 PII 形式泄漏到 log。
  /// 真正的敏感路径 (SMS 全文 / 联系人姓名 / 心理评估内容) 走其他机制
  /// (last_error_capture + 业务层 audit log), 不依赖本函数。
  static String sanitizeForLog(String input) {
    var s = input;
    // 1) 邮箱 — 始终 mask local part (防单字母邮箱泄漏)
    //   'john.doe@example.com' → 'j*******@example.com'
    //   'a@b.com'             → 'a*@b.com'
    s = s.replaceAllMapped(
      RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'),
      (m) {
        final email = m.group(0)!;
        final at = email.indexOf('@');
        if (at <= 0) return email; // 防御: 没 @ 就不算邮箱
        final local = email.substring(0, at);
        final domain = email.substring(at);
        // 至少 1 个 *: 单字符 local 也要 mask ('a@b.com' → 'a*@b.com')
        return '${local[0]}${'*' * local.length}$domain';
      },
    );
    // 2) 手机号 (复用 pii_safe_log.maskPhone, 处理 +86 / 11 位 / 12-13 位)
    s = s.replaceAllMapped(
      RegExp(r'(?<![\d])\+?\d[\d\-\s]{6,18}\d(?![\d])'),
      (m) => maskPhone(m.group(0)!),
    );
    // 3) 长数字串 (10+ 位, 避免身份证 / 银行卡 / 电话泄漏)
    s = s.replaceAllMapped(
      RegExp(r'\b\d{10,}\b'),
      (_) => '****',
    );
    return s;
  }
}

/// 内部 helper: 序列化 _flush 用的 pending 标识
class _PendingFlush {
  final Completer<void> _completer = Completer<void>();
  Future<void> get future => _completer.future;
  void complete() => _completer.complete();
}
