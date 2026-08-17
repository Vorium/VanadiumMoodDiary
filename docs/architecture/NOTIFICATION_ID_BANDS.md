# Notification ID Band Layout

> 1.1.0 round 12k (R120 P1-2 god class split) — extracted from
> `lib/core/data/services/notification_service.dart` (was 40L inline
> comment lines 342-360) into this standalone doc. Class now only
> references this file with a 1-line `// 详见 docs/architecture/NOTIFICATION_ID_BANDS.md`.

## 6 类 ID 范围常量 (v0.16 round 19 文档化)

| ID 范围 | 用途 | 拥有者 | Cancel 范围 |
|---|---|---|---|
| `1001` | defaultReminderId (fallback) | MedicationNotifier | n/a (单 id) |
| `2000-201999` | medication reminder (medId*10 + slotIndex) | MedicationNotifier | `[2000, 202000)` |
| `2500000-2699999` | refill reminder (R114 B1-3 迁出) | RefillNotifier | `[2500000, 2700000)` |
| `300000-2299999` | snooze (300000 base + 2000000 range) | SnoozeManager | `[300000, 2300000)` |
| `5000001` | assessment reminder (v0.32 R110 B1-1 固定带) | AssessmentNotifier | n/a (单 id) |
| `5000002` | mood reminder (v0.32 R110 B1-1 固定带) | MoodReminderNotifier | n/a (单 id) |
| `5000100` | badge virtual id (v0.32 R110 B1-1 固定带) | BadgeSyncService | n/a (单 id) |
| `5000000` | ~~safety alert~~ (1.1.0 round 4b 整摘) | n/a | n/a |

## 顺序保证

固定带 (5,000,001+) ≥ snooze cancel 上界 (2,300,000), 远超所有 cancel 上界 → 不会被静默误杀。

## 关键历史决策

- **R114 B1-3**: refill id 从 `6000` 段迁出到 `2500000` 段。
  - **修前 bug**: refill cancel `[6000, 206000)` 与 medication cancel `[2000, 202000)` 互杀
    — 单侧 reschedule 静默杀另一类。`notification_id_band_round110_test.dart` 回归。
  - **修后**: refill 在 2.5M+ 段, 跟 med / snooze 都不重叠, 老 `6000` 段 id 由 refill 侧精确清理。
- **v0.32 R110 B1-1**: assessment/mood/badge 固定带 5M+。
  - **修前 bug**: 原 5000/7000/8000/9999 落入 snooze cancel 区间 `[300000, 2300000)` 之外的 refill cancel 区间被静默误杀。
  - **修后**: 全部迁到 5M+ 固定带, 回归测试 `notification_id_band_round110`。

## defaultReminderId 1001 安全性

`1001` < med cancel 下界 `2000`, 天然不被 cancel 误伤。

## 1.1.0 round 4b 整摘

`safetyAlertId = 5000000` 随 `showSafetyAlert` 整摘删除 (外联服务决策 D1, 不可逆)。
5000000 段 id 现在空着, 5M+ 段仍只占 5000001/5000002/5000100 三个。

## 验证脚本

`test/core/data/notification_id_band_round110_test.dart` 验证:
- 所有 cancel range 不重叠
- 所有固定带 id 不在任何 cancel range 内
- 1001 不被 med cancel 误伤

更新 ID 分配必须:
1. 选 5M+ 固定带 (单 id) 或空闲 cancel range
2. 更新本表 + 上游 sub-service const
3. 加 `notification_id_band_round110` 回归 case 验证不重叠
