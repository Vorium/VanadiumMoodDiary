#!/usr/bin/env python3
"""Refresh store metadata copy with emotion-first angle (R128e+).

Touches:
  - fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/description.txt
  - fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/subtitle.txt
  - fastlane/metadata/ios/en-US/keywords.txt
  - fastlane/metadata/android/{en-US,zh-CN}/full_description.txt
  - fastlane/metadata/android/{en-US,zh-CN}/short_description.txt

emotion-first rules:
  - NO medical terms (diagnosis, treatment, prescribe, cure)
  - MUST contain 2+ of: mood, vent, journal, tree hole, 树洞, 情绪
  - Vent/tree hole is differentiated FIRST (not buried)
  - 危机热线精简

Usage: python3 scripts/refresh_emotion_first_copy.py
"""

from __future__ import annotations
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

IOS_EN_DESCRIPTION = '''MoodDiary is more than a mood journal — it's a private vent space where your words stay yours.

Every day has unspoken moments. MoodDiary gives you a quiet corner to:
• Rate today across 4 dimensions (mood, energy, sleep, stress)
• Vent freely with voice or text — fully encrypted, on your phone
• Watch patterns over time and see yourself getting better, one day at a time

This is not a medical tool. It doesn't diagnose or treat. But it can help you notice how you feel.

VENT FIRST
A completely private space to write or record what's on your mind. No judgment, no cloud, no one watching. Voice notes supported.

MOOD JOURNAL
Rate today across mood, energy, sleep, and stress. Attach voice notes, influence factors, and optional CBT thought records.

WORRY CLOSURE
Start a worry thread, and record every time it comes back. The day you say "I'm no longer worried", it moves to your memory archive.

TRENDS
Cross-mood, cross-vent trend charts — see yourself getting better, day by day.

SELF-REFLECTION
Optional self-reflection questionnaires to observe patterns in your feelings. Results are for reference only. Answers stay on your device.

CRISIS RESOURCES
Local crisis hotlines (5 regions) — one tap to dial.

OUR PROMISE
• 100% local: all data and recordings stay on your phone, encrypted with SQLCipher
• Zero cloud: no servers, no accounts, no tracking
• Zero ads: no ad SDKs, no third-party analytics
• Permanently free: no in-app purchases, ever
• Exportable: JSON backups anytime, or delete everything with one tap

IMPORTANT DISCLAIMER
This app does not provide medical advice, diagnosis, or treatment. It is a personal journaling tool. If you are in an emergency, contact local emergency services:
• US: 988 (Suicide & Crisis Lifeline)
• UK: 116 123 (Samaritans)
• International: https://findahelpline.com

For everyone who needs a little support.
'''

IOS_ZH_HANS_DESCRIPTION = '''每个人都有说不出口的时刻。

MoodDiary 心情日记,一个只属于你的情绪日记和树洞。

它不是医疗工具,不能替代医生的诊断与治疗。但它能帮你:
• 在树洞里放心倾诉
• 记下每天的情绪和状态
• 看到自己一点一点变好的轨迹

核心功能

【树洞倾诉】完全私密的角落,把想说的写下来、说出来。加密存储在你的手机里。语音记录支持。

【情绪日记】用 4 个维度给今天打分,记录情绪变化轨迹。可附语音、影响因素,还有 CBT 思维记录帮你整理思路。

【烦恼闭环】记下一个烦恼,时间线记录每次心情。有一天你会发现"我不再烦恼啦",它会收藏进"忆往昔"。

【趋势回顾】跨情绪、树洞的趋势图,看到自己一点一点变好的轨迹。

【自我测评】可选的自助反思问卷,帮助观察情绪变化规律。结果仅供参考,答案只保存在你的手机上。

【危机资源】设置页内置各地心理援助热线,一键拨打。

我们的承诺
• 100% 本地:所有数据、录音都存在你手机里,用 SQLCipher 加密
• 零云端:没有服务器、没有账号、没有埋点
• 零广告:不接任何广告 SDK、不接任何第三方统计
• 永久免费:永远不收费,永远没有内购
• 数据可导出:随时导出 JSON 备份,也可以一键全部删除

重要声明
本 App 不提供医疗建议、诊断或治疗。MoodDiary 心情日记是一个个人记录工具,不能替代专业医疗服务。如出现紧急情况,请立即联系当地急救或心理危机热线:
• 全国 24 小时免费心理热线:800-810-1117
• 全国心理援助热线:400-161-9995
• 国际:https://findahelpline.com

献给每一个需要一点支持的人。
'''

IOS_ZH_HANT_DESCRIPTION = '''每個人都有說不出口的時刻。

MoodDiary 心情日記,一個只屬於你的情緒日記和樹洞。

它不是醫療工具,不能替代醫生的診斷與治療。但它能幫你:
• 在樹洞裡放心傾訴
• 記下每天的情緒和狀態
• 看到自己一點一點變好的軌跡

核心功能

【樹洞傾訴】完全私密的角落,把想說的寫下來、說出來。加密儲存在你的手機裡。語音記錄支援。

【情緒日記】用 4 個維度給今天打分,記錄情緒變化軌跡。可附語音、影響因素,還有 CBT 思維記錄幫你整理思路。

【煩惱閉環】記下一個煩惱,時間線記錄每次心情。有一天你會發現「我不再煩惱啦」,它會收藏進「憶往昔」。

【趨勢回顧】跨情緒、樹洞的趨勢圖,看到自己一點一點變好的軌跡。

【自我測評】可選的自助反思問卷,幫助觀察情緒變化規律。結果僅供參考,答案只保存在你的手機上。

【危機資源】設定頁內建各地心理援助熱線,一鍵撥打。

我們的承諾
• 100% 本地:所有資料、錄音都存在你手機裡,用 SQLCipher 加密
• 零雲端:沒有伺服器、沒有帳號、沒有埋點
• 零廣告:不接任何廣告 SDK、不接任何第三方統計
• 永久免費:永遠不收費,永遠沒有內購
• 資料可匯出:隨時匯出 JSON 備份,也可以一鍵全部刪除

重要聲明
本 App 不提供醫療建議、診斷或治療。MoodDiary 心情日記是一個個人記錄工具,不能替代專業醫療服務。如出現緊急情況,請立即聯絡當地急救或心理危機熱線:
• 台灣安心專線:1925
• 香港撒瑪利亞防止自殺會:2389 2222
• 國際:https://findahelpline.com

獻給每一個需要一點支持的人。
'''

IOS_EN_SUBTITLE = 'Mood Journal + Vent Space'
IOS_EN_KEYWORDS = 'mood,journal,vent,diary,wellbeing,self-care,mind,private,encrypted,free'

ANDROID_EN_SHORT = 'Mood journal + vent space. Private.'
ANDROID_ZH_CN_SHORT = '情绪日记·树洞倾诉·本地加密零云端'

WRITES = [
    ('fastlane/metadata/ios/en-US/description.txt', IOS_EN_DESCRIPTION),
    ('fastlane/metadata/ios/zh-Hans/description.txt', IOS_ZH_HANS_DESCRIPTION),
    ('fastlane/metadata/ios/zh-Hant/description.txt', IOS_ZH_HANT_DESCRIPTION),
    ('fastlane/metadata/ios/en-US/subtitle.txt', IOS_EN_SUBTITLE + '\n'),
    ('fastlane/metadata/ios/zh-Hans/subtitle.txt', '情绪日记 + 树洞倾诉\n'),
    ('fastlane/metadata/ios/zh-Hant/subtitle.txt', '情緒日記 + 樹洞傾訴\n'),
    ('fastlane/metadata/ios/en-US/keywords.txt', IOS_EN_KEYWORDS + '\n'),
    ('fastlane/metadata/android/en-US/full_description.txt', IOS_EN_DESCRIPTION),
    ('fastlane/metadata/android/zh-CN/full_description.txt', IOS_ZH_HANS_DESCRIPTION),
    ('fastlane/metadata/android/en-US/short_description.txt', ANDROID_EN_SHORT + '\n'),
    ('fastlane/metadata/android/zh-CN/short_description.txt', ANDROID_ZH_CN_SHORT + '\n'),
]


def main() -> None:
    for rel_path, content in WRITES:
        full = os.path.join(ROOT, rel_path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'  {rel_path}')
    print('[OK] emotion-first copy refreshed')


if __name__ == '__main__':
    main()
