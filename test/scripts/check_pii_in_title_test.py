"""v1.1.0 R113 (P2-21): check_pii_in_title.py 自测

此前守门员只覆盖 2/5 通知 title (round 7c 已扩 title 5/5), 本测试钉住:
1. title + body 全量检测 (5 title + 5 body = 10 个定义)
2. title/body 形参或字面量含 PII -> exit 1
3. deprecated legacy body (dosage 参数) 豁免 (regex 不匹配 Legacy 后缀)
4. call site 传含 name 实参 -> exit 1
5. *Text 变体函数不被重复检测 (只测 const 源 + 直接函数)
"""
import sys
from pathlib import Path

# 把 scripts 加到 path 才能 import
SCRIPTS = Path(__file__).resolve().parent.parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS))

import check_pii_in_title as pii  # noqa: E402

CLEAN_STRINGS = """\
class Strings {
  Strings._();
  static const notifDailyCheckInTitle = '今天吃药了吗';
  static const notifDailyCheckInBody = '点一下 = 打卡';
  static String notifDailyCheckInTitleText({String? override}) =>
      override ?? notifDailyCheckInTitle;
  static String notifDailyCheckInBodyText({String? override}) =>
      override ?? notifDailyCheckInBody;
  static String notifMedicationTitle({String? override}) => override ?? '该吃药了';
  static String notifMedicationBody({String? override}) => override ?? '该吃药了 点一下打卡';
  @Deprecated('legacy')
  static String notifMedicationBodyLegacy(
    double dosage,
    DosageUnit unit, {
    String? override,
  }) =>
      override ?? '该吃药了 点一下打卡';
  static String notifRefillTitle({String? override}) => override ?? '该续方了';
  static String notifRefillBody(int daysLeft, {String? override}) =>
      override ?? '还剩 \$daysLeft 天断药';
  static String notifAssessmentTitle({String? override}) => override ?? '心理评估时间到';
  static String notifAssessmentBody(int days, {String? override}) =>
      override ?? '已经 \$days 天没做心理评估了';
  static const notifMoodReminderTitle = '今天心情怎么样';
  static const notifMoodReminderBody = '花 1 分钟记录一下';
  static String notifMoodReminderTitleText({String? override}) =>
      override ?? notifMoodReminderTitle;
  static String notifMoodReminderBodyText({String? override}) =>
      override ?? notifMoodReminderBody;
}
"""

ALL_TEN = {
    "notifDailyCheckInTitle",
    "notifDailyCheckInBody",
    "notifMedicationTitle",
    "notifMedicationBody",
    "notifRefillTitle",
    "notifRefillBody",
    "notifAssessmentTitle",
    "notifAssessmentBody",
    "notifMoodReminderTitle",
    "notifMoodReminderBody",
}


def _write_strings(tmp_path, content):
    strings_dir = tmp_path / "lib" / "core" / "l10n"
    strings_dir.mkdir(parents=True)
    strings_file = strings_dir / "strings.dart"
    strings_file.write_text(content, encoding="utf-8")
    return strings_file


class TestCoverage:
    def test_clean_detects_all_five_titles_and_bodies(self, tmp_path, monkeypatch):
        """clean 声明 -> exit 0, 检测集含 5 title + 5 body"""
        _write_strings(tmp_path, CLEAN_STRINGS)
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 0
        assert ALL_TEN.issubset(pii.detected_titles)

    def test_text_variants_and_legacy_not_double_detected(self, tmp_path, monkeypatch):
        """*Text 变体 + Legacy 后缀不入检测集 (只测源头声明)"""
        _write_strings(tmp_path, CLEAN_STRINGS)
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 0
        for name in pii.detected_titles:
            assert not name.endswith("Text")
            assert "Legacy" not in name

    def test_body_literal_with_pii_fails(self, tmp_path, monkeypatch):
        """body 字面量拼 $medName -> exit 1 (锁屏 PII 回归)"""
        content = CLEAN_STRINGS.replace(
            "static String notifMedicationBody({String? override}) => override ?? '该吃药了 点一下打卡';",
            "static String notifMedicationBody({String? override}) => override ?? '该吃药了：$medName';",
        )
        _write_strings(tmp_path, content)
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 1

    def test_title_param_with_pii_fails(self, tmp_path, monkeypatch):
        """title 函数形参收 medName -> exit 1"""
        content = CLEAN_STRINGS.replace(
            "static String notifRefillTitle({String? override}) => override ?? '该续方了';",
            "static String notifRefillTitle(String medName, {String? override}) => override ?? '该续方了';",
        )
        _write_strings(tmp_path, content)
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 1


class TestCallSites:
    def test_call_site_passing_name_fails(self, tmp_path, monkeypatch):
        """lib/ 调 notif*Title(name) 传含 name 实参 -> exit 1 (defence in depth)"""
        _write_strings(tmp_path, CLEAN_STRINGS)
        caller = tmp_path / "lib" / "med_notifier.dart"
        caller.write_text(
            "title: Strings.notifMedicationTitle(medName),\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 1

    def test_call_site_clean_returns_zero(self, tmp_path, monkeypatch):
        """干净 caller (不传 name 实参) -> exit 0"""
        _write_strings(tmp_path, CLEAN_STRINGS)
        caller = tmp_path / "lib" / "med_notifier.dart"
        caller.write_text(
            "title: Strings.notifMedicationTitle(override: t),\n"
            "body: Strings.notifRefillBody(daysLeft, override: t),\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(pii, "PROJECT_ROOT", tmp_path)
        assert pii.main() == 0
