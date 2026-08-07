// v0.27 round 77 (R76-N6 修): 法律协议版本号集中器
//
// 背景 (R76 superpowers-en 报告 P1-6):
//   之前 setup_page._kLegalVersion 跟 consent_dialog 都 hardcode const
//   字符串 'v0.27-2026-08-01', 跟 pubspec.yaml version 完全脱节 — 法务
//   模板升级时需要 bump pubspec.yaml 的 version, 但这里 const 字符串忘了改
//   = 用户同意的"v0.27" 法律协议跟实际 app version 不一致, PIPL §17
//   同意记录失效。
//
// 修法:
//   1) 抽 [kPubspecVersion] const (跟 pubspec.yaml 同步), 提供
//      [computeLegalVersionAt(now)] 跟 build 时机 + 日期合并计算
//   2) core_providers.dart 暴露 [legalVersionProvider], 启动时算一次
//      (跟同 session 时间锁定, 跨日不重算 — 避免同一 session 同一用户
//      同意 2 次记录 version 不同)
//   3) setup_page + consent_dialog 都从 provider 读, 不再有 hardcode
//
// 升级流程:
//   1) bump pubspec.yaml version (0.27.0+64+65 → 0.28.0+66)
//   2) 改本文件 [kPubspecVersion] 同步
//   3) 重新 build, ProviderScope 启动时算新的 version
//   4) 旧 session 同意的 version 跟新 version 不同 → 触发 re-consent
//
// v0.27 临时未加 package_info_plus (避免 iOS pod install / Android gradle
// 风险), const + 手动同步是 v1.0 上架前的折中。R78+ 评估引入
// package_info_plus 自动读 pubspec.yaml.version, 进一步降低漏改风险。

/// 跟 pubspec.yaml `version:` 字段同步 (compile time const)
/// R99 (BUG-2): 0.27.0+64+65 → 0.30.0+85 同步 (R78-R98 连续漏改)
const String kPubspecVersion = '0.30.0+85';

/// 计算法律协议版本号
///
/// 格式: `v{major.minor.patch}-{YYYY-MM-DD}`
/// - `v0.27` 来自 pubspec version
/// - 日期是 `now` (调用时机的时间) — 通常是启动时 / 用户首次打开同意
///   弹窗时, 同一 session 内返回相同 string (取决于 caller 是否缓存)
///
/// 同 session 不同时刻调用可能产生不同 string (跨 midnight), caller
/// 应该缓存到 provider 里避免同一 session 多次 re-consent。
String computeLegalVersionAt(DateTime now) {
  // pubspec "0.27.0+64+65" → "0.27.0", 再去掉尾 .patch → "0.27"
  final version = kPubspecVersion.split('+').first; // 0.27.0
  final majorMinor = version.split('.').take(2).join('.'); // 0.27
  final date = '${now.year.toString().padLeft(4, '0')}'
      '-${now.month.toString().padLeft(2, '0')}'
      '-${now.day.toString().padLeft(2, '0')}';
  return 'v$majorMinor-$date';
}
