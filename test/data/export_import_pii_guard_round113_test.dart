// v1.1.0 R113 wave 2 (BUG 2): export_import_pipeline piiSafeLog 无
// kReleaseMode 守卫 lock-in
//
// 背景: pii_safe_log.dart 内部用 `dart.vm.product` 守卫 — 该常量在
// dart2js/ddc (web release build) 下默认 false, web 生产包会把
// `importFromJson error: $e\n$st` (可能含 PII: 文件名 / 用户数据 / 路径)
// 打进 console。kReleaseMode 在所有平台 release 都为 true。
// 修法: facade 的 catch 块在调 piiSafeLog 前加 `if (!kReleaseMode)` 守卫
// (跟 main.dart FlutterError / runZonedGuarded 同款模式)。
//
// 本 test = 源码文本 lock-in: catch 块与 piiSafeLog 调用之间必须出现
// kReleaseMode 引用, 防止后续 refactor 移除守卫。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('export_import_pipeline piiSafeLog 调用被 kReleaseMode 守卫包裹', () {
    final src = File(
      'lib/core/data/services/export/export_import_pipeline.dart',
    ).readAsStringSync();

    const marker = "piiSafeLog('DataExportService'";
    final callIdx = src.indexOf(marker);
    expect(callIdx, greaterThan(-1), reason: 'facade piiSafeLog 调用被删除?');

    // 最近的 catch 到调用点之间必须含 kReleaseMode 守卫
    final catchIdx = src.lastIndexOf('catch', callIdx);
    expect(catchIdx, greaterThan(-1));
    final guardWindow = src.substring(catchIdx, callIdx);
    expect(
      guardWindow,
      contains('kReleaseMode'),
      reason: 'piiSafeLog 调用前必须被 if (!kReleaseMode) 守卫包裹 '
          '(web release 下 dart.vm.product=false, piiSafeLog 内部守卫失效)',
    );
  });
}
