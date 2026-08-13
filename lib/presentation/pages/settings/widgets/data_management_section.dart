// 数据管理 section — 导出/报告/历史/导入/清空
//
// 从 settings_page.dart 提取 (v0.23 P1 refactor)
// v0.30 round 95 (sub-spec 1 task 1): 拆 6 sub-tile 入口, 主壳改 props callback 模式
// v0.30 round 95 (sub-spec 1 task 2a): 抽 ExportTile (200+ 行 → sub-tile, 走 ConsumerWidget)
// v0.30 round 95 (sub-spec 1 task 3): 抽 CbtPdfTile
// v0.30 round 95 (sub-spec 1 task 4a): 抽 ReportTile (ChooseWindowDialog + medication report + swallowError)
// v0.30 round 95 (sub-spec 1 task 4b): 抽 HistoryTile (ReportHistoryListDialog)
// v0.30 round 95 (sub-spec 1 task 5): 抽 ImportTile (JSON 导入 + 风险告知)
// v0.30 round 95 (sub-spec 1 task 6): 抽 ClearTile (清空数据 + 二次确认)
//
// 主壳最终状态 (R95 sub-spec 1 完成): 仅 6 sub-tile 拼装, 0 业务方法。
// 总行数从 606 (R93 起点) → 30-40 (R95 终点)。
//
// v0.32 round 13 (R112 EM-02/AH-04 视觉债): Card + 手写 Divider 改
// AppleListSection (hairline 由容器自动串联, spec §4.5)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/cbt_pdf_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/history_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/import_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/report_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        ExportTile(),
        // v0.30 round 88 (sub-spec 4): 导出 5/7 栏 CBT 思维记录 PDF 入口
        // v0.30 round 95 (sub-spec 1 task 3): 抽到 cbt_pdf_tile.dart
        CbtPdfTile(),
        ReportTile(),
        HistoryTile(),
        ImportTile(),
        ClearTile(),
      ],
    );
  }
}
