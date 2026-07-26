#!/usr/bin/env python3
# v0.25 round 56e (spen P0 #15): 一次性清 39 个 orphan ARB key
#
# 跟 check_orphan_arb_keys.py 配合:
# 1. check_orphan_arb_keys.py 检测 orphan (定义但代码未引用)
# 2. 本脚本删 zh / en / zh_Hant 三份 ARB 的 orphan 字段
# 3. 跑完后再跑 check_orphan_arb_keys 应报 0 orphan
#
# 注: 本脚本是一次性工具, 清完后不需要再跑. 但保留方便未来又有
# orphan 出现时手工清理.
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT / "lib" / "l10n"
ZH_ARB = L10N_DIR / "app_zh.arb"
EN_ARB = L10N_DIR / "app_en.arb"
ZH_HANT_ARB = L10N_DIR / "app_zh_Hant.arb"

# 39 个 orphan key (跟 check_orphan_arb_keys.py 报告一致)
ORPHANS = [
    "appTagline",
    "commonAutoCheckinFailed",
    "commonCheckinFailed",
    "commonConfirm",
    "commonDeleteWarning",
    "commonDone",
    "commonEmpty",
    "commonError",
    "commonTakePhoto",
    "homeSnoozeFailed",
    "legalPageResetConsent",
    "listSwipeDeleteHint",
    "medReportGenPdfAction",
    "moodAudioDeleteRecording",
    "moodAudioDurationTemplate",
    "moodAudioRecording",
    "moodAudioTranscriptEmpty",
    "moodLabel1",
    "moodLabel2",
    "moodLabel3",
    "moodLabel4",
    "moodLabel5",
    "notifChannelMedicationDescI18n",
    "notifChannelMedicationNameI18n",
    "notifDailyCheckInBodyI18n",
    "notifDailyCheckInTitleI18n",
    "settingsClearAllDataFailed",
    "settingsExport",
    "setupContactHint",
    "setupMedFrequency",
    "setupMedName",
    "setupMedSchedule",
    "setupMedTimes1",
    "setupMedTimes2",
    "setupMedTimes3",
    "setupSaveFailed",
    "ventDurationMinutes",
    "ventDurationMinutesSeconds",
    "ventDurationSeconds",
]


def clean_arb(arb_path: Path, orphans: list[str]) -> int:
    """从单个 ARB 文件删除 orphan 字段 + 对应 @metadata 配对. 返回删除数."""
    if not arb_path.exists():
        return 0
    with arb_path.open(encoding="utf-8") as f:
        content = f.read()
    # 解析 (用 json 是为了 sanity check, 但写回时保留原格式)
    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"  [SKIP] {arb_path.name} JSON parse 失败: {e}")
        return 0
    removed = 0
    for key in orphans:
        if key in data:
            del data[key]
            removed += 1
        # 也删 metadata 配对
        meta_key = f"@{key}"
        if meta_key in data:
            del data[meta_key]
    # 写回 (用 json.dump 重新格式化, indent=2 + ensure_ascii=False 保持中文)
    with arb_path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return removed


def main() -> int:
    total = 0
    for arb in [ZH_ARB, EN_ARB, ZH_HANT_ARB]:
        n = clean_arb(arb, ORPHANS)
        print(f"  {arb.name}: 删除 {n} 个 orphan key")
        total += n
    print(f"\n总删除: {total} (期望 {len(ORPHANS) * 3} = 39 keys × 3 ARB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
