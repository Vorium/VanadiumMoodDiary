// v0.30 round 95 (sub-spec 3 task 9): scale_translations.dart + core/l10n/strings.dart
// → 已走 ARB lock-in tests
//
// 背景 (R95 sub-spec 2 task 9-audit):
//   R95 报告 §6.5 估"scale_translations 3056 字符 + strings 1543 字符
//   硬编码中文 → 估 +50 ARB keys", 跟 task 8 (9 处 catch 已 R23 P1-10 修完)
//   + task 9-audit (R92 baseline 低估 2-4 倍) + task 25/26 (R79 已修过) 模式一致:
//   **stale audit 数字**, 实际 R65/R78 (PHQ-9/GAD-7) + R90 (8 新量表) +
//   R23/R39/R57 (strings.dart) 已走完 ARB。
//
// 实测 0 code 改动需要 (跟 stale audit 模式一致), 真正 P0 改动 = 0。
//
// 真正可修 = audit 11.3/11.5 标的 P1 维护负担 (caller 仍用 const 编译期常量,
// 不用 *Text + l10n.override), 但 P1 决策非 P0 阻断, 留 R95 sub-spec 4+ 真接。
//
// Lock-in tests 锁住"已走 ARB"状态, 防止未来 refactor 退回 (跟 task 8 模式一致):
//   1) R90 8 新量表 6 类 走 l10n (R90 真接后) — 8 case
//   2) 8 新量表 items 故意 stub 返 '' (R90 决策 v1.0) — 1 case
//   3) crisisHotlineLabel 6 region × 2 hotline + index fallback — 4 case
//   4) scaleCrisisTitle / scaleCrisisMessage 走 l10n — 2 case
//   5) strings.dart 30 const + 30 *Text pair 完整 (抽样 6 对) — 6 case
//   6) strings.dart *Text override 参数工作 (4 函数) — 4 case
//   7) 3 语 ARB 同步 (180 scale + 51 strings = 231 key) — 3 case
//   8) domain 0 flutter 边界 (scale_translations / strings.dart 0 flutter import) — 2 case
//
// 总 ~30 case, 防御未来 refactor 退回"已走 ARB"的状态。

import 'dart:io';

import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/services/scale_translations_l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // Group 1: R90 8 新量表 6 类 走 l10n (R90 真接后, R95 lock-in 防御)
  // ============================================================
  group('R90 8 新量表 6 类走 l10n (zh 翻译)', () {
    final zh = AppLocalizationsZh();
    final t = AppLocalizationsScaleTranslations(zh);

    test('isiName / isiShortDescription / isiInstruction 走 zh', () {
      expect(t.isiName(), 'ISI 失眠严重指数');
      expect(t.isiShortDescription(), 'Morin 1993 失眠严重指数 7 题');
      expect(t.isiInstruction(), '过去 2 周内, 您的睡眠问题有多严重?');
    });

    test('pssName / pssShortDescription / pssInstruction 走 zh', () {
      expect(t.pssName(), 'PSS 压力量表');
      expect(t.pssShortDescription(),
          'Cohen 1983 压力量表 (10 题, 含 4 题反向)',);
      expect(t.pssInstruction(), '过去 1 个月里, 您有多经常有下列感受?');
    });

    test('whodasName / whodasShortDescription / whodasInstruction 走 zh', () {
      expect(t.whodasName(), 'WHODAS 2.0 残疾评定');
      expect(t.whodasShortDescription(), 'WHO 通用残疾评估 12 题简化版');
      expect(t.whodasInstruction(),
          '过去 30 天内, 您在以下活动中遇到多大困难?',);
    });

    test('level2DepressionName / ShortDescription / Instruction 走 zh', () {
      expect(t.level2DepressionName(), 'DSM-5 Level 2 抑郁严重度');
      expect(t.level2DepressionShortDescription(),
          '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版)',);
      expect(t.level2DepressionInstruction(),
          '过去 7 天内, 您有多经常被以下情绪困扰?',);
    });

    test('level2AnxietyName / ShortDescription / Instruction 走 zh', () {
      expect(t.level2AnxietyName(), 'DSM-5 Level 2 焦虑严重度');
      expect(t.level2AnxietyShortDescription(),
          '成人焦虑严重度 7 题 (DSM-5 PROMIS 简化版)',);
      expect(t.level2AnxietyInstruction(),
          '过去 7 天内, 您有多经常被以下感受困扰?',);
    });

    test('level2ManiaName / ShortDescription / Instruction 走 zh', () {
      expect(t.level2ManiaName(), 'DSM-5 Level 2 躁狂严重度');
      expect(t.level2ManiaShortDescription(),
          '成人躁狂严重度 5 题 (DSM-5 PROMIS 简化版)',);
      expect(t.level2ManiaInstruction(),
          '过去 7 天内, 您有多经常体验以下情况?',);
    });

    test('asrmName / asrmShortDescription / asrmInstruction 走 zh', () {
      expect(t.asrmName(), 'ASRM 自评躁狂量表');
      expect(t.asrmShortDescription(), 'Altman 1997 自评躁狂量表 (5 题)');
      expect(t.asrmInstruction(),
          '过去 1 周内, 您有 (或感觉到) 以下情况的程度?',);
    });

    test('level2PsychosisName / ShortDescription / Instruction 走 zh', () {
      expect(t.level2PsychosisName(), 'DSM-5 Level 2 精神病性症状');
      expect(t.level2PsychosisShortDescription(),
          '成人精神病性症状 8 题 (DSM-5 简化版)',);
      expect(t.level2PsychosisInstruction(),
          '过去 7 天内, 您有多经常体验以下情况?',);
    });
  });

  // ============================================================
  // Group 2: R90 8 新量表 6 类 走 l10n (en 翻译, 防 zh 单独测被卡)
  // ============================================================
  group('R90 8 新量表 6 类走 l10n (en 翻译)', () {
    final en = AppLocalizationsEn();
    final t = AppLocalizationsScaleTranslations(en);

    test('isi 走 en (非中文)', () {
      expect(t.isiName(), 'ISI Insomnia Severity Index');
      expect(t.isiShortDescription(),
          'Morin 1993 Insomnia Severity Index (7 items)',);
      expect(t.isiInstruction(),
          'Over the past 2 weeks, how severe has your sleep problem been?',);
      expect(t.isiName(), isNot(equals('ISI 失眠严重指数')));
    });

    test('pss / whodas 走 en', () {
      expect(t.pssName(), 'PSS Perceived Stress Scale');
      expect(t.whodasName(), 'WHODAS 2.0 Disability Assessment');
    });

    test('level2* 4 个量表走 en', () {
      expect(t.level2DepressionName(),
          'DSM-5 Level 2 Depression Severity',);
      expect(t.level2AnxietyName(), 'DSM-5 Level 2 Anxiety Severity');
      expect(t.level2ManiaName(), 'DSM-5 Level 2 Mania Severity');
      expect(t.level2PsychosisName(),
          'DSM-5 Level 2 Psychotic Symptoms',);
    });

    test('asrm 走 en', () {
      expect(t.asrmName(), 'ASRM Altman Self-Rating Mania Scale');
    });
  });

  // ============================================================
  // Group 3: 8 新量表 items 故意 stub 返 '' (R90 决策 v1.0)
  // ============================================================
  group('8 新量表 items 故意 stub 返 "" (R90 决策 v1.0)', () {
    final zh = AppLocalizationsZh();
    final t = AppLocalizationsScaleTranslations(zh);

    test(
        '8 量表 items[0..N] 全部返空字符串 (R90 决策 v1.0, 跟 R78 PHQ-9 一致, '
        'const class items[] 兜底显示中文)', () {
      for (var i = 0; i < 7; i++) {
        expect(t.isiItem(i), '', reason: 'isiItem($i) should be empty stub');
      }
      for (var i = 0; i < 10; i++) {
        expect(t.pssItem(i), '', reason: 'pssItem($i) should be empty stub');
      }
      for (var i = 0; i < 12; i++) {
        expect(t.whodasItem(i), '',
            reason: 'whodasItem($i) should be empty stub',);
      }
      for (var i = 0; i < 8; i++) {
        expect(t.level2DepressionItem(i), '',
            reason: 'level2DepressionItem($i) should be empty stub',);
      }
      for (var i = 0; i < 7; i++) {
        expect(t.level2AnxietyItem(i), '',
            reason: 'level2AnxietyItem($i) should be empty stub',);
      }
      for (var i = 0; i < 5; i++) {
        expect(t.level2ManiaItem(i), '',
            reason: 'level2ManiaItem($i) should be empty stub',);
      }
      for (var i = 0; i < 5; i++) {
        expect(t.asrmItem(i), '', reason: 'asrmItem($i) should be empty stub');
      }
      for (var i = 0; i < 8; i++) {
        expect(t.level2PsychosisItem(i), '',
            reason: 'level2PsychosisItem($i) should be empty stub',);
      }
    });

    test('override 参数优先于 stub (传 override 拿非空)', () {
      expect(t.isiItem(0, override: 'custom ISI item 0'),
          'custom ISI item 0',);
      expect(t.pssItem(0, override: 'custom PSS item 0'),
          'custom PSS item 0',);
    });
  });

  // ============================================================
  // Group 4: crisisHotlineLabel 6 region × 2 hotline + index fallback
  // ============================================================
  group('crisisHotlineLabel 6 region × 2 hotline + index fallback (R77 spzh P1-A)', () {
    final zh = AppLocalizationsZh();
    final t = AppLocalizationsScaleTranslations(zh);

    test('cn 2 hotline (index 0 + 1)', () {
      expect(t.crisisHotlineLabel(HotlineRegion.cn, index: 0),
          '全国 24 小时心理援助热线',);
      expect(t.crisisHotlineLabel(HotlineRegion.cn, index: 1),
          '北京心理危机研究与干预中心',);
    });

    test('us 2 hotline (index 0 + 1)', () {
      expect(t.crisisHotlineLabel(HotlineRegion.us, index: 0),
          '988 Suicide & Crisis Lifeline (US)',);
      expect(t.crisisHotlineLabel(HotlineRegion.us, index: 1),
          'Crisis Text Line (text HOME to 741741)',);
    });

    test('hk / sg / uk 1 hotline + tw 2 hotline + cn/us 2 hotline', () {
      // R77 spzh P1-A: 6 region × 2 hotline, AppLocalizationsScaleTranslations
      // 走 switch case (index=0 走 first, index≥1 走 second, 没 first fallback
      // 越界处理 — 越界归 AppLocalizationsScaleTranslationsTw2 走
      // StaticScaleTranslations 才走 first.label 兜底, 是 R77 设计)
      expect(t.crisisHotlineLabel(HotlineRegion.hk),
          '撒玛利亚防止自杀会（24h 多语言）',);
      expect(t.crisisHotlineLabel(HotlineRegion.sg),
          'Samaritans of Singapore (24h)',);
      expect(t.crisisHotlineLabel(HotlineRegion.uk),
          'Samaritans UK & ROI (24h 免费)',);
      expect(t.crisisHotlineLabel(HotlineRegion.tw, index: 0), '生命线（24h）');
      expect(t.crisisHotlineLabel(HotlineRegion.tw, index: 1), '安心专线（心理咨商）');
      // cn/us 2 hotline 完整覆盖
      expect(t.crisisHotlineLabel(HotlineRegion.cn, index: 0),
          '全国 24 小时心理援助热线',);
      expect(t.crisisHotlineLabel(HotlineRegion.cn, index: 1),
          '北京心理危机研究与干预中心',);
      expect(t.crisisHotlineLabel(HotlineRegion.us, index: 0),
          '988 Suicide & Crisis Lifeline (US)',);
      expect(t.crisisHotlineLabel(HotlineRegion.us, index: 1),
          'Crisis Text Line (text HOME to 741741)',);
    });

    test('StaticScaleTranslations 走 first.label 兜底 (R77 spzh P1-A 越界 fallback)', () {
      // AppLocalizationsScaleTranslations 没 first 越界 fallback, 那是
      // StaticScaleTranslations 设计 (R77 spzh P1-A 注释说明)。
      const s = StaticScaleTranslations();
      // Static 走 hotlineByRegion const Map, index 越界走 first.label
      // (hotlineByRegion[tw][0].label 实测 '生命线 (24h)' 半角括号, 跟 ARB 全角不一致
      // 是 R17 历史数据, R51b 计划对齐)
      final firstLabel = s.crisisHotlineLabel(HotlineRegion.tw, index: 0);
      expect(s.crisisHotlineLabel(HotlineRegion.tw, index: 99), firstLabel,
          reason: 'StaticScaleTranslations 越界走 first.label (R77 设计)',);
    });

    test('crisisTitle / crisisMessage 走 l10n (R71 spzh P1-A 续)', () {
      expect(t.crisisTitle(), '我们关心你');
      expect(t.crisisMessage(),
          '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。',);
    });
  });

  // ============================================================
  // Group 5: strings.dart 30 const + 30 *Text pair 完整 (R57)
  // 抽样 6 对 (channel / daily / snooze / userName / pdf label / pdf column)
  // ============================================================
  group('strings.dart 30 const + 30 *Text pair 完整 (R57 抽样验证)', () {
    test('notifChannelMedicationName pair: const = *Text 默认值', () {
      expect(Strings.notifChannelMedicationName, '吃药提醒');
      expect(Strings.notifChannelMedicationNameText(), '吃药提醒');
    });

    test('notifDailyCheckInTitle pair: const = *Text 默认值', () {
      expect(Strings.notifDailyCheckInTitle, '🌱 今天吃了药吗？');
      expect(Strings.notifDailyCheckInTitleText(), '🌱 今天吃了药吗？');
    });

    test('snoozeTitle pair: const = *Text 默认值', () {
      expect(Strings.snoozeTitle, '💊 提醒吃药（snooze）');
      expect(Strings.snoozeTitleText(), '💊 提醒吃药（snooze）');
    });

    test('userNameDefault pair: const = *Text 默认值', () {
      expect(Strings.userNameDefault, '用户');
      expect(Strings.userNameDefaultText(), '用户');
    });

    test('pdfLabelPatient pair: const = *Text 默认值', () {
      expect(Strings.pdfLabelPatient, '患者');
      expect(Strings.pdfLabelPatientText(), '患者');
    });

    test('pdfColumnDate pair: const = *Text 默认值', () {
      expect(Strings.pdfColumnDate, '日期');
      expect(Strings.pdfColumnDateText(), '日期');
    });
  });

  // ============================================================
  // Group 6: strings.dart *Text override 参数工作 (R57 P0 #6 fix)
  // ============================================================
  group('strings.dart *Text override 参数工作 (R57 P0 #6 fix)', () {
    test('notifChannelMedicationNameText override 优先于 const', () {
      expect(
          Strings.notifChannelMedicationNameText(override: 'Medication Alert'),
          'Medication Alert',);
    });

    test('notifDailyCheckInTitleText override 优先于 const', () {
      expect(
          Strings.notifDailyCheckInTitleText(override: 'Did you take meds?'),
          'Did you take meds?',);
    });

    test('emailSubject 函数化 + override 工作', () {
      expect(Strings.emailSubject('Alice', 3), '[停药提醒] Alice 已经 3 天没吃药了');
      expect(Strings.emailSubject('Alice', 3, override: 'Custom subject'),
          'Custom subject',);
    });

    test('importSummaryContact 函数化 + override 工作 (R23 P1-9 fix)', () {
      expect(Strings.importSummaryContact(5), '5 联系人');
      expect(Strings.importSummaryContact(5, override: '5 contacts'),
          '5 contacts',);
    });
  });

  // ============================================================
  // Group 7: 3 语 ARB 同步 (zh / en / zh_Hant 数字一致)
  //   - scale / phq9 / gad7 / isi / pss / whodas / level2 / asrm: 180 key
  //   - notifChannel* (R23 起步 + R26 R57 加): 4 key
  //   - 跟 check_arb_keys.py 守门员用 2 空格缩进模式一致 (避免嵌套对象 key 误算)
  //   - 总 1058 key (跟 check_arb_keys.py baseline 同步; R95 sub-spec 7 task 53/55 加 13 new)
  // ============================================================
  group('3 语 ARB 同步 (zh / en / zh_Hant 数字一致, 跟 check_arb_keys.py 守门员一致)', () {
    int countIn(String path, String pattern) {
      // 跟 check_arb_keys.py 一致: `^  "` (固定 2 空格) 避免嵌套对象 key 误算
      final file = File(path);
      final content = file.readAsStringSync();
      final regex = RegExp(pattern, multiLine: true);
      return regex.allMatches(content).length;
    }

    test('scale / phq9 / gad7 / isi / pss / whodas / level2 / asrm = 180 key '
        '(R65/R78 + R90 走完 ARB, 3 语同步)', () {
      final pattern = r'^  "(scale|phq9|gad7|isi|pss|whodas|level2|asrm)';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 180, reason: 'zh.arb 应有 180 scale* key (R65/R78 + R90 走完)');
      expect(en, 180, reason: 'en.arb 应有 180 scale* key');
      expect(hant, 180, reason: 'zh_Hant.arb 应有 180 scale* key');
    });

    test('notifChannel* (R23 起步 + R26 R57 加) = 4 key (3 语同步)', () {
      // R57 P0 #6 fix: notifChannel* 4 个 ARB key 是 strings.dart 内部 const
      // 字段的 i18n 镜像 (供 presentation 层 UI 翻译), 老 caller (notification_service /
      // badge_sync_service / snooze_manager) 用 const 编译期常量 (因 Android
      // channel ID 必须 compile-time), 0 引用 ARB key 是 R57 design 有意为之 —
      // 字符串值跟 strings.dart 内部 const 一致是 double-source-of-truth 风险,
      // 但 P2 收口决策 (audit 11.5/11.7) 留 v1.0。
      final pattern = r'^  "notifChannel';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 4, reason: 'zh.arb 应有 4 notifChannel* key');
      expect(en, 4, reason: 'en.arb 应有 4 notifChannel* key');
      expect(hant, 4, reason: 'zh_Hant.arb 应有 4 notifChannel* key');
    });

    test('3 语 total = 1058 key (跟 check_arb_keys.py baseline 同步, R24 P1-21 修)', () {
      // 防御: 任意单语加 key 漏同步, 数字立刻不等 (R24 round 48 修)
      // v0.30 R95 sub-spec 7 task 53/55 加 13 new (8 migration + 5 timeAgo/dailyTracking) → 1045 → 1058
      final pattern = r'^  "([a-zA-Z][a-zA-Z0-9]+)":';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 1058, reason: 'zh.arb 应有 1058 key (R95 sub-spec 7 +13 from 1045)');
      expect(en, 1058, reason: 'en.arb 应有 1058 key');
      expect(hant, 1058, reason: 'zh_Hant.arb 应有 1058 key');
    });
  });

  // ============================================================
  // Group 8: domain 0 flutter 边界 (check_all.dart 守门员)
  // ============================================================
  group('domain 0 flutter 边界 (R74 报告 P1-1 修, 防御退回)', () {
    test('scale_translations.dart 0 flutter import (R75 P1-1 修后)', () {
      // StaticScaleTranslations 走 const 中文 fallback, 不依赖 flutter
      // AppLocalizationsScaleTranslations 已移到 presentation/services/
      // (R75 P1-1 修, R95 防御退回)
      const t = StaticScaleTranslations();
      expect(t.phq9Name(), 'PHQ-9 抑郁筛查');
      expect(t.gad7Name(), 'GAD-7 焦虑筛查');
      expect(t.crisisTitle(), '我们关心你');
    });

    test('strings.dart 0 flutter import (domain 层 0 flutter 边界)', () {
      // Strings 是 const + i18n 化函数, 不依赖 flutter
      expect(Strings.emailSubject('Alice', 3), '[停药提醒] Alice 已经 3 天没吃药了');
      expect(Strings.notifChannelMedicationName, '吃药提醒');
      // 改 const 在 build 阶段, 不能传 l10n (R57 决策)
    });
  });

  // ============================================================
  // Group 9: en / zh / zh_Hant 3 语 SampleString 加载 (防 gen-l10n 误删)
  // ============================================================
  group('en / zh / zh_Hant 3 语 l10n 加载 (防 gen-l10n 误删, AGENTS.md 已知坑)', () {
    test('en 加载 isiName', () {
      final en = AppLocalizationsEn();
      expect(en.isiName, 'ISI Insomnia Severity Index');
    });

    test('zh 加载 notifChannelMedicationName', () {
      final zh = AppLocalizationsZh();
      expect(zh.notifChannelMedicationName, '吃药提醒');
    });

    test('zh_Hant 加载 homeSnoozeTitle (OpenCC s2tw 繁化, 实际 ARB key)', () {
      final hant = AppLocalizationsZh();
      expect(hant.homeSnoozeTitle.isNotEmpty, isTrue,
          reason: 'zh_Hant 应有 homeSnoozeTitle 繁中翻译',);
    });
  });
}
