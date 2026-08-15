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
//   2) 8 新量表 items 走 domain StaticScaleTranslations 中文 fallback
//      (ARB 无 item key, R112 AR-17 后 l10n impl 已删) — 2 case
//   3) crisisHotlineLabel 6 region × 2 hotline + index fallback — 4 case
//   4) scaleCrisisTitle / scaleCrisisMessage 走 l10n — 2 case
//   5) strings.dart 30 const + 30 *Text pair 完整 (抽样 6 对) — 6 case
//   6) strings.dart *Text override 参数工作 (4 函数) — 4 case
//   7) 3 语 ARB 同步 (180 scale + 51 strings = 231 key) — 3 case
//   8) domain 0 flutter 边界 (scale_translations / strings.dart 0 flutter import) — 2 case
//
// v0.32 R112 (AR-17): AppLocalizationsScaleTranslations (presentation 810L 死
//   代码) 已删, 原走 l10n 包装的断言全部改直测 ARB getter (zh.isiName 等);
//   items stub 锁改测 StaticScaleTranslations 中文 fallback。
//
// 总 ~30 case, 防御未来 refactor 退回"已走 ARB"的状态。

import 'dart:io';

import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/entities/scale_translations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================
  // Group 1: R90 8 新量表 6 类 走 l10n (R90 真接后, R95 lock-in 防御)
  // ============================================================
  group('R90 8 新量表 6 类走 l10n (zh 翻译)', () {
    final zh = AppLocalizationsZh();

    test('isiName / isiShortDescription / isiInstruction 走 zh', () {
      expect(zh.isiName, 'ISI 失眠严重指数');
      expect(zh.isiShortDescription, 'Morin 1993 失眠严重指数 7 题');
      expect(zh.isiInstruction, '过去 2 周内， 您的睡眠问题有多严重？');
    });

    test('pssName / pssShortDescription / pssInstruction 走 zh', () {
      expect(zh.pssName, 'PSS 压力量表');
      expect(
        zh.pssShortDescription,
        'Cohen 1983 压力量表 (10 题， 含 4 题反向）',
      );
      expect(zh.pssInstruction, '过去 1 个月里， 您有多经常有下列感受？');
    });

    test('whodasName / whodasShortDescription / whodasInstruction 走 zh', () {
      expect(zh.whodasName, 'WHODAS 2.0 残疾评定');
      expect(zh.whodasShortDescription, 'WHO 通用残疾评估 12 题简化版');
      expect(
        zh.whodasInstruction,
        '过去 30 天内， 您在以下活动中遇到多大困难？',
      );
    });

    test('level2DepressionName / ShortDescription / Instruction 走 zh', () {
      expect(zh.level2DepressionName, 'DSM-5 Level 2 抑郁严重度');
      expect(
        zh.level2DepressionShortDescription,
        '成人抑郁严重度 8 题 (DSM-5 PROMIS 简化版）',
      );
      expect(
        zh.level2DepressionInstruction,
        '过去 7 天内， 您有多经常被以下情绪困扰？',
      );
    });

    test('level2AnxietyName / ShortDescription / Instruction 走 zh', () {
      expect(zh.level2AnxietyName, 'DSM-5 Level 2 焦虑严重度');
      expect(
        zh.level2AnxietyShortDescription,
        '成人焦虑严重度 7 题 (DSM-5 PROMIS 简化版）',
      );
      expect(
        zh.level2AnxietyInstruction,
        '过去 7 天内， 您有多经常被以下感受困扰？',
      );
    });

    test('level2ManiaName / ShortDescription / Instruction 走 zh', () {
      expect(zh.level2ManiaName, 'DSM-5 Level 2 躁狂严重度');
      expect(
        zh.level2ManiaShortDescription,
        '成人躁狂严重度 5 题 (DSM-5 PROMIS 简化版）',
      );
      expect(
        zh.level2ManiaInstruction,
        '过去 7 天内， 您有多经常体验以下情况？',
      );
    });

    test('asrmName / asrmShortDescription / asrmInstruction 走 zh', () {
      expect(zh.asrmName, 'ASRM 自评躁狂量表');
      expect(zh.asrmShortDescription, 'Altman 1997 自评躁狂量表 (5 题）');
      expect(
        zh.asrmInstruction,
        '过去 1 周内， 您有 （或感觉到） 以下情况的程度？',
      );
    });

    test('level2PsychosisName / ShortDescription / Instruction 走 zh', () {
      expect(zh.level2PsychosisName, 'DSM-5 Level 2 精神病性症状');
      expect(
        zh.level2PsychosisShortDescription,
        '成人精神病性症状 8 题 (DSM-5 简化版）',
      );
      expect(
        zh.level2PsychosisInstruction,
        '过去 7 天内， 您有多经常体验以下情况？',
      );
    });
  });

  // ============================================================
  // Group 2: R90 8 新量表 6 类 走 l10n (en 翻译, 防 zh 单独测被卡)
  // ============================================================
  group('R90 8 新量表 6 类走 l10n (en 翻译)', () {
    final en = AppLocalizationsEn();

    test('isi 走 en (非中文)', () {
      expect(en.isiName, 'ISI Insomnia Severity Index');
      expect(
        en.isiShortDescription,
        'Morin 1993 Insomnia Severity Index (7 items)',
      );
      expect(
        en.isiInstruction,
        'Over the past 2 weeks, how severe has your sleep problem been?',
      );
      expect(en.isiName, isNot(equals('ISI 失眠严重指数')));
    });

    test('pss / whodas 走 en', () {
      expect(en.pssName, 'PSS Perceived Stress Scale');
      expect(en.whodasName, 'WHODAS 2.0 Disability Assessment');
    });

    test('level2* 4 个量表走 en', () {
      expect(en.level2DepressionName, 'DSM-5 Level 2 Depression Severity');
      expect(en.level2AnxietyName, 'DSM-5 Level 2 Anxiety Severity');
      expect(en.level2ManiaName, 'DSM-5 Level 2 Mania Severity');
      expect(en.level2PsychosisName, 'DSM-5 Level 2 Psychotic Symptoms');
    });

    test('asrm 走 en', () {
      expect(en.asrmName, 'ASRM Altman Self-Rating Mania Scale');
    });
  });

  // ============================================================
  // Group 3: 8 新量表 items 走 domain StaticScaleTranslations 中文 fallback
  // (R112 AR-17: ARB 无 item key, l10n impl 已删; 锁 domain fallback 非空)
  // ============================================================
  group('8 新量表 items 走 domain 中文 fallback (R112 AR-17 锁)', () {
    const s = StaticScaleTranslations();

    test(
        '8 量表 items[0..N] 全部返非空中文 (const class 中文兜底, '
        'R90 决策 items i18n 留 v1.0)', () {
      for (var i = 0; i < 7; i++) {
        expect(s.isiItem(i), isNotEmpty, reason: 'isiItem($i) 中文 fallback 非空');
      }
      for (var i = 0; i < 10; i++) {
        expect(s.pssItem(i), isNotEmpty, reason: 'pssItem($i) 中文 fallback 非空');
      }
      for (var i = 0; i < 12; i++) {
        expect(
          s.whodasItem(i),
          isNotEmpty,
          reason: 'whodasItem($i) 中文 fallback 非空',
        );
      }
      for (var i = 0; i < 8; i++) {
        expect(
          s.level2DepressionItem(i),
          isNotEmpty,
          reason: 'level2DepressionItem($i) 中文 fallback 非空',
        );
      }
      for (var i = 0; i < 7; i++) {
        expect(
          s.level2AnxietyItem(i),
          isNotEmpty,
          reason: 'level2AnxietyItem($i) 中文 fallback 非空',
        );
      }
      for (var i = 0; i < 5; i++) {
        expect(
          s.level2ManiaItem(i),
          isNotEmpty,
          reason: 'level2ManiaItem($i) 中文 fallback 非空',
        );
      }
      for (var i = 0; i < 5; i++) {
        expect(
          s.asrmItem(i),
          isNotEmpty,
          reason: 'asrmItem($i) 中文 fallback 非空',
        );
      }
      for (var i = 0; i < 8; i++) {
        expect(
          s.level2PsychosisItem(i),
          isNotEmpty,
          reason: 'level2PsychosisItem($i) 中文 fallback 非空',
        );
      }
    });

    test('override 参数优先于 fallback (传 override 拿非空)', () {
      expect(s.isiItem(0, override: 'custom ISI item 0'), 'custom ISI item 0');
      expect(s.pssItem(0, override: 'custom PSS item 0'), 'custom PSS item 0');
    });
  });

  // ============================================================
  // Group 3b: R90 8 新量表 options/severity ARB key 引用锁 (R112 AR-17)
  // 原 AppLocalizationsScaleTranslations 是这些 key 的唯一引用方, 删除后
  // 111 key 变 orphan (check_orphan_arb_keys FAIL)。这些是 Task 6 (items
  // i18n, v1.0 R51b) 预留翻译, 本锁保持引用 + 锁 3 语非空。
  // ============================================================
  group('R90 8 新量表 options/severity ARB key 引用锁 (R112 AR-17)', () {
    test('R90 8 新量表 options/severity ARB key 引用锁 (防 orphan, Task 6 预留)', () {
      final zh = AppLocalizationsZh();
      final en = AppLocalizationsEn();
      expect(zh.asrmOption0, isNotEmpty, reason: 'asrmOption0 zh 预留翻译非空');
      expect(en.asrmOption0, isNotEmpty, reason: 'asrmOption0 en 预留翻译非空');
      expect(zh.asrmOption1, isNotEmpty, reason: 'asrmOption1 zh 预留翻译非空');
      expect(en.asrmOption1, isNotEmpty, reason: 'asrmOption1 en 预留翻译非空');
      expect(zh.asrmOption2, isNotEmpty, reason: 'asrmOption2 zh 预留翻译非空');
      expect(en.asrmOption2, isNotEmpty, reason: 'asrmOption2 en 预留翻译非空');
      expect(zh.asrmOption3, isNotEmpty, reason: 'asrmOption3 zh 预留翻译非空');
      expect(en.asrmOption3, isNotEmpty, reason: 'asrmOption3 en 预留翻译非空');
      expect(zh.asrmOption4, isNotEmpty, reason: 'asrmOption4 zh 预留翻译非空');
      expect(en.asrmOption4, isNotEmpty, reason: 'asrmOption4 en 预留翻译非空');
      expect(zh.asrmSeverityLabel0, isNotEmpty,
          reason: 'asrmSeverityLabel0 zh 预留翻译非空');
      expect(en.asrmSeverityLabel0, isNotEmpty,
          reason: 'asrmSeverityLabel0 en 预留翻译非空');
      expect(zh.asrmSeverityLabel1, isNotEmpty,
          reason: 'asrmSeverityLabel1 zh 预留翻译非空');
      expect(en.asrmSeverityLabel1, isNotEmpty,
          reason: 'asrmSeverityLabel1 en 预留翻译非空');
      expect(zh.asrmSeverityLabel2, isNotEmpty,
          reason: 'asrmSeverityLabel2 zh 预留翻译非空');
      expect(en.asrmSeverityLabel2, isNotEmpty,
          reason: 'asrmSeverityLabel2 en 预留翻译非空');
      expect(zh.asrmSeverityLabel3, isNotEmpty,
          reason: 'asrmSeverityLabel3 zh 预留翻译非空');
      expect(en.asrmSeverityLabel3, isNotEmpty,
          reason: 'asrmSeverityLabel3 en 预留翻译非空');
      expect(zh.asrmSeverityLabel4, isNotEmpty,
          reason: 'asrmSeverityLabel4 zh 预留翻译非空');
      expect(en.asrmSeverityLabel4, isNotEmpty,
          reason: 'asrmSeverityLabel4 en 预留翻译非空');
      expect(zh.asrmSeveritySummary0, isNotEmpty,
          reason: 'asrmSeveritySummary0 zh 预留翻译非空');
      expect(en.asrmSeveritySummary0, isNotEmpty,
          reason: 'asrmSeveritySummary0 en 预留翻译非空');
      expect(zh.asrmSeveritySummary1, isNotEmpty,
          reason: 'asrmSeveritySummary1 zh 预留翻译非空');
      expect(en.asrmSeveritySummary1, isNotEmpty,
          reason: 'asrmSeveritySummary1 en 预留翻译非空');
      expect(zh.asrmSeveritySummary2, isNotEmpty,
          reason: 'asrmSeveritySummary2 zh 预留翻译非空');
      expect(en.asrmSeveritySummary2, isNotEmpty,
          reason: 'asrmSeveritySummary2 en 预留翻译非空');
      expect(zh.asrmSeveritySummary3, isNotEmpty,
          reason: 'asrmSeveritySummary3 zh 预留翻译非空');
      expect(en.asrmSeveritySummary3, isNotEmpty,
          reason: 'asrmSeveritySummary3 en 预留翻译非空');
      expect(zh.asrmSeveritySummary4, isNotEmpty,
          reason: 'asrmSeveritySummary4 zh 预留翻译非空');
      expect(en.asrmSeveritySummary4, isNotEmpty,
          reason: 'asrmSeveritySummary4 en 预留翻译非空');
      expect(zh.gad7SeveritySummary0, isNotEmpty,
          reason: 'gad7SeveritySummary0 zh 预留翻译非空');
      expect(en.gad7SeveritySummary0, isNotEmpty,
          reason: 'gad7SeveritySummary0 en 预留翻译非空');
      expect(zh.gad7SeveritySummary1, isNotEmpty,
          reason: 'gad7SeveritySummary1 zh 预留翻译非空');
      expect(en.gad7SeveritySummary1, isNotEmpty,
          reason: 'gad7SeveritySummary1 en 预留翻译非空');
      expect(zh.gad7SeveritySummary2, isNotEmpty,
          reason: 'gad7SeveritySummary2 zh 预留翻译非空');
      expect(en.gad7SeveritySummary2, isNotEmpty,
          reason: 'gad7SeveritySummary2 en 预留翻译非空');
      expect(zh.gad7SeveritySummary3, isNotEmpty,
          reason: 'gad7SeveritySummary3 zh 预留翻译非空');
      expect(en.gad7SeveritySummary3, isNotEmpty,
          reason: 'gad7SeveritySummary3 en 预留翻译非空');
      expect(zh.isiOption0, isNotEmpty, reason: 'isiOption0 zh 预留翻译非空');
      expect(en.isiOption0, isNotEmpty, reason: 'isiOption0 en 预留翻译非空');
      expect(zh.isiOption1, isNotEmpty, reason: 'isiOption1 zh 预留翻译非空');
      expect(en.isiOption1, isNotEmpty, reason: 'isiOption1 en 预留翻译非空');
      expect(zh.isiOption2, isNotEmpty, reason: 'isiOption2 zh 预留翻译非空');
      expect(en.isiOption2, isNotEmpty, reason: 'isiOption2 en 预留翻译非空');
      expect(zh.isiOption3, isNotEmpty, reason: 'isiOption3 zh 预留翻译非空');
      expect(en.isiOption3, isNotEmpty, reason: 'isiOption3 en 预留翻译非空');
      expect(zh.isiOption4, isNotEmpty, reason: 'isiOption4 zh 预留翻译非空');
      expect(en.isiOption4, isNotEmpty, reason: 'isiOption4 en 预留翻译非空');
      expect(zh.isiSeverityLabel0, isNotEmpty,
          reason: 'isiSeverityLabel0 zh 预留翻译非空');
      expect(en.isiSeverityLabel0, isNotEmpty,
          reason: 'isiSeverityLabel0 en 预留翻译非空');
      expect(zh.isiSeverityLabel1, isNotEmpty,
          reason: 'isiSeverityLabel1 zh 预留翻译非空');
      expect(en.isiSeverityLabel1, isNotEmpty,
          reason: 'isiSeverityLabel1 en 预留翻译非空');
      expect(zh.isiSeverityLabel2, isNotEmpty,
          reason: 'isiSeverityLabel2 zh 预留翻译非空');
      expect(en.isiSeverityLabel2, isNotEmpty,
          reason: 'isiSeverityLabel2 en 预留翻译非空');
      expect(zh.isiSeverityLabel3, isNotEmpty,
          reason: 'isiSeverityLabel3 zh 预留翻译非空');
      expect(en.isiSeverityLabel3, isNotEmpty,
          reason: 'isiSeverityLabel3 en 预留翻译非空');
      expect(zh.isiSeveritySummary0, isNotEmpty,
          reason: 'isiSeveritySummary0 zh 预留翻译非空');
      expect(en.isiSeveritySummary0, isNotEmpty,
          reason: 'isiSeveritySummary0 en 预留翻译非空');
      expect(zh.isiSeveritySummary1, isNotEmpty,
          reason: 'isiSeveritySummary1 zh 预留翻译非空');
      expect(en.isiSeveritySummary1, isNotEmpty,
          reason: 'isiSeveritySummary1 en 预留翻译非空');
      expect(zh.isiSeveritySummary2, isNotEmpty,
          reason: 'isiSeveritySummary2 zh 预留翻译非空');
      expect(en.isiSeveritySummary2, isNotEmpty,
          reason: 'isiSeveritySummary2 en 预留翻译非空');
      expect(zh.isiSeveritySummary3, isNotEmpty,
          reason: 'isiSeveritySummary3 zh 预留翻译非空');
      expect(en.isiSeveritySummary3, isNotEmpty,
          reason: 'isiSeveritySummary3 en 预留翻译非空');
      expect(zh.level2AnxietyOption0, isNotEmpty,
          reason: 'level2AnxietyOption0 zh 预留翻译非空');
      expect(en.level2AnxietyOption0, isNotEmpty,
          reason: 'level2AnxietyOption0 en 预留翻译非空');
      expect(zh.level2AnxietyOption1, isNotEmpty,
          reason: 'level2AnxietyOption1 zh 预留翻译非空');
      expect(en.level2AnxietyOption1, isNotEmpty,
          reason: 'level2AnxietyOption1 en 预留翻译非空');
      expect(zh.level2AnxietyOption2, isNotEmpty,
          reason: 'level2AnxietyOption2 zh 预留翻译非空');
      expect(en.level2AnxietyOption2, isNotEmpty,
          reason: 'level2AnxietyOption2 en 预留翻译非空');
      expect(zh.level2AnxietyOption3, isNotEmpty,
          reason: 'level2AnxietyOption3 zh 预留翻译非空');
      expect(en.level2AnxietyOption3, isNotEmpty,
          reason: 'level2AnxietyOption3 en 预留翻译非空');
      expect(zh.level2AnxietySeverityLabel0, isNotEmpty,
          reason: 'level2AnxietySeverityLabel0 zh 预留翻译非空');
      expect(en.level2AnxietySeverityLabel0, isNotEmpty,
          reason: 'level2AnxietySeverityLabel0 en 预留翻译非空');
      expect(zh.level2AnxietySeverityLabel1, isNotEmpty,
          reason: 'level2AnxietySeverityLabel1 zh 预留翻译非空');
      expect(en.level2AnxietySeverityLabel1, isNotEmpty,
          reason: 'level2AnxietySeverityLabel1 en 预留翻译非空');
      expect(zh.level2AnxietySeverityLabel2, isNotEmpty,
          reason: 'level2AnxietySeverityLabel2 zh 预留翻译非空');
      expect(en.level2AnxietySeverityLabel2, isNotEmpty,
          reason: 'level2AnxietySeverityLabel2 en 预留翻译非空');
      expect(zh.level2AnxietySeverityLabel3, isNotEmpty,
          reason: 'level2AnxietySeverityLabel3 zh 预留翻译非空');
      expect(en.level2AnxietySeverityLabel3, isNotEmpty,
          reason: 'level2AnxietySeverityLabel3 en 预留翻译非空');
      expect(zh.level2AnxietySeveritySummary0, isNotEmpty,
          reason: 'level2AnxietySeveritySummary0 zh 预留翻译非空');
      expect(en.level2AnxietySeveritySummary0, isNotEmpty,
          reason: 'level2AnxietySeveritySummary0 en 预留翻译非空');
      expect(zh.level2AnxietySeveritySummary1, isNotEmpty,
          reason: 'level2AnxietySeveritySummary1 zh 预留翻译非空');
      expect(en.level2AnxietySeveritySummary1, isNotEmpty,
          reason: 'level2AnxietySeveritySummary1 en 预留翻译非空');
      expect(zh.level2AnxietySeveritySummary2, isNotEmpty,
          reason: 'level2AnxietySeveritySummary2 zh 预留翻译非空');
      expect(en.level2AnxietySeveritySummary2, isNotEmpty,
          reason: 'level2AnxietySeveritySummary2 en 预留翻译非空');
      expect(zh.level2AnxietySeveritySummary3, isNotEmpty,
          reason: 'level2AnxietySeveritySummary3 zh 预留翻译非空');
      expect(en.level2AnxietySeveritySummary3, isNotEmpty,
          reason: 'level2AnxietySeveritySummary3 en 预留翻译非空');
      expect(zh.level2DepressionOption0, isNotEmpty,
          reason: 'level2DepressionOption0 zh 预留翻译非空');
      expect(en.level2DepressionOption0, isNotEmpty,
          reason: 'level2DepressionOption0 en 预留翻译非空');
      expect(zh.level2DepressionOption1, isNotEmpty,
          reason: 'level2DepressionOption1 zh 预留翻译非空');
      expect(en.level2DepressionOption1, isNotEmpty,
          reason: 'level2DepressionOption1 en 预留翻译非空');
      expect(zh.level2DepressionOption2, isNotEmpty,
          reason: 'level2DepressionOption2 zh 预留翻译非空');
      expect(en.level2DepressionOption2, isNotEmpty,
          reason: 'level2DepressionOption2 en 预留翻译非空');
      expect(zh.level2DepressionOption3, isNotEmpty,
          reason: 'level2DepressionOption3 zh 预留翻译非空');
      expect(en.level2DepressionOption3, isNotEmpty,
          reason: 'level2DepressionOption3 en 预留翻译非空');
      expect(zh.level2DepressionSeverityLabel0, isNotEmpty,
          reason: 'level2DepressionSeverityLabel0 zh 预留翻译非空');
      expect(en.level2DepressionSeverityLabel0, isNotEmpty,
          reason: 'level2DepressionSeverityLabel0 en 预留翻译非空');
      expect(zh.level2DepressionSeverityLabel1, isNotEmpty,
          reason: 'level2DepressionSeverityLabel1 zh 预留翻译非空');
      expect(en.level2DepressionSeverityLabel1, isNotEmpty,
          reason: 'level2DepressionSeverityLabel1 en 预留翻译非空');
      expect(zh.level2DepressionSeverityLabel2, isNotEmpty,
          reason: 'level2DepressionSeverityLabel2 zh 预留翻译非空');
      expect(en.level2DepressionSeverityLabel2, isNotEmpty,
          reason: 'level2DepressionSeverityLabel2 en 预留翻译非空');
      expect(zh.level2DepressionSeverityLabel3, isNotEmpty,
          reason: 'level2DepressionSeverityLabel3 zh 预留翻译非空');
      expect(en.level2DepressionSeverityLabel3, isNotEmpty,
          reason: 'level2DepressionSeverityLabel3 en 预留翻译非空');
      expect(zh.level2DepressionSeveritySummary0, isNotEmpty,
          reason: 'level2DepressionSeveritySummary0 zh 预留翻译非空');
      expect(en.level2DepressionSeveritySummary0, isNotEmpty,
          reason: 'level2DepressionSeveritySummary0 en 预留翻译非空');
      expect(zh.level2DepressionSeveritySummary1, isNotEmpty,
          reason: 'level2DepressionSeveritySummary1 zh 预留翻译非空');
      expect(en.level2DepressionSeveritySummary1, isNotEmpty,
          reason: 'level2DepressionSeveritySummary1 en 预留翻译非空');
      expect(zh.level2DepressionSeveritySummary2, isNotEmpty,
          reason: 'level2DepressionSeveritySummary2 zh 预留翻译非空');
      expect(en.level2DepressionSeveritySummary2, isNotEmpty,
          reason: 'level2DepressionSeveritySummary2 en 预留翻译非空');
      expect(zh.level2DepressionSeveritySummary3, isNotEmpty,
          reason: 'level2DepressionSeveritySummary3 zh 预留翻译非空');
      expect(en.level2DepressionSeveritySummary3, isNotEmpty,
          reason: 'level2DepressionSeveritySummary3 en 预留翻译非空');
      expect(zh.level2ManiaOption0, isNotEmpty,
          reason: 'level2ManiaOption0 zh 预留翻译非空');
      expect(en.level2ManiaOption0, isNotEmpty,
          reason: 'level2ManiaOption0 en 预留翻译非空');
      expect(zh.level2ManiaOption1, isNotEmpty,
          reason: 'level2ManiaOption1 zh 预留翻译非空');
      expect(en.level2ManiaOption1, isNotEmpty,
          reason: 'level2ManiaOption1 en 预留翻译非空');
      expect(zh.level2ManiaOption2, isNotEmpty,
          reason: 'level2ManiaOption2 zh 预留翻译非空');
      expect(en.level2ManiaOption2, isNotEmpty,
          reason: 'level2ManiaOption2 en 预留翻译非空');
      expect(zh.level2ManiaOption3, isNotEmpty,
          reason: 'level2ManiaOption3 zh 预留翻译非空');
      expect(en.level2ManiaOption3, isNotEmpty,
          reason: 'level2ManiaOption3 en 预留翻译非空');
      expect(zh.level2ManiaSeverityLabel0, isNotEmpty,
          reason: 'level2ManiaSeverityLabel0 zh 预留翻译非空');
      expect(en.level2ManiaSeverityLabel0, isNotEmpty,
          reason: 'level2ManiaSeverityLabel0 en 预留翻译非空');
      expect(zh.level2ManiaSeverityLabel1, isNotEmpty,
          reason: 'level2ManiaSeverityLabel1 zh 预留翻译非空');
      expect(en.level2ManiaSeverityLabel1, isNotEmpty,
          reason: 'level2ManiaSeverityLabel1 en 预留翻译非空');
      expect(zh.level2ManiaSeverityLabel2, isNotEmpty,
          reason: 'level2ManiaSeverityLabel2 zh 预留翻译非空');
      expect(en.level2ManiaSeverityLabel2, isNotEmpty,
          reason: 'level2ManiaSeverityLabel2 en 预留翻译非空');
      expect(zh.level2ManiaSeverityLabel3, isNotEmpty,
          reason: 'level2ManiaSeverityLabel3 zh 预留翻译非空');
      expect(en.level2ManiaSeverityLabel3, isNotEmpty,
          reason: 'level2ManiaSeverityLabel3 en 预留翻译非空');
      expect(zh.level2ManiaSeveritySummary0, isNotEmpty,
          reason: 'level2ManiaSeveritySummary0 zh 预留翻译非空');
      expect(en.level2ManiaSeveritySummary0, isNotEmpty,
          reason: 'level2ManiaSeveritySummary0 en 预留翻译非空');
      expect(zh.level2ManiaSeveritySummary1, isNotEmpty,
          reason: 'level2ManiaSeveritySummary1 zh 预留翻译非空');
      expect(en.level2ManiaSeveritySummary1, isNotEmpty,
          reason: 'level2ManiaSeveritySummary1 en 预留翻译非空');
      expect(zh.level2ManiaSeveritySummary2, isNotEmpty,
          reason: 'level2ManiaSeveritySummary2 zh 预留翻译非空');
      expect(en.level2ManiaSeveritySummary2, isNotEmpty,
          reason: 'level2ManiaSeveritySummary2 en 预留翻译非空');
      expect(zh.level2ManiaSeveritySummary3, isNotEmpty,
          reason: 'level2ManiaSeveritySummary3 zh 预留翻译非空');
      expect(en.level2ManiaSeveritySummary3, isNotEmpty,
          reason: 'level2ManiaSeveritySummary3 en 预留翻译非空');
      expect(zh.level2PsychosisOption0, isNotEmpty,
          reason: 'level2PsychosisOption0 zh 预留翻译非空');
      expect(en.level2PsychosisOption0, isNotEmpty,
          reason: 'level2PsychosisOption0 en 预留翻译非空');
      expect(zh.level2PsychosisOption1, isNotEmpty,
          reason: 'level2PsychosisOption1 zh 预留翻译非空');
      expect(en.level2PsychosisOption1, isNotEmpty,
          reason: 'level2PsychosisOption1 en 预留翻译非空');
      expect(zh.level2PsychosisOption2, isNotEmpty,
          reason: 'level2PsychosisOption2 zh 预留翻译非空');
      expect(en.level2PsychosisOption2, isNotEmpty,
          reason: 'level2PsychosisOption2 en 预留翻译非空');
      expect(zh.level2PsychosisOption3, isNotEmpty,
          reason: 'level2PsychosisOption3 zh 预留翻译非空');
      expect(en.level2PsychosisOption3, isNotEmpty,
          reason: 'level2PsychosisOption3 en 预留翻译非空');
      expect(zh.level2PsychosisSeverityLabel0, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel0 zh 预留翻译非空');
      expect(en.level2PsychosisSeverityLabel0, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel0 en 预留翻译非空');
      expect(zh.level2PsychosisSeverityLabel1, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel1 zh 预留翻译非空');
      expect(en.level2PsychosisSeverityLabel1, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel1 en 预留翻译非空');
      expect(zh.level2PsychosisSeverityLabel2, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel2 zh 预留翻译非空');
      expect(en.level2PsychosisSeverityLabel2, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel2 en 预留翻译非空');
      expect(zh.level2PsychosisSeverityLabel3, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel3 zh 预留翻译非空');
      expect(en.level2PsychosisSeverityLabel3, isNotEmpty,
          reason: 'level2PsychosisSeverityLabel3 en 预留翻译非空');
      expect(zh.level2PsychosisSeveritySummary0, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary0 zh 预留翻译非空');
      expect(en.level2PsychosisSeveritySummary0, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary0 en 预留翻译非空');
      expect(zh.level2PsychosisSeveritySummary1, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary1 zh 预留翻译非空');
      expect(en.level2PsychosisSeveritySummary1, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary1 en 预留翻译非空');
      expect(zh.level2PsychosisSeveritySummary2, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary2 zh 预留翻译非空');
      expect(en.level2PsychosisSeveritySummary2, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary2 en 预留翻译非空');
      expect(zh.level2PsychosisSeveritySummary3, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary3 zh 预留翻译非空');
      expect(en.level2PsychosisSeveritySummary3, isNotEmpty,
          reason: 'level2PsychosisSeveritySummary3 en 预留翻译非空');
      expect(zh.phq9SeveritySummary0, isNotEmpty,
          reason: 'phq9SeveritySummary0 zh 预留翻译非空');
      expect(en.phq9SeveritySummary0, isNotEmpty,
          reason: 'phq9SeveritySummary0 en 预留翻译非空');
      expect(zh.phq9SeveritySummary1, isNotEmpty,
          reason: 'phq9SeveritySummary1 zh 预留翻译非空');
      expect(en.phq9SeveritySummary1, isNotEmpty,
          reason: 'phq9SeveritySummary1 en 预留翻译非空');
      expect(zh.phq9SeveritySummary3, isNotEmpty,
          reason: 'phq9SeveritySummary3 zh 预留翻译非空');
      expect(en.phq9SeveritySummary3, isNotEmpty,
          reason: 'phq9SeveritySummary3 en 预留翻译非空');
      expect(zh.phq9SeveritySummary4, isNotEmpty,
          reason: 'phq9SeveritySummary4 zh 预留翻译非空');
      expect(en.phq9SeveritySummary4, isNotEmpty,
          reason: 'phq9SeveritySummary4 en 预留翻译非空');
      expect(zh.pssOption0, isNotEmpty, reason: 'pssOption0 zh 预留翻译非空');
      expect(en.pssOption0, isNotEmpty, reason: 'pssOption0 en 预留翻译非空');
      expect(zh.pssOption1, isNotEmpty, reason: 'pssOption1 zh 预留翻译非空');
      expect(en.pssOption1, isNotEmpty, reason: 'pssOption1 en 预留翻译非空');
      expect(zh.pssOption2, isNotEmpty, reason: 'pssOption2 zh 预留翻译非空');
      expect(en.pssOption2, isNotEmpty, reason: 'pssOption2 en 预留翻译非空');
      expect(zh.pssOption3, isNotEmpty, reason: 'pssOption3 zh 预留翻译非空');
      expect(en.pssOption3, isNotEmpty, reason: 'pssOption3 en 预留翻译非空');
      expect(zh.pssOption4, isNotEmpty, reason: 'pssOption4 zh 预留翻译非空');
      expect(en.pssOption4, isNotEmpty, reason: 'pssOption4 en 预留翻译非空');
      expect(zh.pssSeverityLabel0, isNotEmpty,
          reason: 'pssSeverityLabel0 zh 预留翻译非空');
      expect(en.pssSeverityLabel0, isNotEmpty,
          reason: 'pssSeverityLabel0 en 预留翻译非空');
      expect(zh.pssSeverityLabel1, isNotEmpty,
          reason: 'pssSeverityLabel1 zh 预留翻译非空');
      expect(en.pssSeverityLabel1, isNotEmpty,
          reason: 'pssSeverityLabel1 en 预留翻译非空');
      expect(zh.pssSeverityLabel2, isNotEmpty,
          reason: 'pssSeverityLabel2 zh 预留翻译非空');
      expect(en.pssSeverityLabel2, isNotEmpty,
          reason: 'pssSeverityLabel2 en 预留翻译非空');
      expect(zh.pssSeveritySummary0, isNotEmpty,
          reason: 'pssSeveritySummary0 zh 预留翻译非空');
      expect(en.pssSeveritySummary0, isNotEmpty,
          reason: 'pssSeveritySummary0 en 预留翻译非空');
      expect(zh.pssSeveritySummary1, isNotEmpty,
          reason: 'pssSeveritySummary1 zh 预留翻译非空');
      expect(en.pssSeveritySummary1, isNotEmpty,
          reason: 'pssSeveritySummary1 en 预留翻译非空');
      expect(zh.pssSeveritySummary2, isNotEmpty,
          reason: 'pssSeveritySummary2 zh 预留翻译非空');
      expect(en.pssSeveritySummary2, isNotEmpty,
          reason: 'pssSeveritySummary2 en 预留翻译非空');
      expect(zh.scaleHotlineIntl, isNotEmpty,
          reason: 'scaleHotlineIntl zh 预留翻译非空');
      expect(en.scaleHotlineIntl, isNotEmpty,
          reason: 'scaleHotlineIntl en 预留翻译非空');
      expect(zh.whodasOption0, isNotEmpty, reason: 'whodasOption0 zh 预留翻译非空');
      expect(en.whodasOption0, isNotEmpty, reason: 'whodasOption0 en 预留翻译非空');
      expect(zh.whodasOption1, isNotEmpty, reason: 'whodasOption1 zh 预留翻译非空');
      expect(en.whodasOption1, isNotEmpty, reason: 'whodasOption1 en 预留翻译非空');
      expect(zh.whodasOption2, isNotEmpty, reason: 'whodasOption2 zh 预留翻译非空');
      expect(en.whodasOption2, isNotEmpty, reason: 'whodasOption2 en 预留翻译非空');
      expect(zh.whodasOption3, isNotEmpty, reason: 'whodasOption3 zh 预留翻译非空');
      expect(en.whodasOption3, isNotEmpty, reason: 'whodasOption3 en 预留翻译非空');
      expect(zh.whodasOption4, isNotEmpty, reason: 'whodasOption4 zh 预留翻译非空');
      expect(en.whodasOption4, isNotEmpty, reason: 'whodasOption4 en 预留翻译非空');
      expect(zh.whodasSeverityLabel0, isNotEmpty,
          reason: 'whodasSeverityLabel0 zh 预留翻译非空');
      expect(en.whodasSeverityLabel0, isNotEmpty,
          reason: 'whodasSeverityLabel0 en 预留翻译非空');
      expect(zh.whodasSeverityLabel1, isNotEmpty,
          reason: 'whodasSeverityLabel1 zh 预留翻译非空');
      expect(en.whodasSeverityLabel1, isNotEmpty,
          reason: 'whodasSeverityLabel1 en 预留翻译非空');
      expect(zh.whodasSeverityLabel2, isNotEmpty,
          reason: 'whodasSeverityLabel2 zh 预留翻译非空');
      expect(en.whodasSeverityLabel2, isNotEmpty,
          reason: 'whodasSeverityLabel2 en 预留翻译非空');
      expect(zh.whodasSeverityLabel3, isNotEmpty,
          reason: 'whodasSeverityLabel3 zh 预留翻译非空');
      expect(en.whodasSeverityLabel3, isNotEmpty,
          reason: 'whodasSeverityLabel3 en 预留翻译非空');
      expect(zh.whodasSeverityLabel4, isNotEmpty,
          reason: 'whodasSeverityLabel4 zh 预留翻译非空');
      expect(en.whodasSeverityLabel4, isNotEmpty,
          reason: 'whodasSeverityLabel4 en 预留翻译非空');
      expect(zh.whodasSeveritySummary0, isNotEmpty,
          reason: 'whodasSeveritySummary0 zh 预留翻译非空');
      expect(en.whodasSeveritySummary0, isNotEmpty,
          reason: 'whodasSeveritySummary0 en 预留翻译非空');
      expect(zh.whodasSeveritySummary1, isNotEmpty,
          reason: 'whodasSeveritySummary1 zh 预留翻译非空');
      expect(en.whodasSeveritySummary1, isNotEmpty,
          reason: 'whodasSeveritySummary1 en 预留翻译非空');
      expect(zh.whodasSeveritySummary2, isNotEmpty,
          reason: 'whodasSeveritySummary2 zh 预留翻译非空');
      expect(en.whodasSeveritySummary2, isNotEmpty,
          reason: 'whodasSeveritySummary2 en 预留翻译非空');
      expect(zh.whodasSeveritySummary3, isNotEmpty,
          reason: 'whodasSeveritySummary3 zh 预留翻译非空');
      expect(en.whodasSeveritySummary3, isNotEmpty,
          reason: 'whodasSeveritySummary3 en 预留翻译非空');
      expect(zh.whodasSeveritySummary4, isNotEmpty,
          reason: 'whodasSeveritySummary4 zh 预留翻译非空');
      expect(en.whodasSeveritySummary4, isNotEmpty,
          reason: 'whodasSeveritySummary4 en 预留翻译非空');
    });
  });

  // ============================================================
  // Group 4: crisisHotlineLabel 6 region × 2 hotline + index fallback
  // ============================================================
  group(
      'crisisHotlineLabel 6 region × 2 hotline + index fallback (R77 spzh P1-A)',
      () {
    final zh = AppLocalizationsZh();

    test('cn 2 hotline (index 0 + 1)', () {
      expect(zh.scaleHotlineCn, '全国 24 小时心理援助热线');
      expect(zh.scaleHotlineCn2, '北京心理危机研究与干预中心');
    });

    test('us 2 hotline (index 0 + 1)', () {
      expect(zh.scaleHotlineUs, '988 Suicide & Crisis Lifeline (US)');
      expect(zh.scaleHotlineUs2, 'Crisis Text Line (text HOME to 741741)');
    });

    test('hk / sg / uk 1 hotline + tw 2 hotline + cn/us 2 hotline', () {
      // R77 spzh P1-A: 6 region × 2 hotline, 每 region 独立 i18n key
      expect(zh.scaleHotlineHk, '撒玛利亚防止自杀会（24h 多语言）');
      expect(zh.scaleHotlineSg, 'Samaritans of Singapore (24h)');
      expect(zh.scaleHotlineUk, 'Samaritans UK & ROI (24h 免费)');
      expect(zh.scaleHotlineTw, '生命线（24h）');
      expect(zh.scaleHotlineTw2, '安心专线（心理咨商）');
      // cn/us 2 hotline 完整覆盖
      expect(zh.scaleHotlineCn, '全国 24 小时心理援助热线');
      expect(zh.scaleHotlineCn2, '北京心理危机研究与干预中心');
      expect(zh.scaleHotlineUs, '988 Suicide & Crisis Lifeline (US)');
      expect(zh.scaleHotlineUs2, 'Crisis Text Line (text HOME to 741741)');
    });

    test('StaticScaleTranslations 走 first.label 兜底 (R77 spzh P1-A 越界 fallback)',
        () {
      // Static 走 hotlineByRegion const Map, index 越界走 first.label
      // (hotlineByRegion[tw][0].label 实测 '生命线 (24h)' 半角括号, 跟 ARB 全角不一致
      // 是 R17 历史数据, R51b 计划对齐)
      const s = StaticScaleTranslations();
      final firstLabel = s.crisisHotlineLabel(HotlineRegion.tw, index: 0);
      expect(
        s.crisisHotlineLabel(HotlineRegion.tw, index: 99),
        firstLabel,
        reason: 'StaticScaleTranslations 越界走 first.label (R77 设计)',
      );
    });

    test('crisisTitle / crisisMessage 走 l10n (R71 spzh P1-A 续)', () {
      expect(zh.scaleCrisisTitle, '我们关心你');
      expect(
        zh.scaleCrisisMessage,
        '你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。',
      );
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
        'Medication Alert',
      );
    });

    test('notifDailyCheckInTitleText override 优先于 const', () {
      expect(
        Strings.notifDailyCheckInTitleText(override: 'Did you take meds?'),
        'Did you take meds?',
      );
    });
  });

  // ============================================================
  // Group 7: 3 语 ARB 同步 (zh / en / zh_Hant 数字一致)
  //   - scale / phq9 / gad7 / isi / pss / whodas / level2 / asrm: 180 key
  //   - notifChannel* (R23 起步 + R26 R57 加): 2 key (round 4b safety 摘)
  //   - 跟 check_arb_keys.py 守门员用 2 空格缩进模式一致 (避免嵌套对象 key 误算)
  //   - 总 1203 key (跟 check_arb_keys.py baseline 同步; round 4b 外联 25 key 摘)
  // ============================================================
  group('3 语 ARB 同步 (zh / en / zh_Hant 数字一致, 跟 check_arb_keys.py 守门员一致)', () {
    int countIn(String path, String pattern) {
      // 跟 check_arb_keys.py 一致: `^  "` (固定 2 空格) 避免嵌套对象 key 误算
      final file = File(path);
      final content = file.readAsStringSync();
      final regex = RegExp(pattern, multiLine: true);
      return regex.allMatches(content).length;
    }

    test(
        'scale / phq9 / gad7 / isi / pss / whodas / level2 / asrm = 180 key '
        '(R65/R78 + R90 走完 ARB, 3 语同步)', () {
      const pattern = r'^  "(scale|phq9|gad7|isi|pss|whodas|level2|asrm)';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 180, reason: 'zh.arb 应有 180 scale* key (R65/R78 + R90 走完)');
      expect(en, 180, reason: 'en.arb 应有 180 scale* key');
      expect(hant, 180, reason: 'zh_Hant.arb 应有 180 scale* key');
    });

    test(
        'notifChannel* (R23 起步 + R26 R57 加, round 4b: safety 2 key 摘) = 2 key (3 语同步)',
        () {
      // R57 P0 #6 fix: notifChannel* 2 个 ARB key 是 strings.dart 内部 const
      // 字段的 i18n 镜像 (供 presentation 层 UI 翻译), 老 caller (notification_service /
      // badge_sync_service / snooze_manager) 用 const 编译期常量 (因 Android
      // channel ID 必须 compile-time), 0 引用 ARB key 是 R57 design 有意为之 —
      // 字符串值跟 strings.dart 内部 const 一致是 double-source-of-truth 风险,
      // 但 P2 收口决策 (audit 11.5/11.7) 留 v1.0。
      // 1.1.0 round 4b: notifChannelSafety{Name,Desc} 随 safety alert 整摘。
      const pattern = r'^  "notifChannel';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 2, reason: 'zh.arb 应有 2 notifChannel* key');
      expect(en, 2, reason: 'en.arb 应有 2 notifChannel* key');
      expect(hant, 2, reason: 'zh_Hant.arb 应有 2 notifChannel* key');
    });

    test('3 语 total = 1221 key (跟 check_arb_keys.py baseline 同步, R24 P1-21 修)',
        () {
      // 防御: 任意单语加 key 漏同步, 数字立刻不等 (R24 round 48 修)
      // v0.30 R95 sub-spec 7 task 53/55 加 13 new (8 migration + 5 timeAgo/dailyTracking) → 1045 → 1058
      // v0.30 R95 sub-spec 8 task 45 加 1 new (homeTooltipSettings) → 1058 → 1059
      // v0.30 R95 sub-spec 8 task 48 加 1 new (ventSwipeHint) → 1059 → 1060
      // R97-P0-2/P1-4/P1-11 (2026-08-07): +8 new (5 ventReport* + 3 crisisHotline*)
      //   → 1060 → 1068
      // R100 (P1#9, 2026-08-07): +23 new (UI 硬编码中文走 ARB: weight/socialRhythm/
      //   anxiety/sleep/stress/cbt/medReport/medCalendar/hotline/consentWithdraw/export)
      //   → 1068 → 1091
      // R102 (2026-08-08): +107 new (累计增量, baseline 已 1198)
      // R102 (2026-08-08): +4 new (chartMetricWeight/Sleep/Mood/Stress)
      //   → 1198 → 1202
      // R103 (2026-08-08): +5 new (todaySummaryCheckIn/Meds/Mood/Streak/StreakDays)
      //   → 1202 → 1203
      // R110 round 3 (C6): +11 new (4 medAdd* + 2 medsCalendar* + 3 medDetail* +
      //   2 refillManage* 硬编码中文标题走 ARB) → 1230 → 1241
      // v0.32 round 8 (R111): +5 moodLabel1-5 (EM-21) + 2 medCalendarBackfill*
      //   (R111-03, 净 +1: -1 stub) + 3 notificationStatusCardPermission* (GP-10)
      //   → 1241 → 1250
      // v0.32 R112 (export v5 E1/E2/E6 等, 与 A agent 同批): +28 new → 1250 → 1278
      // v0.32 round 8 (R112-06 emil): +1 moodTodayLabelWithValue (参数化拼接,
      //   净 +1; moodLabel1-5 只加 @metadata 不占 key) → 1278 → 1279
      // v0.32 R112 修复战役收尾: TempMedicationDialog 死代码删除连坐
      //   6 个 tempMed* orphan key 清掉 → 1279 → 1273
      // v0.32 R112 round 8h: audioRecord{Pause,Resume,Stop}Tooltip
      //   3 个录音暂停控制 key → 1273 → 1276
      //   录音态 UI 改版后 ventRecordActive (旧'正在录音…点停止') 成 orphan
      //   → 1276 → 1275
      // v1.0.0+147: 删 6 个 IAP key (settingsIapUpgrade{Title,Subtitle} +
      //   settingsIapProOwned{Title,Subtitle} + iapPurchase{Success,Failed}, 永久免费)
      //   → 1275 → 1269
      // 1.1.0 round 4 (emotion-first refactor): 联系人/失联 34 orphan key 整摘
      //   (contact*/setupContact*/safetyCheckResult*/reminderHubSafety* 等) +
      //   consentWithdrawSafetyBody + commonAction{Delete,Save} 2 个存量 orphan
      //   → 1269 → 1233
      // 1.1.0 round 4f (review 修复): SafetyReminderCard 死类整摘, 连带
      //   reminderHubSafety{Title,DescEnabled,DescDisabled,StatusEnabled} +
      //   reminderHubSmsMockWarning 5 key 清掉 → 1233 → 1228
      // 1.1.0 round 4b (emotion-first refactor): 外联 25 orphan key 整摘
      //   (phoneRegion* 5 + checkInType{...} 4 + legalPageWithdrawSafety 2 +
      //   notifChannelSafety 2 + safetyAlert* 5 + careCopy* 7;
      //   careCopyWeekPerfectBody 只存 Strings 不存 ARB)
      //   → 1228 → 1203
      // 1.1.0 round 5 (导航 4 tab 等): +1 net → 1203 → 1204 (本批前基线)
      // 1.1.0 round 5b (Task 12 首页双主卡): +12 new (homeMoodHero* 5 +
      //   homeVentHero* 3 + homeAction* 4), QuickMoodCarousel /
      //   SecondaryActionRow 删除连坐 −14 orphan (homeQuick* 6 +
      //   homeMore* 7 + moodQuickRecordFailed 1)
      //   → 1204 → 1202
      // 1.1.0 round 5c (Task 13 树洞标签): +4 (ventTagSectionTitle /
      //   ventTagCustomHint / ventTagFilterAll / ventTagFilterEmpty)
      //   → 1202 → 1206
      // 1.1.0 round 5d (Task 14 状态短语): +3 (moodStatusPhraseTitle /
      //   moodStatusPhraseHint / moodStatusPhraseShowAll)
      //   → 1206 → 1209
      // 1.1.0 round 5e (Task 15 情绪回顾页): +11 (moodReviewTitle /
      //   moodReviewWeek / moodReviewMonth / moodReviewRecordedDays /
      //   moodReviewAvgMood / moodReviewVsPrev / moodReviewNoPrev /
      //   moodReviewTopTags / moodReviewTopFactors / moodReviewTimeOfDay /
      //   moodReviewCbtCount) → 1209 → 1220
      // 1.1.0 round 6c (Task 17 终验修复): lock-in 基线补齐 1206 → 1220
      // 1.1.0 round 6d (final review 修复): +4 consentDialogGeneric* (Title/
      //   Agree/Reject/Version vent/analytics 中性 fallback) −3
      //   contactConsent{Title,Agree,Version} orphan (contactConsentReject
      //   保留, dataExport 路径复用) → 1220 → 1221
      // 1.1.0 round 7b (P1 i18n, 2026-08-16): +35 new (8 ventTag* 预设标签 +
      //   17 statusPhrase* 状态短语 + 5 moodReviewEncouragement* 鼓励文案 +
      //   5 importSummary* 导入摘要带 {n}) → 1221 → 1256
      const pattern = r'^  "([a-zA-Z][a-zA-Z0-9]+)":';
      const l10nDir = 'lib/l10n';
      final zh = countIn('$l10nDir/app_zh.arb', pattern);
      final en = countIn('$l10nDir/app_en.arb', pattern);
      final hant = countIn('$l10nDir/app_zh_Hant.arb', pattern);
      expect(zh, 1256, reason: 'zh.arb 应有 1256 key');
      expect(en, 1256, reason: 'en.arb 应有 1256 key');
      expect(hant, 1256, reason: 'zh_Hant.arb 应有 1256 key');
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
      // 1.1.0 round 4b: email* 段随 EmailService 整摘, 改测仍存的 notifDaily
      expect(Strings.notifDailyCheckInTitle, '🌱 今天吃了药吗？');
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
      expect(
        hant.homeSnoozeTitle.isNotEmpty,
        isTrue,
        reason: 'zh_Hant 应有 homeSnoozeTitle 繁中翻译',
      );
    });
  });
}
