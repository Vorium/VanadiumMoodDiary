#!/usr/bin/env python3
"""v0.30 round 95 (sub-spec 6 task 6e): Coverage 阈值守门员

R95 报告 §3.2 spen P1 #7 集成测扩 + coverage 阈值。
18 守门员 (R95 sub-spec 6 步骤 5 增 1, 跟 R95 sub-spec 5 17 守门员同模式)。

功能:
1. 解析 coverage/lcov.info (flutter test --coverage 生成)
2. 跟 coverage_threshold.yaml 阈值对比
3. 按 layer (domain / data / presentation / shared / core) 聚合
4. 关键文件单独检查
5. 退出码: 0 = pass, 1 = fail (CI 友好)

用法:
    python scripts/check_coverage.py
    python scripts/check_coverage.py --ci           # CI 模式 (静默 + 退出码)
    python scripts/check_coverage.py --report json  # JSON 输出
    python scripts/check_coverage.py --threshold-yaml coverage_threshold.yaml
"""
import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(2)


# R95 sub-spec 5 17 守门员已用 check_*.py 命名, 这是 R95 sub-spec 6 第 18 个
LCOV_PATH = Path("coverage/lcov.info")
DEFAULT_THRESHOLD_YAML = Path("coverage_threshold.yaml")


def parse_lcov(lcov_path: Path) -> dict:
    """解析 lcov.info, 返:
    {
      'files': {file_path: {lines_total, lines_hit, lines_missed, functions_total, functions_hit}},
      'by_layer': {layer: {lines_total, lines_hit, ...}},
    }
    """
    if not lcov_path.exists():
        print(f"ERROR: {lcov_path} not found. Run `flutter test --coverage` first.",
              file=sys.stderr)
        sys.exit(2)

    files = {}
    current = None

    with open(lcov_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("SF:"):
                # Source file
                path = line[3:].replace("\\", "/")
                # 转换绝对路径 → 相对路径
                if "lib/" in path:
                    path = "lib/" + path.split("lib/", 1)[1]
                current = {
                    "path": path,
                    "lines_total": 0,
                    "lines_hit": 0,
                    "lines_missed": 0,
                    "functions_total": 0,
                    "functions_hit": 0,
                }
            elif line.startswith("LF:") and current:
                current["lines_total"] = int(line[3:])
            elif line.startswith("LH:") and current:
                current["lines_hit"] = int(line[3:])
            elif line.startswith("FNF:") and current:
                current["functions_total"] = int(line[4:])
            elif line.startswith("FNH:") and current:
                current["functions_hit"] = int(line[4:])
            elif line == "end_of_record" and current:
                current["lines_missed"] = (
                    current["lines_total"] - current["lines_hit"]
                )
                files[current["path"]] = current
                current = None

    # 按 layer 聚合
    by_layer = defaultdict(lambda: {
        "lines_total": 0, "lines_hit": 0, "files": 0,
    })
    for path, stats in files.items():
        layer = _classify_layer(path)
        by_layer[layer]["lines_total"] += stats["lines_total"]
        by_layer[layer]["lines_hit"] += stats["lines_hit"]
        by_layer[layer]["files"] += 1

    return {"files": files, "by_layer": dict(by_layer)}


def _classify_layer(path: str) -> str:
    """按 lib/ 路径分类 layer (跟 AGENTS.md 4 层架构一致)"""
    if "/domain/" in path:
        return "domain"
    if "/data/" in path or "/database/" in path:
        return "data"
    if "/presentation/" in path:
        return "presentation"
    if "/shared/" in path:
        return "shared"
    if "/core/" in path or "/theme/" in path or "/routing/" in path or "/l10n/" in path:
        return "core"
    if path.startswith("lib/main") or path.startswith("lib/app"):
        return "core"
    return "other"


def check_thresholds(coverage: dict, threshold: dict) -> list:
    """返 [(layer_or_file, actual_pct, required_pct, status)]"""
    results = []

    # 按层
    by_layer_threshold = threshold.get("by_layer", {})
    for layer, required in by_layer_threshold.items():
        stats = coverage["by_layer"].get(layer, {
            "lines_total": 0, "lines_hit": 0,
        })
        if stats["lines_total"] == 0:
            results.append((layer, 0.0, required, "skip"))
            continue
        actual = stats["lines_hit"] / stats["lines_total"] * 100
        status = "pass" if actual >= required else "fail"
        results.append((layer, actual, required, status))

    # 关键文件
    for entry in threshold.get("critical_files", []):
        path = entry["path"]
        required = entry["min_coverage"]
        stats = coverage["files"].get(path)
        if stats is None or stats["lines_total"] == 0:
            results.append((path, 0.0, required, "skip"))
            continue
        actual = stats["lines_hit"] / stats["lines_total"] * 100
        status = "pass" if actual >= required else "fail"
        results.append((path, actual, required, status))

    return results


def format_human(results: list, coverage: dict) -> str:
    """人类可读输出 (跟 R92 check_*.py 一致) - 避免 unicode 字符防 GBK 编码问题"""
    out = ["=" * 60, "Coverage threshold check (R95 sub-spec 6 task 6e)", "=" * 60, ""]
    out.append("By layer:")
    for layer, actual, required, status in results:
        if layer in coverage["by_layer"]:
            out.append(
                f"  [{status.upper():4}] {layer:15} {actual:5.1f}% "
                f"(required >= {required}%, "
                f"{coverage['by_layer'][layer]['lines_hit']}/{coverage['by_layer'][layer]['lines_total']} lines, "
                f"{coverage['by_layer'][layer]['files']} files)"
            )

    out.append("")
    out.append("Critical files:")
    for layer, actual, required, status in results:
        if layer not in coverage["by_layer"]:
            sym = "[OK]" if status == "pass" else "[FAIL]" if status == "fail" else "[SKIP]"
            out.append(f"  {sym} {layer:60} {actual:5.1f}% (required >= {required}%)")

    fail_count = sum(1 for _, _, _, s in results if s == "fail")
    out.append("")
    out.append("=" * 60)
    if fail_count == 0:
        out.append("[PASS] All thresholds met (18 gatekeeper)")
    else:
        out.append(f"[FAIL] {fail_count} threshold violation(s)")
    out.append("=" * 60)
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser(description="R95 sub-spec 6 coverage 守门员")
    parser.add_argument("--ci", action="store_true", help="CI 模式 (静默 + 退出码)")
    parser.add_argument("--report", choices=["human", "json"], default="human")
    parser.add_argument("--threshold-yaml", type=Path, default=DEFAULT_THRESHOLD_YAML)
    parser.add_argument("--lcov", type=Path, default=LCOV_PATH)
    args = parser.parse_args()

    if not args.threshold_yaml.exists():
        print(f"ERROR: {args.threshold_yaml} not found", file=sys.stderr)
        sys.exit(2)

    with open(args.threshold_yaml, encoding="utf-8") as f:
        threshold = yaml.safe_load(f)

    coverage = parse_lcov(args.lcov)
    # YAML 嵌套: thresholds.by_layer / thresholds.critical_files
    threshold_config = threshold.get("thresholds", threshold)
    results = check_thresholds(coverage, threshold_config)

    if args.report == "json":
        output = {
            "coverage": coverage,
            "results": [
                {"name": r[0], "actual": r[1], "required": r[2], "status": r[3]}
                for r in results
            ],
        }
        print(json.dumps(output, indent=2))
    else:
        print(format_human(results, coverage))

    fail_count = sum(1 for _, _, _, s in results if s == "fail")
    sys.exit(1 if fail_count > 0 else 0)


if __name__ == "__main__":
    main()
