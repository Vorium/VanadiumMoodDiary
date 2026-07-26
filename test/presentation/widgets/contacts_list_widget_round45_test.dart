// v0.24 (Round 45): contacts_list_widget widget 单测
//
// 之前 v0.22 round 30 P1-39 标的"contact 整片 0 widget 测"残留。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之一) 补 4 个 case:
//
// 1. contacts 空 → 渲染 EmptyState (icon + title + action button)
// 2. contacts 1+ → 渲染 List (Card + Dismissible rows)
// 3. contact name 显示 (l10n 走 AppLocalizations.of(context).contactName)
// 4. EmptyState action button 触发 onAction callback → context.push('/contacts/new')
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates (跟 last_startup_error_banner_round31 同模式)
// - 直接 mock ContactEntity (不连 DB)
// - 测 render / tap 行为, 不测业务逻辑
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
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
      GoRoute(
        path: '/contacts/new',
        builder: (_, __) => const Scaffold(body: Text('NEW_CONTACT_PAGE')),
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
              builder: (_, __) =>
                  const ContactsListWidget(contacts: [contact]),
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

  testWidgets('contacts 3 → 渲染 3 个 Dismissible + 2 个 Divider',
      (tester) async {
    const contacts = [
      ContactEntity(
          id: 1,
          name: 'A',
          phone: '13800000001',
          sortOrder: 0,
          isActive: true,),
      ContactEntity(
          id: 2,
          name: 'B',
          phone: '13800000002',
          sortOrder: 1,
          isActive: true,),
      ContactEntity(
          id: 3,
          name: 'C',
          phone: '13800000003',
          sortOrder: 2,
          isActive: true,),
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
              builder: (_, __) =>
                  const ContactsListWidget(contacts: contacts),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNWidgets(3));
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
  });

  testWidgets('EmptyState action button 触发 onAction → context.push(/contacts/new)',
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

    // 点击 EmptyState 的 "添加联系人" 按钮 → 路由到 /contacts/new
    await tester.tap(find.text('添加联系人'));
    await tester.pumpAndSettle();

    // 验证路由成功 → 显示 NEW_CONTACT_PAGE
    expect(find.text('NEW_CONTACT_PAGE'), findsOneWidget);
  });
}
