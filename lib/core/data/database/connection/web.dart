// v0.18 (P2-P0-7) Web 平台 DB connection.
//
// 之前: web 端 IndexedDB 落明文 PII(姓名/电话/用药/情绪/树洞)
//      违反项目"零云端 + 本地加密"核心承诺。
//
// 现在: 启动时抛 UnsupportedError,production build 阻断 web 端使用。
//  精神心理患者 PII 在浏览器沙箱中"裸奔"风险,选 1 (阻断) 比选 2/3
//  (允许但加密) 更安全,代价是 web 端暂不可用。
//
// 未来 (v1.0+): 接 Web Crypto API + PBKDF2 + 用户首次启动设密码,
//  失败 3 次清数据,选 2 折中方案 (用户接受 + 加密)。
//  见 docs/P2_SYSTEM_REVIEW.md P0-7。

import 'package:drift/drift.dart';

/// v0.18 (P2-P0-7) Web 端阻断
///
/// Web 端暂不支持(精神心理 PII 不能落明文 IndexedDB)。
/// 用户看到此异常应该被 main.dart runZonedGuarded 捕获并显示友好提示。
/// Production build 用户根本不会走到这里(Android/iOS 才用 sqlcipher)。
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future.error(
      UnsupportedError(
        'Web 平台暂不支持,精神心理患者 PII 不能落明文 IndexedDB。\n'
        '请用 Android / iOS 客户端获得完整加密保护。\n'
        '详细原因见 docs/P2_SYSTEM_REVIEW.md P0-7。',
      ),
    ),
  );
}
