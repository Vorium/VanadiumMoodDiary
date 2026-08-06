// v0.30 round 93 (test): R93 阶段 2 文档一致性守门
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// 文档一致性守门 (CI 友好, 跑 `flutter test test/documentation/`):
// - 3 法律 md 都有 "v0.30 业务暂停" section 字符串 (或修订历史 entry)
// - README 含 "R93 阶段 2" 红 banner 字符串
// - DEPLOYMENT.md 阶段 5/6/7 节都有
//
// 测试模式: 静态文件读取 (dart:io File), 不依赖 Flutter test runtime
// (虽然走 flutter test 调用, 但只 readAsStringSync 不依赖 widget binding)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R93 阶段 2 文档一致性', () {
    test('3 法律 md 都有 v0.30 业务暂停说明', () {
      // privacy_policy.md 加 §0.6 "v0.30 业务暂停" section (强约束)
      final privacy = File('assets/legal/privacy_policy.md').readAsStringSync();
      expect(privacy.contains('## 0.6 v0.30 业务暂停'), isTrue,
          reason: 'privacy_policy.md 缺 §0.6 v0.30 业务暂停 section');
      expect(privacy.contains('FeatureFlags.iapEnabled'), isTrue,
          reason: 'privacy_policy.md 缺 FeatureFlags.iapEnabled 说明');
      expect(privacy.contains('FeatureFlags.emergencyContactEnabled'), isTrue,
          reason: 'privacy_policy.md 缺 FeatureFlags.emergencyContactEnabled 说明');

      // sensitive_data_consent.md 加修订历史 entry (R93 阶段 2 集中隐藏)
      final sensitive =
          File('assets/legal/sensitive_data_consent.md').readAsStringSync();
      expect(sensitive.contains('v0.30 R93'), isTrue,
          reason: 'sensitive_data_consent.md 缺 v0.30 R93 修订历史 entry');
      expect(sensitive.contains('R93 阶段 2'), isTrue,
          reason: 'sensitive_data_consent.md 缺 R93 阶段 2 说明');

      // user_agreement.md 加修订历史 entry (R93 阶段 2 集中隐藏)
      final userAgreement =
          File('assets/legal/user_agreement.md').readAsStringSync();
      expect(userAgreement.contains('v0.30 R93'), isTrue,
          reason: 'user_agreement.md 缺 v0.30 R93 修订历史 entry');
      expect(userAgreement.contains('IAP 8 元买断业务暂停'), isTrue,
          reason: 'user_agreement.md 缺 IAP 业务暂停说明');
    });

    test('README.md 含 R93 阶段 2 红 banner', () {
      final readme = File('README.md').readAsStringSync();
      expect(readme.contains('v0.30 阶段 2 集中修复'), isTrue,
          reason: 'README.md 缺 v0.30 阶段 2 集中修复红 banner');
      expect(readme.contains('R93'), isTrue,
          reason: 'README.md 缺 R93 标识');
      expect(readme.contains('iapEnabled=false'), isTrue,
          reason: 'README.md 缺 iapEnabled=false 业务暂停说明');
      expect(readme.contains('emergencyContactEnabled=false'), isTrue,
          reason: 'README.md 缺 emergencyContactEnabled=false 业务暂停说明');
    });

    test('DEPLOYMENT.md 阶段 5/6/7 节都有', () {
      final deployment = File('docs/DEPLOYMENT.md').readAsStringSync();
      expect(deployment.contains('## 阶段 5'), isTrue,
          reason: 'DEPLOYMENT.md 缺阶段 5 (Apple 完整 metadata 模板)');
      expect(deployment.contains('## 阶段 6'), isTrue,
          reason: 'DEPLOYMENT.md 缺阶段 6 (5 项上架前手动 checklist)');
      expect(deployment.contains('## 阶段 7'), isTrue,
          reason: 'DEPLOYMENT.md 缺阶段 7 (部署 + 上线监控)');
      // 阶段 6 必含 R93 阶段 2 FeatureFlag checklist
      expect(deployment.contains('R93 阶段 2'), isTrue,
          reason: 'DEPLOYMENT.md 阶段 6 缺 R93 阶段 2 标识');
      expect(deployment.contains('7 项 FeatureFlag 全部 hidden'), isTrue,
          reason: 'DEPLOYMENT.md 阶段 6 缺 7 项 FeatureFlag checklist 标题');
    });
  });
}
