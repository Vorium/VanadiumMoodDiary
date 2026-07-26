#!/usr/bin/env python3
"""B-06 AppSnackBar 集中器冲刺 v3 — 用括号计数处理多行

策略: 找到 'ScaffoldMessenger.of(context).showSnackBar(' 起点, 括号计数
找到匹配的 ')', 然后看是不是 AppSnackBar.xxx(...) 包起来的。
"""
import os

count_total = 0
files_done = []

for root, dirs, names in os.walk('lib'):
    if 'app_snack_bar.dart' in root:
        continue
    for n in names:
        if not n.endswith('.dart'):
            continue
        fp = os.path.join(root, n)
        with open(fp, 'rb') as f:
            text = f.read().decode('utf-8')

        out = []
        i = 0
        n_subs = 0
        prefix = 'ScaffoldMessenger.of(context).showSnackBar('
        while i < len(text):
            idx = text.find(prefix, i)
            if idx < 0:
                out.append(text[i:])
                break
            # 起点找到, 复制前缀前的部分
            out.append(text[i:idx])
            # 找匹配的 ')'
            j = idx + len(prefix)
            depth = 1
            in_string = None
            while j < len(text) and depth > 0:
                c = text[j]
                if in_string:
                    if c == '\\':
                        j += 2
                        continue
                    if c == in_string:
                        in_string = None
                else:
                    if c in '"\'':
                        in_string = c
                    elif c == '(':
                        depth += 1
                    elif c == ')':
                        depth -= 1
                j += 1
            # j 指向匹配的 ')' 之后的位置
            # 内容: text[idx+len(prefix):j-1] 是 showSnackBar 的参数
            inner = text[idx + len(prefix):j - 1].strip()
            # inner 应该是 "AppSnackBar.<method>(context, ...)"
            # 检查是不是 AppSnackBar 开头
            for method in ('error', 'info', 'undo', 'withAction'):
                app_prefix = f'AppSnackBar.{method}('
                if inner.startswith(app_prefix):
                    # 找 AppSnackBar.xxx 内部匹配的 ')'
                    k = len(app_prefix)
                    inner_depth = 1
                    inner_in_string = None
                    inner_start = k
                    while k < len(inner) and inner_depth > 0:
                        cc = inner[k]
                        if inner_in_string:
                            if cc == '\\':
                                k += 2
                                continue
                            if cc == inner_in_string:
                                inner_in_string = None
                        else:
                            if cc in '"\'':
                                inner_in_string = cc
                            elif cc == '(':
                                inner_depth += 1
                            elif cc == ')':
                                inner_depth -= 1
                        k += 1
                    # inner[inner_start:k-1] 是 AppSnackBar.xxx 的内容
                    app_args = inner[inner_start:k - 1].rstrip(',').rstrip()
                    # 替换: AppSnackBar.show<Method>(args)
                    if method == 'withAction':
                        show_method = 'showWithAction'
                    else:
                        show_method = 'show' + method[0].upper() + method[1:]
                    replacement = f'AppSnackBar.{show_method}({app_args})'
                    out.append(replacement)
                    n_subs += 1
                    i = j  # 跳过原始 ScaffoldMessenger.of...showSnackBar(...)
                    break
            else:
                # 不是 AppSnackBar 包起来, 保留原文
                out.append(text[idx:j])
                i = j

        if n_subs > 0:
            new_text = ''.join(out)
            with open(fp, 'wb') as f:
                f.write(new_text.encode('utf-8'))
            count_total += n_subs
            files_done.append((fp, n_subs))

for fp, n in files_done:
    print(f'updated {fp}: {n} substitutions')
print(f'TOTAL: {count_total} replacements')
