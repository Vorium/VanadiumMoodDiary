#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
R128e+ round 12: Play Console Data Safety Form JSON 模板生成器 (emotion-first 重命名)

背景:
- R68 googleplay 报告 GP-P0-7 阻塞: Data Safety Form 0 维护
- 4 大类必填 (账号 / 设备 / 应用活动 / 个人信息) + Health info 勾 (Play Console 必填类目)
- 之前需用户手动填, 容易漏
- R72 脚本化: 自动从 PrivacyInfo.xcprivacy + privacy_policy.md 解析 + 生成 JSON 模板
- R128e+ round 12: emotion-first 重命名 — 自定位从 "Health Apps" 改为 "Personal Wellness App",
  Play Console 类目值 'Health info' 保留 (Google 官方分类术语, 不可改)

用法:
  python scripts/generate_data_safety_form.py

输出:
  build/data_safety_form.json
  build/data_safety_form.md (人类可读)
"""
import json
import os
import re
from pathlib import Path
from datetime import datetime


def parse_privacy_policy(path: Path) -> dict:
    """从 privacy_policy.md 解析数据收集声明"""
    if not path.exists():
        return {'sections': []}
    text = path.read_text(encoding='utf-8')
    return {
        'sections': re.findall(r'^## (\d+\..+)$', text, re.MULTILINE),
    }


def parse_pubspec_version(project_root: Path) -> str:
    """从 pubspec.yaml 动态解析版本号 (GP-R112-03: 原正则 v0.27.0+x 恒 unknown)"""
    pubspec = project_root / 'pubspec.yaml'
    if not pubspec.exists():
        return 'unknown'
    m = re.search(r'^version:\s*(\S+)', pubspec.read_text(encoding='utf-8'), re.MULTILINE)
    return m.group(1) if m else 'unknown'


def parse_privacy_info_xcprivacy(path: Path) -> list:
    """从 ios/Runner/PrivacyInfo.xcprivacy 解析 CollectedDataTypes"""
    if not path.exists():
        return []
    text = path.read_text(encoding='utf-8')
    # 找 NSPrivacyCollectedDataType 块
    collected = re.findall(
        r'<key>NSPrivacyCollectedDataType</key>\s*<string>(.*?)</string>',
        text, re.DOTALL,
    )
    # 找 NSPrivacyCollectedDataTypeLinked / Tracking / Purposes
    purposes = re.findall(
        r'<key>NSPrivacyCollectedDataTypePurposes</key>\s*<array>(.*?)</array>',
        text, re.DOTALL,
    )
    result = []
    for i, data_type in enumerate(collected):
        purpose_match = re.findall(r'<string>(.*?)</string>', purposes[i]) if i < len(purposes) else []
        result.append({
            'type': data_type,
            'linked': False,  # 实际从 NSPrivacyCollectedDataTypeLinked 解析, 简化为 false
            'tracking': False,  # 同上
            'purposes': purpose_match,
        })
    return result


def build_wellness_data_section() -> dict:
    """build wellness data section (自我评估量表 + medication + mood)

    GP-R112-03: 去 PHQ-9/GAD-7 点名 — prod 下 phqGad7I18nEnabled=false,
    实际露 8 量表 (ISI/PSS/WHODAS/ASRM/level2×4), 文案写通用措辞。
    R128e+ round 12: emotion-first 重命名 — function/JSON-key 从 health → wellness,
    category 值 'Health info' 保留 (Play Console 官方类目术语)。
    """
    return {
        'category': 'Health info',
        'subcategories': [
            'Self-assessment scale answers (guided self-reflection scales, on-device only)',
            'Medications (药名 / 剂量 / 用药时间)',
            'Mood and emotional state (1-5 颗星 + 标签)',
        ],
        'encrypted_in_transit': True,
        'encrypted_at_rest': True,
        'user_can_request_deletion': True,
        'collected_for_functionality': True,
        'notes': 'Personal wellness data 仅本地存储 (SQLCipher AES-256 + FlutterSecureStorage Keychain), 零云端, 零共享。',
    }


def build_audio_data_section() -> dict:
    """build audio files data section

    GP-R112-03: ventAudioEnabled=true + manifest RECORD_AUDIO → Audio 是真实
    收集的数据型, Play Data Safety 必须单列 "Photos and videos or audio" 大类。
    """
    return {
        'category': 'Photos and videos or audio',
        'subcategories': [
            'Voice notes (树洞/情绪语音笔记, 仅本地 AES-256 加密存储)',
        ],
        'encrypted_in_transit': True,
        'encrypted_at_rest': True,
        'user_can_request_deletion': True,
        'collected_for_functionality': True,
        'notes': '录音仅由用户主动录制, 本地加密存储, 不共享、不用于广告或诊断。',
    }


def build_deletion_endpoint() -> dict:
    """build data deletion endpoint info"""
    return {
        'url': '[PENDING_DOMAIN] https://chroniccare.app/delete-data-instructions',
        'in_app_deletion': '设置 → 数据管理 → 导出 / 清空',
        'uninstall_deletion': 'Android 12+: 卸载 App 自动清; Android < 12: 手动通过系统设置清',
        'notes': 'App 内一键清空所有数据 (跟 R67 ConsentGate 集成), 卸载后本地数据库删除。',
    }


def main():
    project_root = Path(__file__).resolve().parent.parent
    privacy_info = project_root / 'ios' / 'Runner' / 'PrivacyInfo.xcprivacy'
    out_dir = project_root / 'build'
    out_dir.mkdir(exist_ok=True)

    print('=' * 60)
    print('Play Console Data Safety Form JSON 模板生成器 (R72)')
    print('=' * 60)
    print()

    pi = parse_privacy_info_xcprivacy(privacy_info)
    wellness = build_wellness_data_section()
    audio = build_audio_data_section()
    deletion = build_deletion_endpoint()
    app_version = parse_pubspec_version(project_root)

    form = {
        'metadata': {
            'generated_at': datetime.now().isoformat(),
            'project': 'chroniccare',
            'app_version': app_version,
            'privacy_policy_url': '[PENDING_DOMAIN] https://chroniccare.app/privacy',
            'data_deletion_endpoint': deletion['url'],
        },
        'data_collected': {
            'account_info': {
                'collected': False,
                'notes': 'App 0 账号系统, 不收集账号信息',
            },
            'device_info': {
                'collected': True,
                'types': ['Device locale (zh / en / zh_Hant)'],
                'purpose': 'App functionality (跟 locale 切 ARB 文案)',
            },
            'app_activity': {
                'collected': True,
                'types': [
                    'App interactions (check-in / 趋势 / 评估)',
                    'In-app search history (无搜索, 仅 data filter)',
                ],
                'purpose': 'App functionality',
            },
            'personal_info': {
                'collected': False,
                'types': [],
                'purpose': '未收集 — emergencyContactEnabled=false, 紧急联系人功能全 gate (无任何入口)。v1.0 SMS 真接时改 collected=True 并更新 types。',
            },
            'wellness_info': wellness,
            'audio_files': audio,
        },
        'data_shared': {
            'shared_with_third_parties': False,
            'notes': 'v0.27 R68: 失联通知业务整体暂停 (FeatureFlags.emergencyContactEnabled=false), 不触发任何第三方 SMS / Email 触达。Personal wellness data 仅本地存储, 零云端, 零共享。',
        },
        'data_security_practices': {
            'data_encrypted_in_transit': True,
            'data_encrypted_at_rest': True,
            'users_can_request_data_deletion': True,
            'encryption_standard': 'AES-256 (SQLCipher) + Keychain (iOS) / EncryptedSharedPreferences (Android)',
        },
        'data_deletion': deletion,
        'ios_privacy_manifest': {
            'NSPrivacyTracking': False,
            'NSPrivacyTrackingDomains': [],
            'NSPrivacyCollectedDataTypes': pi,
            'NSPrivacyAccessedAPITypes': [
                {'category': 'UserDefaults', 'reasons': ['CA92.1', 'CA92.2']},
                {'category': 'FileTimestamp', 'reasons': ['C617.1']},
                {'category': 'SystemBootTime', 'reasons': ['35F9.1']},
                {'category': 'DiskSpace', 'reasons': ['85F4.1']},
                {'category': 'ProcessInfo', 'reasons': ['AC67.1']},
            ],
        },
    }

    # 写 JSON
    json_path = out_dir / 'data_safety_form.json'
    json_path.write_text(json.dumps(form, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'[OK] JSON 写到: {json_path}')

    # 写 Markdown (人类可读)
    md_path = out_dir / 'data_safety_form.md'
    md_content = f"""# Play Console Data Safety Form (R72 自动生成)

> 生成时间: {form['metadata']['generated_at']}
> 项目: {form['metadata']['project']}
> App 版本: {form['metadata']['app_version']}
> 隐私 URL: {form['metadata']['privacy_policy_url']}
> 数据删除端点: {form['metadata']['data_deletion_endpoint']}

## 1. 收集的数据

### 账号信息
- 收集: ❌
- 备注: {form['data_collected']['account_info']['notes']}

### 设备信息
- 收集: ✅ ({', '.join(form['data_collected']['device_info']['types'])})
- 用途: {form['data_collected']['device_info']['purpose']}

### App 活动
- 收集: ✅ ({', '.join(form['data_collected']['app_activity']['types'])})
- 用途: {form['data_collected']['app_activity']['purpose']}

### 个人信息
- 收集: {'✅' if form['data_collected']['personal_info']['collected'] else '❌'} ({', '.join(form['data_collected']['personal_info']['types']) or '无'})
- 用途: {form['data_collected']['personal_info']['purpose']}

### 音频 (Photos and videos or audio)
- 收集: ✅ ({', '.join(form['data_collected']['audio_files']['subcategories'])})
- 加密传输: {form['data_collected']['audio_files']['encrypted_in_transit']}
- 加密存储: {form['data_collected']['audio_files']['encrypted_at_rest']}
- 用户可请求删除: {form['data_collected']['audio_files']['user_can_request_deletion']}
- 备注: {form['data_collected']['audio_files']['notes']}

### 健康信息 (Health / Personal Wellness)
- 收集: ✅
- 子类:
{chr(10).join('  - ' + s for s in form['data_collected']['wellness_info']['subcategories'])}
- 加密传输: {form['data_collected']['wellness_info']['encrypted_in_transit']}
- 加密存储: {form['data_collected']['wellness_info']['encrypted_at_rest']}
- 用户可请求删除: {form['data_collected']['wellness_info']['user_can_request_deletion']}
- 备注: {form['data_collected']['wellness_info']['notes']}

## 2. 共享数据

- 共享给第三方: {'✅' if form['data_shared']['shared_with_third_parties'] else '❌'}
- 备注: {form['data_shared']['notes']}

## 3. 安全实践

- 传输加密: {'✅' if form['data_security_practices']['data_encrypted_in_transit'] else '❌'}
- 存储加密: {'✅' if form['data_security_practices']['data_encrypted_at_rest'] else '❌'}
- 用户可请求删除: {'✅' if form['data_security_practices']['users_can_request_data_deletion'] else '❌'}
- 加密标准: {form['data_security_practices']['encryption_standard']}

## 4. 数据删除

- URL: {form['data_deletion']['url']}
- App 内删除: {form['data_deletion']['in_app_deletion']}
- 卸载后删除: {form['data_deletion']['uninstall_deletion']}
- 备注: {form['data_deletion']['notes']}

## 5. iOS Privacy Manifest (从 ios/Runner/PrivacyInfo.xcprivacy 解析)

- 追踪: {'✅' if form['ios_privacy_manifest']['NSPrivacyTracking'] else '❌'}
- 追踪域名: {', '.join(form['ios_privacy_manifest']['NSPrivacyTrackingDomains']) or '(无)'}
- 收集数据类型数: {len(form['ios_privacy_manifest']['NSPrivacyCollectedDataTypes'])}
- 访问 API 类型数: {len(form['ios_privacy_manifest']['NSPrivacyAccessedAPITypes'])}

---

## 用法 (Play Console 提交时):

1. 打开 https://play.google.com/console → App content → Data safety
2. 用本 Markdown 文档的"收集的数据" / "共享数据" / "安全实践" / "数据删除" 4 大类逐项勾选
3. 填完后点 "Save" → "Submit app for review"
4. 后续改隐私政策 → 重新跑本脚本 → 重新填 Data Safety Form

> R72 简化: 4 大类结构化 + 从 PrivacyInfo 自动解析, 避免人工漏填
"""
    md_path.write_text(md_content, encoding='utf-8')
    print(f'[OK] Markdown 写到: {md_path}')
    print()
    print('=' * 60)
    print('总结:')
    print(f'  - JSON 模板: {json_path}')
    print(f'  - Markdown (人类可读): {md_path}')
    print(f'  - 收集数据类型: {len(form["ios_privacy_manifest"]["NSPrivacyCollectedDataTypes"])}')
    print(f'  - 访问 API: {len(form["ios_privacy_manifest"]["NSPrivacyAccessedAPITypes"])}')
    print('=' * 60)


if __name__ == '__main__':
    main()
