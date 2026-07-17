"""v0.17 round 14 (P1-4): check_cross_feature.py 单元测试

覆盖:
1. get_feature: 提取 feature 名 (file / subdir 两种)
2. is_cross_feature_import: hub / non-hub / 同 feature / 跨 feature / 非 pages
3. check_file: 单文件 violations
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

# 把 scripts 加到 path 才能 import
SCRIPTS = Path(__file__).resolve().parent.parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS))

import check_cross_feature as ccf  # noqa: E402


class TestGetFeature:
    def test_file(self):
        # PAGES 在 Windows 上是绝对路径,用 os.path.join 构造
        p = os.path.join(ccf.PAGES, "mood", "foo.dart")
        assert ccf.get_feature(p) == "mood"

    def test_widgets_subdir(self):
        p = os.path.join(ccf.PAGES, "assessment", "widgets", "x.dart")
        assert ccf.get_feature(p) == "assessment"

    def test_hub_home(self):
        p = os.path.join(ccf.PAGES, "home", "home_page.dart")
        assert ccf.get_feature(p) == "home"


class TestIsCrossFeatureImport:
    def test_same_feature_not_violation(self):
        # mood 内的文件 import mood 内的其他文件
        assert ccf.is_cross_feature_import("mood", "package:chroniccare/presentation/pages/mood/foo.dart") is False

    def test_hub_can_import_other(self):
        # home (hub) import vent
        assert ccf.is_cross_feature_import("home", "package:chroniccare/presentation/pages/vent/foo.dart") is False

    def test_settings_hub_can_import(self):
        assert ccf.is_cross_feature_import("settings", "package:chroniccare/presentation/pages/assessment/foo.dart") is False

    def test_non_hub_cross_feature_violation(self):
        # mood import vent — 跨 feature 违规
        assert ccf.is_cross_feature_import("mood", "package:chroniccare/presentation/pages/vent/foo.dart") is True

    def test_allowed_dir_not_violation(self):
        # mood import core
        assert ccf.is_cross_feature_import("mood", "package:chroniccare/core/theme/app_tokens.dart") is False
        # mood import providers
        assert ccf.is_cross_feature_import("mood", "package:chroniccare/presentation/providers/core_providers.dart") is False
        # mood import widgets
        assert ccf.is_cross_feature_import("mood", "package:chroniccare/presentation/widgets/secondary_button.dart") is False

    def test_dart_import_not_violation(self):
        assert ccf.is_cross_feature_import("mood", "dart:io") is False
        assert ccf.is_cross_feature_import("mood", "package:flutter/material.dart") is False

    def test_third_party_package_not_violation(self):
        assert ccf.is_cross_feature_import("mood", "package:flutter_riverpod/flutter_riverpod.dart") is False


class TestCheckFile:
    def test_clean_file(self, tmp_path):
        # 构造一个干净的文件: 同 feature import
        pages = tmp_path / "lib" / "presentation" / "pages" / "mood"
        pages.mkdir(parents=True)
        f = pages / "mood_quick_button.dart"
        f.write_text(
            "import 'package:chroniccare/presentation/pages/mood/mood_dialog.dart';\n"
            "import 'package:chroniccare/core/theme/app_tokens.dart';\n",
            encoding="utf-8",
        )
        # 临时改 PAGES 路径
        original = ccf.PAGES
        ccf.PAGES = str(tmp_path / "lib" / "presentation" / "pages")
        try:
            violations = ccf.check_file(str(f))
        finally:
            ccf.PAGES = original
        assert violations == []

    def test_violation(self, tmp_path):
        pages = tmp_path / "lib" / "presentation" / "pages" / "mood"
        pages.mkdir(parents=True)
        f = pages / "bad.dart"
        f.write_text(
            "import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';\n",
            encoding="utf-8",
        )
        original = ccf.PAGES
        ccf.PAGES = str(tmp_path / "lib" / "presentation" / "pages")
        try:
            violations = ccf.check_file(str(f))
        finally:
            ccf.PAGES = original
        assert len(violations) == 1
        line_num, import_path = violations[0]
        assert line_num == 1
        assert "vent/vent_list_page" in import_path


class TestMain:
    def test_clean_returns_zero(self, tmp_path, monkeypatch):
        """主流程集成测试: 临时 lib/ 跑 main(),clean 时 exit 0"""
        # 构造临时项目结构
        tmp = tmp_path
        (tmp / "lib" / "presentation" / "pages" / "mood").mkdir(parents=True)
        (tmp / "lib" / "presentation" / "pages" / "mood" / "foo.dart").write_text(
            "import 'package:chroniccare/presentation/pages/mood/bar.dart';\n",
            encoding="utf-8",
        )
        (tmp / "lib" / "presentation" / "pages" / "mood" / "bar.dart").write_text(
            "import 'package:flutter/material.dart';\n",
            encoding="utf-8",
        )
        # 改 ROOT 和 PAGES
        monkeypatch.setattr(ccf, "ROOT", str(tmp))
        monkeypatch.setattr(ccf, "PAGES", str(tmp / "lib" / "presentation" / "pages"))
        monkeypatch.setattr(sys, "argv", ["check_cross_feature.py"])
        try:
            ccf.main()
        except SystemExit as e:
            assert e.code == 0

    def test_violation_returns_one_in_ci(self, tmp_path, monkeypatch):
        """CI 模式: 有违规时 exit 1"""
        tmp = tmp_path
        (tmp / "lib" / "presentation" / "pages" / "mood").mkdir(parents=True)
        (tmp / "lib" / "presentation" / "pages" / "mood" / "bad.dart").write_text(
            "import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(ccf, "ROOT", str(tmp))
        monkeypatch.setattr(ccf, "PAGES", str(tmp / "lib" / "presentation" / "pages"))
        monkeypatch.setattr(sys, "argv", ["check_cross_feature.py", "--ci"])
        try:
            ccf.main()
        except SystemExit as e:
            assert e.code == 1
