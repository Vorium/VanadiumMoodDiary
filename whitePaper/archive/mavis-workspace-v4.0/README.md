# Mavis Workspace v4.0 — 归档说明

> **归档时间**: 2026-07-20 (目录时间戳)
> **归档状态**: ⚠️ **已删除** — 仅保留目录骨架作为历史引用
> **位置**: `whitePaper/archive/mavis-workspace-v4.0/`

## 背景

本目录原是 "mavis workspace v4.0" 文档归档区, 包含 v4.0 版本的设计 / 规划 /
评审文档, 用于跨期参考。

## 现状

- **目录已删除 + commit** (2026-08-18), 文件 0
- 完整 v4.0 内容保留在 `whitePaper/archive/v4.1-v1.0-team-package-2026-07-17.tar.gz` (46KB tar.gz)
- 团队白皮书归档在 `whitePaper/archive/team-whitepaper/` (空目录)

## 恢复方法

```bash
# 从 tar.gz 提取
tar -xzf whitePaper/archive/v4.1-v1.0-team-package-2026-07-17.tar.gz

# 从 git history 恢复
git log --all --diff-filter=D --summary | grep mavis-workspace-v4.0
git checkout <commit-hash>~1 -- whitePaper/archive/mavis-workspace-v4.0/
```

## 替代参考

- 团队包: `whitePaper/archive/v4.1-v1.0-team-package-2026-07-17.tar.gz`
- 团队白皮书: `whitePaper/archive/team-whitepaper/`
- 当前白皮书: `whitePaper/慢病管家-白皮书-v3.0.md`

## 维护者

- 文档主理: 主 agent