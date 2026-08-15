// 1.1.0 round 5b (emotion-first refactor · Task 12): 首页双主卡测试
//
// 覆盖:
// 1. MoodHeroCard 显示最新状态短语 (statusPhrase)
// 2. VentHeroCard 显示最新倾诉 1 行预览
// 3. 空数据 → homeMoodHeroNoData / homeVentHeroNoData
// 4. CheckInButton 渲染 compact 尺寸 (height < 64, 打卡降级)
//
// 测试策略: pump 完整 HomePage + ProviderScope overrides 轻量 fake 数据,
// 断言 hero 卡渲染内容 + CheckInButton compact 高度。
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget wrapHome({
  MoodEntryEntity? mood,
  List<VentEntryEntity> vent = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
    ],
  );
  return ProviderScope(
    overrides: [
      latestMoodProvider.overrideWith(
        (ref) => Stream<MoodEntryEntity?>.value(mood),
      ),
      ventEntriesProvider.overrideWith(
        (ref) => Stream<List<VentEntryEntity>>.value(vent),
      ),
      todayCheckInProvider.overrideWith(
        (ref) => Stream<CheckInEntity?>.value(null),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream<UserProfileEntity?>.value(null),
      ),
      todayAllCheckInsProvider.overrideWith(
        (ref) => Stream<List<CheckInEntity>>.value(const []),
      ),
      medicationsProvider.overrideWith(
        (ref) => Stream<List<MedicationEntity>>.value(const []),
      ),
      streakSummaryProvider.overrideWith(
        (ref) => const AsyncValue.data(
          StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
        ),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('1.1.0 round 5b 首页双主卡 (MoodHeroCard + VentHeroCard)', () {
    testWidgets('1. MoodHeroCard 显示最新状态短语 (statusPhrase)', (tester) async {
      final mood = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 14, 30),
        score: 4,
        statusPhrase: '被治愈了',
      );
      await tester.pumpWidget(wrapHome(mood: mood));
      await tester.pumpAndSettle();

      expect(
        find.text('被治愈了'),
        findsOneWidget,
        reason: 'MoodHeroCard 应显示最新 entry 的状态短语',
      );
    });

    testWidgets('2. VentHeroCard 显示最新倾诉 1 行预览', (tester) async {
      final vent = VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 10, 0),
        contentText: '今天想聊聊工作',
      );
      await tester.pumpWidget(wrapHome(vent: [vent]));
      await tester.pumpAndSettle();

      expect(
        find.text('今天想聊聊工作'),
        findsOneWidget,
        reason: 'VentHeroCard 应显示最新倾诉内容预览',
      );
    });

    testWidgets('3. 空数据 → 显示 homeMoodHeroNoData / homeVentHeroNoData',
        (tester) async {
      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      expect(
        find.text('今天还没记录心情'),
        findsOneWidget,
        reason: 'mood 空数据应显示 homeMoodHeroNoData',
      );
      expect(
        find.text('还没有倾诉, 写第一条心事'),
        findsOneWidget,
        reason: 'vent 空数据应显示 homeVentHeroNoData',
      );
    });

    testWidgets('4. CheckInButton 渲染 compact 尺寸 (height < 64)', (tester) async {
      await tester.pumpWidget(wrapHome());
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(CheckInButton));
      expect(
        size.height,
        lessThan(64),
        reason: '打卡降级 compact 后高度应 < 64',
      );
    });
  });
}
