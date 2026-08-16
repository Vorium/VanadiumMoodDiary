// v0.32 R112 (AR-23): swallowError 全局 sink 分簇 — 3 个 scoped wrapper
//
// 背景: swallowError 在 lib/ 有 77+ 处调用点跨 40 文件。为了以后加
// Sentry / Firebase 等错误上报只改 1 个文件, 按功能簇留 3 个带 scope
// 的顶层 wrapper:
//
// - [audioErrorSink] — audio 簇: 录音 / 播放 / 音频文件 IO
//   (audio_lifecycle / mood_audio_service / mood_audio_recorder_widget /
//    vent audio / encrypted_audio_storage / vent_audio_storage ...)
// - [notificationErrorSink] — notification-safety 簇: 通知 / 提醒 / 安全
//   (notification_* / reminder_* / snooze / badge / safety_* /
//    assessment_notifier / mood_reminder_notifier)
// - [exportErrorSink] — export 簇: 数据导出 / 导入
//   (export/ 目录 / data_export_service / export tile)
//
// 行为 100% 不变: 每个 wrapper 内部仍调 [swallowError], 只是 where 加
// scope 前缀 (dev 模式 developer.log 可见 'audio.xxx' / 'export.xxx',
// release 模式仍走 SwallowLogSink, 由 swallow_error.dart 决定)。
//
// 非 3 簇的散落调用点 (theme_provider / app_database / legal 等) 保持
// 直接调 swallowError 原样不动 (AR-23 只要求 3 簇)。

import 'swallow_error.dart';

/// where 加 scope 前缀: `where` → `scope.where`
///
/// 集中 1 处组合逻辑, 以后改 sink 格式 (比如加 timestamp / level) 只动
/// 这里 + [_swallowScoped]。
String _scopedWhere(String scope, String where) => '$scope.$where';

/// 统一转发: scope 前缀 + 调 [swallowError]
void _swallowScoped(
  String scope, {
  required String where,
  required Object error,
  StackTrace? stack,
  String? note,
}) {
  swallowError(
    where: _scopedWhere(scope, where),
    error: error,
    stack: stack,
    note: note,
  );
}

/// audio 簇: 录音 / 播放 / 音频文件 IO 的静默错误 sink
void audioErrorSink({
  required String where,
  required Object error,
  StackTrace? stack,
  String? note,
}) {
  _swallowScoped('audio', where: where, error: error, stack: stack, note: note);
}

/// notification-safety 簇: 通知 / 提醒 / 安全兜底的静默错误 sink
void notificationErrorSink({
  required String where,
  required Object error,
  StackTrace? stack,
  String? note,
}) {
  _swallowScoped(
    'notification',
    where: where,
    error: error,
    stack: stack,
    note: note,
  );
}

/// export 簇: 数据导出 / 导入的静默错误 sink
void exportErrorSink({
  required String where,
  required Object error,
  StackTrace? stack,
  String? note,
}) {
  _swallowScoped(
    'export',
    where: where,
    error: error,
    stack: stack,
    note: note,
  );
}
