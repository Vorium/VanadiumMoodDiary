"""v0.30 R108: 域名 + 邮箱 lock-in 测试

验证 R108 新增的域名注册脚本 + 4 HTML 模板 + 12 URL 文件占位正确。
不实际访问 https://chroniccare.app (需网络, 且 R108 域未注册)。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
SCRIPTS = ROOT / "scripts"
TEMPLATES = SCRIPTS / "templates"
DOC = ROOT / "docs" / "audit" / "2026-08-10-cleanup" / "R108-domain-registration-guide.md"
METADATA = ROOT / "fastlane" / "metadata"


def test_register_domain_script_exists() -> None:
    """R108 注册脚本必须存在"""
    path = SCRIPTS / "register_domain.sh"
    assert path.exists(), f"缺少 {path}"
    content = path.read_text(encoding="utf-8")
    assert "set -euo pipefail" in content, "应 set -euo pipefail"
    # Cloudflare API
    assert "api.cloudflare.com" in content, "应调 Cloudflare API"
    # 域名
    assert "chroniccare.app" in content, "应提到 chroniccare.app"
    # 4 邮箱
    for email in ["support", "privacy", "noreply", "abuse"]:
        assert f"{email}@chroniccare.app" in content, f"应配 {email}@chroniccare.app"


def test_register_domain_script_is_placeholder() -> None:
    """脚本应明确是占位, 需用户填真实 CF_API_TOKEN + CF_ACCOUNT_ID"""
    content = (SCRIPTS / "register_domain.sh").read_text(encoding="utf-8")
    assert "PLACEHOLDER" in content, "应明确标记 PLACEHOLDER 占位"
    assert "FAIL" in content, "应 FAIL 退出 if 未填真实值"


def test_4_html_templates_exist() -> None:
    """R108 4 HTML 模板必须存在"""
    expected = ["privacy.html.tmpl", "support.html.tmpl",
                "user-agreement.html.tmpl", "sensitive-data-consent.html.tmpl"]
    for tmpl in expected:
        path = TEMPLATES / tmpl
        assert path.exists(), f"缺少 {path}"


def test_4_html_templates_have_placeholders() -> None:
    """4 HTML 模板应含 {{占位}} (供 sed 替换)"""
    for tmpl in (TEMPLATES).glob("*.html.tmpl"):
        content = tmpl.read_text(encoding="utf-8")
        # 至少含 VERSION 占位
        assert "{{VERSION}}" in content, f"{tmpl.name} 应含 {{{{VERSION}}}} 占位"
        # 至少含 YEAR
        assert "{{YEAR}}" in content, f"{tmpl.name} 应含 {{{{YEAR}}}} 占位"


def test_4_html_templates_contain_html_doctype() -> None:
    """4 HTML 模板应是合法 HTML5"""
    for tmpl in (TEMPLATES).glob("*.html.tmpl"):
        content = tmpl.read_text(encoding="utf-8")
        assert content.startswith("<!DOCTYPE html>"), \
            f"{tmpl.name} 应以 <!DOCTYPE html> 开头"
        assert "</html>" in content, f"{tmpl.name} 应有 </html> 结束"
        assert "<meta charset=\"UTF-8\">" in content, \
            f"{tmpl.name} 应含 UTF-8 meta"


def test_12_privacy_support_urls_use_chroniccare_app() -> None:
    """12 URL 文件应指向 chroniccare.app"""
    expected_urls = []

    # iOS 3 locale
    for locale in ["en-US", "zh-Hans", "zh-Hant"]:
        for f in ["privacy_url.txt", "support_url.txt"]:
            p = METADATA / "ios" / locale / f
            if p.exists():
                content = p.read_text(encoding="utf-8").strip()
                assert "chroniccare.app" in content, \
                    f"{p} 应含 chroniccare.app (实际: '{content}')"
                expected_urls.append(f"ios/{locale}/{f}")

    # Android 2 locale (R100 删了, R108 应恢复)
    for locale in ["en-US", "zh-CN"]:
        for f in ["privacy_url.txt", "support_url.txt"]:
            p = METADATA / "android" / locale / f
            if p.exists():
                content = p.read_text(encoding="utf-8").strip()
                assert "chroniccare.app" in content, \
                    f"{p} 应含 chroniccare.app (实际: '{content}')"
                expected_urls.append(f"android/{locale}/{f}")

    # 应至少 6 个 (iOS 3 × 2), Android 是 R108 待恢复
    assert len(expected_urls) >= 6, \
        f"应至少 6 个 iOS URL 文件 (实际找到 {len(expected_urls)}: {expected_urls})"


def test_setup_doc_exists() -> None:
    """R108 域名注册文档必须存在"""
    assert DOC.exists(), f"缺少 {DOC}"
    content = DOC.read_text(encoding="utf-8")
    # 6 步流程
    for i in range(1, 7):
        assert f"Step {i}" in content, f"应含 Step {i}"
    # 4 邮箱
    for email in ["support", "privacy", "noreply", "abuse"]:
        assert f"{email}@chroniccare.app" in content, \
            f"应配 {email}@chroniccare.app"
    # Cloudflare
    assert "Cloudflare" in content, "应提 Cloudflare (域名 + Pages + Email Routing)"
    # ICP 备案
    assert "ICP" in content, "应提 ICP 备案 (中国大陆上架强制)"


def test_assets_legal_md_files_still_exist() -> None:
    """源 Markdown 文件 (R67) 仍存在, 模板可引用"""
    legal = ROOT / "assets" / "legal"
    assert legal.exists(), f"缺少 {legal}"
    for f in ["privacy_policy.md", "user_agreement.md", "sensitive_data_consent.md"]:
        path = legal / f
        assert path.exists(), f"缺少 {path} (R67 已有, R108 模板应能引用)"


if __name__ == "__main__":
    test_funcs = [
        test_register_domain_script_exists,
        test_register_domain_script_is_placeholder,
        test_4_html_templates_exist,
        test_4_html_templates_have_placeholders,
        test_4_html_templates_contain_html_doctype,
        test_12_privacy_support_urls_use_chroniccare_app,
        test_setup_doc_exists,
        test_assets_legal_md_files_still_exist,
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
