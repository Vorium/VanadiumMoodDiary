"""v1.1.0 R113 (P2-20): check_datetime_race.py / check_datetime_race2.py 自测

两个脚本此前只打印报告从不 exit non-zero (CI 假绿)。本测试钉住 exit-code
语义: 真 race -> 1, clean -> 0。同时钉住豁免行为 (single-capture /
分支复制同语句) 不被破坏。
"""
import sys
from pathlib import Path

# 把 scripts 加到 path 才能 import
SCRIPTS = Path(__file__).resolve().parent.parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS))

import check_datetime_race as race  # noqa: E402
import check_datetime_race2 as race2  # noqa: E402


class TestCheckDatetimeRace:
    def test_clean_single_now_returns_zero(self, tmp_path, monkeypatch):
        """单个 DateTime.now() (single capture) 不构成 race -> exit 0"""
        lib = tmp_path / "lib"
        lib.mkdir()
        (lib / "a.dart").write_text(
            "void f() {\n"
            "  final now = DateTime.now();\n"
            "  print(now);\n"
            "}\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(race, "ROOT", lib)
        assert race.main() == 0

    def test_two_now_in_window_returns_one(self, tmp_path, monkeypatch):
        """同函数窗口内 >= 2 次 DateTime.now() -> exit 1 (CI 必须挂)"""
        lib = tmp_path / "lib"
        lib.mkdir()
        (lib / "b.dart").write_text(
            "void f() {\n"
            "  final a = DateTime.now();\n"
            "  print(DateTime.now());\n"
            "}\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(race, "ROOT", lib)
        assert race.main() == 1


class TestCheckDatetimeRace2:
    def test_single_capture_returns_zero(self, tmp_path, monkeypatch):
        """single-capture (final now = ...) 豁免 -> exit 0"""
        lib = tmp_path / "lib"
        lib.mkdir()
        (lib / "a.dart").write_text(
            "void f() {\n"
            "  final now = DateTime.now();\n"
            "  print(now);\n"
            "}\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(race2, "ROOT", lib)
        assert race2.main() == 0

    def test_two_distinct_hits_returns_one(self, tmp_path, monkeypatch):
        """同函数体 >= 2 次不同语句的 DateTime.now() -> exit 1"""
        lib = tmp_path / "lib"
        lib.mkdir()
        (lib / "b.dart").write_text(
            "void f() {\n"
            "  final a = DateTime.now();\n"
            "  print(DateTime.now());\n"
            "}\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(race2, "ROOT", lib)
        assert race2.main() == 1

    def test_branch_dup_same_stmt_returns_zero(self, tmp_path, monkeypatch):
        """分支复制 (同一语句 if/else 各一次, 行文本相同) 豁免 -> exit 0"""
        lib = tmp_path / "lib"
        lib.mkdir()
        (lib / "c.dart").write_text(
            "void f(bool flag) {\n"
            "  if (flag) {\n"
            "    print(DateTime.now());\n"
            "  } else {\n"
            "    print(DateTime.now());\n"
            "  }\n"
            "}\n",
            encoding="utf-8",
        )
        monkeypatch.setattr(race2, "ROOT", lib)
        assert race2.main() == 0
