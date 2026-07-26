// v0.24 round 48 (sp-en P1-10): vent_compose._togglePlay 暂停路径 stop 异常防御
//
// 现状: vent_compose_page._togglePlay 的"暂停"分支直接
//   await _player.stop();
//   if (_tempDecryptedPath != null) {
//     await ref.read(ventAudioStorageProvider).deleteTempFile(...);
//     _tempDecryptedPath = null;
//   }
// audioplayers 6.x 在 iOS 上偶发 PlatformException (锁文件 / 系统打断 /
// 后台被杀等),stop 抛异常会 propagate,导致 deleteTempFile 永远不调。
// temp m4a 文件堆在 temp dir 反复播放就堆一堆,磁盘泄漏。
//
// 修法: 抽 @visibleForTesting 的 top-level stopAndCleanup helper,封装
// "stop + deleteTemp" 加 try/catch + swallowError,确保 stop 抛异常时
// deleteTemp 仍被调,异常被吞掉不阻塞 UI 状态。
//
// RED 阶段 helper 没 try/catch,RED test 期望"stop 抛异常时 deleteTemp
// 仍被调" → 当前实现 FAIL (异常 propagate, deleteTemp 永远不到)。
import 'dart:io' show FileSystemException;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart'
    show stopAndCleanup;

void main() {
  group('stopAndCleanup (v0.24 round 48 sp-en P1-10)', () {
    test('stop 抛 PlatformException → deleteTemp 仍被调 (P1-10 RED-1)', () async {
      var deleteTempCalled = 0;
      await stopAndCleanup(
        stop: () async {
          throw PlatformException(code: 'audio_stop_fail');
        },
        deleteTempFile: () async {
          deleteTempCalled++;
        },
        where: 'vent_compose_page._togglePlay',
      );
      // 防御性目标: stop 抛异常也不能阻断 deleteTemp
      expect(
        deleteTempCalled,
        1,
        reason: 'stop 抛异常时 deleteTemp 必须仍被调',
      );
    });

    test('正常路径 (stop 不抛) → deleteTemp 调 1 次', () async {
      var deleteTempCalled = 0;
      var stopCalled = 0;
      await stopAndCleanup(
        stop: () async {
          stopCalled++;
        },
        deleteTempFile: () async {
          deleteTempCalled++;
        },
        where: 'vent_compose_page._togglePlay',
      );
      expect(stopCalled, 1);
      expect(deleteTempCalled, 1);
    });

    test('deleteTemp 抛异常 (file 已被系统清) → 异常 swallow 不外抛', () async {
      // 防御性目标: temp file 已被外部清掉 (iOS 偶尔清 temp dir) 不应让
      // _togglePlay 整个抛回 UI,否则 setState 不跑,_isPlaying 卡 true。
      await stopAndCleanup(
        stop: () async {},
        deleteTempFile: () async {
          throw const FileSystemException('temp file already gone');
        },
        where: 'vent_compose_page._togglePlay',
      );
      // 不抛 = PASS
    });
  });
}
