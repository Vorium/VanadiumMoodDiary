// 1.1.0 round 5b (emotion-first refactor · Task 12): 首页双主卡测试
//
// 覆盖:
// 1. MoodHeroCard 显示最新状态短语 (statusPhrase)
// 2. VentHeroCard 显示最新倾诉 1 行预览
// 3. 空数据 → homeMoodHeroNoData / homeVentHeroNoData
// 4. CheckInButton 渲染 compact 尺寸 (height < 64, 打卡降级)
// 5. audio-only 树洞条目显示语音预览
// 6. tap 查看全部 → /mood-list 路由
// 7. R114 BUG 5: vent 封存 → 首页不泄漏预览 (PIPL §47)
//
// 测试策略: pump 完整 HomePage + ProviderScope overrides 轻量 fake 数据,
// 断言 hero 卡渲染内容 + CheckInButton compact 高度。
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrapHome({
  MoodEntryEntity? mood,
  List<VentEntryEntity> vent = const [],
  SharedPreferences? prefs,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      // round 7c: /mood-list 入口补齐 (查看全部 → 路由到达断言用 stub)
      GoRoute(
        path: '/mood-list',
        builder: (context, state) =>
            const Scaffold(body: Text('mood-list-stub')),
      ),
    ],
  );
  final overrides = [
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
    // v1.1.0 round 11 (R115): TodaySummaryCard 改 4 指标后新增的
    // sleepEntriesProvider / worryOpenProvider 需要 override, 否则
    // 默认走真实 DB provider 在测试环境会抛错 / 留 pending Timer。
    sleepEntriesProvider.overrideWith(
      (ref) => Stream<List<SleepEntryEntity>>.value(const []),
    ),
    worryOpenProvider.overrideWith(
      (ref) => Stream<List<WorryThreadEntity>>.value(const []),
    ),
    // R114 BUG 5: VentHeroCard watch ventSealedProvider → 需要真实
    // mock prefs (sealed 状态由 ConsentPreferenceStore 读
    // 'legal_consent_vent_sealed_at' key)。不传 prefs 时省略 override
    // 走 provider 默认 throw → StreamProvider AsyncError → orElse
    // (sealed=false) 兜底。
    if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// 用 mock SharedPreferences 造 vent 封存状态 (R114 BUG 5)
Future<SharedPreferences> mockPrefs({bool ventSealed = false}) async {
  SharedPreferences.setMockInitialValues({
    if (ventSealed) 'legal_consent_vent_sealed_at': 1,
  });
  return SharedPreferences.getInstance();
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
      await tester.pumpWidget(wrapHome(mood: mood, prefs: await mockPrefs()));
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
      await tester.pumpWidget(wrapHome(vent: [vent], prefs: await mockPrefs()));
      await tester.pumpAndSettle();

      expect(
        find.text('今天想聊聊工作'),
        findsOneWidget,
        reason: 'VentHeroCard 应显示最新倾诉内容预览',
      );
    });

    testWidgets('3. 空数据 → 显示 homeMoodHeroNoData / homeVentHeroNoData',
        (tester) async {
      await tester.pumpWidget(wrapHome(prefs: await mockPrefs()));
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
      await tester.pumpWidget(wrapHome(prefs: await mockPrefs()));
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(CheckInButton));
      expect(
        size.height,
        lessThan(64),
        reason: '打卡降级 compact 后高度应 < 64',
      );
    });

    testWidgets('5. audio-only 树洞条目显示语音预览而非空态 (P0-3 修复)', (tester) async {
      final vent = VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 9, 0),
        audioPath: 'vent_audio/1.m4a.enc',
        audioDurationSec: 30,
      );
      await tester.pumpWidget(wrapHome(vent: [vent], prefs: await mockPrefs()));
      await tester.pumpAndSettle();

      expect(
        find.text('还没有倾诉, 写第一条心事'),
        findsNothing,
        reason: '已有语音倾诉时不应显示空态文案',
      );
      expect(
        find.text('🎙️ 语音'),
        findsOneWidget,
        reason: 'audio-only 条目应显示 ventVoiceLabel 语音预览',
      );
    });

    testWidgets('6. tap 查看全部 → /mood-list 路由到达 (round 7c 死路由入口补齐)',
        (tester) async {
      final mood = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 14, 30),
        score: 4,
        statusPhrase: '被治愈了',
      );
      await tester.pumpWidget(wrapHome(mood: mood, prefs: await mockPrefs()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('查看全部'));
      await tester.tap(find.text('查看全部'));
      await tester.pumpAndSettle();

      expect(
        find.text('mood-list-stub'),
        findsOneWidget,
        reason: 'tap 查看全部应 push /mood-list 路由',
      );
    });

    testWidgets('7. R114 BUG 5: vent 封存 → 首页不泄漏预览 (PIPL §47) + 隐藏写心事',
        (tester) async {
      final vent = VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 10, 0),
        contentText: '这是一条封存后不该出现在首页的内容',
      );
      await tester.pumpWidget(
        wrapHome(
          vent: [vent],
          prefs: await mockPrefs(ventSealed: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('这是一条封存后不该出现在首页的内容'),
        findsNothing,
        reason: 'sealed=true 时 VentHeroCard 不得显示树洞内容预览 (PIPL §47)',
      );
      expect(
        find.text('已加密封存'),
        findsOneWidget,
        reason: '封存态应显示 ventSealedTitle 占位',
      );
      expect(
        find.text('写心事'),
        findsNothing,
        reason: '封存态隐藏写心事入口 (跟 vent_list FAB 隐藏同语义)',
      );
    });

    testWidgets('8. R114 BUG 5: 未封存 → 预览正常显示 (gate 不误伤)', (tester) async {
      final vent = VentEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 15, 10, 0),
        contentText: '今天想聊聊工作',
      );
      await tester.pumpWidget(
        wrapHome(
          vent: [vent],
          prefs: await mockPrefs(ventSealed: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('今天想聊聊工作'),
        findsOneWidget,
        reason: '未封存时预览应正常显示',
      );
      expect(find.text('写心事'), findsOneWidget);
    });
  });
}
