"""check_widget_dispose.py — Widget 资源 dispose 守门员

防 v0.16 round 19/19B 资源泄漏 / StreamSubscription leak 回归:
- `addListener` 没 `removeListener` (setState after defunct)
- `Stream.listen` 返 StreamSubscription 没存字段也没 cancel
- `Timer` 没 `cancel()`
- `addPostFrameCallback` 在 unmounted widget 还触发

策略 (启发式):
1. 找 `StatefulWidget` 子类的 dispose() 方法
2. 找 `_xxx.dispose()` 调用 (e.g. AnimationController / TextEditingController / StreamController)
3. 找 `xxx.cancel()` 调用 (StreamSubscription / Timer)
4. 找 `removeListener` / `removePostFrameCallback` 调用
5. 粗略检查: 整个 class 至少有 1 个资源释放动作,否则警告

注意: 这是启发式检查,不能 100% 准确,但能抓 80% 常见反模式。

用法:
  python scripts/check_widget_dispose.py            # 全检
  python scripts/check_widget_dispose.py --ci       # CI 模式
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.getcwd()) / "lib"

# 资源释放关键字
DISPOSE_KEYWORDS = [
    r'\.dispose\(\)',  # AnimationController / TextEditingController / StreamController / AudioPlayer
    r'\.cancel\(\)',  # StreamSubscription / Timer / Ticker
    r'removeListener',  # Listenable
    r'removePostFrameCallback',  # WidgetsBinding
    r'unsubscribe',  # custom
    r'disposeStream',  # custom (项目用)
]


def scan_file(path: Path):
    """扫描 StatefulWidget 的 dispose() 方法是否释放资源"""
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        return []

    # 找所有 class extends StatefulWidget / ConsumerStatefulWidget
    # 用粗略 regex: class XxxState extends State 或 ConsumerState
    class_pattern = re.compile(
        r'class\s+(\w+State)\s+extends\s+(?:Consumer)?State<(\w+)>',
        re.MULTILINE,
    )
    dispose_pattern = re.compile(
        r'@override\s+void\s+dispose\(\)\s*\{([^}]*)\}',
        re.DOTALL,
    )

    hits = []
    for class_match in class_pattern.finditer(text):
        class_name = class_match.group(1)
        widget_name = class_match.group(2)
        class_start = class_match.end()

        # 找下一个 class 开头 (粗略)
        next_class = re.search(r'^class\s+\w+', text[class_start:], re.MULTILINE)
        class_end = class_start + next_class.start() if next_class else len(text)
        class_body = text[class_start:class_end]

        # 找 dispose() 方法
        disp_m = dispose_pattern.search(class_body)
        if not disp_m:
            # 没有 override dispose() — 如果类里有 _controller / _subscription 字段但没 dispose → 警告
            has_resource = bool(re.search(
                r'(?:late\s+)?(?:final\s+)?(?:\w+Controller|StreamSubscription|_controller|_sub|_timer)\s+\w+',
                class_body,
            ))
            if has_resource:
                rel = path.relative_to(ROOT.parent).as_posix()
                hits.append((0, class_name, widget_name, "有资源字段但无 dispose() 方法"))
            continue

        dispose_body = disp_m.group(1)
        # 检查 dispose() 体内是否有释放动作
        has_release = any(re.search(kw, dispose_body) for kw in DISPOSE_KEYWORDS)

        if not has_release:
            # dispose() 是空 / 只有 super.dispose()
            has_super_only = bool(re.search(r'super\.dispose\(\)', dispose_body))
            if has_super_only and not re.search(r'late\s+\w+\s+\w+\s*=', class_body):
                # 只有 super.dispose() 且没 late field — 正常
                continue
            rel = path.relative_to(ROOT.parent).as_posix()
            hits.append((0, class_name, widget_name, "dispose() 体内无资源释放动作"))

    return hits


def main():
    ci_mode = '--ci' in sys.argv

    files = sorted(ROOT.rglob('*.dart'))
    # 跳过生成文件
    files = [f for f in files if '.g.dart' not in f.name and '.freezed.dart' not in f.name]

    total = 0
    for f in files:
        hits = scan_file(f)
        if not hits:
            continue
        rel = f.relative_to(ROOT.parent)
        for line_no, class_name, widget_name, reason in hits:
            print(f"  {rel}:{line_no}  {class_name} (widget={widget_name}): {reason}")
            total += 1

    if total == 0:
        print('[OK] check_widget_dispose: 0 资源泄漏风险')
        return 0

    print(f'[WARN] check_widget_dispose: {total} 潜在资源泄漏 (启发式检查,需人工 review)')
    print('  修法: addListener → removeListener / Stream.listen 存字段 .cancel() / Timer.cancel() / AnimationController.dispose()')
    return 1


if __name__ == '__main__':
    sys.exit(main())
