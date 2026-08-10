"""v0.30 R108: keystore 脚本 lock-in 测试

验证 R108 新增的 bash keystore 脚本 + R72 PowerShell 脚本都存在 + 关键内容完整。
不实际跑 keytool (CI 没 JDK 也行, 而且不应在 CI 跑出会真 keystore)。

参考 check_drift_namespace_test.py 模式 (v0.17 round 14)。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPTS = ROOT / "scripts"
DOCS = ROOT / "docs" / "audit" / "2026-08-10-cleanup"


def test_bash_keystore_script_exists() -> None:
    """R108 新增的 bash keystore 脚本必须存在 + 内容关键"""
    path = SCRIPTS / "generate_android_keystore.sh"
    assert path.exists(), f"缺少 {path} (R108 应新增)"
    content = path.read_text(encoding="utf-8")

    # 关键标记
    assert "set -euo pipefail" in content, "应 set -euo pipefail 失败退出"
    assert "keytool -genkeypair" in content, "应调 keytool 生成"
    assert "RSA" in content and "2048" in content, "应默认 RSA 2048"
    assert "VALIDITY" in content, "应支持 VALIDITY 环境变量"
    assert "key.properties" in content, "应写 key.properties"
    assert "BACKUP_DIR" in content, "应备份到 ~/.chroniccare-keystore-backup"
    assert "chroniccare-release.jks" in content, "应输出 chroniccare-release.jks"


def test_bash_keystore_has_interactive_and_ci_modes() -> None:
    """支持交互式 + CI 2 种模式"""
    content = (SCRIPTS / "generate_android_keystore.sh").read_text(encoding="utf-8")

    # 交互式: 提示输入密码
    assert "read -r" in content, "应支持交互式输入 (read -r)"
    # CI: 环境变量覆盖
    assert "STORE_PASSWORD" in content and "KEY_PASSWORD" in content, \
        "应支持 STORE_PASSWORD/KEY_PASSWORD 环境变量 (CI 用)"
    # stty 关闭 echo (密码输入)
    assert "stty -echo" in content, "应 stty -echo 隐藏密码输入"


def test_powershell_keystore_script_still_present() -> None:
    """R72 PowerShell 脚本仍存在 (不能因为 R108 删了)"""
    path = SCRIPTS / "generate_release_keystore.ps1"
    assert path.exists(), f"缺少 {path} (R72 已加, R108 不应删)"
    content = path.read_text(encoding="utf-8")
    assert "keytool" in content, "R72 PowerShell 脚本应调 keytool"
    assert "Read-Host" in content, "R72 PowerShell 脚本应交互式输入"


def test_setup_doc_exists() -> None:
    """R108 keystore setup 文档必须存在"""
    doc = DOCS / "R108-android-keystore-setup.md"
    assert doc.exists(), f"缺少 {doc}"
    content = doc.read_text(encoding="utf-8")

    # 5 步流程
    assert "Step 1" in content and "Step 5" in content, "应含 Step 1-5 流程"
    # Play App Signing
    assert "Play App Signing" in content, "应含 Play App Signing 说明"
    # 灾备
    assert "1Password" in content or "Bitwarden" in content, "应含密码管理器备份说明"
    # Checklist
    assert "Checklist" in content, "应含上架前 Checklist"


def test_gradle_kts_references_key_properties() -> None:
    """Gradle 配应读 key.properties (验证 R97 改动未丢)"""
    gradle = ROOT / "android" / "app" / "build.gradle.kts"
    assert gradle.exists(), f"缺少 {gradle}"
    content = gradle.read_text(encoding="utf-8")
    assert "key.properties" in content, "build.gradle.kts 应读 key.properties"
    assert 'signingConfigs.getByName("release")' in content, \
        "应切 release signingConfig"


def test_gitignore_excludes_keystore() -> None:
    """.gitignore 应排除 *.jks + key.properties (R67 已加, R108 验证)"""
    gitignore = ROOT / ".gitignore"
    assert gitignore.exists(), "缺少 .gitignore"
    content = gitignore.read_text(encoding="utf-8")

    # 任一形式排除
    has_jks = "*.jks" in content or "*.keystore" in content
    has_props = "key.properties" in content or "*.properties" in content
    assert has_jks, ".gitignore 应排除 *.jks (防止误 commit keystore)"
    assert has_props, ".gitignore 应排除 key.properties (防止误 commit 密码)"


if __name__ == "__main__":
    # 直接跑 (pytest 模式)
    test_funcs = [
        test_bash_keystore_script_exists,
        test_bash_keystore_has_interactive_and_ci_modes,
        test_powershell_keystore_script_still_present,
        test_setup_doc_exists,
        test_gradle_kts_references_key_properties,
        test_gitignore_excludes_keystore,
    ]
    failed = 0
    for func in test_funcs:
        try:
            func()
            print(f"[OK] {func.__name__}")
        except AssertionError as e:
            print(f"[FAIL] {func.__name__}: {e}")
            failed += 1
    if failed:
        print(f"\n{failed} test(s) failed")
        sys.exit(1)
    print(f"\nAll {len(test_funcs)} tests passed")
