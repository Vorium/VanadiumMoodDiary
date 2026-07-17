# Git Workflow (v0.17 round 14 / P3-2)

> 项目用单 branch (master) + 多 round commit。不走 PR / fork / gitflow,因为单 dev。

## 日常工作流

```bash
# 1. 写代码 (改 lib/, test/)
# 2. 跑验证
echo "PLACEHOLDER=test" > .env  # 如果 .env 不存在 (gitignored)
flutter analyze                   # 必须 0 issues
flutter test                      # 必须全过
python scripts/check_cross_feature.py --ci  # 必须 0 violations

# 3. 跑代码生成 (如果改了 drift 表)
dart run build_runner build --delete-conflicting-outputs

# 4. 跑架构检查 (改了跨层 import 才需要)
dart scripts/check_all.dart  # 或 python scripts/check_cross_feature.py

# 5. 写 commit
git add <files>
git commit -m "<see CHINESE_COMMIT_GUIDE.md>"

# 6. 验证 commit 后没漏
git log --oneline -5
git status  # 应该 clean
```

## Round 节奏

每 5-10 commit = 1 个 round (1 个 round 通常 1 个 feature):

```
v0.17 round 13: P0 review fixes
v0.17 round 14: P1-3 split core_providers into 3 files
v0.17 round 14: P1-1 extract animations/ subdir (FadeIn + SlideUp)
...
```

每个 round:
1. **Domain** (新 entity + abstract repo)
2. **Data** (drift 表 + mapper + repo impl + schemaVersion migration + build_runner)
3. **Presentation** (page + provider + router)
4. **Tests** (flutter analyze + test + check_cross_feature)
5. **Commit** (单 commit, 或拆 2-3 个按 what/why 维度)

## 改错怎么办

```bash
# 改漏了一个 file
git add <forgotten-file>
git commit --amend --no-edit  # 追加到上一个 commit

# 上一个 commit message 写错
git commit --amend  # 编辑 message, 不改内容

# 上一个 commit 内容错
# 1) reset HEAD~1 (soft, 保留 working tree)
git reset --soft HEAD~1
# 2) 重新 stage + commit
git add -A
git commit -m "<new message>"

# 误删 tracked 文件
git rm <file>  # 显式删 + stage
git commit -m "remove <file>"

# 误删 untracked 文件 (没 stage 过)
git clean -fd  # 看 scripts/_*.py 历史的 recover 技巧
```

## Branch 策略

**单 master, 不开 feature branch**。原因:
- 单 dev, 没 code review 摩擦
- Round 之间经常回退 / 重写 (e.g. round 8 失败 → round 8a redo)
- Round 14 的 12 个 commit 都在 master 串行, 互相 build on top

**例外**: 大型实验 (e.g. feature-first refactor 失败回退) 临时用 `git stash` 而非 branch。

## Tag / Release

- 每个 minor version (0.17.0) 在最后一个 round 后打 tag
- Tag 触发 build pipeline (当前 CI 还没接 release)

```bash
git tag -a v0.17.0 -m "v0.17.0 release"
git push origin v0.17.0
```

## 已知坑

- **CRLF vs LF**: Windows 项目是 CRLF, git 自动转换 (`core.autocrlf=true`)。 `warning: LF will be replaced by CRLF` 是无害提示, 不用管。
- **`.env`** 在 `.gitignore`。本地开发前必须先 `echo "PLACEHOLDER=test" > .env`,否则 `flutter test` 找不到 key 报错。
- **`__pycache__/`** 之前漏 ignore, round 14 P1-4 加进 `.gitignore`。
- **大文件**: audio 文件在 `app docs/vent_audio/`, 不会进 git。但 SQLCipher 加密的 DB 在 app docs, 也不会。

## 参考

- `CHINESE_COMMIT_GUIDE.md` — commit message 格式
- `AGENTS.md` — 项目结构 + 命令清单
- `docs/CHANGELOG.md` — 已发布 round 的清单
- `docs/WHITEPAPER.md` § 18 — 决策 + commit hash 索引
