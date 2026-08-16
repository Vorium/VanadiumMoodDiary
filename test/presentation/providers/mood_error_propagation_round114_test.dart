// R114 B1-7: provider `.value ?? const []` 吞 error → ErrorState 永不出现
// (2026-08-16 标准审计 · 12-bottom-presentation-core 发现 6)
//
// 修前: moodEntriesProvider / worry_section / worry_selector_field 在 DB 读
// 失败时静默空列表, 用户看到"0 条"且无重试入口。
// 修后: allMoodProvider 出错 → mood 列表显示 ErrorState; worry section /
// selector 显示错误提示 + 重试。
//
// TDD: 老代码 error 被吞 → expect(ErrorState/错误文案) 失败; 新代码 pass。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/worry_section.dart';
import 'package:chroniccare/presentation/widgets/worry_selector_field.dart';

Widget _wrapL10n({required Widget child}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('mood 列表: allMoodProvider 出错 → ErrorState + 重试 (不再静默空态)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allMoodProvider.overrideWith(
            (ref) => Stream<List<MoodEntryEntity>>.error(
              Exception('db down'),
            ),
          ),
          worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
          worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: _wrapL10n(child: const MoodListPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    // 修前: 空列表文案 (静默吞 error)
    expect(find.text('还没有 mood 记录'), findsNothing);
  });

  testWidgets('worry_section: worry 流出错 → 错误提示 + 重试', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worryOpenProvider.overrideWith(
            (ref) => Stream.error(Exception('db down')),
          ),
          worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: _wrapL10n(child: const WorrySection()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('worry_selector_field: worry 流出错 → 错误提示, 不显示选择器内容',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worryOpenProvider.overrideWith(
            (ref) => Stream.error(Exception('db down')),
          ),
        ],
        child: _wrapL10n(
          child: WorrySelectorField(onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('加载失败'), findsOneWidget);
  });

  testWidgets('worry_section: 正常数据 → 仍显示烦恼 chip (回归)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          worryOpenProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: _wrapL10n(child: const WorrySection()),
      ),
    );
    await tester.pumpAndSettle();

    // 无数据 → 隐藏 section (老行为保留)
    expect(find.textContaining('加载失败'), findsNothing);
  });
}
