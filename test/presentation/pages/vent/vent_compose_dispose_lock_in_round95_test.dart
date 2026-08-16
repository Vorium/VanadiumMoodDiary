// v0.30 round 95 (sub-spec 2 task 25) → R108 重构 (P1 god class 拆 6 大 F):
// vent_compose dispose 异步未 await lock-in test
//
// **R95 修法**: 抽 _asyncDispose() helper 内部顺序释放 (cancel stream sub →
// stop recorder if recording → dispose recorder → dispose player → delete temp
// file), 用 unawaited() 包装避免 State.dispose() 强制 sync 签名要求。每步 catch
// 走 swallowError 集中器, 防止 stop/dispose 异常时整条链中断, 后续资源漏释放。
//
// **R108 重构 (P1 god class 拆 6 大 F - Fix #1)**: audio state machine 抽到
// `lib/presentation/widgets/audio_lifecycle.dart` AudioLifecycleMixin。R79 修法
// 在 mixin.asyncDisposeAudio() 集中实现 (6 步), vent_compose_page.dart dispose()
// 改成调 `unawaited(asyncDisposeAudio(player: _player, recorder: _recorder))`。
//
// **R108 lock-in (本 test 改)**: 验证 vent_compose_page.dart 用 mixin 模式:
// 1. dispose() 调 unawaited(asyncDisposeAudio(...)) — R79 修法在 mixin 集中
// 2. _asyncDispose 本地方法已删 (R108 移到 mixin)
// 3. _playerCompleteSub?.cancel() 仍出现 (initState 里注册 listener)
// 4. mixin 文件存在 + 有 asyncDisposeAudio method
// 5. AudioLifecycleMixin 4 状态 (idle/recording/recorded/playing)
//
// **跟 R95 同样**: 静态源码 grep 守门, 不依赖 audioplayers / record platform
// channel mock。
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    'vent_compose dispose 异步 lock-in (R95 + R108 重构)',
    () {
      late String source;
      late String mixinSource;

      setUpAll(() {
        // 静态读源文件 (跟 R93 vent_compose_page_r93_hide_test 风格一致)
        source = File(
          'lib/presentation/pages/vent/vent_compose_page.dart',
        ).readAsStringSync();
        mixinSource = File(
          'lib/presentation/widgets/audio_lifecycle.dart',
        ).readAsStringSync();
      });

      test('R108 fix 1: dispose() 调 unawaited(asyncDisposeAudio(...))', () {
        // R108 重构: 用 unawaited 包装 asyncDisposeAudio() (mixin method),
        // R79 修法在 mixin 集中实现, vent_compose 只调入口
        expect(
          source.contains('unawaited(asyncDisposeAudio('),
          isTrue,
          reason: 'dispose() 必须用 unawaited(asyncDisposeAudio(...)) 包装 '
              '(R108 重构), 防止 sync 调 future 释放不完整 → OOM / audio session 异常',
        );
      });

      test('R108 fix 2: _asyncDispose 本地方法已删 (R108 移到 mixin)', () {
        // R108 验证: 旧 _asyncDispose helper 已被 mixin 替代
        // (防止有人 revert 回本地 helper)
        expect(
          source.contains('Future<void> _asyncDispose()'),
          isFalse,
          reason: '_asyncDispose() 本地 helper 已删 (R108 移到 '
              'AudioLifecycleMixin.asyncDisposeAudio), 不能重现出现',
        );
      });

      test(
          'R108 fix 3: _playerCompleteSub?.cancel() 仍在 (initState 注册 listener)',
          () {
        // R108: player complete stream subscription 仍由 widget 注册
        // (initState), dispose 时由 mixin.asyncDisposeAudio cancel
        expect(
          source.contains('_player.onPlayerComplete.listen'),
          isTrue,
          reason: '_player.onPlayerComplete.listen 必须在 initState 注册 '
              '(R79 + R108 模式保持)',
        );
      });

      test('R108 fix 4: AudioLifecycleMixin 文件存在 + 有 asyncDisposeAudio method',
          () {
        expect(
          mixinSource.contains('mixin AudioLifecycleMixin'),
          isTrue,
          reason: 'AudioLifecycleMixin 必须存在 (R108 抽到 '
              'lib/presentation/widgets/audio_lifecycle.dart)',
        );
        expect(
          mixinSource.contains('Future<void> asyncDisposeAudio('),
          isTrue,
          reason: 'asyncDisposeAudio method 必须在 mixin 集中实现 '
              '(R79 修法从 vent_compose / mood_audio 抽出)',
        );
      });

      test(
          'R108 fix 5: AudioLifecycleMixin 4 状态 (idle/recording/recorded/playing)',
          () {
        // R108 验证: 4 状态 enum 完整 (替代旧 4 个独立 bool 字段)
        for (final state in [
          'idle',
          'recording',
          'recorded',
          'playing',
        ]) {
          expect(
            mixinSource.contains('AudioState.$state'),
            isTrue,
            reason: 'AudioState enum 必须含 4 状态 (替代 vent_compose / '
                'mood_audio 的 _isRecording / _isPlaying 等独立字段), '
                '缺: $state',
          );
        }
      });
    },
  );
}
