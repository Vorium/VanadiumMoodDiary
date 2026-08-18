# Fix Report: E-01 dispose 期 ref.read 泄漏链 + E-02 裸 log 泄 PII (Task 2 B)

- 状态: **done** (E-01 + E-02 全闭环)
- 范围: R112 hotfix 计划 Task 2 B (FIX-LEDGER 优先级 2)
- 文件: mood_audio_recorder_widget / vent_compose_page / audio_lifecycle / legal_page + 2 测试

## E-01 (P1, 0.5d) dispose 期 ref.read → 资源清理永不执行

### 根因链 (实测, 3 层)

1. **ref.read 层 (审计已知)**: Riverpod 3.4.2 `ref.read()` 无条件 `_assertNotDisposed()` → unmount 后抛 StateError 被 swallowError 吞 → `MoodAudioService.dispose()` 永不执行 (native 句柄 100+/day 泄漏) + `cleanupTempFile` 永不执行 (temp 明文残留, PIPL §28)。
2. **cancel future 层 (本次实测新发现)**: dispose 链里 `await playerCompleteSub?.cancel()` / `await recorder.dispose()` / `await player.dispose()` 也会卡死链 — 派生 broadcast subscription 的 cancel future 在 root zone 才 resolve (fake-async widget test 内永不 resolve; 生产上若 future 永不 resolve 同样卡死后续清理)。record 包 dispose 内部 `_stateStreamSubscription.cancel()` + audioplayers dispose 内部 `Future.wait(内部 stream cancel)` 同款。
3. 修前 vent compose 链还卡在 `_getAudioDuration` 的 `await player.dispose()` (finally 里, 把 deleteTempFile 一起卡死)。

### 修法

- **mood_audio_recorder_widget.dart**: initState 捕获 `_serviceField`/`_storageField` (B1-11 同款), `_service` getter + `cleanupTempFile` 走字段; dispose 链不 await stream cancel。
- **vent_compose_page.dart**: initState 捕获 `_storage`, `cleanupTempFile` 走字段; `_getAudioDuration` finally 的 player.dispose 改 unawaited + catchError (不阻塞 deleteTempFile)。事件回调内 ref.read 合法未动。
- **audio_lifecycle.dart**: asyncDisposeAudio 第 1 步 cancel 改 sync; 第 4/5 步 recorder.dispose()/player.dispose() 改 unawaited + catchError (native release 由 dispose future 自己完成, 链不被 dispose 卡死 → 第 6 步 temp 清理必跑)。

### 测试 (TDD: RED → GREEN)

- `mood_audio_recorder_round7b_test.dart` +3 (7/8 运行时 + 2 lock-in, 共 10 pass):
  - 测试 7: 录音中 unmount (无 serviceFactory, 走 provider) → fake service 收到 cancel + dispose。修前 RED: log 仅 `['start']`。
  - 测试 8: 播放中 unmount → `deletedTempFiles == ['/fake/decrypt.m4a']`。修前 RED: `[]`。
  - lock-in: `_disposeResources` / `cleanupTempFile` 体不出现 `ref.read`。
- `vent_compose_dispose_ref_leak_round112_test.dart` (新, 3 pass): 录音中 unmount → record channel 收到 stop + audioplayers channel 收到 stop (链跑完第 5 步); lock-in: cleanupTempFile 体无 ref.read + initState 捕获字段。

## E-02 (P1, 0.2h) legal_page 裸 developer.log

- `legal_page.dart:94` 裸 `developer.log('vent deleteAll failed', error: e, stackTrace: st)` (全 lib 唯一无守卫) → 换 `swallowError(where: 'legal_page.ventDeleteAll', ...)` (内部 `_isProduct` 守卫), 删 `dart:developer` import。用户可见路径 (AppSnackBar.showError) 保留不变。

## 验证

- 全量 `flutter test`: **2455 pass / 1 skip / 4 fail** — 4 fail = R108 iOS 资产占位 (设计资产待补, 与本批无关, 基线一致)。
- `flutter analyze` 4 个 lib 文件: **0 issues**。测试文件仅 `depend_on_referenced_packages` ×3 info (与既有 vent_detail_page_round7b_test 同款 platform channel mock 模式)。
- 守门员: check_cross_feature 0 violation / check_all.dart 通过 / check_coverage 18 gatekeeper PASS / check_apple_health_claim OK / check_pii_in_title OK / check_strings_hardcoded OK。
- R108 既有 lock-in (audio_lifecycle_round108_test) 5/5 pass (mood 行数压回 < 600)。

## Concerns

1. **vent_audio_section 停止按钮 bug (pre-existing, 非本批)**: `_buildIdleButton` 的 `onPressed: isRecording ? null : onToggleRecord` — 录音中按钮 disabled 但 label 显示"正在录音……点停止", 用户实际点不了停止 (v0.24 round 46 引入, 不在本批文件所有权)。影响 vent compose 运行时测试无法走 UI 播放路径 (temp 清理运行时已由 mood 测试 8 覆盖同一 mixin 第 6 步)。建议下批修。
2. **player/recorder dispose 改 fire-and-forget**: native release 由 dispose future 自行完成, 链不再等它。语义变化 = temp 清理不再排在 dispose 完成之后 (无依赖, 安全), 且 dispose 异常走 catchError + swallowError 有观测。
3. cancel future 的 root-zone 机制未完全定位到 dart:async 源码级 (broadcast 派生订阅 cancel future 不在 fake-async 微任务队列内 flush), 结论基于实证 (多组 probe), 建议后续有需要时补一个最小复现。
