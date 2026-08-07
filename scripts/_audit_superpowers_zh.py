"""superpowers-zh 视角审计脚本。临时跑，结束后删。"""
import re
import json
import sys
import io
from pathlib import Path
from collections import Counter

# 强制 UTF-8 stdout
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(r"D:\Batch\chroniccare")
LIB = ROOT / "lib"
L10N = LIB / "l10n"
LEGAL = ROOT / "assets" / "legal"


def read_utf8(p: Path) -> str:
    return p.read_text(encoding="utf-8-sig")


# ---------- 1. ARB key 对比 ----------
print("=" * 70)
print("1. ARB key 对比 (zh / en / zh_Hant)")
print("=" * 70)
arb = {
    "zh": L10N / "app_zh.arb",
    "en": L10N / "app_en.arb",
    "zh_Hant": L10N / "app_zh_Hant.arb",
}
keys = {l: set(json.loads(read_utf8(p)).keys()) for l, p in arb.items()}
for l, p in arb.items():
    print(f"  {p.name}: {len(keys[l])} keys (含 @@ 元数据)")
real_keys = {l: {k for k in ks if not k.startswith("@@")} for l, ks in keys.items()}
print(f"\n  zh   业务 key: {len(real_keys['zh'])}")
print(f"  en   业务 key: {len(real_keys['en'])}")
print(f"  zh_Hant 业务 key: {len(real_keys['zh_Hant'])}")

print(f"\n  zh - en    (zh 有 en 缺): {sorted(real_keys['zh'] - real_keys['en'])}")
print(f"  en - zh    (en 有 zh 缺): {sorted(real_keys['en'] - real_keys['zh'])}")
print(f"  zh - zh_Hant (zh 有 Hant 缺): {sorted(real_keys['zh'] - real_keys['zh_Hant'])}")
print(f"  en - zh_Hant (en 有 Hant 缺): {sorted(real_keys['en'] - real_keys['zh_Hant'])}")

# ---------- 2. 硬编码中文 (Dart 字符串字面量内含中文) ----------
print()
print("=" * 70)
print("2. 硬编码中文 in lib/ (Dart 字符串)")
print("=" * 70)
hits_hardcoded = []
for p in LIB.rglob("*.dart"):
    try:
        text = read_utf8(p)
    except Exception:
        continue
    for i, line in enumerate(text.splitlines(), 1):
        # 匹配单/双引号字符串中包含中文（排除 import / 注释 / package 路径）
        if line.lstrip().startswith("import"):
            continue
        if line.lstrip().startswith("//") or line.lstrip().startswith("*"):
            continue
        # 找 'xx' 或 "xx" 字面量
        for m in re.finditer(r"""(['"])([^'"\n]*?)\1""", line):
            inner = m.group(2)
            if re.search(r"[\u4e00-\u9fff]", inner):
                # 排除纯路径 / 包名
                if re.match(r"^[\w\.\-/\\:]+$", inner):
                    continue
                hits_hardcoded.append((str(p.relative_to(ROOT)), i, line.strip()[:160]))

# 按文件聚合
by_file = Counter(h[0] for h in hits_hardcoded)
print(f"  硬编码中文候选: {len(hits_hardcoded)} 处, 涉及 {len(by_file)} 文件")
print("\n  涉及文件 Top 15:")
for f, c in by_file.most_common(15):
    print(f"    [{c:3d}] {f}")
print("\n  全部命中 (前 60):")
for p, i, l in hits_hardcoded[:60]:
    print(f"    {p}:{i}  {l}")


# ---------- 3. 中文+半角标点 ----------
print()
print("=" * 70)
print("3. 中文 + 半角标点 in ARB")
print("=" * 70)
arb_halfwidth = []
for p in arb.values():
    data = json.loads(read_utf8(p))
    for k, v in data.items():
        if k.startswith("@@"):
            continue
        if not isinstance(v, str):
            continue
        for m in re.finditer(r"[\u4e00-\u9fff][,.!?;:]", v):
            arb_halfwidth.append((p.name, k, m.group(0), v[:120]))
print(f"  命中: {len(arb_halfwidth)}")
for p, k, m, v in arb_halfwidth[:30]:
    print(f"    {p}  [{k}]  匹配 '{m}'  值: {v}")


# ---------- 4. 繁简一致性: zh vs zh_Hant 对比 (业务 key 文本) ----------
print()
print("=" * 70)
print("4. zh vs zh_Hant 同 key 值是否真的繁体 (用 OpenCC s2tw)")
print("=" * 70)
try:
    import opencc
    converter = opencc.OpenCC("s2tw")
    only_zh = real_keys["zh"] & real_keys["zh_Hant"]
    diffs = []
    not_simplified = []
    same_text = []
    zh_data = json.loads(read_utf8(arb["zh"]))
    hant_data = json.loads(read_utf8(arb["zh_Hant"]))
    for k in only_zh:
        zh_v = zh_data.get(k, "")
        hant_v = hant_data.get(k, "")
        if not isinstance(zh_v, str) or not isinstance(hant_v, str):
            continue
        if zh_v == hant_v:
            same_text.append(k)
            continue
        expected = converter.convert(zh_v)
        if expected == hant_v:
            pass  # OK
        else:
            diffs.append((k, zh_v[:60], hant_v[:60], expected[:60]))
    print(f"  zh 与 zh_Hant 同 key 业务文本: {len(only_zh)}")
    print(f"  文本完全相同 (zh 直接 copy 给 zh_Hant, 未翻译): {len(same_text)}")
    print(f"  差异: {len(diffs)}")
    if same_text:
        print("    文本相同 key (前 20):")
        for k in same_text[:20]:
            print(f"      [{k}]")
    if diffs:
        print("    不匹配 OpenCC s2tw (前 20):")
        for k, z, h, e in diffs[:20]:
            print(f"      [{k}]")
            print(f"        zh: {z}")
            print(f"        hant: {h}")
            print(f"        s2tw expect: {e}")
except ImportError:
    print("  opencc 未装, 跳过 s2tw 转换检测。pip install opencc-python-reimplemented")

# ---------- 5. PIPL §13/§14 单独同意 / 敏感信息相关 ARB key 抽样 ----------
print()
print("=" * 70)
print("5. PIPL §13 §14 相关 ARB key (单独同意 / 敏感信息)")
print("=" * 70)
zh_data = json.loads(read_utf8(arb["zh"]))
en_data = json.loads(read_utf8(arb["en"]))
hant_data = json.loads(read_utf8(arb["zh_Hant"]))
pipl_keywords = ["consent", "§13", "§14", "§17", "§29", "§47", "withdraw", "敏感", "紧急", "联系",
                 "导出", "export", "family", "contact", "share", "sms", "邮件", "email", "IAP", "付费",
                 "crisis", "热线", "hotline"]
for kw in pipl_keywords:
    matching = [k for k in real_keys["zh"] if kw.lower() in k.lower()]
    if matching:
        print(f"  '{kw}': {len(matching)} keys")

# ---------- 6. 业务温度 / 病耻感：care_copy 文案 ----------
print()
print("=" * 70)
print("6. care_copy 文案 (病耻感 / 温度)")
print("=" * 70)
care_keys = sorted(k for k in real_keys["zh"] if k.startswith("care") or "copy" in k.lower() or "greet" in k.lower() or "empty" in k.lower())
print(f"  候选 key: {len(care_keys)}")
for k in care_keys[:30]:
    v = zh_data.get(k, "")
    if isinstance(v, str) and len(v) > 0:
        print(f"    [{k}]: {v[:120]}")
