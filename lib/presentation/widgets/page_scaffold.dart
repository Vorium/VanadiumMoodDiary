import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// 通用页面骨架
class PageScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final PreferredSizeWidget? appBarBottom;

  const PageScaffold({
    super.key,
    this.title,
    required this.child,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.appBarBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
              bottom: appBarBottom,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.pageMarginH,
            vertical: AppTokens.pageMarginV,
          ),
          child: child,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: AppTokens.background,
    );
  }
}
