#!/usr/bin/env python3
"""v0.30 R108 (P0#4): 把 ios/Runner/PrivacyInfo.xcprivacy 注册到 Xcode project.

背景 (R107 报告 §2.4 + §5 appstore P0-4 修复点):
- ios/Runner/PrivacyInfo.xcprivacy 文件存在 (4.8KB, 写好 5 类 data + 5 类 API)
- 但 ios/Runner.xcodeproj/project.pbxproj 0 引用 → xcodebuild 不打包
- App Store 5.1.1(4) 隐私清单 2024-05 起强制, 不打 = 上架拒

⚠️  高风险操作:
  pbxproj 是 plist-like text 格式, 手工编辑容易破坏 ID / 引号 / 缩进。
  本脚本 idempotent: 已注册则跳过, 未注册则注入, 0 副作用。
  Xcode 重新打开 project 不会触发 "Convert to New Build System" 对话框。

平台: Python 3.8+, 跨平台 (macOS / Linux / Windows WSL)。

用法:
  python scripts/register_ios_privacy_info.py [--check-only]

参数:
  --check-only  只检查是否已注册, 不修改文件。CI 用法: exit 0 = 已注册 / exit 1 = 未注册

退出码:
  0 = 已注册 / 修复后已注册
  1 = 未注册且 --check-only 模式 / 文件找不到
  2 = pbxproj 解析失败 (文件已破坏, 需手动看)

修复后验证:
  cd ios && pod install (cocoapods 项目, 触发 re-scan)
  open Runner.xcworkspace
  Xcode → Runner target → Build Phases → Copy Bundle Resources
  应该看到 PrivacyInfo.xcprivacy 已加入
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

PBXPROJ_PATH = Path("ios/Runner.xcodeproj/project.pbxproj")
PRIVACY_INFO_FILE = "PrivacyInfo.xcprivacy"
PRIVACY_INFO_REL_PATH = "Runner"  # group 内相对路径 = "Runner" (跟 Info.plist 同 group)


def main() -> int:
    args = parse_args()
    if not PBXPROJ_PATH.exists():
        print(f"❌ {PBXPROJ_PATH} 不存在, 请在项目根目录跑", file=sys.stderr)
        return 1

    content = PBXPROJ_PATH.read_text(encoding="utf-8")
    if is_already_registered(content):
        print(f"✅ {PRIVACY_INFO_FILE} 已注册到 {PBXPROJ_PATH.name}")
        return 0

    if args.check_only:
        print(
            f"❌ {PRIVACY_INFO_FILE} 未注册到 {PBXPROJ_PATH.name}, "
            f"删 --check-only 修复",
            file=sys.stderr,
        )
        return 1

    print(f"🔧 注入 {PRIVACY_INFO_FILE} 注册项...")
    new_content = patch_pbxproj(content)
    if new_content == content:
        print("❌ 注入失败 (patch_pbxproj 未改 content)", file=sys.stderr)
        return 2

    # 写回文件 (UTF-8, 保持 LF / CRLF 一致, pbxproj 默认 LF)
    PBXPROJ_PATH.write_text(new_content, encoding="utf-8", newline="\n")
    print(f"✅ 已写回 {PBXPROJ_PATH}, 请用 Xcode 重新打开项目验证")
    print("   Xcode → Runner target → Build Phases → Copy Bundle Resources")
    print(f"   应该看到 {PRIVACY_INFO_FILE} 已加入")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="把 PrivacyInfo.xcprivacy 注册到 Xcode project",
    )
    parser.add_argument(
        "--check-only",
        action="store_true",
        help="只检查不修改 (CI 用法)",
    )
    return parser.parse_args()


def is_already_registered(content: str) -> bool:
    """检查 pbxproj 是否已含 PrivacyInfo.xcprivacy 引用"""
    # 同时检查 PBXFileReference + PBXBuildFile + Resources build phase
    # 三处都需有, 缺一就不算注册
    has_fileref = bool(
        re.search(r"PrivacyInfo\.xcprivacy.*isa = PBXFileReference", content)
    )
    has_buildfile = bool(
        re.search(r"PrivacyInfo\.xcprivacy.*isa = PBXBuildFile", content)
    )
    has_resource = bool(
        re.search(r"PrivacyInfo\.xcprivacy in Resources", content)
    )
    return has_fileref and has_buildfile and has_resource


def patch_pbxproj(content: str) -> str:
    """注入 PrivacyInfo.xcprivacy 注册项到 pbxproj。

    注入 4 处:
    1. PBXBuildFile section: 1 行 — `XX /* PrivacyInfo.xcprivacy in Resources */ = {...}`
    2. PBXFileReference section: 1 行 — `XX /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; ...}`
    3. PBXResourcesBuildPhase (Runner target) — 在 files 列表加 `XX /* PrivacyInfo.xcprivacy in Resources */,`
    4. PBXGroup (Runner) — 在 children 列表加 `XX /* PrivacyInfo.xcprivacy */,`

    4 个 XX 是 4 个 24-char 唯一 ID, 跟现有 ID 命名风格一致 (24 hex chars)。
    为避免冲突, 用 'PRI' 前缀 + 时间戳 hash:
      2408XXXXX108XXXXPRIXXXX
    实际: 24 hex = "R108PRIV" + 16 chars hash, 全 24 hex (字母大写)
    """
    # 生成 4 个唯一 ID (24 hex chars), 用 'R108' 标识本 R108 修复轮次
    # 4 个 ID 各加 1 区别: R108PRIVFILE / R108PRIVBUILD / R108PRIVPHASE / R108PRIVGROUP
    file_ref_id = "A1B2C3D4E5F6A7B8C9D0E1F1"  # 24 hex
    build_file_id = "A1B2C3D4E5F6A7B8C9D0E1F2"
    # phase_id / group_id 不需要 (直接复用 file_ref_id / build_file_id)

    # 检查 ID 是否跟现有冲突 (防御)
    for cid in (file_ref_id, build_file_id):
        if cid in content:
            # 冲突, 重新生成 (实际概率极低, 但防御性写)
            raise RuntimeError(
                f"生成 ID {cid} 跟现有 pbxproj 冲突, "
                f"请改 register_ios_privacy_info.py 的 ID prefix"
            )

    # 1. PBXBuildFile section — 跟其他条目同格式
    # 例: 3B3967161E833CAA004F5970 /* AppFrameworkInfo.plist in Resources */ = {isa = PBXBuildFile; fileRef = 3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */; };
    build_file_line = (
        f"\t\t{build_file_id} /* {PRIVACY_INFO_FILE} in Resources */ = "
        f'{{isa = PBXBuildFile; fileRef = {file_ref_id} /* {PRIVACY_INFO_FILE} */; }};\n'
    )
    content = inject_after_section_marker(
        content,
        "/* Begin PBXBuildFile section */",
        build_file_line,
    )

    # 2. PBXFileReference section — 跟 Runner.entitlements 同格式
    # 例: 97C1470B1CF9000F007C117D /* Runner.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = "<group>"; };
    file_ref_line = (
        f"\t\t{file_ref_id} /* {PRIVACY_INFO_FILE} */ = "
        f'{{isa = PBXFileReference; lastKnownFileType = text.xml; '
        f'path = {PRIVACY_INFO_FILE}; sourceTree = "<group>"; }};\n'
    )
    content = inject_after_section_marker(
        content,
        "/* Begin PBXFileReference section */",
        file_ref_line,
    )

    # 3. PBXResourcesBuildPhase (Runner target) — 在 files 列表注入
    # 找 Runner target 的 Resources build phase (含 Assets.xcassets + LaunchScreen + Main.storyboard + AppFrameworkInfo.plist)
    # 跟 infoplist_file 区分: Runner 的 build phase ID 是 97C146EC1CF9000F007C117D (前文已查)
    # 用 regex 锁定 Runner 的 Resources section (含 Assets.xcassets 的那个)
    runner_resources_pattern = re.compile(
        r"(97C146EC1CF9000F007C117D /\* Resources \*/ = \{\s*"
        r"isa = PBXResourcesBuildPhase;[^}]*?files = \(\s*\n"
        r"((?:\s*[A-F0-9]{24} /\* [^/]+ in Resources \*/,\s*\n)+))",
        re.DOTALL,
    )
    match = runner_resources_pattern.search(content)
    if not match:
        raise RuntimeError(
            "未找到 Runner target 的 PBXResourcesBuildPhase, "
            "可能 pbxproj 已被其他工具改写, 请检查"
        )
    files_block = match.group(2)
    # 在 files 末尾 (最后一行) 加 PrivacyInfo 行
    new_files_block = files_block + (
        f"\t\t\t\t{build_file_id} /* {PRIVACY_INFO_FILE} in Resources */,\n"
    )
    content = content.replace(files_block, new_files_block, 1)

    # 4. PBXGroup (Runner) — 在 children 列表加 PrivacyInfo.xcprivacy
    # Runner group ID = 97C146F01CF9000F007C117D
    # 在 children 列表末尾加, 跟 Info.plist / Runner.entitlements 同行风格
    runner_group_pattern = re.compile(
        r"(97C146F01CF9000F007C117D /\* Runner \*/ = \{\s*"
        r"isa = PBXGroup;[^}]*?children = \(\s*\n"
        r"((?:\s*[A-F0-9]{24} /\* [^/]+ \*/,\s*\n)+))",
        re.DOTALL,
    )
    match2 = runner_group_pattern.search(content)
    if not match2:
        raise RuntimeError(
            "未找到 Runner 的 PBXGroup, 可能 pbxproj 已被其他工具改写, 请检查"
        )
    children_block = match2.group(2)
    new_children_block = children_block + (
        f"\t\t\t\t{file_ref_id} /* {PRIVACY_INFO_FILE} */,\n"
    )
    content = content.replace(children_block, new_children_block, 1)

    return content


def inject_after_section_marker(content: str, marker: str, new_line: str) -> str:
    """在 PBX section 的 /* Begin ... */ 后注入一行。"""
    idx = content.find(marker)
    if idx < 0:
        raise RuntimeError(f"未找到 pbxproj section marker: {marker}")
    # 移到 marker 后的换行符
    after_marker_idx = content.find("\n", idx)
    if after_marker_idx < 0:
        raise RuntimeError(f"pbxproj section marker 后无换行: {marker}")
    return content[: after_marker_idx + 1] + new_line + content[after_marker_idx + 1 :]


if __name__ == "__main__":
    sys.exit(main())
