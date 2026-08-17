// v1.1.0 round 9 (论文落地 F4 树洞使用公约): 公约已读状态存储
//
// 首次进入树洞撰写页弹"树洞使用公约"dialog, 用户点"我知道了"后置已读
// 标志, 之后不再弹。纯 informational 提示 (非 PIPL 法律同意), 只需轻量
// bool 标志, 无需 audit log (跟 ConsentPreferenceStore 的 §13/§14 严格
// 同意留痕区分开)。
import 'package:shared_preferences/shared_preferences.dart';

/// 树洞公约已读状态存储 (data 层)
class VentAgreementStore {
  static const _kAcknowledged = 'vent_agreement_acknowledged';

  final SharedPreferences _prefs;

  VentAgreementStore(this._prefs);

  /// 是否已确认过公约 (true = 不再弹)
  Future<bool> isAcknowledged() async {
    return _prefs.getBool(_kAcknowledged) ?? false;
  }

  /// 标记公约已读
  Future<void> acknowledge() async {
    await _prefs.setBool(_kAcknowledged, true);
  }
}
