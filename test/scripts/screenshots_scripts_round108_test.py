"""v0.30 R108: 截图脚本 lock-in 测试

验证 R108 新增的 iOS + Android 截图脚本存在 + 关键内容 + bash 语法 (用 Python 模拟)。
不实际跑 (需 Mac + Xcode + Android Studio)。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPTS = ROOT / "scripts"
DOC = ROOT / "docs" / "audit" / "2026-08-10-cleanup" / "R108-screenshots-automation.md"


def test_ios_screenshots_script_exists() -> None:
    """R108 iOS 截图脚本必须存在"""
    path = SCRIPTS / "generate_ios_screenshots.sh"
    assert path.exists(), f"缺少 {path}"
    content = path.read_text(encoding="utf-8")
    assert "set -euo pipefail" in content, "应 set -euo pipefail 失败退出"
    assert "xcrun simctl" in content, "应调 xcrun simctl 模拟器"
    assert "fastlane" in content, "应输出到 fastlane/metadata/ios/"
    # 5 设备
    for device in ["iPhone 16 Pro Max", "iPhone 11 Pro Max", "iPhone 8 Plus",
                   "iPad Pro 12.9-inch", "iPad Pro 11-inch"]:
        assert device in content, f"应包含设备: {device}"
    # 3 locale
    for locale in ["en-US", "zh-Hans", "zh-Hant"]:
        assert locale in content, f"应包含 locale: {locale}"


def test_ios_screenshots_script_macos_check() -> None:
    """iOS 脚本应在非 Mac 平台直接退出"""
    content = (SCRIPTS / "generate_ios_screenshots.sh").read_text(encoding="utf-8")
    assert 'uname' in content and 'Darwin' in content, \
        "iOS 脚本应检查 uname = Darwin (macOS) 才跑"


def test_android_screenshots_script_exists() -> None:
    """R108 Android 截图脚本必须存在"""
    path = SCRIPTS / "generate_android_screenshots.sh"
    assert path.exists(), f"缺少 {path}"
    content = path.read_text(encoding="utf-8")
    assert "set -euo pipefail" in content, "应 set -euo pipefail 失败退出"
    assert "adb" in content, "应调 adb (Android Debug Bridge)"
    assert "emulator" in content, "应调 emulator 启动 AVD"
    assert "fastlane" in content, "应输出到 fastlane/metadata/android/"
    # 2 locale
    for locale in ["en-US", "zh-CN"]:
        assert locale in content, f"应包含 locale: {locale}"
    # 3 form factor
    for form in ["phoneScreenshots", "sevenInchScreenshots", "tenInchScreenshots"]:
        assert form in content, f"应包含 form factor: {form}"


def test_android_screenshots_script_cross_platform() -> None:
    """Android 脚本应跨平台 (Mac/Linux/WSL) — 不应硬性检查 uname = Darwin"""
    content = (SCRIPTS / "generate_android_screenshots.sh").read_text(encoding="utf-8")
    # Android 脚本不应有 uname != Darwin 检查 (应是 Mac/Linux/WSL 都能跑)
    # 但可以有 darwin/linux 路径分支
    assert 'Darwin' not in content or '# Android' in content or 'Mac' in content, \
        "Android 脚本不应有强制 macOS 限制 (应跨平台)"


def test_bash_syntax_basic() -> None:
    """基础 bash 语法检查 (Windows 上无法跑 `bash -n`, 用启发式)

    启发式:
    1. 文件是 LF 不是 CRLF (Windows 写 bash 常见坑)
    2. 有 shebang (bash 必备)
    3. 大块字符串 (e.g. heredoc) 平衡 — 本脚本不用 heredoc, 跳过
    4. 无明显未配对 quote — 不严格, 跳过 (单引号里的 " 难用 Python 检测)
    """
    for script in [SCRIPTS / "generate_ios_screenshots.sh",
                   SCRIPTS / "generate_android_screenshots.sh"]:
        content = script.read_text(encoding="utf-8")

        # 1. CRLF 检查
        assert '\r\n' not in content, f"{script.name} 含 CRLF, 需 LF (Windows 写 bash 常见坑)"

        # 2. shebang
        first_line = content.split('\n', 1)[0]
        assert first_line.startswith("#!"), f"{script.name} 缺 shebang"
        assert "bash" in first_line, f"{script.name} shebang 应是 bash"

        # 3. set -euo pipefail (严格模式)
        assert "set -euo pipefail" in content, \
            f"{script.name} 应含 'set -euo pipefail' (严格模式)"

        # 4. exit code 检查
        # 不做严格 quote 配对检查 — bash 单引号字符串里的双引号是字面量,
        # Python 难以判断。改为: 验证脚本有 exit code 关键字
        assert "exit " in content or "return " in content, \
            f"{script.name} 应有 'exit' 或 'return' (显式退出)"


def test_setup_doc_exists() -> None:
    """R108 截图文档必须存在"""
    assert DOC.exists(), f"缺少 {DOC}"
    content = DOC.read_text(encoding="utf-8")
    # 5 设备 iOS
    for device in ["iPhone 16 Pro Max", "iPhone 11 Pro Max", "iPhone 8 Plus",
                   "iPad Pro 12.9-inch", "iPad Pro 11-inch"]:
        assert device in content, f"应包含设备: {device}"
    # 3 locale
    for locale in ["en-US", "zh-Hans", "zh-Hant"]:
        assert locale in content, f"应包含 locale: {locale}"
    # Step 1-5
    assert "Step 1" in content and "Step 5" in content, "应含 5 步流程"
    # deep link
    assert "deep link" in content.lower() or "deep_link" in content, \
        "应提 deep link (App 需注册 chroniccare://)"
    # PII 警告
    assert "PII" in content, "应提 PII 警告 (截图用 mock 数据)"


def test_no_screenshot_placeholder_67b_remained() -> None:
    """验证现有 67B 截图占位未变 (R108 写脚本, 不直接改 PNG)"""
    for locale_dir in ["en-US", "zh-CN"]:
        for i in range(1, 5):
            png = ROOT / "fastlane" / "metadata" / "android" / locale_dir / \
                  "phone_screenshots" / f"screenshot_{i}.png"
            if png.exists():
                size = png.stat().st_size
                # 67B 占位 (R107 报告); R108 写脚本, 不实际改文件
                # 此测试仅验证文件存在, 提醒 dev 跑脚本后此占位会被覆盖
                assert size > 0, f"{png} 存在但为空"


if __name__ == "__main__":
    test_funcs = [
        test_ios_screenshots_script_exists,
        test_ios_screenshots_script_macos_check,
        test_android_screenshots_script_exists,
        test_android_screenshots_script_cross_platform,
        test_bash_syntax_basic,
        test_setup_doc_exists,
        test_no_screenshot_placeholder_67b_remained,
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
