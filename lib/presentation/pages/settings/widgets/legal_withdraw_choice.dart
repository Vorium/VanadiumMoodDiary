// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式):
// 公开 vent 撤回 3 选 1 dialog 内部 enum (R0.28 R82.5)
//
// 拆解动机 (R122 P2-2 续 R122 P2-1):
// - legal_page.dart 555L god class 候选, R31 误判"已闭环" 跨 12 round
// - 跟 R120 notification_service 7 sub-service 模式对齐: 抽 widget 到
//   widgets/ 子目录 + 公开 enum
// - 拆后主壳 ~120L (从 555L 减 78%)
//
// 公开 widget 命名:
// - _SectionTitle → LegalSectionTitle
// - _DocTile → LegalDocTile
// - _ConsentTile → LegalConsentTile
// - _WithdrawOption → LegalWithdrawOption
// - _VentWithdrawChoice → LegalWithdrawChoice (公开 enum)

/// vent 撤回 3 选 1 dialog 用户选择 (R0.28 R82.5 法务 Q7b 必改)
enum LegalWithdrawChoice { delete, sealed }
