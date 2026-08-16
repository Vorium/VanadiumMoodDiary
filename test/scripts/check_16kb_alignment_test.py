"""v1.1.0 R113 (P2-20): check_16kb_alignment.py 自测

此前产物路径显式给出时, objdump / unzip 缺失仍返回 True (SKIP) = CI 假绿。
本测试钉住硬验证语义: 产物给定 + 工具/文件缺失 -> exit 1;
默认无产物参数 -> 产物验证 SKIP, 配置 OK 时 exit 0 (本地向后兼容)。
"""
import sys
from pathlib import Path

# 把 scripts 加到 path 才能 import
SCRIPTS = Path(__file__).resolve().parent.parent.parent / "scripts"
sys.path.insert(0, str(SCRIPTS))

import check_16kb_alignment as c16  # noqa: E402


def _valid_project(tmp_path):
    """配置级检查全绿的 fixture 项目 (targetSdk >= 35)"""
    (tmp_path / "android" / "app").mkdir(parents=True)
    (tmp_path / "pubspec.yaml").write_text(
        "name: app\ntargetSdkVersion: 36\n", encoding="utf-8"
    )
    (tmp_path / "android" / "app" / "build.gradle.kts").write_text(
        "targetSdk = 36\n", encoding="utf-8"
    )


class TestArtifactHardFail:
    def test_so_path_missing_returns_one(self, tmp_path, monkeypatch):
        _valid_project(tmp_path)
        monkeypatch.setattr(sys, "argv", ["x", f"--so-path={tmp_path / 'nope.so'}"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 1

    def test_aab_missing_returns_one(self, tmp_path, monkeypatch):
        _valid_project(tmp_path)
        monkeypatch.setattr(sys, "argv", ["x", f"--aab={tmp_path / 'nope.aab'}"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 1

    def test_objdump_missing_with_artifact_returns_one(self, tmp_path, monkeypatch):
        """产物路径给定时 objdump 缺失 = FAIL, 不再静默 SKIP"""
        _valid_project(tmp_path)
        so = tmp_path / "libapp.so"
        so.write_bytes(b"\x7fELF")
        monkeypatch.setattr(
            c16.shutil, "which",
            lambda name: None if name == "objdump" else "/usr/bin/" + name,
        )
        monkeypatch.setattr(sys, "argv", ["x", f"--so-path={so}"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 1

    def test_unzip_missing_with_aab_returns_one(self, tmp_path, monkeypatch):
        """--aab 给定时 unzip 缺失 = FAIL, 不再静默 SKIP"""
        _valid_project(tmp_path)
        aab = tmp_path / "app.aab"
        aab.write_bytes(b"PK")
        monkeypatch.setattr(
            c16.shutil, "which",
            lambda name: None if name == "unzip" else "/usr/bin/" + name,
        )
        monkeypatch.setattr(sys, "argv", ["x", f"--aab={aab}"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 1


class TestDefaultModeBackwardsCompat:
    def test_no_artifact_args_config_ok_returns_zero(self, tmp_path, monkeypatch, capsys):
        """默认本地跑 (无产物参数): 产物验证 SKIP, 配置 OK -> exit 0"""
        _valid_project(tmp_path)
        monkeypatch.setattr(sys, "argv", ["x"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 0
        assert "产物验证=SKIP" in capsys.readouterr().out

    def test_no_artifact_args_config_fail_returns_one(self, tmp_path, monkeypatch):
        """默认本地跑: 配置级检查 (targetSdk < 35) 仍要挂 -> exit 1"""
        (tmp_path / "android" / "app").mkdir(parents=True)
        (tmp_path / "pubspec.yaml").write_text(
            "name: app\ntargetSdkVersion: 34\n", encoding="utf-8"
        )
        (tmp_path / "android" / "app" / "build.gradle.kts").write_text(
            "targetSdk = 34\n", encoding="utf-8"
        )
        monkeypatch.setattr(sys, "argv", ["x"])
        monkeypatch.chdir(tmp_path)
        assert c16.main() == 1
