# Pull Request

> **v0.27 round 82 (上架冲刺批次 A)**
> 上 PR 前 5 段 checklist 必过。

## 1. 命名 / 实体

- [ ] domain entity 用 `*Entity` 后缀(避免和 drift `@DataClassName('X')` 冲突)
- [ ] drift 表的 `@DataClassName` 用单数,domain 实体叫 `XEntity`
- [ ] abstract repo: `lib/domain/repositories/*_repository.dart`(无后缀)
- [ ] repo impl: `lib/core/data/repositories/*/*_repository_impl.dart`
- [ ] provider: `xRepositoryProvider` 暴露 abstract 接口

## 2. 测试

- [ ] 1 个测试文件对应 1 个 round,命名 `{module}_{roundN}_test.dart`
- [ ] 0 单测覆盖的 P0 关键路径?(lost_contact_sms / consent_artifact / safety_config_service / store_kit_service / data_export + 5 子服务)
- [ ] `flutter test` 全过
- [ ] 跨 midnight / 时序 / 边界 case 有 regression test

## 3. 资源 / 异步

- [ ] Stream subscription 在 `dispose()` 调 `.cancel()`
- [ ] 临时 acquire 资源(AudioPlayer / Recorder / file handle)用 `try { use } catch (_) {} finally { release }`
- [ ] BuildContext 跨 async gap 用 `if (!mounted) return;` 或 `final ctx = context;`
- [ ] `DateTime.now()` 在函数入口取 1 次,下面复用(防 race)

## 4. 架构 / 合规

- [ ] domain 不 import `package:flutter/` / `package:drift/` / `package:chroniccare/l10n/` / `package:flutter_riverpod/` / `package:go_router/`
- [ ] presentation 不 import `presentation/pages/{其他 feature}/`(除 home / settings hub)
- [ ] `dart scripts/check_all.dart` 0 violation
- [ ] `python scripts/check_cross_feature.py` 0 violation
- [ ] PIPL §13 单独同意(联系人 / 数据导出 / 失联通知)有 `ConsentArtifact` 留痕
- [ ] `swallowError(where: ..., error: ..., note: ...)` 替代 `catch (e) { }`(PII 安全日志)

## 5. 可读性 / 规范

- [ ] `dart format` + `dart fix --apply` 跑过
- [ ] 0 analyzer error / 0 warning(info-level 可)
- [ ] hardcode 颜色 / 字体 / 间距 → 走 `AppTokens` / `AppColors` / `AppMotion` 集中器
- [ ] 中文文案走 l10n key,3 个 ARB(zh / en / zh_Hant)同步
- [ ] `commit message` 格式 `<version> round <N>: <title>`(豁免 Conventional Commits)
- [ ] 半成品 / TODO 标 owner + 估时(不要 silently 留)

## 6. 上架 / 部署(如改到)

- [ ] iOS / Android 上架元数据 0 占位(截图 / URL / Appfile)
- [ ] Data Safety Form 跟代码实际数据收集一致
- [ ] keystore / signingConfig / Podfile 已就绪
- [ ] 隐私 / 支持 URL 真实可访问(`https://chroniccare.app/*`)
- [ ] 国产 ROM 自检卡 + 自启动引导文案就位

---

> PR 提交前必跑:
> ```bash
> flutter analyze
> flutter test
> dart scripts/check_all.dart
> python scripts/check_cross_feature.py
> python scripts/check_zh_hant_consistency.py
> python scripts/check_orphan_arb_keys.py
> ```
