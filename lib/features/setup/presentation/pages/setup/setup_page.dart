// setup_page.dart — 首次设置引导页主壳 (R95 sub-spec 6 task 6c 拆解)
//
// 职责:
// 1. [SetupPage] ConsumerStatefulWidget — 4 步 wizard 入口
// 2. createState() 返回 public [SetupPageState] (跟 R95 sub-spec 4 task 5
//    _HomePageState → HomePageState 模式一致)
//
// **state class 已搬到 setup_page_state.dart** (v0.30 round 95 sub-spec 6
// task 6c): 517 行 → 主壳 25 行 + state 480 行, 拆完 8 业务方法 (initState /
// dispose / build / _buildStep / _validateWelcomeForm /
// _showPresetTemplatesSheet / _finishSetup) 在 state 独立, 主壳纯 widget 入口。
//
// 4 步 (跟 R95 sub-spec 1 task 1 拆 data_management_section 同款 4-step pattern):
// 0=consent, 1=welcome, 2=medication, 3=done
// 各 step 的 UI 在独立文件中 (SetupStepConsent/Welcome/Medication/Done),
// 本文件只管 ConsumerStatefulWidget 入口, state class 含步骤切换 + 业务方法。
//
// 历史:
// - v0.19 (Q2): 拆分为 4 个 step widget + legal dialog
// - v0.30 round 95 (sub-spec 6 task 6c): SetupPageState 拆 setup_page_state.dart
//   (原 _SetupPageState 改成 public 避免循环 import)
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/pages/setup/setup_page_state.dart';

/// 首次设置引导页（4 步 wizard coordinator）
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => SetupPageState();
}
