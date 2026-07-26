#!/usr/bin/env python3
"""Dry-run: show what would change without writing"""
import sys
import re

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

FIXES = {
    31: "/// 路由切换动画辅助函数（v0.17 round 2 / A2 emil 动效）",
    33: "/// 频度决策（emil 决策框架）：",
    34: "/// - 主导航（/, /settings）→ 偶尔切 → 简单 fade",
    35: "/// - 子页（/trend, /assessment/*, /settings/reminders）→ occasional → slide-from-right",
    36: "/// - 全屏深页（/setup, /vent/*）→ rare → slide-up + fade（full-screen modal 感）",
    38: "/// v0.21 Round 22 (P1-13 修复): helper 接收 BuildContext 用于",
    39: "/// 尊重 prefers-reduced-motion (Motion.duration 类)",
    96: "/// 路由 Provider",
    98: "  // 监听用户档案，判断是否已设置",
    121: "      // 整个 app shell：宽屏带 NavigationRail，窄屏纯 body",
    128: "          // 主导航：occasional 频度 → fade",
    145: "          // v0.14 (Round 12C) 提醒中心",
    151: "          // v0.14 (Round 13A) 续方管理",
    172: "          // v0.14 (Round 13B) 评估历史独立页",
    187: "          // v0.14 (Round 13C) 用药日历（医生视角热力图）",
    217: "          // ============== Round 5: Deep Linking 路由 ==============",
    218: "          // 点 medication 通知 → 直接跳 home 并自动打卡该药",
    219: "          // 不经过 3 步首页流程（参考 HealthReminder）",
    242: "      // v0.21 (P2-2 fix): 之前 error page 只有一个 Text, 用户卡住没有出口",
    243: "      // emil UX 原则: error 出现 = 用户卡住, 必须给明确出口 (icon + hint + 引导按钮)",
    290: "/// - 窄屏（< 840）：只显示 child（页面），无侧栏",
    324: "      // /email-preview 算设置子页",
    339: "          // 窄屏：去掉各页面自己的 AppBar（shell 不管），child 自行处理",
    366: "                            '慢病管家',",
}

path = r'D:\Batch\chroniccare\lib\core\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for ln, correct in FIXES.items():
    idx = ln - 1
    old = lines[idx].rstrip('\n')
    new = correct
    diff = "(no change)" if old == new else "WILL CHANGE"
    print(f"L{ln}: {diff}")
    if old != new:
        print(f"  OLD: {old}")
        print(f"  NEW: {new}")
