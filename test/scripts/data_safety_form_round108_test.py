"""v0.30 R108: Data Safety Form 脚本 lock-in 测试

验证 R72 `generate_data_safety_form.py` 仍存在 + 关键内容完整 + 能跑通。
R108 增量: 加 v0.30 版本号断言 + health_info/audio/contacts 子类覆盖。
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPT = ROOT / "scripts" / "generate_data_safety_form.py"
DOC = ROOT / "docs" / "audit" / "2026-08-10-cleanup" / "R108-android-data-safety-form.md"


def test_script_exists() -> None:
    """R72 Data Safety Form 生成脚本必须存在"""
    assert SCRIPT.exists(), f"缺少 {SCRIPT}"
    content = SCRIPT.read_text(encoding="utf-8")
    assert content.startswith("#!/usr/bin/env python3"), "应有 python3 shebang"
    assert "def main()" in content, "应有 main() 函数"


def test_script_contains_v030_or_later_marker() -> None:
    """R108 增量: 脚本应含 v0.27 / v0.30 标识 (R72 写, R108 验证)"""
    content = SCRIPT.read_text(encoding="utf-8")
    # 至少有一个 v0.27 / v0.30 引用 (R72 写 v0.27 R72, R108 注释可加 v0.30)
    has_marker = bool(
        re.search(r"v0\.(27|30)\.\d", content) or
        re.search(r"R(72|108)\b", content)
    )
    assert has_marker, "脚本应含版本号 (v0.27/v0.30) 或 round 编号 (R72/R108)"


def test_script_covers_5_categories() -> None:
    """脚本应覆盖 5 大类 (account / device / app_activity / personal / health)"""
    content = SCRIPT.read_text(encoding="utf-8")
    expected = ["account_info", "device_info", "app_activity", "personal_info", "health_info"]
    for cat in expected:
        assert f"'{cat}'" in content or f'"{cat}"' in content, \
            f"脚本应覆盖 '{cat}' 类别 (Play Console 7 大类中本项目有内容的 5 类)"


def test_script_mentions_health_audio_vent() -> None:
    """R108 重点: 脚本应包含 health / audio / PHQ-9 / GAD-7 关键字

    R72 写于 R104 vent audio 启用前, 不要求含 'vent', 但应含 'audio' (mental audio)。
    R108 增量的 vent audio 由 doc + Play Console 填表覆盖, 不强求 R72 脚本修改。
    """
    content = SCRIPT.read_text(encoding="utf-8")
    # Health info
    assert "PHQ-9" in content or "GAD-7" in content, \
        "应包含 PHQ-9 / GAD-7 心理评估披露 (Google Play Health 强制)"
    # Audio
    assert "audio" in content.lower(), "应包含 audio (mood audio R27 启用, vent audio R104 启用)"
    # Emergency contacts (PIPL §23)
    assert "FeatureFlags" in content or "feature_flag" in content.lower() or \
           "emergencyContactEnabled" in content, \
        "应提及 FeatureFlag (注明 emergencyContactEnabled=false 未实际触发)"


def test_script_mentions_encryption_aes256() -> None:
    """必填声明: AES-256 SQLCipher 加密"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "AES-256" in content or "AES" in content, "应声明 AES 加密"
    assert "SQLCipher" in content, "应声明 SQLCipher 加密"


def test_script_mentions_deletion_endpoint() -> None:
    """必填: 数据删除端点 URL"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "https://chroniccare.app" in content, "应使用 chroniccare.app 域名 (R108 P0 #13 配套)"
    assert "delete" in content.lower(), "应包含 delete (数据删除端点)"


def test_setup_doc_exists() -> None:
    """R108 Data Safety Form 文档必须存在"""
    assert DOC.exists(), f"缺少 {DOC}"
    content = DOC.read_text(encoding="utf-8")
    # 5 大类 + 4 子项 = 28
    assert "28" in content, "应提 28 子项 (7 大类 × 4 子项)"
    # Step 1-4 流程
    assert "Step 1" in content and "Step 4" in content, "应含 4 步流程"
    # PIPL
    assert "PIPL" in content, "应提 PIPL §23 (联系人) / §28 (加密)"
    # Health & fitness 详细披露
    assert "Health" in content, "应含 Health & fitness 详细披露"
    # Audio 披露
    assert "Audio" in content, "应含 Audio 类披露"


def test_script_runs_without_error() -> None:
    """脚本能跑通 (生成 build/data_safety_form.json + .md)

    Windows PowerShell 默认 CP936 编码, 跑 Python 脚本 stdout 会 mojibake。
    改用 subprocess 配 encoding='utf-8' + 文件生成作为主要验证 (不严格匹配 stdout 字符串)。
    """
    r = subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=ROOT,
    )
    assert r.returncode == 0, f"脚本失败: {r.stderr}"

    # 验证输出文件 (主验证手段, 不靠 stdout 字符串)
    json_path = ROOT / "build" / "data_safety_form.json"
    md_path = ROOT / "build" / "data_safety_form.md"
    assert json_path.exists(), f"应生成 {json_path}"
    assert md_path.exists(), f"应生成 {md_path}"

    # JSON 结构校验
    import json
    form = json.loads(json_path.read_text(encoding="utf-8"))
    assert "data_collected" in form, "JSON 应含 data_collected"
    assert "data_shared" in form, "JSON 应含 data_shared"
    assert "data_security_practices" in form, "JSON 应含 data_security_practices"
    assert "data_deletion" in form, "JSON 应含 data_deletion"
    assert form["data_collected"]["health_info"]["encrypted_at_rest"] is True, \
        "Health info 必填加密 at rest"


if __name__ == "__main__":
    test_funcs = [
        test_script_exists,
        test_script_contains_v030_or_later_marker,
        test_script_covers_5_categories,
        test_script_mentions_health_audio_vent,
        test_script_mentions_encryption_aes256,
        test_script_mentions_deletion_endpoint,
        test_setup_doc_exists,
        test_script_runs_without_error,
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
