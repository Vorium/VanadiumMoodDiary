# 汇总 subagent prompt（待 9 份报告完成后 dispatch）

## 任务
你是 **汇总审计员**，负责读 9 份 subagent 报告，整合输出"从 0 重新出"的总报告。

## 输入
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\01-emil.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\02-spen.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\03-spzh.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\04-flutter-spec.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\05-appstore.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\06-googleplay.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\07-apple-health.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\08-architecture.md`
- `D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\09-bottom-up-bugs.md`

## 输出
`D:\Batch\chroniccare\docs\audit\2026-08-10-cleanup\00-summary.md`（15-30KB）

## 报告格式

### 一、6+2 视角评分总览
- 表格：视角 / 评分 / 跟 R105 对比 / 主要扣分

### 二、用户要求 5 项核心结论
1. **外部链接是否已全部隐藏**（运行时代码 + 注释 + 文档）
2. **上架 / 架构 / 重构 / 半成品 4 大类问题**
3. **顶层架构审视（高内聚低耦合）**：建议
4. **底层逐行排查**：bug 清单
5. **文档更新建议**：README / CHANGELOG / AGENTS / VERSION_1.0_PLAN / DEPLOYMENT

### 三、跨视角问题合并去重
- 7 视角重复提到的问题（高优先级）
- 单视角独有问题
- 列出每条：文件:行 / 视角来源 / 层级 / 难度 / 优先级

### 四、问题清单（按"修复优先级"排序）
| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 视角来源 | 修复建议 |
|---|---------|------|------|------|--------|----------|----------|

### 五、按"修复难度"分类
- 简单（1-4h）：token 化 / 硬编码 → ARB / 缺失 icon / 等
- 中（1-2 天）：god class 拆 / provider 重构 / feature flag 翻转
- 难（1-2 周）：大架构重构 / 真实业务接入 / 上架物料
- 极高（1-2 月）：法务审核 / 临床审核 / NMPA 备案

### 六、按"层级"分类
- 架构层：模块边界 / 依赖方向 / 抽象泄漏 / 循环依赖
- 底层：硬编码 / token 化 / 半成品 / 资源泄漏 / 类型漏洞
- i18n：硬编码中文 / zh_Hant 漏译 / 全角标点
- 合规：PIPL / HIPAA / GDPR / 隐私
- UI/UX：动效 / a11y / 视觉层级
- 上架：截图 / 描述 / 签名 / 域名 / 法务

### 七、外部链接确认
- 运行时：✅ 0 外部链接
- 注释 / doc：3 处（holidayapi / 阿里云 SMS），均为说明性
- 物料层：⚠️ chroniccare.app 域名未注册
- 邮箱：privacy@/support@ 未注册

### 八、半成品 / 8 FeatureFlag 守门
- iapEnabled / emergencyContactEnabled / fiveVendorPushEnabled / emailServiceEnabled / ventAudioEnabled / phqGad7I18nEnabled / bootReceiverEnabled / aliyunSmsEnabled
- 状态 / 真接所需资源 / 预计工时

### 九、上架 blocker 清单
按平台分类（iOS / Android / 通用），按 P0/P1/P2 排序

### 十、架构改进建议（高内聚低耦合）
- 维持 + 拆 god class（短期）
- feature-first 重构（中期）
- Workspace 拆分（长期）

### 十一、文档更新建议
- README.md（顶部 stale，需更新到 R105）
- CHANGELOG.md（缺 R101-R105 entries）
- AGENTS.md（17 守门员清单 + 1951→2019 tests 数据 stale）
- VERSION_1.0_PLAN.md（已 R105 完整但可加 R106）
- DEPLOYMENT.md（待 check）

### 十二、下一步建议
按 ROI 排序的修复路线图
