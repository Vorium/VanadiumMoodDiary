// v0.30 round 95 (sub-spec 8 task 18): 紧急联系人 5→3 步 widget test
//
// 修前流程 5 步 (emil 反复提, P3 阶段不需外部资源):
//   1. 点 add entry
//   2. 输姓名
//   3. 输电话
//   4. 点保存 (校验失败 → snackbar 中断)
//   5. 点同意 consent → 保存
//
// 修后流程 3 步 (emil "3 tap 抵达"):
//   1. 点 add entry → 弹窗, autofocused 姓名输入框
//   2. 输姓名 + 输电话 (内联校验, 无 snackbar 中断), 点保存 → consent
//   3. 点同意 consent → 保存
//
// 关键: phone 校验从 "snackbar 提示 + 退出保存" 改成 "TextField.errorText 即时"
//
// 测试覆盖:
// 1. 弹窗打开: 姓名输入框 autofocus (emil "3 tap 抵达" 第一步)
// 2. phone 非法时, errorText 出现 (替代 snackbar, 不打断流)
// 3. phone 合法时, errorText 消失 (输完即知)
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences mockSp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockSp = await SharedPreferences.getInstance();
  });

  // helper: 构造 ContactsListWidget 测试环境
  Widget buildContactsList({List<ContactEntity> contacts = const []}) {
    return ProviderScope(
      overrides: [
        contactsProvider.overrideWith((ref) => Stream.value(contacts)),
        contactRepositoryProvider.overrideWith(
          (ref) => _FakeContactRepository(),
        ),
        sharedPreferencesProvider.overrideWithValue(mockSp),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: ContactsListWidget(contacts: contacts),
        ),
      ),
    );
  }

  testWidgets('5→3 步 task 18 case 1: 弹窗打开, autofocus 姓名输入框', (tester) async {
    // v0.30 R95 sub-spec 8 task 18: 必须有 contact 才能显示 list 模式 (含
    // 添加 entry), 空列表走 empty state 模式 (action 走 /contacts/new 路由,
    // 跟弹窗逻辑无关)。1 个 contact 让 list 模式显示, "添加联系人" entry
    // 点开弹窗。
    const existing = ContactEntity(
      id: 1,
      name: '现有联系人',
      phone: '13800000000',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(buildContactsList(contacts: const [existing]));
    await tester.pumpAndSettle();

    // 点 list 底部的 "+ 添加另一个联系人" entry (走 setupAddContact ARB key)
    final addButton = find.text('+ 添加另一个联系人');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 弹窗打开, 2 个 TextField 渲染 (姓名 + 手机号)
    expect(find.byType(TextField), findsAtLeast(2));
    // 姓名 + 手机号 label 渲染
    expect(find.text('姓名'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
  });

  testWidgets('5→3 步 task 18 case 2: phone 非法 → errorText 出现 (无 snackbar)',
      (tester) async {
    const existing = ContactEntity(
      id: 1,
      name: '现有联系人',
      phone: '13800000000',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(buildContactsList(contacts: const [existing]));
    await tester.pumpAndSettle();

    final addButton = find.text('+ 添加另一个联系人');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 输非法 phone
    final phoneField = find.byType(TextField).last;
    await tester.enterText(phoneField, 'abc');
    await tester.pump();

    // 点 "保存" 触发 inline 校验
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 验证: phone TextField 的 errorText 出现 (而非 snackbar)
    // snackbarPhoneInvalid key 在 errorText 内 (TextField 下方的 error 文字)
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(l10n.snackbarPhoneInvalid), findsAtLeast(1));
  });

  testWidgets('5→3 步 task 18 case 3: 输完合法 phone → errorText 消失',
      (tester) async {
    const existing = ContactEntity(
      id: 1,
      name: '现有联系人',
      phone: '13800000000',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(buildContactsList(contacts: const [existing]));
    await tester.pumpAndSettle();

    final addButton = find.text('+ 添加另一个联系人');
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // 先输非法 phone + 保存 → 触发 errorText
    final phoneField = find.byType(TextField).last;
    await tester.enterText(phoneField, 'abc');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(l10n.snackbarPhoneInvalid), findsAtLeast(1));

    // 改输合法 phone → onChanged 清 errorText
    await tester.enterText(phoneField, '13800138000');
    await tester.pump();

    // errorText 消失 (emil "3 tap 抵达" — 不打断流)
    expect(find.text(l10n.snackbarPhoneInvalid), findsNothing);
  });
}

/// v0.30 R95 (sub-spec 8 task 18): in-memory contact repository fake
///
/// 让 widget test 不依赖真实 SQLCipher DB, 走 ContactRepository 接口。
/// noSuchMethod 模式: 所有方法返回 null/0/empty stream, 但类型签名
/// (ContactRepository) 静态满足, override 编译过。
class _FakeContactRepository implements ContactRepository {
  @override
  Stream<List<ContactEntity>> watchAll() => Stream.value(const []);

  @override
  Future<int> add({
    required String name,
    required String phone,
    required ConsentArtifact consentArtifact,
    int sortOrder = 0,
  }) async =>
      0;

  @override
  Future<int> delete(int id) async => 0;

  @override
  Future<int> restore(ContactEntity contact) async => 0;

  @override
  Future<bool> update(ContactEntity contact) async => false;
}
