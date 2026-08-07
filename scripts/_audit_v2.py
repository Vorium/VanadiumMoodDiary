"""superpowers-zh 视角审计 v2 - 排除 generated file, 细分类。"""
import re
import json
import sys
import io
from pathlib import Path
from collections import Counter, defaultdict

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(r"D:\Batch\chroniccare")
LIB = ROOT / "lib"
L10N = LIB / "l10n"
LEGAL = ROOT / "assets" / "legal"
FASTLANE = ROOT / "fastlane"


def read_utf8(p: Path) -> str:
    return p.read_text(encoding="utf-8-sig")


# ---------- A. 硬编码中文 (排除 .g.dart / app_localizations_*.dart / .freezed.dart) ----------
print("=" * 70)
print("A. 硬编码中文 (排除 generated / app_localizations_*)")
print("=" * 70)

def is_generated(p: Path) -> bool:
    n = p.name
    return (n.endswith(".g.dart") or n.endswith(".freezed.dart")
            or n == "app_localizations.dart" or n.startswith("app_localizations_"))


hits = []
for p in LIB.rglob("*.dart"):
    if is_generated(p):
        continue
    try:
        text = read_utf8(p)
    except Exception:
        continue
    for i, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("import"):
            continue
        # 单行注释
        stripped = line.lstrip()
        if stripped.startswith("//") or stripped.startswith("*"):
            continue
        for m in re.finditer(r"""(['"])([^'"\n]{2,}?)\1""", line):
            inner = m.group(2)
            if re.search(r"[\u4e00-\u9fff]", inner):
                if re.match(r"^[\w\.\-/\\:]+$", inner):
                    continue
                if inner.startswith("package:") or inner.startswith("assets/"):
                    continue
                hits.append((str(p.relative_to(ROOT)), i, line.strip()[:200]))

by_file = Counter(h[0] for h in hits)
print(f"  硬编码中文 (非 generated): {len(hits)} 处, 涉及 {len(by_file)} 文件\n")
print("  涉及文件:")
for f, c in by_file.most_common():
    print(f"    [{c:3d}] {f}")
print()
print("  全部命中:")
for p, i, l in hits:
    print(f"    {p}:{i}  {l}")


# ---------- B. 半角标点细节：被命中的是否是 UI 文本（value 不是 metadata/description） ----------
print()
print("=" * 70)
print("B. 半角标点 UI 文本 (ARB value 包含, 排除 @@ metadata)")
print("=" * 70)

arb = {n: L10N / f"app_{n}.arb" for n in ["zh", "en", "zh_Hant"]}
for name, p in arb.items():
    data = json.loads(read_utf8(p))
    cnt = 0
    for k, v in data.items():
        if k.startswith("@@"):
            continue
        if not isinstance(v, str):
            continue
        if re.search(r"[\u4e00-\u9fff][,.!?;:]", v):
            cnt += 1
    print(f"  {p.name}: {cnt} 半角标点 key")


# ---------- C. 隐私政策 / 用户协议 / 敏感数据同意 的覆盖检查 ----------
print()
print("=" * 70)
print("C. 法务 3 文件内容覆盖 (v0.22+ vent/mood/assessment)")
print("=" * 70)
keywords_legal = {
    "树洞 (vent)": ["树洞", "vent", "私密", "倾诉"],
    "情绪日记 (mood)": ["情绪", "mood"],
    "心理评估 (PHQ/GAD)": ["心理评估", "PHQ", "GAD", "量表"],
    "PIPL §13 同意": ["§13", "PIPL §13", "单独同意"],
    "PIPL §14 敏感": ["§14", "敏感", "敏感个人信息"],
    "PIPL §17 责任": ["§17", "责任"],
    "PIPL §29 跨境": ["§29", "跨境", "提供给第三方"],
    "PIPL §47 撤回": ["§47", "撤回", "删除"],
    "危机热线": ["热线", "危机", "北京心理危机", "上海心理", "24小时", "24 小時"],
    "8元 IAP": ["8 元", "8元", "8 元 / 月", "付费", "IAP", "捐赠", "訂閱", "订阅"],
    "第三方 SDK 表格": ["SDK", "表格", "第三方"],
    "网络数据安全": ["数据安全", "网络", "传输", "加密"],
    "年龄 18 / 监护人": ["18", "监护人", "未成年人", "年龄"],
}
for f in ["privacy_policy.md", "user_agreement.md", "sensitive_data_consent.md"]:
    p = LEGAL / f
    if not p.exists():
        print(f"\n  --- {f}: 不存在 ---")
        continue
    text = read_utf8(p)
    print(f"\n  --- {f} ({len(text)} chars) ---")
    for label, kws in keywords_legal.items():
        hit = [k for k in kws if k in text]
        mark = "✓" if hit else "✗"
        print(f"    {mark} {label}: {hit if hit else '缺失'}")


# ---------- D. fastlane metadata 4 locale 内容对比 ----------
print()
print("=" * 70)
print("D. fastlane metadata (zh-CN / zh-Hans / zh-Hant / en-US)")
print("=" * 70)
for d in sorted(FASTLANE.glob("metadata/**/")):
    files = sorted(d.glob("*.txt"))
    if not files:
        continue
    print(f"\n  --- {d.relative_to(ROOT)} ---")
    for f in files:
        text = read_utf8(f).strip()
        print(f"    {f.name} ({len(text)} chars): {text[:120]}")


# ---------- E. 提交规范：git log 风格检查 ----------
print()
print("=" * 70)
print("E. git log 提交规范检查 (近 100 commit)")
print("=" * 70)
import subprocess
result = subprocess.run(
    ["git", "-C", str(ROOT), "log", "--pretty=format:%H %s", "-100"],
    capture_output=True, text=True, encoding="utf-8", errors="replace"
)
lines = [l for l in result.stdout.splitlines() if l]
print(f"  共 {len(lines)} commits")

import re as re2
pat_good = re2.compile(r"^v\d+\.\d+(\.\d+)?\s+round\s+\d+(\.\d+)?")
ok, bad = [], []
for l in lines:
    msg = l.split(" ", 1)[1] if " " in l else l
    if pat_good.match(msg):
        ok.append(msg)
    else:
        bad.append(msg)
print(f"  符合 '<version> round <N>: <title>': {len(ok)}")
print(f"  不符合: {len(bad)}")
print("  不符合样本 (前 20):")
for m in bad[:20]:
    print(f"    {m[:140]}")


# ---------- F. PIPL §13 §14 §29 §47 单独同意 关键文件 ----------
print()
print("=" * 70)
print("F. PIPL §13 §14 §29 §47 单独同意 关键代码文件")
print("=" * 70)
for kw in ["§13", "§14", "§29", "§47", "contact_consent", "legal_consent", "WithdrawConsent",
           "ExportConsent", "IAPConsent", "SensitiveConsent", "单独同意", "敏感个人信息"]:
    matches = []
    for p in LIB.rglob("*.dart"):
        if is_generated(p):
            continue
        try:
            text = read_utf8(p)
        except Exception:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            if kw in line:
                matches.append(f"{p.relative_to(ROOT)}:{i}")
                if len(matches) >= 5:
                    break
        if len(matches) >= 5:
            break
    if matches:
        print(f"\n  '{kw}' 出现文件 (前 5):")
        for m in matches:
            print(f"    {m}")


# ---------- G. 文件树扫：业务功能"温度"页面（setup / safety / crisis）文案 ----------
print()
print("=" * 70)
print("G. 关键页面/业务 - 中文文案友好度 (随机抽样)")
print("=" * 70)
sample_keys = [
    "setupHello", "setupIntro", "setupWelcomeTitle",
    "homeStillOnline", "homeStreakBroken", "homeCheckedIn",
    "safetyAlertBodySent", "safetyAlertBodyFailed", "safetyAlertBodyMocked",
    "ventEmptyTitle", "ventEmptySubtitle", "ventEmptyAction",
    "snackbarEmptyVent", "setupDoneTitle", "setupDoneSubtitle",
    "careCopy", "careCopyStreak", "careCopyLongStreak",
    "crisisHotline", "crisisHotlineCall",
    "settingsDisclaimerText", "settingsAboutVersion",
    "legalVentWithdrawBody", "legalVentWithdrawDeleteDesc", "legalVentWithdrawSealDesc",
    "settingsExportRiskBody", "settingsExportRiskLiability", "settingsExportRiskAcknowledge",
    "setupLegalAgeAttestation",
]
data_zh = json.loads(read_utf8(arb["zh"]))
data_en = json.loads(read_utf8(arb["en"]))
data_hant = json.loads(read_utf8(arb["zh_Hant"]))
for k in sample_keys:
    z = data_zh.get(k) or data_zh.get("@" + k)
    e = data_en.get(k) or data_en.get("@" + k)
    h = data_hant.get(k) or data_hant.get("@" + k)
    if not z:
        print(f"  [{k}]  ❌ 缺失")
        continue
    print(f"\n  [{k}]")
    print(f"    zh:     {z[:140]}")
    print(f"    en:     {(e or '❌ 缺')[:140]}")
    print(f"    zh_Hant: {(h or '❌ 缺')[:140]}")
