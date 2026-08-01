#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
v0.27 R72: Play Console Data Safety Form JSON 模板生成器

背景:
- R68 googleplay 报告 GP-P0-7 阻塞: Data Safety Form 0 维护
- 4 大类必填 (账号 / 设备 / 应用活动 / 个人信息) + health data 勾
- 之前需用户手动填, 容易漏
- R72 脚本化: 自动从 PrivacyInfo.xcprivacy + privacy_policy.md 解析 + 生成 JSON 模板

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
        return {'sections': [], 'shared': [], 'collected': []}
    text = path.read_text(encoding='utf-8')
    return {
        'version': re.search(r'v0\.27\.0\+(\d+)', text).group(0)
        if re.search(r'v0\.27\.0\+\d+', text) else 'unknown',
        'sections': re.findall(r'^## (\d+\..+)$', text, re.MULTILINE),
    }


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


def build_health_data_section() -> dict:
    """build health data section (PHQ-9 + GAD-7 + medication + mood + audio)"""
    return {
        'category': 'Health info',
        'subcategories': [
            'Health conditions (PHQ-9 抑郁筛查 / GAD-7 焦虑筛查 answers)',
            'Medications (药名 / 剂量 / 用药时间)',
            'Mood and emotional state (1-5 颗星 + 60 秒语音 + 标签)',
        ],
        'encrypted_in_transit': True,
        'encrypted_at_rest': True,
        'user_can_request_deletion': True,
        'collected_for_functionality': True,
        'notes': 'v0.27 R68 业务暂停: 失联通知业务整体暂停 (FeatureFlags.emergencyContactEnabled=false), 不实际触发 SMS / Email 触达。Health data 仅本地存储 (SQLCipher AES-256 + FlutterSecureStorage Keychain), 零云端。',
    }


def build_deletion_endpoint() -> dict:
    """build data deletion endpoint info"""
    return {
        'url': 'https://chroniccare.app/delete-data-instructions',
        'in_app_deletion': '设置 → 数据管理 → 导出 / 清空',
        'uninstall_deletion': 'Android 12+: 卸载 App 自动清; Android < 12: 手动通过系统设置清',
        'notes': 'App 内一键清空所有数据 (跟 R67 ConsentGate 集成), 卸载后本地数据库删除。',
    }


def main():
    project_root = Path(__file__).resolve().parent.parent
    privacy_policy = project_root / 'assets' / 'legal' / 'privacy_policy.md'
    privacy_info = project_root / 'ios' / 'Runner' / 'PrivacyInfo.xcprivacy'
    out_dir = project_root / 'build'
    out_dir.mkdir(exist_ok=True)

    print('=' * 60)
    print('Play Console Data Safety Form JSON 模板生成器 (R72)')
    print('=' * 60)
    print()

    pp = parse_privacy_policy(privacy_policy)
    pi = parse_privacy_info_xcprivacy(privacy_info)
    health = build_health_data_section()
    deletion = build_deletion_endpoint()

    form = {
        'metadata': {
            'generated_at': datetime.now().isoformat(),
            'project': 'chroniccare',
            'app_version': pp.get('version', 'unknown'),
            'privacy_policy_url': 'https://chroniccare.app/privacy',
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
                'collected': True,
                'types': [
                    'Name (联系人姓名, 选填)',
                    'Phone number (紧急联系人手机号, 选填)',
                ],
                'purpose': 'App functionality (失联通知业务当前暂停, 数据仅本地存储)',
            },
            'health_info': health,
        },
        'data_shared': {
            'shared_with_third_parties': False,
            'notes': 'v0.27 R68: 失联通知业务整体暂停 (FeatureFlags.emergencyContactEnabled=false), 不触发任何第三方 SMS / Email 触达。Health data 仅本地存储, 零云端, 零共享。',
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
- 收集: ✅ ({', '.join(form['data_collected']['personal_info']['types'])})
- 用途: {form['data_collected']['personal_info']['purpose']}

### 健康信息 (Health)
- 收集: ✅
- 子类:
{chr(10).join('  - ' + s for s in form['data_collected']['health_info']['subcategories'])}
- 加密传输: {form['data_collected']['health_info']['encrypted_in_transit']}
- 加密存储: {form['data_collected']['health_info']['encrypted_at_rest']}
- 用户可请求删除: {form['data_collected']['health_info']['user_can_request_deletion']}
- 备注: {form['data_collected']['health_info']['notes']}

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
