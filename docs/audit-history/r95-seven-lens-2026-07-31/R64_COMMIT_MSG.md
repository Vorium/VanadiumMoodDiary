v0.27 round 64 (god class 拆解): 3 个共识最大 god class 拆分收尾

spen + emil + alibaba 3 视角共识最高频: 3 个 god class 待拆

safety_watch_service.dart (354 行) → facade + SafetyDetector 纯函数:
- _checkAndAlert 122 行 → 54 行 (56% reduction)
- 抽 SafetyDetector (234 行) 8 sealed leaf + switch expression 强制穷举
- 抽 _actOnDecision (42) / _dispatchLostContact (26) / _loadContacts (16) 3 helper
- 0 副作用 / 0 Riverpod / 0 Drift / 0 Flutter 依赖 (domain 纯函数)
- 10 case TDD test (test/core/data/services/safety_detector_round64_test.dart)
- facade 17 case 行为不变 (test/data/safety_watch_service_round12_test.dart)

home_page.dart (437 行) → 3 bool flag → HomeLifecycleState enum:
- _safetyCheckTriggered / _safetyRerunRequested / _deepLinkHandled 3 字段
  → 1 个 _lifecycle: HomeLifecycleState (5 state: initial/safetyCheckCompleted/deepLinkHandled/safetyRerunRequested/bothHandled)
- 3 transition method (onSafetyCheckCompleted / onDeepLinkHandled / onRerunRequested)
- switch expression 强制 valid transitions, 违例抛 StateError (race 防护)
- 5 case TDD test (test/presentation/pages/home/home_lifecycle_round64_test.dart)

mood_recorder.dart (562 行 god page) → 5 个单一职责 widget:
- mood_recorder_page.dart (198) 顶层 page + orchestrator
- mood_audio_section.dart (539) 录音 + 计时 + 波形 + mic 权限 (单一职责最重, sub-split 留 R65+)
- mood_score_chooser.dart (77) 4 维分数 (emotion/energy/sleep/anxiety)
- mood_text_input.dart (40) text + tags + character counter
- mood_submit_panel.dart (52) save + 庆祝 + 错误处理
- mood_dialog.dart (192 → 25) 降为薄壳, MoodDialog.show API 不变 (home_page.dart 不用改)
- 删 4 个旧文件: mood_recorder / mood_score_form / mood_text_note / mood_dialog_actions (迁到新拆分)

结果: 1178/1178 tests pass (1163 → 1178, +15), flutter analyze 0 error, 16 守护全绿
