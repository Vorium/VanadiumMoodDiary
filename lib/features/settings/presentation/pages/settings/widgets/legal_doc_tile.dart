// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式):
// 抽 _DocTile 公开 widget — legal_page 法律文档入口 (用户协议 / 隐私政策 / 敏感数据同意)
//
// v0.26 round 57 (emil C-12): 走 AppListTile.standard 集中器
// 替代 inline ListTile + PressFeedback。
// 公开 widget 命名: _DocTile → LegalDocTile

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// legal_page 法律文档入口 (用户协议 / 隐私政策 / 敏感数据同意)
class LegalDocTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const LegalDocTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile.standard(
      leading: Icon(icon, color: AppTokens.primaryColor(context)),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
