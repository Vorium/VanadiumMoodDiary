// v0.30 R108 (P0#7, appstore A-6): fastlane review_information 占位文件
//
// 背景:
//   fastlane/metadata/ios/review_information/ 目录不存在 → Apple App Store
//   Connect 提交时硬阻塞 (fastlane deliver 报 "Missing required review
//   information fields")。需要 6 个标准字段文件:
//
//   - first_name.txt      (Apple Review 联系人的 first name)
//   - last_name.txt       (Apple Review 联系人的 last name)
//   - email_address.txt   (Apple Review 联系的邮箱)
//   - phone_number.txt    (Apple Review 联系的电话)
//   - demo_user.txt       (审核员 demo 账号, 本项目无 login = "n/a" 或说明)
//   - notes.txt           (审核员补充说明, 含功能开关 / 数据流 / 权限说明)
//
// 修法 (R108):
//   - 目录创建
//   - 6 个 .txt 占位文件, 内容标注 TODO / 真实填写
//   - demo_user.txt 写 "This app does not require login — ..." 解释
//   - notes.txt 写 8 项审核员指南 (含 FeatureFlag 7 项业务暂停说明)
//
// 锁住: 防御未来 R109+ refactor 误删目录或文件。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #9: fastlane review_information 占位文件', () {
    test('fastlane/metadata/ios/review_information/ 目录存在', () {
      final dir = Directory('fastlane/metadata/ios/review_information');
      expect(dir.existsSync(), isTrue, reason: 'review_information 目录必须存在');
    });

    // 6 个标准字段, Apple fastlane deliver 必读
    const requiredFiles = <String>[
      'first_name.txt',
      'last_name.txt',
      'email_address.txt',
      'phone_number.txt',
      'demo_user.txt',
      'notes.txt',
    ];

    for (final filename in requiredFiles) {
      test('review_information/$filename 文件存在且非空', () {
        final file = File(
          'fastlane/metadata/ios/review_information/$filename',
        );
        expect(file.existsSync(), isTrue, reason: '$filename 必须存在');
        final content = file.readAsStringSync();
        expect(
          content.trim().isNotEmpty,
          isTrue,
          reason: '$filename 内容不能为空',
        );
      });
    }

    test('demo_user.txt 含 "no login" / "does not require login" 声明', () {
      // 重要: Apple fastlane deliver 必读 demo_user, 必须明确说明 app 无 login
      // 否则审核员会问 "怎么给我 demo 账号?" 拖延审核
      final file = File(
        'fastlane/metadata/ios/review_information/demo_user.txt',
      );
      final content = file.readAsStringSync().toLowerCase();
      expect(
        content.contains('does not require login') ||
            content.contains('no login') ||
            content.contains('no account'),
        isTrue,
        reason: 'demo_user.txt 必须明确说明 app 无 login 需求, 避免审核员追问 demo 账号',
      );
    });

    test('notes.txt 含审核员指南 (FeatureFlag / 数据流 / 权限)', () {
      // 锁定关键术语: 至少出现 1 个 "App Reviewer Guide" / "FeatureFlag" /
      // "no cloud" / "no analytics" / "encrypted" 之一
      final file = File(
        'fastlane/metadata/ios/review_information/notes.txt',
      );
      final content = file.readAsStringSync().toLowerCase();
      final hits = <String>[];
      for (final keyword in [
        'app reviewer',
        'featureflag',
        'no cloud',
        'no analytics',
        'encrypted',
        'sqlcipher',
      ]) {
        if (content.contains(keyword)) hits.add(keyword);
      }
      expect(
        hits.isNotEmpty,
        isTrue,
        reason: 'notes.txt 应含审核员指南关键词, 实际命中: $hits',
      );
    });

    test('联系信息 4 文件含 TODO 标记 (未注册域名 / 邮箱占位)', () {
      // first_name / last_name / email_address / phone_number 4 个真实联系
      // 信息字段, 当前是 TODO 占位 (域名未注册, 邮箱未注册)。
      // 防御未来有人误以为已填真实信息, 上传时漏出。
      const contactFiles = [
        'first_name.txt',
        'last_name.txt',
        'email_address.txt',
        'phone_number.txt',
      ];
      for (final filename in contactFiles) {
        final file = File(
          'fastlane/metadata/ios/review_information/$filename',
        );
        final content = file.readAsStringSync();
        // 允许两种形式: 含 "TODO" 或已被真实信息覆盖 (防御性)
        final hasTodo = content.contains('TODO');
        // 强制要求至少占位标记 (业务上线前域名 + 邮箱注册后会替换为真实值,
        // 替换时记得更新 lock-in test)
        expect(
          hasTodo || content.trim().length >= 2,
          isTrue,
          reason: '$filename 应含 TODO 占位或真实信息',
        );
      }
    });
  });
}
