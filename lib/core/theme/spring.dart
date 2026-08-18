// v1.1.0+186 R129 P0-3 (R128e 综合审视修真) — spring 物理模型 re-export shim
//
// R128d step 1 拆 5 token 集中器时漏拆 spring.dart (留 lib/core/theme/), R129 P0-3
// 修真将其迁到 packages/chroniccare_theme/lib/src/spring.dart (完整 6 集中器闭环).
// 本 shim 跟 R128a notification umbrella 7 re-export + R128d 5 旧 path re-export 同
// 模式, 旧 caller 0 改动.
//
// v0.32 round 8 (R112-03 fix): 删 `SpringType` enum + `Spring.of` factory 死代码
// v1.1.0+162 R121 P1-4 (flutter-spec 跨期修复): gentle 接 1 个 caller, spec §3.4.3
// 完整 3 模型面 (standard / gentle / bouncy) 全部有 caller.
export 'package:chroniccare_theme/chroniccare_theme.dart' show Spring;
