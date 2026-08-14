// v0.32 R112 round 8i (渲染专项): 窄屏 + 大字号防溢出 smoke 测试
//
// 用户实测反馈"视觉错位/溢出" — 全量 widget test 默认 800×600 逻辑宽
// (比真机 360dp 宽一倍), 溢出在真机才出现。本文件把关键行组件在
// 320×640 + textScaler 1.3~2.0 下 pump, RenderFlex overflow 在 test
// 里会直接抛异常 = 防回归守门。

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_audio_section.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap({required double textScale, required Widget child}) {
  return MaterialApp(
    theme: ThemeData.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    builder: (context, w) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: w!,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  for (final scale in [1.3, 2.0]) {
    group('textScaler $scale', () {
      testWidgets('VentAudioSection 录音行 (长时长 59:59) 不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: VentAudioSection(
              isRecording: true,
              isPaused: false,
              recordingElapsed: const Duration(minutes: 59, seconds: 59),
              audioPath: null,
              audioDurationSec: null,
              isPlaying: false,
              onToggleRecord: () {},
              onTogglePause: () {},
              onTogglePlay: () {},
              onReRecord: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.pause), findsOneWidget);
        expect(find.byIcon(Icons.stop), findsOneWidget);
      });

      testWidgets('VentAudioSection 暂停行不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: VentAudioSection(
              isRecording: false,
              isPaused: true,
              recordingElapsed: const Duration(minutes: 9, seconds: 8),
              audioPath: null,
              audioDurationSec: null,
              isPlaying: false,
              onToggleRecord: () {},
              onTogglePause: () {},
              onTogglePlay: () {},
              onReRecord: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('VentAudioSection 已录行 (时长 + 重录按钮) 不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: VentAudioSection(
              isRecording: false,
              isPaused: false,
              recordingElapsed: Duration.zero,
              audioPath: '/x.m4a.enc',
              audioDurationSec: 3599,
              isPlaying: false,
              onToggleRecord: () {},
              onTogglePause: () {},
              onTogglePlay: () {},
              onReRecord: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('StatCard 长数字 + 长标签不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: const SizedBox(
              width: 140,
              child: StatCard(
                label: '距离下次续方提醒天数',
                value: '99999',
                valueColor: AppColors.warning,
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('SectionHeader 复合模式 (title + chip + action) 窄屏不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: SectionHeader(
              title: '这是一段很长的章节标题文字也很长',
              chip: '999',
              action: TextButton(onPressed: () {}, child: const Text('查看全部')),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('AppleListSection title + chip 窄屏不溢出', (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _wrap(
            textScale: scale,
            child: const AppleListSection(
              title: '这是一段很长的章节标题文字',
              chip: '999',
              children: [Text('cell')],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
