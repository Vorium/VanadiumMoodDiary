#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 视觉重构): 主页快捷操作守门员

emotion-first refactor 续作 — 主页第一屏不再出现「用药」「量表」字样,
二级入口 (用药 / 量表 / 危机热线 / 烦恼闭环) 收进 BottomSheet。

本守门员锁住:
1. home_page_state.dart build 树不能直接出现 onMedicationTap / onAssessmentTap 路由跳转
2. PrimaryActionRow 不能包含 medication / assessment 砖块 (iOS 系统图标 icon 或 label)
3. 用药 / 心理评估在设置页 HealthDataGroup 出现 (允许, 入口已挪)

执行:
  python scripts/check_home_quick_actions.py
  python scripts/check_home_quick_actions.py --ci  # exit 1 on fail

依据 (R115 docs/design/2026-08-17-redesign-mockup/index.html):
- 「更多」BottomSheet = 二级入口收纳点
- 主页 PrimaryActionRow = 3 行 list (情绪回顾 / 日常追踪 / 心理技巧)
- 健康数据 group = 设置页置顶 (medication / assessment 入口)
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HOME_DIR = REPO_ROOT / "lib" / "presentation" / "pages" / "home"
SETTINGS_DIR = REPO_ROOT / "lib" / "presentation" / "pages" / "settings"

# 文件白名单: 这些文件可以包含 med/assessment 路由入口
HEALTH_DATA_GROUP_FILE = SETTINGS_DIR / "widgets" / "health_data_group.dart"
MORE_ENTRY_SHEET_FILE = HOME_DIR / "widgets" / "more_entry_sheet.dart"

# 主页不应直接跳转 medication/assessment (必须走 MoreEntryTrigger)
FORBIDDEN_IN_HOME_BUILD = re.compile(
    r"context\.push\(['\"](?:/medication|/assessment-center|/crisis-hotline|/worry)['\"]\)"
)

# PrimaryActionRow 不应包含 AppleHealthTile 4 个砖块 (旧 2x2 API)
FORBIDDEN_OLD_PRIMARY_ACTION_API = re.compile(
    r"onMedicationTap\s*:\s*onMedicationTap\s*\("
)

# PrimaryActionRow 接收的 callback 列表 (R115 新 API)
EXPECTED_PRIMARY_ACTION_CALLBACKS = {
    "onMoodReviewTap",
    "onDailyTrackingTap",
    "onTipsTap",
}

# PrimaryActionRow 不应再出现的 callback 列表 (旧 2x2 API)
FORBIDDEN_PRIMARY_ACTION_CALLBACKS = {
    "onMedicationTap",
    "onAssessmentTap",
}


def collect_violations() -> list[str]:
    """扫描 home/ 目录, 报告违反 R115 守门员规则的文件"""
    violations: list[str] = []

    # Rule 1: home_page_state.dart build 树不能直接 push 4 个二级入口路由
    state_file = HOME_DIR / "home_page_state.dart"
    if state_file.exists():
        text = state_file.read_text(encoding="utf-8")
        for m in FORBIDDEN_IN_HOME_BUILD.finditer(text):
            line = text[: m.start()].count("\n") + 1
            # 例外: 在 _handleDeepLink / auto-fire 场景允许 (通知点击跳药)
            # 修前: 仅 push('/medication') 在 build 树, 已移到 MoreEntrySheet
            context = _get_context(text, m.start(), m.end())
            if "context.push" in context and "build" not in context.split("class")[0]:
                # 通知 deep link autofire 是允许的 (R108 同款)
                if "handleDeepLink" in context or "autofire" in context:
                    continue
                violations.append(
                    f"{state_file.relative_to(REPO_ROOT)}:{line}  "
                    f"主页 build 树不应直接 push 二级入口路由, "
                    f"应走 MoreEntryTrigger → BottomSheet"
                )

    # Rule 2: primary_action_row.dart 不应再包含旧 2x2 砖块 API
    par_file = HOME_DIR / "widgets" / "primary_action_row.dart"
    if par_file.exists():
        text = par_file.read_text(encoding="utf-8")
        # 检旧 callback 名字
        for old in FORBIDDEN_PRIMARY_ACTION_CALLBACKS:
            if f"{old}:" in text or f"{old} " in text:
                # 提取行号
                idx = text.find(f"{old}:")
                if idx == -1:
                    idx = text.find(f"{old} ")
                if idx >= 0:
                    line = text[:idx].count("\n") + 1
                    violations.append(
                        f"{par_file.relative_to(REPO_ROOT)}:{line}  "
                        f"PrimaryActionRow 不应再使用 {old} 旧 callback "
                        f"(R115 改为 onMoodReviewTap / onDailyTrackingTap / onTipsTap)"
                    )
        # 检新 callback 完整 (3 个)
        for new_cb in EXPECTED_PRIMARY_ACTION_CALLBACKS:
            if f"required this.{new_cb}" not in text:
                violations.append(
                    f"{par_file.relative_to(REPO_ROOT)}  "
                    f"PrimaryActionRow 缺少 R115 新 callback {new_cb}"
                )

    # Rule 3: today_summary_card.dart 不应再读 medicationsProvider (用药已挪)
    tsc_file = HOME_DIR / "widgets" / "today_summary_card.dart"
    if tsc_file.exists():
        text = tsc_file.read_text(encoding="utf-8")
        if "medicationsProvider" in text:
            line = _find_line(text, "medicationsProvider")
            violations.append(
                f"{tsc_file.relative_to(REPO_ROOT)}:{line}  "
                f"TodaySummaryCard 不应再读 medicationsProvider "
                f"(R115 换血为 情绪 / 树洞 / 睡眠 / 烦恼, 跟用药脱钩)"
            )

    return violations


def _get_context(text: str, start: int, end: int) -> str:
    """提取匹配位置 ±200 字符上下文"""
    return text[max(0, start - 200) : min(len(text), end + 200)]


def _find_line(text: str, needle: str) -> int:
    idx = text.find(needle)
    if idx < 0:
        return 0
    return text[:idx].count("\n") + 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument(
        "--ci", action="store_true", help="CI mode: exit 1 on violations"
    )
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) 主页快捷操作守门员")
    print("=" * 60)
    print(f"扫描: {HOME_DIR.relative_to(REPO_ROOT)}")
    print(f"白名单: HealthDataGroup / MoreEntrySheet")
    print()

    violations = collect_violations()

    if violations:
        print(f"❌ 发现 {len(violations)} 处违规:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引 (R115 emotion-first):")
        print("  1. 主页 build 树不直接 push medication/assessment/crisis/worry")
        print("  2. 用 MoreEntryTrigger + showMoreEntrySheet() 走 BottomSheet")
        print("  3. PrimaryActionRow 改 3 行 list (onMoodReviewTap / onDailyTrackingTap / onTipsTap)")
        print("  4. TodaySummaryCard 不读 medicationsProvider")
        if args.ci:
            return 1
        return 1

    print("✅ 0 violation — 主页 emotion-first 入口约束保持")
    print()
    print("允许出现 medication/assessment 路由的位置:")
    print(f"  - {HEALTH_DATA_GROUP_FILE.relative_to(REPO_ROOT)} (健康数据 group 入口)")
    print(f"  - {MORE_ENTRY_SHEET_FILE.relative_to(REPO_ROOT)} (更多 BottomSheet)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
