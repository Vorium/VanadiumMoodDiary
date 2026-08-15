// lib/domain/logic/status_phrase_library.dart
/// 情绪状态短语库（v1.1.0）— 预设短语 + 自定义输入
///
/// 记录 dialog 按当前所选 score 方向优先展示对应组。
class StatusPhraseLibrary {
  StatusPhraseLibrary._();

  static const List<String> low = ['有点难过', '心情很低落', '想哭', '提不起劲'];

  static const List<String> tired = ['疲惫但平静', '好累', '身体被掏空', '只想躺着'];

  static const List<String> calm = ['平静', '安稳', '淡淡的', '没什么特别'];

  static const List<String> positive = ['被治愈了', '心情不错', '充满能量', '有盼头', '很快乐'];

  static const List<String> all = [...low, ...tired, ...calm, ...positive];

  /// score 1-5 → 优先展示的短语组
  /// - 1-2: 低落 + 疲惫
  /// - 3: 平静
  /// - 4-5: 积极
  static List<String> phrasesForScore(int score) {
    if (score <= 2) return [...low, ...tired];
    if (score == 3) return calm;
    return positive;
  }
}
