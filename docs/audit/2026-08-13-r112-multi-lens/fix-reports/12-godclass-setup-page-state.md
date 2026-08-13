# 修复报告 12 — AR-20 批2a: setup_page_state god class 拆解 (先测后拆)

- 批次: v0.32 R112 fix-reports #12 (god class 拆解接力, AR-20 批2a)
- 执行者: 实现 subagent (12-godclass-setup-page-state)
- 日期: 2026-08-14
- 基线: HEAD=6bbb308 (R112 working tree 进行中, 有其他 agent 的未 commit 改动)
- 范围: `lib/presentation/pages/setup/` + `test/presentation/pages/setup/` 全量
  (任务: 先补测试 → 拆 3 职责 → 验证)

## 结论速览

| 任务 | 状态 | 验证 |
|---|---|---|
| 1. 拆前补测 (characterization) | **done** | `setup_page_state_round112_test.dart` 7 case, 拆前全绿锁定既有行为 |
| 2. 拆 3 职责 → 4 新文件 + 1 工厂 | **done** | `setup_page_state_split_round112_test.dart` 14 case (新类 TDD red→green) |
| 3. 验证 | **done** | setup 34 test 全绿 + 全量 2533 pass / 4 已知 fail + analyze 0e/0w + check_all ✅ + cross_feature 0 |

**行数变化**:

| 文件 | 拆前 | 拆后 |
|---|---|---|
| setup_page_state.dart | **503L** (职责 3) | **331L** (职责 ≤2: 步骤坐标 + 编排入口) |
| setup_consent_state.dart | — | 44L 新增 (1 职责: 5 勾选状态) |
| setup_contact_consent_flow.dart | — | 81L 新增 (1 职责: 同意弹窗循环) |
| setup_submit_flow.dart | — | 144L 新增 (1 职责: 提交序列 + 收集) |
| widgets/setup_wizard_frame.dart | — | 95L 新增 (1 职责: wizard 壳) |
| setup_widgets.dart | 281L | 300L (+19, `MedDraft.fromTemplate` 工厂) |

## 任务 1: 拆前补测 (characterization, 7 case)

`test/presentation/pages/setup/setup_page_state_round112_test.dart` (499L) — 对照
round77 / round18 / round14 已有测试, 补缺口 (SP-111-06 / SP-en-3 "497L 4 步向导
0 test"):

1. **4 步导航流转**: consent→welcome→medication→done 完整走通 (提交成功) + step 2 上一步回 step 1
2. **consent 弹窗编排**: 填联系人手机号 → 完成弹 PIPL §13 同意 dialog; 拒绝 → snackbar + 停留 step 2 + committer 0 调用; 同意 → 联系人入提交数据 (E.164 normalize + 空名 fallback + consents 等长); 手机号留空 → 跳过 dialog
3. **提交成功**: committer 收到 userName/contacts/meds + recordConsent (PIPL §14) 被调 + 进 step 3
4. **提交失败**: committer 抛异常 → "完成设置失败" snackbar + 停留 step 2 + saving 复位 (spinner 消失 = 按钮可重试)
5. **E5 (R111 fix)**: committer 抛 StateError (长度不一致) → 统一失败路径 + 错误信息透传 snackbar + saving 复位

**测试基建坑 (3 个, 已写进测试注释, 后续 setup/通知相关测试可复用)**:
- `flutter_local_notifications` channel mock 的 `initialize` / `requestPermissions` / `requestNotificationsPermission` **必须返 true** — 包内 `Future<bool> async` 方法直接 return channel null 会抛 `type 'Null' is not a subtype of type 'FutureOr<bool>'`
- `flutter_timezone` channel **不 mock 会挂死** — TestDefaultBinaryMessenger 无 handler 时 delegate.send 走真引擎 messenger, testWidgets 下 future 永不完成 → `init()` 挂死
- saving=true 时 LoadingSpinner 无限动画 → `pumpAndSettle` 会 timeout, 必须有界 pump (press_feedback_round95 同款坑)

## 任务 2: 拆解 (4 新文件 + 1 工厂)

跟 add_medication_page 批2b 的 `AddMedicationSubmitFlow` 命名同款 (flow 放页面根,
纯 widget 放 widgets/):

- **`setup_consent_state.dart`** (44L): `SetupConsentState` — 5 bool 勾选 + `agreeAll()`
  (R104) + `allAgreed` getter。0 Flutter 0 Riverpod 纯状态类, 3 unit test。
- **`setup_contact_consent_flow.dart`** (81L): `SetupContactConsentFlow.collect`
  static — 循环弹 ConsentDialog (R68 CC-1 PIPL §13), 拒绝 → snackbar + null,
  同意 → `SetupContactConsentResult` (contactList 与 consents 等长, E.164 normalize)。
- **`setup_submit_flow.dart`** (144L): `SetupSubmitFlow.run` — completeSetup →
  recordConsent (PIPL §14, legalVersionProvider 读 1 次赋值 2 参, 行为同) →
  watchAll 5s timeout (fail-loud 保留) → requestPermission (swallowError 保留) →
  reschedule + scheduleDailyReminder。错误原样上抛, caller 管 snackbar。
  + `collectMedications` (空名跳过 / dosage 兜底 0 / times 转 HourMinute)。
- **`widgets/setup_wizard_frame.dart`** (95L): `SetupWizardFrame` — PopScope +
  PageScaffold + SetupProgressBar + PageTransitionSwitcher 壳, state 只传
  step + child。
- **`setup_widgets.dart`**: `MedDraft.fromTemplate(MedicationDraft, l10n)` —
  template → 草稿构造 20L 抽出 (name i18n / 整数剂量去 .0 / times 转 TimeOfDay)。
- **`setup_page_state.dart`** 503 → 331L: 只留 _step 坐标 + controller 生命周期 +
  _buildStep 拼装 + `_finishSetup` 编排入口 (saving 标志 + error snackbar +
  swallowError + finally 复位)。

**行为 1:1 对照** (关键点):
- 提交失败路径 (error snackbar + saving 复位 + 停留 step 2) 逐行保留, E5 StateError
  由 SetupCommitter 原样抛出 → state catch → snackbar 透传
- mounted guard 全部换成 `context.mounted`, 语义同 (context = state 的 context)
- unmount 中途 return 路径保留 (finally 复位 _saving 直改字段, R112-04 fix 语义)
- 公开 API 0 变: `SetupPage` / `SetupPageState` / `createState()` 签名不变

## 验证汇总 (实测)

- `flutter test test/presentation/pages/setup/` → **34 pass** (13 旧 + 7 characterization + 14 新类)
- 老 setup 测试 (round77/18/14/step2, 归属外) → **18 pass**
- `flutter test` 全量 → **2533 pass / 1 skip / 4 fail** — 4 fail 为已知 iOS 资产占位
  (app_icon 1 + launch_image 3, 跟 R112 ledger "4 fail (iOS 资产)" 一致, 非本批引入)
- `flutter analyze` → **0 error / 0 warning** (repo 3 info 全在归属外文件:
  medication_slot_calculator_round108 ×2 + mood_audio_recorder close_sinks, 预存在)
- `dart scripts/check_all.dart` → 纯度 ✅ + 一致性 ✅
- `python scripts/check_cross_feature.py` → 0 violation
- 守门员: 20/22 绿; `check_orphan_arb_keys` FAIL (预存在, tempMed* 6 key 由另一
  agent 删 TempMedicationDialog 产生, 非本批); `check_review_information_todo`
  warn-only 外部占位 (同基线)

## Concerns / 注意事项

1. **`dart fix --apply` 越权 collateral**: 项目级 fix (prefer_const_constructors +
   require_trailing_commas) 扫到 34 个归属外文件 (纯 lint 修饰)。其中 1 处破坏
   lock-in 测试 — `lib/main.dart` `runApp(MigrationAbortedApp(onRetry: main))` 被
   加 `const` 导致 `boot_apps_split_round108_test` 字符串匹配失败, **已回退该行
   (仅此一处)**。全量测试复验后无其他破坏。其余 collateral 为纯修饰 (AGENTS.md
   已知坑文档认可的 `dart fix --apply` 组合实践), 若整合者要求归零可再手工回退。
2. **`_finishSetup` 结构微调 (1 处行为差异, 极端路径)**: 原代码 consent 循环在
   try/catch 外, 新代码包进 try — `ConsentDialog.show` 抛异常时原来会 unhandled
   exception + `_saving` 卡死 (按钮永久 disabled), 现在走统一错误 snackbar +
   finally 复位 (更稳)。正常路径 / 提交失败路径 100% 1:1。已在代码注释标注。
3. **331L 仍超 250L 偏好**: 职责已 ≤2 (步骤坐标 + 编排入口)。再压需改
   SetupStepConsent 公开 API (5 bool → 传 SetupConsentState, -25L), 本批没做
   以保持"公开 API 语义不变"约束, 留批 2c 可选。
4. **testWidgets + 真 drift 的 FakeAsync 坑**: 提交路径测试全部用 fake repo /
   fake committer (纯 Dart), 不碰真 drift isolate (testWidgets 下真 DB await 挂死)。
   若未来要测真 DB round-trip, 用 `tester.runAsync` 或转 integration `test()`。
5. **未 commit** (按指令)。新文件 untracked: setup_consent_state.dart /
   setup_contact_consent_flow.dart / setup_submit_flow.dart /
   widgets/setup_wizard_frame.dart + 2 个 round112 测试。

## 测试数变化

| 文件 | 前 | 后 |
|---|---|---|
| test/presentation/pages/setup/setup_page_state_round112_test.dart | — | 7 case 新增 (characterization) |
| test/presentation/pages/setup/setup_page_state_split_round112_test.dart | — | 14 case 新增 (新类 TDD) |
| 既有 setup 测试 (round10/95/8/77/18/14/step2) | 31 | 31 (0 语义变) |
