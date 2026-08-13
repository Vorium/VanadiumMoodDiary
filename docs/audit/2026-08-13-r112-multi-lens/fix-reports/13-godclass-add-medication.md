# 13-godclass-add-medication — AR-20 批2b: add_medication_page 拆解

**执行**: 2026-08-14 (R112 修复战役 wave, 实现 subagent)
**基线**: `add_medication_page.dart` 573L, 职责 3 (form + validation + submit)
**策略**: 先测后拆 (AGENTS: "先补 test 再拆, 拆分目标不是行数而是职责数 ≤2")

## 拆前 / 拆后行数

| 文件 | 拆前 | 拆后 | 职责 |
|---|---|---|---|
| `add_medication_page.dart` | 573L (职责 3) | **258L (职责 1)** | state + 步骤编排 + UX |
| `add_medication_submit_flow.dart` | — | **45L (新)** | repo.add + 双 reschedule 提交流程 |
| `widgets/add_medication_step1_form.dart` | — | **110L (新)** | Step1 表单 UI |
| `widgets/add_medication_step2_form.dart` | — | **194L (新)** | Step2 表单 UI |
| `widgets/add_medication_step3_form.dart` | — | **152L (新)** | Step3 表单 UI |
| `widgets/add_medication_form_shared.dart` | — | **78L (新)** | MedicationStepTitle + formLabel/Icon 映射 |
| `domain/logic/add_medication_form_validator.dart` | 77L (R109 已有) | 77L (未动) | validation |

除 page 258L (编排单职责, 含 34 行文件头注释) 外全部 ≤250L; 每文件职责数 ≤2。

## 新测试 (6 → 31 test)

**`add_medication_page_round7b_test.dart`** (6 → 15, +9):
- 7) Step1 药名纯空格 → 校验 snackbar 不前进 (validateName trim)
- 8) 剂量清空 → 保存成功 dosage 兜底 0 (R109 行为守门)
- 9) 剂量非法文本 → 保存成功 dosage 兜底 0
- 10) Step3 选第 3 色 → draft.colorIndex == 2
- 11) Step1 选剂型胶囊 → Step3 确认 + draft.form == capsule
- 12) Step2 添加时间 20:00 → Step3 双时间 + draft.times 2 项
- 13) Step2 底部"上一步" → 回 Step1 (不 pop)
- 14) AddMedicationSubmitFlow: repo.add 收 draft + 双 reschedule 不抛 (新类 TDD)
- 15) AddMedicationSubmitFlow: repo.add 抛异常原样上抛 (新类 TDD)

**`test/domain/logic/add_medication_form_validator_round112_test.dart`** (新, 16 test):
validateName 5 / parseDosage 6 / canAdvanceFromStep1 3 / toDraft 2 — SP-111-04 同款
0-test 块补锁 (validator 自 R109 起 0 直接单测)。

**`notification_delegate_round108_test.dart`** (改): callerFiles 7 → 8, 加
`add_medication_submit_flow.dart` (delegate lock-in 守门跟到新位置, B5 名称同步)。

## 验证结果

- `flutter test test/presentation/pages/medication/ + validator + delegate`: **71 全绿, 0 warning**
- 全量 `flutter test`: 2517 pass / 1 skip / 10 fail — **fail 全部为工作树既有问题**
  (4 个 iOS 资产占位 + setup_page_state_round112 [其他 agent AR-20 批2a 进行中,
  单跑即挂] + 5 个跨 shard flaky [cbt/apple_health_lock_in/main_migration/
  assessment/medication_backfill, 单跑 + 与我的测试合并跑均全绿], 两次全量 fail
  集合漂移且从不含我的任何文件)
- `flutter analyze`: **0 error / 0 warning 归我** (3 warning 全在另一 agent 的
  `test/presentation/pages/setup/zz_debug3_test.dart`, 工作树既有)
- `dart scripts/check_all.dart`: ✅ 纯度 + ✅ 一致性
- `python scripts/check_cross_feature.py --ci`: ✅ 142 files, 0 violations
- TDD: SubmitFlow 2 test 先写 → 编译失败 (class 缺失) → 实现 → 全绿

## 关键决策

1. **剂量空不改成"错误提示"**: 任务清单写 "剂量/药名空 → 错误提示", 但约束
   "不改业务行为" 优先 — R109 validator 文档化行为是 `parseDosage('') == 0`
   兜底。改错误提示 = 行为变更。改补 test 8/9 锁死兜底行为 (守门), 若产品要
   剂量必填留 R113 决策。
2. **编辑模式**: 本页无编辑模式 (编辑在 edit_medication_dialog), 不适用。
3. **SubmitFlow 依赖注入 `NotificationDelegate` 具体类** (非 interface): 与
   现有 `notif.delegate` 用法 1:1, 0 新抽象。单测走 `_NoopNotificationService`
   真实 delegate + mock channel (空 meds 只 plugin.cancel, 已有先例)。
4. **先试单文件表单 (473L) 后拆 4 文件**: 473L 会落审计 "≥400L god class"
   阈值, 拆 3 step + 1 shared 全部 ≤194L。

## Concerns (给整合 agent)

1. **误格式化 4 个非所有权文件** (dart format 目录级误伤): `edit_medication_dialog.dart` /
   `today_med_schedule.dart` / `refill_manage_page.dart` / `medication_detail_page.dart`
   被 dart format 改写 (纯 whitespace, 内容 0 改, 其他 agent 的内容改动全保留)。
   无法无损还原 (工作树无 pre-format 快照)。建议整合时知会对应 agent。
2. **`medication_calendar_page.dart` / `medication_page.dart` 等其余 M 文件**
   为其他 agent 进行中改动 (含 `temp_medication_dialog.dart` 删除), 本批未触碰。
3. **全量测试 10 fail** 与 R112 ledger "4 fail" 基线不符: setup_page_state_round112
   单跑即挂 (AR-20 批2a agent 未闭环) + 跨 shard flaky — 需整合时统一收口。
4. **page 258L 略超 250L 偏好**: 34 行为文件头注释, 代码 191L。职责 1 (编排),
   若守门员按行数卡可再抽 wizard 底部按钮栏, 但当前无必要。
5. **提交成功语义中 reschedule 无独立断言**: SubmitFlow 单测验证 add + 不抛
   (delegate 无 fake 接口), 双 reschedule 调用路径由既有 test 4 端到端覆盖。

**未 commit** (按指示, 等用户确认)。
