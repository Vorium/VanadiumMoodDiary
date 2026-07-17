# v0.17 round 8 失败脚本

> 这些脚本是 v0.17 round 8 feature-first 重构期间尝试的 1/2/3 层相对路径 → package: 绝对路径转换工具。
> 当时跑通后导致 717 个 import 解析错误，working tree 不得不 reset 回 HEAD。
> 原因：脚本只处理 1/2/3 层相对路径，没意识到 round 8a 后 8 个共享层移到 `lib/core/`，很多 `'../presentation/...'` 实际深度变成 `'../../presentation/...'`，但脚本"按字面"翻译，路径指向不存在的 `lib/core/presentation/...`。

**最终方案**：重写完整脚本 `8a2_rewrite_to_absolute.py`，基于"OS 路径解析 + package: 转换"，理论上 100% 正确。但实际仍未 commit（feature-first 重构整体未完成）。

**目前状态**：feature-first 重构进程到一半中止，working tree 回到 4 层架构干净状态。下一轮（v0.17 round 9）重新做 feature-first 切分时，可以参考 `8a2_rewrite_to_absolute.py` 的"OS 路径解析"思路，但建议：

1. **完全用 package: 绝对路径**，不混相对路径
2. 先把所有 import 重置为 `package:chroniccare/...` 形式（git grep 检查）
3. 然后 `git mv` 目录，再用脚本批量改路径

不要直接运行这两个脚本 — 它们会破坏 8a 之前的 1/2/3 层相对路径。
