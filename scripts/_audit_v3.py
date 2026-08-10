"""v3 - 细节: 版本号一致性 / IAP / 占位符 / 危机话术 / setup_legal_dialog 内容"""
import re
import json
import sys
import io
from pathlib import Path
from collections import Counter

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(r"D:\Batch\chroniccare")
LIB = ROOT / "lib"
L10N = LIB / "l10n"


def read_utf8(p):
    return p.read_text(encoding="utf-8-sig")


# ---------- 1. pubspec 当前版本 ----------
import re as re2
ps = read_utf8(ROOT / "pubspec.yaml")
m = re2.search(r"^version:\s*(\S+)", ps, re2.M)
if m:
    print(f"pubspec.yaml version: {m.group(1)}")

# 找所有 ARB 里写死的版本号
print()
print("=" * 70)
print("1. ARB 内硬编码的版本号 (应与 pubspec 同步)")
print("=" * 70)
for p in L10N.glob("app_*.arb"):
    text = read_utf8(p)
    matches = re2.findall(r"v?\d+\.\d+(\.\d+)?", text)
    if matches:
        from collections import Counter
        c = Counter(matches)
        print(f"\n  {p.name}:")
        for v, n in c.most_common(8):
            print(f"    v{v}: {n} 次")


# ---------- 2. IAP / 8 元 / 付费 / 订阅 / 捐赠 ----------
print()
print("=" * 70)
print("2. IAP / 8 元 / 付费 关键词")
print("=" * 70)
for p in L10N.glob("app_*.arb"):
    text = read_utf8(p)
    keys = list(json.loads(text).keys())
    matched = []
    for k in keys:
        v = json.loads(text)[k]
        if isinstance(v, str) and re2.search(r"8\s*元|IAP|订阅|订阅|訂閱|付费|付費|捐赠|捐贈|in-app|purchase", v, re2.I):
            matched.append((k, v))
        if re2.search(r"8\s*元|IAP|订阅|订阅|訂閱|付费|付費|捐赠|捐贈", k, re2.I):
            if (k, v) not in matched:
                matched.append((k, v))
    if matched:
        print(f"\n  {p.name}: {len(matched)} 命中")
        for k, v in matched[:30]:
            print(f"    [{k}] = {v[:100]}")


# ---------- 3. fastlane / assets / docs 占位符 ----------
print()
print("=" * 70)
print("3. 占位符 (PLACEHOLDER / TODO / xxx / TBD)")
print("=" * 70)
for p in [ROOT / "fastlane" / "Appfile", ROOT / "fastlane" / "Fastfile"]:
    text = read_utf8(p)
    print(f"\n  --- {p.relative_to(ROOT)} ---")
    for i, line in enumerate(text.splitlines(), 1):
        if re2.search(r"PLACEHOLDER|TODO|XXX|TBD|FIXME|REPLACE", line, re2.I):
            print(f"    {i}: {line[:140]}")


# ---------- 4. setup_legal_dialog 内容 ----------
print()
print("=" * 70)
print("4. setup_legal_dialog.dart 热线部分 (R83 Q10b 加的)")
print("=" * 70)
p = LIB / "presentation" / "pages" / "setup" / "setup_legal_dialog.dart"
text = read_utf8(p)
for i, line in enumerate(text.splitlines(), 1):
    if re2.search(r"热线|hotline|crisis|心理危机|🆘", line, re2.I):
        print(f"  {i}: {line[:160]}")


# ---------- 5. PHQ-9 / GAD-7 严重度措辞（精神心理 App 措辞敏感）----------
print()
print("=" * 70)
print("5. PHQ-9 / GAD-7 严重度措辞 (情绪 / 心理 措辞需审慎)")
print("=" * 70)
data_zh = json.loads(read_utf8(L10N / "app_zh.arb"))
for k, v in sorted(data_zh.items()):
    if k.startswith("@@"):
        continue
    if not isinstance(v, str):
        continue
    if re2.search(r"(PHQ|GAD|severity|severe|mild|moderate|minim|crisis|自杀|自伤|伤害自己|无风险|几乎没有|轻度|中度|重度)", k + " " + v, re2.I):
        print(f"  [{k}]: {v[:140]}")


# ---------- 6. 法律条款 §13 §14 §29 §47 单独同意 流程 (R83 集中改) ----------
print()
print("=" * 70)
print("6. 单独同意流程代码 (consent_dialog / legal_consent_provider)")
print("=" * 70)
for f in [
    LIB / "presentation" / "widgets" / "consent_dialog.dart",
    LIB / "presentation" / "providers" / "legal_consent_provider.dart",
    LIB / "presentation" / "pages" / "setup" / "setup_legal_dialog.dart",
]:
    print(f"\n  --- {f.relative_to(ROOT)} (size={f.stat().st_size}) ---")
    text = read_utf8(f)
    for i, line in enumerate(text.splitlines(), 1):
        if re2.search(r"§\d+|ConsentKind\.|consentBody|consentTitle|withdraw|同意|撤回|checkbox|isChecked", line, re2.I):
            if line.lstrip().startswith("//") or line.lstrip().startswith("*"):
                continue
            print(f"    {i}: {line[:170]}")


# ---------- 7. AGENTS.md / CHANGELOG 风格（标点 / 中英混用）----------
print()
print("=" * 70)
print("7. AGENTS.md / CHANGELOG 风格: 中英混用 + 标点")
print("=" * 70)
for f in [ROOT / "AGENTS.md", ROOT / "docs" / "CHANGELOG.md"]:
    text = read_utf8(f)
    # 半角逗号/句号 后跟中文 OR 中文后跟半角逗号
    n_zh_en = len(re2.findall(r"[\u4e00-\u9fff],|[\u4e00-\u9fff]\.|,[\u4e00-\u9fff]|\.[\u4e00-\u9fff]", text))
    n_zh_full = len(re2.findall(r"[\u4e00-\u9fff][，：。；？]|[\u4e00-\u9fff]、", text))
    print(f"  {f.relative_to(ROOT)}: 半角标点贴近中文 {n_zh_en} 处, 全角标点 {n_zh_full} 处")


# ---------- 8. snackbarErrorTemplate / homeLastMed / homeNextReminder / homeStreak ----------
print()
print("=" * 70)
print("8. 缺失的 6 zh key 是否真缺失 (zh - en 集合差)")
print("=" * 70)
zh_data = json.loads(read_utf8(L10N / "app_zh.arb"))
en_data = json.loads(read_utf8(L10N / "app_en.arb"))
hant_data = json.loads(read_utf8(L10N / "app_zh_Hant.arb"))
for k in ["@homeLastMed", "@homeNextReminder", "@homeStreak", "@setupStep", "@snackbarErrorTemplate"]:
    print(f"\n  {k}:")
    print(f"    zh:     {zh_data.get(k, '❌ 缺')!r}")
    print(f"    en:     {en_data.get(k, '❌ 缺')!r}")
    print(f"    zh_Hant: {hant_data.get(k, '❌ 缺')!r}")

# 9. check_widget_dispose / check_no_pua / check_no_hardcoded_utc 等守护脚本是否真的存在
print()
print("=" * 70)
print("9. 16 守护脚本是否真存在 (AGENTS.md 第 16 守护清单)")
print("=" * 70)
import os
scripts = [
    "check_arb_keys.py", "check_changelog.py", "check_cross_feature.py",
    "check_datetime_race.py", "check_datetime_race2.py", "check_drift_namespace.py",
    "check_fullwidth_punctuation.py", "check_no_hardcoded_utc.py", "check_no_pua.py",
    "check_widget_dispose.py", "check_orphan_arb_keys.py", "check_legal_consent.py",
    "check_sms_release_ready.py", "check_strings_hardcoded.py",
    "check_zh_hant_consistency.py", "check_all.dart",
]
scripts_dir = ROOT / "scripts"
for s in scripts:
    p = scripts_dir / s
    print(f"  {'✓' if p.exists() else '✗ 缺失'}  scripts/{s}")
