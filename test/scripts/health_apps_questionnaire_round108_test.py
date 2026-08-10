"""v0.30 R108: Health Apps Questionnaire 脚本 lock-in 测试

验证 R108 新增 `generate_health_apps_questionnaire.py` 存在 + 关键内容 + 能跑通。
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPT = ROOT / "scripts" / "generate_health_apps_questionnaire.py"
DOC = ROOT / "docs" / "audit" / "2026-08-10-cleanup" / "R108-android-health-apps-questionnaire.md"


def test_script_exists() -> None:
    """R108 新增脚本必须存在"""
    assert SCRIPT.exists(), f"缺少 {SCRIPT}"
    content = SCRIPT.read_text(encoding="utf-8")
    assert content.startswith("#!/usr/bin/env python3"), "应有 python3 shebang"
    assert "def main()" in content, "应有 main() 函数"
    assert "R108" in content, "应标 R108"


def test_script_covers_4_blocks() -> None:
    """脚本应覆盖 4 大块 (Mental / Clinical / Medical Device / Stigma)"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "Mental Health" in content or "mental_health" in content, "应覆盖 Block 1 Mental Health"
    assert "Clinical Claims" in content or "clinical_claims" in content, "应覆盖 Block 2 Clinical Claims"
    assert "Medical Device" in content or "medical_device" in content, "应覆盖 Block 3 Medical Device"
    assert "Stigma" in content or "stigma" in content, "应覆盖 Block 4 Stigma"


def test_script_declares_not_medical_device() -> None:
    """Block 3 关键: 声明 NOT a medical device"""
    content = SCRIPT.read_text(encoding="utf-8")
    # 多种表达任一即可
    patterns = [
        r"NOT a medical device",
        r"not a medical device",
        r"is not a medical device",
        r"is \*\*NOT\*\* a medical device",
    ]
    assert any(re.search(p, content) for p in patterns), \
        "应明确声明 NOT a medical device (Block 3 答案)"


def test_script_mentions_phq9_gad7() -> None:
    """Block 1 关键: 提到 PHQ-9 / GAD-7"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "PHQ-9" in content, "应提 PHQ-9 (抑郁筛查)"
    assert "GAD-7" in content, "应提 GAD-7 (焦虑筛查)"


def test_script_mentions_crisis_hotline_6_regions() -> None:
    """Block 1 关键: 6 区域危机热线"""
    content = SCRIPT.read_text(encoding="utf-8")
    # 至少 5 个区域被列出
    regions = ["China", "US", "UK", "Hong Kong", "Taiwan", "Singapore"]
    matched = sum(1 for r in regions if r in content)
    assert matched >= 5, f"应列出 5+ 区域危机热线 (找到 {matched} 个)"


def test_script_mentions_no_clinical_claims() -> None:
    """Block 2 关键: 不做临床声明"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "does NOT make any claims" in content or "No clinical claims" in content, \
        "应声明不做诊断/治疗/治愈声明 (Block 2 答案)"


def test_script_targets_adult_18_plus() -> None:
    """Block 4 关键: 通用成年用户 18+"""
    content = SCRIPT.read_text(encoding="utf-8")
    assert "18+" in content or "adult" in content.lower(), \
        "应声明目标用户是 18+ 成年 (Block 4)"


def test_setup_doc_exists() -> None:
    """R108 Health Apps 文档必须存在"""
    assert DOC.exists(), f"缺少 {DOC}"
    content = DOC.read_text(encoding="utf-8")
    # 4 大块 (用 "Block N" 模式, 本文档用 "### Block N: ..." 格式)
    for block_num in ["1", "2", "3", "4"]:
        assert (f"Block {block_num}" in content or f"Block {block_num}:" in content), \
            f"应含 Block {block_num}"
    # Step 1-4
    assert "Step 1" in content and "Step 4" in content, "应含 4 步流程"
    # FDA / NMPA 监管
    assert "FDA" in content, "应提 FDA 监管"
    assert "NMPA" in content, "应提 NMPA 监管 (中国上架)"


def test_script_runs_without_error() -> None:
    """脚本能跑通 (生成 build/health_apps_questionnaire.json + .md)

    Windows PowerShell 默认 CP936 编码, 跑 Python 脚本 stdout 会 mojibake。
    改用文件生成作为主要验证 (不严格匹配 stdout 字符串)。
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

    # 验证输出文件
    json_path = ROOT / "build" / "health_apps_questionnaire.json"
    md_path = ROOT / "build" / "health_apps_questionnaire.md"
    assert json_path.exists(), f"应生成 {json_path}"
    assert md_path.exists(), f"应生成 {md_path}"

    # JSON 结构校验
    form = json.loads(json_path.read_text(encoding="utf-8"))
    assert "blocks" in form, "JSON 应含 blocks"
    assert len(form["blocks"]) == 4, f"应有 4 大块 (实际 {len(form['blocks'])})"
    # Block 3 必须答 NOT a medical device
    assert "NOT a medical device" in form["blocks"]["3_medical_device"]["chroniccare_answer"], \
        "Block 3 答案必须 NOT a medical device"


if __name__ == "__main__":
    test_funcs = [
        test_script_exists,
        test_script_covers_4_blocks,
        test_script_declares_not_medical_device,
        test_script_mentions_phq9_gad7,
        test_script_mentions_crisis_hotline_6_regions,
        test_script_mentions_no_clinical_claims,
        test_script_targets_adult_18_plus,
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
