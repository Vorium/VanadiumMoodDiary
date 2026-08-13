# AR-23 Fix Report: swallowError 全局 sink 分簇 (3 scoped error sinks)

- **日期**: 2026-08-14
- **执行**: 实现 subagent (R112 hotfix Wave 3 H1)
- **状态**: ✅ 完成 (未 commit)
- **范围**: 架构 AR-23 — swallowError 77+ 处调用点跨 40 文件, 按 3 功能簇
  (audio / notification-safety / export) 各留 1 个带 scope 的 wrapper。

## 变更内容

### 新增文件 (2)

1. **`lib/core/shared/error_sinks.dart`** (82L)
   - `audioErrorSink` / `notificationErrorSink` / `exportErrorSink` 3 个顶层 wrapper,
     签名与 `swallowError` 完全一致 (where / error / stack / note)。
   - 私有实现 `_scopedWhere(scope, where) => '$scope.$where'` +
     `_swallowScoped(scope, ...)` 统一转发: 内部仍调 `swallowError`,
     where 加 scope 前缀 (`audio.` / `notification.` / `export.`)。
   - `lib/core/shared/swallow_error.dart` **0 改动** (原入口保持)。
   - 以后加 Sentry/Firebase 只改这 1 个文件的 3 个 wrapper + 1 个转发函数。
   - 无 Flutter / Drift 依赖, check_all purity 通过 (shared 层, data + presentation
     两层使用)。

2. **`test/core/shared/error_sinks_round8_test.dart`** (10 case)
   - 3 个 wrapper 各自: 最小参数不抛 + 全参数 (stack + note) 不抛 = 6 case。
   - 4 case 源码 lock-in (R95 守门员模式):
     - wrapper 内部仍调 `swallowError` (行为 100% 不变)
     - `_scopedWhere` 实现 `scope.where` 组合
     - 3 个 wrapper 各传自己的 scope 常量
     - wrapper 签名带 where / error / stack / note 4 参数

### 调用点替换 (15 文件, 56 处)

| 簇 | wrapper | 文件数 | 调用点数 |
|---|---|---|---|
| audio | `audioErrorSink` | 8 | **48** |
| notification-safety | `notificationErrorSink` | 4 | **5** |
| export | `exportErrorSink` | 3 | **3** |

**audio 簇 (48)**: mood_audio_service (8) / mood_audio_recorder_widget (8) /
audio_lifecycle (13) / encrypted_audio_storage (6) / vent_audio_storage (2) /
vent_compose_page (7, 含 stopAndCleanup helper 2 处) / vent_detail_page (3) /
mood_recorder_page (1, 文件属录音页按文件归类)。

**notification-safety 簇 (5)**: badge_sync_service (1) /
notification_initializer (1) / reminder_dispatcher (1) /
notification_status_card (2)。

**export 簇 (3)**: export_crypto_service (1) / export_schema_service (1) /
export_tile (1)。

**保持 swallowError 原样不动 (23 处, 16 文件)**: app_database /
assessment_dao / medication_times / vent_mapper / consent_preference_store /
skip_backup / json_codec / theme_provider / assessment_record / assessment_page /
home_care_engine_dispatcher / home_page_state / quick_mood_carousel / legal_page /
setup_page_state / report_tile — AR-23 只要求 3 簇, 其余散落不动。

> 注: 任务描述称 "77 处", 本次 grep 实测 lib/ 共 **79 处** (含 swallow_error.dart
> 定义 + doc 示例 2 处)。56 替换 + 23 保持 = 79, 无遗漏无多改。

### 同步更新的既有测试 (2 个源码 grep lock-in)

- `test/core/data/services/badge_sync_service_swallow_error_lock_in_round95_test.dart`
  — regex `swallowError(` → `notificationErrorSink(` (R79 fix 2/3 断言)。
- `test/presentation/widgets/audio_lifecycle_round108_test.dart`
  — A4 计数 `'swallowError('` → `'audioErrorSink('`。

其余 test/ 中 swallowError 引用均为注释 / test 名 / 未变文件 (JsonCodec /
AssessmentRecord / MedicationTimes / VentMapper 等仍直调 swallowError), 无需改。

## 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze` | 0 error / **4 warning** (与我改动无关, 见下) / 116 info |
| `flutter test` 全量 | **2471 pass / 4 fail / 1 skip** ✅ 不恶化 |
| `dart scripts/check_all.dart` | ✅ 纯度 + 一致性双通过 (exit 0) |
| 新测试单跑 | 10/10 pass |
| 受影响测试单跑 (badge lock-in + audio_lifecycle R108 + catch lock-in R95 + stop_and_cleanup R48) | 39/39 pass |

- 4 fail = iOS 资产占位 (app_icon_size / launch_image_size round108), 与任务描述
  一致, 等设计师资产, 与本批无关。
- 2471 = 基线 2461 + 本批新增 10 test。

## Concerns

1. **基线 warning 4 个 (非本批引入)**: clear_tile.dart ×2 (setup_committer unused
   import + db unused var) / setup_page_state.dart ×1 (setup_committer unused
   import) / vent_audio_storage.dart ×1 (app_database unused import)。第 4 个是
   working tree 里其他 agent 的未提交改动 (doc 注释 `[AppDatabase.clearAllUserData]`
   → `[SetupCommitter.clearAllUserData]`) 把 app_database import 的最后一个引用
   消掉导致的; R112 审计基线称 "3 warning", 现为 4, 需该 agent 收尾。
2. **调用点实测 79 而非 77**: 与 07-top-level-arch.md "本次实测 77 处" 差 2
   (swallow_error.dart 定义 + doc 示例)。可能审计 grep 排除了定义文件; 不影响结论。
3. **wrapper 语义**: where 前缀后 dev log 显示 `audio.xxx` / `export.xxx`,
   release SwallowLogSink 的 where 字段同样带前缀 — 对日志消费方是可见变化
   (仅字段值, 非行为)。若以后有按 where 前缀做统计的消费方需知悉。
4. **mood_recorder_page.dart:152 归类判断**: 该调用点语义是 cbtDraftNotifier.reset
   (非音频), 但按任务规则 "按文件归类" — mood_recorder_page 是录音页 → 划入
   audio 簇。若后续要按语义归 notification 簇, 1 行可改。
5. 本批未 commit (按任务要求), working tree 与多 agent 共享, diff 中同文件可能
   混有其他 agent 改动; 我的增量仅 import 行 + `swallowError(` → `xxxErrorSink(`
   两类替换。
