"""P1-16 后续: 修复 dart format 在 Windows CRLF 上的 strip bug

bug: 跑 `dart format` + 之前 commit `chore: dart fix + format 修 28 个
trailing comma` (07b748b) 时,Windows 上某些 dart format 版本会
把多行 .dart 文件 strip 成 1 行。所有换行被吃,analyzer 看不到
class 定义 → 编译失败。

修法: 对每个 .dart 文件,检查 working tree 是否 0 换行(被 strip);
如果是,从 git HEAD 拿对应文件覆盖回去。git 是 source of truth。
"""
import os
import subprocess
import sys


def is_stripped(path: str) -> bool:
    """检查文件是否 0 换行(被 dart format strip)"""
    with open(path, "rb") as f:
        content = f.read()
    if not content:
        return False
    return b"\n" not in content and b"\r" not in content


def get_git_file(commit: str, path: str) -> bytes | None:
    """从 git 拿指定 commit 的指定文件内容"""
    try:
        result = subprocess.run(
            ["git", "show", f"{commit}:{path}"],
            capture_output=True,
            cwd=os.getcwd(),
            check=True,
        )
        return result.stdout
    except subprocess.CalledProcessError:
        return None


def fix_file(path: str, commit: str) -> bool:
    """从 git 恢复 strip 了的文件"""
    if not is_stripped(path):
        return False
    content = get_git_file(commit, path)
    if content is None:
        print(f"  [SKIP] {path} not in git {commit}")
        return False
    # 检查 git 版本也是 0 换行(strip 也发生在 commit 里)→ 跳过
    if b"\n" not in content and b"\r" not in content:
        print(f"  [SKIP] {path} git version also 0 newlines")
        return False
    with open(path, "wb") as f:
        f.write(content)
    return True


def main() -> int:
    # 用 HEAD 作为 git source of truth
    commit = "HEAD"
    # 收集所有 .dart 文件
    dart_files = []
    for root in ["lib", "test", "scripts"]:
        if not os.path.isdir(root):
            continue
        for dirpath, dirnames, filenames in os.walk(root):
            for f in filenames:
                if f.endswith(".dart"):
                    dart_files.append(os.path.join(dirpath, f))

    print(f"Scanning {len(dart_files)} .dart files...")
    fixed = 0
    skipped = 0
    for path in dart_files:
        if is_stripped(path):
            if fix_file(path, commit):
                fixed += 1
            else:
                skipped += 1
    print(f"Done. Fixed: {fixed}, Skipped (already correct or git also broken): {skipped}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
