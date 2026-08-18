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
  group('法律文档文档一致性 (R128e 定版结构)', () {
    test('3 法律 md 都有 v1.0.0 定版标记 + 无 IAP/买断 残留', () {
      // R128e (2026-08-18): 法律文档重写为新结构 (v1.0.0 定版), 原
      // "## 0.6 v0.30 业务暂停" section 随 R93 业务删除一并移除。
      // 改验新结构标记 (v1.0.0 定版 + lifestyle 类别 + 无 IAP 残留)。
      final privacy = File('assets/legal/privacy_policy.md').readAsStringSync();
      expect(
        privacy.contains('v1.0.0') && privacy.contains('定版'),
        isTrue,
        reason: 'privacy_policy.md 缺 v1.0.0 定版标记 (R128e 重写)',
      );
      // v1.0.0+147: 永久免费, 法务文档 0 IAP / 0 买断残留 (lock-in 防回退)
      expect(
        privacy.contains('IAP') ||
            privacy.contains('买断') ||
            privacy.contains('8 元'),
        isFalse,
        reason: 'privacy_policy.md 含 IAP / 买断残留 (v1.0.0+147 已删, 防回退)',
      );

      // sensitive_data_consent.md: v1.0.0 定版标记 + 情绪健康去医疗化
      final sensitive =
          File('assets/legal/sensitive_data_consent.md').readAsStringSync();
      expect(
        sensitive.contains('v1.0.0') && sensitive.contains('定版'),
        isTrue,
        reason: 'sensitive_data_consent.md 缺 v1.0.0 定版标记 (R128e 重写)',
      );
      expect(
        sensitive.contains('情绪健康'),
        isTrue,
        reason: 'sensitive_data_consent.md 缺 "情绪健康" 去医疗化标记 (R128e)',
      );
      expect(
        sensitive.contains('IAP') || sensitive.contains('买断'),
        isFalse,
        reason: 'sensitive_data_consent.md 含 IAP / 买断残留 (v1.0.0+147 已删, 防回退)',
      );

      // user_agreement.md: v1.0.0 定版 + 永久免费 + 非医疗工具
      final userAgreement =
          File('assets/legal/user_agreement.md').readAsStringSync();
      expect(
        userAgreement.contains('永久完全免费'),
        isTrue,
        reason: 'user_agreement.md 缺永久免费承诺 (v1.0.0+147 定版)',
      );
      expect(
        userAgreement.contains('非医疗工具'),
        isTrue,
        reason: 'user_agreement.md 缺 "非医疗工具" 标记 (R128e 医疗声称降级)',
      );
      expect(
        userAgreement.contains('买断') || userAgreement.contains('8 元'),
        isFalse,
        reason: 'user_agreement.md 含买断 / 8 元残留 (v1.0.0+147 已删, 防回退)',
      );
    });

    test('README.md 含 FeatureFlag 业务暂停说明 + 永久免费声明', () {
      // R97-P1-12 (2026-08-07): README 在 commit f0dcaa6 升级为 R95 阶段 1+2+3+4
      // 状态, 不再含 R93 "阶段 2 集中修复" banner。改验 FeatureFlag
      // 业务暂停说明 (这两个 flag 是长期存在的, 跟 R93/R95 阶段无关)。
      // v1.0.0+146/v1.0.0+147: README 精简重写 + 永久免费定版。
      final readme = File('README.md').readAsStringSync();
      expect(
        readme.contains('永久完全免费'),
        isTrue,
        reason: 'README.md 缺永久免费声明',
      );
      expect(
        readme.contains('iapEnabled') ||
            readme.contains('8 元') ||
            readme.contains('IAP'),
        isFalse,
        reason: 'README.md 含 iapEnabled / 8 元 / IAP 残留 (v1.0.0+147 已删, 防回退)',
      );
      // 1.1.0 round 4b: emergencyContactEnabled flag 随外联服务整摘, 文档
      // 一致性断言移除 (docs 全文去外联由文档任务跟进)。
    });

    test('DEPLOYMENT.md 阶段 5/6/7 节都有', () {
      final deployment = File('docs/DEPLOYMENT.md').readAsStringSync();
      expect(
        deployment.contains('## 阶段 5'),
        isTrue,
        reason: 'DEPLOYMENT.md 缺阶段 5 (Apple 完整 metadata 模板)',
      );
      expect(
        deployment.contains('## 阶段 6'),
        isTrue,
        reason: 'DEPLOYMENT.md 缺阶段 6 (5 项上架前手动 checklist)',
      );
      expect(
        deployment.contains('## 阶段 7'),
        isTrue,
        reason: 'DEPLOYMENT.md 缺阶段 7 (部署 + 上线监控)',
      );
      // 阶段 6 必含 R93 阶段 2 FeatureFlag checklist
      expect(
        deployment.contains('R93 阶段 2'),
        isTrue,
        reason: 'DEPLOYMENT.md 阶段 6 缺 R93 阶段 2 标识',
      );
      expect(
        deployment.contains('4 项 FeatureFlag 当前状态'),
        isTrue,
        reason:
            'DEPLOYMENT.md 阶段 6 缺 4 项 FeatureFlag checklist 标题 (v1.1.0 删外联 3 flag)',
      );
    });
  });
}
