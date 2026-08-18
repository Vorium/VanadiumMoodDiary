#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
R128e+ round 11: Google Play App Review Questionnaire 模板生成器

背景:
- R107 googleplay 报告 P0: App Review Questionnaire 0% (4 大块全空)
- 4 大块: Emotion & Well-being / Clinical Claims / Medical Device / Stigma & Equity
- R108 脚本化: 自动从 mood journal / vent space 业务生成声明文本
- 防止手动填漏项 + 跟隐私政策/PIPL §23/§28/§47 一致

用法:
  python scripts/generate_app_review_questionnaire.py

输出:
  build/app_review_questionnaire.json  (结构化, 含 4 大块)
  build/app_review_questionnaire.md    (人类可读 checklist)
"""
import json
import re
from datetime import datetime
from pathlib import Path


def parse_pubspec_version(project_root: Path) -> str:
    """从 pubspec.yaml 动态解析版本号 (GP-R112-04: 原硬编码 0.30.0+85)"""
    pubspec = project_root / 'pubspec.yaml'
    if not pubspec.exists():
        return 'unknown'
    m = re.search(r'^version:\s*(\S+)', pubspec.read_text(encoding='utf-8'), re.MULTILINE)
    return m.group(1) if m else 'unknown'


# 4 大块 问卷 (Google Play 实际表单项, 2025-Q3 调研)
APP_REVIEW_BLOCKS = {
    "1_emotion_wellbeing_disclosure": {
        "title": "1. Emotion & Well-being Disclosure",
        "summary": "Does your app focus on emotion, mental well-being, or emotional self-care?",
        "chroniccare_answer": "Yes",
        "disclosure": [
            "ChronicCare is a personal journaling tool that helps users record their daily mood, reflect on emotional well-being, and maintain a private vent space for self-expression.",
            "The app supports emotion-first self-care: a mood journal with daily entries (mood score, journal text, optional voice notes), a vent space (匿名倾诉空间) for private emotional release, and gentle self-monitoring scales for self-awareness. These are validated scales presented for self-monitoring purposes only.",
            "Voice notes recorded by the user (vent space / mood journal) are stored locally with AES-256 encryption. They are never uploaded, never shared, and are not used for advertising or any other purpose.",
            "The app integrates crisis hotline numbers for 6 regions (China 400-161-9995, US 988, UK Samaritans 116 123, Hong Kong 2382 0000, Taiwan 1925, Singapore Samaritans of Singapore 1-767) to support users in emotional emergencies.",
            "The app explicitly disclaims that it is a personal journaling tool and does NOT replace professional care. Users are advised to consult a qualified professional for any decisions about emotional well-being.",
        ],
        "key_phrases": [
            "Personal journaling tool, not a substitute for professional care",
            "Emotion-first: mood journal + vent space (匿名倾诉)",
            "Self-monitoring scales for self-awareness only",
            "User-recorded voice notes are local-only, encrypted, never shared",
            "Crisis hotline integration for emergency support",
            "Local-only data storage, zero cloud, AES-256 encryption",
        ],
    },
    "2_clinical_claims": {
        "title": "2. Clinical Claims & Evidence",
        "summary": "Does your app make any clinical, treatment, or diagnostic claims? Does it reference clinical studies or evidence?",
        "chroniccare_answer": "No clinical claims; references validated scales for self-monitoring only",
        "disclosure": [
            "ChronicCare does NOT make any claims about diagnosing, treating, curing, or preventing any condition.",
            "The app references standardized self-assessment scales which are widely used by professionals. These scales are referenced for **self-monitoring purposes only** and their results are NOT used for any diagnostic or treatment decision.",
            "The app does NOT claim to be a substitute for professional advice, diagnosis, or treatment. Users are explicitly advised to seek the advice of a qualified professional with any questions.",
            "The app includes a 'Personal Journaling Disclaimer' (see `assets/legal/medical_disclaimer.md`) which states: 'This app is a personal journaling tool only. It is not intended to be a substitute for professional advice, diagnosis, or treatment.'",
        ],
        "key_phrases": [
            "No diagnostic or treatment claims",
            "References standardized self-assessment scales for self-monitoring only",
            "Explicit personal journaling disclaimer in the app and in legal documents",
            "Does not claim to replace professional care",
        ],
    },
    "3_medical_device": {
        "title": "3. Medical Device Classification",
        "summary": "Is your app a medical device (regulated by FDA, NMPA, CE, or other medical device authorities)?",
        "chroniccare_answer": "No — the app is NOT a medical device",
        "disclosure": [
            "ChronicCare is **NOT** a medical device as defined by the U.S. Food and Drug Administration (FDA), the National Medical Products Administration (NMPA) of China, the European Union Medical Device Regulation (EU MDR), or any other medical device regulatory authority.",
            "The app does NOT perform any measurement, monitoring, or diagnostic function that would require medical device classification.",
            "The app does NOT measure vital signs (e.g., heart rate, blood pressure, blood glucose), does NOT administer any treatment, and does NOT provide any clinical decision support.",
            "The app is a **personal journaling tool** that helps users record daily mood, reflect on emotional well-being, and maintain a private vent space. The self-assessment scales are presented for self-monitoring purposes only, and their results are not intended to be used for any medical decision.",
            "The app does NOT make any claim that it is a medical device, and does NOT include any functionality that would subject it to medical device regulations.",
        ],
        "key_phrases": [
            "NOT a medical device (FDA, NMPA, EU MDR, or other authority)",
            "Does not perform measurement, monitoring, or diagnostic functions",
            "Does not measure vital signs or administer treatment",
            "Personal journaling tool only",
        ],
    },
    "4_stigma_equity": {
        "title": "4. Stigma, Equity & Sensitive Populations",
        "summary": "Does your app address stigma, equity, or target sensitive populations (children, elderly, LGBTQ+, etc.)?",
        "chroniccare_answer": "Addresses emotional well-being stigma; targets general adult population",
        "disclosure": [
            "ChronicCare is designed to help reduce the stigma associated with emotional struggles by providing a private, personal journaling tool for daily mood reflection, emotional release, and well-being tracking.",
            "The app does NOT target any sensitive population specifically (e.g., children under 18, elderly over 65, LGBTQ+ individuals, pregnant women). The app is intended for **general adult users (18+)** seeking personal journaling and emotional self-care.",
            "The app does NOT contain any content that could be considered discriminatory, harmful, or stigmatizing toward any group of people.",
            "The app supports **multiple languages** (Simplified Chinese, English, Traditional Chinese) to improve accessibility for users in different regions.",
            "The app integrates crisis hotline numbers for **6 regions** (China, US, UK, Hong Kong, Taiwan, Singapore) to ensure that users in different countries have access to emergency emotional support.",
            "The app is designed to be accessible to users with low digital literacy, with a simple, intuitive interface and clear language (avoiding clinical jargon).",
        ],
        "key_phrases": [
            "Helps reduce emotional well-being stigma through private journaling",
            "Targets general adult population (18+), no sensitive population targeted",
            "No discriminatory, harmful, or stigmatizing content",
            "Multi-language support (zh / en / zh-Hant) for accessibility",
            "Crisis hotline integration for 6 regions",
            "Accessible to users with low digital literacy",
        ],
    },
}


def build_block_responses() -> dict:
    """build 4 大块 完整响应"""
    project_root = Path(__file__).resolve().parent.parent
    return {
        "metadata": {
            "generated_at": datetime.now().isoformat(),
            "project": "chroniccare",
            "app_version": parse_pubspec_version(project_root),
            "play_console_form": "App Review Questionnaire",
            "estimated_completion_time": "10-15 minutes (人工复制粘贴 4 大块)",
        },
        "blocks": APP_REVIEW_BLOCKS,
    }


def render_markdown(responses: dict) -> str:
    """render 人类可读 Markdown"""
    md = f"""# Google Play App Review Questionnaire (R128e+ 自动生成)

> 生成时间: {responses['metadata']['generated_at']}
> 项目: {responses['metadata']['project']}
> App 版本: {responses['metadata']['app_version']}
> 表单: {responses['metadata']['play_console_form']}
> 预计人工填写时间: {responses['metadata']['estimated_completion_time']}

> **重要**: Google Play **强烈建议**所有 Health & Fitness 类别 App 提交本问卷, 即便 App 不是医疗设备 (FDA/NMPA)。
> 本项目对应 Play Console 路径: **Policy → App content → Health apps** (4 大块)。
> R128e+ 重命名: emotion-first framing (mood journal / vent space / personal journaling tool), 不再以 "Health Apps" 自称。

---

"""
    for block_key, block in responses["blocks"].items():
        md += f"## {block['title']}\n\n"
        md += f"**问题**: {block['summary']}\n\n"
        md += f"**本项目答案**: **{block['chroniccare_answer']}**\n\n"
        md += f"**Disclosure (复制粘贴到 Play Console)**:\n\n"
        for i, line in enumerate(block["disclosure"], 1):
            md += f"{i}. {line}\n"
        md += f"\n**关键短语 (摘要)**:\n\n"
        for phrase in block["key_phrases"]:
            md += f"- {phrase}\n"
        md += "\n---\n\n"

    md += """## 4 步填 Play Console

1. 打开 https://play.google.com/console → 选 ChronicCare
2. **Policy → App content → Health apps** 卡片
3. 点 **Start** (首次) 或 **Manage** (已填过)
4. 逐项填 4 大块, 每块复制上面的 Disclosure 文字 → **Save** → **Submit app for review**

## Checklist

- [ ] Block 1 Emotion & Well-being Disclosure 已填 (答案: Yes, 5 段 disclosure)
- [ ] Block 2 Clinical Claims 已填 (答案: No clinical claims, references validated scales, 4 段 disclosure)
- [ ] Block 3 Medical Device Classification 已填 (答案: NOT a medical device, 5 段 disclosure)
- [ ] Block 4 Stigma & Equity 已填 (答案: 减少 stigma, 通用成年用户, 6 段 disclosure)
- [ ] Save + Submit app for review

## 关联文档

- `docs/audit/2026-08-10-cleanup/06-googleplay.md` §2.4 (App Review Questionnaire 详解)
- `assets/legal/medical_disclaimer.md` (R67 已加, Play Console 引用)
- `scripts/generate_data_safety_form.py` (R72, 配套 Data Safety Form)

---

> R128e+ 重命名: emotion-first framing (mood journal + vent space), 脚本逻辑不变, 仅重命名 + 重写披露文本。
"""
    return md


def main() -> None:
    project_root = Path(__file__).resolve().parent.parent
    out_dir = project_root / "build"
    out_dir.mkdir(exist_ok=True)

    print("=" * 60)
    print("Google Play App Review Questionnaire 模板生成器 (R128e+)")
    print("=" * 60)
    print()

    responses = build_block_responses()

    # JSON
    json_path = out_dir / "app_review_questionnaire.json"
    json_path.write_text(
        json.dumps(responses, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"[OK] JSON 写到: {json_path}")

    # Markdown
    md_path = out_dir / "app_review_questionnaire.md"
    md_path.write_text(render_markdown(responses), encoding="utf-8")
    print(f"[OK] Markdown 写到: {md_path}")

    print()
    print("=" * 60)
    print("总结:")
    print(f"  - JSON 模板: {json_path}")
    print(f"  - Markdown (人类可读): {md_path}")
    print(f"  - 4 大块全结构化")
    print(f"  - 预计人工填 Play Console 时间: 10-15 分钟")
    print("=" * 60)


if __name__ == "__main__":
    main()