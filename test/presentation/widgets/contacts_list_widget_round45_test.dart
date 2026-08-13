// v0.24 (Round 45): contacts_list_widget widget 单测
//
// 之前 v0.22 round 30 P1-39 标的"contact 整片 0 widget 测"残留。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之一) 补 4 个 case:
//
// 1. contacts 空 → 渲染 EmptyState (icon + title + action button)
// 2. contacts 1+ → 渲染 List (AppleListSection + Dismissible rows, v0.32 round 13
//    R112 EM-02/AH-04 视觉债: Card 容器改 AppleListSection)
// 3. contact name 显示 (l10n 走 AppLocalizations.of(context).contactName)
// 4. EmptyState action button 触发 onAction → 打开添加弹窗
//    (v0.32 round 8 R111 FS-14 fix: 原走 /contacts/new 死路由 → 404,
//    改走 _showAddContactDialog, 跟非空列表同一 ConsentDialog 流程)
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates (跟 last_startup_error_banner_round31 同模式)
// - 直接 mock ContactEntity (不连 DB)
// - 测 render / tap 行为, 不测业务逻辑
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const ContactsListWidget(contacts: []),
      ),
    ],
  );
}

void main() {
  testWidgets('contacts 空 → 渲染 EmptyState (icon + title + action button)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: _buildRouter(),
      ),
    );
    await tester.pumpAndSettle();

    // 验证 EmptyState icon + title + action 渲染
    expect(find.byIcon(Icons.contacts_outlined), findsOneWidget);
    // 验证 EmptyState 显示 (title + action label 来自 l10n, 简体)
    expect(find.text('还没有联系人，请先添加'), findsOneWidget);
    // 验证 "添加联系人" action button
    expect(find.text('添加联系人'), findsOneWidget);
  });

  testWidgets('contacts 1 → 渲染 List (1 个 Dismissible row + 名字)',
      (tester) async {
    const contact = ContactEntity(
      id: 1,
      name: '张三',
      phone: '13800000001',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const ContactsListWidget(contacts: [contact]),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1 个 Dismissible 渲染 (左滑删除)
    expect(find.byType(Dismissible), findsOneWidget);
    // contact name 显示
    expect(find.text('张三'), findsOneWidget);
    // phone 显示 (AppListTile subtitle)
    expect(find.text('13800000001'), findsOneWidget);
    // EmptyState 不应显示
    expect(find.byIcon(Icons.contacts_outlined), findsNothing);
  });

  testWidgets('contacts 3 → 渲染 3 个 Dismissible (AppleListSection 容器)',
      (tester) async {
    // v0.32 round 13 (R112 EM-02/AH-04 视觉债): 容器 Card → AppleListSection,
    // 手写 Divider 删 (hairline 由容器自动串联), 断言同步改
    const contacts = [
      ContactEntity(
        id: 1,
        name: 'A',
        phone: '13800000001',
        sortOrder: 0,
        isActive: true,
      ),
      ContactEntity(
        id: 2,
        name: 'B',
        phone: '13800000002',
        sortOrder: 1,
        isActive: true,
      ),
      ContactEntity(
        id: 3,
        name: 'C',
        phone: '13800000003',
        sortOrder: 2,
        isActive: true,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const ContactsListWidget(contacts: contacts),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppleListSection), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(3));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('EmptyState action button 触发 onAction → 打开添加弹窗 (FS-14 fix)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: _buildRouter(),
      ),
    );
    await tester.pumpAndSettle();

    // 点击 EmptyState 的 "添加联系人" 按钮 → 打开 _showAddContactDialog 弹窗
    await tester.tap(find.text('添加联系人'));
    await tester.pumpAndSettle();

    // v0.32 round 8 (R111 FS-14 fix): 不再 push /contacts/new (死路由 404),
    // 弹窗直开 (跟非空列表的 "+ 添加另一个联系人" entry 同一个 flow)
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('添加紧急联系人'), findsOneWidget);
    // 弹窗里 2 个 TextField (姓名 + 手机号)
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
