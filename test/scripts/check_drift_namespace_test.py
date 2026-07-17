"""v0.17 round 14 (P3-5): check_drift_namespace 单元测试"""
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPT = ROOT / "scripts" / "check_drift_namespace.py"


def run(args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=cwd or ROOT,
    )


def test_clean_passes() -> None:
    """项目当前 7 张表全 unique, 0 duplicates"""
    r = run([])
    assert r.returncode == 0
    assert "[OK]" in r.stdout
    assert "0 duplicates" in r.stdout


def test_strict_mode_passes_clean() -> None:
    """干净项目下 --strict 也 exit 0"""
    r = run(["--strict"])
    assert r.returncode == 0
    assert "[OK]" in r.stdout


def test_detects_duplicate(tmp_path: Path) -> None:
    """2 个文件用同一个 @DataClassName 时应被检测

    用 --tables-dir= 指向 tmp_path/lib/.../tables 跑,
    避免 root 解析到 tmp_path 找不到脚本。
    """
    tables = tmp_path / "lib" / "core" / "data" / "database" / "tables"
    tables.mkdir(parents=True)
    (tables / "a.dart").write_text(
        "import 'package:drift/drift.dart';\n"
        "@DataClassName('Foo')\n"
        "class A extends Table {}\n",
        encoding="utf-8",
    )
    (tables / "b.dart").write_text(
        "import 'package:drift/drift.dart';\n"
        "@DataClassName('Foo')\n"
        "class B extends Table {}\n",
        encoding="utf-8",
    )
    r = run(
        ["--strict", f"--tables-dir={tables.relative_to(tmp_path)}"],
        cwd=tmp_path,
    )
    assert r.returncode == 1
    assert "[FAIL]" in r.stdout
    assert "Foo" in r.stdout
    assert "2 occurrences" in r.stdout


def test_handles_missing_dir(tmp_path: Path) -> None:
    """tables 目录不存在时 (greenfield) 报 OK, 不报错

    用 --tables-dir= 指向不存在的子目录。
    """
    r = run(["--tables-dir=does_not_exist"], cwd=tmp_path)
    assert r.returncode == 0
    assert "does not exist" in r.stdout or "nothing to check" in r.stdout
